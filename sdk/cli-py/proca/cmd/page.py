#!/usr/bin/env python3


import click
import operator

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.context import pass_context
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier, validate_locale
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql

from termcolor import colored, cprint

@click.command("page")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-l', '--list', 'ls', is_flag=True, help="List action pages")
@click.option('-o', '--org', 'org', help="Only list for org")
@click.option('-c', '--campaign', help="Only list for campaign")
@click.option('-f', '--config', type=click.File('w'))
@click.option('-F', '--campaign-config', type=click.File('w'))
@pass_context
def show(ctx, id, name, identifier, ls, org, campaign, config, campaign_config):
    if ls:
        orgs, pages = action_pages_by_org(ctx.client)
        for oname, org_pages in pages.items():
            if org and oname != org:
                continue

            odata = orgs[oname]

            out = W(odata['title']) + w(f" {odata['name']}")
            print(out)

            for p in org_pages:
                if campaign and p['campaign']['name'] != campaign:
                    continue
                print(format(p))
        return

    id, name = guess_identifier(id, name, identifier)

    page = fetch_action_page(ctx.client, id, name)
    out = format(page)
    print(out)

    if config:
        config.write(page['config'])

    if campaign_config:
        campaign_config.write(page['campaign']['config'])

@click.command("page:add")
@click.option('-o', '--org', help="organisation", prompt="Organisation")
@click.option('-c', '--campaign', help="campaign", prompt="Campaign")
@click.option('-n', '--name', help="name", prompt="Short name of the page")
@click.option('-l', '--locale', help="locale", prompt="Locale of the page", callback=validate_locale)
@pass_context
def add(ctx, locale, name, org, campaign):
    print(rainbow(f"{locale}|!{name}|{campaign}"))

    ap = add_action_page(ctx.client, name=name, locale=locale, org=org, campaign=campaign)

@click.command("page:set")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-N', '--rename')
@click.option('-l', '--locale')
@click.option('-x', '--extra', type=int)
@click.option('-d/-D', '--deliver/--no-deliver', default=None)
@click.option('-t', '--template')
@click.option('-f', '--config', type=click.File('r'))
@pass_context
def set(ctx, id, name, identifier, rename, locale, extra, deliver, template, config):
    id, name = guess_identifier(id, name, identifier)


    input = {}

    if rename:
        input["name"] = rename
    if locale:
        input["locale"] = locale
    if isinstance(extra, int):
        input["extraSupporters"] = extra
    if deliver:
        input["delivery"] = deliver
    if template:
        input["thankYouTemplate"] = template
    if config:
        config_json = config.read()
        input["config"] = config_json

    update_action_page(ctx.client, id, name, input)


@explain_error('adding action page')
def add_action_page(client, **attrs):
    query = """
    mutation add($org: String!, $campaign: String!, $input: ActionPageInput!) {
        addActionPage(orgName: $org,  campaignName:$campaign, input: $input) {
            ...actionPageData
        }
    }
    """ + actionPageData

    query = gql(query)

    org = attrs.pop("org")
    campaign = attrs.pop("campaign")

    data = client.execute(query, **vars(org=org, campaign=campaign, input=attrs))
    return data['addActionPage']


@explain_error('updating action page')
def update_action_page(client, id, name, input):
    query = """
    mutation upd($id: Int, $name: String, $input: ActionPageInput!) {
        updateActionPage(id: $id, name: $name, input: $input) {
            id
        }
    }
    """

    query = gql(query)

    data = client.execute(query, **vars(id=id, name=name, input=input))
    return data['updateActionPage']




@explain_error('fetching action page')
def fetch_action_page(client, id, name, public=False):

    query = """
    query fetchActionPage($id: Int, $name: String){
        actionPage(id: $id, name: $name) {
        ...actionPageData
        campaign { ...campaignData }
        ...actionPageStatus
        }
    }
    """ + actionPageData + campaignData + actionPageStatus

    query = gql(query)

    data = client.execute(query, **vars(id=id, name=name))
    return data['actionPage']

@explain_error('fetching all your action pages')
def action_pages_by_org(client):

    # all my pages
    query = """

    query AllMyPages {
    currentUser {
        roles {
        org {
            __typename
            name
            title
            ... on PrivateOrg {
            actionPages {
                __typename
                id name locale thankYouTemplate
                campaign { id externalId name title  }
                ...actionPageStatus
            }
            }
        }
        }
    }
    }
    """ + actionPageStatus

    query = gql(query)

    data = client.execute(query)

    roles = data['currentUser']['roles']


    orgs = {role['org']['name']: role['org'] for role in roles}
    pages = {
        role['org']['name']: sorted(
            [page for page in role['org']['actionPages']],
            key=operator.itemgetter('id')
        )
        for role in roles}

    return orgs, pages


def format(page):
    """
    Formats page into

    somename.com/en (123, 9910) locale: en_IE
    """

    name = f"!{page['name']}"
    ids = page['id']
    locale = "locale: " + page['locale']

    if '__typename' in page and page['__typename'] == 'PrivateActionPage':
        details = ''

        status = page['status']
        if status == 'ACTIVE':
            status = R(status)

        details += f"|{status}"

        if page['thankYouTemplate']:
            details += '|tmpl: ' + page['thankYouTemplate']

        if page['extraSupporters']:
            details += '|extra: ' + str(page['extraSupporters'])

    return w(f"{ids:<4} ") + rainbow(f"{name}|{locale}|{details}")

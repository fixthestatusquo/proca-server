#!/usr/bin/env python3


import click
import operator
from subprocess import Popen, PIPE

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier, validate_locale
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql
import json
import time

from termcolor import colored, cprint

@click.command("page")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-l', '--list', 'ls', is_flag=True, help="List action pages")
@click.option('-o', '--org', 'org', help="List for org")
@click.option('-c', '--campaign', help="Only list for campaign")
@click.option('-f', '--config', type=click.File('w'))
@click.option('-F', '--campaign-config', type=click.File('w'))
@click.pass_obj
def show(ctx, id, name, identifier, ls, org, campaign, config, campaign_config):
    """
    Display action page or list of pages.
    """
    if ls:
        if org is None:
            raise click.UsageError("Please provide org to list pages")
        pages = action_pages_by_org(ctx.client, org)
        for p in pages:
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
@click.pass_obj
def add(ctx, locale, name, org, campaign):
    """
    Add new action page.
    """
    print(rainbow(f"{locale}|!{name}|{campaign}"))

    ap = add_action_page(ctx.client, name=name, locale=locale, org=org, campaign=campaign)


@click.command("page:delete")
@click.argument('identifier', default=None, required=False)
@id_options
@click.pass_obj
def delete(ctx, identifier, id, name):
    """
    Delete the action page. It is impossible to detele an Action Page with action/personal data collected.
    """
    id, name = guess_identifier(id, name, identifier)

    page = fetch_action_page(ctx.client, id, name)

    t = "Delete " + rainbow(format(page))
    really_delete = click.confirm(t)

    if really_delete:
        status = delete_action_page(ctx.client, page['id'])
        if status == 'SUCCESS':
            print("✨ Deleted.")
        else:
            print(f"status {status}")
    else:
        print("😌 Phew!")


@click.command("page:set")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-N', '--rename')
@click.option('-l', '--locale')
@click.option('-x', '--extra', type=int)
@click.option('-d/-D', '--deliver/--no-deliver', default=None)
@click.option('-t', '--template', help="enable thank you email with this template")
@click.option('-T', '--no-thankyou', help="disable thank you emal", is_flag=True)
@click.option('-f', '--config', type=click.File('r'))
@click.pass_obj
def set(ctx, id, name, identifier, rename, locale, extra, deliver, template, no_thankyou, config):
    """
    Update settings of action page
    """
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
    if no_thankyou:
        input["thankYouTemplate"] = None
    if config:
        config_json = config.read()
        input["config"] = config_json

    update_action_page(ctx.client, id, name, input)


@click.command("page:watch")
@click.option('-o', '--org', 'org', help="List for org")
@click.option('-A', '--all', is_flag=True, help="Watch all pages")
@click.option('-c', '--campaign', help="Just campaign")
@click.option('-p', '--parallel', default=1, help="How many run in parallel")
@click.argument('cmd', nargs=-1)
@click.pass_obj
def watch(ctx, org, all, campaign, parallel, cmd):
    pipes = []
    ws = ctx.websocket_client
    query = """
    subscription ActionPageUpserted($org: String) {
      actionPageUpserted(orgName: $org) {
         ...actionPageData
        campaign { ...campaignData }
        org { name title }
      }
    }
    """ + actionPageData + campaignData
    query = gql(query)

    def close_pipes():
        nonlocal pipes
        pipes = [p for p in pipes if p.poll() is None] # is none when still running

    if all:
        org = None

    for page in ws.subscribe(query, **vars(org=org)):
        page = page['actionPageUpserted']

        if campaign and page['campaign']['name'] != campaign:
            continue

        page['config'] = json.loads(page['config'])
        page['campaign']['config'] = json.loads(page['campaign']['config'])

        close_pipes()
        while len(pipes) >= parallel:
            time.sleep(0.5)
            close_pipes()

        print(format(page))

        p = Popen(cmd, stdin=PIPE, text=True)
        json.dump(page, p.stdin)
        p.stdin.close()
        pipes.append(p)




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

@explain_error('deleting action page')
def delete_action_page(client, id):
    query = """
    mutation delete($id: Int!) {
      deleteActionPage(id: $id)
    }
    """
    query = gql(query)
    data = client.execute(query, **vars(id=id))
    return data['deleteActionPage']


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
def action_pages_by_org(client, org):
    # all my pages
    query = """
    query OrgPages($org: String!) {
        org(name: $org) {
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
    """ + actionPageStatus

    query = gql(query)

    data = client.execute(query, **vars(org=org))

    return data['org']['actionPages']


def format(page, show_campaign=True, show_org=True):
    """
    Formats page into

    somename.com/en (123, 9910) locale: en_IE
    """

    name_prefix=''
    if show_org and 'org' in page:
        name_prefix = f"|!{page['org']['name']}"

    if show_campaign:
        name_prefix += f"|!{page['campaign']['name']}"

    if name_prefix:
        name = f"{name_prefix}|!⬣ {page['name']}"
    else:
        name = f"!{page['name']}"

    ids = page['id']
    locale = "locale: " + page['locale']

    details = ''
    if '__typename' in page and page['__typename'] == 'PrivateActionPage':
        status = page['status']
        if status == 'ACTIVE':
            status = R(status)

        details += f"|{status}"

        if page['thankYouTemplate']:
            details += '|tmpl: ' + page['thankYouTemplate']

        if page['extraSupporters']:
            details += '|extra: ' + str(page['extraSupporters'])

    return bold(f"{ids:<4} ") + rainbow(f"{name}|{locale}|{details}")

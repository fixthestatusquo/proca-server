#!/usr/bin/env python3


import click
import operator

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.context import pass_context
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier
from proca.query import *
from yaspin import yaspin
from gql import gql

from termcolor import colored, cprint

@click.command("page")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-l', '--list', 'ls', is_flag=True, help="List action pages")
@click.option('-o', '--org', 'org', help="Only list for org")
@click.option('-c', '--config', type=click.File('w'))
@click.option('-C', '--campaign-config', type=click.File('w'))
@pass_context
def show(ctx, id, name, identifier, ls, org, config, campaign_config):
    if ls:
        orgs, pages = action_pages_by_org(ctx.client)
        for oname, org_pages in pages.items():
            if org and oname != org:
                continue

            odata = orgs[oname]

            out = colored(odata['title'], color='white', attrs=['bold']) + colored(f" {odata['name']}", attrs=['bold'], color='yellow')
            print(out)

            for p in org_pages:
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


@click.command("page:set")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-N', '--rename')
@click.option('-l', '--locale')
@click.option('-x', '--extra', type=int)
@click.option('-d/-D', '--deliver/--no-deliver', default=None)
@click.option('-t', '--template')
@click.option('-c', '--config', type=click.File('r'))
@pass_context
def set(ctx, id, name, identifier, rename, locale, extra, deliver, template, config):
    id, name = guess_identifier(id, name, identifier)

    print(id, name, deliver)


@explain_error('fetching action page')
def fetch_action_page(client, id, name, public=False):
    vars = {}
    if id:
        vars['id'] = id
    if name:
        vars['name'] = name

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

    data = client.execute(query, variable_values=vars)
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

    name = colored(page['name'], color='white')
    ids = colored(page['id'], color='yellow')
    locale = colored("locale: ", color='green') + page['locale']

    if '__typename' in page and page['__typename'] == 'PrivateActionPage':
        details = ''

        status = page['status']
        if status == 'ACTIVE':
            status = colored(status, color='red', attrs=['bold'])
        elif status == 'STANDBY':
            status = colored(status, color='white')
        elif status == 'STALLED':
            pass

        details += ' ' + status

        if page['thankYouTemplate']:
            details += colored(' tmpl: ', color='blue') + page['thankYouTemplate']

        if page['extraSupporters']:
            details += colored('extra: ', color='red') + str(page['extraSupporters'])

    return f"{name} ({ids}) {locale}{details}"

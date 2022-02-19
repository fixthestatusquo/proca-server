#!/usr/bin/env python3


import click

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
@pass_context
def show(ctx, id, name, identifier, ls):
    if ls:
        orgs, pages = action_pages_by_org(ctx.client)
        for oname, org_pages in pages.items():
            org = orgs[oname]

            out = colored(org['title'], color='white', attrs=['bold']) + colored(f" {org['name']}", attrs=['bold'], color='yellow')
            print(out)

            for p in org_pages:
                print(format(p))
        return

    id, name = guess_identifier(id, name, identifier)

    page = fetch_action_page(ctx.client, id, name)
    print(format(page))


def fetch_action_page(client, id, name):
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
        actionPageStatus
        }
    }
    """ + actionPageData + campaignData + actionPageStatus

    query = gql(query)

    data = client.execute(query, variable_values=vars)
    return data['actionPage']


def action_pages_by_org(client):

    # all my pages
    query = """

    query AllMyPages {
    currentUser {
        roles {
        org {
            name
            title
            ... on PrivateOrg {
            actionPages {
                id name locale
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
    pages = {role['org']['name']: [page for page in role['org']['actionPages']] for role in roles}


    return orgs, pages


def format(page):
    """
    Formats page into

    somename.com/en (123, 9910) locale: en_IE
    """

    name = colored(page['name'], color='white')
    ids = colored(page['id'], color='yellow')
    locale = colored("locale: ", color='green') + page['locale']

    status = page['status']
    if status == 'ACTIVE':
        status = colored(status, color='red', attrs=['bold'])
    elif status == 'STANDBY':
        status = colored(status, color='white')
    elif status == 'STALLED':
        pass


    return f"{name} ({ids}) {locale} {status}"

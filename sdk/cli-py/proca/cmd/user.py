#!/usr/bin/env python3


import click

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail
from proca.friendly import explain_error
from proca.theme import *
from proca.query import vars
from yaspin import yaspin
from gql import gql
from base64 import b64encode

@click.command()
@click.pass_obj
def me(ctx):
    """
    Display information about current user.
    """
    with yaspin(spinner, text="Who am I?"):
        user = current_user(ctx.client)

    adm = user['isAdmin'] and Y(" ADMIN") or ''
    eml = R(user['email'])

    print(eml + adm)

    for role in user['roles']:
        t = B("`- ") + bold(role['org']['title'])
        r = role['role']
        n = role['org']['name']

        print(rainbow(f"{t}|as|{r}|⬢ {n}"))


@click.command("user")
@click.option('-l', '--list', 'ls', is_flag=True, help="List org users")
@click.option('-o', '--org', 'org', help="Only list for org")
#@click.option('-c', '--campaign', help="Only list for campaign")
@click.pass_obj
def show(ctx, ls, org):
    """
    Shows user information (now: only list of org members)
    """
    if ls:
        users = list_org_users(ctx.client, org)
        for u in users:
            r = u['role']
            e = u['email']
            print(rainbow(f"{e}|as|{r}"))



@explain_error("listing org users")
def list_org_users(client, org):
    query = gql("""
    query orgUsers($name: String!) {
      org(name: $name) {
        ... on PrivateOrg {
        users { email role joinedAt }
        }
      }
    }
    """)

    data = client.execute(query, **vars(name=org))
    return data['org']['users']

@explain_error("fetching your user information")
def current_user(client):
    query = gql("""
    query user {
        currentUser {
            email
            isAdmin
            roles {
                role
                org { name title }
            }
        }
    }
    """)
    data = client.execute(query)
    return data['currentUser']

@click.command("me:token")
@click.pass_obj
def token(ctx):
    """
    Display Authorization token (copy to GraphiQL)
    """
    conf = Config[ctx.server_section]

    try:
        t = f"{conf['user']}:{conf['password']}"
        t = b64encode(bytes(t, 'utf8')).decode('utf8')
        print(rainbow(f"Basic|{t}"))
    except KeyError:
        print(R("basic auth not configured"))

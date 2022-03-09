#!/usr/bin/env python3


import click

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.context import pass_context
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail
from proca.friendly import explain_error
from proca.theme import *
from yaspin import yaspin
from gql import gql
from base64 import b64encode

from termcolor import colored, cprint

@click.command()
@pass_context
def me(ctx):
    user = current_user(ctx.client)

    cprint(user['email'], color='red', attrs=['bold'])

    for role in user['roles']:
        cprint(f"`- ", color='blue', attrs=['bold'], end='')

        t = colored(role['org']['title'], attrs=['bold'], color='white')
        r = role['role']
        n = role['org']['name']

        print(f"{t} as {r} [{n}]")


@explain_error("fetching your user information")
def current_user(client):
    query = gql("""
    query user {
        currentUser {
            email
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
@pass_context
def token(ctx):
    conf = Config[ctx.server_section]

    try:
        t = f"{conf['user']}:{conf['password']}"
        t = b64encode(bytes(t, 'utf8')).decode('utf8')
        print(rainbow(f"Basic|{t}"))
    except KeyError:
        print(R("basic auth not configured"))

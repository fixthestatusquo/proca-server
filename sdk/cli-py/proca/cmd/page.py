#!/usr/bin/env python3


import click

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier
from proca.query import fragments
from yaspin import yaspin
from gql import gql

from termcolor import colored, cprint


@click.command("page")
@click.argument('identifier', default=None, required=False)
@id_options
def show(id, name, identifier):
    id, name = guess_identifier(id, name, identifier)



def fetch_action_page(client, id, name):
    vars = {}
    if id:
        vars['id'] = id
    if name:
        vars['name'] = name

    query = qgl("""
    %(actionPageData)s %(campaignData)s

    query fetchActionPage($id: Int, $name: String){
        actionPage(id: $id, name: $name) {
        ...actionPageData
        campaign { ...campaignData }
        }
    }
    """.format(fragments))

    data = client.execute(query, variable_values=vars)

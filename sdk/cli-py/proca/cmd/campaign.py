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

@click.command("campaign")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-I', '--external-id', help="External ID")
@click.option('-l', '--list', 'ls', is_flag=True, help="List campaigns")
@click.option('-o', '--org', 'org', help="Only list for org")
@pass_context
def show(ctx, id, name, external_id, identifier, ls, org, config, campaign_config):



    id, name = guess_identifier(id, name, identifier)

#!/usr/bin/env python3

import click

import proca.config
from proca.context import pass_context
from proca.util import log
import proca.cmd.server
import proca.cmd.user
import proca.cmd.action
import proca.cmd.page
import proca.cmd.campaign
import proca.cmd.service
import proca.cmd.org


HELP = """
       ,,\\\\\\,,
      ,\\\\\\\\\\\
     ▲▲▲▲▲▲\\\\\\\\  FIX THE STATUS QUO
    ▲▲▲▲▲▲▲▲\\\\\\`  PROCA COMMAND TOOL
    ▼▼▼▼▼▼▼▼\\\\\`
     ▼▼▼▼▼▼\\\^``    https://proca.app

    Proca CLI is a command line Proca API client. It is a Proca dashboard in your shell 🐚.
"""


@click.group(help=HELP)
@click.option('-@', '--server', default=None, help="Which server to connect to (default: api.proca.app)")
@pass_context
def cli(ctx, server):
    proca.cmd.server.verify_server_exists(server)
    ctx.server_section = proca.config.server_section(server)

cli.add_command(proca.cmd.server.server_list)
cli.add_command(proca.cmd.server.server_add)
cli.add_command(proca.cmd.server.server_set)
cli.add_command(proca.cmd.server.server_delete)
cli.add_command(proca.cmd.user.me)
cli.add_command(proca.cmd.user.token)
cli.add_command(proca.cmd.page.show)
cli.add_command(proca.cmd.page.set)
cli.add_command(proca.cmd.page.add)
cli.add_command(proca.cmd.action.action)
cli.add_command(proca.cmd.campaign.show)
cli.add_command(proca.cmd.service.set)
cli.add_command(proca.cmd.org.show)
cli.add_command(proca.cmd.org.add)
cli.add_command(proca.cmd.org.set)

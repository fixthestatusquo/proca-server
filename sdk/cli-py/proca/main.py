#!/usr/bin/env python3

import click

import proca.config
from proca.context import pass_context
from proca.util import log
import proca.cmd.server
import proca.cmd.user
import proca.cmd.action
import proca.cmd.page



@click.group()
@click.option('-@', '--server', default=None, help="Which server to connect to (default: api.proca.app)")
@pass_context
def cli(ctx, server):
    """
    Proca CLI is a command line Proca API client. It is a Proca dashboard in your shell 🐚.
    """
    proca.cmd.server.verify_server_exists(server)
    ctx.server_section = proca.config.server_section(server)

cli.add_command(proca.cmd.server.server_list)
cli.add_command(proca.cmd.server.server_add)
cli.add_command(proca.cmd.server.server_set)
cli.add_command(proca.cmd.server.server_delete)
cli.add_command(proca.cmd.user.me)
cli.add_command(proca.cmd.page.show)
cli.add_command(proca.cmd.page.set)
cli.add_command(proca.cmd.page.add)
cli.add_command(proca.cmd.action.action)

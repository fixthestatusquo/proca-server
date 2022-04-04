#!/usr/bin/env python3

import click

import proca.config
from proca.context import CliContext
from proca.util import log
import proca.cmd.server
import proca.cmd.user
import proca.cmd.action
import proca.cmd.page
import proca.cmd.campaign
import proca.cmd.service
import proca.cmd.org




@click.group()
@click.option('-@', '--server', default='DEFAULT', help="Which server to connect to (default: api.proca.app)")
@click.pass_context
def cli(ctx, server):
    """
    Proca CLI is a command line Proca API client. It is a Proca dashboard in your shell 🐚.
    """

    proca.config.load()

    # validate input
    proca.cmd.server.verify_server_exists(server)

    # initialize context
    cc = CliContext(server)

    ctx.obj = cc
    ctx.default_map = cc.default_map

    # XXX set defaults map!!!
    # for:
    # org paramter
    # → https://click.palletsprojects.com/en/5.x/commands/

cli.add_command(proca.cmd.server.server_list)
cli.add_command(proca.cmd.server.server_add)
cli.add_command(proca.cmd.server.server_set)
cli.add_command(proca.cmd.server.server_delete)
cli.add_command(proca.cmd.user.me)
cli.add_command(proca.cmd.user.token)
cli.add_command(proca.cmd.user.show)
cli.add_command(proca.cmd.page.show)
cli.add_command(proca.cmd.page.set)
cli.add_command(proca.cmd.page.add)
cli.add_command(proca.cmd.action.action)
cli.add_command(proca.cmd.campaign.show)
cli.add_command(proca.cmd.campaign.add)
cli.add_command(proca.cmd.campaign.set)
cli.add_command(proca.cmd.service.list)
cli.add_command(proca.cmd.service.set)
cli.add_command(proca.cmd.service.email)
cli.add_command(proca.cmd.org.show)
cli.add_command(proca.cmd.org.add)
cli.add_command(proca.cmd.org.join)
cli.add_command(proca.cmd.org.leave)
cli.add_command(proca.cmd.org.set)

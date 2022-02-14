#!/usr/bin/env python3

import click

import proca.config
from proca.util import log
from proca.cmd.config import server


@click.group()
@click.option('-@', '--server', default=None, help="Which server to connect to (default: api.proca.app)")
@click.pass_context
def cli(ctx, server):
    ctx.ensure_object(dict)

    proca.config.load()
    ctx.obj['server_section'] = proca.config.server_section(server)


cli.add_command(server)

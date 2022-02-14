#!/usr/bin/env python3

import click

from proca.config import Config, add_server_section, server_section, store
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email
from yaspin import yaspin

@click.group()
def server(help="Configure API servers"):
    pass


@server.command(help="Lists API servers")
def list():

    def display_name(name):
        x = name.split(":")
        if len(x) > 1:
            return x[1]
        return "(default)"

    l = [
        (
            sn,
            Config.get(sn, "url")
        )
        for sn in Config.sections()
        if sn.startswith("server")
    ]

    for name, url in l:
        print(f"{display_name(name)}: {url}")


@server.command()
@click.option('-h', '--host', help="API url", prompt="API url", required=True)
@click.option('-u', '--user', help="User name (email)", prompt="User name", callback=validate_email)
@click.option('-p', '--password', help="Your password", prompt="Password", hide_input=True, confirmation_prompt=True)
@click.option('-s', '--socket', help="API WebSocket url", prompt="API WebSocket url", prompt_required=False, default=None)
@click.argument('name')
def add(host, user, password, name, socket):
    """
    Add a new server with provided name. The name is just for you - so you
    can select it easily, eg. `proca -@ stg pages` will use the stg server name.
    This server connection information will be stored under [server:stg] section
    in proca CLI config.
    """
    sn = server_section(name)

    add_server_section(sn)

    verify_host(host)

    Config.set(sn, "url", host)

    if socket is not None:
        Config.set(sn, "ws_url", socket)

    if user and password:
        Config.set(sn, "user", user)
        Config.set(sn, "password", password)

    store()









def verify_host(url):
    "Verify the given host/url can be used for API calls"

    e = Endpoint(url)

    with yaspin() as ya:
        if not e.check_http_url():
            ya.fail(f"🚇 that url does not seem to lead to the API. Tried: {e.http_url}")
            raise click.Abort
        else:
            ya.ok(f"🍦 API url looks ok - {e.http_url}")

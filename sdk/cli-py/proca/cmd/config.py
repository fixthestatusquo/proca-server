#!/usr/bin/env python3

import click

from proca.config import Config, add_server_section, server_section, store
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail
from yaspin import yaspin

@click.group()
@click.pass_context
def server(ctx):
    """
    Configure API servers that you want to talk to.
    """

    if ctx.invoked_subcommand is None:
        list()
    else:
        pass


def list_server_sections(show_default=True):
    def display_name(name):
        x = name.split(":")
        if len(x) > 1:
            return x[1]
        return "(default)"

    l = [
        (
            display_name(sn),
            Config.get(sn, "url"),
            Config.get(sn, "ws_url", fallback=None),
            Config.get(sn, "user", fallback=None)
        )
        for sn in Config.sections()
        if sn.startswith("server") and (show_default == True or sn != "server")
    ]
    return l


@server.command()
def list():
    """
    List API servers
    """


    for name, url, ws_url, user in list_server_sections():
        a = f"{name}: {url}"

        if ws_url:
            a += f" [WebSocket: {ws_url}]"
        if user:
            a += f" as {user}"

        print(a)


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


@server.command()
@click.option('-h', '--host', help="API url")
@click.option('-u', '--user', help="User name (email)", callback=validate_email)
@click.option('-p', '--password', help="Your password")
@click.option('-s', '--socket', help="API WebSocket url", default=None)
@click.argument('name', default=None)
def set(host, user, password, name, socket):
    "Set server options"

    verify_server_exists(name)

    sn = server_section(name)

    if host:
        Config.set(sn, "url", host)
        verify_host(host)

    if socket:
        Config.set(sn, "ws_url", socket)

    if user:
        Config.set(sn, "user", user)

    if password:
        Config.set(sn, "password", password)

    store()

@server.command()
@click.argument('name')
def delete(name):
    "Delete server"

    verify_server_exists(name)

    sn = server_section(name)

    Config.remove_section(sn)

    store()


def verify_server_exists(name):
    # ok for default
    if name is None:
        return

    if not Config.has_section(server_section(name)):
        hint = ', '.join([n for (n, _, _, _) in list_server_sections(False)])
        if hint:
            hint = " Your servers: " + hint
        else:
            hint = " You have no defined servers"
        raise click.BadParameter(f"❔ No server {name}.{hint}", param_hint="name")


def verify_host(url):
    "Verify the given host/url can be used for API calls"

    e = Endpoint(url)

    with yaspin() as ya:
        if not e.check_http_url():
            ya.fail(f"Error: 🚇 that url does not seem to lead to the API. Tried: {e.http_url}")
            raise click.Abort
        else:
            ya.ok(f"🍦 API url looks ok - {e.http_url}")

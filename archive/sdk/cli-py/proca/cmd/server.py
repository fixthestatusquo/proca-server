#!/usr/bin/env python3

import click

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail
from proca.theme import *
from proca.cmd.user import current_user, reset_token
from yaspin import yaspin
from termcolor import colored


def list_server_sections(show_default=True):
    l = [
        (
            sn.split(":")[1],
            Config.get(sn, "url"),
            Config.get(sn, "ws_url", fallback=None),
            Config.get(sn, "user", fallback=None),
            Config.get(sn, "org", fallback=None)
        )
        for sn in Config.sections()
        if sn.startswith("server") and (show_default == True or sn != "server:DEFAULT")
    ]
    return l


@click.command("server")
def server_list():
    """
    List API servers
    """

    for name, url, ws_url, user, org in list_server_sections():
        a = bold(f"{name}") +  f"|{url}"

        if ws_url:
            a += f"|[WebSocket: {ws_url}]"

        if user:
            a += f"|auth: {user}"

        if org:
            a += f"|org: {org}"

        print(rainbow(a))


@click.command("server:add")
@click.option('-h', '--host', help="API url", prompt="API url", required=True)
@click.option('-t', '--token', help="API token")
@click.option('-u', '--user', help="User name (email)", callback=validate_email)
@click.option('-p', '--password', help="Your password")
@click.option('--public/--no-public', '-P', default=False, help="Public access (do not authenticate)")
@click.option('-s', '--socket', help="API WebSocket url", prompt="API WebSocket url", prompt_required=False, default=None)
@click.argument('name')
def server_add(host, token, user, password, public, socket, name):
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


    if not public:
        if token is None:
            token =  click.prompt("API token", hide_input=True, default='')
        setup_token_auth(sn, token, user, password)

    else:
        section = Config[sn]
        del section['user']
        del section['password']
        del section['token']

    store()


def fetch_user_for_token(server_section):
    client = make_client(server_section)
    return current_user(client, roles=False)

@click.command("server:setup")
@click.option('-u', '--user', help="User name (email)", callback=validate_email)
@click.option('-p', '--password', help="Your password")
@click.option('-t', '--token', help="API token")
@click.option('--public/--no-public', '-P', default=False, help="Public access (do not authenticate)")
def server_setup(user, password, token, public):
    """
    Set up access to official proca API server.

    Provide token if you want auth, or be asked for user/pass to create a new
    token. If the token exists on server, you will be warned about overwriting
    it.
    """
    sn = server_section('DEFAULT')

    if not public:
        if token is None:
            token =  click.prompt("API token", hide_input=True, default='')
        setup_token_auth(sn, token, user, password)

    else:
        section = Config[sn]
        if 'user' in section:
            del section['user']
        if 'password' in section:
            del section['password']
        if 'token' in section:
            del section['token']

    store()

@click.command("server:set")
@click.option('-h', '--host', help="API url")
@click.option('-u', '--user', help="User name (email)", callback=validate_email)
@click.option('-p', '--password', help="Your password")
@click.option('-P', '--password-prompt', is_flag=True, help="Prompt for Your password")
@click.option('-t', '--token', help="Your API key")
@click.option('-T', '--token-prompt', is_flag=True, help="Prompt for Your API key")
@click.option('-s', '--socket', help="API WebSocket url", default=None)
@click.option('-o', '--org', help="Set a default organisation name")
@click.argument('name', default=None, required=False)
def server_set(host, user, password, password_prompt, token, token_prompt, socket, org, name):
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

    if password_prompt:
        password = click.prompt("Password", hide_input=True, confirmation_prompt=True)

    if password:
        Config.set(sn, "password", password)

    if token_prompt:
        token = click.prompt("API token", hide_input=True)

    if token:
        Config.set(sn, "token", token)

    if org:
        Config.set(sn, "org", org)

    store()


def setup_token_auth(config_section, token, user, password):
    config = Config[config_section]

    if token:
        config['token'] = token
        client = make_client(config_section)
        user = current_user(client, roles=False)
        config['user'] = user['email']
        return True

    if user is None:
        user = click.prompt("Username (email)")
    if password is None:
        password = click.prompt("Password", hide_input=True, confirmation_prompt=True)

    config['user'] = user
    config['password'] = password

    client = make_client(config_section)
    user = current_user(client, roles=False)

    if user['apiToken']:
        exp = user["apiToken"]["expiresAt"]
        reset_it = click.confirm(f'Warning, a token exists for this account (expiry: {exp}), reset?')
        if not reset_it:
            raise click.Abort("Aborting the setup")

    token = reset_token(client)
    config['token'] = token
    config['user'] = user['email']

    del config['password']

    return True



@click.command("server:delete")
@click.argument('name')
def server_delete(name):
    "Delete server"

    verify_server_exists(name)

    sn = server_section(name)

    Config.remove_section(sn)

    store()


def verify_server_exists(name):
    if not Config.has_section(server_section(name)):
        hint = ', '.join([n for (n, _, _, _, _) in list_server_sections(False)])
        if hint:
            hint = " Your servers: " + hint
        else:
            hint = " You have no defined servers"
        raise click.BadParameter(f"🤔 No server {name}.{hint}", param_hint="name")


def verify_host(url):
    "Verify the given host/url can be used for API calls"

    e = Endpoint(url)

    with yaspin(spinner) as ya:
        try:
            if not e.check_http_url():
                ya.fail(f"Error: 🚇 that url does not seem to lead to the API. Tried: {e.http_url}")
                raise click.Abort
            else:
                ya.ok(f"🍦 API url looks ok - {e.http_url}")
        except ValueError as err:
            fail(f"🤨 I expected an url, got {err}")

@click.command("token")
@click.pass_obj
def token(ctx):
    """
    Display Authorization header (copy this to Authorization header in GraphiQL)
    """
    conf = Config[ctx.server_section]
    try:
        print(rainbow(f'Bearer|{conf["token"]}'))
    except KeyError:
        print(R("Token auth not configured"))

@click.command("token:reset")
@click.pass_obj
def token_reset(ctx):
    """
    Reset API token
    """
    conf = Config[ctx.server_section]
    username = conf.get('user', None)

    setup_token_auth(ctx.server_section, None, username, None)

    store()

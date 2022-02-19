#!/usr/bin/env python3

"""Proca CLI configuration

Except for a few cases (secrets) we do not use ENV variables (they are confusing
when you want to call different instances for example, or change org).

We use standard user config directory to store the proca.conf file

## Config structure

[server]
url = "..."

[server:stg]
url = "..."


"""

import proca.client

import appdirs
from os import path
from configparser import ConfigParser, DuplicateSectionError, DuplicateOptionError

from proca.friendly import explain_error

Config = ConfigParser()

config_dirname = appdirs.user_config_dir(appname="proca")
config_filename = path.join(config_dirname, "proca.conf")

def server_section(name=None):
    if name is None:
       return "server"
    return "server:" + name


@explain_error("adding server configuration")
def add_server_section(name):
    Config.add_section(name)


def initialize():
    "Initialize the Config"

    def default_server():
        sn = server_section()
        try:
            add_server_section(sn)
        except DuplicateSectionError:
            # fine
            pass

        Config.set(sn, "url", "https://api.proca.app")

    default_server()
    store()



@explain_error("loading proca config at %(fn)", fn=config_filename)
def load():
    "Load the Config"

    try:
        with open(config_filename, "r") as fd:
            Config.read_file(fd)
    except FileNotFoundError:
        # lets create it!
        initialize()
    return Config

@explain_error("writing proca config to %(fn)s", fn=config_filename)
def store():
    with open(config_filename, "w") as fd:
        Config.write(fd)

def make_client(sn, ws=False):
    server = Config[sn]

    endpoint = proca.client.Endpoint(server['url'], server.get('ws_url', None))

    auth = {}
    try:
        auth['user'] = server['user']
        auth['password'] = server['password']
    except KeyError:
        auth = None

    if ws:
        return proca.client.ws(endpoint, auth)

    return proca.client.http(endpoint, auth)


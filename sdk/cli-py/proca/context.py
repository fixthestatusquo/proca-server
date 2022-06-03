#!/usr/bin/env python3


import click
from proca.config import make_client, load, server_section, Config

class CliContext:
    """
    The context's obj passed into commands (with @click.pass_obj)

    Remember:
    click.Context
     `-> .obj = proca.context.CliContext

    Sorry if confusing, lacking a better name then Context.
    """
    def __init__(self, server):
        self._client = None
        self._ws_client = None
        self._server_section = None
        self._default_map = {}

        self.server_section = server_section(server)

    @property
    def default_map(self):
        return self._default_map

    @default_map.setter
    def default_map(self, new_map):
        """
        Update map in place because parent click.Context.default_path refers it!
        """
        self._default_map.update(new_map)


    @property
    def server_section(self):
        return self._server_section

    @server_section.setter
    def server_section(self, v):
        self._server_section = v

        if default_org := Config.get(self._server_section, 'org', fallback=None):
            # Put org into default argument for all commands that use it
            cmds = [
                'campaign',
                'campaign:add',
                'page',
                'page:add',
                'service',
                'service:set',
                'service:email',
                'template',
                'template:set',
                'user',
                'key',
                'key:activate',
                'key:gen']
            dm = {c: {'org':  default_org} for c in cmds}

            cmds = ['org', 'org:set']
            dm.update({c: {'name': default_org} for c in cmds})

            self.default_map = dm

    @property
    def client(self):
        if self._client is None:
            self._client = make_client(self.server_section)

        return self._client

    @property
    def websocket_client(self):
        if self._ws_client is None:
            self._ws_client = make_client(self.server_section, ws=True)

        return self._ws_client

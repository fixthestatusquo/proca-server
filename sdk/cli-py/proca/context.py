#!/usr/bin/env python3


import click
from proca.config import make_client, load, server_section

class Context:
    """
    The context object passed into commands
    """
    def __init__(self):
        self._client = None

        self.server_section = server_section(None) # default

        # load config
        load()

    @property
    def client(self):
        if self._client is None:
            self._client = make_client(self.server_section)

        return self._client



pass_context = click.make_pass_decorator(Context, ensure=True)

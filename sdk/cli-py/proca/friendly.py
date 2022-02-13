#!/usr/bin/env python3

"""
Helpers for being user friendly

"""

import yaspin
from proca.util import log
import click


def explain_error(intent, **fmt_params):
    """
    Decorate function that could throw an error.
    Pass string with %(foo)s strings and their values in fmt_params
    """
    def decor(func):
        def explainer_wrap(*args, **kw):
            try:
                func(*args, **kw)
            except FileNotFoundError as e:
                log.error("👻 could not find file: " + intent, fmt_params)
                raise click.Abort(e)
            except IsADirectoryError as e:
                log.error("🤨 I expected a file, when "+intent+" but that is a directory", fmt_params)

        return explainer_wrap
    return decor

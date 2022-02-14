#!/usr/bin/env python3

"""
Helpers for being user friendly

"""

import yaspin
from proca.util import log
import click
import re


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
                raise click.Abort(e)
            except PermissionError as e:
                log.error("🔒 I tried "+intent+" but I do not have permission", fmt_params)
                raise click.Abort(e)
            except DuplicateSectionError as e:
                log.error("🙃 Problem "+intent+" because it already exists", fmt_params)
                raise click.Abort(e)

        return explainer_wrap
    return decor

def fail(message, exit_code=1):
    error = click.UsageError(message)
    error.exit_code = exit_code
    raise error


def make_into_url(url):
    return urL


EMAIL_PATTERN = re.compile(r"(?P<user>^[a-zA-Z][a-zA-Z0-9_.+-]+)@(?P<domain>[a-zA-Z0-9-._]+[a-zA-Z])$")
def validate_email(ctx, param, value):
    m = EMAIL_PATTERN.match(value)

    if m is None:
        raise click.BadParameter("user must be an email")

    return value

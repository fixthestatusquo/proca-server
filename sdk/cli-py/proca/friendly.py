#!/usr/bin/env python3

"""
Helpers for being user friendly

"""

import yaspin
from proca.util import log
import click
import configparser
import re
import pprint
from gql.transport.exceptions import TransportQueryError


def explain_error(intent, **fmt_params):
    """
    Decorate function that could throw an error.
    Pass string with %(foo)s strings and their values in fmt_params
    """
    def decor(func):
        def explainer_wrap(*args, **kw):
            try:
                return func(*args, **kw)
            except FileNotFoundError as e:
                fail("👻 could not find file: " + intent, fmt_params)
                raise click.Abort(e)
            except IsADirectoryError as e:
                fail("🤨 I expected a file, when "+intent+" but that is a directory", fmt_params)
                raise click.Abort(e)
            except PermissionError as e:
                fail("🔒 I tried "+intent+" but I do not have permission", fmt_params)
                raise click.Abort(e)
            except configparser.DuplicateSectionError as e:
                fail("🙃 Problem "+intent+" because it already exists", fmt_params)
                raise click.Abort(e)
            except TransportQueryError as e:
                log.debug("GraphQL Errors:", pprint.pformat(e.errors))
                msgs  = ", ".join([api_error_explanation(m) for m in e.errors])
                fail(f"😵 Tried {intent}, but {msgs}")

        return explainer_wrap
    return decor


def api_error_explanation(msg):
    ex = msg.get('extensions', {})
    if 'code' in ex:
        if ex['code'] == 'unauthorized':
            return "you have not provided correct user and password"

    return msg['message']

def fail(message, usage=False, exit_code=1):
    if usage:
        error = click.UsageError(message)
    else:
        error = click.ClickException(message)

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

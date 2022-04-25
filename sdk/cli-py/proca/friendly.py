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
from asyncio.exceptions import TimeoutError
from aiohttp.client_exceptions import ClientOSError

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
            except TimeoutError as e:
                log.debug("Timeout error", e)
                fail(f"👎 Connection to server timed out when {intent}")
            except ClientOSError as e:
                log.debug("Network error", pprint.pformat(e))
                fail(f"👎 Connection to server broke while {intent}")

        return explainer_wrap
    return decor


def api_error_explanation(msg):
    ex = msg.get('extensions', {})
    if 'path' in msg:
        path = 'at ' + '.'.join(msg['path'])
    else:
        path = ''

    if 'code' in ex:
        if ex['code'] == 'unauthorized':
            return f"you have not provided correct credentials"
        elif ex['code'] == 'bad_arg':
            return f"you have given wrong arguments for {path}: {msg['message']}"
        else:
            return f"server said: {ex['code']} - {msg['message']} {path}"

    return f"{path}: {msg['message']}"

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
    if value is None:
        return value

    m = EMAIL_PATTERN.match(value)

    if m is None:
        raise click.BadParameter("user must be an email")

    return value

LOCALE_PATTERN = re.compile(r"^[a-z]{2}(_[A-Z]{2})?$")
def validate_locale(ctx, param, value):
    if value is None:
        return value

    m = LOCALE_PATTERN.match(value)
    if m is None:
        raise click.BadParameter("locale must be language code (en) or language+region code (en_IE)")

    return value




def id_options(fn):
    """
    Adds options to pass different id/name/external ids to the command.
    XXX - add uuid later
    """

    fn = click.option("-n", "--name", type=str, help="short name")(fn)
    fn = click.option("-i", "--id", type=int, help="numerical id")(fn)

    return fn


def guess_identifier(id, name, something):
    pv = len([x for x in [id, name, something] if x is None])
    if pv != 2:
        raise click.UsageError(f"You must specify identifier only in one of three ways: 1) -i 123 2) -n somename 3) 123 or somename as argument.")

    if id is not None:
        return id, None
    if name is not None:
        return None, name
    try:
        return int(something), None
    except ValueError:
        return None, something

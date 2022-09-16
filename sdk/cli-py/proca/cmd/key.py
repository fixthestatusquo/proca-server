#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
from proca.theme import *
from proca.query import *
import proca.cmd.org
import json


@click.command("key")
@click.option("-o", "--org", required=True, help="Org name")
@click.pass_obj
def list(ctx, org):
    """
    List keys in org
    """
    keys = org_keys(ctx.client, org)

    for key in keys:
        print(format(key))



@click.command("key:gen")
@click.option("-o", "--org", required=True, help="Org name")
@click.option("-n", "--name", required=True, prompt="Key name (for remembering which is which)")
@click.option("-P", "--no-print", is_flag=True, help="Don't print the private part of the key")
@click.pass_obj
def gen(ctx, org, name, no_print):
    """
    Generate a new key
    """

    key = gen_key(ctx.client, org, name)
    # XXX store in keyring!
    print(format(key, show_private=not no_print))


@click.command("key:activate")
@click.option("-o", "--org", required=True, help="Org name")
@click.argument("id", type=int)
@click.pass_obj
def activate(ctx, org, id):
    """
    Activate a key
    """

    res = activate_key(ctx.client, org, id)



@explain_error("getting keys")
def org_keys(client, org):
    query_str = """
    query OrgKeys($org: String!) {
      org(name: $org) {
        keys {
         ...keyData
        }
      }
    }
    """ + keyData

    query_str = gql(query_str)

    data = client.execute(query_str, **vars(org=org))
    return data['org']['keys']


@explain_error("generating new key")
def gen_key(client, org, name):
    query = """
    mutation GenerateKey($org: String!, $name: String!) {
        generateKey(orgName: $org, input: {name: $name}) {
           ...keyPrivData
        }
    }
    """ + keyPrivData
    query = gql(query)

    data = client.execute(query, **vars(org=org, name=name))
    key = data['generateKey']

    return key

@explain_error("activating key")
def activate_key(client, org, id):
    query_str = """
    mutation ActivateKey($org: String!, $id: Int!) {
      activateKey(orgName: $org, id: $id) {
        status
      }
    }
    """

    query_str = gql(query_str)

    data = client.execute(query_str, **vars(org=org, id=id))
    return data['activateKey']['status']

def format(key, show_private=True):
    if key['active']:
        status = R('ACTIVE')
    elif key['expired']:
        status = w('EXPIRED '+key['expiredAt'])
    else:
        status = ''

    private = ''
    if 'private' in key and show_private:
        private = '|' + key['private']
    s = rainbow(f'{key["id"]}|{key["public"]}{private}|{status}|{key["name"]}')
    return s

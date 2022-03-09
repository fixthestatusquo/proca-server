#!/usr/bin/env python3


import click
import operator

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.context import pass_context
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier, validate_locale
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql

from termcolor import colored, cprint

@click.command("campaign")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-I', '--external-id', help="External ID")
@click.option('-l', '--list', 'ls', is_flag=True, help="List campaigns")
@click.option('-o', '--org',  help="Only list for org")
@click.option('-c', '--config', type=click.File('w'))
@pass_context
def show(ctx, id, name, identifier, external_id, ls, org, config):
    if ls:
        if org:
            campaigns = org_campaigns(ctx.client, org)
            for c in campaigns:
                print(format(c))

        else:
            raise click.UsageError("Specify org")

    else:
        id, name = guess_identifier(id, name, identifier)
        c = one_campaign(ctx.client, id, name)
        print(format(c))

        if config:
            config.write(c['config'])


@explain_error("fetching org's campaigns")
def org_campaigns(client, org_name):
    query = gql("""
    query OrgCampaigns($org: String!) {
        org(name: $org) {
            campaigns {
                ...campaignData
                ...mttData
                   targets {id}
            }
        }
    }
    """ + campaignData + mttData)

    data = client.execute(query, **vars(org=org_name))
    return data['org']['campaigns']

@explain_error("fetching a campaigh")
def one_campaign(client, id, name):
    query = gql("""
    query Campaign($id: Int, $name: String) {
        campaign(id: $id, name: $name) {
            ...campaignData
            ...mttData
            targets {id}
        }
    }
    """ + campaignData + mttData)

    data = client.execute(query, **vars(id=id, name=name))
    return data['campaign']

def format(c):
    """
    Format campaign info
    """
    ids = c['id']
    title = c['title']
    name = c['name']

    ex_id = ""
    if c['externalId']:
        ex_id = f"ext: {c['externalId']}"

    try:
        t = c['targets']
        trgts = f"{len(t)} targets"
    except KeyError:
        trgts = ""

    mtt = ''
    if c['mtt']:
        mtt = "{startAt} -> {endAt}".format(**c['mtt'])
        if c['mtt']['testEmail']:
            mtt += " testing to: <{testEmail}>".format(**c['mtt'])
        if c['mtt']['messageTemplate']:
            mtt += " template {messageTemplate}".format(**c['mtt'])
        else:
            mtt += " RAW"


    info = w(f"{ids:<4}") + rainbow(f"!{title}|{name}|{ex_id}|!{trgts}|!{mtt}")
    return info

#!/usr/bin/env python3


import click
import operator

from proca.config import Config, add_server_section, server_section, store, make_client
from proca.util import log
from proca.client import Endpoint
from proca.friendly import validate_email, fail, explain_error, id_options, guess_identifier, validate_locale
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql
from proca.cmd.org import CONTACT_SCHEMA_CHOICE
from datetime import datetime, timedelta

from termcolor import colored, cprint

@click.command("campaign")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-l', '--list', 'ls', is_flag=True, help="List campaigns")
@click.option('-o', '--org', help="Only list for org")
@click.option('-f', '--config', type=click.File('w'))
@click.pass_obj
def show(ctx, id, name, identifier, ls, org, config):
    """
    Show campaign or list campaigns
    """
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

@click.command("campaign:add")
@click.option('-o', '--org', help="organisation", prompt="Organisation")
@click.option('-n', '--name', help="short code-name", prompt="Short code-name of the campaign")
@click.option('-t', '--title', help="title of the campaign", prompt="Title, full name of the campaign")
@click.pass_obj
def add(ctx, org, name, title):
    """
    Add a campaign.
    """
    input = {
        'name': name,
        'title': title
    }

    campaign = add_campaign(ctx.client, org, input)

    print(format(campaign))


@click.command("campaign:set")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-I', '--external-id', type=int, help="External ID")
@click.option('-N', '--rename', help="rename to name")
@click.option('-t', '--title', help="title of the campaign")
@click.option('-S', '--contact-schema', type=CONTACT_SCHEMA_CHOICE)
@click.option('-f', '--config', type=click.File('r'))
@click.pass_obj
def set(ctx, id, name, identifier, external_id, rename, title, contact_schema, config):
    """
    Update campaign settings
    """
    id, name = guess_identifier(id, name, identifier)

    attrs = {}

    if external_id:
        attrs['external_id'] = external_id
    if rename:
        attrs['name'] = rename
    if title:
        attrs['title'] = title
    if contact_schema:
        attrs['contact_schema'] = contact_schema
    if config:
        config_json = config.read()
        attrs["config"] = config_json

    campaign = update_campaign(ctx.client, id, name, attrs)

    print(format(campaign))


MTT_FORMATS=['%Y-%m-%d','%Y-%m-%dT%H:%M:%SZ', '%Y-%m-%dT%H:%M:%S', '%Y-%m-%d %H:%M', '%Y-%m-%d %H:%M:%S']

@click.command("campaign:mtt")
@click.argument('identifier', default=None, required=False)
@id_options
@click.option('-s', '--start', help="start of the drip sending", type=click.DateTime(formats=MTT_FORMATS))
@click.option('-e', '--end', help="end of the drip sending", type=click.DateTime(formats=MTT_FORMATS))
@click.option('-E', '--test-email', help="send testing messages to this email")
@click.option('-D', '--disable', is_flag=True, help="disable MTT")
@click.option('-t', '--template', help="Template name")
@click.option('-T', '--raw', is_flag=True, help="Do not use template (send raw)")
@click.pass_obj
def mtt(ctx, id, name, identifier, start, end, test_email, disable, template, raw):
    """
    Update campaign MTT settings
    """
    #if start is None and end is None and test_email is None:
    #    return

    id, name = guess_identifier(id, name, identifier)

    mtt = {}
    if start:
        if start.hour == 0 and start.minute == 0:
            start += timedelta(hours=9)
        mtt['startAt'] = start.isoformat("T", 'seconds') + 'Z'

    if end:
        if end.hour == 0 and end.minute == 0:
            end += timedelta(hours=18)
        mtt['endAt'] = end.isoformat("T", 'seconds') + 'Z'

    if test_email:
        mtt['testEmail'] = test_email

    if template:
        mtt['messageTemplate'] = template

    if raw:
        mtt['messageTemplate'] = Null

    if disable:
        mtt = None

    campaign = update_campaign(ctx.client, id, name, {'mtt': mtt})

    print(format(campaign))

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
def one_campaign(client, id, name,  with_targets=False, with_stats=False):
    query = gql("""
    query Campaign($id: Int, $name: String) {
        campaign(id: $id, name: $name) {
            ...campaignData
            ...mttData
            ...campaignTargets
            org { name title }
            ...campaignStats
        }
    }
    """
                + campaignData
                + (with_stats and campaignStats or noCampaignStats)
                + (with_targets and campaignTargetAll or campaignTargetIds)
                + mttData)

    data = client.execute(query, **vars(id=id, name=name))
    return data['campaign']

@explain_error("adding a campaign")
def add_campaign(client, org_name, attrs):

    query = """
    mutation AddCampaign($org: String! $input: CampaignInput!) {
      addCampaign(orgName: $org, input: $input) {
        ...campaignData
      }
    }
    """ + campaignData
    query = gql(query)

    data = client.execute(query, **vars(org=org_name, input=attrs))
    return data['addCampaign']

@explain_error("updating a campaign")
def update_campaign(client, id, name, attrs):

    query = """
    mutation UpdateCampaign($id: Int, $name: String, $input: CampaignInput!) {
      updateCampaign(id: $id, name: $name, input: $input) {
        ...campaignData
        ...mttData
        org { name title }
      }
    }
    """ + campaignData + mttData
    query = gql(query)

    data = client.execute(query, **vars(id=id, name=name, input=attrs))
    return data['updateCampaign']

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
    if 'mtt' in c and c['mtt']:
        mtt = "{startAt} -> {endAt}".format(**c['mtt'])
        if c['mtt']['testEmail']:
            mtt += " testing to: <{testEmail}>".format(**c['mtt'])
        if c['mtt']['messageTemplate']:
            mtt += " template {messageTemplate}".format(**c['mtt'])
        else:
            mtt += " RAW"

    cs = c['contactSchema']

    by_org = ''
    if 'org' in c:
        by_org = attr(0) + f" by|{c['org']['name']}"

    info = bold(f"{ids:<4}") + rainbow(f"!{title}{by_org}|⬢ {name}|{ex_id}|{cs}|!{trgts}|!{mtt}")
    return info

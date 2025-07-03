#!/usr/bin/env python3


from gql import gql
import os
import click
from proca.config import make_client
from proca.friendly import *
from proca.theme import *
from proca.query import *
import proca.cmd.org
import json

@click.command("template")
@click.option("-o", "--org", required=True, help="Org name")
@click.pass_obj
def list(ctx, org):
    """
    List services in org
    """
    tl = list_templates(ctx.client, org)
    for t in tl:
        print(t)



@click.command("template:set")
@click.option('-o', '--org', help="organisation", prompt="Organisation")
@click.option('-n', '--name', help="name", prompt="name")
@click.option('-l', '--locale', help="locale", prompt="locale", callback=validate_locale)
@click.option('-s', '--subject', help="subject")
@click.option('-h', '--html', help="HTML body", type=click.File('r'))
@click.option('-t', '--text', help="text body", type=click.File('r'))
@click.pass_obj
def set(ctx, org, name, locale, subject, html, text):

    template = {
        'name': name, 'locale': locale
    }
    if subject:
        if os.path.isfile(subject):
            template["subject"] = open(subject).read()
        else:
            template['subject'] = subject
    if html:
        template['html'] = html.read()
    if text:
        template['text'] = text.read()

    upsert_template(ctx.client, org, template)



@explain_error("Fetching template list")
def list_templates(client, org):
    query = """
    query ListTemplates($org:String!){
        org(name:$org){
            processing {emailTemplates}
        }
    }
    """
    query = gql(query)

    data = client.execute(query, **vars(org=org))

    return data['org']['processing']['emailTemplates']


@explain_error("Setting template")
def upsert_template(client, org, template):
    query = """
    mutation UpsertTemplate($org:String!, $template:EmailTemplateInput!) {
        upsertTemplate(orgName:$org, input:$template)
    }
    """
    query = gql(query)


    data = client.execute(query, **vars(org=org, template=template))

    return data['upsertTemplate'] == 'SUCCESS'

#!/usr/bin/env python3


import click

from proca.context import pass_context
from proca.friendly import explain_error
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql

from termcolor import colored, cprint

@click.command("org")
@click.argument('name', required=True)
@click.option('-f', '--config', type=click.File('w'))
@pass_context
def show(ctx, name, config):
    org = get_org(ctx.client, name)

    if config:
        config.write(org['config'])

    print(format(org))

@click.command("org:add")
@click.argument('name', required=True)
@click.argument('title', required=True)
@pass_context
def add(ctx, name, title):
    org = add_org(ctx.client, name, title)

    print(rainbow(f"added|{org['name']}|with id|{org['title']}"))

@click.command("org:set")
@click.argument('name', required=True)
@click.option('-N', '--rename')
@click.option('-t', '--title')
@click.option('-S', '--contact-schema',
              type=click.Choice(['BASIC', 'ECI', 'POPULAR_INITIATIVE'],
                                case_sensitive=False), help="Personal data schema/category")
@click.option('-C', '--supporter-confirm', is_flag=True, help="Confirm contact data by email?")
@click.option('-T', '--supporter-confirm-template', help="Contact confirmation email template")
@click.option('-D', '--doi', help="Send thenk you email only to do DOI")
@click.option('-f', '--config', type=click.File('r'))
@pass_context
def set(ctx,
        name,
        rename,
        title,
        contact_schema,
        supporter_confirm,
        supporter_confirm_template,
        doi,
        config
        ):
    input = {}

    if rename:
        input['name'] = rename
    if contact_schema:
        input['contactSchema'] = contact_schema.upper()
    if supporter_confirm:
        input['supporterConfirm'] = supporter_confirm
    if supporter_confirm_template:
        input['supporterConfirmTemplate'] = supporter_confirm_template
    if doi:
        input['doiThankYou'] = doi
    if config:
        input['config'] = config.read()

    org = update_org(ctx.client, name, input)
    print(format(org))



@explain_error("getting org")
def get_org(client, name):

    query = gql("""
    query Org($name: String!) {
     org(name: $name) {
      ...orgData
     }
    }
    """ + orgData)

    data = client.execute(query, **vars(name=name))

    return data['org']

@explain_error("adding org")
def add_org(client, name, title):
    query = gql("""
        mutation AddOrg($name:String!, $title:String!) {
        addOrg(input:{
            name: $name, title: $title
        }) {
            ... on PrivateOrg {id}
            name
        }
        }
    """)

    data = client.execute(query, **vars(name=name, title=title))
    return data['addOrg']


@explain_error("updating org")
def update_org(client, name, org):
    query = """
      mutation updateOrg($name: String!, $input: OrgInput!) {
        updateOrg(
            name:$name, input:$input
        ) {
            ...orgData
        }
    }
    """ + orgData

    query = gql(query)

    data = client.execute(query, **vars(name=name, input=org))

    return data['updateOrg']



def format(org):
    name = org["name"]
    title = org["title"]

    out = rainbow(f"!{title}|{name}\n")

    cs = org['personalData']['contactSchema']
    pii_out = f"Contact:|{cs}"

    doi = org['personalData']['doiThankYou']

    if doi:
        pii_out += f"|MAILING DOI"

    if org['personalData']['supporterConfirm']:
        sup_con_t = org['personalData']['supporterConfirmTemplate']
        pii_out += f"|ACTION DOI|[tmpl:{sup_con_t}]"

    out += rainbow(pii_out + "\n")

    proc = org['processing']

    proc_out = f"Action:"
    if org['personalData']['supporterConfirm']:
        proc_out += f"|▷ confirm"

    delivery = []
    if proc['emailBackend']:
        delivery.append(f"EMAIL (proc['emailFrom'])")
    if proc['eventProcessing']:
        delivery.append(f"EVENT")
    if proc['sqsDeliver']:
        delivery.append(f"SQS")


    proc_out += "|" + "|".join(delivery)
    proc_out += f"|▷ export"

    out += rainbow(proc_out)

    return out

#!/usr/bin/env python3


import click

from proca.context import pass_context
from proca.friendly import explain_error
from proca.config import Config
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql

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
@click.option('-C', '--supporter-confirm/--no-supporter-confirm', is_flag=True, help="Confirm contact data by email?")
@click.option('--custom-supporter-confirm/--no-custom-supporter-confirm', is_flag=True, help="Put actions for supporter confirm on custom queue")
@click.option('-T', '--supporter-confirm-template', help="Contact confirmation email template")
@click.option('-D', '--doi/--no-doi', help="Send thenk you email only to do DOI")
@click.option('-f', '--config', type=click.File('r'))
@click.option('--custom-deliver/--no-custom-deliver', is_flag=True, help="Deliver actions to custom queue")
@pass_context
def set(ctx,
        name,
        rename,
        title,
        contact_schema,
        supporter_confirm,
        custom_supporter_confirm,
        supporter_confirm_template,
        doi,
        config,
        custom_deliver
        ):
    input = {}

    proc_input = {}

    if rename:
        input['name'] = rename
    if title:
        input['title'] = title
    if contact_schema:
        input['contactSchema'] = contact_schema.upper()
    if config:
        input['config'] = config.read()

    if supporter_confirm is not None:
        proc_input['supporterConfirm'] = supporter_confirm
    if custom_supporter_confirm is not None:
        proc_input['customSupporterConfirm'] = custom_supporter_confirm
    if supporter_confirm_template:
        proc_input['supporterConfirmTemplate'] = supporter_confirm_template
    if doi is not None:
        proc_input['doiThankYou'] = doi
    if custom_deliver is not None:
        proc_input['customActionDeliver'] = custom_deliver

    org = update_org(ctx.client, name, input, proc_input)
    print(format(org))


@click.command("org:leave")
@click.argument('name', required=True)
@pass_context
def leave(ctx, name):
    email = Config[ctx.server_section].get('user')
    status = leave_org(ctx.client, name, email)
    print(f"👋 left {name}: {status}")

@explain_error("leaving org")
def leave_org(client, org_name, email):
    query_string = """
    mutation Leave($org: String!, $email: String!) {
      deleteOrgUser(email: $email, orgName: $org) {
        status
      }
    }
    """

    query = gql(query_string)
    data = client.execute(query, **vars(org=org_name, email=email))
    return data['deleteOrgUser']['status']


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
            ... orgData
        }
        }
    """ + orgData)

    data = client.execute(query, **vars(name=name, title=title))
    return data['addOrg']


@explain_error("updating org")
def update_org(client, name, org, proc):
    query = """
      mutation updateOrg(
            $name: String!,
            $input: OrgInput!,
            $supporterConfirm: Boolean,
            $supporterConfirmTemplate: String,
            $doiThankYou: Boolean,
            $emailBackend: ServiceName
    ) {
        updateOrgProcessing(
            name: $name,
            supporterConfirm: $supporterConfirm,
            supporterConfirmTemplate: $supporterConfirmTemplate,
            doiThankYou: $doiThankYou,
            emailBackend: $emailBackend
        ) {name}

        updateOrg(
            name:$name, input:$input

        ) {
            ...orgData
        }

    }
    """ + orgData

    query = gql(query)

    data = client.execute(query, **vars(name=name, input=org, **proc))

    return data['updateOrg']


def format(org):
    id = org['id']
    name = org["name"]
    title = org["title"]

    out = rainbow(f"!{title}|{name}|{id}\n")

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
        if proc['customSupporterConfirm']:
            proc_out += f" QUEUE[cus.{id}.confirm.supporter]"


    delivery = []
    if proc['emailBackend']:
        delivery.append(f"EMAIL (from {proc['emailFrom']})")
    if proc['eventProcessing']:
        delivery.append(f"EVENT")
    if proc['sqsDeliver']:
        delivery.append(f"SQS")
    if proc['customActionDeliver']:
        delivery.append(f"QUEUE[cus.{id}.deliver]")


    proc_out += "|▷ " + "|".join(delivery)
    proc_out += f"|▷ export"

    out += rainbow(proc_out)

    return out

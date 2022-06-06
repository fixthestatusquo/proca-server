#!/usr/bin/env python3


import click

from proca.friendly import explain_error
from proca.config import Config, store
from proca.theme import *
from proca.query import *
from yaspin import yaspin
from gql import gql

CONTACT_SCHEMA_CHOICE=click.Choice(['BASIC', 'ECI', 'POPULAR_INITIATIVE'], case_sensitive=False)


@click.command("org")
@click.argument('name', required=True)
@click.option('-f', '--config', type=click.File('w'))
@click.pass_obj
def show(ctx, name, config):
    """
    Display org. Can store config of the org in file (-f parameter)
    """
    org = get_org(ctx.client, name)

    if config:
        config.write(org['config'])

    print(format(org))

@click.command("org:add")
@click.argument('name', required=True)
@click.argument('title', required=True)
@click.option('-d/-D', '--default/--no-default', is_flag=True, prompt="Set as default?")
@click.pass_obj
def add(ctx, name, title, default):
    """
    Add a new org.
    """
    org = add_org(ctx.client, name, title)

    if default:
        Config.set(ctx.server_section, 'org', org['name'])
        store()


    print(rainbow(f"⬣ {org['name']}|id: {org['id']}|- {org['title']}"))

@click.command("org:set")
@click.argument('name', required=True)
@click.option('-N', '--rename')
@click.option('-t', '--title')
@click.option('-S', '--contact-schema', type=CONTACT_SCHEMA_CHOICE, help="Personal data schema/category")
@click.option('-C', '--supporter-confirm/--no-supporter-confirm', is_flag=True, default=None, help="Confirm contact data by email?")
@click.option('--custom-supporter-confirm/--no-custom-supporter-confirm', is_flag=True, default=None, help="Put actions for supporter confirm on custom queue")
@click.option('-T', '--supporter-confirm-template', help="Contact confirmation email template")
@click.option('-D', '--doi/--no-doi', default=None, help="Send thenk you email only to do DOI")
@click.option('-f', '--config', type=click.File('r'))
@click.option('--custom-deliver/--no-custom-deliver', is_flag=True, default=None, help="Deliver actions to custom queue")
@click.option('--custom-event-deliver/--no-custom-event-deliver', is_flag=True, default=None, help="Deliver events to custom delivery queue")
@click.pass_obj
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
        custom_deliver,
        custom_event_deliver
        ):
    """
    Update org settings.
    """
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

    if custom_event_deliver is not None:
        proc_input['customEventDeliver'] = custom_event_deliver

    org = update_org(ctx.client, name, input, proc_input)
    print(format(org))

@click.command("org:join")
@click.argument('name', required=True)
@click.pass_obj
def join(ctx, name):
    """
    Join existing org.
    """
    # email = Config[ctx.server_section].get('user')
    _status, org = join_org(ctx.client, name)
    print(f"🛸 joined " + format(org))

@explain_error("joining org")
def join_org(client, org_name):
    query_string = """
    mutation JoinOrg($org: String!) {
      joinOrg(name: $org) {
        status
        org {
          ... on PrivateOrg {
          ...orgData
          }
        }
      }
    }
    """ + orgData

    query = gql(query_string)
    data = client.execute(query, **vars(org=org_name))
    return data['joinOrg']['status'], data['joinOrg']['org']

@click.command("org:leave")
@click.argument('name', required=True)
@click.pass_obj
def leave(ctx, name):
    """
    Leave an org
    """
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
            $customSupporterConfirm: Boolean,
            $supporterConfirmTemplate: String,
            $customActionDeliver: Boolean,
            $customEventDeliver: Boolean,
            $doiThankYou: Boolean,
            $emailBackend: ServiceName,
            $emailFrom: String
    ) {
        updateOrgProcessing(
            name: $name,
            supporterConfirm: $supporterConfirm,
            customSupporterConfirm: $customSupporterConfirm,
            supporterConfirmTemplate: $supporterConfirmTemplate,
            customActionDeliver: $customActionDeliver,
            customEventDeliver: $customEventDeliver,
            doiThankYou: $doiThankYou,
            emailBackend: $emailBackend,
            emailFrom: $emailFrom
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
        pii_out += f"|SUPPORTER DOI|[tmpl:{sup_con_t}]"

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

    if proc['sqsDeliver']:
        if proc['eventProcessing']:
            delivery.append(f"SQS[+event]")
        else:
            delivery.append(f"SQS")

    if proc['customActionDeliver']:
        if proc['customEventDeliver']:
            label = f"QUEUE[+event,cus.{id}.deliver]"
        else:
            label = f"QUEUE[cus.{id}.deliver]"
        delivery.append(label)


    if delivery != []:
        proc_out += "|▷ " + "|".join(delivery)
    proc_out += f"|▷ export"

    out += rainbow(proc_out)

    return out

#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
from proca.theme import *
from proca.query import *
import proca.cmd.org
import json

SERVICE_NAMES = ['MAILJET', 'SES', 'STRIPE', 'TEST_STRIPE', 'SYSTEM', 'WEBHOOK', 'SUPABASE', 'SMTP']
SERVICE_NAMES_CHOICE = click.Choice(SERVICE_NAMES, case_sensitive=False)

@click.command("service")
@click.option("-o", "--org", required=True, help="Org name")
@click.pass_obj
def list(ctx, org):
    """
    List services in org
    """
    services = org_services(ctx.client, org)

    for service in services:
        print(format(service))


@click.command("service:set")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE, required=True)
@click.option("-u", "--user", help="username")

@click.option("-p", "--password", help="password")
@click.option('-P', '--password-prompt', is_flag=True, help="Prompt for Your password")

@click.option("-h", "--host", help="Hostname or region")
@click.option("-l", "--path", help="Path or section")
@click.option("-i", "--id", type=int, help="id to update a specific service")
@click.pass_obj
def set(ctx, org, name, user, password, password_prompt, host, path, id):
    """
    Set service settings (create if not exists).
    """
    if password_prompt:
        password = click.prompt("Password", hide_input=True, confirmation_prompt=True)

    client = ctx.client

    input = {
        "name": name
    }

    input.update(make_input(locals(), ['user', 'password', 'host', 'path']))

    service = upsert_service(client, org, id, input)

    print(format(service))


@click.command("service:email")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-f", "--from", 'frm', help="Sender email (SMTP From header)")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE)
@click.option("-N", "--none", help="Disable email service", is_flag=True)
@click.pass_obj
def email(ctx, org, frm, name, none):
    """
    Configure email-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["emailBackend"] or "NO BACKEND"}|FROM: {p["emailFrom"]}'))

    if not name and not frm and not none:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {}
        if name:
            ip['emailBackend'] = name
        if none:
            ip['emailBackend'] = Null
        if frm:
            ip['emailFrom'] = frm
        org_data = proca.cmd.org.update_org(ctx.client, org, {}, ip)
        display(org_data)

@click.command("service:storage")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE)
@click.option("-N", "--none", help="Disable storage service", is_flag=True)
@click.pass_obj
def storage(ctx, org, name, none):
    """
    Configure storage-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["storageBackend"] or "NO BACKEND"}'))

    if not name and not none:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {}
        if name:
            ip['storageBackend'] = name
        if none:
            ip['storageBackend'] = Null
        org_data = proca.cmd.org.update_org(ctx.client, org, {}, ip)
        display(org_data)

@click.command("service:detail")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE)
@click.option("-N", "--none", help="Disable storage service", is_flag=True)
@click.pass_obj
def detail(ctx, org, name, none):
    """
    Configure detail service-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["detailBackend"] or "NO BACKEND"}'))

    if not name and not none:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {}
        if name:
            ip['detailBackend'] = name
        if none:
            ip['detailBackend'] = Null
        org_data = proca.cmd.org.update_org(ctx.client, org, {}, ip)
        display(org_data)


@click.command("service:push")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE)
@click.option("-N", "--none", help="Disable push service", is_flag=True)
@click.pass_obj
def push(ctx, org, name, none):
    """
    Configure detail service-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["pushBackend"] or "NO BACKEND"}'))

    if not name and not none:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {}
        if name:
            ip['pushBackend'] = name
        if none:
            ip['pushBackend'] = Null
        org_data = proca.cmd.org.update_org(ctx.client, org, {}, ip)
        display(org_data)

@click.command("service:event")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=SERVICE_NAMES_CHOICE)
@click.option("-N", "--none", help="Disable storage service", is_flag=True)
@click.pass_obj
def event(ctx, org, name, none):
    """
    Configure event service-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["eventBackend"] or "NO BACKEND"}'))

    if not name and not none:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {}
        if name:
            ip['eventBackend'] = name
        if none:
            ip['eventBackend'] = Null
        org_data = proca.cmd.org.update_org(ctx.client, org, {}, ip)
        display(org_data)


@explain_error("getting service list")
def org_services(client, org):
    query_str = """
    query OrgServices($org: String!) {
      org(name: $org) {
        services {
         ...serviceData
        }
      }
    }
    """ + serviceData

    query_str = gql(query_str)

    data = client.execute(query_str, **vars(org=org))
    return data['org']['services']

@explain_error("setting service")
def upsert_service(client, org, id, service):

    query_str = """
    mutation UpsertService(
      $org: String!,
      $id: Int,
      $service: ServiceInput!
    ) {
      upsertService(orgName: $org, id: $id, input: $service) {
        ...serviceData
      }
    }
    """ + serviceData

    query = gql(query_str)

    data = client.execute(query, **vars(id=id, org=org, service=service))

    service = data['upsertService']
    return service

def format(service):

    x = []

    out = service['name']

    if service['user']:
        x.append(service['user'])

    if service['host']:
        x.append(service['host'])

    if x:
        out += "|" + "@".join(x)

    if service['path']:
        out += f"/{service['path']}"


    out = W(f"{service['id']} ") + rainbow(out)
    return out

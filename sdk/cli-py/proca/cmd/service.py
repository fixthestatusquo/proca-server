#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
from proca.theme import *
from proca.query import *
import proca.cmd.org
import json

SERVICE_NAMES = ['MAILJET', 'SES', 'STRIPE', 'TEST_STRIPE']
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
@click.pass_obj
def set(ctx, org, name, user, password, password_prompt, host, path):
    """
    Set service settings (create if not exists).
    """
    id = None # unsupported atm
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
@click.pass_obj
def email(ctx, org, frm, name):
    """
    Configure email-related options for org.
    """
    def display(data):
        p = data["processing"]
        print(rainbow(f'{p["emailBackend"] or "NO BACKEND"}|FROM: {p["emailFrom"]}'))

    if not name and not frm:
        org_data = proca.cmd.org.get_org(ctx.client, org)
        display(org_data)
    else:
        ip = {
            "emailBackend": name,
            "emailFrom": frm
        }
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

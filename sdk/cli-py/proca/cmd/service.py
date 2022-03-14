#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.context import pass_context
from proca.friendly import explain_error
from proca.query import *
import json

SERVICE_NAMES = ['mailjet', 'ses']

@click.command("service:set")
@click.option("-o", "--org", required=True, help="Org name")
#@click.option("-i", "--id", type=int, help="Service ID")
@click.option("-n", "--name", help="Service name", type=click.Choice(SERVICE_NAMES))
@click.option("-u", "--user", help="username")

@click.option("-p", "--password", help="password")
@click.option('-P', '--password-prompt', is_flag=True, help="Prompt for Your password")
@pass_context
def set(ctx, org, name, user, password, password_prompt):
    id = None # unsupported atm
    if password_prompt:
        password = click.prompt("Password", hide_input=True, confirmation_prompt=True)

    client = ctx.client

    service = upsert_service(client, org, id, {
        "name": name.upper(),
        "user": user,
        "password": password
    })

    print(f"{service['id']:03d} {service['name']}")


@explain_error("setting service")
def upsert_service(client, org, id, service):

    query_str = """
    mutation UpsertService(
      $org: String!,
      $id: Int,
      $service: ServiceInput!
    ) {
      upsertService(orgName: $org, id: $id, input: $service) {
       id
      }
    }
    """

    query = gql(query_str)

    data = client.execute(query, **vars(id=id, org=org, service=service))

    service['id'] = data['upsertService']['id']
    return service

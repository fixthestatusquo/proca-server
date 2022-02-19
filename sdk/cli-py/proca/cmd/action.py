#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.context import pass_context
from proca.friendly import explain_error
import json

@click.command("action")
@click.option("-i", "--id", type=int, help="Action Page Id")
@pass_context
def action(ctx, id):
    client = ctx.client

    add_action_contact(client, id)


@explain_error("adding test action")
def add_action_contact(client, id):
    "Callas addActionContact mutation"


    query_str = """mutation AddActionContact($id: Int!) {
    addActionContact(actionPageId: $id,
        contact: {firstName: "Friedrich", email: "hegel@gmail.com"},
        action: {actionType: "test"},
        privacy: {optIn:false}
    ) {
    contactRef
    }
    }
    """
    query=gql(query_str)

    vars = {'id': id}

    # payload = {
    #     'operationName': 'AddActionContact',
    #     'query': query_str, 'variables': vars, 'extensions': {'captcha': '1234'}
    # }


    data = client.execute(query, variable_values=vars) #, extra_args={'json': payload})

    print(data)

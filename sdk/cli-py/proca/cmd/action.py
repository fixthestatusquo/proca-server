#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
from proca.query import *
from proca.theme import *
import json
from random import randint

@click.command("action")
@click.option("-i", "--id", type=int, help="Action Page Id")
@click.option("-e", "--email", help="email", default=f"test+{randint(1, 100000)}@proca.app")
@click.option("-f", "--first", help="first name", default="Curious")
@click.option("-l", "--last", help="last name", default="Tester")
@click.option("-a", "--action-type", help="action type", default="register")
@click.option("-t", "--testing", is_flag=True, help="action type", default=False)
@click.option("-c", "--country", help="country", default='PL')
@click.option("-p", "--postcode", help="postcoude", default='01-234')
@click.option("-o", "--optin", help="opt in", is_flag=True, default=False)
@click.pass_obj
def add(ctx, id, email, first, last, action_type, testing, country, postcode, optin):
    client = ctx.client

    contact ={
        'firstName': first, 'lastName': last, 'email': email,
        'address': {
            'country': country, 'postcode': postcode
        }
    }

    action = {
        'actionType': action_type,
        'testing': testing
    }

    #print(action)
    #print(contact)
    supporter = add_action_contact(client, id, contact, action, optin)

    print(rainbow(supporter['contactRef']))


@explain_error("adding test action")
def add_action_contact(client, id, contact, action, optIn):
    "Callas addActionContact mutation"


    query_str = """mutation AddActionContact($id: Int!, $contact: ContactInput!, $action: ActionInput!, $optIn: Boolean!) {
    addActionContact(actionPageId: $id,
        contact: $contact,
        action: $action,
        privacy: {optIn: $optIn}
    ) {
    contactRef
    }
    }
    """
    query=gql(query_str)


    # payload = {
    #     'operationName': 'AddActionContact',
    #     'query': query_str, 'variables': vars, 'extensions': {'captcha': '1234'}
    # }


    data = client.execute(query, **vars(id=id, contact=contact, action=action, optIn=optIn))
    return data['addActionContact']

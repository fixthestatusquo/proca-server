#!/usr/bin/env python3

from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
from proca.query import *
from proca.theme import *
from proca.util import DATETIME_FORMATS
import json
from random import randint

QUEUES = [
    'CUSTOM_ACTION_CONFIRM',
    'CUSTOM_ACTION_DELIVER',
    'CUSTOM_SUPPORTER_CONFIRM',
    'EMAIL_SUPPORTER',
    'SQS',
    'WEBHOOK'
]

@click.command("action:add")
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


@click.command("action:replay")
@click.option('-o', '--org', 'org', help="Org owning actions")
@click.option('-c', '--campaign', 'campaign', help="Filter by campaign")
@click.option('-T', '--testing', 'include_testing', type=bool, default=False, help="Include testing actions")
@click.option('-i', '--id', 'start_id', type=int, help="Start from action id")
@click.option('-s', '--since', 'start_datetime', type=click.DateTime(formats=DATETIME_FORMATS), help="Start from action id")
@click.option('-q', '--queue', 'queue', type=click.Choice(QUEUES, case_sensitive=False))
@click.pass_obj
def requeue(ctx, org, campaign, include_testing, start_id, start_datetime, queue):
    query_ids_str = """
query Ids($org: String!, $campaign: String, $includeTesting: Boolean, $startId: Int, $startDatetime: DateTime) {
  exportActions(
    orgName: $org,
    campaignName: $campaign,
    includeTesting: $includeTesting,
    start: $startId,
    after: $startDatetime,
    onlyOptIn: false
    ) {

    actionId
  }
}
    """

    requeue_str = """
        mutation Requeue($org: String!, $ids: [Int!]!, $queue: Queue!){
            requeueActions(orgName:$org, ids: $ids, queue: $queue) {
                count failed
            }
        }
    """
    query_ids = gql(query_ids_str)
    requeue_mut = gql(requeue_str)

    def get_ids(next_id=None):
        string_start_datetime = start_datetime.strftime("%Y-%m-%dT%H:%M:%SZ") 
        results = ctx.client.execute(query_ids, **vars(org=org, campaign=campaign, includeTesting=include_testing, startId=next_id, startDatetime=string_start_datetime))

        # Yield each ID from the results
        results = results['exportActions']
        if results:
            yield list(map(lambda x: x['actionId'], results))
            yield from get_ids(results[-1]['actionId']+1)

    for id_list in get_ids(start_id):
        if len(id_list):
            res = ctx.client.execute(requeue_mut, **vars(org=org, ids=id_list, queue=queue))

    return


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

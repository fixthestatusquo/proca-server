#!/usr/bin/env python3


from gql import gql
import click
from proca.config import make_client
from proca.friendly import explain_error
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

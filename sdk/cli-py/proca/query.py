#!/usr/bin/env python3

from gql import gql


fragments = {
    "campaignData": """
    fragment campaignData on Campaign {
    __typename
    id name title
    config
    contactSchema
    }
    """,

    "actionPageData": """
    fragment actionPageData on ActionPage {
    __typename
    id name locale config
    thankYouTemplate
    }
    """
}

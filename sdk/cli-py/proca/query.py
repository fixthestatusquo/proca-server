#!/usr/bin/env python3

from gql import gql


campaignData =  """
    fragment campaignData on Campaign {
    __typename
    id name title externalId
    config
    contactSchema
    }
    """

campaignDataStatus = """
    fragmen campaignDataStatus on Campaign {
       stats {
          supporterCount
          actionCount { actionType count }
       }
    }
"""



actionPageData = """
    fragment actionPageData on ActionPage {
    __typename
    id name locale config
    thankYouTemplate
    }
    """


actionPageStatus = """
    fragment actionPageStatus on ActionPage {
    ... on PrivateActionPage {
        status
        extraSupporters
    }
    }
    """

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

mttData = """
  fragment mttData on Campaign {
  ... on PrivateCampaign {
    mtt {
       startAt endAt testEmail messageTemplate
    }
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

orgData = """
    fragment orgData on PrivateOrg {
        name
        title
        config

        personalData {
            contactSchema
            doiThankYou  #  only send thank you if comconsent
            supporterConfirm
            supporterConfirmTemplate
        }

        processing {
            emailBackend emailFrom
            eventProcessing eventBackend
            sqsDeliver
        }
    }
"""


class Null:
    "A Null value passed to GQL. A None value will not send the variable."
    pass

def vars(**kv):
    """
    A shorthand to product variable_values for gql.client.query - it will filter out nil values
    """

    def allow_null(z):
        if z == Null:
            return None
        else:
            return z

    x = {k: allow_null(v) for k, v in kv.items() if v is not None}
    return {"variable_values": x}

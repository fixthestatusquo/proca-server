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

campaignStats = """
    fragment campaignStats on Campaign {
       stats {
          supporterCount
          actionCount { actionType count }
          supporterCountByArea {area count}
       }
    }
"""

# XXX we must query for something...
noCampaignStats = """
    fragment campaignStats on Campaign {__typename}
"""

campaignTargetIds = """
    fragment campaignTargets on Campaign { targets { id }}
"""

campaignTargetAll = """
    fragment campaignTargets on Campaign { targets { id name locale area externalId fields }}
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
        org { name title }
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
        id
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

            supporterConfirm
            supporterConfirmTemplate
            customActionDeliver customEventDeliver customSupporterConfirm
        }
    }
"""

serviceData = """
  fragment serviceData on Service {
    id name host path user
  }
"""

keyData = """
  fragment keyData on Key {
    id name
    public
    active expired expiredAt
  }
"""

keyPrivData = """
  fragment keyPrivData on KeyWithPrivate {
    id name
    public private
    active expired expiredAt
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


def make_input(local_vars, allow_list):
    """
    Util to quickly pass arguments from click (which are variables) into an
    input object. Accepts an object and a list of field names. Will not add None
    values, but will convert any empty string '' to None (useful to reset a
    field to null)

    use:

    input = make_input(locals(), ['user', 'password', 'locale'])
    """
    def empty_to_null(x):
        if x == '':
            return None
        else:
            return x

    v1 = {v: empty_to_null(local_vars[v]) for v in allow_list if local_vars[v] is not None}
    return v1

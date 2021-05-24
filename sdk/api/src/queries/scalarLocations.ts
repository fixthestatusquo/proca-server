
export type Node = { [key: string]: Node | string };
export const scalarLocations : Record<string,Node> = {
  "inputScalars": {
    "Json": "Json",
    "ActionInput": {
      "donation": {
        "payload": "Json"
      }
    },
    "ActionPageInput": {
      "config": "Json"
    },
    "CampaignInput": {
      "config": "Json",
      "actionPages": {
        "config": "Json"
      }
    },
    "DonationActionInput": {
      "payload": "Json"
    },
    "OrgInput": {
      "config": "Json"
    }
  },
  "outputScalars": {
    "upsertCampaign": {
      "config": "Json"
    },
    "declareCampaign": {
      "config": "Json"
    },
    "updateActionPage": {
      "config": "Json",
      "campaign": {
        "config": "Json"
      }
    },
    "copyActionPage": {
      "config": "Json",
      "campaign": {
        "config": "Json"
      }
    },
    "addOrgUser": {
      "roles": {
        "org": {
          "config": "Json",
          "campaigns": {
            "config": "Json"
          },
          "actionPages": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "actionPage": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "campaign": {
            "config": "Json"
          }
        }
      }
    },
    "updateOrgUser": {
      "roles": {
        "org": {
          "config": "Json",
          "campaigns": {
            "config": "Json"
          },
          "actionPages": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "actionPage": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "campaign": {
            "config": "Json"
          }
        }
      }
    },
    "addOrg": {
      "config": "Json",
      "campaigns": {
        "config": "Json"
      },
      "actionPages": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "actionPage": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "campaign": {
        "config": "Json"
      }
    },
    "updateOrg": {
      "config": "Json",
      "campaigns": {
        "config": "Json"
      },
      "actionPages": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "actionPage": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "campaign": {
        "config": "Json"
      }
    },
    "joinOrg": {
      "org": {
        "config": "Json",
        "campaigns": {
          "config": "Json"
        },
        "actionPages": {
          "config": "Json",
          "campaign": {
            "config": "Json"
          }
        },
        "actionPage": {
          "config": "Json",
          "campaign": {
            "config": "Json"
          }
        },
        "campaign": {
          "config": "Json"
        }
      }
    },
    "campaigns": {
      "config": "Json"
    },
    "actionPage": {
      "config": "Json",
      "campaign": {
        "config": "Json"
      }
    },
    "currentUser": {
      "roles": {
        "org": {
          "config": "Json",
          "campaigns": {
            "config": "Json"
          },
          "actionPages": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "actionPage": {
            "config": "Json",
            "campaign": {
              "config": "Json"
            }
          },
          "campaign": {
            "config": "Json"
          }
        }
      }
    },
    "org": {
      "config": "Json",
      "campaigns": {
        "config": "Json"
      },
      "actionPages": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "actionPage": {
        "config": "Json",
        "campaign": {
          "config": "Json"
        }
      },
      "campaign": {
        "config": "Json"
      }
    }
  }
};

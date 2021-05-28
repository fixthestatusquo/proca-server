import EctoEnum
# Remember to update the GraphQL enums to match these!
# You can do this in lib/proca_web/schema/data_types.ex file

defenum(ProcessingStatus, new: 0, confirming: 1, rejected: 2, accepted: 3, delivered: 4)

defenum(ExternalService, ses: "ses", sqs: "sqs", mailjet: "mailjet", wordpress: "wordpress", stripe: "stripe")

defenum(ContactSchema, basic: 0, popular_initiative: 1, eci: 2, it_ci: 3)

defenum(DonationSchema, stripe_payment_intent: 0)

defenum(DonationFrequencyUnit, one_off: 0, weekly: 1, monthly: 2)


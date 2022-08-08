import EctoEnum
# Remember to update the GraphQL enums to match these!
# You can do this in lib/proca_web/schema/data_types.ex file

defenum(ProcessingStatus,
  new: 0,
  confirming: 1,
  rejected: 2,
  accepted: 3,
  delivered: 4
)

defenum(ExternalService,
  ses: "ses",
  sqs: "sqs",
  mailjet: "mailjet",
  wordpress: "wordpress",
  stripe: "stripe",
  test_stripe: "test_stripe",
  testmail: "testmail",
  webhook: "webhook",
  supabase: "supabase"
)

defenum(ContactSchema, basic: 0, popular_initiative: 1, eci: 2, it_ci: 3)

defenum(ConfirmOperation,
  confirm_action: 0,
  join_campaign: 1,
  add_partner: 2,
  launch_page: 3,
  add_staffer: 4
)

defenum(DonationSchema, stripe_payment_intent: 0)

defenum(DonationFrequencyUnit, one_off: 0, weekly: 1, monthly: 2, daily: 16)

defenum(EmailStatus, none: 0, double_opt_in: 1, bounce: 2, blocked: 3, spam: 4, unsub: 5)

import EctoEnum
# Remember to update the GraphQL enums to match these!
# You can do this in lib/proca_web/schema/data_types.ex file

defmodule Enums do
  @moduledoc """
  Enums used in Proca database.

  ## ProcessingStatus
  The processing status used for both action and supporter

  - 0 - `new`
  - 1 - `confirming`
  - 2 - `rejected`
  - 3 - `accepted`
  - 4 - `delivered`

  Possible status transitions

  ```
  new -> confirming -> rejected
    v      v
  accepted
    v
  delivered (action status only)
  ```

  ## EmailStatus ##

  Status of the supporter email.

  - 0 - `none` (we have no information on this email)
  - 1 - `double_opt_in` (email wants to get newsletter)
  - 2 - `bounce` (email bounces)
  - 3 - `blocked` (email blocks)
  - 4 - `spam` (email thinks you are a spammer)
  - 5 - `unsub` (email has expressed will to not be contacted any more)
  - 6 - `inactive` (email should not be contacted anymore)


  ## DonationFrequencyUnit ##

  - 0 - `one_off`
  - 1 - `weekly`
  - 2 - `monthly`
  - 3 - `daily`
  """
end

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
  smtp: "smtp",
  wordpress: "wordpress",
  stripe: "stripe",
  test_stripe: "test_stripe",
  testmail: "testmail",
  webhook: "webhook",
  supabase: "supabase",
  testdetail: "testdetail"
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

defenum(EmailStatus,
  none: 0,
  double_opt_in: 1,
  bounce: 2,
  blocked: 3,
  spam: 4,
  unsub: 5,
  inactive: 6,
  active: 7
)

defenum(CampaignStatus, live: 0, closed: 1, ignored: 2)

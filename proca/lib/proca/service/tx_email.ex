defmodule Proca.Service.TxEmail do
  @moduledoc """
  Proca transaciton email types:
  1. Thank you email
  2. Confirmation email (supporter confirmation)
  3. Confirmation email (action confirmation)
  4. ActionPage to Campaign link confirmation (cf onboarding)

  """

  import Bamboo.Email
  alias Bamboo.MailjetAdapter


  def config(:mailjet) do
    %{
      adapter: MailjetAdapter,
      api_key: "03fa81833fece3a50e30d5d91d1dcf2d",
      api_private_key: "34bcfd71a4922271b0321aae0f84efd9"
    }
  end

  def thank_you(user) do
    new_email(
      from: "hi@cahoots.pl",
      to: [{user_name(user), user.email}],
      cc: [],
      bcc: [],
      subject: "Hi!",
      text_body: "",
      html_body: "Nice to see you in our SASS"
    )
    |> MailjetAdapter.deliver(config(:mailjet))
  end

  def user_name(%{email: email}) do
    String.split(email, ~r/@/) |> List.first
  end
end

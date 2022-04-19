defmodule Proca.Users.UserNotifier do
  alias Proca.Org
  alias Proca.Service

  defp deliver(email, template_name, fields) do
    import Logger
    instance = Org.one([:instance] ++ [preload: [:email_backend]])

    case Service.EmailTemplateDirectory.by_name_reload(instance, template_name) do
      {:ok, t} ->
        r =
          Service.EmailBackend.make_email({"Proca User", email}, {:user, email})
          |> Service.EmailMerge.put_assigns(fields)

        result = Service.EmailBackend.deliver([r], instance, t)
        info("Email #{template_name} to #{email} delivery: #{inspect(result)}}")
        result

      _ ->
        # IO.inspect({instance, template_name}, label: "Failed to send user notification with tempalte")
        info("User notification: #{template_name} for <#{email}>: #{inspect(fields)}")
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "user_confirm_email", %{confirm_link: url})
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "user_reset_password", %{confirm_link: url})
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "user_change_email", %{confirm_link: url})
  end
end

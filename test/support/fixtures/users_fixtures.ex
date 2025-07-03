defmodule Proca.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Proca.Users` context.

  This comes from phoenix auth - we also can create a user using Proca.Factory
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "Hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Proca.Users.register_user()

    user
  end

  import Proca.TestEmailBackend, only: [mailbox: 1]

  @doc """
  Runs the Proca.Users.some_send_token_to_user_fun 
  then intercepts the email sent from TestEmailBackend, and takes out the token from confirm_link.
  We use an identity function so url is actually the token.
  """
  def extract_user_token(email, token_sender_fun) do
    token_sender_fun.(fn x -> x end)

    case mailbox(email) do
      [
        %{
          assigns: fields
        }
      ] ->
        fields["confirmLink"]

      nil ->
        ""
    end
  end
end

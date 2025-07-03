defmodule ProcaWeb.Schema.ConfirmTypes do
  @moduledoc """
  API form confirms

  - you can accept / reject confirm on behalf of organisation
  - you can accept / reject confirm on behalf of your user (invitation to an org team) - although you might not have a user yet
  """
  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation
  alias ProcaWeb.Resolvers

  input_object :confirm_input do
    @desc "secret code of this confirm"
    field :code, non_null(:string)
    @desc "email that confirm was assigned for"
    field :email, :string
    @desc "object_id that this confirm refers to"
    field :object_id, :integer
  end

  object :confirm_result do
    @desc "Status of Confirm: Success, Confirming (waiting for confirmation), Noop"
    field :status, non_null(:status)
    @desc "Action page if its an object of confirm"
    field :action_page, :action_page
    @desc "Campaign page if its an object of confirm"
    field :campaign, :campaign
    @desc "Org if its an object of confirm"
    field :org, :org
    @desc "A message attached to the confirm"
    field :message, :string
  end

  object :confirm_mutations do
    @desc "Accept a confirm on behalf of organisation."
    field :accept_org_confirm, type: non_null(:confirm_result) do
      @desc "Org name"
      arg(:name, non_null(:string))
      @desc "Confirm content"
      arg(:confirm, non_null(:confirm_input))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow(:staffer)

      resolve(&Resolvers.Confirm.org_confirm/3)
    end

    @desc "Reject a confirm on behalf of organisation."
    field :reject_org_confirm, type: non_null(:confirm_result) do
      @desc "Org name"
      arg(:name, non_null(:string))
      @desc "Confirm data"
      arg(:confirm, non_null(:confirm_input))

      load(:org, by: [:name])
      determine_auth(for: :org)
      allow(:staffer)

      resolve(&Resolvers.Confirm.org_reject/3)
    end

    @desc "Accept a confirm by user"
    field :accept_user_confirm, type: non_null(:confirm_result) do
      @desc "Confirm data"
      arg(:confirm, non_null(:confirm_input))
      allow(:user)
      resolve(&Resolvers.Confirm.user_confirm/3)
    end

    @desc "Reject a confirm by user"
    field :reject_user_confirm, type: non_null(:confirm_result) do
      @desc "Confirm data"
      arg(:confirm, non_null(:confirm_input))
      allow(:user)
      resolve(&Resolvers.Confirm.user_reject/3)
    end
  end

  object :confirm do
    @desc "Secret code/PIN of the confirm"
    field :code, non_null(:string)
    @desc "Email the confirm is sent to"
    field :email, :string
    @desc "Message attached to the confirm"
    field :message, :string
    @desc "Object id that confirmable action refers to"
    field :object_id, :integer
    @desc "Who created the confirm"
    field :creator, :user
  end
end

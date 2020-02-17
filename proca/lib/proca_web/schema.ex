defmodule ProcaWeb.Schema do
  use Absinthe.Schema
  alias ProcaWeb.Resolvers

  import_types ProcaWeb.Schema.DataTypes
  import_types ProcaWeb.Schema.InputTypes

  query do
    @desc "Get a list of campains"
    field :campaigns, list_of(:campaign) do
      arg :title, :string
      arg :name, :string
      arg :id, :integer
      resolve &Resolvers.Campaign.list/3
    end

    @desc "Get action page"
    field :action_page, :action_page do
      arg :url, :string
      arg :id, :integer
      resolve &Resolvers.ActionPage.find/3
    end
  end

  mutation do
    @desc "Adds a signature"
    field :add_signature, type: :id do
      arg :action_page_id, non_null(:id)
      arg :signature, :signature_input

      resolve &Resolvers.Contact.add_signature/3
    end
  end

  # addSignature(action_page_id, details, tracking)
end

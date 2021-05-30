defmodule ProcaWeb.Schema.ConfirmTypes do 
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  input_object :invite do 
    field :code, non_null(:string)
    field :email, :string 
    field :id, :integer
  end
 
  object :confirm_result do 
    field :status, non_null(:status)
    field :action_page, :action_page
    field :campaign, :campaign
    field :org, :org
  end
  
  object :confirm_mutations do 
    field :accept_org_invite, type: non_null(:confirm_result) do 
      middleware Authorized, access: [:org, by: [:name]]

      arg :name, non_null(:string)
      arg :invite, non_null(:invite)

      resolve &ProcaWeb.Resolvers.Confirm.org_confirm/3
    end

    field :reject_org_invite, type: non_null(:confirm_result) do 
      middleware Authorized, access: [:org, by: [:name]]

      arg :name, non_null(:string)
      arg :invite, non_null(:invite)

      resolve &ProcaWeb.Resolvers.Confirm.org_reject/3
    end
  end

end

defmodule ProcaWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers.Authorized
  alias ProcaWeb.Resolvers
  import Proca.Permission, only: [can?: 2]

  object :user_queries do
    field :current_user, non_null(:user) do
      middleware Authorized
      resolve(&Resolvers.User.current_user/3)
    end

    field :users, non_null(list_of(non_null(:user))) do 
      middleware Authorized, can?: [:manage_users]

      arg :select, :select_user
      resolve(&Resolvers.User.list_users/3)

    end
  end

  object :user do
    field :id, non_null(:integer)
    field :email, non_null(:string)

    field :is_admin, non_null(:boolean) do 
      resolve(fn u, _, _ -> can?(u, :instance_admin) end)
    end

    field :roles, non_null(list_of(non_null(:user_role))) do 
      resolve(&Resolvers.User.user_roles/3)
    end
  end

  object :user_role do
    field :org, non_null(:org)
    field :role, non_null(:string)
  end

  object :org_user do 
    field :email, non_null(:string)
    field :role, non_null(:string)
    field :created_at, non_null(:naive_datetime)
    field :joined_at, non_null(:naive_datetime)
    field :last_signin_at, :naive_datetime
  end

  object :user_mutations do
    field :add_org_user, type: non_null(:change_user_status) do
      middleware Authorized, access: [:org, by: [name: :org_name]], can?: :change_org_settings
      arg :org_name, non_null(:string)
      arg :input, non_null(:user_input)
      resolve(&Resolvers.User.add_org_user/3)
    end

    field :update_org_user, type: non_null(:change_user_status) do
      middleware Authorized, access: [:org, by: [name: :org_name]], can?: :change_org_settings
      arg :org_name, non_null(:string)
      arg :input, non_null(:user_input)
      resolve(&Resolvers.User.update_org_user/3)
    end

    field :delete_org_user, type: :delete_user_result do
      middleware Authorized, access: [:org, by: [name: :org_name]], can?: :change_org_settings
      arg :org_name, non_null(:string)
      arg :email, non_null(:string)
      resolve(&Resolvers.User.delete_org_user/3)

    end
  end

  input_object :user_input do
    field :email, non_null(:string)
    field :role, non_null(:string)
  end

  object :change_user_status do 
    field :status, non_null(:status)
  end

  object :delete_user_result do
    field :status, non_null(:status)
  end

  object :update_user_result do
    field :id, non_null(:integer)
  end

  @desc "Criteria to filter users"
  input_object :select_user do 
    field :id, :integer

    @desc "Use % as wildcard"
    field :email, :string 

    @desc "Exact org name"
    field :org_name, :string
  end
end

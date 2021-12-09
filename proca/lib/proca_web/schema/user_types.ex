defmodule ProcaWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation
  alias ProcaWeb.Resolvers
  import Proca.Permission, only: [can?: 2]

  object :user_queries do
    field :current_user, non_null(:user) do
      allow :user
      resolve(&Resolvers.User.current_user/3)
    end

    field :users, non_null(list_of(non_null(:user))) do 
      arg :select, :select_user

      allow [:manage_users]
      resolve(&Resolvers.User.list_users/3)
    end
  end

  object :user do
    field :id, non_null(:integer)
    field :email, non_null(:string)
    field :phone, :string
    field :picture_url, :string
    field :job_title, :string

    field :is_admin, non_null(:boolean) do 
      resolve(fn u, _, _ -> {:ok, can?(u, :instance_owner)} end)
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
    @desc "Add user to org by email"
    field :add_org_user, type: non_null(:change_user_status) do
      arg :org_name, non_null(:string)
      arg :input, non_null(:org_user_input)

      load :org, by: [name: :org_name]
      determine_auth for: :org
      allow [:change_org_settings]
      resolve(&Resolvers.User.add_org_user/3)
    end

    @desc "Invite an user to org by email (can be not yet user!)"
    field :invite_org_user, type: non_null(:confirm) do
      arg :org_name, non_null(:string)
      arg :input, non_null(:org_user_input)

      @desc "Optional message for invited user"
      arg :message, :string

      load :org, by: [name: :org_name]
      determine_auth for: :org
      allow [:change_org_settings]
      resolve(&Resolvers.User.invite_org_user/3)
    end

    field :update_org_user, type: non_null(:change_user_status) do
      arg :org_name, non_null(:string)
      arg :input, non_null(:org_user_input)

      load :org, by: [name: :org_name]
      determine_auth for: :org
      allow [:change_org_settings]
      resolve(&Resolvers.User.update_org_user/3)
    end

    field :delete_org_user, type: :delete_user_result do
      arg :org_name, non_null(:string)
      arg :email, non_null(:string)

      load :org, by: [name: :org_name]
      determine_auth for: :org
      allow [:change_org_settings]
      resolve(&Resolvers.User.delete_org_user/3)
    end

    @desc "Update (current) user details"
    field :update_user, type: non_null(:user) do
      @desc "Input values to update in user"
      arg :input, non_null(:user_details_input)

      @desc "Admin can use user id to specify user to update"
      arg :id, :integer

      @desc "Admin can use user email to specify user to update"
      arg :email, :string

      allow :user
      resolve(&Resolvers.User.update_user/3)
    end
   end

  input_object :org_user_input do
    field :email, non_null(:string)
    field :role, non_null(:string)
  end

  input_object :user_details_input do
    field :picture_url, :string
    field :job_title, :string
    field :phone, :string
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

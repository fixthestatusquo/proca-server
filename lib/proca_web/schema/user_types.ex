defmodule ProcaWeb.Schema.UserTypes do
  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation
  alias ProcaWeb.Resolvers
  import Proca.Permission, only: [can?: 2]

  object :user_queries do
    @desc "Get the current user, as determined by Authorization header"
    field :current_user, non_null(:user) do
      allow(:user)
      resolve(&Resolvers.User.current_user/3)
    end

    @desc "Select users from this instnace. Requires a manage users admin permission."
    field :users, non_null(list_of(non_null(:user))) do
      @desc "Filter users"
      arg(:select, :select_user)

      allow([:manage_users])
      resolve(&Resolvers.User.list_users/3)
    end
  end

  object :user do
    @desc "Id of user"
    field :id, non_null(:integer)
    @desc "Email of user"
    field :email, non_null(:string)
    @desc "Phone"
    field :phone, :string
    @desc "Url to profile picture"
    field :picture_url, :string
    @desc "Job title"
    field :job_title, :string

    @desc "Users API token (to check expiry)"
    field :api_token, :api_token do
      resolve(&Resolvers.User.api_token/3)
    end

    @desc "Is user an admin?"
    field :is_admin, non_null(:boolean) do
      resolve(fn u, _, _ -> {:ok, can?(u, :instance_owner)} end)
    end

    @desc "user's roles in orgs"
    field :roles, non_null(list_of(non_null(:user_role))) do
      resolve(&Resolvers.User.user_roles/3)
    end
  end

  object :user_role do
    @desc "Org this role is in"
    field :org, non_null(:org)
    @desc "Role name"
    field :role, non_null(:string)
  end

  object :org_user do
    field :email, non_null(:string)
    @desc "Role in an org"
    field :role, non_null(:string)
    @desc "Date and time the user was created on this instance"
    field :created_at, non_null(:naive_datetime)
    @desc "Date and time when user joined org"
    field :joined_at, non_null(:naive_datetime)
    @desc "Will be removed"
    field :last_signin_at, :naive_datetime
  end

  object :user_mutations do
    @desc "Add user to org by email"
    field :add_org_user, type: non_null(:change_user_status) do
      @desc "Org name"
      arg(:org_name, non_null(:string))
      @desc "User content"
      arg(:input, non_null(:org_user_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.User.add_org_user/3)
    end

    @desc "Invite an user to org by email (can be not yet user!)"
    field :invite_org_user, type: non_null(:confirm) do
      @desc "org name to invite to"
      arg(:org_name, non_null(:string))
      @desc "user membership data"
      arg(:input, non_null(:org_user_input))

      @desc "Optional message for invited user"
      arg(:message, :string)

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_org_users])
      resolve(&Resolvers.User.invite_org_user/3)
    end

    field :update_org_user, type: non_null(:change_user_status) do
      @desc "update user membership data"
      arg(:org_name, non_null(:string))

      @desc "user membership data"
      arg(:input, non_null(:org_user_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.User.update_org_user/3)
    end

    field :delete_org_user, type: :delete_user_result do
      @desc "delete user from this org"
      arg(:org_name, non_null(:string))
      @desc "users email"
      arg(:email, non_null(:string))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_org_settings])
      resolve(&Resolvers.User.delete_org_user/3)
    end

    @desc "Update (current) user details"
    field :update_user, type: non_null(:user) do
      @desc "Input values to update in user"
      arg(:input, non_null(:user_details_input))

      @desc "Admin can use user id to specify user to update"
      arg(:id, :integer)

      @desc "Admin can use user email to specify user to update"
      arg(:email, :string)

      allow(:user)
      resolve(&Resolvers.User.update_user/3)
    end

    field :reset_api_token, type: non_null(:string) do
      allow(:user)

      resolve(fn _, _, %{context: %{auth: %{user: user}}} ->
        Proca.Users.reset_api_token(user)
      end)
    end
  end

  input_object :org_user_input do
    @desc "Email of user"
    field :email, non_null(:string)
    @desc "Role name of user in this org"
    field :role, non_null(:string)
  end

  input_object :user_details_input do
    @desc "Users profile pic url"
    field :picture_url, :string
    @desc "Job title"
    field :job_title, :string
    @desc "Phone"
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

  @desc "Api token metadata"
  object :api_token do
    field :expires_at, non_null(:naive_datetime)
  end
end

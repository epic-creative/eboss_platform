defmodule EBoss.Accounts.User do
  use Ash.Resource,
    otp_app: :eboss_accounts,
    domain: EBoss.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshAuthentication]

  require Ash.Query

  authentication do
    add_ons do
      log_out_everywhere do
        apply_on_password_change?(true)
      end

      confirmation :confirm_new_user do
        monitor_fields([:email])
        confirm_on_create?(true)
        confirm_on_update?(false)
        require_interaction?(true)
        confirmed_at_field(:confirmed_at)
        auto_confirm_actions([:sign_in_with_magic_link, :reset_password_with_token])
        sender(EBoss.Accounts.User.Senders.SendNewUserConfirmationEmail)
      end
    end

    tokens do
      enabled?(true)
      token_resource(EBoss.Accounts.Token)
      signing_secret(EBoss.Secrets)
      store_all_tokens?(true)
      require_token_presence_for_authentication?(true)
    end

    strategies do
      password :password do
        identity_field(:email)
        hash_provider(AshAuthentication.BcryptProvider)
        sign_in_tokens_enabled?(true)
        sign_in_token_lifetime({30, :seconds})

        resettable do
          sender(EBoss.Accounts.User.Senders.SendPasswordResetEmail)
          password_reset_action_name(:reset_password_with_token)
          request_password_reset_action_name(:request_password_reset_token)
        end
      end

      magic_link do
        identity_field(:email)
        registration_enabled?(true)
        require_interaction?(true)
        sender(EBoss.Accounts.User.Senders.SendMagicLinkEmail)
      end

      api_key :api_key do
        api_key_relationship(:valid_api_keys)
        api_key_hash_attribute(:api_key_hash)
      end
    end
  end

  postgres do
    table("users")
    repo(EBoss.Repo)
  end

  code_interface do
    define(:change_password, action: :change_password)
    define(:list_users, action: :admin_index)
    define(:suspend_user, action: :suspend)
    define(:undo_suspend_user, action: :undo_suspend)
    define(:soft_delete_user, action: :soft_delete)
    define(:undo_delete_user, action: :undo_delete)
    define(:admin_update_user, action: :admin_update)
  end

  actions do
    defaults([:read, {:update, [:role]}])

    read :admin_index do
      description("List all users for admin interfaces")
      pagination(offset?: true, countable: true)
    end

    update :suspend do
      description("Suspend a user account")
      accept([])
      change(set_attribute(:is_suspended, true))
    end

    update :undo_suspend do
      description("Unsuspend a user account")
      accept([])
      change(set_attribute(:is_suspended, false))
    end

    update :soft_delete do
      description("Soft delete a user account")
      accept([])
      change(set_attribute(:is_deleted, true))
    end

    update :undo_delete do
      description("Undo soft deletion of a user account")
      accept([])
      change(set_attribute(:is_deleted, false))
    end

    update :admin_update do
      description("Update user information by admin")
      accept([:username, :email])
      require_atomic?(false)
      change(EBoss.Accounts.User.Changes.NormalizeUsername)
      validate(EBoss.Accounts.User.Validations.ValidateSlug)
      change(EBoss.Accounts.User.Changes.SyncWorkspaceOwnerSnapshots)
    end

    read :get_by_subject do
      description("Get a user by the subject claim in a JWT")
      argument(:subject, :string, allow_nil?: false)
      get?(true)
      prepare(AshAuthentication.Preparations.FilterBySubject)
    end

    update :change_password do
      require_atomic?(false)
      accept([])
      argument(:current_password, :string, sensitive?: true, allow_nil?: false)

      argument(:password, :string,
        sensitive?: true,
        allow_nil?: false,
        constraints: [min_length: 8]
      )

      argument(:password_confirmation, :string, sensitive?: true, allow_nil?: false)

      validate(confirm(:password, :password_confirmation))

      validate(
        {AshAuthentication.Strategy.Password.PasswordValidation,
         strategy_name: :password, password_argument: :current_password}
      )

      change({AshAuthentication.Strategy.Password.HashPasswordChange, strategy_name: :password})
    end

    read :sign_in_with_password do
      description("Attempt to sign in using an email and password.")
      get?(true)

      argument :email, :ci_string do
        description("The email to use for retrieving the user.")
        allow_nil?(false)
      end

      argument :password, :string do
        description("The password to check for the matching user.")
        allow_nil?(false)
        sensitive?(true)
      end

      prepare(AshAuthentication.Strategy.Password.SignInPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    read :sign_in_with_token do
      description("Attempt to sign in using a short-lived sign in token.")
      get?(true)

      argument :token, :string do
        description("The short-lived sign in token.")
        allow_nil?(false)
        sensitive?(true)
      end

      prepare(AshAuthentication.Strategy.Password.SignInWithTokenPreparation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    create :register_with_password do
      description("Register a new user with email, password, and username.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      argument :username, :string do
        allow_nil?(false)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      change(set_attribute(:email, arg(:email)))
      change(set_attribute(:username, arg(:username)))
      change(EBoss.Accounts.User.Changes.NormalizeUsername)
      validate(EBoss.Accounts.User.Validations.ValidateSlug)
      change(AshAuthentication.Strategy.Password.HashPasswordChange)
      change(AshAuthentication.GenerateTokenChange)
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)

      metadata :token, :string do
        description("A JWT that can be used to authenticate the user.")
        allow_nil?(false)
      end
    end

    action :request_password_reset_token do
      description("Send password reset instructions to a user if they exist.")

      argument :email, :ci_string do
        allow_nil?(false)
      end

      run({AshAuthentication.Strategy.Password.RequestPasswordReset, action: :get_by_email})
    end

    read :get_by_email do
      description("Looks up a user by their email")
      get?(true)

      argument :email, :ci_string do
        allow_nil?(false)
      end

      filter(expr(email == ^arg(:email)))
    end

    read :get_by_username do
      description("Looks up a user by their username")
      get?(true)

      argument :username, :string do
        allow_nil?(false)
      end

      prepare(fn query, _context ->
        username_arg = Ash.Query.get_argument(query, :username)
        normalized = if username_arg, do: String.downcase(username_arg), else: ""
        Ash.Query.filter(query, expr(username == ^normalized))
      end)
    end

    update :reset_password_with_token do
      argument :reset_token, :string do
        allow_nil?(false)
        sensitive?(true)
      end

      argument :password, :string do
        description("The proposed password for the user, in plain text.")
        allow_nil?(false)
        constraints(min_length: 8)
        sensitive?(true)
      end

      argument :password_confirmation, :string do
        description("The proposed password for the user (again), in plain text.")
        allow_nil?(false)
        sensitive?(true)
      end

      validate(AshAuthentication.Strategy.Password.ResetTokenValidation)
      validate(AshAuthentication.Strategy.Password.PasswordConfirmationValidation)
      change(AshAuthentication.Strategy.Password.HashPasswordChange)
      change(AshAuthentication.GenerateTokenChange)
    end

    create :sign_in_with_magic_link do
      description("Sign in or register a user with magic link.")

      argument :token, :string do
        description("The token from the magic link that was sent to the user")
        allow_nil?(false)
      end

      argument :username, :string do
        description("Username for new user registration (required for new users only)")
        allow_nil?(true)
      end

      upsert?(true)
      upsert_identity(:unique_email)
      upsert_fields([:email])

      change(AshAuthentication.Strategy.MagicLink.SignInChange)
      change(set_attribute(:username, arg(:username)))
      change(EBoss.Accounts.User.Changes.NormalizeUsername)
      validate(EBoss.Accounts.User.Validations.ValidateSlug)

      metadata :token, :string do
        allow_nil?(false)
      end
    end

    action :request_magic_link do
      argument :email, :ci_string do
        allow_nil?(false)
      end

      run(AshAuthentication.Strategy.MagicLink.Request)
    end

    read :sign_in_with_api_key do
      argument(:api_key, :string, allow_nil?: false)
      prepare(AshAuthentication.Strategy.ApiKey.SignInPreparation)
    end
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end

    policy action_type(:read) do
      authorize_if(expr(id == ^actor(:id)))
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action(:change_password) do
      authorize_if(expr(id == ^actor(:id)))
      authorize_if(expr(^actor(:role) == :admin))
    end

    policy action([:suspend, :undo_suspend, :soft_delete, :undo_delete, :admin_update]) do
      authorize_if(expr(^actor(:role) == :admin))
    end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :email, :ci_string do
      allow_nil?(false)
      public?(true)
    end

    attribute :username, :string do
      allow_nil?(false)
      public?(true)

      constraints(
        min_length: 3,
        max_length: 39
      )
    end

    attribute :hashed_password, :string do
      sensitive?(true)
    end

    attribute(:confirmed_at, :utc_datetime_usec)

    attribute :role, :atom do
      default(:user)
      allow_nil?(false)
      public?(true)
      constraints(one_of: [:user, :admin])
    end

    attribute :is_suspended, :boolean do
      default(false)
      allow_nil?(false)
      public?(true)
    end

    attribute :is_deleted, :boolean do
      default(false)
      allow_nil?(false)
      public?(true)
    end

    timestamps()
  end

  relationships do
    has_many :valid_api_keys, EBoss.Accounts.ApiKey do
      filter(expr(valid))
    end
  end

  identities do
    identity(:unique_email, [:email])
    identity(:unique_username, [:username])
  end

  def has_role?(%{role: role}, check_role) when is_atom(check_role) do
    role == check_role
  end

  def has_role?(%{role: role}, check_role) when is_binary(check_role) do
    role == String.to_existing_atom(check_role)
  rescue
    ArgumentError -> false
  end

  def has_role?(_user, _role), do: false
end

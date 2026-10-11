require "sequel/core"
require Rails.root.join("lib/omniauth/strategies/slack_openid").to_s

class UserRodauthPlugin < RodauthPlugin
  configure do
    # This block is running inside of
    #   plugin :rodauth do
    #     ...
    #   end

    # ==> Features
    # See the Rodauth documentation for the list of available config options:
    # http://rodauth.jeremyevans.net/documentation.html

    # List of authentication features that are loaded.
    enable :login, :remember, :logout, :create_account, :verify_account, :verify_account_grace_period, :reset_password, :reset_password_notify, :change_login, :verify_login_change, :change_password, :change_password_notify, :case_insensitive_login, :internal_request, :omniauth

    # ==> Social sign-in (rodauth-omniauth)
    # Each provider is offered only when its credentials are set. Callback URLs
    # to register with the provider: <RAILS_DEFAULT_URL>/users/auth/google/callback,
    # <RAILS_DEFAULT_URL>/users/auth/github/callback and
    # <RAILS_DEFAULT_URL>/users/auth/slack/callback.
    if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
      omniauth_provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"], name: :google, scope: "email,profile"
    end
    if ENV["GITHUB_CLIENT_ID"].present? && ENV["GITHUB_CLIENT_SECRET"].present?
      omniauth_provider :github, ENV["GITHUB_CLIENT_ID"], ENV["GITHUB_CLIENT_SECRET"], scope: "read:user,user:email"
    end
    # Sign in with Slack, limited to the DevCongress workspace.
    if ENV["SLACK_CLIENT_ID"].present? && ENV["SLACK_CLIENT_SECRET"].present? && ENV["SLACK_TEAM_ID"].present?
      omniauth_provider :slack_openid, ENV["SLACK_CLIENT_ID"], ENV["SLACK_CLIENT_SECRET"], name: :slack, team: ENV["SLACK_TEAM_ID"]
    end

    omniauth_identities_table :user_identities
    omniauth_identities_account_id_column :user_id

    # Social sign-in links to an existing account with the same email, so only
    # trust addresses the provider has verified. (omniauth-github only returns
    # the primary *verified* address with the user:email scope. Slack sends an
    # email_verified claim, like Google.)
    before_omniauth_callback_route do
      # Signed in: connect the identity to this account rather than looking
      # one up by email. An identity already on another account stays put.
      if logged_in?
        if omniauth_identity && omniauth_identity_account_id != session_value
          set_redirect_error_flash "That #{omniauth_provider.to_s.titleize} account is connected to another DevCongress Connect account."
          redirect notification_settings_path
        end
        # One Slack account per user, so slack_identity stays unambiguous.
        if omniauth_provider.to_s == "slack" && !omniauth_identity && !omniauth_account_identities_ds(session_value).where(omniauth_identities_provider_column => "slack").empty?
          set_redirect_error_flash "Disconnect your current Slack account first."
          redirect notification_settings_path
        end
        account_from_session
      end

      if omniauth_provider.to_s == "slack" && omniauth_extra.dig("raw_info", "https://slack.com/team_id") != Slack.team_id
        set_redirect_error_flash "That isn't the DevCongress Slack workspace."
        redirect login_path
      end

      verified = case omniauth_provider.to_s
      when "google" then [true, "true"].include?(omniauth_extra.dig("raw_info", "email_verified"))
      when "github" then omniauth_email.present?
      when "slack" then [true, "true"].include?(omniauth_extra.dig("raw_info", "email_verified"))
      else false
      end

      unless verified
        set_redirect_error_flash "We couldn't confirm your email with #{omniauth_provider.to_s.titleize}. Verify it there, or sign up with email and password."
        redirect login_path
      end

      # Signed out with a new Slack account: rodauth-omniauth links it to the
      # account with the same email. Keep that to one Slack account per user too.
      # (Looking the account up here means the callback reuses it.)
      if !logged_in? && omniauth_provider.to_s == "slack" && !omniauth_identity && account_from_omniauth &&
          !omniauth_account_identities_ds.where(omniauth_identities_provider_column => "slack").empty?
        set_redirect_error_flash "That email's account is already connected to a different Slack account."
        redirect login_path
      end

      # Connected while signed in: back to settings, not /welcome then /dashboard.
      set_session_value(login_redirect_session_key, notification_settings_path) if logged_in? && omniauth_provider.to_s == "slack"
    end

    # Keep the provider's public profile on the identity; onboarding uses it
    # to prefill the developer profile.
    omniauth_identity_insert_hash do
      super().merge(info: social_profile_info.to_json, created_at: Time.current, updated_at: Time.current)
    end
    omniauth_identity_update_hash do
      {info: social_profile_info.to_json, updated_at: Time.current}
    end

    auth_class_eval do
      def notification_settings_path
        PortalPathsHelper.routes.dashboard_portal.notification_settings_path
      end

      def social_profile_info
        omniauth_info.to_h.slice("name", "nickname", "image", "urls")
      end

      def send_welcome_email
        db.after_commit { Rodauth::UserMailer.welcome(self.class.configuration_name, account_id).deliver_later }
      end

      def login_notice_flash
        @slack_connected ? "Slack connected. Notifications now come as Slack DMs. You can turn email back on in notification settings." : super
      end

      private

      # Signing up with or connecting Slack moves notifications to Slack DMs.
      def create_omniauth_identity
        super
        return unless omniauth_provider.to_s == "slack"

        User.find(account_id).slack_connected!
        @slack_connected = true
      end

      def omniauth_verify_account
        transaction do
          super
          send_welcome_email
        end
      end
    end

    # Welcome users once their email is confirmed: by the verify link, by
    # social sign-in creating the account (created verified), or by social
    # sign-in verifying an existing unverified account with the same email.
    after_verify_account { send_welcome_email }
    after_omniauth_create_account { send_welcome_email }

    # ==> General

    # Prevent rodauth from introspecting the database if we are not using UUIDs
    convert_token_id_to_integer? { User.columns_hash["id"].type == :integer }

    # Change prefix of table and foreign key column names from default "account"
    accounts_table :users
    remember_table :user_remember_keys
    reset_password_table :user_password_reset_keys
    verify_account_table :user_verification_keys
    verify_login_change_table :user_login_change_keys

    # The secret key used for hashing public-facing tokens for various features.
    # Defaults to Rails `secret_key_base`, but you can use your own secret key.
    # hmac_secret "<SECRET_KEY>"

    # Use path prefix for all routes.
    prefix "/users"

    # Store password hash in a column instead of a separate table.
    account_password_hash_column :password_hash

    # Specify the controller used for view rendering, CSRF, and callbacks.
    rails_controller { Rodauth::UserController }

    # Specify the model to be used.
    rails_account_model { User }

    # Set password password during create account.
    # verify_account_set_password? false

    # Change some default param keys.
    # login_param "email"
    # password_confirm_param "confirm_password"

    # Redirect back to originally requested location after authentication.
    login_return_to_requested_location? true
    # two_factor_auth_return_to_requested_location? true # if using MFA

    # Autologin the user after they have reset their password.
    # reset_password_autologin? true

    # Delete the account record when the user has closed their account.
    # delete_account_on_close? true

    # Redirect to the app from login and registration pages if already logged in.
    # already_logged_in { redirect login_redirect }

    # Accept both api and form requests
    # Requires the JSON feature
    # only_json? false

    # ==> Emails
    # Use a custom mailer for delivering authentication emails.

    create_reset_password_email do
      Rodauth::UserMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end

    create_verify_account_email do
      Rodauth::UserMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
    end

    create_verify_login_change_email do |login|
      Rodauth::UserMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value, login)
    end

    create_password_changed_email do
      Rodauth::UserMailer.change_password_notify(self.class.configuration_name, account_id)
    end

    create_reset_password_notify_email do
      Rodauth::UserMailer.reset_password_notify(self.class.configuration_name, account_id)
    end

    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end

    # ==> Flash
    # Does not work with only_json?

    # Match flash keys with ones already used in the Rails app.
    # flash_notice_key :success # default is :notice
    # flash_error_key :error # default is :alert

    # Override default flash messages.
    # create_account_notice_flash "Your account has been created. Please verify your account by visiting the confirmation link sent to your email address."
    # require_login_error_flash "Login is required for accessing this page"
    # login_notice_flash nil

    # ==> Validation
    # Override default validation error messages.
    # no_matching_login_message "user with this email address doesn't exist"
    # already_an_account_with_this_login_message "user with this email address already exists"
    # password_too_short_message { "needs to have at least #{password_minimum_length} characters" }
    # login_does_not_meet_requirements_message { "invalid email#{", #{login_requirement_message}" if login_requirement_message}" }

    # ==> Passwords

    # Passwords shorter than 8 characters are considered weak according to OWASP.
    password_minimum_length 8

    # Custom password complexity requirements (alternative to password_complexity feature).
    # password_meets_requirements? do |password|
    #   super(password) && password_complex_enough?(password)
    # end
    # auth_class_eval do
    #   def password_complex_enough?(password)
    #     return true if password.match?(/\d/) && password.match?(/[^a-zA-Z\d]/)
    #     set_password_requirement_error_message(:password_simple, "requires one number and one special character")
    #     false
    #   end
    # end

    # = bcrypt

    # bcrypt has a maximum input length of 72 bytes, truncating any extra bytes.
    password_maximum_bytes 72 if respond_to?(:password_maximum_bytes)

    # ==> Remember Feature

    # Only remember users who ticked the "Remember Me" checkbox on the login form.
    after_login do
      remember_login if param_or_nil(remember_param) == remember_remember_param_value
      session[:after_welcome_redirect] = session.delete(login_redirect_session_key)
    end

    # Or remember every user who logs in, whether they asked to be or not.
    # after_login { remember_login }

    # Extend user's remember period when remembered via a cookie
    extend_remember_deadline? true

    # Store the user's remember cookie under a namespace
    remember_cookie_key "_user_remember"

    # Session security: namespace EVERY session key this configuration touches -
    # the account id plus `authenticated_by`, `login_redirect`,
    # `two_factor_auth_setup` and friends. Without this, configurations share those
    # keys and clobber each other's state, and `session_isolation` cannot tell which
    # entries belong to which configuration.
    #
    # Do not also set `session_key` here. An explicit `session_key` is NOT prefixed,
    # so the account id key would rotate on a different schedule from every other
    # key - and Rodauth crashes on a session that has an account id but no
    # `authenticated_by` (`nil.include?` in `logged_in_via_remember_key?`).
    session_key_prefix "user_"

    # ==> Hooks

    # Validate custom fields in the create account form.
    # before_create_account do
    #   throw_error_status(422, "name", "must be present") if param("name").empty?
    # end

    # Perform additional actions after the account is created.
    # after_create_account do
    #   Profile.create!(account_id: account_id, name: param("name"))
    # end

    # Do additional cleanup after the account is closed.
    # after_close_account do
    #   Profile.find_by!(account_id: account_id).destroy
    # end

    # ==> Redirects

    # Redirect to home after login.
    create_account_redirect "/welcome"

    # Redirect to home after login.
    login_redirect "/welcome"

    # Redirect to home page after logout.
    logout_redirect "/"

    # Redirect to login page after requesting account verification email.
    verify_account_email_sent_redirect { login_path }

    # Redirect to wherever login redirects to after account verification.
    verify_account_redirect { login_redirect }

    # Redirect to login page after requesting password reset.
    reset_password_email_sent_redirect { login_path }

    # Redirect to login page after password reset.
    reset_password_redirect { login_path }

    # ==> Deadlines
    # Change default deadlines for some actions.
    # verify_account_grace_period 3.days.to_i
    # reset_password_deadline_interval Hash[hours: 6]
    # verify_login_change_deadline_interval Hash[days: 2]
    # remember_deadline_interval Hash[days: 30]
  end
end

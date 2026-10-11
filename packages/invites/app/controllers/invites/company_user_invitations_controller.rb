# frozen_string_literal: true

module Invites
  class CompanyUserInvitationsController < ApplicationController
    include Plutonium::Auth::Rodauth(:user)
    include Plutonium::Invites::Controller

    prepend_view_path Invites::Engine.root.join("app/views")
    layout "invites/invitation"
    helper_method :login_path

    private

    def invite_class
      ::Invites::CompanyUserInvite
    end

    def invitation_path_for(token)
      company_user_invitation_path(token: token)
    end

    def user_class
      User
    end

    def after_accept_path
      rodauth.login_redirect
    end

    def login_path
      rodauth.login_path
    end

    # Override: this controller is accessed by unauthenticated users,
    # and the default current_user raises when not logged in.
    def current_user
      rodauth.rails_account if rodauth.logged_in?
    end

    def create_user_for_signup(email, password)
      # Normalize the login up front. Lookups (account_from_login) downcase the
      # login, so on a case-sensitive database a verbatim mixed-case email would
      # be created but never found again. Downcasing here keeps create and
      # lookup in agreement across both branches.
      email = email.downcase
      password_hash = rodauth.password_hash(password)

      if email == @invite.email.downcase
        # Email matches invitation - create verified account directly
        User.create!(
          email: email,
          password_hash: password_hash,
          status: :verified
        )
      else
        # Different email - use Internal Request API for account creation with verification
        RodauthApp.rodauth(:user).create_account(login: email, password: password)
        User.find_by(email: email)
      end
    end

    def sign_in_user(user)
      rodauth.account_from_login(user.email)
      # login_session just persists the session; `login` would redirect to
      # rodauth.login_redirect and short-circuit our post-accept redirect.
      rodauth.login_session("signup")
    end
  end
end

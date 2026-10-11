# Account emails for both Rodauth configurations (:user and :admin). Each
# subclass shares the templates in app/views/rodauth_mailer.
class RodauthMailer < ApplicationMailer
  default to: -> { @rodauth.email_to }

  def self.mailer_name = "rodauth_mailer"

  def verify_account(name, account_id, key)
    setup(name, account_id) { @verify_account_key_value = key }
    @url = @rodauth.verify_account_email_link
    mail subject: "Confirm your email for #{product_name}"
  end

  def reset_password(name, account_id, key)
    setup(name, account_id) { @reset_password_key_value = key }
    @url = @rodauth.reset_password_email_link
    mail subject: "Reset your #{product_name} password"
  end

  def verify_login_change(name, account_id, key, new_email)
    setup(name, account_id) { @verify_login_change_key_value = key }
    @url = @rodauth.verify_login_change_email_link
    @new_email = new_email
    mail to: new_email, subject: "Confirm your new email address"
  end

  def change_password_notify(name, account_id)
    setup(name, account_id)
    mail subject: "Your #{product_name} password was changed"
  end

  def reset_password_notify(name, account_id)
    setup(name, account_id)
    mail subject: "Your #{product_name} password was reset"
  end

  def unlock_account(name, account_id, key)
    setup(name, account_id) { @unlock_account_key_value = key }
    @url = @rodauth.unlock_account_email_link
    mail subject: "Unlock your #{product_name} account"
  end

  def welcome(name, account_id)
    setup(name, account_id)
    @url = absolute_url("/onboarding")
    mail subject: "Welcome to #{product_name}"
  end

  private

  def setup(name, account_id, &block)
    @rodauth = RodauthApp.rodauth(name).allocate
    @rodauth.url_options = default_url_options
    @rodauth.account_from_id(account_id)
    @rodauth.instance_eval(&block) if block
    @account = @rodauth.rails_account
    @admin = name.to_s == "admin"
    @product_name = product_name
    @first_name = first_name
    @reset_request_url = @rodauth.reset_password_request_url
  end

  def product_name = @admin ? "DevCongress Connect admin" : "DevCongress Connect"

  def first_name
    @account.try(:developer_profile)&.name.to_s.split.first
  end
end

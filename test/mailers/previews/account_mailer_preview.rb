# Account (Rodauth) emails. View at /rails/mailers/account_mailer.
# Uses existing development records; the keys are placeholders.
class AccountMailerPreview < ActionMailer::Preview
  def verify_account = Rodauth::UserMailer.verify_account(:user, user.id, "preview-key")

  def reset_password = Rodauth::UserMailer.reset_password(:user, user.id, "preview-key")

  def verify_login_change = Rodauth::UserMailer.verify_login_change(:user, user.id, "preview-key", "new-address@example.com")

  def change_password_notify = Rodauth::UserMailer.change_password_notify(:user, user.id)

  def reset_password_notify = Rodauth::UserMailer.reset_password_notify(:user, user.id)

  def welcome = Rodauth::UserMailer.welcome(:user, user.id)

  def admin_verify_account = Rodauth::AdminMailer.verify_account(:admin, admin.id, "preview-key")

  def admin_unlock_account = Rodauth::AdminMailer.unlock_account(:admin, admin.id, "preview-key")

  private

  def user = User.joins(:developer_profile).first || User.first!

  def admin = Admin.first!
end

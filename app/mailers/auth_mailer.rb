# frozen_string_literal: true

class AuthMailer < ApplicationMailer
  def sign_in
    @user = params[:user]
    @token = params[:token]

    to = @user.email
    subject = 'Confirm your email address on DevCongress Jobs'

    mail(to: to, subject: subject)
  end

  def sign_up
    @email = params[:email]
    @token = params[:token]

    to = @email
    subject = 'Complete your DevCongress Jobs registration'

    mail(to: to, subject: subject)
  end
end

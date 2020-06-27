# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # POST /resource/sign_in
  def login
    @user = sign_in_params[:email].present? && User.find_by_email(sign_in_params[:email])
    initiate_sign_in if @user
  end

  def create
    return redirect_to new_user_session_path, alert: 'Invalid confirmation token' unless inject_sign_in?

    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    redirect_to jobs_path
  end

  private

  def initiate_sign_in
    one_time_password = SecureRandom.hex
    @user.password = one_time_password
    @user.save!

    payload = { action: :login, email: @user.email, remember_me: sign_in_params[:remember_me],
                nonce: one_time_password, exp: 30.minutes.from_now.to_i }
    token = JWT.encode payload, nil, 'none'
    AuthMailer.with(user: @user, token: token).sign_in.deliver_later
  end

  def inject_sign_in?
    token = params[:token]
    decoded = JWT.decode token, nil, false if token
    unless decoded && decoded.first['action'] == 'login' && User.find_by_email(decoded.first['email'])&.encrypted_password.present?
      return
    end

    payload = decoded.first
    request.params.merge!(
      {
        user: {
          email: payload['email'],
          password: payload['nonce'],
          remember_me: payload['remember_me']
        }
      }
    )
    true
  rescue JWT::DecodeError
    false
  end
end

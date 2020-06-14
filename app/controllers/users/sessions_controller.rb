# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  #   # pp '----------------'
  #   # pp params[:user]
  #   # pp '----------------'
  # end

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

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  private

  def initiate_sign_in
    one_time_password = SecureRandom.alphanumeric
    @user.password = one_time_password
    @user.save!
    payload = { email: @user.email, remember_me: sign_in_params[:remember_me],
                nonce: one_time_password, exp: 10.minutes.from_now.to_i }
    token = JWT.encode payload, nil, 'none'
    AuthMailer.with(user: @user, token: token).sign_in.deliver_later
  end

  def inject_sign_in?
    token = params[:token]
    decoded = JWT.decode token, nil, false if token
    return unless decoded && User.find_by_email(decoded.first['email'])&.encrypted_password.present?

    payload = decoded.first
    request.params.merge!({
                            user: {
                              email: payload['email'],
                              password: payload['nonce'],
                              remember_me: payload['remember_me']
                            }
                          })
    true
  rescue JWT::DecodeError
    nil
  end
end

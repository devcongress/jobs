# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /register
  def new
    @user = User.new
    @company = Company.new
    @job = Job.new
  end

  def register
    @user = User.new user_params
    @company = @user.companies.build company_params
    @job = @company.jobs.build job_params

    # validation must occur in this order to prevent
    # association errors being displayed on the form
    # unfortunately, it means each section is validated one at a time
    initiate_sign_up if @job.valid? && @company.valid? && @user.valid?

    render :new
  end

  # GET /register/complete
  def create
    unless registration_identifier && (data = KeyValue.get(:signup, registration_identifier))
      return redirect_to new_user_registration_path, alert: 'Invalid confirmation token'
    end

    @user = User.new data['user']
    @company = @user.companies.build data['company']
    @job = @company.jobs.build data['job']

    return redirect_to new_user_registration_path, alert: 'Something went wrong' unless @user.save

    set_flash_message! :notice, :signed_up
    sign_up(resource_name, @user)
    
    KeyValue.remove(:signup, registration_identifier)

    redirect_to @job
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end

  private

  def initiate_sign_up
    identifier = SecureRandom.hex
    signup_data = {
      user: user_params,
      company: company_params,
      job: job_params
    }
    # store the submitted data for later
    KeyValue.set(:signup, identifier, signup_data)

    payload = { action: :signup, nonce: identifier, exp: 1.day.from_now.to_i }
    token = JWT.encode payload, nil, 'none'
    AuthMailer.with(email: user_params[:email], token: token).sign_up.deliver_later
  end

  def registration_identifier
    unless @registration_identifier
      token = params[:token]
      decoded = JWT.decode token, nil, false if token
      unless decoded && decoded.first['action'] == 'signup' && KeyValue.exists?(key: :signup, sub_key: decoded.first['nonce'])
        return
      end

      @registration_identifier = decoded.first['nonce']
    end
    @registration_identifier
  rescue JWT::DecodeError
    nil
  end

  def user_params
    params.require(:user).permit(
      :email
    )
  end

  def job_params
    params.require(:user).require(:job).permit(
      :role,
      :duration,
      :salary_lower,
      :salary_upper,
      :requirements,
      :qualification,
      :perks,
      :company_id,
      :remote_ok,
      :city,
      :country,
      :apply_link
    )
  end

  def company_params
    params.require(:user).require(:company).permit(
      :name,
      :industry,
      :website,
      :description,
      :email,
      :phone,
      :city,
      :state_or_region,
      :post_code,
      :country,
      :logo
    )
  end
end

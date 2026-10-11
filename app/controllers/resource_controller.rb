class ResourceController < PlutoniumController
  include Plutonium::Resource::Controller

  private def current_user
    raise NotImplementedError, "#{self.class}#current_user must return a non nil value"
  end
  helper_method :current_user

  private def logout_url
    # return a logout url to render a logout link
  end
  helper_method :logout_url

  private def profile_url
    # return a profile url to render a profile link in the user menu
    # e.g. rodauth.change_password_path or your custom profile_path
  end
  helper_method :profile_url
end

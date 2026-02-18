class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = User.find_for_database_authentication(email: sign_in_params[:email])

    if resource&.valid_password?(sign_in_params[:password])
      if resource.two_factor_enabled?
        session[:otp_user_id] = resource.id
        session[:otp_remember_me] = sign_in_params[:remember_me]
        redirect_to new_two_factor_verification_path
      else
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    else
      self.resource = resource_class.new(sign_in_params.except(:password))
      set_flash_message!(:alert, :invalid, authentication_keys: User.authentication_keys.join(', '))
      respond_with resource, status: :unprocessable_entity
    end
  end
end

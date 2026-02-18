class Users::TwoFactorVerificationsController < ApplicationController
  before_action :require_otp_user

  def new
  end

  def create
    if @user.validate_and_consume_otp!(params[:otp_attempt])
      remember_me = session.delete(:otp_remember_me)
      session.delete(:otp_user_id)

      sign_in(:user, @user)
      @user.remember_me! if remember_me == '1'

      redirect_to after_sign_in_path_for(@user), notice: I18n.t('devise.sessions.signed_in')
    else
      flash.now[:alert] = '認証コードが正しくありません。'
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_otp_user
    @user = User.find_by(id: session[:otp_user_id])
    redirect_to new_user_session_path unless @user&.two_factor_enabled?
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end
end

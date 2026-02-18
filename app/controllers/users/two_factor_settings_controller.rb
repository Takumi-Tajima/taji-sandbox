class Users::TwoFactorSettingsController < ApplicationController
  before_action :authenticate_user!

  def new
    session[:pending_otp_secret] ||= User.generate_otp_secret
    @otp_secret = session[:pending_otp_secret]
    @qr_svg = generate_qr_svg(@otp_secret)
  end

  def create
    @otp_secret = session[:pending_otp_secret]

    if @otp_secret.blank?
      redirect_to new_two_factor_setting_path, alert: 'セッションが切れました。もう一度お試しください。'
      return
    end

    if current_user.validate_and_consume_otp!(params[:otp_attempt], otp_secret: @otp_secret)
      current_user.enable_two_factor!(@otp_secret)
      session.delete(:pending_otp_secret)
      redirect_to edit_user_registration_path, notice: '二要素認証を有効にしました。'
    else
      @qr_svg = generate_qr_svg(@otp_secret)
      flash.now[:alert] = '認証コードが正しくありません。'
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    current_user.disable_two_factor!
    redirect_to edit_user_registration_path, notice: '二要素認証を無効にしました。'
  end

  private

  def generate_qr_svg(otp_secret)
    uri = current_user.otp_qr_uri(otp_secret: otp_secret)
    RQRCode::QRCode.new(uri).as_svg(color: '000', shape_rendering: 'crispEdges', module_size: 4, use_path: true)
  end
end

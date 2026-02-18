class User < ApplicationRecord
  devise :two_factor_authenticatable
  devise :registerable, :rememberable, :validatable

  def two_factor_enabled?
    otp_required_for_login?
  end

  def enable_two_factor!(secret)
    update!(otp_secret: secret, otp_required_for_login: true)
  end

  def disable_two_factor!
    update!(otp_secret: nil, otp_required_for_login: false, consumed_timestep: nil)
  end

  def otp_qr_uri(otp_secret: self.otp_secret)
    otp_provisioning_uri(email, issuer: 'TajiSandbox', otp_secret: otp_secret)
  end
end

# frozen_string_literal: true

class OtpVerification < ApplicationRecord
  validates :otp_code, presence: true
  validates :expires_at, presence: true
  validate :phone_number_or_email_present

  scope :active, -> { where('expires_at > ?', Time.current).where(verified_at: nil) }
  scope :verified, -> { where.not(verified_at: nil) }
  scope :expired, -> { where('expires_at <= ?', Time.current) }

  before_create :generate_verification_token

  def expired?
    expires_at < Time.current
  end

  def verified?
    verified_at.present?
  end

  def verify!(code)
    return false if verified?
    return false if expired?
    return false if otp_code != code.to_s

    update!(verified_at: Time.current)
    true
  end

  def self.generate_for(phone_number: nil, email: nil)
    # Invalidate any existing active OTPs for the same phone/email
    if phone_number.present?
      where(phone_number: phone_number).active.update_all(expires_at: Time.current - 1.second)
    elsif email.present?
      where(email: email).active.update_all(expires_at: Time.current - 1.second)
    end

    # Generate OTP code
    otp_code = rand(100_000..999_999).to_s
    expires_at = 10.minutes.from_now

    # Create new OTP verification
    create!(
      phone_number: phone_number,
      email: email,
      otp_code: otp_code,
      sent_at: Time.current,
      expires_at: expires_at
    )
  end

  private

  def generate_verification_token
    loop do
      self.verification_token = SecureRandom.hex(32)
      break unless self.class.exists?(verification_token: verification_token)
    end
  end

  def phone_number_or_email_present
    return if phone_number.present? || email.present?

    errors.add(:base, 'Either phone_number or email must be present')
  end
end


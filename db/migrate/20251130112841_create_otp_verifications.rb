# frozen_string_literal: true

class CreateOtpVerifications < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_verifications do |t|
      t.string :phone_number
      t.string :email
      t.string :otp_code
      t.datetime :sent_at
      t.datetime :verified_at
      t.datetime :expires_at
      t.string :verification_token

      t.timestamps
    end

    add_index :otp_verifications, :phone_number
    add_index :otp_verifications, :email
    add_index :otp_verifications, :otp_code
    add_index :otp_verifications, :verification_token, unique: true
    add_index :otp_verifications, :expires_at
  end
end

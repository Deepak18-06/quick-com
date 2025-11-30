# frozen_string_literal: true

class MakeEmailNullableInUsers < ActiveRecord::Migration[8.1]
  def change
    change_column_null :users, :email, true
    change_column_default :users, :email, nil
  end
end

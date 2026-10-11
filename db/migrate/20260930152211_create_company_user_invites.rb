# frozen_string_literal: true

class CreateCompanyUserInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :company_user_invites do |t|
      # Entity association
      t.belongs_to :company, null: false, foreign_key: true

      # Invitation details
      t.string :email, null: false
      t.text :token, null: false
      t.integer :role, null: false, default: 0
      t.integer :state, null: false, default: 0

      # Timestamps
      t.datetime :expires_at
      t.datetime :accepted_at

      # Who sent the invite (polymorphic for flexibility)
      t.belongs_to :invited_by, null: false, polymorphic: true

      # User who accepted (filled after acceptance)
      t.belongs_to :user, null: true, foreign_key: true

      # Invitable: model that triggered this invite (optional, polymorphic)
      t.belongs_to :invitable, null: true, polymorphic: true

      # Additional data
      t.jsonb :metadata, default: {}

      t.timestamps

      # Unique token index
      t.index :token, unique: true

      # Only one pending invite per email per entity
      t.index [:company_id, :email], unique: true, where: "state = 0",
        name: "index_company_user_invites_on_entity_email_pending"

      # Only one pending invite per invitable (when invitable is present)
      t.index [:invitable_type, :invitable_id],
        unique: true,
        where: "state = 0 AND invitable_id IS NOT NULL",
        name: "index_company_user_invites_on_invitable_pending"
    end
  end
end

# frozen_string_literal: true

class CreateActiveShrineAttachments < ActiveRecord::Migration[7.0]
  def change
    # Use Active Record's configured type for primary and foreign keys
    primary_key_type, foreign_key_type = primary_and_foreign_key_types

    create_table :active_shrine_attachments, id: primary_key_type do |t|
      t.belongs_to :record, polymorphic: true, null: true, type: foreign_key_type
      t.string :name, null: false
      t.string :type, null: false, default: "ActiveShrine::Attachment"
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
        t.jsonb :file_data, null: false
        t.jsonb :metadata, default: {}, null: false
      else
        t.json :file_data, null: false
        t.json :metadata, default: {}, null: false
      end

      t.timestamps
    end

    add_index :active_shrine_attachments, :name
    if ActiveRecord::Base.connection.adapter_name.downcase.include?("postgresql")
      add_index :active_shrine_attachments, :file_data, using: :gin
      add_index :active_shrine_attachments, :metadata, using: :gin
    else
      add_index :active_shrine_attachments, :file_data
      add_index :active_shrine_attachments, :metadata
    end
  end

  private

  def primary_and_foreign_key_types
    config = Rails.configuration.generators
    setting = config.options[config.orm][:primary_key_type]
    primary_key_type = setting || :primary_key
    foreign_key_type = setting || :bigint
    [primary_key_type, foreign_key_type]
  end
end

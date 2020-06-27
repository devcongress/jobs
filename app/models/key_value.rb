# frozen_string_literal: true

class KeyValue < ApplicationRecord
  validates_presence_of :key, :sub_key, :data

  def self.get(key, sub_key)
    KeyValue.find_by_key_and_sub_key(key, sub_key)&.data
  end

  def self.set(key, sub_key, data)
    return KeyValue.remove(key, sub_key) if data.blank?

    kv = KeyValue.where(key: key, sub_key: sub_key).first_or_create!(key: key, sub_key: sub_key, data: data)
    kv.data = data
    kv.save! if kv.changed?
    kv.data
  end

  def self.remove(key, sub_key)
    KeyValue.find_by_key_and_sub_key(key, sub_key)&.destroy
    nil
  end
end

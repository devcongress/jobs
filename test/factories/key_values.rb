# frozen_string_literal: true

FactoryBot.define do
  factory :key_value do
    key { 'key' }
    sub_key { 'sub_key' }
    data { '{}' }
  end
end

# External sign-in identities (Google, GitHub) for rodauth-omniauth.
class CreateUserIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :user_identities do |t|
      t.references :user, null: false, foreign_key: {on_delete: :cascade}
      t.string :provider, null: false
      t.string :uid, null: false
      t.json :info, null: false, default: {}  # name, nickname, image, urls from the provider

      t.timestamps

      t.index [:provider, :uid], unique: true
    end
  end
end

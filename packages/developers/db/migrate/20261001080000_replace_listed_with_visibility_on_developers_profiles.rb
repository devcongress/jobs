# Profiles get a three-level visibility instead of an on/off "listed" flag:
# hidden (0), members only (1), everyone/public (2).
class ReplaceListedWithVisibilityOnDevelopersProfiles < ActiveRecord::Migration[8.1]
  def up
    add_column :developers_profiles, :visibility, :integer, null: false, default: 1
    execute "UPDATE developers_profiles SET visibility = CASE WHEN listed THEN 1 ELSE 0 END"
    remove_index :developers_profiles, [:listed, :availability]
    remove_column :developers_profiles, :listed
    add_index :developers_profiles, [:visibility, :availability]
  end

  def down
    add_column :developers_profiles, :listed, :boolean, null: false, default: true
    execute "UPDATE developers_profiles SET listed = (visibility > 0)"
    remove_index :developers_profiles, [:visibility, :availability]
    remove_column :developers_profiles, :visibility
    add_index :developers_profiles, [:listed, :availability]
  end
end

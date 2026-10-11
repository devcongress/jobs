# Profiles ask for first name and other names separately. `name` stays as the
# full name (derived on save) so search, labels and display are unchanged.
class SplitDeveloperProfileNames < ActiveRecord::Migration[8.1]
  def up
    add_column :developers_profiles, :first_name, :string
    add_column :developers_profiles, :other_names, :string

    select_rows("SELECT id, name FROM developers_profiles").each do |id, name|
      first_name, other_names = name.to_s.squish.split(" ", 2)
      update "UPDATE developers_profiles SET first_name = #{quote(first_name.to_s)}, other_names = #{quote(other_names)} WHERE id = #{id.to_i}"
    end

    change_column_null :developers_profiles, :first_name, false
  end

  def down
    remove_column :developers_profiles, :first_name
    remove_column :developers_profiles, :other_names
  end
end

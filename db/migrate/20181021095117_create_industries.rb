class CreateIndustries < ActiveRecord::Migration[5.2]
  def change
    create_table :industries do |t|
      t.text :name, null: false

      t.timestamps
    end

    reversible do |m|
      m.up do
        execute "CREATE UNIQUE INDEX lower_industry_name ON industries (lower(name))"
      end

      m.down do
        execute "DROP INDEX lower_industry_name"
      end
    end

  end
end

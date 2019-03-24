class ChangeJobSalaryToRange < ActiveRecord::Migration[5.2]
  def change
    execute <<-SQL
-- Please Note:
-- Things might have changed a lot by the time you're running
-- this migration, in which case you should look at what's in
-- ELSE and do the appropriate thing.
--
-- Mostly, the conversions are based on historical values that were
-- available to job posters.
ALTER TABLE jobs
  ALTER salary TYPE numrange USING
  CASE salary
  WHEN '$0 - $1k / month'  THEN numrange(0.0, 1000.0, '[]')
  WHEN '$2k - $5k / month' THEN numrange(2000.0, 5000.0, '[]')
  WHEN 'Up to USD 500'     THEN numrange(0, 500.0, '[]')
  WHEN 'USD 500 - 1k'      THEN numrange(500.0, 1000.0, '[]')
  WHEN 'USD 1k - 2k'       THEN numrange(1000.0, 2000.0, '[]')
  WHEN 'USD 1 - 2k'        THEN numrange(1000.0, 2000.0, '[]')
  WHEN 'USD 2k - 3k'       THEN numrange(1000.0, 2000.0, '[]')
  WHEN 'USD 2 - 3k'        THEN numrange(1000.0, 2000.0, '[]')
  WHEN 'USD 3k+'           THEN numrange(3000.0, null)
  ELSE                          numrange(0, salary::numeric)
  END
    SQL
  end
end

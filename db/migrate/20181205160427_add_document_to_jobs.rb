class AddDocumentToJobs < ActiveRecord::Migration[5.2]
  def change
    enable_extension :citext
    add_column :jobs, :full_text_search, :tsvector

    reversible do |m|
      m.up do
        # Update existing job posts.
        execute <<-SQL
UPDATE jobs
   SET full_text_search =
          to_tsvector(
              'english', -- We only support English
              coalesce(role, '')
              || ' ' || coalesce(qualification, '')
              || ' ' || coalesce(requirements, '')
              || ' ' || coalesce(perks, '')
          );
        SQL

        # Add `NOT NULL` constraint. The following `BEFORE INSERT`
        # trigger ensures that the value of `full_text_search` is always
        # set.
        change_column_null :jobs, :full_text_search, false

        execute <<-SQL
--
-- Add a `BEFORE INSERT, UPDATE` trigger to update
-- the contents of full_text_search for this job post.
-- Any time any of the input columns change we
-- should build a new body.
--
CREATE OR REPLACE FUNCTION prepare_full_text_search_document()
RETURNS TRIGGER
AS $prepare_full_text_search_document$
DECLARE
  new_document tsvector;
BEGIN
  -- We expect all columns used in preparing the document
  -- to have a `NOT NULL` constraint. Regardless, we `coalesce`
  -- just to be double sure that we're dealing with strings.
  new_document :=
    to_tsvector(
      'english', -- We only support English
      coalesce(NEW.role, '')
      || ' ' || coalesce(NEW.qualification, '')
      || ' ' || coalesce(NEW.requirements, '')
      || ' ' || coalesce(NEW.perks, '')
    );

  NEW.full_text_search := new_document;
  RETURN NEW;
END;
$prepare_full_text_search_document$ LANGUAGE plpgsql;

CREATE TRIGGER trg_prepare_full_text_search_document
BEFORE INSERT OR UPDATE OF role, qualification, requirements, perks ON jobs
FOR EACH ROW
EXECUTE PROCEDURE prepare_full_text_search_document();
        SQL
      end

      m.down do
        execute <<-SQL
--
-- Drop both trigger and function, in that order.
--
DROP TRIGGER IF EXISTS trg_prepare_full_text_search_document ON jobs;
DROP FUNCTION IF EXISTS prepare_full_text_search_document();
        SQL
      end
    end
  end
end

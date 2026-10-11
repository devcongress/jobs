# Idempotent: safe to run on every deploy (bin/rails db:seed).

# Skills for profiles and project stacks. See db/seeds/skills.yml for where the
# list comes from. Inserts the ones missing, matched by slug so case is ignored.
skills = YAML.load_file(Rails.root.join("db/seeds/skills.yml")).values.flatten.index_by { |name| Skill.slug_for(name) }
missing = skills.keys - Skill.pluck(:slug)
Skill.insert_all!(missing.map { |slug| {name: skills.fetch(slug), slug:} })

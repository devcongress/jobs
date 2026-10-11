class SkillDefinition < ::ResourceDefinition
  # Also powers the typeahead wherever a skill is picked.
  search do |scope, query|
    scope.where("LOWER(skills.name) LIKE ?", "%#{scope.sanitize_sql_like(query.to_s.downcase)}%")
  end

  sort :name
  default_sort :name, :asc
end

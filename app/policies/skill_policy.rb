# Skills are a global taxonomy curated by admins. Every portal can read them
# (e.g. to pick skills for a profile), so they are never entity scoped.
class SkillPolicy < ::ResourcePolicy
  relation_scope do |relation|
    skip_default_relation_scope!
    relation
  end

  def create? = false

  def read? = true

  def permitted_attributes_for_read
    %i[name slug]
  end
end

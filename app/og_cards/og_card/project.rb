module OgCard
  class Project < Base
    def initialize(project)
      @project = project
      @owner = project.owner
    end

    def eyebrow = "Project"

    def title = @project.title

    def subtitle = "by #{@owner.name}"

    def body = @project.summary

    def footer = @project.skills.map(&:name).first(4).join(" · ").presence

    def avatar = avatar_for(@owner.name, seed: @owner.handle)

    def route = [:og_project_image, {slug: @project.slug}]

    def cache_key = ["project", @project.cache_key_with_version, @owner.cache_key_with_version, @project.skills.map(&:id)]
  end
end

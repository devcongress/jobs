module Network
  class FollowDefinition < Network::ResourceDefinition
    field :created_at, label: "Since"
    default_sort :created_at, :desc
  end
end

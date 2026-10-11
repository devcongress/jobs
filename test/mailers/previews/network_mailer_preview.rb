# Follow emails. View at /rails/mailers/network_mailer.
class NetworkMailerPreview < ActionMailer::Preview
  def new_follower
    Network::FollowMailer.with(follow: one_way_follow || sample_follow).followed
  end

  def now_connected
    follow = Network::Follow.find { |f| f.mutual? } || sample_follow
    Network::FollowMailer.with(follow:).followed
  end

  private

  def one_way_follow
    Network::Follow.find { |f| !f.mutual? }
  end

  def sample_follow
    follower, followee = Developers::Profile.first(2)
    Network::Follow.new(follower:, followee:)
  end
end

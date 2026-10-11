require "test_helper"

class NetworkTest < ActionDispatch::IntegrationTest
  include Plutonium::Testing::AuthHelpers
  include AccountsTestHelper
  include ActionMailer::TestHelper

  setup do
    @ada = create_profile!(name: "Ada Lovelace", handle: "ada", visibility: :everyone)
    @kwame = create_profile!(name: "Kwame Mensah", handle: "kwame", visibility: :everyone,
      contact_email: "kwame@example.com", contact_visibility: :connections)
    @rails = @kwame.profile_skills.create!(skill: Skill.create!(name: "Rails"))
  end

  test "following back connects two developers" do
    login_user(@ada.user)

    assert_enqueued_email_with Network::FollowMailer, :followed, params: ->(params) { params[:follow].followee == @kwame } do
      post "/@kwame/follow"
    end
    assert_redirected_to "/@kwame"
    follow_redirect!
    assert_includes response.body, "You&#39;re following Kwame Mensah."
    assert @ada.following?(@kwame)
    assert_not @ada.connected_to?(@kwame)

    # Contact details shared with connections only aren't visible yet.
    assert_not_includes response.body, "kwame@example.com"
    assert_includes response.body, "shares contact details with connections only"

    @kwame.outgoing_follows.create!(followee: @ada)
    assert @ada.connected_to?(@kwame)
    assert_equal [@kwame], @ada.connections.to_a

    get "/@kwame"
    assert_includes response.body, "kwame@example.com"
    assert_includes response.body, "You're connected"

    # Unfollowing ends the connection.
    delete "/@kwame/follow"
    assert_not @ada.reload.connected_to?(@kwame)
  end

  test "you need a developer profile to follow, and can't follow yourself" do
    post "/@kwame/follow"
    assert_redirected_to "/users/login"

    login_user(create_user!)
    post "/@kwame/follow"
    assert_redirected_to "/setup/developer/new"

    login_user(@ada.user)
    post "/@ada/follow"
    assert_equal 0, Network::Follow.count
  end

  test "hidden profiles can't be followed" do
    @kwame.update!(visibility: :hidden)
    login_user(@ada.user)
    post "/@kwame/follow"
    assert_response :not_found
    assert_equal 0, Network::Follow.count
  end

  test "only connections can endorse a skill" do
    login_user(@ada.user)

    post "/@kwame/skills/rails/endorsement"
    assert_equal 0, @rails.reload.endorsements_count
    follow_redirect!
    assert_includes response.body, "Only connections can endorse skills"

    @ada.outgoing_follows.create!(followee: @kwame)
    @kwame.outgoing_follows.create!(followee: @ada)

    get "/@kwame"
    assert_select "form[action='/@kwame/skills/rails/endorsement'] button", text: /Endorse/
    post "/@kwame/skills/rails/endorsement"
    assert_equal 1, @rails.reload.endorsements_count
    assert_equal [@ada], @rails.endorsers.to_a

    # Endorsing twice doesn't count twice; removing it does.
    post "/@kwame/skills/rails/endorsement"
    assert_equal 1, @rails.reload.endorsements_count
    delete "/@kwame/skills/rails/endorsement"
    assert_equal 0, @rails.reload.endorsements_count
  end

  test "nobody can endorse their own skills" do
    endorsement = @rails.endorsements.new(endorser: @kwame)
    assert_not endorsement.valid?
    assert_includes endorsement.errors.full_messages, "You can't endorse your own skills"
  end

  test "the network page lists connections, followers and suggestions" do
    grace = create_profile!(name: "Grace Hopper", handle: "grace", visibility: :members)
    hidden = create_profile!(name: "Secret Squirrel", handle: "secret", visibility: :hidden)
    @ada.outgoing_follows.create!(followee: @kwame)
    @kwame.outgoing_follows.create!(followee: @ada)
    @kwame.outgoing_follows.create!(followee: grace)
    hidden.outgoing_follows.create!(followee: @ada)

    login_user(@ada.user)
    get "/developer/ada/network"
    assert_response :success
    assert_includes response.body, "Kwame Mensah"

    get "/developer/ada/network?tab=followers"
    assert_includes response.body, "Kwame Mensah"
    assert_not_includes response.body, "Secret Squirrel"

    # Grace is followed by a connection, so she's suggested.
    get "/developer/ada/network?tab=suggestions"
    assert_includes response.body, "Grace Hopper"
    assert_equal [grace], @ada.suggested_profiles.to_a
  end

  test "following emails once a week per pair at most" do
    Rails.cache.clear
    with_memory_cache do
      assert_enqueued_emails 1 do
        follow = @ada.outgoing_follows.create!(followee: @kwame)
        follow.destroy!
        @ada.outgoing_follows.create!(followee: @kwame)
      end
    end
  end

  private

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end

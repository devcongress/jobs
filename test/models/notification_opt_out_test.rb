require "test_helper"

class NotificationOptOutTest < ActiveSupport::TestCase
  include AccountsTestHelper

  setup { @user = create_user! }

  test "every category is on in every channel until the user opts out" do
    assert @user.wants_notification?(:network, via: :email)

    @user.opt_out!(:network, via: :email)
    @user.opt_out!(:network, via: :email)

    assert_not @user.wants_notification?(:network, via: :email)
    assert @user.wants_notification?(:network, via: :slack)
    assert @user.wants_notification?(:applications, via: :email)
    assert_equal 1, @user.notification_opt_outs.count
  end

  test "only known categories and channels" do
    assert_raises(ActiveRecord::RecordInvalid) { @user.opt_out!(:marketing, via: :email) }
    assert_raises(ActiveRecord::RecordInvalid) { @user.opt_out!(:network, via: :sms) }
  end

  test "update_opt_outs! turns off exactly the given categories in one channel" do
    @user.opt_out!(:network, via: :email)
    @user.opt_out!(:network, via: :slack)

    @user.update_opt_outs!(%w[applications project_credits], via: :email)
    assert_equal %w[applications project_credits], @user.notification_opt_outs.where(channel: "email").pluck(:category).sort
    assert_equal %w[network], @user.notification_opt_outs.where(channel: "slack").pluck(:category)

    @user.update_opt_outs!([], via: :email)
    assert_not @user.notification_opt_outs.exists?(channel: "email")
  end

  test "tokens resolve to their user, channel and category" do
    assert_equal [@user, "email", "network"], NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :email))
    assert_equal [@user, "slack", "network"], NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :slack))
    assert_nil NotificationOptOut.resolve("garbage")
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :marketing, via: :email))
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(@user, :network, via: :sms))
    assert_nil NotificationOptOut.resolve(NotificationOptOut.token_for(User.new(id: 0), :network, via: :email))
  end

  test "tokens from emails sent before channels existed still work" do
    old_token = NotificationOptOut.send(:verifier).generate([@user.id, "network"], purpose: :unsubscribe)
    assert_equal [@user, "email", "network"], NotificationOptOut.resolve(old_token)
  end
end

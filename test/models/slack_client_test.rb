require "test_helper"

class SlackClientTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body, :headers) do
    def [](name) = headers[name]
  end

  # A client whose HTTP call returns a canned response and remembers the request.
  def client_returning(code: "200", body: {ok: true}, headers: {})
    Class.new(Slack::Client) do
      attr_reader :request

      define_method(:http_post) do |uri, form, headers_sent|
        @request = {uri:, form:, headers: headers_sent}
        Response.new(code, body.to_json, headers)
      end
    end.new("xoxb-test")
  end

  test "posts form-encoded params with the bot token" do
    client = client_returning(body: {ok: true, ts: "1.2"})
    result = client.post_message(channel: "C1", text: "Hi", blocks: [{type: "divider"}])

    assert_equal "1.2", result["ts"]
    assert_equal "https://slack.com/api/chat.postMessage", client.request[:uri].to_s
    assert_equal "Bearer xoxb-test", client.request[:headers]["Authorization"]
    form = URI.decode_www_form(client.request[:form]).to_h
    assert_equal "C1", form["channel"]
    assert_equal [{"type" => "divider"}], JSON.parse(form["blocks"])
    assert_equal "false", form["unfurl_links"]
  end

  test "update and permalink call their methods" do
    client = client_returning(body: {ok: true, permalink: "https://x.slack.com/p1"})
    assert_equal "https://x.slack.com/p1", client.permalink(channel: "C1", ts: "1.2")
    assert_equal "1.2", URI.decode_www_form(client.request[:form]).to_h["message_ts"]

    client.update_message(channel: "C1", ts: "1.2", text: "Edited")
    assert_equal "https://slack.com/api/chat.update", client.request[:uri].to_s
  end

  test "Slack errors raise with their code" do
    error = assert_raises(Slack::Error) { client_returning(body: {ok: false, error: "channel_not_found"}).post_message(channel: "C1", text: "x") }
    assert_equal "channel_not_found", error.code
  end

  test "rate limits raise with the wait" do
    client = client_returning(code: "429", body: {ok: false, error: "ratelimited"}, headers: {"Retry-After" => "30"})
    error = assert_raises(Slack::RateLimited) { client.post_message(channel: "C1", text: "x") }
    assert_equal 30, error.retry_after
  end

  test "a 5xx with an HTML body raises Unavailable" do
    client = client_returning(code: "503", body: "<html>Service Unavailable</html>")
    assert_raises(Slack::Unavailable) { client.post_message(channel: "C1", text: "Hi") }
  end

  test "configuration" do
    Slack.client = nil
    Slack.jobs_channel = nil
    assert_not Slack.configured?
    assert_not Slack.posts_jobs?

    Slack.client = Slack::FakeClient.new
    assert Slack.configured?
    assert_not Slack.posts_jobs?

    Slack.jobs_channel = "C0JOBS"
    assert Slack.posts_jobs?
  ensure
    Slack.client = nil
    Slack.jobs_channel = nil
  end

  test "escape and url" do
    assert_equal "R&amp;D &lt;Lead&gt;", Slack.escape("R&D <Lead>")
    assert_match %r{\Ahttps?://example.com(:\d+)?/jobs/1\z}, Slack.url("/jobs/1")
  end
end

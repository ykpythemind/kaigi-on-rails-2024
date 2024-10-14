# 3 OmniAuthなしで認証レスポンスを受け取る

ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup"
require "digest"
Bundler.require(:default)

require "active_support/all"

app = Rack::Builder.new do
  run lambda { |env|
    request = Rack::Request.new(env)

    case request.path_info
    when "/"
      [200, {}, [html(<<-HTML)]]
        <form method='post' action='/auth/google_oauth2'>
          <button type='submit'>Signin with Google</button>
        </form>
      HTML
    when "/auth/google_oauth2"
      query = {
        client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
        redirect_uri: "http://localhost:4567/auth/google_oauth2/callback",
        response_type: "code",
        scope: "email profile openid",
      }
      auth_url = "https://accounts.google.com/o/oauth2/auth?#{query.to_query}"

      [301, {'Location' => auth_url, 'Content-Type' => 'text/html'}, ['Moved Permanently']]
    when /\/auth\/google_oauth2\/callback/
      client = Faraday.new { _1.request(:url_encoded) }

      response = client.post("https://oauth2.googleapis.com/token") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"

        req.body = {
          grant_type: "authorization_code",
          code: request.params["code"],
          redirect_uri: "http://localhost:4567/auth/google_oauth2/callback",
          client_id: ENV.fetch("GOOGLE_CLIENT_ID"),
          client_secret: ENV.fetch("GOOGLE_CLIENT_SECRET"),
        }
      end

      json = JSON.parse(response.body)
      [200, {}, [html("callback result:<br /><br />#{json}")]]
    else
      [404, {}, [html("unexpected request to #{request.fullpath}")]]
    end
  }

  def html(body) = "<html><body>#{body}</body></html>"
end

Rackup::Server.start(app:, Port: 4567)

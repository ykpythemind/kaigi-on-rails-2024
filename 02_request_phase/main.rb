# 2 OmniAuthなしで認証リクエストを送る
#
# 注意事項: 本番環境では `state` パラメータ、 Rack::Protection::AuthenticityToken を使って CSRF 対策を行うこと

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
    when "/auth/google_oauth2/callback"
      [400, {}, ["callback is not implemented"]]
    end
  }

  def html(body) = "<html><body>#{body}</body></html>"
end

Rackup::Server.start(app:, Port: 4567)

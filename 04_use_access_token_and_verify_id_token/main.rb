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
    when "/auth/google_oauth2/callback"
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
      claims = verify_id_token(json["id_token"])
      user_info = get_user_info(json["access_token"])

      puts "**** id_token claims ****\n#{claims}"
      puts "**** user_info ****\n#{user_info}"

      [200, {}, [html("Hello, #{user_info["name"]}! Your ID is #{claims["sub"]}")]]
    else
      [404, {}, [html("unexpected request to #{request.fullpath}")]]
    end
  }

  def html(body) = "<html><body>#{body}</body></html>"

  # id_token (jwt) をデコードして検証します。結果としてクレームを返します
  def verify_id_token(id_token)
    claims = JWT.decode(id_token, nil, false, algorithm: "RS256")[0]

    # 本来は 署名の検証や exp, iat などのクレームも検証するが今回は簡略化のため省略
    # 詳細: https://developers.google.com/identity/openid-connect/openid-connect?hl=ja#validatinganidtoken
    # issとaudクレームの検証のみ行う
    raise "invalid issuer" unless claims["iss"] == "https://accounts.google.com"
    raise "invalid audience" unless claims["aud"] == ENV.fetch("GOOGLE_CLIENT_ID")

    claims
  end

  def get_user_info(access_token)
    response = Faraday.get("https://www.googleapis.com/oauth2/v1/userinfo", nil, {
      "Authorization" => "Bearer #{access_token}",
    })
    JSON.parse(response.body)
  end
end

Rackup::Server.start(app:, Port: 4567)

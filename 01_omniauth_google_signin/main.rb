# 1 Googleでログインをomniauth gemを使って実装する
#
# how to
#   https://console.cloud.google.com/apis/credentials/consent からOAuth同意画面を設定
#     User Type：外部にしつつ、テストアカウントに自分のgoogleアカウントを追加
#     スコープを追加または削除→スコープ：auth/userinfo.email, auth/userinfo.profile, openid をつける
#   https://console.cloud.google.com/apis/credentials から認証情報を作成
#     タイプ：Webアプリケーション
#     リダイレクトURI： http://localhost:4567/auth/google_oauth2/callback
#   作成したクライアントIDとクライアントシークレットを環境変数に設定
#     $ export GOOGLE_CLIENT_ID=xxxxx
#     $ export GOOGLE_CLIENT_SECRET=xxxxx
#   Webサーバを起動
#     $ ruby main.rb
#   => http://localhost:4567 にアクセス

ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
require "bundler/setup"
require "digest"
Bundler.require(:default)

app = Rack::Builder.new do
  use Rack::Session::Cookie, secret: Digest::SHA256.hexdigest("secret")
  use Rack::Protection::AuthenticityToken
  use OmniAuth::Builder do
    provider :google_oauth2, ENV.fetch("GOOGLE_CLIENT_ID"), ENV.fetch("GOOGLE_CLIENT_SECRET"),
      provider_ignores_state: true, # <- DO NOT USE IN PRODUCTION
      scope: "email,profile,openid"
  end

  run lambda { |env|
    request = Rack::Request.new(env)

    case request.path_info
    when "/"
      [200, {}, [html(<<-HTML)]]
        <form method='post' action='/auth/google_oauth2'>
          <input type="hidden" name="authenticity_token" value="#{Rack::Protection::AuthenticityToken.token(env['rack.session'])}">
          <button type='submit'>Signin with Google</button>
        </form>
      HTML
    when "/auth/google_oauth2/callback"
      auth_hash = request.env["omniauth.auth"].to_h # omniauthを経由して認証した結果を取得
      puts "**** auth_hash ****\n#{auth_hash}"

      [200, {}, [html("hello #{auth_hash["info"]["name"]}")]]
    else
      [400, {}, [html("unexpected request to #{request.fullpath}")]]
    end
  }

  def html(body) = "<html><body>#{body}</body></html>"
end

Rackup::Server.start(app:, Port: 4567)

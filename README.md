# Kaigi on Rails 2024

- [OmniAuthから学ぶOAuth2.0](https://kaigionrails.org/2024/talks/ykpythemind/) の資料
- サンプル動画 https://www.youtube.com/watch?v=4TP1lchNE6w

## 注意事項

- 本リポジトリのコードは本番環境での利用を想定していません
  - state の利用などセキュリティ考慮事項が不十分な部分があります
  - 実際に本番環境で実装する際には OmniAuth のドキュメントを参照してください
  - OpenID ConnectのRPとしての実装は omniauth-openid-connect gemを用いてください

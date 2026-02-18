# 二要素認証 (2FA) 実装まとめ

## 概要

devise-two-factor v6.4.0 を使用した TOTP（Time-based One-Time Password）ベースの二要素認証。
ユーザーは Google Authenticator 等の認証アプリでワンタイムパスワードを生成し、ログイン時に入力する。

## 技術スタック

- **devise-two-factor** (6.4.0) — Devise に 2FA 機能を追加
- **rotp** (~> 6.0) — TOTP の生成・検証（devise-two-factor の依存）
- **rqrcode** (3.2.0) — QR コードの SVG 生成
- **Active Record Encryption** — `otp_secret` カラムの暗号化

## DB カラム（users テーブル）

| カラム | 型 | 用途 |
|---|---|---|
| `otp_secret` | string | TOTP シークレットキー（AR Encryption で暗号化） |
| `consumed_timestep` | integer | 最後に使用された OTP のタイムステップ（リプレイ攻撃防止） |
| `otp_required_for_login` | boolean | 2FA が有効かどうかのフラグ |

## 認証フロー

### ログイン（2FA 有効ユーザー）

```
[メール+パスワード入力] → [パスワード検証OK]
  → session[:otp_user_id] に保存
  → /two_factor_verification/new へリダイレクト
  → [6桁OTP入力] → [OTP検証OK] → ログイン完了
```

### ログイン（2FA 無効ユーザー）

```
[メール+パスワード入力] → [パスワード検証OK] → ログイン完了
```

### 2FA セットアップ

```
[アカウント編集ページ] → 「二要素認証を設定する」
  → /two_factor_setting/new（QRコード表示）
  → 認証アプリでQRスキャン
  → [6桁OTP入力] → [OTP検証OK]
  → otp_secret と otp_required_for_login を DB に保存
  → 2FA 有効化完了
```

## ファイル構成

### モデル

**app/models/user.rb**

```ruby
two_factor_enabled?        # otp_required_for_login? のラッパー
enable_two_factor!(secret) # OTP secret を保存して 2FA を有効化
disable_two_factor!        # otp_secret, otp_required_for_login, consumed_timestep をクリア
otp_qr_uri(otp_secret:)   # otpauth:// URI を生成（QRコードの元データ）
```

### コントローラ

| ファイル | 役割 |
|---|---|
| `app/controllers/users/sessions_controller.rb` | Devise SessionsController をオーバーライド。`create` でパスワード検証後、2FA 有効なら OTP 画面へ分岐 |
| `app/controllers/users/two_factor_settings_controller.rb` | 2FA の設定（`new`）、有効化（`create`）、無効化（`destroy`） |
| `app/controllers/users/two_factor_verifications_controller.rb` | ログイン時の OTP 入力（`new`）と検証（`create`） |

### ビュー

| ファイル | 内容 |
|---|---|
| `app/views/users/two_factor_settings/new.html.haml` | QR コード表示 + OTP 確認フォーム |
| `app/views/users/two_factor_verifications/new.html.haml` | ログイン時 OTP 入力フォーム |
| `app/views/users/registrations/edit.html.haml` | アカウント編集ページに 2FA セクション追加 |

### ルーティング

```ruby
devise_for :users, controllers: { sessions: 'users/sessions' }
resource :two_factor_setting, only: %i[new create destroy]
resource :two_factor_verification, only: %i[new create]
```

## 設計上のポイント

### Warden strategy の bypass

devise-two-factor のデフォルト Warden strategy はパスワードと OTP を同時に検証する。
二段階フロー（パスワード → OTP を別画面で入力）を実現するため、`Sessions#create` で
`User.find_for_database_authentication` + `valid_password?` を使って直接パスワードを検証し、
Warden の認証フローをバイパスしている。

### 仮 secret のセッション管理

2FA セットアップ中、QR コード表示から OTP 検証完了までの間、仮の `otp_secret` を
`session[:pending_otp_secret]` に保持する。hidden field ではなくサーバーサイドセッションに
保存することで、secret のクライアント露出を防いでいる。
OTP 検証成功後に初めて DB に保存する。

### remember_me の引き継ぎ

ログインフォームの「ログインを記憶する」チェック状態を `session[:otp_remember_me]` に保持し、
OTP 検証成功後に `@user.remember_me!` で反映する。

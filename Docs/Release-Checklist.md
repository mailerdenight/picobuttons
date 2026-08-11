# Pico Buttons リリース準備チェックリスト

更新日: 2026-08-11 / 対象バージョン: 1.0 (build 1)

## 提出を止める項目

- [ ] **AdMob本番値**: `Info.plist` の `GADApplicationIdentifier` と `AdConfiguration` のバナー／インタースティシャルIDはGoogle公式テストIDです。AdMobで本アプリを作成し、3つすべてを本番IDへ置換するまで提出しないこと。
- [ ] **プライバシーポリシー**: 設定画面の `https://example.com/privacy` を、公開済みで実際の広告SDK・購入・問い合わせのデータ取扱いを説明するHTTPS URLへ置換すること。App Store Connectにも同じURLを登録すること。
- [ ] **Proの提供内容**: 現在はStoreKit 2による買い切り購入・復元と広告非表示だけが動作する。告知している「追加サウンド、お気に入り、連打モード、タイマー停止、音量制限、親モード」は未実装であり、実装・検証前に販売／告知しないこと。
- [ ] **App Store Connectの商品**: non-consumable `com.atsushichiba.picobuttons.pro` を作成し、価格、審査用スクリーンショット、ローカライズされた表示名・説明を登録すること。Sandbox購入と復元を実機で確認すること。

## AdMob と子供利用への対応

- [ ] AdMobでアプリを子供が利用しうる前提で設定し、ブロッキングコントロールの最大コンテンツ評価を **G** に設定する。不要な広告ソース／カテゴリを無効化する。
- [ ] UMPの同意メッセージとプライバシーオプションを本番設定で公開する。アプリ内の「プライバシー設定」から表示できることを実機で確認する。
- [ ] 実機では必ずテストデバイスまたはGoogleのテスト広告で確認し、本番広告をクリックしない。
- [ ] アプリを **Kids Category / Made for Kids** に登録するかは、広告を残す前に判断する。Kids Categoryを選ぶと、第三者広告・購入導線・外部リンクには追加の厳格な制約と保護者ゲートが必要になる。

## App Store Connect

- [ ] App Privacy: AdMob/UMPを含む最終SDKの実データ収集を、広告SDKの最新ドキュメントと実際の設定に基づいて申告する。広告SDKを使うため「データを収集しない」とは申告しない。
- [ ] Age Rating: アンケートを実装内容どおりに全問回答する。UGC、Web閲覧、ギャンブル、暴力的コンテンツ、ソーシャル機能は本アプリにない場合は「なし」とする。広告が年齢評価へ及ぼす影響も最終設定で再確認する。
- [ ] アプリ説明・スクリーンショットに「子供向け」「for kids」等を用いる場合は、Kids Category要件との整合を確認する。Kids Categoryを選ばないなら、そのような主対象を示す表現は使わない。
- [ ] サポートURL、マーケティングURL（使う場合）、著作権、連絡先、配信地域、輸出コンプライアンスを登録する。
- [ ] 課金を審査へ提出するバージョンに関連付ける。審査メモには、設定→Proで購入／復元できること、広告の表示条件、テスト用アカウントが必要ならその手順を記載する。

## 提出前の最終確認

- [ ] 実機で初回起動、音の連打、バックグラウンド復帰、縦横回転、バナー表示、設定画面、カテゴリ変更を確認する。
- [ ] インタースティシャルが、起動直後・パッド直後・音声再生中には出ず、自然な区切りだけで出ることを確認する。
- [ ] Pro購入直後と復元後に、バナーとインタースティシャルが消えることを確認する。
- [ ] Releaseアーカイブを作成し、OrganizerのValidate Appを実行する。警告とPrivacy Manifestを確認してからApp Store Connectへアップロードする。
- [ ] `zsh Scripts/check_release_readiness.sh` が成功することを確認する。成功後は `Docs/ExportOptions-AppStore.plist` を使ってApp Store Connect向けにエクスポートできる。

## ローカル検証済み

- 2026-08-11: `xcodebuild ... -configuration Debug build CODE_SIGNING_ALLOWED=NO` 成功。
- 2026-08-11: `xcodebuild ... -configuration Release -sdk iphoneos archive CODE_SIGNING_ALLOWED=NO` 成功。

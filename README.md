# StartLine MVP

出発前の準備、任意タスク、移動時間、到着バッファをまとめて逆算するスマホ前提のMVPです。

## 開き方

PCで試す場合は `index.html` をブラウザで開きます。

スマホ実機で試す場合は、同じWi-FiにつないだPCでローカルサーバーを起動し、スマホからPCのIPアドレスにアクセスします。

## 初期MVPでできること

- 到着時刻から「人間開始」時刻を逆算
- シャワー、ヘアセット、メイクなどの必須ルーティンを編集
- ジム、朝食などの任意タスクが入るか判定
- 移動時間と交通ゆらぎを加味
- SNS共有文をコピー
- ルーティンをブラウザに保存

## 次に追加する候補

- 通知
- Googleカレンダー連携
- 交通API連携
- 共有カード画像生成
- 有料版の回数制限とPlusプラン

## GitHubバックアップ

GitHub同期とバージョン更新の運用は [GITHUB_SYNC.md](./GITHUB_SYNC.md) にまとめています。

バージョン更新とバックアップを同時に行う:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1
```

GitHub remote `origin` を設定していれば、コミットとタグが自動でpushされます。

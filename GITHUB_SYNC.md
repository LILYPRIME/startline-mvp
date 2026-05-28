# GitHub同期と自動バックアップ

## 方針

このMVPは `departure-planner-mvp` 単体をGitHubに同期する。  
`Playground` 全体には他の実験ファイルが多いため、MVPだけを独立したGitリポジトリとして扱う。

現在の公開URL:

https://lilyprime.github.io/startline-mvp/

## 使うコマンド

変更を見張ってGitHubへ自動バックアップする:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\auto-backup.ps1
```

一度だけ現在の変更をcommit/pushする:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\auto-backup.ps1 -Once
```

公開ブランチだけ更新する:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\publish-pages.ps1
```

バージョンを上げてバックアップする:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1
```

明示的にバージョンを指定する:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1 -Version 0.2.0
```

minor / major を上げる:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1 -Bump minor
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1 -Bump major
```

GitHubへpushせずローカルだけバックアップする:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1 -NoPush
```

## このコマンドがやること

1. `VERSION` を更新
2. `package.json` の `version` を更新
3. `manifest.webmanifest` の `version` を更新
4. Service Workerのキャッシュ名を更新
5. `index.html` の表示バージョンを更新
6. Gitコミットを作成
7. `v0.1.1` のようなGitタグを作成
8. GitHub remote `origin` があれば `main` とタグをpush

## 自動バックアップ運用

`start-auto-backup.bat` をダブルクリックすると監視が始まる。  
ファイルを保存したあと、最後の変更から45秒たつと自動でcommitしてGitHubへpushする。
同時に `gh-pages` ブランチへ公開用ファイルもpushする。

止めたいときは、開いている黒い画面で `Ctrl + C` を押す。

完全自動にしたい場合は、Windowsのスタートアップに `start-auto-backup.bat` のショートカットを入れる。

## 初回だけ必要なGitHub接続

GitHubで空のリポジトリを作ったあと、このフォルダで実行する:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\connect-github.ps1 -RepoUrl https://github.com/YOUR_NAME/startline-mvp.git
```

以後は `backup-version.ps1` を実行するたびにGitHubへバックアップされる。

## 推奨運用

- 小さい修正: patch更新
- 機能追加: minor更新
- 大きな仕様変更: major更新

例:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\backup-version.ps1 -Bump patch -Message "fix: improve mobile sharing"
```

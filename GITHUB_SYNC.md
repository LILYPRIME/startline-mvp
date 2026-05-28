# GitHub同期と自動バックアップ

## 方針

このMVPは `departure-planner-mvp` 単体をGitHubに同期する。  
`Playground` 全体には他の実験ファイルが多いため、MVPだけを独立したGitリポジトリとして扱う。

## 使うコマンド

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

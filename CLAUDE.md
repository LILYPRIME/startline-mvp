# CLAUDE.md (StartLine MVP)

## 0. このプロジェクトの目的

出発前の準備・任意タスク・移動時間・到着バッファをまとめて逆算する、
スマホ前提のMVP。

公開先: https://lilyprime.github.io/startline-mvp/

---

## 1. グローバルルール

`C:/claude-rules/` を前提とする。通常は `QUICKREF.md` だけ見れば足りる。
Git の扱いは `C:/claude-rules/GIT_STRATEGY.md` に従う。

---

## 2. 正本と関連プロジェクト

**このリポジトリが StartLine の正本。**

`C:\ClaudeProjects\departure-planner-mvp` は、2026-05-28 時点の
このプロジェクトのコピー(`package.json` の名前も `startline-mvp` のまま)。
**両方を並行して育てない。** 詳細は departure 側の `CLAUDE.md` を見る。

---

## 3. ディレクトリ構成

| パス | 役割 |
|---|---|
| `index.html` | アプリ本体(正本) |
| `service-worker.js` / `manifest.webmanifest` | PWA |
| `VERSION` | バージョン番号。`backup:*` スクリプトが更新する |
| `scripts/auto-backup.ps1` | 常駐して自動コミットする |
| `scripts/publish-pages.ps1` | GitHub Pages(`gh-pages` ブランチ)へ公開 |
| `scripts/backup-version.ps1` | バージョンを上げてバックアップ |
| `DESIGN.md` / `getdesign.md` | 設計メモ |
| `SNS_*.md` / `TESTER_KIT.md` | SNS展開とテスター募集 |
| `FEEDBACK_LOG.csv` | テスターからのフィードバック |
| `GITHUB_SYNC.md` / `PUBLIC_URL.md` | 同期と公開URLの運用 |

---

## 4. 実行コマンド

```powershell
npm run auto-backup:once     # 1回だけ自動バックアップ
npm run publish-pages        # GitHub Pages へ公開
npm run backup:patch         # パッチ版を上げてバックアップ
```

スマホ実機で試す場合は、同じWi-Fiに繋いだPCでローカルサーバーを立てる。

```powershell
.\serve-phone.ps1
```

---

## 5. 自動バックアップの常駐について

`scripts/auto-backup.ps1` はスタートアップに登録されており、
Windows 起動時に常駐して定期的に自動コミットする。

**この常駐がフォルダをロックするため、フォルダを移動するときは先に停止する。**
起動登録の実体は以下。

```
%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\StartLine Auto Backup.lnk
```

パスを直書きしているので、**フォルダを移動したらショートカットも張り替える。**

コミット履歴に `auto: backup ...` が大量に並ぶのはこの仕組みによるもの。
意味のある変更は、自分で普通にコミットメッセージを書いてコミットする。

---

## 6. 触ってはいけない範囲

- `.github/workflows/` の Pages デプロイ設定(公開が止まる)
- `FEEDBACK_LOG.csv`(テスターの生の回答。上書きしない。追記のみ)
- `PUBLIC_URL.md` に書かれた公開URL(外部に共有済み)

---

## 7. 注意点

- **公開中のプロダクト**なので、`index.html` の変更は高ステークス寄りに扱う
- `gh-pages` ブランチは公開用。`main` と混ぜない
- テスターに配布済みのURLを変えない

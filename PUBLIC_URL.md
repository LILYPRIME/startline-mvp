# 公開URL

GitHub Pagesで公開するURL:

https://lilyprime.github.io/startline-mvp/

## 公開の仕組み

`main` ブランチへpushされるたびに、GitHub Actionsが `index.html`、`manifest.webmanifest`、`icon.svg`、`service-worker.js` をGitHub Pagesへ公開する。

## 更新方法

通常どおりファイルを編集する。  
自動バックアップが動いていれば、保存後にcommit/pushされ、そのあとGitHub Pagesも更新される。

GitHub Pagesの反映には通常1〜3分ほどかかる。


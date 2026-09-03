---
name: Blog 記事を Push
description: "作成済みの Configuration Manager または WSUS の Blog 記事を検証し、既存の未レビュー Pull Request の更新または新しい Pull Request の作成確認までを安全に進める agent。記事の staging、commit、Git 同期、Push、PR 更新・作成時に使用し、レビュー待機やレビュー結果への対応は行いません。"
argument-hint: "対象記事のパスと、必要に応じてコミット メッセージや PR タイトルを入力してください"
tools: [read, search, execute]
user-invocable: true
---

作成済みの Blog 記事を、既存の未レビュー Pull Request へ追加して更新を確認するか、新しい Pull Request を作成して URL を確認するところまで進めてください。その時点でこの agent の作業を終了し、レビューの開始待ち、状態監視、レビュー結果への対応、およびマージは行わないでください。[.github/copilot-instructions.md](../copilot-instructions.md) に従い、対象記事以外の変更を意図せず含めたり、ユーザーの既存変更を破棄したりしないでください。

## 対象記事の特定

ユーザー入力、アクティブ ファイル、直近に作成または編集された `articles/mecm/*.md` または `articles/wsus/*.md` の順で対象記事を特定してください。候補が複数ある場合や対象が不明な場合だけ、ユーザーへ選択を求めてください。

## 事前検証

Git への書き込み操作を行う前に、次の内容を確認してください。

- 対象記事の front matter、日付とファイル名、タグ、見出し階層、リンク、画像パス、コード ブロック、および未置換プレースホルダー
- 利用可能な場合は Hexo の生成結果
- 現在のブランチと追跡ブランチ
- staged、unstaged、および untracked の全ファイル
- `origin` の URL と既定ブランチ
- `git fetch origin` 後の `origin/master` と現在のブランチとの差分コミットおよび差分ファイル
- 対象記事が `origin/master` に存在するか。存在しない場合は [未公開記事の日付更新] に従い、ファイル名と `date` を当日の日付へそろえる
- 他メンバーの open Pull Request が `articles/` 配下に追加または変更するファイル。当日の日付でファイル名が重複しないことを確認する
- 現在のブランチを head とする既存の Pull Request の有無、状態、およびレビューが開始されているか。GitHub 用ツールを利用できない場合は、GitHub の比較ページまたは公開 API で確認し、確認できなかったことを明示する

対象記事以外の変更は、staging、commit、stash、削除、復元、または Push の対象にしないでください。

## 未公開記事の日付更新

`origin/master` に存在しない記事は未公開です。未公開記事を Push する場合は、ファイル名と front matter の `date` を Push 当日の日付にそろえてください。レビュー中に修正を重ねた記事の公開日が、実際の公開日と乖離することを防ぐためです。

既に `origin/master` にある記事を更新する場合は、`date` を変更せず、必要に応じて `lastupdate` を追加してください。

### 公開済みかどうかの判定

`git fetch origin` の後、記事ごとに次を実行します。終了コードが 0 なら公開済みのため、リネームの対象外です。

```powershell
git cat-file -e origin/master:articles/mecm/<ファイル名>.md
```

### 連番の決定と重複の確認

当日の日付でファイル名を決めるときは、`NN` が次のすべてと重複しないことを確認してください。

1. ローカル作業ツリーの同じ製品フォルダー
2. `origin/master` の同じ製品フォルダー
3. open な Pull Request が追加または変更するファイル

3 は GitHub の公開 API で確認します。

```powershell
$h = @{ 'User-Agent' = 'blog-push'; 'Accept' = 'application/vnd.github+json' }
$prs = Invoke-RestMethod -Uri 'https://api.github.com/repos/jpmem/blog/pulls?state=open&per_page=100' -Headers $h
foreach ($pr in $prs) {
    Invoke-RestMethod -Uri "https://api.github.com/repos/jpmem/blog/pulls/$($pr.number)/files?per_page=100" -Headers $h |
        Where-Object { $_.filename -like 'articles/*' } |
        ForEach-Object { "PR #{0} [{1}] {2}" -f $pr.number, $pr.user.login, $_.filename }
}
```

自分が更新しようとしている Pull Request が変更するファイルは、重複の対象から除外します。

未認証の API はレート制限が 1 時間あたり 60 回です。制限に達した場合、または API へ到達できない場合は、リネームを行わず、他メンバーとの重複を確認できなかったことをユーザーへ報告し、日付を変えずに進めるかどうかの判断を求めてください。

### リネームの手順

1. 追跡済みのファイルは `git mv`、未追跡のファイルは通常のリネームで移動する
2. front matter の `date` を当日の日付へ更新する
3. 記事と同名の画像フォルダーがある場合は、フォルダーも同じ名前へリネームし、本文の相対パスを更新する
4. 同時に Push する記事どうしが `https://jpmem.github.io/blog/<製品>/<日付>_<連番>/` の形式で相互参照している場合は、その URL も新しいファイル名へ更新する
5. リポジトリ内の他の記事が、リネーム対象の URL を参照していないか検索し、あれば更新する

### 変更しない内容

- 本文中のログ取得日時、検証を実施した日付、および製品バージョン
- `origin/master` に存在する記事の `date`
- 記事の本文そのもの

### 確認

リネーム後、次をユーザーへ提示してください。

- 変更前と変更後のファイル名の対応
- front matter の `date` が当日の日付であること
- 同じ日付の連番がローカル、`origin/master`、および他メンバーの open Pull Request と重複していないこと
- 相互参照の URL が新しいファイル名を指していること

## 必須確認

事前検証の結果を簡潔に示し、Git への最初の書き込み操作の前に、次の選択肢をユーザーへ提示してください。この確認は省略しないでください。

1. [未レビューの Pull Request に追加] (未レビューの open Pull Request がある場合に推奨): 既存 Pull Request の head ブランチへ対象記事を追加する
2. [記事専用ブランチを作成]: 最新の `origin/master` を基点に、対象記事だけを含む新しいブランチと Pull Request を作成する
3. [中止]: 何も変更しない

確認時には、使用するブランチ名、既存 Pull Request の URL とレビュー状態、対象記事、コミット メッセージ、および Push 後に Pull Request に含まれる全差分ファイルを示してください。現在のブランチを head とする未レビューの open Pull Request がある場合は、[未レビューの Pull Request に追加] を推奨してください。レビューが開始済み、closed、merged、またはレビュー状態を確認できない場合は、[記事専用ブランチを作成] を推奨してください。

## 未レビューの Pull Request に追加

ユーザーが [未レビューの Pull Request に追加] を選択した場合は、次の条件を満たす方法で進めてください。

- 対象となる open Pull Request の head ブランチへ切り替え、リモートの最新状態を fast-forward で取得する
- Pull Request にレビュー、承認、または変更要求がまだ付いていないことを Push の直前にも再確認する
- レビューが開始されていた場合は Push せず、記事専用ブランチを作成するかユーザーへ再確認する
- 対象記事と必要な同名画像フォルダーだけを新しいコミットとして追加する
- 既存 Pull Request に既に含まれる差分は保持し、変更、削除、または再コミットしない
- Push 後は新しい Pull Request を作成せず、既存 Pull Request が更新されたことを確認する

## 記事専用ブランチ

ユーザーが [記事専用ブランチを作成] を選択した場合は、次の条件を満たす方法で進めてください。

- ブランチ名は記事の日付と連番を含む分かりやすい名前にする。既存名と重複する場合は別名を提案する
- ブランチの基点は最新の `origin/master` とする
- 対象記事が既に単独コミットになっている場合は、そのコミットだけを新しいブランチへ cherry-pick する
- 対象記事が未コミットの場合は、対象記事の変更だけを新しいブランチへ引き継ぐ。ブランチ切り替えで他の変更まで持ち込まれる、または上書きされる可能性がある場合は停止してユーザーへ確認する
- 対象記事と同名の画像フォルダーが必要な記事では、その画像だけを同じコミットに含める
- 未レビューの既存 Pull Request を再利用しない場合は、その head ブランチへ記事コミットを Push しない

## Commit と同期

staging では対象記事と必要な同名画像フォルダーだけを明示的に指定してください。`git add .` や `git add -A` は使用しないでください。

commit 前に staged ファイル一覧と `git diff --cached --check` を確認し、予定外のファイルまたはエラーがあれば commit せず停止してください。コミット メッセージはユーザー指定を優先し、指定がなければ記事の内容を端的に表す英語またはリポジトリの慣例に沿った文言にしてください。

commit 後に `origin/master` が更新されていないか再度 fetch してください。更新されている場合は、Pull Request 用ブランチへ `origin/master` を merge してください。rebase や履歴の書き換えは、必要性と影響を説明し、ユーザーの明示的な承認を得た場合だけ実行してください。競合が発生した場合は自動解決せず、競合状態と対象ファイルを報告して確認を求めてください。

## Push と Pull Request

Push 前に次の最終情報を示し、ユーザーの確認を得てください。

- Push 先のリモートとブランチ
- `origin/master` との差分コミット
- Pull Request に含まれる全ファイル
- 対象記事の検証結果

承認後、`git push -u origin <ブランチ名>` を実行してください。資格情報、トークン、パスワードが必要な場合は、ユーザーにターミナルへ直接入力してもらい、チャットでは収集しないでください。

既存の未レビュー Pull Request を再利用した場合は、Push 後にその Pull Request の URL を表示し、追加したコミットと差分ファイルが反映されたことを確認してください。

記事専用ブランチを作成した場合、GitHub 用ツールで Pull Request を作成できる場合は、base を `master`、head を Push した記事専用ブランチとして、タイトルと本文案を提示してユーザーの承認を得てから作成してください。作成ツールを利用できない場合は、次の比較 URL をブラウザーで開き、Pull Request 作成画面を表示してください。

`https://github.com/jpmem/blog/compare/master...<URL エンコードしたブランチ名>?expand=1`

Pull Request 作成画面を開いただけでは完了としないでください。ユーザーが画面上で Pull Request を作成した後、その URL と open 状態を確認してください。Pull Request の作成または既存 Pull Request の更新を確認した時点で agent の役目は完了です。以後、レビュー状態を待機または定期確認せず、レビュー結果に応じた修正、追加 Push、承認、およびマージを行わないでください。

## 完了報告

最後に、ブランチ名、コミット ID、Push 結果、更新または作成を確認した Pull Request の URL、実施した検証、残っている未追跡または未コミットの変更を報告し、レビュー待ちであることを示して終了してください。既存 Pull Request を再利用した場合は、今回追加したファイルと、Pull Request 全体に含まれる既存差分を区別して報告してください。

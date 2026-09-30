---
name: blog-push
description: 作成した記事のコミット対象をユーザーに選択してもらい、GitHub ログイン名のブランチへ安全に Push し、承認されたタイトルと本文で Pull Request を作成する。
argument-hint: Push したい記事または変更内容を入力してください。
tools: [read, search, execute]
user-invocable: true
---

作成済みの記事を安全にコミットして Push し、ユーザーが希望した場合だけ Pull Request を作成してください。

[リポジトリの執筆規約](../copilot-instructions.md) と以下の手順に従ってください。ユーザーの許可なしにブランチの作成、commit、Push、Pull Request の作成を行わないでください。ユーザーの既存変更を破棄、上書き、または意図せず commit しないでください。

## 事前確認

1. 次のコマンドで GitHub CLI が利用でき、GitHub にログイン済みであることを確認します。

   ```powershell
   gh auth status
   gh api user --jq .login
   ```

2. `gh api user --jq .login` の出力を GitHub ログイン名として使用します。推測した名前や Git の `user.name` は使用しません。GitHub CLI が利用できない場合、またはログイン名を取得できない場合は、以降の書き込み操作を行わず、ユーザーへログインを依頼します。トークン、パスワード、または資格情報をチャットへ入力させないでください。
3. `git status --short --branch`、`git remote -v`、現在のブランチ、staged、unstaged、および untracked の変更を確認します。
4. `git fetch origin --prune` を実行し、リモートの最新状態を取得します。

## ブランチの確認と同期

### 現在のブランチが `master` の場合

1. 作成または使用するブランチ名として、取得した GitHub ログイン名をユーザーへ提示します。
2. ブランチを作成または切り替える前に、そのブランチ名でよいかユーザーへ確認します。承認されるまで `git switch`、`git checkout`、またはブランチ作成を実行しません。
3. 承認後、ブランチの存在状態に応じて処理します。
   - `origin/<GitHub ログイン名>` が存在する場合は、そのリモート ブランチを追跡する同名のローカル ブランチへ切り替えます。
   - 同名のローカル ブランチだけが存在する場合は、そのローカル ブランチへ切り替えます。
   - ローカルにもリモートにも存在しない場合は、最新の `origin/master` を基点として同名のローカル ブランチを作成します。
4. リモート ブランチが存在する場合は、切り替え後にリモート ブランチを fast-forward で取得してから、最新の `origin/master` を merge します。rebase や force push は行いません。
5. ブランチの切り替え、fast-forward、または merge が「未コミット変更が上書きされる」という理由で実行できない場合だけ、現在の staged、unstaged、および untracked の変更を名前付き stash に退避し、同期と merge の完了後に `git stash pop` で復元します。
6. stash の作成前後と `stash pop` 後に `git status --short` を確認します。stash に含まれるファイルを記録し、復元漏れがないことを確認します。
7. `origin/master` の merge 自体で競合が発生した場合は、競合を自動解決したり stash を作成したりせず、競合ファイルと現在の状態をユーザーへ報告して指示を求めます。
8. `git stash pop` で競合が発生した場合も自動解決せず、stash を削除しないまま競合ファイルをユーザーへ報告して指示を求めます。

### 現在のブランチが `master` 以外の場合

1. 現在のブランチ名が、取得した GitHub ログイン名と完全に一致するか確認します。
2. 一致しない場合は、期待するブランチ名と現在のブランチ名をユーザーへ伝え、ブランチ名の修正または正しいブランチへの切り替えを依頼します。自動で rename、Push、または Pull Request の作成を行わず、ユーザーの対応を待ちます。
3. 一致する場合は、追跡中のリモート ブランチがあれば fast-forward で最新化し、最新の `origin/master` を merge します。未コミット変更によって処理できない場合と競合時の扱いは、`master` の場合と同じです。

## コミット対象の選択

1. ブランチの同期後、次を区別して変更ファイルをすべてユーザーへ提示します。
   - staged
   - unstaged
   - untracked
2. commit に含めるファイルをユーザーに選択してもらいます。選択が曖昧な場合は commit せず、対象を再確認します。
3. 選択されていないファイルは staged 済みであっても commit に含めません。必要に応じて、選択されていない staged ファイルだけを index から外しますが、作業ツリーの内容は変更しません。
4. 選択されたパスだけを個別に `git add -- <path>` で staging します。`git add .`、`git add -A`、ワイルドカードによる一括追加は使用しません。
5. `git diff --cached --name-status` と `git diff --cached --check` を実行し、選択されたファイルだけが staged され、エラーがないことを確認します。
6. staged ファイル一覧、変更概要、およびコミット メッセージ案を提示し、ユーザーの承認後に commit します。
7. commit 後に commit ID と commit に含まれたファイルを確認します。選択されていない変更は未コミットのまま保持します。

## Push 前の必須確認

1. 再度 `git fetch origin --prune` を実行します。`origin/master` が更新されていれば merge し、競合時は処理を停止してユーザーへ報告します。
2. `origin/master...HEAD` の commit と差分を確認し、Pull Request に含まれる全ファイルを取得します。直前の commit だけでなく、ブランチに既に存在する commit のファイルも含めてください。
3. Push の直前に、少なくとも次をユーザーへ提示します。
   - Push 先のリモート
   - ブランチ名
   - `origin/master` との差分 commit
   - Pull Request に含まれる全ファイル
   - Push 後も残る未コミット変更
4. 「Push してよいか」を明示的に確認し、承認された場合だけ `git push -u origin <GitHub ログイン名>` を実行します。承認されなかった場合は Push しません。
5. force push は行いません。Push が non-fast-forward で拒否された場合は、リモートの変更を確認してユーザーへ報告し、勝手に履歴を書き換えません。

## Pull Request の作成

1. Push 完了後、現在のブランチを head、`master` を base とする open な Pull Request が既に存在しないか確認します。存在する場合は重複して作成せず、その URL と状態を報告します。
2. Pull Request が存在しない場合は、Pull Request を作成するかユーザーへ確認します。承認されなければ作成せず終了します。
3. 作成する場合は、`origin/master...HEAD` の commit と commit 済みファイルの差分を読み、Pull Request のタイトル案と本文案を作成します。
4. 本文案には少なくとも次を含めます。
   - 変更の概要
   - 変更したファイル
   - 実施した確認
5. タイトル案と本文案を全文提示し、その内容で作成してよいかユーザーへ確認します。修正依頼があれば案を更新して再提示し、明示的な承認を得るまで作成しません。
6. 承認後、base を `master`、head を GitHub ログイン名のブランチとして Pull Request を作成します。作成後に URL、base、head、タイトル、および open 状態を確認します。
7. 作成した Pull Request の Assignee に、事前確認で取得した GitHub ログイン名のアカウントを追加します。
8. 作成した Pull Request の Reviewer に、`yuhonda` と `tkaji-w` を追加します。
9. Assignee と Reviewer の設定を API で再取得し、GitHub ログイン名、`yuhonda`、および `tkaji-w` が登録されたことを確認します。権限不足やアカウント名の変更などで設定できない場合は、成功したように扱わず、エラーと手動設定が必要であることを報告します。
10. Pull Request のマージ後に head ブランチが自動削除されるよう、リポジトリ設定 `delete_branch_on_merge` が `true` であることを確認します。`false` の場合は次を実行して有効化し、再取得して `true` になったことを確認します。

   ```powershell
   gh api --method PATCH repos/{owner}/{repo} -F delete_branch_on_merge=true
   ```

   この設定はリポジトリ全体に適用されることを、変更前にユーザーへ伝えてください。権限不足などで有効化できない場合は、成功したように扱わず、エラーと手動設定が必要であることを報告します。

## 完了報告

最後に次を報告してください。

- ブランチ名
- commit ID と commit したファイル
- Push の結果
- Pull Request を作成した場合は URL、タイトル、および base/head
- Pull Request を作成した場合は Assignee と Reviewer の設定結果
- `delete_branch_on_merge` の確認結果
- commit しなかった変更と現在の作業ツリーの状態

Pull Request の作成後にマージ、レビュー承認、またはブランチの手動削除は行いません。

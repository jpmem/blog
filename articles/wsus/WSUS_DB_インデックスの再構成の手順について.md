---
title: WSUS DB インデックスの再構成の手順について
date: 2014-03-05
tags:
  - WSUS
---

# WSUS DB インデックスの再構成の手順について

こんにちは。マイクロソフトの三原です。

今回は、インデックスの再構成の手順をご紹介いたします。

WSUS サーバー自身には、データベースのインデックスをメンテナンスする機能が含まれていません。運用継続に伴ってデータベースのパフォーマンスが劣化する可能性があります。(※1) このメンテナンス用スクリプトが公開されていますので、これを利用し定期的にインデックスの再構成を実施いただくことをお勧めします。

(※1) 例えばWSUS サーバーを運用するにあたり、定期的にクリーンアップ ウィザードを実施していただくことを推奨しておりますが、今まで、定期的にクリーンアップ ウィザードを実施していない場合は、クリーンアップ処理に数時間を要することもあります。処理完了までの時間を少しでも削減するために、まずはインデックスの再構成を行ってください。

インデックスの再構成を行う手順は下記のとおりとなります。

# 作業概要

WSUS のデータベースである SUSDB に対して、下記ページに記載されている WSUS データベース メンテナンス用のスクリプトを実行します。

> - WSUS データベースのインデックスを再作成する\
> https://docs.microsoft.com/ja-jp/troubleshoot/mem/configmgr/reindex-the-wsus-database

※ スクリプトは WSUS サーバー上で実行してください。\
※ WSUS サーバーを親子構成している場合は、親子両方の WSUS サーバー上で実行してください。\
※ <span style="color: red; ">本スクリプトは、Windows Server 2012 以降の WSUS でも動作することを確認しております。</span>\
※ <span style="color: red; ">sqlcmd を用いてスクリプトを実行する場合には、「-I」オプションを設定し、"QUOTED_IDENTIFIER" を ON としてください。</span>

# 作業手順

ご利用いただいているデータベース製品にあわせて、以下のいずれかの作業を実施してください。

どちらのデータベースを現在利用しているかにつきましては、WSUS サーバーの以下のレジストリから判断できます。
"**SqlServerName**" の値が ***%computername%\MICROSOFT##SSEE*** もしくは ***MICROSOFT##WID*** となっていれば、WID です。それ以外は SQL Server です。

## SQL Server (製品版) を使用している場合

1. SQL Server Management Studio を起動し、WSUS 用のデータベースが動作しているインスタンスに接続します。
2. SUSDB に対する新しいクエリ画面を開きます。
3. クエリ画面内に、上述の WSUS データベース メンテナンス用スクリプトをコピーペーストして実行します。データベースの最適化が終了すると "Statistics for all tables have been updated" または "全テーブルの統計が更新されました" というメッセージが表示されます。

## Windows Internal Database (WID) を使用している環境の場合

SQL Server Management Studio Express を下記よりダウンロード、インストールしてから、上述の SQL Server の場合と同じ要領で実行します。本ツールでは 製品版の SQL Server Management Studio とほぼ同等の GUI 操作ができます。

SQL Server Management Studio のインストール方法と、データーベースへの接続方法は下記ページにてご案内していますので、インストールしていない場合には、事前に以下の記事を参照し、インストールしましょう。

> - WSUS データベースを簡単に操作するには\
> https://blogs.technet.microsoft.com/jpwsus/2012/03/08/wsus-3/

> - WSUS データベースを簡単に操作するには (Windows Server 2012 編)\ 
> https://blogs.technet.microsoft.com/jpwsus/2014/08/01/wsus-windows-server-2012/

1. SQL Server Management Studio Express を起動し、下記のパラメータを入力してデータベースへ [接続] を行います。
  - **サーバーの種類 : データベース エンジン**
  - **サーバー名 : \\.\pipe\Microsoft##WID\tsql\query**
  - **認証 : Windows 認証**\
※ WSUS 3.0 SP2 の場合、サーバー名は \\.\pipe\mssql$microsoft##ssee\sql\query を指定してください。
2. 左ペインのデータベースのツリーから [SUSDB] を右クリックして[新しいクエリ] を選択します。
3. 右ペインのクエリ画面内に、上述の WSUS データベース メンテナンス用スクリプトをコピーペーストして、実行します。
4. データベースの最適化が終了すると、 "Statistics for all tables have been updated"  または "全テーブルの統計が更新されました" というメッセージが表示されます。

# 補足
WSUS 3.0 SP2 操作ガイド (Operations Guide) では、少なくとも月次でこのメンテナンスの実施を推奨しております。下記ページをご参照ください。

> - Appendix I: Database Maintenance\
> http://technet.microsoft.com/ja-jp/library/dd939795(v=ws.10).aspx
 
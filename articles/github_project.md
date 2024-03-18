---
title: "GitHub の Project 管理が凄い"
emoji: "😊"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["github"]
published: true
---

RCLab です。職場では Notion を使ってタスクの管理をしていますが、個人開発においては前々から気になっていた GitHub Project を触ってみたかったので、触ってみました。

## Engineer のためのタスク管理ツール
使ってみた感想としては「全員エンジニア」のチームではかなり力を発揮するだろうなと思いました。

## 何が凄いの？
- Project から issue を立てられる
  issue に連携された Projects から Priority や Estimate などを編集できます。当然、予め設定した issue 用の Template を用いることで、タスクの概要ややるべきことなどをきちんとフォーマットに沿って書くことができます。Issue Template に関してはまた別の記事で書こうと思います。
- issue が close されると自動的に Done に移動してくれる
  issue 内で `Development > create a branch` してブランチを切り、そのブランチの Pull Request が merge されたら自動的に issue が close してくれるます。なので、タスクのステータスを完了に変更し忘れることが少なくなるのではないでしょうか？PR 内に `close #<issue_number>` って書かなくても自動でやってくれるのが嬉しいです。

## 求める機能
- issue 内で create branch したら自動的に In Progress になる
  作業の直前にブランチを切ると思うので、これがあるとタスクのステータス変更漏れが Done 以外でも発生しなくなると思います。これを workflow で実現してみたいです。

## 感想
タスクの管理が全て GitHub 上でできるので、かなり楽でした。タスクボードの移し忘れも起きにくいので、実際の作業状況とカンバンの状況が一致しやすいなと感じました。

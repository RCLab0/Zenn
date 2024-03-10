---
title: "zsh を好みにカスタマイズする"
emoji: "🖥️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["zsh", "terminal", "shell", "git"]
published: false
---

RCLab です。便利な alias などを適当にガンガン追加すると、.zshrc がぐちゃぐちゃになった経験ありませんか？今回は改めてその設定を整理するとともに、意味などを掘り下げていきたいと思います。

## 忙しい人のために
https://github.com/RCLab0/zsh_config
今回整備した設定を GitHub 上で公開していますので、どなたでもお使いください。

## 要点
項目毎に設定をまとめておけば散らからないはずだという思想の元、設定ファイルを以下のようなディレクトリ構造で設置し、
```shell
$ tree
/User/rclab
├── .zsh
│   ├── directory.zsh
│   ├── git.zsh
│   └── history.zsh
└── .zshrc
```
`.zshrc` 内で `source ~/.zsh/config.zsh` を呼び出すことにしました。

```shell:.zshrc 該当箇所
# load seperated config files
for conf in "$HOME/.zsh/"*.zsh; do
  source "${conf}"
done
unset conf
```
せっかくなので、各種設定ファイルも除いてみましょう。

### directory.zsh
```shell:~/.zsh/directory.zsh
# cd した際に pushd コマンドも同時に実行するような振る舞い
# cd - [tab] で terminal 起動から移動したディレクトリを一望でき、対応する数字を入力することですぐに移動できる
setopt autopushd

# pushd (directory stack) に同じ directory を重複させない
setopt pushdignoredups
```
`cd -` で直前にいたディレクトリにしか戻れないの不便じゃない？不便ですよね！それを解決してくれるのが `autopushd`！`cd` コマンドを発行した際に自動的に `pushd` してくれるみたい。
恥ずかしながら `pushd` コマンドをこの時まであまり理解していませんでした。思わぬところから解決が降ってきて知識整備って大事だなって思いました。

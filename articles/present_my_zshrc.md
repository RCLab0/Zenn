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

### history.zsh
```shell:~/.zsh/history.zsh
HISTSIZE=10000
SAVEHIST=10000

# .zsh_hisroty に追記する設定
# 複数の zsh を同時に使う時など HISTFILE に上書きせず追加する
# default on
# setopt append_history

# コマンドの実行時刻を記録する
setopt extended_history

# いつ append するのか
# inc_append_history: 実行時に HISTFILE に追加
# inc_append_history_time: 実行終了時に実行時間と共に HISTFILE に追加
# share_history: inc_append_history + 他ターミナルでの実行を即座に反映
# が排他的な設定
# terminal 毎に履歴が残った方が嬉しいこともある + 実行時間は知りたいため inc_append_history_time
setopt inc_append_history_time 

# 履歴の数が上限に達した時、古いもの以前に重複しているものを削除する
setopt hist_expire_dups_first

# 重複するコマンドは新しい方のみを記録する
setopt hist_ignore_all_dups

# 重複するコマンドは新しい方のみを HISTFILE に保存する
# 直前のコマンドをパッと使いたいケースが多いので設定しない
# setopt hist_save_no_dups

# history 参照コマンドを履歴として残さない
setopt hist_no_store

# search history の alias
alias shist="history -i 0 | grep "
```
各 option の意味も書いているので、好みに合わせて設定できます。
:::message
一応動作検証はしましたが、狙った挙動になってるかやや自信がなく、要確認
:::

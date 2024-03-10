---
title: "zsh を好みにカスタマイズする"
emoji: "🖥️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["zsh", "terminal", "shell", "git"]
published: false
---

RCLab です。便利な alias などを適当にガンガン追加すると、.zshrc がぐちゃぐちゃになった経験ありませんか？今回は改めてその設定を整理するとともに、意味などを掘り下げていきたいと思います。

# 忙しい人のために
https://github.com/RCLab0/zsh_config
今回の

# 要点
項目毎に設定をまとめておけば散らからないはずだという思想の元、設定ファイルを以下のようなディレクトリ構造で設置し、
```shell
$ tree
/User/rclab
├── .zsh
│   ├── directory.zsh
│   ├── fzf.zsh
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

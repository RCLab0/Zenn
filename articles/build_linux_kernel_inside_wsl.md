---
title: "WSL2 でカスタム Linux kernel を使いたい"
emoji: "🐧"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["WSL", "Linux", "kernel", "VirtualBox"]
published: true
---


RCLab です。今回はソースからビルドした Linux kernel を WSL 環境で使えるようになるまでをまとめました。

## きっかけ
職場では VirtualBox + Vagrant の環境で開発を進めている筆者ですが、わけあって windows で開発をすることになりました。しかし WSL 上で VirtualBox がうまく動作せず、環境構築が進まなくなってしまいました。VirtualBox をインストールし、その動作を確認するも
```zsh
 ~ $ VBoxManage --version
WARNING: The vboxdrv kernel module is not loaded. Either there is no module
         available for the current kernel (5.15.167.4-microsoft-standard-WSL2) or it failed to
         load. Please recompile the kernel module and install it by

           sudo /sbin/vboxconfig

         You will not be able to start VMs until this problem is fixed.
7.1.6r167084
 ~ $ 
```
このような WARNING が出てしまい、うまく動作しませんでした。それを解消する方法を調べていたところ、[Running Virtualbox+Vagrant inside of WSL2 with nested virtualization](https://askalice97.medium.com/running-virtualbox-inside-of-wsl2-with-nested-virtualization-bde85046fe8d) という記事を見つけたので、実際にやってみようとなった運びです。
作業開始前の kernel は
```
 ~ $ uname -r
5.15.167.4-microsoft-standard-WSL2
 ~ $
```
となってます。

## 作業
1. [WSL Linux Kernel](https://github.com/microsoft/WSL2-Linux-Kernel) を WLS 内で clone
    ```zsh
     ~ $ git clone https://github.com/microsoft/WSL2-Linux-Kernel
     ~ $ cd WSL2-Linux-Kernel
     ~/WSL2-Linux-Kernel $ 
    ```
1. build 用の config file を複製し、編集する
    ```zsh
     ~/WSL2-Linux-Kernel $ cp ./Microsoft/config-wsl .config
    ```
    [先の記事](https://askalice97.medium.com/running-virtualbox-inside-of-wsl2-with-nested-virtualization-bde85046fe8d)のように config を編集
    ```zsh
     ~/WSL2-Linux-Kernel $ vi .config
     ~/WSL2-Linux-Kernel $ cat .config | grep -e CONFIG_MODULES= -e CONFIG_MODULE_SIG= -e CONFIG_SECURITY_LOADPIN= -e CONFIG_SECURITY_LOCKDOWN_LSM=
    CONFIG_MODULES=y
    CONFIG_MODULE_SIG=n
    CONFIG_SECURITY_LOADPIN=n
    CONFIG_SECURITY_LOCKDOWN_LSM=n
     ~/WSL2-Linux-Kernel $ 
    ```
1. [README](https://github.com/microsoft/WSL2-Linux-Kernel/blob/linux-msft-wsl-6.6.y/README.md) にあるように、パッケージを install、その後 kernel configuration を行う
    ```zsh
     ~/WSL2-Linux-Kernel $ sudo apt install build-essential flex bison dwarves libssl-dev libelf-dev cpio qemu-utils
     ~/WSL2-Linux-Kernel $ make menuconfig
     ~/WSL2-Linux-Kernel $ 
    ```
    :::message
    ターミナルのウィンドウサイズが小さいとこの設定に移れないので注意
    その旨を伝える文言は出るので慌てず、画面サイズを大きくしましょう
    :::
    設定画面が開くので、<Esc><Esc>とキーを弾いて設定から抜ける
1. [先の記事](https://askalice97.medium.com/running-virtualbox-inside-of-wsl2-with-nested-virtualization-bde85046fe8d)にあるように build する
    ```zsh
     ~/WSL2-Linux-Kernel $ sudo make -j $(nproc)
     ~/WSL2-Linux-Kernel $ sudo make -j $(nproc) modules_install
    ```
    build に成功していれば、 vmlinux が出来上がっているので確認する
    ```zsh
     ~/WSL2-Linux-Kernel $ ls -la | grep vmlinux
    ...(sinp)...
    -rwxr-xr-x   1 root  root  380167912 Feb 23 23:29 vmlinux
    ...(spin)...
     ~/WSL2-Linux-Kernel $ 
    ```
1. WLS がこの kernel を用いるように .wslconfig を編集
    windows 側に vmlinux をコピーし、それを kernel として用いるように .swlconfig に記載する
    ```zsh
     ~/WSL2-Linux-Kernel $ cp vmlinux /mnc/c/Users/<user_name>
     ~/WSL2-Linux-Kernel $ cd ~
     ~ $ vi /mnc/c/Users/<user_name>/.wslconfig
     ~ $ cat /mnc/c/Users/<user_name>/.wslconfig
    [wsl2]
    kernel=C:\\Users\\<user_name>\\vmlinux
     ~ $
    ```
1. WLS を再起動後 WSL にログインし、kernel を確認
    ```
     ~ $ uname -r
    6.6.75.1-microsoft-standard-WSL2+
     ~ $
    ```
    自分が build したものであるかを確認

ここまでで kernel のビルドは完了です！最後に目的だった VirtualBox がきちんと動きそうかを確認しましょう。

```
 ~ $ VBoxManage --version
7.1.6r167084
 ~ $
```
WARNING が消えました！
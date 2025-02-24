---
title: "vagrant + VirtualBox の環境を WSL 上に作ろう！"
emoji: "📦"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["VirtualBox", "Vagrant", "WSL"]
published: true
---

RCLab です。WSL + VirtualBox + Vagrant の環境構築に挑んでいます。[前回の記事](https://zenn.dev/rclab/articles/build_linux_kernel_inside_wsl)で Linux kernel を build することで VirtualBox の WARNING が出ないところまで進めたので、今回は vagrant の provisioner として、VirtualBox を使えるようにインストールしていきます。

## 作業
1. WSL 環境をバックアップ（というより、実験環境）を用意
    [こちらの記事](https://qiita.com/souyakuchan/items/9f95043cf9c4eda2e1cc)を参考に実験用の環境を作ります。途中で不要なものを install してしまって元に戻れなくなったりするのを防ぎます。
    ```powershell
    PS C:\Users\RCLab> wsl --export Ubuntu VagrantExperiment.tar
    PS C:\Users\RCLab> wsl --import VagrantExperiment ./wsl_vagrant_experiment VagrantExperiment.tar
    PS C:\Users\RCLab> wsl -l --verbose
      NAME                    STATE           VERSION
    * Ubuntu                  Running         2
      VagrantExperimenr       Stopped         2
    PS C:\Users\RCLab> 
    ```

1. 新築した実験環境にログインする
    ```powershell
    PS C:\Users\RCLab> wsl --distribution VagrantExperiment
    Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 6.6.75.1-microsoft-standard-WSL2+ x86_64)
    ....(snip)....
    ~ $ 
    ```

1. vagrant の build に必要になる ruby/golang を install
    筆者は asdf で version 管理をしているので asdf を用いていますが、お好みのパッケージ管理ツールで ruby を install しましょう。
    ```shell:golang
    ~ $ asdf plugin add golang
    ~ $ asdf install golang 1.24.0
    ~ $ asdf global golang 1.24.0
    ~ $
    ```

    ```shell:ruby
    ~ $ asdf plugin add ruby
    ~ $ asdf install ruby 3.3.7
    ~ $
    ```
    :::message alert
    後の工程で
    ```shell
     ~/vagrant  main $  bundle install
    Fetching https://github.com/hashicorp/vagrant-spec.git
    Fetching gem metadata from https://rubygems.org/...........
    Resolving dependencies...
    Could not find compatible versions

    Because every version of vagrant depends on Ruby >= 3.0, < 3.4
    and Gemfile depends on vagrant >= 0,
    Ruby >= 3.0, < 3.4 is required.
    So, because current Ruby version is = 3.4.2,
    version solving has failed.
    ```
    このようなエラーが起きたので version 3系で最新のものを用いました
    :::
    エラーが起きたら ruby の install に必要なパッケージが足りてないので apt で入れます。
    ```shell:install するパッケージはコピペなので、不要なものも含まれているかも
     ~ $ sudo apt-get install autoconf bison build-essential libssl-dev libyaml-dev libreadline6-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm6 libgdbm-dev libdb-dev uuid-dev
     ~ $ asdf install ruby 3.3.7
    ==> Downloading ruby-3.3.7.tar.gz...
    -> curl -q -fL -o ruby-3.3.7.tar.gz https://cache.ruby-lang.org/pub/ruby/3.3/ruby-3.3.7.tar.gz
    % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                        Dload  Upload   Total   Spent    Left  Speed
    100 21.1M  100 21.1M    0     0  7077k      0  0:00:03  0:00:03 --:--:-- 7080k
    ==> Installing ruby-3.3.7...
    -> ./configure "--prefix=$HOME/.asdf/installs/ruby/3.3.7" --enable-shared --with-ext=openssl,psych,+
    -> make -j 28
    -> make install
    ==> Installed ruby-3.3.7 to /home/rclab/.asdf/installs/ruby/3.3.7
     ~ $ asdf global ruby 3.3.7
     ~ $ ruby --version
    ruby 3.3.7
     ~ $
    ```
1. github から vagrant を clone する
    ```shell
    ~ $ git clone --recursive https://github.com/hashicorp/vagrant.git
    Cloning into 'vagrant'...
    remote: Enumerating objects: 136974, done.
    remote: Counting objects: 100% (23/23), done.
    remote: Compressing objects: 100% (16/16), done.
    remote: Total 136974 (delta 14), reused 7 (delta 7), pack-reused 136951 (from 2)
    Receiving objects: 100% (136974/136974), 78.71 MiB | 10.96 MiB/s, done.
    Resolving deltas: 100% (90180/90180), done.
    ~ $ cd ./vagrant
    ~/vagrant $
    ```
1. WSL用に build するため、コードを編集する
    [先人の知恵](https://askalice97.medium.com/running-virtualbox-inside-of-wsl2-with-nested-virtualization-bde85046fe8d)通りに編集します。
    ```diff shell:./lib/vagrant/util/platform.rb
     ~/vagrant  main $ vi ./lib/vagrant/util/platform.rb
     ~/vagrant  main $ git diff
    diff --git a/lib/vagrant/util/platform.rb b/lib/vagrant/util/platform.rb
    index 2070091ef..351c283a8 100644
    --- a/lib/vagrant/util/platform.rb
    +++ b/lib/vagrant/util/platform.rb
    @@ -70,7 +70,7 @@ module Vagrant
                @_wsl = false
                SilenceWarnings.silence! do
                # Find 'microsoft' in /proc/version indicative of WSL
    -              if File.file?('/proc/version')
    +              if File.file?('/proc/version') && !ENV["VAGRANT_WSL_NESTED_VIRTUALIZATION"]
                    osversion = File.open('/proc/version', &:gets)
                    if osversion.downcase.include?("microsoft")
                    @_wsl = true
     ~ $
    ```

1. Gemfile に書かれた Gem をインストール
    ```
     ~/vagrant $ bundle install
    Fetching https://github.com/hashicorp/vagrant-spec.git
    Fetching gem metadata from https://rubygems.org/...........
    Resolving dependencies...
    ...(snip)...
1. vagrant を build する
    ```
     ~/vagrant $ make
    ...(snip)...
     ~/vagrant $ bundle exec vagrant --version
    Vagrant failed to initialize at a very early stage:

    The executable 'cmd.exe' Vagrant is trying to run was not
    found in the PATH variable. This is an error. Please verify
    this software is installed and on the path.
     ~/vagrant $ export VAGRANT_WSL_NESTED_VIRTUALIZATION=true
     ~/vagrant $ bundle exec vagrant --version
    Vagrant 2.4.4.dev
     ~/vagrant $
    ```
    vagrant 実行時に `Vagrant failed to initialize at a very early stage:` と出たら、先人の知恵に乗っ取って `VAGRANT_WSL_NESTED_VIRTUALIZATION=true` に設定します。
1. パスを通して、 vagrant コマンドを実行できるようにする
    ```
     ~/vagrant $ vagrant
    /home/rclab/.asdf/installs/ruby/3.3.7/lib/ruby/3.3.0/rubygems.rb:259:in `find_spec_for_exe': can't find gem vagrant (>= 0.a) with executable vagrant (Gem::GemNotFoundException)
        from /home/rclab/.asdf/installs/ruby/3.3.7/lib/ruby/3.3.0/rubygems.rb:278:in `activate_bin_path'
        from /home/rclab/.asdf/installs/ruby/3.3.7/lib/ruby/gems/3.3.0/bin/vagrant:25:in `<main>'
     ~/vagrant $
    ```
    現段階では上記のようになっていると思います。最後に
    ```
     ~/vagrant $ export PATH="/home/<ures_name>/vagrant/binstubs:$PATH"
     ~/vagrant $ vagrant -v
    Vagrant 2.4.4.dev
     ~/vagrant $
    ```

これにて、 vagrant の build も完了です！

## 確認
適当な Vagrantfile を用意し、
```ruby:Vagrantfie
# hostname を複数用意することで。一つの Vagrantfile で複数の VM を建てられる
# vm.provider で provider ごとに値を設定できるので、どの仮想環境を用いていても一つのファイルで事足りる

require "yaml"

settings = YAML.load_file __dir__ + "/local_settings.yml"

Vagrant.configure("2") do |config|
  config.vm.box = settings["vm_box"]
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
    ip_address = ''

    # 仮想マシンのIPアドレスを取得
    vm.communicate.execute("/sbin/ip -4 -o a | grep eth | sort -k 2 | tail -n 1 | awk '{ print $4 }' | sed -e 's|/[0-9]*$||g'") do |type, contents|
      ip_address = contents.split("\n").first
    end

    ip_address
  end

  # ホスト名の変数を定義
  hostname = settings["hostname"]
  config.vm.define hostname do |node_config|
    node_config.vm.hostname = hostname
    node_config.vm.network "private_network", type: "dhcp"

    node_config.vm.provider "virtualbox" do |vb|
      vb.name = hostname
      vb.cpus   = settings["cpus"]   || 2
      vb.memory = settings["memory"] || 2048
    end
  end
end
```
色々と怒られるので、
```
 ~ $ vagrant plugin install vagrant-hostmanager
 ~ $ sudo apt install libarchive-tools
 ~ $
```
としてください。

### 参考文献
1. [Contributing to Vagrant](https://github.com/hashicorp/vagrant/blob/main/.github/CONTRIBUTING.md#setup-a-development-installation-of-vagrant)
2. [Running Virtualbox+Vagrant inside of WSL2 with nested virtualization](https://askalice97.medium.com/running-virtualbox-inside-of-wsl2-with-nested-virtualization-bde85046fe8d)
3. [Scrap](https://zenn.dev/rclab/scraps/2b9f48c78b3ca4)
---
title: "Ubuntu に ansible を用いて MySQL をインストールしよう"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["Vagrant", "ansible", "MySQL", "apt", "Ubuntu"]
published: false
---

RCLab です。皆さんはインフラの構築をどのようなツールを用いて行なっていますか？個人開発を爆速で進めるという意味では apt で install して、 vi で config を編集すれば十分だと思いますが、折角なので職場で使っている Ansible というツールを深掘りしたく、個人開発でも使ってみることにしました。作業メモは脚注[^1]をご覧ください。

## 忙しい人のために
```shell 
$ tree
.
├── playbooks
│   └── local.yml
└── roles
    └── mysql
        ├── defaults
        │   └── main.yml
        ├── handlers
        │   └── main.yml
        ├── tasks
        │   └── main.yml
        └── templates
            └── mysqld.cnf.j2
```
このような directory 構造で、 `./roles/mysql/tasks/main.yml` を以下のようにします。
```yml:./roles/mysql/tasks/main.yml
---

- name: Install MySQL
  apt:
    name: [mysql-server, python3-pymysql]
    update_cache: true
    state: latest

# https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_user_module.html#ansible-collections-community-mysql-mysql-user-module
- name: Set password of root user
  mysql_user:
    name: root # the user name in order to change settings.
    password: "{{ root_user_password }}" # change password to this valuable.

    # check if mysql allows login as root/nopassword before trying supplied (login_user / login_password) credentials.
    # if this option is `true` and succeed check, ansible will ignore login_user / login_password valuables.
    # インストール以外の作業をしていない状態の MySQL には root ユーザーには password は設定されていない
    check_implicit_admin: true
    login_user: root
    login_password: "{{ root_user_password }}"
    host: localhost # default: localhost
    
    # use socket protocol instead of tcp (default)
    login_unix_socket: /var/run/mysqld/mysqld.sock
    state: present # do delete user change state to absent.

- name: configure mysqld.cnf
  template:
    src: mysqld.cnf.j2
    dest: "{{ mysqldcnf_path }}"
  notify: Restart MySQL
```
`./roles/mysql/tasks/main.yml` で用いている変数については、`./roles/mysql/defaults/main.yml` に記述しましょう。
```yml:./roles/mysql/defaults/main.yml
---
root_user_password: random_string # 8文字以上、大文字、数字、小文字、特殊文字を1文字以上含める

mysqldcnf_path: /etc/mysql/mysql.conf.d/mysqld.cnf # default of mysql
client_config: {}
mysqld_config: 
  user: mysql
  log_error: /var/log/mysql/error.log
  slow_query_log_file: /var/log/mysql/slow_query.log
  long_query_time: 0.1 # default 10
  # character_set_server: utf8mb4 # default: utf8mb4
  collation_server: utf8mb4_general_ci # default: utf8mb4_0900_ai_ci
```
また、notify で発火するタスクは `./roles/mysql/handlers/main.yml` に記述します。
```yaml:./roles/mysql/handlers/main.yml
---
- name: Restart MySQL
  systemd:
    name: mysql
    state: restarted
    enabled: true
```
ここまで用意できたら
```shell
$ ansible-playbook ./playbooks/local.yml 
```
を実行。これで完了です。

## MySQL の Install
まず、インストールしたいパッケージを知る必要があります。 mysql を入れたいので、サーバーに ssh して以下のコマンドを打ちました。
```shell
$ apt search mysql | grep mysql
...
mysql-server/jammy-updates,jammy-security 8.0.36-0ubuntu0.22.04.1 all
...
```
目的のパッケージになります。`spt show mysql-server` などして、内容を確認するとなおいいでしょう。では `apt install mysql-server` に対応する ansible task を書いていきます。
```yaml:./roles/mysql/tasks/main.yml
---
- name: Install MySQL
  apt:
    name: mysql-server
    state: present
    update_cache: yes
```
この時点で `ansible-playbook ./playbook/local.yml` を実行します。
```shell
$ ansible-playbook ./playbooks/local.yml

PLAY [local playbook] ************************************************************************

TASK [Gathering Facts] ***********************************************************************
ok: [rclab-local]

TASK [mysql : Install MySQL] *****************************************************************
changed: [rclab-local]

PLAY RECAP ***********************************************************************************
rclab-local            : ok=1    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
早速確認しましょう。
```shell
vagrant@rclab-local:~$ mysql --version
mysql  Ver 8.0.36-0ubuntu0.22.04.1 for Linux on x86_64 ((Ubuntu))
vagrant@rclab-local:~$ ps aux | grep mysql
mysql       7938 12.0 19.4 1783752 393948 ?      Ssl  13:03   0:01 /usr/sbin/mysqld
vagrant     8019  0.0  0.1   6476  2240 pts/0    S+   13:03   0:00 grep --color=auto mysql
vagrant@rclab-local:~$ systemctl is-enabled mysql
enabled
```
インストールできているようです！ついでに起動・再起動時に起動の設定までしているようですね！

## root user の password を変える
MySQL を install した後にまずすることといえば、root ユーザーの password 変更ですよね？それも ansible でやっちゃいましょう！
```yaml:./roles/mysql/tasks/main.yml
...
- name: Set password of root user
  mysql_user:
    name: root # the user name in order to change settings.
    password: "{{ root_user_password }}" # change password to this valuable.
    check_implicit_admin: true
    login_user: root
    login_password: "{{ root_user_password }}"
    state: present # do delete user change state to absent.
```
ansible を流し込みます
```shell
$ ansible-playbook ./playbooks/local.yml
...
TASK [mysql : Set password of root user] *****************************************************
fatal: [rclab-local]: FAILED! => {"changed": false, "msg": "A MySQL module is required: for Python 2.7 either PyMySQL, or MySQL-python, or for Python 3.X mysqlclient or PyMySQL. Consider setting ansible_python_interpreter to use the intended Python version."}
...
```
エラーで落ちてしましました。ansible で 実現するには `PyMySQL` が必要なようです。
```shell
$ apt search mysql | grep mysql
...
python3-pymysql/jammy 1.0.2-1ubuntu1 all
...
```
これっぽいですね。早速 install できるように task: `Install MySQL` を編集しましょう
```diff yaml:./roles/mysql/tasks/main.yml
 ---
 - name: Install MySQL
   apt:
+    name: [mysql-server, python3-pymysql]
-    name: mysql-server
     state: present
     update_cache: yes
```
もう一度、ansible を流し込みます。

```shell
$ ansible-playbook ./playbooks/local.yml

PLAY [local playbook] **********************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************
ok: [rclab-local]

TASK [mysql : Install MySQL] ***************************************************************************************************************
changed: [rclab-local]

TASK [mysql : Set password of root user] ***************************************************************************************************
changed: [rclab-local]

PLAY RECAP *********************************************************************************************************************************
rclab-local            : ok=1    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```
流れました！これで root password も変更できました！
```shell
vagrant@rclab-local:~$ mysql -uroot -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 9
Server version: 8.0.36-0ubuntu0.22.04.1 (Ubuntu)

Copyright (c) 2000, 2024, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

## 設定を流し込む
最後に `/etc/mysql/mysql.conf.d/mysqld.cnf` を編集します。python のテンプレートエンジンである jinja2 を用いて記述します。
```jinja2:./roles/mysql/templates/mysqld.cnf.j2
[client]
{% for _key, _value in client_config | dictsort(by='key') %}
{%   if not (_value == None or _value == omit) %}
{{     _key }} = {{ _value }}
{%   endif %}
{% endfor %}

[mysqld]
{% for _key, _value in mysqld_config | dictsort(by='key') %}
{%   if not (_value == None or _value == omit) %}
{{     _key }} = {{ _value }}
{%   endif %}
{% endfor %}
```
`./roles/mysql/tasks/main.yml` に
```yaml:./roles/mysql/tasks/main.yml
...
- name: configure mysqld.cnf
  template:
    src: mysqld.cnf.j2
    dest: "{{ mysqldcnf_path }}"
```
上記を追記して、 `./roles/mysql/defaults/main.yml` に `client_config`、`mysqld_config`、`mysqldcnf_path` を下記のように設定します。
```yml:./roles/mysql/defaults/main.yml
---
root_user_password: random_string # 8文字以上、大文字、数字、小文字、特殊文字を1文字以上含める

# default of mysql
mysqldcnf_path: /etc/mysql/mysql.conf.d/mysqld.cnf
client_config: {}
mysqld_config: 
  user: mysql
  log_error: /var/log/mysql/error.log
  collation_server: utf8mb4_general_ci # default: utf8mb4_0900_ai_ci
```
最後に ansible を流し込むと
```shell
$ ansible-playbook ./playbooks/local.yml

PLAY [local playbook] **********************************************************************************************************************

TASK [Gathering Facts] *********************************************************************************************************************
ok: [rclab-local]

TASK [mysql : Install MySQL] ***************************************************************************************************************
ok: [rclab-local]

TASK [mysql : Set password of root user] ***************************************************************************************************
ok: [rclab-local]

TASK [mysql : configure mysqld.cnf] ********************************************************************************************************
changed: [rclab-local]

PLAY RECAP *********************************************************************************************************************************
rclab-local            : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```
設定できました🎉

```shell
vagrant@rclab-local:~$ cat /etc/mysql/mysql.conf.d/mysqld.cnf
[client]

[mysqld]
character_set_server = utf8mb4
collation_server = utf8mb4_general_ci
log_error = /var/log/mysql/error.log
user = mysql
```
しかし、実際に MySQL に接続して確認してみると
```shell
vagrant@rclab-local:~$ mysql -uroot -p
Enter password:
...
mysql> show variables like "col%";
+----------------------+--------------------+
| Variable_name        | Value              |
+----------------------+--------------------+
| collation_connection | utf8mb4_0900_ai_ci |
| collation_database   | utf8mb4_0900_ai_ci |
| collation_server     | utf8mb4_0900_ai_ci |
+----------------------+--------------------+
3 rows in set (0.00 sec)

mysql>
```
あれ、変更されてませんね。当然、設定の反映には再起動が必要です。

## 再起動を handle する
:::message alert
これをすると設定変更時に mysql が自動で再起動してしまいます。
サービスで運用する際には必ずメンテナンスに入れるなどしてから行うのが良いと思います。
:::
ansible の tasks で変更が生じた場合のみに発火するイベントを登録できます。それが、`notify` と `handlers/main.yml` で表現できるのでやって見ます。`./roles/mysql/tasks/main.yml` に以下のような変更を加えると、
```diff yaml:./roles/mysql/tasks/main.yml
 ...
 - name: configure mysqld.cnf
   template:
     src: mysqld.cnf.j2
     dest: "{{ mysqldcnf_path }}"
+  notify: Restart MySQL
```
`configure mysqld.cnf` が changed になった際に `./roles/mysql/handlers/main.yml` に記述されている `Restart MySQL` タスクが発火します。
```yaml:./roles/mysql/handlers/main.yml
---
- name: Restart MySQL
  systemd:
    name: mysql
    state: restarted
    enabled: true
```
実際にやってみましょう。cnf ファイルに変更がなければ発火しないので、`defaults/main.yml` を弄ってみます。
```diff yaml:./roles/mysql/defaults/main.yml
 ... 
 mysqld_config: 
   user: mysql
   log_error: /var/log/mysql/error.log
+   slow_query_log_file: /var/log/mysql/slow_query.log
+   long_query_time: 0.1 # default 10
   # character_set_server: utf8mb4 # default: utf8mb4
   collation_server: utf8mb4_general_ci # default: utf8mb4_0900_ai_ci
```
slow query に関する設定を足してみて、ansible を流し込むと。
```shell
$ ansible-playbook ./playbooks/local.yml

PLAY [local playbook] ***********************************************************************************

TASK [Gathering Facts] **********************************************************************************
ok: [rclab-local]

TASK [mysql : Install MySQL] ****************************************************************************
ok: [rclab-local]

TASK [mysql : Set password of root user] ****************************************************************
ok: [rclab-local]

TASK [mysql : configure mysqld.cnf] *********************************************************************
changed: [v-local]

RUNNING HANDLER [mysql : Restart MySQL] *****************************************************************
changed: [rclab-local]

PLAY RECAP **********************************************************************************************
rclab-local            : ok=5    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
handler が発火して、無事設定を反映することができました。


[^1]: [作業メモ / Zend Scrap](https://zenn.dev/rclab/scraps/8a184f283d0b70)
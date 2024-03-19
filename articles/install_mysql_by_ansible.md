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

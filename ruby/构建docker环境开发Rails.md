---
title: 构建docker环境开发Rails
date: 2022-01-13 09:05:07
tags: [docker, rails]
---

## 初始化项目

新建 myapp 目录，在下面添加 `Dockerfile` 文件，如下:

#### Dockerfile

```Dockfile
FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y nodejs default-mysql-client
ADD . /myapp
WORKDIR /myapp
RUN bundle install
EXPOSE 3000
CMD ["bash"]
```

#### Gemfile
再新建 `Gemfile` 文件

```ruby
source 'https://gems.ruby-china.com'
# 安装 Rails
gem 'rails', '~> 5.1.3'
```

#### docker-compose.yml
```yml
version: '3.3'

# 使用已经存在的外部网络
networks:
  default:
    external:
      name: dev_network

services:
  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -p 3000 -b '0.0.0.0'"
    volumes:
      - .:/myapp
    ports:
      - "3000:3000"
    # 链接已经存在的mysql
    external_links:
      - mysql:mysql
```

#### 加入网络

加入已经存在的 `dev_net` 网络，以便访问 mysql 服务, 如果没有 dev_net,可以通过下面命令创建:

```shell
docker network create dev_net
```
在 mysql 的 docker-compose.yml  中同样添加下面内容，可以加入网络 dev_net
```yml
# 使用已经存在的外部网络
networks:
  default:
    external:
      name: dev_network
```

#### 生成项目骨架
```shell
docker-compose run web rails new . --force --database=mysql --skip-bundle
```
Compose 会先使用 Dockerfile 为 web 服务创建一个镜像，接着使用这个镜像在容器里运行 rails new 和它之后的命令。一旦这个命令运行完后，应该就可以看一个崭新的应用已经生成了

## 再次构建
新生成的 Gemfile 覆盖了原来gem源的配置, 修改 Gemfile 的源为 `source 'https://gems.ruby-china.com'`, 另外可以根据需要添加 gem
由于 修改 Gemfile , 需要再次构建， 将 gem 包安装到镜像中，以后每次修改 Gemfile,都要重新构建。 或者可以将 gem 的安装目录通过添加卷的方式映射到本地。
```shell
docker-compose build
```

## 修改数据库配置

修改 `config/database.yml`
```yml
# MySQL. Versions 5.1.10 and up are supported.
#
# Install the MySQL driver
#   gem install mysql2
#
# Ensure the MySQL gem is defined in your Gemfile
#   gem 'mysql2'
#
# And be sure to use new-style password hashing:
#   http://dev.mysql.com/doc/refman/5.7/en/old-client.html
#
default: &default
  adapter: mysql2
  encoding: utf8
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: root
  password: 123456
  host: mysql

development:
  <<: *default
  database: videobot

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  <<: *default
  database: myapp_test

# As with config/secrets.yml, you never want to store sensitive information,
# like your database password, in your source code. If your source code is
# ever seen by anyone, they now have access to your database.
#
# Instead, provide the password as a unix environment variable when you boot
# the app. Read http://guides.rubyonrails.org/configuring.html#configuring-a-database
# for a full rundown on how to provide these environment variables in a
# production deployment.
#
# On Heroku and other platform providers, you may have a full connection URL
# available as an environment variable. For example:
#
#   DATABASE_URL="mysql2://myuser:mypass@localhost/somedatabase"
#
# You can use this database configuration with:
#
#   production:
#     url: <%= ENV['DATABASE_URL'] %>
#
production:
  <<: *default
  database: myapp_production
  username: myapp
  password: <%= ENV['MYAPP_DATABASE_PASSWORD'] %>
```

## 启动
```shell
docker-compose up
```
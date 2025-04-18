---
title: github_Action使用
date: 2022-07-30 23:01:00
tags: [git]
---

### 需求
最近想实现一个自动部署惊天博客的功能，我有一个[静态博客项目](https://github.com/dccmmtop/dccmmtop.github.io),是使用hugo进行编译和部署的，之前自己写了一个脚本将变动的博客自动编译部署到github page 上，也不是很麻烦。但是需要在本机执行一次命令，没有完全自动化，以前了解过github action的功能，可以在某个分支提交代码时触发一个任务，很适合我这个场景，今天来尝试一下。

github action 其实就是设置一个触发条件，然后github提供一个运行环境去执行我们实现定义好的程序，每次执行这个任务时，所给的环境都是崭新的，不保存数据。并且任务的执行时长和一天内的任务执行次数是有限制的。不然早就被薅秃了。

我的需求是，当我在博客项目`main` 分支 推送代码时，触发`github action` 执行 `hugo --minify` 将markdown 文件编译成静态的 html 文件，然后推送到我的github page 上，完成部署。锁执行的任务就只有三步——下载代码，编译和部署。

先说编译，这一步是需要用到hugo命令的，github action 给我们提供的环境肯定时没有这个命令的，我们需要下载安装，非常棒的是，github 收录了开发者已经写好的 action ，我们可以直接拿来用就好了，这个仓库中就有 `hugo` 相关的action—— `peaceiris/actions-hugo@v2`   

同理， 部署步骤也有人提供了对应的action，我们也是直接拿来用就好了。—— `peaceiris/actions-gh-pages@v3`

编译之前其实还有一步，那就是下载代码，在一个全新的环境中，如果没有代码，难道要编译空气？下载代码肯定离不开 git 工具，难道要我们自己装一个 git ? 这倒不用自己做，也有现成的 action —— `actions/checkout@v2`

### 实现
我们的需求和步骤已经梳理完了，下面看怎么操作吧

1. 在项目根目录下新建 `.github/workflows/pages.yml` 文件， 其中 yml 文件是可以随意命名的，但路径是固定的。
2. 编写`page.yml`

```yml
name: dcblog_action # 名字

on: # 触发条件
  push: # 有推送动作时触发
    branchesjkj:
      - main # 这里的意思是当 main分支发生push的时候，运行下面的jobs

jobs: # 要执行的任务，可以时多个
  deploy: # 任务名
    runs-on: ubuntu-18.04 # 在什么环境运行任务
    steps:
      - uses: actions/checkout@v2 # 引用actions/checkout这个action，与所在的github仓库同名
	    with:
          submodules: true # Fetch Hugo themes (true OR recursive) 获取submodule主题
          fetch-depth: 0 # Fetch all history for .GitInfo and .Lastmod
      - name: Setup Hugo # 步骤名自取
      uses: peaceiris/actions-hugo@v2 # hugo官方提供的action，用于在任务环境中获取hugo
      with:
        hugo-version: 'latest' # 获取最新版本的hugo
		
      - name: Build
      run: hugo --minify # 使用hugo构建静态网页

      - name: Deploy
      uses: peaceiris/actions-gh-pages@v3 # 一个自动发布github pages的action
      with:
        external_repository: dccmmtop/dccmmtop.github.io # 发布到哪个repo
        personal_token: xxxx # 发布到其他repo需要提供上面生成的personal access token
        publish_dir: ./public # 注意这里指的是要发布哪个文件夹的内容，而不是指发布到目的仓库的什么位置，因为hugo默认生成静态网页到public文件夹，所以这里发布public文件夹里的内容
        publish_branch: master # 发布到哪个branch
```

personal_token 可以去你的github setting 中获取,记得保密.

### 验证
下面在main 分支上推送一次代码，可以在github action  标签页下看到action 运行成功的标识，以及日志:

![](images/Pasted%20image%2020220730235459.png)

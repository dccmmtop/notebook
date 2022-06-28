---
title: 制作docSet文档
tags: [linux]
date: 2021-08-10 17:33:16
---

docSet 文档可用于 zeal dash 软件中。 zeal 在win 下 和 Linux 均有可用版本 dash 则只在 Mac 可用

制作 dcocSet 文档主要分 3 步

### 镜像文档网站

做镜像网站就是把整个网站爬下来，并且把  css 和 js 图片等静态资源文件转换成本地的路径， 主要使用工具是 wget

以 vue 中文文档 为例:

```shell
wget -r -p -np -k https://cn.vuejs.org/
```

### 制作索引文件

zeal 可以快速的搜索文档主要利用了 sqlite 数据库，在数据库中有一张 serchIndex 表， 这张表常用的字段有三个，分别是 name , type, path

- name
关键词

- type
关键词的类型，代表该关键词是函数，还是类，等等可选的字段有 `Sections`, `Fun`, `classes`

- path
点击关键词要跳转的路径

所以，关键是制作一个这种合理的索引表
下面是使用 ruby 实现制作索引表的功能，以及一些目录的生成 

```ruby
require 'nokogiri'
require "sqlite3"
require "fileutils"
class HtmlToDoc
  def initialize(html_dir, docset_name)
    @html_path = html_dir
    @docset_name = "#{docset_name}.docset"
    @name = docset_name
    mkdir_file
    create_plist
    @con = SQLite3::Database.new(@dsidx)
    @con.execute("CREATE TABLE IF NOT EXISTS searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT)");
  end


  # 插入数据
  def update_db(name, path, type = 'Classes')
    @con.execute('INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES (?,?,?)',[name,type,path])
    puts name,path
  end

  # 提取url，根据你的需求更改提取规则
  def add_urls(html_path)
    doc = Nokogiri::HTML(File.open(html_path).read)
    doc.css("h3>a").each do |tag|
      name = tag.parent.text.strip
      if name.size > 0 && tag[:href]
        path = tag[:href].strip.split("#").last

        update_db(name,html_path + "#" + path)
      end
    end
  end

  # 生成目录
  def mkdir_file
    FileUtils.rm_r(@docset_name) if File.exists?(@docset_name)
    @doc_dir = "#{@docset_name}/Contents/Resources/Documents"
    FileUtils.mkdir_p(@doc_dir)
    @dsidx = "#{@docset_name}/Contents/Resources/docSet.dsidx"
    FileUtils.touch(@dsidx)
    @plist = "#{@docset_name}/Contents/info.plist"
    FileUtils.touch(@plist)
    puts "目录创建成功"
  end

  # 制作plist 文件
  # 各种key 的意思请参考 dash 官方文档
  def create_plist
    plist = <<-EOF
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
              <key>CFBundleIdentifier</key>
              <string>#{@name}</string>
              <key>CFBundleName</key>
              <string>#{@name}</string>
              <key>DashDocSetFamily</key>
              <string>#{@name}</string>
              <key>DocSetPlatformFamily</key>
              <string>requests</string>
              <key>isDashDocset</key>
              <true/>
              <key>isJavaScriptEnabled</key>
              <true/>
              <key>dashIndexFilePath</key>
              <string>#{@name}</string>
      </dict>
      </plist>
    EOF
    File.open(@plist,"w").write(plist)
  end

  # 移动文档
  def copy_files
    FileUtils.cp_r(@html_path.split("/").first, @doc_dir)

    # 将docSet 文档移动到 zeal 目录下
    # local_doc_dir = "/home/dccmmtop/.local/share/Zeal/Zeal/docsets"
    # FileUtils.cp_r(@docset_name,  local_doc_dir)
  end

  def start
    Dir.open(@html_path).each do |file|
      next unless file =~ /.html$/
      add_urls(File.join(@html_path, file))
    end
    copy_files
  end
end


if ARGV[0] == "-h"
  puts 'ruby ./convert.rb "要生成文档的html地址(要包含整个网站的根目录)" "生成文档的名字"'
  puts "例子： ruby convert.rb cn.vuejs.org/v2/guide vue"
else
  HtmlToDoc.new(ARGV[0],ARGV[1]).start
end

```

### 移动docSet目录

 最后将 制作好的 docSet 文件夹移动到 zeal 的文档目录下, 也可以将上面脚本中 `copy_files` 方法最后两行去掉
require "fileutils"
require "httparty"
require "uri"
require "net/http"
require "json"
require "base64"
require "openssl"

class BlogTool
  def initialize
    @home = ENV["HOME"].gsub("\\", "/")
    @notebook_dir = "#{@home}/notebook"
    @deploy_blog_dir = "#{@home}/blog/hugo_blog"
    @dist_dir = "#{@home}/blog/dccmmtop.github.io"
    @deploy_blog_content_dir = File.join(@deploy_blog_dir, "content")
    @deploy_blog_posts_dir = File.join(@deploy_blog_content_dir, "posts")
    @deploy_blog_images_dir = File.join(@deploy_blog_content_dir, "images")
    @CIPHER_ALGO = "AES-256-CBC"
    @SALT_SIZE = 8
    @password = ENV["BLOG_PASS"]
    @encrypt_flag = "dc1126"
  end

  def main(local = false)
    `cd #{@notebook_dir}`
    git_info_list = `git status -s`.split("\n")
    puts git_info_list
    git_info_list.each do |git_info|
      type, file_name = git_info.split(" ")
      deal_file(type, file_name)
    end
    git_save(@notebook_dir)
    if local
      deploy()
    else
      git_save(@deploy_blog_dir)
    end
  end

  def deploy()
    puts "获取远程最新"
    `cd #{@dist_dir} && git pull`
    puts "本地生成"
    `cd #{@deploy_blog_dir} &&  git pull && hugo && git add . && git ci -m "update" && git push`
    puts "复制到部署目录"
    FileUtils.cp_r(Dir.glob("#{@deploy_blog_dir}/public/*"), @dist_dir)
    puts "推送"
    git_save(@dist_dir)
    puts "部署完成"
  end

  def deal_file(type, file_name)
    ab_file_name = File.join(@notebook_dir, file_name)
    return unless ab_file_name =~ /.md$/

    if type == "D"
      delete_blog(file_name)
    else
      copy_blog(file_name)
    end
  end

  def delete_blog(file_name)
    ab_file_name = File.join(@deploy_blog_posts_dir, File.basename(file_name))
    return unless File.exist? ab_file_name

    content = File.read(ab_file_name)
    all_imgs = content.scan(/!\[.*\]\((.*)\)/).flatten
    all_imgs.each do |img|
      puts "移除没有引用的图片: #{img}"
      `rm #{File.join(@deploy_blog_content_dir, img)}`
    end
    puts "删除bog: #{file_name}"
    `rm #{ab_file_name}`
  end

  def copy_blog(file_name)
    ab_file_name = File.join(@notebook_dir, file_name)
    ab_dir = File.dirname(ab_file_name)
    content = File.read(ab_file_name)
    all_imgs = content.scan(/!\[.*\]\((.*)\)/).flatten
    all_imgs.each do |img|
      puts "复制图片: #{img}"
      begin
        FileUtils.cp(File.join(ab_dir, img), @deploy_blog_images_dir)
      rescue StandardError => e
        puts "复制图片失败，跳过: #{e}"
      end
    end
    puts "复制blog: #{ab_file_name}"
    content.gsub!("../images", "/images")
    blog_name = File.join(@deploy_blog_posts_dir, File.basename(ab_file_name))
    File.open(blog_name, "w") do |io|
      io.puts content
    end
  end

  def git_save(path)
    cmd = "cd #{path} && git add . && git commit -m 'update' && git pull && git push"
    puts cmd
    system(cmd)
  end

  def convert_local_img_to_url(file_name)
    ab_file_name = File.join(@notebook_dir, file_name)
    ab_dir = File.dirname(ab_file_name)
    content = File.read(ab_file_name)
    all_imgs = content.scan(/!\[.*\]\((.*)\)/).flatten
    all_imgs.each do |img|
      ab_img_path = File.join(ab_dir, img)
      img_url = upload_file(ab_img_path)
      content.gsub!(img, img_url)
    end
    save_file(content)
    content
  end

  def save_file(content)
    tmp_file = "1.md"
    File.open(tmp_file, "w") do |io|
      io.puts content
    end
    puts "写入临时文件: #{tmp_file}"
  end

  def upload_file(img_path)
    img_path.gsub!("%20", " ")
    puts "正在上传图片: #{img_path}"
    url = URI("https://locimg.com/upload/upload.html")
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request["authority"] = "locimg.com"
    request["accept"] = "application/json, text/javascript, */*; q=0.01"
    request["accept-language"] = "zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
    request["cookie"] = "PHPSESSID=88l7cei45fa5u2q35s6vt9nrt3"
    request["origin"] = "https://locimg.com"
    request["referer"] = "https://locimg.com/"
    request["sec-ch-ua"] = '"Microsoft Edge";v="111", "Not(A:Brand";v="8", "Chromium";v="111"'
    request["sec-ch-ua-mobile"] = "?0"
    request["sec-ch-ua-platform"] = '"Windows"'
    request["sec-fetch-dest"] = "empty"
    request["sec-fetch-mode"] = "cors"
    request["sec-fetch-site"] = "same-origin"
    request["user-agent"] =
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.51"
    request["x-requested-with"] = "XMLHttpRequest"
    form_data = [["image", File.open(img_path)], ["fileId", File.basename(img_path)], ["initialPreview", "[]"],
                 ["initialPreviewConfig", "[]"], ["initialPreviewThumbTags", "[]"]]
    request.set_form form_data, "multipart/form-data"
    response = https.request(request)
    url = ""
    begin
      url = JSON.parse(response.read_body)["data"]["url"].to_s
      raise if url == ""
    rescue StandardError => e
      puts "上传图片失败#{e}"
    end
    url
  end
  
  def auto_en_de(file_name)
    content = File.read(file_name)
    if content.start_with?(@encrypt_flag)
      puts "执行解密"
      content.gsub!(@encrypt_flag,"")
      content = decrypt(content, @password)
      puts content
      File.open(file_name, "w") do |io|
        io.puts content
      end
    else
      puts "执行加密: #{@password}"
      content = @encrypt_flag +  encrypt(content, @password)
      puts content
      File.open(file_name, "w") do |io|
        io.print content
      end
    end
  end

  def encrypt_blog(file_name, pass = "")
    @password = pass if pass.to_s != ""
    raise "未设置密码" if @password.to_s == ""
    content = File.read(file_name)
    puts "不是要加密文件，跳过" and return unless content =~ /tags: \[.*secret.*\]/
    main_body_start_index = content.index("\n---\n")
    raise "未找到正文" if main_body_start_index.nil?
    main_body_start_index += 5
    title = content[0, main_body_start_index]

    main_body = content[main_body_start_index..]
    if main_body.match?(@encrypt_flag)
      puts "不会重复加密"
      return
    end

    encrypt_main_body = encrypt(main_body, @password)
    File.open(file_name, "w") do |io|
      io.print title + @encrypt_flag + encrypt_main_body
    end
    puts "加密完成：#{file_name}"
  end

  def decrypt_blog(file_name, pass = "")
    @password = pass if pass.to_s != ""
    raise "未设置密码" if @password.to_s == ""
    content = File.read(file_name)
    unless content =~ /tags: \[.*secret.*\]/
      puts "不是加密文件，跳过"
      return
    end
    unless content.match?(@encrypt_flag)
      puts "不是加密文件，跳过"
      return
    end

    main_body_start_index = content.index("\n---\n")
    raise "未找到正文" if main_body_start_index.nil?
    main_body_start_index += 5
    title = content[0, main_body_start_index]

    main_body = content[main_body_start_index..]
    main_body.gsub!(@encrypt_flag, "")
    encrypt_main_body = decrypt(main_body, @password)
    File.open(file_name, "w") do |io|
      io.print title + encrypt_main_body
    end
    puts "解密完成：#{file_name}"
  end

  def encrypt(data, pass)
    salt = OpenSSL::Random.random_bytes(@SALT_SIZE)
    cipher = OpenSSL::Cipher::Cipher.new(@CIPHER_ALGO)
    cipher.encrypt
    cipher.pkcs5_keyivgen(pass, salt, 1)
    enc_data = cipher.update(data) + cipher.final
    Base64.strict_encode64(salt + enc_data)
  end

  def decrypt(enc_data, pass)
    enc_data = Base64.strict_decode64(enc_data)
    enc_data = enc_data.dup
    enc_data.force_encoding("ASCII-8BIT")
    salt = enc_data[0, @SALT_SIZE]
    data = enc_data[@SALT_SIZE..-1]
    cipher = OpenSSL::Cipher::Cipher.new(@CIPHER_ALGO)
    cipher.decrypt
    cipher.pkcs5_keyivgen(pass, salt, 1)
    cipher.update(data) + cipher.final
  end
end

# c = "C:\\Users\\dccmm\\notebook\\redis\\Redis的主从和哨兵以及集群架构.md"
blog_tool = BlogTool.new

first_arg = ARGV[0].to_s

if first_arg == "c"
  blog_file = ARGV[1]
  if blog_file.to_s == ""
    puts "缺少要转换的blog文件"
    return
  end
  blog_tool.convert_local_img_to_url(blog_file)
  return
end

if first_arg == "l"
  blog_tool.main(true)
  return
end

if first_arg == "r"
  blog_tool.main(false)
  return
end

if first_arg == "en"
  blog_file = ARGV[1]
  pass = ARGV[2]
  if blog_file.to_s == ""
    puts "缺少要加密的文件"
    return
  end
  blog_tool.encrypt_blog(blog_file, pass)
  return
end

if first_arg == "de"
  blog_file = ARGV[1]
  pass = ARGV[2]
  if blog_file.to_s == ""
    puts "缺少要解密的文件"
    return
  end
  blog_tool.decrypt_blog(blog_file, pass)
  return
end

if first_arg == "auto"
  blog_file = ARGV[1]
  pass = ARGV[2]
  if blog_file.to_s == ""
    puts "缺少要加解密的文件"
    return
  end
  blog_tool.auto_en_de(blog_file)
  return
end

puts "==========帮助文档==========="
puts "./blog_tool.rb l # 本地部署"
puts "./blog_tool.rb r # 远程部署"
puts "./blog_tool.rb c ./1.md # 将博客中的本地图片转换成图床中的链接"
puts "./blog_tool.rb en ./1.md # 加密 1.md 文件"
puts "./blog_tool.rb de ./1.md # 解密 1.md 文件"
puts "./blog_tool.rb auto ./1.md # 自动判断解密解密 1.md 文件"

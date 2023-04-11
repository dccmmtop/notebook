require 'fileutils'

require 'httparty'

require 'uri'

require 'net/http'

require 'json'

class BlogTool
  def initialize
    @notebook_dir = 'C:\\Users\\dccmm\\notebook'

    @deploy_blog_dir = 'C:\\Users\\dccmm\\blog\\hugo_blog'

    @dist_dir = 'C:\\Users\\dccmm\\blog\\dccmmtop.github.io'

    @deploy_blog_content_dir = File.join(@deploy_blog_dir, 'content')

    @deploy_blog_posts_dir = File.join(@deploy_blog_content_dir, 'posts')

    @deploy_blog_images_dir = File.join(@deploy_blog_content_dir, 'images')
  end

  def main
    `cd #{@notebook_dir}`

    git_info_list = `git status -s`.split("\n")

    puts git_info_list

    git_info_list.each do |git_info|
      type, file_name = git_info.split(' ')

      deal_file(type, file_name)
    end

    git_save(@notebook_dir)

    # git_save(@deploy_blog_dir)

    deploy
  end

  def deploy
    `cd #{@deploy_blog_dir} && hugo`
    FileUtils.cp_r(Dir.glob("#{@deploy_blog_dir}\\public\\*"), @dist_dir)

    git_save(@dist_dir)
  end

  def deal_file(type, file_name)
    ab_file_name = File.join(@notebook_dir, file_name)

    return unless ab_file_name =~ /.md$/

    if type == 'D'

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

    content.gsub!('../images', '/images')

    blog_name = File.join(@deploy_blog_posts_dir, File.basename(ab_file_name))

    File.open(blog_name, 'w') do |io|
      io.puts content
    end
  end

  def git_save(path)
    `cd #{path} && git add . && git commit -m "update" && git push`
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
    tmp_file = '1.md'

    File.open(tmp_file, 'w') do |io|
      io.puts content
    end

    puts "写入临时文件: #{tmp_file}"
  end

  def upload_file(img_path)
    img_path.gsub!('%20', ' ')

    puts "正在上传图片: #{img_path}"

    url = URI('https://locimg.com/upload/upload.html')

    https = Net::HTTP.new(url.host, url.port)

    https.use_ssl = true

    request = Net::HTTP::Post.new(url)

    request['authority'] = 'locimg.com'

    request['accept'] = 'application/json, text/javascript, */*; q=0.01'

    request['accept-language'] = 'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6'

    request['cookie'] = 'PHPSESSID=88l7cei45fa5u2q35s6vt9nrt3'

    request['origin'] = 'https://locimg.com'

    request['referer'] = 'https://locimg.com/'

    request['sec-ch-ua'] = '"Microsoft Edge";v="111", "Not(A:Brand";v="8", "Chromium";v="111"'

    request['sec-ch-ua-mobile'] = '?0'

    request['sec-ch-ua-platform'] = '"Windows"'

    request['sec-fetch-dest'] = 'empty'

    request['sec-fetch-mode'] = 'cors'

    request['sec-fetch-site'] = 'same-origin'

    request['user-agent'] =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 Edg/111.0.1661.51'

    request['x-requested-with'] = 'XMLHttpRequest'

    form_data = [['image', File.open(img_path)], ['fileId', File.basename(img_path)], ['initialPreview', '[]'],

                 ['initialPreviewConfig', '[]'], ['initialPreviewThumbTags', '[]']]

    request.set_form form_data, 'multipart/form-data'

    response = https.request(request)

    url = ''

    begin
      url = JSON.parse(response.read_body)['data']['url'].to_s

      raise if url == ''
    rescue StandardError => e
      puts '上传图片失败'
    end

    url
  end
end

# c = "C:\\Users\\dccmm\\notebook\\redis\\Redis的主从和哨兵以及集群架构.md"

blog_tool = BlogTool.new

if ARGV[0] == 'c'

  blog_file = ARGV[1]

  if blog_file.to_s == ''

    puts '缺少要转换的blog文件'

    return

  end

  blog_tool.convert_local_img_to_url(blog_file)

else

  blog_tool.main

end

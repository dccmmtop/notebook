name = ARGV[0]
blog_dir = "/mnt/f/blog"
note_dir = "/mnt/f/notebook"
cmd =  "cp -r #{note_dir}/images #{blog_dir}/content | cat #{name}  | sed 's/\\.\\.\\/image/\\/image/g' | sed 's/=.*x//g' > #{blog_dir}/content/posts/#{name}"
puts cmd
system cmd
 

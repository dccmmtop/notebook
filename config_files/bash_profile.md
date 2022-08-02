# bash_profile
```bash
git config --global alias.co checkout
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.br branch
git config --global core.autocrlf false

export PATH=$PATH:/home/dccmmtop/bin
export PATH=$PATH:/home/dccmmtop/opt/go/bin
export PATH=$PATH:/home/dccmmtop/opt/apache-maven-3.5.4/bin
alias w="cd /mnt/f/code/yuanxin"
alias wg="cd /home/dccmmtop/code/go"
alias f="cd /mnt/f/"
alias rr="source /home/dccmmtop/.bash_profile"
alias gem_doc="cd /home/dccmmtop/.rbenv/versions/2.1.6/lib/ruby/gems/2.1.0/gems"
alias 8l='ssh ewhine@10.102.49.2 "tail -f /home/ewhine/deploy/ewhine_NB/current/log/production.log"'
alias 6l='ssh ewhine@10.100.200.69 "tail -f /home/ewhine/deploy/ewhine_NB/current/log/production.log"'
alias 69='ssh ewhine@10.100.200.69'
alias u8='ssh ewhine@10.102.49.2'
alias rc='rails c'
alias rs='rails s'
alias em='cd /mnt/f/code/java/eop-yuanxin-message'
alias ec='cd /mnt/f/code/java/eop-yuanxin-core'
alias eb='cd /mnt/f/code/java/eop-yuanxin-base'
alias eg='cd /mnt/f/code/java/eop-yuanxin-colleagues'
alias jc='cd /home/dccmmtop/code/rails_app/java_yuanxin'
alias clean_zyb_base='rm -rf /mnt/e/.m2/cn/com/zybank/eop/eop-yuanxin-base'
alias google='/mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe'
alias mvn='/home/dccmmtop/opt/apache-maven-3.5.4/bin/mvn'
export GOPATH=$GOPATH:/home/dccmmtop/code/go

export JAVA_HOME=/home/dccmmtop/opt/jdk1.8.0_261
export PATH="$JAVA_HOME/bin:$PATH"

export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

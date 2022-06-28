# tmux
tmux简洁教程及config关键配置


这个教程的目的是为了更好地使用tmux，作为一个小白，看了网上众多的资料后，感觉资料太多，质量也良莠不齐。在youtube上找了一个很好地系列教程，实际跟着做了一遍后tmux最有用的部分都学会了。有什么不懂得直接查查速查表即可。

本次教程的环境是MAC OS 10.11. 关于如何安装tmux可以参考这两篇文章。

http://cenalulu.github.io/linux/tmux/ ： 了解session，window，pane的区别
http://harttle.com/2015/11/06/tmux-startup.html

这两篇是我个人觉得比较好的文章，可以看完这两篇文章后再来看我的教程。做一个梳理和总结。

这个教程是我跟着视频做完的笔记，视频里有些内容因为时间问题不能用，我也做了相应的改进。建议最好还是把视频跟一遍，然后拿我的笔记用做复习。

本教程参考的视频：https://www.youtube.com/watch?v=FEfuXRTqINg

快捷键速查表：https://tmuxcheatsheet.com

1 Introduction
为什么使用tmux？
因为如果我们用terminal连接remote server。发生一些不可抗力，terminal关了的话，your work is GONE!

但是tmux不一样，即使你关闭了tmux。下次重新attch的时候，你会发现之前的东西都还在。这是因为即使你关闭了tmux，它也还在服务器的后台运行。

prefix默认指的是ctrl键位和b键位，两个一起press，然后再按其他键位来实现不同的命令。在第4部分，我们会更改这个默认设置为ctrl+a，方便输入。在此之前默认都是ctrl+b
举个栗子：
prefix + % :水平分割pane
上面这句话里的+号和:号可以无视。:号之后的内容是我写的注释。
prefix是按下ctrl和b, 然后再按%键，这个%键就是shift+5。

2 Panes
分割pane

prefix + % :水平分割pane
prefix + " : 竖直分割pane
退出

exit ： 退出一个pane，直接在shell里输入即可，这个比快捷键方便
放大一个pane

prefix + z : 把当前一个pane放大（zoom in)。比如在用ls查看output的时候，因为一个pane可能空间太小，所以把这个pane放大，你可以把注意力全放在这个pane里。回到之前的多pane状态的话只需要重复一遍命令即可(zoom out)
在pane之间switch

prefix + 上下左右的箭头 :这个说实话还是不方便，之后会有设置的方法来用鼠标选择pane
resize the pane

prefix + （ctrl）+上下左右箭头 : 与上面命令不同的是，ctrl + b按完之后，不要松开ctrl，一直按着，然后再按箭头来调整。不过因为在mac下ctrl+箭头是切换屏幕，所以还得在偏好设置->键盘->快捷键->Mission Control里把对应的快捷键取消掉。
3 Windows
创建window

prefix + c : 创建一个新的window。最下面会多出window的编号。有*号所在的window就是当前正在操作的window。
在不同的window间移动

prefix + 数字1，2，3 : 因为能看到不同window的数字编号，所以直接输入想去的window的数字编号即可
关闭window

prefix + & ： 关闭当前window
重命名window：因为创建新的window后，下面除了数字编号不同外window名称都是一样的。所以为了知道每一个window是什么，最好重命名一下。

prefix + , (逗号）：更改window名称。但是这里遇到一个问题。更名后，我随便使用ls或cd命令后，window名称会随着目录的不同而变化。google后发现这个是zsh下oh-my-zsh的特性。于是打开~/.zshrc, 讲DISABLE_AUTO_TITLE="true"这一行反注释掉。source ~/.zshrc后，测试更改的名称，发现一切正常。
4 Configuration
如果没有配置文件的话先创建: touch ~/.tmux.conf
视频中的文件配置

# Send prefix
set-option -g prefix C-a
unbind-key C-a
bind-key C-a send-prefix

# Use Alt-arrow keys to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Shift arrow to switch windows
bind -n S-Left previous-window
bind -n S-Right next-window

# Mouse mode
set -g mode-mouse on
set -g mouse-resize-pane on
set -g mouse-select-pane on
set -g mouse-select-window on

# Set easier window split keys
bind-key v split-window -h
bind-key h split-window -v

# Easy config reload
bind-key r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"
首先，在更改了.tmux.conf后，在tmux里的快捷键没有变化。查找后发现是tmux只有在新建session的时候，才会去找tmux.conf文件。所以说，我之前创建的那些session都没有参考tmux.conf. 所以我就用tmux lstmux kill-session -a只保留当前session。再删除当前session tmux kill-session -t py27。这下删除了所有创建好的session。

然后再次用tmux new -s py27创建一个新的名为py27的session。有提示了，但是错误提示显示没有mode-mouse命令。google之发现在2.1之后的tmux版本里，已经废除了这个命令。想要开启mouse mode的话，只需要一个句命令即可set -g mouse on。

更新后如下

# Send prefix
set-option -g prefix C-a
unbind-key C-a
bind-key C-a send-prefix

# Use Alt-arrow keys to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Shift arrow to switch windows
bind -n S-Left previous-window
bind -n S-Right next-window

# Mouse mode
set -g mouse on


# Set easier window split keys
bind-key v split-window -h
bind-key h split-window -v

# Easy config reload
bind-key r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"
Send prefix
把prefix的ctrl+b变为了ctrl+a，因为这样按起来方便些。基本上用tmux的都改了这个。

Use Alt-arrow keys to switch panes
不用按prefix，直接用alt+箭头在pane之间switch。实际用过之后才发现真是太方便了！

Shift arrow to switch windows
不用按prefix，直接用shift+箭头在window之间switch。太方便了！

Mouse mode
开启鼠标模式。用鼠标就能切换window，pane，还能调整pane的大小，方便！

Set easier window split keys
这一部分是用来更方便切分pane的。prefix + v 代表竖着切，prefix + h 代表横着切。比起默认的切割方法不仅直观而且方便。

Easy config reload
下一次如果修改了.tmux.conf的设置的话，不用关掉tmux。直接用prefix+r,就能重新加载设置。

5 Session
查看所有的session（在terminal输入）

tmux ls : 这个命令是在terminal里输入的。当前正常运作中的tmux server会显示（attached）。没有的话就是已关闭，tmux server在后台运行。
更名session（tmux状态下输入）

prefix + $ : 更名后好让自己知道每一个session是用来做什么的。通常一个session对应一个project
创建session的时候直接命名(在terminal输入）

tmux new -s py35 : 新建一个名为py35的session
断开一个session(detached) （tmux状态下输入）

prefix + d ：退出session。在只有一个window的状态下，直接输入exit也能退出
重新连接某一个session wich name（在terminal输入）

tmux a -t py35 : 重新连接py35 session。这里的a是attach的意思
偷懒连接上一个session（在terminal输入）

tmux a : 如果只有一个session的话，这个是最快的连接方法
删除session（在terminal输入）

tmux kill-session -a -t py35 : 删除除了py35以外的所有session



tmux
安装
tmux
tmux

# Install tmux 2.8 on Centos

# install deps
yum install -y gcc kernel-devel make ncurses-devel
yum install -y automake.noarch

# DOWNLOAD SOURCES FOR LIBEVENT AND MAKE AND INSTALL
cd /tmp
curl -LOk https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz
tar -xf libevent-2.1.8-stable.tar.gz
cd libevent-2.1.8-stable
./configure --prefix=/usr/local
make -j & make install

# DOWNLOAD SOURCES FOR TMUX AND MAKE AND INSTALL

cd /tmp
curl -LOk https://github.com/tmux/tmux/releases/download/2.8/tmux-2.8.tar.gz
tar -xf tmux-2.8.tar.gz
cd tmux-2.8
LDFLAGS="-L/usr/local/lib -Wl,-rpath=/usr/local/lib" ./configure --prefix=/usr/local
make -j && make install

pkill tmux

# 编译出来的程序在 tmux 目录内，这里假设你还没离开 tmux 目录
cp tmux /usr/bin/tmux -f
cp tmux /usr/local/bin/tmux -f

# close your terminal window (flushes cached tmux executable)
# open new shell and check tmux version
tmux -V


## 如果出现乱码
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
tmux -u
配置
可以通过修改 ~/.tmux.conf 进行设置

#
# author   : Xu Xiaodong <xxdlhy@gmail.com>
# modified : 2017 Apr 29
#

#-- base settings --#
## set -g default-terminal "screen-256color"
set -g default-terminal 'linux'
set -ga terminal-overrides ",rxvt-unicode-256color:Tc"
set -sg escape-time 0
set -g display-time 3000
set -g history-limit 65535
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on

#-- bindkeys --#
# prefix key (Ctrl+k)
set -g prefix ^k
unbind ^b
bind k send-prefix

# split window
unbind '"'
bind - splitw -v # vertical split (prefix -)
unbind %
#bind | splitw -h # horizontal split (prefix |)
bind \ splitw -h # horizontal split (prefix \)

# select pane
bind k selectp -U # above (prefix k)
bind j selectp -D # below (prefix j)
bind h selectp -L # left (prefix h)
bind l selectp -R # right (prefix l)

# resize pane
bind -r ^k resizep -U 5 # upward (prefix Ctrl+k)
bind -r ^j resizep -D 5 # downward (prefix Ctrl+j)
bind -r ^h resizep -L 5 # to the left (prefix Ctrl+h)
bind -r ^l resizep -R 5 # to the right (prefix Ctrl+l)

# swap pane
bind ^u swapp -U # swap with the previous pane (prefix Ctrl+u)
bind ^d swapp -D # swap with the next pane (prefix Ctrl+d)

# select layout
bind , select-layout even-vertical
bind . select-layout even-horizontal

# misc
bind e lastp  # select the last pane (prefix e)
bind ^e last  # select the last window (prefix Ctrl+e)
bind q killp  # kill pane (prefix q)
bind ^q killw # kill window (prefix Ctrl+q)

# copy mode
bind Escape copy-mode               # enter copy mode (prefix Escape)
bind ^p pasteb                      # paste buffer (prefix Ctrl+p)
unbind -T copy-mode-vi Space
bind -T copy-mode-vi v send -X begin-selection   # select (v)
bind -T copy-mode-vi y send -X copy-pipe "xclip" # copy (y)

# app
bind ! splitw htop                                  # htop (prefix !)
bind m command-prompt "splitw 'exec man %%'"        # man (prefix m)
bind % command-prompt "splitw 'exec perldoc -t %%'" # perl doc (prefix %)
bind / command-prompt "splitw 'exec ri %%'"         # ruby doc (prefix /)

# reload config (prefix r)
bind r source ~/.tmux.conf \; display "Configuration reloaded!"

#-- statusbar --#
set -g status-interval 1
set -g status-keys vi

setw -g mode-keys vi
setw -g automatic-rename off

#-- colorscheme --#
# statusbar
set -g status-justify right
# set -g status-left ""
# set -g status-right ""
#左下角
set -g status-left "#[bg=black,fg=green][#[fg=cyan]#S#[fg=green]]"
set -g status-left-length 20
set -g automatic-rename on
set-window-option -g window-status-format '#[dim]#I:#[default]#W#[fg=grey,dim]'
set-window-option -g window-status-current-format '#[fg=cyan,bold]#I#[fg=blue]:#[fg=cyan]#W#[fg=dim]'
#右下角
set -g status-right '#[fg=green][#[fg=cyan]%Y-%m-%d %H:%M:%S#[fg=green]]'

# -- display -------------------------------------------------------------------

set -g base-index 1           # start windows numbering at 1
setw -g pane-base-index 1     # make pane numbering consistent with windows
setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed
set -g set-titles on          # set terminal title
set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time
set -g status-interval 1     # redraw status line every 10 seconds

set -g status-style "fg=#504945,bg=#282828"
setw -g window-status-current-fg white
setw -g window-status-current-bg red
setw -g window-status-current-attr bright
setw -g window-status-fg cyan
setw -g window-status-bg default
setw -g window-status-attr dim

# window
setw -g window-status-separator " "
setw -g window-status-format "-"
setw -g window-status-current-format "+"
setw -g window-status-current-style "fg=#d79921,bg=#282828"

# pane
set -g pane-border-style "fg=#ebdbb2"
set -g pane-active-border-style "fg=#d79921"

#开启window事件提示
setw -g monitor-activity on
#set -g visual-activity on

## 鼠标设置，不要打开，不然用鼠标选择不了内容
set-option -g mouse on
tmux
tmux

接着，我们需要安装底部状态栏支持插件 tmux-powerline

mkidr -p $HOME/opt
cd $HOME/opt
mkdir -p .tmux
cd .tmux
git clone https://github.com/erikw/tmux-powerline.git 

echo '
## =============================================================================
## https://github.com/erikw/tmux-powerline
set-option -g status on
set-option -g status-interval 2
set-option -g status-justify "centre"
set-option -g status-left-length 60
set-option -g status-right-length 150
set-option -g status-left "#(~/opt/.tmux/tmux-powerline/powerline.sh left)"
set-option -g status-right "#(~/opt/.tmux/tmux-powerline/powerline.sh right)"
set-window-option -g window-status-current-format "#[fg=colour235, bg=colour27]⮀#[fg=colour255, bg=colour27] #I ⮁ #W #[fg=colour27, bg=colour235]⮀"
## =============================================================================
' >> $HOME/.tmux.conf
然后在 ~/.tmux.conf 添加如下

## =============================================================================
## https://github.com/erikw/tmux-powerline
set-option -g status on
set-option -g status-interval 2
set-option -g status-justify "centre"
set-option -g status-left-length 150
set-option -g status-right-length 120
set-option -g status-left "#(~/opt/.tmux/tmux-powerline/powerline.sh left)"
set-option -g status-right "#(~/opt/.tmux/tmux-powerline/powerline.sh right)"
set-window-option -g window-status-current-format "#[fg=colour235, bg=colour27]⮀#[fg=colour255, bg=colour27] #I ⮁ #W #[fg=colour27, bg=colour235]⮀"

setw -g window-status-style 'fg=colour9 bg=colour18'
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
setw -g window-status-bell-style 'fg=colour255 bg=colour1 bold'
# messages
set -g message-style 'fg=colour1 bg=colour16 bold'
## =============================================================================
## =============================================================================

## 使用 bin++z 实现最大-最小屏
# unbind m
# bind m run ". ~/tmux-zoom "

bind -r a select-pane -t .+1 \;  resize-pane -Z
# bind -n C-Space resize-pane -Z

# Ref https://superuser.com/questions/238702/maximizing-a-pane-in-tmux
# #!/bin/bash -f
# currentwindow=`tmux list-window | tr '\t' ' ' | sed -n -e '/(active)/s/^[^:]*: *\([^ ]*\) .*/\1/gp'`;
# currentpane=`tmux list-panes | sed -n -e '/(active)/s/^\([^:]*\):.*/\1/gp'`;
# panecount=`tmux list-panes | wc | sed -e 's/^ *//g' -e 's/ .*$//g'`;
# inzoom=`echo $currentwindow | sed -n -e '/^zoom/p'`;
# if [ $panecount -ne 1 ]; then
#     inzoom="";
# fi
# if [ $inzoom ]; then
#     lastpane=`echo $currentwindow | rev | cut -f 1 -d '@' | rev`;
#     lastwindow=`echo $currentwindow | cut -f 2- -d '@' | rev | cut -f 2- -d '@' | rev`;
#     tmux select-window -t $lastwindow;
#     tmux select-pane -t $lastpane;
#     tmux swap-pane -s $currentwindow;
#     tmux kill-window -t $currentwindow;
# else
#     newwindowname=zoom@$currentwindow@$currentpane;
#     tmux new-window -d -n $newwindowname;
#     tmux swap-pane -s $newwindowname;
#     tmux select-window -t $newwindowname;
# fi


## --------------------------------------------------
# setw -g window-style 'bg=#262626'
# setw -g window-active-style 'bg=#121212'
# set-option -g pane-active-border-style 'bg=#3a3a3a'
# set-option -ag pane-active-border-style 'bg=#3a3a3a'
# set-option -g pane-active-border-fg colour237
# set-option -g pane-border-fg colour237
# setw -g pane-border-status bottom
# setw -g window-active-style 'bg=#3a3a3a,bold'

## -----------------------------------------------------
## 设置活跃窗口的背景颜色
set-option -ga terminal-overrides ",xterm-256color:Tc"
# setw -g window-style 'bg=#504945'
# setw -g window-active-style 'bg=#282828'

set -g "window-style" "fg=#aab2bf,bg=default"
# set -g "window-active-style" "bg=default"
# setw -g window-style 'bg=#504945'
setw -g window-active-style 'bg=#282828,bold'
## -----------------------------------------------------

set-window-option -g clock-mode-colour colour40 #green
set-option -g pane-border-fg colour10
set-option -g pane-active-border-fg colour4

# toggle pane synchronization
bind s setw synchronize-panes

## =============================================================================
## 安装 tmux plugin
## 在 Tmux 里面使用 prefix + I 安装插件
# prefix + Ctrl-s - save
# prefix + Ctrl-r - restore
set -g @plugin 'tmux-plugins/tmux-resurrect'
## 或者手动安装
## cd ~/Documents
## git clone https://github.com/tmux-plugins/tmux-resurrect
run-shell ~/Documents/tmux-resurrect/resurrect.tmux
## =============================================================================

set -g pane-border-status bottom
set -g pane-border-format "#P #T #{pane_current_command}"
设置窗口显示
#-- base settings --#
## set -g default-terminal "screen-256color"
set -g default-terminal 'linux'
set -ga terminal-overrides ",rxvt-unicode-256color:Tc"
set -sg escape-time 0
set -g display-time 3000
set -g history-limit 65535
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
修改绑定键
原来的绑定是 ctrl+b，总感觉这个有点逆人性，每次按下这两个键的时候整个手掌都是弯曲的，后来就干脆分开使用两只手分别按住一个键，这样就避免了使用单手产生的扭曲感

##-- bindkeys --#
## prefix key (Ctrl+k)
set -g prefix ^k
unbind ^b
bind k send-prefix
分屏
这个是 tmux 的看家本领，允许我们通过快捷键进行屏幕的任意切分，相比于 terminator 的方式要灵活很多。这里我使用了

bind-key（也就是我修改后的 ctrl+k），然后按下 | 进行横向切分
bind-key，然后按下 - 进行纵向切分
bind-key，然后按下
j：跳转下面屏幕
k：跳转上面屏幕
h：跳转左边屏幕
l：跳转右边屏幕 其实这个方向跟 vim 的操作是一样的想法，避免了记忆压力。
同时，我还可以使用快捷键进行屏幕大小调整。
先按下 bind-key （也就是我修改后的 ctrl+k）
然后松开 k，但是不要松开 ctrl 键（如果松开，就变成了上面的屏幕跳转了）
接着使用 h、j、k、l 进行屏幕大小调整
# split window
unbind '"'
bind - splitw -v # vertical split (prefix -)
unbind %
#bind | splitw -h # horizontal split (prefix |)
bind \ splitw -h # horizontal split (prefix \)

# select pane
bind k selectp -U # above (prefix k)
bind j selectp -D # below (prefix j)
bind h selectp -L # left (prefix h)
bind l selectp -R # right (prefix l)

# resize pane
bind -r ^k resizep -U 5 # upward (prefix Ctrl+k)
bind -r ^j resizep -D 5 # downward (prefix Ctrl+j)
bind -r ^h resizep -L 5 # to the left (prefix Ctrl+h)
bind -r ^l resizep -R 5 # to the right (prefix Ctrl+l)

# swap pane
bind ^u swapp -U # swap with the previous pane (prefix Ctrl+u)
bind ^d swapp -D # swap with the next pane (prefix Ctrl+d)

# select layout
bind , select-layout even-vertical
bind . select-layout even-horizontal

# misc
bind e lastp  # select the last pane (prefix e)
bind ^e last  # select the last window (prefix Ctrl+e)
bind q killp  # kill pane (prefix q)
bind ^q killw # kill window (prefix Ctrl+q)
状态栏显示
作为程序员，我们每天都在与终端打交道，几乎所有的视线就是整个屏幕范围。因此，我当然希望所有的监控状态也同样可以在视野所及范围内都一一收下。tmux 也同样允许我们通过修改配置进行调整

#-- colorscheme --#
# statusbar
set -g status-justify right
# set -g status-left ""
# set -g status-right ""
#左下角
set -g status-left "#[bg=black,fg=green][#[fg=cyan]#S#[fg=green]]"
set -g status-left-length 20
set -g automatic-rename on
set-window-option -g window-status-format '#[dim]#I:#[default]#W#[fg=grey,dim]'
set-window-option -g window-status-current-format '#[fg=cyan,bold]#I#[fg=blue]:#[fg=cyan]#W#[fg=dim]'
#右下角
set -g status-right '#[fg=green][#[fg=cyan]%Y-%m-%d %H:%M:%S#[fg=green]]'

# -- display -------------------------------------------------------------------

set -g base-index 1           # start windows numbering at 1
setw -g pane-base-index 1     # make pane numbering consistent with windows
setw -g automatic-rename on   # rename window to reflect current program
set -g renumber-windows on    # renumber windows when a window is closed
set -g set-titles on          # set terminal title
set -g display-panes-time 800 # slightly longer pane indicators display time
set -g display-time 1000      # slightly longer status messages display time
set -g status-interval 1     # redraw status line every 10 seconds

set -g status-style "fg=#504945,bg=#282828"
setw -g window-status-current-fg white
setw -g window-status-current-bg red
setw -g window-status-current-attr bright
setw -g window-status-fg cyan
setw -g window-status-bg default
setw -g window-status-attr dim

# window
setw -g window-status-separator " "
setw -g window-status-format "-"
setw -g window-status-current-format "+"
setw -g window-status-current-style "fg=#d79921,bg=#282828"

# pane
set -g pane-border-style "fg=#ebdbb2"
set -g pane-active-border-style "fg=#d79921"

#开启window事件提示
setw -g monitor-activity on
#set -g visual-activity on

## 鼠标设置，不要打开，不然用鼠标选择不了内容
set-option -g mouse on


## =============================================================================
## https://github.com/erikw/tmux-powerline
set-option -g status on
set-option -g status-interval 2
set-option -g status-justify "centre"
set-option -g status-left-length 150
set-option -g status-right-length 120
set-option -g status-left "#(~/opt/.tmux/tmux-powerline/powerline.sh left)"
set-option -g status-right "#(~/opt/.tmux/tmux-powerline/powerline.sh right)"
set-window-option -g window-status-current-format "#[fg=colour235, bg=colour27]⮀#[fg=colour255, bg=colour27] #I ⮁ #W #[fg=colour27, bg=colour235]⮀"

setw -g window-status-style 'fg=colour9 bg=colour18'
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '
setw -g window-status-bell-style 'fg=colour255 bg=colour1 bold'
# messages
set -g message-style 'fg=colour1 bg=colour16 bold'
## =============================================================================
## =============================================================================

## 使用 bin++z 实现最大-最小屏
# unbind m
# bind m run ". ~/tmux-zoom "

bind -r a select-pane -t .+1 \;  resize-pane -Z
# bind -n C-Space resize-pane -Z

# Ref https://superuser.com/questions/238702/maximizing-a-pane-in-tmux
# #!/bin/bash -f
# currentwindow=`tmux list-window | tr '\t' ' ' | sed -n -e '/(active)/s/^[^:]*: *\([^ ]*\) .*/\1/gp'`;
# currentpane=`tmux list-panes | sed -n -e '/(active)/s/^\([^:]*\):.*/\1/gp'`;
# panecount=`tmux list-panes | wc | sed -e 's/^ *//g' -e 's/ .*$//g'`;
# inzoom=`echo $currentwindow | sed -n -e '/^zoom/p'`;
# if [ $panecount -ne 1 ]; then
#     inzoom="";
# fi
# if [ $inzoom ]; then
#     lastpane=`echo $currentwindow | rev | cut -f 1 -d '@' | rev`;
#     lastwindow=`echo $currentwindow | cut -f 2- -d '@' | rev | cut -f 2- -d '@' | rev`;
#     tmux select-window -t $lastwindow;
#     tmux select-pane -t $lastpane;
#     tmux swap-pane -s $currentwindow;
#     tmux kill-window -t $currentwindow;
# else
#     newwindowname=zoom@$currentwindow@$currentpane;
#     tmux new-window -d -n $newwindowname;
#     tmux swap-pane -s $newwindowname;
#     tmux select-window -t $newwindowname;
# fi


## --------------------------------------------------
# setw -g window-style 'bg=#262626'
# setw -g window-active-style 'bg=#121212'
# set-option -g pane-active-border-style 'bg=#3a3a3a'
# set-option -ag pane-active-border-style 'bg=#3a3a3a'
# set-option -g pane-active-border-fg colour237
# set-option -g pane-border-fg colour237
# setw -g pane-border-status bottom
# setw -g window-active-style 'bg=#3a3a3a,bold'
设置活跃窗口
## -----------------------------------------------------
## 设置活跃窗口的背景颜色
set-option -ga terminal-overrides ",xterm-256color:Tc"
# setw -g window-style 'bg=#504945'
# setw -g window-active-style 'bg=#282828'

set -g "window-style" "fg=#aab2bf,bg=default"
# set -g "window-active-style" "bg=default"
# setw -g window-style 'bg=#504945'
setw -g window-active-style 'bg=#282828,bold'
## -----------------------------------------------------

set-window-option -g clock-mode-colour colour40 #green
set-option -g pane-border-fg colour10
set-option -g pane-active-border-fg colour4

# toggle pane synchronization
bind s setw synchronize-panes

## =============================================================================
## 安装 tmux plugin
## 在 Tmux 里面使用 prefix + I 安装插件
# prefix + Ctrl-s - save
# prefix + Ctrl-r - restore
set -g @plugin 'tmux-plugins/tmux-resurrect'
## 或者手动安装
## cd ~/Documents
## git clone https://github.com/tmux-plugins/tmux-resurrect
run-shell ~/Documents/tmux-resurrect/resurrect.tmux
## =============================================================================

set -g pane-border-status bottom
set -g pane-border-format "#P #T #{pane_current_command}"
屏幕右边显示命令执行时间
这个主要为了提醒我们在什么时候执行了操作。其实是通过修改 ~/.oh-my-zsh/themes/agnoster.zsh-theme。不过我把这条放在一起

## 显示命令执行时间
strlen () {
    FOO=$1
    local zero='%([BSUbfksu]|([FB]|){*})'
    LEN=${#${(S%%)FOO//$~zero/}}
    echo $LEN
}

# show right prompt with date ONLY when command is executed
preexec () {
    DATE=$( date +"[%H:%M:%S]" )
    local len_right=$( strlen "$DATE" )
    len_right=$(( $len_right+1 ))
    local right_start=$(($COLUMNS - $len_right))

    local len_cmd=$( strlen "$@" )
    local len_prompt=$(strlen "$PROMPT" )
    local len_left=$(($len_cmd+$len_prompt))

    RDATE="\033[${right_start}C ${DATE}"

    if [ $len_left -lt $right_start ]; then
        # command does not overwrite right prompt
        # ok to move up one line
        #echo -e "\033[1A${RDATE}"

        # Black='\033[30m'        # Black
        # Red='\033[31m'          # Red
        # Green='\033[32m'        # Green
        # Yellow='\033[33m'       # Yellow
        # Blue='\033[34m'         # Blue
        # Purple='\033[35m'       # Purple
        # Cyan='\033[36m'         # Cyan
        # White='\033[37m'        # White

        echo -e "\033[1A\033[36m${RDATE}\033[36m"

    else
        echo -e "${RDATE}"
    fi

}
Author William
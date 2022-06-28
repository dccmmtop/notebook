# tmux.conf

```bash
##-- bindkeys --#
### prefix key (Ctrl+k)
set -g prefix ^a
unbind ^b
bind a send-prefix

# Shift arrow to switch windows
bind -n C-j previous-window
bind -n C-k next-window
#




# Mouse mode
set -g mouse on
unbind -T copy-mode-vi MouseDragEnd1Pane
#set-window-option -g mode-keys vi
#bind-key -t vi-copy v begin-selection
#bind-key -t vi-copy y copy-pipe "reattach-to-user-namespace pbcopy"



# Easy config reload
bind-key r source-file ~/.tmux.conf \; display-message "tmux.conf reloaded"

set -g message-style "bg=#00346e, fg=#ffffd7"        # tomorrow night blue, base3

set -g status-style "bg=#00346e, fg=#ffffd7"   # tomorrow night blue, base3
set -g status-left "#[bg=#0087ff] ❐ 邓超"       # blue
set -g status-left-length 400
set -g status-right ""
#set -g status-right "#[bg=red] %Y-%m-%d %H:%M "
#set -g status-right-length 600

set -wg window-status-format " #I #W "
set -wg window-status-current-format " #I #W "
set -wg window-status-separator "|"
set -wg window-status-current-style "bg=red" # red
set -wg window-status-last-style "fg=red"


# split window
unbind %
bind \\ split-window -h
unbind '"'
bind - split-window -v

# select pane
bind k selectp -U # above (prefix k)
bind j selectp -D # below (prefix j)
bind h selectp -L # left (prefix h)
bind l selectp -R # right (prefix l)


set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @resurrect-save-bash-history 'on'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-strategy-vim 'session'
set -g @continuum-save-interval '60'

set -g @plugin 'tmux-plugins/tmux-yank'
set -g @yank_action 'copy-pipe'
set -g @yank_with_mouse on

run '~/.tmux/plugins/tpm/tpm'


```

# fzf

## 安装

```shell
git clone https://github.com/junegunn/fzf.git
cd .fzf/
./install
```

## 配置
```shell
###
###FZF
###
export FZF_DEFAULT_OPTS='--bind ctrl-e:down,ctrl-u:up --preview "[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500"'
export FZF_DEFAULT_COMMAND='ag --hidden --ignore .git -g ""'
export FZF_COMPLETION_TRIGGER='\'
export FZF_TMUX_HEIGHT='80%'
export FZF_PREVIEW_COMMAND='[[ $(file --mime {}) =~ binary ]] && echo {} is a binary file || (ccat --color=always {} || highlight -O ansi -l {} || cat {}) 2> /dev/null | head -500'


_fzf_compgen_path() {
  ag -g "$1" --ignore .git --ignore node_module
}

# Use fd to generate the list for directory completion
_fzf_compgen_dir() {
  ag -g "$1" --ignore .git --ignore node_module
}
```
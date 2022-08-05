---
title: powershell配置
date: 2022-05-13 17:28:48
tags: [powershell]
---

### 安装powershell

[下载地址](https://github.com/PowerShell/PowerShell/releases)

### 安装scoop

打开powershell 执行

1. 修改策略
`set-executionpolicy remotesigned -s cu`
2. 安装scoop
`iex (new-object net.webclient).downloadstring('https://get.scoop.sh')`

### 自动补全

PSReadLine 在 V5 或以上版本中自带

命令 `$profile` 可见看见配置文件的路径，如果没有此文件，新建即可

打配置文件 `notepad $profile`,输入一下内容

```shell
Import-Module PSReadLine
# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History

#Set the color for Prediction (auto-suggestion)
Set-PSReadLineOption -Colors @{
  Command            = 'Magenta'
  Number             = 'DarkBlue'
  Member             = 'DarkBlue'
  Operator           = 'DarkBlue'
  Type               = 'DarkBlue'
  Variable           = 'DarkGreen'
  Parameter          = 'DarkGreen'
  ContinuationPrompt = 'DarkBlue'
  Default            = 'DarkBlue'
  InlinePrediction   = 'DarkGray'
}
```


### oh-my-posh
Oh My Posh是一个定制的提示引擎，适用于任何能够使用函数或变量调整提示字符串的shell。

**安装**

`scoop install oh-my-posh`

**配置**

在配置文件 `$profile` 输入：

```shell
oh-my-posh init pwsh --config ~\scoop\apps\oh-my-posh\current\themes\robbyrussel.omp.json | Invoke-Expression
```


### Get-ChildItemColor 

**安装**

`Install-Module -AllowClobber Get-ChildItemColor -Scope CurrentUser`

**配置:**

在配置文件 `$profile` 输入：

`Import-Module Get-ChildItemColor`







### 完整配置

```txt
oh-my-posh init pwsh --config C:\Users\Administrator\scoop\apps\oh-my-posh\current\themes\robbyrussel.omp.json | Invoke-Expression

Import-Module PSReadLine
# Shows navigable menu of all options when hitting Tab
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Autocompleteion for Arrow keys
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineOption -ShowToolTips
Set-PSReadLineOption -PredictionSource History

#Set the color for Prediction (auto-suggestion)
Set-PSReadLineOption -Colors @{
  Command            = 'Magenta'
  Number             = 'DarkBlue'
  Member             = 'DarkBlue'
  Operator           = 'DarkBlue'
  Type               = 'DarkBlue'
  Variable           = 'DarkGreen'
  Parameter          = 'DarkGreen'
  ContinuationPrompt = 'DarkBlue'
  Default            = 'DarkBlue'
  InlinePrediction   = 'DarkGray'
}



Import-Module Get-ChildItemColor
#Set-Alias ll Get-ChildItem -option AllScope
#Set-Alias ls Get-ChildItemColorFormatWide -option AllScope

Function vim {F:\Neovim\bin\nvim.exe $args}

```
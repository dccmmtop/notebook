# 杀死已经停掉的nginx进程

`kill $(ps -ef | grep nginx | grep down | grep -v grep | grep ewhine | awk -F' ' '{printf $2 " "}')
`

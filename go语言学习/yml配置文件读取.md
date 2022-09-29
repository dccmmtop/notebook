---
title: yml配置文件读取
date: 2022-09-29 14:42:32
tags: [go]
---

```go
import (
	"fmt"
	"github.com/spf13/viper"
	"os"
	"path/filepath"
)

type Config struct  {
	DesDir string
	SourceFiles []string
}
func loadConfig()(con Config){
	home := os.Getenv("HOME")
	viper.SetConfigFile(filepath.Join(home,"config","syncFile.yml"))
	viper.SetConfigType("yml")
	err := viper.ReadInConfig()
	checkErr(err)
	err = viper.Unmarshal(&con)
	checkErr(err)
	fmt.Printf("config: %v\n", con)
	return con
}
func checkErr(err error){
	if err != nil {
		panic(err)
	}
}
```

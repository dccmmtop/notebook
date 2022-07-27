---
title: zap包使用
date: 2022-07-27 09:17:52
tags: [zap,log,go]
---

```go
package model

import (
        "os"

        "go.uber.org/zap"
        "go.uber.org/zap/zapcore"
)

func InitLogger(level string) *zap.SugaredLogger {
        encoder := getEncoder()
        // 同时输出到文件和控制台
        core := zapcore.NewTee(
                zapcore.NewCore(encoder, stdWriter(), getLogLevel(level)),
                zapcore.NewCore(encoder, fileWriter(), getLogLevel(level)),
        )
        return zap.New(core, zap.AddCaller()).Sugar()
}

func getLogLevel(level string) zapcore.LevelEnabler {
        switch level {
        case "DEBUG":
                return zapcore.DebugLevel
        case "INFO":
                return zapcore.InfoLevel
        case "WARN":
                return zapcore.WarnLevel
        case "ERROR":
                return zapcore.ErrorLevel
        default:
                return zapcore.InfoLevel
        }
}

func getEncoder() zapcore.Encoder {
        encoderConfig := zap.NewProductionEncoderConfig()
        encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
        encoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
        return zapcore.NewConsoleEncoder(encoderConfig)
}

func stdWriter() zapcore.WriteSyncer {
        return zapcore.AddSync(os.Stdout)
}

func fileWriter() zapcore.WriteSyncer {
        file, _ := os.Create(fmt.Sprintf("./%d_log_name.log", time.Now().Unix()))
        return zapcore.AddSync(file)
}
```
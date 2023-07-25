---
title: AES加解密工具
date: 2023-07-19 09:41:12
tags: [java]
---

## 背景

当我们想把某些文件上传到云上，方便备份和分享，但是还担心文件泄露，或者不想让提供云存储服务方的管理员看到,可以对文件加密再上传，就可以实现。比如我们的代码不想被审核或者公开，但还想上传到 github 或者 gitee 等开源平台管理。就可以对代码进行加密，再上传。

我习惯将大部分的操作都在终端完成，这样更高效，自由组合程度更高。linux 平台下有 gpg 工具可以对文件加密，但是 win 下没有找到好用的命令行下的加密工具，于是自己用java实现了一个支持批量操作的 aes 加密工具。

## 特性

### 命令行操作

例：

#### 加密
```shell
java -jar .\AesTool.jar -d ./ -f ".*.java$" -p Aa111111 -en
```

`-d` : 指定目录
`-f` : 加密哪些文件，支持正则表达式
`-p` : 密码，可以显示输入密码，也可隐式输入，当只有 `-p` 参数，后面没有密码时，按下回车键后，会提示输入密码，并不会显示到控制台中
`-en`: 代表要执行加密操作

执行该命令后，会对当前目录下的java文件进行加密，并生成一个 `.java.gpg` 后缀的加密文件。

#### 解密

```shell
java -jar .\AesTool.jar -d ./ -f ".*.gpg$" -p Aa111111 -de
```

执行该命令后，会对当前目录下的`gpg`后缀文件解密，覆盖原文件: `Main.java.gpg` 解密后生成一个 `Main.java`


## 关键代码实现

### 命令行工具

借助 `picocli` 实现命令行参数的解析，使用起来非常方便，示例:

```java
@CommandLine.Command(name = "Aes 加解密工具", mixinStandardHelpOptions = true, version = "1.0", description = "")
public class Main  implements  Runnable{
    @CommandLine.Option(names = {"-p", "--password"}, description = "密码，小于等于16位", required = true,interactive = true, arity = "0..1", hidden = true)
    private String password;

    @CommandLine.Option(names = {"-en"} , description = "加密", required = false)
    private Boolean en = false;

    @CommandLine.Option(names = {"-de"} , description = "解密", required = false)
    private Boolean de = false;

    @CommandLine.Option(names = {"-d", "--dir"}, description = "目录", required = true)
    private String dir;
    @CommandLine.Option(names = {"-f", "--file"}, description = "文件名，支持正则表达式，例： java -jar .\\AesTool.jar -d ./ -f \".*.java$\" -p Aa111111 -en", required = true)


    @Override
    public void run() {
    }

    public static void main(String[] args) {
        CommandLine.run(new Main(), args);
    }
}
```

### 加解密
```java
    public static void aesEn(String key, String filename) throws IOException, NoSuchPaddingException, NoSuchAlgorithmException, InvalidAlgorithmParameterException, InvalidKeyException, IllegalBlockSizeException, BadPaddingException {
        String plaintext = readFile(filename);
        key = String.format("%-16s", key);
        byte[] iv = IV.getBytes(CHARSET);

        // Generate a new AES key
        byte[] keyBytes = key.getBytes(CHARSET);
        SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");

        // Initialize the cipher with the key and IV
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.ENCRYPT_MODE, keySpec, new IvParameterSpec(iv));

        // Encrypt the plaintext
        byte[] ciphertext = cipher.doFinal(plaintext.getBytes(CHARSET));

        // Return the Base64-encoded ciphertext
        plaintext = Base64.getEncoder().encodeToString(ciphertext);
        writeFile(filename + EN_FILE_FLAG, plaintext);
    }

    public static void aesDe(String key, String filename) throws Exception {
        if(!filename.endsWith(EN_FILE_FLAG)){
            System.out.println("不是加密文件，跳过");
            return;
        }
        String encrypted = readFile(filename);
        key = String.format("%-16s", key);
        byte[] iv = IV.getBytes(CHARSET);

        // Generate the AES key from the key bytes
        byte[] keyBytes = key.getBytes(CHARSET);
        SecretKeySpec keySpec = new SecretKeySpec(keyBytes, "AES");

        // Initialize the cipher with the key and IV
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(Cipher.DECRYPT_MODE, keySpec, new IvParameterSpec(iv));

        // Decrypt the ciphertext
        byte[] ciphertext = Base64.getDecoder().decode(encrypted);
        byte[] plaintext = cipher.doFinal(ciphertext);

        writeFile(filename.replace(EN_FILE_FLAG,""), new String(plaintext, CHARSET));
    }

```

完整项目已经开源: https://github.com/dccmmtop/aes_tool


> 联系方式: dccmmtop@foxmail.com
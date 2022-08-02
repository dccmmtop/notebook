# Postman token失效后自动登录

```js
var code = pm.response.json().code;
if (code == 401) {
    console.log("自动登录获取token")
    const loginRequest = {
        url: "http://" + pm.globals.get("loginIP") + ":1800/eop/api/v1/token/account",
        method: "POST",
        header: 'Content-Type: application/json',
        body: {
            mode: "json",
            raw: {
                loginCode: pm.globals.get("loginCode"),
                password: pm.globals.get("password"),
                clientIdentifier: pm.globals.get("clientIdentifier"),
                encrypted: false
            } //要将JSON对象转为文本发送
        },

    };
    pm.sendRequest(loginRequest, function (err, res) {
        console.log(err ? err : res.text());
        res = JSON.parse(res.text());
        console.log(res.code);
        if (res.code == 0) {
            console.log("自动登录成功 token:" + res.data.token);
            pm.globals.set("token", res.data.token);
            // console.log(request.name);
            //postman.setNextRequest(request.name);
            // postman.setNextRequest(null);
        } else {
            console.error("自动登录失败:" + err);
        }
    });
}
```

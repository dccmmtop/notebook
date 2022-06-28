---
title: Go与SQL
date: 2021-11-13 22:21:13
tags: [go]
---

## 连接数据库

sq1.DB结构是一个数据库句柄（handle），它代表的是一个包含了零个或任意多个数据库连接的连接池（pool），这个连接池由sql包管理。程序可以通过调用Open函数，并将相应的数据库驱动名字（driver name）以及数据源名字（data source name）传递给该函数来建立与数据库的连接。

比如，在下面展示的例子中，程序使用的是mysql驱动。数据源名字是一个特定于数据库驱动的字符串，它会告诉驱动应该如何与数据库进行连接。

Open函数在执行之后会返回一个指向sq1.DB结构的指针作为结果。Open函数在执行时，不会真正的与数据库连接，甚至不会检查参数.

Open函数真正的作用是设置好连接数据库所需要的结构，并以惰性的方式，等真正需要的时候才建立与数据库连接


```go
var Db *sql.DB

func init() {
	var err error
	Db, err = sql.Open("mysql", "esns:dccmmtop@tcp(192.168.32.128:3306)/chitchat")
	if err != nil {
		log.Fatal(err)
	}
	return
}
```


## 创建用户

```go
type User struct {
	Id int64
	Uuid string
	Name string
	Email string
	Password string
	CreatedAt time.Time
}

func (u *User) Create() (err error) {
	statement := "insert into users(uuid,name,email,password, created_at) value(?,?,?,?,?)"
	// 预编译
	stmt, err := Db.Prepare(statement)
	if err != nil {
		return  err
	}
	defer stmt.Close()
	// 加密密码
	u.Password = Encrypt(u.Password)
	// 生成UUID
	u.Uuid = CreateUUID()
	u.CreatedAt = time.Now()
	// 执行
	result, err := stmt.Exec(u.Uuid,u.Name,u.Email,u.Password,u.CreatedAt)
	if err != nil {
		return err
	}
	// 返回插入后的自增ID
	u.Id, err = result.LastInsertId()
	if err != nil {
		util.Danger.Println("创建用户返回Id错误: ",err)
		return err
	}
	util.Info.Println("新增用户: ", fmt.Sprintf("%v",*u))
	userJson, err := json.Marshal(*u)
	if err != nil {
		return err
	}
	util.Info.Println("新增用户: ", string(userJson))
	return
}
```

## 查询用户
```go
// 根据ID查询用户
func FindUserById(id int64)(u User, err error) {
	sql := "select id, uuid, `name`, email, password, created_at from users where id = ?"
	u = User{}
  // scan 将查询出来的每一列赋值给对应的属性
	err = Db.QueryRow(sql, id).Scan(&u.Id, &u.Uuid, &u.Name, &u.Email, &u.Password, &u.CreatedAt)
	if err != nil {
		util.Danger.Println("查询用户错误: ", err)
		return
	}
	return
}
```

## 获取多个对象

```go
type Thread struct {
	Id int64
	Uuid   string
	UserId int64
	Topic string
	CreatedAt time.Time
}

// 获取用户发布多个帖子
func ThreadsList(userId int64)(threads []Thread){
	sql := "select id, uuid, user_id, topic,created_at from threads where user_id = ? order by created_at desc"
	rows, err := Db.Query(sql,userId)
	if err != nil {
		util.Danger.Println("查询 threads 错误, 返回空数据,err:", err)
		return
	}
	defer rows.Close()
	for rows.Next() {
		thread := Thread{}
		err := rows.Scan(&thread.Id,&thread.Uuid,&thread.UserId,&thread.Topic,&thread.CreatedAt)
		if err != nil {
			util.Danger.Println(err)
			continue
		}
		threads = append(threads,thread)
	}

	return
}
```

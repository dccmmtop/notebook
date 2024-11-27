---
title: js 函数
date: 2024-07-09 07:25:41
tags: [js]
---

js 中的函数，**既不关心参数个数，也不关心参数类型**
> 函数的参数在内部表现为一个数组。函数被调用时总会接收一个数组，但函数并不关心这个数组中包含什么。如果数组中什么也没有，那没问题；如果数组的元素超出了要求，那也没问题

## arguments
在使用function关键字定义（非箭头）函数时，可以在函数内部访问arguments对象，从中取得传进来的每个参数值。
**箭头函数不行**

```js
function doAdd() {
  if (arguments.length === 1) {
    return arguments[0] + 10;
  } else if (arguments.length === 2) {
    return arguments[0] + arguments[1];
  }
}

console.log(doAdd(1)); //11
console.log(doAdd(1, 2)); //3
```

### 参数名与arguments
两者可以同时使用，并且绑定，同步发生变化
> 它们在内存中还是分开的，只不过会保持同步而已
```js
function doAdd(num1, num2) {
  console.log("num1: " + num1);
  console.log("num1: " + arguments[0]);
  console.log("num2: " + num2);
  console.log("num2: " + arguments[1]);

  num1 = 10;
  console.log("num1_change: " + num1); //10
  console.log("num1_change: " + arguments[0]); //10

  arguments[1] = 20;
  console.log("num2_change: " + num2); //20
  console.log("num2_change: " + arguments[1]); //20
}

doAdd(1, 2);
```
**arguments 只和实际传入的参数绑定，与声明时参数个数无关**

## 没有重载
同名函数，后定义覆盖先定义的

## 参数默认值

在 ES5.1 之前，没有默认值的实现，需要在函数中判断参数是否等于 undefined, 然后手动赋值

ES6 之后，支持定义默认值参数
```js
function say(name = "dc") {
  return `你好 ${name}`;
}

console.log(say());

```

### 使用函数返回值做默认值
```js
function randNum() {
  console.log("获取随机数....");
  return Math.floor(Math.random() * 10);
}
function say(name = "dc", num = randNum()) {
  return `你好 ${name} ${num}`;
}

console.log(say("dch"));

// undefined 占位，name 仍然使用默认值，
// num 使用确定值，randNum()不会调用
console.log(say(undefined,1)); //你好 dc 1
```

## 参数的扩展与收集
### 扩展
```js
function sum() {
  let sum = 0;
  for (let i = 0; i < arguments.length; i++) {
    sum += arguments[i];
  }
  return sum;
}

let value = [1, 2, 3, 4, 5];

console.log(sum(...value));
// 扩展参数前后仍然可以使用参数
console.log(sum(1,...value,2));
```

### 收集

```js
function sum(...values) {
  // 把传进来的参数封装成一个数组到 values 中
  return values.reduce((x, y) => x + y, 0);
}

console.log(sum(1, 2, 3));
```

## 函数内部

### callee
arguments对象其实还有一个callee属性，是一个指向arguments对象所在函数的指针，其用法：
阶乘算法实现1：
```js
function factorial(num) {
  if (num <= 1) {
    return 1;
  }
  return num * factorial(num - 1);
}
```

阶乘算法实现2：
```js
function factorial(num) {
  if (num <= 1) {
    return 1;
  }
  return num * arguments.callee(num - 1);
}
```
算法2 函数内部不使用方法名，而是使用函数指针，避免了函数被覆盖而导致的算法失效


### this
- 在标准函数中，this是方法调用的上下文对象
- 在箭头函数中，this定义箭头函数的上下文对象

标准函数:

```js
function sayColor() {
  console.log(this.color);
}
window = {
  color: "red",
};
window.sayColor = sayColor;
window.sayColor(); // red

o = {
  color: "blue",
};

o.sayColor = sayColor;
o.sayColor(); // blue
```

箭头函数: 
```js
let sayColor = () => {
    // 顶层，this 是 window
  console.log(this.color);
};
Red = {
  color: "red",
};
Red.sayColor = sayColor;
Red.sayColor(); // undefined

Blue = {
  color: "blue",
};

Blue.sayColor = sayColor;
Blue.sayColor(); // undefined
```

### caller

返回函数的调用者
```js
function inner() {
  console.log(inner.caller);
}
function out() {
  inner();
}

function out1() {
  inner();
}

out(); // [Function: out]
out1(); // [Function: out1]

```

### new.target
ECMAScript 6新增了检测函数是否使用new关键字调用的属性: new.target
如果函数是正常调用的，则new.target的值是undefined；如果是使用new关键字调用的，则new.target将引用被调用的构造函数。
```js
function King() {
  if (!new.target) throw "只能通过new 初始化";
  console.log(`Success ${new.target}`);
}

new King(); // Succss, [Function: King]
King(); //  只能通过new 初始化

```




> 联系方式：dccmmtop@foxmail.com

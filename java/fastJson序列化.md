# fastJson序列化

```java
Map < String , Object > jsonMap = new HashMap< String , Object>();
jsonMap.put("a",1);
jsonMap.put("b","");
jsonMap.put("c",null);
jsonMap.put("d","wuzhuti.cn");

String str = JSONObject.toJSONString(jsonMap);
System.out.println(str);
//输出结果:{"a":1,"b":"",d:"wuzhuti.cn"}  
```
从输出结果可以看出，null对应的key已经被过滤掉；这明显不是我们想要的结果，这时我们就需要用到fastjson的SerializerFeature序列化属性

也就是这个方法：JSONObject.toJSONString(Object object, SerializerFeature... features)

Fastjson的SerializerFeature序列化属性

- QuoteFieldNames———-输出key时是否使用双引号,默认为true 
- WriteMapNullValue——–是否输出值为null的字段,默认为false 
- WriteNullNumberAsZero—-数值字段如果为null,输出为0,而非null 
- WriteNullListAsEmpty—–List字段如果为null,输出为[],而非null 
- WriteNullStringAsEmpty—字符类型字段如果为null,输出为”“,而非null 
- WriteNullBooleanAsFalse–Boolean字段如果为null,输出为false,而非null

```java
Map < String , Object > jsonMap = new HashMap< String , Object>();
jsonMap.put("a",1);
jsonMap.put("b","");
jsonMap.put("c",null);
jsonMap.put("d","wuzhuti.cn");

String str = JSONObject.toJSONString(jsonMap,SerializerFeature.WriteMapNullValue);  
System.out.println(str);  
//输出结果:{"a":1,"b":"","c":null,"d":"wuzhuti.cn"}  
```
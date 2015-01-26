CrashLogger
===========

记录iOS崩溃日志，主要用在集成于SDK中的崩溃信息，在SDK被调用时接管崩溃信息，SDK操作完成后将崩溃信息权限交还给原有APP。

## 使用

首先clone项目或者下载zip包；

引入头文件：

```objective-c
#import "CrashLogger.h"
```

初始化CrashLogger单例

```objective-c
self.crashHandle = [CrashLogger sharedInstance];
```

在SDK被调用时候接管崩溃信息：

```objective-c
[self.crashHandle setHandler];
```

在SDK被调用完成后交还崩溃信息：

```objective-c
[self.crashHandle remuseHandler];
```

获取崩溃日志（如果无崩溃日志返回 `nil` ）：

```objective-c
NSDictionary *log = [self.crashHandle getCashLog];
```
> 可以在获取到崩溃日志后将日志内容上传到自己的服务器，然后执行删除操作

删除崩溃日志：

```objective-c
[self.crashHandle deleteCashLog];
```

具体的使用方法等可以参考Demo。

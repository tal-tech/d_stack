# 前言

 ![img](https://magicmadegithub.github.io/img/dstacklogo.png) 

Flutter是谷歌的移动UI框架，可以快速在iOS和Android上构建高质量的原生用户界面。 Flutter可以与现有的代码一起工作。

DStack是为了解决在使用Flutter进行混合开发时，不同类型的页面之间互相跳转时的统一管理和处理。

2020年5月，我们对DStack进行整理、封装和推广。

2020年8月，集团内部开源，9月，外部开源，以此共建交流。

开源并不是我们的终点，我们希望能有更多小伙伴和我们共建DStack，我们一起为Flutter社区做更多的贡献。

## 设计方向

DStack是基于**节点**进行管理的，**使用简单，易于集成，性能优秀**的混合开发框架。

- **节点管理**：不同类型页面抽象成节点这种数据结构，便于后期的扩展
- **引擎复用**：利用Flutter引擎复用机制，框架内存性能优秀
- **简单实用**：追求集成和使用简单，对原有工程改动小
- **持续积累**：紧跟Flutter团队每次版本升级，解决新问题，尝试新思路，不断优化
- **开源心态**：开放公开，接受任何源码的贡献，但有比较严格的代码审核

## 功能简介

- 混合页面之间随意跳转

- 混合页面一致的生命周期管理

- 页面间数据传递，回传等

- iOS侧滑返回和android返回键返回

- 提供一致的页面路由方案



## [接入与详细的使用文档](https://www.yuque.com/tal-tech/ag1kaf)



## 发行版本介绍

DStack目前有一个版本

- master分支为tag1.1.5稳定版本

### 以下为1.1.5版本安装

#### 1.引入

在 pubspec.yaml 文件中添加依赖:

```dart
d_stack:
    git:
      url: https://github.com/tal-tech/d_stack.git
      ref: 1.2.3
```

#### 2.安装

命令行下执行：

**flutter pub get**

## 软件作者贡献列表

| 姓名   | 事业部 | 部门           |
| ------ | ------ | -------------- |
| 杨令龙 | 网校   | 1对1客户端团队 |
| 麻旭   | 网校   | 1对1客户端团队 |
| 王化强 | 网校   | 1对1客户端团队 |
| 林克文 | 网校   | 1对1客户端团队 |
| 孙建   | 网校   | 1对1客户端团队 |
| 刘松   | 网校   | 1对1客户端团队 |

(其他贡献者、请详见文档鸣谢)

## 合作伙伴

![xes1v1.jpeg](https://magicmadegithub.github.io/img/1v1logo.png)

## 联系我们



issue: https://github.com/tal-tech/d_stack/issues

加群请加微信：

<img src="https://magicmadegithub.github.io/img/wechat.jpg" alt="wechat" style="zoom:50%;" />
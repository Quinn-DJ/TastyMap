# TastyMap

TastyMap 是一个原生 SwiftUI 美食地图，支持 iPhone、iPad 和 macOS。它用于保存想去的餐厅，在地图上查看收藏，搜索店铺，并跳转到 Apple 地图导航。

## 当前功能

- 邮箱密码登录、令牌刷新和 Keychain 令牌存储
- 本机 SwiftData 店铺数据库
- 与自建 PocketBase 后端同步
- 按店名、地址、菜系、标签和备注搜索
- MapKit 店铺标记、用户位置和结果聚焦
- Apple 地图步行、驾车和公共交通导航
- 从 Apple 地图查找并导入店铺信息
- iOS 地图详情卡和 macOS 分栏布局
- 深色与浅色模式、动态字体和键盘快捷键

## 技术结构

```text
TastyMap/
├── App/           App 入口与 SwiftData 容器
├── Config/        服务端地址
├── Design/        颜色、排版和通用组件
├── Features/      登录、地图、店铺列表、详情和编辑器
├── Models/        SwiftData 模型与业务枚举
├── Navigation/    Apple 地图导航
├── Networking/    REST 客户端、Keychain 和会话状态
└── Sync/          本地优先的双向同步
```

## 运行

本项目使用 XcodeGen 管理工程文件：

```bash
xcodegen generate
open TastyMap.xcodeproj
```

选择 `TastyMap` scheme 和 macOS、iPhone 或 iPad 模拟器运行。

默认 API 地址为：

```text
https://quinn.eastasia.cloudapp.azure.com:8443
```

可在 scheme 的环境变量中覆盖：

```text
TASTYMAP_API_BASE_URL
```

该值必须是包含 HTTPS 端口的完整 Base URL。普通用户由 PocketBase 超级管理员创建，公开注册保持关闭。

## 测试

macOS 单元测试覆盖中文搜索、SwiftData 持久化以及服务端同步字段解码：

```bash
xcodebuild \
  -project TastyMap.xcodeproj \
  -scheme TastyMap \
  -destination 'platform=macOS' \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

通用 iOS 构建：

```bash
xcodebuild \
  -project TastyMap.xcodeproj \
  -scheme TastyMap \
  -destination 'generic/platform=iOS' \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## 数据策略

店铺首先保存到本机 SwiftData。登录后，应用拉取当前用户的远端店铺，并上传本地修改。删除使用软删除墓碑，以确保删除状态能够同步到其他设备。

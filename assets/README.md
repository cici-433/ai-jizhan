# 资源文件夹

此目录包含应用程序使用的所有资源文件。

## 目录结构

- `images/`: 存放应用中使用的图片资源，如背景图、插图等
- `icons/`: 存放应用中使用的图标资源，如功能图标、导航图标等

## 使用说明

这些资源已在pubspec.yaml中注册，可以通过以下方式访问：

```dart
// 加载图片
Image.asset('assets/images/图片名称.png')

// 加载图标
Image.asset('assets/icons/图标名称.png')
```
<p align="center">
  <img src="assets/icon/modu-app-icon.png" width="96" alt="Modu app icon">
</p>
<h1 align="center">默读 · Modu Reader</h1>
<p align="center">
  <a href="README.md">简体中文</a> · <a href="README_EN.md">English</a>
</p>
<p align="center">默读是基于 Flutter 的开源跨平台阅读器，支持电子书、PDF 与扫描图片书籍。裁边增强、设备端 OCR、全文翻译、听书与 AI 阅读，让不同格式的书籍更易阅读；笔记、阅读进度与 WebDAV 同步相连，也可按需建立本地或远程向量索引。</p>

<p align="center">
  <a href="https://github.com/sobranie2406/modureader/releases/latest"><b>下载最新版</b></a> ·
  <a href="#interface">界面预览</a>
</p>

<a id="interface"></a>

## 界面预览

奶白背景、珊瑚色操作按钮与圆角卡片，贯穿书架、笔记、阅读历史、远程书库、句境、AI、搜索和设置。深色模式采用炭灰背景与分层灰色表面，搭配浅色文字和珊瑚红按钮；自定义主题色、OLED 纯黑和墨水屏模式仍可按需选择。

![桌面书架：侧栏导航、继续阅读卡片、搜索与阅读状态筛选](docs/design/previews/bookshelf-desktop.png)

| 手机浅色 | 手机深色 |
| --- | --- |
| ![浅色书架与圆角底部导航](docs/design/previews/bookshelf-phone-light.png) | ![深色书架与圆角底部导航](docs/design/previews/bookshelf-phone-dark.png) |

手机使用圆角底部导航，次要页面从「更多」进入；桌面使用随窗口宽度折叠的侧栏。书架提供继续阅读、搜索、阅读状态筛选与网格／列表切换，设置按阅读、智能辅助、数据和支持分组。

<details>
<summary>查看笔记、设置与历史页面</summary>

| 浅色笔记 | 深色笔记 |
| --- | --- |
| ![浅色笔记页面](docs/design/previews/notes-phone-light.png) | ![深色笔记页面](docs/design/previews/notes-phone-dark.png) |

| 浅色设置 | 深色设置 |
| --- | --- |
| ![浅色手机设置](docs/design/previews/settings-phone-light.png) | ![深色手机设置](docs/design/previews/settings-phone-dark.png) |

[桌面设置](docs/design/previews/settings-desktop.png) · [深色桌面设置](docs/design/previews/settings-desktop-dark.png) · [阅读历史卡片](docs/design/previews/history-cards-phone-light.png)

</details>

以上预览由当前源码中的真实 Flutter 组件渲染，使用虚构书籍、笔记与阅读数据，界面字体随平台略有差异。完整预览与生成方法见[界面设计说明](docs/design/README.md)。

<a id="downloads"></a>

## 下载

[GitHub Releases](https://github.com/sobranie2406/modureader/releases/latest)

支持 Android、iOS、macOS、Windows、Linux 和原生鸿蒙。请按系统与架构选择安装包；签名、依赖和安装步骤见[安装指南](docs/RELEASING.md)。

[设置指南](docs/SETTINGS_zh.md) · [详细功能介绍](docs/FEATURES_zh.md) · [文档目录](docs/README.md)

按 [GPL-3.0-or-later](LICENSE) 开源，保留 Anx Reader 与 ReadAny 的版权和许可；来源与归属见 [UPSTREAM.md](UPSTREAM.md) 和 [NOTICE](NOTICE)。

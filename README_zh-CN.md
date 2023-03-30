# 简介

fclipboard 是一个基于 flutter 的剪贴板管理工具，支持多平台。
可根据用户的输入模糊匹配复杂的剪贴板内容。

# 安装

windows 双击安装包安装即可。

# 使用

匹配内容是以键值对的形式存储，键为标题，值为内容。

## 常规模式

输入想匹配的标题，系统会列出 10 个最匹配的内容，按下`Ctrl+n`即可复制到剪贴板。

## 参数模式

补全内容支持带入参数，输入内容以空格分割，第一个为补全匹配模式，后面的依次以$A、$B、$C...的形式作为参数传入。

例如：输入`execcindervolume 2`时会进入第二个`cinder volume`容器。

## 快捷键

可通过全局快捷键`alt+p`呼出应用。

## 使用示例

### k8s 命令补全

当前已经获取环境中所有的 POD 信息，并根据 label 生成了快速补全命令，包括：

| 操作名称      | 命令               |
| ------------- | ------------------ |
| 查询 POD      | getcindervolume    |
| 删除 POD      | deletecindervolume |
| 进入 POD      | execcindervolume   |
| 查看 POD 日志 | logscindervolume   |
| Tail POD 日志 | tailcindervolume   |

### 高性能问题定位

当前已经集成了高性能所有接口的快速日志查询命令，包括：

| 操作名称   | 命令                 |
| ---------- | -------------------- |
| 创建卷     | alcubierrecreate     |
| 连接卷     | alcubierreconnect    |
| 断开卷     | alcubierredisconnect |
| 扩容卷     | alcubierreexpand     |
| 删除卷     | alcubierredelete     |
| 创建快照   | alcubierresnapshot   |
| 快照恢复   | alcubierrerollback   |
| 克隆卷     | alcubierreclone      |
| 查询卷信息 | alcubierredisk       |

# 其他

更多功能等待你的探索！

# TouchBarCommander

![Swift](https://img.shields.io/badge/Swift-5.0+-orange.svg)
![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Privat API](https://img.shields.io/badge/API-DFRFoundation-red.svg)

[English](#english) | [中文](#中文)

---

A lightweight background utility for macOS that lets you customize your MacBook Pro's Touch Bar globally. Written in Swift, it utilizes macOS private APIs (`DFRFoundation`) to register a custom Control Strip button and overlay a completely custom, JSON-configured system modal Touch Bar.

---

<a name="english"></a>

## Features

- 🎙️ **Quick Actions** — Built-in Siri trigger and play/pause media controls
- 🔊 **System Controls** — Smooth volume slider and toggleable mute button
- 🔋 **Live Monitoring** — Track battery, CPU, RAM, or custom metrics
- 🐚 **Shell Script Widgets** — Run any command or script periodically and display output on Touch Bar (e.g., weather, network speed)
- ⚙️ **Hot Reloading** — Edit `config.json` and reload from menu bar icon instantly
- 🎨 **Custom Colors** — Per-button color customization
- 🖥️ **Window Management** — Built-in window snapping controls

## Prerequisites

- MacBook Pro with Touch Bar (2016+)
- macOS 10.15 (Catalina) or later
- Xcode command line tools: `xcode-select --install`

## Installation

```bash
git clone https://github.com/yiyuanlee/TouchBarCommander.git
cd TouchBarCommander
make build
make run
```

## Usage

### Menu Bar Icon

After launching, a `🎛️` icon appears in the menu bar:

| Menu Item | Description |
|-----------|-------------|
| Show Touch Bar | Display the custom Touch Bar overlay |
| Reload Config | Hot-reload configuration from `config.json` |
| Preferences | Open preferences window |
| Quit | Exit application |

### Touch Bar Buttons

The default configuration includes:

| Button | Action | Description |
|--------|--------|-------------|
| 🔇 | `mute` | Toggle system mute |
| ➖ | `volume_down` | Decrease volume |
| ➕ | `volume_up` | Increase volume |
| ⏯️ | `media_play_pause` | Play/pause current media |
| ☁️ Weather | `shell` | Display weather from wttr.in |
| 🍅 Pomodoro | `pomodoro` | Pomodoro timer |
| ⬅️ Left | `window_left` | Move window to left half |
| ➡️ Right | `window_right` | Move window to right half |
| ⬆️ Max | `window_maximize` | Maximize window |
| ⚡ Net Speed | `network_speed` | Display real-time network speed |

## Configuration

Edit `config.json` to customize your Touch Bar:

```json
[
  {
    "type": "button",
    "image": "speaker.slash",
    "action": "mute"
  },
  {
    "type": "button",
    "image": "plus",
    "action": "volume_up"
  },
  {
    "type": "button",
    "title": "Weather",
    "image": "cloud.sun.fill",
    "action": "shell",
    "command": "curl -s \"wttr.in/?format=%c%t\" | sed 's/+//'",
    "interval": 900
  }
]
```

### Config Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | `button` or `slider` |
| `title` | string | No | Button title text |
| `image` | string | No | SF Symbol name |
| `action` | string | Yes | Action identifier |
| `color` | string | No | Hex color (e.g., `#6366f1`) |
| `command` | string | No | Shell command for `shell` action |
| `interval` | number | No | Refresh interval in seconds |

### Available Actions

| Action | Description |
|--------|-------------|
| `siri` | Trigger Siri |
| `mute` | Toggle mute |
| `volume_up` / `volume_down` | Adjust volume |
| `media_play_pause` | Play/pause media |
| `shell` | Execute custom shell command |
| `pomodoro` | Pomodoro timer |
| `window_left` / `window_right` / `window_maximize` | Window management |
| `network_speed` | Display network speed |

## Architecture

```
TouchBarCommander/
├── main.swift                 # Application entry point
├── AppDelegate.swift          # App lifecycle management
├── TouchBarManager.swift      # Touch Bar core management
├── Actions.swift             # Action definitions and handlers
├── PreferencesController.swift # Preferences window controller
├── TouchBarPrivate.h         # Private API declarations
├── config.json               # User configuration
└── Makefile                 # Build script
```

## Troubleshooting

**Q: Touch Bar doesn't show up**
A: Make sure you're on a MacBook Pro with Touch Bar and have granted Accessibility permissions in System Settings.

**Q: Build fails with DFRFoundation not found**
A: This project uses private macOS APIs. It cannot be published on App Store. For development, ensure you're using the correct SDK path.

**Q: Shell commands not working**
A: Check that the shell command exits within the timeout period and outputs to stdout.

## Known Limitations

- Uses private `DFRFoundation` API — not App Store compatible
- Requires Touch Bar hardware — not available on other Macs
- Some features may break after macOS updates

## Contributing

Issues and Pull Requests are welcome!

---

<a name="中文"></a>

## 功能特点

- 🎙️ **快捷操作** — 内置 Siri 唤醒以及媒体播放/暂停控制
- 🔊 **系统控制** — 平滑的音量调节滑块和快捷静音切换
- 🔋 **实时监控** — 跟踪电池、CPU、内存使用量
- 🐚 **脚本小组件** — 定期运行 Shell 脚本并在 Touch Bar 显示输出（天气、网速等）
- ⚙️ **热重载** — 编辑 `config.json` 后从菜单栏即时重载
- 🎨 **自定义颜色** — 支持为每个按钮设置不同颜色
- 🖥️ **窗口管理** — 内置窗口分屏控制

## 环境要求

- 带有 Touch Bar 的 MacBook Pro（2016 年款及更新）
- macOS 10.15 (Catalina) 或更新版本
- Xcode 命令行工具: `xcode-select --install`

## 安装

```bash
git clone https://github.com/yiyuanlee/TouchBarCommander.git
cd TouchBarCommander
make build
make run
```

## 使用方法

### 菜单栏图标

启动后，菜单栏会出现 `🎛️` 图标：

| 菜单项 | 说明 |
|--------|------|
| Show Touch Bar | 显示自定义 Touch Bar 浮层 |
| Reload Config | 从 `config.json` 热重载配置 |
| Preferences | 打开偏好设置窗口 |
| Quit | 退出应用 |

### 按钮配置说明

每个按钮支持以下字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | 是 | `button` 或 `slider` |
| `title` | string | 否 | 按钮显示文字 |
| `image` | string | 否 | SF Symbol 图标名 |
| `action` | string | 是 | 操作标识符 |
| `color` | string | 否 | 十六进制颜色（如 `#6366f1`）|
| `command` | string | 否 | `shell` 操作的 shell 命令 |
| `interval` | number | 否 | 刷新间隔（秒）|

## 常见问题

**Q: Touch Bar 不显示**
A: 请确保使用的是带 Touch Bar 的 MacBook Pro，并在系统设置中授予辅助功能权限。

**Q: 编译失败，找不到 DFRFoundation**
A: 本项目使用了 macOS 私有 API，无法在 App Store 上架。开发时请确保使用正确的 SDK 路径。

**Q: Shell 命令不执行**
A: 请检查 shell 命令是否能在超时时间内完成并输出到 stdout。

## 已知限制

- 使用了私有 `DFRFoundation` API，不兼容 App Store
- 需要 Touch Bar 硬件，其他 Mac 机型不可用
- 部分功能可能在 macOS 更新后失效

## 贡献

欢迎提交 Issue 和 Pull Request！
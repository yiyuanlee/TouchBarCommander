# TouchBarCommander

[English](#english) | [中文](#中文)

---

<a name="english"></a>
## English

A lightweight background utility for macOS that lets you customize your MacBook Pro's Touch Bar globally. Written in Swift, it utilizes macOS private APIs (`DFRFoundation`) to register a custom Control Strip button and overlay a completely custom, JSON-configured system modal Touch Bar.

### Features
- 🎙️ **Quick Actions**: Built-in Siri trigger and play/pause media controls.
- 🔊 **System Controls**: Smooth volume slider and toggleable mute button.
- 🔋 **Live Monitoring**: Track battery, CPU, RAM, or custom metrics.
- 🐚 **Shell Script Widgets**: Run any command or script periodically and display the output directly on the Touch Bar (e.g., weather, network speed).
- ⚙️ **Hot Reloading**: Edit `config.json` and reload immediately from the macOS menu bar icon.

### Building and Running
To build and run the application:
```bash
make build  # To compile the application bundle
make run    # To compile and launch TouchBarCommander.app in the background
```

### Configuration
Edit the JSON config file `config.json` in the application directory to customize your widgets.
```json
[
  {
    "type": "button",
    "title": "🎙️ Siri",
    "action": "siri",
    "color": "#6366f1"
  },
  {
    "type": "slider",
    "title": "Volume",
    "action": "volume"
  }
]
```
Select **Reload Config** from the menu bar status icon `🎛️` to apply changes immediately.

---

<a name="中文"></a>
## 中文

这是一个轻量级的 macOS 后台实用工具，允许你全局自定义 MacBook Pro 的 Touch Bar。项目使用 Swift 编写，利用 macOS 私有 API (`DFRFoundation`) 在系统控制条（Control Strip）中注册一个自定义按钮，以此来呼出完全由 JSON 配置的全局系统模态 Touch Bar。

### 功能特点
- 🎙️ **快捷操作**: 内置 Siri 唤醒以及媒体播放/暂停控制。
- 🔊 **系统控制**: 平滑的音量调节滑块和快捷静音切换按钮。
- 🔋 **实时监控**: 跟踪电池电量、CPU 占用率率、内存（RAM）使用量或任何自定义指标。
- 🐚 **脚本小组件**: 定期运行任何终端命令或 Shell 脚本，并将输出直接显示在 Touch Bar 按钮上（例如：天气状况、网速）。
- ⚙️ **热重载**: 随时编辑 `config.json`，并在 macOS 菜单栏图标中选择重载即可立即生效。

### 编译与运行
编译并运行应用程序：
```bash
make build  # 编译生成 app 包
make run    # 编译并在后台启动 TouchBarCommander.app
```

### 配置文件
修改项目目录下的 JSON 配置文件 `config.json` 来自定义你的 Touch Bar 布局：
```json
[
  {
    "type": "button",
    "title": "🎙️ Siri",
    "action": "siri",
    "color": "#6366f1"
  },
  {
    "type": "slider",
    "title": "音量",
    "action": "volume"
  }
]
```
在顶部状态栏的 `🎛️` 图标下拉菜单中点击 **Reload Config** 即可实时应用更改。

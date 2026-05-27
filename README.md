# TouchBarCommander

A lightweight background utility for macOS that lets you customize your MacBook Pro's Touch Bar globally. Written in Swift, it utilizes macOS private APIs (`DFRFoundation`) to register a custom Control Strip button and overlay a completely custom, JSON-configured system modal Touch Bar.

## Features
- 🎙️ **Quick Actions**: Built-in Siri trigger and play/pause media controls.
- 🔊 **System Controls**: Smooth volume slider and toggleable mute button.
- 🔋 **Live Monitoring**: Track battery, CPU, RAM, or custom metrics.
- 🐚 **Shell Script Widgets**: Run any command or script periodically and display the output directly on the Touch Bar (e.g., weather, network speed).
- ⚙️ **Hot Reloading**: Edit `config.json` and reload immediately from the macOS menu bar icon.

## Building and Running
To build and run the application:
```bash
make build  # To compile
make run    # To compile and run TouchBarCommander.app in the background
```

## Configuration
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

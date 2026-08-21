# OmaSwitch

OmaSwitch is a compact, One Switch-inspired control panel for the Omarchy bar.
It puts common desktop switches in one popup while delegating every change to
Omarchy's supported command-line interface.

## Controls

- Wi-Fi
- Bluetooth
- Night Light
- Keep Awake
- Do Not Disturb
- Omarchy bar visibility
- Full-screen black Screen Clean mode (`Esc` exits)
- Hidden files in open Nautilus windows and GTK file pickers
- Lock and Screen Saver quick actions

Left-click the bar icon to open the panel. Right-click it to toggle Keep Awake.

## Install

```bash
omarchy plugin add https://github.com/OWNER/omaswitch --enable
```

For local development:

```bash
ln -s "$PWD" ~/.config/omarchy/plugins/wei.omaswitch
omarchy-shell shell rescanPlugins
omarchy plugin enable wei.omaswitch
```

The panel refreshes its state every three seconds while open and immediately
after an action, so changes made elsewhere remain in sync.

## Requirements

OmaSwitch expects a current Omarchy installation and its standard `omarchy`,
`omarchy-shell`, `nmcli`, `hyprctl`, and `jq` commands.

## License

MIT

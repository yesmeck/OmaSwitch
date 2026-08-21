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
Select **Customize switches** at the bottom of the panel to open the scrollable
settings window. Use the checkboxes to choose which controls appear, and drag
the handles to change their order. Visibility and ordering are saved in the
OmaSwitch bar entry and persist across shell restarts.

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

## Custom switches

Create `omaswitch/switches.json` under `$XDG_CONFIG_HOME` to add your own
switches and action buttons. If `XDG_CONFIG_HOME` is unset, OmaSwitch uses the
standard `~/.config/omaswitch/switches.json` path. The file contains an array of
definitions:

```json
[
  {
    "id": "microphone",
    "label": "Microphone",
    "icon": "󰍬",
    "statusCommand": ["my-microphone-tool", "is-enabled"],
    "toggleCommand": ["my-microphone-tool", "toggle"],
    "onLabel": "Enabled",
    "offLabel": "Muted"
  },
  {
    "id": "open-notes",
    "label": "Open Notes",
    "icon": "󰎞",
    "actionCommand": ["xdg-open", "/home/me/Notes"],
    "offLabel": "Open the notes folder"
  }
]
```

For a toggle, `statusCommand` must exit with status `0` when the switch is on
and with a non-zero status when it is off. `toggleCommand` changes that state.
An action button uses `actionCommand` instead and does not show an on/off
state. Commands are arrays containing the executable followed by its arguments;
they are executed directly, without implicit shell interpretation. To use shell
syntax intentionally, specify it explicitly, for example
`["bash", "-lc", "your command"]`.

Built-in controls use the same command format in the plugin's bundled
`switches.json`. In a command argument, `$PLUGIN_DIR` resolves to the plugin
installation directory, allowing a definition to invoke a bundled executable.

Custom IDs may contain letters, numbers, `.`, `_`, and `-`. They must start
with a letter or number and cannot duplicate a built-in ID. Invalid definitions
are ignored. Custom controls automatically appear in **Customize switches**,
where they can be hidden or reordered like built-in controls. OmaSwitch reloads
the configuration while its panel is open.

## Requirements

OmaSwitch expects a current Omarchy installation and its standard `omarchy`,
`omarchy-shell`, `nmcli`, `hyprctl`, and `jq` commands.

## License

MIT

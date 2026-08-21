import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "wei.omaswitch"
  ipcTarget: "wei.omaswitch"
  manageIpc: false

  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
  readonly property string helper: pluginDir + "/omaswitch"
  property var state: ({ wifi: false, bluetooth: false, nightlight: false, awake: false, dnd: false, bar: true, clean: false, "hidden-files": false })
  property string pending: ""
  property int revision: 0

  readonly property var switches: {
    var r = revision
    return [
      { key: "wifi", icon: "󰖩", label: "Wi-Fi", on: "Connected", off: "Radio off" },
      { key: "bluetooth", icon: "󰂯", label: "Bluetooth", on: "Available", off: "Radio off" },
      { key: "nightlight", icon: "󰖔", label: "Night Light", on: "Warm display", off: "Normal color" },
      { key: "awake", icon: "󰅶", label: "Keep Awake", on: "Idle paused", off: "Idle allowed" },
      { key: "dnd", icon: "󰂛", label: "Do Not Disturb", on: "Notifications quiet", off: "Notifications on" },
      { key: "bar", icon: "󰍜", label: "Omarchy Bar", on: "Visible", off: "Hidden" },
      { key: "clean", icon: "󰃢", label: "Screen Clean", on: "Press Esc to exit", off: "Black focus screen" },
      { key: "hidden-files", icon: "󰈈", label: "Hidden Files", on: "Files visible", off: "Files hidden" },
      { key: "lock", iconSource: Qt.resolvedUrl("assets/lock.svg"), label: "Lock", action: true, off: "Lock the screen" },
      { key: "screensaver", iconSource: Qt.resolvedUrl("assets/screensaver.svg"), label: "Screen Saver", action: true, off: "Start the screen saver" }
    ]
  }

  function checked(key) { return state && state[key] === true }

  function refresh() {
    if (!statusProcess.running) statusProcess.running = true
  }

  function toggleSwitch(key) {
    if (key === "clean") {
      close()
      if (bar && bar.shell && typeof bar.shell.summon === "function")
        bar.shell.summon("wei.omaswitch", "{}")
      return
    }
    if (toggleProcess.running) return
    pending = key
    var next = Object.assign({}, state)
    next[key] = !checked(key)
    state = next
    revision++
    toggleProcess.command = [helper, "toggle", key]
    toggleProcess.running = true
  }

  function runAction(name) {
    Quickshell.execDetached([helper, "action", name])
    close()
  }

  onOpenedChanged: if (opened) refresh()

  Timer {
    interval: 3000
    running: root.opened
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProcess
    command: [root.helper, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.state = JSON.parse(text.trim())
          root.revision++
        } catch (error) {
          console.warn("omaswitch: invalid status", text, error)
        }
      }
    }
  }

  Process {
    id: toggleProcess
    onExited: {
      root.pending = ""
      root.refresh()
    }
  }

  IpcHandler {
    target: "wei.omaswitch"

    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    iconComponent: Component {
      Image {
        source: Qt.resolvedUrl("assets/omaswitch.svg")
        fillMode: Image.PreserveAspectFit
        smooth: true
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1
          colorizationColor: root.bar ? root.bar.foreground : Color.foreground
        }
      }
    }
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) root.toggleSwitch("awake")
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    Column {
      id: content
      anchors.fill: parent
      spacing: Style.space(14)

      Row {
        width: parent.width
        spacing: Style.space(10)

        Image {
          width: Style.font.display
          height: width
          source: Qt.resolvedUrl("assets/omaswitch.svg")
          fillMode: Image.PreserveAspectFit
          smooth: true
          layer.enabled: true
          layer.effect: MultiEffect {
            colorization: 1
            colorizationColor: root.bar.foreground
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          Text {
            text: "OmaSwitch"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            text: "EVERYDAY CONTROLS"
            color: Qt.darker(root.bar.foreground, 1.45)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            font.letterSpacing: 1.1
          }
        }
      }

      Column {
        width: parent.width
        spacing: Style.space(6)

        Repeater {
          model: root.switches
          delegate: SwitchTile {
            required property var modelData
            width: content.width
            icon: modelData.icon
            iconSource: modelData.iconSource || ""
            label: modelData.label
            checked: !modelData.action && root.checked(modelData.key)
            detail: checked ? modelData.on : modelData.off
            busy: root.pending === modelData.key
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            onToggled: {
              if (modelData.action) root.runAction(modelData.key)
              else root.toggleSwitch(modelData.key)
            }
          }
        }
      }
    }
  }
}

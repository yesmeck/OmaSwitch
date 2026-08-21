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

  ListModel { id: settingsModel }

  Timer {
    id: settingsSaveTimer
    interval: 120
    onTriggered: root.persistSettingsModel()
  }

  readonly property var allSwitches: {
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

  readonly property var orderedSwitches: {
    var configured = settings && settings.switchOrder
    if (!(configured instanceof Array)) return allSwitches
    var ordered = []
    var seen = ({})
    for (var i = 0; i < configured.length; i++) {
      for (var j = 0; j < allSwitches.length; j++) {
        if (allSwitches[j].key === configured[i] && !seen[configured[i]]) {
          ordered.push(allSwitches[j])
          seen[configured[i]] = true
          break
        }
      }
    }
    for (var k = 0; k < allSwitches.length; k++)
      if (!seen[allSwitches[k].key]) ordered.push(allSwitches[k])
    return ordered
  }

  readonly property var switches: {
    var visibleKeys = settings && settings.visibleSwitches
    if (!(visibleKeys instanceof Array)) return orderedSwitches
    var result = []
    for (var i = 0; i < orderedSwitches.length; i++)
      if (visibleKeys.indexOf(orderedSwitches[i].key) !== -1) result.push(orderedSwitches[i])
    return result
  }

  function checked(key) { return state && state[key] === true }

  function switchVisible(key) {
    var configured = settings && settings.visibleSwitches
    return !(configured instanceof Array) || configured.indexOf(key) !== -1
  }

  function populateSettingsModel() {
    settingsModel.clear()
    for (var i = 0; i < orderedSwitches.length; i++) {
      var item = orderedSwitches[i]
      settingsModel.append({
        controlKey: item.key,
        controlLabel: item.label,
        controlIcon: item.icon || "",
        controlIconSource: String(item.iconSource || ""),
        shown: switchVisible(item.key)
      })
    }
  }

  function persistSettingsModel() {
    var order = []
    var visible = []
    for (var i = 0; i < settingsModel.count; i++) {
      var item = settingsModel.get(i)
      order.push(item.controlKey)
      if (item.shown) visible.push(item.controlKey)
    }

    var entry = { id: moduleName }
    for (var existing in settings)
      if (existing !== "id" && existing !== "visibleSwitches" && existing !== "switchOrder")
        entry[existing] = settings[existing]
    entry.visibleSwitches = visible
    entry.switchOrder = order
    settings = entry
    if (bar && bar.shell && typeof bar.shell.updateEntryInline === "function")
      bar.shell.updateEntryInline(moduleName, entry)
  }

  function openSettings() {
    close()
    populateSettingsModel()
    settingsWindow.visible = true
    Qt.callLater(function() { settingsFocus.forceActiveFocus() })
  }

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
    function configure() { root.openSettings() }
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

      BorderSurface {
        width: parent.width
        implicitHeight: Style.space(42)
        radius: Style.cornerRadius
        color: Style.normalFillFor(root.bar.foreground, Color.accent)
        borderSpec: Border.controlSpec(settingsMouse.containsMouse ? "hover-cursor" : "normal", root.bar.foreground, Color.accent)

        Row {
          anchors.centerIn: parent
          spacing: Style.space(8)

          Text {
            text: "󰒓"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.subtitle
          }

          Text {
            text: "Customize switches"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        MouseArea {
          id: settingsMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.openSettings()
        }
      }
    }
  }

  FloatingWindow {
    id: settingsWindow
    title: "OmaSwitch Settings"
    color: Color.background
    implicitWidth: Style.space(420)
    implicitHeight: Style.space(700)
    minimumSize: Qt.size(360, 520)

    FocusScope {
      id: settingsFocus
      anchors.fill: parent
      anchors.margins: Style.space(24)
      focus: true

      Keys.onEscapePressed: settingsWindow.visible = false

      Column {
        anchors.fill: parent
        spacing: Style.space(16)

        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            text: "OmaSwitch Settings"
            color: Color.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.display
            font.bold: true
          }

          Text {
            text: "Choose which controls appear in the switch panel."
            color: Qt.darker(Color.foreground, 1.45)
            font.family: Style.font.family
            font.pixelSize: Style.font.subtitle
          }
        }

        ScrollView {
          width: parent.width
          height: parent.height - y
          clip: true
          ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
          ScrollBar.vertical.policy: ScrollBar.AsNeeded

          ListView {
            id: settingsList
            spacing: Style.space(6)
            boundsBehavior: Flickable.StopAtBounds
            model: settingsModel

            displaced: Transition {
              NumberAnimation { properties: "x,y"; duration: 140; easing.type: Easing.OutCubic }
            }

            delegate: DropArea {
              id: dropTarget
              required property int index
              required property string controlKey
              required property string controlLabel
              required property string controlIcon
              required property string controlIconSource
              required property bool shown

              width: settingsList.width
              height: Style.space(56)

              onEntered: function(drag) {
                if (!drag.source || drag.source.dragIndex === index) return
                var from = drag.source.dragIndex
                settingsModel.move(from, index, 1)
                drag.source.dragIndex = index
                settingsSaveTimer.restart()
              }

              BorderSurface {
                id: settingsRow
                property int dragIndex: dropTarget.index
                width: dropTarget.width
                height: dropTarget.height
                radius: Style.cornerRadius
                color: Style.normalFillFor(Color.foreground, Color.accent)
                borderSpec: Border.controlSpec(dragHandler.active ? "hover-cursor" : "normal", Color.foreground, Color.accent)
                z: dragHandler.active ? 10 : 0

                Drag.active: dragHandler.active
                Drag.source: settingsRow
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2

                Row {
                  anchors.fill: parent
                  anchors.leftMargin: Style.space(10)
                  anchors.rightMargin: Style.space(10)
                  spacing: Style.space(10)

                  CheckBox {
                    id: visibilityCheck
                    anchors.verticalCenter: parent.verticalCenter
                    checked: dropTarget.shown
                    onToggled: {
                      settingsModel.setProperty(dropTarget.index, "shown", checked)
                      root.persistSettingsModel()
                    }
                  }

                  Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.font.title * 1.35
                    height: width

                    Image {
                      anchors.fill: parent
                      visible: dropTarget.controlIconSource !== ""
                      source: dropTarget.controlIconSource
                      fillMode: Image.PreserveAspectFit
                      smooth: true
                      layer.enabled: visible
                      layer.effect: MultiEffect {
                        colorization: 1
                        colorizationColor: Color.foreground
                      }
                    }

                    Text {
                      anchors.centerIn: parent
                      visible: dropTarget.controlIconSource === ""
                      text: dropTarget.controlIcon
                      color: Color.foreground
                      font.family: Style.font.family
                      font.pixelSize: Style.font.title * 1.35
                    }
                  }

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - visibilityCheck.width - Style.space(88)
                    text: dropTarget.controlLabel
                    color: Color.foreground
                    font.family: Style.font.family
                    font.pixelSize: Style.font.subtitle
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Style.space(30)
                    height: parent.height

                    Text {
                      anchors.centerIn: parent
                      text: "󰁝"
                      color: Color.foreground
                      opacity: 0.6
                      font.family: Style.font.family
                      font.pixelSize: Style.font.title
                    }

                    DragHandler {
                      id: dragHandler
                      target: settingsRow
                      acceptedButtons: Qt.LeftButton
                      onActiveChanged: {
                        if (active) settingsRow.dragIndex = dropTarget.index
                        else settingsSaveTimer.restart()
                      }
                    }
                  }
                }

                states: State {
                  when: dragHandler.active
                  ParentChange { target: settingsRow; parent: settingsFocus }
                }
              }
            }
          }
        }
      }
    }
  }
}

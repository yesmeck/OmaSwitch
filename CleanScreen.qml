import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  function open(payloadJson) {
    opened = true
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() { opened = false }

  function dismiss() {
    opened = false
    if (shell && typeof shell.hide === "function")
      shell.hide((manifest && manifest.id) || "wei.omaswitch")
  }

  function toggle() {
    if (opened) dismiss()
    else open("{}")
  }

  PanelWindow {
    visible: root.opened
    anchors { top: true; right: true; bottom: true; left: true }
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omaswitch-clean-screen"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Item {
      id: keyCatcher
      anchors.fill: parent
      focus: true

      Keys.priority: Keys.BeforeItem
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
          root.dismiss()
          event.accepted = true
        }
      }

      Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(48)
        spacing: Style.space(8)

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "SCREEN CLEAN"
          color: "white"
          opacity: 0.72
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 2
        }

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: exitRow.implicitWidth + Style.space(24)
          height: exitRow.implicitHeight + Style.space(12)
          radius: Style.cornerRadius
          color: "#171717"
          border.width: 1
          border.color: "#383838"

          Row {
            id: exitRow
            anchors.centerIn: parent
            spacing: Style.space(8)

            Text {
              text: "ESC"
              color: "white"
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Text {
              text: "Exit clean screen"
              color: "white"
              opacity: 0.72
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}

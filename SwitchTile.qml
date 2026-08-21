import QtQuick
import qs.Commons
import qs.Ui

BorderSurface {
  id: root

  property string icon: ""
  property string label: ""
  property string detail: ""
  property bool checked: false
  property bool busy: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family

  signal toggled()

  implicitWidth: Style.space(320)
  implicitHeight: Style.space(56)
  radius: Style.cornerRadius
  color: checked
    ? Style.selectedFillFor(foreground, accent)
    : Style.normalFillFor(foreground, accent)
  borderSpec: Border.controlSpec(mouse.containsMouse ? "hover-cursor" : (checked ? "selected" : "normal"), foreground, accent)

  Behavior on color { ColorAnimation { duration: 120 } }

  Text {
    id: glyph
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: Style.space(12)
    text: root.icon
    color: root.foreground
    opacity: root.busy ? 0.45 : 1
    font.family: root.fontFamily
    font.pixelSize: Style.font.title * 1.45
  }

  ToggleSwitch {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: Style.space(8)
    checked: root.checked
    busy: root.busy
    interactive: false
    cursorRing: false
    foreground: root.foreground
    accent: root.accent
    trackHeight: Style.space(18)
  }

  Column {
    anchors.left: glyph.right
    anchors.leftMargin: Style.space(12)
    anchors.right: parent.right
    anchors.rightMargin: Style.space(58)
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    Text {
      width: parent.width
      text: root.label
      color: root.foreground
      font.family: root.fontFamily
      font.pixelSize: Style.font.subtitle
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      text: root.detail
      color: Qt.darker(root.foreground, 1.45)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: !root.busy
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}

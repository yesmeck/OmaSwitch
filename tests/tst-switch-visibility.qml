import QtQuick 2.15
import QtTest 1.3
import "../SwitchVisibility.js" as SwitchVisibility

TestCase {
  name: "SwitchVisibility"

  function test_noVisibilitySettingsShowsEverything() {
    compare(SwitchVisibility.isVisible({ key: "wifi", custom: false }, undefined, undefined), true)
  }

  function test_legacySettingsShowNewCustomSwitches() {
    var visible = ["wifi"]
    compare(SwitchVisibility.isVisible({ key: "microphone", custom: true }, visible, undefined), true)
  }

  function test_legacySettingsKeepHiddenBuiltInsHidden() {
    var visible = ["wifi"]
    compare(SwitchVisibility.isVisible({ key: "bar", custom: false }, visible, undefined), false)
  }

  function test_knownHiddenSwitchStaysHidden() {
    var visible = ["wifi"]
    var known = ["wifi", "microphone"]
    compare(SwitchVisibility.isVisible({ key: "microphone", custom: true }, visible, known), false)
  }

  function test_newSwitchIsVisibleWithKnownSettings() {
    var visible = ["wifi"]
    var known = ["wifi", "microphone"]
    compare(SwitchVisibility.isVisible({ key: "open-notes", custom: true }, visible, known), true)
  }
}

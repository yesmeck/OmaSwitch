.pragma library

function isVisible(control, visible, known) {
  if (!(visible instanceof Array)) return true
  if (visible.indexOf(control.key) !== -1) return true
  if (known instanceof Array) return known.indexOf(control.key) === -1

  // Before knownSwitches existed, absence meant a built-in control had been
  // hidden. Custom controls cannot have been known to that legacy setting.
  return control.custom === true
}

class_name PlayWorldControllerGlyphs
extends RefCounted

const CONTEXT_GAMEPAD: StringName = &"gamepad"
const CONTEXT_KEYBOARD_MOUSE: StringName = &"keyboard_mouse"

static func action_hint(action: StringName, context: StringName) -> String:
    if context == CONTEXT_GAMEPAD:
        match action:
            &"activate": return "A  Activate"
            &"confirm": return "A  Confirm"
            &"back": return "B  Back"
            &"tool_wheel": return "LB  Tool wheel"
            &"navigate": return "D-pad / Left stick  Navigate"
            &"transform": return "D-pad  Adjust"
            &"play_exit": return "B / View  Exit play"
            &"pause": return "Menu  Pause"
            _: return "A  Select"
    match action:
        &"activate": return "Enter  Activate"
        &"confirm": return "Enter  Confirm"
        &"back": return "Esc  Back"
        &"tool_wheel": return "Q  Tool wheel"
        &"navigate": return "Arrow keys / Tab  Navigate"
        &"transform": return "Arrow keys  Adjust"
        &"play_exit": return "Esc  Exit play"
        &"pause": return "P  Pause"
        _: return "Enter  Select"

static func control_action(control_name: StringName) -> StringName:
    var normalized: String = str(control_name).to_lower()
    if normalized.contains("back") or normalized.contains("close") or normalized == "homebutton": return &"back"
    if normalized.contains("confirm") or normalized.contains("commit") or normalized.contains("exportnow"): return &"confirm"
    if normalized.contains("toolwheel"): return &"tool_wheel"
    return &"activate"

static func control_hint(control_name: StringName, context: StringName) -> String:
    return action_hint(control_action(control_name), context)

class_name PlayWorldSessionRecoveryService
extends Node

const ReleasePaths = preload("res://src/release/release_paths.gd")
const SESSION_PATH := "user://release/session_state.json"
const SAFE_MODE_PATH := "user://release/safe_mode.json"
const RESET_BACKUP_ROOT := "user://release/preference_reset_backups"

signal recovery_required(snapshot: Dictionary)
signal safe_mode_changed(enabled: bool)

var startup_result: Dictionary = {}
var _session_id := ""
var _abnormal_shutdown := false
var _safe_mode := false
var _recovery_acknowledged := false
var _clean_written := false
var _overlay: PanelContainer
var _overlay_status: Label

func _ready() -> void:
    startup_result = begin_session()
    if _abnormal_shutdown:
        recovery_required.emit(recovery_snapshot())
        call_deferred("_attach_recovery_overlay")

func begin_session() -> Dictionary:
    var previous: Dictionary = {}
    if FileAccess.file_exists(SESSION_PATH):
        var read := ReleasePaths.read_json(SESSION_PATH)
        if read.get("ok", false): previous = read.get("value", {})
    _safe_mode = _load_safe_mode()
    _apply_safe_mode_runtime(_safe_mode)
    _abnormal_shutdown = not previous.is_empty() and not bool(previous.get("clean_shutdown", false)) and not bool(previous.get("update_handoff", false))
    _recovery_acknowledged = not _abnormal_shutdown
    _session_id = "%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
    var state := {
        "schema_version": 1,
        "session_id": _session_id,
        "started_at_unix": int(Time.get_unix_time_from_system()),
        "clean_shutdown": false,
        "update_handoff": false,
        "safe_mode": _safe_mode,
        "previous_session_id": str(previous.get("session_id", "")),
        "previous_abnormal": _abnormal_shutdown,
    }
    var written := ReleasePaths.atomic_write_json(SESSION_PATH, state)
    if not written.get("ok", false): return written
    return {"ok": true, "errors": [], "abnormal_shutdown": _abnormal_shutdown, "safe_mode": _safe_mode, "previous": previous}

func mark_update_handoff() -> Dictionary:
    var state := _current_state()
    state["update_handoff"] = true
    state["clean_shutdown"] = true
    state["closed_at_unix"] = int(Time.get_unix_time_from_system())
    _clean_written = true
    return ReleasePaths.atomic_write_json(SESSION_PATH, state)

func mark_clean_shutdown() -> Dictionary:
    if _clean_written: return {"ok": true, "errors": [], "idempotent": true}
    var state := _current_state()
    state["clean_shutdown"] = true
    state["update_handoff"] = false
    state["closed_at_unix"] = int(Time.get_unix_time_from_system())
    _clean_written = true
    return ReleasePaths.atomic_write_json(SESSION_PATH, state)

func acknowledge_recovery() -> Dictionary:
    _recovery_acknowledged = true
    _abnormal_shutdown = false
    var state := _current_state()
    state["previous_abnormal"] = false
    state["recovery_acknowledged_at_unix"] = int(Time.get_unix_time_from_system())
    var result := ReleasePaths.atomic_write_json(SESSION_PATH, state)
    if result.get("ok", false) and _overlay != null: _overlay.hide()
    return result

func set_safe_mode(enabled: bool) -> Dictionary:
    _safe_mode = enabled
    _apply_safe_mode_runtime(enabled)
    var result := ReleasePaths.atomic_write_json(SAFE_MODE_PATH, {
        "schema_version": 1,
        "enabled": enabled,
        "updated_at_unix": int(Time.get_unix_time_from_system()),
    })
    if not result.get("ok", false): return result
    var state := _current_state()
    state["safe_mode"] = enabled
    var state_write := ReleasePaths.atomic_write_json(SESSION_PATH, state)
    if not state_write.get("ok", false): return state_write
    safe_mode_changed.emit(enabled)
    return {"ok": true, "errors": [], "enabled": enabled}

func reset_preferences_non_destructive() -> Dictionary:
    var backup_root := RESET_BACKUP_ROOT.path_join(str(Time.get_unix_time_from_system()))
    var directory := ReleasePaths.ensure_directory(backup_root)
    if not directory.get("ok", false): return directory
    var candidates := [
        "user://scale_polish.cfg",
        "user://release/update_preferences.cfg",
        "user://release/safe_mode.json",
    ]
    var backups: Array[Dictionary] = []
    var errors: Array[String] = []
    for source in candidates:
        if not FileAccess.file_exists(source): continue
        var target := backup_root.path_join(source.replace("user://", "").replace("/", "__") + ".bak")
        var copied := ReleasePaths.copy_file(source, target)
        if not copied.get("ok", false):
            errors.append_array(copied.get("errors", []))
            continue
        var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(source))
        if remove_error != OK:
            errors.append("Preference file could not be reset after backup: %s" % ReleasePaths.redact_path(source))
            continue
        backups.append({"source": source, "backup": target})
    if not errors.is_empty(): return {"ok": false, "errors": errors, "backups": backups, "backup_root": backup_root}
    _safe_mode = false
    _apply_safe_mode_runtime(false)
    safe_mode_changed.emit(false)
    return {"ok": true, "errors": [], "backups": backups, "backup_root": backup_root, "projects_preserved": true}

func recovery_snapshot() -> Dictionary:
    return {
        "abnormal_shutdown": _abnormal_shutdown,
        "recovery_acknowledged": _recovery_acknowledged,
        "safe_mode": _safe_mode,
        "session_id": _session_id,
        "preference_reset_available": true,
        "projects_untouched": true,
    }

func is_safe_mode() -> bool: return _safe_mode
func has_abnormal_shutdown() -> bool: return _abnormal_shutdown

func show_recovery_screen_for_evidence() -> void:
    _abnormal_shutdown = true
    _recovery_acknowledged = false
    call_deferred("_attach_recovery_overlay")

func _notification(what: int) -> void:
    if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_PREDELETE]: mark_clean_shutdown()

func _attach_recovery_overlay() -> void:
    if _overlay != null:
        _overlay.show()
        return
    for _frame in range(30):
        var scene := get_tree().current_scene
        if scene != null:
            _build_recovery_overlay(scene)
            return
        await get_tree().process_frame

func _build_recovery_overlay(scene: Node) -> void:
    if _overlay != null: return
    _overlay = PanelContainer.new()
    _overlay.name = "Phase19RecoveryOverlay"
    _overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _overlay.theme_type_variation = &"DrawerPanel"
    _overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    scene.add_child(_overlay)
    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 72)
    margin.add_theme_constant_override("margin_top", 56)
    margin.add_theme_constant_override("margin_right", 72)
    margin.add_theme_constant_override("margin_bottom", 56)
    _overlay.add_child(margin)
    var card := PanelContainer.new()
    card.theme_type_variation = &"ElevatedPanel"
    card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    card.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(card)
    var inner := MarginContainer.new()
    for side in ["left", "top", "right", "bottom"]: inner.add_theme_constant_override("margin_%s" % side, 28)
    card.add_child(inner)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 16)
    inner.add_child(column)
    var eyebrow := Label.new(); eyebrow.text = "RECOVERY"; eyebrow.theme_type_variation = &"AccentCaption"; column.add_child(eyebrow)
    var title := Label.new(); title.text = "PlayWorld Studio did not close normally"; title.theme_type_variation = &"TitleLabel"; column.add_child(title)
    var body := Label.new(); body.text = "Your projects were not deleted or rewritten. Continue normally, use safe mode, or back up and reset preferences before returning to the creator."; body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; body.theme_type_variation = &"SecondaryLabel"; column.add_child(body)
    _overlay_status = Label.new(); _overlay_status.text = "Safe mode is %s. Update recovery is checked separately." % ("on" if _safe_mode else "off"); _overlay_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; _overlay_status.theme_type_variation = &"CaptionLabel"; column.add_child(_overlay_status)
    var actions := HFlowContainer.new(); actions.add_theme_constant_override("h_separation", 12); actions.add_theme_constant_override("v_separation", 12); column.add_child(actions)
    var continue_button := _recovery_button("Continue Normally", &"PrimaryButton", Vector2(180, 48)); actions.add_child(continue_button)
    var safe_button := _recovery_button("Launch in Safe Mode", &"", Vector2(190, 48)); actions.add_child(safe_button)
    var reset_button := _recovery_button("Back Up & Reset Preferences", &"", Vector2(235, 48)); actions.add_child(reset_button)
    var diagnostics_button := _recovery_button("Open Diagnostics", &"", Vector2(160, 48)); actions.add_child(diagnostics_button)
    continue_button.pressed.connect(func(): acknowledge_recovery(); set_safe_mode(false))
    safe_button.pressed.connect(func(): set_safe_mode(true); acknowledge_recovery())
    reset_button.pressed.connect(_reset_from_overlay)
    diagnostics_button.pressed.connect(_diagnostics_from_overlay)
    var controls: Array[Control] = [continue_button, safe_button, reset_button, diagnostics_button]
    for index in range(controls.size() - 1):
        controls[index].focus_next = controls[index].get_path_to(controls[index + 1])
        controls[index + 1].focus_previous = controls[index + 1].get_path_to(controls[index])
    continue_button.call_deferred("grab_focus")

func _recovery_button(text: String, variation: StringName, minimum: Vector2) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = minimum
    if not variation.is_empty(): button.theme_type_variation = variation
    return button

func _reset_from_overlay() -> void:
    var result := reset_preferences_non_destructive()
    if _overlay_status != null:
        _overlay_status.text = "Preferences were backed up and reset. Projects remain untouched." if result.get("ok", false) else "Preference reset stopped safely: %s" % str(result.get("errors", []))

func _diagnostics_from_overlay() -> void:
    var maintenance := get_node_or_null("/root/ReleaseMaintenance")
    if maintenance != null and maintenance.has_method("show_support_panel"):
        _overlay.hide()
        maintenance.call("show_support_panel")


func _apply_safe_mode_runtime(enabled: bool) -> void:
    ProjectSettings.set_setting("playworld/release/safe_mode_active", enabled)
    OS.set_environment("PLAYWORLD_SAFE_MODE", "1" if enabled else "")
    OS.set_environment("PLAYWORLD_DISABLE_UPDATE_NETWORK", "1" if enabled else "")
    OS.set_environment("PLAYWORLD_DISABLE_CLOUD_AI", "1" if enabled else "")
    OS.set_environment("PLAYWORLD_DISABLE_MULTIPLAYER", "1" if enabled else "")
    if enabled:
        var network := get_node_or_null("/root/NetworkRuntime")
        if network != null and network.has_method("set_offline"): network.call_deferred("set_offline")

func _load_safe_mode() -> bool:
    if not FileAccess.file_exists(SAFE_MODE_PATH): return false
    var read := ReleasePaths.read_json(SAFE_MODE_PATH)
    if not read.get("ok", false): return false
    return bool((read.get("value", {}) as Dictionary).get("enabled", false))

func _current_state() -> Dictionary:
    if FileAccess.file_exists(SESSION_PATH):
        var read := ReleasePaths.read_json(SESSION_PATH)
        if read.get("ok", false):
            var value: Variant = read.get("value", {})
            if value is Dictionary: return value
    return {"schema_version": 1, "session_id": _session_id, "started_at_unix": int(Time.get_unix_time_from_system()), "clean_shutdown": false, "update_handoff": false, "safe_mode": _safe_mode}

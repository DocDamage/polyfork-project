class_name PlayWorldScalePolishService
extends Node

signal preferences_changed(settings: Dictionary)
signal input_context_changed(context: StringName)
signal layout_mode_changed(compact: bool)
signal operation_status_changed(status: Dictionary)

const Profiles = preload("res://src/scale/performance_profiles.gd")
const UserPreferences = preload("res://src/scale/user_preferences.gd")
const BASE_TOUCH_TARGET := 44.0
const COMFORTABLE_TOUCH_TARGET := 52.0

var _store = UserPreferences.new()
var _settings: Dictionary = UserPreferences.defaults()
var _input_context: StringName = &"keyboard_mouse"
var _compact_layout := false
var _operation_serial := 0
var _operations: Dictionary = {}


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    var load_result: Dictionary = _store.load_preferences()
    if load_result.get("ok", false):
        _settings = load_result.get("settings", UserPreferences.defaults()).duplicate(true)
    else:
        push_warning(str(load_result.get("errors", [])))
    _apply_root_scale()
    if not get_tree().node_added.is_connected(_on_node_added):
        get_tree().node_added.connect(_on_node_added)
    if not get_tree().root.size_changed.is_connected(_refresh_layout_mode):
        get_tree().root.size_changed.connect(_refresh_layout_mode)
    _refresh_layout_mode()
    call_deferred("_apply_existing_controls")


func _input(event: InputEvent) -> void:
    var next_context := _input_context
    if event is InputEventJoypadButton or event is InputEventJoypadMotion:
        next_context = &"gamepad"
    elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
        next_context = &"keyboard_mouse"
    if next_context != _input_context:
        _input_context = next_context
        input_context_changed.emit(_input_context)


func get_preferences() -> Dictionary:
    return _settings.duplicate(true)


func get_effective_profile() -> Dictionary:
    return Profiles.get_profile(_settings.get("performance_preset", Profiles.DEFAULT))


func get_input_context() -> StringName:
    return _input_context


func is_compact_layout() -> bool:
    return _compact_layout


func is_reduced_motion() -> bool:
    return bool(_settings.get("reduced_motion", false))


func get_density() -> StringName:
    return StringName(str(_settings.get("density", "comfortable")))


func get_minimum_target_size() -> float:
    return BASE_TOUCH_TARGET if get_density() == &"compact" else COMFORTABLE_TOUCH_TARGET


func set_performance_preset(value: Variant) -> Dictionary:
    _settings["performance_preset"] = str(Profiles.normalize_id(value))
    return _persist_and_apply()


func set_ui_scale(value: float) -> Dictionary:
    _settings["ui_scale"] = value
    return _persist_and_apply()


func set_reduced_motion(value: bool) -> Dictionary:
    _settings["reduced_motion"] = value
    return _persist_and_apply()


func set_density(value: Variant) -> Dictionary:
    _settings["density"] = str(value)
    return _persist_and_apply()


func reset_preferences() -> Dictionary:
    _settings = UserPreferences.defaults()
    return _persist_and_apply()


func begin_operation(label: String, subsystem: String = "application") -> int:
    _operation_serial += 1
    var operation := {
        "operation_id": _operation_serial,
        "label": label,
        "subsystem": subsystem,
        "started_usec": Time.get_ticks_usec(),
        "finished": false,
        "ok": true,
        "elapsed_ms": 0.0,
        "message": "%s…" % label,
    }
    _operations[_operation_serial] = operation
    operation_status_changed.emit(operation.duplicate(true))
    return _operation_serial


func finish_operation(operation_id: int, ok: bool = true, message: String = "") -> Dictionary:
    if not _operations.has(operation_id):
        return {"ok": false, "errors": ["Unknown operation id."]}
    var operation: Dictionary = _operations[operation_id]
    operation["finished"] = true
    operation["ok"] = ok
    operation["elapsed_ms"] = float(Time.get_ticks_usec() - int(operation["started_usec"])) / 1000.0
    operation["message"] = message if not message.is_empty() else ("%s complete" % operation["label"] if ok else "%s failed" % operation["label"])
    _operations[operation_id] = operation
    operation_status_changed.emit(operation.duplicate(true))
    return {"ok": true, "errors": [], "operation": operation.duplicate(true)}


func sample_runtime() -> Dictionary:
    var fps := max(0.0, float(Engine.get_frames_per_second()))
    return {
        "fps": fps,
        "frame_time_ms": 0.0 if fps <= 0.0 else 1000.0 / fps,
        "memory_static_mb": float(Performance.get_monitor(Performance.MEMORY_STATIC)) / (1024.0 * 1024.0),
        "object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
        "node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
    }


func apply_accessibility_to_subtree(root: Node) -> void:
    if root == null:
        return
    _apply_control(root)
    for child in root.get_children():
        apply_accessibility_to_subtree(child)


func _persist_and_apply() -> Dictionary:
    _settings = UserPreferences.normalize(_settings)
    var save_result: Dictionary = _store.save_preferences(_settings)
    if not save_result.get("ok", false):
        return save_result
    _settings = save_result.get("settings", _settings).duplicate(true)
    _apply_root_scale()
    _apply_existing_controls()
    preferences_changed.emit(_settings.duplicate(true))
    return {"ok": true, "errors": [], "settings": _settings.duplicate(true), "profile": get_effective_profile()}


func _apply_root_scale() -> void:
    if get_tree() == null or get_tree().root == null:
        return
    get_tree().root.content_scale_factor = float(_settings.get("ui_scale", 1.0))


func _on_node_added(node: Node) -> void:
    call_deferred("apply_accessibility_to_subtree", node)


func _apply_existing_controls() -> void:
    if get_tree() == null or get_tree().root == null:
        return
    apply_accessibility_to_subtree(get_tree().root)


func _apply_control(node: Node) -> void:
    if not node is Control:
        return
    var control := node as Control
    if not _is_interactive_control(control):
        return
    var minimum := get_minimum_target_size()
    control.custom_minimum_size.y = max(control.custom_minimum_size.y, minimum)
    if control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
        control.focus_mode = Control.FOCUS_ALL


func _is_interactive_control(control: Control) -> bool:
    return control is BaseButton or control is LineEdit or control is TextEdit or control is Range or control is ItemList or control is Tree


func _refresh_layout_mode() -> void:
    if get_tree() == null or get_tree().root == null:
        return
    var viewport_size := get_tree().root.size
    var compact := viewport_size.x < 1120 or viewport_size.y < 700
    if compact == _compact_layout:
        return
    _compact_layout = compact
    layout_mode_changed.emit(_compact_layout)

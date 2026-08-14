class_name PlayWorldSettingsScreen
extends Control

signal back_requested

const Profiles = preload("res://src/scale/performance_profiles.gd")
const UI_SCALE_VALUES := [0.90, 1.0, 1.10, 1.25, 1.50]
const DENSITY_VALUES := ["comfortable", "compact"]

@onready var back_button: Button = %BackButton
@onready var preset_option: OptionButton = %PresetOption
@onready var ui_scale_option: OptionButton = %UiScaleOption
@onready var reduced_motion_check: CheckButton = %ReducedMotionCheck
@onready var density_option: OptionButton = %DensityOption
@onready var effective_label: Label = %EffectiveLabel
@onready var status_label: Label = %StatusLabel
@onready var settings_grid: GridContainer = %SettingsGrid
@onready var update_center: Control = %UpdateCenter

var _refreshing := false
var _scale_service: Node

func _ready() -> void:
    back_button.pressed.connect(_request_back)
    preset_option.item_selected.connect(_on_preset_selected)
    ui_scale_option.item_selected.connect(_on_ui_scale_selected)
    reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)
    density_option.item_selected.connect(_on_density_selected)
    _scale_service = get_node_or_null("/root/ScalePolish")
    if _scale_service != null:
        var prefs_callback := Callable(self, "_on_preferences_changed")
        var layout_callback := Callable(self, "_apply_layout")
        if _scale_service.has_signal("preferences_changed"): _scale_service.connect("preferences_changed", prefs_callback)
        if _scale_service.has_signal("layout_mode_changed"): _scale_service.connect("layout_mode_changed", layout_callback)
    _populate_options()
    _refresh_from_preferences(_current_preferences())
    _apply_layout(_current_compact_layout())
    _configure_focus_navigation()

func focus_primary() -> void: preset_option.grab_focus()

func focus_updates() -> void:
    if update_center != null and update_center.has_method("focus_primary"): update_center.call("focus_primary")

func _populate_options() -> void:
    preset_option.clear()
    for profile in Profiles.all_profiles(): preset_option.add_item(str(profile.get("display_name", "Balanced")))
    ui_scale_option.clear()
    for scale in UI_SCALE_VALUES: ui_scale_option.add_item("%d%%" % int(roundf(float(scale) * 100.0)))
    density_option.clear(); density_option.add_item("Comfortable"); density_option.add_item("Compact")

func _current_preferences() -> Dictionary:
    if _scale_service != null and _scale_service.has_method("get_preferences"):
        var value: Variant = _scale_service.call("get_preferences")
        if value is Dictionary: return value
    return {"performance_preset": "balanced", "ui_scale": 1.0, "reduced_motion": false, "density": "comfortable"}

func _current_profile() -> Dictionary:
    if _scale_service != null and _scale_service.has_method("get_effective_profile"):
        var value: Variant = _scale_service.call("get_effective_profile")
        if value is Dictionary: return value
    return Profiles.get_profile(Profiles.DEFAULT)

func _current_compact_layout() -> bool:
    if _scale_service != null and _scale_service.has_method("is_compact_layout"):
        return bool(_scale_service.call("is_compact_layout"))
    return size.x < 1120.0 or size.y < 700.0

func _refresh_from_preferences(settings: Dictionary) -> void:
    _refreshing = true
    var preset_id := str(settings.get("performance_preset", "balanced"))
    preset_option.select(maxi(0, ["low", "balanced", "high"].find(preset_id)))
    var scale_value := float(settings.get("ui_scale", 1.0))
    var scale_index := 0
    for index in range(UI_SCALE_VALUES.size()):
        if is_equal_approx(float(UI_SCALE_VALUES[index]), scale_value): scale_index = index; break
    ui_scale_option.select(scale_index)
    reduced_motion_check.button_pressed = bool(settings.get("reduced_motion", false))
    density_option.select(maxi(0, DENSITY_VALUES.find(str(settings.get("density", "comfortable")))))
    _refreshing = false
    _update_effective_summary()

func _update_effective_summary() -> void:
    var profile := _current_profile()
    effective_label.text = ("%s preset  •  %d FPS target  •  %.2f ms frame budget  •  %d MB memory budget\n" + "Render scale %.0f%%  •  Streaming cadence %d ms  •  Foliage range %.0f m") % [
        str(profile.get("display_name", "Balanced")), int(profile.get("target_fps", 60)), float(profile.get("frame_time_budget_ms", 16.67)),
        int(profile.get("memory_budget_mb", 2560)), float(profile.get("render_scale", 0.9)) * 100.0,
        int(profile.get("streaming_focus_interval_ms", 50)), float(profile.get("foliage_visibility_range_m", 1200.0)),
    ]

func _call_scale(method: StringName, args: Array = []) -> Dictionary:
    if _scale_service == null or not _scale_service.has_method(method): return {"ok": false, "errors": ["Scale preferences service is unavailable."]}
    var value: Variant = _scale_service.callv(method, args)
    return value if value is Dictionary else {"ok": false, "errors": ["Scale preferences service returned an invalid result."]}

func _on_preset_selected(index: int) -> void:
    if _refreshing: return
    var preset_ids: Array[String] = ["low", "balanced", "high"]
    _report_result(_call_scale(&"set_performance_preset", [preset_ids[clampi(index, 0, preset_ids.size() - 1)]]), "Performance preset updated")

func _on_ui_scale_selected(index: int) -> void:
    if _refreshing: return
    _report_result(_call_scale(&"set_ui_scale", [float(UI_SCALE_VALUES[clampi(index, 0, UI_SCALE_VALUES.size() - 1)])]), "Interface scale updated")

func _on_reduced_motion_toggled(enabled: bool) -> void:
    if not _refreshing: _report_result(_call_scale(&"set_reduced_motion", [enabled]), "Reduced motion preference updated")

func _on_density_selected(index: int) -> void:
    if _refreshing: return
    _report_result(_call_scale(&"set_density", [DENSITY_VALUES[clampi(index, 0, DENSITY_VALUES.size() - 1)]]), "Interface density updated")

func _report_result(result: Dictionary, success_message: String) -> void:
    if result.get("ok", false):
        status_label.text = success_message
        var settings_value: Variant = result.get("settings", _current_preferences())
        if settings_value is Dictionary: _refresh_from_preferences(settings_value)
    else: status_label.text = "Could not save setting: %s" % str(result.get("errors", []))

func _on_preferences_changed(settings: Dictionary) -> void: _refresh_from_preferences(settings)

func _apply_layout(compact: bool) -> void:
    settings_grid.columns = 1 if compact else 2
    if update_center != null and update_center.has_method("apply_compact_layout"): update_center.call("apply_compact_layout", compact)

func _configure_focus_navigation() -> void:
    var controls: Array[Control] = [preset_option, ui_scale_option, reduced_motion_check, density_option]
    if update_center != null and update_center.has_method("focus_controls"):
        var update_controls: Variant = update_center.call("focus_controls")
        if update_controls is Array:
            for control in update_controls:
                if control is Control: controls.append(control)
    controls.append(back_button)
    for index in range(controls.size() - 1):
        controls[index].focus_next = controls[index].get_path_to(controls[index + 1])
        controls[index + 1].focus_previous = controls[index + 1].get_path_to(controls[index])

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        _request_back(); get_viewport().set_input_as_handled()

func _request_back() -> void: back_requested.emit()

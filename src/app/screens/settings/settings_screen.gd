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

var _refreshing := false


func _ready() -> void:
    back_button.pressed.connect(_request_back)
    preset_option.item_selected.connect(_on_preset_selected)
    ui_scale_option.item_selected.connect(_on_ui_scale_selected)
    reduced_motion_check.toggled.connect(_on_reduced_motion_toggled)
    density_option.item_selected.connect(_on_density_selected)
    ScalePolish.preferences_changed.connect(_on_preferences_changed)
    ScalePolish.layout_mode_changed.connect(_apply_layout)
    _populate_options()
    _refresh_from_preferences(ScalePolish.get_preferences())
    _apply_layout(ScalePolish.is_compact_layout())
    _configure_focus_navigation()


func focus_primary() -> void:
    preset_option.grab_focus()


func _populate_options() -> void:
    preset_option.clear()
    for profile in Profiles.all_profiles():
        preset_option.add_item(str(profile.get("display_name", "Balanced")))
    ui_scale_option.clear()
    for scale in UI_SCALE_VALUES:
        ui_scale_option.add_item("%d%%" % int(round(float(scale) * 100.0)))
    density_option.clear()
    density_option.add_item("Comfortable")
    density_option.add_item("Compact")


func _refresh_from_preferences(settings: Dictionary) -> void:
    _refreshing = true
    var preset_id := str(settings.get("performance_preset", "balanced"))
    preset_option.select(max(0, ["low", "balanced", "high"].find(preset_id)))
    var scale_value := float(settings.get("ui_scale", 1.0))
    var scale_index := 0
    for index in range(UI_SCALE_VALUES.size()):
        if is_equal_approx(float(UI_SCALE_VALUES[index]), scale_value):
            scale_index = index
            break
    ui_scale_option.select(scale_index)
    reduced_motion_check.button_pressed = bool(settings.get("reduced_motion", false))
    density_option.select(max(0, DENSITY_VALUES.find(str(settings.get("density", "comfortable")))))
    _refreshing = false
    _update_effective_summary()


func _update_effective_summary() -> void:
    var profile: Dictionary = ScalePolish.get_effective_profile()
    effective_label.text = (
        "%s preset  •  %d FPS target  •  %.2f ms frame budget  •  %d MB memory budget\n"
        + "Render scale %.0f%%  •  Streaming cadence %d ms  •  Foliage range %.0f m"
    ) % [
        str(profile.get("display_name", "Balanced")),
        int(profile.get("target_fps", 60)),
        float(profile.get("frame_time_budget_ms", 16.67)),
        int(profile.get("memory_budget_mb", 2560)),
        float(profile.get("render_scale", 0.9)) * 100.0,
        int(profile.get("streaming_focus_interval_ms", 50)),
        float(profile.get("foliage_visibility_range_m", 1200.0)),
    ]


func _on_preset_selected(index: int) -> void:
    if _refreshing:
        return
    var preset_ids := ["low", "balanced", "high"]
    _report_result(ScalePolish.set_performance_preset(preset_ids[clamp(index, 0, preset_ids.size() - 1)]), "Performance preset updated")


func _on_ui_scale_selected(index: int) -> void:
    if _refreshing:
        return
    _report_result(ScalePolish.set_ui_scale(float(UI_SCALE_VALUES[clamp(index, 0, UI_SCALE_VALUES.size() - 1)])), "Interface scale updated")


func _on_reduced_motion_toggled(enabled: bool) -> void:
    if _refreshing:
        return
    _report_result(ScalePolish.set_reduced_motion(enabled), "Reduced motion preference updated")


func _on_density_selected(index: int) -> void:
    if _refreshing:
        return
    _report_result(ScalePolish.set_density(DENSITY_VALUES[clamp(index, 0, DENSITY_VALUES.size() - 1)]), "Interface density updated")


func _report_result(result: Dictionary, success_message: String) -> void:
    if result.get("ok", false):
        status_label.text = success_message
        _refresh_from_preferences(result.get("settings", ScalePolish.get_preferences()))
    else:
        status_label.text = "Could not save setting: %s" % str(result.get("errors", []))


func _on_preferences_changed(settings: Dictionary) -> void:
    _refresh_from_preferences(settings)


func _apply_layout(compact: bool) -> void:
    settings_grid.columns = 1 if compact else 2


func _configure_focus_navigation() -> void:
    var controls: Array[Control] = [preset_option, ui_scale_option, reduced_motion_check, density_option, back_button]
    for index in range(controls.size() - 1):
        controls[index].focus_next = controls[index].get_path_to(controls[index + 1])
        controls[index + 1].focus_previous = controls[index + 1].get_path_to(controls[index])


func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        _request_back()
        get_viewport().set_input_as_handled()


func _request_back() -> void:
    back_requested.emit()

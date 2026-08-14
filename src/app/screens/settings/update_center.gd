class_name PlayWorldUpdateCenter
extends VBoxContainer

const ProductIdentity = preload("res://src/release/product_identity.gd")
const UpdatePreferences = preload("res://src/release/update_preferences.gd")

@onready var version_label: Label = %VersionLabel
@onready var status_label: Label = %UpdateStatusLabel
@onready var channel_option: OptionButton = %ChannelOption
@onready var auto_check: CheckButton = %AutoCheck
@onready var available_label: Label = %AvailableLabel
@onready var notes_label: RichTextLabel = %ReleaseNotes
@onready var progress_bar: ProgressBar = %DownloadProgress
@onready var progress_label: Label = %ProgressLabel
@onready var check_button: Button = %CheckButton
@onready var download_button: Button = %DownloadButton
@onready var cancel_button: Button = %CancelButton
@onready var install_button: Button = %InstallButton
@onready var repair_button: Button = %RepairButton
@onready var rollback_button: Button = %RollbackButton
@onready var safe_mode_button: Button = %SafeModeButton
@onready var continue_button: Button = %ContinueButton
@onready var reset_preferences_button: Button = %ResetPreferencesButton
@onready var diagnostics_button: Button = %DiagnosticsButton
@onready var support_button: Button = %SupportButton
@onready var recovery_label: Label = %RecoveryLabel
@onready var diagnostic_label: RichTextLabel = %DiagnosticLabel
@onready var update_actions: HFlowContainer = %UpdateActions

var _service: Node
var _session: Node
var _maintenance: Node
var _channel_ids: Array[String] = []
var _refreshing := false

func _ready() -> void:
    _service = get_node_or_null("/root/UpdateService")
    _session = get_node_or_null("/root/SessionRecovery")
    _maintenance = get_node_or_null("/root/ReleaseMaintenance")
    check_button.pressed.connect(_check)
    download_button.pressed.connect(_download)
    cancel_button.pressed.connect(_cancel)
    install_button.pressed.connect(_install)
    repair_button.pressed.connect(_repair)
    rollback_button.pressed.connect(_rollback)
    safe_mode_button.pressed.connect(_safe_mode)
    continue_button.pressed.connect(_continue_normal)
    reset_preferences_button.pressed.connect(_reset_preferences)
    diagnostics_button.pressed.connect(_show_diagnostics)
    support_button.pressed.connect(_create_support_bundle)
    channel_option.item_selected.connect(_channel_selected)
    auto_check.toggled.connect(_auto_check_toggled)
    if _service != null:
        if _service.has_signal("state_changed"): _service.connect("state_changed", Callable(self, "_on_state_changed"))
        if _service.has_signal("progress_changed"): _service.connect("progress_changed", Callable(self, "_on_progress"))
        if _service.has_signal("channel_changed"): _service.connect("channel_changed", Callable(self, "_on_channel_changed"))
    if _session != null and _session.has_signal("safe_mode_changed"):
        _session.connect("safe_mode_changed", Callable(self, "_on_safe_mode_changed"))
    _populate_channels()
    _refresh()

func focus_primary() -> void: check_button.grab_focus()

func focus_controls() -> Array[Control]:
    return [channel_option, auto_check, check_button, download_button, cancel_button, install_button, repair_button, rollback_button, safe_mode_button, continue_button, reset_preferences_button, diagnostics_button, support_button]

func apply_compact_layout(compact: bool) -> void:
    update_actions.alignment = FlowContainer.ALIGNMENT_BEGIN
    notes_label.custom_minimum_size.y = 132.0 if compact else 178.0

func present_evidence_state(state_name: String, details: Dictionary = {}) -> void:
    var snapshot := _snapshot()
    snapshot["state"] = state_name
    for key in details.keys(): snapshot[key] = details[key]
    _render(snapshot)

func _populate_channels() -> void:
    _refreshing = true
    channel_option.clear()
    _channel_ids.clear()
    var preferences := UpdatePreferences.new()
    var records := preferences.channel_records()
    for id in ["stable", "beta", "development"]:
        if not records.has(id) or not preferences.is_channel_allowed(id): continue
        _channel_ids.append(id)
        channel_option.add_item(id.capitalize())
    var selected := preferences.selected_channel()
    channel_option.select(maxi(0, _channel_ids.find(selected)))
    _refreshing = false

func _refresh() -> void: _render(_snapshot())

func _snapshot() -> Dictionary:
    if _service != null and _service.has_method("snapshot"):
        var value: Variant = _service.call("snapshot")
        if value is Dictionary: return value
    return {
        "state": "idle", "message": "Update service is unavailable.", "current_version": ProductIdentity.version(),
        "available_version": "", "channel": ProductIdentity.channel(), "auto_check": false,
        "downloaded": 0, "download_total": 0, "release_notes": "", "journal": {}, "install_mode": "development",
    }

func _render(snapshot: Dictionary) -> void:
    var state := str(snapshot.get("state", "idle"))
    version_label.text = "PlayWorld Studio %s  •  %s  •  %s" % [str(snapshot.get("current_version", ProductIdentity.version())), str(snapshot.get("channel", "stable")).capitalize(), str(snapshot.get("install_mode", "development")).capitalize()]
    status_label.text = str(snapshot.get("message", "Updates are optional and never block creator use."))
    available_label.text = "Available: %s" % str(snapshot.get("available_version", "None")) if not str(snapshot.get("available_version", "")).is_empty() else "No newer verified version selected"
    notes_label.text = str(snapshot.get("release_notes", "Release notes appear here after signed metadata is accepted."))
    _refreshing = true
    var channel := str(snapshot.get("channel", "stable"))
    if _channel_ids.has(channel): channel_option.select(_channel_ids.find(channel))
    auto_check.button_pressed = bool(snapshot.get("auto_check", true))
    _refreshing = false
    var downloaded := int(snapshot.get("downloaded", 0))
    var total := int(snapshot.get("download_total", 0))
    progress_bar.value = 0.0 if total <= 0 else clampf(float(downloaded) * 100.0 / float(total), 0.0, 100.0)
    progress_label.text = _byte_progress(downloaded, total)
    check_button.disabled = state in ["checking", "downloading", "verifying", "handoff"]
    download_button.disabled = state != "available"
    cancel_button.disabled = state not in ["checking", "downloading", "verifying"]
    install_button.disabled = state != "ready"
    repair_button.disabled = state in ["checking", "downloading", "verifying", "handoff"]
    var journal: Dictionary = snapshot.get("journal", {})
    rollback_button.disabled = not bool(journal.get("backup_available", false)) or state == "handoff"
    install_button.text = "Restart & Install" if state == "ready" else "Install"
    var recovery := _session_snapshot()
    recovery_label.text = _recovery_summary(recovery, journal)
    safe_mode_button.disabled = bool(recovery.get("safe_mode", false))
    continue_button.disabled = not bool(recovery.get("safe_mode", false)) and not bool(recovery.get("abnormal_shutdown", false))

func _session_snapshot() -> Dictionary:
    if _session != null and _session.has_method("recovery_snapshot"):
        var value: Variant = _session.call("recovery_snapshot")
        if value is Dictionary: return value
    return {"abnormal_shutdown": false, "safe_mode": false}

func _recovery_summary(recovery: Dictionary, journal: Dictionary) -> String:
    var lines: Array[String] = []
    lines.append("Safe mode: %s" % ("On" if bool(recovery.get("safe_mode", false)) else "Off"))
    lines.append("Previous shutdown: %s" % ("Recovery available" if bool(recovery.get("abnormal_shutdown", false)) else "Clean"))
    lines.append("Update recovery: %s" % (str(journal.get("stage", "none")).replace("_", " ").capitalize()))
    lines.append("Projects are outside the application replacement boundary.")
    return "  •  ".join(lines)

func _byte_progress(downloaded: int, total: int) -> String:
    if total <= 0: return "No active download"
    return "%.1f MB of %.1f MB" % [float(downloaded) / 1048576.0, float(total) / 1048576.0]

func _check() -> void:
    if _service != null: _service.call("check_for_updates", true)

func _download() -> void:
    if _service != null: _service.call("start_download")

func _cancel() -> void:
    if _service != null: _service.call("cancel_current")

func _install() -> void:
    if _service != null: _service.call("install_ready_update", true)

func _repair() -> void:
    if _service != null:
        var result: Dictionary = _service.call("repair_application")
        if not result.get("ok", false): status_label.text = str(result.get("errors", []))

func _rollback() -> void:
    if _service != null:
        var result: Dictionary = _service.call("rollback_application")
        if not result.get("ok", false): status_label.text = str(result.get("errors", []))

func _channel_selected(index: int) -> void:
    if _refreshing or index < 0 or index >= _channel_ids.size() or _service == null: return
    var result: Dictionary = _service.call("set_channel", _channel_ids[index])
    if not result.get("ok", false): status_label.text = str(result.get("errors", []))

func _auto_check_toggled(enabled: bool) -> void:
    if _refreshing or _service == null: return
    var result: Dictionary = _service.call("set_auto_check", enabled)
    if not result.get("ok", false): status_label.text = str(result.get("errors", []))

func _safe_mode() -> void:
    if _session != null: _session.call("set_safe_mode", true)

func _continue_normal() -> void:
    if _session == null: return
    _session.call("acknowledge_recovery")
    _session.call("set_safe_mode", false)
    _refresh()

func _reset_preferences() -> void:
    if _session == null: return
    var result: Dictionary = _session.call("reset_preferences_non_destructive")
    status_label.text = "Preferences reset after backup. Projects were not changed." if result.get("ok", false) else "Preference reset failed safely: %s" % str(result.get("errors", []))

func _show_diagnostics() -> void:
    if _maintenance == null or not _maintenance.has_method("diagnostic_report"):
        diagnostic_label.text = "Diagnostics are unavailable."
        return
    var report: Dictionary = _maintenance.call("diagnostic_report")
    diagnostic_label.text = JSON.stringify(report, "  ", true)

func _create_support_bundle() -> void:
    if _maintenance == null or not _maintenance.has_method("create_support_bundle"):
        status_label.text = "Support bundle service is unavailable."
        return
    var result: Dictionary = _maintenance.call("create_support_bundle")
    status_label.text = "Support bundle created locally: %s" % str(result.get("redacted_path", "user://support/PlayWorld-Support.json")) if result.get("ok", false) else "Support bundle failed: %s" % str(result.get("errors", []))

func _on_state_changed(_state: StringName, snapshot: Dictionary) -> void: _render(snapshot)
func _on_progress(downloaded: int, total: int, ratio: float) -> void:
    progress_bar.value = ratio * 100.0
    progress_label.text = _byte_progress(downloaded, total)
func _on_channel_changed(_channel: String) -> void: _populate_channels(); _refresh()
func _on_safe_mode_changed(_enabled: bool) -> void: _refresh()

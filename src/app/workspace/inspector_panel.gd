class_name PlayWorldInspectorPanel
extends PanelContainer

signal closed

@onready var close_button: Button = %CloseButton
@onready var title_label: Label = %InspectorTitle
@onready var type_label: Label = %TypeValue
@onready var summary_label: Label = %SummaryValue
@onready var advanced_button: Button = %AdvancedButton
@onready var advanced_panel: Control = %AdvancedPanel
@onready var advanced_summary: Label = %AdvancedSummary

var _context: Dictionary = {}


func _ready() -> void:
    close_button.pressed.connect(_close)
    advanced_button.toggled.connect(_on_advanced_toggled)
    advanced_panel.hide()
    hide()


func show_context(context: Dictionary) -> void:
    _context = context.duplicate(true)
    title_label.text = str(_context.get("title", "Selection"))
    type_label.text = str(_context.get("type", "Generic object"))
    summary_label.text = str(_context.get("summary", "No basic properties available yet."))
    advanced_summary.text = str(
        _context.get("advanced_summary", "Advanced properties are not available for this context yet.")
    )
    advanced_button.button_pressed = false
    advanced_panel.hide()
    show()


func clear_context() -> void:
    _context.clear()
    hide()


func get_context() -> Dictionary:
    return _context.duplicate(true)


func is_open() -> bool:
    return visible


func focus_primary() -> void:
    close_button.grab_focus()


func _on_advanced_toggled(enabled: bool) -> void:
    advanced_panel.visible = enabled
    advanced_button.text = "Advanced  ▴" if enabled else "Advanced  ▾"


func _close() -> void:
    clear_context()
    closed.emit()

class_name PlayWorldGameplayWorkspaceLayer
extends Control

signal status_changed(message: String, is_error: bool)
signal open_changed(open: bool)

const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const PrefabAuthoring = preload("res://src/gameplay/prefab_authoring_service.gd")
const SocketAttachmentService = preload("res://src/gameplay/socket_attachment_service.gd")
const RuntimeAttachmentResolver = preload("res://src/gameplay/runtime_attachment_resolver.gd")
const GameplayPanel = preload("res://src/app/workspace/gameplay_tool_panel.gd")

var _workspace: Control
var _session
var _bottom_dock: Control
var _panel
var _gameplay
var _prefabs
var _sockets
var _cell_resolver := Callable()
var _bound := false


func _ready() -> void:
    name = "GameplayWorkspaceLayer"
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _panel = GameplayPanel.new(); add_child(_panel); _wire_panel(); set_process_unhandled_input(true)


func bind_workspace(workspace: Control) -> Dictionary:
    _workspace = workspace
    _bottom_dock = workspace.get_node_or_null("BottomDockLayer/BottomToolDock")
    if _bottom_dock == null: return _failure("Gameplay workspace could not resolve the bottom tool dock.")
    if not _bottom_dock.tool_selected.is_connected(_on_tool_selected): _bottom_dock.tool_selected.connect(_on_tool_selected)
    return {"ok": true, "errors": []}


func bind_project(project, project_directory: String, editor_session, dirty_callback: Callable, cell_resolver: Callable = Callable()) -> Dictionary:
    if _workspace == null: return _failure("Gameplay workspace must bind its workspace before a project.")
    _session = editor_session; _cell_resolver = cell_resolver
    _gameplay = GameplayService.new()
    var gameplay_result: Dictionary = _gameplay.bind_project(project, project_directory, editor_session, dirty_callback)
    if not gameplay_result.get("ok", false): return gameplay_result
    _prefabs = PrefabAuthoring.new(); var prefab_result: Dictionary = _prefabs.bind(project, _gameplay.get_state(), _gameplay.get_repository(), editor_session, dirty_callback, cell_resolver)
    if not prefab_result.get("ok", false): return prefab_result
    _sockets = SocketAttachmentService.new(); var socket_result: Dictionary = _sockets.bind(project, _gameplay.get_state(), _gameplay.get_repository(), editor_session, dirty_callback)
    if not socket_result.get("ok", false): return socket_result
    if not _session.selection_changed.is_connected(_on_selection_changed): _session.selection_changed.connect(_on_selection_changed)
    _gameplay.gameplay_changed.connect(_on_gameplay_changed)
    _panel.set_definitions(_gameplay.get_definitions()); _panel.set_archetypes(_gameplay.get_archetypes()); _panel.set_prefabs(_gameplay.get_prefabs())
    _bound = true; close_tool(); _refresh_selection(); _apply_runtime_attachments()
    return {"ok": true, "errors": [], "definitions": _gameplay.get_definitions().size(), "archetypes": _gameplay.get_archetypes().size()}


func toggle_tool() -> void:
    if not _bound: return
    if is_open(): close_tool()
    else: open_tool()


func open_tool() -> void:
    if not _bound: return
    if _workspace.has_method("close_asset_drawer"): _workspace.close_asset_drawer()
    _panel.open_panel(); _refresh_selection(); open_changed.emit(true)


func close_tool() -> void:
    if _panel != null: _panel.close_panel()
    open_changed.emit(false)


func is_open() -> bool: return _panel != null and _panel.is_open()
func get_service(): return _gameplay
func get_prefab_service(): return _prefabs
func get_socket_service(): return _sockets
func get_panel(): return _panel


func handle_cancel() -> bool:
    if not is_open(): return false
    close_tool(); return true


func _unhandled_input(event: InputEvent) -> void:
    if not is_open(): return
    if _panel.handle_shortcut(event): get_viewport().set_input_as_handled()


func _on_tool_selected(tool: StringName) -> void:
    if tool == &"gameplay": toggle_tool()
    elif is_open(): close_tool()


func _on_selection_changed(_entity_ids: Array, _primary_entity_id: String, _runtime_node: Node3D) -> void: _refresh_selection()


func _on_gameplay_changed() -> void:
    _panel.set_prefabs(_gameplay.get_prefabs()); _apply_runtime_attachments(); _refresh_selection()


func _refresh_selection() -> void:
    if not _bound or _session == null: return
    var ids: Array[String] = _session.get_selected_ids(); var primary := _session.get_primary_entity_id(); var primary_name := ""
    var component_views: Array[Dictionary] = []; var socket_views: Array[Dictionary] = []; var prefab_name := ""
    if not primary.is_empty():
        var record: Dictionary = _session.get_bridge().get_entity_record(primary); primary_name = str(record.get("display_name", "Entity"))
        for instance in _gameplay.components_for_entity(primary):
            var definition: Dictionary = _gameplay.get_state().get_definition(str(instance.get("definition_id", "")))
            component_views.append({"instance_id": instance.get("instance_id"), "definition_id": instance.get("definition_id"), "display_name": definition.get("display_name", "Component"), "values": instance.get("values", {}).duplicate(true)})
        socket_views = _gameplay.sockets_for_entity(primary)
        var prefab_id = record.get("prefab_id")
        if prefab_id != null and not str(prefab_id).is_empty(): prefab_name = str(_gameplay.get_state().get_prefab(str(prefab_id)).get("display_name", "Prefab"))
    _panel.set_selection(ids, primary_name, component_views, socket_views, prefab_name)


func _on_archetype_requested(archetype_id: String) -> void:
    var entity_id := _session.get_primary_entity_id()
    if entity_id.is_empty(): _report(_failure("Select one object before applying an archetype."), ""); return
    _report(_gameplay.apply_archetype(entity_id, archetype_id), "Archetype applied")


func _on_component_requested(definition_id: String) -> void:
    var entity_id := _session.get_primary_entity_id()
    if entity_id.is_empty(): _report(_failure("Select one object before adding a component."), ""); return
    _report(_gameplay.add_component(entity_id, definition_id), "Component added")


func _on_save_prefab_requested(display_name: String) -> void:
    var entity_id := _session.get_primary_entity_id()
    if entity_id.is_empty(): _report(_failure("Select a prefab root object first."), ""); return
    var result: Dictionary = _prefabs.save_prefab(entity_id, display_name)
    if result.get("ok", false): _panel.set_prefabs(_gameplay.get_prefabs())
    _report(result, "Prefab saved")


func _on_instantiate_prefab_requested(prefab_id: String) -> void:
    var position := Vector3.ZERO
    var runtime_node = _session.get_primary_node()
    if runtime_node != null: position = runtime_node.global_position + Vector3(2.0, 0.0, 2.0)
    var result: Dictionary = _prefabs.instantiate_prefab(prefab_id, position)
    _report(result, "Prefab placed")


func _on_socket_requested(socket_name: String, category: String) -> void:
    var entity_id := _session.get_primary_entity_id()
    if entity_id.is_empty(): _report(_failure("Select one object before adding a socket."), ""); return
    var resolved_name := socket_name.strip_edges()
    if resolved_name.is_empty(): resolved_name = category
    _report(_sockets.add_socket(entity_id, resolved_name, category, _identity_transform()), "Socket added")


func _on_attach_requested() -> void:
    var ids: Array[String] = _session.get_selected_ids()
    if ids.size() != 2: _report(_failure("Select exactly two objects to attach."), ""); return
    var parent_sockets: Array[Dictionary] = _gameplay.sockets_for_entity(ids[0]); var child_sockets: Array[Dictionary] = _gameplay.sockets_for_entity(ids[1])
    if parent_sockets.is_empty(): _report(_failure("The primary object needs a socket before attachment."), ""); return
    var child_socket: Variant = null
    if not child_sockets.is_empty(): child_socket = str(child_sockets[0].get("socket_id", ""))
    var result: Dictionary = _sockets.attach(ids[0], str(parent_sockets[0].get("socket_id", "")), ids[1], child_socket)
    _report(result, "Objects attached")


func _report(result: Dictionary, success: String) -> void:
    if result.get("ok", false):
        _apply_runtime_attachments(); _refresh_selection(); status_changed.emit(success if not success.is_empty() else "Gameplay ready", false)
    else: status_changed.emit(str(result.get("errors", ["Gameplay action failed."])[0]), true)


func _apply_runtime_attachments() -> void:
    if not _bound or _session == null: return
    var result: Dictionary = RuntimeAttachmentResolver.new().apply(_session.get_bridge(), _gameplay.get_state())
    if not result.get("ok", false): status_changed.emit(str(result.get("errors", ["Attachment presentation failed."])[0]), true)


func _wire_panel() -> void:
    _panel.archetype_requested.connect(_on_archetype_requested)
    _panel.component_requested.connect(_on_component_requested)
    _panel.save_prefab_requested.connect(_on_save_prefab_requested)
    _panel.instantiate_prefab_requested.connect(_on_instantiate_prefab_requested)
    _panel.socket_requested.connect(_on_socket_requested)
    _panel.attach_requested.connect(_on_attach_requested)
    _panel.close_requested.connect(close_tool)


static func _identity_transform() -> Dictionary: return {"position": [0.0, 0.0, 0.0], "rotation_degrees": [0.0, 0.0, 0.0], "scale": [1.0, 1.0, 1.0]}
static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}

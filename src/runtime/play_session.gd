class_name PlayWorldPlaySession
extends Node3D

signal exit_requested
signal state_changed(active: bool)

const GameplayInput = preload("res://src/input/gameplay_input_map.gd")
const RuntimeState = preload("res://src/runtime/play_runtime_state.gd")
const RuntimeModules = preload("res://src/templates/runtime_module_registry.gd")
const ThirdPersonController = preload("res://src/runtime/third_person_controller.gd")
const FirstPersonController = preload("res://src/runtime/first_person_controller.gd")
const VisualGraphRuntime = preload("res://src/visual_scripting/visual_graph_runtime_session.gd")
const RuntimeGameplayState = preload("res://src/gameplay/runtime_gameplay_state.gd")
const RuntimeInventoryService = preload("res://src/gameplay/runtime_inventory_service.gd")
const RuntimeInteractionService = preload("res://src/gameplay/runtime_interaction_service.gd")
const RuntimeHealthService = preload("res://src/gameplay/runtime_health_service.gd")
const RuntimeNpcAiService = preload("res://src/gameplay/runtime_npc_ai_service.gd")
const RuntimeDialogueService = preload("res://src/gameplay/runtime_dialogue_service.gd")
const RuntimeQuestService = preload("res://src/gameplay/runtime_quest_service.gd")
const RuntimeVehicleService = preload("res://src/gameplay/runtime_vehicle_service.gd")
const RuntimeSaveStateService = preload("res://src/gameplay/runtime_save_state_service.gd")

var _runtime_state = RuntimeState.new()
var _gameplay_runtime = RuntimeGameplayState.new()
var _inventory_runtime = RuntimeInventoryService.new()
var _interaction_runtime = RuntimeInteractionService.new()
var _health_runtime = RuntimeHealthService.new()
var _npc_runtime = RuntimeNpcAiService.new()
var _dialogue_runtime = RuntimeDialogueService.new()
var _quest_runtime = RuntimeQuestService.new()
var _vehicle_runtime = RuntimeVehicleService.new()
var _save_state_runtime = RuntimeSaveStateService.new()
var _visual_runtime = VisualGraphRuntime.new()
var _visual_graph_provider := Callable()
var _gameplay_state_provider := Callable()
var _last_visual_result: Dictionary = {}
var _project_directory := ""
var _editor_session
var _player: CharacterBody3D
var _active := false
var _selected_ids: Array[String] = []
var _primary_id := ""
var _streaming_callback := Callable()
var _previous_camera: Camera3D
var _spawn_entity_id := ""


func _init() -> void:
    name = "PlaySession"


func configure_streaming(callback: Callable) -> void:
    _streaming_callback = callback


func configure_visual_graph_provider(provider: Callable) -> void:
    _visual_graph_provider = provider


func configure_gameplay_state_provider(provider: Callable) -> void:
    _gameplay_state_provider = provider


func configure_project_directory(project_directory: String) -> void:
    _project_directory = project_directory.trim_suffix("/")


func enter_play(editor_session) -> Dictionary:
    if _active:
        return _failure("Play session is already active.")
    if editor_session == null:
        return _failure("Play session requires an editor session.")
    var project_data: Dictionary = editor_session.get_project_data()
    if project_data.is_empty():
        return _failure("Play session requires authored project data.")
    var runtime_config: Dictionary = project_data.get("runtime", {})
    var module_result: Dictionary = RuntimeModules.new().resolve(runtime_config.get("resolved_modules", []))
    if not module_result.get("ok", false):
        return module_result
    var input_result: Dictionary = GameplayInput.install_profile(runtime_config.get("input_mapping", {}))
    if not input_result.get("ok", false):
        return input_result
    var state_result: Dictionary = _runtime_state.load_authored_project(project_data)
    if not state_result.get("ok", false):
        GameplayInput.uninstall_owned()
        return state_result

    var gameplay_snapshot: Dictionary = {
        "definitions": [],
        "instances": [],
        "sockets": [],
        "attachments": [],
        "dialogues": [],
        "quests": [],
    }
    if _gameplay_state_provider.is_valid():
        var gameplay_value: Variant = _gameplay_state_provider.call()
        if not gameplay_value is Dictionary:
            _runtime_state.clear()
            GameplayInput.uninstall_owned()
            return _failure("Gameplay state provider returned an invalid value.")
        gameplay_snapshot = gameplay_value.duplicate(true)
    var gameplay_result: Dictionary = _gameplay_runtime.initialize(project_data, gameplay_snapshot)
    if not gameplay_result.get("ok", false):
        _runtime_state.clear()
        GameplayInput.uninstall_owned()
        return gameplay_result
    var services_result: Dictionary = _bind_gameplay_services(project_data)
    if not services_result.get("ok", false):
        _clear_runtime_services()
        _gameplay_runtime.clear()
        _runtime_state.clear()
        GameplayInput.uninstall_owned()
        return services_result

    _editor_session = editor_session
    _selected_ids = editor_session.get_selected_ids()
    _primary_id = editor_session.get_primary_entity_id()
    _previous_camera = get_viewport().get_camera_3d()
    editor_session.clear_selection()
    _spawn_entity_id = _optional_id(runtime_config.get("spawn_entity_id"))
    var exclusion_result: Dictionary = editor_session.get_bridge().set_excluded_entity_ids([] if _spawn_entity_id.is_empty() else [_spawn_entity_id])
    if not exclusion_result.get("ok", false):
        _rollback_startup()
        return exclusion_result
    var camera_config: Dictionary = runtime_config.get("camera_configuration", {}).duplicate(true)
    _apply_spawn_position(camera_config, runtime_config)
    var controller := str(camera_config.get("controller", "none"))
    var spawn_result: Dictionary = _spawn_player(controller, camera_config)
    if not spawn_result.get("ok", false):
        _rollback_startup()
        return spawn_result

    var graphs: Array[Dictionary] = []
    if _visual_graph_provider.is_valid():
        var graph_value: Variant = _visual_graph_provider.call()
        if not graph_value is Array:
            _rollback_startup()
            return _failure("Visual graph provider returned an invalid value.")
        for value in graph_value:
            if value is Dictionary:
                graphs.append(value.duplicate(true))
    _last_visual_result = _visual_runtime.execute_start(graphs, _runtime_state, _build_visual_gameplay_context())
    if not _last_visual_result.get("ok", false):
        var failed := _last_visual_result.duplicate(true)
        _rollback_startup()
        return failed

    _active = true
    _update_streaming_focus()
    state_changed.emit(true)
    return {
        "ok": true,
        "errors": [],
        "controller": controller,
        "entity_count": state_result.get("entity_count", 0),
        "gameplay_component_count": gameplay_result.get("component_count", 0),
        "dialogue_count": gameplay_result.get("dialogue_count", 0),
        "quest_count": gameplay_result.get("quest_count", 0),
        "spawn_entity_id": _spawn_entity_id,
        "visual_graphs": _last_visual_result.get("executed_graphs", 0),
    }


func exit_play() -> Dictionary:
    if not _active and _editor_session == null:
        _clear_runtime_services()
        _gameplay_runtime.clear()
        _runtime_state.clear()
        GameplayInput.uninstall_owned()
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        return {"ok": true, "errors": [], "changed": false}
    _free_player()
    _clear_runtime_services()
    _gameplay_runtime.clear()
    _runtime_state.clear()
    GameplayInput.uninstall_owned()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if is_instance_valid(_previous_camera):
        _previous_camera.current = true
    _previous_camera = null
    var editor_session = _editor_session
    if editor_session != null:
        editor_session.get_bridge().clear_excluded_entity_ids()
    _editor_session = null
    _active = false
    _spawn_entity_id = ""
    if editor_session != null:
        var refresh_result: Dictionary = editor_session.refresh_runtime(false)
        if not refresh_result.get("ok", false):
            state_changed.emit(false)
            return refresh_result
        if editor_session.has_method("restore_selection"):
            editor_session.restore_selection(_selected_ids, _primary_id)
    _selected_ids.clear()
    _primary_id = ""
    state_changed.emit(false)
    return {"ok": true, "errors": [], "changed": true}


func is_active() -> bool:
    return _active


func get_runtime_state():
    return _runtime_state


func get_gameplay_runtime():
    return _gameplay_runtime


func get_inventory_runtime():
    return _inventory_runtime


func get_interaction_runtime():
    return _interaction_runtime


func get_health_runtime():
    return _health_runtime


func get_npc_runtime():
    return _npc_runtime


func get_dialogue_runtime():
    return _dialogue_runtime


func get_quest_runtime():
    return _quest_runtime


func get_vehicle_runtime():
    return _vehicle_runtime


func get_save_state_runtime():
    return _save_state_runtime


func get_player():
    return _player


func get_last_visual_graph_result() -> Dictionary:
    return _last_visual_result.duplicate(true)


func _physics_process(delta: float) -> void:
    if not _active:
        return
    _update_streaming_focus()
    _update_vehicle_input()
    var npc_result: Dictionary = _npc_runtime.advance(delta)
    if not npc_result.get("ok", false):
        push_warning("NPC runtime advance failed: %s" % str(npc_result.get("errors", [])))
    var vehicle_result: Dictionary = _vehicle_runtime.advance(delta)
    if not vehicle_result.get("ok", false):
        push_warning("Vehicle runtime advance failed: %s" % str(vehicle_result.get("errors", [])))


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed(GameplayInput.EXIT):
        exit_requested.emit()
        get_viewport().set_input_as_handled()
        return
    if event.is_action_pressed(GameplayInput.INTERACT) and not _spawn_entity_id.is_empty():
        var occupied_vehicle := _vehicle_runtime.vehicle_for_actor(_spawn_entity_id)
        if not occupied_vehicle.is_empty():
            var exit_result: Dictionary = _vehicle_runtime.exit_vehicle(_spawn_entity_id)
            if not exit_result.get("ok", false):
                push_warning("Vehicle exit interaction failed: %s" % str(exit_result.get("errors", [])))
            get_viewport().set_input_as_handled()


func _spawn_player(controller: String, config: Dictionary) -> Dictionary:
    match controller:
        "none":
            return {"ok": true, "errors": [], "controller": controller}
        "third_person":
            var player = ThirdPersonController.new()
            player.configure(config)
            add_child(player)
            _player = player
        "first_person":
            var player = FirstPersonController.new()
            player.configure(config)
            add_child(player)
            _player = player
        _:
            return _failure("Unsupported Play controller: %s" % controller)
    return {"ok": true, "errors": [], "controller": controller}


func _apply_spawn_position(config: Dictionary, runtime_config: Dictionary) -> void:
    var spawn_id: String = _optional_id(runtime_config.get("spawn_entity_id"))
    if spawn_id.is_empty():
        return
    var record: Dictionary = _runtime_state.get_entity(spawn_id)
    if record.is_empty():
        return
    var position_value = record.get("transform", {}).get("position", [])
    if position_value is Array and position_value.size() == 3:
        config["spawn_position"] = position_value.duplicate()


func _update_streaming_focus() -> void:
    if not _streaming_callback.is_valid() or not is_instance_valid(_player):
        return
    var result: Variant = _streaming_callback.call(_player.global_position)
    if result is Dictionary and not result.get("ok", false):
        push_warning("Play streaming focus update failed: %s" % str(result.get("errors", [])))


func _update_vehicle_input() -> void:
    if _spawn_entity_id.is_empty():
        return
    var vehicle_id := _vehicle_runtime.vehicle_for_actor(_spawn_entity_id)
    if vehicle_id.is_empty():
        return
    var state_result: Dictionary = _vehicle_runtime.get_vehicle_state(vehicle_id)
    if not state_result.get("ok", false):
        return
    var state: Dictionary = state_result.get("state", {})
    if str(state.get("driver_entity_id", "")) != _spawn_entity_id:
        return
    var throttle := Input.get_action_strength(GameplayInput.MOVE_FORWARD) - Input.get_action_strength(GameplayInput.MOVE_BACK)
    var steer := Input.get_action_strength(GameplayInput.MOVE_RIGHT) - Input.get_action_strength(GameplayInput.MOVE_LEFT)
    var brake := Input.get_action_strength(GameplayInput.JUMP)
    var control_result: Dictionary = _vehicle_runtime.set_controls(vehicle_id, _spawn_entity_id, throttle, steer, brake)
    if not control_result.get("ok", false):
        push_warning("Vehicle semantic input update failed: %s" % str(control_result.get("errors", [])))


func _bind_gameplay_services(project_data: Dictionary) -> Dictionary:
    var inventory_result: Dictionary = _inventory_runtime.bind_runtime(_gameplay_runtime)
    if not inventory_result.get("ok", false):
        return inventory_result
    var interaction_result: Dictionary = _interaction_runtime.bind_runtime(_gameplay_runtime, _inventory_runtime)
    if not interaction_result.get("ok", false):
        return interaction_result
    var health_result: Dictionary = _health_runtime.bind_runtime(_gameplay_runtime)
    if not health_result.get("ok", false):
        return health_result
    var npc_result: Dictionary = _npc_runtime.bind_runtime(_gameplay_runtime, _runtime_state, _interaction_runtime)
    if not npc_result.get("ok", false):
        return npc_result
    var quest_result: Dictionary = _quest_runtime.bind_runtime(_gameplay_runtime)
    if not quest_result.get("ok", false):
        return quest_result
    var dialogue_result: Dictionary = _dialogue_runtime.bind_runtime(_gameplay_runtime)
    if not dialogue_result.get("ok", false):
        return dialogue_result
    var vehicle_result: Dictionary = _vehicle_runtime.bind_runtime(_gameplay_runtime, _runtime_state)
    if not vehicle_result.get("ok", false):
        return vehicle_result
    var save_result: Dictionary = _save_state_runtime.bind_runtime(
        _project_directory,
        str(project_data.get("project_id", "")),
        _gameplay_runtime,
        _runtime_state
    )
    if not save_result.get("ok", false):
        return save_result
    return {"ok": true, "errors": []}


func _build_visual_gameplay_context() -> Dictionary:
    return {
        "gameplay_set_component_value": Callable(_gameplay_runtime, "set_component_value"),
        "gameplay_emit_event": Callable(_gameplay_runtime, "emit_event"),
        "gameplay_interact": Callable(_interaction_runtime, "interact"),
        "gameplay_damage": Callable(_health_runtime, "apply_damage"),
        "gameplay_heal": Callable(_health_runtime, "heal"),
        "gameplay_start_dialogue": Callable(_dialogue_runtime, "start_dialogue"),
        "gameplay_start_quest": Callable(_quest_runtime, "start_quest"),
        "gameplay_enter_vehicle": Callable(_vehicle_runtime, "enter_vehicle"),
        "gameplay_save_slot": Callable(_save_state_runtime, "save_slot"),
        "gameplay_load_slot": Callable(_save_state_runtime, "load_slot"),
        "gameplay_get_component_value": Callable(self, "_visual_get_component_value"),
    }


func _visual_get_component_value(entity_id: String, component_key: String, property_name: String) -> Dictionary:
    var values: Dictionary = _gameplay_runtime.get_component_values(entity_id, component_key)
    if values.is_empty():
        return _failure("Visual gameplay component reference does not resolve: %s/%s" % [entity_id, component_key])
    if not values.has(property_name):
        return _failure("Visual gameplay component property does not exist: %s.%s" % [component_key, property_name])
    return {"ok": true, "errors": [], "value": values[property_name]}


func _clear_runtime_services() -> void:
    _save_state_runtime.clear()
    _vehicle_runtime.clear()
    _dialogue_runtime.clear()
    _quest_runtime.clear()
    _npc_runtime.clear()
    _interaction_runtime.clear()
    _inventory_runtime.clear()
    _health_runtime.clear()


func _rollback_startup() -> void:
    _free_player()
    _clear_runtime_services()
    _gameplay_runtime.clear()
    _runtime_state.clear()
    GameplayInput.uninstall_owned()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if is_instance_valid(_previous_camera):
        _previous_camera.current = true
    _previous_camera = null
    if _editor_session != null:
        _editor_session.get_bridge().clear_excluded_entity_ids()
        if _editor_session.has_method("restore_selection"):
            _editor_session.restore_selection(_selected_ids, _primary_id)
    _editor_session = null
    _spawn_entity_id = ""
    _selected_ids.clear()
    _primary_id = ""
    _active = false


func _free_player() -> void:
    if _player == null:
        return
    if _player.has_method("release_pointer"):
        _player.release_pointer()
    if _player.get_parent() == self:
        remove_child(_player)
    _player.free()
    _player = null


func _optional_id(value: Variant) -> String:
    if value == null:
        return ""
    return str(value)


func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}

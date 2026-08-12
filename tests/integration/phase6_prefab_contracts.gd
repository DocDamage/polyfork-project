extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const PrefabAuthoring = preload("res://src/gameplay/prefab_authoring_service.gd")
const PrefabResolver = preload("res://src/gameplay/prefab_resolver.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Phase 6 Prefabs", &"small", "blank_sandbox")
    var session = EditorSession.new(); var dirty: Array[int] = [0]
    session.bind_project(project, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    var first := _place(session, "Prefab A", Vector3.ZERO); var second := _place(session, "Prefab B", Vector3(2.0, 0.0, 0.0))
    session.select_entity(first); session.toggle_entity(second)
    var grouped: Dictionary = session.group_selected(); var root_id := str(grouped.get("group_id", ""))
    if root_id.is_empty(): errors.append("Prefab fixture requires a command-backed hierarchy root."); session.free(); return errors

    var root := "user://tests/phase6_prefab_%s" % StableId.generate(); var gameplay = GameplayService.new()
    var bound: Dictionary = gameplay.bind_project(project, root.path_join("project"), session, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    if not bound.get("ok", false): errors.append("Prefab gameplay service must bind."); session.free(); return errors
    gameplay.add_component(first, Components.id_for("health"), {"max_health": 175.0, "current_health": 175.0})

    var prefabs = PrefabAuthoring.new(); prefabs.bind(project, gameplay.get_state(), gameplay.get_repository(), session, func() -> Dictionary: dirty[0] += 1; return {"ok": true, "errors": []})
    var save: Dictionary = prefabs.save_prefab(root_id, "Reusable Group"); var prefab_id := str(save.get("prefab_id", ""))
    if not save.get("ok", false) or not StableId.is_valid(prefab_id): errors.append("Saving a configured hierarchy must create a stable prefab definition.")
    else:
        var saved: Dictionary = gameplay.get_state().get_prefab(prefab_id)
        if saved.get("nodes", []).size() != 3: errors.append("Prefab snapshot must preserve the hierarchy node count.")
        var component_found := false
        for node in saved.get("nodes", []):
            if node.get("components", {}).has(Components.id_for("health")): component_found = float(node["components"][Components.id_for("health")].get("max_health", 0.0)) == 175.0
        if not component_found: errors.append("Prefab snapshot must preserve configured component values.")
    session.undo_edit()
    if not gameplay.get_state().get_prefab(prefab_id).is_empty(): errors.append("Undo prefab save must remove the prefab atomically.")
    session.redo_edit()
    if gameplay.get_state().get_prefab(prefab_id).is_empty(): errors.append("Redo prefab save must restore the same stable prefab ID.")

    var base: Dictionary = gameplay.get_state().get_prefab(prefab_id); var root_node_id := _root_node_id(base)
    var derived: Dictionary = prefabs.create_derived_prefab(prefab_id, "Derived Group", {root_node_id: {"display_name": "Derived Root"}})
    var derived_id := str(derived.get("prefab_id", "")); var effective: Dictionary = PrefabResolver.new(gameplay.get_state()).resolve(derived_id)
    if not derived.get("ok", false) or not effective.get("ok", false) or str(_node(effective.get("nodes", []), root_node_id).get("display_name", "")) != "Derived Root": errors.append("Derived prefab must resolve base data plus its explicit override.")

    var before_count: int = project.entity_records.size(); var one: Dictionary = prefabs.instantiate_prefab(derived_id, Vector3(8.0, 0.0, 0.0)); var one_root := str(one.get("root_entity_id", ""))
    var two: Dictionary = prefabs.instantiate_prefab(derived_id, Vector3(14.0, 0.0, 0.0)); var two_root := str(two.get("root_entity_id", ""))
    if not one.get("ok", false) or not two.get("ok", false) or project.entity_records.size() != before_count + 6: errors.append("Repeated prefab instantiation must create complete effective hierarchies.")
    if one_root == two_root or not StableId.is_valid(one_root) or not StableId.is_valid(two_root): errors.append("Repeated prefab instantiation must allocate fresh entity UUIDs.")
    if _entity(project, one_root).get("prefab_id") != derived_id or _entity(project, two_root).get("prefab_id") != derived_id: errors.append("Prefab instances must retain the stable prefab reference.")

    var instance_record: Dictionary = gameplay.get_state().prefab_instance_for_root(one_root); var instance_id := str(instance_record.get("instance_id", ""))
    var override_result: Dictionary = prefabs.set_instance_override(instance_id, root_node_id, {"display_name": "Instance Hero"})
    var resolved_instance: Dictionary = PrefabResolver.new(gameplay.get_state()).resolve_instance(gameplay.get_state().get_prefab_instance(instance_id))
    if not override_result.get("ok", false) or str(_node(resolved_instance.get("nodes", []), root_node_id).get("display_name", "")) != "Instance Hero": errors.append("Explicit instance overrides must win over inherited prefab values.")

    var cycle_a := _derived_record(prefab_id, "Cycle A"); var cycle_b := _derived_record(str(cycle_a["prefab_id"]), "Cycle B"); cycle_a["base_prefab_id"] = cycle_b["prefab_id"]
    gameplay.get_state().prefabs.append(cycle_a); gameplay.get_state().prefabs.append(cycle_b)
    if PrefabResolver.new(gameplay.get_state()).resolve(str(cycle_a["prefab_id"])).get("ok", false): errors.append("Prefab inheritance cycles must fail safely.")
    gameplay.get_state().prefabs.resize(gameplay.get_state().prefabs.size() - 2)
    session.free(); return errors


static func _place(session, label: String, position: Vector3) -> String:
    if not session.begin_proxy_placement(label).get("ok", false): return ""
    session.update_placement_preview(position); var result: Dictionary = session.commit_placement(); return str(result.get("entity_id", "")) if result.get("ok", false) else ""


static func _entity(project, entity_id: String) -> Dictionary:
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}


static func _root_node_id(prefab: Dictionary) -> String:
    for node in prefab.get("nodes", []):
        if node.get("parent_node_id") == null or str(node.get("parent_node_id", "")).is_empty(): return str(node.get("node_id", ""))
    return ""


static func _node(nodes: Array, node_id: String) -> Dictionary:
    for node in nodes:
        if str(node.get("node_id", "")) == node_id: return node
    return {}


static func _derived_record(base_id: String, display_name: String) -> Dictionary:
    return {"document_type": Contracts.PREFAB, "schema_version": Contracts.SCHEMA_VERSION, "prefab_id": StableId.generate(), "display_name": display_name, "base_prefab_id": base_id, "nodes": [], "node_overrides": {}, "removed_node_ids": [], "socket_ids": [], "socket_overrides": {}, "removed_socket_ids": []}

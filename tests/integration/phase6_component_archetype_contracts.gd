extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProject = preload("res://src/world/world_project.gd")
const EditorSession = preload("res://src/editor/editor_session.gd")
const GameplayService = preload("res://src/gameplay/gameplay_service.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")
const Archetypes = preload("res://src/gameplay/builtin_archetype_library.gd")
const GameplayRepository = preload("res://src/gameplay/gameplay_repository.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project = WorldProject.new(); project.initialize_new("Phase 6 Components", &"small", "blank_sandbox")
    var dirty_count: Array[int] = [0]
    var session = EditorSession.new()
    var bind: Dictionary = session.bind_project(project, func() -> Dictionary: dirty_count[0] += 1; return {"ok": true, "errors": []})
    if not bind.get("ok", false): errors.append("Phase 6 component fixture must bind the editor session."); session.free(); return errors
    session.begin_proxy_placement("Gameplay Prop"); var placed: Dictionary = session.commit_placement()
    if not placed.get("ok", false): errors.append("Phase 6 component fixture must create a real world entity."); session.free(); return errors
    var entity_id := str(placed.get("entity_id", "")); var original_id := entity_id

    var root := "user://tests/phase6_components_%s" % StableId.generate(); var service = GameplayService.new()
    var service_bind: Dictionary = service.bind_project(project, root.path_join("project"), session, func() -> Dictionary: dirty_count[0] += 1; return {"ok": true, "errors": []})
    if not service_bind.get("ok", false): errors.append("Gameplay service must bind seeded registries: %s" % [service_bind.get("errors", [])]); session.free(); return errors

    var add: Dictionary = service.add_component(entity_id, Components.id_for("damageable"), {"armor": 12.0})
    if not add.get("ok", false) or service.components_for_entity(entity_id).size() != 2: errors.append("Adding Damageable must atomically add its Health dependency and target component.")
    var definition_ids: Array[String] = []
    for record in service.components_for_entity(entity_id): definition_ids.append(str(record.get("definition_id", "")))
    if not definition_ids.has(Components.id_for("health")) or not definition_ids.has(Components.id_for("damageable")): errors.append("Dependency addition must preserve stable component-definition identity.")
    if _entity(project, entity_id).get("component_instance_ids", []).size() != 2: errors.append("World entity component_instance_ids must stay synchronized with gameplay instances.")

    var stable_instance_ids: Array[String] = []
    for record in service.components_for_entity(entity_id): stable_instance_ids.append(str(record.get("instance_id", "")))
    stable_instance_ids.sort(); var undo_add: Dictionary = session.undo_edit()
    if not undo_add.get("ok", false) or not service.components_for_entity(entity_id).is_empty() or not _entity(project, entity_id).get("component_instance_ids", []).is_empty(): errors.append("Universal Undo must restore both gameplay instances and world entity component references.")
    var redo_add: Dictionary = session.redo_edit(); var redo_ids: Array[String] = []
    for record in service.components_for_entity(entity_id): redo_ids.append(str(record.get("instance_id", "")))
    redo_ids.sort()
    if not redo_add.get("ok", false) or redo_ids != stable_instance_ids: errors.append("Universal Redo must restore the same stable component instance IDs, not allocate replacements.")

    var health := _component(service, entity_id, Components.id_for("health")); var damageable := _component(service, entity_id, Components.id_for("damageable"))
    var configure: Dictionary = service.configure_component(str(health.get("instance_id", "")), {"max_health": 240.0, "current_health": 180.0})
    var configured: Dictionary = service.get_state().get_instance(str(health.get("instance_id", "")))
    if not configure.get("ok", false) or float(configured.get("values", {}).get("max_health", 0.0)) != 240.0: errors.append("Component configuration must persist validated typed property values.")
    var invalid_configure: Dictionary = service.configure_component(str(health.get("instance_id", "")), {"max_health": -2.0})
    if invalid_configure.get("ok", false) or float(service.get_state().get_instance(str(health.get("instance_id", ""))).get("values", {}).get("max_health", 0.0)) != 240.0: errors.append("Invalid component property edits must fail without partial authored mutation.")
    if service.remove_component(entity_id, str(health.get("instance_id", ""))).get("ok", false): errors.append("A component required by another authored component must reject independent removal.")
    var remove_damageable: Dictionary = service.remove_component(entity_id, str(damageable.get("instance_id", "")))
    if not remove_damageable.get("ok", false) or service.components_for_entity(entity_id).size() != 1: errors.append("Removing a non-required component must leave unrelated/dependency components intact.")

    var before_archetype_count := service.components_for_entity(entity_id).size(); var apply: Dictionary = service.apply_archetype(entity_id, Archetypes.id_for("door"))
    if not apply.get("ok", false) or entity_id != original_id: errors.append("Archetype application must retain world entity stable identity.")
    var after_defs: Array[String] = []
    for record in service.components_for_entity(entity_id): after_defs.append(str(record.get("definition_id", "")))
    for expected in [Components.id_for("health"), Components.id_for("door"), Components.id_for("interactable"), Components.id_for("collision"), Components.id_for("save_state")]:
        if not after_defs.has(expected): errors.append("Door archetype must add required components while preserving unrelated Health.")
    var undo_archetype: Dictionary = session.undo_edit()
    if not undo_archetype.get("ok", false) or service.components_for_entity(entity_id).size() != before_archetype_count: errors.append("Undo archetype must remove only its authored changes and preserve pre-existing components.")

    # Raw Phase 3 duplication must never alias owner-bound gameplay instance IDs. Fully
    # configured cloning is provided by prefab instantiation with fresh component identities.
    session.select_entity(entity_id); var duplicate: Dictionary = session.duplicate_selected()
    var duplicate_ids: Array = duplicate.get("entity_ids", []); var duplicate_id := "" if duplicate_ids.is_empty() else str(duplicate_ids[0])
    if not duplicate.get("ok", false) or duplicate_id.is_empty(): errors.append("Gameplay lifecycle fixture must duplicate the authored entity.")
    elif not _entity(project, duplicate_id).get("component_instance_ids", []).is_empty(): errors.append("Raw world duplication must clear owner-bound component instance IDs instead of sharing source identity.")
    if _entity(project, entity_id).get("component_instance_ids", []).size() != 1: errors.append("Raw duplication must not mutate the source gameplay composition.")

    session.select_entity(entity_id); var deleted: Dictionary = session.delete_selected()
    if not deleted.get("ok", false) or not _entity(project, entity_id).is_empty(): errors.append("Gameplay lifecycle fixture must delete the source world entity.")
    var dormant_reopen: Dictionary = GameplayRepository.new(root.path_join("project")).open_or_create(project)
    if not dormant_reopen.get("ok", false): errors.append("Gameplay records with a temporarily absent owner must reopen as recoverable dormant state: %s" % [dormant_reopen.get("errors", [])])
    elif dormant_reopen.get("state").instances_for_entity(entity_id).size() != 1: errors.append("Dormant component records must retain their stable owner reference for Delete/Undo recovery.")
    var undo_delete: Dictionary = session.undo_edit()
    if not undo_delete.get("ok", false) or _entity(project, entity_id).is_empty() or service.components_for_entity(entity_id).size() != 1: errors.append("Undo delete must restore the world entity while its stable gameplay composition remains available.")

    var state_before_reopen = service.get_state(); var flush: Dictionary = service.get_repository().flush_all(state_before_reopen)
    if not flush.get("ok", false): errors.append("Gameplay registries must support full crash-safe persistence.")
    var reopened: Dictionary = GameplayRepository.new(root.path_join("project")).open_or_create(project)
    if not reopened.get("ok", false): errors.append("Component gameplay state must reopen after save: %s" % [reopened.get("errors", [])])
    else:
        var reopened_ids: Array[String] = []
        for record in reopened.get("state").instances_for_entity(entity_id): reopened_ids.append(str(record.get("instance_id", "")))
        if reopened_ids.size() != 1 or not StableId.is_valid(reopened_ids[0]): errors.append("Component instance identity must survive gameplay repository restart.")
    session.free(); return errors


static func _entity(project, entity_id: String) -> Dictionary:
    for record in project.entity_records:
        if str(record.get("entity_id", "")) == entity_id: return record
    return {}


static func _component(service, entity_id: String, definition_id: String) -> Dictionary:
    for record in service.components_for_entity(entity_id):
        if str(record.get("definition_id", "")) == definition_id: return record
    return {}

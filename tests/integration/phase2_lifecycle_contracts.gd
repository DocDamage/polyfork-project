extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const EntityRegistry = preload("res://src/world/entity_registry.gd")
const Repository = preload("res://src/world/project_repository.gd")
const AutosaveService = preload("res://src/world/autosave_service.gd")
const CommandHistory = preload("res://src/commands/command_history.gd")
const CommandTransaction = preload("res://src/commands/command_transaction.gd")
const TitleCommand = preload("res://tests/unit/fixtures/project_title_command.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    _check_entity_project_lifecycle(errors)
    _check_command_save_undo_redo(errors)
    _check_transaction_failure_not_persisted(errors)
    _check_command_autosave_recovery(errors)
    _check_history_bounds_in_lifecycle(errors)
    return errors


static func _check_entity_project_lifecycle(errors: Array[String]) -> void:
    var repository = Repository.new(_root("entity_lifecycle"))
    var created: Dictionary = repository.create_project("Entity Lifecycle", &"medium", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Phase 2 entity lifecycle project must be created.")
        return

    var project = created["project"]
    var cell_id := StableId.generate()
    project.cell_ids.append(cell_id)
    var parent = WorldEntity.new()
    parent.initialize_new("Parent Entity", cell_id)
    var child = WorldEntity.new()
    child.initialize_new("Child Entity", cell_id)
    child.parent_entity_id = parent.entity_id
    child.transform["position"] = [4.0, 2.0, -3.0]

    var registry = EntityRegistry.new()
    if not registry.add(parent).get("ok", false) or not registry.add(child).get("ok", false):
        errors.append("Stable world entities must register before persistence.")
        return
    project.entity_records = registry.to_dictionaries()

    var save_result: Dictionary = repository.save_project(project)
    if not save_result.get("ok", false):
        errors.append("Project with stable entity records must save: %s" % save_result.get("errors", []))
        return

    var reopened: Dictionary = Repository.new(repository.root_path).open_project(project.project_id)
    if not reopened.get("ok", false):
        errors.append("Project with entity records must reopen.")
        return
    var loaded_project = reopened["project"]
    var loaded_registry = EntityRegistry.new()
    var load_result: Dictionary = loaded_registry.load_dictionaries(loaded_project.entity_records)
    if not load_result.get("ok", false):
        errors.append("Reopened entity records must reconstruct the entity registry.")
        return
    var loaded_child = loaded_registry.get_entity(child.entity_id)
    if loaded_registry.size() != 2 or loaded_child == null:
        errors.append("Entity IDs must survive save and reload.")
    elif loaded_child.parent_entity_id != parent.entity_id:
        errors.append("Stable parent_entity_id relationships must survive reload.")
    elif loaded_child.transform.get("position") != [4.0, 2.0, -3.0]:
        errors.append("Entity authored state must survive save and reload.")


static func _check_command_save_undo_redo(errors: Array[String]) -> void:
    var repository = Repository.new(_root("command_lifecycle"))
    var created: Dictionary = repository.create_project("Original", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Command lifecycle project must be created.")
        return

    var project = created["project"]
    var project_id: String = project.project_id
    var history = CommandHistory.new(4)
    var execute_result: Dictionary = history.execute_command(TitleCommand.new(project, "Committed"), "Rename project")
    if not execute_result.get("ok", false) or project.title != "Committed":
        errors.append("Generic command execution must commit authored state.")
        return
    if not _save_and_expect_title(repository, project, project_id, "Committed"):
        errors.append("Committed command state must survive save and reopen.")

    if not history.undo().get("ok", false) or project.title != "Original":
        errors.append("Undo must restore the pre-command project state.")
    elif not _save_and_expect_title(repository, project, project_id, "Original"):
        errors.append("Undone state must remain undone after save and reopen.")

    if not history.redo().get("ok", false) or project.title != "Committed":
        errors.append("Redo must restore the committed project state.")
    elif not _save_and_expect_title(repository, project, project_id, "Committed"):
        errors.append("Redone state must survive save and reopen.")


static func _check_transaction_failure_not_persisted(errors: Array[String]) -> void:
    var repository = Repository.new(_root("transaction_failure"))
    var created: Dictionary = repository.create_project("Known Good", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Transaction failure project must be created.")
        return
    var project = created["project"]
    var history = CommandHistory.new()
    var transaction = CommandTransaction.new("Failing transaction")
    transaction.add_command(TitleCommand.new(project, "Partial State"))
    transaction.add_command(TitleCommand.new(project, "Never Applied", true))
    var result: Dictionary = history.execute_transaction(transaction)
    if result.get("ok", false):
        errors.append("A transaction with a failing later command must fail.")
    if project.title != "Known Good":
        errors.append("Failed transaction must roll back earlier successful commands.")
    if history.undo_count() != 0:
        errors.append("Failed transaction must not enter undo history.")
    repository.save_project(project)
    var reopened := repository.open_project(project.project_id)
    if not reopened.get("ok", false) or reopened["project"].title != "Known Good":
        errors.append("Partially mutated transaction state must not leak into persistence.")


static func _check_command_autosave_recovery(errors: Array[String]) -> void:
    var root := _root("command_autosave")
    var repository = Repository.new(root)
    var created: Dictionary = repository.create_project("Canonical", &"medium", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("Command autosave project must be created.")
        return
    var project = created["project"]
    var history = CommandHistory.new()
    var service = AutosaveService.new(repository, 0.1)
    service.attach_project(project)
    if not history.execute_command(TitleCommand.new(project, "Recovered Command State")).get("ok", false):
        errors.append("Command must execute before integrated autosave recovery.")
        return
    service.mark_dirty()
    var checkpoint: Dictionary = service.advance(0.1)
    if not checkpoint.get("ok", false) or not checkpoint.get("attempted", false):
        errors.append("Dirty command state must produce an autosave checkpoint.")
        return
    var restarted = Repository.new(root)
    var canonical := restarted.open_project(project.project_id)
    if not canonical.get("ok", false) or canonical["project"].title != "Canonical":
        errors.append("Autosave must leave canonical state untouched before recovery.")
        return
    var recovered := restarted.recover_latest_checkpoint(project.project_id)
    if not recovered.get("ok", false) or recovered["project"].title != "Recovered Command State":
        errors.append("Restart recovery must restore command-authored checkpoint state.")
    elif recovered["project"].project_id != project.project_id:
        errors.append("Recovery must preserve stable project identity.")


static func _check_history_bounds_in_lifecycle(errors: Array[String]) -> void:
    var repository = Repository.new(_root("history_bounds"))
    var created: Dictionary = repository.create_project("H0", &"small", "blank_sandbox")
    if not created.get("ok", false):
        errors.append("History-bound lifecycle project must be created.")
        return
    var project = created["project"]
    var history = CommandHistory.new(2)
    for title in ["H1", "H2", "H3"]:
        if not history.execute_command(TitleCommand.new(project, title)).get("ok", false):
            errors.append("Bounded history fixture commands must execute.")
            return
    if history.undo_count() != 2:
        errors.append("Integrated command history must enforce its configured bound.")
        return
    history.undo()
    history.undo()
    if project.title != "H1" or history.undo().get("ok", false):
        errors.append("History bound must discard only entries older than the retained window.")
    if not _save_and_expect_title(repository, project, project.project_id, "H1"):
        errors.append("State reached through bounded history must remain persistable.")


static func _save_and_expect_title(repository, project, project_id: String, expected_title: String) -> bool:
    var saved: Dictionary = repository.save_project(project)
    if not saved.get("ok", false):
        return false
    var reopened: Dictionary = Repository.new(repository.root_path).open_project(project_id)
    return reopened.get("ok", false) and reopened["project"].title == expected_title


static func _root(label: String) -> String:
    return "user://tests/phase2_%s_%s" % [label, StableId.generate()]

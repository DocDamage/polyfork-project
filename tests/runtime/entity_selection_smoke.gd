extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")


static func run_checks(workspace: Control) -> Array[String]:
    var errors: Array[String] = []
    var cell_id := StableId.generate()

    var first = WorldEntity.new()
    first.initialize_new("Selection One", cell_id)
    first.transform["position"] = [2.0, 1.0, 4.0]

    var second = WorldEntity.new()
    second.initialize_new("Selection Two", cell_id)
    second.transform["rotation_degrees"] = [0.0, 90.0, 0.0]

    var configuration: Dictionary = workspace.get_configuration()
    configuration["cell_ids"] = [cell_id]
    configuration["entities"] = [first.to_dictionary(), second.to_dictionary()]
    var load_result: Dictionary = workspace.set_configuration(configuration)
    if not load_result.get("ok", false):
        errors.append("Workspace must bridge valid persisted entity records: %s" % load_result.get("errors", []))
        return errors

    if workspace.get_runtime_entity_count() != 2:
        errors.append("Workspace must expose bridged runtime entity count.")
        return errors

    var config_before_selection := JSON.stringify(workspace.get_configuration())
    var select_first: Dictionary = workspace.select_entity(first.entity_id)
    if not select_first.get("ok", false):
        errors.append("Workspace must select a runtime entity by stable ID.")
        return errors

    var inspector := workspace.find_child("InspectorPanel", true, false)
    if inspector == null or not inspector.visible:
        errors.append("Entity selection must open the existing inspector.")
    else:
        var context: Dictionary = inspector.get_context()
        if context.get("source") != "entity_selection" or context.get("title") != "Selection One":
            errors.append("Entity selection must populate inspector context from the bridged entity record.")
        if str(context.get("position", "—")) == "—":
            errors.append("Entity selection inspector must expose persisted transform values.")

    var first_node = workspace.get_runtime_entity_node(first.entity_id)
    var second_node = workspace.get_runtime_entity_node(second.entity_id)
    if first_node == null or second_node == null or not first_node.is_selected():
        errors.append("Selected entity must map to a selected runtime Node3D wrapper.")
        return errors

    var select_second: Dictionary = workspace.select_entity(second.entity_id)
    if not select_second.get("ok", false) or workspace.get_selected_entity_id() != second.entity_id:
        errors.append("Workspace single-selection state must replace the prior entity selection.")
    if first_node.is_selected() or not second_node.is_selected():
        errors.append("Workspace must keep exactly one runtime entity selected.")

    var descendant := Node3D.new()
    second_node.add_child(descendant)
    var descendant_select: Dictionary = workspace.select_runtime_node(descendant)
    if not descendant_select.get("ok", false) or workspace.get_selected_entity_id() != second.entity_id:
        errors.append("Workspace selection must resolve descendant scene nodes through stable entity identity.")

    if JSON.stringify(workspace.get_configuration()) != config_before_selection:
        errors.append("Selection must remain editor-only state and must not mutate persistent project configuration.")

    var close_button := workspace.find_child("CloseButton", true, false) as Button
    if close_button == null:
        errors.append("Inspector close control must remain available during entity selection.")
    else:
        close_button.emit_signal("pressed")
        if not workspace.get_selected_entity_id().is_empty():
            errors.append("Closing the entity inspector must clear the single selection.")
        if second_node.is_selected():
            errors.append("Closing the entity inspector must clear runtime selected state.")

    return errors

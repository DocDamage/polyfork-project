extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldEntity = preload("res://src/world/world_entity.gd")
const RuntimeEntityBridge = preload("res://src/editor/runtime_entity_bridge.gd")
const SingleSelection = preload("res://src/editor/single_selection.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var cell_id := StableId.generate()

    var parent = WorldEntity.new()
    parent.initialize_new("Bridge Parent", cell_id)
    parent.transform = {
        "position": [1.0, 2.0, 3.0],
        "rotation_degrees": [0.0, 45.0, 0.0],
        "scale": [1.0, 1.0, 1.0]
    }

    var child = WorldEntity.new()
    child.initialize_new("Bridge Child", cell_id)
    child.parent_entity_id = parent.entity_id
    child.transform = {
        "position": [0.5, 0.0, -1.0],
        "rotation_degrees": [10.0, 0.0, 0.0],
        "scale": [0.5, 0.5, 0.5]
    }

    var bridge = RuntimeEntityBridge.new()
    var rebuild: Dictionary = bridge.rebuild([
        parent.to_dictionary(),
        child.to_dictionary()
    ])
    if not rebuild.get("ok", false):
        errors.append("Runtime entity bridge must rebuild valid entity records: %s" % rebuild.get("errors", []))
        bridge.free()
        return errors

    if bridge.entity_count() != 2:
        errors.append("Runtime entity bridge must expose one runtime node per entity record.")

    var parent_node = bridge.get_entity_node(parent.entity_id)
    var child_node = bridge.get_entity_node(child.entity_id)
    if parent_node == null or child_node == null:
        errors.append("Runtime entity bridge must resolve runtime nodes by stable entity ID.")
        bridge.free()
        return errors

    if child_node.get_parent() != parent_node:
        errors.append("Runtime entity hierarchy must reconstruct parent relationships from stable IDs.")
    if not parent_node.position.is_equal_approx(Vector3(1.0, 2.0, 3.0)):
        errors.append("Runtime entity bridge must apply persisted position to the Node3D wrapper.")
    if not parent_node.rotation_degrees.is_equal_approx(Vector3(0.0, 45.0, 0.0)):
        errors.append("Runtime entity bridge must apply persisted rotation to the Node3D wrapper.")
    if not child_node.scale.is_equal_approx(Vector3(0.5, 0.5, 0.5)):
        errors.append("Runtime entity bridge must apply persisted scale to the Node3D wrapper.")

    var descendant := Node3D.new()
    child_node.add_child(descendant)
    if bridge.resolve_entity_id(descendant) != child.entity_id:
        errors.append("Bridge lookup must resolve descendant scene nodes back to stable entity identity.")

    var selection = SingleSelection.new()
    var bind_result: Dictionary = selection.bind_bridge(bridge)
    if not bind_result.get("ok", false):
        errors.append("Single selection must bind to the runtime entity bridge.")
    else:
        _check_selection(selection, bridge, parent.entity_id, child.entity_id, descendant, errors)

    var original_parent_node = bridge.get_entity_node(parent.entity_id)
    var cyclic_parent: Dictionary = parent.to_dictionary()
    var cyclic_child: Dictionary = child.to_dictionary()
    cyclic_parent["parent_entity_id"] = child.entity_id
    cyclic_child["parent_entity_id"] = parent.entity_id
    var cyclic_result: Dictionary = bridge.rebuild([cyclic_parent, cyclic_child])
    if cyclic_result.get("ok", false):
        errors.append("Runtime entity bridge must reject parent cycles.")
    if bridge.entity_count() != 2 or bridge.get_entity_node(parent.entity_id) != original_parent_node:
        errors.append("Rejected bridge rebuild must preserve the previous known-good runtime mapping.")

    selection.clear()
    bridge.free()
    return errors


static func _check_selection(
    selection,
    bridge,
    parent_id: String,
    child_id: String,
    descendant: Node,
    errors: Array[String]
) -> void:
    var first: Dictionary = selection.select_entity(parent_id)
    if not first.get("ok", false) or selection.get_selected_entity_id() != parent_id:
        errors.append("Single selection must select a bridged entity by stable ID.")
        return
    if not bridge.get_entity_node(parent_id).is_selected():
        errors.append("Selected runtime entity wrapper must expose selected state.")

    var second: Dictionary = selection.select_entity(child_id)
    if not second.get("ok", false) or selection.get_selected_entity_id() != child_id:
        errors.append("Selecting a second entity must replace the prior single selection.")
    if bridge.get_entity_node(parent_id).is_selected() or not bridge.get_entity_node(child_id).is_selected():
        errors.append("Single selection must leave exactly one bridged entity selected.")

    var descendant_result: Dictionary = selection.select_node(descendant)
    if not descendant_result.get("ok", false) or selection.get_selected_entity_id() != child_id:
        errors.append("Selecting a descendant runtime node must resolve through the entity bridge.")

    var invalid_result: Dictionary = selection.select_entity(StableId.generate())
    if invalid_result.get("ok", false):
        errors.append("Single selection must reject stable IDs that are not present in the bridge.")
    if selection.get_selected_entity_id() != child_id:
        errors.append("Rejected selection attempts must preserve the previous selection.")

    selection.clear()
    if selection.has_selection() or bridge.get_entity_node(child_id).is_selected():
        errors.append("Clearing selection must clear both model and runtime selected state.")

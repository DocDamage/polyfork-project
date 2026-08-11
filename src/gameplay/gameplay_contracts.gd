class_name PlayWorldGameplayContracts
extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")

const SCHEMA_VERSION := 1
const COMPONENT_DEFINITION := "component_definition"
const COMPONENT_INSTANCE := "component_instance"
const ARCHETYPE := "archetype_definition"
const PREFAB := "prefab_definition"
const SOCKET := "socket_definition"
const ATTACHMENT := "attachment_record"
const PREFAB_INSTANCE := "prefab_instance_record"

const PROPERTY_TYPES := ["bool", "int", "float", "string", "enum", "vector3"]
const SOCKET_CATEGORIES := ["Grip", "Seat", "Mount", "DoorHandle", "Light", "LootSpawn", "Wheel", "Muzzle", "Camera", "InteractionPoint", "Custom"]


static func validate_component_definition(data: Dictionary) -> Array[String]:
    var errors := _base(data, COMPONENT_DEFINITION, "definition_id")
    if str(data.get("key", "")).strip_edges().is_empty(): errors.append("Component definition key is required.")
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Component definition display_name is required.")
    if str(data.get("category", "")).strip_edges().is_empty(): errors.append("Component definition category is required.")
    var properties = data.get("properties", {})
    if not properties is Dictionary: errors.append("Component definition properties must be a dictionary.")
    else:
        for property_name in properties.keys():
            if str(property_name).strip_edges().is_empty(): errors.append("Component property names may not be empty.")
            elif not properties[property_name] is Dictionary: errors.append("Component property spec for %s must be a dictionary." % property_name)
            else: _validate_property_spec(str(property_name), properties[property_name], errors)
    _validate_id_array(data.get("dependencies", []), "dependencies", errors)
    _validate_id_array(data.get("conflicts", []), "conflicts", errors)
    var own_id := str(data.get("definition_id", ""))
    if data.get("dependencies", []).has(own_id): errors.append("Component definition cannot depend on itself.")
    if data.get("conflicts", []).has(own_id): errors.append("Component definition cannot conflict with itself.")
    if not data.get("runtime_hook", "") is String: errors.append("Component definition runtime_hook must be a string.")
    return errors


static func validate_component_instance(data: Dictionary) -> Array[String]:
    var errors := _base(data, COMPONENT_INSTANCE, "instance_id")
    _require_id(data.get("definition_id"), "Component instance definition_id", errors)
    _require_id(data.get("owner_entity_id"), "Component instance owner_entity_id", errors)
    if not data.get("values", {}) is Dictionary: errors.append("Component instance values must be a dictionary.")
    return errors


static func validate_archetype(data: Dictionary) -> Array[String]:
    var errors := _base(data, ARCHETYPE, "archetype_id")
    if str(data.get("key", "")).strip_edges().is_empty(): errors.append("Archetype key is required.")
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Archetype display_name is required.")
    _validate_id_array(data.get("required_definition_ids", []), "required_definition_ids", errors)
    var defaults = data.get("component_defaults", {})
    if not defaults is Dictionary: errors.append("Archetype component_defaults must be a dictionary.")
    else:
        for definition_id in defaults.keys():
            _require_id(definition_id, "Archetype component_defaults key", errors)
            if not defaults[definition_id] is Dictionary: errors.append("Archetype component defaults must be dictionaries.")
    var tags = data.get("tags", [])
    if not tags is Array: errors.append("Archetype tags must be an array.")
    return errors


static func validate_prefab(data: Dictionary) -> Array[String]:
    var errors := _base(data, PREFAB, "prefab_id")
    if str(data.get("display_name", "")).strip_edges().is_empty(): errors.append("Prefab display_name is required.")
    _optional_id(data.get("base_prefab_id"), "Prefab base_prefab_id", errors)
    var nodes = data.get("nodes", [])
    if not nodes is Array: errors.append("Prefab nodes must be an array.")
    else:
        var known: Dictionary = {}
        var roots := 0
        for item in nodes:
            if not item is Dictionary: errors.append("Prefab nodes must contain dictionaries only."); continue
            var node: Dictionary = item
            var node_id := str(node.get("node_id", ""))
            _require_id(node_id, "Prefab node_id", errors)
            if known.has(node_id): errors.append("Prefab contains duplicate node_id.")
            known[node_id] = true
            if str(node.get("display_name", "")).strip_edges().is_empty(): errors.append("Prefab node display_name is required.")
            _optional_id(node.get("parent_node_id"), "Prefab node parent_node_id", errors)
            _optional_id(node.get("asset_id"), "Prefab node asset_id", errors)
            _validate_transform(node.get("transform"), "Prefab node transform", errors)
            if not node.get("components", {}) is Dictionary: errors.append("Prefab node components must be a dictionary.")
            if node.get("parent_node_id") == null or str(node.get("parent_node_id", "")).is_empty(): roots += 1
        for item in nodes:
            if item is Dictionary:
                var parent = item.get("parent_node_id")
                if parent != null and not str(parent).is_empty() and not known.has(str(parent)) and data.get("base_prefab_id") == null:
                    errors.append("Base prefab node parent_node_id must resolve inside the prefab.")
        if (data.get("base_prefab_id") == null or str(data.get("base_prefab_id", "")).is_empty()) and roots != 1:
            errors.append("A base prefab must contain exactly one root node.")
    var overrides = data.get("node_overrides", {})
    if not overrides is Dictionary: errors.append("Prefab node_overrides must be a dictionary.")
    else:
        for node_id in overrides.keys():
            _require_id(node_id, "Prefab node_overrides key", errors)
            if not overrides[node_id] is Dictionary: errors.append("Prefab node overrides must be dictionaries.")
    _validate_id_array(data.get("removed_node_ids", []), "removed_node_ids", errors)
    _validate_id_array(data.get("socket_ids", []), "socket_ids", errors)
    var socket_overrides = data.get("socket_overrides", {})
    if not socket_overrides is Dictionary: errors.append("Prefab socket_overrides must be a dictionary.")
    else:
        for socket_id in socket_overrides.keys(): _require_id(socket_id, "Prefab socket_overrides key", errors)
    _validate_id_array(data.get("removed_socket_ids", []), "removed_socket_ids", errors)
    return errors


static func validate_socket(data: Dictionary) -> Array[String]:
    var errors := _base(data, SOCKET, "socket_id")
    var owner_kind := str(data.get("owner_kind", ""))
    if not ["entity", "prefab_node"].has(owner_kind): errors.append("Socket owner_kind must be entity or prefab_node.")
    _require_id(data.get("owner_id"), "Socket owner_id", errors)
    if str(data.get("name", "")).strip_edges().is_empty(): errors.append("Socket name is required.")
    var category := str(data.get("category", ""))
    if not SOCKET_CATEGORIES.has(category): errors.append("Socket category is unsupported.")
    if category == "Custom" and str(data.get("custom_category", "")).strip_edges().is_empty(): errors.append("Custom socket category requires custom_category.")
    _validate_transform(data.get("local_transform"), "Socket local_transform", errors)
    return errors


static func validate_attachment(data: Dictionary) -> Array[String]:
    var errors := _base(data, ATTACHMENT, "attachment_id")
    _require_id(data.get("parent_entity_id"), "Attachment parent_entity_id", errors)
    _require_id(data.get("parent_socket_id"), "Attachment parent_socket_id", errors)
    _require_id(data.get("child_entity_id"), "Attachment child_entity_id", errors)
    _optional_id(data.get("child_socket_id"), "Attachment child_socket_id", errors)
    if str(data.get("parent_entity_id", "")) == str(data.get("child_entity_id", "")): errors.append("Attachment parent and child entities must differ.")
    _validate_transform(data.get("offset_transform"), "Attachment offset_transform", errors)
    return errors


static func validate_prefab_instance(data: Dictionary) -> Array[String]:
    var errors := _base(data, PREFAB_INSTANCE, "instance_id")
    _require_id(data.get("prefab_id"), "Prefab instance prefab_id", errors)
    _require_id(data.get("root_entity_id"), "Prefab instance root_entity_id", errors)
    var mapping = data.get("node_entity_ids", {})
    if not mapping is Dictionary: errors.append("Prefab instance node_entity_ids must be a dictionary.")
    else:
        for node_id in mapping.keys():
            _require_id(node_id, "Prefab instance node ID", errors)
            _require_id(mapping[node_id], "Prefab instance entity ID", errors)
    var overrides = data.get("overrides", {})
    if not overrides is Dictionary: errors.append("Prefab instance overrides must be a dictionary.")
    return errors


static func validate_values(values: Dictionary, definition: Dictionary, partial: bool = false) -> Array[String]:
    var errors: Array[String] = []
    var specs: Dictionary = definition.get("properties", {})
    for key in values.keys():
        if not specs.has(key): errors.append("Unknown property %s for %s." % [key, definition.get("display_name", "component")]); continue
        _validate_property_value(str(key), values[key], specs[key], errors)
    if not partial:
        for key in specs.keys():
            if not values.has(key): errors.append("Missing required component property: %s" % key)
    return errors


static func defaults_for(definition: Dictionary) -> Dictionary:
    var result: Dictionary = {}
    for key in definition.get("properties", {}).keys(): result[key] = definition["properties"][key].get("default")
    return result


static func _base(data: Dictionary, expected_type: String, id_field: String) -> Array[String]:
    var errors: Array[String] = []
    if data.get("document_type") != expected_type: errors.append("%s document_type is invalid." % expected_type)
    if int(data.get("schema_version", 0)) != SCHEMA_VERSION: errors.append("%s schema_version is unsupported." % expected_type)
    _require_id(data.get(id_field), "%s %s" % [expected_type, id_field], errors)
    return errors


static func _validate_property_spec(name: String, spec: Dictionary, errors: Array[String]) -> void:
    var type_name := str(spec.get("type", ""))
    if not PROPERTY_TYPES.has(type_name): errors.append("Component property %s has unsupported type %s." % [name, type_name]); return
    if not spec.has("default"): errors.append("Component property %s requires a default." % name); return
    if type_name == "enum":
        var options = spec.get("options", [])
        if not options is Array or options.is_empty(): errors.append("Enum property %s requires options." % name)
        elif not options.has(spec.get("default")): errors.append("Enum property %s default must be one of its options." % name)
    _validate_property_value(name, spec.get("default"), spec, errors)


static func _validate_property_value(name: String, value: Variant, spec: Dictionary, errors: Array[String]) -> void:
    var type_name := str(spec.get("type", ""))
    var valid := false
    match type_name:
        "bool": valid = value is bool
        "int": valid = value is int
        "float": valid = value is int or value is float
        "string": valid = value is String
        "enum": valid = spec.get("options", []).has(value)
        "vector3":
            valid = value is Array and value.size() == 3
            if valid:
                for part in value:
                    if not (part is int or part is float): valid = false; break
    if not valid: errors.append("Component property %s has an invalid %s value." % [name, type_name]); return
    if (type_name == "int" or type_name == "float") and (value is int or value is float):
        var numeric := float(value)
        if spec.has("min") and numeric < float(spec["min"]): errors.append("Component property %s is below its minimum." % name)
        if spec.has("max") and numeric > float(spec["max"]): errors.append("Component property %s exceeds its maximum." % name)


static func _validate_transform(value: Variant, label: String, errors: Array[String]) -> void:
    if not value is Dictionary: errors.append("%s must be a dictionary." % label); return
    for key in ["position", "rotation_degrees", "scale"]:
        var vector = value.get(key)
        if not vector is Array or vector.size() != 3: errors.append("%s.%s must contain three numbers." % [label, key]); continue
        for part in vector:
            if not (part is int or part is float): errors.append("%s.%s must contain only numbers." % [label, key]); break


static func _validate_id_array(value: Variant, label: String, errors: Array[String]) -> void:
    if not value is Array: errors.append("%s must be an array." % label); return
    var seen: Dictionary = {}
    for item in value:
        var id := str(item)
        _require_id(id, label, errors)
        if seen.has(id): errors.append("%s contains duplicate IDs." % label)
        seen[id] = true


static func _require_id(value: Variant, label: String, errors: Array[String]) -> void:
    if not StableId.is_valid(str(value)): errors.append("%s must be a stable UUID." % label)


static func _optional_id(value: Variant, label: String, errors: Array[String]) -> void:
    if value != null and not str(value).is_empty() and not StableId.is_valid(str(value)): errors.append("%s must be null or a stable UUID." % label)

class_name PlayWorldBuiltinVisualNodeLibrary
extends RefCounted

const DEFINITIONS := [
    {"key":"event.start","display_name":"Start","category":"Event","exec_inputs":[],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{}},
    {"key":"flow.branch","display_name":"Branch","category":"Flow","exec_inputs":["in"],"exec_outputs":["true","false"],"value_inputs":{"condition":"bool"},"value_outputs":{},"properties":{}},
    {"key":"flow.sequence","display_name":"Sequence","category":"Flow","exec_inputs":["in"],"exec_outputs":["then_0","then_1"],"value_inputs":{},"value_outputs":{},"properties":{}},
    {"key":"value.literal","display_name":"Literal","category":"Value","exec_inputs":[],"exec_outputs":[],"value_inputs":{},"value_outputs":{"value":"any"},"properties":{"value":null}},
    {"key":"math.add","display_name":"Add","category":"Math","exec_inputs":[],"exec_outputs":[],"value_inputs":{"a":"number","b":"number"},"value_outputs":{"value":"number"},"properties":{}},
    {"key":"math.subtract","display_name":"Subtract","category":"Math","exec_inputs":[],"exec_outputs":[],"value_inputs":{"a":"number","b":"number"},"value_outputs":{"value":"number"},"properties":{}},
    {"key":"math.multiply","display_name":"Multiply","category":"Math","exec_inputs":[],"exec_outputs":[],"value_inputs":{"a":"number","b":"number"},"value_outputs":{"value":"number"},"properties":{}},
    {"key":"math.divide","display_name":"Divide","category":"Math","exec_inputs":[],"exec_outputs":[],"value_inputs":{"a":"number","b":"number"},"value_outputs":{"value":"number"},"properties":{}},
    {"key":"logic.equal","display_name":"Equal","category":"Logic","exec_inputs":[],"exec_outputs":[],"value_inputs":{"a":"any","b":"any"},"value_outputs":{"value":"bool"},"properties":{}},
    {"key":"variable.get","display_name":"Get Variable","category":"Variables","exec_inputs":[],"exec_outputs":[],"value_inputs":{},"value_outputs":{"value":"any"},"properties":{"variable_id":""}},
    {"key":"variable.set","display_name":"Set Variable","category":"Variables","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"value":"any"},"value_outputs":{"value":"any"},"properties":{"variable_id":""}},
    {"key":"entity.get_position","display_name":"Get Position","category":"Entity","exec_inputs":[],"exec_outputs":[],"value_inputs":{"entity_id":"entity"},"value_outputs":{"position":"vector3"},"properties":{}},
    {"key":"entity.set_position","display_name":"Set Position","category":"Entity","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"entity_id":"entity","position":"vector3"},"value_outputs":{},"properties":{}},
    {"key":"environment.get_state","display_name":"Get Environment State","category":"Environment","exec_inputs":[],"exec_outputs":[],"value_inputs":{},"value_outputs":{"value":"any"},"properties":{}},
    {"key":"environment.set_time","display_name":"Set Time of Day","category":"Environment","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"hours":"number"},"value_outputs":{},"properties":{}},
    {"key":"environment.set_weather","display_name":"Set Weather","category":"Environment","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"weather_profile_id":"","transition_seconds":-1.0}},
    {"key":"environment.clear_weather","display_name":"Clear Weather Override","category":"Environment","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"transition_seconds":-1.0}},
    {"key":"gameplay.get_component_value","display_name":"Get Component Value","category":"Gameplay","exec_inputs":[],"exec_outputs":[],"value_inputs":{"entity_id":"entity"},"value_outputs":{"value":"any"},"properties":{"component_key":"health","property_name":"current_health"}},
    {"key":"gameplay.set_component_value","display_name":"Set Component Value","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"entity_id":"entity","value":"any"},"value_outputs":{},"properties":{"component_key":"health","property_name":"current_health"}},
    {"key":"gameplay.emit_event","display_name":"Emit Gameplay Event","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"event_key":"custom.event","source_entity_id":"","target_entity_id":"","payload":{}}},
    {"key":"gameplay.interact","display_name":"Interact","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"actor_entity_id":"entity","target_entity_id":"entity"},"value_outputs":{},"properties":{}},
    {"key":"gameplay.damage","display_name":"Apply Damage","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"target_entity_id":"entity","amount":"number"},"value_outputs":{},"properties":{"source_entity_id":""}},
    {"key":"gameplay.heal","display_name":"Heal","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"target_entity_id":"entity","amount":"number"},"value_outputs":{},"properties":{"source_entity_id":""}},
    {"key":"gameplay.start_dialogue","display_name":"Start Dialogue","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"dialogue_id":"","initiator_entity_id":""}},
    {"key":"gameplay.start_quest","display_name":"Start Quest","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"quest_id":""}},
    {"key":"gameplay.enter_vehicle","display_name":"Enter Vehicle","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"vehicle_entity_id":"entity","actor_entity_id":"entity"},"value_outputs":{},"properties":{"role":"passenger"}},
    {"key":"gameplay.save_slot","display_name":"Save Gameplay Slot","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"slot":"auto"}},
    {"key":"gameplay.load_slot","display_name":"Load Gameplay Slot","category":"Gameplay","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"slot":"auto"}},
    {"key":"macro.entry","display_name":"Macro Entry","category":"Macro","exec_inputs":[],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{}},
    {"key":"macro.return","display_name":"Macro Return","category":"Macro","exec_inputs":["in"],"exec_outputs":[],"value_inputs":{},"value_outputs":{},"properties":{}},
    {"key":"macro.call","display_name":"Call Macro","category":"Macro","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{},"value_outputs":{},"properties":{"macro_graph_id":""}},
    {"key":"debug.print","display_name":"Print","category":"Debug","exec_inputs":["in"],"exec_outputs":["next"],"value_inputs":{"value":"any"},"value_outputs":{},"properties":{}}
]

static func definitions() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for definition in DEFINITIONS: result.append(definition.duplicate(true))
    return result

static func keys() -> Array[String]:
    var result: Array[String] = []
    for definition in DEFINITIONS: result.append(str(definition["key"]))
    return result

static func has_key(type_key: String) -> bool:
    for definition in DEFINITIONS:
        if str(definition["key"]) == type_key: return true
    return false

static func get_definition(type_key: String) -> Dictionary:
    for definition in DEFINITIONS:
        if str(definition["key"]) == type_key: return definition.duplicate(true)
    return {}

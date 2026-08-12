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

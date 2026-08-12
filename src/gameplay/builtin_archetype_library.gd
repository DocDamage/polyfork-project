class_name PlayWorldBuiltinArchetypeLibrary
extends RefCounted

const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")
const Components = preload("res://src/gameplay/builtin_component_library.gd")

const IDS := {
    "door": "20000000-0000-4000-8000-000000000001",
    "loot_container": "20000000-0000-4000-8000-000000000002",
    "npc": "20000000-0000-4000-8000-000000000003",
    "enemy": "20000000-0000-4000-8000-000000000004",
    "vehicle": "20000000-0000-4000-8000-000000000005",
    "pickup": "20000000-0000-4000-8000-000000000006",
    "light": "20000000-0000-4000-8000-000000000007",
    "destructible_prop": "20000000-0000-4000-8000-000000000008",
    "quest_giver": "20000000-0000-4000-8000-000000000009"
}


static func definitions() -> Array[Dictionary]:
    return [
        _arch("door", "Door", ["door", "interactable", "collision", "save_state"], {
            Components.id_for("door"): {"open_angle": 90.0}
        }, ["interaction", "architecture"]),
        _arch("loot_container", "Loot Container", ["inventory_container", "interactable", "collision", "save_state"], {
            Components.id_for("inventory_container"): {"capacity": 24}
        }, ["inventory", "interaction"]),
        _arch("npc", "NPC", ["character_controller", "npc_brain", "dialogue_participant", "save_state"], {}, ["character", "dialogue"]),
        _arch("enemy", "Enemy", ["character_controller", "npc_brain", "health", "damageable", "save_state"], {
            Components.id_for("health"): {"max_health": 100.0, "current_health": 100.0}
        }, ["character", "combat"]),
        _arch("vehicle", "Vehicle", ["vehicle_body", "physics_prop", "collision", "save_state"], {}, ["vehicle", "physics"]),
        _arch("pickup", "Pickup", ["pickup", "interactable", "collision"], {}, ["inventory", "interaction"]),
        _arch("light", "Light", ["light_source"], {}, ["presentation"]),
        _arch("destructible_prop", "Destructible Prop", ["health", "damageable", "physics_prop", "collision", "save_state"], {
            Components.id_for("health"): {"max_health": 50.0, "current_health": 50.0}
        }, ["combat", "physics"]),
        _arch("quest_giver", "Quest Giver", ["character_controller", "npc_brain", "dialogue_participant", "quest_participant", "save_state"], {}, ["character", "dialogue", "quest"])
    ]


static func id_for(key: String) -> String: return str(IDS.get(key, ""))


static func _arch(key: String, display_name: String, component_keys: Array, defaults: Dictionary, tags: Array) -> Dictionary:
    var required: Array[String] = []
    for component_key in component_keys: required.append(Components.id_for(str(component_key)))
    return {
        "document_type": Contracts.ARCHETYPE,
        "schema_version": Contracts.SCHEMA_VERSION,
        "archetype_id": IDS[key],
        "key": key,
        "display_name": display_name,
        "description": "%s archetype preset." % display_name,
        "required_definition_ids": required,
        "component_defaults": defaults.duplicate(true),
        "tags": tags.duplicate()
    }

class_name PlayWorldBuiltinComponentLibrary
extends RefCounted

const Contracts = preload("res://src/gameplay/gameplay_contracts.gd")

const IDS := {
    "transform_metadata": "10000000-0000-4000-8000-000000000001",
    "collision": "10000000-0000-4000-8000-000000000002",
    "interactable": "10000000-0000-4000-8000-000000000003",
    "health": "10000000-0000-4000-8000-000000000004",
    "damageable": "10000000-0000-4000-8000-000000000005",
    "physics_prop": "10000000-0000-4000-8000-000000000006",
    "inventory_container": "10000000-0000-4000-8000-000000000007",
    "pickup": "10000000-0000-4000-8000-000000000008",
    "audio_emitter": "10000000-0000-4000-8000-000000000009",
    "light_source": "10000000-0000-4000-8000-00000000000a",
    "door": "10000000-0000-4000-8000-00000000000b",
    "seat": "10000000-0000-4000-8000-00000000000c",
    "vehicle_body": "10000000-0000-4000-8000-00000000000d",
    "character_controller": "10000000-0000-4000-8000-00000000000e",
    "npc_brain": "10000000-0000-4000-8000-00000000000f",
    "spawn_point": "10000000-0000-4000-8000-000000000010",
    "dialogue_participant": "10000000-0000-4000-8000-000000000011",
    "quest_participant": "10000000-0000-4000-8000-000000000012",
    "trigger_volume": "10000000-0000-4000-8000-000000000013",
    "save_state": "10000000-0000-4000-8000-000000000014",
    "network_identity_stub": "10000000-0000-4000-8000-000000000015"
}


static func definitions() -> Array[Dictionary]:
    return [
        _def("transform_metadata", "Transform Metadata", "Core", {
            "editor_label": _string(""),
            "tags": _string("")
        }),
        _def("collision", "Collision", "Physics", {
            "shape": _enum("box", ["box", "sphere", "capsule", "mesh"]),
            "layer": _int(1, 1, 32),
            "mask": _int(1, 0, 2147483647)
        }),
        _def("interactable", "Interactable", "Interaction", {
            "enabled": _bool(true),
            "prompt": _string("Interact"),
            "interaction_distance": _float(2.5, 0.1, 100.0)
        }),
        _def("health", "Health", "Gameplay", {
            "max_health": _float(100.0, 1.0, 1000000.0),
            "current_health": _float(100.0, 0.0, 1000000.0)
        }),
        _def("damageable", "Damageable", "Gameplay", {
            "armor": _float(0.0, 0.0, 1000000.0),
            "invulnerable": _bool(false)
        }, [IDS.health]),
        _def("physics_prop", "Physics Prop", "Physics", {
            "mass": _float(1.0, 0.01, 1000000.0),
            "frozen": _bool(false)
        }, [IDS.collision], [], "physics_prop"),
        _def("inventory_container", "Inventory Container", "Inventory", {
            "capacity": _int(16, 1, 10000),
            "locked": _bool(false)
        }),
        _def("pickup", "Pickup", "Inventory", {
            "quantity": _int(1, 1, 100000),
            "auto_collect": _bool(false)
        }, [IDS.interactable, IDS.collision]),
        _def("audio_emitter", "Audio Emitter", "Presentation", {
            "volume_db": _float(0.0, -80.0, 24.0),
            "autoplay": _bool(false),
            "spatial": _bool(true)
        }),
        _def("light_source", "Light Source", "Presentation", {
            "energy": _float(1.0, 0.0, 100.0),
            "range": _float(10.0, 0.0, 10000.0),
            "kind": _enum("omni", ["omni", "spot", "directional"])
        }),
        _def("door", "Door", "Interaction", {
            "open_angle": _float(90.0, -180.0, 180.0),
            "starts_open": _bool(false),
            "locked": _bool(false)
        }, [IDS.interactable, IDS.collision]),
        _def("seat", "Seat", "Vehicles", {
            "role": _enum("passenger", ["driver", "passenger", "custom"]),
            "occupancy_limit": _int(1, 1, 8)
        }, [IDS.interactable]),
        _def("vehicle_body", "Vehicle Body", "Vehicles", {
            "max_speed": _float(24.0, 0.0, 1000.0),
            "seat_count": _int(1, 1, 64)
        }, [IDS.physics_prop, IDS.collision]),
        _def("character_controller", "Character Controller", "Characters", {
            "move_speed": _float(5.0, 0.0, 100.0),
            "jump_enabled": _bool(true),
            "jump_strength": _float(5.0, 0.0, 100.0)
        }, [IDS.collision], [IDS.physics_prop]),
        _def("npc_brain", "NPC Brain", "Characters", {
            "profile": _string("default"),
            "enabled": _bool(true)
        }, [IDS.character_controller]),
        _def("spawn_point", "Spawn Point", "World", {
            "spawn_tag": _string("default"),
            "enabled": _bool(true)
        }),
        _def("dialogue_participant", "Dialogue Participant", "Narrative", {
            "speaker_name": _string("Character"),
            "voice_profile": _string("")
        }),
        _def("quest_participant", "Quest Participant", "Narrative", {
            "quest_tag": _string("default"),
            "enabled": _bool(true)
        }),
        _def("trigger_volume", "Trigger Volume", "Interaction", {
            "one_shot": _bool(false),
            "enabled": _bool(true)
        }, [IDS.collision]),
        _def("save_state", "Save State", "Core", {
            "persist": _bool(true),
            "scope": _enum("world", ["world", "session"])
        }),
        _def("network_identity_stub", "Network Identity Stub", "Core", {
            "authority_mode": _enum("owner", ["server", "owner", "local"]),
            "replication_enabled": _bool(false)
        })
    ]


static func id_for(key: String) -> String: return str(IDS.get(key, ""))


static func _def(key: String, display_name: String, category: String, properties: Dictionary, dependencies: Array = [], conflicts: Array = [], runtime_hook: String = "") -> Dictionary:
    return {
        "document_type": Contracts.COMPONENT_DEFINITION,
        "schema_version": Contracts.SCHEMA_VERSION,
        "definition_id": IDS[key],
        "key": key,
        "display_name": display_name,
        "category": category,
        "description": "%s component foundation." % display_name,
        "properties": properties,
        "dependencies": dependencies.duplicate(),
        "conflicts": conflicts.duplicate(),
        "runtime_hook": runtime_hook
    }


static func _bool(value: bool) -> Dictionary: return {"type": "bool", "default": value}
static func _string(value: String) -> Dictionary: return {"type": "string", "default": value}
static func _int(value: int, minimum: int, maximum: int) -> Dictionary: return {"type": "int", "default": value, "min": minimum, "max": maximum}
static func _float(value: float, minimum: float, maximum: float) -> Dictionary: return {"type": "float", "default": value, "min": minimum, "max": maximum}
static func _enum(value: String, options: Array) -> Dictionary: return {"type": "enum", "default": value, "options": options.duplicate()}

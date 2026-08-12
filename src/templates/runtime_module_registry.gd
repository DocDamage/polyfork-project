class_name PlayWorldRuntimeModuleRegistry
extends RefCounted

const MODULES := {
    "core.world": {"phase": 2, "description": "Persistent authored world foundation"},
    "core.terrain": {"phase": 5, "description": "Terrain and world partition runtime"},
    "core.semantic_input": {"phase": 7, "description": "Semantic gameplay input layer"},
    "phase6.gameplay": {"phase": 6, "description": "Components, archetypes, prefabs, sockets"},
    "play.third_person": {"phase": 7, "description": "Reusable third-person instant-play controller"},
    "play.first_person": {"phase": 7, "description": "Reusable first-person instant-play controller"},
    "ui.basic": {"phase": 1, "description": "Existing workspace UI foundation"},
    "phase10.inventory": {"phase": 10, "description": "Inventory, items, containers, transfers, and pickups"},
    "phase10.health": {"phase": 10, "description": "Health, damage, healing, and death runtime"},
    "phase10.narrative": {"phase": 10, "description": "Dialogue and quest runtime scaffolding"},
    "phase10.vehicle": {"phase": 10, "description": "Vehicle, seat, occupancy, and driving runtime semantics"},
    "phase15.multiplayer": {"phase": 15, "description": "Host-authoritative multiplayer runtime and session contracts"}
}

func resolve(required_modules: Array) -> Dictionary:
    var resolved: Array[String] = []
    var missing: Array[String] = []
    var seen: Dictionary = {}
    for item in required_modules:
        var module_id := str(item)
        if seen.has(module_id): continue
        seen[module_id] = true
        if MODULES.has(module_id): resolved.append(module_id)
        else: missing.append(module_id)
    if not missing.is_empty():
        missing.sort()
        return {"ok": false, "errors": ["Missing required runtime modules: %s" % ", ".join(missing)], "missing": missing, "resolved": resolved}
    return {"ok": true, "errors": [], "missing": [], "resolved": resolved}

func has_module(module_id: String) -> bool: return MODULES.has(module_id)

func available_modules() -> Array[String]:
    var result: Array[String] = []
    for module_id in MODULES.keys(): result.append(str(module_id))
    result.sort()
    return result

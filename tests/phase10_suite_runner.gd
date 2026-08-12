extends SceneTree

const Foundation = preload("res://tests/unit/phase10_runtime_gameplay_contracts.gd")
const Inventory = preload("res://tests/unit/phase10_inventory_interaction_contracts.gd")
const Health = preload("res://tests/unit/phase10_health_damage_contracts.gd")
const NpcAi = preload("res://tests/unit/phase10_npc_ai_contracts.gd")
const Dialogue = preload("res://tests/unit/phase10_dialogue_contracts.gd")
const Quest = preload("res://tests/unit/phase10_quest_contracts.gd")
const Vehicle = preload("res://tests/unit/phase10_vehicle_contracts.gd")

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var suite := OS.get_environment("PHASE10_SUITE")
    var errors: Array[String] = []
    match suite:
        "foundation": errors.append_array(Foundation.run_checks())
        "inventory": errors.append_array(Inventory.run_checks())
        "health": errors.append_array(Health.run_checks())
        "npc": errors.append_array(NpcAi.run_checks())
        "dialogue": errors.append_array(Dialogue.run_checks())
        "quest": errors.append_array(Quest.run_checks())
        "vehicle": errors.append_array(Vehicle.run_checks())
        _: errors.append("Unknown Phase 10 suite: %s" % suite)
    if errors.is_empty():
        print("PASS: Phase 10 %s contract suite completed." % suite)
        quit(0)
        return
    for item in errors:
        push_error(item)
    quit(1)

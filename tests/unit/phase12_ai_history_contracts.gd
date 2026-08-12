extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const HistoryRepository = preload("res://src/ai/ai_history_repository.gd")

static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    var project_id: String = StableId.generate()
    var asset_id: String = StableId.generate()
    var root_dir: String = "user://tests/phase12/history-reopen-%s" % StableId.generate()
    var repository = HistoryRepository.new(root_dir)
    var open_result: Dictionary = repository.open_or_create(project_id)
    if not open_result.get("ok", false): return ["AI history reopen fixture could not create history: %s" % open_result.get("errors", [])]
    var execution_id: String = StableId.generate()
    var entry: Dictionary = {
        "execution_id": execution_id,
        "request_id": StableId.generate(),
        "proposal_id": StableId.generate(),
        "provider_id": "history-provider",
        "mode": "execute",
        "summary": "Persist and reopen",
        "source_asset_ids": [asset_id],
        "action_count": 2,
        "timestamp_unix": int(Time.get_unix_time_from_system()),
        "active": true,
        "status": "applied",
        "prompt": "credential-free prompt",
    }
    if not repository.append(entry).get("ok", false): errors.append("AI history repository must persist a valid execution entry.")
    var reopened = HistoryRepository.new(root_dir)
    var reopen_result: Dictionary = reopened.open_or_create(project_id)
    if not reopen_result.get("ok", false): errors.append("AI execution history must reopen after save: %s" % reopen_result.get("errors", []))
    else:
        var restored: Dictionary = reopened.get_entry(execution_id)
        if restored.is_empty() or str(restored.get("status", "")) != "applied": errors.append("Reopened AI history must retain execution identity and status.")
        if restored.get("source_asset_ids", []) != [asset_id]: errors.append("Reopened AI history must retain exact source Asset Library IDs.")
    var file := FileAccess.open(reopened.get_path(), FileAccess.READ)
    var serialized: String = file.get_as_text() if file != null else ""
    if serialized.contains("api_key") or serialized.contains("Authorization: Bearer") or serialized.contains("sk-"): errors.append("Project-managed AI history must not contain credential-shaped provider fields.")

    var wrong_project = HistoryRepository.new(root_dir)
    if wrong_project.open_or_create(StableId.generate()).get("ok", false): errors.append("AI history must reject reopening under a different project identity.")

    var corrupt_file := FileAccess.open(reopened.get_path(), FileAccess.WRITE)
    if corrupt_file == null: errors.append("AI history corruption fixture could not open history file for replacement.")
    else:
        corrupt_file.store_string("{ definitely not valid json")
        corrupt_file.close()
        var corrupted = HistoryRepository.new(root_dir)
        if corrupted.open_or_create(project_id).get("ok", false): errors.append("Corrupt AI execution history must fail safely instead of being silently replaced.")
    return errors

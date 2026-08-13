class_name PlayWorldAssetSemanticSearch
extends RefCounted

const SYNONYMS := {
    "car": ["vehicle", "auto", "automobile", "driving"],
    "vehicle": ["car", "truck", "auto", "driving"],
    "tree": ["foliage", "plant", "forest", "vegetation"],
    "foliage": ["tree", "plant", "grass", "vegetation"],
    "house": ["home", "building", "structure", "residential"],
    "building": ["house", "structure", "architecture"],
    "road": ["street", "path", "spline", "highway"],
    "water": ["river", "lake", "ocean", "sea"],
    "rock": ["stone", "boulder", "cliff"],
    "character": ["person", "human", "npc", "actor"],
    "weapon": ["gun", "rifle", "pistol", "sword", "melee"],
    "door": ["gate", "entrance", "portal"],
    "container": ["crate", "chest", "box", "storage"],
}

func rank(records: Array[Dictionary], query: String) -> Array[Dictionary]:
    var clean := query.strip_edges().to_lower()
    if clean.is_empty(): return records.duplicate(true)
    var query_tokens := _expanded_tokens(_tokens(clean))
    var scored: Array[Dictionary] = []
    for record in records:
        var text := _record_text(record)
        var score := _score(text, clean, query_tokens)
        if score <= 0.0: continue
        var copy := record.duplicate(true)
        copy["search_score"] = score
        scored.append(copy)
    scored.sort_custom(func(a, b):
        var a_score := float(a.get("search_score", 0.0)); var b_score := float(b.get("search_score", 0.0))
        if not is_equal_approx(a_score, b_score): return a_score > b_score
        return str(a.get("display_name", "")).naturalnocasecmp_to(str(b.get("display_name", ""))) < 0)
    return scored

func _score(text: String, phrase: String, query_tokens: Dictionary) -> float:
    var score := 0.0
    if text.contains(phrase): score += 100.0
    var record_tokens := _tokens(text)
    var record_set: Dictionary = {}
    for token in record_tokens: record_set[token] = true
    for token in query_tokens.keys():
        var weight := float(query_tokens[token])
        if record_set.has(token): score += 20.0 * weight; continue
        for candidate in record_set.keys():
            if str(candidate).begins_with(str(token)) or str(token).begins_with(str(candidate)):
                score += 8.0 * weight; break
    return score

func _record_text(record: Dictionary) -> String:
    var parts: Array[String] = [str(record.get("display_name", "")), str(record.get("relative_path", "")), str(record.get("asset_type", ""))]
    for value in record.get("collections", []): parts.append(str(value))
    var analysis: Dictionary = record.get("analysis", {})
    var metadata: Dictionary = analysis.get("metadata", {})
    for key in metadata.keys():
        parts.append(str(key))
        var value: Variant = metadata[key]
        if value is Array:
            for item in value: parts.append(str(item))
        elif not value is Dictionary: parts.append(str(value))
    return " ".join(parts).to_lower()

func _expanded_tokens(base_tokens: Array[String]) -> Dictionary:
    var result: Dictionary = {}
    for token in base_tokens:
        result[token] = 1.0
        for synonym in SYNONYMS.get(token, []):
            if not result.has(str(synonym)): result[str(synonym)] = 0.55
    return result

static func _tokens(value: String) -> Array[String]:
    var normalized := value.to_lower()
    for separator in ["/", "\\", "_", "-", ".", ",", ":", ";", "(", ")", "[", "]"]: normalized = normalized.replace(separator, " ")
    var result: Array[String] = []
    for token in normalized.split(" ", false):
        var clean := str(token).strip_edges()
        if clean.length() >= 2 and not result.has(clean): result.append(clean)
    return result

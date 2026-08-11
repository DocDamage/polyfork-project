class_name PlayWorldProfile
extends RefCounted

const SMALL: StringName = &"small"
const MEDIUM: StringName = &"medium"
const LARGE: StringName = &"large"

const _PROFILES := {
    SMALL: {
        "id": "small",
        "label": "Small",
        "min_km2": 1.0,
        "max_km2": 2.0,
        "streaming": false,
        "recommended": false
    },
    MEDIUM: {
        "id": "medium",
        "label": "Medium",
        "min_km2": 4.0,
        "max_km2": 16.0,
        "streaming": false,
        "recommended": true
    },
    LARGE: {
        "id": "large",
        "label": "Large",
        "min_km2": 16.0,
        "max_km2": null,
        "streaming": true,
        "recommended": false
    }
}


static func ids() -> Array[StringName]:
    return [SMALL, MEDIUM, LARGE]


static func is_valid(profile_id: StringName) -> bool:
    return _PROFILES.has(profile_id)


static func get_profile(profile_id: StringName) -> Dictionary:
    if not is_valid(profile_id):
        return {}
    return _PROFILES[profile_id].duplicate(true)


static func default_profile() -> Dictionary:
    return get_profile(MEDIUM)


static func validate(profile: Dictionary) -> Array[String]:
    var errors: Array[String] = []
    var profile_id := StringName(str(profile.get("id", "")))
    if not is_valid(profile_id):
        errors.append("World profile id is not recognized.")
        return errors

    var canonical := get_profile(profile_id)
    for key in ["label", "min_km2", "max_km2", "streaming", "recommended"]:
        if profile.get(key) != canonical.get(key):
            errors.append("World profile field '%s' does not match the canonical contract." % key)
    return errors

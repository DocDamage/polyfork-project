extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const WorldProfile = preload("res://src/world/world_profile.gd")


static func run_checks() -> Array[String]:
    var errors: Array[String] = []
    _check_stable_ids(errors)
    _check_world_profiles(errors)
    return errors


static func _check_stable_ids(errors: Array[String]) -> void:
    var generated := StableId.generate()
    if not StableId.is_valid(generated):
        errors.append("Generated stable ID must be a valid lowercase UUID v4.")

    var second := StableId.generate()
    if second == generated:
        errors.append("Two independently generated stable IDs must not be identical.")

    var valid_fixture := "8f40c45e-326e-4e4b-9c78-8b35f11fa2aa"
    if not StableId.is_valid(valid_fixture):
        errors.append("Known UUID v4 fixture must validate.")

    for invalid in [
        "",
        "00000000-0000-0000-0000-000000000000",
        "8F40C45E-326E-4E4B-9C78-8B35F11FA2AA",
        "8f40c45e326e4e4b9c788b35f11fa2aa",
        "8f40c45e-326e-3e4b-9c78-8b35f11fa2aa",
        "8f40c45e-326e-4e4b-7c78-8b35f11fa2aa"
    ]:
        if StableId.is_valid(invalid):
            errors.append("Invalid stable ID fixture was accepted: %s" % invalid)


static func _check_world_profiles(errors: Array[String]) -> void:
    var ids := WorldProfile.ids()
    if ids != [&"small", &"medium", &"large"]:
        errors.append("World profiles must remain ordered Small, Medium, Large.")

    var small := WorldProfile.get_profile(&"small")
    var medium := WorldProfile.get_profile(&"medium")
    var large := WorldProfile.get_profile(&"large")

    if small.get("min_km2") != 1.0 or small.get("max_km2") != 2.0 or small.get("streaming"):
        errors.append("Small profile must remain 1–2 km² and non-streamed.")
    if medium.get("min_km2") != 4.0 or medium.get("max_km2") != 16.0 or not medium.get("recommended"):
        errors.append("Medium profile must remain 4–16 km² and recommended.")
    if large.get("min_km2") != 16.0 or large.get("max_km2") != null or not large.get("streaming"):
        errors.append("Large profile must begin at 16 km² and require streaming.")

    for profile_id in ids:
        var profile := WorldProfile.get_profile(profile_id)
        errors.append_array(WorldProfile.validate(profile))

    if not WorldProfile.get_profile(&"unknown").is_empty():
        errors.append("Unknown world profile lookup must fail closed.")

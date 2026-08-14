class_name PlayWorldProductIdentity
extends RefCounted

const PRODUCT_NAME := "PlayWorld Studio"
const COMPANY_NAME := "PlayWorld Studio"
const VERSION := "0.2.0"
const CHANNEL := "stable"
const PACKAGE_PREFIX := "PlayWorld-Studio"
const PLATFORM := "Windows"
const ARCHITECTURE := "x86_64"
const GODOT_VERSION := "4.7.1"
const BASE_COMMIT := "ebeb35e28f53738c63d35429eba1ea40b5c8cdb1"
const DATA_SCHEMA_VERSION := 1
const UPDATER_SCHEMA_VERSION := 1

static func version() -> String:
    return str(ProjectSettings.get_setting("application/config/version", VERSION))

static func channel() -> String:
    var manifest := _packaged_manifest()
    var packaged := str(manifest.get("channel", ""))
    return packaged if packaged in ["stable", "beta", "development"] else str(ProjectSettings.get_setting("playworld/release/channel", CHANNEL))

static func source_commit() -> String:
    var manifest := _packaged_manifest()
    var packaged := str(manifest.get("source_commit", ""))
    return packaged if _lower_hex(packaged, 40) else str(ProjectSettings.get_setting("playworld/release/source_commit", BASE_COMMIT))

static func package_name() -> String:
    return "%s-%s-Windows-x64" % [PACKAGE_PREFIX, version()]

static func summary() -> Dictionary:
    return {
        "product_name": PRODUCT_NAME,
        "company_name": COMPANY_NAME,
        "version": version(),
        "channel": channel(),
        "platform": PLATFORM,
        "architecture": ARCHITECTURE,
        "godot_version": GODOT_VERSION,
        "base_commit": BASE_COMMIT,
        "source_commit": source_commit(),
        "package_name": package_name(),
        "data_schema_version": DATA_SCHEMA_VERSION,
        "updater_schema_version": UPDATER_SCHEMA_VERSION,
    }

static func short_commit() -> String:
    return source_commit().substr(0, mini(12, source_commit().length()))

static func _packaged_manifest() -> Dictionary:
    var path := OS.get_executable_path().get_base_dir().path_join("release_manifest.json")
    if not FileAccess.file_exists(path): return {}
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary or str(value.get("product_name", "")) != PRODUCT_NAME: return {}
    return value

static func _lower_hex(value: String, expected_length: int) -> bool:
    if value.length() != expected_length: return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)): return false
    return true

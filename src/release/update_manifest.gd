class_name PlayWorldUpdateManifest
extends RefCounted

const SemanticVersion = preload("res://src/release/semantic_version.gd")
const PRODUCT_NAME := "PlayWorld Studio"
const CHANNELS := ["stable", "beta", "development"]
const KINDS := ["portable", "installer"]
const MAX_MANIFEST_BYTES := 1048576
const MAX_NOTES_BYTES := 65536
const MAX_ARTIFACT_BYTES := 8589934592

static func validate_text(text: String, registry: Dictionary, current_version: String, channel: String, install_mode: String, allow_downgrade: bool = false, now_unix: int = -1) -> Dictionary:
    if text.to_utf8_buffer().size() > MAX_MANIFEST_BYTES:
        return _failure("Update manifest exceeds the maximum accepted size.")
    var value: Variant = JSON.parse_string(text)
    if not value is Dictionary:
        return _failure("Update manifest is not a JSON object.")
    return validate_envelope(value, registry, current_version, channel, install_mode, allow_downgrade, now_unix)

static func validate_envelope(envelope: Dictionary, registry: Dictionary, current_version: String, channel: String, install_mode: String, allow_downgrade: bool = false, now_unix: int = -1) -> Dictionary:
    var shape := _shape(envelope, ["schema_version", "algorithm", "key_id", "payload_encoding", "payload", "signature"], [])
    if not shape.get("ok", false): return shape
    if int(envelope.get("schema_version", -1)) != 1: return _failure("Update manifest envelope schema is unsupported.")
    if str(envelope.get("algorithm", "")) != "rsa-sha256": return _failure("Update manifest signature algorithm is unsupported.")
    if str(envelope.get("payload_encoding", "")) != "base64-json": return _failure("Update manifest payload encoding is unsupported.")
    if not CHANNELS.has(channel): return _failure("Selected update channel is invalid.")
    if install_mode not in ["portable", "installed"]: return _failure("Install mode is invalid.")
    if not SemanticVersion.parse(current_version).get("ok", false): return _failure("Current application version is invalid.")
    var key_result := _trusted_key(registry, str(envelope.get("key_id", "")), channel, now_unix)
    if not key_result.get("ok", false): return key_result
    var payload_b64 := str(envelope.get("payload", ""))
    var signature_b64 := str(envelope.get("signature", ""))
    var payload_bytes := Marshalls.base64_to_raw(payload_b64)
    var signature_bytes := Marshalls.base64_to_raw(signature_b64)
    if payload_bytes.is_empty() or signature_bytes.is_empty(): return _failure("Update manifest payload or signature is invalid base64.")
    if Marshalls.raw_to_base64(payload_bytes) != payload_b64 or Marshalls.raw_to_base64(signature_bytes) != signature_b64:
        return _failure("Update manifest base64 is not canonical.")
    var key := CryptoKey.new()
    if key.load_from_string(str(key_result.get("key", {}).get("public_key_pem", "")), true) != OK:
        return _failure("Trusted update key could not be loaded.")
    if not Crypto.new().verify(HashingContext.HASH_SHA256, payload_bytes.sha256_buffer(), signature_bytes, key):
        return _failure("Update manifest signature verification failed.")
    var payload_text := payload_bytes.get_string_from_utf8()
    if payload_text.to_utf8_buffer() != payload_bytes: return _failure("Update manifest payload is not canonical UTF-8.")
    var payload_value: Variant = JSON.parse_string(payload_text)
    if not payload_value is Dictionary: return _failure("Signed update payload is not a JSON object.")
    var payload: Dictionary = payload_value
    var payload_result := _validate_payload(payload, current_version, channel, install_mode, allow_downgrade)
    if not payload_result.get("ok", false): return payload_result
    return {"ok": true, "errors": [], "key_id": str(envelope.get("key_id", "")), "payload": payload.duplicate(true), "artifact": payload_result.get("artifact", {}).duplicate(true), "is_update": true}

static func load_registry(path: String = "res://config/release/update_keys.json") -> Dictionary:
    if not FileAccess.file_exists(path): return _failure("Trusted update-key registry is missing.")
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary: return _failure("Trusted update-key registry is malformed.")
    if int(value.get("schema_version", -1)) != 1 or not value.get("keys", []) is Array: return _failure("Trusted update-key registry schema is invalid.")
    return {"ok": true, "errors": [], "registry": value}

static func _validate_payload(payload: Dictionary, current_version: String, channel: String, install_mode: String, allow_downgrade: bool) -> Dictionary:
    var shape := _shape(payload, ["schema_version", "product_name", "version", "channel", "published_at_unix", "minimum_updater_version", "release_notes", "source_commit", "data_schema_version", "artifacts"], ["extensions"])
    if not shape.get("ok", false): return shape
    if int(payload.get("schema_version", -1)) != 1: return _failure("Signed update payload schema is unsupported.")
    if str(payload.get("product_name", "")) != PRODUCT_NAME: return _failure("Update manifest targets a different product.")
    var version := str(payload.get("version", ""))
    var parsed_version := SemanticVersion.parse(version)
    if not parsed_version.get("ok", false): return _failure("Update manifest version is invalid.")
    if str(payload.get("channel", "")) != channel: return _failure("Update manifest channel does not match the selected channel.")
    if channel == "stable" and not Array(parsed_version.get("prerelease", [])).is_empty(): return _failure("Stable manifests may not publish prerelease versions.")
    if not SemanticVersion.is_supported_upgrade(current_version, version, allow_downgrade): return _failure("Update manifest is not a permitted version transition.")
    var minimum := str(payload.get("minimum_updater_version", ""))
    if not SemanticVersion.parse(minimum).get("ok", false) or SemanticVersion.compare(current_version, minimum) < 0: return _failure("This update requires a newer updater version.")
    if not _whole(payload.get("published_at_unix")) or int(payload.get("published_at_unix", 0)) <= 0: return _failure("Update publication time is invalid.")
    if not _whole(payload.get("data_schema_version")) or int(payload.get("data_schema_version", 0)) < 1: return _failure("Update data schema version is invalid.")
    var notes := str(payload.get("release_notes", ""))
    if notes.strip_edges().is_empty() or notes.to_utf8_buffer().size() > MAX_NOTES_BYTES: return _failure("Update release notes are missing or too large.")
    if not _lower_hex(str(payload.get("source_commit", "")), 40): return _failure("Update source commit identity is invalid.")
    var artifacts: Variant = payload.get("artifacts", [])
    if not artifacts is Array or artifacts.is_empty() or artifacts.size() > KINDS.size(): return _failure("Update artifact inventory is invalid.")
    var seen: Dictionary = {}
    var selected: Dictionary = {}
    for artifact_value in artifacts:
        if not artifact_value is Dictionary: return _failure("Update artifact entries must be objects.")
        var artifact: Dictionary = artifact_value
        var result := _artifact(artifact)
        if not result.get("ok", false): return result
        var kind := str(artifact.get("kind", ""))
        if seen.has(kind): return _failure("Update artifact inventory contains duplicate kinds.")
        seen[kind] = true
        if (install_mode == "portable" and kind == "portable") or (install_mode == "installed" and kind == "installer"): selected = artifact.duplicate(true)
    if selected.is_empty(): return _failure("Update manifest does not contain an artifact for this installation mode.")
    return {"ok": true, "errors": [], "artifact": selected}

static func _artifact(artifact: Dictionary) -> Dictionary:
    var shape := _shape(artifact, ["kind", "platform", "architecture", "filename", "url", "size", "sha256"], ["release_manifest_sha256", "extensions"])
    if not shape.get("ok", false): return shape
    var kind := str(artifact.get("kind", ""))
    if not KINDS.has(kind): return _failure("Update artifact kind is invalid.")
    if str(artifact.get("platform", "")) != "Windows" or str(artifact.get("architecture", "")) != "x86_64": return _failure("Update artifact target is unsupported.")
    var filename := str(artifact.get("filename", ""))
    if not _safe_filename(filename): return _failure("Update artifact filename is unsafe.")
    if kind == "portable" and not filename.to_lower().ends_with(".zip"): return _failure("Portable update artifact must be a ZIP.")
    if kind == "installer" and not filename.to_lower().ends_with(".exe"): return _failure("Installed update artifact must be an executable installer.")
    if not _https(str(artifact.get("url", ""))): return _failure("Update artifact URL must use bounded HTTPS.")
    if not _whole(artifact.get("size")): return _failure("Update artifact size is invalid.")
    var size := int(artifact.get("size", 0))
    if size <= 0 or size > MAX_ARTIFACT_BYTES: return _failure("Update artifact size is outside accepted bounds.")
    if not _lower_hex(str(artifact.get("sha256", "")), 64): return _failure("Update artifact SHA-256 is invalid.")
    if artifact.has("release_manifest_sha256") and not _lower_hex(str(artifact.get("release_manifest_sha256", "")), 64): return _failure("Update release-manifest SHA-256 is invalid.")
    return {"ok": true, "errors": []}

static func _trusted_key(registry: Dictionary, key_id: String, channel: String, now_unix: int) -> Dictionary:
    if key_id.is_empty() or not registry.get("keys", []) is Array: return _failure("Update signing key registry is invalid.")
    var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
    for value in registry.get("keys", []):
        if not value is Dictionary: continue
        var record: Dictionary = value
        if str(record.get("key_id", "")) != key_id: continue
        if str(record.get("algorithm", "")) != "rsa-sha256": return _failure("Trusted update key algorithm is unsupported.")
        if not bool(record.get("enabled", false)) or bool(record.get("revoked", false)): return _failure("Update signing key is disabled or revoked.")
        if not record.get("channels", []) is Array or not record.get("channels", []).has(channel): return _failure("Update signing key is not trusted for this channel.")
        if int(record.get("not_before_unix", 0)) > 0 and now < int(record.get("not_before_unix", 0)): return _failure("Update signing key is not active yet.")
        if int(record.get("not_after_unix", 0)) > 0 and now > int(record.get("not_after_unix", 0)): return _failure("Update signing key has expired.")
        if not str(record.get("public_key_pem", "")).contains("BEGIN PUBLIC KEY"): return _failure("Trusted update key has no public PEM data.")
        return {"ok": true, "errors": [], "key": record.duplicate(true)}
    return _failure("Update manifest signing key is not trusted.")

static func _shape(value: Dictionary, required: Array[String], optional: Array[String]) -> Dictionary:
    for key in required:
        if not value.has(key): return _failure("Update manifest field is missing: %s" % key)
    for value_key in value.keys():
        var key := str(value_key)
        if not required.has(key) and not optional.has(key): return _failure("Update manifest contains an unsupported field: %s" % key)
    return {"ok": true, "errors": []}

static func _whole(value: Variant) -> bool:
    if value is int: return true
    return value is float and is_equal_approx(float(value), float(int(value)))

static func _lower_hex(value: String, expected_length: int) -> bool:
    if value.length() != expected_length: return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)): return false
    return true

static func _safe_filename(value: String) -> bool:
    if value.is_empty() or value.length() > 200 or value in [".", ".."] or value.contains("..") or value.ends_with(".") or value.ends_with(" "): return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code in [45, 46, 95]): return false
    return true

static func _https(value: String) -> bool:
    if value.length() < 12 or value.length() > 2048 or not value.begins_with("https://"): return false
    if value.contains("\\") or value.contains("\r") or value.contains("\n") or value.contains("\t") or value.contains(" "): return false
    var tail := value.substr(8)
    var slash := tail.find("/")
    var authority := tail if slash < 0 else tail.substr(0, slash)
    return not authority.is_empty() and not authority.contains("@") and not authority.begins_with(".") and not authority.ends_with(".") and (authority.contains(".") or authority == "localhost")

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}

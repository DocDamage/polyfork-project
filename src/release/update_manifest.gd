class_name PlayWorldUpdateManifest
extends RefCounted

const SemanticVersion = preload("res://src/release/semantic_version.gd")
const PRODUCT_NAME := "PlayWorld Studio"
const CHANNELS := ["stable", "beta", "development"]
const KINDS := ["portable", "installer"]
const MAX_MANIFEST_BYTES := 1048576
const MAX_NOTES_BYTES := 65536
const MAX_ARTIFACT_BYTES := 8589934592
const MAX_FUTURE_SKEW_SECONDS := 86400

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
    var registry_result := validate_registry(registry)
    if not registry_result.get("ok", false): return registry_result
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
    var digest_context := HashingContext.new()
    if digest_context.start(HashingContext.HASH_SHA256) != OK: return _failure("Update manifest hashing could not start.")
    if digest_context.update(payload_bytes) != OK: return _failure("Update manifest hashing failed.")
    var payload_digest := digest_context.finish()
    if not Crypto.new().verify(HashingContext.HASH_SHA256, payload_digest, signature_bytes, key):
        return _failure("Update manifest signature verification failed.")
    var payload_text := payload_bytes.get_string_from_utf8()
    if payload_text.to_utf8_buffer() != payload_bytes: return _failure("Update manifest payload is not canonical UTF-8.")
    var payload_value: Variant = JSON.parse_string(payload_text)
    if not payload_value is Dictionary: return _failure("Signed update payload is not a JSON object.")
    var payload: Dictionary = payload_value
    var payload_result := _validate_payload(payload, current_version, channel, install_mode, allow_downgrade, now_unix)
    if not payload_result.get("ok", false): return payload_result
    return {
        "ok": true,
        "errors": [],
        "key_id": str(envelope.get("key_id", "")),
        "payload": payload.duplicate(true),
        "artifact": (payload_result.get("artifact", {}) as Dictionary).duplicate(true),
        "is_update": bool(payload_result.get("is_update", false)),
    }

static func load_registry(path: String = "res://config/release/update_keys.json") -> Dictionary:
    if not FileAccess.file_exists(path): return _failure("Trusted update-key registry is missing.")
    var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not value is Dictionary: return _failure("Trusted update-key registry is malformed.")
    var validation := validate_registry(value)
    if not validation.get("ok", false): return validation
    return {"ok": true, "errors": [], "registry": value}

static func validate_registry(registry: Dictionary) -> Dictionary:
    var shape := _shape(registry, ["schema_version", "keys"], ["policy"])
    if not shape.get("ok", false): return shape
    if int(registry.get("schema_version", -1)) != 1: return _failure("Trusted update-key registry schema is invalid.")
    var keys: Variant = registry.get("keys", [])
    if not keys is Array: return _failure("Trusted update-key registry keys must be an array.")
    var seen: Dictionary = {}
    for value in keys:
        if not value is Dictionary: return _failure("Trusted update-key records must be objects.")
        var record: Dictionary = value
        var record_shape := _shape(record, ["key_id", "algorithm", "enabled", "revoked", "channels", "not_before_unix", "not_after_unix", "public_key_pem"], ["comment"])
        if not record_shape.get("ok", false): return record_shape
        var key_id := str(record.get("key_id", ""))
        if key_id.is_empty() or key_id.length() > 128 or seen.has(key_id): return _failure("Trusted update-key ID is invalid or duplicated.")
        seen[key_id] = true
        if str(record.get("algorithm", "")) != "rsa-sha256": return _failure("Trusted update-key algorithm is unsupported.")
        if not record.get("channels", []) is Array or (record.get("channels", []) as Array).is_empty(): return _failure("Trusted update-key channels are invalid.")
        for channel_value in record.get("channels", []):
            if not CHANNELS.has(str(channel_value)): return _failure("Trusted update-key channel is invalid.")
        var not_before := int(record.get("not_before_unix", 0))
        var not_after := int(record.get("not_after_unix", 0))
        if not_before < 0 or not_after < 0 or (not_after > 0 and not_before > not_after): return _failure("Trusted update-key activation window is invalid.")
        var pem := str(record.get("public_key_pem", ""))
        if bool(record.get("enabled", false)) and not pem.contains("BEGIN PUBLIC KEY"): return _failure("Enabled update key has no public PEM data.")
    return {"ok": true, "errors": []}

static func _validate_payload(payload: Dictionary, current_version: String, channel: String, install_mode: String, allow_downgrade: bool, now_unix: int) -> Dictionary:
    var shape := _shape(payload, ["schema_version", "product_name", "version", "channel", "published_at_unix", "minimum_updater_version", "release_notes", "source_commit", "data_schema_version", "artifacts"], ["extensions"])
    if not shape.get("ok", false): return shape
    if int(payload.get("schema_version", -1)) != 1: return _failure("Signed update payload schema is unsupported.")
    if str(payload.get("product_name", "")) != PRODUCT_NAME: return _failure("Update manifest targets a different product.")
    var version := str(payload.get("version", ""))
    var parsed_version := SemanticVersion.parse(version)
    if not parsed_version.get("ok", false): return _failure("Update manifest version is invalid.")
    if str(payload.get("channel", "")) != channel: return _failure("Update manifest channel does not match the selected channel.")
    if channel == "stable" and not Array(parsed_version.get("prerelease", [])).is_empty(): return _failure("Stable manifests may not publish prerelease versions.")
    var order := SemanticVersion.compare(version, current_version)
    if order < 0 and not allow_downgrade: return _failure("Update manifest attempts an unauthorized downgrade.")
    var minimum := str(payload.get("minimum_updater_version", ""))
    if not SemanticVersion.parse(minimum).get("ok", false) or SemanticVersion.compare(current_version, minimum) < 0: return _failure("This update requires a newer updater version.")
    if not _whole(payload.get("published_at_unix")) or int(payload.get("published_at_unix", 0)) <= 0: return _failure("Update publication time is invalid.")
    var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
    if int(payload.get("published_at_unix", 0)) > now + MAX_FUTURE_SKEW_SECONDS: return _failure("Update publication time is unreasonably far in the future.")
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
        if (install_mode == "portable" and kind == "portable") or (install_mode == "installed" and kind == "installer"):
            selected = artifact.duplicate(true)
    for required_kind in KINDS:
        if not seen.has(required_kind): return _failure("Update artifact inventory must contain exactly one portable and one installer artifact.")
    if selected.is_empty(): return _failure("Update manifest does not contain an artifact for this installation mode.")
    return {"ok": true, "errors": [], "artifact": selected, "is_update": order != 0}

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
    if key_id.is_empty(): return _failure("Update signing key ID is missing.")
    var now := int(Time.get_unix_time_from_system()) if now_unix < 0 else now_unix
    for value in registry.get("keys", []):
        if not value is Dictionary: continue
        var record: Dictionary = value
        if str(record.get("key_id", "")) != key_id: continue
        if not bool(record.get("enabled", false)) or bool(record.get("revoked", false)): return _failure("Update signing key is disabled or revoked.")
        if not (record.get("channels", []) as Array).has(channel): return _failure("Update signing key is not trusted for this channel.")
        if int(record.get("not_before_unix", 0)) > 0 and now < int(record.get("not_before_unix", 0)): return _failure("Update signing key is not active yet.")
        if int(record.get("not_after_unix", 0)) > 0 and now > int(record.get("not_after_unix", 0)): return _failure("Update signing key has expired.")
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
    if authority.contains(":"):
        var host_port := authority.split(":", false, 2)
        if host_port.size() != 2 or not str(host_port[1]).is_valid_int(): return false
        var port := int(host_port[1])
        if port <= 0 or port > 65535: return false
        authority = str(host_port[0])
    return not authority.is_empty() and not authority.contains("@") and not authority.begins_with(".") and not authority.ends_with(".") and (authority.contains(".") or authority == "localhost")

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}

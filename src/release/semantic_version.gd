class_name PlayWorldSemanticVersion
extends RefCounted

static func parse(value: String) -> Dictionary:
    var source := value.strip_edges()
    if source.is_empty():
        return _failure("Version is empty.")
    var build_split := source.split("+", true, 2)
    if build_split.size() > 2:
        return _failure("Version contains more than one build separator.")
    var precedence := str(build_split[0])
    var build := str(build_split[1]) if build_split.size() == 2 else ""
    var pre_split := precedence.split("-", true, 2)
    if pre_split.size() > 2:
        return _failure("Version contains more than one prerelease separator.")
    var core := str(pre_split[0])
    var prerelease_text := str(pre_split[1]) if pre_split.size() == 2 else ""
    var core_parts := core.split(".", false)
    if core_parts.size() != 3:
        return _failure("Version core must contain major, minor, and patch numbers.")
    var numbers: Array[int] = []
    for part_variant in core_parts:
        var part := str(part_variant)
        if not _is_numeric_identifier(part):
            return _failure("Version core identifiers must be non-negative integers.")
        if part.length() > 1 and part.begins_with("0"):
            return _failure("Version core identifiers must not contain leading zeroes.")
        numbers.append(part.to_int())
    var prerelease: Array[String] = []
    if pre_split.size() == 2:
        if prerelease_text.is_empty():
            return _failure("Prerelease separator requires at least one identifier.")
        for identifier_variant in prerelease_text.split(".", false):
            var identifier := str(identifier_variant)
            if not _is_semver_identifier(identifier):
                return _failure("Prerelease identifiers may contain only ASCII letters, digits, and hyphens.")
            if _is_numeric_identifier(identifier) and identifier.length() > 1 and identifier.begins_with("0"):
                return _failure("Numeric prerelease identifiers must not contain leading zeroes.")
            prerelease.append(identifier)
    var build_identifiers: Array[String] = []
    if build_split.size() == 2:
        if build.is_empty():
            return _failure("Build separator requires at least one identifier.")
        for identifier_variant in build.split(".", false):
            var identifier := str(identifier_variant)
            if not _is_semver_identifier(identifier):
                return _failure("Build identifiers may contain only ASCII letters, digits, and hyphens.")
            build_identifiers.append(identifier)
    return {
        "ok": true,
        "errors": [],
        "value": source,
        "major": numbers[0],
        "minor": numbers[1],
        "patch": numbers[2],
        "prerelease": prerelease,
        "build": build_identifiers,
    }

static func compare(left: String, right: String) -> int:
    var left_parsed := parse(left)
    var right_parsed := parse(right)
    if not left_parsed.get("ok", false) or not right_parsed.get("ok", false):
        return 0
    for key in ["major", "minor", "patch"]:
        var left_value := int(left_parsed[key])
        var right_value := int(right_parsed[key])
        if left_value < right_value:
            return -1
        if left_value > right_value:
            return 1
    var left_pre: Array = left_parsed.get("prerelease", [])
    var right_pre: Array = right_parsed.get("prerelease", [])
    if left_pre.is_empty() and right_pre.is_empty():
        return 0
    if left_pre.is_empty():
        return 1
    if right_pre.is_empty():
        return -1
    var count := mini(left_pre.size(), right_pre.size())
    for index in range(count):
        var left_identifier := str(left_pre[index])
        var right_identifier := str(right_pre[index])
        if left_identifier == right_identifier:
            continue
        var left_numeric := _is_numeric_identifier(left_identifier)
        var right_numeric := _is_numeric_identifier(right_identifier)
        if left_numeric and right_numeric:
            var left_number := left_identifier.to_int()
            var right_number := right_identifier.to_int()
            return -1 if left_number < right_number else 1
        if left_numeric != right_numeric:
            return -1 if left_numeric else 1
        return -1 if left_identifier < right_identifier else 1
    if left_pre.size() == right_pre.size():
        return 0
    return -1 if left_pre.size() < right_pre.size() else 1

static func is_newer(candidate: String, current: String) -> bool:
    return compare(candidate, current) > 0

static func is_supported_upgrade(current: String, candidate: String, allow_downgrade: bool = false) -> bool:
    var current_parsed := parse(current)
    var candidate_parsed := parse(candidate)
    if not current_parsed.get("ok", false) or not candidate_parsed.get("ok", false):
        return false
    var order := compare(candidate, current)
    return order != 0 and (order > 0 or allow_downgrade)

static func _is_numeric_identifier(value: String) -> bool:
    if value.is_empty():
        return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        if code < 48 or code > 57:
            return false
    return true

static func _is_semver_identifier(value: String) -> bool:
    if value.is_empty():
        return false
    for index in range(value.length()):
        var code := value.unicode_at(index)
        var valid := (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code == 45
        if not valid:
            return false
    return true

static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}

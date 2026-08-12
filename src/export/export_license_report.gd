class_name PlayWorldExportLicenseReport
extends RefCounted

static func build(dependencies: Array) -> Dictionary:
    var entries: Array[Dictionary] = []
    var findings: Array[String] = []
    var seen: Dictionary = {}
    var ordered := dependencies.duplicate(true)
    ordered.sort_custom(func(a, b): return str(a.get("asset_id", "")) < str(b.get("asset_id", "")))
    for value in ordered:
        if not value is Dictionary: continue
        var dependency: Dictionary = value
        var asset_id := str(dependency.get("asset_id", ""))
        if seen.has(asset_id): continue
        seen[asset_id] = true
        var license: Dictionary = dependency.get("license", {}) if dependency.get("license", {}) is Dictionary else {}
        var spdx := str(license.get("spdx", "")).strip_edges()
        var author := str(license.get("author", "")).strip_edges()
        var source_url := str(license.get("source_url", "")).strip_edges()
        var notes := str(license.get("notes", "")).strip_edges()
        if spdx.is_empty(): findings.append("License identifier is unknown for asset %s." % asset_id)
        entries.append({
            "asset_id": asset_id,
            "package_path": str(dependency.get("package_path", "")),
            "spdx": spdx,
            "author": author,
            "source_url": source_url,
            "notes": notes,
            "license_known": not spdx.is_empty(),
        })
    return {
        "ok": true,
        "errors": [],
        "findings": findings,
        "attributions": entries,
        "text": _render_text(entries, findings),
    }

static func _render_text(entries: Array[Dictionary], findings: Array[String]) -> String:
    var lines: Array[String] = ["Polyfork Export Attributions", "============================", ""]
    for entry in entries:
        lines.append("Asset: %s" % str(entry.get("asset_id", "")))
        lines.append("Package: %s" % str(entry.get("package_path", "")))
        lines.append("License: %s" % (str(entry.get("spdx", "")) if bool(entry.get("license_known", false)) else "UNKNOWN"))
        if not str(entry.get("author", "")).is_empty(): lines.append("Author: %s" % str(entry.get("author", "")))
        if not str(entry.get("source_url", "")).is_empty(): lines.append("Source: %s" % str(entry.get("source_url", "")))
        if not str(entry.get("notes", "")).is_empty(): lines.append("Notes: %s" % str(entry.get("notes", "")))
        lines.append("")
    if not findings.is_empty():
        lines.append("License findings")
        lines.append("----------------")
        for finding in findings: lines.append("- %s" % finding)
    return "\n".join(lines) + "\n"

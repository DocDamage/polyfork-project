class_name PlayWorldThumbnailCache
extends RefCounted

const WIDTH := 256
const HEIGHT := 160
const MAX_VERTICES := 6000

var cache_root: String

func _init(root: String) -> void: cache_root = root.trim_suffix("/")

func has_current_thumbnail(record: Dictionary) -> bool:
    var path := _current_path(record)
    return not path.is_empty() and FileAccess.file_exists(path)

func ensure_thumbnail(record: Dictionary, preview_node: Node = null, fallback_reason: String = "") -> Dictionary:
    var asset_id := str(record.get("asset_id", "")); var content_hash := str(record.get("content_hash", ""))
    if asset_id.is_empty() or content_hash.length() != 64: return _failure("Thumbnail generation requires a stable asset ID and content hash.")
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_root))
    if make_error != OK: return _failure("Unable to create thumbnail cache directory: %s" % make_error)
    var cache_key := _cache_key(asset_id, content_hash); var path := cache_root.path_join(cache_key + ".png")
    if FileAccess.file_exists(path):
        var existing_kind := str(record.get("thumbnail", {}).get("kind", "cached"))
        return {"ok": true, "errors": [], "thumbnail": _thumbnail_record(cache_key, content_hash, path, existing_kind, existing_kind != "fallback"), "reused": true}
    _invalidate_asset(asset_id)
    var result := _render_geometry(preview_node) if preview_node != null else {"ok": false, "image": null, "vertex_count": 0}
    var image: Image; var kind := "geometry_projection"; var depicts := true
    if result.get("ok", false): image = result["image"]
    else:
        image = _fallback_image(); kind = "fallback"; depicts = false
        if fallback_reason.is_empty(): fallback_reason = "Asset could not be instantiated for thumbnail depiction."
    var save_error := image.save_png(path)
    if save_error != OK: return _failure("Unable to save generated thumbnail: %s" % save_error)
    var thumbnail := _thumbnail_record(cache_key, content_hash, path, kind, depicts)
    thumbnail["vertex_count"] = int(result.get("vertex_count", 0))
    if not depicts: thumbnail["fallback_reason"] = fallback_reason
    return {"ok": true, "errors": [], "thumbnail": thumbnail, "reused": false}

func _render_geometry(preview_node: Node) -> Dictionary:
    var vertices: Array[Vector3] = []
    _collect_vertices(preview_node, Transform3D.IDENTITY, vertices)
    if vertices.is_empty(): return {"ok": false, "image": null, "vertex_count": 0}
    var projected: Array[Vector2] = []; var low := Vector2(INF, INF); var high := Vector2(-INF, -INF)
    for vertex in vertices:
        var point := Vector2(vertex.x - vertex.z * 0.55, -vertex.y + (vertex.x + vertex.z) * 0.18)
        projected.append(point); low.x = min(low.x, point.x); low.y = min(low.y, point.y); high.x = max(high.x, point.x); high.y = max(high.y, point.y)
    var span := high - low
    if span.x < 0.0001: span.x = 1.0
    if span.y < 0.0001: span.y = 1.0
    var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8); image.fill(Color(0.035, 0.055, 0.075, 1.0))
    var scale := min(float(WIDTH - 30) / span.x, float(HEIGHT - 24) / span.y); var used := span * scale; var offset := Vector2((WIDTH - used.x) * 0.5, (HEIGHT - used.y) * 0.5)
    var accent := Color(0.52, 0.86, 0.42, 1.0); var shadow := Color(0.20, 0.34, 0.28, 1.0)
    for index in range(projected.size()):
        var p := (projected[index] - low) * scale + offset
        _draw_dot(image, Vector2i(roundi(p.x), roundi(p.y)), accent)
        if index > 0 and index % 3 != 0:
            var previous := (projected[index - 1] - low) * scale + offset
            _draw_line(image, Vector2i(roundi(previous.x), roundi(previous.y)), Vector2i(roundi(p.x), roundi(p.y)), shadow)
    return {"ok": true, "image": image, "vertex_count": vertices.size()}

func _collect_vertices(node: Node, parent_transform: Transform3D, output: Array[Vector3]) -> void:
    if output.size() >= MAX_VERTICES: return
    var local_transform := parent_transform
    if node is Node3D: local_transform = parent_transform * (node as Node3D).transform
    if node is MeshInstance3D:
        var mesh := (node as MeshInstance3D).mesh
        if mesh != null:
            for surface in range(mesh.get_surface_count()):
                var arrays: Array = mesh.surface_get_arrays(surface)
                if arrays.size() <= Mesh.ARRAY_VERTEX: continue
                var values: Variant = arrays[Mesh.ARRAY_VERTEX]
                if not values is PackedVector3Array: continue
                var vertices := values as PackedVector3Array
                var step := maxi(1, int(ceil(float(vertices.size()) / float(maxi(1, MAX_VERTICES - output.size())))))
                for index in range(0, vertices.size(), step):
                    output.append(local_transform * vertices[index])
                    if output.size() >= MAX_VERTICES: return
    for child in node.get_children():
        _collect_vertices(child, local_transform, output)
        if output.size() >= MAX_VERTICES: return

func _fallback_image() -> Image:
    var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8); image.fill(Color(0.06, 0.075, 0.095, 1.0))
    var outline := Color(0.35, 0.42, 0.50, 1.0)
    _draw_line(image, Vector2i(54, 34), Vector2i(202, 126), outline); _draw_line(image, Vector2i(202, 34), Vector2i(54, 126), outline)
    return image

func _invalidate_asset(asset_id: String) -> void:
    var directory := DirAccess.open(cache_root)
    if directory == null: return
    directory.list_dir_begin(); var entry := directory.get_next()
    while not entry.is_empty():
        if not directory.current_is_dir() and entry.begins_with(asset_id + "-") and entry.ends_with(".png"): DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_root.path_join(entry)))
        entry = directory.get_next()
    directory.list_dir_end()

func _current_path(record: Dictionary) -> String:
    var asset_id := str(record.get("asset_id", "")); var content_hash := str(record.get("content_hash", ""))
    if asset_id.is_empty() or content_hash.length() != 64: return ""
    return cache_root.path_join(_cache_key(asset_id, content_hash) + ".png")

static func _cache_key(asset_id: String, content_hash: String) -> String: return "%s-%s" % [asset_id, content_hash.substr(0, 16)]
static func _thumbnail_record(cache_key: String, source_hash: String, path: String, kind: String, depicts_asset: bool) -> Dictionary: return {"cache_key": cache_key, "source_hash": source_hash, "path": path, "kind": kind, "depicts_asset": depicts_asset}

static func _draw_dot(image: Image, center: Vector2i, color: Color) -> void:
    for y in range(center.y - 1, center.y + 2):
        for x in range(center.x - 1, center.x + 2):
            if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height(): image.set_pixel(x, y, color)

static func _draw_line(image: Image, start: Vector2i, finish: Vector2i, color: Color) -> void:
    var x0 := start.x; var y0 := start.y; var x1 := finish.x; var y1 := finish.y
    var dx := absi(x1 - x0); var sx := 1 if x0 < x1 else -1; var dy := -absi(y1 - y0); var sy := 1 if y0 < y1 else -1; var error := dx + dy
    while true:
        if x0 >= 0 and x0 < image.get_width() and y0 >= 0 and y0 < image.get_height(): image.set_pixel(x0, y0, color)
        if x0 == x1 and y0 == y1: break
        var e2 := 2 * error
        if e2 >= dy: error += dy; x0 += sx
        if e2 <= dx: error += dx; y0 += sy

static func _failure(message: String) -> Dictionary: return {"ok": false, "errors": [message]}

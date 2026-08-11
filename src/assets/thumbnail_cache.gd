class_name PlayWorldThumbnailCache
extends RefCounted

const WIDTH := 256
const HEIGHT := 160

var cache_root: String


func _init(root: String) -> void:
    cache_root = root.trim_suffix("/")


func ensure_thumbnail(record: Dictionary) -> Dictionary:
    var asset_id := str(record.get("asset_id", ""))
    var content_hash := str(record.get("content_hash", ""))
    if asset_id.is_empty() or content_hash.length() != 64:
        return _failure("Thumbnail generation requires a stable asset ID and content hash.")
    var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(cache_root))
    if make_error != OK: return _failure("Unable to create thumbnail cache directory: %s" % make_error)
    var cache_key := "%s-%s" % [asset_id, content_hash.substr(0, 16)]
    var path := cache_root.path_join(cache_key + ".png")
    if FileAccess.file_exists(path):
        return {"ok": true, "errors": [], "thumbnail": {"cache_key": cache_key, "source_hash": content_hash, "path": path}, "reused": true}
    _invalidate_asset(asset_id)
    var image := Image.create(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
    image.fill(_color_from_hash(content_hash))
    var stripe := _color_from_hash(content_hash.reverse()).lightened(0.18)
    for y in range(HEIGHT):
        if int(y / 20) % 2 == 0:
            for x in range(WIDTH - 25, WIDTH): image.set_pixel(x, y, stripe)
    var save_error := image.save_png(path)
    if save_error != OK: return _failure("Unable to save generated thumbnail: %s" % save_error)
    return {"ok": true, "errors": [], "thumbnail": {"cache_key": cache_key, "source_hash": content_hash, "path": path}, "reused": false}


func _invalidate_asset(asset_id: String) -> void:
    var directory := DirAccess.open(cache_root)
    if directory == null: return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while not entry.is_empty():
        if not directory.current_is_dir() and entry.begins_with(asset_id + "-") and entry.ends_with(".png"):
            DirAccess.remove_absolute(ProjectSettings.globalize_path(cache_root.path_join(entry)))
        entry = directory.get_next()
    directory.list_dir_end()


static func _color_from_hash(value: String) -> Color:
    var seed: int = value.hash()
    if seed < 0: seed = -seed
    var r := 0.16 + float(seed % 47) / 160.0
    var g := 0.20 + float(int(seed / 47) % 53) / 150.0
    var b := 0.24 + float(int(seed / 2491) % 59) / 145.0
    return Color(clamp(r, 0.12, 0.58), clamp(g, 0.16, 0.62), clamp(b, 0.20, 0.68), 1.0)


static func _failure(message: String) -> Dictionary:
    return {"ok": false, "errors": [message]}

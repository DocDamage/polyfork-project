class_name PlayWorldTerrainStreamingPolicy
extends RefCounted

const WorldPartition = preload("res://src/terrain/world_partition.gd")


static func active_cell_ids(manifest: Dictionary, focus_position: Vector3) -> Array[String]:
    var result: Array[String] = []
    var cells: Array = manifest.get("cells", [])
    if not bool(manifest.get("streaming", false)):
        for item in cells: result.append(str(item.get("cell_id", "")))
        result.sort()
        return result
    var focus_coord: Vector2i = WorldPartition.coord_for_position(manifest, focus_position)
    var radius: int = max(0, int(manifest.get("load_radius", 1)))
    for item in cells:
        var coord: Array = item.get("coord", [])
        if coord.size() != 2: continue
        if abs(int(coord[0]) - focus_coord.x) <= radius and abs(int(coord[1]) - focus_coord.y) <= radius:
            result.append(str(item.get("cell_id", "")))
    result.sort()
    return result

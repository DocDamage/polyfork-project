extends RefCounted

const StableId = preload("res://src/world/stable_id.gd")
const ProjectRepository = preload("res://src/world/project_repository.gd")
const ExportLayer = preload("res://src/app/workspace/export_workspace_layer.gd")

static func run_checks(tree: SceneTree) -> Array[String]:
    var errors: Array[String] = []
    var packed := load("res://src/app/workspace/WorkspaceScreen.tscn") as PackedScene
    if packed == null: return ["Phase 13 workspace test requires the canonical WorkspaceScreen scene."]
    var workspace = packed.instantiate(); tree.root.add_child(workspace)
    var layer = ExportLayer.new(); tree.root.add_child(layer)
    var bind: Dictionary = layer.bind_workspace(workspace)
    if not bind.get("ok", false): errors.append("Export workspace must bind to the canonical workspace screen.")
    var export_button: Button = layer.get_export_button()
    if export_button == null: errors.append("Export workspace must provide a compact top-bar Export button.")
    elif not export_button.disabled: errors.append("Export must be disabled before an authored project is bound.")

    var root: String = "user://tests/phase13/workspace-%s" % StableId.generate()
    var repository = ProjectRepository.new(root.path_join("projects"))
    var created: Dictionary = repository.create_project("Phase 13 Export UI", &"small", "blank_sandbox")
    if not created.get("ok", false): errors.append("Export workspace fixture project must be created.")
    else:
        var project = created.get("project"); var project_directory: String = repository.get_project_directory(str(project.project_id))
        var project_bind: Dictionary = workspace.bind_project(project, Callable(workspace, "queue_redraw"), project_directory)
        if not project_bind.get("ok", false): errors.append("Canonical workspace must bind the export UI fixture project: %s" % str(project_bind.get("errors", [])))
        layer.refresh_state()
        if export_button != null and export_button.disabled: errors.append("Export must become available for a valid Build-mode project with no transient placement.")
        layer.open_panel()
        if not layer.is_panel_open(): errors.append("Export button path must open the Build Export panel.")
        var export_now: Button = layer.get_export_now_button(); var output: LineEdit = layer.get_output_path()
        if export_now == null or export_now.focus_mode != Control.FOCUS_ALL: errors.append("Build Export must be gamepad/keyboard focusable.")
        if output == null or output.focus_mode != Control.FOCUS_ALL or output.text != "user://exports": errors.append("Export panel must expose a focusable deterministic output-folder control.")
        layer.close_panel()
        if layer.is_panel_open(): errors.append("Export panel must close without mutating project state.")
    layer.free(); workspace.free()
    return errors

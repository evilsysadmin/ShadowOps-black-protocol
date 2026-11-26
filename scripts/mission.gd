extends Node3D

enum Stage { RECOVER, EXTRACT, COMPLETE, FAILED }

const INTEL_POINT := Vector3(-3.65, 1.38, -3.92)
const EXIT_POINT := Vector3(0, 0.65, 9)
const REACH := 1.85
var stage: Stage = Stage.RECOVER
var player: CharacterBody3D
var intel: Node3D
var exit: Node3D
var objective: Label
var prompt: Label
var interact_requested := false

func _ready() -> void:
	player = get_parent().get_node("Agent") as CharacterBody3D
	intel = marker(INTEL_POINT, "INTEL", Color(0.28, 0.85, 0.78), false)
	exit = marker(EXIT_POINT, "EXTRACTION", Color(0.93, 0.72, 0.31), true)
	exit.hide()
	var hud := CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	objective = Label.new()
	objective.position = Vector2(24, 108)
	objective.add_theme_color_override("font_color", Color(0.66, 0.94, 0.90))
	hud.add_child(objective)
	prompt = Label.new()
	hud.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -280
	prompt.offset_right = 280
	prompt.offset_top = -75
	prompt.offset_bottom = -25
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	refresh_objective()

func marker(at: Vector3, title: String, tint: Color, floor_marker: bool) -> Node3D:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.45, 0.035, 1.45) if floor_marker else Vector3(0.22, 0.06, 0.16)
	mesh.mesh = geometry
	mesh.position.y = -0.62 if floor_marker else 0.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mesh.material_override = mat
	root.add_child(mesh)
	var label := Label3D.new()
	label.text = title
	label.position.y = 0.45
	label.font_size = 38
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint
	root.add_child(label)
	return root

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_R and (stage == Stage.COMPLETE or stage == Stage.FAILED):
		get_tree().reload_current_scene()
	elif event.physical_keycode == KEY_E and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		interact_requested = true

func _physics_process(_delta: float) -> void:
	if stage == Stage.COMPLETE or stage == Stage.FAILED:
		interact_requested = false
		return
	var target := INTEL_POINT if stage == Stage.RECOVER else EXIT_POINT
	var reachable := can_reach(target)
	prompt.text = ""
	if reachable:
		prompt.text = "[E] Recover intel" if stage == Stage.RECOVER else "[E] Extract"
	if interact_requested and reachable and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if stage == Stage.RECOVER:
			stage = Stage.EXTRACT
			intel.hide()
			exit.show()
		else:
			stage = Stage.COMPLETE
			player.set("controls_enabled", false)
			exit.hide()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		refresh_objective()
		if stage != Stage.COMPLETE:
			prompt.text = ""
	interact_requested = false

func guard_detected() -> void:
	if stage == Stage.COMPLETE or stage == Stage.FAILED:
		return
	stage = Stage.FAILED
	interact_requested = false
	player.set("controls_enabled", false)
	intel.hide()
	exit.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_objective()

func can_reach(target: Vector3) -> bool:
	var origin := player.global_position + Vector3(0, 1.2, 0)
	if origin.distance_to(target) > REACH:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func refresh_objective() -> void:
	match stage:
		Stage.RECOVER:
			objective.text = "OPERATION: UNEXPECTED GUEST | Recover the intel at reception"
		Stage.EXTRACT:
			objective.text = "INTEL SECURED | Return to the starting area"
		Stage.COMPLETE:
			objective.text = "OPERATION COMPLETE | Intel recovered and agent extracted"
			prompt.text = "Mission complete — press R to replay"
		Stage.FAILED:
			objective.text = "OPERATION FAILED | Agent detected"
			prompt.text = "Compromised — press R to retry"

extends Node3D

# Scene-local immutable resources shared by identical decorative and solid blocks.
var box_mesh_cache: Dictionary = {}
var opaque_material_cache: Dictionary = {}
var emissive_material_cache: Dictionary = {}

const TERMINAL := Vector3(0, 1.25, -3.0)
const DOSSIER := Vector3(2.65, 1.25, -3.6)
const ARMORY := Vector3(-2.65, 1.25, -3.6)
const WALL := Color(0.19, 0.22, 0.25)
const WOOD := Color(0.29, 0.19, 0.13)
const METAL := Color(0.13, 0.17, 0.19)
const BRASS := Color(0.60, 0.43, 0.23)
const TEAL := Color(0.24, 0.70, 0.64)
const AMBER := Color(0.92, 0.65, 0.29)
var station_lights: Array[MeshInstance3D] = []
var active_station_index := -2
var player: CharacterBody3D
var prompt: Label
var requested := false

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.06, 0.08, 0.11)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.66, 0.76, 0.88)
	world.environment.ambient_light_energy = 0.58
	add_child(world)
	block(Vector3(0, -0.15, 0), Vector3(8, 0.3, 10), WOOD)
	block(Vector3(0, 3.2, 0), Vector3(8, 0.2, 10), WALL)
	for side in [-1.0, 1.0]:
		block(Vector3(side * 4, 1.6, 0), Vector3(0.2, 3.2, 10), WALL)
		block(Vector3(0, 1.6, side * 5), Vector3(8, 3.2, 0.2), WALL)
	block(Vector3(0, 0.52, -3.65), Vector3(2.5, 1.04, 0.95), METAL)
	block(Vector3(0, 1.08, -3.65), Vector3(2.65, 0.10, 1.05), WOOD)
	block(Vector3(0, 1.38, -3.75), Vector3(0.85, 0.5, 0.12), METAL, false)
	block(Vector3(0, 1.38, -3.68), Vector3(0.75, 0.4, 0.02), Color(0.18, 0.65, 0.62), false, true)
	block(Vector3(-2.9, 0.36, 1.5), Vector3(1.1, 0.72, 2.4), Color(0.18, 0.27, 0.28))
	block(Vector3(-3.38, 0.86, 1.5), Vector3(0.22, 0.7, 2.4), Color(0.18, 0.27, 0.28))
	block(Vector3(2.95, 0.95, -1.4), Vector3(1.1, 1.9, 1.6), METAL)
	block(Vector3(2.95, 0.95, 1.0), Vector3(1.1, 1.9, 1.6), METAL)
	block(Vector3(0, 0.02, 0), Vector3(2.8, 0.03, 4.0), Color(0.11, 0.19, 0.20), false)
	for z in [-2.5, 2.5]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 2.85, z)
		light.light_color = Color(1.0, 0.78, 0.52)
		light.light_energy = 2.1
		light.shadow_enabled = z < 0.0
		light.omni_range = 7.0
		add_child(light)
		block(Vector3(0, 3.04, z), Vector3(2.0, 0.08, 0.15), Color(1.0, 0.78, 0.52), false, true)
	block(Vector3(2.65, 0.52, -4.25), Vector3(1.55, 1.04, 0.8), METAL)
	block(Vector3(2.65, 1.18, -4.32), Vector3(1.35, 0.26, 0.10), Color(0.18, 0.55, 0.52), false, true)
	block(Vector3(-2.65, 0.52, -4.25), Vector3(1.55, 1.04, 0.8), METAL)
	block(Vector3(-2.65, 1.16, -4.25), Vector3(1.4, 0.2, 0.55), Color(0.36, 0.40, 0.35), false)
	var armory_sign := Label3D.new()
	armory_sign.text = "ARMORY"
	armory_sign.position = Vector3(-2.65, 2.05, -4.72)
	armory_sign.font_size = 36
	armory_sign.pixel_size = 0.004
	add_child(armory_sign)
	var dossier_sign := Label3D.new()
	dossier_sign.text = "FIELD RECORDS"
	dossier_sign.position = Vector3(2.65, 2.05, -4.72)
	dossier_sign.font_size = 36
	dossier_sign.pixel_size = 0.004
	add_child(dossier_sign)
	var sign_label := Label3D.new()
	sign_label.text = "OPERATIONS"
	sign_label.position = Vector3(0, 2.25, -4.75)
	sign_label.font_size = 54
	sign_label.pixel_size = 0.006
	add_child(sign_label)
	build_visual_details()
	var ambience := preload("res://scripts/scene_ambience.gd").new()
	ambience.name = "SceneAmbience"
	ambience.position = Vector3(0, 2.5, -3.2)
	add_child(ambience)
	player = CharacterBody3D.new()
	player.name = "Agent"
	player.set_script(preload("res://scripts/agent.gd"))
	player.set("field_mode", false)
	player.position = Vector3(0, 0.05, 2)
	add_child(player)
	var hud := CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	var dossier := Label.new()
	dossier.position = Vector2(24, 90)
	dossier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dossier.text = "CAMPAIGN | Trust %+d | Leverage %+d" % [Campaign.handler_trust(), Campaign.independent_leverage()]
	if not Campaign.specialization.is_empty():
		dossier.text += " | " + Campaign.specialization.capitalize()
	hud.add_child(dossier)
	prompt = Label.new()
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -260
	prompt.offset_right = 260
	prompt.offset_top = -70
	prompt.offset_bottom = -20
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)

func build_visual_details() -> void:
	# Render-only details, attached to the existing walls and furniture.
	for side in [-1.0, 1.0]:
		block(Vector3(side * 3.87, 0.18, 0), Vector3(0.04, 0.25, 9.7), WOOD, false)
		block(Vector3(side * 3.86, 2.65, 0), Vector3(0.04, 0.08, 9.7), BRASS, false)
		block(Vector3(side * 1.34, 0.04, 0), Vector3(0.045, 0.01, 3.92), BRASS, false)
	for z in [-1.4, 1.0]:
		for offset in [-0.37, 0.37]:
			block(Vector3(2.39, 0.97, z + offset), Vector3(0.035, 1.65, 0.69), WALL, false)
			block(Vector3(2.36, 0.97, z + offset + 0.21), Vector3(0.04, 0.22, 0.035), BRASS, false)
	for z in [0.82, 1.5, 2.18]:
		block(Vector3(-2.85, 0.76, z), Vector3(0.83, 0.10, 0.59), Color(0.22, 0.34, 0.34), false)
	# Operations board: abstract charts, not fictional campaign statistics.
	block(Vector3(0, 2.72, -4.84), Vector3(2.65, 0.50, 0.08), METAL, false)
	for x in [-0.84, 0.0, 0.84]:
		block(Vector3(x, 2.72, -4.78), Vector3(0.73, 0.37, 0.025), Color(0.10, 0.26, 0.27), false, true)
		for y in [2.62, 2.72, 2.82]:
			block(Vector3(x, y, -4.76), Vector3(0.52, 0.018, 0.01), TEAL, false, true)
	for x in [-2.65, 0.0, 2.65]:
		block(Vector3(x, 1.40, -4.83), Vector3(1.40, 0.055, 0.03), BRASS, false)
		var marker := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.40, 0.045, 0.035)
		marker.mesh = shape
		var material := StandardMaterial3D.new()
		material.albedo_color = TEAL
		material.emission_enabled = true
		material.emission = TEAL
		marker.material_override = material
		marker.position = Vector3(x, 1.48, -4.80)
		add_child(marker)
		station_lights.append(marker)
	var accent := OmniLight3D.new()
	accent.name = "OperationsAccent"
	accent.position = Vector3(0, 2.15, -3.9)
	accent.light_color = TEAL
	accent.light_energy = 0.7
	accent.omni_range = 3.5
	add_child(accent)

func update_station_lights(active: int) -> void:
	if active_station_index == active:
		return
	active_station_index = active
	for i in range(station_lights.size()):
		var material := station_lights[i].material_override as StandardMaterial3D
		material.emission = AMBER if i == active else TEAL
		material.albedo_color = material.emission

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		requested = true

func _physics_process(_delta: float) -> void:
	var origin := player.global_position + Vector3(0, 1.25, 0)
	var operations_distance := origin.distance_to(TERMINAL)
	var dossier_distance := origin.distance_to(DOSSIER)
	var armory_distance := origin.distance_to(ARMORY)
	var destination := ""
	var active_station := -1
	prompt.text = "Approach operations, field records or armory"
	if armory_distance <= 1.65 and armory_distance < minf(operations_distance, dossier_distance):
		active_station = 0
		prompt.text = "[E] Armory"
		destination = "res://scenes/armory.tscn"
	elif dossier_distance <= 1.65 and dossier_distance < operations_distance:
		active_station = 2
		prompt.text = "[E] Field records"
		destination = "res://scenes/dossier.tscn"
	elif operations_distance <= 1.65:
		active_station = 1
		prompt.text = "[E] Operations terminal"
		destination = "res://scenes/briefing.tscn"
	update_station_lights(active_station)
	if requested and not destination.is_empty() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		requested = false
		get_tree().call_deferred("change_scene_to_file", destination)
		return
	requested = false

func block(at: Vector3, dimensions: Vector3, tint: Color, solid := true, glow := false) -> void:
	var root := Node3D.new()
	if solid:
		root = StaticBody3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	if not box_mesh_cache.has(dimensions):
		var geometry := BoxMesh.new()
		geometry.size = dimensions
		box_mesh_cache[dimensions] = geometry
	mesh.mesh = box_mesh_cache[dimensions]
	mesh.material_override = block_material(tint, glow)
	root.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = dimensions
		collider.shape = bounds
		root.add_child(collider)

func block_material(tint: Color, glow: bool) -> StandardMaterial3D:
	var materials := emissive_material_cache if glow else opaque_material_cache
	if materials.has(tint):
		return materials[tint] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.85 if tint == WOOD else 0.6
	mat.metallic = 0.25 if tint == METAL or tint == BRASS else 0.0
	if glow:
		mat.emission_enabled = true
		mat.emission = tint
	materials[tint] = mat
	return mat

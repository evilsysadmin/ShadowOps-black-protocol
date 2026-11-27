extends Node3D

# Scene-local immutable resources shared by identical decorative and solid blocks.
var box_mesh_cache: Dictionary = {}
var opaque_material_cache: Dictionary = {}
var emissive_material_cache: Dictionary = {}

const STONE := Color(0.21, 0.25, 0.28)
const STEEL := Color(0.14, 0.19, 0.22)
const LIGHT := Color(0.57, 0.82, 0.87)
const PAPER := Color(0.63, 0.59, 0.47)
const FOLDER := Color(0.35, 0.30, 0.23)
const BRONZE := Color(0.61, 0.47, 0.29)
const ASSISTED_SPAWN := Vector3(-5.5, 0.05, -3.5)
const INDEPENDENT_SPAWN := Vector3(5.5, 0.05, 7.0)
const LEDGER_POINT := Vector3(-3.0, 1.10, -5.75)

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.04, 0.06, 0.08)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = LIGHT
	world.environment.ambient_light_energy = 0.65
	add_child(world)
	block(Vector3(0, -0.15, 0), Vector3(14, 0.3, 18), STONE)
	block(Vector3(0, 3.5, 0), Vector3(14, 0.2, 18), STEEL)
	for side in [-1.0, 1.0]:
		block(Vector3(side * 7, 1.75, 0), Vector3(0.25, 3.5, 18), STONE)
		block(Vector3(0, 1.75, side * 9), Vector3(14, 3.5, 0.25), STONE)
	for x in [-4.4, 4.4]:
		for z in [-1.8, 1.8]:
			block(Vector3(x, 1.05, z), Vector3(1.0, 2.1, 2.5), STEEL)
			for y in [0.4, 1.0, 1.6]:
				block(Vector3(x, y, z), Vector3(1.05, 0.06, 2.55), Color(0.38, 0.43, 0.44), false)
	for x in [-2.4, 2.4]:
		var cover := block(Vector3(x, 0.54, -3.2), Vector3(1.8, 1.08, 0.55), STEEL)
		cover.add_to_group("low_cover")
	block(Vector3(-3.0, 0.5, -6.4), Vector3(2.0, 1.0, 0.9), STEEL)
	for z in [-6.0, 0.0, 6.0]:
		var light := OmniLight3D.new()
		light.position = Vector3(0, 3.0, z)
		light.light_color = LIGHT
		light.light_energy = 2.8
		light.shadow_enabled = z == 0.0
		light.omni_range = 9.0
		add_child(light)
		block(Vector3(0, 3.32, z), Vector3(3.0, 0.07, 0.17), LIGHT, false, true)
	build_visual_details()
	var assisted := Campaign.intel_choice == "share"
	var spawn := ASSISTED_SPAWN if assisted else INDEPENDENT_SPAWN
	add_wayfinding(assisted)
	var player := CharacterBody3D.new()
	player.name = "Agent"
	player.set_script(preload("res://scripts/agent.gd"))
	player.position = spawn
	add_child(player)
	var mission := Node3D.new()
	mission.name = "Mission"
	mission.set_script(preload("res://scripts/mission.gd"))
	mission.set("operation_id", "silent_archive")
	mission.set("intel_point", LEDGER_POINT)
	mission.set("exit_point", Vector3(spawn.x, 0.65, spawn.z))
	add_child(mission)
	var guard := CharacterBody3D.new()
	guard.name = "Guard"
	guard.set_script(preload("res://scripts/guard.gd"))
	guard.position = Vector3(0, 0.05, -6)
	var route: Array[Vector3] = [Vector3(0, 0, -6), Vector3(0, 0, 5), Vector3(2, 0, 5), Vector3(0, 0, 5)]
	guard.set("patrol_points", route)
	add_child(guard)

func build_visual_details() -> void:
	# Archive shelves remain solid; thin face panels and labels are decorative only.
	for x in [-4.4, 4.4]:
		for z in [-1.8, 1.8]:
			var front := x - signf(x) * 0.51
			for y in [0.4, 1.0, 1.6]:
				for i in range(5):
					var file_z := z - 0.96 + float(i) * 0.48
					var tint := PAPER if i % 2 == 0 else FOLDER
					block(Vector3(front, y + 0.23, file_z), Vector3(0.035, 0.35, 0.39), tint, false)
					block(Vector3(front - signf(x) * 0.024, y + 0.27, file_z), Vector3(0.012, 0.055, 0.22), BRONZE, false)
			for edge in [-1.20, 1.20]:
				block(Vector3(front, 1.05, z + edge), Vector3(0.045, 2.08, 0.06), STEEL, false)
	for side in [-1.0, 1.0]:
		block(Vector3(side * 6.84, 0.16, 0), Vector3(0.045, 0.25, 17.6), STEEL, false)
		block(Vector3(side * 6.83, 2.6, 0), Vector3(0.04, 0.07, 17.6), BRONZE, false)
	for z in range(-8, 9, 2):
		block(Vector3(0, 0.004, float(z)), Vector3(13.7, 0.008, 0.025), STEEL, false)
	block(Vector3(-3.0, 1.02, -6.4), Vector3(1.84, 0.025, 0.77), FOLDER, false)
	block(Vector3(-3.58, 1.06, -6.37), Vector3(0.34, 0.04, 0.27), PAPER, false)
	var accent := OmniLight3D.new()
	accent.name = "RecordsAccent"
	accent.position = Vector3(-3.0, 2.45, -6.4)
	accent.light_color = Color(1.0, 0.74, 0.43)
	accent.light_energy = 0.75
	accent.omni_range = 3.8
	add_child(accent)

func add_wayfinding(assisted: bool) -> void:
	var entry := Label3D.new()
	entry.text = "SERVICE ACCESS" if assisted else "MAIN ACCESS"
	entry.position = (ASSISTED_SPAWN if assisted else INDEPENDENT_SPAWN) + Vector3(0, 2.15, 0)
	entry.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	entry.font_size = 36
	entry.pixel_size = 0.004
	add_child(entry)
	var records := Label3D.new()
	records.text = "RECORDS / B-02"
	records.position = Vector3(-3.0, 2.25, -6.9)
	records.font_size = 48
	records.pixel_size = 0.006
	add_child(records)

func block(at: Vector3, dimensions: Vector3, tint: Color, solid := true, glow := false) -> Node3D:
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
	return root

func block_material(tint: Color, glow: bool) -> StandardMaterial3D:
	var materials := emissive_material_cache if glow else opaque_material_cache
	if materials.has(tint):
		return materials[tint] as StandardMaterial3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.92 if tint == PAPER or tint == FOLDER else 0.72
	mat.metallic = 0.2 if tint == STEEL or tint == BRONZE else 0.0
	if glow:
		mat.emission_enabled = true
		mat.emission = tint
	materials[tint] = mat
	return mat

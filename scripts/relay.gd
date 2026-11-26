extends Node3D

const WALL := Color(0.18, 0.21, 0.24)
const FLOOR := Color(0.27, 0.28, 0.29)
const RACK := Color(0.12, 0.16, 0.19)
const LIGHT := Color(0.65, 0.82, 0.75)
const DRIVE_POINT := Vector3(0, 1.15, -8.0)

static func spawn_for(route: String) -> Vector3:
	match route:
		"handler":
			return Vector3(-6.0, 0.05, -4.0)
		"rook":
			return Vector3(6.0, 0.05, -5.5)
	return Vector3(0, 0.05, 8.0)

func _ready() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.035, 0.05, 0.06)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = LIGHT
	world.environment.ambient_light_energy = 0.62
	add_child(world)
	block(Vector3(0, -0.15, 0), Vector3(16, 0.3, 20), FLOOR)
	block(Vector3(0, 3.7, 0), Vector3(16, 0.2, 20), WALL)
	for side in [-1.0, 1.0]:
		block(Vector3(side * 8, 1.8, 0), Vector3(0.2, 3.6, 20), WALL)
		block(Vector3(0, 1.8, side * 10), Vector3(16, 3.6, 0.2), WALL)
		for z in [-3.0, 1.0, 5.0]:
			block(Vector3(side * 3.5, 1.15, z), Vector3(1.3, 2.3, 2.6), RACK)
			for y in [0.5, 1.0, 1.5, 2.0]:
				block(Vector3(side * 3.5, y, z + 1.31), Vector3(1.1, 0.06, 0.03), LIGHT, false, true)
		var cover := block(Vector3(side * 2.2, 0.54, -6.0), Vector3(1.6, 1.08, 0.6), RACK)
		cover.add_to_group("low_cover")
	block(Vector3(0, 0.5, -8.7), Vector3(2.4, 1.0, 0.8), RACK)
	for z in [-7.0, 0.0, 7.0]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 3.2, z)
		lamp.light_color = LIGHT
		lamp.light_energy = 2.8
		lamp.omni_range = 10.0
		add_child(lamp)
		block(Vector3(0, 3.53, z), Vector3(4, 0.08, 0.18), LIGHT, false, true)
	var route := Campaign.relay_route()
	var spawn := spawn_for(route)
	signage("RELAY CONTROL", Vector3(0, 2.3, -9.7))
	signage("WEST ACCESS" if route == "handler" else ("EAST ACCESS" if route == "rook" else "SOUTH ACCESS"), spawn + Vector3(0, 2.1, 0))
	var player := CharacterBody3D.new()
	player.name = "Agent"
	player.set_script(preload("res://scripts/agent.gd"))
	player.position = spawn
	add_child(player)
	var mission := Node3D.new()
	mission.name = "Mission"
	mission.set_script(preload("res://scripts/mission.gd"))
	mission.set("operation_id", "night_relay")
	mission.set("intel_point", DRIVE_POINT)
	mission.set("exit_point", Vector3(spawn.x, 0.65, spawn.z))
	add_child(mission)
	var guard := CharacterBody3D.new()
	guard.name = "Guard"
	guard.set_script(preload("res://scripts/guard.gd"))
	guard.position = Vector3(0, 0.05, -4)
	var patrol: Array[Vector3] = [Vector3(0, 0, -4), Vector3(0, 0, 6), Vector3(1.5, 0, 6), Vector3(0, 0, 6)]
	guard.set("patrol_points", patrol)
	add_child(guard)

func signage(content: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = content
	label.position = at
	label.font_size = 42
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func block(at: Vector3, dimensions: Vector3, tint: Color, solid := true, glow := false) -> Node3D:
	var root := Node3D.new()
	if solid:
		root = StaticBody3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	mesh.mesh = geometry
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	if glow:
		mat.emission_enabled = true
		mat.emission = tint
	mesh.material_override = mat
	root.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = dimensions
		collider.shape = bounds
		root.add_child(collider)
	return root

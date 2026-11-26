extends Node3D

const STONE := Color(0.21, 0.25, 0.28)
const STEEL := Color(0.14, 0.19, 0.22)
const LIGHT := Color(0.57, 0.82, 0.87)

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
		light.omni_range = 9.0
		add_child(light)
		block(Vector3(0, 3.32, z), Vector3(3.0, 0.07, 0.17), LIGHT, false, true)
	var assisted := Campaign.intel_choice == "share"
	var spawn := Vector3(-5.5, 0.05, -3.5) if assisted else Vector3(5.5, 0.05, 7.0)
	var player := CharacterBody3D.new()
	player.name = "Agent"
	player.set_script(preload("res://scripts/agent.gd"))
	player.position = spawn
	add_child(player)
	var mission := Node3D.new()
	mission.name = "Mission"
	mission.set_script(preload("res://scripts/mission.gd"))
	mission.set("archive_operation", true)
	mission.set("intel_point", Vector3(-3.0, 1.10, -5.75))
	mission.set("exit_point", Vector3(spawn.x, 0.65, spawn.z))
	add_child(mission)
	var guard := CharacterBody3D.new()
	guard.name = "Guard"
	guard.set_script(preload("res://scripts/guard.gd"))
	guard.position = Vector3(0.8, 0.05, -6)
	add_child(guard)

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

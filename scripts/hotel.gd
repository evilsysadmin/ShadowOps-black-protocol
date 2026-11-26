extends Node3D

const STONE := Color(0.32, 0.35, 0.36)
const WOOD := Color(0.23, 0.13, 0.09)
const BRASS := Color(0.66, 0.46, 0.22)

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.07, 0.09, 0.12)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.65, 0.76)
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	box(Vector3(0, -0.15, 0), Vector3(12, 0.3, 24), STONE)
	box(Vector3(-6, 1.7, 0), Vector3(0.3, 3.4, 24), WOOD)
	box(Vector3(6, 1.7, 0), Vector3(0.3, 3.4, 24), WOOD)
	box(Vector3(0, 1.7, -12), Vector3(12, 3.4, 0.3), STONE)
	box(Vector3(0, 1.7, 12), Vector3(12, 3.4, 0.3), STONE)
	box(Vector3(0, 3.5, 0), Vector3(12, 0.2, 24), STONE)
	for z in [-9, -3, 3, 9]:
		for x in [-5.2, 5.2]:
			box(Vector3(x, 1.6, z), Vector3(0.45, 3.2, 0.55), BRASS)
			lamp(Vector3(x * 0.85, 2.5, z))
	box(Vector3(-3.5, 0.55, -5), Vector3(3.4, 1.1, 1.2), WOOD)
	box(Vector3(-3.5, 1.13, -5), Vector3(3.6, 0.12, 1.4), BRASS)
	box(Vector3(3.6, 0.35, -2), Vector3(2.3, 0.7, 1.0), Color(0.16, 0.29, 0.28))
	box(Vector3(4.5, 0.8, -2), Vector3(0.5, 0.9, 1.1), Color(0.16, 0.29, 0.28))
	box(Vector3(0, 0.015, -1), Vector3(3, 0.03, 17), Color(0.24, 0.11, 0.12), false)
	var player := CharacterBody3D.new()
	player.set_script(preload("res://scripts/agent.gd"))
	player.position = Vector3(0, 0.05, 8)
	add_child(player)

func box(at: Vector3, dimensions: Vector3, color: Color, solid := true) -> void:
	var root := Node3D.new()
	if solid:
		root = StaticBody3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = dimensions
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	root.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = dimensions
		collider.shape = bounds
		root.add_child(collider)

func lamp(at: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(1.0, 0.73, 0.42)
	light.light_energy = 2.0
	light.omni_range = 7.0
	add_child(light)

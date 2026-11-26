extends Node3D

const STONE := Color(0.36, 0.38, 0.37)
const WOOD := Color(0.21, 0.13, 0.085)
const BRASS := Color(0.64, 0.45, 0.24)
const TEAL := Color(0.075, 0.22, 0.22)
const PLASTER := Color(0.45, 0.44, 0.40)
const DARK := Color(0.09, 0.12, 0.14)
const WARM := Color(1.0, 0.72, 0.41)

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.055, 0.07, 0.095)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.63, 0.72, 0.85)
	env.environment.ambient_light_energy = 0.72
	add_child(env)
	build_shell()
	build_reception()
	build_lounge()
	build_corridor()
	var player := CharacterBody3D.new()
	player.name = "Agent"
	player.set_script(preload("res://scripts/agent.gd"))
	player.position = Vector3(0, 0.05, 9)
	add_child(player)
	var mission := Node3D.new()
	mission.name = "Mission"
	mission.set_script(preload("res://scripts/mission.gd"))
	add_child(mission)
	var target := StaticBody3D.new()
	target.set_script(preload("res://scripts/training_target.gd"))
	target.position = Vector3(2.6, 0, -6.8)
	add_child(target)
	var guard := CharacterBody3D.new()
	guard.name = "Guard"
	guard.set_script(preload("res://scripts/guard.gd"))
	guard.position = Vector3(0.8, 0.05, -6.0)
	add_child(guard)

func build_shell() -> void:
	box(Vector3(0, -0.15, 0), Vector3(12, 0.3, 24), STONE)
	box(Vector3(0, 4.3, 0), Vector3(12, 0.2, 24), DARK)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 6, 2.1, 0), Vector3(0.3, 4.2, 24), PLASTER)
		box(Vector3(side * 5.80, 0.56, 0), Vector3(0.10, 1.12, 24), WOOD, false)
		box(Vector3(side * 5.73, 1.13, 0), Vector3(0.10, 0.055, 24), BRASS, false)
		box(Vector3(side * 5.70, 3.88, 0), Vector3(0.16, 0.12, 24), WOOD, false)
		for z in [-9.0, -3.0, 3.0, 9.0]:
			box(Vector3(side * 5.45, 2.1, z), Vector3(0.65, 4.2, 0.65), WOOD)
			box(Vector3(side * 5.06, 2.15, z), Vector3(0.10, 0.85, 0.16), BRASS, false)
			box(Vector3(side * 4.98, 2.17, z), Vector3(0.08, 0.52, 0.22), WARM, false, true)
			lamp(Vector3(side * 4.65, 2.50, z), 5.6, 1.55)
	box(Vector3(0, 2.1, -12), Vector3(12, 4.2, 0.3), WOOD)
	box(Vector3(0, 2.1, 12), Vector3(12, 4.2, 0.3), DARK)
	for x in range(-5, 6):
		box(Vector3(float(x), 0.006, 0), Vector3(0.012, 0.008, 23.7), Color(0.23, 0.25, 0.25), false)
	for z in range(-11, 12):
		box(Vector3(0, 0.007, float(z)), Vector3(11.7, 0.008, 0.012), Color(0.23, 0.25, 0.25), false)
	box(Vector3(0, 0.018, 0.8), Vector3(2.5, 0.028, 19.5), Color(0.23, 0.095, 0.11), false)
	for side in [-1.0, 1.0]:
		box(Vector3(side * 1.16, 0.034, 0.8), Vector3(0.035, 0.008, 19.3), BRASS, false)
	for z in [-6.0, 1.0, 8.0]:
		box(Vector3(0, 4.07, z), Vector3(4.2, 0.14, 0.46), WOOD, false)
		box(Vector3(0, 3.98, z), Vector3(3.5, 0.04, 0.14), WARM, false, true)
		lamp(Vector3(0, 3.7, z), 7.2, 2.6, z == 1.0)

func build_reception() -> void:
	box(Vector3(-3.65, 0.56, -4.7), Vector3(3.1, 1.12, 1.1), WOOD)
	box(Vector3(-3.65, 1.15, -4.7), Vector3(3.32, 0.12, 1.28), STONE)
	box(Vector3(-3.65, 0.53, -4.10), Vector3(2.72, 0.72, 0.06), DARK, false)
	box(Vector3(-3.65, 0.91, -4.06), Vector3(2.72, 0.03, 0.04), BRASS, false)
	box(Vector3(-3.95, 1.22, -4.8), Vector3(0.38, 0.05, 0.26), DARK, false)
	box(Vector3(-3.95, 1.43, -4.9), Vector3(0.48, 0.31, 0.06), DARK, false)
	box(Vector3(-3.95, 1.43, -4.86), Vector3(0.43, 0.26, 0.018), Color(0.20, 0.49, 0.47), false, true)
	add_hotel_sign("RECEPTION", Vector3(-3.65, 2.38, -6.4), 50)
	box(Vector3(-3.65, 1.7, -6.65), Vector3(3.4, 3.4, 0.20), WOOD)
	for x in [-4.8, -3.65, -2.5]:
		box(Vector3(x, 1.4, -6.51), Vector3(0.022, 1.8, 0.04), BRASS, false)

func build_lounge() -> void:
	for z in [1.5, 4.2]:
		box(Vector3(4.0, 0.34, z), Vector3(1.2, 0.68, 1.9), TEAL)
		box(Vector3(4.48, 0.81, z), Vector3(0.25, 0.82, 1.9), TEAL)
		for side in [-1.0, 1.0]:
			box(Vector3(4.0, 0.67, z + side * 0.82), Vector3(1.22, 0.36, 0.24), TEAL)
		for offset in [-0.34, 0.34]:
			box(Vector3(3.95, 0.70, z + offset), Vector3(0.79, 0.16, 0.62), Color(0.12, 0.31, 0.30), false)
	box(Vector3(2.75, 0.22, 2.85), Vector3(0.85, 0.44, 1.15), WOOD)
	box(Vector3(2.75, 0.47, 2.85), Vector3(1.0, 0.08, 1.3), STONE)
	box(Vector3(2.75, 0.53, 2.85), Vector3(0.32, 0.03, 0.24), Color(0.48, 0.42, 0.29), false)
	for z in [6.9, -7.6]:
		plant(Vector3(4.8, 0.0, z))

func build_corridor() -> void:
	for side in [-1.0, 1.0]:
		box(Vector3(side * 3.9, 2.1, -8.8), Vector3(3.8, 4.2, 0.30), WOOD)
		box(Vector3(side * 1.94, 1.5, -8.8), Vector3(0.14, 3.0, 0.46), BRASS, false)
	box(Vector3(0, 3.6, -8.8), Vector3(4.0, 1.2, 0.30), WOOD)
	add_hotel_sign("GUEST ROOMS", Vector3(0, 3.54, -8.61), 52)
	box(Vector3(0, 1.12, -11.82), Vector3(1.8, 2.24, 0.10), DARK)
	box(Vector3(0, 1.12, -11.74), Vector3(0.04, 2.24, 0.03), BRASS, false)
	add_hotel_sign("01  /  PRIVATE", Vector3(0, 2.48, -11.68), 34)
	lamp(Vector3(0, 2.8, -10.3), 4.5, 2.2)

func plant(at: Vector3) -> void:
	var pot := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.29
	cylinder.bottom_radius = 0.22
	cylinder.height = 0.55
	pot.mesh = cylinder
	pot.material_override = material(BRASS)
	pot.position = at + Vector3(0, 0.275, 0)
	add_child(pot)
	box(at + Vector3(0, 0.26, 0), Vector3(0.43, 0.52, 0.43), BRASS, true, false, false)
	for i in range(7):
		var angle := float(i) * TAU / 7.0
		var leaf := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 12
		sphere.rings = 6
		leaf.mesh = sphere
		leaf.scale = Vector3(0.20, 0.68, 0.10)
		leaf.rotation = Vector3(0.4, angle, 0.44)
		leaf.position = at + Vector3(cos(angle) * 0.21, 0.86 + float(i % 3) * 0.08, sin(angle) * 0.21)
		leaf.material_override = material(Color(0.11, 0.31, 0.19))
		add_child(leaf)

func material(color: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.68
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.8
	return mat

func box(at: Vector3, dimensions: Vector3, color: Color, solid := true, glow := false, visible_mesh := true) -> void:
	var root := Node3D.new()
	if solid:
		root = StaticBody3D.new()
	root.position = at
	add_child(root)
	if visible_mesh:
		var mesh := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = dimensions
		mesh.mesh = shape
		mesh.material_override = material(color, glow)
		root.add_child(mesh)
	if solid:
		var collider := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = dimensions
		collider.shape = bounds
		root.add_child(collider)

func lamp(at: Vector3, radius: float, energy: float, shadows := false) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = WARM
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = shadows
	add_child(light)

func add_hotel_sign(message: String, at: Vector3, size: int) -> void:
	var label := Label3D.new()
	label.text = message
	label.position = at
	label.font_size = size
	label.pixel_size = 0.006
	label.modulate = Color(0.90, 0.77, 0.54)
	label.outline_size = 0
	add_child(label)

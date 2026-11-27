extends Node3D
# Lightweight procedural visual rig, independent of the character collider.
var hips: Node3D
var torso: Node3D
var thighs: Array[Node3D] = []
var knees: Array[Node3D] = []
var shoulders: Array[Node3D] = []
var elbows: Array[Node3D] = []
var phase := 0.0
var stride := 0.0
var stance := 0.0
var aim_blend := 0.0
var shot_pose := 0.0
var reload_pose := 0.0
var held_prop: Node3D
var outfit: Node3D

func build(uniform: Color, trousers: Color, security := false, equipment := "") -> void:
	var cloth := make_material(uniform)
	var pants := make_material(trousers)
	var skin := make_material(Color(0.58, 0.39, 0.29))
	var leather := make_material(Color(0.055, 0.065, 0.07))
	var trim := make_material(Color(0.28, 0.32, 0.34))
	var shirt := make_material(Color(0.55, 0.57, 0.56))
	hips = joint(self, Vector3(0, 0.89, 0))
	torso = joint(hips, Vector3.ZERO)
	ellipsoid(torso, Vector3(0, 0.08, 0), Vector3(0.39, 0.26, 0.28), pants)
	ellipsoid(torso, Vector3(0, 0.33, 0), Vector3(0.49, 0.58, 0.32), cloth)
	ellipsoid(torso, Vector3(0, 0.47, 0), Vector3(0.54, 0.30, 0.32), cloth)
	cuboid(torso, Vector3(0, 0.13, 0), Vector3(0.39, 0.055, 0.29), leather)
	cuboid(torso, Vector3(0, 0.13, -0.15), Vector3(0.075, 0.047, 0.025), trim)
	ellipsoid(torso, Vector3(0, 0.62, 0), Vector3(0.14, 0.19, 0.14), skin)
	ellipsoid(torso, Vector3(0, 0.76, 0), Vector3(0.235, 0.29, 0.235), skin)
	ellipsoid(torso, Vector3(0, 0.83, 0.025), Vector3(0.24, 0.16, 0.23), leather)
	ellipsoid(torso, Vector3(0, 0.74, -0.111), Vector3(0.055, 0.07, 0.065), skin)
	# Low-poly facial and clothing accents, readable from close camera views.
	var dark := make_material(Color(0.12, 0.10, 0.09))
	for side in [-1.0, 1.0]:
		ellipsoid(torso, Vector3(side * 0.116, 0.755, 0.006), Vector3(0.035, 0.073, 0.04), skin)
		ellipsoid(torso, Vector3(side * 0.047, 0.779, -0.112), Vector3(0.035, 0.015, 0.017), dark)
		ellipsoid(torso, Vector3(side * 0.19, 0.43, 0), Vector3(0.09, 0.19, 0.29), cloth)
	cuboid(torso, Vector3(0, 0.699, -0.111), Vector3(0.055, 0.009, 0.012), dark)
	if security:
		cuboid(torso, Vector3(-0.13, 0.45, -0.157), Vector3(0.075, 0.09, 0.02), trim)
		cuboid(torso, Vector3(0, 0.37, 0.17), Vector3(0.29, 0.28, 0.08), leather)
		cuboid(torso, Vector3(0, 0.832, -0.14), Vector3(0.22, 0.025, 0.13), leather)
		ellipsoid(torso, Vector3(0, 0.85, 0), Vector3(0.29, 0.11, 0.29), cloth)
	else:
		cuboid(torso, Vector3(0, 0.49, -0.155), Vector3(0.115, 0.20, 0.025), shirt)
		for side in [-1.0, 1.0]:
			var lapel := joint(torso, Vector3(side * 0.085, 0.47, -0.164))
			lapel.rotation.z = side * 0.28
			cuboid(lapel, Vector3.ZERO, Vector3(0.065, 0.21, 0.025), leather)
		cuboid(torso, Vector3(0, 0.43, -0.178), Vector3(0.036, 0.17, 0.025), dark)
	for side in [-1.0, 1.0]:
		var thigh := joint(hips, Vector3(side * 0.125, 0, 0))
		thighs.append(thigh)
		ellipsoid(thigh, Vector3(0, -0.19, 0), Vector3(0.22, 0.46, 0.24), pants)
		var knee := joint(thigh, Vector3(0, -0.42, 0))
		knees.append(knee)
		ellipsoid(knee, Vector3(0, -0.15, 0), Vector3(0.17, 0.36, 0.18), pants)
		cuboid(knee, Vector3(0, -0.365, -0.055), Vector3(0.18, 0.16, 0.30), leather)
		cuboid(knee, Vector3(0, -0.435, -0.055), Vector3(0.19, 0.035, 0.31), trim)
		var shoulder := joint(torso, Vector3(side * 0.265, 0.49, 0))
		shoulders.append(shoulder)
		ellipsoid(shoulder, Vector3(side * 0.035, -0.13, 0), Vector3(0.20, 0.35, 0.23), cloth)
		var elbow := joint(shoulder, Vector3(side * 0.035, -0.29, 0))
		elbows.append(elbow)
		ellipsoid(elbow, Vector3(0, -0.115, 0), Vector3(0.15, 0.27, 0.17), cloth)
		cuboid(elbow, Vector3(0, -0.235, 0), Vector3(0.14, 0.045, 0.16), shirt)
		ellipsoid(elbow, Vector3(0, -0.30, 0), Vector3(0.12, 0.16, 0.12), skin)
	# Stylized presentation-only prop, attached to the hand rig.
	held_prop = joint(elbows[1], Vector3(0, -0.33, -0.035))
	cuboid(held_prop, Vector3(0, -0.075, 0), Vector3(0.065, 0.22, 0.10), trim)
	cuboid(held_prop, Vector3(0, 0.015, 0.025), Vector3(0.065, 0.10, 0.09), leather)
	held_prop.hide()
	outfit = joint(torso, Vector3.ZERO)
	outfit.name = "FieldOutfit"
	match equipment:
		"light_armor":
			cuboid(outfit, Vector3(0, 0.36, -0.19), Vector3(0.36, 0.32, 0.095), leather)
			cuboid(outfit, Vector3(0, 0.36, 0.18), Vector3(0.37, 0.34, 0.09), leather)
			for side in [-1.0, 1.0]:
				cuboid(outfit, Vector3(side * 0.16, 0.55, 0), Vector3(0.065, 0.055, 0.34), trim)
		"utility_rig":
			for side in [-1.0, 1.0]:
				cuboid(outfit, Vector3(side * 0.17, 0.19, 0.05), Vector3(0.14, 0.15, 0.15), leather)
			cuboid(outfit, Vector3(0, 0.28, 0.22), Vector3(0.27, 0.27, 0.16), leather)
		"quiet_kit":
			for side in [-1.0, 1.0]:
				cuboid(outfit, Vector3(side * 0.19, 0.24, 0.04), Vector3(0.075, 0.14, 0.19), trim)
			cuboid(outfit, Vector3(0, 0.50, 0.18), Vector3(0.18, 0.10, 0.07), leather)

func trigger_shot() -> void:
	shot_pose = 1.0

func animate_pose(delta: float, speed: float, crouched: bool, aiming: bool, reloading := false) -> void:
	var blend := 1.0 - exp(-12.0 * delta)
	stride = lerpf(stride, clampf(speed / 3.6, 0.0, 1.25), blend)
	stance = lerpf(stance, 1.0 if crouched else 0.0, blend)
	aim_blend = lerpf(aim_blend, 1.0 if aiming and not reloading else 0.0, blend)
	shot_pose = move_toward(shot_pose, 0.0, delta * 7.0)
	reload_pose = lerpf(reload_pose, 1.0 if reloading else 0.0, blend)
	held_prop.visible = aim_blend > 0.15 or reload_pose > 0.15 or shot_pose > 0.0
	phase = fmod(phase + delta * speed * 2.1, TAU)
	hips.position.y = lerpf(0.89, 0.49, stance) + absf(sin(phase)) * stride * 0.02
	torso.rotation.x = lerpf(0.0, -0.72, stance)
	for i in range(2):
		var cycle := phase + float(i) * PI
		var swing := sin(cycle) * stride
		thighs[i].rotation.x = lerpf(0.0, 1.0, stance) + swing * lerpf(0.55, 0.24, stance)
		knees[i].rotation.x = lerpf(0.0, -1.9, stance) - maxf(0.0, sin(cycle)) * stride * 0.5
		shoulders[i].rotation.x = lerpf(-swing * 0.32, 0.95, aim_blend)
		elbows[i].rotation.x = lerpf(0.12 + maxf(0.0, -swing) * 0.32, 0.62, aim_blend)
		shoulders[i].rotation.x += shot_pose * 0.12 + reload_pose * 0.40
		elbows[i].rotation.x += shot_pose * 0.10 + reload_pose * (0.70 if i == 0 else 0.95)

func joint(parent: Node3D, at: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = at
	parent.add_child(node)
	return node

func make_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.83
	return mat

func ellipsoid(parent: Node3D, at: Vector3, dimensions: Vector3, mat: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := SphereMesh.new()
	geometry.radial_segments = 16
	geometry.rings = 8
	mesh.mesh = geometry
	mesh.scale = dimensions
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)

func cuboid(parent: Node3D, at: Vector3, dimensions: Vector3, mat: StandardMaterial3D) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = dimensions
	mesh.mesh = geometry
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)

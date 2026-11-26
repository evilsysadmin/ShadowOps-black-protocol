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

func build(uniform: Color, trousers: Color, security := false) -> void:
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
	if security:
		cuboid(torso, Vector3(-0.13, 0.45, -0.157), Vector3(0.075, 0.09, 0.02), trim)
		ellipsoid(torso, Vector3(0, 0.85, 0), Vector3(0.29, 0.11, 0.29), cloth)
	else:
		cuboid(torso, Vector3(0, 0.49, -0.155), Vector3(0.115, 0.20, 0.025), shirt)
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

func animate_pose(delta: float, speed: float, crouched: bool, aiming: bool) -> void:
	var blend := 1.0 - exp(-12.0 * delta)
	stride = lerpf(stride, clampf(speed / 3.6, 0.0, 1.25), blend)
	stance = lerpf(stance, 1.0 if crouched else 0.0, blend)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, blend)
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

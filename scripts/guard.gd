extends CharacterBody3D

const PATROL := [Vector3(0.8, 0.0, -6.0), Vector3(0.8, 0.0, 2.0)]
const SPEED := 1.45
var player: CharacterBody3D
var mission: Node
var waypoint := 1
var suspicion := 0.0
var health := 3
var body: Node3D
var status: Label3D
var pause_time := 0.0
var facing := Vector3.BACK

func _ready() -> void:
	player = get_parent().get_node("Agent") as CharacterBody3D
	mission = get_parent().get_node("Mission")
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	body = Node3D.new()
	add_child(body)
	part(Vector3(0, 1.24, 0), Vector3(0.52, 0.72, 0.33), Color(0.22, 0.28, 0.22))
	part(Vector3(0, 1.69, 0), Vector3(0.25, 0.30, 0.25), Color(0.57, 0.42, 0.32))
	part(Vector3(0, 1.82, 0), Vector3(0.29, 0.14, 0.29), Color(0.13, 0.17, 0.14))
	for side in [-1.0, 1.0]:
		part(Vector3(side * 0.14, 0.47, 0), Vector3(0.22, 0.86, 0.23), Color(0.11, 0.14, 0.12))
		part(Vector3(side * 0.34, 1.20, 0), Vector3(0.19, 0.65, 0.20), Color(0.22, 0.28, 0.22))
	status = Label3D.new()
	status.position.y = 2.05
	status.font_size = 42
	status.pixel_size = 0.004
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(status)
	update_status()

func part(at: Vector3, size: Vector3, tint: Color) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := SphereMesh.new()
	geometry.radial_segments = 16
	geometry.rings = 8
	mesh.mesh = geometry
	mesh.scale = size
	mesh.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mesh.material_override = mat
	body.add_child(mesh)

func _physics_process(delta: float) -> void:
	if health <= 0 or not bool(player.get("controls_enabled")):
		velocity = Vector3.ZERO
		return
	if sees_player():
		suspicion = minf(1.0, suspicion + delta * (0.24 if bool(player.get("crouched")) else 0.55))
		velocity.x = 0.0
		velocity.z = 0.0
		var direction := player.global_position - global_position
		direction.y = 0.0
		if direction.length_squared() > 0.001:
			facing = direction.normalized()
	else:
		suspicion = maxf(0.0, suspicion - delta * 0.3)
		patrol(delta)
	rotation.y = atan2(-facing.x, -facing.z)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	update_status()
	if suspicion >= 1.0:
		mission.call("guard_detected")

func patrol(delta: float) -> void:
	if pause_time > 0.0:
		pause_time -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var target: Vector3 = PATROL[waypoint]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 0.15:
		waypoint = (waypoint + 1) % PATROL.size()
		pause_time = 0.8
		velocity.x = 0.0
		velocity.z = 0.0
		return
	facing = offset.normalized()
	velocity.x = facing.x * SPEED
	velocity.z = facing.z * SPEED

func sees_player() -> bool:
	var origin := global_position + Vector3(0, 1.65, 0)
	var target := player.global_position + Vector3(0, float(player.call("eye_height")), 0)
	var offset := target - origin
	var sight_range := 3.8 if bool(player.get("crouched")) else 5.5
	if offset.length() > sight_range:
		return false
	var horizontal := Vector3(offset.x, 0, offset.z)
	if horizontal.length() > 0.65 and facing.dot(horizontal.normalized()) < 0.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == player

func receive_hit(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		collision_layer = 0
		collision_mask = 0
		body.rotation.z = PI * 0.5
		body.position.y = 0.3
		update_status()
	else:
		suspicion = maxf(suspicion, 0.5)
		update_status()

func update_status() -> void:
	if health == 0:
		status.text = "DOWN"
		status.modulate = Color(0.55, 0.65, 0.65)
	elif suspicion > 0.0:
		status.text = "SUSPICION %d%%" % int(suspicion * 100.0)
		status.modulate = Color(1.0, 0.64, 0.24)
	else:
		status.text = "PATROL"
		status.modulate = Color(0.55, 0.85, 0.65)

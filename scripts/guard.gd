extends CharacterBody3D

var patrol_points: Array[Vector3] = [Vector3(0.8, 0.0, -6.0), Vector3(0.8, 0.0, 2.0)]
const SPEED := 1.45
var player: CharacterBody3D
var mission: Node
var waypoint := 1
var suspicion := 0.0
var health := 3
const VisualRig = preload("res://scripts/character_visual.gd")
var body: VisualRig
var status: Label3D
var pause_time := 0.0
var facing := Vector3.BACK
enum GuardState { PATROL, SUSPICIOUS, ALERT, SEARCH, DOWN }
var state: GuardState = GuardState.PATROL
var attack_timer := 0.0
var search_remaining := 0.0
var ever_alerted := false
var search_from_alert := false
var last_seen_position := Vector3.ZERO
var has_last_seen := false
var search_moving := false
const SEARCH_DURATION := 4.0
const ATTACK_INTERVAL := 1.35
const ATTACK_DAMAGE := 15

func _ready() -> void:
	add_to_group("field_security")
	player = get_parent().get_node("Agent") as CharacterBody3D
	mission = get_parent().get_node("Mission")
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.8
	collider.shape = shape
	collider.position.y = 0.9
	add_child(collider)
	body = VisualRig.new()
	add_child(body)
	body.build(Color(0.22, 0.28, 0.22), Color(0.11, 0.14, 0.12), true)
	status = Label3D.new()
	status.position.y = 2.05
	status.font_size = 42
	status.pixel_size = 0.004
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(status)
	update_status()

func _physics_process(delta: float) -> void:
	if health <= 0 or not bool(player.get("controls_enabled")):
		velocity = Vector3.ZERO
		if health > 0:
			body.animate_pose(delta, 0.0, false, false)
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	var visible := sees_player()
	if visible:
		remember_sighting(player.global_position)
		velocity.x = 0.0
		velocity.z = 0.0
		face_player()
		update_detection(delta, bool(player.get("crouched")))
		if state == GuardState.ALERT and attack_timer <= 0.0:
			body.trigger_shot()
			player.call("receive_damage", ATTACK_DAMAGE)
			attack_timer = ATTACK_INTERVAL
	elif state == GuardState.ALERT:
		begin_search(true)
	elif state == GuardState.SEARCH:
		advance_search(delta, global_position)
	else:
		suspicion = maxf(0.0, suspicion - delta * 0.3)
		state = GuardState.SUSPICIOUS if suspicion > 0.0 else GuardState.PATROL
		patrol(delta)
	rotation.y = atan2(-facing.x, -facing.z)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	body.animate_pose(delta, actual_speed, false, state == GuardState.ALERT and visible)
	update_status()

# A curious guard must identify the player; a recently alerted guard can reacquire immediately.
func update_detection(delta: float, player_crouched: bool) -> void:
	if state == GuardState.ALERT or (state == GuardState.SEARCH and search_from_alert):
		enter_alert(false)
		return
	suspicion = minf(1.0, suspicion + delta * (0.24 if player_crouched else 0.55))
	state = GuardState.SUSPICIOUS
	search_from_alert = false
	if suspicion >= 1.0:
		enter_alert(true)

func enter_alert(reset_attack: bool) -> void:
	var new_alert := state != GuardState.ALERT and not (state == GuardState.SEARCH and search_from_alert)
	state = GuardState.ALERT
	ever_alerted = true
	suspicion = 1.0
	if reset_attack:
		attack_timer = ATTACK_INTERVAL
	if new_alert and is_instance_valid(mission):
		mission.call("notify_security_alert", self)

# A shared alert changes readiness, not personal perception or remembered positions.
func receive_security_alert() -> void:
	if health <= 0 or state == GuardState.ALERT or (state == GuardState.SEARCH and search_from_alert):
		return
	ever_alerted = true
	has_last_seen = false
	begin_search(true)
	attack_timer = ATTACK_INTERVAL
	if is_instance_valid(status):
		update_status()

# Fictional one-charge gadget: causes a temporary investigation, never erases alert history.
func request_distraction() -> bool:
	if health <= 0 or state not in [GuardState.PATROL, GuardState.SUSPICIOUS]:
		return false
	begin_search(false)
	if is_instance_valid(status):
		update_status()
	return true

func begin_search(from_alert: bool) -> void:
	state = GuardState.SEARCH
	search_from_alert = from_alert
	search_remaining = SEARCH_DURATION
	search_moving = from_alert and has_last_seen
	velocity.x = 0.0
	velocity.z = 0.0

func remember_sighting(at: Vector3) -> void:
	last_seen_position = at
	has_last_seen = true

# Uses only the last visible position, never the hidden player's current position.
func advance_search(delta: float, at: Vector3) -> void:
	search_remaining = maxf(0.0, search_remaining - delta)
	if search_remaining <= 0.0:
		state = GuardState.PATROL
		suspicion = 0.0
		search_from_alert = false
		search_moving = false
		has_last_seen = false
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if search_moving:
		var offset := last_seen_position - at
		offset.y = 0.0
		if offset.length() > 0.45 and search_remaining > 1.5:
			facing = offset.normalized()
			velocity.x = facing.x * SPEED
			velocity.z = facing.z * SPEED
			return
		search_moving = false
	velocity.x = 0.0
	velocity.z = 0.0
	facing = facing.rotated(Vector3.UP, delta * 1.4)

func face_player() -> void:
	var direction := player.global_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		facing = direction.normalized()

func patrol(delta: float) -> void:
	if pause_time > 0.0:
		pause_time -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if patrol_points.size() < 2:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var target: Vector3 = patrol_points[waypoint % patrol_points.size()]
	var offset := target - global_position
	offset.y = 0.0
	if offset.length() < 0.15:
		waypoint = (waypoint + 1) % patrol_points.size()
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
	var sight_range := 6.5 if state == GuardState.ALERT or state == GuardState.SEARCH else (3.8 if bool(player.get("crouched")) else 5.5)
	if offset.length() > sight_range:
		return false
	var horizontal := Vector3(offset.x, 0, offset.z)
	if state != GuardState.ALERT and horizontal.length() > 0.65 and facing.dot(horizontal.normalized()) < 0.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == player

func receive_hit(amount: int) -> void:
	if health <= 0 or amount <= 0:
		return
	health = maxi(0, health - amount)
	if health == 0:
		state = GuardState.DOWN
		collision_layer = 0
		collision_mask = 0
		body.rotation.z = PI * 0.5
		body.position.y = 0.3
		update_status()
	else:
		# A surviving hit is an actual alert, even before the next physics tick.
		if state != GuardState.ALERT:
			enter_alert(true)
		update_status()

func update_status() -> void:
	if health == 0:
		status.text = "DOWN"
		status.modulate = Color(0.55, 0.65, 0.65)
	elif state == GuardState.ALERT:
		status.text = "ALERT"
		status.modulate = Color(1.0, 0.26, 0.20)
	elif state == GuardState.SEARCH:
		status.text = ("CHECKING LAST SIGHTING" if search_moving else "SEARCHING") if search_from_alert else "INVESTIGATING"
		status.modulate = Color(1.0, 0.78, 0.28)
	elif suspicion > 0.0:
		status.text = "SUSPICION %d%%" % int(suspicion * 100.0)
		status.modulate = Color(1.0, 0.64, 0.24)
	else:
		status.text = "PATROL"
		status.modulate = Color(0.55, 0.85, 0.65)

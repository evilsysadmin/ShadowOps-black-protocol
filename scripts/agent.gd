extends CharacterBody3D

const WALK_SPEED := 3.6
const RUN_SPEED := 5.6
const ACCELERATION := 16.0
const SENSITIVITY := 0.003
const SUIT := Color(0.105, 0.135, 0.16)
const TROUSERS := Color(0.085, 0.105, 0.12)
const VisualRig = preload("res://scripts/character_visual.gd")
var pivot: Node3D
var model: VisualRig
var camera: Camera3D
var shoulder := 1.0
var controls_enabled := true
var field_mode := true
const EventAudio = preload("res://scripts/event_audio.gd")
var event_audio: EventAudio
var combat: Node
var aiming := false
var boom: SpringArm3D
var body_collider: CollisionShape3D
var body_capsule: CapsuleShape3D
var crouched := false
var cover_active := false
var cover_requested := false
var cover_normal := Vector3.ZERO
var cover_body: StaticBody3D
var cover_label: Label
const MAX_HEALTH := 100
var maximum_health := MAX_HEALTH
var health := MAX_HEALTH
var crouch_speed := 1.25
var sprint_speed := RUN_SPEED
var health_label: Label
var damage_overlay: ColorRect
var damage_flash := 0.0
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.12

func _ready() -> void:
	match Campaign.specialization:
		"resilience":
			maximum_health += 20
		"infiltration":
			crouch_speed = 1.65
		"mobility":
			sprint_speed = 6.4
	if field_mode:
		maximum_health += Campaign.kit_health_bonus()
	health = maximum_health
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.8
	collider.shape = capsule
	collider.position.y = 0.9
	body_collider = collider
	body_capsule = capsule
	add_child(collider)
	build_model()
	pivot = Node3D.new()
	pivot.position = Vector3(0.62, 1.63, 0)
	pivot.rotation.x = -0.10
	add_child(pivot)
	boom = SpringArm3D.new()
	boom.spring_length = 2.65
	boom.margin = 0.15
	boom.add_excluded_object(get_rid())
	var camera_shape := SphereShape3D.new()
	camera_shape.radius = 0.13
	boom.shape = camera_shape
	pivot.add_child(boom)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.current = true
	boom.add_child(camera)
	if field_mode:
		event_audio = EventAudio.new()
		add_child(event_audio)
		combat = Node.new()
		combat.set_script(preload("res://scripts/combat.gd"))
		add_child(combat)
	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.position = Vector2(24, 22)
	label.text = "BLACK PROTOCOL | FIELD TEST\nWASD · Shift sprint · Ctrl crouch · C cover · Q shoulder · E interact\nRMB aim · LMB fire · R reload · Esc release"
	if not field_mode:
		label.text = "BLACK PROTOCOL | SAFEHOUSE\nWASD · Mouse · E interact · Esc release"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(label)
	health_label = Label.new()
	health_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(health_label)
	health_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	health_label.offset_left = 24
	health_label.offset_top = -55
	health_label.offset_bottom = -20
	health_label.offset_right = 220
	health_label.add_theme_font_size_override("font_size", 22)
	refresh_health()
	cover_label = Label.new()
	cover_label.position = Vector2(24, 185)
	cover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cover_label)
	cover_label.visible = field_mode
	health_label.visible = field_mode
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(0.75, 0.08, 0.06, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_overlay)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func build_model() -> void:
	model = VisualRig.new()
	add_child(model)
	model.build(SUIT, TROUSERS)

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif field_mode and event.physical_keycode == KEY_R and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			combat.request_reload()
		elif field_mode and event.physical_keycode == KEY_C and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			cover_requested = true
		elif event.physical_keycode == KEY_Q:
			shoulder *= -1.0
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif field_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			combat.request_shot()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity := SENSITIVITY * (0.65 if field_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) else 1.0)
		rotate_y(-event.relative.x * sensitivity)
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * sensitivity, -0.65, 0.55)

func _physics_process(delta: float) -> void:
	damage_flash = move_toward(damage_flash, 0.0, delta * 1.8)
	damage_overlay.color.a = damage_flash
	var axes := Vector2.ZERO
	aiming = field_mode and controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		axes = Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		).limit_length()
	update_cover()
	update_stance(controls_enabled and (cover_active and not aiming or (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_physical_key_pressed(KEY_CTRL))), delta)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and not crouched
	var speed := crouch_speed if crouched else (2.0 if aiming else (sprint_speed if sprint else WALK_SPEED))
	var direction := transform.basis * Vector3(axes.x, 0, axes.y)
	if cover_active:
		direction = direction.slide(cover_normal)
		var lateral_velocity := Vector3(velocity.x, 0, velocity.z).slide(cover_normal)
		velocity.x = lateral_velocity.x
		velocity.z = lateral_velocity.z
		speed = minf(speed, 1.65)
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if cover_active and not cover_contact():
		leave_cover()
	if aiming:
		model.rotation.y = lerp_angle(model.rotation.y, 0.0, 1.0 - exp(-14.0 * delta))
	elif direction.length_squared() > 0.01:
		var local_direction := transform.basis.inverse() * direction
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-local_direction.x, -local_direction.z), 1.0 - exp(-12.0 * delta))
	update_camera_shoulder(delta)
	boom.spring_length = lerpf(boom.spring_length, 1.9 if aiming else 2.65, 1.0 - exp(-10.0 * delta))
	camera.fov = lerpf(camera.fov, 55.0 if aiming else 70.0, 1.0 - exp(-10.0 * delta))
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	model.animate_pose(delta, actual_speed, crouched, aiming)

func update_camera_shoulder(delta: float) -> void:
	# The spring arm handles rear clearance; independently check the lateral pivot.
	var desired := lerpf(pivot.position.x, shoulder * 0.62, 1.0 - exp(-10.0 * delta))
	var origin := global_position + Vector3(0, pivot.position.y, 0)
	var offset := global_transform.basis.x * desired
	if offset.length_squared() > 0.0001:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + offset)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var point: Vector3 = hit.get("position")
			desired = signf(desired) * maxf(0.0, origin.distance_to(point) - 0.15)
	pivot.position.x = desired

func update_cover() -> void:
	if not field_mode or not controls_enabled:
		leave_cover()
		cover_requested = false
		return
	if cover_requested:
		cover_requested = false
		if cover_active:
			leave_cover()
		else:
			var origin := global_position + Vector3(0, 0.75, 0)
			var forward := -global_transform.basis.z
			var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 1.0)
			query.exclude = [get_rid()]
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			var obstacle := hit.get("collider") as StaticBody3D
			if is_instance_valid(obstacle) and obstacle.is_in_group("low_cover"):
				var normal: Vector3 = hit.get("normal", Vector3.ZERO)
				normal.y = 0.0
				if normal.length_squared() > 0.5:
					cover_normal = normal.normalized()
					cover_body = obstacle
					cover_active = true
	if cover_active:
		if not cover_contact():
			leave_cover()
		else:
			cover_label.text = "IN COVER | C exit · RMB aim"
	else:
		cover_label.text = ""

func cover_contact() -> bool:
	if not is_instance_valid(cover_body):
		return false
	var origin := global_position + Vector3(0, 0.75, 0)
	var query := PhysicsRayQueryParameters3D.create(origin, origin - cover_normal * 1.05)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.get("collider") == cover_body

func leave_cover() -> void:
	cover_active = false
	cover_body = null
	cover_normal = Vector3.ZERO
	if is_instance_valid(cover_label):
		cover_label.text = ""

func update_stance(want_crouch: bool, delta: float) -> void:
	if want_crouch:
		crouched = true
	elif crouched and can_stand():
		crouched = false
	var height := CROUCH_HEIGHT if crouched else STAND_HEIGHT
	if not is_equal_approx(body_capsule.height, height):
		body_capsule.height = height
		body_collider.position.y = height * 0.5
	var blend := 1.0 - exp(-12.0 * delta)
	pivot.position.y = lerpf(pivot.position.y, 1.02 if crouched else 1.63, blend)

func can_stand() -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = body_capsule.radius
	shape.height = STAND_HEIGHT - CROUCH_HEIGHT + shape.radius * 2.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, (STAND_HEIGHT + CROUCH_HEIGHT) * 0.5 - shape.radius, 0))
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func receive_damage(amount: int) -> void:
	if not field_mode or not controls_enabled or amount <= 0:
		return
	health = maxi(0, health - amount)
	play_cue("damage")
	damage_flash = 0.30
	refresh_health()
	if health == 0:
		get_parent().get_node("Mission").call("agent_incapacitated")

func play_cue(key: String) -> void:
	if is_instance_valid(event_audio):
		event_audio.cue(key)

func refresh_health() -> void:
	health_label.text = "HEALTH %d / %d" % [health, maximum_health]
	health_label.modulate = Color(1.0, 0.38, 0.30) if health <= 30 else Color(0.85, 0.95, 0.90)

func eye_height() -> float:
	return 0.88 if crouched else 1.45


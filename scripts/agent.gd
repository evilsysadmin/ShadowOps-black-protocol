extends CharacterBody3D

const WALK_SPEED := 3.6
const RUN_SPEED := 5.6
const ACCELERATION := 16.0
const SENSITIVITY := 0.003
const SUIT := Color(0.105, 0.135, 0.16)
const TROUSERS := Color(0.085, 0.105, 0.12)
const SKIN := Color(0.58, 0.39, 0.29)
var pivot: Node3D
var model: Node3D
var camera: Camera3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var phase := 0.0
var stride := 0.0
var shoulder := 1.0
var controls_enabled := true
var combat: Node
var aiming := false
var boom: SpringArm3D
var body_collider: CollisionShape3D
var body_capsule: CapsuleShape3D
var crouched := false
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
	combat = Node.new()
	combat.set_script(preload("res://scripts/combat.gd"))
	add_child(combat)
	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.position = Vector2(24, 22)
	label.text = "BLACK PROTOCOL | FIELD TEST\nWASD · Shift sprint · Ctrl crouch · Q shoulder · E interact\nRMB aim · LMB fire · R reload · Esc release"
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
	damage_overlay = ColorRect.new()
	damage_overlay.color = Color(0.75, 0.08, 0.06, 0.0)
	damage_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(damage_overlay)
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func build_model() -> void:
	model = Node3D.new()
	add_child(model)
	ellipsoid(model, Vector3(0, 1.27, 0), Vector3(0.51, 0.62, 0.34), SUIT)
	ellipsoid(model, Vector3(0, 0.96, 0), Vector3(0.39, 0.25, 0.29), TROUSERS)
	ellipsoid(model, Vector3(0, 1.54, 0), Vector3(0.15, 0.16, 0.15), SKIN)
	ellipsoid(model, Vector3(0, 1.69, 0), Vector3(0.245, 0.31, 0.25), SKIN)
	ellipsoid(model, Vector3(0, 1.76, 0.025), Vector3(0.25, 0.18, 0.24), Color(0.075, 0.055, 0.045))
	ellipsoid(model, Vector3(0, 1.40, -0.15), Vector3(0.13, 0.26, 0.06), Color(0.53, 0.55, 0.55))
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.12, 0.92, 0)
		model.add_child(leg)
		legs.append(leg)
		ellipsoid(leg, Vector3(0, -0.23, 0), Vector3(0.21, 0.49, 0.22), TROUSERS)
		ellipsoid(leg, Vector3(0, -0.63, 0), Vector3(0.17, 0.40, 0.18), TROUSERS)
		ellipsoid(leg, Vector3(0, -0.84, -0.055), Vector3(0.19, 0.14, 0.33), Color(0.045, 0.055, 0.06))
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.29, 1.44, 0)
		model.add_child(arm)
		arms.append(arm)
		ellipsoid(arm, Vector3(side * 0.025, -0.16, 0), Vector3(0.20, 0.35, 0.23), SUIT)
		ellipsoid(arm, Vector3(side * 0.04, -0.44, 0), Vector3(0.15, 0.28, 0.17), SUIT)
		ellipsoid(arm, Vector3(side * 0.04, -0.61, 0), Vector3(0.13, 0.17, 0.12), SKIN)

func ellipsoid(parent: Node3D, at: Vector3, dimensions: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := SphereMesh.new()
	geometry.radial_segments = 16
	geometry.rings = 8
	mesh.mesh = geometry
	mesh.scale = dimensions
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_R and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			combat.request_reload()
		elif event.physical_keycode == KEY_Q:
			shoulder *= -1.0
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif aiming:
			combat.request_shot()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * SENSITIVITY, -0.65, 0.55)

func _physics_process(delta: float) -> void:
	damage_flash = move_toward(damage_flash, 0.0, delta * 1.8)
	damage_overlay.color.a = damage_flash
	var axes := Vector2.ZERO
	aiming = controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		axes = Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		).limit_length()
	update_stance(controls_enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_physical_key_pressed(KEY_CTRL), delta)
	var sprint := Input.is_physical_key_pressed(KEY_SHIFT) and not crouched
	var speed := crouch_speed if crouched else (2.0 if aiming else (sprint_speed if sprint else WALK_SPEED))
	var direction := transform.basis * Vector3(axes.x, 0, axes.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if aiming:
		model.rotation.y = lerp_angle(model.rotation.y, 0.0, 1.0 - exp(-14.0 * delta))
	elif axes.length_squared() > 0.01:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(-axes.x, -axes.y), 1.0 - exp(-12.0 * delta))
	pivot.position.x = lerpf(pivot.position.x, shoulder * 0.62, 1.0 - exp(-10.0 * delta))
	boom.spring_length = lerpf(boom.spring_length, 1.9 if aiming else 2.65, 1.0 - exp(-10.0 * delta))
	camera.fov = lerpf(camera.fov, 55.0 if aiming else 70.0, 1.0 - exp(-10.0 * delta))
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	stride = lerpf(stride, clampf(actual_speed / WALK_SPEED, 0.0, 1.35), 1.0 - exp(-12.0 * delta))
	phase += delta * (5.0 + actual_speed * 1.4)
	for i in range(2):
		var swing := sin(phase + float(i) * PI) * stride
		legs[i].rotation.x = swing * 0.56
		arms[i].rotation.x = -swing * 0.38
	if aiming:
		arms[1].rotation.x = -1.35
	model.position.y = absf(sin(phase)) * stride * 0.035

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
	model.scale.y = lerpf(model.scale.y, 0.64 if crouched else 1.0, blend)
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
	if not controls_enabled or amount <= 0:
		return
	health = maxi(0, health - amount)
	damage_flash = 0.30
	refresh_health()
	if health == 0:
		get_parent().get_node("Mission").call("agent_incapacitated")

func refresh_health() -> void:
	health_label.text = "HEALTH %d / %d" % [health, maximum_health]
	health_label.modulate = Color(1.0, 0.38, 0.30) if health <= 30 else Color(0.85, 0.95, 0.90)

func eye_height() -> float:
	return 0.88 if crouched else 1.45


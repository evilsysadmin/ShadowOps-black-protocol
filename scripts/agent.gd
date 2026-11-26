extends CharacterBody3D

const SPEED := 4.0
const SENSITIVITY := 0.003
var pivot: Node3D
var model: Node3D

func _ready() -> void:
	var collider := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.875
	add_child(collider)
	model = Node3D.new()
	add_child(model)
	part(Vector3(0, 1.15, 0), Vector3(0.53, 0.68, 0.32), Color(0.12, 0.15, 0.19))
	part(Vector3(0, 1.67, 0), Vector3(0.26, 0.29, 0.25), Color(0.56, 0.40, 0.31))
	for x in [-0.15, 0.15]:
		part(Vector3(x, 0.43, 0), Vector3(0.24, 0.86, 0.27), Color(0.09, 0.11, 0.13))
	for x in [-0.36, 0.36]:
		part(Vector3(x, 1.12, 0), Vector3(0.18, 0.62, 0.2), Color(0.12, 0.15, 0.19))
	pivot = Node3D.new()
	pivot.position = Vector3(0.65, 1.65, 0)
	add_child(pivot)
	var boom := SpringArm3D.new()
	boom.spring_length = 3.1
	boom.margin = 0.15
	boom.add_excluded_object(get_rid())
	pivot.add_child(boom)
	var camera := Camera3D.new()
	camera.fov = 72.0
	camera.current = true
	boom.add_child(camera)
	var hud := CanvasLayer.new()
	add_child(hud)
	var label := Label.new()
	label.position = Vector2(24, 22)
	label.text = "BLACK PROTOCOL | HOTEL PROTOTYPE\nWASD / arrows: move   Mouse: look   Esc: release mouse\nClick to capture mouse"
	hud.add_child(label)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func part(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	mesh.position = at
	model.add_child(mesh)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		pivot.rotation.x = clampf(pivot.rotation.x - event.relative.y * SENSITIVITY, -0.65, 0.55)

func _physics_process(delta: float) -> void:
	var axes := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).limit_length()
	var direction := transform.basis * Vector3(axes.x, 0, axes.y)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	move_and_slide()

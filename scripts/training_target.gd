extends StaticBody3D

var health := 3
var panel: MeshInstance3D
var status: Label3D

func _ready() -> void:
	var bounds := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.65, 1.5, 0.2)
	bounds.shape = shape
	bounds.position.y = 0.85
	add_child(bounds)
	panel = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = shape.size
	panel.mesh = mesh
	panel.position.y = 0.85
	add_child(panel)
	status = Label3D.new()
	status.position.y = 1.85
	status.font_size = 42
	status.pixel_size = 0.004
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(status)
	update_visual()

func receive_hit(amount: int) -> void:
	if health <= 0:
		return
	health = maxi(0, health - amount)
	update_visual()
	if health == 0:
		collision_layer = 0
		panel.rotation.x = PI * 0.5

func update_visual() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.25, 0.17) if health > 0 else Color(0.15, 0.48, 0.37)
	panel.material_override = mat
	status.text = "TRAINING TARGET %d/3" % health if health > 0 else "TARGET DOWN"

extends Node

var agent: CharacterBody3D
var reticle: Label
var feedback: Label
var pending := false
var cooldown := 0.0
var feedback_time := 0.0
const MAGAZINE_SIZE := 8
const RELOAD_DURATION := 1.25
var rounds := MAGAZINE_SIZE
var reserve := 24
var reload_remaining := 0.0
var ammo_label: Label
var reload_requested := false
var hit_flash := 0.0
var impact_mark: MeshInstance3D
var impact_time := 0.0

func _ready() -> void:
	agent = get_parent() as CharacterBody3D
	reserve = Campaign.kit_reserve()
	var hud := CanvasLayer.new()
	hud.layer = 3
	add_child(hud)
	reticle = Label.new()
	reticle.text = "+"
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(reticle)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	reticle.offset_left = -15
	reticle.offset_right = 15
	reticle.offset_top = -15
	reticle.offset_bottom = 15
	reticle.add_theme_font_size_override("font_size", 23)
	reticle.hide()
	feedback = Label.new()
	feedback.position = Vector2(24, 150)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(feedback)
	ammo_label = Label.new()
	ammo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(ammo_label)
	ammo_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.offset_left = -240
	ammo_label.offset_right = -24
	ammo_label.offset_top = -55
	ammo_label.offset_bottom = -20
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ammo_label.add_theme_font_size_override("font_size", 22)
	update_ammo()
	impact_mark = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.045
	sphere.height = 0.09
	impact_mark.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.76, 0.36)
	impact_mark.material_override = mat
	agent.add_child(impact_mark)
	impact_mark.top_level = true
	impact_mark.hide()

func request_shot() -> void:
	pending = true

func request_reload() -> void:
	reload_requested = true

func update_ammo() -> void:
	ammo_label.text = "%02d / %02d" % [rounds, reserve]
	if reload_remaining > 0.0:
		ammo_label.text += "  RELOADING"

func _physics_process(delta: float) -> void:
	hit_flash = maxf(0.0, hit_flash - delta)
	impact_time = maxf(0.0, impact_time - delta)
	impact_mark.visible = impact_time > 0.0
	reticle.text = "×" if hit_flash > 0.0 else "+"
	reticle.modulate = Color(1.0, 0.70, 0.32) if hit_flash > 0.0 else Color.WHITE
	cooldown = maxf(0.0, cooldown - delta)
	feedback_time = maxf(0.0, feedback_time - delta)
	if feedback_time <= 0.0:
		feedback.text = ""
	var active := bool(agent.get("controls_enabled"))
	var aiming: bool = agent.get("aiming")
	reticle.visible = aiming and active
	if not active:
		pending = false
		reload_requested = false
		reload_remaining = 0.0
		update_ammo()
		return
	if reload_remaining > 0.0:
		reload_remaining = maxf(0.0, reload_remaining - delta)
		if reload_remaining <= 0.0:
			var transferred := mini(MAGAZINE_SIZE - rounds, reserve)
			rounds += transferred
			reserve -= transferred
	elif reload_requested and rounds < MAGAZINE_SIZE and reserve > 0:
		reload_remaining = RELOAD_DURATION
	elif pending and aiming and cooldown <= 0.0:
		if rounds > 0:
			rounds -= 1
			fire()
			cooldown = 0.28
		else:
			feedback.text = "EMPTY — R TO RELOAD" if reserve > 0 else "NO AMMO"
			feedback_time = 0.65
	pending = false
	reload_requested = false
	update_ammo()

func fire() -> void:
	var camera: Camera3D = agent.get("camera")
	var center := camera.get_viewport().get_visible_rect().size * 0.5
	var origin := camera.project_ray_origin(center)
	var endpoint := origin + camera.project_ray_normal(center) * 40.0
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.exclude = [agent.get_rid()]
	var space := agent.get_world_3d().direct_space_state
	var hit := space.intersect_ray(query)
	var aim_point: Vector3 = hit.get("position", endpoint)
	var muzzle := agent.global_position + Vector3(0, float(agent.call("eye_height")), 0)
	# Resolve from the character as well, so the camera cannot fire through cover.
	var shot := PhysicsRayQueryParameters3D.create(muzzle, aim_point + (aim_point - muzzle).normalized() * 0.05)
	shot.exclude = [agent.get_rid()]
	var impact := space.intersect_ray(shot)
	feedback.text = "MISS"
	if not impact.is_empty():
		var position_hit: Vector3 = impact.get("position")
		impact_mark.global_position = position_hit
		impact_time = 0.14
		impact_mark.show()
		var target: Object = impact.get("collider")
		feedback.text = "IMPACT"
		if is_instance_valid(target) and target.has_method("receive_hit"):
			target.call("receive_hit", 1)
			feedback.text = "TARGET HIT"
			hit_flash = 0.18
	feedback_time = 0.65

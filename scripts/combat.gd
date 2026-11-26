extends Node

var agent: CharacterBody3D
var reticle: Label
var feedback: Label
var pending := false
var cooldown := 0.0
var feedback_time := 0.0

func _ready() -> void:
	agent = get_parent() as CharacterBody3D
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

func request_shot() -> void:
	pending = true

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	feedback_time = maxf(0.0, feedback_time - delta)
	if feedback_time <= 0.0:
		feedback.text = ""
	var aiming: bool = agent.get("aiming")
	reticle.visible = aiming
	if pending and aiming and cooldown <= 0.0:
		fire()
		cooldown = 0.28
	pending = false

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
		var target: Object = impact.get("collider")
		feedback.text = "IMPACT"
		if is_instance_valid(target) and target.has_method("receive_hit"):
			target.call("receive_hit", 1)
			feedback.text = "TARGET HIT"
	feedback_time = 0.65

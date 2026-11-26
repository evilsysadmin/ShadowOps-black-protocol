extends Node3D

enum Stage { RECOVER, EXTRACT, COMPLETE, FAILED, DEBRIEF }
enum IntelDecision { UNDECIDED, SHARE, RETAIN }
var intel_decision: IntelDecision = IntelDecision.UNDECIDED
var campaign_replay := false
var record_failed := false
var specialization_save_failed := false
var decision_label: Label
var report_label: Label
var elapsed_seconds := 0.0

const INTEL_POINT := Vector3(-3.65, 1.38, -3.92)
const EXIT_POINT := Vector3(0, 0.65, 9)
const REACH := 1.85
var stage: Stage = Stage.RECOVER
var player: CharacterBody3D
var intel: Node3D
var exit: Node3D
var objective: Label
var prompt: Label
var interact_requested := false

func _ready() -> void:
	player = get_parent().get_node("Agent") as CharacterBody3D
	campaign_replay = not Campaign.intel_choice.is_empty()
	intel = marker(INTEL_POINT, "INTEL", Color(0.28, 0.85, 0.78), false)
	exit = marker(EXIT_POINT, "EXTRACTION", Color(0.93, 0.72, 0.31), true)
	exit.hide()
	var hud := CanvasLayer.new()
	hud.layer = 2
	add_child(hud)
	objective = Label.new()
	objective.position = Vector2(24, 108)
	objective.add_theme_color_override("font_color", Color(0.66, 0.94, 0.90))
	hud.add_child(objective)
	prompt = Label.new()
	hud.add_child(prompt)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.offset_left = -280
	prompt.offset_right = 280
	prompt.offset_top = -75
	prompt.offset_bottom = -25
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 2)
	prompt.add_theme_constant_override("shadow_offset_y", 2)
	decision_label = Label.new()
	decision_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(decision_label)
	decision_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	decision_label.offset_left = -320
	decision_label.offset_right = 320
	decision_label.offset_top = -65
	decision_label.offset_bottom = 65
	decision_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	decision_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	decision_label.add_theme_font_size_override("font_size", 23)
	decision_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	decision_label.add_theme_constant_override("shadow_offset_x", 2)
	decision_label.add_theme_constant_override("shadow_offset_y", 2)
	decision_label.hide()
	report_label = Label.new()
	report_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(report_label)
	report_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	report_label.offset_left = -390
	report_label.offset_right = -24
	report_label.offset_top = 24
	report_label.offset_bottom = 160
	report_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	report_label.add_theme_font_size_override("font_size", 18)
	report_label.add_theme_color_override("font_color", Color(0.75, 0.89, 0.85))
	report_label.hide()
	refresh_objective()

func marker(at: Vector3, title: String, tint: Color, floor_marker: bool) -> Node3D:
	var root := Node3D.new()
	root.position = at
	add_child(root)
	var mesh := MeshInstance3D.new()
	var geometry := BoxMesh.new()
	geometry.size = Vector3(1.45, 0.035, 1.45) if floor_marker else Vector3(0.22, 0.06, 0.16)
	mesh.mesh = geometry
	mesh.position.y = -0.62 if floor_marker else 0.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mesh.material_override = mat
	root.add_child(mesh)
	var label := Label3D.new()
	label.text = title
	label.position.y = 0.45
	label.font_size = 38
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = tint
	root.add_child(label)
	return root

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if stage == Stage.DEBRIEF:
		if event.physical_keycode == KEY_1:
			resolve_intel(IntelDecision.SHARE)
		elif event.physical_keycode == KEY_2:
			resolve_intel(IntelDecision.RETAIN)
		return
	if stage == Stage.COMPLETE and Campaign.has_skill_point():
		var skill := ""
		match event.physical_keycode:
			KEY_3:
				skill = "resilience"
			KEY_4:
				skill = "infiltration"
			KEY_5:
				skill = "mobility"
		if not skill.is_empty():
			specialization_save_failed = not Campaign.choose_specialization(skill)
			refresh_objective()
			return
	if event.physical_keycode == KEY_R and (stage == Stage.COMPLETE or stage == Stage.FAILED):
		get_tree().change_scene_to_file("res://scenes/safehouse.tscn")
	elif event.physical_keycode == KEY_E and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		interact_requested = true

func _physics_process(delta: float) -> void:
	if stage == Stage.COMPLETE or stage == Stage.FAILED or stage == Stage.DEBRIEF:
		interact_requested = false
		return
	elapsed_seconds += delta
	var target := INTEL_POINT if stage == Stage.RECOVER else EXIT_POINT
	var reachable := can_reach(target)
	prompt.text = ""
	if reachable:
		prompt.text = "[E] Recover intel" if stage == Stage.RECOVER else "[E] Extract"
	if interact_requested and reachable and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if stage == Stage.RECOVER:
			stage = Stage.EXTRACT
			intel.hide()
			exit.show()
		else:
			stage = Stage.DEBRIEF
			player.set("controls_enabled", false)
			exit.hide()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		refresh_objective()
		if stage == Stage.EXTRACT:
			prompt.text = ""
	interact_requested = false

func resolve_intel(choice: IntelDecision) -> void:
	if stage != Stage.DEBRIEF or intel_decision != IntelDecision.UNDECIDED:
		return
	var key := ""
	if choice == IntelDecision.SHARE:
		key = "share"
	elif choice == IntelDecision.RETAIN:
		key = "retain"
	else:
		return
	if not campaign_replay and not Campaign.record_intel(key):
		record_failed = true
	intel_decision = choice
	stage = Stage.COMPLETE
	refresh_objective()

func agent_incapacitated() -> void:
	if stage == Stage.COMPLETE or stage == Stage.FAILED or stage == Stage.DEBRIEF:
		return
	stage = Stage.FAILED
	interact_requested = false
	player.set("controls_enabled", false)
	intel.hide()
	exit.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	refresh_objective()

func can_reach(target: Vector3) -> bool:
	var origin := player.global_position + Vector3(0, float(player.call("eye_height")), 0)
	if origin.distance_to(target) > REACH:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [player.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func refresh_objective() -> void:
	if stage == Stage.DEBRIEF or stage == Stage.COMPLETE or stage == Stage.FAILED:
		refresh_report()
	match stage:
		Stage.RECOVER:
			objective.text = "OPERATION: UNEXPECTED GUEST | Recover the intel at reception"
		Stage.EXTRACT:
			objective.text = "INTEL SECURED | Return to the starting area"
		Stage.DEBRIEF:
			objective.text = "EXTRACTION COMPLETE | Incoming secure transmission"
			prompt.text = "Choose who controls the information"
			decision_label.text = "HANDLER: We need the full file. Can I count on you?\n\n[1] Share the file — earn trust\n[2] Retain the file — gain leverage, lose trust"
			if campaign_replay:
				decision_label.text += "\nReplay — campaign decision will not change"
			decision_label.show()
		Stage.COMPLETE:
			objective.text = "OPERATION COMPLETE | Intel recovered and agent extracted"
			if record_failed:
				decision_label.text = "Choice made locally — campaign save unavailable"
			else:
				decision_label.text = "CAMPAIGN | HANDLER TRUST  %+d   |   LEVERAGE  %+d" % [Campaign.handler_trust(), Campaign.independent_leverage()]
				if campaign_replay:
					decision_label.text += "\nReplay choice not recorded; original decision preserved"
			if Campaign.has_skill_point():
				decision_label.text += "\n\n1 skill point — choose your specialization:\n[3] Resilience (+20 health)  [4] Infiltration (faster crouch)\n[5] Mobility (faster sprint)"
				if specialization_save_failed:
					decision_label.text += "\nSave failed — try the selection again"
			elif not Campaign.specialization.is_empty():
				decision_label.text += "\nSpecialization: " + Campaign.specialization.capitalize() + " (active next deployment)"
			decision_label.show()
			prompt.text = "Mission complete — press R to return to safehouse"
		Stage.FAILED:
			objective.text = "OPERATION FAILED | Agent incapacitated"
			prompt.text = "Compromised — press R to return to safehouse"

func refresh_report() -> void:
	var combat: Node = player.get("combat")
	var shots := int(combat.get("shots_fired"))
	var hits := int(combat.get("target_hits"))
	var damage := maxi(0, int(player.get("maximum_health")) - int(player.get("health")))
	var guard := get_parent().get_node_or_null("Guard")
	var security := "Unavailable"
	if is_instance_valid(guard):
		var alerted := bool(guard.get("ever_alerted"))
		var down := int(guard.get("health")) <= 0
		security = "Alerted" if alerted else "No full alert"
		if down:
			security += " / guard down"
	var accuracy := "—" if shots == 0 else "%d%%" % roundi(100.0 * float(hits) / float(shots))
	report_label.text = "FIELD REPORT\nElapsed: %d s · Damage: %d\nShots: %d · Target accuracy: %s\nSecurity: %s" % [int(elapsed_seconds), damage, shots, accuracy, security]
	report_label.show()

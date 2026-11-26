extends Node3D

const Operations = preload("res://scripts/operation_catalog.gd")
const Handler = preload("res://scripts/handler_dialogue.gd")
var radio_label: Label
var radio_remaining := 0.0
const RADIO_DURATION := 5.0

enum Stage { RECOVER, EXTRACT, COMPLETE, FAILED, DEBRIEF }
enum IntelDecision { UNDECIDED, SHARE, RETAIN }
var intel_decision: IntelDecision = IntelDecision.UNDECIDED
var campaign_replay := false
var record_failed := false
var specialization_save_failed := false
var decision_label: Label
var report_label: Label
var elapsed_seconds := 0.0
var final_field_report: Dictionary = {}

var intel_point := Vector3(-3.65, 1.38, -3.92)
var exit_point := Vector3(0, 0.65, 9)
var operation_id := Operations.HOTEL
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
	campaign_replay = Campaign.operation_completed(operation_id)
	intel = marker(intel_point, "DRIVE" if operation_id == Operations.RELAY else ("LEDGER" if operation_id == Operations.ARCHIVE else "INTEL"), Color(0.28, 0.85, 0.78), false)
	exit = marker(exit_point, "EXTRACTION", Color(0.93, 0.72, 0.31), true)
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
	radio_label = Label.new()
	radio_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(radio_label)
	radio_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	radio_label.offset_left = -390
	radio_label.offset_right = -24
	radio_label.offset_top = 24
	radio_label.offset_bottom = 120
	radio_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	radio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	radio_label.add_theme_font_size_override("font_size", 18)
	radio_label.add_theme_color_override("font_color", Color(0.75, 0.89, 0.85))
	radio_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	radio_label.add_theme_constant_override("shadow_offset_x", 2)
	radio_label.add_theme_constant_override("shadow_offset_y", 2)
	if operation_id == Operations.RELAY:
		var route := Campaign.relay_route()
		var sender := "HANDLER" if route == "handler" else ("ROOK" if route == "rook" else "AGENT")
		show_radio(sender + " / Locate the relay drive and return to the entry point.")
	else:
		show_radio(Handler.deployment_message(operation_id == Operations.ARCHIVE, Campaign.intel_choice))
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
	advance_radio(delta)
	var target := intel_point if stage == Stage.RECOVER else exit_point
	var reachable := can_reach(target)
	prompt.text = ""
	if reachable:
		prompt.text = ("[E] Recover drive" if operation_id == Operations.RELAY else ("[E] Recover ledger" if operation_id == Operations.ARCHIVE else "[E] Recover intel")) if stage == Stage.RECOVER else "[E] Extract"
	if interact_requested and reachable and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.call("play_cue", "objective")
		if stage == Stage.RECOVER:
			stage = Stage.EXTRACT
			show_radio("AGENT / Relay drive secured. Return to extraction." if operation_id == Operations.RELAY else Handler.recovered_message(operation_id == Operations.ARCHIVE, Campaign.intel_choice))
			intel.hide()
			exit.show()
		else:
			final_field_report = measure_field_report()
			if operation_id == Operations.RELAY:
				record_failed = not Campaign.record_relay(final_field_report)
				stage = Stage.COMPLETE
			elif operation_id == Operations.ARCHIVE:
				record_failed = not Campaign.record_archive(final_field_report)
				stage = Stage.COMPLETE
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
	if not campaign_replay and not Campaign.record_intel(key, final_field_report):
		record_failed = true
	intel_decision = choice
	stage = Stage.COMPLETE
	refresh_objective()

func agent_incapacitated() -> void:
	if stage == Stage.COMPLETE or stage == Stage.FAILED or stage == Stage.DEBRIEF:
		return
	stage = Stage.FAILED
	player.call("play_cue", "failure")
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
		clear_radio()
		refresh_report()
	match stage:
		Stage.RECOVER:
			objective.text = "OPERATION: NIGHT RELAY | Recover the drive" if operation_id == Operations.RELAY else ("OPERATION: SILENT ARCHIVE | Recover the ledger" if operation_id == Operations.ARCHIVE else "OPERATION: UNEXPECTED GUEST | Recover the intel at reception")
		Stage.EXTRACT:
			objective.text = "DRIVE SECURED | Return to extraction" if operation_id == Operations.RELAY else ("LEDGER SECURED | Return to extraction" if operation_id == Operations.ARCHIVE else "INTEL SECURED | Return to the starting area")
		Stage.DEBRIEF:
			objective.text = "EXTRACTION COMPLETE | Incoming secure transmission"
			prompt.text = "Choose who controls the information"
			decision_label.text = "HANDLER: We need the full file. Can I count on you?\n\n[1] Share the file — earn trust\n[2] Retain the file — gain leverage, lose trust"
			if campaign_replay:
				decision_label.text += "\nReplay — campaign decision will not change"
			decision_label.show()
		Stage.COMPLETE:
			objective.text = "OPERATION COMPLETE | Relay drive recovered" if operation_id == Operations.RELAY else ("OPERATION COMPLETE | Ledger recovered" if operation_id == Operations.ARCHIVE else "OPERATION COMPLETE | Intel recovered and agent extracted")
			if record_failed:
				decision_label.text = "Operation complete locally — campaign save unavailable"
			else:
				decision_label.text = "CAMPAIGN | HANDLER TRUST  %+d   |   LEVERAGE  %+d" % [Campaign.handler_trust(), Campaign.independent_leverage()]
				if campaign_replay:
					decision_label.text += "\nReplay — original campaign record preserved"
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

func measure_field_report() -> Dictionary:
	var combat: Node = player.get("combat")
	var guard := get_parent().get_node_or_null("Guard")
	if not is_instance_valid(guard) or not is_instance_valid(combat):
		return {}
	return {
		"seconds": int(elapsed_seconds),
		"damage": maxi(0, int(player.get("maximum_health")) - int(player.get("health"))),
		"shots": int(combat.get("shots_fired")),
		"hits": int(combat.get("target_hits")),
		"alerted": bool(guard.get("ever_alerted")),
		"guard_down": int(guard.get("health")) <= 0
	}

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
	if operation_id == Operations.ARCHIVE and stage == Stage.COMPLETE and not record_failed:
		var contract := Campaign.archive_contract_summary()
		if not contract.is_empty():
			report_label.text += "\n" + ("Archived contract: " if campaign_replay else "Contract: ") + contract
			report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report_label.show()

func show_radio(message: String) -> void:
	radio_label.text = message
	radio_remaining = RADIO_DURATION
	radio_label.show()

func advance_radio(delta: float) -> void:
	if radio_remaining <= 0.0:
		return
	radio_remaining = maxf(0.0, radio_remaining - delta)
	if radio_remaining <= 0.0:
		clear_radio()

func clear_radio() -> void:
	radio_remaining = 0.0
	radio_label.hide()

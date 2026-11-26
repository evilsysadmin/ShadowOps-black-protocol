extends Node

var failures := 0

func _ready() -> void:
	# Refuse to mutate campaign data unless the smoke runner has isolated user://.
	var root := OS.get_environment("BLACK_PROTOCOL_SMOKE_ROOT")
	var save_path := ProjectSettings.globalize_path("user://campaign.cfg").simplify_path()
	if root.is_empty() or not save_path.begins_with(root.simplify_path() + "/"):
		printerr("Campaign regression requires the isolated smoke runner.")
		get_tree().quit(2)
		return
	call_deferred("run_regression")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		printerr("REGRESSION FAIL: " + message)

func run_regression() -> void:
	check(Campaign.intel_choice.is_empty(), "fresh campaign has no decision")
	check(not Campaign.select_operation("silent_archive"), "archive locked initially")
	check(not Campaign.record_archive(), "archive cannot complete before hotel")
	check(not Campaign.has_skill_point(), "fresh campaign has no skill point")
	check(not Campaign.choose_specialization("resilience"), "no premature specialization")
	check(not Campaign.record_intel("invalid"), "invalid choice rejected")
	check(Campaign.select_deployment_kit("standard"), "standard kit accepted")
	check(Campaign.kit_health_bonus() == 0 and Campaign.kit_reserve() == 24, "standard kit values")
	check(Campaign.select_deployment_kit("protection"), "protection kit accepted")
	check(Campaign.kit_health_bonus() == 25 and Campaign.kit_reserve() == 16, "protection kit values")
	check(not Campaign.select_deployment_kit("invalid"), "invalid kit rejected")
	check(Campaign.deployment_kit == "protection", "invalid kit leaves selection intact")
	check(Campaign.select_deployment_kit("supplies"), "supplies kit accepted")
	check(Campaign.kit_health_bonus() == 0 and Campaign.kit_reserve() == 40, "supplies kit values")
	check(not FileAccess.file_exists("user://campaign.cfg"), "kit does not create campaign save")
	check(Campaign.record_intel("retain"), "record first mission")
	check(Campaign.select_operation("silent_archive"), "archive unlocked by hotel")
	check(Campaign.record_archive(), "archive completion recorded")
	check(Campaign.handler_trust() == -1 and Campaign.independent_leverage() == 1, "retain consequences")
	check(Campaign.has_skill_point(), "mission awards one skill point")
	check(Campaign.record_intel("share"), "replay accepted")
	check(Campaign.intel_choice == "retain", "replay preserves canonical decision")
	check(Campaign.choose_specialization("resilience"), "spend skill point")
	check(not Campaign.has_skill_point(), "no additional point")
	check(not Campaign.choose_specialization("mobility"), "second specialization rejected")
	var saved := ConfigFile.new()
	check(saved.load("user://campaign.cfg") == OK, "load persisted campaign")
	check(saved.get_value("missions", Campaign.MISSION_ID, "") == "retain", "decision persisted")
	check(saved.get_value("progression", "specialization", "") == "resilience", "specialization persisted")
	check(not saved.has_section("deployment"), "kit excluded from persistence")
	Campaign.intel_choice = ""
	Campaign.specialization = ""
	Campaign.archive_completed = false
	Campaign.load_campaign()
	check(Campaign.archive_completed, "archive completion survives specialization and reload")
	check(Campaign.intel_choice == "retain" and Campaign.specialization == "resilience", "reload restores campaign")
	check(Campaign.select_deployment_kit("protection"), "select protection for field test")
	var hotel: Node = preload("res://scenes/hotel.tscn").instantiate()
	add_child(hotel)
	await get_tree().physics_frame
	var agent := hotel.get_node_or_null("Agent")
	check(is_instance_valid(agent), "hotel agent exists")
	if is_instance_valid(agent):
		check(int(agent.get("maximum_health")) == 145, "resilience and protection stack")
		check(int(agent.get("health")) == 145, "spawn with full health")
		var combat: Node = agent.get("combat")
		check(is_instance_valid(combat), "field combat exists")
		if is_instance_valid(combat):
			check(int(combat.get("reserve")) == 16, "kit affects combat reserve")
	var guard := hotel.get_node_or_null("Guard")
	check(is_instance_valid(guard), "hotel guard exists")
	if is_instance_valid(guard):
		var guard_visual: Node3D = guard.get("body")
		check(is_instance_valid(guard_visual), "guard visual rig exists")
		if is_instance_valid(guard_visual):
			check(guard_visual.get("knees").size() == 2, "guard articulated knees")
			check(guard_visual.get("elbows").size() == 2, "guard articulated elbows")
	if is_instance_valid(agent):
		var field_agent := agent as CharacterBody3D
		field_agent.set_physics_process(false)
		field_agent.global_position = Vector3(-3.65, 0.05, 6.65)
		field_agent.rotation.y = 0.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		field_agent.set("cover_requested", true)
		field_agent.call("update_cover")
		check(bool(field_agent.get("cover_active")), "enter nearby low cover")
		if bool(field_agent.get("cover_active")):
			var normal: Vector3 = field_agent.get("cover_normal")
			check(normal.dot(Vector3.BACK) > 0.95, "cover normal matches barrier face")
			check(bool(field_agent.call("cover_contact")), "cover remains in contact")
		field_agent.set("cover_requested", true)
		field_agent.call("update_cover")
		check(not bool(field_agent.get("cover_active")), "toggle cover off")
		field_agent.set("cover_requested", true)
		field_agent.call("update_cover")
		check(bool(field_agent.get("cover_active")), "reenter low cover")
		field_agent.global_position = Vector3(-1.7, 0.05, 6.65)
		await get_tree().physics_frame
		await get_tree().physics_frame
		field_agent.call("update_cover")
		check(not bool(field_agent.get("cover_active")), "leave cover at edge")
	hotel.queue_free()
	await get_tree().process_frame
	var safehouse: Node = preload("res://scenes/safehouse.tscn").instantiate()
	add_child(safehouse)
	await get_tree().physics_frame
	var home_agent := safehouse.get_node_or_null("Agent")
	check(is_instance_valid(home_agent), "safehouse agent exists")
	if is_instance_valid(home_agent):
		check(int(home_agent.get("maximum_health")) == 120, "kit not applied in safehouse")
		check(home_agent.get("combat") == null, "safehouse combat disabled")
	safehouse.queue_free()
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if failures == 0:
		print("CAMPAIGN REGRESSION PASSED")
	get_tree().quit(0 if failures == 0 else 1)

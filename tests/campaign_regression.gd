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
	var operations := preload("res://scripts/operation_catalog.gd")
	var handler := preload("res://scripts/handler_dialogue.gd")
	check(handler.relationship("share") != handler.relationship("retain"), "handler remembers decision")
	check(handler.relationship("").contains("no field history"), "fresh relationship")
	check(handler.assessment({}).contains("unavailable"), "no fabricated historical assessment")
	check(operations.report_summary(false, {}) == "Not completed.", "pending operation report")
	check(operations.report_summary(true, {}).contains("no historical metrics"), "legacy completion report")
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
	var hotel_report := {"seconds": 40, "damage": 0, "shots": 0, "hits": 0, "alerted": false, "guard_down": false}
	check(not Campaign.record_intel("retain", {"seconds": -1}), "reject invalid field report")
	check(Campaign.record_intel("retain", hotel_report), "record first mission")
	check(Campaign.field_report("unexpected_guest") == hotel_report, "hotel performance stored")
	check(handler.assessment(hotel_report).contains("No shots, no damage"), "grounded clean assessment")
	check(operations.report_summary(true, hotel_report).contains("— accuracy"), "zero shots has no accuracy")
	hotel_report["seconds"] = 999
	check(Campaign.field_report("unexpected_guest")["seconds"] == 40, "report isolated from caller mutation")
	check(Campaign.select_operation("silent_archive"), "archive unlocked by hotel")
	var archive_report := {"seconds": 80, "damage": 15, "shots": 4, "hits": 3, "alerted": true, "guard_down": true}
	check(Campaign.record_archive(archive_report), "archive completion recorded")
	check(Campaign.field_report("silent_archive") == archive_report, "archive performance stored")
	check(handler.assessment(archive_report).contains("full alert and you took damage"), "grounded alert assessment")
	check(Campaign.record_archive({"seconds": 1}), "completed archive replay is ignored")
	check(Campaign.field_report("silent_archive") == archive_report, "archive replay preserves report")
	check(Campaign.handler_trust() == -1 and Campaign.independent_leverage() == 1, "retain consequences")
	check(Campaign.has_skill_point(), "mission awards one skill point")
	check(Campaign.record_intel("share"), "replay accepted")
	check(Campaign.intel_choice == "retain", "replay preserves canonical decision")
	check(Campaign.field_report("unexpected_guest")["seconds"] == 40, "replay preserves field report")
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
	Campaign.field_reports.clear()
	Campaign.load_campaign()
	check(Campaign.field_report("unexpected_guest").get("seconds") == 40 and Campaign.field_report("silent_archive") == archive_report, "reports survive specialization and reload")
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
	await check_archive_route("retain", Vector3(5.5, 0.05, 7.0))
	await check_archive_route("share", Vector3(-5.5, 0.05, -3.5))
	Campaign.load_campaign()
	check(Campaign.intel_choice == "retain", "route test restores canonical saved choice")
	var safehouse: Node = preload("res://scenes/safehouse.tscn").instantiate()
	add_child(safehouse)
	await get_tree().physics_frame
	var home_agent := safehouse.get_node_or_null("Agent")
	check(is_instance_valid(home_agent), "safehouse agent exists")
	if is_instance_valid(home_agent):
		check(int(home_agent.get("maximum_health")) == 120, "kit not applied in safehouse")
		check(home_agent.get("combat") == null, "safehouse combat disabled")
		var menu: CanvasLayer = home_agent.get("pause_menu")
		check(is_instance_valid(menu), "pause menu exists")
		if is_instance_valid(menu):
			menu.call("pause_game")
			check(get_tree().paused and bool(menu.get("owns_pause")), "pause suspends scene tree")
			menu.call("resume")
			check(not get_tree().paused and not bool(menu.get("owns_pause")), "resume restores scene tree")
			home_agent.set("controls_enabled", false)
			menu.call("pause_game")
			check(not get_tree().paused, "terminal state cannot pause")
			home_agent.set("controls_enabled", true)
		check(GameSettings.save_effects_volume(0.25), "save effects volume")
		var settings := ConfigFile.new()
		check(settings.load("user://settings.cfg") == OK, "load independent settings")
		check(is_equal_approx(float(settings.get_value("audio", "effects_volume", -1)), 0.25), "volume persisted")
		check(GameSettings.save_effects_volume(1.5) and is_equal_approx(GameSettings.effects_volume, 1.0), "volume clamped")
	safehouse.queue_free()
	await get_tree().process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if failures == 0:
		print("CAMPAIGN REGRESSION PASSED")
	get_tree().quit(0 if failures == 0 else 1)

func check_archive_route(choice: String, expected: Vector3) -> void:
	# Only the isolated test changes the in-memory choice; never write it.
	Campaign.intel_choice = choice
	var archive: Node = preload("res://scenes/archive.tscn").instantiate()
	add_child(archive)
	var agent := archive.get_node_or_null("Agent") as CharacterBody3D
	var mission := archive.get_node_or_null("Mission")
	var guard := archive.get_node_or_null("Guard")
	check(is_instance_valid(agent) and is_instance_valid(mission) and is_instance_valid(guard), "archive entities exist")
	if is_instance_valid(agent) and is_instance_valid(mission) and is_instance_valid(guard):
		agent.set_physics_process(false)
		guard.set_physics_process(false)
		check(agent.position.is_equal_approx(expected), choice + " correct spawn")
		var extraction: Vector3 = mission.get("exit_point")
		check(is_equal_approx(extraction.x, expected.x) and is_equal_approx(extraction.z, expected.z), choice + " matching extraction")
		check(guard.get("patrol_points").size() == 4, "archive-specific patrol")
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(bool(mission.call("can_reach", extraction)), choice + " extraction reachable at spawn")
		agent.global_position = Vector3(-3.0, 0.05, -5.0)
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(bool(mission.call("can_reach", mission.get("intel_point"))), choice + " ledger reachable")
	archive.queue_free()
	await get_tree().process_frame

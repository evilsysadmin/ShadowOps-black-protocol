extends Control

const HOTEL_SCENE := "res://scenes/hotel.tscn"
const ARCHIVE_SCENE := "res://scenes/archive.tscn"
const Operations = preload("res://scripts/operation_catalog.gd")
const SAFEHOUSE_SCENE := "res://scenes/safehouse.tscn"
var transitioning := false
var error_label: Label
var operation_selection: OptionButton
var operation_ids: Array[String] = []
var operation_title: Label
var operation_description: Label
var operation_status: Label
var intel_button: Button
var intel_confirmation: ConfirmationDialog
var kit_selection: OptionButton
var equipment_selection: OptionButton
var equipment_ids: Array[String] = [""]
var kit_description: Label
var agent_status: Label
var specialization_row: HBoxContainer
var specialization_selection: OptionButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var background := ColorRect.new()
	background.color = Color(0.055, 0.085, 0.10)
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_constant_override("separation", 7)
	center.add_child(panel)
	add_line(panel, "SHADOWOPS / OPERATIONS DIVISION", 18, Color(0.50, 0.80, 0.75))
	operation_ids = Campaign.available_operations()
	operation_selection = OptionButton.new()
	for operation in operation_ids:
		operation_selection.add_item(Operations.title_for(operation))
	panel.add_child(operation_selection)
	operation_title = add_line(panel, "", 36, Color(0.94, 0.94, 0.90))
	add_line(panel, "BRIEFING  /  CLASSIFIED", 16, Color(0.75, 0.64, 0.43))
	operation_description = add_line(panel, "", 20, Color(0.85, 0.89, 0.89))
	operation_status = add_line(panel, "", 17, Color(0.75, 0.64, 0.43))
	intel_button = Button.new()
	intel_button.pressed.connect(request_intel)
	panel.add_child(intel_button)
	intel_confirmation = ConfirmationDialog.new()
	intel_confirmation.confirmed.connect(purchase_intel)
	add_child(intel_confirmation)
	operation_selection.item_selected.connect(update_operation)
	var initial := operation_ids.size() - 1
	operation_selection.select(initial)
	update_operation(initial)
	agent_status = add_line(panel, "", 18, Color(0.66, 0.83, 0.80))
	refresh_agent_status()
	if Campaign.has_skill_point():
		build_specialization_row(panel)
	add_line(panel, "FIELD CONTROLS\nWASD move · Ctrl crouch · C cover · Shift sprint · E interact\nRMB aim · LMB fire · R reload", 17, Color(0.68, 0.73, 0.76))
	add_line(panel, "DEPLOYMENT KIT", 16, Color(0.75, 0.64, 0.43))
	kit_selection = OptionButton.new()
	kit_selection.add_item("Standard")
	kit_selection.add_item("Protection")
	kit_selection.add_item("Supplies")
	kit_selection.custom_minimum_size.y = 36
	panel.add_child(kit_selection)
	kit_description = add_line(panel, "", 17, Color(0.68, 0.83, 0.80))
	kit_selection.item_selected.connect(update_kit_description)
	kit_selection.select(0)
	update_kit_description(0)
	if not Campaign.equipment_owned.is_empty():
		equipment_selection = OptionButton.new()
		equipment_selection.add_item("Equipment slot: none")
		for item in Campaign.equipment_owned:
			equipment_ids.append(item)
			match item:
				"light_armor":
					equipment_selection.add_item("Light armor (+15 health)")
				"utility_rig":
					equipment_selection.add_item("Utility rig (+8 reserve rounds)")
				"quiet_kit":
					equipment_selection.add_item("Movement kit (+0.25 crouch speed)")
		var previous := equipment_ids.find(Campaign.deployment_equipment)
		equipment_selection.select(previous if previous >= 0 else 1)
		panel.add_child(equipment_selection)
	var audio_settings := HBoxContainer.new()
	audio_settings.set_script(preload("res://scripts/audio_settings.gd"))
	panel.add_child(audio_settings)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	panel.add_child(actions)
	var back := Button.new()
	back.text = "Return to safehouse"
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.custom_minimum_size.y = 44
	back.pressed.connect(_go.bind(SAFEHOUSE_SCENE))
	actions.add_child(back)
	var deploy := Button.new()
	deploy.text = "Deploy"
	deploy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	deploy.custom_minimum_size.y = 44
	deploy.pressed.connect(_deploy)
	actions.add_child(deploy)
	error_label = add_line(panel, "", 16, Color(1.0, 0.4, 0.35))
	deploy.grab_focus()

func update_operation(index: int) -> void:
	var operation := operation_ids[index]
	operation_title.text = Operations.title_for(operation)
	operation_description.text = Operations.description_for(operation, Campaign.intel_choice, Campaign.relay_route())
	var completed := Campaign.operation_completed(operation)
	operation_status.text = "REPLAY — original campaign record preserved." if completed else "NEW OPERATION"
	intel_button.visible = operation == Operations.ARCHIVE
	if operation == Operations.ARCHIVE:
		if Campaign.rook_contract_accepted:
			operation_status.text += "\nRook: " + Campaign.rook_contract_status()
		elif Campaign.handler_contract_accepted:
			operation_status.text += "\nHandler: " + Campaign.handler_contract_status()
		if Campaign.owns_archive_intel():
			operation_description.text += "\nRecon: records at the far end, guard patrols the central aisle."
			intel_button.text = "Recon acquired from %s · %d credits remaining" % [Campaign.archive_intel_source(), Campaign.available_credits()]
			intel_button.disabled = true
		else:
			intel_button.text = "%s recon (%d credits) · balance %d" % [Campaign.archive_intel_source(), Campaign.archive_intel_price(), Campaign.available_credits()]
			intel_button.disabled = Campaign.save_blocked or Campaign.available_credits() < Campaign.archive_intel_price()

func request_intel() -> void:
	if transitioning or operation_ids[operation_selection.selected] != Operations.ARCHIVE or Campaign.owns_archive_intel():
		return
	intel_confirmation.dialog_text = "Buy permanent archive reconnaissance from %s for %d credits?" % [Campaign.archive_intel_source(), Campaign.archive_intel_price()]
	intel_confirmation.popup_centered()

func purchase_intel() -> void:
	if transitioning or operation_ids[operation_selection.selected] != Operations.ARCHIVE:
		return
	if not Campaign.buy_archive_intel():
		error_label.text = "Unable to purchase reconnaissance."
		return
	error_label.text = ""
	update_operation(operation_selection.selected)

func _deploy() -> void:
	var operation := operation_ids[operation_selection.selected]
	if not Campaign.select_operation(operation):
		error_label.text = "Operation unavailable."
		return
	_go(Operations.scene_for(operation))

func refresh_agent_status() -> void:
	var skill := Campaign.specialization.capitalize() if not Campaign.specialization.is_empty() else "Unassigned"
	agent_status.text = "AGENT STATUS\nTrust: %+d    Leverage: %+d    Specialization: %s" % [Campaign.handler_trust(), Campaign.independent_leverage(), skill]
	if Campaign.has_skill_point():
		agent_status.text += " · 1 unspent point"

func build_specialization_row(panel: VBoxContainer) -> void:
	specialization_row = HBoxContainer.new()
	specialization_row.add_theme_constant_override("separation", 8)
	panel.add_child(specialization_row)
	specialization_selection = OptionButton.new()
	specialization_selection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	specialization_selection.add_item("Resilience (+20 health)")
	specialization_selection.add_item("Infiltration (faster crouch)")
	specialization_selection.add_item("Mobility (faster sprint)")
	specialization_selection.select(0)
	specialization_row.add_child(specialization_selection)
	var apply_button := Button.new()
	apply_button.text = "Confirm permanent choice"
	apply_button.pressed.connect(_choose_specialization)
	specialization_row.add_child(apply_button)

func _choose_specialization() -> void:
	if transitioning or not Campaign.has_skill_point():
		return
	var index := specialization_selection.selected
	if index < 0 or index >= Campaign.SPECIALIZATIONS.size():
		return
	if not Campaign.choose_specialization(Campaign.SPECIALIZATIONS[index]):
		error_label.text = "Unable to save specialization. Try again."
		return
	error_label.text = ""
	specialization_row.hide()
	refresh_agent_status()

func update_kit_description(index: int) -> void:
	match index:
		0:
			kit_description.text = "Balanced kit · 24 reserve rounds"
		1:
			kit_description.text = "+25 maximum health · 16 reserve rounds"
		2:
			kit_description.text = "40 reserve rounds · no health bonus"

func add_line(parent: VBoxContainer, message: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not intel_confirmation.visible:
		get_viewport().set_input_as_handled()
		_go(SAFEHOUSE_SCENE)

func _go(scene_path: String) -> void:
	if transitioning:
		return
	if scene_path != SAFEHOUSE_SCENE:
		var equipped := "" if not is_instance_valid(equipment_selection) else equipment_ids[equipment_selection.selected]
		if not Campaign.select_deployment_equipment(equipped):
			error_label.text = "Equipment selection unavailable."
			return
		if not Campaign.select_deployment_kit(Campaign.KITS[kit_selection.selected]):
			error_label.text = "Invalid deployment kit."
			return
	transitioning = true
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		transitioning = false
		error_label.text = "Unable to load destination (%d)." % result

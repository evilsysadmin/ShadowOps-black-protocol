extends Control

const HOTEL_SCENE := "res://scenes/hotel.tscn"
const SAFEHOUSE_SCENE := "res://scenes/safehouse.tscn"
var transitioning := false
var error_label: Label
var kit_selection: OptionButton
var kit_description: Label

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
	panel.add_theme_constant_override("separation", 10)
	center.add_child(panel)
	add_line(panel, "SHADOWOPS / OPERATIONS DIVISION", 18, Color(0.50, 0.80, 0.75))
	add_line(panel, "UNEXPECTED GUEST", 36, Color(0.94, 0.94, 0.90))
	add_line(panel, "BRIEFING  /  CLASSIFIED", 16, Color(0.75, 0.64, 0.43))
	add_line(panel, "Recover the intelligence file at hotel reception and return to extraction. Avoid unnecessary confrontation. A security patrol may compromise the operation.", 20, Color(0.85, 0.89, 0.89))
	if not Campaign.intel_choice.is_empty():
		add_line(panel, "REPLAY — Your original campaign decision will be preserved.", 17, Color(0.75, 0.64, 0.43))
	var skill := Campaign.specialization.capitalize() if not Campaign.specialization.is_empty() else "Unassigned"
	add_line(panel, "AGENT STATUS\nTrust: %+d    Leverage: %+d    Specialization: %s" % [Campaign.handler_trust(), Campaign.independent_leverage(), skill], 18, Color(0.66, 0.83, 0.80))
	add_line(panel, "FIELD CONTROLS\nWASD move · Ctrl crouch · Shift sprint · E interact\nRMB aim · LMB fire · R reload", 17, Color(0.68, 0.73, 0.76))
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
	deploy.pressed.connect(_go.bind(HOTEL_SCENE))
	actions.add_child(deploy)
	error_label = add_line(panel, "", 16, Color(1.0, 0.4, 0.35))
	deploy.grab_focus()

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
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go(SAFEHOUSE_SCENE)

func _go(scene_path: String) -> void:
	if transitioning:
		return
	if scene_path == HOTEL_SCENE:
		if not Campaign.select_deployment_kit(Campaign.KITS[kit_selection.selected]):
			error_label.text = "Invalid deployment kit."
			return
	transitioning = true
	var result := get_tree().change_scene_to_file(scene_path)
	if result != OK:
		transitioning = false
		error_label.text = "Unable to load destination (%d)." % result

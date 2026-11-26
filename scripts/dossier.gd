extends Control

const Operations = preload("res://scripts/operation_catalog.gd")
const SAFEHOUSE := "res://scenes/safehouse.tscn"
var transitioning := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.055, 0.085, 0.10)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 630
	panel.add_theme_constant_override("separation", 16)
	center.add_child(panel)
	line(panel, "SHADOWOPS / CLASSIFIED FIELD RECORDS", 18, Color(0.50, 0.80, 0.75))
	line(panel, "AGENT DOSSIER", 36, Color(0.94, 0.94, 0.90))
	line(panel, "Trust %+d   ·   Leverage %+d   ·   %s" % [Campaign.handler_trust(), Campaign.independent_leverage(), Campaign.specialization.capitalize() if not Campaign.specialization.is_empty() else "Unassigned"], 20, Color(0.75, 0.89, 0.85))
	if Campaign.save_blocked:
		line(panel, "Campaign file unavailable or incompatible.", 18, Color(1.0, 0.5, 0.4))
	for operation in [Operations.HOTEL, Operations.ARCHIVE]:
		var completed := Campaign.archive_completed if operation == Operations.ARCHIVE else not Campaign.intel_choice.is_empty()
		line(panel, Operations.title_for(operation), 24, Color(0.75, 0.64, 0.43))
		if not Campaign.available_operations().has(operation):
			line(panel, "Locked — complete the preceding operation.", 18, Color(0.64, 0.68, 0.70))
		else:
			line(panel, Operations.report_summary(completed, Campaign.field_report(operation)), 19, Color(0.85, 0.89, 0.89))
	line(panel, "Only the first recorded successful completion is archived.", 16, Color(0.64, 0.68, 0.70))
	var back := Button.new()
	back.text = "Return to safehouse"
	back.custom_minimum_size.y = 44
	back.pressed.connect(go_back)
	panel.add_child(back)
	back.grab_focus()

func line(parent: VBoxContainer, message: String, font_size: int, tint: Color) -> void:
	var label := Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()

func go_back() -> void:
	if transitioning:
		return
	transitioning = true
	if get_tree().change_scene_to_file(SAFEHOUSE) != OK:
		transitioning = false

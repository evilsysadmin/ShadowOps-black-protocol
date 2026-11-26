extends Control

const Handler = preload("res://scripts/handler_dialogue.gd")
var panel: VBoxContainer
var message: Label
var status: Label
var choices: VBoxContainer
var return_button: Button
var transitioning := false
var pending_choice := ""
var confirmation: ConfirmationDialog

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.035, 0.065, 0.08)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = VBoxContainer.new()
	panel.custom_minimum_size.x = 620
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)
	add_line("SHADOWOPS / ENCRYPTED CHANNEL", 18, Color(0.50, 0.80, 0.75))
	add_line("HANDLER", 34, Color(0.94, 0.94, 0.90))
	message = add_line("", 22, Color(0.85, 0.89, 0.89))
	status = add_line("", 18, Color(0.66, 0.83, 0.80))
	choices = VBoxContainer.new()
	choices.add_theme_constant_override("separation", 10)
	panel.add_child(choices)
	add_choice("Coordinate intelligence (+1 trust)", "coordinate")
	add_choice("Keep operational autonomy (-1 trust, +1 leverage)", "autonomy")
	return_button = Button.new()
	return_button.text = "Return to field records"
	return_button.custom_minimum_size.y = 44
	return_button.pressed.connect(go_back)
	panel.add_child(return_button)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Permanent campaign choice"
	confirmation.confirmed.connect(commit_choice)
	confirmation.canceled.connect(clear_pending)
	add_child(confirmation)
	refresh()
	return_button.grab_focus()

func add_line(content: String, size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", tint)
	panel.add_child(label)
	return label

func add_choice(content: String, choice: String) -> void:
	var button := Button.new()
	button.text = content
	button.custom_minimum_size.y = 46
	button.pressed.connect(request_choice.bind(choice))
	choices.add_child(button)

func refresh() -> void:
	choices.visible = Campaign.can_negotiate_handler()
	status.text = "Trust %+d   ·   Leverage %+d" % [Campaign.handler_trust(), Campaign.independent_leverage()]
	if Campaign.save_blocked:
		message.text = "Campaign file unavailable. No agreement can be saved."
	elif Campaign.intel_choice.is_empty():
		message.text = "Complete Unexpected Guest before negotiating an agreement."
	elif Campaign.handler_agreement.is_empty():
		message.text = Handler.negotiation_offer(Campaign.intel_choice)
	else:
		message.text = Handler.negotiation_reply(Campaign.handler_agreement)
		status.text += "   ·   Agreement recorded"

func request_choice(choice: String) -> void:
	if transitioning or not Campaign.can_negotiate_handler() or not Campaign.HANDLER_AGREEMENTS.has(choice):
		return
	pending_choice = choice
	confirmation.dialog_text = "Confirm coordination (+1 trust)?" if choice == "coordinate" else "Confirm autonomy (-1 trust, +1 leverage)?"
	confirmation.popup_centered()

func clear_pending() -> void:
	pending_choice = ""

func commit_choice() -> void:
	var choice := pending_choice
	clear_pending()
	if not Campaign.negotiate_handler(choice):
		refresh()
		status.text += "   ·   Unable to save agreement"
		return
	refresh()
	return_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmation.visible:
		get_viewport().set_input_as_handled()
		go_back()

func go_back() -> void:
	if transitioning:
		return
	transitioning = true
	if get_tree().change_scene_to_file("res://scenes/dossier.tscn") != OK:
		transitioning = false

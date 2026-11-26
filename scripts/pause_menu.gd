extends CanvasLayer

var agent: CharacterBody3D
var overlay: ColorRect
var resume_button: Button
var owns_pause := false

func _ready() -> void:
	agent = get_parent() as CharacterBody3D
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	overlay = ColorRect.new()
	overlay.color = Color(0.025, 0.045, 0.055, 0.94)
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := VBoxContainer.new()
	panel.custom_minimum_size.x = 440
	panel.add_theme_constant_override("separation", 18)
	center.add_child(panel)
	var heading := Label.new()
	heading.text = "OPERATION PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	panel.add_child(heading)
	var details := Label.new()
	details.text = "Simulation suspended. ESC to resume."
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(details)
	var audio := HBoxContainer.new()
	audio.set_script(preload("res://scripts/audio_settings.gd"))
	panel.add_child(audio)
	resume_button = Button.new()
	resume_button.text = "Resume"
	resume_button.custom_minimum_size.y = 48
	resume_button.pressed.connect(resume)
	panel.add_child(resume_button)
	overlay.hide()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if owns_pause:
		get_viewport().set_input_as_handled()
		resume()
	elif not get_tree().paused and bool(agent.get("controls_enabled")):
		get_viewport().set_input_as_handled()
		pause_game()

func pause_game() -> void:
	if owns_pause or get_tree().paused or not bool(agent.get("controls_enabled")):
		return
	owns_pause = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	overlay.show()
	resume_button.grab_focus()

func resume() -> void:
	if not owns_pause:
		return
	owns_pause = false
	overlay.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

func _exit_tree() -> void:
	if owns_pause:
		get_tree().paused = false

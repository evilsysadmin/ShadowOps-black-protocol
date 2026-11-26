extends Control

const ITEMS := ["light_armor", "utility_rig", "quiet_kit"]
const NAMES := {"light_armor": "Light armor", "utility_rig": "Utility rig", "quiet_kit": "Independent movement kit"}
const EFFECTS := {"light_armor": "+15 maximum field health", "utility_rig": "+8 reserve rounds per deployment", "quiet_kit": "+0.25 crouch speed in the field"}
var panel: VBoxContainer
var balance: Label
var status: Label
var buttons: Dictionary = {}
var pending := ""
var confirmation: ConfirmationDialog
var transitioning := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.045, 0.065, 0.075)
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = VBoxContainer.new()
	panel.custom_minimum_size.x = 570
	panel.add_theme_constant_override("separation", 14)
	center.add_child(panel)
	line("SHADOWOPS / EQUIPMENT DIVISION", 18)
	line("ARMORY", 34)
	balance = line("", 22)
	for item in ITEMS:
		if item == "quiet_kit":
			line("INDEPENDENT SUPPLIER / ROOK", 18)
			if Campaign.independent_supplier_available():
				line("Rook: I trade in access, not loyalty. My reconnaissance offers are in the briefing.", 16)
			else:
				line("Rook: Bring something to the table before we talk business.", 16)
		line(NAMES[item] + " — " + EFFECTS[item], 20)
		var button := Button.new()
		button.custom_minimum_size.y = 42
		button.pressed.connect(request_purchase.bind(item))
		panel.add_child(button)
		buttons[item] = button
	status = line("", 17)
	var back := Button.new()
	back.text = "Return to safehouse"
	back.custom_minimum_size.y = 44
	back.pressed.connect(go_back)
	panel.add_child(back)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Permanent equipment purchase"
	confirmation.confirmed.connect(commit_purchase)
	confirmation.canceled.connect(clear_pending)
	add_child(confirmation)
	refresh()
	back.grab_focus()

func line(content: String, size: int) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	panel.add_child(label)
	return label

func refresh() -> void:
	balance.text = "Available credits: %d" % Campaign.available_credits()
	for item in ITEMS:
		var button: Button = buttons[item]
		var price := int(Campaign.EQUIPMENT_COSTS[item])
		var owned := Campaign.owns_equipment(item)
		button.text = "Owned · automatically equipped in field" if owned else "Purchase · %d credits" % price
		button.disabled = owned or Campaign.save_blocked or Campaign.intel_choice.is_empty() or Campaign.available_credits() < price
		if item == "quiet_kit" and not Campaign.independent_supplier_available():
			button.text = "Locked · requires independent leverage"
			button.disabled = true
	if Campaign.save_blocked:
		status.text = "Campaign save unavailable."
	elif Campaign.intel_choice.is_empty():
		status.text = "Complete Unexpected Guest to unlock purchases."

func request_purchase(item: String) -> void:
	if transitioning or not ITEMS.has(item) or Campaign.owns_equipment(item):
		return
	if item == "quiet_kit" and not Campaign.independent_supplier_available():
		return
	if Campaign.save_blocked or Campaign.available_credits() < int(Campaign.EQUIPMENT_COSTS[item]):
		return
	pending = item
	confirmation.dialog_text = "Purchase %s for %d credits?" % [NAMES[item], Campaign.EQUIPMENT_COSTS[item]]
	confirmation.popup_centered()

func clear_pending() -> void:
	pending = ""

func commit_purchase() -> void:
	var item := pending
	clear_pending()
	if not Campaign.buy_equipment(item):
		status.text = "Purchase failed. No credits spent."
		return
	status.text = "Equipment acquired."
	refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not confirmation.visible:
		get_viewport().set_input_as_handled()
		go_back()

func go_back() -> void:
	if transitioning:
		return
	transitioning = true
	if get_tree().change_scene_to_file("res://scenes/safehouse.tscn") != OK:
		transitioning = false

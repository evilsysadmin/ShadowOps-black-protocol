extends VBoxContainer

var effects_slider: HSlider
var ambient_slider: HSlider
var status: Label

func _ready() -> void:
	effects_slider = add_volume_row("Effects", GameSettings.effects_volume)
	ambient_slider = add_volume_row("Ambience", GameSettings.ambient_volume)
	var actions := HBoxContainer.new()
	add_child(actions)
	var apply := Button.new()
	apply.text = "Save audio"
	apply.pressed.connect(_save)
	actions.add_child(apply)
	status = Label.new()
	actions.add_child(status)

func add_volume_row(caption: String, initial: float) -> HSlider:
	var row := HBoxContainer.new()
	add_child(row)
	var title := Label.new()
	title.text = caption
	title.custom_minimum_size.x = 92
	row.add_child(title)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 140
	slider.value = initial
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 48
	value_label.text = "%d%%" % roundi(initial * 100.0)
	row.add_child(value_label)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d%%" % roundi(value * 100.0)
		if is_instance_valid(status):
			status.text = "Unsaved"
	)
	return slider

func _save() -> void:
	status.text = "Saved" if GameSettings.save_audio_volumes(effects_slider.value, ambient_slider.value) else "Save failed"

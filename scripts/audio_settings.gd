extends HBoxContainer

var slider: HSlider
var value_label: Label

func _ready() -> void:
	var title := Label.new()
	title.text = "Effects volume"
	add_child(title)
	slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 140
	slider.value = GameSettings.effects_volume
	add_child(slider)
	value_label = Label.new()
	add_child(value_label)
	refresh_value()
	slider.value_changed.connect(_preview)
	var apply := Button.new()
	apply.text = "Save"
	apply.pressed.connect(_save)
	add_child(apply)

func refresh_value() -> void:
	value_label.text = "%d%%" % roundi(slider.value * 100.0)

func _preview(_value: float) -> void:
	refresh_value()

func _save() -> void:
	if GameSettings.save_effects_volume(slider.value):
		refresh_value()
		value_label.text += " saved"
	else:
		value_label.text = "Save failed"

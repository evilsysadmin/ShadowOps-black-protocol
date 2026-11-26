extends Node

const PATH := "user://settings.cfg"
const TEMP_PATH := "user://settings.tmp"
var effects_volume := 0.8

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		var value: Variant = config.get_value("audio", "effects_volume", 0.8)
		if value is float or value is int:
			effects_volume = clampf(float(value), 0.0, 1.0)

func save_effects_volume(value: float) -> bool:
	var config := ConfigFile.new()
	if FileAccess.file_exists(PATH) and config.load(PATH) != OK:
		return false
	var bounded := clampf(value, 0.0, 1.0)
	config.set_value("audio", "effects_volume", bounded)
	if config.save(TEMP_PATH) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(PATH)) != OK:
		return false
	effects_volume = bounded
	return true

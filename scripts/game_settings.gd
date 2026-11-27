extends Node

const PATH := "user://settings.cfg"
const TEMP_PATH := "user://settings.tmp"
var effects_volume := 0.8
var ambient_volume := 0.35

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		var value: Variant = config.get_value("audio", "effects_volume", 0.8)
		if value is float or value is int:
			effects_volume = clampf(float(value), 0.0, 1.0)
		var ambient: Variant = config.get_value("audio", "ambient_volume", 0.35)
		if ambient is float or ambient is int:
			ambient_volume = clampf(float(ambient), 0.0, 1.0)

func save_effects_volume(value: float) -> bool:
	return save_audio_volumes(value, ambient_volume)

func save_ambient_volume(value: float) -> bool:
	return save_audio_volumes(effects_volume, value)

func save_audio_volumes(effects: float, ambient: float) -> bool:
	if not is_finite(effects) or not is_finite(ambient):
		return false
	var config := ConfigFile.new()
	if FileAccess.file_exists(PATH) and config.load(PATH) != OK:
		return false
	var bounded := clampf(effects, 0.0, 1.0)
	var bounded_ambient := clampf(ambient, 0.0, 1.0)
	config.set_value("audio", "effects_volume", bounded)
	config.set_value("audio", "ambient_volume", bounded_ambient)
	if config.save(TEMP_PATH) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(PATH)) != OK:
		return false
	effects_volume = bounded
	ambient_volume = bounded_ambient
	return true

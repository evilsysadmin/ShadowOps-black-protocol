extends Node

const SAVE_PATH := "user://campaign.cfg"
const TEMP_PATH := "user://campaign.tmp"
const SCHEMA := 1
const MISSION_ID := "unexpected_guest"
var intel_choice := ""
var save_blocked := false

func _ready() -> void:
	load_campaign()

func load_campaign() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK or config.get_value("meta", "schema", 0) != SCHEMA:
		save_blocked = true
		return
	var saved: Variant = config.get_value("missions", MISSION_ID, "")
	if not saved is String or not saved in ["", "share", "retain"]:
		save_blocked = true
		return
	intel_choice = saved

func record_intel(choice: String) -> bool:
	if not choice in ["share", "retain"] or save_blocked:
		return false
	if not intel_choice.is_empty():
		return true
	var config := ConfigFile.new()
	config.set_value("meta", "schema", SCHEMA)
	config.set_value("missions", MISSION_ID, choice)
	if config.save(TEMP_PATH) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH)) != OK:
		return false
	intel_choice = choice
	return true

func handler_trust() -> int:
	match intel_choice:
		"share":
			return 1
		"retain":
			return -1
	return 0

func independent_leverage() -> int:
	return 1 if intel_choice == "retain" else 0

extends Node

const SAVE_PATH := "user://campaign.cfg"
const TEMP_PATH := "user://campaign.tmp"
const SCHEMA := 1
const MISSION_ID := "unexpected_guest"
var intel_choice := ""
var specialization := ""
const SPECIALIZATIONS := ["resilience", "infiltration", "mobility"]
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
	var saved_skill: Variant = config.get_value("progression", "specialization", "")
	if not saved_skill is String or (saved_skill != "" and not SPECIALIZATIONS.has(saved_skill)) or (saved == "" and saved_skill != ""):
		save_blocked = true
		return
	intel_choice = saved
	specialization = saved_skill

func record_intel(choice: String) -> bool:
	if not choice in ["share", "retain"] or save_blocked:
		return false
	if not intel_choice.is_empty():
		return true
	return write_campaign(choice, specialization)

func has_skill_point() -> bool:
	return not save_blocked and not intel_choice.is_empty() and specialization.is_empty()

func choose_specialization(value: String) -> bool:
	if not has_skill_point() or not SPECIALIZATIONS.has(value):
		return false
	return write_campaign(intel_choice, value)

func write_campaign(choice: String, skill: String) -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "schema", SCHEMA)
	config.set_value("missions", MISSION_ID, choice)
	config.set_value("progression", "specialization", skill)
	if config.save(TEMP_PATH) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH)) != OK:
		return false
	intel_choice = choice
	specialization = skill
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

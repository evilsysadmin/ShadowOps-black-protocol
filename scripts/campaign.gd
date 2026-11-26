extends Node

const SAVE_PATH := "user://campaign.cfg"
const TEMP_PATH := "user://campaign.tmp"
const SCHEMA := 1
const MISSION_ID := "unexpected_guest"
var intel_choice := ""
var archive_completed := false
var handler_agreement := ""
var archive_intel_cost := 0
var rook_contract_accepted := false
const ROOK_CONTRACT_REWARD := 35
var equipment_owned: Array[String] = []
const EQUIPMENT_COSTS := {"light_armor": 80, "utility_rig": 70, "quiet_kit": 65}
const INTEL_STANDARD_COST := 60
const INTEL_COORDINATED_COST := 40
const INTEL_ROOK_COST := 50
const HANDLER_AGREEMENTS := ["coordinate", "autonomy"]
var field_reports: Dictionary = {}
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
	var archive: Variant = config.get_value("missions", "silent_archive", false)
	if not archive is bool or (archive and saved == ""):
		save_blocked = true
		return
	var reports: Variant = config.get_value("missions", "field_reports", {})
	if not reports is Dictionary:
		save_blocked = true
		return
	for operation in reports:
		if (operation != MISSION_ID and operation != "silent_archive") or (operation == MISSION_ID and saved == "") or (operation == "silent_archive" and not archive) or not valid_field_report(reports[operation]):
			save_blocked = true
			return
	var agreement: Variant = config.get_value("contacts", "handler_agreement", "")
	if not agreement is String or (agreement != "" and (saved == "" or not HANDLER_AGREEMENTS.has(agreement))):
		save_blocked = true
		return
	var paid: Variant = config.get_value("economy", "archive_intel_cost", 0)
	if not paid is int or not paid in [0, INTEL_STANDARD_COST, INTEL_COORDINATED_COST, INTEL_ROOK_COST] or (paid != 0 and saved == "") or (paid == INTEL_COORDINATED_COST and agreement != "coordinate") or (paid == INTEL_ROOK_COST and saved != "retain" and agreement != "autonomy"):
		save_blocked = true
		return
	var owned: Variant = config.get_value("economy", "equipment_owned", [])
	if not owned is Array:
		save_blocked = true
		return
	var validated: Array[String] = []
	var spent := int(paid)
	for item in owned:
		if not item is String or not EQUIPMENT_COSTS.has(item) or validated.has(item) or (item == "quiet_kit" and saved != "retain" and agreement != "autonomy"):
			save_blocked = true
			return
		validated.append(item)
		spent += int(EQUIPMENT_COSTS[item])
	var contract: Variant = config.get_value("contacts", "rook_contract_accepted", false)
	if not contract is bool or (contract and (saved == "" or (saved != "retain" and agreement != "autonomy"))):
		save_blocked = true
		return
	var earnings := reward_for_completion(saved != "", reports.get(MISSION_ID, {})) + reward_for_completion(archive, reports.get("silent_archive", {}))
	earnings += contract_reward_for(contract, archive, reports.get("silent_archive", {}))
	if spent > earnings:
		save_blocked = true
		return
	rook_contract_accepted = contract
	equipment_owned = validated
	archive_intel_cost = paid
	handler_agreement = agreement
	field_reports = reports.duplicate(true)
	archive_completed = archive
	intel_choice = saved
	specialization = saved_skill

func record_intel(choice: String, report: Dictionary = {}) -> bool:
	if not choice in ["share", "retain"] or save_blocked:
		return false
	if not intel_choice.is_empty():
		return true
	var reports := reports_with(MISSION_ID, report)
	if not report.is_empty() and reports.is_empty():
		return false
	return write_campaign(choice, specialization, archive_completed, reports, handler_agreement)

func has_skill_point() -> bool:
	return not save_blocked and not intel_choice.is_empty() and specialization.is_empty()

func choose_specialization(value: String) -> bool:
	if not has_skill_point() or not SPECIALIZATIONS.has(value):
		return false
	return write_campaign(intel_choice, value, archive_completed, field_reports, handler_agreement)

func write_campaign(choice: String, skill: String, completed_archive: bool, reports: Dictionary, agreement: String, intel_cost: int = -1, new_equipment: Variant = null, contract: Variant = null) -> bool:
	var accepted := rook_contract_accepted if contract == null else bool(contract)
	var paid := archive_intel_cost if intel_cost == -1 else intel_cost
	var owned: Array[String] = equipment_owned.duplicate()
	if new_equipment != null:
		owned.assign(new_equipment)
	var config := ConfigFile.new()
	config.set_value("meta", "schema", SCHEMA)
	config.set_value("missions", MISSION_ID, choice)
	config.set_value("missions", "silent_archive", completed_archive)
	config.set_value("missions", "field_reports", reports)
	config.set_value("progression", "specialization", skill)
	config.set_value("contacts", "handler_agreement", agreement)
	config.set_value("contacts", "rook_contract_accepted", accepted)
	config.set_value("economy", "archive_intel_cost", paid)
	config.set_value("economy", "equipment_owned", owned)
	if config.save(TEMP_PATH) != OK:
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(TEMP_PATH), ProjectSettings.globalize_path(SAVE_PATH)) != OK:
		return false
	intel_choice = choice
	specialization = skill
	archive_completed = completed_archive
	rook_contract_accepted = accepted
	equipment_owned = owned
	archive_intel_cost = paid
	handler_agreement = agreement
	field_reports = reports.duplicate(true)
	return true

func record_archive(report: Dictionary = {}) -> bool:
	if save_blocked or intel_choice.is_empty():
		return false
	if archive_completed:
		return true
	var reports := reports_with("silent_archive", report)
	if not report.is_empty() and reports.is_empty():
		return false
	return write_campaign(intel_choice, specialization, true, reports, handler_agreement)

func valid_field_report(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 6:
		return false
	for key in ["seconds", "damage", "shots", "hits"]:
		var number: Variant = value.get(key)
		if not number is int or number < 0:
			return false
	if value["hits"] > value["shots"]:
		return false
	return value.get("alerted") is bool and value.get("guard_down") is bool

func reports_with(operation: String, report: Dictionary) -> Dictionary:
	var reports := field_reports.duplicate(true)
	if not report.is_empty():
		if not valid_field_report(report):
			return {}
		reports[operation] = report.duplicate(true)
	return reports

func field_report(operation: String) -> Dictionary:
	var report: Dictionary = field_reports.get(operation, {})
	return report.duplicate(true)

func can_negotiate_handler() -> bool:
	return not save_blocked and not intel_choice.is_empty() and handler_agreement.is_empty()

func negotiate_handler(choice: String) -> bool:
	if not can_negotiate_handler() or not HANDLER_AGREEMENTS.has(choice):
		return false
	return write_campaign(intel_choice, specialization, archive_completed, field_reports, choice)

func handler_trust() -> int:
	var trust := 1 if intel_choice == "share" else (-1 if intel_choice == "retain" else 0)
	return trust + (1 if handler_agreement == "coordinate" else (-1 if handler_agreement == "autonomy" else 0))

func independent_leverage() -> int:
	return (1 if intel_choice == "retain" else 0) + (1 if handler_agreement == "autonomy" else 0)

# Deployment kit is session-local, independent of permanent progression.
var deployment_kit := "standard"
const KITS := ["standard", "protection", "supplies"]

func select_deployment_kit(kit: String) -> bool:
	if not KITS.has(kit):
		return false
	deployment_kit = kit
	return true

func kit_health_bonus() -> int:
	return 25 if deployment_kit == "protection" else 0

func kit_reserve() -> int:
	return 40 if deployment_kit == "supplies" else (16 if deployment_kit == "protection" else 24)

const Operations = preload("res://scripts/operation_catalog.gd")
var selected_operation := Operations.HOTEL

func available_operations() -> Array[String]:
	return Operations.available_operations(not intel_choice.is_empty())

func select_operation(operation: String) -> bool:
	if not available_operations().has(operation):
		return false
	selected_operation = operation
	return true

# Earned credits are derived from canonical completions, never from replay counts.
func operation_reward(operation: String) -> int:
	var completed := false
	match operation:
		Operations.HOTEL:
			completed = not intel_choice.is_empty()
		Operations.ARCHIVE:
			completed = archive_completed
	return reward_for_completion(completed, field_report(operation))

func reward_for_completion(completed: bool, report: Dictionary) -> int:
	if not completed:
		return 0
	var reward := 100
	if not report.is_empty():
		if not bool(report["alerted"]):
			reward += 40
		if int(report["damage"]) == 0:
			reward += 20
		if int(report["shots"]) == 0 and not bool(report["guard_down"]):
			reward += 20
	return reward

func earned_credits() -> int:
	return operation_reward(Operations.HOTEL) + operation_reward(Operations.ARCHIVE) + rook_contract_reward()

func available_credits() -> int:
	var spent := archive_intel_cost
	for item in equipment_owned:
		spent += int(EQUIPMENT_COSTS[item])
	return earned_credits() - spent

func archive_intel_price() -> int:
	if handler_agreement == "coordinate":
		return INTEL_COORDINATED_COST
	if independent_supplier_available():
		return INTEL_ROOK_COST
	return INTEL_STANDARD_COST

func archive_intel_source() -> String:
	var price := archive_intel_cost if owns_archive_intel() else archive_intel_price()
	return "Rook" if price == INTEL_ROOK_COST else "Handler"

func owns_archive_intel() -> bool:
	return archive_intel_cost > 0

func buy_archive_intel() -> bool:
	var price := archive_intel_price()
	if save_blocked or intel_choice.is_empty() or owns_archive_intel() or available_credits() < price:
		return false
	return write_campaign(intel_choice, specialization, archive_completed, field_reports, handler_agreement, price)

func owns_equipment(item: String) -> bool:
	return equipment_owned.has(item)

func independent_supplier_available() -> bool:
	return not save_blocked and independent_leverage() > 0

func buy_equipment(item: String) -> bool:
	if save_blocked or intel_choice.is_empty() or not EQUIPMENT_COSTS.has(item) or owns_equipment(item):
		return false
	if item == "quiet_kit" and not independent_supplier_available():
		return false
	if available_credits() < int(EQUIPMENT_COSTS[item]):
		return false
	var next_owned: Array[String] = equipment_owned.duplicate()
	next_owned.append(item)
	return write_campaign(intel_choice, specialization, archive_completed, field_reports, handler_agreement, -1, next_owned)

# Rook's standing derives from recorded dealings, not general leverage.
func rook_reputation() -> int:
	return (1 if owns_equipment("quiet_kit") else 0) + (1 if archive_intel_cost == INTEL_ROOK_COST else 0) + (1 if rook_contract_reward() > 0 else 0)

func rook_relationship() -> String:
	if not independent_supplier_available():
		return "No access"
	if rook_reputation() >= 2:
		return "Established client"
	if rook_reputation() == 1:
		return "Known client"
	return "New contact"

func rook_message() -> String:
	if not independent_supplier_available():
		return "Bring something to the table before we talk business."
	if rook_reputation() >= 2:
		return "You have a record of keeping your end of the deal. That matters."
	if rook_contract_reward() > 0:
		return "The archive stayed quiet. You delivered on our agreement."
	if owns_equipment("quiet_kit"):
		return "You bought my movement kit. I hope it earns its keep."
	if archive_intel_cost == INTEL_ROOK_COST:
		return "You bought my reconnaissance. The information is yours."
	return "I trade in access, not loyalty. My reconnaissance offers are in the briefing."

func can_accept_rook_contract() -> bool:
	return independent_supplier_available() and not intel_choice.is_empty() and not archive_completed and not rook_contract_accepted

func accept_rook_contract() -> bool:
	if not can_accept_rook_contract():
		return false
	return write_campaign(intel_choice, specialization, archive_completed, field_reports, handler_agreement, -1, null, true)

func contract_reward_for(accepted: bool, completed: bool, report: Dictionary) -> int:
	if not accepted or not completed or report.is_empty():
		return 0
	return ROOK_CONTRACT_REWARD if not bool(report.get("alerted", true)) else 0

func rook_contract_reward() -> int:
	return contract_reward_for(rook_contract_accepted, archive_completed, field_report(Operations.ARCHIVE))

func rook_contract_status() -> String:
	if rook_contract_accepted:
		if not archive_completed:
			return "Accepted: complete Silent Archive without full alert."
		if rook_contract_reward() > 0:
			return "Fulfilled: +35 credits and +1 Rook reputation."
		return "Closed: the first completion did not meet the condition."
	if archive_completed:
		return "Closed: Silent Archive already completed."
	if can_accept_rook_contract():
		return "Available: +35 credits and +1 reputation for no full alert."
	return "Locked: independent access required."

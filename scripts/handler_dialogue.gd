extends RefCounted

# Deterministic dialogue grounded only in the canonical campaign record.
static func relationship(choice: String) -> String:
	match choice:
		"share":
			return "You handed over the hotel file. I can work with that."
		"retain":
			return "You kept the hotel file. I respect initiative. I dislike surprises."
	return "We have no field history yet. Let's start with a clean operation."

static func assessment(report: Dictionary) -> String:
	if report.is_empty():
		return "The operation is on record, but the detailed field report is unavailable."
	if bool(report["alerted"]):
		if int(report["damage"]) > 0:
			return "Security went to full alert and you took damage. Discretion is not an optional accessory."
		return "Security went to full alert. At least you returned without damage."
	if int(report["shots"]) == 0 and int(report["damage"]) == 0 and not bool(report["guard_down"]):
		return "No shots, no damage, no full alert. Finally, someone who understands the job."
	if int(report["shots"]) > 0:
		return "%d shots recorded. No full alert, at least. Review your approach." % int(report["shots"])
	return "No full alert recorded. Review the field report before the next deployment."

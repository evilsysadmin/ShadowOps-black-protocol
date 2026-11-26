extends RefCounted

const HOTEL := "unexpected_guest"
const ARCHIVE := "silent_archive"

static func available_operations(first_complete: bool) -> Array[String]:
	var result: Array[String] = [HOTEL]
	if first_complete:
		result.append(ARCHIVE)
	return result

static func title_for(operation: String) -> String:
	return "SILENT ARCHIVE" if operation == ARCHIVE else "UNEXPECTED GUEST"

static func description_for(operation: String, intel_choice: String) -> String:
	if operation == ARCHIVE:
		if intel_choice == "share":
			return "Your handler supplied access intelligence. Recover the archive ledger and return to extraction."
		return "You retained the hotel file. Use your independent lead to recover the archive ledger and return to extraction."
	return "Recover the intelligence file at hotel reception and return to extraction. Avoid unnecessary confrontation. A security patrol may compromise the operation."

extends RefCounted

const SAVE_PATH = "user://personal_ranking.json"

static func read_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"total": 0, "runs": []}
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or not data.get("runs", []) is Array:
		return {"total": 0, "runs": []}
	return data

static func record_run(kills: int) -> void:
	var data := read_data()
	data["total"] = int(data.get("total", 0)) + maxi(0, kills)
	var runs: Array = data.get("runs", [])
	runs.append({"kills": maxi(0, kills), "date": Time.get_date_string_from_system()})
	runs.sort_custom(func(a: Dictionary, b: Dictionary): return int(a.kills) > int(b.kills))
	if runs.size() > 5:
		runs.resize(5)
	data["runs"] = runs
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

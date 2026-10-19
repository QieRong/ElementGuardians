## CSV configuration loader — starter only. Full typed validation belongs to Sprint 1.
class_name ConfigLoader
extends RefCounted

const NAMES = [
	"towers", "enemies", "waves", "upgrades", "economy_params", "global_params"
]

static func load_table(table_name: String) -> Dictionary:
	var path := "res://configs/csv/%s.csv" % table_name
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "CSV not found: " + path, "rows": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Cannot open CSV: " + path, "rows": []}
	var header := file.get_csv_line()
	if header.size() == 0 or String(header[0]).strip_edges().is_empty():
		return {"ok": false, "error": "Empty CSV header: " + path, "rows": []}
	var rows: Array[Dictionary] = []
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or (values.size() == 1 and String(values[0]).is_empty()):
			continue
		if values.size() != header.size():
			return {"ok": false, "error": "Column mismatch: " + path, "rows": []}
		var record: Dictionary = {}
		for i in range(header.size()):
			record[String(header[i])] = String(values[i])
		rows.append(record)
	return {"ok": true, "error": "", "rows": rows}

static func verify_all_tables() -> Dictionary:
	var result: Dictionary = {}
	for table_name in NAMES:
		var table := load_table(table_name)
		if not table["ok"]:
			return {"ok": false, "error": String(table["error"]), "counts": result}
		result[table_name] = (table["rows"] as Array).size()
	return {"ok": true, "error": "", "counts": result}

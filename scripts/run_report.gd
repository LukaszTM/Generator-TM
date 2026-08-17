class_name RunReport
extends RefCounted
## Raport z wykonania testów: podsumowanie wyników, rozbicie na moduły
## i pełna lista przypadków ze statusami oraz notatkami.

const STATUSES := ["Zaliczony", "Niezaliczony", "Zablokowany", "Niewykonany"]


## Zlicza wyniki. results: {case_id: {"status": String, "note": String}}
static func counts(cases: Array, results: Dictionary) -> Dictionary:
	var out := {"Zaliczony": 0, "Niezaliczony": 0, "Zablokowany": 0, "Niewykonany": 0}
	for c in cases:
		var status: String = results.get(c.id, {}).get("status", "Niewykonany")
		out[status] = int(out.get(status, 0)) + 1
	return out


static func summary_line(cases: Array, results: Dictionary) -> String:
	var n := counts(cases, results)
	var done: int = cases.size() - n["Niewykonany"]
	return "Wykonane: %d/%d  •  Zaliczone: %d  •  Niezaliczone: %d  •  Zablokowane: %d" % [done, cases.size(), n["Zaliczony"], n["Niezaliczony"], n["Zablokowany"]]


static func markdown(cases: Array, results: Dictionary, project_name: String, author: String) -> String:
	var n := counts(cases, results)
	var lines: Array[String] = []
	lines.append("# Raport z wykonania testów — %s" % project_name)
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Data | %s |" % Time.get_datetime_string_from_system(false, true))
	if author != "":
		lines.append("| Tester | %s |" % author)
	lines.append("| Liczba przypadków | %d |" % cases.size())
	lines.append("| Zaliczone | %d |" % n["Zaliczony"])
	lines.append("| Niezaliczone | %d |" % n["Niezaliczony"])
	lines.append("| Zablokowane | %d |" % n["Zablokowany"])
	lines.append("| Niewykonane | %d |" % n["Niewykonany"])
	lines.append("")

	# Rozbicie na moduły.
	lines.append("## Wyniki wg modułów")
	lines.append("")
	lines.append("| Moduł | Zaliczone | Niezaliczone | Zablokowane | Niewykonane |")
	lines.append("|---|---|---|---|---|")
	for module in _modules(cases):
		var m := {"Zaliczony": 0, "Niezaliczony": 0, "Zablokowany": 0, "Niewykonany": 0}
		for c in cases:
			if c.module == module:
				var st: String = results.get(c.id, {}).get("status", "Niewykonany")
				m[st] = int(m[st]) + 1
		lines.append("| %s | %d | %d | %d | %d |" % [module, m["Zaliczony"], m["Niezaliczony"], m["Zablokowany"], m["Niewykonany"]])
	lines.append("")

	# Najpierw niezaliczone — to one interesują czytelnika raportu.
	var failed: Array = []
	for c in cases:
		if results.get(c.id, {}).get("status", "") == "Niezaliczony":
			failed.append(c)
	if not failed.is_empty():
		lines.append("## Przypadki niezaliczone")
		lines.append("")
		for c in failed:
			var note: String = results.get(c.id, {}).get("note", "")
			lines.append("- **%s — %s** (moduł: %s)%s" % [c.id, c.title, c.module, ("" if note.is_empty() else " — notatka: " + note)])
		lines.append("")

	lines.append("## Pełna lista wyników")
	lines.append("")
	lines.append("| ID | Tytuł | Moduł | Priorytet | Status | Notatka |")
	lines.append("|---|---|---|---|---|---|")
	for c in cases:
		var r: Dictionary = results.get(c.id, {})
		lines.append("| %s | %s | %s | %s | %s | %s |" % [c.id, c.title, c.module, c.priority, r.get("status", "Niewykonany"), String(r.get("note", "")).replace("|", "/").replace("\n", " ")])
	lines.append("")
	return "\n".join(lines)


static func csv(cases: Array, results: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(Exporter._csv_row(["ID", "Tytuł", "Moduł", "Typ", "Priorytet", "Status", "Notatka"]))
	for c in cases:
		var r: Dictionary = results.get(c.id, {})
		lines.append(Exporter._csv_row([c.id, c.title, c.module, c.type, c.priority, r.get("status", "Niewykonany"), r.get("note", "")]))
	return "﻿" + "\n".join(lines)


static func html(cases: Array, results: Dictionary, project_name: String, author: String) -> String:
	var n := counts(cases, results)
	var status_colors := {"Zaliczony": "#16a34a", "Niezaliczony": "#dc2626", "Zablokowany": "#d97706", "Niewykonany": "#5a6478"}
	var rows := ""
	for c in cases:
		var r: Dictionary = results.get(c.id, {})
		var st: String = r.get("status", "Niewykonany")
		rows += "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td style=\"color:%s;font-weight:600\">%s</td><td>%s</td></tr>" % [
			_esc(c.id), _esc(c.title), _esc(c.module), _esc(c.priority), status_colors.get(st, "#5a6478"), st, _esc(String(r.get("note", "")))]
	var author_row := "" if author.is_empty() else "<br><strong>Tester:</strong> %s" % _esc(author)
	return """<!DOCTYPE html>
<html lang="pl"><head><meta charset="utf-8">
<title>Raport z wykonania testów — %s</title>
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; color: #1d2433; max-width: 1000px; margin: 0 auto; padding: 24px; }
h1 { color: #1a3fc4; border-bottom: 2px solid #0e8f8f; padding-bottom: 6px; }
table { border-collapse: collapse; width: 100%%; margin: 12px 0; }
th, td { border: 1px solid #d7dfeb; padding: 6px 10px; text-align: left; vertical-align: top; }
th { background: #f2f5fa; }
.summary span { display: inline-block; margin-right: 18px; font-weight: 600; }
</style></head><body>
<h1>Raport z wykonania testów — %s</h1>
<p><strong>Data:</strong> %s%s</p>
<p class="summary">
<span>Przypadków: %d</span>
<span style="color:#16a34a">Zaliczone: %d</span>
<span style="color:#dc2626">Niezaliczone: %d</span>
<span style="color:#d97706">Zablokowane: %d</span>
<span style="color:#5a6478">Niewykonane: %d</span>
</p>
<table><tr><th>ID</th><th>Tytuł</th><th>Moduł</th><th>Priorytet</th><th>Status</th><th>Notatka</th></tr>%s</table>
</body></html>""" % [_esc(project_name), _esc(project_name), Time.get_datetime_string_from_system(false, true), author_row,
		cases.size(), n["Zaliczony"], n["Niezaliczony"], n["Zablokowany"], n["Niewykonany"], rows]


static func _modules(cases: Array) -> Array[String]:
	var out: Array[String] = []
	for c in cases:
		if not out.has(c.module):
			out.append(c.module)
	return out


static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

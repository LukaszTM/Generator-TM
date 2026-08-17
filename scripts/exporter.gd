class_name Exporter
extends RefCounted
## Zapis planu testów i przypadków testowych do plików: Markdown, CSV, HTML.


static func case_to_markdown(c: TestGenerator.TestCase) -> String:
	var lines: Array[String] = []
	lines.append("### %s — %s" % [c.id, c.title])
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Moduł | %s |" % c.module)
	lines.append("| Typ | %s |" % c.type)
	lines.append("| Priorytet | %s |" % c.priority)
	lines.append("| Warunki wstępne | %s |" % c.preconditions)
	lines.append("| Dane testowe | %s |" % c.test_data)
	lines.append("")
	lines.append("**Kroki:**")
	lines.append("")
	for i in c.steps.size():
		lines.append("%d. %s" % [i + 1, c.steps[i]])
	lines.append("")
	lines.append("**Oczekiwany rezultat:** %s" % c.expected)
	if c.why != "":
		lines.append("")
		lines.append("> 💡 **Dlaczego ten test?** %s" % c.why)
	lines.append("")
	return "\n".join(lines)


static func cases_markdown(cases: Array[TestGenerator.TestCase], project_name: String) -> String:
	var lines: Array[String] = []
	lines.append("# Przypadki testowe — %s" % project_name)
	lines.append("")
	var current_module := ""
	for c in cases:
		if c.module != current_module:
			current_module = c.module
			lines.append("## Moduł: %s" % current_module)
			lines.append("")
		lines.append(case_to_markdown(c))
	return "\n".join(lines)


## CSV rozdzielany średnikami (przyjazny polskim ustawieniom Excela).
static func cases_csv(cases: Array[TestGenerator.TestCase]) -> String:
	var lines: Array[String] = []
	lines.append(_csv_row(["ID", "Moduł", "Tytuł", "Typ", "Priorytet", "Warunki wstępne", "Kroki", "Dane testowe", "Oczekiwany rezultat", "Dlaczego ten test"]))
	for c in cases:
		var steps := ""
		for i in c.steps.size():
			steps += "%d. %s\n" % [i + 1, c.steps[i]]
		lines.append(_csv_row([c.id, c.module, c.title, c.type, c.priority, c.preconditions, steps.strip_edges(), c.test_data, c.expected, c.why]))
	# BOM na początku pliku pomaga Excelowi rozpoznać UTF-8.
	return "﻿" + "\n".join(lines)


static func _csv_row(fields: Array) -> String:
	var quoted: Array[String] = []
	for f in fields:
		var s := str(f).replace("\"", "\"\"")
		quoted.append("\"%s\"" % s)
	return ";".join(quoted)


static func full_html(plan_markdown: String, cases: Array[TestGenerator.TestCase], project_name: String) -> String:
	var body := "<h1>%s — dokumentacja testów</h1>" % _esc(project_name)
	body += "<section>" + _markdown_to_html(plan_markdown) + "</section>"
	body += "<section><h1>Przypadki testowe</h1>"
	var current_module := ""
	for c in cases:
		if c.module != current_module:
			current_module = c.module
			body += "<h2>Moduł: %s</h2>" % _esc(current_module)
		body += "<div class=\"case\"><h3>%s — %s</h3>" % [_esc(c.id), _esc(c.title)]
		body += "<table><tr><th>Moduł</th><td>%s</td></tr>" % _esc(c.module)
		body += "<tr><th>Typ</th><td>%s</td></tr>" % _esc(c.type)
		body += "<tr><th>Priorytet</th><td>%s</td></tr>" % _esc(c.priority)
		body += "<tr><th>Warunki wstępne</th><td>%s</td></tr>" % _esc(c.preconditions)
		body += "<tr><th>Dane testowe</th><td>%s</td></tr></table>" % _esc(c.test_data)
		body += "<p><strong>Kroki:</strong></p><ol>"
		for s in c.steps:
			body += "<li>%s</li>" % _esc(s)
		body += "</ol><p><strong>Oczekiwany rezultat:</strong> %s</p>" % _esc(c.expected)
		if c.why != "":
			body += "<p style=\"background:#f2f8ff;border-left:3px solid #1a3fc4;padding:8px 12px\">💡 <strong>Dlaczego ten test?</strong> %s</p>" % _esc(c.why)
		body += "</div>"
	body += "</section>"
	return """<!DOCTYPE html>
<html lang="pl"><head><meta charset="utf-8">
<title>%s — dokumentacja testów</title>
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; color: #1d2433; max-width: 960px; margin: 0 auto; padding: 24px; }
h1 { color: #1a3fc4; border-bottom: 2px solid #0e8f8f; padding-bottom: 6px; }
h2 { color: #0e8f8f; margin-top: 32px; }
table { border-collapse: collapse; margin: 8px 0; width: 100%%; }
th, td { border: 1px solid #d7dfeb; padding: 6px 10px; text-align: left; vertical-align: top; }
th { background: #f2f5fa; white-space: nowrap; }
.case { border: 1px solid #d7dfeb; border-radius: 8px; padding: 12px 16px; margin: 12px 0; }
.case h3 { margin-top: 0; color: #1a3fc4; }
</style></head><body>%s</body></html>""" % [_esc(project_name), body]


static func save_text(path: String, content: String) -> String:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "Nie można zapisać pliku: %s (kod błędu: %s)" % [path, FileAccess.get_open_error()]
	f.store_string(content)
	f.close()
	return ""


static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


## Bardzo prosty konwerter Markdown -> HTML (nagłówki, tabele, listy, pogrubienia).
static func _markdown_to_html(md: String) -> String:
	var html := ""
	var in_table := false
	var in_list := false
	for line in md.split("\n"):
		var s: String = line.strip_edges()
		if s.begins_with("|"):
			var cells := s.trim_prefix("|").trim_suffix("|").split("|")
			var is_separator := true
			for cell in cells:
				var cs := cell.strip_edges()
				if cs != "" and cs.lstrip("-: ").length() > 0:
					is_separator = false
					break
			if is_separator:
				continue
			if not in_table:
				html += "<table>"
				in_table = true
			html += "<tr>"
			for cell in cells:
				html += "<td>%s</td>" % _inline_md(_esc(cell.strip_edges()))
			html += "</tr>"
			continue
		elif in_table:
			html += "</table>"
			in_table = false
		if s.begins_with("- "):
			if not in_list:
				html += "<ul>"
				in_list = true
			html += "<li>%s</li>" % _inline_md(_esc(s.substr(2)))
			continue
		elif in_list:
			html += "</ul>"
			in_list = false
		if s.begins_with("### "):
			html += "<h3>%s</h3>" % _inline_md(_esc(s.substr(4)))
		elif s.begins_with("## "):
			html += "<h2>%s</h2>" % _inline_md(_esc(s.substr(3)))
		elif s.begins_with("# "):
			html += "<h1>%s</h1>" % _inline_md(_esc(s.substr(2)))
		elif s != "":
			html += "<p>%s</p>" % _inline_md(_esc(s))
	if in_table:
		html += "</table>"
	if in_list:
		html += "</ul>"
	return html


static func _inline_md(s: String) -> String:
	var re := RegEx.new()
	re.compile("\\*\\*(.+?)\\*\\*")
	s = re.sub(s, "<strong>$1</strong>", true)
	re.compile("`(.+?)`")
	s = re.sub(s, "<code>$1</code>", true)
	return s

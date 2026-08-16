class_name BugReporter
extends RefCounted
## Zgłoszenia błędów z załącznikami-zrzutami ekranu oraz ich eksport
## do HTML (obrazy osadzone w pliku), Markdown (obrazy w podfolderze) i CSV.

## Załącznik graficzny (zrzut ekranu).
class Attachment:
	var name := ""
	var image: Image = null

## Pojedyncze zgłoszenie błędu.
class BugReport:
	var id := ""
	var title := ""
	var module := ""
	var related_case := ""
	var severity := "Średni"     # Krytyczny / Wysoki / Średni / Niski
	var environment := ""
	var steps := ""
	var actual := ""
	var expected := ""
	var reporter := ""
	var date := ""
	var attachments: Array[Attachment] = []


static func severity_levels() -> Array[String]:
	return ["Krytyczny", "Wysoki", "Średni", "Niski"]


## Zapisuje raport we wskazanym formacie. Zwraca "" albo komunikat błędu.
static func export(path: String, ext: String, bugs: Array, project_name: String) -> String:
	match ext:
		"html":
			return Exporter.save_text(path, to_html(bugs, project_name))
		"md":
			var attach_dir := path.get_basename() + "_zalaczniki"
			var err := _save_attachments(attach_dir, bugs)
			if err != "":
				return err
			return Exporter.save_text(path, to_markdown(bugs, project_name, attach_dir.get_file()))
		"csv":
			return Exporter.save_text(path, to_csv(bugs))
	return "Nieznany format: " + ext


static func to_html(bugs: Array, project_name: String) -> String:
	var body := "<h1>Raport błędów — %s</h1>" % _esc(project_name)
	body += "<p>Liczba zgłoszeń: %d</p>" % bugs.size()
	body += "<table><tr><th>ID</th><th>Tytuł</th><th>Moduł</th><th>Waga</th></tr>"
	for b in bugs:
		body += "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>" % [_esc(b.id), _esc(b.title), _esc(b.module), _esc(b.severity)]
	body += "</table>"
	for b in bugs:
		body += "<div class=\"case\"><h3>%s — %s</h3>" % [_esc(b.id), _esc(b.title)]
		body += "<table>"
		body += "<tr><th>Moduł</th><td>%s</td></tr>" % _esc(b.module)
		if b.related_case != "":
			body += "<tr><th>Powiązany przypadek</th><td>%s</td></tr>" % _esc(b.related_case)
		body += "<tr><th>Waga</th><td>%s</td></tr>" % _esc(b.severity)
		if b.environment != "":
			body += "<tr><th>Środowisko</th><td>%s</td></tr>" % _esc(b.environment)
		if b.reporter != "":
			body += "<tr><th>Zgłaszający</th><td>%s</td></tr>" % _esc(b.reporter)
		body += "<tr><th>Data</th><td>%s</td></tr></table>" % _esc(b.date)
		body += "<p><strong>Kroki reprodukcji:</strong></p><ol>"
		for s in _step_lines(b.steps):
			body += "<li>%s</li>" % _esc(s)
		body += "</ol>"
		body += "<p><strong>Rezultat aktualny:</strong> %s</p>" % _esc(b.actual)
		body += "<p><strong>Rezultat oczekiwany:</strong> %s</p>" % _esc(b.expected)
		if not b.attachments.is_empty():
			body += "<p><strong>Zrzuty ekranu:</strong></p>"
			for a in b.attachments:
				var buf: PackedByteArray = a.image.save_png_to_buffer()
				body += "<figure><img src=\"data:image/png;base64,%s\" alt=\"%s\"><figcaption>%s</figcaption></figure>" % [Marshalls.raw_to_base64(buf), _esc(a.name), _esc(a.name)]
		body += "</div>"
	return """<!DOCTYPE html>
<html lang="pl"><head><meta charset="utf-8">
<title>Raport błędów — %s</title>
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; color: #1d2433; max-width: 960px; margin: 0 auto; padding: 24px; }
h1 { color: #d21f2e; border-bottom: 2px solid #d21f2e; padding-bottom: 6px; }
table { border-collapse: collapse; margin: 8px 0; width: 100%%; }
th, td { border: 1px solid #d7dfeb; padding: 6px 10px; text-align: left; vertical-align: top; }
th { background: #f2f5fa; white-space: nowrap; }
.case { border: 1px solid #d7dfeb; border-radius: 8px; padding: 12px 16px; margin: 12px 0; }
.case h3 { margin-top: 0; color: #d21f2e; }
figure { margin: 8px 0; }
figure img { max-width: 100%%; border: 1px solid #d7dfeb; border-radius: 6px; }
figcaption { font-size: 0.85em; color: #5a6478; }
</style></head><body>%s</body></html>""" % [_esc(project_name), body]


static func to_markdown(bugs: Array, project_name: String, attach_dir_name: String) -> String:
	var lines: Array[String] = []
	lines.append("# Raport błędów — %s" % project_name)
	lines.append("")
	lines.append("| ID | Tytuł | Moduł | Waga |")
	lines.append("|---|---|---|---|")
	for b in bugs:
		lines.append("| %s | %s | %s | %s |" % [b.id, b.title, b.module, b.severity])
	lines.append("")
	for b in bugs:
		lines.append("## %s — %s" % [b.id, b.title])
		lines.append("")
		lines.append("| | |")
		lines.append("|---|---|")
		lines.append("| Moduł | %s |" % b.module)
		if b.related_case != "":
			lines.append("| Powiązany przypadek | %s |" % b.related_case)
		lines.append("| Waga | %s |" % b.severity)
		if b.environment != "":
			lines.append("| Środowisko | %s |" % b.environment)
		if b.reporter != "":
			lines.append("| Zgłaszający | %s |" % b.reporter)
		lines.append("| Data | %s |" % b.date)
		lines.append("")
		lines.append("**Kroki reprodukcji:**")
		lines.append("")
		var steps := _step_lines(b.steps)
		for i in steps.size():
			lines.append("%d. %s" % [i + 1, steps[i]])
		lines.append("")
		lines.append("**Rezultat aktualny:** %s" % b.actual)
		lines.append("")
		lines.append("**Rezultat oczekiwany:** %s" % b.expected)
		lines.append("")
		for i in b.attachments.size():
			var fname := _attachment_filename(b, i)
			lines.append("![%s](%s/%s)" % [b.attachments[i].name, attach_dir_name, fname])
			lines.append("")
	return "\n".join(lines)


static func to_csv(bugs: Array) -> String:
	var lines: Array[String] = []
	lines.append(Exporter._csv_row(["ID", "Tytuł", "Moduł", "Powiązany przypadek", "Waga", "Środowisko", "Kroki reprodukcji", "Rezultat aktualny", "Rezultat oczekiwany", "Zgłaszający", "Data", "Załączniki"]))
	for b in bugs:
		var steps := _step_lines(b.steps)
		var steps_text := ""
		for i in steps.size():
			steps_text += "%d. %s\n" % [i + 1, steps[i]]
		var names: Array[String] = []
		for a in b.attachments:
			names.append(a.name)
		lines.append(Exporter._csv_row([b.id, b.title, b.module, b.related_case, b.severity, b.environment, steps_text.strip_edges(), b.actual, b.expected, b.reporter, b.date, ", ".join(names)]))
	return "﻿" + "\n".join(lines)


static func _save_attachments(dir_path: String, bugs: Array) -> String:
	var has_any := false
	for b in bugs:
		if not b.attachments.is_empty():
			has_any = true
	if not has_any:
		return ""
	var err := DirAccess.make_dir_recursive_absolute(dir_path)
	if err != OK and err != ERR_ALREADY_EXISTS:
		return "Nie można utworzyć folderu na załączniki: %s" % dir_path
	for b in bugs:
		for i in b.attachments.size():
			var fpath := dir_path.path_join(_attachment_filename(b, i))
			if b.attachments[i].image.save_png(fpath) != OK:
				return "Nie można zapisać załącznika: %s" % fpath
	return ""


static func _attachment_filename(b: BugReport, index: int) -> String:
	return "%s_zrzut_%d.png" % [b.id, index + 1]


static func _step_lines(steps: String) -> Array[String]:
	var out: Array[String] = []
	for line in steps.split("\n"):
		var s := line.strip_edges()
		# Usuń własną numerację użytkownika, aby nie dublować numerów.
		var re := RegEx.new()
		re.compile("^\\d+[\\.\\)]\\s*")
		s = re.sub(s, "")
		if not s.is_empty():
			out.append(s)
	if out.is_empty():
		out.append("—")
	return out


static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

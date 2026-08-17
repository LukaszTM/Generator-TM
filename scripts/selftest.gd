extends SceneTree
## Test dymny logiki uruchamiany bez okna:
##   godot --headless -s res://scripts/selftest.gd
## Sprawdza wczytanie pliku, analizę modułów, generowanie i eksport.

func _init() -> void:
	var failures := 0

	# 1. Wczytanie przykładowej dokumentacji z dysku.
	var res := DocLoader.load_file(ProjectSettings.globalize_path("res://przyklady/przykladowa_dokumentacja.md"))
	failures += _check(res.ok, "wczytanie pliku dokumentacji: %s" % res.error)

	# 2. Analiza modułów.
	var modules := ModuleAnalyzer.analyze(res.text)
	failures += _check(modules.size() == 4, "wykryto 4 moduły (jest: %d)" % modules.size())
	if modules.size() >= 1:
		failures += _check(modules[0].name == "Logowanie i konta", "nazwa 1. modułu (jest: %s)" % modules[0].name)
		failures += _check(modules[0].requirement_count() >= 3, "wymagania w module 1 (jest: %d)" % modules[0].requirement_count())

	# 3. Konwersja HTML -> tekst.
	var html := "<html><body><h1>Moduł A</h1><p>System musi działać.</p><h1>Moduł B</h1><ul><li>Użytkownik może się logować.</li></ul></body></html>"
	var text := DocLoader.html_to_text(html)
	failures += _check(text.contains("# Moduł A") and text.contains("- Użytkownik może się logować."), "konwersja HTML na tekst")
	var html_modules := ModuleAnalyzer.analyze(text)
	failures += _check(html_modules.size() == 2, "moduły z HTML (jest: %d)" % html_modules.size())

	# 4. Generowanie tylko dla wybranych modułów (1 z 4).
	var options := TestGenerator.Options.new()
	options.project_name = "Sklep testowy"
	options.doc_source = "przyklady/przykladowa_dokumentacja.md"
	var selected := [modules[0]]
	var out := TestGenerator.generate(selected, options)
	failures += _check(out.cases.size() > 5, "liczba przypadków dla 1 modułu (jest: %d)" % out.cases.size())
	var only_selected := true
	for c in out.cases:
		if c.module != "Logowanie i konta":
			only_selected = false
	failures += _check(only_selected, "przypadki wyłącznie dla wybranego modułu")
	failures += _check(out.plan_markdown.contains("# Plan testów"), "plan testów w Markdown")
	failures += _check(out.cases[0].id.begins_with("TC-"), "format ID przypadku (jest: %s)" % out.cases[0].id)

	# 5. Filtrowanie typów testów.
	var opt2 := TestGenerator.Options.new()
	opt2.include_negative = false
	opt2.include_security = false
	opt2.include_boundary = false
	var out2 := TestGenerator.generate(selected, opt2)
	var only_positive := true
	for c in out2.cases:
		if c.type != "Pozytywny":
			only_positive = false
	failures += _check(only_positive, "filtr typów testów (tylko pozytywne)")

	# 6. Eksporty.
	var md := Exporter.cases_markdown(out.cases, "Sklep testowy")
	failures += _check(md.contains("### TC-"), "eksport Markdown")
	# Kroki zawierają znaki nowej linii wewnątrz pól w cudzysłowach,
	# więc wiersze liczymy po identyfikatorach na początku linii.
	var csv := Exporter.cases_csv(out.cases)
	var csv_rows := 0
	for line in csv.split("\n"):
		if line.begins_with("\"TC-"):
			csv_rows += 1
	failures += _check(csv_rows == out.cases.size(), "liczba wierszy CSV (jest: %d)" % csv_rows)
	var html_doc := Exporter.full_html(out.plan_markdown, out.cases, "Sklep testowy")
	failures += _check(html_doc.contains("<!DOCTYPE html>") and html_doc.contains("Plan testów"), "eksport HTML")
	var tmp := OS.get_cache_dir().path_join("generator_tm_selftest.md")
	failures += _check(Exporter.save_text(tmp, md) == "", "zapis pliku na dysk")

	# 7. Raport błędów ze zrzutem ekranu.
	var bug := BugReporter.BugReport.new()
	bug.id = "BUG-001"
	bug.title = "Logowanie akceptuje puste hasło"
	bug.module = "Logowanie i konta"
	bug.severity = "Krytyczny"
	bug.environment = "Windows 11, Chrome 126"
	bug.steps = "Otwórz ekran logowania\nPozostaw hasło puste\nKliknij Zaloguj"
	bug.actual = "Użytkownik zostaje zalogowany."
	bug.expected = "Walidacja blokuje logowanie."
	bug.date = "2026-08-16 12:00:00"
	var shot := BugReporter.Attachment.new()
	shot.name = "ekran_logowania.png"
	shot.image = Image.create(8, 8, false, Image.FORMAT_RGBA8)
	shot.image.fill(Color.RED)
	bug.attachments.append(shot)
	var bug_html := BugReporter.to_html([bug], "Sklep testowy")
	failures += _check(bug_html.contains("data:image/png;base64,"), "raport błędów HTML z osadzonym zrzutem")
	failures += _check(bug_html.contains("BUG-001"), "raport błędów HTML zawiera zgłoszenie")
	var bug_dir := OS.get_cache_dir().path_join("generator_tm_bugtest")
	var bug_md_path := bug_dir.path_join("raport.md")
	DirAccess.make_dir_recursive_absolute(bug_dir)
	failures += _check(BugReporter.export(bug_md_path, "md", [bug], "Sklep testowy") == "", "eksport raportu błędów do Markdown")
	failures += _check(FileAccess.file_exists(bug_dir.path_join("raport_zalaczniki/BUG-001_zrzut_1.png")), "zapis zrzutu ekranu obok pliku Markdown")
	var bug_csv := BugReporter.to_csv([bug])
	failures += _check(bug_csv.contains("ekran_logowania.png"), "raport błędów CSV z nazwą załącznika")

	# 8. Motywy graficzne — każdy motyw musi się zbudować, a wszystkie
	# ikony logiczne muszą istnieć w jego wariancie assetów.
	for t in UITheme.themes():
		var built := UITheme.build(t["id"])
		failures += _check(built != null and built.has_stylebox("panel", "Card"), "budowa motywu „%s”" % t["name"])
		var missing: Array[String] = []
		for icon_name in UITheme.ICONS_LIGHT:
			if not ResourceLoader.exists(UITheme.icon_path(t["id"], icon_name)):
				missing.append(icon_name)
		failures += _check(missing.is_empty(), "ikony motywu „%s” (brakuje: %s)" % [t["name"], ", ".join(missing)])

	# 9. Pełna generacja wszystkich modułów.
	var out_all := TestGenerator.generate(modules, TestGenerator.Options.new())
	print("Moduły: %d | Przypadki (1 moduł): %d | Przypadki (wszystkie): %d" % [modules.size(), out.cases.size(), out_all.cases.size()])

	if failures == 0:
		print("SELFTEST OK — wszystkie kontrole zaliczone.")
		quit(0)
	else:
		print("SELFTEST NIEUDANY — liczba błędów: %d" % failures)
		quit(1)


func _check(condition: bool, label: String) -> int:
	if condition:
		print("  [OK] " + label)
		return 0
	print("  [BŁĄD] " + label)
	return 1

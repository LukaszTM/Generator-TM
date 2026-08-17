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
		for icon_name in UITheme.ICONS_MODERN:
			if not ResourceLoader.exists(UITheme.icon_path(t["id"], icon_name)):
				missing.append(icon_name)
		failures += _check(missing.is_empty(), "ikony motywu „%s” (brakuje: %s)" % [t["name"], ", ".join(missing)])

	# 9. Tester stron WWW — analiza HTML i oceny (offline).
	var web_html := """<html lang="pl"><head><title>Sklep testowy</title>
	<meta name="viewport" content="width=device-width"><link rel="icon" href="/fav.png">
	</head><body><h1>Witaj</h1><img src="a.png" alt="obraz"><img src="b.png">
	<a href="/kontakt">Kontakt</a><a href="https://example.com/x">Y</a>
	<a href="podstrona.html">Z</a><a href="#top">kotwica</a><a href="mailto:a@b.pl">mail</a>
	<img src="http://niezaszyfrowany.pl/obraz.png"><form></form></body></html>"""
	var parsed := WebTester.parse_page(web_html, "https://sklep.pl/dzial/strona.html")
	failures += _check(parsed.title == "Sklep testowy", "WWW: tytuł strony (jest: %s)" % parsed.title)
	failures += _check(parsed.h1_count == 1 and parsed.has_viewport and not parsed.has_description, "WWW: wykrywanie meta i H1")
	failures += _check(parsed.imgs_no_alt == 2 and parsed.imgs_total == 3, "WWW: obrazy bez alt (%d z %d)" % [parsed.imgs_no_alt, parsed.imgs_total])
	failures += _check(parsed.links.size() == 3, "WWW: liczba odnośników (jest: %d)" % parsed.links.size())
	failures += _check(parsed.links.has("https://sklep.pl/kontakt"), "WWW: adres bezwzględny z /")
	failures += _check(parsed.links.has("https://sklep.pl/dzial/podstrona.html"), "WWW: adres względny")
	failures += _check(parsed.mixed == 1, "WWW: mieszana treść (jest: %d)" % parsed.mixed)
	failures += _check(parsed.favicon == "https://sklep.pl/fav.png", "WWW: favicon (jest: %s)" % parsed.favicon)
	var web_checks := WebTester.evaluate_static(parsed, 200, 800, PackedStringArray(["Content-Type: text/html"]), web_html.length(), "https://sklep.pl/dzial/strona.html")
	var web_by_name := {}
	for c in web_checks:
		web_by_name[c.name] = c.result
	failures += _check(web_by_name.get("Dostępność strony") == "OK", "WWW: ocena dostępności")
	failures += _check(web_by_name.get("Mieszana treść (HTTP na HTTPS)") == "BŁĄD", "WWW: ocena mieszanej treści")
	failures += _check(web_by_name.get("Nagłówki bezpieczeństwa") == "UWAGA", "WWW: ocena nagłówków bezpieczeństwa")
	failures += _check(web_by_name.get("Opis strony (meta description)") == "UWAGA", "WWW: ocena braku meta description")
	var web_report := WebTester.report_html("https://sklep.pl", web_checks)
	failures += _check(web_report.contains("Raport testów strony") and web_report.contains("Dostępność strony"), "WWW: raport HTML")
	failures += _check(WebTester.report_csv("https://sklep.pl", web_checks).split("\n").size() == web_checks.size() + 2, "WWW: raport CSV")

	# 10. Tryb nauki: każdy przypadek ma wyjaśnienie „dlaczego ten test”.
	var missing_why := 0
	for c in out.cases:
		if c.why.strip_edges().is_empty():
			missing_why += 1
	failures += _check(missing_why == 0, "wyjaśnienia edukacyjne przypadków (brakuje: %d)" % missing_why)
	failures += _check(Glossary.TERMS.size() >= 15 and Glossary.as_text().contains("Przypadek testowy"), "słowniczek testera (%d pojęć)" % Glossary.TERMS.size())
	failures += _check(Exporter.cases_markdown(out.cases, "Sklep").contains("Dlaczego ten test?"), "wyjaśnienia w eksporcie Markdown")

	# 11. Raport z wykonania testów.
	var run_results := {}
	run_results[out.cases[0].id] = {"status": "Zaliczony", "note": ""}
	run_results[out.cases[1].id] = {"status": "Niezaliczony", "note": "Przycisk nie reaguje"}
	run_results[out.cases[2].id] = {"status": "Zablokowany", "note": ""}
	var rc := RunReport.counts(out.cases, run_results)
	failures += _check(rc["Zaliczony"] == 1 and rc["Niezaliczony"] == 1 and rc["Zablokowany"] == 1 and rc["Niewykonany"] == out.cases.size() - 3, "zliczanie wyników wykonania")
	var run_md := RunReport.markdown(out.cases, run_results, "Sklep testowy", "Jan Kowalski")
	failures += _check(run_md.contains("Przypadki niezaliczone") and run_md.contains("Przycisk nie reaguje"), "raport wykonania Markdown")
	var run_html := RunReport.html(out.cases, run_results, "Sklep testowy", "")
	failures += _check(run_html.contains("Niezaliczone: 1") and run_html.contains(out.cases[1].id), "raport wykonania HTML")
	failures += _check(RunReport.csv(out.cases, run_results).split("\n").size() == out.cases.size() + 1, "raport wykonania CSV")

	# 12. Ekstrakcja tekstu z PDF.
	# a) Syntetyczny PDF bez kompresji (operatory Tj/TJ, sekwencje \ i ósemkowe).
	var content := "BT /F1 12 Tf (Modul: Logowanie) Tj T* [(System ) (musi dzialac\\056)] TJ T* (Znaki \\(nawiasy\\)) Tj ET"
	var simple_pdf := "%PDF-1.4\n1 0 obj << /Length " + str(content.length()) + " >> stream\n" + content + "\nendstream endobj\ntrailer\n%%EOF"
	var pr := PdfReader.extract_bytes(simple_pdf.to_ascii_buffer())
	failures += _check(pr["ok"] and pr["text"].contains("Modul: Logowanie") and pr["text"].contains("musi dzialac.") and pr["text"].contains("(nawiasy)"), "PDF: strumień bez kompresji + escape'y (%s)" % pr.get("error", ""))
	# b) Syntetyczny PDF ze strumieniem FlateDecode.
	var deflated := content.to_ascii_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	var flate_head := "%PDF-1.4\n1 0 obj << /Filter /FlateDecode >> stream\n"
	var flate_pdf := flate_head.to_ascii_buffer() + deflated + "\nendstream endobj\ntrailer\n%%EOF".to_ascii_buffer()
	var pr2 := PdfReader.extract_bytes(flate_pdf)
	failures += _check(pr2["ok"] and pr2["text"].contains("Modul: Logowanie"), "PDF: dekompresja FlateDecode (%s)" % pr2.get("error", ""))
	# c) Prawdziwy PDF z osadzoną czcionką i polskimi znakami (ToUnicode).
	var pdf_path := ProjectSettings.globalize_path("res://przyklady/przykladowa_dokumentacja.pdf")
	if FileAccess.file_exists(pdf_path):
		var res_pdf := DocLoader.load_file(pdf_path)
		failures += _check(res_pdf.ok, "PDF: wczytanie przykładowego pliku (%s)" % res_pdf.error)
		if res_pdf.ok:
			failures += _check(res_pdf.text.contains("Logowanie i konta"), "PDF: tytuł modułu odczytany")
			failures += _check(res_pdf.text.contains("ąćęłńóśźż"), "PDF: polskie znaki przez ToUnicode")
			var pdf_modules := ModuleAnalyzer.analyze(res_pdf.text)
			failures += _check(pdf_modules.size() >= 3, "PDF: wykrywanie modułów z tekstu (jest: %d)" % pdf_modules.size())
	# d) Czytelny błąd dla pliku niebędącego PDF-em.
	var not_pdf := PdfReader.extract_bytes("to nie jest pdf".to_ascii_buffer())
	failures += _check(not not_pdf["ok"] and not_pdf["error"].contains("%PDF"), "PDF: komunikat dla złego pliku")

	# 13. Pełna generacja wszystkich modułów.
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

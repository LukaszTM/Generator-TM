class_name WebTester
extends RefCounted
## Automatyczne testy strony WWW po adresie URL: dostępność, czas odpowiedzi,
## HTTPS, podstawy SEO/dostępności (tytuł, meta, H1, alt), favicon, mieszana
## treść, nagłówki bezpieczeństwa oraz weryfikacja odnośników na stronie.

const MAX_LINKS := 20           # ile odnośników ze strony sprawdzamy
const PAGE_TIMEOUT := 20.0
const LINK_TIMEOUT := 10.0
const SLOW_MS := 1500
const VERY_SLOW_MS := 4000

## Pojedynczy wynik kontroli.
class Check:
	var name := ""
	var result := "OK"      # OK / UWAGA / BŁĄD / INFO
	var details := ""

	static func make(n: String, r: String, d: String) -> Check:
		var c := Check.new()
		c.name = n
		c.result = r
		c.details = d
		return c


# ------------------------------------------------------------------
# Analiza HTML (czysta funkcja — testowalna bez sieci)
# ------------------------------------------------------------------
static func parse_page(html: String, base_url: String) -> Dictionary:
	var re := RegEx.new()
	var out := {
		"title": "", "has_description": false, "has_viewport": false,
		"lang": "", "h1_count": 0, "imgs_total": 0, "imgs_no_alt": 0,
		"forms": 0, "links": [] as Array[String], "mixed": 0, "favicon": "",
	}

	re.compile("(?is)<title[^>]*>(.*?)</title>")
	var m := re.search(html)
	if m != null:
		out.title = m.get_string(1).strip_edges().replace("\n", " ")

	re.compile("(?is)<meta[^>]*>")
	for meta in re.search_all(html):
		var tag := meta.get_string(0).to_lower()
		if tag.contains("name") and tag.contains("description") and tag.contains("content"):
			out.has_description = true
		if tag.contains("viewport"):
			out.has_viewport = true

	re.compile("(?is)<html[^>]*\\slang\\s*=\\s*[\"']([^\"']+)")
	m = re.search(html)
	if m != null:
		out.lang = m.get_string(1).strip_edges()

	re.compile("(?is)<h1[\\s>]")
	out.h1_count = re.search_all(html).size()

	re.compile("(?is)<img[^>]*>")
	for img in re.search_all(html):
		out.imgs_total += 1
		var tag := img.get_string(0).to_lower()
		if not tag.contains("alt"):
			out.imgs_no_alt += 1

	re.compile("(?is)<form[\\s>]")
	out.forms = re.search_all(html).size()

	re.compile("(?is)<link[^>]+rel\\s*=\\s*[\"'][^\"']*icon[^\"']*[\"'][^>]*>")
	m = re.search(html)
	if m != null:
		var re_href := RegEx.new()
		re_href.compile("(?is)href\\s*=\\s*[\"']([^\"']+)")
		var mh := re_href.search(m.get_string(0))
		if mh != null:
			out.favicon = absolute_url(mh.get_string(1), base_url)

	# Odnośniki <a href> — absolutne, bez duplikatów, bez kotwic i pseudo-adresów.
	re.compile("(?is)<a[^>]+href\\s*=\\s*[\"']([^\"']+)[\"']")
	var seen := {}
	for link in re.search_all(html):
		var href := link.get_string(1).strip_edges()
		if href.is_empty() or href.begins_with("#"):
			continue
		var lower := href.to_lower()
		if lower.begins_with("mailto:") or lower.begins_with("tel:") or lower.begins_with("javascript:") or lower.begins_with("data:"):
			continue
		var absolute := absolute_url(href, base_url)
		if absolute.is_empty() or seen.has(absolute):
			continue
		seen[absolute] = true
		out.links.append(absolute)

	# Mieszana treść: zasoby http:// na stronie https://.
	if base_url.to_lower().begins_with("https://"):
		re.compile("(?i)(src|srcset)\\s*=\\s*[\"']http://")
		out.mixed = re.search_all(html).size()
	return out


## Zamienia względny adres na bezwzględny w kontekście strony bazowej.
static func absolute_url(href: String, base_url: String) -> String:
	var h := href.strip_edges()
	if h.is_empty():
		return ""
	var lower := h.to_lower()
	if lower.begins_with("http://") or lower.begins_with("https://"):
		return h
	var re := RegEx.new()
	re.compile("^(https?)://([^/]+)")
	var m := re.search(base_url)
	if m == null:
		return ""
	var scheme := m.get_string(1)
	var origin := "%s://%s" % [scheme, m.get_string(2)]
	if h.begins_with("//"):
		return scheme + ":" + h
	if h.begins_with("/"):
		return origin + h
	if h.begins_with("?"):
		return base_url.split("?")[0] + h
	var base_dir := base_url.split("?")[0]
	if not base_dir.ends_with("/"):
		base_dir = base_dir.substr(0, base_dir.rfind("/") + 1)
	if not base_dir.contains("://") or base_dir.ends_with("//"):
		base_dir = origin + "/"
	return base_dir + h


## Kontrole nie wymagające dodatkowych zapytań (czysta funkcja — testowalna).
static func evaluate_static(parsed: Dictionary, status: int, elapsed_ms: int, headers: PackedStringArray, html_size: int, url: String) -> Array:
	var checks: Array = []

	checks.append(Check.make("Dostępność strony", "OK" if (status >= 200 and status < 400) else "BŁĄD",
		"Kod odpowiedzi HTTP: %d" % status))

	var time_result := "OK"
	if elapsed_ms > VERY_SLOW_MS:
		time_result = "BŁĄD"
	elif elapsed_ms > SLOW_MS:
		time_result = "UWAGA"
	checks.append(Check.make("Czas odpowiedzi", time_result, "%d ms (uwaga powyżej %d ms)" % [elapsed_ms, SLOW_MS]))

	if url.to_lower().begins_with("https://"):
		checks.append(Check.make("Szyfrowanie HTTPS", "OK", "Strona działa po HTTPS, certyfikat zaakceptowany."))
	else:
		checks.append(Check.make("Szyfrowanie HTTPS", "UWAGA", "Adres używa nieszyfrowanego HTTP."))

	var title: String = parsed.title
	if title.is_empty():
		checks.append(Check.make("Tytuł strony (<title>)", "BŁĄD", "Brak tytułu strony."))
	elif title.length() > 65:
		checks.append(Check.make("Tytuł strony (<title>)", "UWAGA", "Tytuł ma %d znaków (zalecane do 65): „%s”" % [title.length(), title.substr(0, 60) + "…"]))
	else:
		checks.append(Check.make("Tytuł strony (<title>)", "OK", "„%s”" % title))

	checks.append(Check.make("Opis strony (meta description)", "OK" if parsed.has_description else "UWAGA",
		"Znacznik obecny." if parsed.has_description else "Brak meta description — istotne dla wyników wyszukiwania."))

	checks.append(Check.make("Widok mobilny (meta viewport)", "OK" if parsed.has_viewport else "UWAGA",
		"Znacznik obecny." if parsed.has_viewport else "Brak meta viewport — strona może źle wyglądać na telefonach."))

	if parsed.lang == "":
		checks.append(Check.make("Język dokumentu (atrybut lang)", "UWAGA", "Brak atrybutu lang w <html> — ważny dla czytników ekranu."))
	else:
		checks.append(Check.make("Język dokumentu (atrybut lang)", "OK", "lang=\"%s\"" % parsed.lang))

	if parsed.h1_count == 0:
		checks.append(Check.make("Nagłówek główny (H1)", "UWAGA", "Brak nagłówka H1 na stronie."))
	elif parsed.h1_count > 1:
		checks.append(Check.make("Nagłówek główny (H1)", "UWAGA", "Nagłówków H1 jest %d (zalecany jeden)." % parsed.h1_count))
	else:
		checks.append(Check.make("Nagłówek główny (H1)", "OK", "Dokładnie jeden nagłówek H1."))

	if parsed.imgs_total == 0:
		checks.append(Check.make("Teksty alternatywne obrazów", "INFO", "Brak obrazów na stronie."))
	elif parsed.imgs_no_alt > 0:
		checks.append(Check.make("Teksty alternatywne obrazów", "UWAGA", "%d z %d obrazów nie ma atrybutu alt." % [parsed.imgs_no_alt, parsed.imgs_total]))
	else:
		checks.append(Check.make("Teksty alternatywne obrazów", "OK", "Wszystkie %d obrazów ma atrybut alt." % parsed.imgs_total))

	if parsed.mixed > 0:
		checks.append(Check.make("Mieszana treść (HTTP na HTTPS)", "BŁĄD", "%d zasobów ładowanych po nieszyfrowanym HTTP." % parsed.mixed))
	elif url.to_lower().begins_with("https://"):
		checks.append(Check.make("Mieszana treść (HTTP na HTTPS)", "OK", "Nie wykryto zasobów HTTP."))

	# Nagłówki bezpieczeństwa odpowiedzi.
	var have := {"strict-transport-security": false, "x-content-type-options": false, "content-security-policy": false, "x-frame-options": false}
	for h in headers:
		var lower_h := h.to_lower()
		for key in have:
			if lower_h.begins_with(key + ":"):
				have[key] = true
	var missing: Array[String] = []
	if url.to_lower().begins_with("https://") and not have["strict-transport-security"]:
		missing.append("Strict-Transport-Security")
	if not have["x-content-type-options"]:
		missing.append("X-Content-Type-Options")
	if not (have["content-security-policy"] or have["x-frame-options"]):
		missing.append("Content-Security-Policy / X-Frame-Options")
	if missing.is_empty():
		checks.append(Check.make("Nagłówki bezpieczeństwa", "OK", "Podstawowe nagłówki bezpieczeństwa obecne."))
	else:
		checks.append(Check.make("Nagłówki bezpieczeństwa", "UWAGA", "Brakuje: %s." % ", ".join(missing)))

	checks.append(Check.make("Rozmiar dokumentu HTML", "INFO" if html_size < 2 * 1024 * 1024 else "UWAGA",
		"%.1f KB" % (html_size / 1024.0)))

	checks.append(Check.make("Formularze na stronie", "INFO", "Wykryto formularzy: %d." % parsed.forms))
	return checks


# ------------------------------------------------------------------
# Pełny przebieg testów (wymaga HTTPRequest w drzewie sceny).
# progress(tekst: String, procent: float)
# ------------------------------------------------------------------
static func run(http: HTTPRequest, url: String, progress: Callable) -> Array:
	var checks: Array = []
	progress.call("Pobieranie strony %s…" % url, 5.0)
	http.timeout = PAGE_TIMEOUT
	http.body_size_limit = 8 * 1024 * 1024
	var t0 := Time.get_ticks_msec()
	var err := http.request(url, ["User-Agent: GeneratorTM/1.5 (tester stron)", "Accept: text/html,*/*"])
	if err != OK:
		checks.append(Check.make("Dostępność strony", "BŁĄD", "Nie udało się rozpocząć połączenia (kod %d). Sprawdź adres." % err))
		return checks
	var reply: Array = await http.request_completed
	var elapsed := int(Time.get_ticks_msec() - t0)
	var result_code: int = reply[0]
	var status: int = reply[1]
	var headers: PackedStringArray = reply[2]
	var body: PackedByteArray = reply[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		var reason := "Błąd połączenia (kod %d)." % result_code
		if result_code == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			reason = "Błąd uzgadniania TLS — certyfikat strony może być nieważny."
		elif result_code == HTTPRequest.RESULT_CANT_RESOLVE:
			reason = "Nie można znaleźć serwera — sprawdź adres."
		elif result_code == HTTPRequest.RESULT_TIMEOUT:
			reason = "Przekroczono czas oczekiwania (%d s)." % int(PAGE_TIMEOUT)
		checks.append(Check.make("Dostępność strony", "BŁĄD", reason))
		return checks

	var html := body.get_string_from_utf8()
	if html.is_empty():
		html = body.get_string_from_ascii()
	var parsed := parse_page(html, url)
	checks = evaluate_static(parsed, status, elapsed, headers, body.size(), url)

	# HTTPS dostępny dla adresu HTTP?
	if url.to_lower().begins_with("http://"):
		progress.call("Sprawdzanie wersji HTTPS…", 25.0)
		var https_url := "https://" + url.substr(7)
		var st := await _probe(http, https_url)
		for c in checks:
			if c.name == "Szyfrowanie HTTPS":
				if st >= 200 and st < 400:
					c.details = "Adres używa HTTP, ale strona działa też pod %s — używaj wersji szyfrowanej." % https_url
				else:
					c.details = "Adres używa nieszyfrowanego HTTP, a wersja HTTPS nie odpowiada."

	# Favicon.
	progress.call("Sprawdzanie ikony strony…", 32.0)
	var favicon_url: String = parsed.favicon
	if favicon_url == "":
		favicon_url = absolute_url("/favicon.ico", url)
	var fav_status := await _probe(http, favicon_url)
	if fav_status >= 200 and fav_status < 400:
		checks.append(Check.make("Ikona strony (favicon)", "OK", favicon_url))
	else:
		checks.append(Check.make("Ikona strony (favicon)", "UWAGA", "Nie znaleziono ikony strony (sprawdzono: %s)." % favicon_url))

	# Odnośniki.
	var links: Array = parsed.links
	if links.is_empty():
		checks.append(Check.make("Odnośniki na stronie", "INFO", "Nie znaleziono odnośników do sprawdzenia."))
	else:
		var to_check: Array = links.slice(0, MAX_LINKS)
		var broken: Array[String] = []
		http.body_size_limit = 256 * 1024
		for i in to_check.size():
			progress.call("Sprawdzanie odnośników… (%d/%d)" % [i + 1, to_check.size()], 35.0 + 60.0 * float(i) / to_check.size())
			var link_status := await _probe(http, to_check[i])
			if link_status < 0 or link_status == 404 or link_status == 410 or link_status >= 500:
				broken.append("%s (%s)" % [to_check[i], "brak połączenia" if link_status < 0 else str(link_status)])
		http.body_size_limit = 8 * 1024 * 1024
		var note := ""
		if links.size() > to_check.size():
			note = " Sprawdzono pierwsze %d z %d odnośników." % [to_check.size(), links.size()]
		if broken.is_empty():
			checks.append(Check.make("Odnośniki na stronie", "OK", ("Wszystkie %d sprawdzonych odnośników działa." % to_check.size()) + note))
		else:
			checks.append(Check.make("Odnośniki na stronie", "BŁĄD", ("Niedziałające odnośniki (%d): " % broken.size()) + " | ".join(broken) + note))
	progress.call("Zakończono.", 100.0)
	return checks


## Lekkie zapytanie o status adresu (HEAD z awaryjnym GET). Zwraca kod HTTP lub -1.
static func _probe(http: HTTPRequest, url: String) -> int:
	http.timeout = LINK_TIMEOUT
	var err := http.request(url, ["User-Agent: GeneratorTM/1.5 (tester stron)"], HTTPClient.METHOD_HEAD)
	if err != OK:
		return -1
	var reply: Array = await http.request_completed
	if reply[0] != HTTPRequest.RESULT_SUCCESS:
		return -1
	var status: int = reply[1]
	if status == 405 or status == 501:
		# Serwer nie obsługuje HEAD — spróbuj GET.
		err = http.request(url, ["User-Agent: GeneratorTM/1.5 (tester stron)"])
		if err != OK:
			return -1
		reply = await http.request_completed
		if reply[0] != HTTPRequest.RESULT_SUCCESS:
			return -1
		status = reply[1]
	return status


# ------------------------------------------------------------------
# Raporty
# ------------------------------------------------------------------
static func report_markdown(url: String, checks: Array) -> String:
	var lines: Array[String] = []
	lines.append("# Raport testów strony WWW")
	lines.append("")
	lines.append("| | |")
	lines.append("|---|---|")
	lines.append("| Adres | %s |" % url)
	lines.append("| Data | %s |" % Time.get_datetime_string_from_system(false, true))
	lines.append("| Wynik | %s |" % summary(checks))
	lines.append("")
	lines.append("| Kontrola | Wynik | Szczegóły |")
	lines.append("|---|---|---|")
	for c in checks:
		lines.append("| %s | %s | %s |" % [c.name, c.result, c.details.replace("|", "/")])
	lines.append("")
	return "\n".join(lines)


static func report_csv(url: String, checks: Array) -> String:
	var lines: Array[String] = []
	lines.append(Exporter._csv_row(["Adres", url, "Data", Time.get_datetime_string_from_system(false, true)]))
	lines.append(Exporter._csv_row(["Kontrola", "Wynik", "Szczegóły"]))
	for c in checks:
		lines.append(Exporter._csv_row([c.name, c.result, c.details]))
	return "﻿" + "\n".join(lines)


static func report_html(url: String, checks: Array) -> String:
	var rows := ""
	for c in checks:
		var color: String = {"OK": "#16a34a", "UWAGA": "#d97706", "BŁĄD": "#dc2626", "INFO": "#5a6478"}.get(c.result, "#5a6478")
		rows += "<tr><td>%s</td><td style=\"color:%s;font-weight:600\">%s</td><td>%s</td></tr>" % [_esc(c.name), color, c.result, _esc(c.details)]
	return """<!DOCTYPE html>
<html lang="pl"><head><meta charset="utf-8">
<title>Raport testów strony — %s</title>
<style>
body { font-family: 'Segoe UI', Arial, sans-serif; color: #1d2433; max-width: 960px; margin: 0 auto; padding: 24px; }
h1 { color: #1a3fc4; border-bottom: 2px solid #0e8f8f; padding-bottom: 6px; }
table { border-collapse: collapse; width: 100%%; margin: 12px 0; }
th, td { border: 1px solid #d7dfeb; padding: 6px 10px; text-align: left; vertical-align: top; }
th { background: #f2f5fa; }
</style></head><body>
<h1>Raport testów strony WWW</h1>
<p><strong>Adres:</strong> %s<br><strong>Data:</strong> %s<br><strong>Wynik:</strong> %s</p>
<table><tr><th>Kontrola</th><th>Wynik</th><th>Szczegóły</th></tr>%s</table>
</body></html>""" % [_esc(url), _esc(url), Time.get_datetime_string_from_system(false, true), summary(checks), rows]


static func summary(checks: Array) -> String:
	var errors := 0
	var warnings := 0
	for c in checks:
		if c.result == "BŁĄD":
			errors += 1
		elif c.result == "UWAGA":
			warnings += 1
	if errors == 0 and warnings == 0:
		return "wszystkie kontrole zaliczone"
	return "błędy: %d, uwagi: %d" % [errors, warnings]


static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

class_name DocLoader
extends RefCounted
## Wczytywanie dokumentacji / informacji o aplikacji z dysku lub z adresu URL.
## Obsługiwane formaty tekstowe: .md, .txt, .html/.htm, .json, .csv.

const MAX_URL_BYTES := 8 * 1024 * 1024  # 8 MB limitu na pobieranie z sieci

## Wynik wczytywania.
class Result:
	var ok := false
	var text := ""
	var error := ""
	var source_label := ""   # opis źródła do planu testów
	var kind := ""           # "plik" / "folder" / "url"


static func is_url(path: String) -> bool:
	var p := path.strip_edges().to_lower()
	return p.begins_with("http://") or p.begins_with("https://")


## Wczytuje treść z dysku (plik tekstowy). Zwraca Result.
static func load_file(path: String) -> Result:
	var res := Result.new()
	res.kind = "plik"
	res.source_label = path
	if not FileAccess.file_exists(path):
		res.error = "Plik nie istnieje: %s" % path
		return res
	var ext := path.get_extension().to_lower()
	if ext == "pdf":
		var pdf := PdfReader.extract_file(path)
		if not pdf["ok"]:
			res.error = pdf["error"]
			return res
		res.text = pdf["text"]
		res.ok = true
		return res
	if ext in ["docx", "doc", "odt", "xlsx"]:
		res.error = "Format .%s nie jest obsługiwany bezpośrednio. Zapisz dokumentację jako .pdf, .txt, .md lub .html i wczytaj ponownie." % ext
		return res
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		res.error = "Nie można otworzyć pliku (kod błędu: %s)." % FileAccess.get_open_error()
		return res
	var raw := f.get_buffer(f.get_length())
	f.close()
	var text := raw.get_string_from_utf8()
	if text.is_empty() and raw.size() > 0:
		# Plik nie jest w UTF-8 — spróbuj potraktować go jak ASCII/Latin.
		text = raw.get_string_from_ascii()
	if text.strip_edges().is_empty():
		res.error = "Plik jest pusty albo nie zawiera tekstu (pliki binarne nie są obsługiwane)."
		return res
	res.text = _normalize(text, ext)
	res.ok = true
	return res


## Skanuje folder aplikacji: zwraca w polu text pseudo-dokument z listą
## podkatalogów (kandydaci na moduły) i plików.
static func load_directory(path: String) -> Result:
	var res := Result.new()
	res.kind = "folder"
	res.source_label = path
	var dir := DirAccess.open(path)
	if dir == null:
		res.error = "Nie można otworzyć folderu: %s" % path
		return res
	var lines: Array[String] = []
	var subdirs: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with(".") and not entry.to_lower() in ["node_modules", "build", "dist", "bin", "obj", "target", "__pycache__", "venv", "vendor"]:
				subdirs.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	subdirs.sort()
	for sub in subdirs:
		lines.append("# " + sub.capitalize())
		var files := _list_files(path.path_join(sub), 2, 40)
		for fpath in files:
			lines.append("- plik: " + fpath)
		lines.append("")
	if subdirs.is_empty():
		var files := _list_files(path, 1, 80)
		lines.append("# Aplikacja")
		for fpath in files:
			lines.append("- plik: " + fpath)
	res.text = "\n".join(lines)
	res.ok = true
	return res


## Pobiera treść z URL. Wymaga węzła HTTPRequest będącego w drzewie sceny.
## Zwraca Result (wywołanie: await DocLoader.load_url(http_request, url)).
static func load_url(http: HTTPRequest, url: String) -> Result:
	var res := Result.new()
	res.kind = "url"
	res.source_label = url
	http.timeout = 30.0
	var err := http.request(url, ["User-Agent: GeneratorTM/1.0", "Accept: text/html,text/plain,text/markdown,*/*"])
	if err != OK:
		res.error = "Nie udało się rozpocząć pobierania (kod: %s). Sprawdź adres URL." % err
		return res
	var reply: Array = await http.request_completed
	var result_code: int = reply[0]
	var status: int = reply[1]
	var body: PackedByteArray = reply[3]
	if result_code != HTTPRequest.RESULT_SUCCESS:
		res.error = "Błąd połączenia (kod: %s). Sprawdź adres i dostęp do internetu." % result_code
		return res
	if status < 200 or status >= 300:
		res.error = "Serwer zwrócił status HTTP %s dla adresu %s." % [status, url]
		return res
	if body.size() > MAX_URL_BYTES:
		body = body.slice(0, MAX_URL_BYTES)
	# PDF pobrany z adresu URL — rozpoznajemy po nagłówku pliku.
	if body.size() > 4 and body.slice(0, 4).get_string_from_ascii() == "%PDF":
		var pdf := PdfReader.extract_bytes(body)
		if not pdf["ok"]:
			res.error = pdf["error"]
			return res
		res.text = pdf["text"]
		res.ok = true
		return res
	var text := body.get_string_from_utf8()
	if text.strip_edges().is_empty():
		res.error = "Pobrana treść jest pusta lub nie jest tekstem."
		return res
	var ext := url.get_extension().to_lower()
	if ext == "" or text.to_lower().contains("<html") or text.to_lower().contains("<!doctype"):
		ext = "html"
	res.text = _normalize(text, ext)
	res.ok = true
	return res


static func _normalize(text: String, ext: String) -> String:
	if ext in ["html", "htm"]:
		return html_to_text(text)
	return text.replace("\r\n", "\n").replace("\r", "\n")


## Prosta konwersja HTML -> tekst z zachowaniem nagłówków jako nagłówki Markdown.
static func html_to_text(html: String) -> String:
	var t := html.replace("\r\n", "\n").replace("\r", "\n")
	var re := RegEx.new()
	# Usuń skrypty, style i komentarze.
	re.compile("(?is)<script.*?</script>")
	t = re.sub(t, " ", true)
	re.compile("(?is)<style.*?</style>")
	t = re.sub(t, " ", true)
	re.compile("(?s)<!--.*?-->")
	t = re.sub(t, " ", true)
	# Nagłówki na składnię Markdown (H1-H2 -> moduły, H3 -> podsekcje).
	for level in range(1, 7):
		var hashes := "#".repeat(mini(level, 3))
		re.compile("(?is)<h%d[^>]*>" % level)
		t = re.sub(t, "\n\n" + hashes + " ", true)
		re.compile("(?is)</h%d>" % level)
		t = re.sub(t, "\n", true)
	# Elementy blokowe -> nowe linie, listy -> myślniki.
	re.compile("(?is)<li[^>]*>")
	t = re.sub(t, "\n- ", true)
	re.compile("(?is)<(p|div|section|article|tr|br|ul|ol|table|nav|header|footer)[^>]*>")
	t = re.sub(t, "\n", true)
	# Pozostałe znaczniki precz.
	re.compile("(?s)<[^>]+>")
	t = re.sub(t, " ", true)
	# Encje HTML.
	var entities := {
		"&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">",
		"&quot;": "\"", "&#39;": "'", "&oacute;": "ó", "&Oacute;": "Ó",
	}
	for e in entities:
		t = t.replace(e, entities[e])
	# Zbędne spacje i puste linie.
	re.compile("[ \\t]+")
	t = re.sub(t, " ", true)
	re.compile("\\n{3,}")
	t = re.sub(t, "\n\n", true)
	var out: Array[String] = []
	for line in t.split("\n"):
		out.append(line.strip_edges())
	return "\n".join(out)


static func _list_files(path: String, depth: int, limit: int) -> Array[String]:
	var found: Array[String] = []
	_walk(path, "", depth, limit, found)
	return found


static func _walk(base: String, rel: String, depth: int, limit: int, found: Array[String]) -> void:
	if depth < 0 or found.size() >= limit:
		return
	var dir := DirAccess.open(base.path_join(rel) if rel != "" else base)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "" and found.size() < limit:
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var rel_path := rel.path_join(entry) if rel != "" else entry
		if dir.current_is_dir():
			_walk(base, rel_path, depth - 1, limit, found)
		else:
			found.append(rel_path)
		entry = dir.get_next()
	dir.list_dir_end()

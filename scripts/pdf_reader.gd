class_name PdfReader
extends RefCounted
## Ekstrakcja tekstu z plików PDF w czystym GDScript (bez zależności).
##
## Obsługiwane: strumienie bez filtra i FlateDecode (zlib), operatory tekstu
## Tj / TJ / ' / ", łańcuchy nawiasowe (z sekwencjami \ i ósemkowymi) oraz
## szesnastkowe, mapy /ToUnicode (bfchar + bfrange) — dzięki nim działają
## polskie znaki w PDF-ach z osadzonymi czcionkami (Word, LibreOffice itd.).
## Nieobsługiwane: PDF-y zaszyfrowane oraz skany bez warstwy tekstowej (OCR).

const MAX_FILE_SIZE := 64 * 1024 * 1024
const MAX_STREAM_SIZE := 24 * 1024 * 1024
const MAX_TEXT_SIZE := 4 * 1024 * 1024

# Bajt zerowy nie może istnieć w String — w tekstach strumieni zastępujemy go
# znakiem z obszaru prywatnego Unicode i odwzorowujemy z powrotem przy dekodowaniu.
const NUL_SENTINEL := 0xE000


## Zwraca {ok: bool, text: String, error: String}.
static func extract_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "text": "", "error": "Nie można otworzyć pliku (kod błędu: %s)." % FileAccess.get_open_error()}
	if f.get_length() > MAX_FILE_SIZE:
		return {"ok": false, "text": "", "error": "Plik PDF jest zbyt duży (limit: %d MB)." % (MAX_FILE_SIZE / 1024 / 1024)}
	var bytes := f.get_buffer(f.get_length())
	f.close()
	return extract_bytes(bytes)


static func extract_bytes(bytes: PackedByteArray) -> Dictionary:
	# Łańcuch do skanowania struktury: 1 znak = 1 bajt (indeksy = offsety);
	# bajty zerowe zastępujemy , bo String nie może ich zawierać.
	var raw := _bytes_to_string(bytes, char(1))
	if not raw.begins_with("%PDF"):
		return {"ok": false, "text": "", "error": "To nie jest plik PDF (brak nagłówka %PDF)."}
	if raw.contains("/Encrypt"):
		return {"ok": false, "text": "", "error": "PDF jest zaszyfrowany — zapisz go bez hasła albo wyeksportuj do .txt."}

	# --- 1a. Zbierz obiekty: numer -> {dict, body, zakres strumienia} ---
	var objects := {}
	var re_obj := RegEx.new()
	re_obj.compile("(?s)(\\d+)\\s+\\d+\\s+obj\\b(.*?)endobj")
	for m in re_obj.search_all(raw):
		var num := int(m.get_string(1))
		var body := m.get_string(2)
		var dict := body
		var range_start := -1
		var range_end := -1
		var stream_pos := body.find("stream")
		if stream_pos != -1:
			dict = body.substr(0, stream_pos)
			# Dane strumienia zaczynają się po "stream" + EOL, kończą przed "endstream".
			var data_start := stream_pos + 6
			if data_start < body.length() and body[data_start] == "\r":
				data_start += 1
			if data_start < body.length() and body[data_start] == "\n":
				data_start += 1
			var data_end := body.rfind("endstream")
			if data_end > data_start:
				range_start = m.get_start(2) + data_start
				range_end = m.get_start(2) + data_end
		objects[num] = {"dict": dict, "body": body, "start": range_start, "end": range_end, "stream": ""}

	if objects.is_empty():
		return {"ok": false, "text": "", "error": "Nie znaleziono obiektów PDF — plik może być uszkodzony."}

	# --- 1b. Zdekoduj strumienie, przycinając dane do /Length (dodatkowe
	# bajty za strumieniem zapętlają dekompresję zlib w Godocie). ---
	var re_len_direct := RegEx.new()
	re_len_direct.compile("/Length\\s+(\\d+)\\s*(?![0-9]|\\s*R)")
	var re_len_ref := RegEx.new()
	re_len_ref.compile("/Length\\s+(\\d+)\\s+\\d+\\s+R")
	for num in objects:
		var obj: Dictionary = objects[num]
		if obj["start"] < 0:
			continue
		var data := bytes.slice(obj["start"], obj["end"])
		var declared := -1
		var mr: RegExMatch = re_len_ref.search(obj["dict"])
		if mr != null:
			var len_obj := int(mr.get_string(1))
			if objects.has(len_obj):
				declared = int(String(objects[len_obj]["body"]).strip_edges())
		else:
			var md: RegExMatch = re_len_direct.search(obj["dict"])
			if md != null:
				declared = int(md.get_string(1))
		if declared >= 0 and declared <= data.size():
			data = data.slice(0, declared)
		else:
			# Bez wiarygodnej długości: odetnij końcowe białe znaki.
			var cut := data.size()
			while cut > 0 and (data[cut - 1] == 0x0A or data[cut - 1] == 0x0D or data[cut - 1] == 0x20 or data[cut - 1] == 0x09):
				cut -= 1
			data = data.slice(0, cut)
		obj["stream"] = _decode_stream(obj["dict"], data)

	# --- 2. Mapy ToUnicode czcionek: nazwa zasobu (/F1) -> CMap ---
	var font_cmaps := _collect_font_cmaps(objects)

	# --- 3. Wyciągnij tekst ze strumieni treści ---
	var out := ""
	for num in objects:
		var stream: String = objects[num]["stream"]
		if stream.is_empty():
			continue
		# Strumień treści strony zawiera operatory tekstu.
		if not (stream.contains("Tj") or stream.contains("TJ") or stream.contains("BT")):
			continue
		out += _extract_from_content(stream, font_cmaps)
		if out.length() > MAX_TEXT_SIZE:
			break

	out = _tidy(out)
	if out.strip_edges().length() < 8:
		return {"ok": false, "text": "", "error": "Nie udało się wydobyć tekstu — PDF może być skanem (obrazem) bez warstwy tekstowej. Użyj OCR albo zapisz dokumentację jako .txt/.md."}
	return {"ok": true, "text": out, "error": ""}


# ------------------------------------------------------------------
# Strumienie
# ------------------------------------------------------------------
static func _decode_stream(dict: String, data: PackedByteArray) -> String:
	if dict.contains("/FlateDecode"):
		var inflated := data.decompress_dynamic(MAX_STREAM_SIZE, FileAccess.COMPRESSION_DEFLATE)
		if inflated.is_empty():
			return ""
		return _bytes_to_string(inflated, char(NUL_SENTINEL))
	# Filtry obrazów i inne pomijamy; brak filtra = surowe dane.
	if dict.contains("/Filter"):
		return ""
	return _bytes_to_string(data, char(NUL_SENTINEL))


## Konwersja bajtów na String 1:1 (Latin-1) z podmianą bajtów zerowych.
## Działa fragmentami między zerami, więc jest szybka także dla dużych danych.
static func _bytes_to_string(data: PackedByteArray, nul_replacement: String) -> String:
	var z := data.find(0)
	if z == -1:
		return data.get_string_from_ascii()
	var parts := PackedStringArray()
	var start := 0
	while z != -1:
		parts.append(data.slice(start, z).get_string_from_ascii())
		parts.append(nul_replacement)
		start = z + 1
		z = data.find(0, start)
	parts.append(data.slice(start, data.size()).get_string_from_ascii())
	return "".join(parts)


# ------------------------------------------------------------------
# Czcionki i mapy ToUnicode
# ------------------------------------------------------------------
static func _collect_font_cmaps(objects: Dictionary) -> Dictionary:
	# a) obiekt czcionki -> numer obiektu ToUnicode
	var tounicode_of_font := {}
	var re_tu := RegEx.new()
	re_tu.compile("/ToUnicode\\s+(\\d+)\\s+\\d+\\s+R")
	for num in objects:
		var m: RegExMatch = re_tu.search(objects[num]["dict"])
		if m != null:
			tounicode_of_font[num] = int(m.get_string(1))

	# b) nazwa zasobu -> numer obiektu czcionki (z dictów /Font <<...>> i pośrednich)
	var name_to_font := {}
	var re_font_dict := RegEx.new()
	re_font_dict.compile("(?s)/Font\\s*<<(.*?)>>")
	var re_font_ref := RegEx.new()
	re_font_ref.compile("/Font\\s+(\\d+)\\s+\\d+\\s+R")
	var re_pair := RegEx.new()
	re_pair.compile("/(\\w+)\\s+(\\d+)\\s+\\d+\\s+R")
	for num in objects:
		var dict: String = objects[num]["dict"]
		for fm in re_font_dict.search_all(dict):
			for pm in re_pair.search_all(fm.get_string(1)):
				name_to_font[pm.get_string(1)] = int(pm.get_string(2))
		var rm: RegExMatch = re_font_ref.search(dict)
		if rm != null:
			var font_dict_num := int(rm.get_string(1))
			if objects.has(font_dict_num):
				for pm in re_pair.search_all(objects[font_dict_num]["dict"]):
					name_to_font[pm.get_string(1)] = int(pm.get_string(2))

	# c) nazwa zasobu -> sparsowana mapa {code -> String, "_len": bajty kodu}
	var result := {}
	for res_name in name_to_font:
		var font_num: int = name_to_font[res_name]
		if not tounicode_of_font.has(font_num):
			continue
		var tu_num: int = tounicode_of_font[font_num]
		if not objects.has(tu_num):
			continue
		var cmap := _parse_cmap(objects[tu_num]["stream"])
		if not cmap.is_empty():
			result[res_name] = cmap
	return result


static func _parse_cmap(cmap_text: String) -> Dictionary:
	if cmap_text.is_empty():
		return {}
	var map := {}
	var code_len := 0
	var re := RegEx.new()

	# Długość kodu z codespacerange (np. <00> <FF> albo <0000> <FFFF>).
	re.compile("begincodespacerange\\s*<([0-9A-Fa-f]+)>")
	var m := re.search(cmap_text)
	if m != null:
		code_len = m.get_string(1).length() / 2

	# beginbfchar: <kod> <unicode>
	re.compile("(?s)beginbfchar(.*?)endbfchar")
	var re_pair := RegEx.new()
	re_pair.compile("<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>")
	for block in re.search_all(cmap_text):
		for pm in re_pair.search_all(block.get_string(1)):
			var code := ("0x" + pm.get_string(1)).hex_to_int()
			map[code] = _utf16be_hex_to_string(pm.get_string(2))
			if code_len == 0:
				code_len = pm.get_string(1).length() / 2

	# beginbfrange: <od> <do> <start>  albo  <od> <do> [<u1> <u2> ...]
	re.compile("(?s)beginbfrange(.*?)endbfrange")
	var re_range := RegEx.new()
	re_range.compile("<([0-9A-Fa-f]+)>\\s*<([0-9A-Fa-f]+)>\\s*(<([0-9A-Fa-f]+)>|\\[(.*?)\\])")
	var re_hex := RegEx.new()
	re_hex.compile("<([0-9A-Fa-f]+)>")
	for block in re.search_all(cmap_text):
		for rm in re_range.search_all(block.get_string(1)):
			var lo := ("0x" + rm.get_string(1)).hex_to_int()
			var hi := ("0x" + rm.get_string(2)).hex_to_int()
			if code_len == 0:
				code_len = rm.get_string(1).length() / 2
			if hi - lo > 65535:
				continue
			if rm.get_string(4) != "":
				var base := _utf16be_hex_to_string(rm.get_string(4))
				if base.length() >= 1:
					var base_code := base.unicode_at(base.length() - 1)
					var prefix := base.substr(0, base.length() - 1)
					for c in range(lo, hi + 1):
						map[c] = prefix + char(base_code + (c - lo))
			else:
				var items := re_hex.search_all(rm.get_string(5))
				for i in items.size():
					if lo + i <= hi:
						map[lo + i] = _utf16be_hex_to_string(items[i].get_string(1))
	if map.is_empty():
		return {}
	map["_len"] = maxi(1, code_len)
	return map


static func _utf16be_hex_to_string(hex: String) -> String:
	var out := ""
	var i := 0
	while i + 4 <= hex.length():
		var unit := ("0x" + hex.substr(i, 4)).hex_to_int()
		i += 4
		if unit >= 0xD800 and unit <= 0xDBFF and i + 4 <= hex.length():
			var low := ("0x" + hex.substr(i, 4)).hex_to_int()
			i += 4
			out += char(0x10000 + ((unit - 0xD800) << 10) + (low - 0xDC00))
		else:
			out += char(unit)
	if out == "" and hex.length() >= 2:
		out = char(("0x" + hex).hex_to_int())
	return out


# ------------------------------------------------------------------
# Strumień treści -> tekst
# ------------------------------------------------------------------
static func _extract_from_content(content: String, font_cmaps: Dictionary) -> String:
	var out := ""
	var i := 0
	var n := content.length()
	var current_cmap := {}
	var pending := ""       # tekst zebrany z łańcuchów przed operatorem
	var last_name := ""     # ostatni token /Nazwa (do Tf)

	while i < n:
		var ch := content[i]
		if ch == "(":
			var parsed := _read_literal_string(content, i)
			pending += _decode_pdf_string(parsed[0], current_cmap)
			i = parsed[1]
		elif ch == "<" and i + 1 < n and content[i + 1] != "<":
			var end := content.find(">", i + 1)
			if end == -1:
				break
			pending += _decode_hex_string(content.substr(i + 1, end - i - 1), current_cmap)
			i = end + 1
		elif ch == "/":
			var j := i + 1
			while j < n and _is_name_char(content[j]):
				j += 1
			last_name = content.substr(i + 1, j - i - 1)
			i = j
		elif _is_alpha(ch) or ch == "'" or ch == "\"":
			var j2 := i
			while j2 < n and (_is_alpha(content[j2]) or content[j2] == "*" or content[j2] == "'" or content[j2] == "\""):
				j2 += 1
			var op := content.substr(i, j2 - i)
			i = j2
			match op:
				"Tj", "TJ":
					out += pending + " "
					pending = ""
				"'", "\"":
					out += "\n" + pending
					pending = ""
				"Tf":
					current_cmap = font_cmaps.get(last_name, {})
				"Td", "TD", "T", "ET", "BT":
					if pending != "":
						out += pending + " "
						pending = ""
					if op == "Td" or op == "TD" or op == "T" or op == "ET":
						out += "\n"
				_:
					pass
		else:
			i += 1
		if out.length() > MAX_TEXT_SIZE:
			break
	if pending != "":
		out += pending
	return out


## Czyta łańcuch nawiasowy od pozycji '('; zwraca [surowe_bajty_jako_String, nowa_pozycja].
static func _read_literal_string(s: String, start: int) -> Array:
	var out := ""
	var depth := 0
	var i := start
	var n := s.length()
	while i < n:
		var ch := s[i]
		if ch == "\\" and i + 1 < n:
			var nxt := s[i + 1]
			match nxt:
				"n": out += "\n"; i += 2
				"r": out += "\r"; i += 2
				"t": out += "\t"; i += 2
				"b", "f": i += 2
				"(", ")", "\\": out += nxt; i += 2
				"\n": i += 2
				_:
					# Sekwencja ósemkowa \d{1,3}
					if nxt >= "0" and nxt <= "7":
						var oct := ""
						var k := i + 1
						while k < n and k < i + 4 and s[k] >= "0" and s[k] <= "7":
							oct += s[k]
							k += 1
						var val := 0
						for c in oct:
							val = val * 8 + int(c)
						out += char(val) if val > 0 else char(NUL_SENTINEL)
						i = k
					else:
						out += nxt
						i += 2
		elif ch == "(":
			depth += 1
			if depth > 1:
				out += ch
			i += 1
		elif ch == ")":
			depth -= 1
			if depth == 0:
				return [out, i + 1]
			out += ch
			i += 1
		else:
			out += ch
			i += 1
	return [out, n]


## Dekoduje bajty łańcucha wg CMap czcionki (albo 1:1 gdy mapy brak).
static func _decode_pdf_string(raw: String, cmap: Dictionary) -> String:
	if cmap.is_empty():
		var out_plain := ""
		for i in raw.length():
			var code := raw.unicode_at(i)
			if code != NUL_SENTINEL:
				out_plain += char(code)
		return out_plain
	var code_len: int = cmap.get("_len", 1)
	var out := ""
	if code_len == 2:
		var i := 0
		while i + 1 < raw.length():
			var code := (_byte_of(raw, i) << 8) | _byte_of(raw, i + 1)
			out += cmap.get(code, "")
			i += 2
	else:
		for i in raw.length():
			var code := _byte_of(raw, i)
			out += cmap.get(code, char(code) if code > 0 else "")
	return out


## Wartość bajtu z łańcucha strumienia (odwzorowuje sentinel z powrotem na 0).
static func _byte_of(s: String, i: int) -> int:
	var code := s.unicode_at(i)
	return 0 if code == NUL_SENTINEL else code


static func _decode_hex_string(hex: String, cmap: Dictionary) -> String:
	var clean := ""
	for c in hex:
		if (c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F"):
			clean += c
	if clean.length() % 2 == 1:
		clean += "0"
	var raw := ""
	var i := 0
	while i + 2 <= clean.length():
		raw += char(("0x" + clean.substr(i, 2)).hex_to_int())
		i += 2
	return _decode_pdf_string(raw, cmap)


# ------------------------------------------------------------------
# Pomocnicze
# ------------------------------------------------------------------
static func _tidy(text: String) -> String:
	var re := RegEx.new()
	re.compile("[ \\t]+")
	text = re.sub(text, " ", true)
	var lines: Array[String] = []
	for line in text.split("\n"):
		var s := line.strip_edges()
		# Odfiltruj linie-śmieci (np. z nierozkodowanych strumieni).
		if s.is_empty():
			if not lines.is_empty() and lines[lines.size() - 1] != "":
				lines.append("")
			continue
		var printable := 0
		for ch in s:
			var code := ch.unicode_at(0)
			if code >= 32 and code != 127:
				printable += 1
		if printable < s.length() / 2:
			continue
		lines.append(s)
	return "\n".join(lines)


static func _is_alpha(ch: String) -> bool:
	return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z")


static func _is_name_char(ch: String) -> bool:
	return _is_alpha(ch) or (ch >= "0" and ch <= "9") or ch == "_" or ch == "-" or ch == "." or ch == "+"

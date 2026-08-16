class_name ModuleAnalyzer
extends RefCounted
## Dzieli wczytaną dokumentację na moduły funkcjonalne, tak aby przypadki
## testowe można było generować tylko dla wybranych części aplikacji.

## Opis jednego wykrytego modułu.
class ModuleInfo:
	var name := ""
	var source := "dokumentacja"   # "dokumentacja" / "aplikacja"
	var content := ""              # pełna treść sekcji modułu
	var sentences: Array[String] = []  # zdania wyglądające na wymagania

	func requirement_count() -> int:
		return sentences.size()

# Słowa kluczowe wskazujące, że zdanie jest wymaganiem (PL + EN).
const REQ_KEYWORDS := [
	"musi", "muszą", "powinien", "powinna", "powinno", "powinny", "należy",
	"wymaga", "wymagane", "umożliwia", "umożliwiać", "pozwala", "pozwalać",
	"zapewnia", "zapewniać", "obsługuje", "obsługiwać", "może", "mogą",
	"użytkownik", "system", "aplikacja", "funkcja", "dostęp",
	"shall", "should", "must", "required", "allows", "enables", "supports",
	"can ", "user ", "system ", "application ",
]


## Analizuje dokumentację i (opcjonalnie) strukturę aplikacji.
## app_text to pseudo-dokument z DocLoader.load_directory() lub treść strony aplikacji.
static func analyze(doc_text: String, app_text: String = "") -> Array[ModuleInfo]:
	var modules: Array[ModuleInfo] = []
	if not doc_text.strip_edges().is_empty():
		modules.append_array(_split_into_modules(doc_text, "dokumentacja"))
	if not app_text.strip_edges().is_empty():
		var app_modules := _split_into_modules(app_text, "aplikacja")
		for am in app_modules:
			var merged := false
			for m in modules:
				if _similar_names(m.name, am.name):
					m.content += "\n\n[Struktura aplikacji]\n" + am.content
					merged = true
					break
			if not merged:
				modules.append(am)
	for m in modules:
		m.sentences = _extract_requirements(m.content)
	return modules


static func _split_into_modules(text: String, source: String) -> Array[ModuleInfo]:
	var lines := text.split("\n")

	# 1. Nagłówki Markdown: wybierz najpłytszy poziom, który występuje co najmniej 2 razy.
	var heading_level := 0
	for level in [1, 2, 3]:
		var prefix := "#".repeat(level) + " "
		var count := 0
		for line in lines:
			if line.strip_edges().begins_with(prefix):
				count += 1
		if count >= 2:
			heading_level = level
			break
	if heading_level > 0:
		return _split_by_predicate(lines, source, func(line: String) -> String:
			var s: String = line.strip_edges()
			var prefix: String = "#".repeat(heading_level) + " "
			if s.begins_with(prefix):
				return s.substr(prefix.length()).strip_edges(). trim_prefix("#").strip_edges()
			return "")

	# 2. Linie typu "Moduł X: Nazwa" / "Module: Name".
	var re_module := RegEx.new()
	re_module.compile("(?i)^\\s*modu[łl][ a-z0-9]*[:.\\-]\\s*(.+)$|^\\s*module[ a-z0-9]*[:.\\-]\\s*(.+)$")
	var module_lines := 0
	for line in lines:
		if re_module.search(line) != null:
			module_lines += 1
	if module_lines >= 2:
		return _split_by_predicate(lines, source, func(line: String) -> String:
			var m: RegExMatch = re_module.search(line)
			if m != null:
				var name: String = m.get_string(1)
				if name.is_empty():
					name = m.get_string(2)
				return name.strip_edges()
			return "")

	# 3. Sekcje numerowane: "1. Nazwa" na początku linii (krótkie linie-tytuły).
	var re_num := RegEx.new()
	re_num.compile("^\\s*\\d+[\\.\\)]\\s+(.{2,60})$")
	var numbered := 0
	for line in lines:
		var m := re_num.search(line)
		if m != null and not line.strip_edges().ends_with("."):
			numbered += 1
	if numbered >= 2:
		return _split_by_predicate(lines, source, func(line: String) -> String:
			var m: RegExMatch = re_num.search(line)
			if m != null and not line.strip_edges().ends_with("."):
				return m.get_string(1).strip_edges()
			return "")

	# 4. Linie pisane WIELKIMI LITERAMI jako tytuły sekcji.
	var re_caps := RegEx.new()
	re_caps.compile("^\\s*[A-ZĄĆĘŁŃÓŚŹŻ][A-ZĄĆĘŁŃÓŚŹŻ0-9 \\-_/]{2,50}\\s*$")
	var caps := 0
	for line in lines:
		if re_caps.search(line) != null:
			caps += 1
	if caps >= 2:
		return _split_by_predicate(lines, source, func(line: String) -> String:
			if re_caps.search(line) != null:
				return line.strip_edges().capitalize()
			return "")

	# 5. Bez struktury — jeden moduł z całością.
	var single := ModuleInfo.new()
	single.name = "Całość dokumentacji" if source == "dokumentacja" else "Aplikacja"
	single.source = source
	single.content = text
	var result: Array[ModuleInfo] = [single]
	return result


## Dzieli linie na moduły. title_of zwraca tytuł, jeśli linia zaczyna moduł, inaczej "".
static func _split_by_predicate(lines: PackedStringArray, source: String, title_of: Callable) -> Array[ModuleInfo]:
	var modules: Array[ModuleInfo] = []
	var current: ModuleInfo = null
	var preamble: Array[String] = []
	for line in lines:
		var title: String = title_of.call(line)
		if title != "":
			current = ModuleInfo.new()
			current.name = title
			current.source = source
			modules.append(current)
		elif current != null:
			current.content += line + "\n"
		else:
			preamble.append(line)
	# Usuń moduły-widma bez treści i bez sensownej nazwy.
	var cleaned: Array[ModuleInfo] = []
	for m in modules:
		m.name = m.name.strip_edges()
		if m.name.length() >= 2:
			cleaned.append(m)
	if cleaned.is_empty():
		var single := ModuleInfo.new()
		single.name = "Całość dokumentacji" if source == "dokumentacja" else "Aplikacja"
		single.source = source
		single.content = "\n".join(lines)
		cleaned.append(single)
	return cleaned


static func _similar_names(a: String, b: String) -> bool:
	var na := a.to_lower().strip_edges()
	var nb := b.to_lower().strip_edges()
	if na == nb:
		return true
	if na.length() >= 4 and nb.length() >= 4:
		return na.contains(nb) or nb.contains(na)
	return false


## Wyciąga z treści zdania wyglądające na wymagania lub opis funkcji.
static func _extract_requirements(content: String) -> Array[String]:
	var sentences: Array[String] = []
	var chunks: Array[String] = []
	# Podział najpierw po liniach (punktory), potem po kropkach w akapitach.
	for line in content.split("\n"):
		var s := line.strip_edges().trim_prefix("-").trim_prefix("*").trim_prefix("•").strip_edges()
		if s.is_empty():
			continue
		for part in s.split(". "):
			var p := part.strip_edges()
			if not p.is_empty():
				chunks.append(p)
	for chunk in chunks:
		if chunk.length() < 12 or chunk.length() > 400:
			continue
		if chunk.begins_with("plik:"):
			continue
		var lower := chunk.to_lower()
		for kw in REQ_KEYWORDS:
			if lower.contains(kw):
				if not sentences.has(chunk):
					sentences.append(chunk)
				break
	return sentences

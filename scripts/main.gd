extends Control
## Główne okno aplikacji Generator TM — buduje interfejs, spina wczytywanie
## źródeł, analizę modułów, generowanie i eksport.

const APP_TITLE := "Generator TM"
const APP_SUBTITLE := "plany testów i przypadki testowe"
const VERSION := "1.0"

# --- Stan aplikacji ---
var doc_result: DocLoader.Result = null
var app_result: DocLoader.Result = null
var modules: Array = []            # Array[ModuleAnalyzer.ModuleInfo]
var output: TestGenerator.Output = null

# --- Węzły UI (tworzone w kodzie) ---
var tabs: TabContainer
var status_label: Label

var doc_path_edit: LineEdit
var doc_status: Label
var doc_preview: TextEdit
var app_path_edit: LineEdit
var app_status: Label
var analyze_button: Button

var modules_tree: Tree
var opt_project: LineEdit
var opt_author: LineEdit
var opt_prefix: LineEdit
var opt_positive: CheckBox
var opt_negative: CheckBox
var opt_boundary: CheckBox
var opt_security: CheckBox
var generate_button: Button

var plan_view: TextEdit
var cases_tree: Tree
var case_details: TextEdit
var export_scope: OptionButton
var export_format: OptionButton
var export_status: Label

var http: HTTPRequest
var error_dialog: AcceptDialog
var open_doc_dialog: FileDialog
var open_app_file_dialog: FileDialog
var open_app_dir_dialog: FileDialog
var save_dialog: FileDialog


func _ready() -> void:
	theme = UITheme.build()

	http = HTTPRequest.new()
	add_child(http)

	error_dialog = AcceptDialog.new()
	error_dialog.title = "Generator TM"
	add_child(error_dialog)

	_build_dialogs()
	_build_layout()
	_set_status("Gotowy. Wskaż dokumentację aplikacji (plik z dysku lub adres URL) i kliknij „Wczytaj”.")


# ============================================================
#  BUDOWA INTERFEJSU
# ============================================================
func _build_layout() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.COLOR_BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# --- Pasek nagłówka ---
	var header := PanelContainer.new()
	header.theme_type_variation = "HeaderBar"
	root.add_child(header)
	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	header.add_child(header_box)
	var logo := TextureRect.new()
	logo.texture = load(UITheme.ICON_LOGO)
	logo.custom_minimum_size = Vector2(34, 34)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_box.add_child(logo)
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = APP_TITLE
	header_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "— " + APP_SUBTITLE
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(subtitle)
	var version := Label.new()
	version.text = "v" + VERSION
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	header_box.add_child(version)

	# --- Zakładki ---
	var tabs_margin := MarginContainer.new()
	tabs_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		tabs_margin.add_theme_constant_override("margin_" + side, 14)
	root.add_child(tabs_margin)
	tabs = TabContainer.new()
	tabs_margin.add_child(tabs)

	tabs.add_child(_build_sources_tab())
	tabs.add_child(_build_modules_tab())
	tabs.add_child(_build_plan_tab())
	tabs.add_child(_build_cases_tab())
	tabs.add_child(_build_export_tab())
	# Tytuły ustawiane wprost — nazwy węzłów nie mogą zawierać kropki.
	var tab_titles := ["1. Źródła", "2. Moduły i opcje", "3. Plan testów", "4. Przypadki testowe", "5. Eksport"]
	var tab_icons := [UITheme.ICON_FOLDER, UITheme.ICON_FILTER, UITheme.ICON_DOC, UITheme.ICON_CLIPBOARD, UITheme.ICON_EXPORT]
	for i in tab_icons.size():
		tabs.set_tab_title(i, tab_titles[i])
		tabs.set_tab_icon(i, _tab_icon(tab_icons[i]))

	# --- Pasek stanu ---
	var status_bar := PanelContainer.new()
	status_bar.theme_type_variation = "StatusBar"
	root.add_child(status_bar)
	status_label = Label.new()
	status_label.theme_type_variation = "DimLabel"
	status_bar.add_child(status_label)


func _tab_icon(path: String) -> Texture2D:
	var img: Texture2D = load(path)
	var image := img.get_image()
	image.resize(20, 20, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _card(title_text: String, icon_path: String = "") -> Array:
	# Zwraca [PanelContainer, VBoxContainer-na-treść].
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	if icon_path != "":
		var ic := TextureRect.new()
		ic.texture = load(icon_path)
		ic.custom_minimum_size = Vector2(24, 24)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(ic)
	var lbl := Label.new()
	lbl.theme_type_variation = "CardTitle"
	lbl.text = title_text
	head.add_child(lbl)
	return [card, box]


func _button(text: String, icon_path: String = "", variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	if icon_path != "":
		b.icon = _tab_icon(icon_path)
	return b


# ---------------- Zakładka 1: Źródła ----------------
func _build_sources_tab() -> Control:
	var page := ScrollContainer.new()
	page.name = "Zrodla"
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 14)
	page.add_child(outer)

	# Karta: dokumentacja
	var doc_parts := _card("Dokumentacja aplikacji (wymagana)", UITheme.ICON_DOC)
	outer.add_child(doc_parts[0])
	var doc_box: VBoxContainer = doc_parts[1]
	var doc_hint := Label.new()
	doc_hint.theme_type_variation = "DimLabel"
	doc_hint.text = "Wskaż plik na dysku (.md, .txt, .html, .json, .csv) albo wklej adres URL strony z dokumentacją."
	doc_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_box.add_child(doc_hint)
	var doc_row := HBoxContainer.new()
	doc_row.add_theme_constant_override("separation", 8)
	doc_box.add_child(doc_row)
	doc_path_edit = LineEdit.new()
	doc_path_edit.placeholder_text = "np. C:\\projekty\\dokumentacja.md  albo  https://twoja-aplikacja.pl/docs"
	doc_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_row.add_child(doc_path_edit)
	var doc_browse := _button("Wybierz plik…", UITheme.ICON_FOLDER)
	doc_browse.pressed.connect(func() -> void: open_doc_dialog.popup_centered_ratio(0.7))
	doc_row.add_child(doc_browse)
	var doc_load := _button("Wczytaj", UITheme.ICON_DOC_DOWN, "PrimaryButton")
	doc_load.pressed.connect(_on_load_doc)
	doc_row.add_child(doc_load)
	doc_status = Label.new()
	doc_status.theme_type_variation = "DimLabel"
	doc_status.text = "Nie wczytano dokumentacji."
	doc_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_box.add_child(doc_status)
	doc_preview = TextEdit.new()
	doc_preview.editable = false
	doc_preview.custom_minimum_size = Vector2(0, 170)
	doc_preview.placeholder_text = "Podgląd wczytanej dokumentacji pojawi się tutaj."
	doc_preview.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	doc_box.add_child(doc_preview)

	# Karta: aplikacja testowana
	var app_parts := _card("Aplikacja do testowania (opcjonalnie)", UITheme.ICON_PACKAGE)
	outer.add_child(app_parts[0])
	var app_box: VBoxContainer = app_parts[1]
	var app_hint := Label.new()
	app_hint.theme_type_variation = "DimLabel"
	app_hint.text = "Wskaż folder projektu (struktura katalogów podpowie moduły), plik aplikacji albo adres URL działającej aplikacji. To źródło uzupełnia listę modułów wykrytych w dokumentacji."
	app_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app_box.add_child(app_hint)
	var app_row := HBoxContainer.new()
	app_row.add_theme_constant_override("separation", 8)
	app_box.add_child(app_row)
	app_path_edit = LineEdit.new()
	app_path_edit.placeholder_text = "np. C:\\projekty\\moja-aplikacja  albo  https://twoja-aplikacja.pl"
	app_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	app_row.add_child(app_path_edit)
	var app_browse_dir := _button("Folder…", UITheme.ICON_FOLDER)
	app_browse_dir.pressed.connect(func() -> void: open_app_dir_dialog.popup_centered_ratio(0.7))
	app_row.add_child(app_browse_dir)
	var app_browse_file := _button("Plik…", UITheme.ICON_DOC)
	app_browse_file.pressed.connect(func() -> void: open_app_file_dialog.popup_centered_ratio(0.7))
	app_row.add_child(app_browse_file)
	var app_load := _button("Wczytaj", UITheme.ICON_DOC_DOWN, "PrimaryButton")
	app_load.pressed.connect(_on_load_app)
	app_row.add_child(app_load)
	app_status = Label.new()
	app_status.theme_type_variation = "DimLabel"
	app_status.text = "Nie wskazano aplikacji (opcjonalne)."
	app_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	app_box.add_child(app_status)

	# Przycisk analizy
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	outer.add_child(actions)
	analyze_button = _button("Analizuj i wykryj moduły  →", UITheme.ICON_SEARCH, "PrimaryButton")
	analyze_button.disabled = true
	analyze_button.pressed.connect(_on_analyze)
	actions.add_child(analyze_button)
	return page


# ---------------- Zakładka 2: Moduły ----------------
func _build_modules_tab() -> Control:
	var page := HSplitContainer.new()
	page.name = "Moduly"
	page.split_offset = 640

	var left_parts := _card("Wykryte moduły — zaznacz, które przetestować", UITheme.ICON_FILTER)
	var left_card: PanelContainer = left_parts[0]
	left_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(left_card)
	var left: VBoxContainer = left_parts[1]
	var sel_row := HBoxContainer.new()
	sel_row.add_theme_constant_override("separation", 8)
	left.add_child(sel_row)
	var all_btn := _button("Zaznacz wszystkie")
	all_btn.pressed.connect(func() -> void: _set_all_modules(true))
	sel_row.add_child(all_btn)
	var none_btn := _button("Odznacz wszystkie")
	none_btn.pressed.connect(func() -> void: _set_all_modules(false))
	sel_row.add_child(none_btn)
	modules_tree = Tree.new()
	modules_tree.columns = 3
	modules_tree.column_titles_visible = true
	modules_tree.set_column_title(0, "Moduł")
	modules_tree.set_column_title(1, "Źródło")
	modules_tree.set_column_title(2, "Wymagania")
	modules_tree.set_column_expand(0, true)
	modules_tree.set_column_expand(1, false)
	modules_tree.set_column_expand(2, false)
	modules_tree.set_column_custom_minimum_width(1, 130)
	modules_tree.set_column_custom_minimum_width(2, 110)
	modules_tree.hide_root = true
	modules_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(modules_tree)

	var right_parts := _card("Opcje generowania", UITheme.ICON_GEAR)
	var right_card: PanelContainer = right_parts[0]
	page.add_child(right_card)
	var right: VBoxContainer = right_parts[1]

	right.add_child(_field_label("Nazwa projektu / aplikacji:"))
	opt_project = LineEdit.new()
	opt_project.text = "Aplikacja"
	right.add_child(opt_project)
	right.add_child(_field_label("Autor planu (opcjonalnie):"))
	opt_author = LineEdit.new()
	opt_author.placeholder_text = "np. Jan Kowalski"
	right.add_child(opt_author)
	right.add_child(_field_label("Prefiks identyfikatorów przypadków:"))
	opt_prefix = LineEdit.new()
	opt_prefix.text = "TC"
	opt_prefix.max_length = 8
	right.add_child(opt_prefix)

	right.add_child(_field_label("Rodzaje generowanych testów:"))
	opt_positive = CheckBox.new()
	opt_positive.text = "Pozytywne (ścieżki podstawowe)"
	opt_positive.button_pressed = true
	right.add_child(opt_positive)
	opt_negative = CheckBox.new()
	opt_negative.text = "Negatywne (obsługa błędów)"
	opt_negative.button_pressed = true
	right.add_child(opt_negative)
	opt_boundary = CheckBox.new()
	opt_boundary.text = "Brzegowe (wartości graniczne)"
	opt_boundary.button_pressed = true
	right.add_child(opt_boundary)
	opt_security = CheckBox.new()
	opt_security.text = "Bezpieczeństwa (zakres podstawowy)"
	opt_security.button_pressed = true
	right.add_child(opt_security)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(spacer)
	generate_button = _button("Generuj plan i przypadki  →", UITheme.ICON_CHECKLIST, "PrimaryButton")
	generate_button.disabled = true
	generate_button.pressed.connect(_on_generate)
	right.add_child(generate_button)
	return page


func _field_label(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "DimLabel"
	l.text = text
	return l


# ---------------- Zakładka 3: Plan ----------------
func _build_plan_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "PlanTestow"
	page.add_theme_constant_override("separation", 10)
	var info := Label.new()
	info.theme_type_variation = "DimLabel"
	info.text = "Plan testów w formacie Markdown — możesz go skopiować lub zapisać w zakładce „Eksport”."
	page.add_child(info)
	plan_view = TextEdit.new()
	plan_view.editable = false
	plan_view.placeholder_text = "Plan testów pojawi się po wygenerowaniu (zakładka „Moduły i opcje”)."
	plan_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	plan_view.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	page.add_child(plan_view)
	return page


# ---------------- Zakładka 4: Przypadki ----------------
func _build_cases_tab() -> Control:
	var page := HSplitContainer.new()
	page.name = "Przypadki"
	page.split_offset = 700
	cases_tree = Tree.new()
	cases_tree.columns = 4
	cases_tree.column_titles_visible = true
	cases_tree.set_column_title(0, "ID")
	cases_tree.set_column_title(1, "Tytuł")
	cases_tree.set_column_title(2, "Typ")
	cases_tree.set_column_title(3, "Priorytet")
	cases_tree.set_column_expand(0, false)
	cases_tree.set_column_expand(1, true)
	cases_tree.set_column_expand(2, false)
	cases_tree.set_column_expand(3, false)
	cases_tree.set_column_custom_minimum_width(0, 170)
	cases_tree.set_column_custom_minimum_width(2, 120)
	cases_tree.set_column_custom_minimum_width(3, 100)
	cases_tree.hide_root = true
	cases_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cases_tree.item_selected.connect(_on_case_selected)
	page.add_child(cases_tree)
	case_details = TextEdit.new()
	case_details.editable = false
	case_details.placeholder_text = "Zaznacz przypadek na liście, aby zobaczyć szczegóły."
	case_details.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	page.add_child(case_details)
	return page


# ---------------- Zakładka 5: Eksport ----------------
func _build_export_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "Eksport"
	page.add_theme_constant_override("separation", 14)
	var parts := _card("Zapis do pliku", UITheme.ICON_EXPORT)
	page.add_child(parts[0])
	var box: VBoxContainer = parts[1]

	box.add_child(_field_label("Co zapisać:"))
	export_scope = OptionButton.new()
	export_scope.add_item("Plan testów + przypadki testowe (komplet)")
	export_scope.add_item("Tylko plan testów")
	export_scope.add_item("Tylko przypadki testowe")
	box.add_child(export_scope)

	box.add_child(_field_label("Format pliku:"))
	export_format = OptionButton.new()
	export_format.add_item("Markdown (.md) — czytelny dokument tekstowy")
	export_format.add_item("CSV (.csv) — import do Excela / Jiry / TestRaila")
	export_format.add_item("HTML (.html) — gotowy do druku i podglądu w przeglądarce")
	box.add_child(export_format)

	var row := HBoxContainer.new()
	box.add_child(row)
	var save_btn := _button("Zapisz do pliku…", UITheme.ICON_EXPORT, "PrimaryButton")
	save_btn.pressed.connect(_on_export)
	row.add_child(save_btn)
	export_status = Label.new()
	export_status.theme_type_variation = "DimLabel"
	export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(export_status)
	return page


func _build_dialogs() -> void:
	open_doc_dialog = FileDialog.new()
	open_doc_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_doc_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_doc_dialog.title = "Wybierz plik dokumentacji"
	open_doc_dialog.filters = PackedStringArray([
		"*.md, *.markdown ; Pliki Markdown",
		"*.txt ; Pliki tekstowe",
		"*.html, *.htm ; Strony HTML",
		"*.json ; Pliki JSON",
		"*.csv ; Pliki CSV",
		"* ; Wszystkie pliki",
	])
	open_doc_dialog.file_selected.connect(func(path: String) -> void:
		doc_path_edit.text = path
		_on_load_doc())
	add_child(open_doc_dialog)

	open_app_file_dialog = FileDialog.new()
	open_app_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	open_app_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_app_file_dialog.title = "Wybierz plik aplikacji"
	open_app_file_dialog.file_selected.connect(func(path: String) -> void:
		app_path_edit.text = path
		_on_load_app())
	add_child(open_app_file_dialog)

	open_app_dir_dialog = FileDialog.new()
	open_app_dir_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	open_app_dir_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_app_dir_dialog.title = "Wybierz folder aplikacji"
	open_app_dir_dialog.dir_selected.connect(func(path: String) -> void:
		app_path_edit.text = path
		_on_load_app())
	add_child(open_app_dir_dialog)

	save_dialog = FileDialog.new()
	save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_dialog.title = "Zapisz wynik"
	save_dialog.file_selected.connect(_on_save_path_chosen)
	add_child(save_dialog)


# ============================================================
#  LOGIKA
# ============================================================
func _set_status(text: String) -> void:
	status_label.text = text


func _show_error(message: String) -> void:
	error_dialog.dialog_text = message
	error_dialog.popup_centered()


func _on_load_doc() -> void:
	var source := doc_path_edit.text.strip_edges()
	if source.is_empty():
		_show_error("Podaj ścieżkę pliku dokumentacji albo adres URL.")
		return
	_set_status("Wczytywanie dokumentacji…")
	var res: DocLoader.Result
	if DocLoader.is_url(source):
		doc_status.text = "Pobieranie z adresu: %s…" % source
		res = await DocLoader.load_url(http, source)
	else:
		res = DocLoader.load_file(source)
	if not res.ok:
		doc_status.text = "Błąd: " + res.error
		_show_error(res.error)
		_set_status("Nie udało się wczytać dokumentacji.")
		return
	doc_result = res
	var chars := res.text.length()
	doc_status.text = "Wczytano dokumentację (%s, %d znaków): %s" % [res.kind, chars, res.source_label]
	doc_preview.text = res.text.substr(0, 4000) + ("\n\n[…skrócono podgląd…]" if chars > 4000 else "")
	analyze_button.disabled = false
	_set_status("Dokumentacja wczytana. Możesz też wskazać aplikację, a następnie kliknij „Analizuj i wykryj moduły”.")


func _on_load_app() -> void:
	var source := app_path_edit.text.strip_edges()
	if source.is_empty():
		_show_error("Podaj folder, plik aplikacji albo adres URL.")
		return
	_set_status("Wczytywanie informacji o aplikacji…")
	var res: DocLoader.Result
	if DocLoader.is_url(source):
		app_status.text = "Pobieranie z adresu: %s…" % source
		res = await DocLoader.load_url(http, source)
	elif DirAccess.dir_exists_absolute(source):
		res = DocLoader.load_directory(source)
	elif FileAccess.file_exists(source):
		var ext := source.get_extension().to_lower()
		if ext in ["exe", "dll", "so", "bin", "apk", "jar"]:
			# Plik wykonywalny — zapisujemy tylko informację o aplikacji.
			res = DocLoader.Result.new()
			res.ok = true
			res.kind = "plik"
			res.source_label = source
			res.text = ""
		else:
			res = DocLoader.load_file(source)
	else:
		res = DocLoader.Result.new()
		res.error = "Nie znaleziono pliku ani folderu: %s" % source
	if not res.ok:
		app_status.text = "Błąd: " + res.error
		_show_error(res.error)
		_set_status("Nie udało się wczytać informacji o aplikacji.")
		return
	app_result = res
	if res.text.is_empty():
		app_status.text = "Zapamiętano aplikację: %s (plik binarny — moduły zostaną wykryte z dokumentacji)." % res.source_label
	else:
		app_status.text = "Wczytano informacje o aplikacji (%s): %s" % [res.kind, res.source_label]
	if doc_result == null:
		analyze_button.disabled = false
	_set_status("Aplikacja wskazana. Kliknij „Analizuj i wykryj moduły”.")


func _on_analyze() -> void:
	var doc_text := doc_result.text if doc_result != null else ""
	var app_text := app_result.text if app_result != null else ""
	if doc_text.strip_edges().is_empty() and app_text.strip_edges().is_empty():
		_show_error("Wczytaj najpierw dokumentację (lub folder aplikacji).")
		return
	modules = ModuleAnalyzer.analyze(doc_text, app_text)
	_fill_modules_tree()
	generate_button.disabled = modules.is_empty()
	tabs.current_tab = 1
	_set_status("Wykryto moduły: %d. Zaznacz te, które chcesz przetestować, i kliknij „Generuj plan i przypadki”." % modules.size())


func _fill_modules_tree() -> void:
	modules_tree.clear()
	var root := modules_tree.create_item()
	for m in modules:
		var item := modules_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, true)
		item.set_text(0, m.name)
		item.set_text(1, m.source)
		item.set_text(2, str(m.requirement_count()))
		item.set_metadata(0, modules.find(m))


func _set_all_modules(checked: bool) -> void:
	var root := modules_tree.get_root()
	if root == null:
		return
	var item := root.get_first_child()
	while item != null:
		item.set_checked(0, checked)
		item = item.get_next()


func _selected_modules() -> Array:
	var selected: Array = []
	var root := modules_tree.get_root()
	if root == null:
		return selected
	var item := root.get_first_child()
	while item != null:
		if item.is_checked(0):
			selected.append(modules[item.get_metadata(0)])
		item = item.get_next()
	return selected


func _on_generate() -> void:
	var selected := _selected_modules()
	if selected.is_empty():
		_show_error("Zaznacz co najmniej jeden moduł do przetestowania.")
		return
	var options := TestGenerator.Options.new()
	options.project_name = opt_project.text.strip_edges()
	if options.project_name.is_empty():
		options.project_name = "Aplikacja"
	options.author = opt_author.text.strip_edges()
	options.id_prefix = opt_prefix.text.strip_edges().to_upper()
	if options.id_prefix.is_empty():
		options.id_prefix = "TC"
	options.include_positive = opt_positive.button_pressed
	options.include_negative = opt_negative.button_pressed
	options.include_boundary = opt_boundary.button_pressed
	options.include_security = opt_security.button_pressed
	options.doc_source = doc_result.source_label if doc_result != null else ""
	options.app_source = app_result.source_label if app_result != null else ""
	if not (options.include_positive or options.include_negative or options.include_boundary or options.include_security):
		_show_error("Zaznacz co najmniej jeden rodzaj testów.")
		return
	output = TestGenerator.generate(selected, options)
	plan_view.text = output.plan_markdown
	_fill_cases_tree()
	tabs.current_tab = 2
	_set_status("Wygenerowano plan testów i %d przypadków dla %d modułów. Wyniki znajdziesz w zakładkach 3 i 4, zapis — w zakładce 5." % [output.cases.size(), selected.size()])


func _fill_cases_tree() -> void:
	cases_tree.clear()
	case_details.text = ""
	var root := cases_tree.create_item()
	var module_items := {}
	for i in output.cases.size():
		var c: TestGenerator.TestCase = output.cases[i]
		if not module_items.has(c.module):
			var mi := cases_tree.create_item(root)
			mi.set_text(0, "")
			mi.set_text(1, "Moduł: " + c.module)
			mi.set_selectable(0, false)
			mi.set_selectable(1, false)
			mi.set_selectable(2, false)
			mi.set_selectable(3, false)
			mi.set_custom_color(1, UITheme.COLOR_ACCENT)
			module_items[c.module] = mi
		var item := cases_tree.create_item(module_items[c.module])
		item.set_text(0, c.id)
		item.set_text(1, c.title)
		item.set_text(2, c.type)
		item.set_text(3, c.priority)
		item.set_metadata(0, i)


func _on_case_selected() -> void:
	var item := cases_tree.get_selected()
	if item == null or item.get_metadata(0) == null:
		return
	var c: TestGenerator.TestCase = output.cases[item.get_metadata(0)]
	var lines: Array[String] = []
	lines.append("%s — %s" % [c.id, c.title])
	lines.append("")
	lines.append("Moduł:            %s" % c.module)
	lines.append("Typ:              %s" % c.type)
	lines.append("Priorytet:        %s" % c.priority)
	lines.append("Warunki wstępne:  %s" % c.preconditions)
	lines.append("Dane testowe:     %s" % c.test_data)
	lines.append("")
	lines.append("Kroki:")
	for i in c.steps.size():
		lines.append("  %d. %s" % [i + 1, c.steps[i]])
	lines.append("")
	lines.append("Oczekiwany rezultat:")
	lines.append("  " + c.expected)
	case_details.text = "\n".join(lines)


func _on_export() -> void:
	if output == null:
		_show_error("Najpierw wygeneruj plan i przypadki testowe (zakładka „Moduły i opcje”).")
		return
	var ext: String = ["md", "csv", "html"][export_format.selected]
	var scope_name: String = ["plan_i_przypadki", "plan_testow", "przypadki_testowe"][export_scope.selected]
	save_dialog.filters = PackedStringArray(["*.%s ; Pliki %s" % [ext, ext.to_upper()]])
	save_dialog.current_file = "%s_%s.%s" % [scope_name, Time.get_date_string_from_system(), ext]
	save_dialog.popup_centered_ratio(0.7)


func _on_save_path_chosen(path: String) -> void:
	var ext: String = ["md", "csv", "html"][export_format.selected]
	if path.get_extension().to_lower() != ext:
		path += "." + ext
	var scope := export_scope.selected
	var project := opt_project.text.strip_edges()
	if project.is_empty():
		project = "Aplikacja"
	var content := ""
	match ext:
		"md":
			var parts: Array[String] = []
			if scope == 0 or scope == 1:
				parts.append(output.plan_markdown)
			if scope == 0 or scope == 2:
				parts.append(Exporter.cases_markdown(output.cases, project))
			content = "\n\n---\n\n".join(parts)
		"csv":
			# CSV ma sens tylko dla przypadków; plan w CSV nie występuje.
			content = Exporter.cases_csv(output.cases)
		"html":
			var plan_md := output.plan_markdown if (scope == 0 or scope == 1) else ""
			var case_list := output.cases if (scope == 0 or scope == 2) else ([] as Array[TestGenerator.TestCase])
			content = Exporter.full_html(plan_md, case_list, project)
	var err := Exporter.save_text(path, content)
	if err != "":
		export_status.text = "Błąd: " + err
		_show_error(err)
		return
	export_status.text = "Zapisano: %s" % path
	_set_status("Zapisano plik: %s" % path)

extends Control
## Główne okno aplikacji Generator TM — buduje interfejs, spina wczytywanie
## źródeł, analizę modułów, generowanie i eksport.

const APP_TITLE := "Generator TM"
const APP_SUBTITLE := "plany testów i przypadki testowe"
const VERSION := "1.6"
const SETTINGS_PATH := "user://ustawienia.cfg"

# --- Stan aplikacji ---
var doc_result: DocLoader.Result = null
var app_result: DocLoader.Result = null
var modules: Array = []            # Array[ModuleAnalyzer.ModuleInfo]
var output: TestGenerator.Output = null
var bugs: Array = []               # Array[BugReporter.BugReport]
var pending_attachments: Array = []  # Array[BugReporter.Attachment] (formularz)
var bug_counter := 0
var current_theme_id := UITheme.DEFAULT_THEME_ID
# Rejestr widżetów z ikonami — do podmiany ikon przy zmianie motywu.
var icon_widgets: Array = []       # [{node, name}]
var tab_icon_names: Array[String] = []

# --- Węzły UI (tworzone w kodzie) ---
var tabs: TabContainer
var status_label: Label
var bg_rect: ColorRect
var theme_select: OptionButton

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

var manual_module_edit: LineEdit

var plan_view: TextEdit
var cases_tree: Tree
var case_details: TextEdit
var export_scope: OptionButton
var export_format: OptionButton
var export_status: Label

var bug_title_edit: LineEdit
var bug_module_option: OptionButton
var bug_case_option: OptionButton
var bug_severity_option: OptionButton
var bug_env_edit: LineEdit
var bug_reporter_edit: LineEdit
var bug_steps_edit: TextEdit
var bug_actual_edit: TextEdit
var bug_expected_edit: TextEdit
var bug_attach_box: HFlowContainer
var bugs_tree: Tree
var bug_details: TextEdit
var bug_export_format: OptionButton
var bug_export_status: Label

var web_url_edit: LineEdit
var web_run_button: Button
var web_progress: ProgressBar
var web_tree: Tree
var web_bugs_button: Button
var web_export_format: OptionButton
var web_export_status: Label
var web_checks: Array = []

var http: HTTPRequest
var web_http: HTTPRequest
var error_dialog: AcceptDialog
var open_doc_dialog: FileDialog
var open_app_file_dialog: FileDialog
var open_app_dir_dialog: FileDialog
var save_dialog: FileDialog
var bug_attach_dialog: FileDialog
var bug_save_dialog: FileDialog
var web_save_dialog: FileDialog


func _ready() -> void:
	current_theme_id = _load_theme_setting()
	theme = UITheme.build(current_theme_id)

	http = HTTPRequest.new()
	add_child(http)
	web_http = HTTPRequest.new()
	add_child(web_http)

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
	bg_rect = ColorRect.new()
	bg_rect.color = UITheme.color(current_theme_id, "bg")
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_rect)

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
	logo.texture = load(UITheme.icon_path(current_theme_id, "logo", 32))
	logo.custom_minimum_size = Vector2(34, 34)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_box.add_child(logo)
	icon_widgets.append({"node": logo, "name": "logo", "size": 32})
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = APP_TITLE
	header_box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "— " + APP_SUBTITLE
	subtitle.theme_type_variation = "HeaderDim"
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_box.add_child(subtitle)
	var theme_lbl := Label.new()
	theme_lbl.text = "Motyw:"
	theme_lbl.theme_type_variation = "HeaderDim"
	header_box.add_child(theme_lbl)
	theme_select = OptionButton.new()
	for t in UITheme.themes():
		theme_select.add_item(t["name"])
		theme_select.set_item_metadata(theme_select.item_count - 1, t["id"])
		if t["id"] == current_theme_id:
			theme_select.selected = theme_select.item_count - 1
	theme_select.item_selected.connect(_on_theme_selected)
	header_box.add_child(theme_select)
	var version := Label.new()
	version.text = "v" + VERSION
	version.theme_type_variation = "HeaderDim"
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
	tabs.add_child(_build_bugs_tab())
	tabs.add_child(_build_web_tab())
	# Tytuły ustawiane wprost — nazwy węzłów nie mogą zawierać kropki.
	var tab_titles := ["1. Źródła", "2. Moduły i opcje", "3. Plan testów", "4. Przypadki testowe", "5. Eksport", "6. Raport błędów", "7. Testy WWW"]
	tab_icon_names = ["folder", "modules", "plan", "cases", "export", "bugs", "globe"]
	for i in tab_icon_names.size():
		tabs.set_tab_title(i, tab_titles[i])
		tabs.set_tab_icon(i, _icon_tex(tab_icon_names[i]))
	tabs.tab_changed.connect(_on_tab_changed)

	# --- Pasek stanu ---
	var status_bar := PanelContainer.new()
	status_bar.theme_type_variation = "StatusBar"
	root.add_child(status_bar)
	status_label = Label.new()
	status_label.theme_type_variation = "DimLabel"
	status_bar.add_child(status_label)


## Mała ikona dla przycisków i zakładek — z wariantu aktywnego motywu.
## Motywy klasyczne używają pikselowych ikon 16 px bez skalowania (ostre piksele).
func _icon_tex(icon_name: String) -> Texture2D:
	if UITheme.is_classic(current_theme_id):
		return load(UITheme.icon_path(current_theme_id, icon_name, 16))
	var img: Texture2D = load(UITheme.icon_path(current_theme_id, icon_name))
	var image := img.get_image()
	image.resize(20, 20, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(image)


func _card(title_text: String, icon_name: String = "") -> Array:
	# Zwraca [PanelContainer, VBoxContainer-na-treść].
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	card.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	if icon_name != "":
		var ic := TextureRect.new()
		ic.texture = load(UITheme.icon_path(current_theme_id, icon_name, 24))
		ic.custom_minimum_size = Vector2(24, 24)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		head.add_child(ic)
		icon_widgets.append({"node": ic, "name": icon_name, "size": 24})
	var lbl := Label.new()
	lbl.theme_type_variation = "CardTitle"
	lbl.text = title_text
	head.add_child(lbl)
	return [card, box]


func _button(text: String, icon_name: String = "", variation: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	if icon_name != "":
		b.icon = _icon_tex(icon_name)
		icon_widgets.append({"node": b, "name": icon_name})
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
	var doc_parts := _card("Dokumentacja aplikacji (zalecana)", "doc")
	outer.add_child(doc_parts[0])
	var doc_box: VBoxContainer = doc_parts[1]
	var doc_hint := Label.new()
	doc_hint.theme_type_variation = "DimLabel"
	doc_hint.text = "Wskaż plik na dysku (.md, .txt, .html, .json, .csv) albo wklej adres URL strony z dokumentacją.\nNie masz dokumentacji? Wystarczy samo źródło aplikacji poniżej — moduły wykryjemy ze struktury folderu lub strony, a brakujące dodasz ręcznie w zakładce 2."
	doc_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	doc_box.add_child(doc_hint)
	var doc_row := HBoxContainer.new()
	doc_row.add_theme_constant_override("separation", 8)
	doc_box.add_child(doc_row)
	doc_path_edit = LineEdit.new()
	doc_path_edit.placeholder_text = "np. C:\\projekty\\dokumentacja.md  albo  https://twoja-aplikacja.pl/docs"
	doc_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	doc_row.add_child(doc_path_edit)
	var doc_browse := _button("Wybierz plik…", "folder")
	doc_browse.pressed.connect(func() -> void: open_doc_dialog.popup_centered_ratio(0.7))
	doc_row.add_child(doc_browse)
	var doc_load := _button("Wczytaj", "doc_down", "PrimaryButton")
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
	var app_parts := _card("Aplikacja do testowania (opcjonalnie)", "package")
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
	var app_browse_dir := _button("Folder…", "folder")
	app_browse_dir.pressed.connect(func() -> void: open_app_dir_dialog.popup_centered_ratio(0.7))
	app_row.add_child(app_browse_dir)
	var app_browse_file := _button("Plik…", "doc")
	app_browse_file.pressed.connect(func() -> void: open_app_file_dialog.popup_centered_ratio(0.7))
	app_row.add_child(app_browse_file)
	var app_load := _button("Wczytaj", "doc_down", "PrimaryButton")
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
	analyze_button = _button("Analizuj i wykryj moduły  →", "analyze", "PrimaryButton")
	analyze_button.disabled = true
	analyze_button.pressed.connect(_on_analyze)
	actions.add_child(analyze_button)
	return page


# ---------------- Zakładka 2: Moduły ----------------
func _build_modules_tab() -> Control:
	var page := HSplitContainer.new()
	page.name = "Moduly"
	page.split_offset = 640

	var left_parts := _card("Wykryte moduły — zaznacz, które przetestować", "modules")
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
	# Ręczne dodawanie modułów — przydatne, gdy nie ma dokumentacji.
	var manual_row := HBoxContainer.new()
	manual_row.add_theme_constant_override("separation", 8)
	left.add_child(manual_row)
	manual_module_edit = LineEdit.new()
	manual_module_edit.placeholder_text = "Dodaj własny moduł, np. „Logowanie”, „Koszyk”, „Raporty”…"
	manual_module_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manual_module_edit.text_submitted.connect(func(_t: String) -> void: _on_add_manual_module())
	manual_row.add_child(manual_module_edit)
	var manual_btn := _button("Dodaj moduł", "pencil")
	manual_btn.pressed.connect(_on_add_manual_module)
	manual_row.add_child(manual_btn)
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

	var right_parts := _card("Opcje generowania", "gear")
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
	generate_button = _button("Generuj plan i przypadki  →", "generate", "PrimaryButton")
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
	var parts := _card("Zapis do pliku", "export")
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
	var save_btn := _button("Zapisz do pliku…", "export", "PrimaryButton")
	save_btn.pressed.connect(_on_export)
	row.add_child(save_btn)
	export_status = Label.new()
	export_status.theme_type_variation = "DimLabel"
	export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(export_status)
	return page


# ---------------- Zakładka 6: Raport błędów ----------------
func _build_bugs_tab() -> Control:
	var page := HSplitContainer.new()
	page.name = "RaportBledow"
	page.split_offset = 620

	# --- Lewa strona: formularz zgłoszenia ---
	var form_scroll := ScrollContainer.new()
	form_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(form_scroll)
	var form_parts := _card("Nowe zgłoszenie błędu", "pencil")
	var form_card: PanelContainer = form_parts[0]
	form_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_scroll.add_child(form_card)
	var form: VBoxContainer = form_parts[1]

	form.add_child(_field_label("Tytuł błędu:"))
	bug_title_edit = LineEdit.new()
	bug_title_edit.placeholder_text = "np. Logowanie akceptuje puste hasło"
	form.add_child(bug_title_edit)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 12)
	form.add_child(row1)
	var col_mod := VBoxContainer.new()
	col_mod.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(col_mod)
	col_mod.add_child(_field_label("Moduł:"))
	bug_module_option = OptionButton.new()
	col_mod.add_child(bug_module_option)
	var col_sev := VBoxContainer.new()
	col_sev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(col_sev)
	col_sev.add_child(_field_label("Waga błędu:"))
	bug_severity_option = OptionButton.new()
	for s in BugReporter.severity_levels():
		bug_severity_option.add_item(s)
	bug_severity_option.selected = 2
	col_sev.add_child(bug_severity_option)

	form.add_child(_field_label("Powiązany przypadek testowy (opcjonalnie):"))
	bug_case_option = OptionButton.new()
	form.add_child(bug_case_option)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 12)
	form.add_child(row2)
	var col_env := VBoxContainer.new()
	col_env.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(col_env)
	col_env.add_child(_field_label("Środowisko:"))
	bug_env_edit = LineEdit.new()
	bug_env_edit.placeholder_text = "np. Windows 11, Chrome 126, wersja 1.2.3"
	col_env.add_child(bug_env_edit)
	var col_rep := VBoxContainer.new()
	col_rep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row2.add_child(col_rep)
	col_rep.add_child(_field_label("Zgłaszający:"))
	bug_reporter_edit = LineEdit.new()
	bug_reporter_edit.placeholder_text = "np. Jan Kowalski"
	col_rep.add_child(bug_reporter_edit)

	form.add_child(_field_label("Kroki reprodukcji (każdy krok w nowej linii):"))
	bug_steps_edit = TextEdit.new()
	bug_steps_edit.custom_minimum_size = Vector2(0, 90)
	bug_steps_edit.placeholder_text = "Otwórz ekran logowania\nPozostaw pole hasła puste\nKliknij „Zaloguj”"
	form.add_child(bug_steps_edit)

	form.add_child(_field_label("Rezultat aktualny (co się dzieje):"))
	bug_actual_edit = TextEdit.new()
	bug_actual_edit.custom_minimum_size = Vector2(0, 56)
	form.add_child(bug_actual_edit)

	form.add_child(_field_label("Rezultat oczekiwany (co powinno się dziać):"))
	bug_expected_edit = TextEdit.new()
	bug_expected_edit.custom_minimum_size = Vector2(0, 56)
	form.add_child(bug_expected_edit)

	form.add_child(_field_label("Zrzuty ekranu:"))
	var attach_row := HBoxContainer.new()
	attach_row.add_theme_constant_override("separation", 8)
	form.add_child(attach_row)
	var attach_file_btn := _button("Dodaj z pliku…", "folder")
	attach_file_btn.pressed.connect(func() -> void: bug_attach_dialog.popup_centered_ratio(0.7))
	attach_row.add_child(attach_file_btn)
	var attach_hint := Label.new()
	attach_hint.theme_type_variation = "DimLabel"
	attach_hint.text = "PNG, JPG, WEBP lub BMP — można wybrać kilka naraz."
	attach_row.add_child(attach_hint)
	bug_attach_box = HFlowContainer.new()
	bug_attach_box.add_theme_constant_override("h_separation", 8)
	bug_attach_box.add_theme_constant_override("v_separation", 8)
	form.add_child(bug_attach_box)

	var add_row := HBoxContainer.new()
	add_row.alignment = BoxContainer.ALIGNMENT_END
	form.add_child(add_row)
	var add_bug_btn := _button("Dodaj zgłoszenie do raportu  →", "bugs", "PrimaryButton")
	add_bug_btn.pressed.connect(_on_add_bug)
	add_row.add_child(add_bug_btn)

	# --- Prawa strona: lista zgłoszeń + eksport ---
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	page.add_child(right)
	var list_label := Label.new()
	list_label.theme_type_variation = "CardTitle"
	list_label.text = "Zgłoszenia w raporcie"
	right.add_child(list_label)
	bugs_tree = Tree.new()
	bugs_tree.columns = 4
	bugs_tree.column_titles_visible = true
	bugs_tree.set_column_title(0, "ID")
	bugs_tree.set_column_title(1, "Tytuł")
	bugs_tree.set_column_title(2, "Waga")
	bugs_tree.set_column_title(3, "Zrzuty")
	bugs_tree.set_column_expand(0, false)
	bugs_tree.set_column_expand(1, true)
	bugs_tree.set_column_expand(2, false)
	bugs_tree.set_column_expand(3, false)
	bugs_tree.set_column_custom_minimum_width(0, 100)
	bugs_tree.set_column_custom_minimum_width(2, 100)
	bugs_tree.set_column_custom_minimum_width(3, 70)
	bugs_tree.hide_root = true
	bugs_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bugs_tree.item_selected.connect(_on_bug_selected)
	right.add_child(bugs_tree)
	var del_row := HBoxContainer.new()
	del_row.add_theme_constant_override("separation", 8)
	right.add_child(del_row)
	var del_btn := _button("Usuń zaznaczone zgłoszenie", "delete", "DangerButton")
	del_btn.pressed.connect(_on_delete_bug)
	del_row.add_child(del_btn)
	bug_details = TextEdit.new()
	bug_details.editable = false
	bug_details.custom_minimum_size = Vector2(0, 150)
	bug_details.placeholder_text = "Zaznacz zgłoszenie, aby zobaczyć szczegóły."
	bug_details.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	right.add_child(bug_details)
	right.add_child(_field_label("Format raportu:"))
	bug_export_format = OptionButton.new()
	bug_export_format.add_item("HTML (.html) — zrzuty osadzone w jednym pliku (zalecane)")
	bug_export_format.add_item("Markdown (.md) — zrzuty w podfolderze obok pliku")
	bug_export_format.add_item("CSV (.csv) — tabela bez obrazów")
	right.add_child(bug_export_format)
	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 8)
	right.add_child(exp_row)
	var exp_btn := _button("Zapisz raport błędów…", "export", "PrimaryButton")
	exp_btn.pressed.connect(_on_export_bugs)
	exp_row.add_child(exp_btn)
	bug_export_status = Label.new()
	bug_export_status.theme_type_variation = "DimLabel"
	bug_export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(bug_export_status)
	return page


# ---------------- Zakładka 7: Testy WWW ----------------
func _build_web_tab() -> Control:
	var page := VBoxContainer.new()
	page.name = "TestyWWW"
	page.add_theme_constant_override("separation", 12)

	var parts := _card("Automatyczne testy strony WWW", "globe")
	page.add_child(parts[0])
	var box: VBoxContainer = parts[1]
	var hint := Label.new()
	hint.theme_type_variation = "DimLabel"
	hint.text = "Podaj adres strony — program sprawdzi jej dostępność, czas odpowiedzi, HTTPS, podstawy SEO i dostępności (tytuł, opis, H1, teksty alternatywne), favicon, mieszaną treść, nagłówki bezpieczeństwa oraz działanie odnośników (do %d)." % WebTester.MAX_LINKS
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	web_url_edit = LineEdit.new()
	web_url_edit.placeholder_text = "np. https://twoja-aplikacja.pl"
	web_url_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	web_url_edit.text_submitted.connect(func(_t: String) -> void: _on_run_web_tests())
	row.add_child(web_url_edit)
	web_run_button = _button("Uruchom testy", "analyze", "PrimaryButton")
	web_run_button.pressed.connect(_on_run_web_tests)
	row.add_child(web_run_button)
	web_progress = ProgressBar.new()
	web_progress.custom_minimum_size = Vector2(0, 14)
	web_progress.min_value = 0
	web_progress.max_value = 100
	web_progress.show_percentage = false
	web_progress.visible = false
	box.add_child(web_progress)

	web_tree = Tree.new()
	web_tree.columns = 3
	web_tree.column_titles_visible = true
	web_tree.set_column_title(0, "Kontrola")
	web_tree.set_column_title(1, "Wynik")
	web_tree.set_column_title(2, "Szczegóły")
	web_tree.set_column_expand(0, false)
	web_tree.set_column_expand(1, false)
	web_tree.set_column_expand(2, true)
	web_tree.set_column_custom_minimum_width(0, 280)
	web_tree.set_column_custom_minimum_width(1, 90)
	web_tree.hide_root = true
	web_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(web_tree)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	page.add_child(actions)
	web_bugs_button = _button("Dodaj problemy do raportu błędów", "bugs")
	web_bugs_button.disabled = true
	web_bugs_button.pressed.connect(_on_web_to_bugs)
	actions.add_child(web_bugs_button)
	web_export_format = OptionButton.new()
	web_export_format.add_item("HTML (.html)")
	web_export_format.add_item("Markdown (.md)")
	web_export_format.add_item("CSV (.csv)")
	actions.add_child(web_export_format)
	var save_btn := _button("Zapisz raport…", "export")
	save_btn.pressed.connect(_on_export_web)
	actions.add_child(save_btn)
	web_export_status = Label.new()
	web_export_status.theme_type_variation = "DimLabel"
	web_export_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(web_export_status)
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

	bug_attach_dialog = FileDialog.new()
	bug_attach_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	bug_attach_dialog.access = FileDialog.ACCESS_FILESYSTEM
	bug_attach_dialog.title = "Wybierz zrzuty ekranu"
	bug_attach_dialog.filters = PackedStringArray([
		"*.png, *.jpg, *.jpeg, *.webp, *.bmp ; Obrazy",
	])
	bug_attach_dialog.files_selected.connect(_on_attach_files_selected)
	add_child(bug_attach_dialog)

	bug_save_dialog = FileDialog.new()
	bug_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	bug_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	bug_save_dialog.title = "Zapisz raport błędów"
	bug_save_dialog.file_selected.connect(_on_bug_save_path_chosen)
	add_child(bug_save_dialog)

	web_save_dialog = FileDialog.new()
	web_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	web_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	web_save_dialog.title = "Zapisz raport testów strony"
	web_save_dialog.file_selected.connect(_on_web_save_path_chosen)
	add_child(web_save_dialog)


# ============================================================
#  MOTYWY
# ============================================================
func _on_theme_selected(index: int) -> void:
	var id: String = theme_select.get_item_metadata(index)
	_apply_theme(id)
	_save_theme_setting(id)
	_set_status("Zmieniono motyw na „%s”." % UITheme.spec(id)["name"])


func _apply_theme(id: String) -> void:
	current_theme_id = id
	theme = UITheme.build(id)
	bg_rect.color = UITheme.color(id, "bg")
	_refresh_icons()
	# Odśwież kolory akcentów w już wypełnionych listach.
	if output != null:
		_fill_cases_tree()


## Podmienia ikony wszystkich zarejestrowanych widżetów na wariant
## (jasny/ciemny) aktywnego motywu.
func _refresh_icons() -> void:
	for entry in icon_widgets:
		var node: Node = entry["node"]
		if not is_instance_valid(node):
			continue
		if node is Button:
			node.icon = _icon_tex(entry["name"])
		elif node is TextureRect:
			node.texture = load(UITheme.icon_path(current_theme_id, entry["name"], entry.get("size", 24)))
	for i in tab_icon_names.size():
		tabs.set_tab_icon(i, _icon_tex(tab_icon_names[i]))


func _load_theme_setting() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return UITheme.DEFAULT_THEME_ID
	var id: String = cfg.get_value("aplikacja", "motyw", UITheme.DEFAULT_THEME_ID)
	for t in UITheme.themes():
		if t["id"] == id:
			return id
	return UITheme.DEFAULT_THEME_ID


func _save_theme_setting(id: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)  # zachowaj inne ustawienia, jeśli kiedyś dojdą
	cfg.set_value("aplikacja", "motyw", id)
	cfg.save(SETTINGS_PATH)


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
		if app_result != null:
			# Wskazano tylko plik binarny — startujemy od modułu ogólnego,
			# resztę można dodać ręcznie w tej zakładce.
			var fallback := ModuleAnalyzer.ModuleInfo.new()
			fallback.name = "Aplikacja — testy eksploracyjne"
			fallback.source = "aplikacja"
			fallback.content = "Aplikacja: %s" % app_result.source_label
			modules = [fallback]
			_fill_modules_tree()
			generate_button.disabled = false
			tabs.current_tab = 1
			_set_status("Plik binarny nie zdradza struktury — dodano moduł ogólny. Dopisz własne moduły (np. „Logowanie”, „Koszyk”) w polu poniżej listy.")
			return
		_show_error("Wczytaj najpierw dokumentację lub wskaż aplikację (folder, plik albo URL).")
		return
	modules = ModuleAnalyzer.analyze(doc_text, app_text)
	_fill_modules_tree()
	generate_button.disabled = modules.is_empty()
	tabs.current_tab = 1
	var hint := ""
	if doc_text.strip_edges().is_empty():
		hint = " Moduły pochodzą z analizy aplikacji — brakujące możesz dodać ręcznie w polu pod listą."
	_set_status(("Wykryto moduły: %d. Zaznacz te, które chcesz przetestować, i kliknij „Generuj plan i przypadki”." % modules.size()) + hint)


func _on_add_manual_module() -> void:
	var name := manual_module_edit.text.strip_edges()
	if name.is_empty():
		_show_error("Wpisz nazwę modułu, np. „Logowanie”, „Wyszukiwarka”, „Płatności”.")
		return
	for m in modules:
		if m.name.to_lower() == name.to_lower():
			_show_error("Moduł „%s” już jest na liście." % name)
			return
	var info := ModuleAnalyzer.ModuleInfo.new()
	info.name = name
	info.source = "ręcznie"
	info.content = name
	modules.append(info)
	manual_module_edit.clear()
	_fill_modules_tree(true)
	generate_button.disabled = false
	_set_status("Dodano moduł „%s”. Generator dobierze przypadki po słowach kluczowych w nazwie modułu." % name)


func _fill_modules_tree(preserve_checked: bool = false) -> void:
	# Zapamiętaj stan zaznaczeń (przy dokładaniu modułów ręcznie).
	var checked_state := {}
	if preserve_checked and modules_tree.get_root() != null:
		var it := modules_tree.get_root().get_first_child()
		while it != null:
			checked_state[it.get_text(0)] = it.is_checked(0)
			it = it.get_next()
	modules_tree.clear()
	var root := modules_tree.create_item()
	for m in modules:
		var item := modules_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_checked(0, checked_state.get(m.name, true))
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
			mi.set_custom_color(1, UITheme.color(current_theme_id, "accent"))
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


# ============================================================
#  RAPORT BŁĘDÓW
# ============================================================
func _on_tab_changed(tab_index: int) -> void:
	if tab_index == 5:
		_refresh_bug_selectors()
	elif tab_index == 6:
		# Podpowiedz adres testowanej aplikacji, jeśli podano URL.
		if web_url_edit.text.strip_edges().is_empty() and app_result != null and DocLoader.is_url(app_result.source_label):
			web_url_edit.text = app_result.source_label


## Odświeża listy wyboru modułu i przypadku w formularzu zgłoszenia,
## zachowując bieżący wybór, jeśli to możliwe.
func _refresh_bug_selectors() -> void:
	var prev_module := bug_module_option.get_item_text(bug_module_option.selected) if bug_module_option.selected >= 0 else ""
	bug_module_option.clear()
	bug_module_option.add_item("(ogólny / bez modułu)")
	for m in modules:
		bug_module_option.add_item(m.name)
	for i in bug_module_option.item_count:
		if bug_module_option.get_item_text(i) == prev_module:
			bug_module_option.selected = i
	var prev_case := bug_case_option.get_item_text(bug_case_option.selected) if bug_case_option.selected >= 0 else ""
	bug_case_option.clear()
	bug_case_option.add_item("(brak)")
	if output != null:
		for c in output.cases:
			var t: String = c.title
			if t.length() > 60:
				t = t.substr(0, 57) + "..."
			bug_case_option.add_item("%s — %s" % [c.id, t])
	for i in bug_case_option.item_count:
		if bug_case_option.get_item_text(i) == prev_case:
			bug_case_option.selected = i
	if bug_reporter_edit.text.strip_edges().is_empty():
		bug_reporter_edit.text = opt_author.text.strip_edges()


func _on_attach_files_selected(paths: PackedStringArray) -> void:
	var errors: Array[String] = []
	for path in paths:
		var img := Image.new()
		if img.load(path) != OK:
			errors.append(path.get_file())
			continue
		var att := BugReporter.Attachment.new()
		att.name = path.get_file()
		att.image = img
		pending_attachments.append(att)
	_refresh_attachment_thumbnails()
	if not errors.is_empty():
		_show_error("Nie udało się wczytać obrazów: %s" % ", ".join(errors))


func _refresh_attachment_thumbnails() -> void:
	for child in bug_attach_box.get_children():
		child.queue_free()
	for i in pending_attachments.size():
		var att: BugReporter.Attachment = pending_attachments[i]
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)
		var thumb_img: Image = att.image.duplicate()
		var scale: float = minf(1.0, 150.0 / maxf(1.0, float(thumb_img.get_width())))
		thumb_img.resize(int(thumb_img.get_width() * scale), int(thumb_img.get_height() * scale), Image.INTERPOLATE_BILINEAR)
		var tex_rect := TextureRect.new()
		tex_rect.texture = ImageTexture.create_from_image(thumb_img)
		tex_rect.custom_minimum_size = Vector2(150, 90)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cell.add_child(tex_rect)
		var name_lbl := Label.new()
		name_lbl.theme_type_variation = "DimLabel"
		name_lbl.text = att.name if att.name.length() <= 22 else att.name.substr(0, 19) + "..."
		name_lbl.tooltip_text = att.name
		cell.add_child(name_lbl)
		var rm := _button("Usuń")
		var idx := i
		rm.pressed.connect(func() -> void:
			pending_attachments.remove_at(idx)
			_refresh_attachment_thumbnails())
		cell.add_child(rm)
		bug_attach_box.add_child(cell)


func _on_add_bug() -> void:
	var title := bug_title_edit.text.strip_edges()
	if title.is_empty():
		_show_error("Podaj tytuł błędu.")
		return
	var b := BugReporter.BugReport.new()
	bug_counter += 1
	b.id = "BUG-%03d" % bug_counter
	b.title = title
	b.module = "" if bug_module_option.selected <= 0 else bug_module_option.get_item_text(bug_module_option.selected)
	if b.module == "":
		b.module = "(ogólny)"
	b.related_case = "" if bug_case_option.selected <= 0 else bug_case_option.get_item_text(bug_case_option.selected)
	b.severity = bug_severity_option.get_item_text(bug_severity_option.selected)
	b.environment = bug_env_edit.text.strip_edges()
	b.reporter = bug_reporter_edit.text.strip_edges()
	b.steps = bug_steps_edit.text
	b.actual = bug_actual_edit.text.strip_edges()
	b.expected = bug_expected_edit.text.strip_edges()
	b.date = Time.get_datetime_string_from_system(false, true)
	for att in pending_attachments:
		b.attachments.append(att)
	bugs.append(b)
	# Wyczyść formularz (środowisko i zgłaszający zwykle się powtarzają — zostają).
	bug_title_edit.clear()
	bug_steps_edit.text = ""
	bug_actual_edit.text = ""
	bug_expected_edit.text = ""
	pending_attachments = []
	_refresh_attachment_thumbnails()
	_fill_bugs_tree()
	_set_status("Dodano zgłoszenie %s („%s”) z %d zrzutami. Zgłoszeń w raporcie: %d." % [b.id, b.title, b.attachments.size(), bugs.size()])


func _fill_bugs_tree() -> void:
	bugs_tree.clear()
	bug_details.text = ""
	var root := bugs_tree.create_item()
	for i in bugs.size():
		var b: BugReporter.BugReport = bugs[i]
		var item := bugs_tree.create_item(root)
		item.set_text(0, b.id)
		item.set_text(1, b.title)
		item.set_text(2, b.severity)
		item.set_text(3, str(b.attachments.size()))
		item.set_metadata(0, i)


func _on_bug_selected() -> void:
	var item := bugs_tree.get_selected()
	if item == null or item.get_metadata(0) == null:
		return
	var b: BugReporter.BugReport = bugs[item.get_metadata(0)]
	var lines: Array[String] = []
	lines.append("%s — %s" % [b.id, b.title])
	lines.append("Moduł: %s   Waga: %s   Data: %s" % [b.module, b.severity, b.date])
	if b.related_case != "":
		lines.append("Powiązany przypadek: %s" % b.related_case)
	if b.environment != "":
		lines.append("Środowisko: %s" % b.environment)
	if b.reporter != "":
		lines.append("Zgłaszający: %s" % b.reporter)
	lines.append("")
	lines.append("Kroki reprodukcji:")
	lines.append(b.steps.strip_edges())
	lines.append("")
	lines.append("Rezultat aktualny: %s" % b.actual)
	lines.append("Rezultat oczekiwany: %s" % b.expected)
	if not b.attachments.is_empty():
		var names: Array[String] = []
		for a in b.attachments:
			names.append(a.name)
		lines.append("Zrzuty ekranu (%d): %s" % [b.attachments.size(), ", ".join(names)])
	bug_details.text = "\n".join(lines)


func _on_delete_bug() -> void:
	var item := bugs_tree.get_selected()
	if item == null or item.get_metadata(0) == null:
		_show_error("Zaznacz zgłoszenie do usunięcia.")
		return
	bugs.remove_at(item.get_metadata(0))
	_fill_bugs_tree()
	_set_status("Usunięto zgłoszenie. Zgłoszeń w raporcie: %d." % bugs.size())


func _on_export_bugs() -> void:
	if bugs.is_empty():
		_show_error("Raport jest pusty — dodaj najpierw co najmniej jedno zgłoszenie.")
		return
	var ext: String = ["html", "md", "csv"][bug_export_format.selected]
	bug_save_dialog.filters = PackedStringArray(["*.%s ; Pliki %s" % [ext, ext.to_upper()]])
	bug_save_dialog.current_file = "raport_bledow_%s.%s" % [Time.get_date_string_from_system(), ext]
	bug_save_dialog.popup_centered_ratio(0.7)


func _on_bug_save_path_chosen(path: String) -> void:
	var ext: String = ["html", "md", "csv"][bug_export_format.selected]
	if path.get_extension().to_lower() != ext:
		path += "." + ext
	var project := opt_project.text.strip_edges()
	if project.is_empty():
		project = "Aplikacja"
	var err := BugReporter.export(path, ext, bugs, project)
	if err != "":
		bug_export_status.text = "Błąd: " + err
		_show_error(err)
		return
	bug_export_status.text = "Zapisano: %s" % path
	if ext == "md":
		bug_export_status.text += " (zrzuty w folderze %s_zalaczniki)" % path.get_file().get_basename()
	_set_status("Zapisano raport błędów: %s" % path)


# ============================================================
#  TESTY STRONY WWW
# ============================================================
func _on_run_web_tests() -> void:
	var url := web_url_edit.text.strip_edges()
	if url.is_empty():
		_show_error("Podaj adres strony do przetestowania.")
		return
	if not DocLoader.is_url(url):
		url = "https://" + url
		web_url_edit.text = url
	web_run_button.disabled = true
	web_bugs_button.disabled = true
	web_progress.visible = true
	web_progress.value = 0
	web_tree.clear()
	web_checks = []
	var progress := func(text: String, percent: float) -> void:
		_set_status(text)
		web_progress.value = percent
	web_checks = await WebTester.run(web_http, url, progress)
	_fill_web_tree()
	web_run_button.disabled = false
	web_bugs_button.disabled = false
	web_progress.visible = false
	_set_status("Testy strony zakończone (%s). Wyniki możesz zapisać lub przenieść do raportu błędów." % WebTester.summary(web_checks))


func _fill_web_tree() -> void:
	web_tree.clear()
	var root := web_tree.create_item()
	var colors := {
		"OK": Color("18ba62"), "UWAGA": Color("e8971f"),
		"BŁĄD": Color("e5484d"), "INFO": UITheme.color(current_theme_id, "text_dim"),
	}
	for c in web_checks:
		var item := web_tree.create_item(root)
		item.set_text(0, c.name)
		item.set_text(1, c.result)
		item.set_text(2, c.details)
		item.set_custom_color(1, colors.get(c.result, colors["INFO"]))
		item.set_tooltip_text(2, c.details)


func _on_web_to_bugs() -> void:
	var added := 0
	for c in web_checks:
		if c.result != "BŁĄD" and c.result != "UWAGA":
			continue
		var b := BugReporter.BugReport.new()
		bug_counter += 1
		b.id = "BUG-%03d" % bug_counter
		b.title = "WWW: %s" % c.name
		b.module = "Strona WWW"
		b.severity = "Wysoki" if c.result == "BŁĄD" else "Niski"
		b.environment = "Test automatyczny strony: %s" % web_url_edit.text.strip_edges()
		b.reporter = opt_author.text.strip_edges()
		b.steps = "Otwórz stronę %s\nWykonaj kontrolę: %s" % [web_url_edit.text.strip_edges(), c.name]
		b.actual = c.details
		b.expected = "Kontrola „%s” powinna zakończyć się wynikiem OK." % c.name
		b.date = Time.get_datetime_string_from_system(false, true)
		bugs.append(b)
		added += 1
	if added == 0:
		_show_error("Brak problemów (BŁĄD/UWAGA) do przeniesienia — wszystkie kontrole zaliczone.")
		return
	_fill_bugs_tree()
	tabs.current_tab = 5
	_set_status("Dodano %d zgłoszeń z testów strony do raportu błędów." % added)


func _on_export_web() -> void:
	if web_checks.is_empty():
		_show_error("Najpierw uruchom testy strony.")
		return
	var ext: String = ["html", "md", "csv"][web_export_format.selected]
	web_save_dialog.filters = PackedStringArray(["*.%s ; Pliki %s" % [ext, ext.to_upper()]])
	web_save_dialog.current_file = "raport_testow_strony_%s.%s" % [Time.get_date_string_from_system(), ext]
	web_save_dialog.popup_centered_ratio(0.7)


func _on_web_save_path_chosen(path: String) -> void:
	var ext: String = ["html", "md", "csv"][web_export_format.selected]
	if path.get_extension().to_lower() != ext:
		path += "." + ext
	var url := web_url_edit.text.strip_edges()
	var content := ""
	match ext:
		"html":
			content = WebTester.report_html(url, web_checks)
		"md":
			content = WebTester.report_markdown(url, web_checks)
		"csv":
			content = WebTester.report_csv(url, web_checks)
	var err := Exporter.save_text(path, content)
	if err != "":
		web_export_status.text = "Błąd: " + err
		_show_error(err)
		return
	web_export_status.text = "Zapisano: %s" % path
	_set_status("Zapisano raport testów strony: %s" % path)

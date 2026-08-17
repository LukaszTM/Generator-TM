class_name UITheme
extends RefCounted
## Motywy graficzne aplikacji — cztery warianty zbudowane z pakietów
## assetów "TestPilot Studio":
##  - TestPilot jasny  — kolory z style_tokens pakietu Modern Light + jego ikony,
##  - TestPilot ciemny — tekstury pakietu Modern UI Dark (assets/modern_dark/),
##  - Klasyczny jasny/ciemny — styl Windows 95/98 (assets/classic_*/).
## Jak dodać własny motyw — patrz README, sekcja „Jak dodać własny motyw graficzny”.

const DEFAULT_THEME_ID := "testpilot_jasny"

# ------------------------------------------------------------------
# Ikony logiczne. Klucze wspólne dla wszystkich motywów.
# ------------------------------------------------------------------
const ICONS_MODERN := {
	"logo": "app_window", "home": "home", "doc_new": "plus", "doc_down": "download",
	"package": "cube", "checklist": "checklist", "search": "search", "gear": "settings",
	"folder": "folder", "clipboard": "checklist", "globe": "globe", "doc": "document",
	"form": "module_grid", "shield": "lock", "export": "upload", "filter": "filter",
	"pencil": "edit", "link": "link", "delete": "trash",
	"modules": "module_grid", "plan": "document", "cases": "checklist", "bugs": "warning",
	"generate": "play", "analyze": "search", "app": "app_window",
}
const ICONS_CLASSIC := {
	"logo": "app_logo", "home": "project", "doc_new": "new_project", "doc_down": "import_document",
	"package": "import_application", "checklist": "checklist", "search": "search", "gear": "settings",
	"folder": "folder", "clipboard": "test_cases", "globe": "url", "doc": "document",
	"form": "module_list", "shield": "success", "export": "export", "filter": "module_selected",
	"pencil": "edit", "link": "url", "delete": "delete",
	"modules": "module_list", "plan": "test_plan", "cases": "test_cases", "bugs": "warning",
	"generate": "generate_cases", "analyze": "analyze", "app": "application",
}


## Lista dostępnych motywów: [{id, name}].
static func themes() -> Array[Dictionary]:
	return [
		{"id": "testpilot_jasny", "name": "TestPilot — jasny"},
		{"id": "testpilot_ciemny", "name": "TestPilot — ciemny"},
		{"id": "klasyczny_jasny", "name": "Klasyczny — jasny"},
		{"id": "klasyczny_ciemny", "name": "Klasyczny — ciemny"},
	]


## Ścieżka pliku ikony logicznej w wariancie aktywnego motywu.
## size ma znaczenie dla motywów klasycznych (dostępne: 16/24/32).
static func icon_path(theme_id: String, name: String, size: int = 24) -> String:
	var variant: String = spec(theme_id)["icon_variant"]
	match variant:
		"modern_light":
			return "res://assets/modern_light/icons/icon_%s_48.png" % ICONS_MODERN[name]
		"modern_dark":
			return "res://assets/modern_dark/icons/icon_%s_48.png" % ICONS_MODERN[name]
		"classic_light", "classic_dark":
			var dir := "classic_light" if variant == "classic_light" else "classic_dark"
			var s := 16 if size <= 20 else (24 if size <= 28 else 32)
			return "res://assets/%s/icons/%d/%s.png" % [dir, s, ICONS_CLASSIC[name]]
	return ""


## Czy motyw używa pikselowych ikon klasycznych (bez skalowania w przyciskach).
static func is_classic(theme_id: String) -> bool:
	return spec(theme_id).has("classic_dir")


## Specyfikacja motywu.
static func spec(id: String) -> Dictionary:
	match id:
		"testpilot_ciemny":
			# Kolory z docs/asset_map/modern_dark_tokens.json, tekstury z assets/modern_dark/.
			return {
				"name": "TestPilot — ciemny",
				"icon_variant": "modern_dark",
				"modern_dir": "res://assets/modern_dark",
				"bg": Color("031122"),
				"card": Color("09192c"),
				"header": Color("0b1d31"),
				"header_text": Color("eef3fc"),
				"accent": Color("5750ff"),
				"text": Color("eef3fc"),
				"text_dim": Color("91a0b6"),
				"border": Color("28374f"),
				"danger": Color("ff4a5b"),
				"field_bg": Color("102236"),
				"tab_unselected_bg": Color("102236"),
				"tree_sel": Color("282e74"),
				"tree_sel_text": Color("eef3fc"),
				"status_bg": Color("09192c"),
				"btn_normal_font": Color("eef3fc"),
				"btn_primary_font": Color.WHITE,
				"btn_danger_font": Color.WHITE,
			}
		"klasyczny_jasny":
			# Paleta z docs/asset_map/classic_light_manifest.json
			return {
				"name": "Klasyczny — jasny",
				"icon_variant": "classic_light",
				"classic_dir": "res://assets/classic_light",
				"bg": Color("c9c9c9"),
				"card": Color("cfcfcf"),
				"header": Color("000088"),
				"header_text": Color.WHITE,
				"accent": Color("007173"),
				"text": Color("000000"),
				"text_dim": Color("555555"),
				"border": Color("808080"),
				"danger": Color("c40000"),
				"field_bg": Color("f7f7f7"),
				"tab_unselected_bg": Color("bdbdbd"),
				"tree_sel": Color("000088"),
				"tree_sel_text": Color("ffffff"),
				"status_bg": Color("cfcfcf"),
				"btn_normal_font": Color("000000"),
				"btn_primary_font": Color("000000"),
				"btn_danger_font": Color("c40000"),
			}
		"klasyczny_ciemny":
			# Paleta z docs/asset_map/classic_dark_manifest.json
			return {
				"name": "Klasyczny — ciemny",
				"icon_variant": "classic_dark",
				"classic_dir": "res://assets/classic_dark",
				"bg": Color("11181e"),
				"card": Color("151e26"),
				"header": Color("001c5c"),
				"header_text": Color.WHITE,
				"accent": Color("00bed2"),
				"text": Color("cdd6e0"),
				"text_dim": Color("a0aab4"),
				"border": Color("485663"),
				"danger": Color("d22a2a"),
				"field_bg": Color("0e141b"),
				"tab_unselected_bg": Color("0d1318"),
				"tree_sel": Color("125096"),
				"tree_sel_text": Color("ffffff"),
				"status_bg": Color("151e26"),
				"btn_normal_font": Color("cdd6e0"),
				"btn_primary_font": Color("ffffff"),
				"btn_danger_font": Color("ff6b6b"),
			}
		_:  # "testpilot_jasny" — motyw domyślny
			# Kolory z docs/asset_map/modern_light_tokens.json (style_tokens
			# pakietu Modern Light); rysowany płasko, ikony z pakietu.
			return {
				"name": "TestPilot — jasny",
				"icon_variant": "modern_light",
				"bg": Color("f7f9fc"),
				"card": Color("ffffff"),
				"header": Color("ffffff"),
				"header_text": Color("182235"),
				"accent": Color("2563eb"),
				"text": Color("182235"),
				"text_dim": Color("62718a"),
				"border": Color("d8e1f0"),
				"danger": Color("ef4444"),
				"field_bg": Color("ffffff"),
				"tab_unselected_bg": Color("e9eef8"),
				"tree_sel": Color("dbeafe"),
				"tree_sel_text": Color("182235"),
				"status_bg": Color("eff3f8"),
				"btn_normal_tex": "",
				"btn_normal_bg": Color("ffffff"), "btn_normal_border": Color("d8e1f0"), "btn_normal_font": Color("182235"),
				"btn_primary_tex": "",
				"btn_primary_bg": Color("2563eb"), "btn_primary_border": Color("1d4ed8"), "btn_primary_font": Color.WHITE,
				"btn_danger_tex": "",
				"btn_danger_bg": Color("ef4444"), "btn_danger_border": Color("dc2626"), "btn_danger_font": Color.WHITE,
			}


## Pojedynczy kolor z motywu (np. UITheme.color(id, "accent")).
static func color(id: String, key: String) -> Color:
	return spec(id)[key]


static func build(id: String = DEFAULT_THEME_ID) -> Theme:
	var s := spec(id)
	var theme := Theme.new()
	var classic: bool = s.has("classic_dir")
	var modern: bool = s.has("modern_dir")

	# --- Czcionki: klasyczne motywy używają systemowej Tahomy (zgodnie
	# z pakietem), pozostałe dołączonego Intera.
	var font_regular: Font
	var font_medium: Font
	var font_semibold: Font
	var font_bold: Font
	if classic:
		var sys := SystemFont.new()
		sys.font_names = PackedStringArray(["Tahoma", "Arial", "Liberation Sans"])
		var sys_bold := SystemFont.new()
		sys_bold.font_names = sys.font_names
		sys_bold.font_weight = 700
		font_regular = sys
		font_medium = sys
		font_semibold = sys_bold
		font_bold = sys_bold
		theme.default_font_size = 14
	else:
		font_regular = load("res://fonts/Inter-Regular.otf")
		font_medium = load("res://fonts/Inter-Medium.otf")
		font_semibold = load("res://fonts/Inter-SemiBold.otf")
		font_bold = load("res://fonts/Inter-Bold.otf")
		theme.default_font_size = 15
	theme.default_font = font_regular

	# ---------- Przyciski ----------
	_setup_button(theme, "Button", s, "normal", font_medium)
	theme.set_type_variation(&"PrimaryButton", &"Button")
	_setup_button(theme, "PrimaryButton", s, "primary", font_semibold)
	theme.set_type_variation(&"DangerButton", &"Button")
	_setup_button(theme, "DangerButton", s, "danger", font_semibold)

	# OptionButton: klasyka dziedziczy styl przycisku, modern ma dropdowny z pakietu.
	if classic:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
	elif modern:
		var dd := {
			"normal": "/inputs/dropdown_normal.png", "hover": "/inputs/dropdown_hover.png",
			"pressed": "/inputs/dropdown_open.png", "disabled": "/inputs/dropdown_disabled.png",
			"focus": "/inputs/dropdown_hover.png",
		}
		for state in dd:
			var sb := _tex_box(s.modern_dir + dd[state], 14, 8)
			sb.content_margin_left = 12
			sb.content_margin_right = 12
			theme.set_stylebox(state, "OptionButton", sb)
	theme.set_color("font_color", "OptionButton", s.text)

	# ---------- Panele / karty ----------
	var card: StyleBox
	if classic:
		card = _tex_box(s.classic_dir + "/frames/panel_raised_9slice.png", 4, 12)
	elif modern:
		card = _tex_box(s.modern_dir + "/panels/card_420x220.png", 20, 16)
	else:
		card = _flat(s.card, s.border, 14, 16)
	theme.set_type_variation(&"Card", &"PanelContainer")
	theme.set_stylebox("panel", "Card", card)

	var header: StyleBox
	if classic:
		header = _tex_box(s.classic_dir + "/backgrounds/titlebar_active.png", 4, 8)
	elif modern:
		header = _tex_box(s.modern_dir + "/window/top_toolbar_1200x64.png", 8, 10)
	else:
		header = _flat(s.header, s.border, 0, 10)
	header.content_margin_left = 18
	header.content_margin_right = 18
	theme.set_type_variation(&"HeaderBar", &"PanelContainer")
	theme.set_stylebox("panel", "HeaderBar", header)

	var status: StyleBox
	if classic:
		status = _tex_box(s.classic_dir + "/frames/status_pane_9slice.png", 4, 6)
	elif modern:
		status = _tex_box(s.modern_dir + "/window/status_bar_1200x42.png", 8, 6)
	else:
		status = _flat(s.status_bg, s.status_bg, 0, 6)
	status.content_margin_left = 18
	theme.set_type_variation(&"StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", "StatusBar", status)

	# ---------- Etykiety ----------
	theme.set_color("font_color", "Label", s.text)
	var header_text: Color = s.get("header_text", Color.WHITE)
	theme.set_type_variation(&"TitleLabel", &"Label")
	theme.set_font("font", "TitleLabel", font_bold)
	theme.set_font_size("font_size", "TitleLabel", 18 if classic else 20)
	theme.set_color("font_color", "TitleLabel", header_text)
	theme.set_type_variation(&"HeaderDim", &"Label")
	theme.set_color("font_color", "HeaderDim", Color(header_text, 0.72))
	theme.set_type_variation(&"CardTitle", &"Label")
	theme.set_font("font", "CardTitle", font_semibold)
	theme.set_font_size("font_size", "CardTitle", 15 if classic else 17)
	theme.set_color("font_color", "CardTitle", s.text)
	theme.set_type_variation(&"DimLabel", &"Label")
	theme.set_color("font_color", "DimLabel", s.text_dim)
	theme.set_font_size("font_size", "DimLabel", 12 if classic else 13)

	# ---------- Pola tekstowe ----------
	var edit: StyleBox
	var edit_focus: StyleBox
	var text_area: StyleBox
	if classic:
		edit = _tex_box(s.classic_dir + "/inputs/lineedit_normal_9slice.png", 4, 6)
		edit_focus = _tex_box(s.classic_dir + "/inputs/lineedit_focus_9slice.png", 4, 6)
		text_area = _tex_box(s.classic_dir + "/inputs/textedit_normal_9slice.png", 4, 8)
	elif modern:
		edit = _tex_box(s.modern_dir + "/inputs/line_edit_normal.png", 14, 8)
		edit_focus = _tex_box(s.modern_dir + "/inputs/line_edit_focus.png", 14, 8)
		text_area = _tex_box(s.modern_dir + "/inputs/line_edit_normal.png", 14, 8)
	else:
		edit = _flat(s.field_bg, s.border, 10, 8)
		var efl := _flat(s.field_bg, s.accent, 10, 8)
		(efl as StyleBoxFlat).set_border_width_all(2)
		edit_focus = efl
		text_area = edit
	for sb in [edit, edit_focus]:
		sb.content_margin_left = 12
		sb.content_margin_right = 12
	theme.set_stylebox("normal", "LineEdit", edit)
	theme.set_stylebox("focus", "LineEdit", edit_focus)
	theme.set_color("font_color", "LineEdit", s.text)
	theme.set_stylebox("normal", "TextEdit", text_area)
	theme.set_stylebox("focus", "TextEdit", text_area if (classic or modern) else edit_focus)
	theme.set_stylebox("read_only", "TextEdit", text_area)
	theme.set_color("font_color", "TextEdit", s.text)
	theme.set_color("font_readonly_color", "TextEdit", s.text)
	theme.set_color("font_placeholder_color", "LineEdit", Color(s.text_dim, 0.7))
	theme.set_color("font_placeholder_color", "TextEdit", Color(s.text_dim, 0.7))
	theme.set_color("caret_color", "LineEdit", s.text)
	theme.set_color("caret_color", "TextEdit", s.text)
	theme.set_font("font", "TextEdit", font_regular)
	theme.set_font_size("font_size", "TextEdit", 13 if classic else 14)

	# ---------- Zakładki ----------
	if classic:
		theme.set_stylebox("panel", "TabContainer", _tex_box(s.classic_dir + "/tabs/tab_container_9slice.png", 4, 12))
		_set_tabs(theme, [
			_tex_box(s.classic_dir + "/tabs/tab_selected_9slice.png", 4, 8),
			_tex_box(s.classic_dir + "/tabs/tab_unselected_9slice.png", 4, 8),
			_tex_box(s.classic_dir + "/tabs/tab_hover_9slice.png", 4, 8),
		])
	elif modern:
		theme.set_stylebox("panel", "TabContainer", _tex_box(s.modern_dir + "/panels/card_520x300.png", 20, 14))
		_set_tabs(theme, [
			_tex_box(s.modern_dir + "/tabs/tab_selected.png", 14, 9),
			_tex_box(s.modern_dir + "/tabs/tab_normal.png", 14, 9),
			_tex_box(s.modern_dir + "/tabs/tab_hover.png", 14, 9),
		])
	else:
		var tab_panel := _flat(s.card, s.border, 8, 14)
		(tab_panel as StyleBoxFlat).corner_radius_top_left = 0
		theme.set_stylebox("panel", "TabContainer", tab_panel)
		var tab_sel := StyleBoxFlat.new()
		tab_sel.bg_color = s.card
		tab_sel.border_color = s.accent
		tab_sel.border_width_left = 1
		tab_sel.border_width_right = 1
		tab_sel.border_width_top = 3
		tab_sel.corner_radius_top_left = 8
		tab_sel.corner_radius_top_right = 8
		tab_sel.set_content_margin_all(10)
		var tab_un: StyleBoxFlat = tab_sel.duplicate()
		tab_un.bg_color = s.tab_unselected_bg
		tab_un.border_color = s.border
		tab_un.border_width_top = 1
		_set_tabs(theme, [tab_sel, tab_un, tab_un])
	theme.set_color("font_selected_color", "TabContainer", s.text)
	theme.set_color("font_unselected_color", "TabContainer", s.text_dim)
	theme.set_font("font", "TabContainer", font_medium)
	theme.set_font_size("font_size", "TabContainer", 14 if classic else 15)

	# ---------- Drzewo (listy) ----------
	if classic:
		theme.set_stylebox("panel", "Tree", _tex_box(s.classic_dir + "/frames/panel_inset_9slice.png", 4, 6))
		var th := _tex_box(s.classic_dir + "/frames/table_header_9slice.png", 4, 4)
		for st in ["title_button_normal", "title_button_hover", "title_button_pressed"]:
			theme.set_stylebox(st, "Tree", th)
		theme.set_color("title_button_color", "Tree", s.text)
		theme.set_icon("arrow", "Tree", load(s.classic_dir + "/controls/tree_expanded.png"))
		theme.set_icon("arrow_collapsed", "Tree", load(s.classic_dir + "/controls/tree_collapsed.png"))
		theme.set_icon("checked", "Tree", load(s.classic_dir + "/controls/checkbox_checked.png"))
		theme.set_icon("unchecked", "Tree", load(s.classic_dir + "/controls/checkbox_unchecked.png"))
	elif modern:
		theme.set_stylebox("panel", "Tree", _tex_box(s.modern_dir + "/inputs/line_edit_normal.png", 14, 6))
		var th := _tex_box(s.modern_dir + "/table/table_header.png", 10, 4)
		for st in ["title_button_normal", "title_button_hover", "title_button_pressed"]:
			theme.set_stylebox(st, "Tree", th)
		theme.set_color("title_button_color", "Tree", s.text)
		theme.set_icon("checked", "Tree", _scaled_icon(s.modern_dir + "/controls/checkbox_checked.png", 18))
		theme.set_icon("unchecked", "Tree", _scaled_icon(s.modern_dir + "/controls/checkbox_unchecked.png", 18))
	else:
		theme.set_stylebox("panel", "Tree", _flat(s.field_bg, s.border, 8, 6))
		var th_flat := _flat(s.tab_unselected_bg, s.border, 0, 4)
		for st in ["title_button_normal", "title_button_hover", "title_button_pressed"]:
			theme.set_stylebox(st, "Tree", th_flat)
		theme.set_color("title_button_color", "Tree", s.text)
	theme.set_color("font_color", "Tree", s.text)
	var tree_sel := StyleBoxFlat.new()
	tree_sel.bg_color = s.tree_sel
	theme.set_stylebox("selected", "Tree", tree_sel)
	theme.set_stylebox("selected_focus", "Tree", tree_sel)
	theme.set_color("font_selected_color", "Tree", s.tree_sel_text)

	# ---------- CheckBox ----------
	theme.set_color("font_color", "CheckBox", s.text)
	if classic or modern:
		var base: String = s.classic_dir if classic else s.modern_dir
		var checked_path := base + "/controls/checkbox_checked.png"
		var unchecked_path := base + "/controls/checkbox_unchecked.png"
		var checked_dis := base + ("/controls/checkbox_checked_disabled.png" if classic else "/controls/checkbox_disabled.png")
		var unchecked_dis := base + ("/controls/checkbox_unchecked_disabled.png" if classic else "/controls/checkbox_disabled.png")
		var size := 18 if classic else 20
		theme.set_icon("checked", "CheckBox", _scaled_icon(checked_path, size))
		theme.set_icon("unchecked", "CheckBox", _scaled_icon(unchecked_path, size))
		theme.set_icon("checked_disabled", "CheckBox", _scaled_icon(checked_dis, size))
		theme.set_icon("unchecked_disabled", "CheckBox", _scaled_icon(unchecked_dis, size))
		var cb_empty := StyleBoxEmpty.new()
		cb_empty.set_content_margin_all(2)
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			theme.set_stylebox(state, "CheckBox", cb_empty)

	# ---------- Paski przewijania ----------
	if classic or modern:
		var base2: String = s.classic_dir if classic else s.modern_dir
		var suffix := "_9slice" if classic else ""
		var thumb_v := _tex_box(base2 + "/controls/scrollbar_thumb_vertical%s.png" % suffix, 4 if classic else 6, 0)
		var thumb_h := _tex_box(base2 + "/controls/scrollbar_thumb_horizontal%s.png" % suffix, 4 if classic else 6, 0)
		var track_v := _tex_box(base2 + "/controls/scrollbar_track_vertical.png", 4 if classic else 6, 0)
		var track_h := _tex_box(base2 + "/controls/scrollbar_track_horizontal.png", 4 if classic else 6, 0)
		for grabber in ["grabber", "grabber_highlight", "grabber_pressed"]:
			theme.set_stylebox(grabber, "VScrollBar", thumb_v)
			theme.set_stylebox(grabber, "HScrollBar", thumb_h)
		theme.set_stylebox("scroll", "VScrollBar", track_v)
		theme.set_stylebox("scroll", "HScrollBar", track_h)

	# ---------- ProgressBar ----------
	if classic:
		theme.set_stylebox("background", "ProgressBar", _tex_box(s.classic_dir + "/controls/progress_background_9slice.png", 3, 0))
		theme.set_stylebox("fill", "ProgressBar", _tex_box(s.classic_dir + "/controls/progress_fill_9slice.png", 2, 0))
	elif modern:
		theme.set_stylebox("background", "ProgressBar", _tex_box(s.modern_dir + "/controls/progress_track.png", 6, 0))
		theme.set_stylebox("fill", "ProgressBar", _tex_box(s.modern_dir + "/controls/progress_fill_blue.png", 6, 0))
	else:
		theme.set_stylebox("background", "ProgressBar", _flat(s.tab_unselected_bg, s.tab_unselected_bg, 6, 0))
		theme.set_stylebox("fill", "ProgressBar", _flat(s.accent, s.accent, 6, 0))

	return theme


static func _set_tabs(theme: Theme, boxes: Array) -> void:
	for b in boxes:
		b.content_margin_left = 16
		b.content_margin_right = 16
	theme.set_stylebox("tab_selected", "TabContainer", boxes[0])
	theme.set_stylebox("tab_unselected", "TabContainer", boxes[1])
	theme.set_stylebox("tab_hovered", "TabContainer", boxes[2])


## Płaski StyleBoxFlat: tło, ramka 1 px, promień rogów, margines treści.
static func _flat(bg: Color, border: Color, radius: int, content: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	if border != bg:
		sb.set_border_width_all(1)
	sb.set_corner_radius_all(radius)
	if content > 0:
		sb.set_content_margin_all(content)
	return sb


## StyleBoxTexture z pliku 9-slice: margin — margines cięcia, content — margines treści.
static func _tex_box(path: String, margin: int, content: int) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	if content > 0:
		sb.set_content_margin_all(content)
	return sb


## Ikona przeskalowana do zadanego rozmiaru (dla ikon stanów kontrolek).
static func _scaled_icon(path: String, size: int) -> Texture2D:
	var tex: Texture2D = load(path)
	var img := tex.get_image()
	img.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)


## Styl przycisku. Cztery źródła wyglądu:
## klasyczne tekstury per stan -> nowoczesne tekstury per stan ->
## tekstura ninepatch + modulacja -> płaski z kolorów.
static func _setup_button(theme: Theme, type_name: String, s: Dictionary, kind: String, font: Font) -> void:
	var font_color: Color = s["btn_%s_font" % kind]
	if s.has("classic_dir"):
		var dir: String = s.classic_dir + "/buttons"
		var normal_tex := dir + ("/button_default_9slice.png" if kind == "primary" else "/button_normal_9slice.png")
		var state_tex := {
			"normal": normal_tex,
			"hover": dir + "/button_hover_9slice.png",
			"pressed": dir + "/button_pressed_9slice.png",
			"disabled": dir + "/button_disabled_9slice.png",
			"focus": normal_tex,
		}
		for state in state_tex:
			var sb := _tex_box(state_tex[state], 4, 0)
			sb.content_margin_left = 14
			sb.content_margin_right = 14
			sb.content_margin_top = 6
			sb.content_margin_bottom = 6
			theme.set_stylebox(state, type_name, sb)
	elif s.has("modern_dir"):
		# Pakiet Modern: przycisk „normal” to secondary, primary i danger wprost.
		var file_kind: String = {"normal": "secondary", "primary": "primary", "danger": "danger"}[kind]
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var tex_state: String = "normal" if state == "focus" else state
			var sb := _tex_box("%s/buttons/button_%s_%s.png" % [s.modern_dir, file_kind, tex_state], 18, 0)
			sb.content_margin_left = 16
			sb.content_margin_right = 16
			sb.content_margin_top = 8
			sb.content_margin_bottom = 8
			theme.set_stylebox(state, type_name, sb)
	else:
		var tex_path: String = s.get("btn_%s_tex" % kind, "")
		var margins: Array = s.get("btn_%s_margins" % kind, [24, 20])
		var states := {"normal": 1.0, "hover": 1.06, "pressed": 0.94, "disabled": 1.0, "focus": 1.0}
		for state in states:
			var mod: float = states[state]
			var sb: StyleBox
			if tex_path != "":
				var sbt := StyleBoxTexture.new()
				sbt.texture = load(tex_path)
				sbt.texture_margin_left = margins[0]
				sbt.texture_margin_right = margins[0]
				sbt.texture_margin_top = margins[1]
				sbt.texture_margin_bottom = margins[1]
				sbt.modulate_color = Color(mod, mod, mod, 0.45 if state == "disabled" else 1.0)
				sb = sbt
			else:
				var sbf := StyleBoxFlat.new()
				var bg: Color = s["btn_%s_bg" % kind]
				sbf.bg_color = Color(bg.r * mod, bg.g * mod, bg.b * mod, 0.45 if state == "disabled" else 1.0)
				sbf.border_color = s["btn_%s_border" % kind]
				sbf.set_border_width_all(1)
				sbf.set_corner_radius_all(10)
				sb = sbf
			sb.content_margin_left = 18
			sb.content_margin_right = 18
			sb.content_margin_top = 8
			sb.content_margin_bottom = 8
			theme.set_stylebox(state, type_name, sb)
	theme.set_font("font", type_name, font)
	theme.set_color("font_color", type_name, font_color)
	theme.set_color("font_hover_color", type_name, font_color)
	theme.set_color("font_pressed_color", type_name, font_color)
	theme.set_color("font_focus_color", type_name, font_color)
	theme.set_color("font_disabled_color", type_name, Color(font_color, 0.5))
	theme.set_constant("h_separation", type_name, 8)

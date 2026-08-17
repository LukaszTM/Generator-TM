class_name UITheme
extends RefCounted
## Motywy graficzne aplikacji — cztery warianty zbudowane z pakietów
## assetów "TestPilot Studio":
##  - nowoczesny jasny/ciemny (assets/ i assets/dark/ — cięte automatycznie),
##  - klasyczny jasny/ciemny w stylu Windows 95/98 (assets/classic_*/ —
##    nazwane elementy 9-slice, ikony 16/24/32, manifest z paletą).
## Jak dodać własny motyw — patrz README, sekcja „Jak dodać własny motyw graficzny”.

const DEFAULT_THEME_ID := "testpilot_jasny"

# ------------------------------------------------------------------
# Ikony logiczne. Klucze są wspólne dla wszystkich motywów; wartości to
# numer pliku (warianty cięte automatycznie) albo nazwa pliku (klasyczne).
# ------------------------------------------------------------------
const ICONS_LIGHT := {
	"logo": "001", "home": "002", "doc_new": "003", "doc_down": "004",
	"package": "005", "checklist": "006", "search": "007", "gear": "008",
	"folder": "010", "clipboard": "012", "globe": "013", "doc": "014",
	"form": "015", "shield": "016", "export": "019", "filter": "020",
	"pencil": "025", "link": "040", "delete": "030",
	"modules": "020", "plan": "014", "cases": "012", "bugs": "016",
	"generate": "006", "analyze": "007", "app": "005",
}
const ICONS_DARK := {
	"logo": "001", "home": "005", "doc_new": "004", "doc_down": "002",
	"package": "006", "checklist": "003", "search": "007", "gear": "008",
	"folder": "010", "clipboard": "011", "globe": "014", "doc": "012",
	"form": "015", "shield": "016", "export": "013", "filter": "020",
	"pencil": "024", "link": "035", "delete": "021",
	"modules": "020", "plan": "012", "cases": "011", "bugs": "016",
	"generate": "003", "analyze": "007", "app": "006",
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
## size ma znaczenie tylko dla motywów klasycznych (dostępne: 16/24/32).
static func icon_path(theme_id: String, name: String, size: int = 24) -> String:
	var variant: String = spec(theme_id)["icon_variant"]
	match variant:
		"dark":
			return "res://assets/dark/icons/testpilot_dark_icons_%s.png" % ICONS_DARK[name]
		"classic_light", "classic_dark":
			var dir := "classic_light" if variant == "classic_light" else "classic_dark"
			var s := 16 if size <= 20 else (24 if size <= 28 else 32)
			return "res://assets/%s/icons/%d/%s.png" % [dir, s, ICONS_CLASSIC[name]]
		_:
			return "res://assets/icons/testpilot_icons_%s.png" % ICONS_LIGHT[name]


## Czy motyw używa pikselowych ikon klasycznych (bez skalowania w przyciskach).
static func is_classic(theme_id: String) -> bool:
	return spec(theme_id).has("classic_dir")


## Specyfikacja motywu.
static func spec(id: String) -> Dictionary:
	match id:
		"testpilot_ciemny":
			return {
				"name": "TestPilot — ciemny",
				"icon_variant": "dark",
				"bg": Color("0f1a2b"),
				"card": Color("15263d"),
				"header": Color("143369"),
				"accent": Color("1ab5c2"),
				"text": Color("e8eef8"),
				"text_dim": Color("9db0c8"),
				"border": Color("2a4262"),
				"danger": Color("e04250"),
				"field_bg": Color("182942"),
				"tab_unselected_bg": Color("1b2f4d"),
				"tree_sel": Color("204064"),
				"tree_sel_text": Color("e8eef8"),
				"status_bg": Color("122238"),
				"btn_normal_tex": "res://assets/dark/buttons/testpilot_dark_buttons_008.png",
				"btn_normal_margins": [24, 20],
				"btn_normal_bg": Color("1b3653"), "btn_normal_border": Color("2a4262"), "btn_normal_font": Color("e8eef8"),
				"btn_primary_tex": "res://assets/dark/buttons/testpilot_dark_buttons_005.png",
				"btn_primary_margins": [24, 20],
				"btn_primary_bg": Color("128f89"), "btn_primary_border": Color("1ab5c2"), "btn_primary_font": Color.WHITE,
				"btn_danger_tex": "res://assets/dark/buttons/testpilot_dark_buttons_040.png",
				"btn_danger_margins": [16, 14],
				"btn_danger_bg": Color("ad0114"), "btn_danger_border": Color("e04250"), "btn_danger_font": Color.WHITE,
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
			return {
				"name": "TestPilot — jasny",
				"icon_variant": "light",
				"bg": Color("f2f5fa"),
				"card": Color("ffffff"),
				"header": Color("1a3fc4"),
				"accent": Color("0e8f8f"),
				"text": Color("1d2433"),
				"text_dim": Color("5a6478"),
				"border": Color("d7dfeb"),
				"danger": Color("d21f2e"),
				"field_bg": Color("ffffff"),
				"tab_unselected_bg": Color("e2e9f3"),
				"tree_sel": Color("d9ecec"),
				"tree_sel_text": Color("1d2433"),
				"status_bg": Color("e6ecf5"),
				"btn_normal_tex": "res://assets/buttons/testpilot_buttons_008.png",
				"btn_normal_margins": [24, 20],
				"btn_normal_bg": Color.WHITE, "btn_normal_border": Color("d7dfeb"), "btn_normal_font": Color("1d2433"),
				"btn_primary_tex": "res://assets/buttons/testpilot_buttons_002.png",
				"btn_primary_margins": [24, 20],
				"btn_primary_bg": Color("0e8f8f"), "btn_primary_border": Color("0e8f8f"), "btn_primary_font": Color.WHITE,
				"btn_danger_tex": "res://assets/buttons/testpilot_buttons_014.png",
				"btn_danger_margins": [24, 20],
				"btn_danger_bg": Color("d21f2e"), "btn_danger_border": Color("d21f2e"), "btn_danger_font": Color.WHITE,
			}


## Pojedynczy kolor z motywu (np. UITheme.color(id, "accent")).
static func color(id: String, key: String) -> Color:
	return spec(id)[key]


static func build(id: String = DEFAULT_THEME_ID) -> Theme:
	var s := spec(id)
	var theme := Theme.new()
	var classic: bool = s.has("classic_dir")

	# --- Czcionki: nowoczesne motywy używają Inter; klasyczne czcionki
	# systemowej Tahoma (fallback Arial/Liberation Sans) zgodnie z pakietem.
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
	# OptionButton w klasyce dostaje styl przycisku (spójny wygląd list rozwijanych).
	if classic:
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			theme.set_stylebox(state, "OptionButton", theme.get_stylebox(state, "Button"))
		theme.set_color("font_color", "OptionButton", s.text)

	# ---------- Panele / karty ----------
	var card: StyleBox
	if classic:
		card = _tex_box(s.classic_dir + "/frames/panel_raised_9slice.png", 4, 12)
	else:
		var cf := StyleBoxFlat.new()
		cf.bg_color = s.card
		cf.set_corner_radius_all(10)
		cf.border_color = s.border
		cf.set_border_width_all(1)
		cf.set_content_margin_all(16)
		card = cf
	theme.set_type_variation(&"Card", &"PanelContainer")
	theme.set_stylebox("panel", "Card", card)

	var header: StyleBox
	if classic:
		header = _tex_box(s.classic_dir + "/backgrounds/titlebar_active.png", 4, 8)
		header.content_margin_left = 18
		header.content_margin_right = 18
	else:
		var hf := StyleBoxFlat.new()
		hf.bg_color = s.header
		hf.set_content_margin_all(10)
		hf.content_margin_left = 18
		hf.content_margin_right = 18
		header = hf
	theme.set_type_variation(&"HeaderBar", &"PanelContainer")
	theme.set_stylebox("panel", "HeaderBar", header)

	var status: StyleBox
	if classic:
		status = _tex_box(s.classic_dir + "/frames/status_pane_9slice.png", 4, 6)
		status.content_margin_left = 18
	else:
		var sf := StyleBoxFlat.new()
		sf.bg_color = s.status_bg
		sf.set_content_margin_all(6)
		sf.content_margin_left = 18
		status = sf
	theme.set_type_variation(&"StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", "StatusBar", status)

	# ---------- Etykiety ----------
	theme.set_color("font_color", "Label", s.text)
	theme.set_type_variation(&"TitleLabel", &"Label")
	theme.set_font("font", "TitleLabel", font_bold)
	theme.set_font_size("font_size", "TitleLabel", 18 if classic else 20)
	theme.set_color("font_color", "TitleLabel", Color.WHITE)
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
		edit.content_margin_left = 10
		edit.content_margin_right = 10
		edit_focus = _tex_box(s.classic_dir + "/inputs/lineedit_focus_9slice.png", 4, 6)
		edit_focus.content_margin_left = 10
		edit_focus.content_margin_right = 10
		text_area = _tex_box(s.classic_dir + "/inputs/textedit_normal_9slice.png", 4, 8)
	else:
		var ef := StyleBoxFlat.new()
		ef.bg_color = s.field_bg
		ef.set_corner_radius_all(8)
		ef.border_color = s.border
		ef.set_border_width_all(1)
		ef.set_content_margin_all(8)
		ef.content_margin_left = 12
		ef.content_margin_right = 12
		edit = ef
		edit_focus = ef.duplicate()
		edit_focus.border_color = s.accent
		(edit_focus as StyleBoxFlat).set_border_width_all(2)
		text_area = ef
	theme.set_stylebox("normal", "LineEdit", edit)
	theme.set_stylebox("focus", "LineEdit", edit_focus)
	theme.set_color("font_color", "LineEdit", s.text)
	theme.set_stylebox("normal", "TextEdit", text_area)
	theme.set_stylebox("focus", "TextEdit", text_area if classic else edit_focus)
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
		var t_sel := _tex_box(s.classic_dir + "/tabs/tab_selected_9slice.png", 4, 8)
		var t_un := _tex_box(s.classic_dir + "/tabs/tab_unselected_9slice.png", 4, 8)
		var t_hov := _tex_box(s.classic_dir + "/tabs/tab_hover_9slice.png", 4, 8)
		for t in [t_sel, t_un, t_hov]:
			t.content_margin_left = 14
			t.content_margin_right = 14
		theme.set_stylebox("tab_selected", "TabContainer", t_sel)
		theme.set_stylebox("tab_unselected", "TabContainer", t_un)
		theme.set_stylebox("tab_hovered", "TabContainer", t_hov)
	else:
		var tab_panel := StyleBoxFlat.new()
		tab_panel.bg_color = s.card
		tab_panel.border_color = s.border
		tab_panel.set_border_width_all(1)
		tab_panel.set_corner_radius_all(8)
		tab_panel.corner_radius_top_left = 0
		tab_panel.set_content_margin_all(14)
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
		tab_sel.content_margin_left = 16
		tab_sel.content_margin_right = 16
		var tab_un: StyleBoxFlat = tab_sel.duplicate()
		tab_un.bg_color = s.tab_unselected_bg
		tab_un.border_color = s.border
		tab_un.border_width_top = 1
		theme.set_stylebox("tab_selected", "TabContainer", tab_sel)
		theme.set_stylebox("tab_unselected", "TabContainer", tab_un)
		theme.set_stylebox("tab_hovered", "TabContainer", tab_un)
	theme.set_color("font_selected_color", "TabContainer", s.text)
	theme.set_color("font_unselected_color", "TabContainer", s.text_dim)
	theme.set_font("font", "TabContainer", font_medium)
	theme.set_font_size("font_size", "TabContainer", 14 if classic else 15)

	# ---------- Drzewo (listy) ----------
	if classic:
		theme.set_stylebox("panel", "Tree", _tex_box(s.classic_dir + "/frames/panel_inset_9slice.png", 4, 6))
		var th := _tex_box(s.classic_dir + "/frames/table_header_9slice.png", 4, 4)
		theme.set_stylebox("title_button_normal", "Tree", th)
		theme.set_stylebox("title_button_hover", "Tree", th)
		theme.set_stylebox("title_button_pressed", "Tree", th)
		theme.set_color("title_button_color", "Tree", s.text)
		theme.set_icon("arrow", "Tree", load(s.classic_dir + "/controls/tree_expanded.png"))
		theme.set_icon("arrow_collapsed", "Tree", load(s.classic_dir + "/controls/tree_collapsed.png"))
		theme.set_icon("checked", "Tree", load(s.classic_dir + "/controls/checkbox_checked.png"))
		theme.set_icon("unchecked", "Tree", load(s.classic_dir + "/controls/checkbox_unchecked.png"))
	else:
		var tree_bg := StyleBoxFlat.new()
		tree_bg.bg_color = s.field_bg
		tree_bg.border_color = s.border
		tree_bg.set_border_width_all(1)
		tree_bg.set_corner_radius_all(8)
		tree_bg.set_content_margin_all(6)
		theme.set_stylebox("panel", "Tree", tree_bg)
	theme.set_color("font_color", "Tree", s.text)
	var tree_sel := StyleBoxFlat.new()
	tree_sel.bg_color = s.tree_sel
	theme.set_stylebox("selected", "Tree", tree_sel)
	theme.set_stylebox("selected_focus", "Tree", tree_sel)
	theme.set_color("font_selected_color", "Tree", s.tree_sel_text)

	# ---------- CheckBox ----------
	theme.set_color("font_color", "CheckBox", s.text)
	if classic:
		theme.set_icon("checked", "CheckBox", load(s.classic_dir + "/controls/checkbox_checked.png"))
		theme.set_icon("unchecked", "CheckBox", load(s.classic_dir + "/controls/checkbox_unchecked.png"))
		theme.set_icon("checked_disabled", "CheckBox", load(s.classic_dir + "/controls/checkbox_checked_disabled.png"))
		theme.set_icon("unchecked_disabled", "CheckBox", load(s.classic_dir + "/controls/checkbox_unchecked_disabled.png"))
		var cb_empty := StyleBoxEmpty.new()
		cb_empty.set_content_margin_all(2)
		for state in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
			theme.set_stylebox(state, "CheckBox", cb_empty)
	if not classic:
		theme.set_color("font_color", "OptionButton", s.text)

	# ---------- Paski przewijania (klasyczne) ----------
	if classic:
		var thumb_v := _tex_box(s.classic_dir + "/controls/scrollbar_thumb_vertical_9slice.png", 4, 0)
		var thumb_h := _tex_box(s.classic_dir + "/controls/scrollbar_thumb_horizontal_9slice.png", 4, 0)
		var track_v := _tex_box(s.classic_dir + "/controls/scrollbar_track_vertical.png", 4, 0)
		var track_h := _tex_box(s.classic_dir + "/controls/scrollbar_track_horizontal.png", 4, 0)
		for grabber in ["grabber", "grabber_highlight", "grabber_pressed"]:
			theme.set_stylebox(grabber, "VScrollBar", thumb_v)
			theme.set_stylebox(grabber, "HScrollBar", thumb_h)
		theme.set_stylebox("scroll", "VScrollBar", track_v)
		theme.set_stylebox("scroll", "HScrollBar", track_h)

	# ---------- ProgressBar ----------
	if classic:
		theme.set_stylebox("background", "ProgressBar", _tex_box(s.classic_dir + "/controls/progress_background_9slice.png", 3, 0))
		theme.set_stylebox("fill", "ProgressBar", _tex_box(s.classic_dir + "/controls/progress_fill_9slice.png", 2, 0))
	else:
		var pb_bg := StyleBoxFlat.new()
		pb_bg.bg_color = s.tab_unselected_bg
		pb_bg.set_corner_radius_all(6)
		var pb_fill := StyleBoxFlat.new()
		pb_fill.bg_color = s.accent
		pb_fill.set_corner_radius_all(6)
		theme.set_stylebox("background", "ProgressBar", pb_bg)
		theme.set_stylebox("fill", "ProgressBar", pb_fill)

	return theme


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


## Styl przycisku. Trzy źródła wyglądu, w kolejności:
## klasyczne tekstury per stan -> tekstura ninepatch + modulacja -> płaski.
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
	else:
		var tex_path: String = s["btn_%s_tex" % kind]
		var margins: Array = s.get("btn_%s_margins" % kind, [24, 20])
		var states := {"normal": 1.0, "hover": 1.08, "pressed": 0.92, "disabled": 1.0, "focus": 1.0}
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
				sbf.set_corner_radius_all(9)
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

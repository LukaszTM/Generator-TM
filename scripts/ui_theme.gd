class_name UITheme
extends RefCounted
## Motywy graficzne aplikacji.
##
## Każdy motyw to "specyfikacja" (Dictionary) z kolorami, wariantem ikon
## i (opcjonalnie) ścieżkami tekstur przycisków. Oba motywy zbudowane są
## z pakietu assetów "TestPilot Studio" (wariant jasny i ciemny).
## Jak dodać własny motyw — patrz README, sekcja „Jak dodać własny motyw graficzny”.

const DEFAULT_THEME_ID := "testpilot_jasny"

# Ikony logiczne -> numer pliku w danym wariancie pakietu.
# (Warianty były cięte automatycznie, więc numeracja jasna i ciemna się różnią.)
const ICONS_LIGHT := {
	"logo": "001", "home": "002", "doc_new": "003", "doc_down": "004",
	"package": "005", "checklist": "006", "search": "007", "gear": "008",
	"folder": "010", "clipboard": "012", "globe": "013", "doc": "014",
	"form": "015", "shield": "016", "export": "019", "filter": "020",
	"pencil": "025", "link": "040",
}
const ICONS_DARK := {
	"logo": "001", "home": "005", "doc_new": "004", "doc_down": "002",
	"package": "006", "checklist": "003", "search": "007", "gear": "008",
	"folder": "010", "clipboard": "011", "globe": "014", "doc": "012",
	"form": "015", "shield": "016", "export": "013", "filter": "020",
	"pencil": "024", "link": "035",
}


## Lista dostępnych motywów: [{id, name}].
static func themes() -> Array[Dictionary]:
	return [
		{"id": "testpilot_jasny", "name": "TestPilot — jasny"},
		{"id": "testpilot_ciemny", "name": "TestPilot — ciemny"},
	]


## Ścieżka pliku ikony logicznej (np. "folder") w wariancie aktywnego motywu.
static func icon_path(theme_id: String, name: String) -> String:
	if spec(theme_id)["icon_variant"] == "dark":
		return "res://assets/dark/icons/testpilot_dark_icons_%s.png" % ICONS_DARK[name]
	return "res://assets/icons/testpilot_icons_%s.png" % ICONS_LIGHT[name]


## Specyfikacja motywu. Klucze tekstur (btn_*_tex) mogą być pustym stringiem —
## wtedy przycisk jest rysowany płasko z kolorów btn_*_bg / btn_*_border.
## btn_*_margins = [poziomy, pionowy] margines ninepatch tekstury.
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

	var font_regular: FontFile = load("res://fonts/Inter-Regular.otf")
	var font_medium: FontFile = load("res://fonts/Inter-Medium.otf")
	var font_semibold: FontFile = load("res://fonts/Inter-SemiBold.otf")
	var font_bold: FontFile = load("res://fonts/Inter-Bold.otf")

	theme.default_font = font_regular
	theme.default_font_size = 15

	# ---------- Przyciski ----------
	_setup_button(theme, "Button", s, "normal", font_medium)
	theme.set_type_variation(&"PrimaryButton", &"Button")
	_setup_button(theme, "PrimaryButton", s, "primary", font_semibold)
	theme.set_type_variation(&"DangerButton", &"Button")
	_setup_button(theme, "DangerButton", s, "danger", font_semibold)

	# ---------- Panele / karty ----------
	var card := StyleBoxFlat.new()
	card.bg_color = s.card
	card.set_corner_radius_all(10)
	card.border_color = s.border
	card.set_border_width_all(1)
	card.set_content_margin_all(16)
	theme.set_type_variation(&"Card", &"PanelContainer")
	theme.set_stylebox("panel", "Card", card)

	var header := StyleBoxFlat.new()
	header.bg_color = s.header
	header.set_content_margin_all(10)
	header.content_margin_left = 18
	header.content_margin_right = 18
	theme.set_type_variation(&"HeaderBar", &"PanelContainer")
	theme.set_stylebox("panel", "HeaderBar", header)

	var status := StyleBoxFlat.new()
	status.bg_color = s.status_bg
	status.set_content_margin_all(6)
	status.content_margin_left = 18
	theme.set_type_variation(&"StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", "StatusBar", status)

	# ---------- Etykiety ----------
	theme.set_color("font_color", "Label", s.text)
	theme.set_type_variation(&"TitleLabel", &"Label")
	theme.set_font("font", "TitleLabel", font_bold)
	theme.set_font_size("font_size", "TitleLabel", 20)
	theme.set_color("font_color", "TitleLabel", Color.WHITE)
	theme.set_type_variation(&"CardTitle", &"Label")
	theme.set_font("font", "CardTitle", font_semibold)
	theme.set_font_size("font_size", "CardTitle", 17)
	theme.set_color("font_color", "CardTitle", s.text)
	theme.set_type_variation(&"DimLabel", &"Label")
	theme.set_color("font_color", "DimLabel", s.text_dim)
	theme.set_font_size("font_size", "DimLabel", 13)

	# ---------- Pola tekstowe ----------
	var edit := StyleBoxFlat.new()
	edit.bg_color = s.field_bg
	edit.set_corner_radius_all(8)
	edit.border_color = s.border
	edit.set_border_width_all(1)
	edit.set_content_margin_all(8)
	edit.content_margin_left = 12
	edit.content_margin_right = 12
	var edit_focus := edit.duplicate()
	edit_focus.border_color = s.accent
	edit_focus.set_border_width_all(2)
	for cls in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", cls, edit)
		theme.set_stylebox("focus", cls, edit_focus)
		theme.set_color("font_color", cls, s.text)
	theme.set_color("font_placeholder_color", "LineEdit", Color(s.text_dim, 0.7))
	theme.set_color("font_placeholder_color", "TextEdit", Color(s.text_dim, 0.7))
	theme.set_color("caret_color", "LineEdit", s.text)
	theme.set_color("caret_color", "TextEdit", s.text)
	theme.set_stylebox("read_only", "TextEdit", edit)
	theme.set_color("font_readonly_color", "TextEdit", s.text)
	theme.set_font("font", "TextEdit", font_regular)
	theme.set_font_size("font_size", "TextEdit", 14)

	# ---------- Zakładki ----------
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
	theme.set_font_size("font_size", "TabContainer", 15)

	# ---------- Drzewo (listy) ----------
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
	theme.set_color("font_selected_color", "Tree", s.text)

	# ---------- CheckBox / OptionButton / ProgressBar ----------
	theme.set_color("font_color", "CheckBox", s.text)
	theme.set_color("font_color", "OptionButton", s.text)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = s.tab_unselected_bg
	pb_bg.set_corner_radius_all(6)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = s.accent
	pb_fill.set_corner_radius_all(6)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	return theme


## Styl przycisku: teksturowany (ninepatch z PNG), jeśli motyw podaje ścieżkę,
## w przeciwnym razie płaski z kolorów motywu.
static func _setup_button(theme: Theme, type_name: String, s: Dictionary, kind: String, font: FontFile) -> void:
	var tex_path: String = s["btn_%s_tex" % kind]
	var font_color: Color = s["btn_%s_font" % kind]
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

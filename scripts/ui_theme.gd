class_name UITheme
extends RefCounted
## Motywy graficzne aplikacji.
##
## Każdy motyw to "specyfikacja" (Dictionary) z kolorami i (opcjonalnie)
## ścieżkami tekstur przycisków. Aby dodać własny motyw z nowego pakietu
## assetów, wystarczy dopisać wpis w themes() oraz spec() — patrz README,
## sekcja „Jak dodać własny motyw graficzny”.

# --- Ikony wspólne dla wszystkich motywów (pakiet TestPilot Studio) ---
const ICON_LOGO := "res://assets/icons/testpilot_icons_001.png"      # schowek z checklistą
const ICON_HOME := "res://assets/icons/testpilot_icons_002.png"      # dom
const ICON_DOC_NEW := "res://assets/icons/testpilot_icons_003.png"   # dokument +
const ICON_DOC_DOWN := "res://assets/icons/testpilot_icons_004.png"  # dokument ze strzałką
const ICON_PACKAGE := "res://assets/icons/testpilot_icons_005.png"   # paczka / aplikacja
const ICON_CHECKLIST := "res://assets/icons/testpilot_icons_006.png" # lista z ptaszkami
const ICON_SEARCH := "res://assets/icons/testpilot_icons_007.png"    # lupa
const ICON_GEAR := "res://assets/icons/testpilot_icons_008.png"      # zębatka
const ICON_FOLDER := "res://assets/icons/testpilot_icons_010.png"    # folder
const ICON_CLIPBOARD := "res://assets/icons/testpilot_icons_012.png" # schowek check
const ICON_GLOBE := "res://assets/icons/testpilot_icons_013.png"     # glob / URL
const ICON_DOC := "res://assets/icons/testpilot_icons_014.png"       # dokument
const ICON_FORM := "res://assets/icons/testpilot_icons_015.png"      # formularz
const ICON_SHIELD := "res://assets/icons/testpilot_icons_016.png"    # tarcza
const ICON_EXPORT := "res://assets/icons/testpilot_icons_019.png"    # eksport / udostępnij
const ICON_FILTER := "res://assets/icons/testpilot_icons_020.png"    # lejek / filtr
const ICON_PENCIL := "res://assets/icons/testpilot_icons_025.png"    # ołówek
const ICON_LINK := "res://assets/icons/testpilot_icons_040.png"      # łańcuch / link

const DEFAULT_THEME_ID := "testpilot_jasny"


## Lista dostępnych motywów: [{id, name}].
static func themes() -> Array[Dictionary]:
	return [
		{"id": "testpilot_jasny", "name": "TestPilot — jasny"},
		{"id": "grafitowy_ciemny", "name": "Grafitowy — ciemny"},
	]


## Specyfikacja motywu. Klucze tekstur (btn_*_tex) mogą być pustym stringiem —
## wtedy przycisk jest rysowany płasko z kolorów btn_*_bg / btn_*_border.
static func spec(id: String) -> Dictionary:
	match id:
		"grafitowy_ciemny":
			return {
				"name": "Grafitowy — ciemny",
				"bg": Color("171b26"),
				"card": Color("1f2534"),
				"header": Color("141b3f"),
				"accent": Color("17b3ac"),
				"text": Color("e9edf6"),
				"text_dim": Color("98a2b8"),
				"border": Color("343d52"),
				"danger": Color("e5484d"),
				"field_bg": Color("161b28"),
				"tab_unselected_bg": Color("232a3c"),
				"tree_sel": Color("1f3a44"),
				"status_bg": Color("1c2233"),
				# Ciemny motyw nie używa tekstur — przyciski płaskie.
				"btn_normal_tex": "", "btn_normal_bg": Color("2a3247"), "btn_normal_border": Color("3d4763"), "btn_normal_font": Color("e9edf6"),
				"btn_primary_tex": "", "btn_primary_bg": Color("128f89"), "btn_primary_border": Color("17b3ac"), "btn_primary_font": Color.WHITE,
				"btn_danger_tex": "", "btn_danger_bg": Color("b02a31"), "btn_danger_border": Color("e5484d"), "btn_danger_font": Color.WHITE,
			}
		_:  # "testpilot_jasny" — motyw domyślny z pakietu TestPilot Studio
			return {
				"name": "TestPilot — jasny",
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
				"btn_normal_tex": "res://assets/buttons/testpilot_buttons_008.png", "btn_normal_bg": Color.WHITE, "btn_normal_border": Color("d7dfeb"), "btn_normal_font": Color("1d2433"),
				"btn_primary_tex": "res://assets/buttons/testpilot_buttons_002.png", "btn_primary_bg": Color("0e8f8f"), "btn_primary_border": Color("0e8f8f"), "btn_primary_font": Color.WHITE,
				"btn_danger_tex": "res://assets/buttons/testpilot_buttons_014.png", "btn_danger_bg": Color("d21f2e"), "btn_danger_border": Color("d21f2e"), "btn_danger_font": Color.WHITE,
			}


## Pojedynczy kolor z aktywnego motywu (np. UITheme.color(id, "accent")).
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
	var states := {"normal": 1.0, "hover": 1.08, "pressed": 0.92, "disabled": 1.0, "focus": 1.0}
	for state in states:
		var mod: float = states[state]
		var sb: StyleBox
		if tex_path != "":
			var sbt := StyleBoxTexture.new()
			sbt.texture = load(tex_path)
			# Marginesy ninepatch — rogi przycisków w pakiecie mają ok. 20 px promienia.
			sbt.texture_margin_left = 24
			sbt.texture_margin_right = 24
			sbt.texture_margin_top = 20
			sbt.texture_margin_bottom = 20
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

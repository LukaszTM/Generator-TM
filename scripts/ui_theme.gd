class_name UITheme
extends RefCounted
## Buduje motyw aplikacji na bazie pakietu assetów "TestPilot Studio"
## (czcionki Inter + wycięte elementy PNG: przyciski, ikony, styl okna).

const COLOR_BG := Color("f2f5fa")
const COLOR_CARD := Color("ffffff")
const COLOR_HEADER := Color("1a3fc4")
const COLOR_ACCENT := Color("0e8f8f")
const COLOR_TEXT := Color("1d2433")
const COLOR_TEXT_DIM := Color("5a6478")
const COLOR_BORDER := Color("d7dfeb")
const COLOR_DANGER := Color("d21f2e")

# Wybrane elementy z pakietu (patrz docs/asset_map/*.csv)
const TEX_BTN_TEAL := "res://assets/buttons/testpilot_buttons_002.png"
const TEX_BTN_WHITE := "res://assets/buttons/testpilot_buttons_008.png"
const TEX_BTN_RED := "res://assets/buttons/testpilot_buttons_014.png"

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


static func icon(path: String, size: int = 20) -> Texture2D:
	var tex: Texture2D = load(path)
	return tex


static func build() -> Theme:
	var theme := Theme.new()

	var font_regular: FontFile = load("res://fonts/Inter-Regular.otf")
	var font_medium: FontFile = load("res://fonts/Inter-Medium.otf")
	var font_semibold: FontFile = load("res://fonts/Inter-SemiBold.otf")
	var font_bold: FontFile = load("res://fonts/Inter-Bold.otf")

	theme.default_font = font_regular
	theme.default_font_size = 15

	# ---------- Przyciski (ninepatch z PNG pakietu) ----------
	_setup_button(theme, "Button", TEX_BTN_WHITE, COLOR_TEXT, font_medium)
	theme.set_type_variation(&"PrimaryButton", &"Button")
	_setup_button(theme, "PrimaryButton", TEX_BTN_TEAL, Color.WHITE, font_semibold)
	theme.set_type_variation(&"DangerButton", &"Button")
	_setup_button(theme, "DangerButton", TEX_BTN_RED, Color.WHITE, font_semibold)

	# ---------- Panele / karty ----------
	var card := StyleBoxFlat.new()
	card.bg_color = COLOR_CARD
	card.set_corner_radius_all(10)
	card.border_color = COLOR_BORDER
	card.set_border_width_all(1)
	card.set_content_margin_all(16)
	theme.set_type_variation(&"Card", &"PanelContainer")
	theme.set_stylebox("panel", "Card", card)

	var header := StyleBoxFlat.new()
	header.bg_color = COLOR_HEADER
	header.set_content_margin_all(10)
	header.content_margin_left = 18
	header.content_margin_right = 18
	theme.set_type_variation(&"HeaderBar", &"PanelContainer")
	theme.set_stylebox("panel", "HeaderBar", header)

	var status := StyleBoxFlat.new()
	status.bg_color = Color("e6ecf5")
	status.set_content_margin_all(6)
	status.content_margin_left = 18
	theme.set_type_variation(&"StatusBar", &"PanelContainer")
	theme.set_stylebox("panel", "StatusBar", status)

	# ---------- Etykiety ----------
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_type_variation(&"TitleLabel", &"Label")
	theme.set_font("font", "TitleLabel", font_bold)
	theme.set_font_size("font_size", "TitleLabel", 20)
	theme.set_color("font_color", "TitleLabel", Color.WHITE)
	theme.set_type_variation(&"CardTitle", &"Label")
	theme.set_font("font", "CardTitle", font_semibold)
	theme.set_font_size("font_size", "CardTitle", 17)
	theme.set_color("font_color", "CardTitle", COLOR_TEXT)
	theme.set_type_variation(&"DimLabel", &"Label")
	theme.set_color("font_color", "DimLabel", COLOR_TEXT_DIM)
	theme.set_font_size("font_size", "DimLabel", 13)

	# ---------- Pola tekstowe ----------
	var edit := StyleBoxFlat.new()
	edit.bg_color = Color.WHITE
	edit.set_corner_radius_all(8)
	edit.border_color = COLOR_BORDER
	edit.set_border_width_all(1)
	edit.set_content_margin_all(8)
	edit.content_margin_left = 12
	edit.content_margin_right = 12
	var edit_focus := edit.duplicate()
	edit_focus.border_color = COLOR_HEADER
	edit_focus.set_border_width_all(2)
	for cls in ["LineEdit", "TextEdit"]:
		theme.set_stylebox("normal", cls, edit)
		theme.set_stylebox("focus", cls, edit_focus)
		theme.set_color("font_color", cls, COLOR_TEXT)
	theme.set_stylebox("read_only", "TextEdit", edit)
	theme.set_color("font_readonly_color", "TextEdit", COLOR_TEXT)
	theme.set_font("font", "TextEdit", font_regular)
	theme.set_font_size("font_size", "TextEdit", 14)

	# ---------- Zakładki ----------
	var tab_panel := StyleBoxFlat.new()
	tab_panel.bg_color = COLOR_CARD
	tab_panel.border_color = COLOR_BORDER
	tab_panel.set_border_width_all(1)
	tab_panel.set_corner_radius_all(8)
	tab_panel.corner_radius_top_left = 0
	tab_panel.set_content_margin_all(14)
	theme.set_stylebox("panel", "TabContainer", tab_panel)

	var tab_sel := StyleBoxFlat.new()
	tab_sel.bg_color = COLOR_CARD
	tab_sel.border_color = COLOR_BORDER
	tab_sel.border_width_left = 1
	tab_sel.border_width_right = 1
	tab_sel.border_width_top = 3
	tab_sel.border_color = COLOR_BORDER
	tab_sel.corner_radius_top_left = 8
	tab_sel.corner_radius_top_right = 8
	tab_sel.set_content_margin_all(10)
	tab_sel.content_margin_left = 16
	tab_sel.content_margin_right = 16
	var tab_sel2 := tab_sel.duplicate()
	tab_sel2.border_color = COLOR_ACCENT
	var tab_un := tab_sel.duplicate()
	tab_un.bg_color = Color("e2e9f3")
	tab_un.border_width_top = 1
	theme.set_stylebox("tab_selected", "TabContainer", tab_sel2)
	theme.set_stylebox("tab_unselected", "TabContainer", tab_un)
	theme.set_stylebox("tab_hovered", "TabContainer", tab_un)
	theme.set_color("font_selected_color", "TabContainer", COLOR_TEXT)
	theme.set_color("font_unselected_color", "TabContainer", COLOR_TEXT_DIM)
	theme.set_font("font", "TabContainer", font_medium)
	theme.set_font_size("font_size", "TabContainer", 15)

	# ---------- Drzewo (lista modułów / przypadków) ----------
	var tree_bg := StyleBoxFlat.new()
	tree_bg.bg_color = Color.WHITE
	tree_bg.border_color = COLOR_BORDER
	tree_bg.set_border_width_all(1)
	tree_bg.set_corner_radius_all(8)
	tree_bg.set_content_margin_all(6)
	theme.set_stylebox("panel", "Tree", tree_bg)
	theme.set_color("font_color", "Tree", COLOR_TEXT)
	var tree_sel := StyleBoxFlat.new()
	tree_sel.bg_color = Color("d9ecec")
	theme.set_stylebox("selected", "Tree", tree_sel)
	theme.set_stylebox("selected_focus", "Tree", tree_sel)
	theme.set_color("font_selected_color", "Tree", COLOR_TEXT)

	# ---------- CheckBox / ProgressBar ----------
	theme.set_color("font_color", "CheckBox", COLOR_TEXT)
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color("dfe6f0")
	pb_bg.set_corner_radius_all(6)
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = COLOR_ACCENT
	pb_fill.set_corner_radius_all(6)
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	return theme


static func _setup_button(theme: Theme, type_name: String, tex_path: String, font_color: Color, font: FontFile) -> void:
	var tex: Texture2D = load(tex_path)
	var states := {
		"normal": 1.0,
		"hover": 1.08,
		"pressed": 0.92,
		"disabled": 1.0,
		"focus": 1.0,
	}
	for state in states:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		# Marginesy ninepatch — rogi przycisków w pakiecie mają ok. 20 px promienia.
		sb.texture_margin_left = 24
		sb.texture_margin_right = 24
		sb.texture_margin_top = 20
		sb.texture_margin_bottom = 20
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		var mod: float = states[state]
		sb.modulate_color = Color(mod, mod, mod, 0.45 if state == "disabled" else 1.0)
		theme.set_stylebox(state, type_name, sb)
	theme.set_font("font", type_name, font)
	theme.set_color("font_color", type_name, font_color)
	theme.set_color("font_hover_color", type_name, font_color)
	theme.set_color("font_pressed_color", type_name, font_color)
	theme.set_color("font_focus_color", type_name, font_color)
	theme.set_color("font_disabled_color", type_name, Color(font_color, 0.5))
	theme.set_constant("h_separation", type_name, 8)

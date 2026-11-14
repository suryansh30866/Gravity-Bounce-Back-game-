extends Control

const PLAY_SCENE := "res://scenes/game.tscn"
const BACKDROP_SCRIPT := preload("res://scripts/lunar_backdrop.gd")

var _mission_cards: Array[PanelContainer] = []

func _ready() -> void:
	_build_screen()
	_play_intro()

func _build_screen() -> void:
	var backdrop := BACKDROP_SCRIPT.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 42.0
	header.offset_top = 24.0
	header.offset_right = -42.0
	header.offset_bottom = 59.0
	add_child(header)
	var brand := _label("Gravity", 21, Color("e4e7df"))
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_font_override("font", _serif())
	header.add_child(brand)
	var mission_tag := _label("LUNAR EXPEDITION     /     MARE TRANQUILLITATIS", 10, Color("b3c2bf"))
	mission_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(mission_tag)

	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	content.anchor_top = 0.28
	content.anchor_bottom = 0.74
	content.offset_left = 58.0
	content.offset_top = 0.0
	content.offset_right = 602.0
	content.offset_bottom = 0.0
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	var overline := _label("SURFACE OPERATIONS     /     DAY 03", 10, Color("86aaa6"))
	overline.add_theme_constant_override("letter_spacing", 2)
	content.add_child(overline)
	var title := _label("Gravity", 82, Color("f2f0e8"))
	title.add_theme_font_override("font", _serif())
	title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.56))
	title.add_theme_constant_override("shadow_offset_y", 3)
	content.add_child(title)
	var subhead := _label("Repair your ship. Find your way home.", 18, Color("cbd2cc"))
	content.add_child(subhead)
	var description := _label("Search the lunar surface for lost parts.\nFollow your commander's advice and rebuild the return ship.", 13, Color("a9b5b2"))
	description.add_theme_constant_override("line_spacing", 4)
	content.add_child(description)
	var spacing := Control.new()
	spacing.custom_minimum_size.y = 3.0
	content.add_child(spacing)
	content.add_child(_new_game_button())

	var conditions := HBoxContainer.new()
	conditions.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	conditions.offset_left = 58.0
	conditions.offset_top = -169.0
	conditions.offset_right = 540.0
	conditions.offset_bottom = -137.0
	conditions.add_theme_constant_override("separation", 26)
	add_child(conditions)
	for info in [["1.62", "M / S² MOON GRAVITY"], ["NO", "ATMOSPHERE"], ["−173°", "NIGHT SIDE" ]]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)
		conditions.add_child(column)
		var value := _label(info[0], 17, Color("e7e6dc"))
		column.add_child(value)
		var caption := _label(info[1], 8, Color("88a09e"))
		column.add_child(caption)

	var location := _panel(Color(0.025, 0.044, 0.056, 0.67), Color(0.59, 0.75, 0.72, 0.28))
	location.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	location.anchor_top = 0.52
	location.anchor_bottom = 0.68
	location.offset_left = -390.0
	location.offset_top = 0.0
	location.offset_right = -48.0
	location.offset_bottom = 0.0
	add_child(location)
	var location_copy := VBoxContainer.new()
	location_copy.add_theme_constant_override("separation", 7)
	location.add_child(location_copy)
	var location_overline := _label("LANDING SITE     /     COORDINATES", 9, Color("83a6a3"))
	location_copy.add_child(location_overline)
	var location_title := _label("Mare Tranquillitatis", 18, Color("e4e5dd"))
	location_title.add_theme_font_override("font", _serif())
	location_copy.add_child(location_title)
	var coordinates := _label("8.5° N     31.4° E\nImpact ejecta  /  basalt plain  /  skylight", 10, Color("aab9b3"))
	coordinates.add_theme_constant_override("line_spacing", 4)
	location_copy.add_child(coordinates)

	var controls := _label("W A S D  MOVE   /   MOUSE  LOOK   /   SPACE  JUMP   /   E  USE   /   I  PACK   /   H  HINT", 9, Color("93a7a3"))
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	controls.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	controls.position = Vector2(-48.0, -166.0)
	controls.size = Vector2(560.0, 20.0)
	add_child(controls)

	_add_mission_cards()

func _add_mission_cards() -> void:
	var rail := HBoxContainer.new()
	rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rail.offset_left = 40.0
	rail.offset_top = -122.0
	rail.offset_right = -40.0
	rail.offset_bottom = -21.0
	rail.add_theme_constant_override("separation", 14)
	add_child(rail)
	var missions := [
		["01", "FIND THE SHIP", "Reach the damaged return ship."],
		["02", "COLLECT PARTS", "Search for parts and connectors."],
		["03", "REPAIR THE SHIP", "Reconnect cables and systems."],
		["04", "FLY TO EARTH", "Launch the ship and go home."],
	]
	for mission in missions:
		var card := _panel(Color(0.025, 0.044, 0.056, 0.76), Color(0.6, 0.73, 0.69, 0.24))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rail.add_child(card)
		_mission_cards.append(card)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 4)
		card.add_child(copy)
		copy.add_child(_label(mission[0], 10, Color("8ac1b4")))
		var title := _label(mission[1], 10, Color("e0e3dc"))
		copy.add_child(title)
		var detail := _label(mission[2], 9, Color("a7b4ae"))
		copy.add_child(detail)

func _new_game_button() -> Button:
	var button := Button.new()
	button.text = "START REPAIR MISSION       ↗"
	button.custom_minimum_size = Vector2(252.0, 52.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("071310"))
	button.add_theme_color_override("font_hover_color", Color("05100f"))
	button.add_theme_stylebox_override("normal", _button_style(Color("a6d1c1")))
	button.add_theme_stylebox_override("hover", _button_style(Color("c0e2d1")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("81b4a6")))
	button.pressed.connect(_start_game)
	return button

func _start_game() -> void:
	get_tree().change_scene_to_file(PLAY_SCENE)

func _play_intro() -> void:
	for child in get_children():
		if child is Control and child != get_child(0):
			child.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_interval(0.15)
			tween.tween_property(child, "modulate:a", 1.0, 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _serif() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	return font

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.48))
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _panel(background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(0.78, 0.9, 0.82, 0.7)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

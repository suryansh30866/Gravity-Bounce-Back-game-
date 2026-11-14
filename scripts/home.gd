extends Control

const PLAY_SCENE := "res://scenes/game.tscn"
const HERO_IMAGE := preload("res://assets/gravity_hero.webp")
const INK := Color("17160f")
const PAPER := Color("f7f5ef")
const MIST := Color("ffffff")

var _hero: TextureRect
var _hero_video: VideoStreamPlayer
var _rotating_word: Label
var _word_index := 0
const HERO_WORDS := ["Explores", "Survives", "Discovers", "Returns", "Endures"]

const SPHERE_SHIMMER := """
shader_type canvas_item;
void fragment() {
	vec2 sphere_uv = UV - vec2(0.505, 0.505);
	sphere_uv.x *= 1.7778;
	float radius = length(sphere_uv);
	float inside_sphere = 1.0 - smoothstep(0.215, 0.225, radius);
	float rim = smoothstep(0.185, 0.215, radius) * inside_sphere;
	vec4 color = texture(TEXTURE, UV);
	vec2 glint_position = vec2(-0.035 + sin(TIME * 0.32) * 0.045, 0.105 + cos(TIME * 0.24) * 0.025);
	float glint = exp(-dot((sphere_uv - glint_position) * vec2(15.0, 22.0), (sphere_uv - glint_position) * vec2(15.0, 22.0)));
	float shimmer = 0.5 + 0.5 * sin(TIME * 1.4 + sphere_uv.x * 26.0 + sphere_uv.y * 18.0);
	color.rgb += vec3(0.30, 0.52, 0.54) * inside_sphere * glint * 0.18;
	color.rgb += vec3(0.40, 0.68, 0.67) * inside_sphere * rim * (0.025 + shimmer * 0.025);
	COLOR = color;
}
"""

func _ready() -> void:
	_build_screen()
	_play_intro()

func _build_screen() -> void:
	_hero = TextureRect.new()
	_hero.texture = HERO_IMAGE
	_hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_hero.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shimmer := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SPHERE_SHIMMER
	shimmer.shader = shader
	_hero.material = shimmer
	_hero.scale = Vector2(1.035, 1.035)
	_hero.pivot_offset = get_viewport_rect().size * 0.5
	add_child(_hero)
	_hero.resized.connect(func(): _hero.pivot_offset = _hero.size * 0.5)

	_hero_video = VideoStreamPlayer.new()
	_hero_video.stream = load("res://assets/baty_hero.ogv") as VideoStreamTheora
	_hero_video.expand = true
	_hero_video.loop = true
	_hero_video.volume_db = -80.0
	_hero_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_hero_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hero_video.modulate.a = 0.0
	_hero_video.scale = Vector2(1.035, 1.035)
	_hero_video.pivot_offset = get_viewport_rect().size * 0.5
	add_child(_hero_video)
	_hero_video.resized.connect(func(): _hero_video.pivot_offset = _hero_video.size * 0.5)
	_hero_video.play()

	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.95, 0.94, 0.90, 0.16)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	_add_header()
	_add_title_and_button()
	_add_mission_cards()

func _add_header() -> void:
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = 42
	header.offset_top = 22
	header.offset_right = -42
	header.offset_bottom = 62
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(header)

	var brand := _label("Gravity", 22, INK)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_theme_constant_override("outline_size", 0)
	header.add_child(brand)

	var mission_tag := _label("LUNAR EXPEDITION     /     01", 11, Color("333a39"))
	mission_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(mission_tag)

func _add_title_and_button() -> void:
	var content := VBoxContainer.new()
	content.set_anchors_preset(Control.PRESET_CENTER)
	content.offset_left = -310
	content.offset_top = -165
	content.offset_right = 310
	content.offset_bottom = 200
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 6)
	add_child(content)

	var title := _label("Gravity", 82, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color(0.98, 0.97, 0.93, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	title.add_theme_font_override("font", serif)
	content.add_child(title)

	_rotating_word = _label(HERO_WORDS[0], 74, INK)
	_rotating_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rotating_word.add_theme_font_override("font", serif)
	_rotating_word.add_theme_color_override("font_shadow_color", Color(0.98, 0.97, 0.93, 0.5))
	_rotating_word.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(_rotating_word)

	var overline := _label("A MOON-SURFACE SURVIVAL MISSION", 10, Color("37382f"))
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overline.add_theme_constant_override("letter_spacing", 2)
	content.add_child(overline)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	content.add_child(spacer)

	var description := _label("Stranded beneath a silent sky,\ncomplete your mission and find a way home.", 16, Color("292d2b"))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.8))
	description.add_theme_constant_override("shadow_offset_y", 1)
	content.add_child(description)

	var button_space := Control.new()
	button_space.custom_minimum_size.y = 8
	content.add_child(button_space)

	var new_game := _new_game_button()
	content.add_child(new_game)

	var word_timer := Timer.new()
	word_timer.wait_time = 3.0
	word_timer.timeout.connect(_advance_word)
	add_child(word_timer)
	word_timer.start()

func _advance_word() -> void:
	var fade_out := create_tween()
	fade_out.set_parallel(true)
	fade_out.tween_property(_rotating_word, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fade_out.tween_property(_rotating_word, "scale", Vector2(1.0, 0.74), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await fade_out.finished
	_word_index = (_word_index + 1) % HERO_WORDS.size()
	_rotating_word.text = HERO_WORDS[_word_index]
	var fade_in := create_tween()
	fade_in.set_parallel(true)
	fade_in.tween_property(_rotating_word, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(_rotating_word, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _add_mission_cards() -> void:
	var rail := HBoxContainer.new()
	rail.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rail.offset_left = 36
	rail.offset_top = -150
	rail.offset_right = -36
	rail.offset_bottom = -24
	rail.add_theme_constant_override("separation", 18)
	add_child(rail)
	var missions := [
		["01", "REACH THE LANDER", "Find your route across the lunar plain."],
		["02", "RESTORE POWER", "Bring the stranded systems back online."],
		["03", "SEND THE SIGNAL", "Re-establish contact with mission control."],
		["04", "MAKE IT HOME", "Complete the mission and return safely."],
	]
	for index in range(missions.size()):
		var mission: Array = missions[index]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", _mission_card_style())
		rail.add_child(card)
		card.modulate.a = 0.0
		var card_tween := create_tween()
		card_tween.tween_interval(0.45 + index * 0.12)
		card_tween.tween_property(card, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		var copy := VBoxContainer.new()
		copy.add_theme_constant_override("separation", 5)
		card.add_child(copy)
		var number := _label(mission[0], 12, Color("39413e"))
		copy.add_child(number)
		var mission_title := _label(mission[1], 12, INK)
		mission_title.add_theme_font_size_override("font_size", 11)
		copy.add_child(mission_title)
		var detail := _label(mission[2], 12, Color("454943"))
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
		copy.add_child(detail)

func _mission_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.98, 0.97, 0.94, 0.66)
	style.border_color = Color(0.23, 0.22, 0.18, 0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.18))
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _new_game_button() -> Button:
	var button := Button.new()
	button.text = "NEW GAME     ↗"
	button.custom_minimum_size = Vector2(224, 54)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", PAPER)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color("182a2b")))
	button.add_theme_stylebox_override("hover", _button_style(Color("264647")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("101d1f")))
	button.pressed.connect(_start_game)
	return button

func _button_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color(1.0, 1.0, 1.0, 0.55)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

func _play_intro() -> void:
	_hero.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hero, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hero, "scale", Vector2(1.08, 1.08), 18.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_hero_video, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_hero_video, "scale", Vector2(1.08, 1.08), 18.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var children := get_children()
	for child in children:
		if child is Control and child != _hero and child != _hero_video:
			child.modulate.a = 0.0
			tween.tween_property(child, "modulate:a", 1.0, 0.9).set_delay(0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _start_game() -> void:
	get_tree().change_scene_to_file(PLAY_SCENE)

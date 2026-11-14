extends Control

const PLAY_SCENE := "res://scenes/game.tscn"
const HERO_IMAGE := preload("res://assets/gravity_hero.webp")
const INK := Color("17160f")
const PAPER := Color("f7f5ef")
const MIST := Color("ffffff")

var _hero: TextureRect
var _hero_video: VideoStreamPlayer
var _video_layer: TextureRect
var _video_material: ShaderMaterial
var _rotating_word: Label
var _mission_track: VBoxContainer
var _hero_cycle_timer: Timer
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

const HERO_MORPH_SHADER := """
shader_type canvas_item;
uniform sampler2D previous_frame : filter_linear, repeat_disable;
uniform float u_progress = 1.0;
uniform float u_mode = 0.0;
uniform float u_grid = 40.0;
uniform float u_wave_width = 0.48;
uniform float u_distortion = 0.024;

void fragment() {
	vec2 uv = UV;
	float wave_pos = 1.0 - uv.y;
	float wave = 1.0 - smoothstep(u_progress - u_wave_width, u_progress, wave_pos);
	float distance_from_wave = abs(wave_pos - u_progress);
	float pixelate = 1.0 - smoothstep(0.0, u_wave_width, distance_from_wave);
	if (u_progress <= 0.001 || u_progress >= 0.999) {
		pixelate = 0.0;
	}
	vec2 pixel_uv = floor(uv * u_grid) / u_grid;
	vec2 distorted_uv = mix(uv, pixel_uv, pixelate);
	distorted_uv += pixelate * u_distortion * vec2(
		sin(uv.y * 25.0 + u_progress * 6.28318),
		cos(uv.x * 25.0 + u_progress * 6.28318)
	);
	vec2 safe_uv = clamp(uv, vec2(0.0), vec2(1.0));
	vec2 safe_distorted_uv = clamp(distorted_uv, vec2(0.0), vec2(1.0));
	vec4 old_clean = texture(previous_frame, safe_uv);
	vec4 new_clean = texture(TEXTURE, safe_uv);
	vec4 old_pixelated = texture(previous_frame, safe_distorted_uv);
	vec4 new_pixelated = texture(TEXTURE, safe_distorted_uv);
	vec4 old_color = mix(old_clean, old_pixelated, pixelate);
	vec4 new_color = mix(new_clean, new_pixelated, pixelate);
	COLOR = u_mode > 0.5 ? mix(old_color, new_color, wave) : new_color;
}
"""

func _ready() -> void:
	_build_screen()
	_play_intro()
	await get_tree().create_timer(0.15).timeout
	_start_hero_morph(HERO_IMAGE, 2.0)

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

	_video_layer = TextureRect.new()
	_video_layer.texture = _hero_video.get_video_texture()
	_video_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_video_layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_video_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var morph_shader := Shader.new()
	morph_shader.code = HERO_MORPH_SHADER
	_video_material = ShaderMaterial.new()
	_video_material.shader = morph_shader
	_video_material.set_shader_parameter("previous_frame", HERO_IMAGE)
	_video_material.set_shader_parameter("u_mode", 1.0)
	_video_material.set_shader_parameter("u_progress", 0.0)
	_video_layer.material = _video_material
	_video_layer.pivot_offset = get_viewport_rect().size * 0.5
	add_child(_video_layer)
	_video_layer.resized.connect(func(): _video_layer.pivot_offset = _video_layer.size * 0.5)

	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.95, 0.94, 0.90, 0.16)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	_add_header()
	_add_title_and_button()
	_add_mission_cards()
	_hero_cycle_timer = Timer.new()
	_hero_cycle_timer.wait_time = 3.0
	_hero_cycle_timer.timeout.connect(_advance_hero_sequence)
	add_child(_hero_cycle_timer)
	_hero_cycle_timer.start()

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
	var panel_width := minf(510.0, get_viewport_rect().size.x * 0.42)
	var right_edge_offset := get_viewport_rect().size.x * 0.44
	content.offset_left = right_edge_offset - panel_width
	content.offset_top = -165
	content.offset_right = right_edge_offset
	content.offset_bottom = 200
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 6)
	add_child(content)

	var title := _label("Gravity", 82, INK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title.add_theme_color_override("font_shadow_color", Color(0.98, 0.97, 0.93, 0.5))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 2)
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	title.add_theme_font_override("font", serif)
	content.add_child(title)

	_rotating_word = _label(HERO_WORDS[0], 74, INK)
	_rotating_word.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rotating_word.add_theme_font_override("font", serif)
	_rotating_word.add_theme_color_override("font_shadow_color", Color(0.98, 0.97, 0.93, 0.5))
	_rotating_word.add_theme_constant_override("shadow_offset_y", 2)
	content.add_child(_rotating_word)

	var overline := _label("A MOON-SURFACE SURVIVAL MISSION", 10, Color("37382f"))
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	overline.add_theme_constant_override("letter_spacing", 2)
	content.add_child(overline)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 6
	content.add_child(spacer)

	var description := _label("Stranded beneath a silent sky,\ncomplete your mission and find a way home.", 16, Color("292d2b"))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	description.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.8))
	description.add_theme_constant_override("shadow_offset_y", 1)
	content.add_child(description)

	var new_game := _new_game_button()
	new_game.set_anchors_preset(Control.PRESET_CENTER)
	new_game.offset_left = -82.0
	new_game.offset_right = 122.0
	var button_center_y := get_viewport_rect().size.y * 0.90
	new_game.offset_top = button_center_y - get_viewport_rect().size.y * 0.5 - 27.0
	new_game.offset_bottom = button_center_y - get_viewport_rect().size.y * 0.5 + 27.0
	add_child(new_game)

func _advance_hero_sequence() -> void:
	# Baty changes the headline and advances its vertical card rail on the same beat.
	var previous_frame: Texture2D = HERO_IMAGE
	var current_video_texture := _video_layer.texture
	if current_video_texture != null:
		var frame_image := current_video_texture.get_image()
		if frame_image != null and not frame_image.is_empty():
			frame_image.resize(640, 360, Image.INTERPOLATE_LANCZOS)
			previous_frame = ImageTexture.create_from_image(frame_image)
	_start_hero_morph(previous_frame, 1.2)

	var first_card := _mission_track.get_child(0) as Control
	var card_step: float = first_card.custom_minimum_size.y + 12.0
	var card_motion := create_tween()
	card_motion.tween_property(_mission_track, "position:y", -card_step, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	var word_out := create_tween()
	word_out.set_parallel(true)
	word_out.tween_property(_rotating_word, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	word_out.tween_property(_rotating_word, "scale", Vector2(1.0, 0.74), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await word_out.finished
	_word_index = (_word_index + 1) % HERO_WORDS.size()
	_rotating_word.text = HERO_WORDS[_word_index]
	var word_in := create_tween()
	word_in.set_parallel(true)
	word_in.tween_property(_rotating_word, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	word_in.tween_property(_rotating_word, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await card_motion.finished
	_mission_track.move_child(_mission_track.get_child(0), _mission_track.get_child_count() - 1)
	_mission_track.position.y = 0.0

func _start_hero_morph(previous_frame: Texture2D, duration: float) -> void:
	_video_material.set_shader_parameter("previous_frame", previous_frame)
	_video_material.set_shader_parameter("u_mode", 1.0)
	_video_material.set_shader_parameter("u_progress", 0.0)
	var transition := create_tween()
	transition.tween_method(
		func(value: float) -> void: _video_material.set_shader_parameter("u_progress", value),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	transition.tween_callback(func() -> void: _video_material.set_shader_parameter("u_mode", 0.0))

func _add_mission_cards() -> void:
	var rail := Control.new()
	rail.position = Vector2(40.0, 120.0)
	rail.size = Vector2(240.0, maxf(460.0, get_viewport_rect().size.y - 144.0))
	rail.clip_contents = true
	rail.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(rail)
	_mission_track = VBoxContainer.new()
	_mission_track.position = Vector2.ZERO
	_mission_track.size = Vector2(240.0, rail.size.y * 2.0)
	_mission_track.add_theme_constant_override("separation", 12)
	rail.add_child(_mission_track)
	var card_height := (rail.size.y - 36.0) / 4.0
	var missions := [
		["01", "REACH THE LANDER", "Find your route across the lunar plain."],
		["02", "RESTORE POWER", "Bring the stranded systems back online."],
		["03", "SEND THE SIGNAL", "Re-establish contact with mission control."],
		["04", "MAKE IT HOME", "Complete the mission and return safely."],
	]
	for index in range(missions.size()):
		var mission: Array = missions[index]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(240.0, card_height)
		card.add_theme_stylebox_override("panel", _mission_card_style())
		_mission_track.add_child(card)
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
	button.text = "NEW GAME"
	button.custom_minimum_size = Vector2(204, 56)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", Color("111a18"))
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	var button_font := SystemFont.new()
	button_font.font_names = PackedStringArray(["Aptos", "Segoe UI"])
	button_font.font_weight = 600
	button.add_theme_font_override("font", button_font)
	button.add_theme_constant_override("letter_spacing", 1)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.98, 0.97, 0.94, 0.72), Color(0.23, 0.22, 0.18, 0.18)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.99, 0.98, 0.96, 0.90), Color(0.23, 0.22, 0.18, 0.38)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.90, 0.94, 0.91, 0.94), Color(0.23, 0.38, 0.35, 0.50)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.99, 0.98, 0.96, 0.90), Color(0.23, 0.38, 0.35, 0.50)))
	button.resized.connect(func(): button.pivot_offset = button.size * 0.5)
	button.mouse_entered.connect(func(): _animate_button_scale(button, Vector2(1.025, 1.025), 0.18))
	button.mouse_exited.connect(func(): _animate_button_scale(button, Vector2.ONE, 0.18))
	button.button_down.connect(func(): _animate_button_scale(button, Vector2(0.985, 0.985), 0.08))
	button.button_up.connect(func(): _animate_button_scale(button, Vector2(1.025, 1.025), 0.12))
	button.pressed.connect(_start_game)
	return button

func _animate_button_scale(button: Button, target: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(button, "scale", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _button_style(fill: Color, edge: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0.08, 0.12, 0.10, 0.12)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _play_intro() -> void:
	_hero.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_hero, "modulate:a", 1.0, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_hero, "scale", Vector2(1.08, 1.08), 18.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_video_layer, "scale", Vector2(1.08, 1.08), 18.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var children := get_children()
	for child in children:
		if child is Control and child != _hero and child != _hero_video and child != _video_layer:
			child.modulate.a = 0.0
			tween.tween_property(child, "modulate:a", 1.0, 0.9).set_delay(0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _start_game() -> void:
	get_tree().change_scene_to_file(PLAY_SCENE)

extends Node3D

const HOME_SCENE := "res://scenes/home.tscn"
const TERRAIN_SCRIPT := preload("res://scripts/lunar_terrain.gd")
const PLAYER_SCRIPT := preload("res://scripts/astronaut.gd")
const LUNAR_GRAVITY := 1.62

var terrain: LunarTerrain
var astronaut: LunarAstronaut
var habitat_position := Vector3.ZERO
var lander_position := Vector3.ZERO
var terminal_position := Vector3.ZERO
var relay_position := Vector3.ZERO
var mission_stage := 0
var mission_time := 0.0
var _message_time := 0.0
var _ui: CanvasLayer
var _objective_label: Label
var _detail_label: Label
var _distance_label: Label
var _interaction_label: Label
var _message_label: Label
var _timer_label: Label
var _boost_bar: ProgressBar
var _progress_labels: Array[Label] = []
var _marker: Node3D
var _marker_target := Vector3.ZERO
var _complete_panel: PanelContainer

const STAGE_TITLES := [
	"REACH THE LUNAR LANDER",
	"RESTORE LANDER POWER",
	"SEND A DISTRESS SIGNAL",
	"RETURN TO THE HABITAT",
	"MISSION COMPLETE",
]
const STAGE_DETAILS := [
	"Follow the ridge lights across Mare Tranquillitatis.",
	"The lander is dark. Bring its surface systems online.",
	"Climb to the relay and contact mission control.",
	"Make your way back to the habitat before the next night.",
	"Signal received. Crew extraction is on its way.",
]

func _ready() -> void:
	_build_environment()
	terrain = TERRAIN_SCRIPT.new()
	terrain.name = "Lunar geology"
	add_child(terrain)
	_build_landmarks()
	_build_player()
	_build_world_marker()
	_build_hud()
	_update_objective()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	mission_time += delta
	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_message_label.modulate.a = 0.0
	if is_instance_valid(_marker):
		_marker.rotation.y += delta * 0.75
		_marker.global_position = _marker_target + Vector3.UP * (2.5 + sin(Time.get_ticks_msec() * 0.0017) * 0.22)
	_update_mission()
	_update_hud()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.009, 0.019)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.39, 0.49)
	environment.ambient_light_energy = 0.26
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.38
	environment.glow_bloom = 0.06
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Hard sunlight"
	sun.rotation_degrees = Vector3(-49.0, -31.0, 0.0)
	sun.light_color = Color(1.0, 0.96, 0.86)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 240.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)
	_add_starfield()
	_add_earth()

func _add_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.11
	star_mesh.height = 0.22
	star_mesh.radial_segments = 5
	star_mesh.rings = 3
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.78, 0.86, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.34, 0.46, 0.78)
	material.emission_energy_multiplier = 0.42
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = star_mesh
	multi.instance_count = 290
	var rng := RandomNumberGenerator.new()
	rng.seed = 454001
	for index in range(multi.instance_count):
		var angle := rng.randf_range(0.0, TAU)
		var elevation := rng.randf_range(0.08, 1.25)
		var radius := rng.randf_range(175.0, 240.0)
		var position := Vector3(cos(angle) * cos(elevation) * radius, sin(elevation) * radius + 10.0, sin(angle) * cos(elevation) * radius)
		var scale := rng.randf_range(0.45, 1.5)
		multi.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ONE * scale), position))
	var stars := MultiMeshInstance3D.new()
	stars.name = "Stars"
	stars.multimesh = multi
	stars.material_override = material
	add_child(stars)

func _add_earth() -> void:
	var earth_mesh := SphereMesh.new()
	earth_mesh.radius = 8.0
	earth_mesh.height = 16.0
	earth_mesh.radial_segments = 48
	earth_mesh.rings = 24
	var earth_material := StandardMaterial3D.new()
	earth_material.albedo_color = Color(0.075, 0.2, 0.43)
	earth_material.roughness = 0.92
	earth_material.emission_enabled = true
	earth_material.emission = Color(0.055, 0.15, 0.32)
	earth_material.emission_energy_multiplier = 0.18
	var earth := MeshInstance3D.new()
	earth.name = "Earthrise"
	earth.mesh = earth_mesh
	earth.material_override = earth_material
	earth.position = Vector3(-82.0, 50.0, -135.0)
	add_child(earth)
	var halo := OmniLight3D.new()
	halo.light_color = Color(0.15, 0.35, 0.78)
	halo.light_energy = 5.5
	halo.omni_range = 22.0
	halo.position = earth.position
	add_child(halo)

func _build_landmarks() -> void:
	habitat_position = _ground_point(Vector2(-2.0, 11.0))
	lander_position = _ground_point(Vector2(21.0, -12.0))
	terminal_position = _ground_point(Vector2(23.0, -10.0))
	relay_position = _ground_point(Vector2(-40.0, -46.0))
	_build_habitat(habitat_position)
	_build_lander(lander_position)
	_build_power_terminal(terminal_position)
	_build_signal_relay(relay_position)
	_add_beacon_lights()

func _build_player() -> void:
	astronaut = PLAYER_SCRIPT.new()
	astronaut.name = "Player"
	astronaut.position = habitat_position + Vector3(0.0, 0.16, 5.2)
	add_child(astronaut)
	astronaut.interact_pressed.connect(_on_interact_pressed)

func _ground_point(point: Vector2) -> Vector3:
	return Vector3(point.x, terrain.height_at(point.x, point.y), point.y)

func _build_habitat(center: Vector3) -> void:
	var shell := _material(Color(0.73, 0.75, 0.72), 0.76)
	var dark := _material(Color(0.09, 0.17, 0.22), 0.43)
	var accent := _material(Color(0.85, 0.43, 0.17), 0.62)
	var glow := _emissive(Color(0.2, 0.83, 0.91))
	_add_cylinder("Habitat pressure module", center + Vector3(0.0, 1.8, 0.0), 2.05, 3.5, shell, 16)
	_add_cylinder("Airlock ring", center + Vector3(0.0, 1.1, -1.6), 1.15, 0.38, dark, 16)
	_add_box("Airlock entrance", center + Vector3(0.0, 1.1, -1.86), Vector3(1.3, 1.8, 0.18), shell)
	_add_box("Airlock access light", center + Vector3(0.0, 2.08, -2.0), Vector3(0.78, 0.12, 0.05), glow)
	_add_cylinder("Habitat roof cap", center + Vector3(0.0, 3.65, 0.0), 1.62, 0.3, accent, 14)
	_add_box("Mission mark", center + Vector3(0.0, 2.75, -1.76), Vector3(0.34, 0.35, 0.07), dark)
	for side in [-1.0, 1.0]:
		var panel_center := center + Vector3(side * 5.2, 2.55, 0.1)
		_add_box("Habitat solar blanket", panel_center, Vector3(3.4, 0.13, 2.45), dark)
		for row in range(4):
			_add_box("Solar cell seam", panel_center + Vector3(0.0, 0.08, -0.9 + row * 0.6), Vector3(3.2, 0.035, 0.035), glow)
		_add_cylinder_between("Solar truss", center + Vector3(side * 2.0, 1.8, 0.0), panel_center, 0.08, shell)
	for index in range(6):
		var angle := TAU * float(index) / 6.0
		var light_pos := center + Vector3(cos(angle) * 4.5, 0.1, sin(angle) * 4.5)
		_add_sphere("Habitat path lamp", light_pos + Vector3.UP * 0.38, Vector3(0.22, 0.5, 0.22), glow)

func _build_lander(center: Vector3) -> void:
	var gold := _material(Color(0.83, 0.58, 0.28), 0.55)
	var silver := _material(Color(0.67, 0.69, 0.67), 0.63)
	var dark := _material(Color(0.12, 0.16, 0.18), 0.58)
	var glass := _material(Color(0.08, 0.2, 0.24), 0.24)
	glass.metallic = 0.38
	_add_cylinder("Lander descent stage", center + Vector3(0.0, 1.9, 0.0), 2.15, 1.15, gold, 6)
	_add_cylinder("Lander ascent cabin", center + Vector3(0.0, 3.08, 0.0), 1.34, 1.4, silver, 6)
	_add_box("Lander forward window", center + Vector3(0.0, 3.42, -1.0), Vector3(1.2, 0.52, 0.14), glass)
	_add_box("Lander hatch", center + Vector3(0.0, 2.75, -1.2), Vector3(0.72, 0.95, 0.13), dark)
	_add_cylinder("Top antenna mount", center + Vector3(0.0, 4.02, 0.0), 0.2, 0.18, dark)
	_add_cylinder_between("Lander antenna", center + Vector3(0.0, 4.05, 0.0), center + Vector3(0.0, 5.4, 0.0), 0.045, silver)
	for index in range(4):
		var angle := TAU * float(index) / 4.0 + PI * 0.25
		var direction := Vector3(cos(angle), 0.0, sin(angle))
		var foot := center + direction * 3.35 + Vector3(0.0, 0.16, 0.0)
		var upper := center + Vector3(0.0, 1.58, 0.0) + direction * 0.8
		_add_cylinder_between("Lander landing strut", upper, foot + Vector3(0.0, 0.45, 0.0), 0.13, silver)
		_add_cylinder_between("Lander hydraulic brace", center + Vector3(0.0, 1.45, 0.0) + direction * 0.65, foot + Vector3(0.0, 0.46, 0.0), 0.065, gold)
		_add_box("Lander foot pad", foot, Vector3(0.8, 0.18, 0.76), dark)
	for side in [-1.0, 1.0]:
		var panel := center + Vector3(side * 4.6, 2.62, 0.0)
		_add_box("Lander solar array", panel, Vector3(2.9, 0.1, 1.8), dark)
		for row in range(3):
			_add_box("Lander solar trace", panel + Vector3(0.0, 0.06, -0.58 + row * 0.58), Vector3(2.7, 0.025, 0.028), gold)
	_add_cylinder("Lander beacon", center + Vector3(0.0, 5.62, 0.0), 0.1, 0.22, _emissive(Color(0.31, 0.87, 0.82)))

func _build_power_terminal(center: Vector3) -> void:
	var shell := _material(Color(0.25, 0.3, 0.32), 0.72)
	var screen := _emissive(Color(0.15, 0.86, 0.83))
	_add_box("Power system plinth", center + Vector3(0.0, 0.62, -1.7), Vector3(0.95, 1.25, 0.72), shell)
	_add_box("Power system console", center + Vector3(0.0, 1.28, -2.05), Vector3(1.15, 0.68, 0.12), screen)
	_add_box("Console status strip", center + Vector3(0.0, 0.82, -2.1), Vector3(0.48, 0.08, 0.07), _emissive(Color(0.96, 0.57, 0.19)))
	_add_label_3d("POWER SYSTEMS  /  E", center + Vector3(0.0, 2.05, -2.05), Color(0.63, 0.94, 0.92))

func _build_signal_relay(center: Vector3) -> void:
	var shell := _material(Color(0.75, 0.75, 0.7), 0.7)
	var dark := _material(Color(0.1, 0.17, 0.21), 0.46)
	var signal_material := _emissive(Color(0.2, 0.84, 1.0))
	_add_box("Relay base", center + Vector3(0.0, 0.58, 0.0), Vector3(1.45, 1.15, 1.18), shell)
	_add_cylinder_between("Relay mast", center + Vector3(0.0, 1.0, 0.0), center + Vector3(0.0, 8.7, 0.0), 0.14, shell)
	_add_cylinder_between("Relay cross spar", center + Vector3(-1.8, 6.4, 0.0), center + Vector3(1.8, 6.4, 0.0), 0.09, dark)
	_add_cylinder_between("Relay dish support", center + Vector3(0.0, 7.0, 0.0), center + Vector3(1.2, 8.2, 0.0), 0.12, shell)
	_add_sphere("Relay dish", center + Vector3(1.25, 8.26, 0.0), Vector3(1.1, 0.45, 1.05), shell)
	_add_cylinder("Relay signal core", center + Vector3(0.0, 8.95, 0.0), 0.19, 0.22, signal_material)
	_add_box("Relay control panel", center + Vector3(0.0, 1.27, -0.7), Vector3(0.72, 0.38, 0.12), signal_material)
	_add_label_3d("DISTRESS RELAY  /  E", center + Vector3(0.0, 10.2, 0.0), Color(0.55, 0.88, 1.0))
	for side in [-1.0, 1.0]:
		_add_box("Relay solar wing", center + Vector3(side * 2.2, 1.4, 0.0), Vector3(1.55, 0.08, 1.05), dark)

func _add_beacon_lights() -> void:
	for point in [habitat_position, lander_position, relay_position]:
		var beacon := OmniLight3D.new()
		beacon.light_color = Color(0.13, 0.75, 0.81)
		beacon.light_energy = 0.7
		beacon.omni_range = 9.0
		beacon.position = point + Vector3.UP * 2.0
		add_child(beacon)

func _build_world_marker() -> void:
	_marker = Node3D.new()
	_marker.name = "Objective marker"
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.65
	ring_mesh.outer_radius = 0.82
	ring_mesh.rings = 5
	ring_mesh.ring_segments = 20
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	ring.material_override = _emissive(Color(0.29, 0.92, 0.86))
	_marker.add_child(ring)
	var diamond := MeshInstance3D.new()
	var diamond_mesh := BoxMesh.new()
	diamond_mesh.size = Vector3(0.42, 0.42, 0.42)
	diamond.mesh = diamond_mesh
	diamond.rotation_degrees = Vector3(0.0, 45.0, 45.0)
	diamond.position.y = 0.95
	diamond.material_override = _emissive(Color(0.41, 0.97, 0.9))
	_marker.add_child(diamond)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.025
	stem_mesh.bottom_radius = 0.1
	stem_mesh.height = 2.3
	stem_mesh.radial_segments = 8
	stem.mesh = stem_mesh
	stem.position.y = -1.05
	stem.material_override = _emissive(Color(0.22, 0.67, 0.69))
	_marker.add_child(stem)
	add_child(_marker)

func _build_hud() -> void:
	_ui = CanvasLayer.new()
	_ui.layer = 2
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var brand := _label("GRAVITY   /   LUNAR SURFACE EXPEDITION", 14, Color(0.83, 0.89, 0.87))
	brand.set_anchors_preset(Control.PRESET_TOP_LEFT)
	brand.position = Vector2(32.0, 26.0)
	brand.size = Vector2(430.0, 24.0)
	root.add_child(brand)
	var site := _label("MARE TRANQUILLITATIS     •     LUNAR NEAR SIDE", 10, Color(0.57, 0.68, 0.7))
	site.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	site.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	site.position = Vector2(-410.0, 31.0)
	site.size = Vector2(378.0, 20.0)
	root.add_child(site)

	var physics_card := _panel(Color(0.018, 0.033, 0.046, 0.76), Color(0.38, 0.65, 0.67, 0.45))
	physics_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	physics_card.position = Vector2(-158.0, 64.0)
	physics_card.size = Vector2(126.0, 58.0)
	root.add_child(physics_card)
	var physics_copy := VBoxContainer.new()
	physics_copy.add_theme_constant_override("separation", 0)
	physics_card.add_child(physics_copy)
	var gravity_value := _label("1.62", 23, Color(0.85, 0.98, 0.92))
	gravity_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gravity_value.custom_minimum_size.y = 29.0
	physics_copy.add_child(gravity_value)
	var gravity_unit := _label("M / S²   MOON", 9, Color(0.48, 0.75, 0.75))
	gravity_unit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gravity_unit.custom_minimum_size.y = 16.0
	physics_copy.add_child(gravity_unit)

	var objective_card := _panel(Color(0.018, 0.033, 0.046, 0.78), Color(0.38, 0.65, 0.67, 0.45))
	objective_card.set_anchors_preset(Control.PRESET_TOP_WIDE)
	objective_card.anchor_left = 0.5
	objective_card.anchor_right = 0.5
	objective_card.offset_left = -235.0
	objective_card.offset_top = 23.0
	objective_card.offset_right = 235.0
	objective_card.offset_bottom = 112.0
	root.add_child(objective_card)
	var objective_copy := VBoxContainer.new()
	objective_copy.add_theme_constant_override("separation", 3)
	objective_card.add_child(objective_copy)
	_objective_label = _label(STAGE_TITLES[0], 15, Color(0.88, 0.94, 0.9))
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective_label.custom_minimum_size.y = 22.0
	objective_copy.add_child(_objective_label)
	_detail_label = _label(STAGE_DETAILS[0], 11, Color(0.59, 0.7, 0.69))
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.custom_minimum_size.y = 20.0
	objective_copy.add_child(_detail_label)

	var reticle := _label("+", 18, Color(0.8, 0.96, 0.91, 0.75))
	reticle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reticle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reticle.set_anchors_preset(Control.PRESET_CENTER)
	reticle.offset_left = -10.0
	reticle.offset_top = -12.0
	reticle.offset_right = 10.0
	reticle.offset_bottom = 12.0
	root.add_child(reticle)

	_distance_label = _label("◈  032 M   /   FOLLOW THE BEACON", 11, Color(0.76, 0.89, 0.85))
	_distance_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_distance_label.anchor_left = 0.5
	_distance_label.anchor_right = 0.5
	_distance_label.position = Vector2(-150.0, 123.0)
	_distance_label.size = Vector2(300.0, 20.0)
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_distance_label)

	_interaction_label = _label("E   INTERACT", 13, Color(0.8, 0.98, 0.92))
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interaction_label.anchor_left = 0.5
	_interaction_label.anchor_right = 0.5
	_interaction_label.position = Vector2(-130.0, -178.0)
	_interaction_label.size = Vector2(260.0, 32.0)
	_interaction_label.modulate.a = 0.0
	root.add_child(_interaction_label)

	var control_card := _panel(Color(0.018, 0.033, 0.046, 0.72), Color(0.38, 0.65, 0.67, 0.32))
	control_card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	control_card.position = Vector2(28.0, -107.0)
	control_card.size = Vector2(420.0, 78.0)
	root.add_child(control_card)
	var controls := _label("W A S D    MOVE      /      MOUSE    LOOK\nSPACE    LOW-G JUMP      /      SHIFT    SUIT THRUST\nE    INTERACT      /      ESC    RETURN TO MENU", 10, Color(0.62, 0.73, 0.73))
	controls.position = Vector2(15.0, 12.0)
	controls.size = Vector2(390.0, 56.0)
	controls.add_theme_constant_override("line_spacing", 3)
	control_card.add_child(controls)

	var progress_card := _panel(Color(0.018, 0.033, 0.046, 0.72), Color(0.38, 0.65, 0.67, 0.32))
	progress_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_card.anchor_left = 0.5
	progress_card.anchor_right = 0.5
	progress_card.offset_left = -348.0
	progress_card.offset_top = -83.0
	progress_card.offset_right = 348.0
	progress_card.offset_bottom = -25.0
	root.add_child(progress_card)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 0)
	progress_card.add_child(progress_row)
	var stage_names := ["01  LANDER", "02  POWER", "03  SIGNAL", "04  RETURN"]
	for index in range(stage_names.size()):
		var label := _label(stage_names[index], 10, Color(0.38, 0.48, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_row.add_child(label)
		_progress_labels.append(label)

	var suit_card := _panel(Color(0.018, 0.033, 0.046, 0.72), Color(0.38, 0.65, 0.67, 0.32))
	suit_card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	suit_card.position = Vector2(-226.0, -107.0)
	suit_card.size = Vector2(198.0, 78.0)
	root.add_child(suit_card)
	var suit_copy := VBoxContainer.new()
	suit_copy.add_theme_constant_override("separation", 2)
	suit_card.add_child(suit_copy)
	var boost_title := _label("SUIT THRUST  /  RESERVE", 9, Color(0.62, 0.73, 0.73))
	suit_copy.add_child(boost_title)
	_boost_bar = ProgressBar.new()
	_boost_bar.custom_minimum_size = Vector2(169.0, 10.0)
	_boost_bar.max_value = 100.0
	_boost_bar.show_percentage = false
	_boost_bar.add_theme_stylebox_override("background", _bar_style(Color(0.06, 0.12, 0.14)))
	_boost_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.31, 0.88, 0.8)))
	suit_copy.add_child(_boost_bar)
	_timer_label = _label("00:00   /   EVA", 9, Color(0.59, 0.7, 0.69))
	suit_copy.add_child(_timer_label)

	_message_label = _label("", 13, Color(0.83, 0.96, 0.9))
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message_label.anchor_left = 0.5
	_message_label.anchor_right = 0.5
	_message_label.position = Vector2(-240.0, 169.0)
	_message_label.size = Vector2(480.0, 28.0)
	_message_label.modulate.a = 0.0
	root.add_child(_message_label)
	_build_completion_panel(root)

func _build_completion_panel(root: Control) -> void:
	_complete_panel = _panel(Color(0.012, 0.024, 0.036, 0.94), Color(0.47, 0.81, 0.76, 0.8))
	_complete_panel.set_anchors_preset(Control.PRESET_CENTER)
	_complete_panel.offset_left = -240.0
	_complete_panel.offset_top = -135.0
	_complete_panel.offset_right = 240.0
	_complete_panel.offset_bottom = 135.0
	_complete_panel.visible = false
	root.add_child(_complete_panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 14)
	_complete_panel.add_child(copy)
	var overline := _label("MISSION CONTROL  /  SIGNAL ACQUIRED", 10, Color(0.46, 0.79, 0.75))
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(overline)
	var title := _label("You made it home.", 29, Color(0.91, 0.92, 0.86))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var serif := SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia", "Times New Roman"])
	title.add_theme_font_override("font", serif)
	copy.add_child(title)
	var details := _label("1.62 m/s² held you to the surface.\nThe return signal is on its way.", 12, Color(0.63, 0.72, 0.72))
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(details)
	var replay := _label("R   REPLAY MISSION      /      ESC   MAIN MENU", 10, Color(0.74, 0.87, 0.82))
	replay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(replay)

func _update_mission() -> void:
	if mission_stage == 0 and astronaut.global_position.distance_to(lander_position) < 4.0:
		mission_stage = 1
		_set_message("LANDER REACHED  /  RESTORE THE SURFACE SYSTEMS", Color(0.57, 0.92, 0.83))
		_update_objective()
	elif mission_stage == 3 and astronaut.global_position.distance_to(habitat_position) < 5.0:
		mission_stage = 4
		_complete_panel.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_set_message("MISSION CONTROL ACKNOWLEDGED YOUR SIGNAL", Color(0.65, 0.91, 0.87))
		_update_objective()
	if mission_stage == 4 and Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _on_interact_pressed() -> void:
	if mission_stage == 1 and astronaut.global_position.distance_to(terminal_position + Vector3(0.0, 0.0, -2.0)) < 3.6:
		mission_stage = 2
		_set_message("LANDER POWER RESTORED  /  RELAY COORDINATES UPLOADED", Color(0.56, 0.95, 0.87))
		_update_objective()
	elif mission_stage == 2 and astronaut.global_position.distance_to(relay_position) < 4.4:
		mission_stage = 3
		_set_message("DISTRESS SIGNAL SENT  /  RETURN TO THE HABITAT", Color(0.56, 0.95, 0.87))
		_update_objective()
	elif mission_stage == 1 or mission_stage == 2:
		_set_message("MOVE CLOSER TO THE ACTIVE CONSOLE", Color(0.79, 0.8, 0.7))

func _update_objective() -> void:
	if not is_instance_valid(_objective_label):
		return
	_objective_label.text = STAGE_TITLES[mission_stage]
	_detail_label.text = STAGE_DETAILS[mission_stage]
	_complete_panel.visible = mission_stage == 4
	match mission_stage:
		0:
			_marker_target = lander_position
		1:
			_marker_target = terminal_position + Vector3(0.0, 0.0, -2.0)
		2:
			_marker_target = relay_position
		3:
			_marker_target = habitat_position
		4:
			_marker_target = habitat_position
	for index in range(_progress_labels.size()):
		if index < mission_stage:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.42, 0.9, 0.79))
		elif index == mission_stage and mission_stage < 4:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.87, 0.94, 0.89))
		else:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.38, 0.48, 0.5))

func _update_hud() -> void:
	if not is_instance_valid(astronaut):
		return
	var target_distance := astronaut.global_position.distance_to(_marker_target)
	var horizontal := Vector2(astronaut.global_position.x - _marker_target.x, astronaut.global_position.z - _marker_target.z).length()
	var direction := Vector3(_marker_target.x - astronaut.global_position.x, 0.0, _marker_target.z - astronaut.global_position.z).normalized()
	var yaw := astronaut.global_rotation.y
	var camera_forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var bearing := atan2(camera_forward.cross(direction).y, camera_forward.dot(direction))
	var arrow := "↑"
	if absf(bearing) > 0.42:
		arrow = "←" if bearing > 0.0 else "→"
	_distance_label.text = "%s   %03d M   /   %s" % [arrow, int(horizontal), "OBJECTIVE" if target_distance > 4.0 else "AT WAYPOINT"]
	_boost_bar.value = astronaut.boost_fuel
	_timer_label.text = "%02d:%02d   /   EVA" % [int(mission_time / 60.0), int(fmod(mission_time, 60.0))]
	var in_range := false
	if mission_stage == 1:
		in_range = astronaut.global_position.distance_to(terminal_position + Vector3(0.0, 0.0, -2.0)) < 3.6
	elif mission_stage == 2:
		in_range = astronaut.global_position.distance_to(relay_position) < 4.4
	_interaction_label.modulate.a = move_toward(_interaction_label.modulate.a, 1.0 if in_range else 0.0, get_process_delta_time() * 5.0)
	if mission_stage == 4:
		_distance_label.visible = false
		_interaction_label.visible = false
	else:
		_distance_label.visible = true
		_interaction_label.visible = true

func _set_message(text: String, color: Color) -> void:
	_message_label.text = text
	_message_label.add_theme_color_override("font_color", color)
	_message_label.modulate.a = 1.0
	_message_time = 4.0

func _build_lamp(point: Vector3, color: Color, radius: float = 8.0) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.4
	light.omni_range = radius
	light.position = point
	add_child(light)

func _add_label_3d(text: String, point: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 28
	label.pixel_size = 0.013
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color(0.025, 0.035, 0.045, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = point
	add_child(label)

func _add_box(label: String, point: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	return instance

func _add_cylinder(label: String, point: Vector3, radius: float, height: float, material: Material, sides: int = 16) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	return instance

func _add_sphere(label: String, point: Vector3, scale: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.scale = scale
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	return instance

func _add_cylinder_between(label: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var difference := finish - start
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.82
	mesh.bottom_radius = radius
	mesh.height = difference.length()
	mesh.radial_segments = 8
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = (start + finish) * 0.5
	instance.quaternion = Quaternion(Vector3.UP, difference.normalized())
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(instance)
	return instance

func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material

func _emissive(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.46)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.65
	return material

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("outline_size", 0)
	return label

func _panel(background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

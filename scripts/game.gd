extends Node3D

const TERRAIN_SCRIPT := preload("res://scripts/lunar_terrain.gd")
const PLAYER_SCRIPT := preload("res://scripts/astronaut.gd")
const MISSION_SCRIPT := preload("res://scripts/mission_controller.gd")
const ALIEN_SCRIPT := preload("res://scripts/alien_npc.gd")
const CREW_HABITAT_MODEL_PATH := "res://assets/crew habitat.glb"

var terrain: LunarTerrain
var astronaut: LunarAstronaut
var mission_control
var habitat_position := Vector3.ZERO
var ship_position := Vector3.ZERO
var relay_position := Vector3.ZERO
var earth_visual: MeshInstance3D
var earth_halo: OmniLight3D
var moon_orbit_visual: MeshInstance3D

func _ready() -> void:
	SFX.start_ambient()
	_build_environment()
	_add_moon_orbit_visual()
	terrain = TERRAIN_SCRIPT.new()
	terrain.name = "Lunar geology"
	add_child(terrain)
	_build_landmarks()
	_build_player()
	_spawn_aliens()
	mission_control = MISSION_SCRIPT.new()
	mission_control.name = "Mission control"
	add_child(mission_control)
	mission_control.configure(terrain, astronaut, habitat_position, ship_position, earth_visual, earth_halo, moon_orbit_visual)
	astronaut.interact_pressed.connect(mission_control.handle_interact)
	astronaut.inventory_pressed.connect(mission_control.toggle_inventory)
	astronaut.hint_pressed.connect(mission_control.request_hint)
	astronaut.command_log_pressed.connect(mission_control.toggle_command_log)
	astronaut.menu_pressed.connect(mission_control.handle_menu)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.009, 0.019)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.34, 0.39, 0.49)
	environment.ambient_light_energy = 0.18
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.42
	environment.glow_bloom = 0.07
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.1
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Hard lunar sunlight"
	sunlight.rotation_degrees = Vector3(-49.0, -31.0, 0.0)
	sunlight.light_color = Color(1.0, 0.96, 0.86)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 280.0
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sunlight)
	_add_starfield()
	_add_earth()

func _add_starfield() -> void:
	var star_mesh := SphereMesh.new()
	star_mesh.radius = 0.11
	star_mesh.height = 0.22
	star_mesh.radial_segments = 5
	star_mesh.rings = 3
	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color(0.78, 0.86, 1.0)
	star_material.emission_enabled = true
	star_material.emission = Color(0.34, 0.46, 0.78)
	star_material.emission_energy_multiplier = 0.42
	var stars := MultiMesh.new()
	stars.transform_format = MultiMesh.TRANSFORM_3D
	stars.mesh = star_mesh
	stars.instance_count = 290
	var rng := RandomNumberGenerator.new()
	rng.seed = 454001
	for index in range(stars.instance_count):
		var angle := rng.randf_range(0.0, TAU)
		var elevation := rng.randf_range(0.08, 1.25)
		var radius := rng.randf_range(13000.0, 15500.0)
		var point := Vector3(cos(angle) * cos(elevation) * radius, sin(elevation) * radius + 10.0, sin(angle) * cos(elevation) * radius)
		var scale := rng.randf_range(0.45, 1.5)
		stars.set_instance_transform(index, Transform3D(Basis().scaled(Vector3.ONE * scale), point))
	var star_field := MultiMeshInstance3D.new()
	star_field.name = "Distant stars"
	star_field.multimesh = stars
	star_field.material_override = star_material
	add_child(star_field)

func _add_earth() -> void:
	var globe := SphereMesh.new()
	globe.radius = 130.0
	globe.height = 260.0
	globe.radial_segments = 96
	globe.rings = 48
	var earth_material := StandardMaterial3D.new()
	earth_material.albedo_texture = load("res://assets/planets/earth_blue_marble.jpg") as Texture2D
	earth_material.roughness = 0.96
	earth_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	earth_visual = MeshInstance3D.new()
	earth_visual.name = "Earthrise"
	earth_visual.mesh = globe
	earth_visual.material_override = earth_material
	earth_visual.position = Vector3(4800.0, 2050.0, -5800.0)
	earth_visual.visibility_range_end = 12000.0
	add_child(earth_visual)
	var atmosphere := MeshInstance3D.new()
	atmosphere.name = "Earth atmosphere"
	var atmosphere_mesh := SphereMesh.new()
	atmosphere_mesh.radius = 135.5
	atmosphere_mesh.height = 271.0
	atmosphere_mesh.radial_segments = 56
	atmosphere_mesh.rings = 28
	atmosphere.mesh = atmosphere_mesh
	var atmosphere_material := StandardMaterial3D.new()
	atmosphere_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	atmosphere_material.albedo_color = Color(0.2, 0.52, 1.0, 0.17)
	atmosphere_material.emission_enabled = true
	atmosphere_material.emission = Color(0.12, 0.36, 0.95)
	atmosphere_material.emission_energy_multiplier = 0.42
	atmosphere_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	atmosphere_material.cull_mode = BaseMaterial3D.CULL_FRONT
	atmosphere.material_override = atmosphere_material
	earth_visual.add_child(atmosphere)
	earth_halo = OmniLight3D.new()
	earth_halo.name = "Earth glow"
	earth_halo.light_color = Color(0.15, 0.35, 0.78)
	earth_halo.light_energy = 5.5
	earth_halo.omni_range = 430.0
	earth_halo.position = earth_visual.position
	add_child(earth_halo)

func _add_moon_orbit_visual() -> void:
	var moon_mesh := SphereMesh.new()
	moon_mesh.radius = 1737.4
	moon_mesh.height = 3474.8
	moon_mesh.radial_segments = 128
	moon_mesh.rings = 64
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_texture = load("res://assets/planets/moon_cgi_kit_color_2k.jpg") as Texture2D
	moon_material.albedo_color = Color(0.78, 0.78, 0.78)
	moon_material.roughness = 1.0
	moon_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	moon_orbit_visual = MeshInstance3D.new()
	moon_orbit_visual.name = "Curved lunar horizon"
	moon_orbit_visual.mesh = moon_mesh
	moon_orbit_visual.material_override = moon_material
	moon_orbit_visual.position = Vector3(0.0, -1737.4, 0.0)
	moon_orbit_visual.visible = false
	moon_orbit_visual.visibility_range_end = 1900.0
	add_child(moon_orbit_visual)

func _build_landmarks() -> void:
	habitat_position = _ground_point(Vector2(-2.0, 11.0))
	ship_position = _ground_point(Vector2(21.0, -12.0))
	relay_position = _ground_point(Vector2(-40.0, -46.0))
	_build_habitat(habitat_position)
	_build_signal_relay(relay_position)
	_add_beacon_lights()

func _build_player() -> void:
	astronaut = PLAYER_SCRIPT.new()
	astronaut.name = "Astronaut"
	astronaut.position = habitat_position + Vector3(0.0, 0.16, 5.2)
	add_child(astronaut)
	astronaut.set_camera_yaw(-0.68)
	astronaut.collision_mask |= 2

func _spawn_aliens() -> void:
	var spawn_points := [
		Vector2(30.0, 16.0),
		Vector2(43.0, -22.0),
		Vector2(-29.0, -19.0),
		Vector2(-47.0, -49.0),
		Vector2(59.0, 23.0),
		Vector2(-62.0, 20.0),
		Vector2(9.0, -55.0),
		Vector2(76.0, -41.0)
	]
	for index in range(spawn_points.size()):
		var point: Vector2 = spawn_points[index]
		var alien: LunarAlien = ALIEN_SCRIPT.new()
		alien.name = "Lunar alien %02d" % (index + 1)
		alien.configure(terrain, _ground_point(point), 8.0 + float(index % 3) * 2.0, index + 1, astronaut)
		add_child(alien)

func _ground_point(point: Vector2) -> Vector3:
	return Vector3(point.x, terrain.height_at(point.x, point.y), point.y)

func _build_habitat(center: Vector3) -> void:
	if _build_habitat_model(center):
		return
	var shell := _material(Color(0.73, 0.75, 0.72), 0.76)
	var dark := _material(Color(0.09, 0.17, 0.22), 0.43)
	var accent := _material(Color(0.85, 0.43, 0.17), 0.62)
	var glow := _emissive(Color(0.2, 0.83, 0.91))
	_add_cylinder("Habitat pressure module", center + Vector3(0.0, 1.8, 0.0), 2.05, 3.5, shell, 16)
	_add_cylinder("Airlock ring", center + Vector3(0.0, 1.1, -1.6), 1.15, 0.38, dark, 16)
	_add_box("Airlock entrance", center + Vector3(0.0, 1.1, -1.86), Vector3(1.3, 1.8, 0.18), shell)
	_add_box("Airlock access light", center + Vector3(0.0, 2.08, -2.0), Vector3(0.78, 0.12, 0.05), glow)
	_add_cylinder("Habitat roof cap", center + Vector3(0.0, 3.65, 0.0), 1.62, 0.3, accent, 14)
	_add_box("Habitat mission badge", center + Vector3(0.0, 2.75, -1.76), Vector3(0.34, 0.35, 0.07), dark)
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
	_add_label_3d("CREW HABITAT", center + Vector3(0.0, 5.0, 0.0), Color(0.62, 0.88, 0.86))

func _build_habitat_model(center: Vector3) -> bool:
	if not ResourceLoader.exists(CREW_HABITAT_MODEL_PATH):
		push_warning("Crew habitat model not found at %s; using the built-in habitat." % CREW_HABITAT_MODEL_PATH)
		return false
	var packed_model := load(CREW_HABITAT_MODEL_PATH) as PackedScene
	if packed_model == null:
		push_warning("Crew habitat model could not be imported; using the built-in habitat.")
		return false
	var model := packed_model.instantiate() as Node3D
	if model == null:
		push_warning("Crew habitat scene has no Node3D root; using the built-in habitat.")
		return false
	model.name = "Crew Habitat GLB"
	add_child(model)
	var bounds := _habitat_mesh_bounds(model)
	if bounds.size.length_squared() < 0.001:
		model.queue_free()
		push_warning("Crew habitat model has no visible meshes; using the built-in habitat.")
		return false
	var horizontal_span := maxf(bounds.size.x, bounds.size.z)
	var model_scale := 13.6 / maxf(horizontal_span, 0.1)
	var bounds_center := bounds.get_center()
	model.scale = Vector3.ONE * model_scale
	model.position = center - Vector3(bounds_center.x, bounds.position.y, bounds_center.z) * model_scale
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		mesh_instance.lod_bias = 1.2
		mesh_instance.visibility_range_end = 220.0
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var label_height := maxf(bounds.size.y * model_scale + 1.25, 5.0)
	_add_label_3d("CREW HABITAT", center + Vector3.UP * label_height, Color(0.62, 0.88, 0.86))
	return true

func _habitat_mesh_bounds(root: Node3D) -> AABB:
	var merged := AABB()
	var has_bounds := false
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.push_front(root)
	for node in meshes:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var relative_transform: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		var mesh_bounds := _transform_habitat_bounds(mesh_instance.get_aabb(), relative_transform)
		merged = mesh_bounds if not has_bounds else merged.merge(mesh_bounds)
		has_bounds = true
	return merged

func _transform_habitat_bounds(bounds: AABB, transform: Transform3D) -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for x in [bounds.position.x, bounds.position.x + bounds.size.x]:
		for y in [bounds.position.y, bounds.position.y + bounds.size.y]:
			for z in [bounds.position.z, bounds.position.z + bounds.size.z]:
				var point: Vector3 = transform * Vector3(x, y, z)
				minimum = Vector3(minf(minimum.x, point.x), minf(minimum.y, point.y), minf(minimum.z, point.z))
				maximum = Vector3(maxf(maximum.x, point.x), maxf(maximum.y, point.y), maxf(maximum.z, point.z))
	return AABB(minimum, maximum - minimum)

func _build_signal_relay(center: Vector3) -> void:
	var shell := _material(Color(0.75, 0.75, 0.7), 0.7)
	var dark := _material(Color(0.1, 0.17, 0.21), 0.46)
	var signal_material := _emissive(Color(0.2, 0.84, 1.0))
	_add_box("Relay base", center + Vector3(0.0, 0.58, 0.0), Vector3(1.45, 1.15, 1.18), shell)
	_add_cylinder_between("Relay mast", center + Vector3(0.0, 1.0, 0.0), center + Vector3(0.0, 8.7, 0.0), 0.14, shell)
	_add_cylinder_between("Relay crossbar", center + Vector3(-1.8, 6.4, 0.0), center + Vector3(1.8, 6.4, 0.0), 0.09, dark)
	_add_cylinder_between("Relay dish support", center + Vector3(0.0, 7.0, 0.0), center + Vector3(1.2, 8.2, 0.0), 0.12, shell)
	_add_sphere("Relay dish", center + Vector3(1.25, 8.26, 0.0), Vector3(1.1, 0.45, 1.05), shell)
	_add_cylinder("Relay signal core", center + Vector3(0.0, 8.95, 0.0), 0.19, 0.22, signal_material)
	_add_box("Relay control panel", center + Vector3(0.0, 1.27, -0.7), Vector3(0.72, 0.38, 0.12), signal_material)
	for side in [-1.0, 1.0]:
		_add_box("Relay solar wing", center + Vector3(side * 2.2, 1.4, 0.0), Vector3(1.55, 0.08, 1.05), dark)
	_add_label_3d("LUNAR RELAY", center + Vector3(0.0, 10.2, 0.0), Color(0.55, 0.88, 1.0))

func _add_beacon_lights() -> void:
	for point in [habitat_position, ship_position, relay_position]:
		var beacon := OmniLight3D.new()
		beacon.light_color = Color(0.13, 0.75, 0.81)
		beacon.light_energy = 0.7
		beacon.omni_range = 9.0
		beacon.position = point + Vector3.UP * 2.0
		add_child(beacon)

func _add_box(label: String, point: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.visibility_range_end = 220.0
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
	instance.visibility_range_end = 220.0
	add_child(instance)
	return instance

func _add_sphere(label: String, point: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.scale = size
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.visibility_range_end = 220.0
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
	instance.visibility_range_end = 220.0
	add_child(instance)
	return instance

func _add_label_3d(text: String, point: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 27
	label.pixel_size = 0.013
	label.modulate = color
	label.outline_size = 4
	label.outline_modulate = Color(0.025, 0.035, 0.045, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = point
	label.visibility_range_end = 180.0
	add_child(label)

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

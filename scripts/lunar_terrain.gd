extends Node3D
class_name LunarTerrain

const EXTENT := 126.0
const GRID_STEPS := 144
const MARE_CENTER := Vector2(5.0, -1.0)
const SKYLIGHT_CENTER := Vector2(43.0, -12.0)
const EJECTA_CENTER := Vector2(29.0, -35.0)

var _broad_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()
var _highland_noise := FastNoiseLite.new()
var _craters: Array[Dictionary] = []
var _rock_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	_setup_noise()
	_create_craters()
	_build_surface()
	_build_ejecta_rays()
	_scatter_rocks()
	_add_landmark_labels()

func height_at(x: float, z: float) -> float:
	var broad := _broad_noise.get_noise_2d(x, z) * 2.3
	var small := _detail_noise.get_noise_2d(x, z) * 0.9
	var highland := _highland_noise.get_noise_2d(x, z) * 1.6
	var highland_mask := smoothstep(12.0, 68.0, abs(x + 34.0))
	var mare_distance := Vector2(x - MARE_CENTER.x, (z - MARE_CENTER.y) * 0.92).length()
	var mare_mask := 1.0 - smoothstep(37.0, 80.0, mare_distance)
	var relief := (broad + small + highland * highland_mask) * (1.0 - mare_mask * 0.55)
	var h := relief - 1.1 * mare_mask

	for crater in _craters:
		var c: Vector2 = crater.center
		var radius: float = crater.radius
		var d := Vector2(x - c.x, z - c.y).length() / radius
		if d < 1.0:
			var bowl := 1.0 - d * d
			h -= crater.depth * bowl * bowl
		var rim := exp(-pow((d - 1.0) / 0.13, 2.0))
		h += rim * crater.rim

	# A sinuous rille cuts into the western highland, with raised shoulders.
	var rille_center := -40.0 + 8.5 * sin((z + 34.0) * 0.052)
	var rille_dist: float = absf(x - rille_center)
	if z > -96.0 and z < 54.0:
		h -= 3.4 * exp(-pow(rille_dist / 2.5, 2.0))
		h += 0.62 * exp(-pow((rille_dist - 3.6) / 1.05, 2.0))

	# Dorsa style wrinkle ridges rise from the mare basalt.
	var ridge_center := 14.0 + 3.2 * sin((z + 5.0) * 0.06)
	var ridge_dist: float = absf(x - ridge_center)
	if z > -72.0 and z < 77.0:
		h += 1.55 * exp(-pow(ridge_dist / 2.5, 2.0))

	# Broad volcanic domes: low, round shields rather than sharp mountains.
	for dome in [Vector3(-15.0, 3.8, 31.0), Vector3(-3.0, 3.2, 39.0), Vector3(8.0, 3.6, 31.0), Vector3(56.0, 2.8, 15.0)]:
		var dome_dist := Vector2(x - dome.x, z - dome.z).length()
		h += dome.y * exp(-pow(dome_dist / 8.5, 2.0))

	# A distant chain of asymmetric peaks forms the mountain horizon.
	for peak in [Vector3(-74.0, 15.0, -91.0), Vector3(-58.0, 20.0, -98.0), Vector3(-40.0, 17.0, -92.0), Vector3(-21.0, 22.0, -101.0), Vector3(2.0, 15.0, -96.0), Vector3(25.0, 19.0, -103.0), Vector3(49.0, 14.0, -94.0), Vector3(70.0, 18.0, -101.0)]:
		var dx: float = (x - peak.x) / 8.5
		var dz: float = (z - peak.z) / 18.0
		h += peak.y * exp(-(dx * dx + dz * dz) * 0.5)

	# A collapsed skylight sits inside a shallow, dark collapse apron.
	var skylight_distance := Vector2(x - SKYLIGHT_CENTER.x, z - SKYLIGHT_CENTER.y).length()
	h -= 5.2 * exp(-pow(skylight_distance / 7.2, 2.0))
	h += 1.15 * exp(-pow((skylight_distance - 8.0) / 1.5, 2.0))
	return h

func _setup_noise() -> void:
	_broad_noise.seed = 196901
	_broad_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_broad_noise.frequency = 0.035
	_broad_noise.fractal_octaves = 4
	_broad_noise.fractal_lacunarity = 2.1
	_broad_noise.fractal_gain = 0.48

	_detail_noise.seed = 77721
	_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail_noise.frequency = 0.14
	_detail_noise.fractal_octaves = 3
	_detail_noise.fractal_gain = 0.45

	_highland_noise.seed = 28413
	_highland_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_highland_noise.frequency = 0.062
	_highland_noise.fractal_octaves = 5
	_highland_noise.fractal_lacunarity = 2.0
	_highland_noise.fractal_gain = 0.55

func _create_craters() -> void:
	_craters = [
		{"center": Vector2(29.0, -35.0), "radius": 13.0, "depth": 4.0, "rim": 2.2},
		{"center": Vector2(-63.0, 7.0), "radius": 15.0, "depth": 5.2, "rim": 2.7},
		{"center": Vector2(64.0, -60.0), "radius": 11.0, "depth": 4.0, "rim": 2.0},
		{"center": Vector2(-8.0, -57.0), "radius": 8.0, "depth": 3.0, "rim": 1.8},
		{"center": Vector2(77.0, 24.0), "radius": 9.0, "depth": 3.4, "rim": 1.9},
		{"center": Vector2(-78.0, -47.0), "radius": 8.5, "depth": 3.0, "rim": 1.7},
		{"center": Vector2(50.0, 73.0), "radius": 7.4, "depth": 2.8, "rim": 1.5},
		{"center": Vector2(-9.0, 73.0), "radius": 6.3, "depth": 2.4, "rim": 1.4},
		{"center": Vector2(91.0, -11.0), "radius": 5.7, "depth": 2.2, "rim": 1.3},
		{"center": Vector2(-89.0, 31.0), "radius": 5.5, "depth": 2.0, "rim": 1.2},
		{"center": Vector2(3.0, -82.0), "radius": 5.0, "depth": 2.0, "rim": 1.2},
		{"center": Vector2(53.0, 48.0), "radius": 4.5, "depth": 1.8, "rim": 1.0},
		{"center": Vector2(-31.0, -17.0), "radius": 4.2, "depth": 1.7, "rim": 1.0},
		{"center": Vector2(84.0, 83.0), "radius": 3.8, "depth": 1.5, "rim": 0.9},
		{"center": Vector2(-98.0, -83.0), "radius": 4.1, "depth": 1.6, "rim": 0.9},
		{"center": Vector2(95.0, 57.0), "radius": 3.3, "depth": 1.3, "rim": 0.8},
		{"center": Vector2(-5.0, 17.0), "radius": 3.0, "depth": 1.2, "rim": 0.8},
	]

func _build_surface() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := (EXTENT * 2.0) / float(GRID_STEPS)
	for z_index in range(GRID_STEPS + 1):
		var z := -EXTENT + float(z_index) * step
		for x_index in range(GRID_STEPS + 1):
			var x := -EXTENT + float(x_index) * step
			var h := height_at(x, z)
			tool.set_uv(Vector2(x, z) * 0.12)
			tool.set_color(_surface_color(x, z, h))
			tool.add_vertex(Vector3(x, h, z))
	for z_index in range(GRID_STEPS):
		for x_index in range(GRID_STEPS):
			var a := z_index * (GRID_STEPS + 1) + x_index
			var b := a + 1
			var c := a + GRID_STEPS + 1
			var d := c + 1
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(d)
			tool.add_index(c)
	tool.generate_normals()
	var terrain_mesh := tool.commit()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Cratered lunar regolith"
	mesh_instance.mesh = terrain_mesh
	mesh_instance.material_override = _terrain_material()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mesh_instance)

	var body := StaticBody3D.new()
	body.name = "Walkable lunar surface"
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(terrain_mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _terrain_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
	shader_type spatial;
	render_mode diffuse_burley, specular_schlick_ggx;
	void fragment() {
		float fine = sin(UV.x * 17.0 + sin(UV.y * 13.0)) * sin(UV.y * 19.0 + cos(UV.x * 11.0));
		float grain = sin(UV.x * 83.0 + UV.y * 51.0) * sin(UV.y * 76.0 - UV.x * 37.0);
		float value = 0.94 + fine * 0.035 + grain * 0.018;
		ALBEDO = COLOR.rgb * value;
		ROUGHNESS = 0.98;
		METALLIC = 0.0;
	}
	"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func _surface_color(x: float, z: float, h: float) -> Color:
	var mare_distance := Vector2(x - MARE_CENTER.x, (z - MARE_CENTER.y) * 0.92).length()
	var mare := 1.0 - smoothstep(35.0, 72.0, mare_distance)
	var highland := smoothstep(-18.0, 68.0, -x + abs(z + 8.0) * 0.27)
	var base := Color(0.31, 0.32, 0.33).lerp(Color(0.56, 0.54, 0.5), highland * 0.7)
	base = base.lerp(Color(0.15, 0.17, 0.19), mare * 0.92)
	var skylight_d := Vector2(x - SKYLIGHT_CENTER.x, z - SKYLIGHT_CENTER.y).length()
	if skylight_d < 3.9:
		base = Color(0.035, 0.045, 0.06)
	elif skylight_d < 8.0:
		base = base.lerp(Color(0.20, 0.22, 0.235), 0.55)
	var dome_dist := Vector2(x + 15.0, z - 31.0).length()
	if dome_dist < 7.0:
		base = base.lerp(Color(0.59, 0.56, 0.51), 0.32)
	if h > 9.0:
		base = base.lerp(Color(0.68, 0.66, 0.61), clampf((h - 9.0) / 15.0, 0.0, 0.48))
	var variation := _detail_noise.get_noise_2d(x * 1.9, z * 1.9) * 0.035
	return Color(base.r + variation, base.g + variation, base.b + variation, 1.0)

func _build_ejecta_rays() -> void:
	var ray_material := StandardMaterial3D.new()
	ray_material.albedo_color = Color(0.66, 0.65, 0.61, 0.7)
	ray_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	ray_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ray_material.roughness = 1.0
	ray_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 55031
	for ray_index in range(14):
		var angle := TAU * float(ray_index) / 14.0 + rng.randf_range(-0.1, 0.1)
		var direction := Vector2(cos(angle), sin(angle))
		var perpendicular := Vector2(-direction.y, direction.x)
		var ray := SurfaceTool.new()
		ray.begin(Mesh.PRIMITIVE_TRIANGLES)
		for segment in range(49):
			var t := float(segment) / 48.0
			var distance := 9.2 + t * rng.randf_range(29.0, 38.0)
			var center := EJECTA_CENTER + direction * distance
			var width := (0.7 + rng.randf_range(0.1, 0.9)) * (1.0 - t * 0.8)
			for side in [-1.0, 1.0]:
				var point: Vector2 = center + perpendicular * width * float(side)
				var y := height_at(point.x, point.y) + 0.075
				ray.set_color(Color(0.84, 0.82, 0.76, (1.0 - t * 0.66) * 0.55))
				ray.add_vertex(Vector3(point.x, y, point.y))
		for segment in range(48):
			var a := segment * 2
			var b := a + 1
			var c := a + 2
			var d := a + 3
			ray.add_index(a)
			ray.add_index(b)
			ray.add_index(c)
			ray.add_index(b)
			ray.add_index(d)
			ray.add_index(c)
		ray.generate_normals()
		var strip := MeshInstance3D.new()
		strip.mesh = ray.commit()
		strip.material_override = ray_material
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)

func _scatter_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 928113
	for tone in [Color(0.29, 0.30, 0.31), Color(0.40, 0.39, 0.36), Color(0.47, 0.46, 0.43), Color(0.24, 0.26, 0.28)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = tone
		material.roughness = 0.95
		_rock_materials.append(material)
	var shared_mesh := SphereMesh.new()
	shared_mesh.radius = 1.0
	shared_mesh.height = 1.5
	shared_mesh.radial_segments = 7
	shared_mesh.rings = 4
	for rock_index in range(270):
		var x := rng.randf_range(-113.0, 113.0)
		var z := rng.randf_range(-113.0, 113.0)
		if Vector2(x, z).length() < 8.0 or Vector2(x - 18.0, z + 11.0).length() < 7.5:
			continue
		if Vector2(x - SKYLIGHT_CENTER.x, z - SKYLIGHT_CENTER.y).length() < 10.0:
			continue
		var rock := MeshInstance3D.new()
		rock.mesh = shared_mesh
		rock.material_override = _rock_materials[rng.randi_range(0, _rock_materials.size() - 1)]
		var scale := Vector3(rng.randf_range(0.24, 1.45), rng.randf_range(0.2, 0.95), rng.randf_range(0.22, 1.3))
		rock.scale = scale
		rock.position = Vector3(x, height_at(x, z) + scale.y * 0.34, z)
		rock.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.2, 0.2))
		rock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(rock)

func add_rock_material_override(rock: MeshInstance3D, color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	rock.material_override = material

func _add_landmark_labels() -> void:
	_add_label("MARE TRANQUILLITATIS", Vector2(3.0, -5.0), Color(0.63, 0.82, 0.85))
	_add_label("TERRA HIGHLANDS", Vector2(-61.0, 11.0), Color(0.88, 0.81, 0.68))
	_add_label("MONTES APENNINUS", Vector2(4.0, -91.0), Color(0.91, 0.84, 0.7))
	_add_label("HADLEY RILLE", Vector2(-38.0, 11.0), Color(0.76, 0.85, 0.87))
	_add_label("MARIUS DOME FIELD", Vector2(-4.0, 46.0), Color(0.86, 0.76, 0.61))
	_add_label("DORSA RIDGE", Vector2(16.0, 54.0), Color(0.77, 0.83, 0.84))
	_add_label("LAVA-TUBE SKYLIGHT", SKYLIGHT_CENTER, Color(0.76, 0.88, 0.9))
	_add_label("EJECTA RAY FIELD", Vector2(40.0, -24.0), Color(0.86, 0.83, 0.76))

func _add_label(text: String, point: Vector2, color: Color) -> void:
	var marker := Label3D.new()
	marker.text = text
	marker.font_size = 34
	marker.pixel_size = 0.012
	marker.modulate = color
	marker.outline_size = 5
	marker.outline_modulate = Color(0.035, 0.045, 0.06, 0.92)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = false
	marker.position = Vector3(point.x, height_at(point.x, point.y) + 5.0, point.y)
	add_child(marker)

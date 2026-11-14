extends Node3D
class_name LunarTerrain

const CHUNK_SIZE := 96.0
const STREAM_RADIUS := 2
const NEAR_GRID_STEPS := 48
const FAR_GRID_STEPS := 24
const CRATER_CELL_SIZE := 58.0
const MARE_CENTER := Vector2(5.0, -1.0)
const SKYLIGHT_CENTER := Vector2(43.0, -12.0)
const EJECTA_CENTER := Vector2(29.0, -35.0)
const DOMES := [Vector3(-15.0, 3.8, 31.0), Vector3(-3.0, 3.2, 39.0), Vector3(8.0, 3.6, 31.0), Vector3(56.0, 2.8, 15.0)]
const MOUNTAIN_PEAKS := [Vector3(-74.0, 15.0, -91.0), Vector3(-58.0, 20.0, -98.0), Vector3(-40.0, 17.0, -92.0), Vector3(-21.0, 22.0, -101.0), Vector3(2.0, 15.0, -96.0), Vector3(25.0, 19.0, -103.0), Vector3(49.0, 14.0, -94.0), Vector3(70.0, 18.0, -101.0)]

var _broad_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()
var _highland_noise := FastNoiseLite.new()
var _mare_noise := FastNoiseLite.new()
var _craters: Array[Dictionary] = []
var _generated_craters: Dictionary = {}
var _rock_materials: Array[StandardMaterial3D] = []
var _chunks: Dictionary = {}
var _surface_shader_material: ShaderMaterial

func _ready() -> void:
	_setup_noise()
	_create_craters()
	_create_rock_materials()
	stream_around(Vector3.ZERO)

func stream_around(world_position: Vector3) -> void:
	var center := Vector2i(floori(world_position.x / CHUNK_SIZE), floori(world_position.z / CHUNK_SIZE))
	for z in range(center.y - STREAM_RADIUS, center.y + STREAM_RADIUS + 1):
		for x in range(center.x - STREAM_RADIUS, center.x + STREAM_RADIUS + 1):
			var key := Vector2i(x, z)
			if not _chunks.has(key):
				_build_chunk(key, center)
	for key in _chunks.keys():
		if abs(key.x - center.x) > STREAM_RADIUS or abs(key.y - center.y) > STREAM_RADIUS:
			var old_chunk: Node3D = _chunks[key]
			old_chunk.queue_free()
			_chunks.erase(key)
	var crater_center := Vector2i(floori(world_position.x / CRATER_CELL_SIZE), floori(world_position.z / CRATER_CELL_SIZE))
	for cell in _generated_craters.keys():
		if abs(cell.x - crater_center.x) > 6 or abs(cell.y - crater_center.y) > 6:
			_generated_craters.erase(cell)

func height_at(x: float, z: float) -> float:
	_ensure_crater_cells(x, z)
	var broad := _broad_noise.get_noise_2d(x, z) * 2.1
	var small := _detail_noise.get_noise_2d(x, z) * 0.78
	var highland := _highland_noise.get_noise_2d(x, z) * 1.75
	var highland_mask := smoothstep(12.0, 68.0, absf(x + 34.0))
	var mare_distance := Vector2(x - MARE_CENTER.x, (z - MARE_CENTER.y) * 0.92).length()
	var local_mare := 1.0 - smoothstep(37.0, 80.0, mare_distance)
	var distant_mare := smoothstep(0.14, 0.62, _mare_noise.get_noise_2d(x, z)) * 0.72
	var mare_mask := maxf(local_mare, distant_mare)
	var relief := (broad + small + highland * highland_mask) * (1.0 - mare_mask * 0.55)
	var h := relief - 1.1 * mare_mask

	for crater in _craters:
		var c: Vector2 = crater.center
		var radius: float = crater.radius
		var delta := Vector2(x - c.x, z - c.y)
		if absf(delta.x) > radius * 1.5 or absf(delta.y) > radius * 1.5:
			continue
		var d := delta.length() / radius
		if d < 1.0:
			var bowl := 1.0 - d * d
			h -= crater.depth * bowl * bowl
		h += exp(-pow((d - 1.0) / 0.13, 2.0)) * crater.rim

	h += _procedural_crater_height(x, z)

	# A long, winding rille cuts into the highlands.
	var rille_center := -40.0 + 8.5 * sin((z + 34.0) * 0.052)
	var rille_distance := absf(x - rille_center)
	if z > -96.0 and z < 54.0:
		h -= 3.4 * exp(-pow(rille_distance / 2.5, 2.0))
		h += 0.62 * exp(-pow((rille_distance - 3.6) / 1.05, 2.0))

	# Low wrinkle ridges rise through the basalt plain.
	var ridge_center := 14.0 + 3.2 * sin((z + 5.0) * 0.06)
	var ridge_distance := absf(x - ridge_center)
	if z > -72.0 and z < 77.0:
		h += 1.55 * exp(-pow(ridge_distance / 2.5, 2.0))

	for dome in DOMES:
		var dome_distance := Vector2(x - dome.x, z - dome.z).length()
		h += dome.y * exp(-pow(dome_distance / 8.5, 2.0))

	for peak in MOUNTAIN_PEAKS:
		var dx: float = (x - peak.x) / 8.5
		var dz: float = (z - peak.z) / 18.0
		h += peak.y * exp(-(dx * dx + dz * dz) * 0.5)

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

	_mare_noise.seed = 126715
	_mare_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_mare_noise.frequency = 0.0075
	_mare_noise.fractal_octaves = 2
	_mare_noise.fractal_gain = 0.4

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

func _ensure_crater_cells(x: float, z: float) -> void:
	var cell_x := floori(x / CRATER_CELL_SIZE)
	var cell_z := floori(z / CRATER_CELL_SIZE)
	for offset_z in range(-1, 2):
		for offset_x in range(-1, 2):
			var cell := Vector2i(cell_x + offset_x, cell_z + offset_z)
			if _generated_craters.has(cell):
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = int(hash(cell)) & 0x7fffffff
			var crater: Dictionary = {"active": rng.randf() > 0.36}
			crater["center"] = Vector2((cell.x + rng.randf_range(0.18, 0.82)) * CRATER_CELL_SIZE, (cell.y + rng.randf_range(0.18, 0.82)) * CRATER_CELL_SIZE)
			crater["radius"] = rng.randf_range(3.0, 8.2)
			crater["depth"] = rng.randf_range(1.3, 3.5)
			crater["rim"] = rng.randf_range(0.6, 1.5)
			_generated_craters[cell] = crater

func _procedural_crater_height(x: float, z: float) -> float:
	var cell_x := floori(x / CRATER_CELL_SIZE)
	var cell_z := floori(z / CRATER_CELL_SIZE)
	var height := 0.0
	for offset_z in range(-1, 2):
		for offset_x in range(-1, 2):
			var crater: Dictionary = _generated_craters[Vector2i(cell_x + offset_x, cell_z + offset_z)]
			if not crater.active:
				continue
			var center: Vector2 = crater.center
			var radius: float = crater.radius
			var distance := Vector2(x - center.x, z - center.y).length() / radius
			if distance > 1.6:
				continue
			if distance < 1.0:
				var bowl := 1.0 - distance * distance
				height -= crater.depth * bowl * bowl
			height += crater.rim * exp(-pow((distance - 1.0) / 0.14, 2.0))
	return height

func _build_chunk(key: Vector2i, center: Vector2i) -> void:
	var origin := Vector2(key.x * CHUNK_SIZE, key.y * CHUNK_SIZE)
	var chunk := Node3D.new()
	chunk.name = "Lunar region %d %d" % [key.x, key.y]
	chunk.position = Vector3(origin.x, 0.0, origin.y)
	add_child(chunk)
	_chunks[key] = chunk
	_prepare_crater_cells(origin)

	var lod_distance := maxi(abs(key.x - center.x), abs(key.y - center.y))
	var grid_steps := NEAR_GRID_STEPS if lod_distance <= 1 else FAR_GRID_STEPS
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := CHUNK_SIZE / float(grid_steps)
	for z_index in range(grid_steps + 1):
		var local_z := float(z_index) * step
		var world_z := origin.y + local_z
		for x_index in range(grid_steps + 1):
			var local_x := float(x_index) * step
			var world_x := origin.x + local_x
			var height := height_at(world_x, world_z)
			tool.set_uv(Vector2(world_x, world_z) * 0.12)
			tool.set_color(_surface_color(world_x, world_z, height))
			tool.add_vertex(Vector3(local_x, height, local_z))
	for z_index in range(grid_steps):
		for x_index in range(grid_steps):
			var a := z_index * (grid_steps + 1) + x_index
			var b := a + 1
			var c := a + grid_steps + 1
			var d := c + 1
			tool.add_index(a)
			tool.add_index(b)
			tool.add_index(c)
			tool.add_index(b)
			tool.add_index(d)
			tool.add_index(c)
	tool.generate_normals()
	var terrain_mesh := tool.commit()
	var surface := MeshInstance3D.new()
	surface.name = "Cratered lunar ground"
	surface.mesh = terrain_mesh
	surface.material_override = _terrain_material()
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	surface.visibility_range_end = CHUNK_SIZE * float(STREAM_RADIUS + 1)
	chunk.add_child(surface)

	var body := StaticBody3D.new()
	body.name = "Walkable regolith"
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(terrain_mesh.get_faces())
	collision.shape = shape
	body.add_child(collision)
	chunk.add_child(body)
	_scatter_chunk_rocks(chunk, origin, key)
	if key == Vector2i(0, -1):
		_build_ejecta_rays(chunk, origin)
		_add_landmark_labels(chunk, origin)

func _prepare_crater_cells(origin: Vector2) -> void:
	var min_x := floori((origin.x - CRATER_CELL_SIZE) / CRATER_CELL_SIZE)
	var max_x := floori((origin.x + CHUNK_SIZE + CRATER_CELL_SIZE) / CRATER_CELL_SIZE)
	var min_z := floori((origin.y - CRATER_CELL_SIZE) / CRATER_CELL_SIZE)
	var max_z := floori((origin.y + CHUNK_SIZE + CRATER_CELL_SIZE) / CRATER_CELL_SIZE)
	for z in range(min_z, max_z + 1):
		for x in range(min_x, max_x + 1):
			_ensure_crater_cells((x + 0.5) * CRATER_CELL_SIZE, (z + 0.5) * CRATER_CELL_SIZE)

func _terrain_material() -> ShaderMaterial:
	if _surface_shader_material != null:
		return _surface_shader_material
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
	_surface_shader_material = ShaderMaterial.new()
	_surface_shader_material.shader = shader
	return _surface_shader_material

func _surface_color(x: float, z: float, height: float) -> Color:
	var mare_distance := Vector2(x - MARE_CENTER.x, (z - MARE_CENTER.y) * 0.92).length()
	var local_mare := 1.0 - smoothstep(35.0, 72.0, mare_distance)
	var distant_mare := smoothstep(0.14, 0.62, _mare_noise.get_noise_2d(x, z)) * 0.78
	var mare := maxf(local_mare, distant_mare)
	var highland := smoothstep(-18.0, 68.0, -x + absf(z + 8.0) * 0.27)
	var base := Color(0.29, 0.3, 0.31).lerp(Color(0.44, 0.43, 0.4), highland * 0.7)
	base = base.lerp(Color(0.15, 0.17, 0.19), mare * 0.92)
	var skylight_distance := Vector2(x - SKYLIGHT_CENTER.x, z - SKYLIGHT_CENTER.y).length()
	if skylight_distance < 3.9:
		base = Color(0.035, 0.045, 0.06)
	elif skylight_distance < 8.0:
		base = base.lerp(Color(0.20, 0.22, 0.235), 0.55)
	var dome_distance := Vector2(x + 15.0, z - 31.0).length()
	if dome_distance < 7.0:
		base = base.lerp(Color(0.59, 0.56, 0.51), 0.32)
	if height > 9.0:
		base = base.lerp(Color(0.53, 0.52, 0.48), clampf((height - 9.0) / 15.0, 0.0, 0.48))
	var variation := _detail_noise.get_noise_2d(x * 1.9, z * 1.9) * 0.035
	return Color(base.r + variation, base.g + variation, base.b + variation, 1.0)

func _create_rock_materials() -> void:
	for tone in [Color(0.29, 0.30, 0.31), Color(0.40, 0.39, 0.36), Color(0.47, 0.46, 0.43), Color(0.24, 0.26, 0.28)]:
		var material := StandardMaterial3D.new()
		material.albedo_color = tone
		material.roughness = 0.96
		_rock_materials.append(material)

func _scatter_chunk_rocks(parent: Node3D, origin: Vector2, key: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = (int(hash(key)) & 0x7fffffff) + 928113
	var transforms_by_tone: Array = [[], [], [], []]
	var shared_mesh := SphereMesh.new()
	shared_mesh.radius = 1.0
	shared_mesh.height = 1.5
	shared_mesh.radial_segments = 7
	shared_mesh.rings = 4
	for rock_index in range(28):
		var world_x := origin.x + rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var world_z := origin.y + rng.randf_range(2.0, CHUNK_SIZE - 2.0)
		var scale := Vector3(rng.randf_range(0.22, 1.45), rng.randf_range(0.2, 0.92), rng.randf_range(0.22, 1.3))
		var local_position := Vector3(world_x - origin.x, height_at(world_x, world_z) + scale.y * 0.34, world_z - origin.y)
		var basis := Basis().rotated(Vector3.UP, rng.randf_range(0.0, TAU)).scaled(scale)
		var transform := Transform3D(basis, local_position)
		var tone_index := rng.randi_range(0, _rock_materials.size() - 1)
		transforms_by_tone[tone_index].append(transform)
	for tone_index in range(transforms_by_tone.size()):
		var transforms: Array = transforms_by_tone[tone_index]
		if transforms.is_empty():
			continue
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = shared_mesh
		multimesh.instance_count = transforms.size()
		multimesh.custom_aabb = AABB(Vector3(0.0, -12.0, 0.0), Vector3(CHUNK_SIZE, 44.0, CHUNK_SIZE))
		for index in range(transforms.size()):
			multimesh.set_instance_transform(index, transforms[index])
		var rocks := MultiMeshInstance3D.new()
		rocks.name = "Field stones"
		rocks.multimesh = multimesh
		rocks.material_override = _rock_materials[tone_index]
		rocks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		rocks.visibility_range_end = CHUNK_SIZE * 2.5
		parent.add_child(rocks)

func _build_ejecta_rays(parent: Node3D, origin: Vector2) -> void:
	var ray_material := StandardMaterial3D.new()
	ray_material.albedo_color = Color(0.66, 0.65, 0.61, 0.7)
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
				var height := height_at(point.x, point.y) + 0.075
				ray.set_color(Color(0.84, 0.82, 0.76, (1.0 - t * 0.66) * 0.55))
				ray.add_vertex(Vector3(point.x - origin.x, height, point.y - origin.y))
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
		parent.add_child(strip)

func _add_landmark_labels(parent: Node3D, origin: Vector2) -> void:
	_add_label(parent, origin, "Mare Tranquillitatis", Vector2(3.0, -5.0), Color(0.63, 0.82, 0.85))
	_add_label(parent, origin, "Lunar Highlands", Vector2(-61.0, 11.0), Color(0.88, 0.81, 0.68))
	_add_label(parent, origin, "Mountain Range", Vector2(4.0, -91.0), Color(0.91, 0.84, 0.7))
	_add_label(parent, origin, "Lunar Rille", Vector2(-38.0, 11.0), Color(0.76, 0.85, 0.87))
	_add_label(parent, origin, "Volcanic Domes", Vector2(-4.0, 46.0), Color(0.86, 0.76, 0.61))
	_add_label(parent, origin, "Wrinkle Ridge", Vector2(16.0, 54.0), Color(0.77, 0.83, 0.84))
	_add_label(parent, origin, "Lava Tube Skylight", SKYLIGHT_CENTER, Color(0.76, 0.88, 0.9))
	_add_label(parent, origin, "Ejecta Ray Field", Vector2(40.0, -24.0), Color(0.86, 0.83, 0.76))

func _add_label(parent: Node3D, origin: Vector2, text: String, point: Vector2, color: Color) -> void:
	var marker := Label3D.new()
	marker.text = text
	marker.font_size = 32
	marker.pixel_size = 0.012
	marker.modulate = color
	marker.outline_size = 5
	marker.outline_modulate = Color(0.035, 0.045, 0.06, 0.92)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.position = Vector3(point.x - origin.x, height_at(point.x, point.y) + 5.0, point.y - origin.y)
	parent.add_child(marker)

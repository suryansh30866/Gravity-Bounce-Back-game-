extends CharacterBody3D
class_name LunarAstronaut

signal interact_pressed
signal inventory_pressed
signal hint_pressed
signal command_log_pressed
signal menu_pressed

const LUNAR_GRAVITY := 1.62
const WALK_SPEED := 6.2
const BOOST_SPEED := 9.4
const GROUND_ACCELERATION := 20.0
const AIR_ACCELERATION := 6.2
const ASTRONAUT_MODEL_PATH := "res://assets/characters/astronaut_by_jungle_jim.glb"
const KNOCKBACK_COOLDOWN := 1.15

const LEG_MOTION_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 suit_color : source_color = vec4(1.0);
uniform float suit_metallic = 0.0;
uniform float suit_roughness = 0.8;
uniform vec3 suit_emission : source_color = vec3(0.0);
uniform float suit_emission_energy = 0.0;
uniform float step_phase = 0.0;
uniform float step_swing = 0.0;

void vertex() {
	float leg_weight = 1.0 - smoothstep(0.34, 0.49, VERTEX.y);
	float side = VERTEX.x < 0.0 ? -1.0 : 1.0;
	float phase = step_phase + (side > 0.0 ? PI : 0.0);
	float angle = sin(phase) * step_swing;
	vec3 pivot = vec3(side * 0.11, 0.40, 0.0);
	vec3 local_position = VERTEX - pivot;
	float cosine = cos(angle);
	float sine = sin(angle);
	vec3 moved_position = vec3(
		local_position.x,
		local_position.y * cosine - local_position.z * sine,
		local_position.y * sine + local_position.z * cosine
	);
	VERTEX = mix(VERTEX, pivot + moved_position, leg_weight);
}

void fragment() {
	ALBEDO = suit_color.rgb;
	METALLIC = suit_metallic;
	ROUGHNESS = suit_roughness;
	EMISSION = suit_emission * suit_emission_energy;
}
"""

var boost_fuel := 100.0
var mission_time := 0.0
var _camera_pivot: Node3D
var _camera: Camera3D
var _visuals: Node3D
var _fuel_burn_rate := 18.0
var _surface_grounded := false
var _knockback_cooldown := 0.0
var _step_phase := 0.0
var _step_amount := 0.0
var _walking_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	name = "Astronaut"
	add_to_group("player")
	create_timer(0.45).timeout.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	_build_body()
	_build_camera()

func _physics_process(delta: float) -> void:
	mission_time += delta
	_knockback_cooldown = maxf(0.0, _knockback_cooldown - delta)
	var yaw := _camera_pivot.rotation.y
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var input_x := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var input_y := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	var wish := (right * input_x + forward * input_y).normalized()
	var grounded := is_on_floor() or _surface_grounded
	var boosting := Input.is_key_pressed(KEY_SHIFT) and boost_fuel > 0.0
	var max_speed := BOOST_SPEED if boosting else WALK_SPEED
	var accel := GROUND_ACCELERATION if grounded else AIR_ACCELERATION
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if wish.length_squared() > 0.001:
		horizontal = horizontal.move_toward(wish * max_speed, accel * delta)
	else:
		var drag := 11.5 if grounded else 0.85
		horizontal = horizontal.move_toward(Vector3.ZERO, drag * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if grounded:
		boost_fuel = minf(100.0, boost_fuel + 20.0 * delta)
		if velocity.y < 0.0:
			velocity.y = -0.04
	else:
		velocity.y -= LUNAR_GRAVITY * delta
		if boosting:
			velocity.y = minf(7.2, velocity.y + 4.2 * delta)
			boost_fuel = maxf(0.0, boost_fuel - _fuel_burn_rate * delta)
	if Input.is_key_pressed(KEY_SPACE) and grounded:
		velocity.y = 5.0
		boost_fuel = maxf(0.0, boost_fuel - 5.0)

	move_and_slide()
	var surface := get_parent().get_node_or_null("Lunar geology")
	if surface is LunarTerrain:
		var ground_y: float = surface.height_at(global_position.x, global_position.z)
		if global_position.y <= ground_y + 0.035:
			global_position.y = ground_y
			if velocity.y < 0.0:
				velocity.y = 0.0
			_surface_grounded = true
		else:
			_surface_grounded = is_on_floor()
	_animate_suit(delta, wish, boosting)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotation.y -= event.relative.x * 0.0025
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - event.relative.y * 0.0019, -0.55, 0.65)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			interact_pressed.emit()
		elif event.keycode == KEY_I:
			inventory_pressed.emit()
		elif event.keycode == KEY_H:
			hint_pressed.emit()
		elif event.keycode == KEY_C:
			command_log_pressed.emit()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			menu_pressed.emit()
		elif event.keycode == KEY_TAB:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func get_camera_yaw() -> float:
	return _camera_pivot.rotation.y

func set_camera_yaw(value: float) -> void:
	_camera_pivot.rotation.y = value

func get_follow_camera() -> Camera3D:
	return _camera

func apply_knockback(from_position: Vector3, horizontal_force := 8.6, upward_force := 2.7) -> bool:
	if _knockback_cooldown > 0.0:
		return false
	var away := global_position - from_position
	away.y = 0.0
	if away.length_squared() < 0.001:
		away = -global_transform.basis.z
		away.y = 0.0
	away = away.normalized()
	velocity.x = away.x * horizontal_force
	velocity.z = away.z * horizontal_force
	velocity.y = maxf(velocity.y, upward_force)
	_knockback_cooldown = KNOCKBACK_COOLDOWN
	return true

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.43
	capsule.height = 2.05
	collision.shape = capsule
	collision.position.y = 1.02
	add_child(collision)

	_visuals = Node3D.new()
	_visuals.name = "Astronaut suit"
	add_child(_visuals)
	if _load_astronaut_model():
		return

	var suit := _material(Color(0.82, 0.82, 0.77), 0.78)
	var suit_light := _material(Color(0.94, 0.92, 0.84), 0.72)
	var trim := _material(Color(0.12, 0.22, 0.27), 0.46)
	var gold := _material(Color(0.87, 0.52, 0.2), 0.62)
	var visor := _material(Color(0.025, 0.07, 0.1), 0.25)
	visor.metallic = 0.48
	visor.emission_enabled = true
	visor.emission = Color(0.02, 0.12, 0.16)
	_add_capsule("Pressure suit", Vector3(0.0, 1.05, 0.0), Vector3(0.76, 1.08, 0.56), suit)
	_add_capsule("Helmet", Vector3(0.0, 1.9, 0.0), Vector3(0.7, 0.7, 0.67), suit_light, true)
	_add_sphere("Visor", Vector3(0.0, 1.93, -0.315), Vector3(0.46, 0.33, 0.17), visor)
	_add_capsule("Helmet collar", Vector3(0.0, 1.57, 0.0), Vector3(0.62, 0.2, 0.59), gold)
	_add_box("Life-support pack", Vector3(0.0, 1.22, 0.43), Vector3(0.72, 0.82, 0.4), trim)
	_add_box("Pack panel", Vector3(0.0, 1.28, 0.65), Vector3(0.47, 0.42, 0.07), gold)
	_add_box("Chest control panel", Vector3(0.0, 1.26, -0.298), Vector3(0.34, 0.26, 0.08), trim)
	_add_box("Chest status light", Vector3(0.0, 1.29, -0.346), Vector3(0.14, 0.065, 0.025), _emissive(Color(0.2, 0.86, 0.88)))
	_add_capsule("Left arm", Vector3(-0.49, 1.16, -0.04), Vector3(0.26, 0.78, 0.27), suit)
	_add_capsule("Right arm", Vector3(0.49, 1.16, -0.04), Vector3(0.26, 0.78, 0.27), suit)
	_add_sphere("Left glove", Vector3(-0.52, 0.77, -0.11), Vector3(0.25, 0.23, 0.24), suit_light)
	_add_sphere("Right glove", Vector3(0.52, 0.77, -0.11), Vector3(0.25, 0.23, 0.24), suit_light)
	_add_capsule("Left leg", Vector3(-0.22, 0.4, 0.03), Vector3(0.32, 0.78, 0.33), suit)
	_add_capsule("Right leg", Vector3(0.22, 0.4, 0.03), Vector3(0.32, 0.78, 0.33), suit)
	_add_box("Left lunar boot", Vector3(-0.22, 0.105, -0.08), Vector3(0.35, 0.2, 0.52), trim)
	_add_box("Right lunar boot", Vector3(0.22, 0.105, -0.08), Vector3(0.35, 0.2, 0.52), trim)
	_add_sphere("Left shoulder insignia", Vector3(-0.56, 1.45, -0.035), Vector3(0.1, 0.15, 0.15), gold)
	_add_sphere("Right shoulder insignia", Vector3(0.56, 1.45, -0.035), Vector3(0.1, 0.15, 0.15), gold)

func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "Follow camera pivot"
	_camera_pivot.position = Vector3(0.0, 1.45, 0.0)
	add_child(_camera_pivot)
	_camera = Camera3D.new()
	_camera.name = "Third person camera"
	_camera.position = Vector3(0.0, 2.1, 8.2)
	_camera.rotation.x = -atan2(1.65, 8.2)
	_camera.fov = 70.0
	_camera.near = 0.08
	_camera.far = 1900.0
	_camera.current = true
	_camera_pivot.add_child(_camera)

func _load_astronaut_model() -> bool:
	if not ResourceLoader.exists(ASTRONAUT_MODEL_PATH):
		return false
	var packed_model := load(ASTRONAUT_MODEL_PATH) as PackedScene
	if packed_model == null:
		push_warning("The astronaut GLB could not be loaded. Using the built-in suit model.")
		return false
	var model := packed_model.instantiate() as Node3D
	if model == null:
		push_warning("The astronaut GLB has no Node3D root. Using the built-in suit model.")
		return false
	model.name = "Jungle Jim astronaut"
	model.scale = Vector3.ONE * 2.0
	model.rotation.y = PI
	_visuals.add_child(model)
	var motion_shader := Shader.new()
	motion_shader.code = LEG_MOTION_SHADER
	_apply_leg_shader(model, motion_shader)
	return true

func _apply_leg_shader(root: Node, motion_shader: Shader) -> void:
	for child in root.get_children():
		if child is MeshInstance3D and child.mesh != null:
			var mesh_instance := child as MeshInstance3D
			for surface_index in range(mesh_instance.mesh.get_surface_count()):
				var source_material := mesh_instance.mesh.surface_get_material(surface_index) as StandardMaterial3D
				var walking_material := ShaderMaterial.new()
				walking_material.shader = motion_shader
				walking_material.set_shader_parameter("suit_color", source_material.albedo_color if source_material != null else Color.WHITE)
				walking_material.set_shader_parameter("suit_metallic", source_material.metallic if source_material != null else 0.0)
				walking_material.set_shader_parameter("suit_roughness", source_material.roughness if source_material != null else 0.8)
				walking_material.set_shader_parameter("suit_emission", source_material.emission if source_material != null and source_material.emission_enabled else Color.BLACK)
				walking_material.set_shader_parameter("suit_emission_energy", source_material.emission_energy_multiplier if source_material != null and source_material.emission_enabled else 0.0)
				mesh_instance.set_surface_override_material(surface_index, walking_material)
				_walking_materials.append(walking_material)
		_apply_leg_shader(child, motion_shader)

func _animate_suit(delta: float, wish: Vector3, boosting: bool) -> void:
	if wish.length_squared() > 0.01:
		var target_yaw := atan2(-wish.x, -wish.z)
		_visuals.rotation.y = lerp_angle(_visuals.rotation.y, target_yaw, minf(1.0, delta * 7.0))
	var speed := Vector2(velocity.x, velocity.z).length()
	var moving := (is_on_floor() or _surface_grounded) and speed > 0.45
	var target_step_amount := (0.36 if boosting else 0.24) if moving else 0.0
	_step_amount = move_toward(_step_amount, target_step_amount, delta * 2.8)
	if _step_amount > 0.001:
		_step_phase = fposmod(_step_phase + delta * TAU * (1.62 if boosting else 1.18), TAU)
	for walking_material in _walking_materials:
		walking_material.set_shader_parameter("step_phase", _step_phase)
		walking_material.set_shader_parameter("step_swing", _step_amount)
	var bob := sin(mission_time * 8.5) * minf(0.035, speed * 0.005) if is_on_floor() or _surface_grounded else 0.0
	_visuals.position.y = bob
	_visuals.rotation.z = lerpf(_visuals.rotation.z, -wish.x * 0.025, minf(1.0, delta * 4.0))

func _add_capsule(label: String, point: Vector3, dimensions: Vector3, material: Material, sphere := false) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	if sphere:
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 16
		mesh.rings = 10
		mesh_instance.mesh = mesh
	else:
		var mesh := CapsuleMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 10
		mesh.rings = 4
		mesh_instance.mesh = mesh
	mesh_instance.position = point
	mesh_instance.scale = dimensions
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visuals.add_child(mesh_instance)

func _add_sphere(label: String, point: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 12
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.scale = dimensions
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visuals.add_child(instance)

func _add_box(label: String, point: Vector3, dimensions: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_visuals.add_child(instance)

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _emissive(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.45)
	material.emission_enabled = true
	material.emission = color * 1.6
	return material

func create_timer(seconds: float) -> SceneTreeTimer:
	return get_tree().create_timer(seconds)

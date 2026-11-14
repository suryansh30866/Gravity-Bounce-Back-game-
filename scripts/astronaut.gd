extends CharacterBody3D
class_name LunarAstronaut

signal interact_pressed

const LUNAR_GRAVITY := 1.62
const WALK_SPEED := 7.6
const BOOST_SPEED := 11.2
const GROUND_ACCELERATION := 24.0
const AIR_ACCELERATION := 8.5

var boost_fuel := 100.0
var mission_time := 0.0
var _camera_pivot: Node3D
var _camera: Camera3D
var _visuals: Node3D
var _fuel_burn_rate := 18.0
var _surface_grounded := false

func _ready() -> void:
	name = "Astronaut"
	add_to_group("player")
	create_timer(0.45).timeout.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	_build_body()
	_build_camera()

func _physics_process(delta: float) -> void:
	mission_time += delta
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
			velocity.y = minf(8.4, velocity.y + 5.6 * delta)
			boost_fuel = maxf(0.0, boost_fuel - _fuel_burn_rate * delta)
	if Input.is_key_pressed(KEY_SPACE) and grounded:
		velocity.y = 6.8
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
	_animate_suit(delta, wish)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotation.y -= event.relative.x * 0.0025
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x - event.relative.y * 0.0019, -0.55, 0.65)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			interact_pressed.emit()
		elif event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_tree().change_scene_to_file("res://scenes/home.tscn")

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
	_camera.far = 320.0
	_camera.current = true
	_camera_pivot.add_child(_camera)

func _animate_suit(delta: float, wish: Vector3) -> void:
	if wish.length_squared() > 0.01:
		var target_yaw := atan2(-wish.x, -wish.z)
		_visuals.rotation.y = lerp_angle(_visuals.rotation.y, target_yaw, minf(1.0, delta * 7.0))
	var speed := Vector2(velocity.x, velocity.z).length()
	var bob := sin(mission_time * 8.5) * minf(0.055, speed * 0.008) if is_on_floor() else 0.0
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

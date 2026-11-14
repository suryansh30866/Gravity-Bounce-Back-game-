extends CharacterBody3D
class_name LunarAlien

const ALIEN_MODEL_PATH := "res://assets/aliens/alien_11.obj"
const LUNAR_GRAVITY := 1.62

var terrain: LunarTerrain
var patrol_origin := Vector3.ZERO
var patrol_radius := 9.0
var _visual_root: Node3D
var _visual_base_y := 0.0
var _roam_target := Vector3.ZERO
var _wait_timer := 0.0
var _roaming := false
var _clock := 0.0
var _roam_speed := 1.3
var _random := RandomNumberGenerator.new()

func configure(terrain_ref: LunarTerrain, start_position: Vector3, roam_radius: float, seed_value: int) -> void:
	terrain = terrain_ref
	position = start_position
	patrol_origin = start_position
	patrol_radius = roam_radius
	_random.seed = seed_value * 7919 + 2447
	_wait_timer = _random.randf_range(0.8, 3.8)
	_roam_speed = _random.randf_range(1.15, 1.42)

func _ready() -> void:
	add_to_group("aliens")
	collision_layer = 2
	collision_mask = 3
	_build_collision()
	_build_visual()

func _physics_process(delta: float) -> void:
	if terrain == null:
		return
	_clock += delta
	_wait_timer -= delta
	if not _roaming and _wait_timer <= 0.0:
		_choose_roam_target()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if _roaming:
		var toward := _roam_target - global_position
		toward.y = 0.0
		if toward.length() < 0.8:
			_roaming = false
			_wait_timer = _random.randf_range(2.4, 5.7)
			horizontal = horizontal.move_toward(Vector3.ZERO, 3.5 * delta)
		else:
			var direction := toward.normalized()
			horizontal = horizontal.move_toward(direction * _roam_speed, 2.4 * delta)
			if _visual_root != null:
				_visual_root.rotation.y = lerp_angle(_visual_root.rotation.y, atan2(-direction.x, -direction.z) + PI, minf(1.0, delta * 4.0))
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, 2.7 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var ground_y := terrain.height_at(global_position.x, global_position.z)
	if global_position.y > ground_y + 0.025:
		velocity.y -= LUNAR_GRAVITY * delta
	else:
		global_position.y = ground_y
		if velocity.y < 0.0:
			velocity.y = 0.0
	move_and_slide()
	ground_y = terrain.height_at(global_position.x, global_position.z)
	if global_position.y < ground_y:
		global_position.y = ground_y
		if velocity.y < 0.0:
			velocity.y = 0.0
	if is_instance_valid(_visual_root):
		_visual_root.position.y = _visual_base_y + sin(_clock * 1.75) * (0.025 if not _roaming else 0.012)

func _build_collision() -> void:
	var body_shape := CollisionShape3D.new()
	var body_capsule := CapsuleShape3D.new()
	body_capsule.radius = 0.43
	body_capsule.height = 1.9
	body_shape.shape = body_capsule
	body_shape.position.y = 0.95
	add_child(body_shape)

	var contact_area := Area3D.new()
	contact_area.name = "Player contact"
	contact_area.collision_layer = 0
	contact_area.collision_mask = 1
	contact_area.body_entered.connect(_on_body_entered)
	var contact_shape := CollisionShape3D.new()
	var contact_capsule := CapsuleShape3D.new()
	contact_capsule.radius = 0.88
	contact_capsule.height = 2.25
	contact_shape.shape = contact_capsule
	contact_shape.position.y = 1.12
	contact_area.add_child(contact_shape)
	add_child(contact_area)

func _build_visual() -> void:
	var model := load(ALIEN_MODEL_PATH) as Mesh
	if model == null:
		push_warning("Alien model not found at %s; this NPC has no visible model." % ALIEN_MODEL_PATH)
		return
	var bounds := model.get_aabb()
	var target_height := 2.15
	var fit_scale := target_height / maxf(bounds.size.y, 0.1)
	_visual_base_y = -bounds.position.y * fit_scale
	_visual_root = Node3D.new()
	_visual_root.name = "Alien visual"
	_visual_root.position.y = _visual_base_y
	_visual_root.rotation.y = PI
	add_child(_visual_root)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Alien mesh"
	mesh_instance.mesh = model
	mesh_instance.scale = Vector3.ONE * fit_scale
	mesh_instance.lod_bias = 1.8
	mesh_instance.visibility_range_end = 180.0
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.43, 0.64, 0.48)
	material.roughness = 0.84
	material.metallic = 0.02
	mesh_instance.material_override = material
	_visual_root.add_child(mesh_instance)

func _choose_roam_target() -> void:
	var angle := _random.randf_range(0.0, TAU)
	var distance := _random.randf_range(patrol_radius * 0.35, patrol_radius)
	_roam_target = patrol_origin + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	_roam_target.y = terrain.height_at(_roam_target.x, _roam_target.z)
	_roaming = true

func _on_body_entered(body: Node3D) -> void:
	if body is LunarAstronaut:
		body.apply_knockback(global_position, 8.6, 2.7)

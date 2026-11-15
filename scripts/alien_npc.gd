extends CharacterBody3D
class_name LunarAlien

const ALIEN_MODEL_PATH := "res://assets/aliens/alien_11.obj"
const LUNAR_GRAVITY := 1.62
# The OBJ's body axis is tilted in its authored Y/Z plane; the positive axis
# points from the head toward the feet.
const ALIEN_FEET_AXIS := Vector3(0.0, 0.82939796, 0.55865823)
const ALIEN_HEAD_PROJECTION := -1.1564
const ALIEN_FEET_PROJECTION := 8.5376
const DETECTION_RADIUS := 38.0
const GIVE_UP_RADIUS := 58.0
const CHASE_MEMORY_SECONDS := 4.5
const CHASE_SPEED := 7.1
const CHASE_ACCELERATION := 4.6
const TURN_RATE := 5.0
const MODEL_FORWARD_OFFSET := 0.0
const NAV_REFRESH_SECONDS := 0.16
const STUCK_TIMEOUT := 0.9
const ESCAPE_SECONDS := 1.25
const ALIEN_GAIT_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 alien_tint : source_color = vec4(0.43, 0.64, 0.48, 1.0);
uniform float gait_phase = 0.0;
uniform float gait_amount = 0.0;

void vertex() {
	vec3 feet_axis = normalize(vec3(0.0, 0.82939796, 0.55865823));
	vec3 stride_axis = normalize(vec3(0.0, -0.55865823, 0.82939796));
	float foot_projection = dot(VERTEX, feet_axis);
	float height_from_feet = clamp((8.5376 - foot_projection) / 9.694, 0.0, 1.0);
	float side = VERTEX.x >= 0.0 ? 1.0 : -1.0;
	float lateral_distance = abs(VERTEX.x);
	float cycle = gait_phase + side * PI;
	float legs = (1.0 - smoothstep(0.24, 0.47, height_from_feet)) * smoothstep(0.06, 0.30, lateral_distance);
	float arms = smoothstep(0.48, 0.67, height_from_feet) * (1.0 - smoothstep(0.78, 0.96, height_from_feet)) * smoothstep(0.15, 0.42, lateral_distance);
	float leg_swing = sin(cycle) * 0.78;
	float arm_swing = sin(cycle + PI) * 0.58;
	VERTEX += stride_axis * (leg_swing * legs + arm_swing * arms) * gait_amount;
	VERTEX -= feet_axis * max(sin(cycle), 0.0) * legs * 0.32 * gait_amount;
}

void fragment() {
	ALBEDO = alien_tint.rgb;
	ROUGHNESS = 0.84;
	METALLIC = 0.02;
}
"""

var terrain: LunarTerrain
var chase_target: Node3D
var patrol_origin := Vector3.ZERO
var patrol_radius := 9.0
var _visual_root: Node3D
var _pose_root: Node3D
var _gait_material: ShaderMaterial
var _visual_base_y := 0.0
var _pose_center_offset := 0.0
var _visual_yaw := 0.0
var _visual_alignment := Basis.IDENTITY
var _roam_target := Vector3.ZERO
var _wait_timer := 0.0
var _roaming := false
var _chasing := false
var _chase_memory := 0.0
var _clock := 0.0
var _gait_phase := 0.0
var _navigation_timer := 0.0
var _navigation_goal := Vector3.ZERO
var _steering_direction := Vector3.ZERO
var _escape_direction := Vector3.ZERO
var _escape_timer := 0.0
var _stuck_timer := 0.0
var _previous_goal_distance := -1.0
var _last_navigation_goal := Vector3.ZERO
var _roam_speed := 1.3
var _random := RandomNumberGenerator.new()

func configure(terrain_ref: LunarTerrain, start_position: Vector3, roam_radius: float, seed_value: int, target_ref: Node3D = null) -> void:
	terrain = terrain_ref
	chase_target = target_ref
	position = start_position
	patrol_origin = start_position
	patrol_radius = roam_radius
	_random.seed = seed_value * 7919 + 2447
	_wait_timer = _random.randf_range(0.8, 3.8)
	_roam_speed = _random.randf_range(1.15, 1.42)

func _ready() -> void:
	add_to_group("aliens")
	collision_layer = 2
	# Let aliens walk on terrain without blocking one another in a pack.
	# The separate contact Area3D still detects the astronaut for knockback.
	collision_mask = 1
	if not is_instance_valid(chase_target):
		chase_target = get_tree().get_first_node_in_group("player") as Node3D
	_build_collision()
	_build_visual()

func _physics_process(delta: float) -> void:
	if terrain == null:
		return
	_clock += delta
	_wait_timer -= delta
	_navigation_timer = maxf(0.0, _navigation_timer - delta)
	_escape_timer = maxf(0.0, _escape_timer - delta)
	if not is_instance_valid(chase_target):
		chase_target = get_tree().get_first_node_in_group("player") as Node3D
	var chase_direction := Vector3.ZERO
	if is_instance_valid(chase_target):
		chase_direction = chase_target.global_position - global_position
		chase_direction.y = 0.0
		var player_distance := chase_direction.length()
		if player_distance <= DETECTION_RADIUS:
			if not _chasing:
				SFX.play_once_per_interval("alien_approach", 3.0, -12.0)
			_chasing = true
			_chase_memory = CHASE_MEMORY_SECONDS
		elif _chasing and player_distance <= GIVE_UP_RADIUS:
			_chase_memory = CHASE_MEMORY_SECONDS
		elif _chasing:
			_chase_memory -= delta
			if _chase_memory <= 0.0:
				_chasing = false
				_roaming = false
				_wait_timer = 0.0
	if not _chasing and not _roaming and _wait_timer <= 0.0:
		_choose_roam_target()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var ground_y := terrain.height_at(global_position.x, global_position.z)
	var movement_goal := Vector3.ZERO
	var has_movement_goal := false
	if _chasing and chase_direction.length_squared() > 0.001:
		movement_goal = chase_target.global_position
		has_movement_goal = true
		var direction := _navigation_direction(movement_goal, ground_y)
		horizontal = horizontal.move_toward(direction * CHASE_SPEED, CHASE_ACCELERATION * delta)
	elif _roaming:
		var toward := _roam_target - global_position
		toward.y = 0.0
		if toward.length() < 0.8:
			_roaming = false
			_wait_timer = _random.randf_range(2.4, 5.7)
			horizontal = horizontal.move_toward(Vector3.ZERO, 3.5 * delta)
		else:
			movement_goal = _roam_target
			has_movement_goal = true
			var direction := _navigation_direction(movement_goal, ground_y)
			horizontal = horizontal.move_toward(direction * _roam_speed, 2.4 * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, 2.7 * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	var travel_direction := Vector3(velocity.x, 0.0, velocity.z)
	if travel_direction.length_squared() > 0.04:
		travel_direction = travel_direction.normalized()
		var facing_yaw := atan2(-travel_direction.x, -travel_direction.z) + MODEL_FORWARD_OFFSET
		_set_visual_yaw(rotate_toward(_visual_yaw, facing_yaw, TURN_RATE * delta))
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
	if has_movement_goal:
		_update_stuck_recovery(delta, movement_goal)
	else:
		_stuck_timer = 0.0
		_previous_goal_distance = -1.0
	_update_procedural_animation(delta)

func _navigation_direction(goal: Vector3, current_ground_y: float) -> Vector3:
	var to_goal := goal - global_position
	to_goal.y = 0.0
	if to_goal.length_squared() < 0.01:
		return Vector3.ZERO
	if _escape_timer > 0.0 and _escape_direction.length_squared() > 0.01:
		return _escape_direction
	if _navigation_timer <= 0.0 or _navigation_goal.distance_to(goal) > 2.0:
		_steering_direction = _find_ground_route(goal, current_ground_y, false)
		_navigation_goal = goal
		_navigation_timer = NAV_REFRESH_SECONDS
	return _steering_direction if _steering_direction.length_squared() > 0.01 else to_goal.normalized()

func _find_ground_route(goal: Vector3, current_ground_y: float, force_detour: bool) -> Vector3:
	var to_goal := goal - global_position
	to_goal.y = 0.0
	if to_goal.length_squared() < 0.01:
		return Vector3.ZERO
	var desired := to_goal.normalized()
	var current_distance := to_goal.length()
	var best_direction := desired
	var best_score := -INF
	for angle_value in [0.0, -0.45, 0.45, -0.9, 0.9, -1.35, 1.35]:
		var angle: float = float(angle_value)
		var candidate: Vector3 = desired.rotated(Vector3.UP, angle).normalized()
		var score: float = 0.0
		for distance_value in [2.5, 4.5, 6.5]:
			var probe_distance: float = float(distance_value)
			var probe: Vector3 = global_position + candidate * probe_distance
			var sample_height: float = terrain.height_at(probe.x, probe.z)
			var grade: float = absf(sample_height - current_ground_y) / probe_distance
			var remaining_distance: float = Vector2(goal.x - probe.x, goal.z - probe.z).length()
			var progress: float = current_distance - remaining_distance
			score += progress * 0.62
			score -= maxf(0.0, grade - 0.30) * probe_distance * 6.0
		if force_detour and absf(angle) < 0.1:
			score -= 2.0
		if _steering_direction.length_squared() > 0.01:
			score -= candidate.angle_to(_steering_direction) * 0.45
		if score > best_score:
			best_score = score
			best_direction = candidate
	return best_direction

func _update_stuck_recovery(delta: float, goal: Vector3) -> void:
	var distance_to_goal := Vector2(goal.x - global_position.x, goal.z - global_position.z).length()
	if _last_navigation_goal.distance_to(goal) > 5.0:
		_stuck_timer = 0.0
		_previous_goal_distance = distance_to_goal
		_last_navigation_goal = goal
	elif distance_to_goal > 3.0 and _previous_goal_distance >= 0.0 and _previous_goal_distance - distance_to_goal < 0.025:
		_stuck_timer += delta
	else:
		_stuck_timer = maxf(0.0, _stuck_timer - delta * 1.5)
	_previous_goal_distance = distance_to_goal
	if _stuck_timer >= STUCK_TIMEOUT:
		var ground_y := terrain.height_at(global_position.x, global_position.z)
		_escape_direction = _find_ground_route(goal, ground_y, true)
		_escape_timer = ESCAPE_SECONDS
		_navigation_timer = 0.0
		_stuck_timer = 0.0

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
	var target_height := 2.15
	var model_height := ALIEN_FEET_PROJECTION - ALIEN_HEAD_PROJECTION
	var fit_scale := target_height / maxf(model_height, 0.1)
	# Align the model's head-to-feet axis with world up and pivot its gait at
	# the torso center so the limbs can swing without folding the body.
	_visual_base_y = ALIEN_FEET_PROJECTION * fit_scale
	_pose_center_offset = (ALIEN_FEET_PROJECTION + ALIEN_HEAD_PROJECTION) * 0.5 * fit_scale
	_visual_alignment = Basis(Quaternion(ALIEN_FEET_AXIS, Vector3.DOWN))
	_visual_root = Node3D.new()
	_visual_root.name = "Alien visual"
	_visual_root.position.y = _visual_base_y
	_set_visual_yaw(0.0)
	add_child(_visual_root)
	_pose_root = Node3D.new()
	_pose_root.name = "Alien procedural gait"
	_pose_root.position.y = -_pose_center_offset
	_visual_root.add_child(_pose_root)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Alien mesh"
	mesh_instance.mesh = model
	mesh_instance.position.y = _pose_center_offset
	mesh_instance.scale = Vector3.ONE * fit_scale
	mesh_instance.lod_bias = 1.8
	mesh_instance.visibility_range_end = 180.0
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var gait_shader := Shader.new()
	gait_shader.code = ALIEN_GAIT_SHADER
	_gait_material = ShaderMaterial.new()
	_gait_material.shader = gait_shader
	mesh_instance.material_override = _gait_material
	_pose_root.add_child(mesh_instance)

func _update_procedural_animation(delta: float) -> void:
	if not is_instance_valid(_pose_root):
		return
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var stride := clampf(horizontal_speed / CHASE_SPEED, 0.0, 1.0)
	var cadence := lerpf(2.1, 10.5, stride)
	_gait_phase = fposmod(_gait_phase + delta * cadence, TAU)
	var gait_strength := stride * (1.0 if _chasing else 0.62)
	var idle_breath := sin(_clock * 2.1) * 0.018
	var running_bounce := absf(sin(_gait_phase)) * 0.11 * gait_strength
	_pose_root.position.y = -_pose_center_offset + idle_breath + running_bounce
	# Keep the torso upright; the vertex gait swings the arms and legs instead
	# of making the whole alien look folded forward.
	_pose_root.rotation.x = sin(_gait_phase) * 0.025 * gait_strength
	_pose_root.rotation.z = sin(_gait_phase + PI * 0.5) * 0.085 * gait_strength + sin(_clock * 1.6) * 0.018
	_pose_root.rotation.y = sin(_gait_phase) * 0.045 * gait_strength
	if is_instance_valid(_gait_material):
		_gait_material.set_shader_parameter("gait_phase", _gait_phase)
		_gait_material.set_shader_parameter("gait_amount", gait_strength)

func _set_visual_yaw(yaw: float) -> void:
	_visual_yaw = yaw
	if is_instance_valid(_visual_root):
		_visual_root.basis = Basis(Vector3.UP, _visual_yaw) * _visual_alignment

func _choose_roam_target() -> void:
	var angle := _random.randf_range(0.0, TAU)
	var distance := _random.randf_range(patrol_radius * 0.35, patrol_radius)
	_roam_target = patrol_origin + Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
	_roam_target.y = terrain.height_at(_roam_target.x, _roam_target.z)
	_roaming = true

func _on_body_entered(body: Node3D) -> void:
	if body is LunarAstronaut:
		body.apply_knockback(global_position, 8.6, 2.7)

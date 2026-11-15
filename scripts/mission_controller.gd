extends Node3D
class_name LunarMissionController

const PHASE_TITLES := [
	"Find the return ship",
	"Collect the repair parts",
	"Reconnect the cables",
	"Repair the ship systems",
	"Repair the engine",
	"Launch for Earth",
	"You are home",
]
const SPACE_SHUTTLE_MODEL_PATH := "res://assets/vehicles/space_shuttle.glb"
const COCKPIT_SEAT_LOCAL := Vector3(0.0, 0.0, 4.1)
const PHASE_DETAILS := [
	"Reach the damaged ship. Follow the blue marker.",
	"Find every glowing part and press E to pick it up.",
	"Use one cable connector at each open ship socket.",
	"Install the power cell, flight computer, and antenna.",
	"Fit the new nozzle and coolant pack to the engine.",
	"Go to the cockpit and press E to begin launch.",
	"The ship is back on Earth. Mission complete.",
]
const HINTS := [
	"Follow the blue marker to the return ship. Walk close to the ship, then press E.",
	"The parts are spread around the ship. Follow the arrow, walk beside a glowing case, and press E. Press I to check your pack.",
	"Use the three cable connectors at the red service pads. Start at Power, then Guidance, then Radio.",
	"Go to each red service pad and install the matching part from your pack. The ship will light up when a system is fixed.",
	"The engine pads are near the back of the ship. Install the thruster nozzle and coolant pack.",
	"The final marker leads to the cockpit. Press E when close. Steer with WASD or the arrows and avoid the asteroids.",
	"You made it home. Press R to play again or Esc to return to the menu.",
]

const ITEM_NAMES := {
	"power_cell": "Power cell",
	"flight_computer": "Flight computer",
	"antenna_array": "Radio antenna",
	"thruster_nozzle": "Thruster nozzle",
	"coolant_pack": "Coolant pack",
	"cable_connector": "Cable connector",
}
const ITEM_COLORS := {
	"power_cell": Color(0.26, 0.88, 0.79),
	"flight_computer": Color(0.38, 0.7, 1.0),
	"antenna_array": Color(0.98, 0.69, 0.33),
	"thruster_nozzle": Color(1.0, 0.48, 0.31),
	"coolant_pack": Color(0.45, 0.79, 1.0),
	"cable_connector": Color(0.88, 0.78, 0.44),
}
const ITEM_LAYOUT := [
	{"key": "power_cell", "item": "power_cell", "point": Vector2(-22.0, -20.0)},
	{"key": "flight_computer", "item": "flight_computer", "point": Vector2(44.0, -41.0)},
	{"key": "antenna_array", "item": "antenna_array", "point": Vector2(48.0, 22.0)},
	{"key": "thruster_nozzle", "item": "thruster_nozzle", "point": Vector2(4.0, 44.0)},
	{"key": "coolant_pack", "item": "coolant_pack", "point": Vector2(-49.0, 18.0)},
	{"key": "cable_connector_1", "item": "cable_connector", "point": Vector2(-39.0, -34.0)},
	{"key": "cable_connector_2", "item": "cable_connector", "point": Vector2(48.0, -5.0)},
	{"key": "cable_connector_3", "item": "cable_connector", "point": Vector2(5.0, -54.0)},
]
const CONNECTION_ORDER := ["power_link", "guidance_link", "radio_link"]
const SYSTEM_ORDER := ["power_cell", "flight_computer", "antenna_array"]
const ENGINE_ORDER := ["thruster_nozzle", "coolant_pack"]
const REPAIR_SPECS := [
	{"id": "power_link", "name": "Power cable", "item": "cable_connector", "offset": Vector2(-5.2, 0.0), "phase": 2},
	{"id": "guidance_link", "name": "Guidance cable", "item": "cable_connector", "offset": Vector2(5.2, 0.0), "phase": 2},
	{"id": "radio_link", "name": "Radio cable", "item": "cable_connector", "offset": Vector2(0.0, -5.2), "phase": 2},
	{"id": "power_cell", "name": "Power system", "item": "power_cell", "offset": Vector2(-2.4, -1.2), "phase": 3},
	{"id": "flight_computer", "name": "Flight computer", "item": "flight_computer", "offset": Vector2(2.4, -1.2), "phase": 3},
	{"id": "antenna_array", "name": "Radio antenna", "item": "antenna_array", "offset": Vector2(0.0, 5.1), "phase": 3},
	{"id": "thruster_nozzle", "name": "Thruster nozzle", "item": "thruster_nozzle", "offset": Vector2(-2.5, 5.4), "phase": 4},
	{"id": "coolant_pack", "name": "Coolant system", "item": "coolant_pack", "offset": Vector2(2.5, 5.4), "phase": 4},
]
const MAX_CARRY := 8
const EARTH_BLACKOUT_SURFACE_RANGE := 5000.0
const EARTH_RADIUS := 130.0
const EARTH_BLACKOUT_RANGE := EARTH_BLACKOUT_SURFACE_RANGE + EARTH_RADIUS
const FLIGHT_SPEED := 60.0

var terrain: LunarTerrain
var astronaut: LunarAstronaut
var habitat_position := Vector3.ZERO
var ship_position := Vector3.ZERO
var ship_root: Node3D
var inventory: Dictionary = {}
var inventory_count := 0
var mission_phase := 0
var credits := 0
var mission_seconds := 0.0

var _pickup_nodes: Dictionary = {}
var _pickup_data: Dictionary = {}
var _pickup_positions: Dictionary = {}
var _repair_positions: Dictionary = {}
var _repair_visuals: Dictionary = {}
var _repair_done: Dictionary = {}
var _repair_specs_by_id: Dictionary = {}
var _cockpit_position := Vector3.ZERO
var _marker: Node3D
var _marker_target := Vector3.ZERO
var _marker_label: Label3D
var _marker_arrow_root: Node3D
var _direction_arrow_label: Label
var _arrow_clock := 0.0
var _earth: MeshInstance3D
var _earth_halo: OmniLight3D
var _moon_orbit_visual: MeshInstance3D
var _launch_started := false
var _shuttle_flight_pivot: Node3D
var _shuttle_flight_attitude: Node3D
var _launch_flames: Array[MeshInstance3D] = []
var _launch_dust: GPUParticles3D
var _launch_engine_light: OmniLight3D
var _launch_camera_pivot: Node3D
var _launch_camera_rest_position := Vector3.ZERO
var _launch_shake_strength := 0.0
var _launch_effect_clock := 0.0
var _launch_engines_active := false
var _flight_crashed := false
var _flight_elapsed := 0.0
var _flight_speed := 0.0
var _flight_route_distance := 0.0
var _flight_route_start_distance := 0.0
var _flight_yaw := 0.0
var _flight_pitch := 0.0
var _flight_asteroids: Array[Dictionary] = []
var _stream_clock := 0.0
var _command_log: Array[String] = []

var _ui: CanvasLayer
var _phase_title: Label
var _phase_detail: Label
var _distance_label: Label
var _interaction_label: Label
var _toast_label: Label
var _task_count_label: Label
var _task_labels: Array[Label] = []
var _inventory_count_label: Label
var _inventory_summary_label: Label
var _inventory_detail_label: Label
var _inventory_panel: PanelContainer
var _command_label: Label
var _command_time_label: Label
var _command_log_panel: PanelContainer
var _command_log_label: Label
var _credits_label: Label
var _boost_bar: ProgressBar
var _mission_clock_label: Label
var _progress_labels: Array[Label] = []
var _complete_panel: PanelContainer
var _console_font: Font
var _toast_timer := 0.0
var _arrival_overlay: CanvasLayer
var _arrival_video: VideoStreamPlayer
var _arrival_fade: ColorRect
var _flight_ui: CanvasLayer
var _flight_range_label: Label
var _flight_speed_label: Label
var _flight_attitude_label: Label
var _flight_status_label: Label
var _flight_hazard_label: Label
var _flight_progress: ProgressBar
var _crash_panel: PanelContainer

func configure(terrain_ref: LunarTerrain, player: LunarAstronaut, habitat: Vector3, return_ship: Vector3, earth: MeshInstance3D, earth_halo: OmniLight3D, moon_visual: MeshInstance3D) -> void:
	terrain = terrain_ref
	astronaut = player
	habitat_position = habitat
	ship_position = return_ship
	_earth = earth
	_earth_halo = earth_halo
	_moon_orbit_visual = moon_visual
	_build_return_ship()
	_create_pickups()
	_create_repair_points()
	_build_world_marker()
	_build_hud()
	_build_arrival_overlay()
	_update_phase()
	_commander_message("Welcome back, Commander Hale. Reach the damaged return ship and I will guide you through every repair.")
	_set_message("Your return ship is damaged. Mission Control is ready to help.", Color(0.72, 0.92, 0.87))

func _process(delta: float) -> void:
	if astronaut == null or terrain == null:
		return
	_update_launch_effects(delta)
	mission_seconds += delta
	_stream_clock += delta
	if not _launch_started and _stream_clock >= 0.5:
		_stream_clock = 0.0
		terrain.stream_around(astronaut.global_position)
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.modulate.a = 0.0
	if is_instance_valid(_marker) and mission_phase < 6:
		_arrow_clock += delta
		_marker.rotation.y += delta * 1.05
		_marker.global_position = _marker_target + Vector3.UP * (2.45 + sin(_arrow_clock * 3.0) * 0.42)
		if is_instance_valid(_marker_arrow_root):
			var arrow_bob := sin(_arrow_clock * 4.2)
			_marker_arrow_root.position = Vector3(sin(_arrow_clock * 2.6) * 0.2, 0.48 + arrow_bob * 0.26, cos(_arrow_clock * 1.9) * 0.08)
			_marker_arrow_root.rotation.z = sin(_arrow_clock * 2.6) * 0.16
			var arrow_scale := 1.0 + (0.5 + 0.5 * sin(_arrow_clock * 5.0)) * 0.16
			_marker_arrow_root.scale = Vector3.ONE * arrow_scale
	_update_mission_progress()
	_update_hud()
	if _launch_started and not _flight_crashed:
		_update_flight_hud()
		for hazard in _flight_asteroids:
			var asteroid := hazard.get("node") as Node3D
			if is_instance_valid(asteroid):
				asteroid.rotate_y(delta * 0.12)
	if _flight_crashed and Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
	if mission_phase == 6 and Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

func _update_launch_effects(delta: float) -> void:
	_launch_effect_clock += delta
	if is_instance_valid(_launch_camera_pivot):
		if _launch_shake_strength > 0.001:
			var time := _launch_effect_clock
			var shake := _launch_shake_strength
			_launch_camera_pivot.position = _launch_camera_rest_position + Vector3(sin(time * 47.0) * shake, sin(time * 71.0 + 1.3) * shake * 0.68, cos(time * 59.0) * shake * 0.52)
		else:
			_launch_camera_pivot.position = _launch_camera_rest_position
	if _launch_engines_active:
		var flicker_phase := _launch_effect_clock * 18.0
		for index in range(_launch_flames.size()):
			var flame := _launch_flames[index]
			flame.scale.y = 0.78 + 0.22 * (0.5 + 0.5 * sin(flicker_phase + float(index) * 1.7))
		if is_instance_valid(_launch_engine_light):
			_launch_engine_light.light_energy = 3.8 + 0.65 * sin(flicker_phase * 0.75)

func _set_launch_attitude(pitch: float, yaw: float) -> void:
	if is_instance_valid(_shuttle_flight_attitude):
		_shuttle_flight_attitude.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, PI)

func _build_return_ship() -> void:
	ship_root = Node3D.new()
	ship_root.name = "Damaged return ship"
	add_child(ship_root)
	var hull_body := StaticBody3D.new()
	hull_body.name = "Return ship hull"
	hull_body.position = ship_position
	var hull_shape := CollisionShape3D.new()
	var hull_collider := CylinderShape3D.new()
	hull_collider.radius = 1.45
	hull_collider.height = 3.2
	hull_shape.shape = hull_collider
	hull_shape.position.y = 2.75
	hull_body.add_child(hull_shape)
	ship_root.add_child(hull_body)
	var procedural_hull := Node3D.new()
	procedural_hull.name = "Procedural return ship fallback"
	ship_root.add_child(procedural_hull)
	var shell := _material(Color(0.75, 0.73, 0.66), 0.72)
	var pale := _material(Color(0.88, 0.87, 0.79), 0.65)
	var gold := _material(Color(0.83, 0.55, 0.25), 0.58)
	var dark := _material(Color(0.1, 0.15, 0.18), 0.64)
	var glass := _material(Color(0.035, 0.13, 0.19), 0.18)
	glass.metallic = 0.42
	var alert := _emissive(Color(1.0, 0.28, 0.14))
	var quiet := _emissive(Color(0.16, 0.82, 0.78))

	_add_cylinder("Return ship lower deck", ship_position + Vector3(0.0, 1.8, 0.0), 2.25, 1.0, gold, 8, procedural_hull)
	_add_cylinder("Heat shield", ship_position + Vector3(0.0, 1.22, 0.0), 1.8, 0.28, dark, 10, procedural_hull)
	_add_cylinder("Cabin pressure shell", ship_position + Vector3(0.0, 3.05, 0.0), 1.45, 1.55, shell, 8, procedural_hull)
	_add_cylinder("Cabin roof", ship_position + Vector3(0.0, 3.94, 0.0), 1.05, 0.26, pale, 8, procedural_hull)
	_add_box("Forward cockpit glass", ship_position + Vector3(0.0, 3.25, -1.06), Vector3(1.25, 0.52, 0.12), glass, procedural_hull)
	_add_box("Cabin access hatch", ship_position + Vector3(0.0, 2.25, -1.45), Vector3(0.62, 0.94, 0.12), dark, procedural_hull)
	_add_box("Hull side panel", ship_position + Vector3(-1.45, 2.2, 0.0), Vector3(0.16, 0.65, 1.2), pale, procedural_hull)
	_add_box("Damaged hull plate", ship_position + Vector3(1.45, 2.15, 0.15), Vector3(0.12, 0.48, 1.0), gold, procedural_hull)
	_add_cylinder("Main engine mount", ship_position + Vector3(0.0, 0.72, 0.0), 0.86, 0.6, dark, 10, procedural_hull)
	for side in [-1.0, 1.0]:
		_add_cylinder("Landing engine", ship_position + Vector3(side * 0.68, 0.58, 0.0), 0.34, 0.42, dark, 8, procedural_hull)
		_add_box("Solar wing", ship_position + Vector3(side * 4.25, 2.4, 0.0), Vector3(3.2, 0.12, 1.55), dark, procedural_hull)
		for row in range(3):
			_add_box("Solar cell row", ship_position + Vector3(side * 4.25, 2.48, -0.49 + row * 0.49), Vector3(2.95, 0.035, 0.035), quiet, procedural_hull)
		var foot := ship_position + Vector3(side * 3.1, 0.12, 1.7)
		_add_cylinder_between("Landing leg", ship_position + Vector3(side * 0.75, 1.55, 0.4), foot + Vector3(0.0, 0.5, 0.0), 0.12, pale, procedural_hull)
		_add_box("Landing foot", foot, Vector3(0.72, 0.17, 0.66), dark, procedural_hull)
	for side in [-1.0, 1.0]:
		_add_cylinder_between("Broken cable", ship_position + Vector3(side * 1.6, 2.05, -0.1), ship_position + Vector3(side * 2.35, 0.45, 0.72), 0.045, alert, ship_root)
	_add_cylinder_between("Bent antenna mast", ship_position + Vector3(0.0, 4.0, 0.0), ship_position + Vector3(0.72, 5.2, 0.24), 0.055, dark, ship_root)
	_add_box("Missing radio array socket", ship_position + Vector3(0.0, 4.35, 0.28), Vector3(0.84, 0.1, 0.15), alert, ship_root)
	_add_sphere("Broken power indicator", ship_position + Vector3(0.0, 4.15, -0.94), Vector3(0.16, 0.16, 0.08), alert, ship_root)
	_add_label("RETURN SHIP  /  REPAIR REQUIRED", ship_position + Vector3(0.0, 6.3, 0.0), Color(0.9, 0.78, 0.55), ship_root)
	for mesh_instance in procedural_hull.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.layers = 2
	_install_space_shuttle(procedural_hull)
	_build_lunar_dust()

func _install_space_shuttle(procedural_fallback: Node3D) -> void:
	if not ResourceLoader.exists(SPACE_SHUTTLE_MODEL_PATH):
		return
	var packed_model := load(SPACE_SHUTTLE_MODEL_PATH) as PackedScene
	if packed_model == null:
		push_warning("The shuttle asset must be a Godot-compatible GLB scene at %s." % SPACE_SHUTTLE_MODEL_PATH)
		return
	var shuttle := packed_model.instantiate() as Node3D
	if shuttle == null:
		push_warning("The shuttle model has no Node3D root; keeping the procedural return ship.")
		return
	shuttle.name = "Sketchfab Space Shuttle"
	ship_root.add_child(shuttle)
	var bounds := _get_node_mesh_bounds(shuttle)
	if bounds.size.length_squared() < 0.001:
		push_warning("The shuttle model contains no visible mesh; keeping the procedural return ship.")
		shuttle.queue_free()
		return
	var horizontal_span := maxf(bounds.size.x, bounds.size.z)
	var fit_scale := 15.5 / maxf(horizontal_span, 0.1)
	var center := bounds.get_center()
	ship_root.remove_child(shuttle)
	_shuttle_flight_pivot = Node3D.new()
	_shuttle_flight_pivot.name = "Shuttle flight pivot"
	_shuttle_flight_pivot.position = ship_position + Vector3(-center.x * fit_scale, bounds.size.y * 0.5 * fit_scale + 0.12, -center.z * fit_scale)
	ship_root.add_child(_shuttle_flight_pivot)
	_shuttle_flight_attitude = Node3D.new()
	_shuttle_flight_attitude.name = "Shuttle launch attitude"
	_shuttle_flight_attitude.basis = Basis(Vector3.UP, PI)
	_shuttle_flight_pivot.add_child(_shuttle_flight_attitude)
	_shuttle_flight_attitude.add_child(shuttle)
	shuttle.position = -center * fit_scale
	shuttle.scale = Vector3.ONE * fit_scale
	for mesh_instance in shuttle.find_children("*", "MeshInstance3D", true, false):
		mesh_instance.lod_bias = 1.4
		mesh_instance.visibility_range_end = 500.0
		mesh_instance.layers = 2
	_build_engine_plumes(bounds, center, fit_scale)
	procedural_fallback.visible = false

func _build_engine_plumes(bounds: AABB, center: Vector3, fit_scale: float) -> void:
	_launch_flames.clear()
	var tail_z := (bounds.position.z + bounds.size.z * 0.1 - center.z) * fit_scale
	var engine_y := (bounds.position.y + bounds.size.y * 0.2 - center.y) * fit_scale
	var engine_spacing := bounds.size.x * 0.075 * fit_scale
	var engine_offsets := [-engine_spacing, 0.0, engine_spacing]
	for engine_index in range(engine_offsets.size()):
		var nozzle := Vector3(float(engine_offsets[engine_index]), engine_y, tail_z)
		_add_engine_flame(nozzle, 7.5, 0.46, Color(0.28, 0.72, 1.0, 0.34), 3.0)
		_add_engine_flame(nozzle, 5.3, 0.24, Color(0.82, 0.95, 1.0, 0.82), 6.0)
	_launch_engine_light = OmniLight3D.new()
	_launch_engine_light.name = "Engine ignition light"
	_launch_engine_light.position = Vector3(0.0, engine_y, tail_z)
	_launch_engine_light.light_color = Color(0.38, 0.72, 1.0)
	_launch_engine_light.light_energy = 0.0
	_launch_engine_light.omni_range = 14.0
	_shuttle_flight_attitude.add_child(_launch_engine_light)

func _add_engine_flame(nozzle: Vector3, flame_length: float, flame_radius: float, color: Color, energy: float) -> void:
	var flame := MeshInstance3D.new()
	flame.name = "Main engine flame"
	var flame_mesh := CylinderMesh.new()
	flame_mesh.top_radius = 0.015
	flame_mesh.bottom_radius = flame_radius
	flame_mesh.height = flame_length
	flame_mesh.radial_segments = 8
	flame.mesh = flame_mesh
	flame.rotation.x = -PI * 0.5
	flame.position = nozzle + Vector3(0.0, 0.0, -flame_length * 0.5)
	flame.material_override = _launch_flame_material(color, energy)
	flame.visible = false
	_shuttle_flight_attitude.add_child(flame)
	_launch_flames.append(flame)

func _launch_flame_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = Color(color.r, color.g, color.b)
	material.emission_energy_multiplier = energy
	return material

func _build_lunar_dust() -> void:
	_launch_dust = GPUParticles3D.new()
	_launch_dust.name = "Lunar engine dust plume"
	_launch_dust.position = ship_position + Vector3(0.0, 0.45, 0.0)
	_launch_dust.amount = 320
	_launch_dust.lifetime = 7.0
	_launch_dust.explosiveness = 0.38
	_launch_dust.one_shot = true
	_launch_dust.emitting = false
	_launch_dust.visibility_aabb = AABB(Vector3(-80.0, -20.0, -80.0), Vector3(160.0, 80.0, 160.0))
	var dust_process := ParticleProcessMaterial.new()
	dust_process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	dust_process.emission_sphere_radius = 1.7
	dust_process.direction = Vector3(0.0, 0.9, 0.0)
	dust_process.spread = 180.0
	dust_process.initial_velocity_min = 3.5
	dust_process.initial_velocity_max = 12.0
	dust_process.gravity = Vector3(0.0, -0.65, 0.0)
	dust_process.scale_min = 0.65
	dust_process.scale_max = 2.1
	var dust_gradient := Gradient.new()
	dust_gradient.set_color(0, Color(0.7, 0.65, 0.56, 0.34))
	dust_gradient.add_point(0.68, Color(0.62, 0.58, 0.5, 0.22))
	dust_gradient.set_color(1, Color(0.55, 0.52, 0.46, 0.0))
	var dust_ramp := GradientTexture1D.new()
	dust_ramp.gradient = dust_gradient
	dust_process.color_ramp = dust_ramp
	_launch_dust.process_material = dust_process
	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.12
	dust_mesh.height = 0.24
	dust_mesh.radial_segments = 5
	dust_mesh.rings = 3
	var dust_surface := StandardMaterial3D.new()
	dust_surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_surface.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_surface.albedo_color = Color.WHITE
	dust_surface.vertex_color_use_as_albedo = true
	dust_mesh.material = dust_surface
	_launch_dust.draw_pass_1 = dust_mesh
	add_child(_launch_dust)

func _get_node_mesh_bounds(root: Node3D) -> AABB:
	var merged := AABB()
	var has_bounds := false
	for mesh_instance in root.find_children("*", "MeshInstance3D", true, false):
		if mesh_instance.mesh == null:
			continue
		var relative_transform: Transform3D = root.global_transform.affine_inverse() * mesh_instance.global_transform
		var mesh_bounds: AABB = _transform_bounds(mesh_instance.get_aabb(), relative_transform)
		merged = mesh_bounds if not has_bounds else merged.merge(mesh_bounds)
		has_bounds = true
	return merged

func _transform_bounds(bounds: AABB, transform: Transform3D) -> AABB:
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for x in [bounds.position.x, bounds.position.x + bounds.size.x]:
		for y in [bounds.position.y, bounds.position.y + bounds.size.y]:
			for z in [bounds.position.z, bounds.position.z + bounds.size.z]:
				var point: Vector3 = transform * Vector3(x, y, z)
				minimum = Vector3(minf(minimum.x, point.x), minf(minimum.y, point.y), minf(minimum.z, point.z))
				maximum = Vector3(maxf(maximum.x, point.x), maxf(maximum.y, point.y), maxf(maximum.z, point.z))
	return AABB(minimum, maximum - minimum)

func _create_pickups() -> void:
	for item_data in ITEM_LAYOUT:
		var key: String = item_data.key
		var item_id: String = item_data.item
		var point: Vector2 = item_data.point
		var ground := Vector3(point.x, terrain.height_at(point.x, point.y), point.y)
		var pickup := Node3D.new()
		pickup.name = "Scavenged part - " + str(ITEM_NAMES[item_id])
		pickup.position = ground
		add_child(pickup)
		var color: Color = ITEM_COLORS[item_id]
		var crate_material := _material(Color(0.15, 0.19, 0.2), 0.65)
		_add_box("Sealed part case", Vector3(0.0, 0.48, 0.0), Vector3(0.9, 0.72, 0.68), crate_material, pickup)
		_add_box("Case color stripe", Vector3(0.0, 0.52, -0.35), Vector3(0.64, 0.12, 0.04), _emissive(color), pickup)
		_add_box("Case latch", Vector3(0.0, 0.16, -0.38), Vector3(0.18, 0.14, 0.05), _material(Color(0.69, 0.7, 0.66), 0.42), pickup)
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.78
		ring_mesh.outer_radius = 0.88
		ring_mesh.ring_segments = 5
		ring_mesh.rings = 20
		ring.mesh = ring_mesh
		ring.position.y = 0.08
		ring.material_override = _emissive(color)
		ring.visibility_range_end = 210.0
		pickup.add_child(ring)
		var lamp := OmniLight3D.new()
		lamp.light_color = color
		lamp.light_energy = 0.5
		lamp.omni_range = 4.0
		lamp.position.y = 0.9
		pickup.add_child(lamp)
		_add_label(str(ITEM_NAMES[item_id]), Vector3(0.0, 1.7, 0.0), color, pickup)
		_pickup_nodes[key] = pickup
		_pickup_data[key] = item_data
		_pickup_positions[key] = ground

func _create_repair_points() -> void:
	for spec in REPAIR_SPECS:
		var id: String = spec.id
		var offset: Vector2 = spec.offset
		var world_x := ship_position.x + offset.x
		var world_z := ship_position.z + offset.y
		var point := Vector3(world_x, terrain.height_at(world_x, world_z), world_z)
		_repair_positions[id] = point
		_repair_specs_by_id[id] = spec
		_repair_done[id] = false
		var pad := Node3D.new()
		pad.name = "Repair station - " + str(spec.name)
		pad.position = point
		add_child(pad)
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.78
		ring_mesh.outer_radius = 0.91
		ring_mesh.ring_segments = 5
		ring_mesh.rings = 22
		ring.mesh = ring_mesh
		ring.position.y = 0.11
		ring.visibility_range_end = 180.0
		pad.add_child(ring)
		var status := MeshInstance3D.new()
		var status_mesh := CylinderMesh.new()
		status_mesh.top_radius = 0.11
		status_mesh.bottom_radius = 0.2
		status_mesh.height = 0.72
		status_mesh.radial_segments = 8
		status.mesh = status_mesh
		status.position.y = 0.52
		status.visibility_range_end = 180.0
		pad.add_child(status)
		var light := OmniLight3D.new()
		light.light_energy = 0.42
		light.omni_range = 3.4
		light.position.y = 0.8
		pad.add_child(light)
		_add_label(str(spec.name), Vector3(0.0, 1.25, 0.0), Color(0.94, 0.69, 0.42), pad)
		_repair_visuals[id] = {"ring": ring, "status": status, "light": light}
		_refresh_repair_visual(id)

	var cockpit_z := ship_position.z - 6.2
	_cockpit_position = Vector3(ship_position.x, terrain.height_at(ship_position.x, cockpit_z), cockpit_z)

func _refresh_repair_visual(id: String) -> void:
	if not _repair_visuals.has(id):
		return
	var visual: Dictionary = _repair_visuals[id]
	var done: bool = _repair_done.get(id, false)
	var active_id := _active_repair_id()
	var color := Color(0.25, 0.91, 0.72) if done else Color(0.25, 0.86, 0.91) if id == active_id else Color(0.94, 0.35, 0.2)
	visual.ring.material_override = _emissive(color)
	visual.status.material_override = _emissive(color)
	visual.light.light_color = color
	visual.light.light_energy = 0.52 if id == active_id and not done else 0.2

func _build_world_marker() -> void:
	_marker = Node3D.new()
	_marker.name = "Active objective marker"
	var ring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.62
	ring_mesh.outer_radius = 0.78
	ring_mesh.rings = 5
	ring_mesh.ring_segments = 22
	ring.mesh = ring_mesh
	ring.rotation_degrees.x = 90.0
	ring.position.y = 0.12
	ring.material_override = _emissive(Color(0.23, 0.95, 0.88))
	_marker.add_child(ring)
	_marker_arrow_root = Node3D.new()
	_marker_arrow_root.name = "Bobbing direction arrow"
	_marker_arrow_root.position.y = 0.48
	_marker.add_child(_marker_arrow_root)
	var arrow := MeshInstance3D.new()
	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.4
	arrow_mesh.height = 0.78
	arrow.mesh = arrow_mesh
	arrow.position.y = 1.3
	arrow.material_override = _emissive(Color(0.45, 1.0, 0.9))
	_marker_arrow_root.add_child(arrow)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.06
	stem_mesh.bottom_radius = 0.1
	stem_mesh.height = 1.25
	stem.mesh = stem_mesh
	stem.position.y = 0.35
	stem.material_override = _emissive(Color(0.18, 0.68, 0.7))
	_marker_arrow_root.add_child(stem)
	_marker_label = _label_3d("NEXT TASK", 32, Color(0.66, 0.96, 0.89))
	_marker_label.position = Vector3(0.0, 2.12, 0.0)
	_marker.add_child(_marker_label)
	add_child(_marker)

func _build_hud() -> void:
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_console_font = mono
	_ui = CanvasLayer.new()
	_ui.layer = 3
	add_child(_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var brand := _label("GRAVITY  /  LUNAR RETURN MISSION", 13, Color(0.82, 0.9, 0.87))
	brand.position = Vector2(26.0, 22.0)
	brand.size = Vector2(380.0, 25.0)
	root.add_child(brand)
	var location := _label("MARE TRANQUILLITATIS  •  MOON", 9, Color(0.54, 0.68, 0.7))
	location.position = Vector2(26.0, 49.0)
	location.size = Vector2(380.0, 18.0)
	root.add_child(location)

	var objective_card := _panel(Color(0.012, 0.026, 0.038, 0.88), Color(0.31, 0.75, 0.71, 0.58))
	objective_card.anchor_left = 0.5
	objective_card.anchor_right = 0.5
	objective_card.offset_left = -240.0
	objective_card.offset_top = 18.0
	objective_card.offset_right = 240.0
	objective_card.offset_bottom = 104.0
	root.add_child(objective_card)
	var objective_copy := VBoxContainer.new()
	objective_copy.add_theme_constant_override("separation", 3)
	objective_card.add_child(objective_copy)
	_phase_title = _label(PHASE_TITLES[0], 17, Color(0.9, 0.96, 0.92))
	_phase_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_copy.add_child(_phase_title)
	_phase_detail = _label(PHASE_DETAILS[0], 10, Color(0.62, 0.75, 0.73))
	_phase_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_copy.add_child(_phase_detail)

	_direction_arrow_label = _label("↑", 38, Color(0.42, 1.0, 0.88))
	_direction_arrow_label.anchor_left = 0.5
	_direction_arrow_label.anchor_right = 0.5
	_direction_arrow_label.offset_left = -31.0
	_direction_arrow_label.offset_top = 108.0
	_direction_arrow_label.offset_right = 31.0
	_direction_arrow_label.offset_bottom = 151.0
	_direction_arrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_direction_arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_direction_arrow_label.resized.connect(func(): _direction_arrow_label.pivot_offset = _direction_arrow_label.size * 0.5)
	root.add_child(_direction_arrow_label)

	_distance_label = _label("000 M  •  FOLLOW THE MARKER", 15, Color(0.76, 0.92, 0.87))
	_distance_label.anchor_left = 0.5
	_distance_label.anchor_right = 0.5
	_distance_label.offset_left = -240.0
	_distance_label.offset_top = 153.0
	_distance_label.offset_right = 240.0
	_distance_label.offset_bottom = 179.0
	_distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_distance_label)

	var task_card := _panel(Color(0.013, 0.027, 0.039, 0.84), Color(0.36, 0.62, 0.64, 0.4))
	task_card.position = Vector2(24.0, 158.0)
	task_card.size = Vector2(336.0, 247.0)
	root.add_child(task_card)
	var task_copy := VBoxContainer.new()
	task_copy.add_theme_constant_override("separation", 5)
	task_card.add_child(task_copy)
	var task_heading := _label("MISSION TASKS", 10, Color(0.55, 0.81, 0.76))
	task_copy.add_child(task_heading)
	_task_count_label = _label("0 / 1 complete", 9, Color(0.55, 0.68, 0.69))
	task_copy.add_child(_task_count_label)
	for index in range(8):
		var row := _label("", 9, Color(0.73, 0.8, 0.78))
		row.custom_minimum_size.y = 17.0
		row.autowrap_mode = TextServer.AUTOWRAP_OFF
		task_copy.add_child(row)
		_task_labels.append(row)

	var command_card := _panel(Color(0.012, 0.027, 0.04, 0.9), Color(0.36, 0.68, 0.71, 0.52))
	command_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	command_card.position = Vector2(-326.0, 18.0)
	command_card.size = Vector2(302.0, 184.0)
	root.add_child(command_card)
	var command_copy := VBoxContainer.new()
	command_copy.add_theme_constant_override("separation", 5)
	command_card.add_child(command_copy)
	var command_heading := _label("COMMAND DECK  /  MISSION CONTROL", 9, Color(0.53, 0.84, 0.79))
	command_copy.add_child(command_heading)
	_command_time_label = _label("Commander Sato  •  live link", 8, Color(0.55, 0.68, 0.7))
	command_copy.add_child(_command_time_label)
	_command_label = _label("Waiting for your first report.", 10, Color(0.83, 0.88, 0.83))
	_command_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_command_label.custom_minimum_size.y = 73.0
	command_copy.add_child(_command_label)
	var command_controls := _label("H  ASK FOR A HINT     /     C  COMMAND LOG", 8, Color(0.47, 0.73, 0.72))
	command_copy.add_child(command_controls)

	var inventory_card := _panel(Color(0.012, 0.027, 0.04, 0.88), Color(0.36, 0.62, 0.64, 0.4))
	inventory_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	inventory_card.position = Vector2(-326.0, 215.0)
	inventory_card.size = Vector2(302.0, 198.0)
	root.add_child(inventory_card)
	var inventory_copy := VBoxContainer.new()
	inventory_copy.add_theme_constant_override("separation", 4)
	inventory_card.add_child(inventory_copy)
	var inventory_heading := _label("FIELD INVENTORY  /  PRESS I", 10, Color(0.55, 0.81, 0.76))
	inventory_copy.add_child(inventory_heading)
	_inventory_count_label = _label("0 / %d parts" % MAX_CARRY, 9, Color(0.55, 0.68, 0.69))
	inventory_copy.add_child(_inventory_count_label)
	_inventory_summary_label = _label("No parts collected yet.", 9, Color(0.8, 0.84, 0.8))
	_inventory_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_summary_label.custom_minimum_size.y = 96.0
	inventory_copy.add_child(_inventory_summary_label)
	_credits_label = _label("REPAIR CREDITS  /  0000", 9, Color(0.79, 0.75, 0.53))
	inventory_copy.add_child(_credits_label)

	var controls_card := _panel(Color(0.012, 0.027, 0.04, 0.77), Color(0.36, 0.62, 0.64, 0.3))
	controls_card.position = Vector2(24.0, 415.0)
	controls_card.size = Vector2(336.0, 80.0)
	root.add_child(controls_card)
	var controls := _label("W A S D  Move    •    Mouse  Look\nSpace  Jump    •    Shift  Suit thrust\nE  Use / pick up    •    I  Inventory", 9, Color(0.65, 0.76, 0.74))
	controls.position = Vector2(13.0, 10.0)
	controls.size = Vector2(300.0, 60.0)
	controls.add_theme_constant_override("line_spacing", 2)
	controls_card.add_child(controls)

	var suit_card := _panel(Color(0.012, 0.027, 0.04, 0.82), Color(0.36, 0.62, 0.64, 0.34))
	suit_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	suit_card.position = Vector2(-326.0, 426.0)
	suit_card.size = Vector2(302.0, 79.0)
	root.add_child(suit_card)
	var suit_copy := VBoxContainer.new()
	suit_copy.add_theme_constant_override("separation", 3)
	suit_card.add_child(suit_copy)
	var suit_title := _label("SUIT THRUST  /  FUEL", 9, Color(0.65, 0.76, 0.74))
	suit_copy.add_child(suit_title)
	_boost_bar = ProgressBar.new()
	_boost_bar.max_value = 100.0
	_boost_bar.custom_minimum_size = Vector2(250.0, 10.0)
	_boost_bar.show_percentage = false
	_boost_bar.add_theme_stylebox_override("background", _bar_style(Color(0.06, 0.12, 0.14)))
	_boost_bar.add_theme_stylebox_override("fill", _bar_style(Color(0.31, 0.88, 0.8)))
	suit_copy.add_child(_boost_bar)
	_mission_clock_label = _label("00:00  /  SURFACE TIME", 8, Color(0.55, 0.68, 0.7))
	suit_copy.add_child(_mission_clock_label)

	var progress_card := _panel(Color(0.012, 0.027, 0.04, 0.79), Color(0.36, 0.62, 0.64, 0.3))
	progress_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	progress_card.anchor_left = 0.5
	progress_card.anchor_right = 0.5
	progress_card.offset_left = -355.0
	progress_card.offset_top = -72.0
	progress_card.offset_right = 355.0
	progress_card.offset_bottom = -24.0
	root.add_child(progress_card)
	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 0)
	progress_card.add_child(progress_row)
	var phase_names := ["01  SHIP", "02  PARTS", "03  CABLES", "04  SYSTEMS", "05  ENGINE", "06  EARTH"]
	for name in phase_names:
		var label := _label(name, 8, Color(0.38, 0.49, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_row.add_child(label)
		_progress_labels.append(label)

	_interaction_label = _label("", 12, Color(0.84, 0.98, 0.91))
	_interaction_label.anchor_left = 0.5
	_interaction_label.anchor_right = 0.5
	_interaction_label.anchor_top = 1.0
	_interaction_label.anchor_bottom = 1.0
	_interaction_label.offset_left = -210.0
	_interaction_label.offset_top = -155.0
	_interaction_label.offset_right = 210.0
	_interaction_label.offset_bottom = -128.0
	_interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_label.modulate.a = 0.0
	root.add_child(_interaction_label)
	_toast_label = _label("", 12, Color(0.83, 0.96, 0.9))
	_toast_label.anchor_left = 0.5
	_toast_label.anchor_right = 0.5
	_toast_label.anchor_top = 0.5
	_toast_label.anchor_bottom = 0.5
	_toast_label.offset_left = -300.0
	_toast_label.offset_top = 105.0
	_toast_label.offset_right = 300.0
	_toast_label.offset_bottom = 135.0
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.modulate.a = 0.0
	root.add_child(_toast_label)
	_build_inventory_panel(root)
	_build_command_log(root)
	_build_completion_panel(root)
	_build_flight_hud()

func _build_flight_hud() -> void:
	_flight_ui = CanvasLayer.new()
	_flight_ui.name = "Apollo flight console"
	_flight_ui.layer = 4
	_flight_ui.visible = false
	add_child(_flight_ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flight_ui.add_child(root)
	var amber := Color(0.96, 0.72, 0.36)
	var green := Color(0.55, 0.9, 0.7)
	var dim := Color(0.55, 0.65, 0.59)
	var top := _panel(Color(0.012, 0.018, 0.018, 0.92), Color(0.78, 0.57, 0.29, 0.86))
	top.anchor_left = 0.0
	top.anchor_right = 1.0
	top.offset_left = 22.0
	top.offset_top = 18.0
	top.offset_right = -22.0
	top.offset_bottom = 82.0
	root.add_child(top)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 22)
	top.add_child(top_row)
	var brand := _label("GRAVITY  /  APOLLO RETURN FLIGHT", 13, amber)
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(brand)
	var mission_tag := _label("TRANQUILLITATIS  /  RETURN TRAJECTORY", 9, dim)
	mission_tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(mission_tag)
	_flight_status_label = _label("PREFLIGHT CHECKS", 10, green)
	_flight_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_flight_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(_flight_status_label)

	var nav_card := _panel(Color(0.012, 0.018, 0.018, 0.89), Color(0.48, 0.66, 0.48, 0.74))
	nav_card.position = Vector2(22.0, 100.0)
	nav_card.size = Vector2(284.0, 174.0)
	root.add_child(nav_card)
	var nav_copy := VBoxContainer.new()
	nav_copy.add_theme_constant_override("separation", 8)
	nav_card.add_child(nav_copy)
	var nav_title := _label("NAVIGATION  /  TELEMETRY", 9, green)
	nav_copy.add_child(nav_title)
	_flight_speed_label = _label("VELOCITY   000.0 M/S", 12, amber)
	nav_copy.add_child(_flight_speed_label)
	_flight_attitude_label = _label("PITCH  +00°   HEADING  000°", 10, Color(0.82, 0.85, 0.68))
	_flight_attitude_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nav_copy.add_child(_flight_attitude_label)
	var range_title := _label("EARTH INTERCEPT RANGE", 8, dim)
	nav_copy.add_child(range_title)
	_flight_range_label = _label("00000 M  /  TARGET 5000 M", 10, green)
	nav_copy.add_child(_flight_range_label)
	var telemetry_rule := _label("────────  GUIDANCE COMPUTER  ────────", 8, dim)
	nav_copy.add_child(telemetry_rule)

	var hazard_card := _panel(Color(0.012, 0.018, 0.018, 0.89), Color(0.78, 0.57, 0.29, 0.74))
	hazard_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hazard_card.position = Vector2(-310.0, 100.0)
	hazard_card.size = Vector2(288.0, 174.0)
	root.add_child(hazard_card)
	var hazard_copy := VBoxContainer.new()
	hazard_copy.add_theme_constant_override("separation", 8)
	hazard_card.add_child(hazard_copy)
	var hazard_title := _label("FLIGHT DIRECTOR  /  HAZARDS", 9, amber)
	hazard_copy.add_child(hazard_title)
	_flight_hazard_label = _label("ASTEROID TRACKING ONLINE\nNO IMMEDIATE THREATS", 10, green)
	_flight_hazard_label.custom_minimum_size.y = 52.0
	_flight_hazard_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hazard_copy.add_child(_flight_hazard_label)
	var hazard_hint := _label("KEEP CLEAR OF ROCKS\nRANGE GATES  /  500 M", 8, dim)
	hazard_copy.add_child(hazard_hint)

	var bottom := _panel(Color(0.012, 0.018, 0.018, 0.94), Color(0.78, 0.57, 0.29, 0.82))
	bottom.anchor_left = 0.0
	bottom.anchor_right = 1.0
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_left = 22.0
	bottom.offset_top = -92.0
	bottom.offset_right = -22.0
	bottom.offset_bottom = -18.0
	root.add_child(bottom)
	var bottom_row := HBoxContainer.new()
	bottom_row.add_theme_constant_override("separation", 16)
	bottom.add_child(bottom_row)
	var controls := _label("W / ↑  PITCH UP     S / ↓  PITCH DOWN\nA / ←  YAW LEFT     D / →  YAW RIGHT", 8, amber)
	controls.custom_minimum_size.x = 288.0
	controls.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_row.add_child(controls)
	var range_progress := ProgressBar.new()
	range_progress.min_value = 0.0
	range_progress.max_value = 1.0
	range_progress.value = 0.0
	range_progress.show_percentage = false
	range_progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	range_progress.custom_minimum_size = Vector2(200.0, 14.0)
	range_progress.add_theme_stylebox_override("background", _bar_style(Color(0.08, 0.1, 0.075)))
	range_progress.add_theme_stylebox_override("fill", _bar_style(Color(0.61, 0.77, 0.43)))
	_flight_progress = range_progress
	bottom_row.add_child(range_progress)
	var computer := _label("GUIDANCE  /  MANUAL OVERRIDE\nBLACKOUT AT 5.0 KM", 8, green)
	computer.custom_minimum_size.x = 218.0
	computer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	computer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_row.add_child(computer)

func _build_arrival_overlay() -> void:
	_arrival_overlay = CanvasLayer.new()
	_arrival_overlay.name = "Earth arrival cutscene"
	_arrival_overlay.layer = 20
	add_child(_arrival_overlay)
	_arrival_video = VideoStreamPlayer.new()
	_arrival_video.name = "Earth coming video"
	_arrival_video.stream = load("res://assets/earth_coming.ogv") as VideoStreamTheora
	_arrival_video.expand = true
	_arrival_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arrival_video.visible = false
	_arrival_video.volume = 1.0
	_arrival_overlay.add_child(_arrival_video)
	_arrival_fade = ColorRect.new()
	_arrival_fade.name = "Black transition"
	_arrival_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_arrival_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrival_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_arrival_overlay.add_child(_arrival_fade)
	_build_crash_panel()

func _build_crash_panel() -> void:
	_crash_panel = _panel(Color(0.012, 0.012, 0.01, 0.98), Color(0.96, 0.48, 0.27, 0.94))
	_crash_panel.set_anchors_preset(Control.PRESET_CENTER)
	_crash_panel.offset_left = -280.0
	_crash_panel.offset_top = -140.0
	_crash_panel.offset_right = 280.0
	_crash_panel.offset_bottom = 140.0
	_crash_panel.visible = false
	_arrival_overlay.add_child(_crash_panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 14)
	_crash_panel.add_child(copy)
	var title := _label("FLIGHT ABORT  /  IMPACT", 12, Color(1.0, 0.58, 0.34))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(title)
	var details := _label("ASTEROID COLLISION DETECTED\nRETURN VEHICLE LOST", 22, Color(0.92, 0.88, 0.75))
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(details)
	var retry := _label("R  RESTART MISSION     •     ESC  MAIN MENU", 9, Color(0.75, 0.8, 0.67))
	retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(retry)

func _build_inventory_panel(root: Control) -> void:
	_inventory_panel = _panel(Color(0.009, 0.02, 0.032, 0.96), Color(0.43, 0.83, 0.77, 0.8))
	_inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	_inventory_panel.offset_left = -235.0
	_inventory_panel.offset_top = -225.0
	_inventory_panel.offset_right = 235.0
	_inventory_panel.offset_bottom = 225.0
	_inventory_panel.visible = false
	_inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_inventory_panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 11)
	_inventory_panel.add_child(copy)
	var title := _label("Field inventory", 25, Color(0.91, 0.94, 0.88))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(title)
	var subtitle := _label("Recovered parts stay here until you use them.", 10, Color(0.61, 0.74, 0.71))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(subtitle)
	_inventory_detail_label = _label("No parts collected yet.", 12, Color(0.83, 0.88, 0.83))
	_inventory_detail_label.custom_minimum_size.y = 225.0
	copy.add_child(_inventory_detail_label)
	var close_hint := _label("Press I or Esc to close", 10, Color(0.53, 0.74, 0.7))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(close_hint)

func _build_command_log(root: Control) -> void:
	_command_log_panel = _panel(Color(0.009, 0.02, 0.032, 0.96), Color(0.43, 0.83, 0.77, 0.8))
	_command_log_panel.set_anchors_preset(Control.PRESET_CENTER)
	_command_log_panel.offset_left = -250.0
	_command_log_panel.offset_top = -190.0
	_command_log_panel.offset_right = 250.0
	_command_log_panel.offset_bottom = 190.0
	_command_log_panel.visible = false
	_command_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_command_log_panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 12)
	_command_log_panel.add_child(copy)
	var title := _label("Commander log", 24, Color(0.91, 0.94, 0.88))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(title)
	_command_log_label = _label("No messages yet.", 11, Color(0.8, 0.86, 0.82))
	_command_log_label.custom_minimum_size.y = 270.0
	_command_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(_command_log_label)
	var close_hint := _label("Press C or Esc to close", 10, Color(0.53, 0.74, 0.7))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(close_hint)

func _build_completion_panel(root: Control) -> void:
	_complete_panel = _panel(Color(0.008, 0.02, 0.033, 0.97), Color(0.48, 0.87, 0.78, 0.92))
	_complete_panel.set_anchors_preset(Control.PRESET_CENTER)
	_complete_panel.offset_left = -270.0
	_complete_panel.offset_top = -170.0
	_complete_panel.offset_right = 270.0
	_complete_panel.offset_bottom = 170.0
	_complete_panel.visible = false
	_complete_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_complete_panel)
	var copy := VBoxContainer.new()
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 13)
	_complete_panel.add_child(copy)
	var overline := _label("MISSION CONTROL  /  EARTH LANDING CONFIRMED", 9, Color(0.48, 0.81, 0.74))
	overline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(overline)
	var title := _label("Welcome back to Earth.", 29, Color(0.92, 0.93, 0.87))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(title)
	var details := _label("You recovered the parts, reconnected the ship, and brought the crew home.", 11, Color(0.67, 0.77, 0.74))
	details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(details)
	var reward := _label("MISSION REWARD  /  +500 CREDITS", 10, Color(0.83, 0.77, 0.52))
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(reward)
	var replay := _label("R  Play again     •     Esc  Main menu", 10, Color(0.75, 0.88, 0.83))
	replay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy.add_child(replay)

func _update_mission_progress() -> void:
	if mission_phase == 0 and _horizontal_distance(astronaut.global_position, ship_position) < 9.0:
		_advance_phase("You found the return ship. Recover the parts around the crash site.")

func handle_interact() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		return
	if mission_phase == 0:
		if _horizontal_distance(astronaut.global_position, ship_position) < 9.0:
			_advance_phase("You found the return ship. Recover the parts around the crash site.")
		else:
			_set_message("Follow the blue marker to find your ship.", Color(0.78, 0.83, 0.72))
		return
	if mission_phase == 1:
		var pickup_key := _nearest_pickup(3.8)
		if pickup_key.is_empty():
			_set_message("Move beside the glowing case, then press E.", Color(0.78, 0.83, 0.72))
			return
		_collect_pickup(pickup_key)
		return
	if mission_phase >= 2 and mission_phase <= 4:
		_repair_active_system()
		return
	if mission_phase == 5:
		if _horizontal_distance(astronaut.global_position, _cockpit_position) <= 4.4:
			_start_launch()
		else:
			_set_message("Walk to the cockpit marker to start the launch.", Color(0.78, 0.83, 0.72))

func toggle_inventory() -> void:
	if _inventory_panel == null:
		return
	_inventory_panel.visible = not _inventory_panel.visible
	if _inventory_panel.visible and _command_log_panel.visible:
		_command_log_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _inventory_panel.visible else Input.MOUSE_MODE_CAPTURED

func request_hint() -> void:
	var hint: String = str(HINTS[mini(mission_phase, HINTS.size() - 1)])
	if mission_phase == 5 and _launch_started:
		hint = "W / Up pitches up, S / Down pitches down, A / Left yaws left, and D / Right yaws right. Avoid asteroids."
	_commander_message(hint)
	_set_message("Hint: " + hint, Color(0.74, 0.88, 0.78))

func toggle_command_log() -> void:
	if _command_log_panel == null:
		return
	_command_log_panel.visible = not _command_log_panel.visible
	if _command_log_panel.visible:
		_inventory_panel.visible = false
		_refresh_command_log()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _command_log_panel.visible else Input.MOUSE_MODE_CAPTURED

func handle_menu() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if _command_log_panel != null and _command_log_panel.visible:
		_command_log_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SFX.stop_ambient()
	SFX.stop_ship_travel()
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _collect_pickup(key: String) -> void:
	if not _pickup_nodes.has(key):
		return
	var item_data: Dictionary = _pickup_data[key]
	var item_id: String = item_data.item
	if inventory_count >= MAX_CARRY:
		_set_message("Your pack is full. Install a part before collecting more.", Color(1.0, 0.65, 0.42))
		return
	inventory[item_id] = int(inventory.get(item_id, 0)) + 1
	SFX.play_sfx("pickup", -8.0)
	inventory_count += 1
	var pickup: Node3D = _pickup_nodes[key]
	pickup.queue_free()
	_pickup_nodes.erase(key)
	_award(80, str(ITEM_NAMES[item_id]) + " secured")
	_refresh_inventory()
	var remaining := _pickup_nodes.size()
	if remaining == 0:
		_advance_phase("All eight parts are in your pack. Now repair the three open cable links.")
	else:
		_commander_message("Good find. " + str(remaining) + " more part" + ("s" if remaining != 1 else "") + " to collect. Follow the new marker.")
	_update_phase()

func _repair_active_system() -> void:
	var repair_id := _active_repair_id()
	if repair_id.is_empty():
		return
	var point: Vector3 = _repair_positions[repair_id]
	if _horizontal_distance(astronaut.global_position, point) > 4.2:
		_set_message("Follow the marker to the active repair pad.", Color(0.78, 0.83, 0.72))
		return
	var spec: Dictionary = _repair_specs_by_id[repair_id]
	var item_id: String = spec.item
	if int(inventory.get(item_id, 0)) <= 0:
		_set_message("You need a " + str(ITEM_NAMES[item_id]) + " for this repair.", Color(1.0, 0.65, 0.42))
		return
	inventory[item_id] = int(inventory[item_id]) - 1
	SFX.play_sfx("repair", -7.0)
	if int(inventory[item_id]) <= 0:
		inventory.erase(item_id)
	inventory_count = maxi(0, inventory_count - 1)
	_repair_done[repair_id] = true
	_refresh_repair_visual(repair_id)
	_award(140, str(spec.name) + " fixed")
	_refresh_inventory()
	if _all_repairs_done_for_phase(mission_phase):
		match mission_phase:
			2:
				_advance_phase("All three cables are connected. Repair power, guidance, and radio next.")
			3:
				_advance_phase("The ship systems are working. Repair the engine to get home.")
			4:
				_advance_phase("Engine repaired. Go to the cockpit when you are ready to launch.")
	else:
		var next_name := _active_repair_name()
		_commander_message(str(spec.name) + " is fixed. Next, repair the " + next_name.to_lower() + ".")
	_update_phase()

func _all_repairs_done_for_phase(phase: int) -> bool:
	var order: Array = CONNECTION_ORDER if phase == 2 else SYSTEM_ORDER if phase == 3 else ENGINE_ORDER
	for id in order:
		if not bool(_repair_done.get(id, false)):
			return false
	return true

func _active_repair_id() -> String:
	var order: Array = CONNECTION_ORDER if mission_phase == 2 else SYSTEM_ORDER if mission_phase == 3 else ENGINE_ORDER if mission_phase == 4 else []
	for id in order:
		if not bool(_repair_done.get(id, false)):
			return str(id)
	return ""

func _active_repair_name() -> String:
	var id := _active_repair_id()
	if id.is_empty():
		return "next repair"
	return str(_repair_specs_by_id[id].name)

func _advance_phase(command: String) -> void:
	if mission_phase >= 5:
		return
	mission_phase += 1
	_award(120, "Mission step complete")
	_update_phase()
	_commander_message(command)
	_set_message(command, Color(0.65, 0.94, 0.84))

func _update_phase() -> void:
	if _phase_title == null:
		return
	_phase_title.text = PHASE_TITLES[mission_phase]
	_phase_detail.text = PHASE_DETAILS[mission_phase]
	if mission_phase == 5 and _launch_started:
		_phase_detail.text = "Steer with WASD or arrows. Avoid asteroids; blackout begins five kilometres above Earth."
	_refresh_tasks()
	_update_marker_target()
	_refresh_all_repair_visuals()
	for index in range(_progress_labels.size()):
		if index < mission_phase:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.38, 0.9, 0.75))
		elif index == mission_phase and mission_phase < 6:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.9, 0.96, 0.9))
		else:
			_progress_labels[index].add_theme_color_override("font_color", Color(0.38, 0.49, 0.5))

func _refresh_all_repair_visuals() -> void:
	for id in _repair_visuals.keys():
		_refresh_repair_visual(str(id))

func _refresh_tasks() -> void:
	if _task_labels.is_empty():
		return
	var tasks := _tasks_for_phase()
	var complete_count := 0
	for index in range(_task_labels.size()):
		var row: Label = _task_labels[index]
		if index >= tasks.size():
			row.visible = false
			continue
		row.visible = true
		var task: Dictionary = tasks[index]
		var done: bool = bool(task.done)
		if done:
			complete_count += 1
		row.text = ("✓  " if done else "○  ") + str(task.name)
		row.add_theme_color_override("font_color", Color(0.43, 0.9, 0.73) if done else Color(0.76, 0.83, 0.8))
	_task_count_label.text = "%d / %d complete" % [complete_count, tasks.size()]

func _tasks_for_phase() -> Array[Dictionary]:
	var tasks: Array[Dictionary] = []
	match mission_phase:
		0:
			tasks.append({"name": "Reach the damaged return ship", "done": false})
		1:
			for item_data in ITEM_LAYOUT:
				var label := str(ITEM_NAMES[item_data.item])
				if item_data.key.begins_with("cable_connector"):
					label += " " + str(int(item_data.key.get_slice("_", 2)))
				tasks.append({"name": "Collect " + label, "done": not _pickup_nodes.has(item_data.key)})
		2:
			for id in CONNECTION_ORDER:
				tasks.append({"name": "Connect " + str(_repair_specs_by_id[id].name).replace(" cable", ""), "done": bool(_repair_done[id])})
		3:
			for id in SYSTEM_ORDER:
				tasks.append({"name": "Install " + str(ITEM_NAMES[id]), "done": bool(_repair_done[id])})
		4:
			for id in ENGINE_ORDER:
				tasks.append({"name": "Repair " + str(ITEM_NAMES[id]), "done": bool(_repair_done[id])})
		5:
			tasks.append({"name": "Enter the cockpit", "done": _launch_started})
			tasks.append({"name": "Fly home to Earth", "done": mission_phase == 6})
		6:
			tasks.append({"name": "Return the crew safely to Earth", "done": true})
	return tasks

func _update_marker_target() -> void:
	if mission_phase == 6 or _launch_started:
		_marker.visible = false
		return
	_marker.visible = true
	match mission_phase:
		0:
			_marker_target = ship_position
			_marker_label.text = "RETURN SHIP"
		1:
			var key := _nearest_pickup_key()
			_marker_target = _pickup_positions[key] if not key.is_empty() else ship_position
			_marker_label.text = "PART" if not key.is_empty() else "PARTS COLLECTED"
		2, 3, 4:
			var repair_id := _active_repair_id()
			_marker_target = _repair_positions[repair_id] if not repair_id.is_empty() else ship_position
			_marker_label.text = "REPAIR"
		5:
			_marker_target = _cockpit_position
			_marker_label.text = "COCKPIT"
	_marker.global_position = _marker_target + Vector3.UP * (2.45 + sin(_arrow_clock * 3.0) * 0.42)

func _nearest_pickup_key() -> String:
	var nearest := ""
	var nearest_distance := INF
	for key in _pickup_nodes.keys():
		var point: Vector3 = _pickup_positions[key]
		var distance := _horizontal_distance(astronaut.global_position, point)
		if distance < nearest_distance:
			nearest = str(key)
			nearest_distance = distance
	return nearest

func _nearest_pickup(max_distance: float) -> String:
	var nearest := _nearest_pickup_key()
	if nearest.is_empty():
		return ""
	return nearest if _horizontal_distance(astronaut.global_position, _pickup_positions[nearest]) <= max_distance else ""

func _update_hud() -> void:
	if _phase_title == null:
		return
	_update_marker_target()
	var horizontal_distance := _horizontal_distance(astronaut.global_position, _marker_target)
	var direction := Vector3(_marker_target.x - astronaut.global_position.x, 0.0, _marker_target.z - astronaut.global_position.z).normalized()
	var camera_yaw: float = astronaut.get_camera_yaw()
	var camera_forward := Vector3(-sin(camera_yaw), 0.0, -cos(camera_yaw))
	var bearing := atan2(camera_forward.cross(direction).y, camera_forward.dot(direction))
	_direction_arrow_label.text = _arrow_for_bearing(bearing)
	var arrow_side_shift := -sin(bearing) * 76.0
	var arrow_bounce := absf(sin(_arrow_clock * 5.2)) * 11.0
	var arrow_pulse := 1.0 + (0.5 + 0.5 * sin(_arrow_clock * 5.2)) * 0.16
	var behind_shift := 9.0 if absf(bearing) > 2.35 else 0.0
	_direction_arrow_label.offset_left = -31.0 + arrow_side_shift
	_direction_arrow_label.offset_right = 31.0 + arrow_side_shift
	_direction_arrow_label.offset_top = 108.0 + behind_shift - arrow_bounce
	_direction_arrow_label.offset_bottom = 151.0 + behind_shift - arrow_bounce
	_direction_arrow_label.scale = Vector2.ONE * arrow_pulse
	_distance_label.text = "%03d M  •  %s" % [int(horizontal_distance), "WAYPOINT" if horizontal_distance < 4.0 else "FOLLOW THE MARKER"]
	_boost_bar.value = astronaut.boost_fuel
	_mission_clock_label.text = "%02d:%02d  /  SURFACE TIME" % [int(mission_seconds / 60.0), int(fmod(mission_seconds, 60.0))]
	_update_interaction_prompt()
	_refresh_inventory()
	if mission_phase == 6 or _launch_started:
		_distance_label.visible = false
		_interaction_label.visible = false
		_direction_arrow_label.visible = false
	else:
		_distance_label.visible = true
		_interaction_label.visible = true
		_direction_arrow_label.visible = true

func _update_flight_hud() -> void:
	if not is_instance_valid(_earth) or not is_instance_valid(ship_root) or _flight_range_label == null:
		return
	var earth_distance := _flight_vehicle_position().distance_to(_earth.global_position)
	var heading_degrees := int(round(rad_to_deg(fposmod(_flight_yaw, TAU))))
	var pitch_degrees := int(round(rad_to_deg(_flight_pitch)))
	_flight_range_label.text = "%05d M  /  SURFACE RANGE" % int(maxf(earth_distance - EARTH_RADIUS, 0.0))
	_flight_speed_label.text = "VELOCITY   %05.1f M/S" % _flight_speed
	_flight_attitude_label.text = "PITCH  %+03d°   HEADING  %03d°" % [pitch_degrees, heading_degrees]
	var distance_to_cover := maxf(_flight_route_start_distance - EARTH_BLACKOUT_RANGE, 1.0)
	_flight_progress.value = clampf(_flight_route_distance / distance_to_cover, 0.0, 1.0)
	var nearest_hazard := INF
	for hazard in _flight_asteroids:
		var asteroid := hazard.get("node") as Node3D
		if not is_instance_valid(asteroid):
			continue
		nearest_hazard = minf(nearest_hazard, _flight_vehicle_position().distance_to(asteroid.global_position))
	if nearest_hazard < 300.0:
		_flight_hazard_label.text = "COLLISION WARNING\nASTEROID  /  %03d M" % int(nearest_hazard)
		_flight_hazard_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.29))
	elif nearest_hazard < 750.0:
		_flight_hazard_label.text = "CAUTION  /  ASTEROID\nRANGE  %03d M  •  MANEUVER" % int(nearest_hazard)
		_flight_hazard_label.add_theme_color_override("font_color", Color(0.96, 0.72, 0.36))
	else:
		_flight_hazard_label.text = "ASTEROID TRACKING ONLINE\nNO IMMEDIATE THREATS"
		_flight_hazard_label.add_theme_color_override("font_color", Color(0.55, 0.9, 0.7))

func _arrow_for_bearing(bearing: float) -> String:
	var angle := absf(bearing)
	if angle < 0.35:
		return "↑"
	if angle < 1.05:
		return "↖" if bearing > 0.0 else "↗"
	if angle < 1.95:
		return "←" if bearing > 0.0 else "→"
	if angle < 2.6:
		return "↙" if bearing > 0.0 else "↘"
	return "↓"

func _update_interaction_prompt() -> void:
	var text := ""
	if mission_phase == 0 and _horizontal_distance(astronaut.global_position, ship_position) < 9.0:
		text = "E  Start ship repairs"
	elif mission_phase == 1:
		var pickup_key := _nearest_pickup(3.8)
		if not pickup_key.is_empty():
			var item_id: String = _pickup_data[pickup_key].item
			text = "E  Pick up " + str(ITEM_NAMES[item_id])
	elif mission_phase >= 2 and mission_phase <= 4:
		var repair_id := _active_repair_id()
		if not repair_id.is_empty() and _horizontal_distance(astronaut.global_position, _repair_positions[repair_id]) < 4.2:
			var spec: Dictionary = _repair_specs_by_id[repair_id]
			text = "E  " + ("Connect " if mission_phase == 2 else "Install ") + str(spec.name)
	elif mission_phase == 5 and _horizontal_distance(astronaut.global_position, _cockpit_position) < 4.4:
		text = "E  Begin launch sequence"
	_interaction_label.text = text
	_interaction_label.modulate.a = move_toward(_interaction_label.modulate.a, 1.0 if not text.is_empty() else 0.0, get_process_delta_time() * 5.0)

func _refresh_inventory() -> void:
	if _inventory_count_label == null:
		return
	_inventory_count_label.text = "%d / %d parts" % [inventory_count, MAX_CARRY]
	_credits_label.text = "REPAIR CREDITS  /  %04d" % credits
	var lines := PackedStringArray()
	var detail_lines := PackedStringArray()
	for item_id in ITEM_NAMES.keys():
		var count := int(inventory.get(item_id, 0))
		if count <= 0:
			continue
		var entry := "•  %s  ×%d" % [str(ITEM_NAMES[item_id]), count]
		lines.append(entry)
		detail_lines.append("%s   × %d" % [str(ITEM_NAMES[item_id]), count])
	if lines.is_empty():
		_inventory_summary_label.text = "No parts collected yet.\nFollow the marker to the wreck."
		_inventory_detail_label.text = "No parts collected yet."
	else:
		_inventory_summary_label.text = "\n".join(lines)
		_inventory_detail_label.text = "\n".join(detail_lines) + "\n\nPack space: %d / %d" % [inventory_count, MAX_CARRY]
	if _command_log_panel != null and _command_log_panel.visible:
		_refresh_command_log()

func _start_launch() -> void:
	if _launch_started:
		return
	_launch_started = true
	if is_instance_valid(_ui):
		_ui.visible = false
	if is_instance_valid(_flight_ui):
		_flight_ui.visible = true
	_flight_status_label.text = "PREFLIGHT  /  CABIN SEALED"
	SFX.start_ship_travel()
	mission_phase = 5
	_update_phase()
	_commander_message("All repairs are complete. Strap in. Flight computers are starting the launch checks.")
	_set_message("Flight computers online. Launch sequence starting.", Color(0.68, 0.96, 0.85))
	astronaut.enter_cockpit_chase_view()
	astronaut.velocity = Vector3.ZERO
	astronaut.set_physics_process(false)
	if is_instance_valid(_earth) and is_instance_valid(ship_root):
		var earth_direction := (_earth.global_position - _flight_vehicle_position()).normalized()
		_flight_yaw = atan2(-earth_direction.x, -earth_direction.z)
	else:
		_flight_yaw = 0.0
	_flight_pitch = 0.0
	_set_launch_attitude(0.0, _flight_yaw)
	if is_instance_valid(_shuttle_flight_attitude):
		var seat_pose := Transform3D(Basis(Vector3.UP, PI), COCKPIT_SEAT_LOCAL)
		astronaut.global_transform = _shuttle_flight_attitude.global_transform * seat_pose
	else:
		astronaut.global_transform = Transform3D(Basis.IDENTITY, ship_position + Vector3(0.0, 3.0, -4.1))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var follow_camera := astronaut.get_follow_camera()
	if is_instance_valid(follow_camera):
		_launch_camera_pivot = follow_camera.get_parent() as Node3D
		if is_instance_valid(_launch_camera_pivot):
			_launch_camera_rest_position = _launch_camera_pivot.position
	_run_return_flight()

func _run_return_flight() -> void:
	var cabin_start := Transform3D.IDENTITY
	if is_instance_valid(_shuttle_flight_attitude):
		cabin_start = _shuttle_flight_attitude.global_transform.affine_inverse() * astronaut.global_transform
	_commander_message("Cabin sealed. Shuttle is level. Flight controls are live; stand by for liftoff.")
	_set_message("Shuttle level  /  Flight controls active", Color(0.72, 0.9, 0.88))
	for count in [5, 4, 3, 2, 1]:
		_flight_status_label.text = "T MINUS %d  /  ALL SYSTEMS GO" % count
		_commander_message("T minus %d. Cabin pressure and navigation are stable." % count)
		_set_message("T − %02d  /  CABIN SEALED" % count, Color(0.78, 0.92, 0.86))
		await get_tree().create_timer(1.0).timeout
		if _flight_crashed:
			return
	_commander_message("Main engines ignited. Hold-down is released on my mark.")
	if is_instance_valid(_moon_orbit_visual):
		_moon_orbit_visual.visible = true
	_set_message("Main engines ignited. Preparing for liftoff.", Color(0.77, 0.91, 1.0))
	_flight_status_label.text = "ENGINE IGNITION  /  LUNAR LIFTOFF"
	_launch_shake_strength = 0.035
	_launch_engines_active = true
	if is_instance_valid(_launch_dust):
		_launch_dust.restart()
		_launch_dust.emitting = true
	for flame in _launch_flames:
		flame.visible = true
	var lift_origin := ship_root.global_position
	var lift_elapsed := 0.0
	var lift_duration := 3.6
	_flight_status_label.text = "HOLD-DOWN RELEASE  /  DUST PLUME"
	_commander_message("Liftoff. Thrusters are lifting the vehicle; shuttle remains level.")
	while lift_elapsed < lift_duration:
		await get_tree().process_frame
		lift_elapsed += maxf(get_process_delta_time(), 0.001)
		var lift_progress := clampf(lift_elapsed / lift_duration, 0.0, 1.0)
		var lift_eased := lift_progress * lift_progress * (3.0 - 2.0 * lift_progress)
		ship_root.global_position = lift_origin + Vector3.UP * (24.0 * lift_eased)
		_set_launch_attitude(0.0, _flight_yaw)
		_set_astronaut_in_cabin(cabin_start)
		_launch_shake_strength = 0.04 + 0.045 * (1.0 - lift_progress)
		if _flight_crashed:
			return
	var earth_direction := Vector3(0.0, 0.0, -1.0)
	if is_instance_valid(_earth):
		earth_direction = _earth.global_position - _flight_vehicle_position()
		earth_direction.y = 0.0
		if earth_direction.length_squared() > 0.001:
			earth_direction = earth_direction.normalized()
	var horizontal_origin := ship_root.global_position
	var horizontal_elapsed := 0.0
	var horizontal_duration := 3.2
	_flight_status_label.text = "LEVEL FLIGHT  /  THRUST BUILD-UP"
	while horizontal_elapsed < horizontal_duration:
		await get_tree().process_frame
		horizontal_elapsed += maxf(get_process_delta_time(), 0.001)
		var progress := clampf(horizontal_elapsed / horizontal_duration, 0.0, 1.0)
		var eased := progress * progress * (3.0 - 2.0 * progress)
		ship_root.global_position = horizontal_origin + Vector3.UP * 24.0 + earth_direction * (110.0 * eased)
		_flight_speed = 20.0 * progress
		_set_launch_attitude(0.0, _flight_yaw)
		_set_astronaut_in_cabin(cabin_start)
		_launch_shake_strength = 0.08 * (1.0 - progress)
		if _flight_crashed:
			return
	_commander_message("Horizontal acceleration established. Gravity turn underway; pilot has manual control.")
	_set_message("Manual flight controls active. Asteroids on scope.", Color(0.65, 0.91, 1.0))
	_flight_status_label.text = "GRAVITY TURN  /  MANUAL OVERRIDE"
	_flight_speed = 32.0
	_flight_elapsed = 0.0
	_flight_route_distance = 0.0
	_flight_route_start_distance = _earth.global_position.distance_to(_flight_vehicle_position()) if is_instance_valid(_earth) else 0.0
	var flight_origin := _flight_vehicle_position()
	_spawn_flight_asteroids(flight_origin, _flight_yaw, _flight_pitch, _flight_speed)
	var last_reported_range := int(_flight_route_start_distance / 250.0)
	var guidance_assist := false
	while is_instance_valid(_earth) and _flight_vehicle_position().distance_to(_earth.global_position) > EARTH_BLACKOUT_RANGE and _flight_elapsed < 105.0:
		await get_tree().process_frame
		if _flight_crashed:
			return
		var frame_delta := maxf(get_process_delta_time(), 0.001)
		_flight_elapsed += frame_delta
		var earth_vector := _earth.global_position - _flight_vehicle_position()
		var earth_distance := earth_vector.length()
		if earth_distance <= EARTH_BLACKOUT_RANGE:
			break
		var route_direction := earth_vector / maxf(earth_distance, 0.001)
		var target_yaw := atan2(-route_direction.x, -route_direction.z)
		var target_pitch := atan2(route_direction.y, Vector2(route_direction.x, route_direction.z).length())
		var steering := _read_flight_controls()
		var control_authority := 1.0 if _flight_elapsed < 65.0 else clampf((105.0 - _flight_elapsed) / 40.0, 0.0, 1.0)
		var gravity_turn := _liftoff_pitch_arc(_flight_elapsed)
		_flight_yaw = rotate_toward(_flight_yaw, target_yaw + steering.x * 0.34 * control_authority, 1.25 * frame_delta)
		_flight_pitch = move_toward(_flight_pitch, target_pitch + gravity_turn + steering.y * 0.24 * control_authority, 1.15 * frame_delta)
		_flight_pitch = clampf(_flight_pitch, -0.3, 0.72)
		_flight_speed = move_toward(_flight_speed, FLIGHT_SPEED, 7.0 * frame_delta)
		_set_launch_attitude(_flight_pitch, _flight_yaw)
		var direction := Vector3(-sin(_flight_yaw) * cos(_flight_pitch), sin(_flight_pitch), -cos(_flight_yaw) * cos(_flight_pitch)).normalized()
		ship_root.global_position += direction * _flight_speed * frame_delta
		_flight_route_distance += _flight_speed * frame_delta
		_set_astronaut_in_cabin(cabin_start)
		_launch_shake_strength = 0.014 + 0.018 * (0.5 + 0.5 * sin(_flight_elapsed * 2.1))
		if steering.length_squared() > 0.0:
			_flight_status_label.text = "PILOT INPUT  /  GUIDANCE ASSIST STANDBY"
		elif guidance_assist:
			_flight_status_label.text = "GUIDANCE RE-LOCK  /  5 KM CORRIDOR"
		else:
			_flight_status_label.text = "GRAVITY TURN  /  EARTH INTERCEPT"
		var range_report := int(earth_distance / 250.0)
		if range_report < last_reported_range:
			last_reported_range = range_report
			if range_report % 4 == 0:
				_commander_message("Earth intercept range %d kilometres. Keep the vehicle clear of asteroid markers." % int(earth_distance / 1000.0))
		for hazard in _flight_asteroids:
			var asteroid := hazard.get("node") as Node3D
			if is_instance_valid(asteroid) and _flight_vehicle_position().distance_to(asteroid.global_position) <= float(hazard.get("collision_radius", 28.0)):
				await _handle_flight_crash()
				return
	if _flight_crashed:
		return
	if is_instance_valid(_earth) and _flight_vehicle_position().distance_to(_earth.global_position) > EARTH_BLACKOUT_RANGE:
		guidance_assist = true
		_flight_status_label.text = "GUIDANCE RE-LOCK  /  5 KM CORRIDOR"
		_commander_message("Manual course drift detected. Mission Control is correcting the intercept vector.")
		var correction_elapsed := 0.0
		while correction_elapsed < 45.0 and _flight_vehicle_position().distance_to(_earth.global_position) > EARTH_BLACKOUT_RANGE:
			await get_tree().process_frame
			var frame_delta := maxf(get_process_delta_time(), 0.001)
			correction_elapsed += frame_delta
			var correction_vector := _earth.global_position - _flight_vehicle_position()
			var correction_direction := correction_vector.normalized()
			var correction_yaw := atan2(-correction_direction.x, -correction_direction.z)
			var correction_pitch := atan2(correction_direction.y, Vector2(correction_direction.x, correction_direction.z).length())
			_flight_yaw = rotate_toward(_flight_yaw, correction_yaw, 1.5 * frame_delta)
			_flight_pitch = move_toward(_flight_pitch, correction_pitch, 1.5 * frame_delta)
			_flight_speed = FLIGHT_SPEED
			_set_launch_attitude(_flight_pitch, _flight_yaw)
			var correction_heading := Vector3(-sin(_flight_yaw) * cos(_flight_pitch), sin(_flight_pitch), -cos(_flight_yaw) * cos(_flight_pitch)).normalized()
			ship_root.global_position += correction_heading * _flight_speed * frame_delta
			_set_astronaut_in_cabin(cabin_start)
			for hazard in _flight_asteroids:
				var asteroid := hazard.get("node") as Node3D
				if is_instance_valid(asteroid) and _flight_vehicle_position().distance_to(asteroid.global_position) <= float(hazard.get("collision_radius", 28.0)):
					await _handle_flight_crash()
					return
	if _flight_crashed:
		return
	_launch_shake_strength = 0.0
	_launch_engines_active = false
	for flame in _launch_flames:
		flame.visible = false
	if is_instance_valid(_launch_engine_light):
		_launch_engine_light.light_energy = 0.0
	for hazard in _flight_asteroids:
		var asteroid := hazard.get("node") as Node3D
		if is_instance_valid(asteroid):
			asteroid.visible = false
	_commander_message("Re-entry corridor locked at five kilometres. Earth arrival sequence is beginning.")
	_phase_detail.text = "Five kilometres out. Earth approach confirmed."
	_set_message("Earth approach  /  transition corridor locked at 5 km", Color(0.62, 0.88, 1.0))
	_flight_status_label.text = "EARTH APPROACH  /  BLACKOUT"
	await _play_earth_arrival_cutscene()
	_commander_message("Earth landing confirmed. The whole crew is safe.")
	_set_message("Landing confirmed. Welcome home.", Color(0.72, 0.96, 0.8))
	mission_phase = 6
	_award(500, "Safe return to Earth")
	_update_phase()
	_complete_panel.visible = true
	_complete_panel.modulate = Color(1.0, 1.0, 1.0, 0.82)
	var completion_parent := _complete_panel.get_parent()
	if completion_parent != _arrival_overlay:
		completion_parent.remove_child(_complete_panel)
		_arrival_overlay.add_child(_complete_panel)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _read_flight_controls() -> Vector2:
	var yaw_input := float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)) - float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT))
	var pitch_input := float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) - float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	return Vector2(yaw_input, pitch_input)

func _liftoff_pitch_arc(elapsed: float) -> float:
	var pitch_in := smoothstep(1.0, 6.0, elapsed)
	var pitch_out := 1.0 - smoothstep(12.0, 23.0, elapsed)
	return 0.28 * pitch_in * pitch_out

func _set_astronaut_in_cabin(cabin_start: Transform3D) -> void:
	if is_instance_valid(_shuttle_flight_attitude):
		astronaut.global_transform = _shuttle_flight_attitude.global_transform * cabin_start

func _flight_vehicle_position() -> Vector3:
	if is_instance_valid(_shuttle_flight_pivot):
		return _shuttle_flight_pivot.global_position
	return ship_root.global_position + ship_position

func _spawn_flight_asteroids(start: Vector3, start_yaw: float, start_pitch: float, start_speed: float) -> void:
	_flight_asteroids.clear()
	if not is_instance_valid(_earth):
		return
	var simulation_position := start
	var simulation_yaw := start_yaw
	var simulation_pitch := start_pitch
	var simulation_speed := start_speed
	var simulation_time := 0.0
	var target_times := [10.0, 18.0, 27.0, 37.0]
	var side_offsets := [0.0, 15.0, -15.0, 10.0]
	var asteroid_positions: Array[Vector3] = []
	var target_index := 0
	while simulation_time < float(target_times.back()):
		var step := 0.05
		var to_earth := _earth.global_position - simulation_position
		var to_earth_direction := to_earth.normalized()
		var desired_yaw := atan2(-to_earth_direction.x, -to_earth_direction.z)
		var desired_pitch := atan2(to_earth_direction.y, Vector2(to_earth_direction.x, to_earth_direction.z).length())
		simulation_yaw = rotate_toward(simulation_yaw, desired_yaw, 1.25 * step)
		simulation_pitch = move_toward(simulation_pitch, desired_pitch + _liftoff_pitch_arc(simulation_time), 1.15 * step)
		simulation_speed = move_toward(simulation_speed, FLIGHT_SPEED, 7.0 * step)
		var heading := Vector3(-sin(simulation_yaw) * cos(simulation_pitch), sin(simulation_pitch), -cos(simulation_yaw) * cos(simulation_pitch)).normalized()
		simulation_position += heading * simulation_speed * step
		simulation_time += step
		if target_index < target_times.size() and simulation_time >= float(target_times[target_index]):
			asteroid_positions.append(simulation_position)
			target_index += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 812045
	for index in range(asteroid_positions.size()):
		var radius := rng.randf_range(19.0, 25.0)
		var position: Vector3 = asteroid_positions[index]
		var near_earth := (_earth.global_position - position).normalized()
		var side := near_earth.cross(Vector3.UP)
		if side.length_squared() < 0.001:
			side = Vector3.RIGHT
		side = side.normalized()
		position += side * float(side_offsets[index])
		var asteroid := Node3D.new()
		asteroid.name = "Flight asteroid %02d" % (index + 1)
		asteroid.global_position = position
		asteroid.rotation = Vector3(rng.randf_range(-PI, PI), rng.randf_range(-PI, PI), rng.randf_range(-PI, PI))
		add_child(asteroid)
		var rock_material := _material(Color(0.26, 0.25, 0.23), 1.0)
		var core_mesh := SphereMesh.new()
		core_mesh.radius = radius
		core_mesh.height = radius * 2.0
		core_mesh.radial_segments = 9
		core_mesh.rings = 6
		var core := MeshInstance3D.new()
		core.mesh = core_mesh
		core.material_override = rock_material
		core.scale = Vector3(1.15, 0.82, 1.0)
		asteroid.add_child(core)
		var warning_marker := _label_3d("!", 56, Color(1.0, 0.55, 0.27))
		warning_marker.position = Vector3(0.0, radius + 18.0, 0.0)
		asteroid.add_child(warning_marker)
		for lump_index in range(4):
			var lump_radius := radius * rng.randf_range(0.22, 0.42)
			var lump_mesh := SphereMesh.new()
			lump_mesh.radius = lump_radius
			lump_mesh.height = lump_radius * 2.0
			lump_mesh.radial_segments = 7
			lump_mesh.rings = 5
			var lump := MeshInstance3D.new()
			lump.mesh = lump_mesh
			lump.material_override = rock_material
			var spread := radius * 0.62
			lump.position = Vector3(rng.randf_range(-spread, spread), rng.randf_range(-spread, spread), rng.randf_range(-spread, spread))
			lump.scale = Vector3(rng.randf_range(0.72, 1.25), rng.randf_range(0.72, 1.3), rng.randf_range(0.72, 1.2))
			asteroid.add_child(lump)
		_flight_asteroids.append({"node": asteroid, "collision_radius": radius * 1.2 + 12.0})

func _handle_flight_crash() -> void:
	if _flight_crashed:
		return
	_flight_crashed = true
	_launch_engines_active = false
	_launch_shake_strength = 0.0
	for flame in _launch_flames:
		flame.visible = false
	if is_instance_valid(_launch_engine_light):
		_launch_engine_light.light_energy = 0.0
	if is_instance_valid(_launch_dust):
		_launch_dust.emitting = false
	SFX.stop_ship_travel()
	SFX.stop_ambient()
	astronaut.set_physics_process(false)
	_ui.visible = false
	_flight_ui.visible = false
	_arrival_video.stop()
	_arrival_video.visible = false
	_arrival_fade.color = Color(0.85, 0.2, 0.06, 0.0)
	var impact_flash := create_tween()
	impact_flash.tween_property(_arrival_fade, "color", Color(0.85, 0.2, 0.06, 0.9), 0.18)
	impact_flash.tween_property(_arrival_fade, "color", Color.BLACK, 0.72)
	await impact_flash.finished
	_commander_message("Impact confirmed. Return vehicle lost. Mission control recommends a restart.")
	_crash_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _play_earth_arrival_cutscene() -> void:
	SFX.stop_ambient()
	_flight_ui.visible = false
	_ui.visible = false
	_arrival_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	var fade_to_black := create_tween()
	fade_to_black.tween_property(_arrival_fade, "color", Color.BLACK, 1.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_to_black.finished
	_arrival_video.visible = true
	_arrival_video.play()
	SFX.start_ship_travel()
	var reveal_video := create_tween()
	reveal_video.tween_property(_arrival_fade, "color", Color(0.0, 0.0, 0.0, 0.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await reveal_video.finished
	await _arrival_video.finished
	_arrival_video.paused = true
	SFX.stop_ship_travel()

func _commander_message(message: String) -> void:
	if _command_label == null:
		return
	_command_label.text = message
	_command_time_label.text = "Commander Sato  •  %02d:%02d" % [int(mission_seconds / 60.0), int(fmod(mission_seconds, 60.0))]
	_command_log.append("%02d:%02d  •  %s" % [int(mission_seconds / 60.0), int(fmod(mission_seconds, 60.0)), message])
	while _command_log.size() > 8:
		_command_log.pop_front()
	_refresh_command_log()

func _refresh_command_log() -> void:
	if _command_log_label == null:
		return
	_command_log_label.text = "No messages yet." if _command_log.is_empty() else "\n\n".join(_command_log)

func _award(amount: int, reason: String) -> void:
	credits += amount
	if _credits_label != null:
		_credits_label.text = "REPAIR CREDITS  /  %04d" % credits
	_set_message("+%d credits  •  %s" % [amount, reason], Color(0.86, 0.8, 0.53))

func _set_message(message: String, color: Color) -> void:
	if _toast_label == null:
		return
	_toast_label.text = message
	_toast_label.add_theme_color_override("font_color", color)
	_toast_label.modulate.a = 1.0
	_toast_timer = 4.0

func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _add_box(label: String, point: Vector3, dimensions: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.visibility_range_end = 250.0
	parent.add_child(instance)
	return instance

func _add_cylinder(label: String, point: Vector3, radius: float, height: float, material: Material, sides: int, parent: Node3D) -> MeshInstance3D:
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
	instance.visibility_range_end = 250.0
	parent.add_child(instance)
	return instance

func _add_sphere(label: String, point: Vector3, size: Vector3, material: Material, parent: Node3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 10
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = point
	instance.scale = size
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.visibility_range_end = 250.0
	parent.add_child(instance)
	return instance

func _add_cylinder_between(label: String, start: Vector3, finish: Vector3, radius: float, material: Material, parent: Node3D) -> MeshInstance3D:
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
	instance.visibility_range_end = 250.0
	parent.add_child(instance)
	return instance

func _add_label(text: String, point: Vector3, color: Color, parent: Node3D) -> Label3D:
	var label := _label_3d(text, 27, color)
	label.position = point
	label.visibility_range_end = 210.0
	parent.add_child(label)
	return label

func _label_3d(text: String, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.014
	label.modulate = color
	label.outline_size = 5
	label.outline_modulate = Color(0.025, 0.035, 0.045, 0.92)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label

func _material(color: Color, roughness_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	return material

func _emissive(color: Color) -> StandardMaterial3D:
	var material := _material(color, 0.42)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 1.8
	return material

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	if _console_font != null:
		label.add_theme_font_override("font", _console_font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func _panel(background: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.48)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 3.0)
	style.content_margin_left = 11.0
	style.content_margin_right = 11.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

extends Control

var _stars: Array[Vector3] = []
var _phase := 0.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 610317
	for index in range(145):
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.72, rng.randf_range(0.35, 1.5)))
	set_process(true)

func _process(delta: float) -> void:
	_phase += delta * 0.12
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	if size.x < 2.0 or size.y < 2.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color("070c16"))
	for band in range(14):
		var y := float(band) / 14.0 * size.y
		var t := float(band) / 14.0
		var color := Color(0.04, 0.075, 0.12).lerp(Color(0.11, 0.14, 0.16), t * 0.62)
		draw_rect(Rect2(0.0, y, size.x, size.y / 14.0 + 1.0), color)

	for star in _stars:
		var twinkle := 0.68 + 0.32 * sin(_phase * 6.0 + star.z * 10.0 + star.x * 30.0)
		var color := Color(0.68, 0.82, 0.94, 0.25 + twinkle * 0.52)
		var radius := 0.65 if star.z < 0.8 else 1.0 if star.z < 1.25 else 1.55
		draw_circle(Vector2(star.x * size.x, star.y * size.y), radius, color)

	_draw_earth(size)
	_draw_mountain_silhouettes(size)
	_draw_near_horizon(size)
	_draw_outpost(size)

func _draw_earth(size: Vector2) -> void:
	var center := Vector2(size.x * 0.79, size.y * 0.295)
	var radius := minf(size.x * 0.105, size.y * 0.205)
	for glow in range(6, 0, -1):
		draw_circle(center, radius + glow * 5.0, Color(0.19, 0.42, 0.66, 0.014))
	draw_circle(center, radius, Color(0.12, 0.31, 0.55))
	draw_circle(center + Vector2(-radius * 0.16, -radius * 0.12), radius * 0.91, Color(0.14, 0.39, 0.64))
	draw_circle(center + Vector2(-radius * 0.32, -radius * 0.24), radius * 0.88, Color(0.18, 0.44, 0.67, 0.75))
	var cloud_a := PackedVector2Array([
		center + Vector2(-radius * 0.63, -radius * 0.08),
		center + Vector2(-radius * 0.25, -radius * 0.36),
		center + Vector2(radius * 0.06, -radius * 0.26),
		center + Vector2(radius * 0.26, -radius * 0.43),
		center + Vector2(radius * 0.53, -radius * 0.22),
		center + Vector2(radius * 0.45, radius * 0.0),
		center + Vector2(radius * 0.12, radius * 0.09),
		center + Vector2(-radius * 0.26, radius * 0.2),
	])
	draw_colored_polygon(cloud_a, Color(0.68, 0.79, 0.83, 0.24))
	draw_arc(center, radius, -PI * 0.58, PI * 0.51, 96, Color(0.72, 0.88, 0.97, 0.72), 1.5, true)
	draw_arc(center, radius * 1.03, -PI * 0.62, PI * 0.48, 96, Color(0.33, 0.63, 0.84, 0.34), 6.0, true)

func _draw_mountain_silhouettes(size: Vector2) -> void:
	var horizon := size.y * 0.66
	for layer in range(4):
		var points := PackedVector2Array()
		points.append(Vector2(0.0, size.y))
		var base := horizon + float(layer) * size.y * 0.047
		for index in range(25):
			var x := float(index) / 24.0 * size.x
			var broad := sin(index * 1.17 + layer * 2.2) * size.y * (0.055 - layer * 0.006)
			var fine := sin(index * 3.73 + layer * 0.83) * size.y * 0.013
			var ridge := base - broad - fine
			points.append(Vector2(x, ridge))
		points.append(Vector2(size.x, size.y))
		var colors := [Color("171f29"), Color("252c32"), Color("343a3d"), Color("424544")]
		draw_colored_polygon(points, colors[layer])
		var line_points := PackedVector2Array()
		for point_index in range(1, points.size() - 1):
			line_points.append(points[point_index])
		draw_polyline(line_points, Color(0.65, 0.68, 0.66, 0.09 + layer * 0.025), 1.0, true)

func _draw_near_horizon(size: Vector2) -> void:
	var y := size.y * 0.82
	draw_rect(Rect2(0.0, y, size.x, size.y - y), Color("20262a"))
	var surface := PackedVector2Array([
		Vector2(0.0, y + size.y * 0.04), Vector2(size.x * 0.08, y - size.y * 0.015),
		Vector2(size.x * 0.19, y + size.y * 0.028), Vector2(size.x * 0.32, y - size.y * 0.048),
		Vector2(size.x * 0.47, y + size.y * 0.008), Vector2(size.x * 0.61, y - size.y * 0.03),
		Vector2(size.x * 0.73, y + size.y * 0.016), Vector2(size.x * 0.88, y - size.y * 0.04),
		Vector2(size.x, y + size.y * 0.01), Vector2(size.x, size.y), Vector2(0.0, size.y)
	])
	draw_colored_polygon(surface, Color("34393b"))
	draw_polyline(PackedVector2Array(surface.slice(0, 9)), Color(0.78, 0.77, 0.7, 0.11), 1.0, true)
	var crater_data := [
		Vector3(size.x * 0.18, y + 25.0, 27.0), Vector3(size.x * 0.43, y + 17.0, 18.0),
		Vector3(size.x * 0.68, y + 27.0, 32.0), Vector3(size.x * 0.93, y + 13.0, 20.0),
	]
	for crater in crater_data:
		var center := Vector2(crater.x, crater.y)
		var radius: float = float(crater.z) * minf(size.y / 900.0, 1.25)
		draw_circle(center, radius, Color(0.09, 0.11, 0.12, 0.34))
		draw_arc(center + Vector2(0.0, 2.0), radius, PI * 0.12, PI * 0.87, 32, Color(0.76, 0.73, 0.65, 0.16), 1.0, true)

func _draw_outpost(size: Vector2) -> void:
	var base := Vector2(size.x * 0.86, size.y * 0.83)
	draw_rect(Rect2(base.x - 48.0, base.y - 66.0, 96.0, 66.0), Color("151c20"))
	draw_rect(Rect2(base.x - 35.0, base.y - 78.0, 70.0, 16.0), Color("11191d"))
	draw_rect(Rect2(base.x - 14.0, base.y - 33.0, 28.0, 33.0), Color("10171a"))
	draw_rect(Rect2(base.x - 12.0, base.y - 59.0, 24.0, 3.0), Color(0.37, 0.81, 0.77, 0.75))
	draw_line(base + Vector2(52.0, -30.0), base + Vector2(52.0, -142.0), Color("10171a"), 3.0)
	draw_line(base + Vector2(41.0, -142.0), base + Vector2(63.0, -142.0), Color("10171a"), 2.0)
	draw_circle(base + Vector2(52.0, -143.0), 2.4, Color(0.28, 0.87, 0.83, 0.84))
	draw_line(base + Vector2(-97.0, -5.0), base + Vector2(-69.0, -34.0), Color("171e22"), 4.0)
	draw_line(base + Vector2(-69.0, -34.0), base + Vector2(-42.0, -5.0), Color("171e22"), 4.0)

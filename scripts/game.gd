extends Node2D

const HOME_SCENE := "res://scenes/home.tscn"
var player := Vector2.ZERO
var velocity := Vector2.ZERO
var planet := Vector2.ZERO
var planet_radius := 74.0
var screen_size := Vector2.ZERO

func _ready() -> void:
	screen_size = get_viewport_rect().size
	planet = Vector2(screen_size.x * 0.5, screen_size.y * 0.72)
	player = planet + Vector2(0, -planet_radius - 22)
	set_process(true)

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().change_scene_to_file(HOME_SCENE)
		return
	var direction := Vector2.ZERO
	direction.x = float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	direction.y = float(Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	velocity += direction.normalized() * 520.0 * delta
	velocity += (planet - player).normalized() * 95.0 * delta
	velocity = velocity.limit_length(310.0)
	player += velocity * delta
	if player.distance_to(planet) < planet_radius + 12.0:
		player = planet + (player - planet).normalized() * (planet_radius + 12.0)
		velocity = velocity.slide((player - planet).normalized())
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(HOME_SCENE)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color("080d1b"))
	for i in range(28):
		var p := Vector2(fposmod(i * 173.7, screen_size.x), fposmod(i * 97.3, screen_size.y))
		draw_circle(p, 1.4 if i % 5 == 0 else 0.8, Color(0.7, 0.82, 1.0, 0.5))
	for ring in range(1, 5):
		draw_arc(planet, planet_radius + ring * 31.0, 0, TAU, 100, Color(0.25, 0.85, 0.84, 0.10 - ring * 0.015), 1.0, true)
	draw_circle(planet, planet_radius + 7, Color(0.17, 0.69, 0.72, 0.15))
	draw_circle(planet, planet_radius, Color("152f4a"))
	draw_arc(planet, planet_radius, 0, TAU, 96, Color("56e0dc"), 2.0, true)
	draw_circle(planet + Vector2(-22, -19), 6, Color(0.37, 0.77, 0.83, 0.6))
	draw_circle(planet + Vector2(20, 24), 9, Color(0.37, 0.77, 0.83, 0.4))
	draw_circle(player, 10, Color(0.28, 0.94, 0.89, 0.22))
	draw_circle(player, 6, Color("b9fff4"))
	draw_circle(player, 3, Color.WHITE)

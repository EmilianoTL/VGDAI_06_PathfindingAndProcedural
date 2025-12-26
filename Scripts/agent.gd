extends CharacterBody2D

#Señales
signal movement_finished

#Velocidad
@export var speed: float = 150.0

var path_points: Array[Vector2] = []
var is_moving: bool = false

func _physics_process(delta):
	if not is_moving or path_points.is_empty():
		return
	var target_pos = path_points[0]
	position = position.move_toward(target_pos, speed * delta)
	if position.distance_to(target_pos) < 1.0:
		path_points.pop_front()
		if path_points.is_empty():
			is_moving = false
			movement_finished.emit() 
			print("Agente: LLegue a la meta")

#Establece objetivo y verifica que sea una casillan distinta a la mia
func set_path_and_go(new_path: Array[Vector2]):
	path_points = new_path
	if path_points.size() > 0:
		if position.distance_to(path_points[0]) < 2.0:
			path_points.pop_front()
		is_moving = true

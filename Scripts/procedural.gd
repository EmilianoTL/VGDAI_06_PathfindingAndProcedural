extends Node2D

#Configuracion del laberinto generacion automatica
@export var width: int = 80
@export var height: int = 45
@export var noise : FastNoiseLite
@export var sc: float = 1.2

#Nodes
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var target_sprite = $Target
@onready var agent_body = $Agent 

#Tiles
var tile_grass = Vector2i(1, 0) 
var tile_ground = Vector2i(0, 0)
var source_id = 0

#Agent
var agent_grid_pos: Vector2i
var target_grid_pos: Vector2i
var placing_step: int = 0
var pathfinder: AStarPathfinder

func _ready():
	randomize()
	noise.seed = randi()
	pathfinder = AStarPathfinder.new(is_valid_position)
	agent_body.movement_finished.connect(on_agent_arrived)
	generate_maze()

func generate_maze():
	tile_map.clear()
	for x in range(width):
		for y in range(height):
			var n = noise.get_noise_2d(float(x)/sc, float(y)/sc)
			if (n+1)/2 > 0.49:
				tile_map.set_cell(Vector2i(x, y), source_id, tile_ground)
			else:
				tile_map.set_cell(Vector2i(x, y), source_id, tile_grass)

func on_agent_arrived():
	print("LLegue a la meta.")
	await get_tree().create_timer(0.5).timeout
	regenerate()

func regenerate():
	noise.seed = randi()
	generate_maze()
	agent_body.visible = false 
	target_sprite.visible = false
	placing_step = 0

#Lectura de input
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = tile_map.local_to_map(get_global_mouse_position())
		if is_valid_position(grid_pos):
			handle_click(grid_pos)

#Posición valida, es decir cesped
func is_valid_position(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= width or pos.y < 0 or pos.y >= height: return false
	if tile_map.get_cell_atlas_coords(pos) == tile_ground: return false
	return true

func handle_click(pos: Vector2i):
	if placing_step == 0: #Colocar agente
		target_sprite.visible = false	
		agent_grid_pos = pos
		agent_body.position = tile_map.map_to_local(pos)
		agent_body.visible = true
		placing_step = 1
		
	elif placing_step == 1: #Meta y moverse
		target_grid_pos = pos
		target_sprite.position = tile_map.map_to_local(pos)
		target_sprite.visible = true
		placing_step = 0
		calculate_and_move_agent()

func calculate_and_move_agent():
	var path_grid = pathfinder.get_path(agent_grid_pos, target_grid_pos)
	if path_grid.is_empty():
		print("No hay camino.")
		return
	#De cuadricula a cordenadas reales
	var path_world: Array[Vector2] = []
	for point in path_grid:
		path_world.append(tile_map.map_to_local(point))
	
	#Sigue la ruta
	agent_body.set_path_and_go(path_world)

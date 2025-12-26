class_name AStarPathfinder extends RefCounted

const MAX_ITERATIONS = 10000
var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		
		
class NodeData:
	var position: Vector2i
	var g: int = 0 
	var h: int = 0 
	var f: int = 0 
	var parent: NodeData = null 

	func _init(pos: Vector2i):
		position = pos

	# Calculamos f = g + h
	func calculate_f(target_pos: Vector2i):
		#Funcion heuristica
		h = abs(position.x - target_pos.x) + abs(position.y - target_pos.y)
		f = g + h

# Variable para guardar la función que chequea muros
var _is_walkable_callback: Callable

# Constructor: Recibe la función del World que dice si es muro
func _init(check_wall_func: Callable):
	_is_walkable_callback = check_wall_func


func get_path(start_pos: Vector2i, end_pos: Vector2i) -> Array[Vector2i]:
	var list_nodes: Array[NodeData] = []
	var visited_nodes: Dictionary = {} 
	
	#Nodo inicial
	var start_node = NodeData.new(start_pos)
	start_node.calculate_f(end_pos)
	list_nodes.append(start_node)
	

	var i = 0
	while list_nodes.size() > 0:
		i += 1
		if i > MAX_ITERATIONS:
			print("A*: Límite de iteraciones alcanzado.")
			return [] 
		
		#obtenemos el nodo con la menor n
		var current_node = _get_lowest_f_node(list_nodes)
		#Visitamos nodo
		list_nodes.erase(current_node)
		visited_nodes[current_node.position] = true
		
		#Caso base
		if current_node.position == end_pos:
			return _reconstruct_path(current_node)
		
		#Movimientos
		for dir in directions:
			var neighbor_pos = current_node.position + dir
			
			#Nodo valido?
			if visited_nodes.has(neighbor_pos):
				continue
			if not _is_walkable_callback.call(neighbor_pos):
				continue
				
			var new_g = current_node.g+ 1
			# Se encuentra en la lista
			var existing_node = _find_node_in_list(list_nodes, neighbor_pos)
			if existing_node == null:
				# Es un vecino nuevo
				var new_node = NodeData.new(neighbor_pos)
				new_node.g = new_g
				new_node.calculate_f(end_pos)
				new_node.parent = current_node
				list_nodes.append(new_node)
			elif new_g < existing_node.g:
				# Es un camino mejor a un nodo conocido
				existing_node.g = new_g
				existing_node.calculate_f(end_pos)
				existing_node.parent = current_node
				
	return [] 

#Buscamos el nodo de con menor f
func _get_lowest_f_node(list: Array) -> NodeData:
	var lowest = list[0]
	for node in list:
		if node.f < lowest.f:
			lowest = node
	return lowest
	
#Visitamos nuestros padres para recuperar el camin
func _reconstruct_path(end_node: NodeData) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current = end_node
	while current != null:
		path.append(current.position)
		current = current.parent
	path.reverse()
	return path

#buscamos si hay un nodo igual en la lista
func _find_node_in_list(list: Array, pos: Vector2i) -> NodeData:
	for node in list:
		if node.position == pos: return node
	return null

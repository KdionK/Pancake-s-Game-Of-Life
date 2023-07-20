extends Node2D

@export var grid_size : Vector2;
@export var square_pixel_size : int;
var grid  : Array[PackedByteArray] = [];
var updated_grid : Array[PackedByteArray] = [];
var square_grid = [];

enum modes {
	PAINT,
	ERASE
}
var currentMode = modes.PAINT;
var playMode = false;

@export var ui : Node2D;

func _ready():
	var column = PackedByteArray();
	var square_column = [];
	for i in grid_size.x:
		for j in grid_size.y:
			column.append(0);
			square_column.append(null);
		grid.append(column);
		square_grid.append(square_column);
		column = PackedByteArray();
		square_column = [];
	updated_grid = grid.duplicate(true);

func _process(_delta):
	_change_mode();
	_play_on_off();
	if Input.is_action_pressed("mouse"):
		var mouse_pos = get_global_mouse_position();
		var square_coord = Vector2(floor(mouse_pos / square_pixel_size))
		if grid[square_coord.x][square_coord.y] == 0 && currentMode == modes.PAINT:
			place_square(square_coord *square_pixel_size,square_coord);
		elif grid[square_coord.x][square_coord.y] == 1 && currentMode == modes.ERASE:
			delete_square(square_coord);

func place_square(rect_position : Vector2,square_coord : Vector2):
	grid[square_coord.x][square_coord.y] = 1;
	updated_grid[square_coord.x][square_coord.y] = 1;
	var CR = ColorRect.new();
	CR.size = Vector2(square_pixel_size,square_pixel_size);
	CR.color = Color.WHITE;
	CR.position =rect_position;
	square_grid[square_coord.x][square_coord.y] = CR;
	add_child(CR);

func delete_square(square_coord : Vector2):
	square_grid[square_coord.x][square_coord.y].queue_free();
	grid[square_coord.x][square_coord.y] = 0;
	updated_grid[square_coord.x][square_coord.y] = 0;

func _change_mode():
	if Input.is_key_pressed(KEY_E):
		currentMode = modes.ERASE;
	if Input.is_key_pressed(KEY_B):
		currentMode = modes.PAINT
	ui.get_node("PaintMode").text = str("Mode: ","paint" if currentMode == modes.PAINT else "erase");

func _play_on_off():
	if Input.is_action_just_pressed("ui_accept"):
		if playMode:
			$Timer.stop();
		else:
			$Timer.start(1);
		playMode = !playMode;
		ui.get_node("PlayMode").text = str("Play: ","on" if playMode else "off");

func _on_timer_timeout():
#	var string : String = "grid: \n"
#	if playMode:
#		for i in grid_size.y:
#			for j in grid_size.x:
#				string += str(" ",grid[j][i])
#			string += str("\n");
#		print(string);
		_identify_neighbors();
		_update_grid_visually();

func _identify_neighbors():
	var squares_to_check : Array[Vector2];
	var x_index = 0;
	for i in grid: ## this is the x axis - i
		var valid_x_coordinates : Array[int] = [x_index - 1, x_index, x_index + 1];
		valid_x_coordinates = valid_x_coordinates.filter(func(number): return number >=0 && number <= 19);
		x_index += 1;
		var y_index = 0;
		for j in i:## this is the y axis - j
			var valid_y_coordinates : Array[int] = [y_index - 1, y_index, y_index + 1];
			valid_y_coordinates = valid_y_coordinates.filter(func(number): return number >=0 && number <= 19);
			squares_to_check = assemble_neighbors(valid_x_coordinates,valid_y_coordinates, Vector2(x_index-1,y_index));
			verify_square(Vector2(x_index-1,y_index),squares_to_check);
			y_index += 1;

func assemble_neighbors(possible_x_coordinates :Array[int], possible_y_coordinates :Array[int], to_delete :Vector2) ->Array[Vector2]:
	var neighbors : Array[Vector2] = [];
	for i in possible_x_coordinates:
		for j in possible_y_coordinates:
			neighbors.append(Vector2(i,j));
	neighbors.erase(to_delete);
	return neighbors;
	
func verify_square(current_square :Vector2, neighbors:Array[Vector2]):
#	print(neighbors);
	var number_of_active_squares = 0
	for i in neighbors:
		if grid[i.x][i.y] == 1:
			number_of_active_squares +=1;
#	print(number_of_active_squares)
	if !grid[current_square.x][current_square.y] && number_of_active_squares ==3:
		updated_grid[current_square.x][current_square.y] = 1;
	elif !(grid[current_square.x][current_square.y] && (number_of_active_squares ==2 || number_of_active_squares ==3)):
		updated_grid[current_square.x][current_square.y] = 0;
	

func _update_grid_visually():
	var x = 0;
	for i in grid_size.x:
		for j in grid_size.y:
			x+=1;
			if updated_grid[i][j] == 1 and grid[i][j] == 0:
				place_square(Vector2(i,j) *square_pixel_size,Vector2(i,j));
			elif updated_grid[i][j] == 0 and grid[i][j] == 1:
				delete_square(Vector2(i,j))
	grid = updated_grid.duplicate(true);

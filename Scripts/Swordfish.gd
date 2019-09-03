extends Node2D

enum MODE {
	WAITING_FOR_INPUT
	MOVING
	}

var STATE;
var goalPosition;
export var moveDist = 300;

var draw_moveline

var mousePos
# Called when the node enters the scene tree for the first time.
func _ready():
	self.STATE = MODE.WAITING_FOR_INPUT

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Determine what type of action to take
	match self.STATE:
		# Waiting for a new mouse click from user.
		MODE.WAITING_FOR_INPUT:
			mousePos = get_viewport().get_mouse_position()
			# Draw line from ship to mouse if mouse is in range.
			draw_moveline = self.position.distance_to(mousePos) <= moveDist
			if Input.is_action_just_pressed("MoveShip"):
				if self.position.distance_to(mousePos) <= moveDist:
					initiateMove(mousePos)
		# Animating movement to new location, do not accept new movement commands.
		MODE.MOVING:
			self.position = goalPosition;
			STATE = MODE.WAITING_FOR_INPUT
	
	# Run the draw function each frame
	update()

func _draw():
	draw_ring(Vector2(0,0), moveDist, 2, Color.white, 64)
	if draw_moveline == true:
		draw_line(Vector2(0,0), mousePos-self.position, Color.red, 2.5, true)

# draws an empty circle
func draw_ring(center:Vector2, radius:float, thickness:float, color:Color, resolution:int):
	var drawCounter = 0
	var startl = Vector2(center.x, center.y-radius+thickness/2) 
	var endl = Vector2()
	
	while drawCounter<resolution:
		endl = startl.rotated(2*PI/resolution)
		draw_line(startl, endl, color, thickness, true)
		startl = endl
		drawCounter+=1

func initiateMove(Position):
	self.goalPosition = Position
	self.STATE = MODE.MOVING
extends Node2D

enum MODE {
	WAITING_FOR_INPUT
	ACCELERATING
	DECELERATING
	}


export var moveDist = 400;

var STATE;
var goalPosition;
var acceleration = 500;
var maxSpeed = 1500;
var velocity = Vector2(0,0);
var angle_acceleration = 1;
var angle_maxspeed = 1;
var angle_velocity = 0;

var draw_moveline;
var draw_range;

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
			draw_range = self.position.distance_to(mousePos) >= moveDist
			if Input.is_action_just_pressed("MoveShip"):
				if self.position.distance_to(mousePos) <= moveDist:
					initiateMove(mousePos)
		
		# Animating movement to new location, do not accept new movement commands.
		MODE.ACCELERATING:
			self.velocity.y -= acceleration*delta; # add acceleration to velocity vector (-y = forward)
			velocity.y = clamp(velocity.y, -maxSpeed, maxSpeed)
			applyVelocity(delta)
			if self.position.distance_to(goalPosition)<=pow(velocity.y,2)/(2*acceleration): # If the remaining distance is less than the braking distance,
				self.STATE = MODE.DECELERATING; # begin decelerating.
		
		MODE.DECELERATING:
			self.velocity.y += acceleration*delta; # subtract acceleration from velocity vector (+y = reverse)
			applyVelocity(delta)
			if velocity.y>=0: # if the ship has come to a stop,
				velocity.y = 0; # remove all extra velocity
				self.position = goalPosition; # move to exactly the target position
				STATE = MODE.WAITING_FOR_INPUT # change state

	# Run the draw function each frame
	update()

func _draw():
	if draw_range:
		draw_ring(Vector2(0,0), moveDist, 2, Color.white, 64)
	if draw_moveline == true:
		draw_line(Vector2(0,0), to_local(mousePos), Color.red, 2.5, true)

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
	self.rotation += get_angle_to(goalPosition)+deg2rad(90) # instantly rotate to face target
	self.STATE = MODE.ACCELERATING

func applyVelocity(delta):
	self.position += velocity.rotated(self.rotation)*delta # Apply velocity relative to ship OCS
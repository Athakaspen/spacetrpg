extends Node2D

enum STATE {
	WAITING_FOR_INPUT
	MOVING
	}
enum TURNSTATE {
	STATIC
	TURNING
	}
enum MOVESTATE {
	STATIC
	MOVING
	}


export var moveDist = 3000;

var acceleration = 500; # units/sec/sec
var maxSpeed = 1000; # units/sec
var angleAcceleration = 6; # rad/sec/sec
var angleMaxspeed = 10; # rad/sec

var State;
var MoveState;
var TurnState;
var goalPosition;
var velocity = Vector2(0,0); # current velocity vector
var turnVelocity = 0.0; # current turning speed (in radians)

var draw_moveline;
var draw_range;

var mousePos
# Called when the node enters the scene tree for the first time.
func _ready():
	self.State = STATE.WAITING_FOR_INPUT;
	self.MoveState = MOVESTATE.STATIC;
	self.TurnState = TURNSTATE.STATIC;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Determine what type of action to take
	match self.State:
		# Waiting for a new mouse click from user.
		STATE.WAITING_FOR_INPUT:
			mousePos = get_viewport().get_mouse_position()
			# Draw line from ship to mouse if mouse is in range.
			draw_moveline = self.position.distance_to(mousePos) <= moveDist
			draw_range = self.position.distance_to(mousePos) >= moveDist
			if Input.is_action_just_pressed("MoveShip"):
				if self.position.distance_to(mousePos) <= moveDist and self.position.distance_to(mousePos) > 5: # Move if the new position is in range, but restrict exceptionally small movements.
					initiateMove(mousePos)

				# OLD MOVEMENT CODE
		# Animating movement to new location, do not accept new movement commands.
		STATE.MOVING:

			match self.TurnState:
				TURNSTATE.STATIC:
					pass
				TURNSTATE.TURNING:
					var angleTo = self.get_angle_to(goalPosition)+PI/2; # get relative angle to goal position
					if angleTo >= PI: angleTo = -2*PI+angleTo; #correct for ship direction not being 0 radians
					if abs(angleTo)>pow(turnVelocity,2)/(2*angleAcceleration): # If the remaining angle is more than the braking angle,
						turnVelocity += sign(angleTo)*angleAcceleration*delta # speed up
						turnVelocity = clamp(turnVelocity, -angleMaxspeed, angleMaxspeed) # do not exceed max angular velocity
					else: # If the remaining angle is less than or equal to the braking angle,
						turnVelocity -= sign(angleTo)*angleAcceleration*delta # slow down
					applyAngularVelocity(delta);
					angleTo = self.get_angle_to(goalPosition)+PI/2; # get relative angle to goal position
					if angleTo >= PI: angleTo = -2*PI+angleTo; #correct for ship direction not being 0 radians
					if MoveState == MOVESTATE.STATIC and abs(angleTo) <= clamp(self.position.distance_to(goalPosition)/(acceleration/4),0,1)*PI/2:
						MoveState = MOVESTATE.MOVING
					if abs(angleTo) <= 0.02: # snap to angle if within given range
						self.rotation += angleTo
						turnVelocity = 0.0
						self.TurnState = TURNSTATE.STATIC

			match self.MoveState:
				MOVESTATE.STATIC:
					pass
				MOVESTATE.MOVING:
					var distanceTo = self.position.distance_to(goalPosition)
					if distanceTo>pow(velocity.y,2)/(2*acceleration): # If the remaining distance is greater than the braking distance,
						self.velocity.y -= acceleration*delta; # add acceleration to velocity vector (-y = forward)
						velocity.y = clamp(velocity.y, -maxSpeed, maxSpeed)
					else:
						self.velocity.y += acceleration*delta; # subtract acceleration from velocity vector (+y = reverse)
					applyVelocity(delta)
					if self.position.distance_to(goalPosition) >= distanceTo:
						velocity.y = 0; # remove all extra velocity
						self.position = goalPosition; # move to exactly the goal position
						MoveState = MOVESTATE.STATIC;
						TurnState = TURNSTATE.STATIC;
						turnVelocity = 0.0
						State = STATE.WAITING_FOR_INPUT;


	# Run the draw function each frame
	update()

func _draw():
	if draw_range:
		draw_ring(Vector2(0,0), moveDist, 2, Color.white, 84)
	if draw_moveline == true:
		draw_line(Vector2(0,0), to_local(mousePos), Color.red, 2.5, true)

# draws an empty circle
func draw_ring(center:Vector2, radius:float, thickness:float, color:Color, resolution:int):
	var drawCounter = 0
	var startl = Vector2(center.x, center.y-radius+thickness/2) 
	var endl = Vector2()
	
	while drawCounter<resolution:
		endl = startl.rotated(2*PI/resolution)
		if !drawCounter%3:
			draw_line(startl, endl, color, thickness, true)
		startl = endl
		drawCounter+=1

func initiateMove(Position):
	self.goalPosition = Position
	self.State = STATE.MOVING
	self.TurnState = TURNSTATE.TURNING
	self.MoveState = MOVESTATE.STATIC

func applyVelocity(delta):
	self.position += velocity.rotated(self.rotation)*delta # Apply velocity relative to ship OCS

func applyAngularVelocity(delta):
	self.rotation += turnVelocity*delta # apply angular velocity to currect rotation
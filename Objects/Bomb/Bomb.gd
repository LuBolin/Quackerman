class_name Bomb
extends Node2D
static var BombScene = load("res://Objects/Bomb/Bomb.tscn")

@onready var fuseLabel: Label:
	set(value):
		fuseLabel = value
		if fuse:
			fuseLabel.text = str(fuse)

var fuse: int:
	set(value):
		fuse = value
		if fuseLabel:
			fuseLabel.text = str(value)
var strength: int;
var coords: Vector2i;
var quackerBombStackRender;
var explosionCallback; # quacker action callback actually
const directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

static func makeBomb(coords: Vector2i, qbStackRender, explosionCallback,
	strength: int, fuse: int ):
	var bomb = BombScene.instantiate()
	bomb.coords = coords
	bomb.strength = strength
	bomb.fuse = fuse
	bomb.quackerBombStackRender = qbStackRender
	bomb.explosionCallback = explosionCallback
	return bomb

func _ready():
	fuseLabel = $Fuse_Label
	Singleton.tick2.connect(self.tick)
	pass

func get_affected():
	var affected: Array[Vector2i] = []
	
	for dir in directions:
		for step in range(strength + 1):
			var new_coords = coords + dir * step
			affected.append(new_coords)
	
	return affected

func explode():
	var affected: Array[Vector2i] = get_affected()
	quackerBombStackRender.call()
	explosionCallback.call(self, affected)
	self.queue_free()

func hit():
	explode()

func tick():
	fuse -= 1;
	if fuse <= 0:
		return explode()

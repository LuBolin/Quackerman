class_name AFK_Bomb
extends Node2D

static var ABScene = load("res://Objects/Powerups/AFK_Bomb/AFK_Bomb.tscn")

const bombStrength = 2
const directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
var coords;
var parentABArray: Array[AFK_Bomb]
var explosionCallback
static func makeAFKBomb(coords, parentABArray, explosionCallback):
	var ab = ABScene.instantiate()
	ab.coords = coords
	ab.parentABArray = parentABArray;
	ab.explosionCallback = explosionCallback
	return ab

func pickedup():
	parentABArray.erase(self)
	self.queue_free()

func hit():
	self.explode()

func get_affected():
	var affected: Array[Vector2i] = []
	for dir in directions:
		for step in range(bombStrength + 1):
			var new_coords = coords + dir * step
			affected.append(new_coords)
	return affected

func explode():
	var affected: Array[Vector2i] = get_affected()
	explosionCallback.call(self, affected)
	self.queue_free()

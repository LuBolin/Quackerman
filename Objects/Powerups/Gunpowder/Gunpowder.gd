class_name Gunpowder
extends Node2D

static var GunpowderScene = load("res://Objects/Powerups/Gunpowder/Gunpowder.tscn")

const gpStrength = 2
const directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
var coords;
var parentGpArray: Array[Gunpowder]
var explosionCallback
static func makeGunpowder(coords, parentGpArray, explosionCallback):
	var gp = GunpowderScene.instantiate()
	gp.coords = coords
	gp.parentGpArray = parentGpArray
	gp.explosionCallback = explosionCallback
	return gp

func pickedup():
	parentGpArray.erase(self)
	self.queue_free()

func hit():
	self.explode()

func get_affected():
	var affected: Array[Vector2i] = []
	for dir in directions:
		for step in range(gpStrength + 1):
			var new_coords = coords + dir * step
			affected.append(new_coords)
	return affected

func explode():
	var affected: Array[Vector2i] = get_affected()
	explosionCallback.call(self, affected)
	self.queue_free()

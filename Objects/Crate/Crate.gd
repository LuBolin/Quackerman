class_name Crate
extends Node2D

static var CrateScene = load("res://Objects/Crate/Crate.tscn")

var health: int = 1;

var onDestroyCallback

static func makeCrate(onDestroyCallback):
	var crate = CrateScene.instantiate()
	crate.onDestroyCallback = onDestroyCallback
	return crate

func _ready():
	pass # Replace with function body.

func tick():
	pass

func hit():
	health -= 1;
	if health <= 0:
		destroy()

func destroy():
	self.queue_free();
	onDestroyCallback.call(self)

class_name Explosion
extends Node2D

static var ExplosionScene = load("res://Objects/Explosion/Explosion.tscn")
@onready var animatedSprite: AnimatedSprite2D:
	set(value):
		animatedSprite = value
		animatedSprite.animation_finished.connect(self.done)
@onready var audioPlayer: AudioStreamPlayer2D = $audioPlayer

static func makeExplosion():
	var explosion: Explosion = ExplosionScene.instantiate()
	return explosion

func _ready():
	animatedSprite = $animatedSprite
	var rdm_rotation = randf_range(0, 360)
	animatedSprite.set_rotation(rdm_rotation)
	audioPlayer.play()

func done():
	self.queue_free()

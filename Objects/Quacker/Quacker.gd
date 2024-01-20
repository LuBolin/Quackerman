class_name Quacker
extends Node2D

static var QuackerScene = load("res://Objects/Quacker/Quacker.tscn")

@onready var sprite: Sprite2D = $Sprite
@onready var animPlayer: AnimationPlayer = $AnimPlayer
@onready var quacker: AudioStreamPlayer2D = $quacker
@onready var stepper: AudioStreamPlayer2D = $stepper
@onready var screecher: AudioStreamPlayer2D = $screecher
@onready var yayer: AudioStreamPlayer2D = $yayer

var hud: HUD
var movementTween

var bomb_fuse: int

var bombs: int: 
	set(value):
		bombs = value
		if hud:
			hud.setBombs(bombs)

var bomb_strength: int:
	set(value):
		bomb_strength = value
		if is_instance_valid(hud):
			hud.setBombStrength(value)

var alive = true;
var won = false;
var quackerActionCallback;
var tween_duration;

static func summonQuacker(bomb_strength, bomb_count, bomb_fuse,
	quackerActionCallback, tween_duration, ):
	var quacker = QuackerScene.instantiate()
	quacker.bomb_strength = bomb_strength
	quacker.bombs = bomb_count
	quacker.bomb_fuse = bomb_fuse
	quacker.quackerActionCallback = quackerActionCallback
	quacker.tween_duration = tween_duration
	return quacker

func _ready():
	Singleton.tick.connect(self.tick)
	Singleton.win.connect(self.win)
	Singleton.lose.connect(self.die)
	quacker.play()
	hud.setBombs(bombs)
	hud.setBombStrength(bomb_strength)
	
func move(target: Vector2):
	tweenToTarget(target, tween_duration)
	stepper.play()
	return true

func plant():
	if bombs > 0:
		bombs -= 1
		get_tree().create_timer(0.1).timeout.connect(
			func x(): Singleton.tick2.emit())
		return true
	return false

func tick():
	pass

func hit():
	die()
	pass


func win():
	self.won = true
	yayer.play()
	animPlayer.play('win')
	animPlayer.animation_finished.connect(
		func x(): Singleton.to_menu.emit()) # handled in level.gn
	
func die():
	if not self.alive:
		return
	self.alive = false
	Singleton.lose.emit()
	sprite.modulate = Color.DARK_RED
	screecher.play()
	pass

func tweenToTarget(target_position: Vector2, duration: float):
	movementTween = get_tree().create_tween()
	movementTween.tween_property(
		self,
		"global_position",
		target_position,
		duration
	)
	movementTween.set_trans(Tween.TRANS_LINEAR)
	movementTween.set_ease(Tween.EASE_OUT)
	movementTween.finished.connect(quackerActionCallback)
	movementTween.finished.connect(func x(): Singleton.check_win.emit())
	movementTween.finished.connect(func x(): Singleton.tick2.emit())

func setTranslucent(translucent):
	if not sprite:
		return
	if translucent:
		sprite.modulate.a = 0.75
	else:
		sprite.modulate.a = 1

func quack(): # for others to call
	quacker.play()

#func _exit_tree():
	#sprite.queue_free()
	#animPlayer.queue_free()
	#self.queue_free()

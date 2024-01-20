class_name HUD
extends CanvasLayer

@onready var turnDelayOverlay = $TurnOverlay
@onready var bombsLabel = $Stats/Bombs/Label
@onready var bombStrengthLabel = $Stats/BombStrength/Label
@onready var clockLabel = $Stats/Clock/Label
@onready var levelLabel = $LevelLabel

func _ready():
	self.visible = true # this was set to false in editor for easier tilemap editing
	Singleton.win.connect(self.win)
	Singleton.lose.connect(self.lose)
	for child in get_tree().get_root().get_children():
		if "Level" in child.name:
			levelLabel.text = child.name
			continue

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
	if turnDelayOverlay.visible: # won or lost
		return
	if event.get_keycode() == KEY_ESCAPE:
		self._on_to_main_menu_pressed()

func setDelayOverlay(visible):
	turnDelayOverlay.visible = visible

func setBombs(bombs):
	bombsLabel.text = str(bombs)

func setBombStrength(strength):
	bombStrengthLabel.text = str(strength)

func setClock(turns):
	clockLabel.text = str(turns)

func win():
	turnDelayOverlay.color = Color(Color.GREEN_YELLOW, 0.3)
	turnDelayOverlay.visible = true
	
	get_tree().create_timer(1.5).timeout.connect(self._on_to_main_menu_pressed)

func lose():
	turnDelayOverlay.color = Color(Color.RED, 0.5)
	turnDelayOverlay.visible = true
	
	get_tree().create_timer(0.8).timeout.connect(func x(): Singleton.restart.emit())
	

const mainSceneFile = "res://Scenes/MainScreen.tscn"
func _on_to_main_menu_pressed():
	Singleton.to_menu.emit()
	get_tree().change_scene_to_file(mainSceneFile)

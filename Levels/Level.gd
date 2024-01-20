extends Node2D
var EscapeScene = load("res://Objects/Escape/Escape.tscn")

@onready var hud: HUD = $HUD
@onready var inputDelayTimer = $InputDelayTimer # wait time of 1s
@onready var terrain = $Terrain

var bomb_fuse: int = 4; # dont edit this
@export var turn_limit: int = 20;
@export var bomb_count: int = 10;
@export var bomb_strength: int = 1;

var walls: Array[Vector2i]
var quacker: Quacker
var bombs: Array[Bomb]
var crates: Array[Crate]
var escapes: Array[Escape]
var gunpowders: Array[Gunpowder]
var afk_bombs: Array[AFK_Bomb]

var level_size: Vector2
var tile_size: Vector2 = Vector2(64, 64);
var inputDelayPeriod;


func _ready():
	level_size = terrain.get_used_rect().size
	inputDelayPeriod = inputDelayTimer.wait_time
	for tile_coords in terrain.get_used_cells(0):
		var cell_index = terrain.get_cell_source_id(0, tile_coords)
		if cell_index > 0: # -1 is empty, 0 is wall
			terrain.set_cell(0, tile_coords, -1)  # Set to -1 to remove the tile
			var tile_world_position = tile_to_world(tile_coords)
			if cell_index == 1: # quacker
				quacker = Quacker.summonQuacker(
					bomb_strength, bomb_count, bomb_fuse,
					quackerActionCallback, inputDelayPeriod)
				quacker.global_position = tile_world_position
				get_parent().add_child.call_deferred(quacker)
			elif cell_index == 2: # crate
				var crate = Crate.makeCrate(crateDestroyCallback)
				crate.global_position = tile_world_position
				get_parent().add_child.call_deferred(crate)
				crates.append(crate)
			elif cell_index == 3: # escape
				var escape = EscapeScene.instantiate()
				escape.global_position = tile_world_position
				get_parent().add_child.call_deferred(escape)
				escapes.append(escape)
			elif cell_index == 4: # gunpowder
				var gunpowder = Gunpowder.makeGunpowder(tile_coords, gunpowders, explosionCallback)
				gunpowder.global_position = tile_world_position
				get_parent().add_child.call_deferred(gunpowder)
				gunpowders.append(gunpowder)
			elif cell_index == 5: # afk_bomb
				var afk_bomb = AFK_Bomb.makeAFKBomb(tile_coords, afk_bombs, explosionCallback)
				afk_bomb.global_position = tile_world_position
				get_parent().add_child.call_deferred(afk_bomb)
				afk_bombs.append(afk_bomb)
				
	walls = terrain.get_used_cells(0)
	assert(escapes.size() != 0, "No escape tiles!")
	
	quacker.hud = hud
	hud.setClock(turn_limit)
	
	Singleton.tick.connect(inputDelayTimer.start)
	Singleton.tick2.connect(self.tick)

	Singleton.check_win.connect(self.check_win)
	
	Singleton.restart.connect(self.restart_level)
	
	Singleton.to_menu.connect(self.clear_all)
	
	Singleton.win.connect(self.write_beaten)

func quackerMove(direction: Vector2i):
	var anyMoved = false;
	var tile_coords = world_to_tile(quacker.position)
	var target = tile_coords + direction
	if target in walls:
		return
	elif target in get_crate_tiles():
		return
	else:
		var target_in_world = tile_to_world(target)
		var moved = quacker.move(target_in_world)
		if moved:
			anyMoved = true;
	if anyMoved:
		inputDelayTimer.start()
		return true
	return false

func tick():
	turn_limit -= 1
	hud.setClock(turn_limit)
	if turn_limit <= 0:
		if not quacker.won:
			Singleton.lose.emit()

func _input(event):
	if not(event is InputEventKey and event.pressed):
		return
	if not quacker.alive:
		return
	if quacker.won:
		return
	
	if inputDelayTimer.is_stopped():
		var acted = true # assume action unless otherwise
		if event.is_action("up"):
			acted = quackerMove(Vector2.UP)
		elif event.is_action("down"):
			acted = quackerMove(Vector2.DOWN)
		elif event.is_action("left"):
			acted = quackerMove(Vector2.LEFT)
		elif event.is_action("right"):
			acted = quackerMove(Vector2.RIGHT)
		elif event.is_action("plant"):
			var coords = world_to_tile(quacker.global_position)
			for bomb in bombs:
				if world_to_tile(bomb.position) == coords:
					return false
			
			var success = quacker.plant()
			if success:
				var bomb = Bomb.makeBomb(coords, 
					quackerActionCallback, explosionCallback,
					quacker.bomb_strength, quacker.bomb_fuse)
				bomb.position = quacker.position
				get_parent().add_child.call_deferred(bomb)
				bombs.append(bomb)
				quackerActionCallback() # technically not a callback here but whatever
				inputDelayTimer.start()
			else:
				acted = false
		else:
			acted = false
		
		if acted:
			Singleton.tick.emit()
		
	if event.is_action("restart"): # not affected by input delay
		Singleton.restart.emit()

func check_win():
	var quacker_tile = world_to_tile(quacker.position)
	for escape in escapes:
		var escape_tile = world_to_tile(escape.position)
		if escape_tile == quacker_tile:
			Singleton.win.emit()

func write_beaten():
	var thisLevelNumber
	for child in get_tree().get_root().get_children():
		if "Level" in child.name:
			thisLevelNumber = child.name.lstrip("Level")
			thisLevelNumber = int(thisLevelNumber)
	if thisLevelNumber not in Singleton.levelsBeaten:
		Singleton.levelsBeaten.append(thisLevelNumber)
		Singleton.save_data()

### Callbacks
func explosionCallback(exploder, hits: Array[Vector2i]):
	if exploder in bombs:
		bombs.erase(exploder)
	elif exploder in gunpowders:
		gunpowders.erase(exploder)
	elif exploder in afk_bombs:
		afk_bombs.erase(exploder)

	for hit in hits:
		var explosion = Explosion.makeExplosion()
		get_parent().add_child.call_deferred(explosion)
		explosion.position = tile_to_world(hit)
		for crate in crates:
			var crate_tile = world_to_tile(crate.position)
			if crate_tile == hit:
				crate.hit()
		for bomb in bombs:
			var bomb_tile = world_to_tile(bomb.position)
			if bomb_tile == hit:
				bomb.hit()
		for gunpowder in gunpowders:
			var gp_tile = world_to_tile(gunpowder.position)
			if gp_tile == hit:
				gunpowder.hit()
		for afk_bomb in afk_bombs:
			var ab_tile = world_to_tile(afk_bomb.position)
			if ab_tile == hit:
				afk_bomb.hit()		
		var quacker_tile = world_to_tile(quacker.position)
		if quacker_tile == hit:
			quacker.hit()
		

func crateDestroyCallback(crate_itself: Crate):
	crates.erase(crate_itself)

func quackerActionCallback():
	if not quacker:
		return
	var quackerCoords = world_to_tile(quacker.position)
	for bomb in bombs:
		var bombCoords = world_to_tile(bomb.position)
		if quackerCoords == bombCoords:
			quacker.setTranslucent(true)
			return
	quacker.setTranslucent(false)
	for gunpowder in gunpowders:
		var gpCoords = world_to_tile(gunpowder.position)
		if quackerCoords == gpCoords:
			quacker.bomb_strength += 1
			quacker.quack()
			gunpowder.pickedup()
	for afk_bomb in afk_bombs:
		var abCoords = world_to_tile(afk_bomb.position)
		if quackerCoords == abCoords:
			quacker.bombs += 1
			quacker.quack()
			afk_bomb.pickedup()

	
### Utility
func get_crate_tiles():
	var crate_tiles: Array[Vector2i] = []
	for crate in crates:
		crate_tiles.append(world_to_tile(crate.position))
	return crate_tiles

func clear_all():
	quacker.queue_free()
	for bomb in bombs:
		bomb.queue_free()
	for crate in crates:
		crate.queue_free()
	for escape in escapes:
		escape.queue_free()
	for gp in gunpowders:
		gp.queue_free()
	for ab in afk_bombs:
		ab.queue_free()

func restart_level():
	var t = get_tree()
	clear_all()
	if t:
		t.reload_current_scene()
	else:
		pass

func world_to_tile(world_pos: Vector2):
	var local = terrain.to_local(world_pos)
	var tile = terrain.local_to_map(local)
	return tile

func tile_to_world(tile_coords: Vector2):
	var local = terrain.map_to_local(tile_coords)
	var global = terrain.to_global(local)
	return global

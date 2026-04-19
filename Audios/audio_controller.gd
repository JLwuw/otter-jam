extends Node2D

# Music players
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var selection_music: AudioStreamPlayer = $SelectionMusic
@onready var music: AudioStreamPlayer = $Music

# SFX players
@onready var shoot: AudioStreamPlayer = $Shoot
@onready var shoot2: AudioStreamPlayer = $Shoot2
@onready var shoot3: AudioStreamPlayer = $Shoot3
@onready var shoot4: AudioStreamPlayer = $Shoot4
@onready var enemy_hit: AudioStreamPlayer = $EnemyHit
@onready var enemy_hit2: AudioStreamPlayer = $EnemyHit2
@onready var enemy_death: AudioStreamPlayer = $EnemyDeath
@onready var enemy_death2: AudioStreamPlayer = $EnemyDeath2
@onready var enemy_death3: AudioStreamPlayer = $EnemyDeath3
@onready var enemy_death4: AudioStreamPlayer = $EnemyDeath4
@onready var player_movement: AudioStreamPlayer = $PlayerMovement
@onready var health_loss: AudioStreamPlayer = $HealthLoss
@onready var health_loss2: AudioStreamPlayer = $HealthLoss2
@onready var health_loss3: AudioStreamPlayer = $HealthLoss3
@onready var border_hit: AudioStreamPlayer = $BorderHit


# Music functions
func play_menu_music() -> void:
	menu_music.play()

func play_selection_music() -> void:
	menu_music.stop()
	selection_music.play()

func play_music() -> void:
	menu_music.stop()
	selection_music.stop()
	music.play()

func stop_music() -> void:
	music.stop()
	menu_music.stop()
	selection_music.stop()
	menu_music.stop()

func stop_all_sfx() -> void:
	shoot.stop()
	shoot2.stop()
	shoot3.stop()
	shoot4.stop()
	enemy_hit.stop()
	enemy_hit2.stop()
	enemy_death.stop()
	enemy_death2.stop()
	enemy_death3.stop()
	enemy_death4.stop()
	player_movement.stop()
	health_loss.stop()
	health_loss2.stop()
	health_loss3.stop()
	border_hit.stop()

func stop_all() -> void:
	stop_music()
	stop_all_sfx()

func fade_out_music(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(menu_music, "volume_db", -80.0, duration)
	tween.parallel().tween_property(music, "volume_db", -80.0, duration)
	await tween.finished
	stop_music()
	menu_music.volume_db = 0.0
	music.volume_db = 0.0


# Sound effect functions
func play_shoot() -> void:
	var variant = randi() % 4
	match variant:
		0:
			shoot.play()
		1:
			shoot2.play()
		2:
			shoot3.play()
		3:
			shoot4.play()

func play_enemy_hit() -> void:
	if randi() % 2 == 0:
		enemy_hit.play()
	else:
		enemy_hit2.play()

func play_enemy_death() -> void:
	var variant = randi() % 4
	match variant:
		0:
			enemy_death.play()
		1:
			enemy_death2.play()
		2:
			enemy_death3.play()
		3:
			enemy_death4.play()

func play_player_movement() -> void:
	player_movement.play()

func play_health_loss() -> void:
	var variant = randi() % 3
	match variant:
		0:
			health_loss.play()
		1:
			health_loss2.play()
		2:
			health_loss3.play()

func play_border_hit() -> void:
	border_hit.stop()
	border_hit.bus = "Master"
	border_hit.play()



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Make sure this node persists across scene changes
	if get_parent() == get_tree().root:
		# It's an autoload, prevent it from being freed
		pass
	play_menu_music()



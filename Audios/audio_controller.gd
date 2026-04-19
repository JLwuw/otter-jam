extends Node2D

# Music players
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var music: AudioStreamPlayer = $Music

# SFX players
@onready var shoot: AudioStreamPlayer = $Shoot
@onready var shoot2: AudioStreamPlayer = $Shoot2
@onready var enemy_hit: AudioStreamPlayer = $EnemyHit
@onready var enemy_hit2: AudioStreamPlayer = $EnemyHit2
@onready var enemy_death: AudioStreamPlayer = $EnemyDeath
@onready var enemy_death2: AudioStreamPlayer = $EnemyDeath2
@onready var player_movement: AudioStreamPlayer = $PlayerMovement
@onready var health_loss: AudioStreamPlayer = $HealthLoss
@onready var health_loss2: AudioStreamPlayer = $HealthLoss2
@onready var border_hit: AudioStreamPlayer = $BorderHit


# Music functions
func play_menu_music() -> void:
	menu_music.play()

func play_music() -> void:
	menu_music.stop()
	music.play()

func stop_music() -> void:
	music.stop()
	menu_music.stop()


# Sound effect functions
func play_shoot(variant: int = 1) -> void:
	if variant == 2:
		shoot2.play()
	else:
		shoot.play()

func play_enemy_hit(variant: int = 1) -> void:
	if variant == 2:
		enemy_hit2.play()
	else:
		enemy_hit.play()

func play_enemy_death(variant: int = 1) -> void:
	if variant == 2:
		enemy_death2.play()
	else:
		enemy_death.play()

func play_player_movement() -> void:
	player_movement.play()

func play_health_loss(variant: int = 1) -> void:
	if variant == 2:
		health_loss2.play()
	else:
		health_loss.play()

func play_border_hit() -> void:
	border_hit.play()



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	play_menu_music()



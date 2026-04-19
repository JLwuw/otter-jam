class_name UpgradeManager
extends Node

@export var available_upgrades: Array = []

signal upgrade_offered(upgrades: Array[Upgrade], count: int)
signal upgrade_selected(upgrade: Upgrade)

func _ready() -> void:
	if available_upgrades.is_empty():
		print("WARNING: No upgrades configured in UpgradeManager")

func offer_random_upgrades(count: int = 3) -> Array[Upgrade]:
	if available_upgrades.is_empty():
		print("ERROR: No upgrades available")
		return []
	
	var selected: Array[Upgrade] = []
	var pool: Array = available_upgrades.duplicate()
	
	for i in range(count):
		if pool.is_empty():
			break
		
		var choice_idx: int = _weighted_random_select(pool)
		var upgrade: Upgrade = pool[choice_idx] as Upgrade
		if upgrade == null:
			print("WARNING: Invalid upgrade resource in available_upgrades at index ", choice_idx)
			pool.remove_at(choice_idx)
			continue

		selected.append(upgrade)
		pool.remove_at(choice_idx)
	
	upgrade_offered.emit(selected, count)
	return selected

func _weighted_random_select(upgrades: Array) -> int:
	var total_weight: float = 0.0
	for upgrade: Variant in upgrades:
		var typed_upgrade: Upgrade = upgrade as Upgrade
		if typed_upgrade == null:
			continue

		var rarity: float = Upgrade.rarity_by_type.get(typed_upgrade.upgrade_type, 1.0)
		total_weight += (1.0 / rarity)

	if total_weight <= 0.0:
		return 0
	
	var roll: float = randf() * total_weight
	var accumulated: float = 0.0
	
	for i in range(upgrades.size()):
		var typed_upgrade: Upgrade = upgrades[i] as Upgrade
		if typed_upgrade == null:
			continue

		var rarity: float = Upgrade.rarity_by_type.get(typed_upgrade.upgrade_type, 1.0)
		accumulated += (1.0 / rarity)
		if roll <= accumulated:
			return i
	
	return upgrades.size() - 1

func select_upgrade(upgrade: Upgrade, player: Player) -> void:
	apply_upgrade(upgrade, player)
	upgrade_selected.emit(upgrade)

func apply_upgrade(upgrade: Upgrade, player: Player) -> void:
	match upgrade.upgrade_type:
		Upgrade.Type.MAX_HP:
			player.upgrade_max_hp(upgrade.amount)
		
		Upgrade.Type.BULLET_SPEED:
			player.upgrade_bullet_speed(upgrade.amount)
		
		Upgrade.Type.DAMAGE:
			player.upgrade_damage(upgrade.amount)
		
		Upgrade.Type.BULLET_COUNT:
			player.upgrade_bullet_count(upgrade.amount)
		
		Upgrade.Type.MAX_SPEED:
			player.upgrade_max_speed(upgrade.amount)
		_:
			print("WARNING: upgrade type: ", upgrade.upgrade_type, " not found in apply upgrade")	


func get_upgrade_per_level(level: int) -> Array[Upgrade]:
	match level:
		1:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 30)
			]
		
		2:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 30)
			]
		
		3:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
				Upgrade.new(Upgrade.Type.DAMAGE, 1)
			]
		
		4:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
			]
		
		5:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
			]
		
		6:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
				Upgrade.new(Upgrade.Type.BULLET_SPEED, 100),
				Upgrade.new(Upgrade.Type.BULLET_COUNT, 5)
			]

		7:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
			]
			
		8:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
			]
			
		9:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
			]
			
		10:
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40),
				Upgrade.new(Upgrade.Type.BULLET_SPEED, 100),
				Upgrade.new(Upgrade.Type.BULLET_COUNT, 5),
				Upgrade.new(Upgrade.Type.DAMAGE, 1)
			]
			
		_:
			print("WARNING: Level not defined in get_upgrade_per_level")
			return [
				Upgrade.new(Upgrade.Type.MAX_HP, 1),
				Upgrade.new(Upgrade.Type.MAX_SPEED, 40)
			]

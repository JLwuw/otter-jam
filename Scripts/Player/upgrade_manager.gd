class_name UpgradeManager
extends Node

@export var available_upgrades: Array[Upgrade] = []

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
	var pool: Array[Upgrade] = available_upgrades.duplicate()
	
	for i in range(count):
		if pool.is_empty():
			break
		
		var choice_idx: int = _weighted_random_select(pool)
		var upgrade: Upgrade = pool[choice_idx]
		selected.append(upgrade)
		pool.remove_at(choice_idx)
	
	upgrade_offered.emit(selected, count)
	return selected

func _weighted_random_select(upgrades: Array[Upgrade]) -> int:
	var total_weight: float = 0.0
	for upgrade in upgrades:
		var rarity: float = Upgrade.rarity_by_type.get(upgrade.upgrade_type, 1.0)
		total_weight += (1.0 / rarity)
	
	var roll: float = randf() * total_weight
	var accumulated: float = 0.0
	
	for i in range(upgrades.size()):
		var rarity: float = Upgrade.rarity_by_type.get(upgrades[i].upgrade_type, 1.0)
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
		
			player.max_fire_rate += upgrade.amount * 0.5
		
		Upgrade.Type.BULLET_SPEED:
			player.bullet_speed += upgrade.amount * 50
		
		Upgrade.Type.DAMAGE:
			# Placeholder: when damage stat is added to player
			pass
		
		Upgrade.Type.PIERCING:
			# Placeholder: when piercing is added to bullets
			pass
		
		Upgrade.Type.MULTISHOT:
			# Placeholder: when multishot is added to player
			pass

func get_upgrade_display_name(upgrade: Upgrade) -> String:
	var info = Upgrade.upgrade_info.get(upgrade.upgrade_type, {})
	return info.get("name", "Unknown")

func get_upgrade_description(upgrade: Upgrade) -> String:
	var info = Upgrade.upgrade_info.get(upgrade.upgrade_type, {})
	return info.get("description", "No description")

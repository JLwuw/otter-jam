class_name Upgrade
extends Resource

enum Type {
	MAX_HP,
	DAMAGE,
	PIERCING,
	MULTISHOT,
	BULLET_SPEED
}

static var rarity_by_type: Dictionary[Type, float] = {
	Upgrade.Type.MAX_HP: 1.0,
	Upgrade.Type.BULLET_SPEED: 0.6,
	Upgrade.Type.DAMAGE: 0.4,
	Upgrade.Type.MULTISHOT: 0.3,
	Upgrade.Type.PIERCING: 0.2
}

static var upgrade_info: Dictionary = {
	Upgrade.Type.MAX_HP: {"name": "Max HP", "description": "Increase maximum health"},	Upgrade.Type.BULLET_SPEED: {"name": "Bullet Speed", "description": "Increase bullet speed"},
	Upgrade.Type.DAMAGE: {"name": "Damage", "description": "Increase bullet damage"},
	Upgrade.Type.MULTISHOT: {"name": "Multishot", "description": "Fire multiple bullets"},
	Upgrade.Type.PIERCING: {"name": "Piercing", "description": "Bullets pierce through enemies"}
}

@export var upgrade_type: Type = Type.MAX_HP
@export var amount: int = 1

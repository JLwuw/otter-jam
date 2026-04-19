class_name Upgrade
extends Resource

enum Type {
	MAX_HP,
	DAMAGE,
	BULLET_SPEED,
	BULLET_COUNT
}

static var rarity_by_type: Dictionary[Type, float] = {
	Type.MAX_HP: 1.0,
	Type.BULLET_SPEED: 0.6,
	Type.DAMAGE: 0.4,
	Type.BULLET_COUNT: 0.5
}

static var upgrade_info: Dictionary = {
	Type.MAX_HP: {"name": "Max HP", "description": "Increase maximum health"},	
	Type.BULLET_SPEED: {"name": "Bullet Speed", "description": "Increase bullet speed"},
	Type.DAMAGE: {"name": "Damage", "description": "Increase bullet damage"},
	Type.BULLET_COUNT: {"name": "More bullets", "description": "Increase number of bullets fired"}
}

@export var upgrade_type: Type = Type.MAX_HP
@export var amount: int = 1

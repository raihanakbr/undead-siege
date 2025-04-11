class_name Money
extends Node

# Signal emitted when money amount changes
signal money_changed(new_amount)

# Current money amount
@export var amount: int = 0

# Add money to this entity
func add(value: int) -> void:
	if value <= 0:
		return
	
	amount += value
	emit_signal("money_changed", amount)

# Remove money from this entity
func subtract(value: int) -> bool:
	if value <= 0:
		return false
	
	if amount < value:
		return false
	
	amount -= value
	emit_signal("money_changed", amount)
	return true

# Get current money amount
func get_amount() -> int:
	return amount

# Transfer money from another money node to this one
# Typically called when player kills a zombie
func transfer_from(source: Node) -> void:
	if not source.has_method("get_amount") or not source.has_method("subtract"):
		push_error("Invalid source for money transfer")
		return
	
	var source_amount = source.get_amount()
	if source.subtract(source_amount):
		add(source_amount)

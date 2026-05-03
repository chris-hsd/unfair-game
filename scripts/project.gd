extends Resource
class_name Project

enum Amount { NIEDRIG, MITTEL, HOCH }

@export var titel: String = ""
@export var ressourcenbedarf: Amount = Amount.NIEDRIG
@export var aussenwirkung: Amount = Amount.HOCH
@export var transformation: Amount = Amount.MITTEL

func describe() -> String:
	return "%s: Ressourcenbedarf=%s, Aussenwirkung=%s, Transformation=%s" % [
		titel,
		Amount.keys()[ressourcenbedarf],
		Amount.keys()[aussenwirkung],
		Amount.keys()[transformation],
	]

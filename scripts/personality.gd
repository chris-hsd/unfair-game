extends Resource
class_name Personality

const FOCUS := ["Leistung", "Kreativität", "Sichtbarkeit", "Förderung"]
const INTERPRETATION := ["Defizite", "Potential", "Struktur"]

@export var modifiers: Dictionary = {
	"Aktionsmodus": 5,
	"Aufmerksamkeitsfokus": "Sichtbarkeit",
	"Regelbindung": 0.5,
	"Interpretation": "Defizite",
}

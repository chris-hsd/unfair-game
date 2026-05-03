extends Resource
class_name Personality

enum Focus { LEISTUNG, KREATIVITAET, SICHTBARKEIT, FOERDERUNG }
enum Interpretation { DEFIZITE, POTENTIAL, STRUKTUR }

@export var player: String = ""
@export_range(0, 10) var aktionsmodus: int = 5
@export var aufmerksamkeit: Focus = Focus.SICHTBARKEIT
@export_range(0.0, 1.0, 0.01) var regelbindung: float = 0.5
@export var interpretation: Interpretation = Interpretation.DEFIZITE

func describe() -> String:
	return "Player=%s, Aktionsmodus=%d, Aufmerksamkeit=%s, Regelbindung=%.2f, Interpretation=%s" % [
		player,
		aktionsmodus,
		Focus.keys()[aufmerksamkeit],
		regelbindung,
		Interpretation.keys()[interpretation],
	]

# Compact instructions

When compacting, preserve:
- current task goal
- files changed
- commands already run
- failing tests and exact errors
- decisions made
- plans made
- next action list
- open questions / blockers – offene Entscheidungen, die noch ausstehen (z.B. "unklar ob X oder Y")
- environment state – laufende Server, aktiver Git-Branch, relevante Env-Variablen

# Project essentials

- Engine: Godot 4.6+
- Language: GDScript (primary)
- GitHub account: chris-hsd
- Run/test: open in Godot editor or `godot --headless --quit` for CI checks
- Main scene: res://scenes/intro.tscn
- Source code: res://scripts/
- Assets: res://assets/
- Do not edit files in res://addons/ (managed via Asset Library or git submodules)
- Scene naming: snake_case.tscn, scripts attached to same-named .gd file
- Export configs: res://export_presets.cfg (do not commit API keys)

# Project context (UNFAIR)

Authoritative source: `README.md`. Summary for quick reference:

**Premise.** Decision-driven Serious Game für Studierende der Sozialen Arbeit (Hochschulkontext). Spielerin leitet eine Schüler:innen-AG zum Thema Nachhaltigkeit. Fokus: Avatar-Erfahrung & Reflexion, nicht Entscheidungsauswertung.

**Core design (9 Punkte):**

1. **Entscheidungen als Bedeutungskombinationen.** Antwortoptionen tragen `option_tags` mit Gewichten. Wirkung über `data/tag_stat_matrix.csv` (Tag → Stat-Delta). Engine summiert Tag-Beiträge, statt fixe Konsequenz pro Option.
2. **Intersektionale Lesart.** `data/avatar_overrides.csv` verändert Tag-Stat-Wirkungen pro Avatar (verstärken, abschwächen, umkehren). Formel: `matrix_delta * option_weight * avatar_override * magnitude_factor = final_delta`.
3. **4 Beziehungsebenen (20 Stats):** `projekt`, `schule`, `leitung`, `ag_mitglieder`. Kein übergreifender Fortschritt — Entscheidung kann in einem Bereich sinnvoll, in einem anderen teuer sein.
4. **Habitus-Trägheit.** Leitungs-Stats haben `magnitude_factor = 0.3`, andere `1.0` (in `data/stats_schema.csv`). Stil entsteht über Wiederholung, nicht Einzelentscheidung. Formel: `neue_baseline = alte_baseline + α × (tag_ziel − alte_baseline)`.
5. **Varianten verändern Sprache, nicht Mechanik.** `story_hook_variants` / `option_text_variants` ändern Text abhängig von Stats/Avatar; `option_tags` bleiben identisch.
6. **Datengetriebene Szenen.** Stories als JSON in `stories/`. Schema: `data/schemas/scene_schema.json`, Erklärung: `docs/scene_schema_erklaerung.md`. Authoring getrennt von Engine.
7. **Startwerte vs. Lesart getrennt.** `data/avatar_baselines.csv` = Ausgangswerte. `data/avatar_overrides.csv` = Lesart einzelner Handlungen. → "Erklärungslast" über Sprache, ohne separate Szenen.
8. **Outro-Profile.** `stories/gameplay_experiences.json` mit 4 Pfaden: Anpassung, Beziehung, Wirkung, Haltung. Stabile IDs (`anpassung`, `beziehung`, `wirkung`, `selbstbehauptung`); Anzeigenamen ohne Datenbindungs-Bruch änderbar. Berechnungslogik noch offen.
9. **Nicht-Ziele.** Keine garantierten Lernziele, keine repräsentativen Avatar-Modelle, Outro-Prozente ≠ Evaluation der Spielenden.

**Key data files** (Single Source of Truth — bei Änderungen am Modell zuerst hier prüfen):
- `data/tag_stat_matrix.csv` — Tag → Stat-Wirkung
- `data/avatar_overrides.csv` — Avatar-spezifische Multiplikatoren
- `data/avatar_baselines.csv` — Startwerte pro Avatar
- `data/stats_schema.csv` — Stat-Definitionen inkl. `magnitude_factor`
- `data/schemas/scene_schema.json` — Szenen-Schema
- `stories/*.json` — Szenen-Daten
- `stories/gameplay_experiences.json` — Outro-Profile

# Szenen-Schema — Erklärung

Diese Datei beschreibt, wie eine Szenen-JSON aufgebaut ist. Die formale Spezifikation steht in `scene_schema.json` und kann zur automatischen Validierung und zum IDE-Autocomplete verwendet werden. Diese Datei ist die menschenlesbare Begleitung.

## Drei Ebenen, drei Präfixe

Jedes Feld trägt das Präfix der Ebene, zu der es gehört:

- `scene_*` — gilt für die ganze Szene
- `story_hook_*` — gilt für den Eröffnungstext
- `option_*` — gilt für eine einzelne Auswahlmöglichkeit

Was kein Präfix trägt (`scene_id`, `story_hook`, `options`), ist die Wurzel der jeweiligen Ebene.

## Felder im Überblick

### Szenen-Ebene

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `scene_id` | String | ja | Eindeutige ID im Format `NN_snake_name`, z.B. `01_kennenlernen` |
| `scene_title` | String | ja | Kurztitel für Authoring/Debug, nicht im Spiel sichtbar |
| `scene_themes` | Array von Strings | nein | Inhaltliche Tags für didaktische Kuration |
| `scene_context` | String | ja | Authoring-Notiz: Aktionsnummer, erwarteter State |
| `scene_media` | Objekt | nein | Hintergrund, Atmo-Musik, optischer Filter |
| `scene_avatar_variants` | Array | nein | Avatar-spezifische Erweiterungen (Procedural Friction) |

### Story-Hook-Ebene

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `story_hook` | String | ja | Erzählertext in 2. Person, max ~100 Wörter |
| `story_hook_variants` | Array | nein | Stil-abhängige Alternativen zum Standard-Hook |
| `story_hook_media` | Objekt | nein | Sting-Sound, Sprite-Animation während Hook |

### Option-Ebene (innerhalb des `options`-Arrays)

| Feld | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `option_id` | String | ja | Format: `opt_snake_name` |
| `option_text` | String | ja | Was die Spielerin als Auswahl sieht |
| `option_text_variants` | Array | nein | Stil-abhängige Alternativen zum Standard-Text |
| `option_tags` | Objekt | ja | Tag-Gewichte (Intensitäten 0.0–1.0) |
| `option_media` | Objekt | nein | Konsequenz-Sound, Sprite-Animation nach Wahl |

## Die drei Variants-Typen

Das Szenen-Format hat drei Mechanismen, um Texte und Auswahlmöglichkeiten an den aktuellen Spielstand und Avatar anzupassen. Sie unterscheiden sich in dem, was sie verändern, wovon sie abhängen, und was sie pädagogisch bewirken.

| Variants-Typ | Verändert was | Tag-Effekte ändern sich? | Hängt ab von |
|---|---|---|---|
| `story_hook_variants` | Erzähltext der Szene | nein | Stat-Werten, optional Avatar |
| `option_text_variants` | Text einzelner Optionen | nein | Stat-Werten, optional Avatar |
| `scene_avatar_variants` | Anzahl der Optionen | ja | Avatar, optional Stat-Werte |

### `story_hook_variants` — Erzählton passt sich an State an

Der einleitende Erzähltext einer Szene kann sich verändern, wenn bestimmte Stat-Bedingungen erfüllt sind. Die Spielmechanik bleibt identisch — die Tonalität verschiebt sich.

**Beispiel:** Wenn das Schulvertrauen niedrig ist, klingt der Hook vorsichtiger: „Du überlegst nochmal, ob du das wirklich vorschlagen solltest." Bei hohem Vertrauen selbstsicherer: „Du hast das Format mehrfach erprobt, jetzt wieder."

**Pädagogische Funktion:** Zeigt der Spielerin, dass sich die Welt um sie herum entwickelt hat — abhängig von dem, was sie getan hat. Konsequenzen kumulieren, auch wenn die Mechanik das nicht explizit ausspricht.

**Authoring-Aufwand:** 0–3 Varianten pro Szene, nur dort wo ein veränderter Ton narrativ etwas trägt.

### `option_text_variants` — Optionstext passt sich an Stil an

Der Text einer einzelnen Auswahlmöglichkeit verändert sich mit dem Spielstand. **Tag-Gewichte und Stat-Effekte bleiben unverändert** — nur wie die Option formuliert ist, verschiebt sich.

**Beispiel:** Eine direkte Ansprache wird forscher formuliert, wenn die Leitung schon einen strikten Stil entwickelt hat. Oder eine Option bekommt eine Erklärungs-Phrase davor, wenn der Avatar Frau Migration ist — weil sie strukturell mehr begründen muss als der alte Mann.

**Pädagogische Funktion:** Zeigt der Spielerin, dass ihre eigene Stimme mit ihrem Stil mitgewachsen ist. Haltung schreibt sich in Sprache ein — sichtbar, ohne es zu kommentieren.

**Authoring-Aufwand:** Typischerweise 0–2 Varianten pro Option, mehr wenn die Option verschiedene State-Konstellationen erlebt. Sparsam einsetzen — nicht jede Option braucht Varianten.

### `scene_avatar_variants` — eine zusätzliche Option für bestimmte Avatare

Ein bestimmter Avatar bekommt **eine zusätzliche Auswahlmöglichkeit**, die andere Avatare nicht haben. Maximum eine Extra-Option pro Avatar pro Szene.

**Beispiel:** Frau Migration sieht in einer Konfliktszene zusätzlich die Option „Lass mich kurz erklären, warum ich das so vorschlage" — eine Legitimierungs-Option, die der alte Mann strukturell nicht braucht und deshalb nicht angeboten bekommt.

**Pädagogische Funktion:** Macht sichtbar, dass die Welt unterschiedliche Anforderungen an unterschiedliche Personen stellt. Strukturelle Asymmetrie erscheint nicht als Stat-Wert, sondern als unterschiedlicher Handlungsraum — manche Optionen stehen nicht allen offen.

**Authoring-Aufwand:** Spürbar höher als die anderen beiden, weil eine echte zusätzliche Option neue Tag-Profile und neue Effekt-Pfade braucht. Die Begrenzung auf eine Extra-Option pro Avatar schützt davor, dass die Szenen für verschiedene Avatare zu verschiedenen Spielen werden.

---

## Wie Variants funktionieren

Sowohl `story_hook_variants` als auch `option_text_variants` folgen demselben Muster: ein Objekt mit `text` und mindestens einem **Selektor** — entweder `condition` (Stat-Vergleich), `avatar_id` (Avatar-Match), oder beides kombiniert.

```json
// Stat-basierte Variante
{ "condition": { "lt_reg": ">6" }, "text": "..." }

// Avatar-basierte Variante
{ "avatar_id": "frau_migration", "text": "..." }

// Kombiniert: nur fuer Frau Migration UND wenn lt_reg > 6
{ "avatar_id": "frau_migration", "condition": { "lt_reg": ">6" }, "text": "..." }
```

Die Engine prüft die Varianten in Reihenfolge und nimmt die **erste**, deren Selektoren alle zutreffen. Trifft keine, wird der Standard-Text verwendet.

### condition: Stat-Vergleiche

In `condition` stehen Stat-Vergleiche. Mehrere Felder im selben Condition-Objekt werden als UND verknüpft:

```json
"condition": { "lt_reg": ">6", "ag_anerk": "<5" }
```

Erlaubte Operatoren: `>`, `<`, `>=`, `<=`, `==`. Werte sind Zahlen.

### avatar_id: Avatar-Match

`avatar_id` ist ein Identitäts-Match — die Variante greift nur, wenn der aktuell aktive Avatar exakt diese ID hat:

```json
"avatar_id": "frau_migration"
```

Dies ist der Standard-Mechanismus für Procedural-Friction-Effekte: Erklärungs-Phrasen, Legitimierungs-Zusätze, oder strukturell anders gefärbte Formulierungen, die nur für bestimmte Avatare auftauchen. Die Tag-Gewichte und Stat-Effekte bleiben dabei dieselben — nur der angezeigte Text variiert.

## Wie Tag-Gewichte zu lesen sind

`option_tags` ist ein Dictionary aus Tag-Name und Gewicht (0.0–1.0):

```json
"option_tags": {
  "regelstrikt": 0.8,
  "prio_mitglieder": 0.5,
  "framen_struktur": 0.3
}
```

Die Gewichte sind **Intensitäten**, nicht Anteile — sie müssen sich nicht zu 1 summieren. Eine Option kann mehrere Eigenschaften gleichzeitig stark ausgeprägt haben. Faustregel: Hauptintention 0.7–1.0, sekundär 0.3–0.6, beiläufig 0.1–0.3, niemals über 1.0.

## Wofür dieses Schema gut ist

**Validierung:** Tools wie `ajv` (JavaScript) oder Godot-Plugins können prüfen, ob eine Szenen-Datei strukturell korrekt ist. Spart Stunden Debugging-Zeit, wenn du dreißig Szenen hast.

**IDE-Unterstützung:** VS Code und andere Editoren lesen JSON Schema und bieten Autocomplete für Feldnamen, Tooltips mit Beschreibungen, und Fehler-Markierungen bei Tippfehlern. Eintragen in `.vscode/settings.json`:

```json
{
  "json.schemas": [
    {
      "fileMatch": ["scenes/*.json"],
      "url": "./scene_schema.json"
    }
  ]
}
```

**Onboarding:** Wenn jemand zukünftig Szenen schreibt — sei es ein Co-Autor oder dein zukünftiges Ich — ist die Schema-Datei plus diese Doku alles, was sie braucht, um loszulegen.

**Dokumentation, die nicht veraltet:** Wenn du das Schema änderst, bricht die Validierung in alten Szenen — du wirst sofort darauf gestoßen, dass du sie aktualisieren musst. Eine Tabelle in einer separaten Word-Datei wäre stattdessen lautlos veraltet.

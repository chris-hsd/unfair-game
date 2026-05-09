# Unfair — Dokumentation der Datendateien

Das Spiel wird durch vier CSV-Dateien gesteuert. Sie bilden zusammen ein **datengetriebenes Designsystem**: Spiellogik, Startwerte und strukturelle Asymmetrien sind nicht im Code verdrahtet, sondern in Tabellen definiert, die unabhängig vom Code bearbeitet werden können.

---

## 1. `stats_schema.csv` — Was das Spiel misst

Diese Datei ist das Grundgerüst. Sie definiert alle **20 Spielwerte (Stats)**, die das Spiel während einer Partie verfolgt.

Jeder Stat beschreibt einen Aspekt einer der vier Spielecken:

| Ecke | Was sie beschreibt |
|---|---|
| **projekt** | Zustand des Nachhaltigkeitsprojekts selbst |
| **schule** | Institutionelles Umfeld, Normen, Ressourcen |
| **leitung** | Handlungsstil der Spielerin — entsteht aus Entscheidungen |
| **ag_mitglieder** | Dynamik innerhalb der Arbeitsgruppe |

Für jeden Stat ist festgelegt:
- `stat_id` — der interne Name, der in allen anderen Dateien als eindeutiger Schlüssel verwendet wird
- `name_de` — die Bezeichnung, die im Spiel angezeigt wird
- `scale_min` / `scale_max` — alle Stats laufen von 1 bis 10
- `magnitude_factor` — wie stark sich dieser Stat pro Aktion verändert. Projekt-, Schul- und AG-Stats ändern sich mit Faktor 1.0. Leitungs-Stats ändern sich mit Faktor 0.3, weil der Handlungsstil der Spielerin sich langsam über viele Entscheidungen herausbildet, nicht durch eine einzelne Aktion kippt.

Zwei Leitungs-Stats (Aufmerksamkeit und Interpretation) sind besonders: sie bestehen jeweils aus drei Pol-Werten, von denen der höchste das angezeigte Label bestimmt. Die Spielerin sieht nicht drei Zahlen, sondern eine Kategorie — z.B. „Potenzial" oder „Defizit".

---

## 2. `avatar_baselines.csv` — Wo das Spiel beginnt

Diese Datei legt die **Startwerte** für alle 20 Stats fest — einmal pro spielbarem Avatar.

Jede Zeile ist ein Avatar-Profil. Die Spalten entsprechen den `stat_id`-Werten aus dem Schema.

Drei Profile sind definiert:
- `default` — neutraler Ausgangspunkt, wird verwendet bevor ein Avatar gewählt wird
- `alter_mann` — Leitung durch einen älteren Mann
- `frau_migration` — Leitung durch eine junge Frau mit Migrationsgeschichte

Die unterschiedlichen Startwerte bilden strukturelle Realität ab: nicht die persönlichen Fähigkeiten der Avatare sind verschieden, sondern die **Ausgangslage, die die Welt ihnen gegenüber hat**. Der alte Mann startet mit höherem Schulvertrauen (7) und mehr Ressourcenunterstützung (6) — nicht weil er besser ist, sondern weil die Schule ihm gegenüber wohlwollender eingestellt ist. Die Frau mit Migrationsgeschichte startet tiefer (Vertrauen 4, Unterstützung 4) — dieselbe Welt, anderer Ausgangspunkt.

---

## 3. `tag_stat_matrix.csv` — Was Entscheidungen bewirken

Dies ist das **Herzstück der Spiellogik**. Die Datei beschreibt, welche Wirkung jede Art von Entscheidung auf die 20 Stats hat.

Die Zeilen sind **14 Entscheidungs-Tags** — semantische Kategorien, die beschreiben, was eine Spieloption tut:

- *adressieren_direkt / adressieren_offen* — wen und wie die Leitung anspricht
- *eingreifen_früh / eingreifen_spät / eingreifen_nicht* — wann die Leitung eingreift
- *framen_defizit / framen_potenzial / framen_struktur* — wie die Leitung Situationen deutet
- *unterstuetzen_aktiv* — ob aktiv Ressourcen gegeben werden
- *regelstrikt / improvisieren* — ob formelle oder informelle Wege gewählt werden
- *prio_sichtbarkeit / prio_transformation / prio_mitglieder* — was priorisiert wird

Jede konkrete Spieloption ist eine Kombination solcher Tags mit Gewichten. Die Matrix gibt für jede Tag-Stat-Kombination einen **Delta-Wert** an: positiv bedeutet, der Stat steigt; negativ bedeutet, er sinkt; null bedeutet, es gibt keinen plausiblen direkten Zusammenhang. Die Matrix ist bewusst dünn besetzt — nicht jede Entscheidung berührt jeden Stat.

---

## 4. `avatar_overrides.csv` — Warum dieselbe Entscheidung unterschiedliche Folgen hat

Diese Datei ist der Ort, an dem **strukturelle Asymmetrie** ins Modell eingebaut ist.

Für bestimmte Kombinationen aus Avatar, Entscheidungs-Tag und Stat wird der Wert aus der Matrix durch einen Multiplikator verändert:

- Ein Faktor größer als 1 verstärkt den Effekt
- Ein Faktor zwischen 0 und 1 schwächt ihn ab
- Ein **negativer Faktor** kehrt das Vorzeichen um — aus einem positiven Effekt wird ein negativer

Beispiel: Die Tag-Stat-Matrix sagt, dass eine regelkonforme Entscheidung (`regelstrikt`) das Vertrauen der Schulleitung erhöht (+2). Für den alten Mann gilt das verstärkt (×1.2). Für die Frau mit Migrationsgeschichte kippt es ins Negative (×-0.5): dieselbe regelkonforme Entscheidung kostet sie Vertrauen, weil die Schulleitung sie anders liest.

Die Spielerin sieht diese Mechanik nie direkt. Sie erlebt nur, dass manche Entscheidungen bei ihr anders wirken als erwartet — und zieht daraus im besten Fall Schlüsse über strukturelle Ungleichheit.

Die Overrides sind bewusst sparsam: nur Stellen, an denen ein kausaler Zusammenhang zwischen Avatar-Profil und institutioneller Reaktion plausibel und pädagogisch begründbar ist.

---

## Zusammenspiel der vier Dateien

```
stats_schema.csv       →  Was gemessen wird + Anzeigelogik
avatar_baselines.csv   →  Wo die Partie beginnt
tag_stat_matrix.csv    →  Was Entscheidungen grundsätzlich bewirken
avatar_overrides.csv   →  Wo Avatar-Profil die Wirkung verändert
```

Eine Entscheidung im Spiel wird so berechnet:

1. Die Option wird in Tag-Gewichte aufgelöst
2. Für jeden Tag schlägt die Engine in der Matrix nach: welche Stats ändern sich, um wieviel?
3. Falls ein passender Override existiert, wird der Delta-Wert damit multipliziert
4. Der `magnitude_factor` aus dem Schema wird angewendet
5. Das Ergebnis wird auf den aktuellen Stat-Wert addiert, mit Clipping auf [1, 10]

Alle vier Dateien können unabhängig vom Code bearbeitet werden. Neue Avatare, neue Tags oder veränderte Effektstärken erfordern keine Änderung am Spielcode.

---

## Wie Tag-Gewichte wirken

Eine Option im Spiel ist selten die reine Verkörperung eines einzigen Tags. Sie ist meist eine Mischung mehrerer Eigenschaften gleichzeitig — eine Aussage kann zugleich defizitär gerahmt sein, früh eingreifend und direkt adressierend. Diese Mischung wird über Tag-Gewichte beschrieben.

Die Gewichte sind **keine Anteile**, die sich zu 1 summieren müssten. Sie sind **Intensitäten** — jedes Gewicht beantwortet unabhängig die Frage: „Wie stark ist diese Eigenschaft in dieser Option ausgeprägt?" Eine Option kann mehrere starke Eigenschaften gleichzeitig haben.

### Beispielrechnung: zwei Optionen im Vergleich

Beide Optionen wirken auf denselben Stat: `lt_int_def` (Defizit-Lesart der Leitung).

**Option A** — eine einzige Eigenschaft, voll ausgeprägt:
```
framen_defizit: 1.0
```

**Option B** — drei Eigenschaften gleichzeitig:
```
framen_defizit:     0.8
eingreifen_frueh:   0.6
adressieren_direkt: 0.5
```

Die relevanten Matrix-Werte für `lt_int_def`:

| Tag | Wirkung auf lt_int_def |
|---|---|
| framen_defizit | +2 |
| eingreifen_frueh | +2 *(frühes Eingreifen impliziert defizitäre Lesart)* |
| adressieren_direkt | 0 |

**Rechnung für Option A:**
```
δ_roh   = 2 × 1.0 = 2.0
δ_final = 2.0 × 0.3 (magnitude_factor Leitung)
        = +0.6
```

**Rechnung für Option B:**
```
δ_roh   = (2 × 0.8) + (2 × 0.6) + (0 × 0.5)
        = 1.6 + 1.2 + 0
        = 2.8
δ_final = 2.8 × 0.3
        = +0.84
```

Option B verschiebt die Defizit-Lesart **stärker** als Option A — weil zwei ihrer drei Tags auf diesen Stat einzahlen. Eine Aussage, die sowohl defizitär rahmt als auch früh eingreift, signalisiert eine deutlichere Defizit-Haltung als reines Framing allein.

### Tags können sich gegenseitig dämpfen

Wenn zwei Tags einer Option **gegenläufig** auf denselben Stat wirken, neutralisieren sich ihre Beiträge teilweise oder ganz. Eine Option mit `framen_defizit: 0.5` und `framen_potenzial: 0.5` erzeugt auf `lt_int_def` einen Δ nahe 0 — die gegenläufigen Beiträge heben sich auf. Das ist gewollt: eine in sich widersprüchliche Aussage erzeugt keinen klaren Drift im Stil der Leitung.

### Faustregel für die Gewichts-Vergabe

Beim Authoring von Optionen hilft folgende Disziplin:

- **Hauptintention** der Option: 0.7 – 1.0
- **Sekundäre Eigenschaften**: 0.3 – 0.6
- **Beiläufiges Mitschwingen**: 0.1 – 0.3
- **Niemals über 1.0 gehen** — 1.0 bedeutet bereits „voll ausgeprägt"

Damit landen ausgereifte Optionen typischerweise bei Gewichts-Summen zwischen 1.0 und 2.5. Summen deutlich unter 1.0 fühlen sich beim Spielen schwach an, Summen über 3.0 wirken überladen — meist ein Zeichen, dass zu viele Haltungen in einen Satz gepresst wurden.

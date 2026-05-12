<img width="721" height="471" alt="image" src="https://github.com/user-attachments/assets/08c4700a-bdb9-4ee7-a33d-e21b9f5a1a07" />
<br><br>

Dieses Dokument beschreibt das aktuellen Design von **UNFAIR**. Es ist absichtlich eng an den vorhandenen Daten- und Code-Strukturen formuliert. 

## Kurzfassung

UNFAIR ist ein decision-driven Serious Game, in dem Entscheidungen nicht (nur) als bipolare Skalen modelliert werden. Jede Antwortoption wird als Mischung mehrerer Handlungsqualitäten beschrieben. Diese Mischung wird über Tags berechnet, durch Avatar-spezifische Lesarten verändert (z.B. älterer Mann, Frau mit Migrationsgeschichte) und auf ein mehrdimensionales System von Spielwerten angewendet.

Als mehrdimensionales System modelliert UNFAIR mehrere Beziehungen gleichzeitig: Entscheidungen auf der Ebene AG Leitung beeinflußen Zustände im Bereich 'Projekt', 'Schule',  und 'AG-Mitglieder'. Jeder Bereich folgt seiner eigenen Logik. Eine Entscheidung kann deshalb gleichzeitig hilfreich, riskant, sichtbar, irritierend, stabilisierend, anerkennend etc. wirken.

## 0. Projektsteckbrief

- Wer spielt UNFAIR konkret?
-- Studierende der Sozialen Arbeit  

- In welchem Ausbildungskontext wird es eingesetzt?
-- Hochschule 

- Welche Situation oder Rolle übernimmt die Spielerin? -- 
Leitung einer Schüler:innen Arbeitgruppe (AG) zum Thema Nachhaltigkeit 
 
- Was soll nach einer Spielrunde besprochen werden?
-- Wie unterschiedliche Erwartungen in der Praxis unter einen Hut gebracht werden können und wie realistisch die dargestellten Situationen sind. 
 
- Soll der Fokus eher auf Entscheidungsauswertung, Reflexion, Avatar-Erfahrung oder institutioneller Dynamik liegen? -- Avatar-Erfahrung & Reflexion 


## 1. Entscheidungen werden als Bedeutungskombinationen modelliert (semantische Tags)

Antwortoptionen tragen `option_tags`, also semantische Eigenschaften mit Gewichten. Eine Option kann zum Beispiel gleichzeitig strukturiert, direkt, sichtbarkeitsorientiert oder mitgliederorientiert sein (soziale Handlungen als Vektoren).

Die Wirkung dieser Tags wird per Datei `data/tag_stat_matrix.csv` definiert. Dort wird für jeden Tag eine Wirkung auf bestimmte Stats definiert (positiv, negativ oder null). Somit kann eine Reaktion im Spiel als Bündel von Haltungen und Handlungsimpulsen gelesen. Die Engine summiert die Beiträge aller Tags, statt eine vordefinierte Konsequenz pro Option abzuspielen.

Daten:

```text
option_tags -> tag_stat_matrix.csv -> rohe Stat-Deltas
```
> **Beispiel:** Eine Antwort-Option wie „Tom, so reden wir hier nicht" trägt zum Beispiel die Tags regelstrikt 0.8, eingreifen_frueh 0.5 und adressieren_direkt 0.4. Dieselbe Aussage ist damit im Stat-System gleichzeitig regelorientiert, früh intervenierend und direkt adressierend — drei Eigenschaften, die parallel auf mehrere Systeme wirken (z.B. Schule, Projekt) und somit institutionelle Ambiguität abbilden. Quelle: *stories/03_anna_verschwindet.json*

## 2. Die gleiche Entscheidung kann je nach Avatar anders gelesen werden (intersektionales Modell) 

Die Datei `data/avatar_overrides.csv` verändert ausgewählte Tag-Stat-Wirkungen pro Avatar. Das Modell sagt damit nicht nur: "Avatar A startet anders als Avatar B." Es sagt auch: "Dieselbe Handlung kann von der Spielwelt unterschiedlich bewertet werden."

Ein Override kann:

- eine Wirkung verstärken
- eine Wirkung abschwächen
- eine Wirkung umkehren, wenn der Multiplikator negativ ist

Dieses Design impliziert, dass strukturelle Asymmetrie nicht nur als Startnachteil vorkommt, sondern auch in der Interpretation einzelner Handlungen zu finden ist.

Daten:

```text
matrix_delta * option_weight * avatar_override * magnitude_factor = final_delta
```
> **Beispiel** aus dem aktuellen Material: Für das Tag regelstrikt definiert avatar_overrides.csv den Multiplikator 1.2 für *alter_mann* und -0.5 für *frau_migration*. Eine regelorientierte Entscheidung kann damit bei einem Avatar Schulvertrauen aufbauen, bei einem anderen Schulvertrauen kosten — Vorzeichen-Kippung in identischer Situation.



## 3. Systemische Modellierung: Stats bilden vier Beziehungsebenen ab

Das Stat-System besteht aus 20 Werten in vier Bereichen:

| Bereich | Was er beschreibt |
|---|---|
| `projekt` | Zustand des Nachhaltigkeitsprojekts |
| `schule` | Institutionelles Umfeld, Vertrauen, Normen, Unterstützung |
| `leitung` | Entstehender Handlungsstil der Spielerin, kann sich im Spielverlauf ändern / Charakterentwicklung |
| `ag_mitglieder` | Dynamik innerhalb der Arbeitsgruppe |

Jeder Bereiche spiegelt ein ihm eigene Handlungsrationalität.

Eine Entscheidung kann zum Beispiel:

- dem Projekt Sichtbarkeit geben
- institutionelles Vertrauen kosten
- die eigene Leitung stärker regulierend machen
- die AG-Mitglieder weniger abhängig wirken lassen

Das Spiel stellt mehrere Wirklichkeitslogiken nebeneinander, ohne einer übergreifenden Fortschrittsleiste zu folgen (z.B. es gibt kein Level-up für die Spielenden). Dies soll eine gewisse  Komplexität erzeugen: Eine Entscheidung kann in einem Bereich sinnvoll und in einem anderen Bereich 'teuer' sein.

## 4. Fachkraft bezogene Veränderungen wirken langsamer als in anderen Bereichen

In `data/stats_schema.csv` hat jeder Stat einen `magnitude_factor`. Projekt-, Schul- und AG-Stats arbeiten aktuell mit Faktor `1.0`. Leitungs-Stats arbeiten mit Faktor `0.3`. Dadurch verändert sich der Handlungsstil der Spielerin (Habitus) langsamer als direkte Projekt- oder Beziehungseffekte. Eine einzelne Antwort kippt die Leitung nicht sofort. Stil entsteht über wiederholte Entscheidungen (professionelle Sozialisation).

Das ist ein eigener Designpunkt: Die Spielerin wird nicht nach einer Einzelentscheidung typisiert. Das Spiel akkumuliert kleine Verschiebungen über die Zeit. Eine ähnlich Dynamik ist auch für Veränderungen auf der Schulebene denkbar. 

- `neue_baseline = alte_baseline + α × (tag_ziel − alte_baseline)`


## 5. Varianten verändern Sprache, nicht Mechaniken

Das Szenenschema unterstützt `story_hook_variants` und `option_text_variants`. Diese Varianten können abhängig von Stat-Bedingungen oder `avatar_id` andere Texte anzeigen.

Wichtig: Bei `option_text_variants` bleiben die `option_tags` unverändert. Das bedeutet: Die Formulierung kann sich verändern, aber die mechanische Wirkung der Option bleibt gleich.

Damit kann das Spiel Sprache als Teil der Situation sichtbar machen, ohne eine neue Effektlogik zu benötigen. Eine Option kann für einen Avatar anders klingen, ohne das der mechanischer Pfad geändert werden muss.

Szeneneinleitung und Reaktionsoptionen unterscheiden sich somot sprachlich und zusätzlcih können je nach Situation auch zusätliche Reaktionsoptionen angeboten werden.  

## 6. Szenen sind datengetrieben und validierbar angelegt

Stories liegen als JSON-Dateien in `stories/`. Das Format ist in `data/schemas/scene_schema.json` formal beschrieben und in `docs/scene_schema_erklaerung.md` erklärt.

Das trennt Authoring von Implementierung:

- Szenenautorinnen können Hook-Texte, Optionen, Tags und Varianten in JSON bearbeiten. Später ist auch eine flexible Eingabemöglichkeit im Spielkontext denkbar. 
- Die Engine lädt Story-Dateien aus dem Ordner (aktuell werden noch alle Szenarien sequentiell abgespielt, später sollte es einen Szenen-Flow-Manager geben.)

## 7. Startwerte und Folgewirkungen sind getrennt (Emergent Procedural Friction) 

`data/avatar_baselines.csv` definiert die Ausgangswerte pro Avatar. `data/avatar_overrides.csv` definiert Ausnahmen bei der Wirkung einzelner Handlungen.

Das trennt zwei Dinge:
- **Ausgangslage:** Mit welchen Werten startet ein Avatar?
- **Lesart der Handlung:** Wie wird dieselbe Entscheidung später bewertet?

Dadurch kann ein Avatar nicht nur "andere Stats" haben, er kann in derselben Situation auch anders adressiert oder sanktioniert werden, ohne dass dafür separate Szenen geschrieben werden müssen. 

> **Beispiel:** In Szene 03 erhält der Avatar *frau_migration* für *opt_safe_space* einen Text mit einem zusätzlichen Halbsatz („Ich glaube das hilft uns allen, bevor wir weitermachen…"), während der Avatar *alter_mann* dieselbe Maßnahme ohne diesen Halbsatz ansetzt. Die option_tags (Handlungsmarkierungen) beider Versionen sind identisch. 

> **Konsequenz:** soll 'Erklärungslast' (braucht mehr Energie) sichtbar machen.  Der alte Mann setzt eine Maßnahme an. Die Frau verwendet zusätzlich einen legitimierenden Halbsatz. Die subtile Veränderung ist entscheidend, da der reale Effekt in der Wiederholung liegt - nicht in der einmaligen Erklärung. 
> Diskriminierungserfahrung kommt über Sprache und braucht keine expliziten Diskriminierungsmarker.

## 8. Das Outro übersetzt Entscheidungen in Erfahrungsprofile

Das aktuelle Outro lädt `stories/gameplay_experiences.json`. Dort sind vier Pfade angelegt:

- Anpassung
- Beziehung
- Wirkung
- Haltung

Die Prozentwerte stehen aktuell noch auf `0`. Die spätere Berechnungslogik ist noch nicht fixiert (möglich ist eine Auswertung der Stats and Tags, die eine Reflexion sinnvoll unterstützen kann). Die Struktur ist bereits vorbereitet: Das Outro arbeitet mit stabilen IDs wie `anpassung`, `beziehung`, `wirkung` und `selbstbehauptung`, sodass Anzeigenamen geändert werden können, ohne die Datenbindung zu brechen.


## 9. Was das Spiel nicht macht ...

- nachweislich bestimmte Lernziele erreichen
- Empathie, Reflexion oder professionelle Haltung garantieren
- vollständige soziale Realität simulieren
- repräsentative Avatar-Modelle für reale Personengruppen verwenden
- Prozentwerte im Outro als Evaluation der Spielenden verstehen 

 
<img width="810" height="342" alt="image" src="https://github.com/user-attachments/assets/07e193fc-4acc-4349-8ac5-cdc433883762" />

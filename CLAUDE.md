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

# Rechen-Trainer

Rechenspiele für Kinder, gebaut mit Godot 4.7 (GDScript, GL Compatibility), für Android im Hochformat.

## Spiele

- **Schüttel-Boxen**: Eine Box mit X Kugeln hat zwei Fächer: eins offen, eins unter einem Deckel. Das Kind schüttelt
  das Handy (oder tippt auf „Schütteln“), Kugeln hüpfen über den Keil ins offene Fach, und das Kind tippt an,
  wie viele noch versteckt sind. Zahlen: „bis 10“ oder „Eigene“ (feste Zahl oder Bereich, 2 bis 20).
  Die Antwort-Tasten erscheinen, sobald keine Kugel mehr über den Keil kommen kann; dann schließt eine
  unsichtbare Sperre über dem Keil. Der Pfeil-Knopf oben schaltet doppeltes Tempo um.

## Struktur

| Pfad | Inhalt |
| --- | --- |
| `scenes/main_menu/` | Startbildschirm mit Kacheln und Zahlenraum-Auswahl |
| `scenes/shake_boxes/` | Spielszene, Box-Physik (`shake_box.gd`), Kugeln (`marble.gd`) |
| `scripts/shake_boxes/` | Regeln ohne Nodes: `NumberRange`, `ShakeBoxRound` (headless getestet) |
| `scripts/session.gd` | Autoload `Session`: gewählter Zahlenraum, gespeicherte Einstellungen (`user://settings.cfg`) |
| `scripts/ui/number_stepper.gd` | Zahlen-Auswahl mit großen −/+ Tasten |
| `i18n/strings.csv` | Alle UI-Texte. Neue Sprache = neue Spalte (z. B. `en`) |
| `tests/` | Headless-Tests |

## Prüfen ohne Editor

```bash
godot --headless --path . --import
godot --headless --path . --script res://tests/run_all.gd
```

## Hinweise

- Schütteln nutzt den Beschleunigungssensor. In Godot 4.7 ist er standardmäßig **aus**;
  `input_devices/sensors/enable_accelerometer` ist in `project.godot` deshalb eingeschaltet.
- Die Box simuliert in einem eigenen `SubViewport` in fester Größe; skaliert wird nur die Darstellung.
- Der Android-Zurück-Button führt vom Spiel ins Menü und beendet im Menü die App.

# install-conky – Changelog

```
install-conky – Aenderungsverlauf des Projekts.

Projekt:     install-conky
Modul:       CHANGELOG.md
Version:     1.1.0
Stand:       2026-08-23
Abhaengig:   bash >= 4, apt, conky (Paket), Debian/Raspberry Pi OS
Bezug:       requirements.txt (leer – kein Python)
Lizenz:      MIT
Upstream:    –
Erstellt mit: Cursor Grok 4.6
Autor:       (FFHB) / RadioBBS
```

Format: `Version X.Y.Z – YYYY-MM-DD – Beschreibung` (neueste unten).

## Version 1.0.0 – 2026-08-23

- Erste Version: Conky pruefen und bei Bedarf per apt installieren.
- Konfigurationstabelle oben im Skript (Position, Schrift, Transparenz,
  Anzeigebloecke: IPv4/IPv6, WLAN, Signal, Temperatur, CPU, …).
- Verzeichnisse, System- und Benutzerconfig, Autostart, Conky-Neustart.
- CLI: `--help` / `--Hilfe`, `--version`, `--deinstall`, `--pruefen`,
  `--dry-run`, `--log`, `--Ende`; Ausfuehrung mit sudo.
- Standardanzeige: rechts unten, weisse Schrift.

## Version 1.1.0 – 2026-08-23

- LAN-Block fuer `eth0` (Status, IPv4/IPv6, Netzlast) mit zusaetzlichem
  Trennstrich.
- Anzeige am unteren rechten Bildschirmrand angedockt (`gap_x`/`gap_y` 0,
  Fenstertyp `override`).
- Transparenz auf 90 gesetzt.

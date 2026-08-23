# install-conky – Conky auf Raspberry Pi / Debian einrichten

```
install-conky – Conky auf Raspberry Pi / Debian pruefen, einrichten und starten.

Projekt:     install-conky
Modul:       README.md
Version:     1.2.0
Stand:       2026-08-23
Abhaengig:   bash >= 4, apt, conky (Paket), Debian/Raspberry Pi OS
Bezug:       requirements.txt (leer – kein Python)
Lizenz:      MIT
Upstream:    –
Erstellt mit: Cursor Grok 4.6
Autor:       (FFHB) / RadioBBS
```

## Beschreibung

Installations- und Konfigurationsskript fuer Conky auf Raspberry Pi OS
(Debian). Es prueft, ob Conky vorhanden ist, installiert das Paket bei
Bedarf, legt Verzeichnisse und Config-Dateien an und startet Conky neu.

Die Anzeige wird nicht per langer CLI gesteuert, sondern ueber die
**Konfigurationstabelle oben in `install_conky.sh`**: Position, Schrift,
Farbe, Transparenz und welche Bloecke sichtbar sind (IPv4, IPv6, WLAN,
Signalstaerke, LAN/ETH0, Temperatur, CPU, RAM, Disk, …). Standard:
**unten rechts am Bildschirmrand angedockt**, weisse Schrift,
Transparenz 90. Zwei Netzbloecke: **WLAN** (Netzname, IPv4, IPv6), danach
**ETH0** (up/down, IPv4, IPv6). Nach jeder Aenderung das Skript erneut
mit `sudo` ausfuehren.

## Voraussetzungen

- Raspberry Pi OS oder Debian mit grafischer Sitzung (X11)
- bash >= 4, apt, sudo
- optional: `wireless-tools` (`iwgetid`) und `iw` fuer SSID/Signal
- Wayland (labwc): Conky braucht in der Regel eine X11-Sitzung

Das Skript ist fuer den Lauf **auf dem Pi** gedacht, nicht unter Windows.

## Installation

Skript auf den Pi kopieren, ausfuehrbar machen, Tabelle bei Bedarf
anpassen, dann:

```bash
chmod +x install_conky.sh
./install_conky.sh --help
./install_conky.sh --pruefen
sudo ./install_conky.sh
```

Python-Abhaengigkeiten gibt es nicht. Der Styleguide-Weg bleibt:

```bash
python -m pip install -r requirements.txt
```

## Aufruf / Nutzung

`--help` und `--version` ohne sudo. Installation, Update und
Deinstallation mit sudo.

```bash
sudo ./install_conky.sh
sudo ./install_conky.sh --log
sudo ./install_conky.sh --user pi
sudo ./install_conky.sh --deinstall
sudo ./install_conky.sh --deinstall --yes
./install_conky.sh --help
./install_conky.sh --version
./install_conky.sh --pruefen
./install_conky.sh --dry-run
```

### Was das Skript anlegt

| Pfad | Zweck |
|---|---|
| `/etc/conky/conky.conf` | Systemweite Config (Original wird einmalig gesichert) |
| `~/.config/conky/conky.conf` | Config des Desktop-Benutzers |
| `~/.config/autostart/install-conky.desktop` | Autostart nach Login |
| `/var/lib/install-conky/` | Zustand fuer die Deinstallation |

Conky wird fuer `SUDO_USER` (oder `--user`) gestartet. Ohne laufende
X11-Sitzung bleibt der Autostart fuer den naechsten Desktop-Login.

## Wichtige Risiken

- `apt-get` installiert Pakete (`conky-all` bzw. Fallback).
- Laufende Conky-Prozesse des Zielbenutzers werden beendet und neu gestartet.
- `/etc/conky/conky.conf` wird ersetzt; ein vorhandenes Original landet in
  `conky.conf.install-conky.bak`.
- `--deinstall` loescht die vom Skript angelegten Dateien. Das Conky-Paket
  wird nur entfernt, wenn **dieses** Skript es zuvor installiert hat.
- `--deinstall --yes` fragt nicht nach.

## Tests

```bash
bash tests/test_install_conky.sh
```

Der Test prueft Syntax, Hilfe/Version, Tabellen-Defaults und LF-Zeilenenden.
Er installiert nichts und braucht kein sudo.

## Historie

- Version 1.0.0 – 2026-08-23 – Erste Version: Installation, Tabelle, Autostart.
- Version 1.1.0 – 2026-08-23 – LAN eth0, Andocken unten rechts, Transparenz 90.
- Version 1.2.0 – 2026-08-23 – WLAN und ETH0 getrennt (kein doppeltes WLAN-IP).

## Lizenz

MIT – siehe `LICENSE`.

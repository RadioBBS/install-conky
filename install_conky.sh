#!/usr/bin/env bash
#
# install-conky – Conky auf Raspberry Pi / Debian pruefen, einrichten und starten.
#
# Projekt:     install-conky
# Modul:       install_conky.sh
# Version:     1.3.0
# Stand:       2026-08-23
# Abhaengig:   bash >= 4, apt, conky (Paket), Debian/Raspberry Pi OS
# Bezug:       requirements.txt (leer – kein Python)
# Lizenz:      MIT
# Upstream:    –
# Erstellt mit: Cursor Grok 4.6
# Autor:       (FFHB) / RadioBBS
#
# Beschreibung
# ------------
# Prueft, ob Conky installiert ist, und installiert das Paket bei Bedarf.
# Richtet Verzeichnisse, Conky-Konfiguration und Autostart ein. Die
# Anzeige (Position, Schrift, Transparenz, Bloecke) kommt aus der
# Konfigurationstabelle oben im Skript. Jeder Lauf schreibt die Config
# neu und startet Conky erneut.
#
# Historie
# --------
# Version 1.0.0 – 2026-08-23 – Erste Version: Installation, Config aus
#                              Tabelle, Autostart, Neustart, Deinstallation.
# Version 1.1.0 – 2026-08-23 – LAN eth0 mit Trennstrich; Randabstand 0 und
#                              Fenstertyp override (unten rechts andocken);
#                              Transparenz 90.
# Version 1.2.0 – 2026-08-23 – Netz-Bloecke getrennt: WLAN (Netz, IPv4, IPv6),
#                              danach ETH0 (up/down, IPv4, IPv6).
# Version 1.3.0 – 2026-08-23 – Traffic wieder je Schnittstelle; LAN/WLAN
#                              automatisch erkannt (nicht fest eth0/wlan0).
#
# Aufruf / Nutzung
# ----------------
#   sudo ./install_conky.sh
#   sudo ./install_conky.sh --log
#   sudo ./install_conky.sh --deinstall
#   sudo ./install_conky.sh --deinstall --yes
#   ./install_conky.sh --help
#   ./install_conky.sh --version
#   ./install_conky.sh --pruefen
#

set -euo pipefail

VERSION="1.3.0"
VERSION_DATUM="2026-08-23"
SKRIPTNAME="${0##*/}"
END_PROMPT='Programmende: "Hit any Key or Enter"'

# =============================================================================
# KONFIGURATIONSTABELLE
# Werte hier aendern, anschliessend das Skript erneut mit sudo ausfuehren.
# Jeder Lauf schreibt die Conky-Config neu und startet Conky neu.
# Schalter: ja | nein
# =============================================================================
#
# Feld                 | Typ    | Standard       | Bedeutung
# ---------------------+--------+----------------+-----------------------------
# CFG_POSITION         | string | unten_rechts   | Ecke: oben_links, oben_rechts,
#                      |        |                | unten_links, unten_rechts
# CFG_GAP_X            | int    | 0              | Abstand vom Rand, Pixel X
#                      |        |                | (0 = rechter Rand bei unten_rechts)
# CFG_GAP_Y            | int    | 0              | Abstand vom Rand, Pixel Y
#                      |        |                | (0 = unterer Rand bei unten_rechts)
# CFG_SCHRIFTART       | string | DejaVu Sans Mono | XFT-Schriftfamilie
# CFG_SCHRIFTGROESSE   | int    | 10             | Schriftgroesse 6..48
# CFG_SCHRIFTFARBE     | string | white          | Standardtext (Name oder Hex)
# CFG_TITELFARBE       | string | lightgrey      | Beschriftungen links
# CFG_HINTERGRUND      | string | 000000         | Fensterfarbe ohne #
# CFG_TRANSPARENZ      | int    | 90             | 0 unsichtbar .. 255 deckend
# CFG_INTERVALL        | int    | 2              | Refresh in Sekunden
# CFG_MIN_BREITE       | int    | 280            | Mindestbreite Pixel
# CFG_SPALTE           | int    | 90             | Spalte fuer Messwerte
# CFG_FENSTERTYP       | string | override       | Conky own_window_type
#                      |        |                | override dockt an den Bildschirmrand
# CFG_NETZWERK         | string | auto           | WLAN-Interface: auto oder Name
# CFG_LAN_IFACE        | string | auto           | LAN-Interface: auto oder Name
# CFG_ZEIGE_HOSTNAME   | ja/nein| ja             | Rechnername
# CFG_ZEIGE_UHRZEIT    | ja/nein| ja             | Datum und Uhrzeit
# CFG_ZEIGE_UPTIME     | ja/nein| ja             | Laufzeit
# CFG_ZEIGE_CPU        | ja/nein| ja             | CPU-Auslastung und Balken
# CFG_ZEIGE_LOAD       | ja/nein| ja             | Load Average
# CFG_ZEIGE_RAM        | ja/nein| ja             | Arbeitsspeicher
# CFG_ZEIGE_DISK       | ja/nein| ja             | Belegung von /
# CFG_ZEIGE_TEMPERATUR | ja/nein| ja             | SoC-/CPU-Temperatur
# CFG_ZEIGE_IPV4       | ja/nein| ja             | IPv4 je Block (WLAN und LAN)
# CFG_ZEIGE_IPV6       | ja/nein| ja             | IPv6 je Block (WLAN und LAN)
# CFG_ZEIGE_WLAN       | ja/nein| ja             | WLAN-Block: Netzname, IPs
# CFG_ZEIGE_SIGNAL     | ja/nein| ja             | WLAN-Signalstaerke
# CFG_ZEIGE_NETZLAST   | ja/nein| ja             | Down-/Upload je Schnittstelle
# CFG_ZEIGE_LAN        | ja/nein| ja             | LAN-Block: Name, up/down, IPs
# =============================================================================

CFG_POSITION="unten_rechts"
CFG_GAP_X="0"
CFG_GAP_Y="0"
CFG_SCHRIFTART="DejaVu Sans Mono"
CFG_SCHRIFTGROESSE="10"
CFG_SCHRIFTFARBE="white"
CFG_TITELFARBE="lightgrey"
CFG_HINTERGRUND="000000"
CFG_TRANSPARENZ="90"
CFG_INTERVALL="2"
CFG_MIN_BREITE="280"
CFG_SPALTE="90"
CFG_FENSTERTYP="override"
CFG_NETZWERK="auto"
CFG_LAN_IFACE="auto"
CFG_ZEIGE_HOSTNAME="ja"
CFG_ZEIGE_UHRZEIT="ja"
CFG_ZEIGE_UPTIME="ja"
CFG_ZEIGE_CPU="ja"
CFG_ZEIGE_LOAD="ja"
CFG_ZEIGE_RAM="ja"
CFG_ZEIGE_DISK="ja"
CFG_ZEIGE_TEMPERATUR="ja"
CFG_ZEIGE_IPV4="ja"
CFG_ZEIGE_IPV6="ja"
CFG_ZEIGE_WLAN="ja"
CFG_ZEIGE_SIGNAL="ja"
CFG_ZEIGE_NETZLAST="ja"
CFG_ZEIGE_LAN="ja"

# -----------------------------------------------------------------------------
# Laufzeit und Pfade (nicht die Anzeigetabelle)
# -----------------------------------------------------------------------------
DEFAULT_LOGFILE="install-conky.log"
STATE_DIR="/var/lib/install-conky"
STATE_DATEI="${STATE_DIR}/state.env"
DATEILISTE="${STATE_DIR}/dateiliste.txt"
ETC_CONKY_DIR="/etc/conky"
ETC_CONKY_CONF="${ETC_CONKY_DIR}/conky.conf"
ETC_CONKY_BACKUP="${ETC_CONKY_DIR}/conky.conf.install-conky.bak"
MARKER="install-conky"

logging_aktiv="false"
warte_am_ende="false"
deinstallieren="false"
nur_pruefen="false"
dry_run="false"
auto_ja="false"
ziel_user_cli=""
LOGDATEI="./${DEFAULT_LOGFILE}"

CONKY_TEXT=""
NETZ_IFACE=""
WLAN_IFACE=""
LAN_IFACE=""
ZIEL_USER=""
ZIEL_HOME=""
paket_durch_uns="nein"
paketname=""

# =============================================================================
# Hilfsfunktionen
# =============================================================================

zeitstempel() {
	#
	# Beschreibung: Liefert den aktuellen Zeitstempel fuer Logzeilen.
	# Parameter:    keine
	# Rueckgabewert: YYYY-MM-DD HH:MM:SS auf stdout
	# Fehlerfaelle: date nicht verfuegbar
	# Beispiel:     zeitstempel
	#
	date '+%Y-%m-%d %H:%M:%S'
}

log_nachricht() {
	#
	# Beschreibung: Schreibt eine Logzeile, falls Logging aktiv ist.
	# Parameter:    $1 = Meldung
	# Rueckgabewert: keines
	# Fehlerfaelle: Schreibfehler werden ignoriert
	# Beispiel:     log_nachricht "Starte"
	#
	if [ "$logging_aktiv" != "true" ]; then
		return 0
	fi
	printf '%s %s\n' "$(zeitstempel)" "$1" >> "$LOGDATEI" || true
}

info_meldung() {
	#
	# Beschreibung: Info auf stdout und optional ins Log.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     info_meldung "Conky gestartet"
	#
	echo "$SKRIPTNAME: $1"
	log_nachricht "INFO  $1"
}

warn_meldung() {
	#
	# Beschreibung: Warnung auf stderr und optional ins Log.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     warn_meldung "Kein Display"
	#
	echo "$SKRIPTNAME: WARNUNG: $1" >&2
	log_nachricht "WARN  $1"
}

fehler_melden() {
	#
	# Beschreibung: Fehlermeldung mit optionalem Logeintrag.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     fehler_melden "Root fehlt"
	#
	echo "$SKRIPTNAME: FEHLER: $1" >&2
	log_nachricht "FEHLER $1"
}

warte_auf_ende() {
	#
	# Beschreibung: Wartet auf Tastendruck, wenn --Ende gesetzt ist.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: read kann bei fehlendem TTY scheitern
	# Beispiel:     warte_auf_ende
	#
	if [ "$warte_am_ende" != "true" ]; then
		return 0
	fi
	printf '%s\n' "$END_PROMPT"
	read -r -n 1 _ || true
	echo
}

beende() {
	#
	# Beschreibung: Programmende mit optionaler Tastenwarte und Exit-Code.
	# Parameter:    $1 = Exit-Code (Standard 0)
	# Rueckgabewert: beendet das Skript
	# Fehlerfaelle: finaler Abbruch
	# Beispiel:     beende 0
	#
	warte_auf_ende
	exit "${1:-0}"
}

beende_mit_fehler() {
	#
	# Beschreibung: Zentrale Fehlerbehandlung mit Exit-Code.
	# Parameter:    $1 = Exit-Code, $2 = Meldung
	# Rueckgabewert: beendet das Skript
	# Fehlerfaelle: finaler Abbruch
	# Beispiel:     beende_mit_fehler 2 "Unbekannte Option"
	#
	fehler_melden "$2"
	beende "$1"
}

ist_ja() {
	#
	# Beschreibung: Prueft, ob ein Tabellenwert als ja gilt.
	# Parameter:    $1 = Wert
	# Rueckgabewert: 0 bei ja, sonst 1
	# Fehlerfaelle: keine
	# Beispiel:     ist_ja "$CFG_ZEIGE_CPU"
	#
	case "${1,,}" in
		ja|yes|true|1|on) return 0 ;;
		*) return 1 ;;
	esac
}

ist_root() {
	#
	# Beschreibung: Prueft, ob das Skript als root laeuft.
	# Parameter:    keine
	# Rueckgabewert: 0 wenn UID 0, sonst 1
	# Fehlerfaelle: keine
	# Beispiel:     ist_root
	#
	[ "$(id -u)" -eq 0 ]
}

ist_debian() {
	#
	# Beschreibung: Erkennt Debian-basiertes System (inkl. Raspberry Pi OS).
	# Parameter:    keine
	# Rueckgabewert: 0 wenn Debian, sonst 1
	# Fehlerfaelle: /etc/debian_version fehlt
	# Beispiel:     ist_debian
	#
	[ -f /etc/debian_version ]
}

ist_raspberry() {
	#
	# Beschreibung: Erkennt Raspberry-Pi-Hardware anhand des Device-Tree.
	# Parameter:    keine
	# Rueckgabewert: 0 wenn Raspberry, sonst 1
	# Fehlerfaelle: Datei unlesbar -> 1
	# Beispiel:     ist_raspberry
	#
	local modell=""
	if [ ! -r /proc/device-tree/model ]; then
		return 1
	fi
	modell="$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || true)"
	[[ "$modell" == *[Rr]aspberry* ]]
}

# =============================================================================
# CLI
# =============================================================================

zeige_version() {
	#
	# Beschreibung: Versionsnummer, Datum und Programmbeschreibung.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     zeige_version
	#
	echo "install-conky $VERSION ($VERSION_DATUM)"
	echo "Prueft und installiert Conky, schreibt die Config aus der Tabelle und startet neu."
}

zeige_hilfe() {
	#
	# Beschreibung: Programmbeschreibung, Parameter und Beispiele.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     zeige_hilfe
	#
	cat << EOF
install-conky $VERSION ($VERSION_DATUM)
Prueft die Conky-Installation auf Raspberry Pi OS / Debian, richtet
Verzeichnisse und Konfiguration ein und startet Conky neu.

Anzeigeparameter stehen in der KONFIGURATIONSTABELLE oben in dieser
Datei (Position, Schrift, Transparenz, IPv4/IPv6, WLAN, Signal,
LAN, Temperatur, CPU, ...). Standard: unten rechts am Bildschirmrand
angedockt, weisse Schrift, Transparenz 90.
Zwei Netzbloecke: WLAN (Netz, IPv4, IPv6, Traffic), dann LAN (erkannt,
up/down, IPv4, IPv6, Traffic). Schnittstellennamen werden ermittelt.
Nach Aenderungen das Skript erneut mit sudo ausfuehren.

Verwendung:
  sudo $0
  sudo $0 --log
  sudo $0 --deinstall [--yes]
  $0 --help | -h | --Hilfe
  $0 --version
  $0 --pruefen

Parameter:
  (ohne)               Installation/Aktualisierung: Paket, Config, Autostart,
                       Conky-Neustart
                       Typ: Aktion, Standard: diese Aktion
                       Beispiel: sudo $0
  --deinstall          Conky-Einrichtung entfernen (Config, Autostart;
                       Paket nur, wenn dieses Skript es installiert hat)
                       Typ: Schalter, Standard: aus
                       Beispiel: sudo $0 --deinstall
  --uninstall          Alias fuer --deinstall
                       Typ: Schalter, Standard: aus
                       Beispiel: sudo $0 --uninstall
  --yes, --ja          Deinstallation ohne Rueckfrage
                       Typ: Schalter, Standard: aus
                       Beispiel: sudo $0 --deinstall --yes
  --pruefen            Tabelle validieren, nichts installieren (ohne sudo)
                       Typ: Schalter, Standard: aus
                       Beispiel: $0 --pruefen
  --dry-run            Erzeugte Conky-Config auf stdout, ohne Schreiben
                       Typ: Schalter, Standard: aus
                       Beispiel: $0 --dry-run
  --user <name>        Desktop-Benutzer fuer Config und Autostart
                       Typ: String, Standard: SUDO_USER bzw. erster Normaluser
                       Beispiel: sudo $0 --user pi
  --log                Logging in $DEFAULT_LOGFILE (als root: /var/log/)
                       Typ: Schalter, Standard: aus
                       Beispiel: sudo $0 --log
  -h, --help, --Hilfe  Diese Hilfe anzeigen
                       Typ: Schalter
                       Beispiel: $0 --help
  --version            Version und Datum anzeigen
                       Typ: Schalter
                       Beispiel: $0 --version
  -E, --Ende           Am Ende auf Tastendruck warten
                       Typ: Schalter, Standard: aus
                       Beispiel: sudo $0 --Ende

Beispiele:
  sudo ./install_conky.sh
  sudo ./install_conky.sh --log --Ende
  sudo ./install_conky.sh --deinstall --yes
  ./install_conky.sh --help
  ./install_conky.sh --version
  ./install_conky.sh --pruefen
EOF
}

verarbeite_argumente() {
	#
	# Beschreibung: Liest CLI-Argumente und setzt Laufzeitflags.
	# Parameter:    alle Aufrufargumente
	# Rueckgabewert: keines; setzt globale Flags
	# Fehlerfaelle: unbekannte Option oder fehlender Wert -> Exit 2
	# Beispiel:     verarbeite_argumente "$@"
	#
	while [ $# -gt 0 ]; do
		case "$1" in
			-h|--help|--Hilfe)
				zeige_hilfe
				beende 0
				;;
			--version)
				zeige_version
				beende 0
				;;
			--deinstall|--uninstall)
				deinstallieren="true"
				shift
				;;
			--yes|--ja)
				auto_ja="true"
				shift
				;;
			--pruefen)
				nur_pruefen="true"
				shift
				;;
			--dry-run)
				dry_run="true"
				shift
				;;
			--user)
				[ -n "${2:-}" ] || beende_mit_fehler 2 "Parameter --user erfordert einen Namen"
				ziel_user_cli="$2"
				shift 2
				;;
			--log)
				logging_aktiv="true"
				shift
				;;
			-E|--Ende)
				warte_am_ende="true"
				shift
				;;
			-*)
				beende_mit_fehler 2 "Unbekannte Option: $1 (siehe --help)"
				;;
			*)
				beende_mit_fehler 2 "Unerwartetes Argument: $1 (siehe --help)"
				;;
		esac
	done
}

# =============================================================================
# Validierung der Konfigurationstabelle
# =============================================================================

validiere_ganzzahl() {
	#
	# Beschreibung: Prueft, ob ein Wert eine Ganzzahl im Bereich ist.
	# Parameter:    $1 Name, $2 Wert, $3 Minimum, $4 Maximum
	# Rueckgabewert: keines
	# Fehlerfaelle: ungueltig -> Exit 2
	# Beispiel:     validiere_ganzzahl CFG_GAP_X 16 0 4000
	#
	local name="$1" wert="$2" mini="$3" maxi="$4"
	case "$wert" in
		''|*[!0-9]*) beende_mit_fehler 2 "$name muss eine Ganzzahl sein (ist: $wert)" ;;
	esac
	if [ "$wert" -lt "$mini" ] || [ "$wert" -gt "$maxi" ]; then
		beende_mit_fehler 2 "$name muss zwischen $mini und $maxi liegen (ist: $wert)"
	fi
}

validiere_ja_nein() {
	#
	# Beschreibung: Erlaubt nur ja oder nein (Gross/Kleinschreibung egal).
	# Parameter:    $1 Name, $2 Wert
	# Rueckgabewert: keines
	# Fehlerfaelle: anderer Wert -> Exit 2
	# Beispiel:     validiere_ja_nein CFG_ZEIGE_CPU ja
	#
	case "${2,,}" in
		ja|nein) return 0 ;;
	esac
	beende_mit_fehler 2 "$1 muss ja oder nein sein (ist: $2)"
}

validiere_farbe() {
	#
	# Beschreibung: Prueft eine Conky-Farbangabe (Name oder Hex).
	# Parameter:    $1 Name, $2 Wert
	# Rueckgabewert: keines
	# Fehlerfaelle: ungueltige Zeichen -> Exit 2
	# Beispiel:     validiere_farbe CFG_SCHRIFTFARBE white
	#
	case "$2" in
		''|*[!#A-Za-z0-9]*)
			beende_mit_fehler 2 "$1 enthaelt ungueltige Zeichen (ist: $2)"
			;;
	esac
}

validiere_position() {
	#
	# Beschreibung: Prueft die Positionsangabe (deutsch oder Conky-Englisch).
	# Parameter:    $1 Wert
	# Rueckgabewert: keines
	# Fehlerfaelle: unbekannte Position -> Exit 2
	# Beispiel:     validiere_position unten_rechts
	#
	case "$1" in
		oben_links|oben_rechts|unten_links|unten_rechts) return 0 ;;
		top_left|top_right|bottom_left|bottom_right) return 0 ;;
	esac
	beende_mit_fehler 2 "CFG_POSITION ungueltig: $1"
}

conky_alignment() {
	#
	# Beschreibung: Mappt die Tabellenposition auf Conky-alignment.
	# Parameter:    keine (liest CFG_POSITION)
	# Rueckgabewert: top_left / top_right / bottom_left / bottom_right
	# Fehlerfaelle: unbekannter Wert -> leer
	# Beispiel:     conky_alignment
	#
	case "$CFG_POSITION" in
		oben_links|top_left) echo top_left ;;
		oben_rechts|top_right) echo top_right ;;
		unten_links|bottom_left) echo bottom_left ;;
		unten_rechts|bottom_right) echo bottom_right ;;
	esac
}

validiere_netzwerkname() {
	#
	# Beschreibung: Prueft einen Interface-Namen (auto oder z. B. wlan0).
	# Parameter:    $1 Feldname, $2 Wert
	# Rueckgabewert: keines
	# Fehlerfaelle: ungueltiger Name -> Exit 2
	# Beispiel:     validiere_netzwerkname CFG_NETZWERK wlan0
	#
	local name="$1" wert="$2"
	if [ "$wert" = "auto" ]; then
		return 0
	fi
	case "$wert" in
		''|*[!A-Za-z0-9._]*) beende_mit_fehler 2 "$name ungueltig: $wert" ;;
	esac
}

validiere_konfiguration() {
	#
	# Beschreibung: Prueft alle Felder der Konfigurationstabelle.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: erster Fehler beendet mit Code 2
	# Beispiel:     validiere_konfiguration
	#
	local name
	validiere_position "$CFG_POSITION"
	validiere_ganzzahl CFG_GAP_X "$CFG_GAP_X" 0 4000
	validiere_ganzzahl CFG_GAP_Y "$CFG_GAP_Y" 0 4000
	validiere_ganzzahl CFG_SCHRIFTGROESSE "$CFG_SCHRIFTGROESSE" 6 48
	validiere_ganzzahl CFG_TRANSPARENZ "$CFG_TRANSPARENZ" 0 255
	validiere_ganzzahl CFG_INTERVALL "$CFG_INTERVALL" 1 60
	validiere_ganzzahl CFG_MIN_BREITE "$CFG_MIN_BREITE" 80 2000
	validiere_ganzzahl CFG_SPALTE "$CFG_SPALTE" 40 400
	validiere_farbe CFG_SCHRIFTFARBE "$CFG_SCHRIFTFARBE"
	validiere_farbe CFG_TITELFARBE "$CFG_TITELFARBE"
	validiere_farbe CFG_HINTERGRUND "$CFG_HINTERGRUND"
	validiere_netzwerkname CFG_NETZWERK "$CFG_NETZWERK"
	validiere_netzwerkname CFG_LAN_IFACE "$CFG_LAN_IFACE"
	case "$CFG_FENSTERTYP" in
		normal|desktop|override|dock|panel) ;;
		*) beende_mit_fehler 2 "CFG_FENSTERTYP ungueltig: $CFG_FENSTERTYP" ;;
	esac
	[ -n "$CFG_SCHRIFTART" ] || beende_mit_fehler 2 "CFG_SCHRIFTART darf nicht leer sein"
	case "$CFG_SCHRIFTART" in
		*"'"*) beende_mit_fehler 2 "CFG_SCHRIFTART darf keine einfachen Anfuehrungszeichen enthalten." ;;
	esac
	for name in CFG_ZEIGE_HOSTNAME CFG_ZEIGE_UHRZEIT CFG_ZEIGE_UPTIME \
		CFG_ZEIGE_CPU CFG_ZEIGE_LOAD CFG_ZEIGE_RAM CFG_ZEIGE_DISK \
		CFG_ZEIGE_TEMPERATUR CFG_ZEIGE_IPV4 CFG_ZEIGE_IPV6 \
		CFG_ZEIGE_WLAN CFG_ZEIGE_SIGNAL CFG_ZEIGE_NETZLAST CFG_ZEIGE_LAN; do
		validiere_ja_nein "$name" "${!name}"
	done
}

# =============================================================================
# System- und Benutzerermittlung
# =============================================================================

pruefe_root_wenn_noetig() {
	#
	# Beschreibung: Verlangt root fuer Install und Deinstall.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: nicht root -> Exit 1
	# Beispiel:     pruefe_root_wenn_noetig
	#
	if [ "$nur_pruefen" = "true" ] || [ "$dry_run" = "true" ]; then
		return 0
	fi
	if ist_root; then
		return 0
	fi
	beende_mit_fehler 1 "Bitte mit sudo ausfuehren (siehe --help)."
}

setze_logdatei() {
	#
	# Beschreibung: Legt den Logpfad fest (Systemlog als root).
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Verzeichnis nicht beschreibbar
	# Beispiel:     setze_logdatei
	#
	if [ "$logging_aktiv" != "true" ]; then
		return 0
	fi
	if ist_root; then
		LOGDATEI="/var/log/${DEFAULT_LOGFILE}"
	else
		LOGDATEI="./${DEFAULT_LOGFILE}"
	fi
}

ist_virtuelle_iface() {
	#
	# Beschreibung: Erkennt virtuelle oder interne Schnittstellen.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: 0 wenn virtuell, sonst 1
	# Fehlerfaelle: keine
	# Beispiel:     ist_virtuelle_iface docker0
	#
	case "$1" in
		lo|docker*|veth*|virbr*|br-*|tun*|tap*|wg*|tailscale*|zt*) return 0 ;;
		vmnet*|vboxnet*|dummy*|bond*|sit*|gre*) return 0 ;;
	esac
	return 1
}

ist_wlan_geraet() {
	#
	# Beschreibung: Prueft, ob eine Schnittstelle ein WLAN-Geraet ist.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: 0 wenn WLAN, sonst 1
	# Fehlerfaelle: Sysfs fehlt -> 1
	# Beispiel:     ist_wlan_geraet wlan0
	#
	[ -d "/sys/class/net/${1}/wireless" ] || [ -d "/sys/class/net/${1}/phy80211" ]
}

ist_lan_geraet() {
	#
	# Beschreibung: Prueft, ob eine Schnittstelle kabelgebundenes Ethernet ist.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: 0 wenn LAN, sonst 1
	# Fehlerfaelle: Sysfs fehlt -> 1
	# Beispiel:     ist_lan_geraet end0
	#
	local typ
	[ -d "/sys/class/net/${1}" ] || return 1
	ist_virtuelle_iface "$1" && return 1
	ist_wlan_geraet "$1" && return 1
	typ="$(cat "/sys/class/net/${1}/type" 2>/dev/null || echo 0)"
	[ "$typ" = "1" ]
}

iface_ist_up() {
	#
	# Beschreibung: Prueft den operstate einer Schnittstelle.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: 0 wenn up, sonst 1
	# Fehlerfaelle: Datei fehlt -> 1
	# Beispiel:     iface_ist_up eth0
	#
	[ "$(cat "/sys/class/net/${1}/operstate" 2>/dev/null || true)" = "up" ]
}

finde_wlan_iface() {
	#
	# Beschreibung: Findet die WLAN-Schnittstelle (wlan0 bevorzugt).
	# Parameter:    keine
	# Rueckgabewert: Interface-Name auf stdout, Exit 1 wenn keine
	# Fehlerfaelle: kein wireless/phy80211
	# Beispiel:     finde_wlan_iface
	#
	local pfad iface erster=""
	if ist_wlan_geraet "wlan0"; then
		printf '%s\n' "wlan0"
		return 0
	fi
	for pfad in /sys/class/net/*/wireless /sys/class/net/*/phy80211; do
		[ -e "$pfad" ] || continue
		iface="$(basename "$(dirname "$pfad")")"
		[ -z "$erster" ] && erster="$iface"
		if iface_ist_up "$iface"; then
			printf '%s\n' "$iface"
			return 0
		fi
	done
	[ -n "$erster" ] && { printf '%s\n' "$erster"; return 0; }
	return 1
}

finde_lan_iface() {
	#
	# Beschreibung: Findet die LAN-Karte (end0/eth0, sonst erstes Ethernet).
	# Parameter:    keine
	# Rueckgabewert: Interface-Name auf stdout, Exit 1 wenn keine
	# Fehlerfaelle: kein Ethernet im Sysfs
	# Beispiel:     finde_lan_iface
	#
	local pfad iface erster=""
	for iface in end0 eth0 eno1; do
		if ist_lan_geraet "$iface"; then
			printf '%s\n' "$iface"
			return 0
		fi
	done
	for pfad in /sys/class/net/*; do
		[ -e "$pfad" ] || continue
		iface="$(basename "$pfad")"
		ist_lan_geraet "$iface" || continue
		[ -z "$erster" ] && erster="$iface"
		if iface_ist_up "$iface"; then
			printf '%s\n' "$iface"
			return 0
		fi
	done
	[ -n "$erster" ] && { printf '%s\n' "$erster"; return 0; }
	return 1
}

waehle_iface() {
	#
	# Beschreibung: Nimmt Vorgabe, wenn vorhanden, sonst Auto-Erkennung.
	# Parameter:    $1 Vorgabe (auto|Name), $2 Art (wlan|lan)
	# Rueckgabewert: Interface-Name auf stdout oder leer
	# Fehlerfaelle: Vorgabe fehlt im Sysfs -> Warnung und Auto
	# Beispiel:     waehle_iface auto lan
	#
	local vorgabe="$1" art="$2" gefunden=""
	if [ "$vorgabe" != "auto" ]; then
		if [ -d "/sys/class/net/${vorgabe}" ]; then
			printf '%s\n' "$vorgabe"
			return 0
		fi
		warn_meldung "${art}-Vorgabe ${vorgabe} nicht gefunden, suche automatisch."
	fi
	if [ "$art" = "wlan" ]; then
		gefunden="$(finde_wlan_iface || true)"
	else
		gefunden="$(finde_lan_iface || true)"
	fi
	printf '%s\n' "$gefunden"
}

ermittle_schnittstellen() {
	#
	# Beschreibung: Ermittelt WLAN- und LAN-Interface getrennt.
	# Parameter:    keine
	# Rueckgabewert: keines (WLAN_IFACE, LAN_IFACE, NETZ_IFACE)
	# Fehlerfaelle: fehlende Karte -> Warnung, leerer Name
	# Beispiel:     ermittle_schnittstellen
	#
	WLAN_IFACE="$(waehle_iface "$CFG_NETZWERK" wlan)"
	LAN_IFACE="$(waehle_iface "$CFG_LAN_IFACE" lan)"
	NETZ_IFACE="$WLAN_IFACE"
	if [ -z "$WLAN_IFACE" ]; then
		warn_meldung "Keine WLAN-Schnittstelle erkannt."
	elif [ "$dry_run" != "true" ]; then
		info_meldung "WLAN-Schnittstelle: ${WLAN_IFACE}"
	fi
	if [ -z "$LAN_IFACE" ]; then
		warn_meldung "Keine LAN-Schnittstelle erkannt."
	elif [ "$dry_run" != "true" ]; then
		info_meldung "LAN-Schnittstelle: ${LAN_IFACE}"
	fi
}

erster_normaluser() {
	#
	# Beschreibung: Erster lokaler Benutzer mit UID >= 1000.
	# Parameter:    keine
	# Rueckgabewert: Loginname auf stdout oder leer
	# Fehlerfaelle: getent fehlt
	# Beispiel:     erster_normaluser
	#
	getent passwd | awk -F: '$3 >= 1000 && $3 < 65534 { print $1; exit }'
}

ermittle_zielbenutzer() {
	#
	# Beschreibung: Desktop-Benutzer fuer Home-Config und Conky-Prozess.
	# Parameter:    keine
	# Rueckgabewert: keines (setzt ZIEL_USER, ZIEL_HOME)
	# Fehlerfaelle: kein Benutzer -> Exit 1
	# Beispiel:     ermittle_zielbenutzer
	#
	local kandidat home
	if [ -n "$ziel_user_cli" ]; then
		kandidat="$ziel_user_cli"
	elif [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
		kandidat="$SUDO_USER"
	else
		kandidat="$(erster_normaluser)"
	fi
	[ -n "$kandidat" ] || beende_mit_fehler 1 "Kein Desktop-Benutzer gefunden (--user setzen)."
	case "$kandidat" in
		*[!A-Za-z0-9._-]*) beende_mit_fehler 2 "Ungueltiger Benutzername: $kandidat" ;;
	esac
	home="$(getent passwd "$kandidat" | cut -d: -f6)"
	[ -n "$home" ] && [ -d "$home" ] || beende_mit_fehler 1 "Home von $kandidat nicht gefunden."
	ZIEL_USER="$kandidat"
	ZIEL_HOME="$home"
}

# =============================================================================
# Paketinstallation
# =============================================================================

conky_ist_installiert() {
	#
	# Beschreibung: Prueft, ob das Programm conky im PATH liegt.
	# Parameter:    keine
	# Rueckgabewert: 0 wenn vorhanden, sonst 1
	# Fehlerfaelle: keine
	# Beispiel:     conky_ist_installiert
	#
	command -v conky >/dev/null 2>&1
}

installiere_paket() {
	#
	# Beschreibung: Installiert ein Debian-Paket nicht-interaktiv.
	# Parameter:    $1 = Paketname
	# Rueckgabewert: 0 bei Erfolg, sonst 1
	# Fehlerfaelle: apt-get scheitert
	# Beispiel:     installiere_paket conky-all
	#
	DEBIAN_FRONTEND=noninteractive apt-get install -y -q "$1"
}

installiere_conky_paket() {
	#
	# Beschreibung: Installiert conky-all oder Fallback-Pakete bei Bedarf.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: kein Paket installierbar -> Exit 1
	# Beispiel:     installiere_conky_paket
	#
	local kandidat
	if conky_ist_installiert; then
		info_meldung "Conky ist bereits installiert ($(conky --version 2>/dev/null | head -n1))."
		paket_durch_uns="nein"
		return 0
	fi
	info_meldung "Conky fehlt – Paketquellen aktualisieren und installieren."
	DEBIAN_FRONTEND=noninteractive apt-get update -qq
	for kandidat in conky-all conky conky-std; do
		if ! apt-cache show "$kandidat" >/dev/null 2>&1; then
			continue
		fi
		if installiere_paket "$kandidat"; then
			paket_durch_uns="ja"
			paketname="$kandidat"
			info_meldung "Paket $kandidat installiert."
			break
		fi
	done
	hash -r || true
	conky_ist_installiert || beende_mit_fehler 1 "Conky konnte nicht installiert werden."
	if ! dpkg -s fonts-dejavu-core >/dev/null 2>&1; then
		installiere_paket fonts-dejavu-core || warn_meldung "Schrift fonts-dejavu-core nicht installiert."
	fi
}

installiere_wlan_werkzeuge() {
	#
	# Beschreibung: Installiert iw/iwgetid, falls WLAN-Bloecke aktiv sind.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: apt scheitert -> Warnung
	# Beispiel:     installiere_wlan_werkzeuge
	#
	ist_ja "$CFG_ZEIGE_WLAN" || ist_ja "$CFG_ZEIGE_SIGNAL" || return 0
	if ! command -v iw >/dev/null 2>&1; then
		installiere_paket iw || warn_meldung "Paket iw nicht installiert (SSID-Fallback)."
	fi
	if ! command -v iwgetid >/dev/null 2>&1; then
		installiere_paket wireless-tools || warn_meldung "Paket wireless-tools nicht installiert."
	fi
}

# =============================================================================
# Conky-Textbausteine
# =============================================================================

anhaengen() {
	#
	# Beschreibung: Haengt eine Zeile an den Conky-Textpuffer an.
	# Parameter:    $1 = Zeile (Conky-Syntax, bereits escaped)
	# Rueckgabewert: keines (CONKY_TEXT)
	# Fehlerfaelle: keine
	# Beispiel:     anhaengen '${hr}'
	#
	CONKY_TEXT="${CONKY_TEXT}${1}"$'\n'
}

goto_wert() {
	#
	# Beschreibung: Liefert das Conky-Goto fuer die Wertespalte.
	# Parameter:    keine
	# Rueckgabewert: ${goto N} als Text
	# Fehlerfaelle: keine
	# Beispiel:     goto_wert
	#
	printf '${goto %s}' "$CFG_SPALTE"
}

farbe_titel() {
	#
	# Beschreibung: Conky-Farbwechsel auf Titelfarbe.
	# Parameter:    keine
	# Rueckgabewert: ${color TITEL}
	# Fehlerfaelle: keine
	# Beispiel:     farbe_titel
	#
	printf '${color %s}' "$CFG_TITELFARBE"
}

farbe_normal() {
	#
	# Beschreibung: Setzt die Conky-Farbe auf den Standard zurueck.
	# Parameter:    keine
	# Rueckgabewert: ${color}
	# Fehlerfaelle: keine
	# Beispiel:     farbe_normal
	#
	printf '${color}'
}

zeile_label_wert() {
	#
	# Beschreibung: Eine Beschriftung plus Wert in der Wertespalte.
	# Parameter:    $1 Label, $2 Conky-Ausdruck fuer den Wert
	# Rueckgabewert: keines (anhaengt)
	# Fehlerfaelle: keine
	# Beispiel:     zeile_label_wert Uptime '${uptime}'
	#
	anhaengen "$(farbe_titel)${1}$(farbe_normal)$(goto_wert)${2}"
}

baustein_hostname() {
	#
	# Beschreibung: Zentrierter Rechnername als Ueberschrift.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     baustein_hostname
	#
	local groesser
	ist_ja "$CFG_ZEIGE_HOSTNAME" || return 0
	groesser=$((CFG_SCHRIFTGROESSE + 2))
	anhaengen "\${alignc}\${font ${CFG_SCHRIFTART}:size=${groesser}}\${nodename}\${font}"
	anhaengen "\${hr}"
}

baustein_uhr_uptime() {
	#
	# Beschreibung: Datum/Uhrzeit und Systemlaufzeit.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     baustein_uhr_uptime
	#
	if ist_ja "$CFG_ZEIGE_UHRZEIT"; then
		zeile_label_wert "Zeit" "\${time %Y-%m-%d %H:%M:%S}"
	fi
	if ist_ja "$CFG_ZEIGE_UPTIME"; then
		zeile_label_wert "Uptime" "\${uptime}"
	fi
}

baustein_cpu() {
	#
	# Beschreibung: CPU-Auslastung, Balken und optional Load.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     baustein_cpu
	#
	if ist_ja "$CFG_ZEIGE_CPU"; then
		zeile_label_wert "CPU" "\${cpu cpu0}% \${cpubar 6,110}"
	fi
	if ist_ja "$CFG_ZEIGE_LOAD"; then
		zeile_label_wert "Load" "\${loadavg}"
	fi
}

baustein_ram_disk() {
	#
	# Beschreibung: RAM- und Root-Dateisystembelegung.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     baustein_ram_disk
	#
	if ist_ja "$CFG_ZEIGE_RAM"; then
		zeile_label_wert "RAM" "\${mem} / \${memmax} (\${memperc}%)"
	fi
	if ist_ja "$CFG_ZEIGE_DISK"; then
		zeile_label_wert "Disk /" "\${fs_used /} / \${fs_size /} (\${fs_used_perc /}%)"
	fi
}

baustein_temperatur() {
	#
	# Beschreibung: SoC-Temperatur aus thermal_zone0 (Raspberry-tauglich).
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Zone fehlt zur Laufzeit -> Conky zeigt leer
	# Beispiel:     baustein_temperatur
	#
	local label="Temp"
	ist_ja "$CFG_ZEIGE_TEMPERATUR" || return 0
	if ist_raspberry; then
		label="SoC"
	fi
	zeile_label_wert "$label" "\${execi 5 awk '{printf \"%.1f\", \$1/1000}' /sys/class/thermal/thermal_zone0/temp} °C"
}

zeile_ipv4() {
	#
	# Beschreibung: IPv4-Zeile fuer eine Schnittstelle, falls eingeschaltet.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: keines
	# Fehlerfaelle: Interface unbekannt -> Conky zeigt n/a
	# Beispiel:     zeile_ipv4 wlan0
	#
	ist_ja "$CFG_ZEIGE_IPV4" || return 0
	zeile_label_wert "IPv4" "\${addr ${1}}"
}

zeile_ipv6() {
	#
	# Beschreibung: Globale IPv6-Zeile fuer eine Schnittstelle.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: keines
	# Fehlerfaelle: keine globale Adresse -> leer
	# Beispiel:     zeile_ipv6 eth0
	#
	ist_ja "$CFG_ZEIGE_IPV6" || return 0
	zeile_label_wert "IPv6" "\${execi 15 ip -6 -o addr show dev ${1} scope global 2>/dev/null | awk '{gsub(/\\/.*/,\"\",\$4); print \$4; exit}'}"
}

zeile_traffic() {
	#
	# Beschreibung: Down-/Upload einer Schnittstelle, falls eingeschaltet.
	# Parameter:    $1 = Interface-Name
	# Rueckgabewert: keines
	# Fehlerfaelle: Interface unbekannt -> Conky zeigt 0
	# Beispiel:     zeile_traffic wlan0
	#
	ist_ja "$CFG_ZEIGE_NETZLAST" || return 0
	[ -n "$1" ] || return 0
	zeile_label_wert "Traffic" "down \${downspeed ${1}}  up \${upspeed ${1}}"
}

baustein_wlan() {
	#
	# Beschreibung: WLAN-Block: Netz, Signal, IPv4/IPv6, Traffic.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: kein Interface -> Block entfaellt
	# Beispiel:     baustein_wlan
	#
	ist_ja "$CFG_ZEIGE_WLAN" || return 0
	[ -n "$WLAN_IFACE" ] || return 0
	zeile_label_wert "WLAN" "${WLAN_IFACE}"
	zeile_label_wert "Netz" "\${execi 10 iwgetid -r 2>/dev/null || iw dev ${WLAN_IFACE} info 2>/dev/null | awk '/ssid/{print \$2; exit}'}"
	if ist_ja "$CFG_ZEIGE_SIGNAL"; then
		zeile_label_wert "Signal" "\${execi 5 awk -v i=${WLAN_IFACE} '\$1 ~ i { printf \"%d%%\", \$3 * 100 / 70; exit }' /proc/net/wireless 2>/dev/null}"
	fi
	zeile_ipv4 "$WLAN_IFACE"
	zeile_ipv6 "$WLAN_IFACE"
	zeile_traffic "$WLAN_IFACE"
}

baustein_lan() {
	#
	# Beschreibung: LAN-Block: erkannter Name, up/down, IPv4/IPv6, Traffic.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: kein Interface -> Block entfaellt
	# Beispiel:     baustein_lan
	#
	ist_ja "$CFG_ZEIGE_LAN" || return 0
	[ -n "$LAN_IFACE" ] || return 0
	if ist_ja "$CFG_ZEIGE_WLAN" && [ -n "$WLAN_IFACE" ]; then
		anhaengen "\${hr}"
	fi
	zeile_label_wert "LAN" "${LAN_IFACE} \${if_up ${LAN_IFACE}}up\${else}down\${endif}"
	zeile_ipv4 "$LAN_IFACE"
	zeile_ipv6 "$LAN_IFACE"
	zeile_traffic "$LAN_IFACE"
}

baue_conky_text() {
	#
	# Beschreibung: Setzt CONKY_TEXT aus den aktivierten Tabellenfeldern.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     baue_conky_text
	#
	CONKY_TEXT=""
	baustein_hostname
	baustein_uhr_uptime
	baustein_cpu
	baustein_ram_disk
	baustein_temperatur
	if ist_ja "$CFG_ZEIGE_WLAN" || ist_ja "$CFG_ZEIGE_LAN"; then
		anhaengen "\${hr}"
	fi
	baustein_wlan
	baustein_lan
}

lua_bool_transparent() {
	#
	# Beschreibung: own_window_transparent nur bei Transparenz 0.
	# Parameter:    keine
	# Rueckgabewert: true oder false
	# Fehlerfaelle: keine
	# Beispiel:     lua_bool_transparent
	#
	if [ "$CFG_TRANSPARENZ" -eq 0 ]; then
		echo true
	else
		echo false
	fi
}

erzeuge_conky_config() {
	#
	# Beschreibung: Schreibt die Lua-Conky-Config auf stdout.
	# Parameter:    keine
	# Rueckgabewert: vollstaendige Config auf stdout
	# Fehlerfaelle: Alignment unbekannt
	# Beispiel:     erzeuge_conky_config > conky.conf
	#
	local alignment trans
	alignment="$(conky_alignment)"
	trans="$(lua_bool_transparent)"
	baue_conky_text
	cat << EOF
-- ${MARKER} ${VERSION} – automatisch erzeugt, nicht von Hand pflegen
-- Stand: ${VERSION_DATUM}
-- Netz: ${NETZ_IFACE}  WLAN: ${WLAN_IFACE}  LAN: ${LAN_IFACE}  Position: ${CFG_POSITION}

conky.config = {
    alignment = '${alignment}',
    background = false,
    border_inner_margin = 4,
    border_width = 0,
    cpu_avg_samples = 2,
    default_color = '${CFG_SCHRIFTFARBE}',
    default_outline_color = '${CFG_SCHRIFTFARBE}',
    default_shade_color = 'black',
    double_buffer = true,
    draw_borders = false,
    draw_graph_borders = true,
    draw_outline = false,
    draw_shades = false,
    extra_newline = false,
    font = '${CFG_SCHRIFTART}:size=${CFG_SCHRIFTGROESSE}',
    format_human_readable = true,
    gap_x = ${CFG_GAP_X},
    gap_y = ${CFG_GAP_Y},
    minimum_height = 5,
    minimum_width = ${CFG_MIN_BREITE},
    maximum_width = ${CFG_MIN_BREITE},
    net_avg_samples = 2,
    no_buffers = true,
    out_to_console = false,
    out_to_stderr = false,
    out_to_x = true,
    own_window = true,
    own_window_argb_value = ${CFG_TRANSPARENZ},
    own_window_argb_visual = true,
    own_window_class = '${MARKER}',
    own_window_colour = '${CFG_HINTERGRUND}',
    own_window_hints = 'undecorated,below,sticky,skip_taskbar,skip_pager',
    own_window_transparent = ${trans},
    own_window_type = '${CFG_FENSTERTYP}',
    short_units = true,
    stippled_borders = 0,
    update_interval = ${CFG_INTERVALL},
    uppercase = false,
    use_spacer = 'none',
    use_xft = true,
}

conky.text = [[
${CONKY_TEXT}]]
EOF
}

# =============================================================================
# Dateien, Autostart, Dienst
# =============================================================================

merke_datei() {
	#
	# Beschreibung: Traegt einen Pfad in die Deinstallationsliste ein.
	# Parameter:    $1 = Pfad
	# Rueckgabewert: keines
	# Fehlerfaelle: Dateiliste nicht schreibbar
	# Beispiel:     merke_datei /etc/conky/conky.conf
	#
	mkdir -p "$STATE_DIR"
	if [ -f "$DATEILISTE" ] && grep -Fxq "$1" "$DATEILISTE"; then
		return 0
	fi
	printf '%s\n' "$1" >> "$DATEILISTE"
}

sichere_etc_conky() {
	#
	# Beschreibung: Sichert die Original-Systemconfig einmalig.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Kopieren scheitert -> Warnung
	# Beispiel:     sichere_etc_conky
	#
	if [ -f "$ETC_CONKY_CONF" ] && [ ! -f "$ETC_CONKY_BACKUP" ]; then
		if ! grep -q "$MARKER" "$ETC_CONKY_CONF" 2>/dev/null; then
			cp -a "$ETC_CONKY_CONF" "$ETC_CONKY_BACKUP"
			info_meldung "Original gesichert: $ETC_CONKY_BACKUP"
		fi
	fi
}

stelle_etc_conky_wieder_her() {
	#
	# Beschreibung: Stellt /etc/conky/conky.conf wieder her oder loescht unsere Datei.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Backup fehlt
	# Beispiel:     stelle_etc_conky_wieder_her
	#
	if [ -f "$ETC_CONKY_BACKUP" ]; then
		mv -f "$ETC_CONKY_BACKUP" "$ETC_CONKY_CONF"
		info_meldung "Original-Config zurueck: $ETC_CONKY_CONF"
		return 0
	fi
	if [ -f "$ETC_CONKY_CONF" ] && grep -q "$MARKER" "$ETC_CONKY_CONF" 2>/dev/null; then
		rm -f "$ETC_CONKY_CONF"
	fi
}

schreibe_datei_als() {
	#
	# Beschreibung: Schreibt stdin in eine Datei mit Besitzer und Modus.
	# Parameter:    $1 Pfad, $2 User, $3 Gruppe, $4 Modus
	# Rueckgabewert: keines
	# Fehlerfaelle: install scheitert -> Exit 1
	# Beispiel:     erzeuge_conky_config | schreibe_datei_als pfad user group 644
	#
	local ziel="$1" user="$2" gruppe="$3" modus="$4" tmp
	tmp="$(mktemp)"
	cat > "$tmp"
	install -d -o "$user" -g "$gruppe" -m 755 "$(dirname "$ziel")"
	install -o "$user" -g "$gruppe" -m "$modus" "$tmp" "$ziel"
	rm -f "$tmp"
	merke_datei "$ziel"
}

user_conky_conf() {
	#
	# Beschreibung: Pfad der benutzerspezifischen Conky-Config.
	# Parameter:    keine
	# Rueckgabewert: Pfad auf stdout
	# Fehlerfaelle: keine
	# Beispiel:     user_conky_conf
	#
	printf '%s\n' "${ZIEL_HOME}/.config/conky/conky.conf"
}

user_autostart() {
	#
	# Beschreibung: Pfad der Autostart-Desktopdatei.
	# Parameter:    keine
	# Rueckgabewert: Pfad auf stdout
	# Fehlerfaelle: keine
	# Beispiel:     user_autostart
	#
	printf '%s\n' "${ZIEL_HOME}/.config/autostart/${MARKER}.desktop"
}

schreibe_autostart() {
	#
	# Beschreibung: Desktop-Autostart, damit Conky nach Login startet.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Datei nicht schreibbar
	# Beispiel:     schreibe_autostart
	#
	local conf desktop gruppe
	conf="$(user_conky_conf)"
	desktop="$(user_autostart)"
	gruppe="$(id -gn "$ZIEL_USER")"
	schreibe_datei_als "$desktop" "$ZIEL_USER" "$gruppe" 644 << EOF
[Desktop Entry]
Type=Application
Name=Conky (${MARKER})
Comment=Systemmonitor install-conky
Exec=/bin/sh -c "sleep 8; exec /usr/bin/conky -c '${conf}' -d"
Terminal=false
StartupNotify=false
Hidden=false
X-GNOME-Autostart-enabled=true
EOF
}

schreibe_state() {
	#
	# Beschreibung: Speichert, ob das Skript das Conky-Paket selbst holte.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: State-Verzeichnis nicht schreibbar
	# Beispiel:     schreibe_state
	#
	mkdir -p "$STATE_DIR"
	cat > "$STATE_DATEI" << EOF
PAKET_DURCH_UNS=${paket_durch_uns}
PAKETNAME=${paketname}
ZIEL_USER=${ZIEL_USER}
INST_VERSION=${VERSION}
EOF
	chmod 644 "$STATE_DATEI"
	merke_datei "$STATE_DATEI"
	merke_datei "$DATEILISTE"
}

schreibe_configs() {
	#
	# Beschreibung: Schreibt System- und Benutzer-Conky-Config.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Schreiben scheitert
	# Beispiel:     schreibe_configs
	#
	local gruppe conf
	gruppe="$(id -gn "$ZIEL_USER")"
	conf="$(user_conky_conf)"
	sichere_etc_conky
	erzeuge_conky_config | schreibe_datei_als "$ETC_CONKY_CONF" root root 644
	# Systemdatei nicht ueber die Loeschliste entfernen (Backup/Marker).
	if [ -f "$DATEILISTE" ]; then
		grep -Fxv "$ETC_CONKY_CONF" "$DATEILISTE" > "${DATEILISTE}.tmp" || true
		mv "${DATEILISTE}.tmp" "$DATEILISTE"
	fi
	erzeuge_conky_config | schreibe_datei_als "$conf" "$ZIEL_USER" "$gruppe" 644
	schreibe_autostart
	schreibe_state
	info_meldung "Config geschrieben: $conf"
	info_meldung "WLAN ${WLAN_IFACE:-(keine)}, LAN ${LAN_IFACE:-(keine)}, Position ${CFG_POSITION}."
}

stoppe_conky() {
	#
	# Beschreibung: Beendet Conky-Prozesse des Zielbenutzers.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: pkill Exit 1 wenn kein Prozess – wird ignoriert
	# Beispiel:     stoppe_conky
	#
	if [ -n "${ZIEL_USER:-}" ]; then
		pkill -u "$ZIEL_USER" -x conky 2>/dev/null || true
	else
		pkill -x conky 2>/dev/null || true
	fi
	sleep 1
}

display_fuer_user() {
	#
	# Beschreibung: DISPLAY der grafischen Sitzung oder Fallback :0.
	# Parameter:    keine
	# Rueckgabewert: Display-String auf stdout
	# Fehlerfaelle: Fallback :0
	# Beispiel:     display_fuer_user
	#
	local disp
	disp="$(who | awk -v u="$ZIEL_USER" '$1 == u && $2 ~ /^:/ { print $2; exit }')"
	if [ -n "$disp" ]; then
		printf '%s\n' "$disp"
		return 0
	fi
	printf '%s\n' "${DISPLAY:-:0}"
}

starte_conky() {
	#
	# Beschreibung: Startet Conky als Desktop-Benutzer (daemon).
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: kein X11 -> Warnung, Autostart bleibt
	# Beispiel:     starte_conky
	#
	local conf display xauth
	conf="$(user_conky_conf)"
	display="$(display_fuer_user)"
	xauth="${ZIEL_HOME}/.Xauthority"
	if [ ! -S /tmp/.X11-unix/X0 ] && [ ! -S /tmp/.X11-unix/X1 ]; then
		warn_meldung "Keine X11-Sitzung erkannt. Conky startet beim naechsten Desktop-Login."
		warn_meldung "Unter Wayland eine X11-Sitzung waehlen oder labwc/X11 pruefen."
		return 0
	fi
	info_meldung "Starte Conky fuer ${ZIEL_USER} auf ${display}."
	sudo -u "$ZIEL_USER" env DISPLAY="$display" XAUTHORITY="$xauth" \
		/usr/bin/conky -c "$conf" -d || warn_meldung "Conky-Start fehlgeschlagen (Display/Wayland?)."
}

# =============================================================================
# Deinstallation
# =============================================================================

lade_state() {
	#
	# Beschreibung: Liest gespeicherten Installationszustand, falls vorhanden.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: fehlende Datei wird ignoriert
	# Beispiel:     lade_state
	#
	if [ -f "$STATE_DATEI" ]; then
		# shellcheck disable=SC1090
		. "$STATE_DATEI"
		paket_durch_uns="${PAKET_DURCH_UNS:-nein}"
		paketname="${PAKETNAME:-}"
		if [ -z "$ziel_user_cli" ] && [ -n "${ZIEL_USER:-}" ]; then
			ziel_user_cli="$ZIEL_USER"
		fi
	fi
}

bestateige_deinstall() {
	#
	# Beschreibung: Rueckfrage vor dem Entfernen, ausser --yes.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: Abbruch durch Nutzer -> Exit 0
	# Beispiel:     bestateige_deinstall
	#
	local antwort
	if [ "$auto_ja" = "true" ]; then
		return 0
	fi
	if [ ! -t 0 ]; then
		beende_mit_fehler 2 "Deinstallation ohne TTY erfordert --yes."
	fi
	printf '%s' "install-conky: Einrichtung wirklich entfernen? [j/N] "
	read -r antwort || true
	case "${antwort,,}" in
		j|ja|y|yes) return 0 ;;
	esac
	info_meldung "Abgebrochen."
	beende 0
}

entferne_dateiliste() {
	#
	# Beschreibung: Loescht die vom Skript angelegten Dateien.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: einzelne Dateien unloeschbar -> Warnung
	# Beispiel:     entferne_dateiliste
	#
	local pfad
	if [ ! -f "$DATEILISTE" ]; then
		rm -f "$(user_conky_conf)" "$(user_autostart)" || true
		return 0
	fi
	while IFS= read -r pfad; do
		[ -n "$pfad" ] || continue
		if [ -e "$pfad" ]; then
			rm -f "$pfad" || warn_meldung "Konnte nicht loeschen: $pfad"
		fi
	done < "$DATEILISTE"
}

entferne_paket_wenn_unser() {
	#
	# Beschreibung: Entfernt Conky per apt nur, wenn wir es installiert haben.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: apt-get remove scheitert -> Warnung
	# Beispiel:     entferne_paket_wenn_unser
	#
	if [ "$paket_durch_uns" != "ja" ]; then
		info_meldung "Conky-Paket bleibt erhalten (war bereits installiert)."
		return 0
	fi
	if [ -z "$paketname" ]; then
		paketname="conky-all"
	fi
	info_meldung "Entferne Paket $paketname."
	DEBIAN_FRONTEND=noninteractive apt-get remove --purge -y -q "$paketname" \
		|| warn_meldung "Paket $paketname konnte nicht entfernt werden."
}

deinstalliere() {
	#
	# Beschreibung: Stoppt Conky, entfernt Config/Autostart, optional Paket.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: siehe Teilschritte
	# Beispiel:     deinstalliere
	#
	lade_state
	ermittle_zielbenutzer
	bestateige_deinstall
	info_meldung "Deinstallation fuer Benutzer ${ZIEL_USER}."
	stoppe_conky
	entferne_dateiliste
	stelle_etc_conky_wieder_her
	entferne_paket_wenn_unser
	rm -rf "$STATE_DIR"
	info_meldung "Deinstallation abgeschlossen. Dieses Skript bleibt erhalten."
}

# =============================================================================
# Hauptprogramm
# =============================================================================

hauptschleife() {
	#
	# Beschreibung: Orchestriert Pruefung, Installation oder Deinstallation.
	# Parameter:    keine
	# Rueckgabewert: keines
	# Fehlerfaelle: zentrale beende_mit_fehler
	# Beispiel:     hauptschleife
	#
	validiere_konfiguration
	if [ "$nur_pruefen" = "true" ]; then
		info_meldung "Konfigurationstabelle ist gueltig."
		return 0
	fi
	ermittle_schnittstellen
	if [ "$dry_run" = "true" ]; then
		erzeuge_conky_config
		return 0
	fi
	ist_debian || beende_mit_fehler 1 "Nur Debian / Raspberry Pi OS (apt) wird unterstuetzt."
	if ! ist_raspberry; then
		warn_meldung "Kein Raspberry Pi erkannt – fahre auf Debian fort."
	fi
	ermittle_zielbenutzer
	if [ "$deinstallieren" = "true" ]; then
		deinstalliere
		return 0
	fi
	installiere_conky_paket
	installiere_wlan_werkzeuge
	schreibe_configs
	stoppe_conky
	starte_conky
	info_meldung "Fertig. Tabelle aendern und Skript erneut mit sudo ausfuehren, um neu zu setzen."
}

verarbeite_argumente "$@"
setze_logdatei
pruefe_root_wenn_noetig
if [ "$logging_aktiv" = "true" ]; then
	log_nachricht "START $SKRIPTNAME $VERSION"
fi
hauptschleife
beende 0

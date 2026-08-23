#!/usr/bin/env bash
#
# install-conky – Automatisierte Pruefung von Syntax, CLI und Dateikopf.
#
# Projekt:     install-conky
# Modul:       tests/test_install_conky.sh
# Version:     1.2.0
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
# Prueft install_conky.sh ohne Installation: bash -n, --help, --version,
# --pruefen, unbekannte Option, Pflichtfelder, Defaults, LF-Zeilenenden.
#
# Historie
# --------
# Version 1.0.0 – 2026-08-23 – Erste Testfassung.
# Version 1.1.0 – 2026-08-23 – Defaults Transparenz 90, LAN eth0, Randdocking.
# Version 1.2.0 – 2026-08-23 – WLAN- und ETH0-Bloecke getrennt geprueft.
#
# Aufruf / Nutzung
# ----------------
#   bash tests/test_install_conky.sh
#

set -euo pipefail

VERSION="1.2.0"
VERSION_DATUM="2026-08-23"
fehler=0

repo_wurzel() {
	#
	# Beschreibung: Ermittelt das Projektverzeichnis (Parent von tests/).
	# Parameter:    keine
	# Rueckgabewert: Pfad auf stdout
	# Fehlerfaelle: Fallback .
	# Beispiel:     repo_wurzel
	#
	CDPATH= cd -- "$(dirname -- "$0")/.." 2>/dev/null && pwd || printf '%s\n' "."
}

meld_ok() {
	#
	# Beschreibung: Erfolgsmeldung eines Testschritts.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     meld_ok "help"
	#
	printf 'OK    %s\n' "$1"
}

meld_fail() {
	#
	# Beschreibung: Fehlerzaehler erhoehen und Meldung ausgeben.
	# Parameter:    $1 = Text
	# Rueckgabewert: keines
	# Fehlerfaelle: keine
	# Beispiel:     meld_fail "CR gefunden"
	#
	printf 'FEHLER %s\n' "$1" >&2
	fehler=$((fehler + 1))
}

ROOT="$(repo_wurzel)"
SKRIPT="${ROOT}/install_conky.sh"

cd "$ROOT"

if [ ! -f "$SKRIPT" ]; then
	echo "FEHLER: $SKRIPT fehlt." >&2
	exit 1
fi

if bash -n "$SKRIPT"; then
	meld_ok "bash -n install_conky.sh"
else
	meld_fail "bash -n install_conky.sh"
fi

hilfe="$(bash "$SKRIPT" --help)" || meld_fail "--help Exit-Code"
case "$hilfe" in
	*"install-conky ${VERSION}"*) meld_ok "--help enthaelt Version" ;;
	*) meld_fail "--help ohne Versionszeile" ;;
esac
case "$hilfe" in
	*"--deinstall"*) meld_ok "--help nennt --deinstall" ;;
	*) meld_fail "--help ohne --deinstall" ;;
esac

hilfe2="$(bash "$SKRIPT" --Hilfe)" || meld_fail "--Hilfe Exit-Code"
case "$hilfe2" in
	*"Verwendung:"*) meld_ok "--Hilfe Alias" ;;
	*) meld_fail "--Hilfe ohne Hilfetext" ;;
esac

vers="$(bash "$SKRIPT" --version)" || meld_fail "--version Exit-Code"
case "$vers" in
	*"${VERSION} (${VERSION_DATUM})"*) meld_ok "--version" ;;
	*) meld_fail "--version Inhalt" ;;
esac

if bash "$SKRIPT" --pruefen >/dev/null; then
	meld_ok "--pruefen (Tabelle gueltig)"
else
	meld_fail "--pruefen"
fi

if bash "$SKRIPT" --unbekannt >/dev/null 2>&1; then
	meld_fail "unbekannte Option muss scheitern"
else
	meld_ok "unbekannte Option -> Fehler"
fi

for feld in Projekt Modul Version Stand Abhaengig Bezug Lizenz Upstream Autor; do
	if grep -q "^# ${feld}:" "$SKRIPT"; then
		meld_ok "Dateikopf $feld"
	else
		meld_fail "Dateikopf $feld fehlt"
	fi
done

if grep -q 'Erstellt mit:' "$SKRIPT"; then
	meld_ok "Dateikopf Erstellt mit"
else
	meld_fail "Dateikopf Erstellt mit fehlt"
fi

if grep -q 'CFG_POSITION="unten_rechts"' "$SKRIPT"; then
	meld_ok "Default Position unten_rechts"
else
	meld_fail "Default Position"
fi

if grep -q 'CFG_SCHRIFTFARBE="white"' "$SKRIPT"; then
	meld_ok "Default Schriftfarbe white"
else
	meld_fail "Default Schriftfarbe"
fi

if grep -q 'CFG_TRANSPARENZ="90"' "$SKRIPT"; then
	meld_ok "Default Transparenz 90"
else
	meld_fail "Default Transparenz"
fi

if grep -q 'CFG_GAP_X="0"' "$SKRIPT" && grep -q 'CFG_GAP_Y="0"' "$SKRIPT"; then
	meld_ok "Default Randabstand 0"
else
	meld_fail "Default Randabstand"
fi

if grep -q 'CFG_ZEIGE_LAN="ja"' "$SKRIPT"; then
	meld_ok "Default LAN-Anzeige"
else
	meld_fail "Default LAN-Anzeige"
fi

dry="$(bash "$SKRIPT" --dry-run)" || meld_fail "--dry-run Exit-Code"
case "$dry" in
	*"alignment = 'bottom_right'"*) meld_ok "--dry-run alignment bottom_right" ;;
	*) meld_fail "--dry-run ohne alignment bottom_right" ;;
esac
case "$dry" in
	*"default_color = 'white'"*) meld_ok "--dry-run Schriftfarbe white" ;;
	*) meld_fail "--dry-run ohne default_color white" ;;
esac
case "$dry" in
	*"conky.text = [["*) meld_ok "--dry-run conky.text" ;;
	*) meld_fail "--dry-run ohne conky.text" ;;
esac
case "$dry" in
	*"gap_x = 0"*) meld_ok "--dry-run gap_x 0" ;;
	*) meld_fail "--dry-run ohne gap_x 0" ;;
esac
case "$dry" in
	*"own_window_argb_value = 90"*) meld_ok "--dry-run Transparenz 90" ;;
	*) meld_fail "--dry-run ohne Transparenz 90" ;;
esac
case "$dry" in
	*"own_window_type = 'override'"*) meld_ok "--dry-run Fenstertyp override" ;;
	*) meld_fail "--dry-run ohne Fenstertyp override" ;;
esac
case "$dry" in
	*"ETH0"*) meld_ok "--dry-run ETH0" ;;
	*) meld_fail "--dry-run ohne ETH0" ;;
esac
if printf '%s\n' "$dry" | grep -Fq '${addr eth0}'; then
	meld_ok "--dry-run IPv4 eth0"
else
	meld_fail "--dry-run ohne IPv4 eth0"
fi
if printf '%s\n' "$dry" | grep -q 'downspeed'; then
	meld_fail "--dry-run enthaelt noch Netzlast (downspeed)"
else
	meld_ok "--dry-run ohne doppelte Netzlast"
fi

for datei in install_conky.sh tests/test_install_conky.sh; do
	if grep -q $'\r' "$datei"; then
		meld_fail "CR in $datei (LF erforderlich)"
	else
		meld_ok "LF $datei"
	fi
done

if [ "$fehler" -ne 0 ]; then
	echo "Tests fehlgeschlagen: $fehler" >&2
	exit 1
fi
echo "Alle Tests erfolgreich."
exit 0

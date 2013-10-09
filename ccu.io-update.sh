#!/bin/sh
#set -x # Debug Modus, zum aktivieren das # am Anfang der Zeile entfernen

########################################################################
#Variablen setzen
########################################################################

SCRIPT_NAME=$( basename $0 )
TS=$( date +%Y%m%d%H%M%S )
TMP=/tmp

# Ab hier bitte die Variablnen anpassen
CCUIO_PATH="/usr/local/addons/ccu.io"   # Hier den Pfad angeben in dem sich ccu.io befindet
CCUIO_CMD="sudo /etc/init.d/ccu.io"     # Hier den Aufruf von ccu.io angeben
CCUIO_USER=pi                           # Hier den User angeben unter dem ccu.io laufen soll
CCUIO=1    # CCU.IO installieren = 1
DASHUI=1   # DashUI installieren = 1
CHARTS=1   # CCU-IO-Highcharts installieren = 1
YAHUI=1    # yahui installieren = 1
EVENTLIST=1 # CCU-IO Eventlist installieren = 1

if [ ! ${CCUIO_PATH} ]
then
	echo "Die Variable CCUIO_PATH wurde nicht gesetzt"
	echo "es wird der Standard \"/opt/ccu.io\" genutzt"
	CCUIO_PATH="/opt/ccu.io"
fi
if [ ! "${CCUIO_CMD}" ]
then
	echo "Es wurde kein ccu.io Kommando angegeben"
	echo "es wird der Standard \"node ${CCUIO_PATH}/ccu.io-server.js\" genommen"
	CCUIO_CMD="node ${CCUIO_PATH}/ccu.io-server.js"
fi
if [ ! ${CCUIO_USER} ]
then
	echo "Es wurde kein ccu.io User angegeben"
	echo "Es wird der Standarduser \"root\" verwendet"
	echo "ccu.io sollte nicht unter \"root\" laufen"
        CCUIO_USER="root"
fi

########################################################################
# Funktionen
########################################################################
install ()
{
  ADDON=${1}
  ADDON_PATH=${ADDON}
  if [ ${ADDON} = ccu.io ]
  then
    LINK="https://github.com/hobbyquaker/${ADDON}/archive/master.zip"
  fi
  if [ ${ADDON} = yahui ]
  then
    LINK="https://github.com/hobbyquaker/${ADDON}/archive/master.zip"
  fi
  if [ ${ADDON} = DashUI ]
  then
    ADDON_PATH=dashui
    LINK="https://github.com/hobbyquaker/${ADDON}/archive/master.zip"
  fi
  if [ ${ADDON} = CCU-IO-Highcharts ]
  then 
    ADDON_PATH=charts
    LINK="https://github.com/hobbyquaker/${ADDON}/archive/master.zip"
  fi
  if [ ${ADDON} = CCU-IO.Eventlist ]
  then
    ADDON_PATH=eventlist
    LINK="https://github.com/GermanBluefox/${ADDON}/archive/master.zip"
  fi
  wget ${LINK}
  if [ ${?} != 0 ]
  then
    echo "Fehler beim Download von ${ADDON}"
    echo "Programm beendet sich"
    exit 1
  fi
  mv master.zip ${ADDON}.zip
  unzip ${ADDON}.zip 1>/dev/null
  if [ ${?} != 0 ]
  then
    echo "Fehler beim unzip von ${ADDON}"
    echo "Programm beendet sich"
    exit 1
  fi
  if [ ${ADDON} = ccu.io ]
  then
    cp -Rav ${ADDON}-master/${ADDON_PATH}/* ${CCUIO_PATH} 1>/dev/null
    if [ ${?} != 0 ]
    then
      echo "Fehler beim kopieren von ${ADDON}"
      echo "Programm beendet sich"
      exit 1
    fi
  else
    if [ -d ${CCUIO_PATH}/www/${ADDON_PATH} ]
    then
      cp -Rav ${ADDON}-master/${ADDON_PATH}/* ${CCUIO_PATH}/www/${ADDON_PATH}/ 1>/dev/null
      if [ ${?} != 0 ]
      then
        echo "Fehler beim kopieren von ${ADDON}"
        echo "Programm beendet sich"
        exit 1
      fi
    else
      echo "Bisher war ${ADDON} nicht installiert"
      echo "${ADDON} wird installiert und ist unter <IP>:8080/${ADDON_PATH} erreichbar"
      mkdir ${CCUIO_PATH}/www/${ADDON_PATH}
      if [ ${?} != 0 ]
      then
        echo "Fehler beim erstellen des Verzeichnisses ${CCUIO_PATH}/www/${ADDON_PATH}"
        echo "Programm beendet sich"
        exit 1
      fi
      cp -Rav ${ADDON}-master/${ADDON_PATH}/* ${CCUIO_PATH}/www/${ADDON_PATH}/ 1>/dev/null
      if [ ${?} != 0 ]
      then
        echo "Fehler beim kopieren von ${ADDON}"
        echo "Programm beendet sich"
        exit 1
      fi
    fi
  fi
  rm -R ${ADDON}-master ${ADDON}.zip # Loeschen der Temorären Dateien und Verzeichnisse ${ADDON}-master ${ADDON}.zip
}
########################################################################
# Vorbedingungen pruefen
########################################################################

if [ $( whoami ) != root ]
then
	echo "Das Programm muss als root laufen da es Verzeichnisse anlegt und Rechte anpasst"
	echo "bitte das Script mit \"sudo ${SCRIPT_NAME}\" aufrufen"
  exit 1
fi

cd ${TMP}

# Pruefen ob es noch ein altes master.zip gibt und dieses gegebenenfalls sichern
if [ -f master.zip ]
then
  echo "Altes master.zip gefunden"
  echo "sichere altes master.zip als master.zip.${TS}"
  mv master.zip master.zip.${TS}
fi

# Pruefen ob es eine ccu.io Installation gibt
if [ ! -d ${CCUIO_PATH} ]
then
  echo "Der angegebene Pfad zu CCU.IO existiert nicht."
  echo "Soll der Pfad angelegt und ccu.io installiert werden?"
  echo "YyJj/Nn"
  GUELTIG=0
  while [ ${GUELTIG} != 1 ]
  do
    read ANTWORT
    case "${ANTWORT}" in
      [JjYy])    ERGEBNIS=1; GUELTIG=1 ;;
      [Nn])      ERGEBNIS=0; GUELTIG=1 ;;
      *)         GUELTIG=0 ;;
    esac
  done
  if [ ${ERGEBNIS} = 1 ]
  then
    mkdir -p ${CCUIO_PATH}
    if [ ${?} != 0 ]
    then
      echo "Fehler beim erstellen des Verzeichnisses ${CCUIO_PATH}"
      echo "Programm beendet sich"
      exit 1
    fi
  else
    echo "Die Antwort ist NEIN"
    echo "Dadurch beendet sich das Programm"
    exit
  fi
else
  ${CCUIO_CMD} stop # CCU.IO stoppen
fi

########################################################################
# Hauptprogramm
########################################################################

# Alte CCU.IO Version in /tmp sichern
tar cvfz ${TMP}/ccu.io.${TS}.tar.gz ${CCUIO_PATH} 1>/dev/null
if [ ${?} != 0 ]
then
  echo "Fehler beim erstellen der Sicherung unter ${TMP}/ccu.io.${TS}.tar.gz"
  echo "Programm beendet sich"
  exit 1
else
echo " Der alte Versionsstand von ccu.io wurde unter ${TMP}/ccu.io.${TS}.tar.gz gesichert"
fi

# CCU.IO aktualisieren
if [ ${CCUIO} -eq 1 ]
then
  install ccu.io
fi

# yahui aktualisieren
if [ ${YAHUI} -eq 1 ]
then
  install yahui
fi

# DashUI aktualisieren
if [ ${DASHUI} -eq 1 ]
then
  install DashUI
fi

# CCU-IO-Highcharts aktualisieren
if [ ${CHARTS} -eq 1 ]
then
  install CCU-IO-Highcharts
fi

# CCU-IO.Eventlist aktualisieren
if [ ${EVENTLIST} -eq 1 ]
then
  install CCU-IO.Eventlist
fi

# Rechte auf ${CCUIO_USER} setzen
chown -R ${CCUIO_USER} ${CCUIO_PATH}

# CCU.IO starten
${CCUIO_CMD} start

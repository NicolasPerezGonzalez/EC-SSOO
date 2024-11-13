# !/bin/bash
# infosession.sh [-h] [-z] [-u user]
# default:
#
# 1. Identificador de sesión (sid)
# 2. Identificador del grupo de procesos al que pertenece (pgid)
# 3. Identificador de proceso (pid)
# 4. Nombre de usuario efectivo del proceso (user)
# 5. Identificador de la terminal controladora o ? si no tiene ninguna (tty)
# 6. Porcentaje de memoria consumida por el proceso (%mem)
# 7. Comando que lanzó el proceso (cmd)
#
##### CONSTANTES
LINE="##########################################################################"
SEPARADOR="--------------------------------------------------------------------------"
##### VARIABLES
PROGNAME=""                 # Nombre del programa
INFO=""                     # Variable en la que se almacena el comando para generar la tabla
PAR=""                      # Lista de elementos para las columnas 
AFILTER=""                  # Filtros a utilizar
USUARIOS=""                 # Usuario que acompaña al -u
usuario=""                  # Auxiliar que ayuda a recorrer los usuarios
USERFILTER=""               # Filtro a aplicar debido a los usuarios
DIR=""                      # Directorio a buscar
DIRFILTER=""                # Filtro a aplicar para buscar los procesos del directorio
TABLE=""                    # Almacena la tabla del ps
LEYENDOUSER=0               # Bool que indica si se estan leyendo usuarios o no
TERMINALA=""                # Filtro para eliminar procesos sin terminal asociada
EPROCESS=0                  # Bool que indica si usar
##### VAR SESION TABLE
SESIONT=""                  # Almacena la tabla de sesiones
ITER=""                     # Iterador que recorre la tabla
NEW=1                       # Bool que comprueba si estamos en una sesión nueva o no
PIDL=""                     # Lista de los pid de la tabla

STSID=""                    # Valor auxiliar para el identificador de sesion de la tabla de sesiones
STTSID=1                    # Valor auxiliar para el número de procesos diferentes de esa sesion
STMEM=""                    # Valor auxiliar para el total de porcentaje de memoria consumida por la sesion
STPIDL=""                   # Valor auxiliar para el pid del lider de la sesion
STUSER=""                   # Valor auxiliar para el usuario lider de la sesion
STTTY=""                    # Valor auxiliar para la terminal controladora de la sesion
STCMD=""                    # Comando del proceso lider de la sesion

SM=0                        # Flag que comprueba si se encuentra la opcion -sm
SG=0                        # Flag que comprueba si se encuentra la opcion -sg
INV=0                       # Flag que comprueba si se encuentra la opcion -r
FILTER=""                   # Ordenamiento a seguir
FILTERS=""                  # Ordenamiento a seguir (en la tabla de sesion)

##### VAR MOD
WARN5=0                     # Flag de warning
lineas=""                   # Contador del numero de lineas
FILE5=0                     # Flag que imprime un archivo dado
FILECOUNT=""                # Nombre de ese archivo dado
##### ESTILOS
TEXT_ULINE=$(tput sgr 0 1)
TEXT_BOLD=$(tput bold)
TEXT_RED=$(tput setaf 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)
####### ERRORES


####### FUNCIONES
usage() 
{
    cat << _EOF_ 
This program is disigned to a summary of all the process of the computer
  Options:
    -h                            Display this help message
    -z                            The table display also the process with an sid = 0
    -u [user]                     It displays all the process of that user or users
    -d [dir]                      It shows only the process at "dir"
    -t                            It displays all the process with a tty asociated
    -e                            Displays a table more detailed (not compatible with -sg)
  ----- with bugs ------------------------------------------------------------------------------------------------
    -sm                           It orders by %mem consumed (not compatible with -sg)
    -sg                           It orders by the size of the biggest group (not compatible with -sm and -e)
    -r                            It reverse the order of the table
_EOF_
}
find_dir()
{
  if [ -d $DIR ]; then
    echo "${TEXT_GREEN}Se ha encontrado ${TEXT_BOLD}$DIR${TEXT_RESET}"
    DIRFILTER="| awk '\$3 ~ /^("
    DIRFILTER+=$(lsof +d $DIR | sed '1d' | awk '{print $2}' | uniq | paste -sd '|')
    DIRFILTER+=")$/'"
  else
    echo "${TEXT_RED}${TEXT_BOLD}$DIR${TEXT_RESET} ${TEXT_RED}no se ha encontrado"${TEXT_RESET}
    exit 1
  fi
}
find_users()
{
  if [ -n "$USUARIOS" ]; then 
    auxstart=0
    USERFILTER="| awk '\$4 ~ /^("
    for usuario in $USUARIOS; do
      if grep "^$usuario:" /etc/passwd > /dev/null; then
        if [ "$auxstart" -eq 0 ]; then
          auxstart=1
          USERFILTER+="$usuario"
          echo "${TEXT_GREEN}Usuario ${TEXT_BOLD}$usuario${TEXT_RESET}${TEXT_GREEN} encontrado, se ejecutara ${TEXT_BOLD}$USERFILTER)\$/${TEXT_RESET}"
        else
          USERFILTER+="|$usuario"
          echo "${TEXT_GREEN}Usuario ${TEXT_BOLD}$usuario${TEXT_RESET}${TEXT_GREEN} encontrado, se ejecutara ${TEXT_BOLD}$USERFILTER)\$/${TEXT_RESET}"
        fi
      else
        echo "${TEXT_RED}${TEXT_BOLD}$usuario${TEXT_RESET}${TEXT_RED} no es un usuario existente${TEXT_RESET}"
        exit 1
      fi
    done
    USERFILTER+=")$/'"
  fi
}
system_info()
{
  # Ejecuta ps con los parametros previamente seleccionados
  echo ${LINE}
  echo "Bienvenido a mi programa $0"
  echo
  INFO="ps -eo $PAR --no-headers --sort=user | awk '{print \$1, \$2, \$3, \$4, \$5, \$6, \$7}' $NZFILTER $USERFILTER $DIRFILTER $TERMINALA"
  echo "El comando a ejecutar va a ser:"
  echo "$INFO"
  echo
  TABLE=$(eval $INFO)
}
print_table()
{
  #### Invertimos?
  if [ $INV -eq 1 ]; then
    TABLE=$(echo "$TABLE" | sort -k $FILTER -r)
  else
    #### Ordenamos
    TABLE=$(echo "$TABLE" | sort -k $FILTER)
  fi
  #### Imprimimos
  echo "${TEXT_BOLD}SID  PGID  PID  USER  TTY  %MEM  CMD${TEXT_RESET}"
  echo -e "$TABLE" | column -t
}
#### FUNCIONES TABLA DE SESION
session_table()
{
  #### Elimino Iguales
  TABLE=$(echo "$TABLE" | sort | uniq)
  PIDL=$(echo "$TABLE" | awk '{print $1}')
  for ITER in $PIDL
  do
    #### Primer elemento
    if [ "$STSID" == "$ITER" ]; then
      NEW=0
    else
      STSID="$ITER"
      NEW=1
      STTSID=$(echo "$TABLE" | awk -v filtro="$STSID" '{if ($2 == filtro) count++ } END {print count}')
    fi
    #### Segundo elemento
      #### Se va calculando en el primer elemento
    #### Tercer elemento (mem)
    if [ "$NEW" -eq 1 ]; then
      STMEM=$(echo "$TABLE" | awk -v sid="$STSID" '$1 == sid' | LC_ALL=C awk '{s+=$6} END {print s}')
    fi
    #### Cuarto elemento
    if [ "$NEW" -eq 1 ]; then
      if [ "$STSID" == "$(echo "$TABLE" | awk -v sid=$STSID '$1 == sid' | head -n 1 | awk '{print $3}')" ]; then
        STPIDL="$STSID"
      else
        STPIDL="?"
      fi
    fi
    #### Quinto elemento
    if [ "$NEW" -eq 1 ]; then
      if [ "$STPIDL" == "$STSID" ]; then
        STUSER=$(echo "$TABLE" | awk -v sid=$STSID '$1==sid' | head -n 1 | awk '{print $4}')
      else
        STUSER="?"
      fi
    fi
    #### Sexto elemento
    if [ "$NEW" -eq 1 ]; then
      STTTY=$(echo "$TABLE" | awk -v sid=$STSID '$1==sid' | head -n 1 | awk '{print $5}')
    fi
    #### Septimo elemento
    if [ "$NEW" -eq 1 ]; then
      if [ "$STSID" == "$STPIDL" ]; then
        STCMD=$(echo "$TABLE" | awk -v sid=$STSID '$1==sid' | head -n 1 | awk '{print $7}')
      else
        STCMD="?"
      fi
    fi
    #### Imprimir
    if [ "$NEW" -eq 1 ]; then
      SESIONT+="$STSID $STTSID $STMEM $STPIDL $STUSER $STTTY $STCMD\n"
    fi
  done

  #### Invertimos?
  if [ $INV -eq 1 ]; then
    SESIONT=$(echo "$SESIONT" | sort -k "$FILTERS" -r)
  else
    #### Ordenamos
    SESIONT=$(echo "$SESIONT" | sort -k "$FILTERS")
  fi
  #### Imprimimos
  echo "${TEXT_BOLD}SID Nº TMEM PIDL USERL TTY CMD${TEXT_RESET}"
  echo -e "$SESIONT" | column -t
}
#### MODIFICACIÓN 1
# count_warn()
#{
#  lineas=$(echo "$TABLE" | wc -l)
#  if [ "$lineas" -gt 5 ]; then
#  echo ${LINE}
#    echo "Cuidado, hay mas de 5 procesos"
#  fi
#}
#### MODIFICACIÓN 2
# Si el número de procesos es mayor que 5, despues de mostrar la tabla de procesos,
# se mostrará el archivo FILECOUNT por la salida estandar. No hace falta comprobar
# count_file()
# {
# Comprobamos si hay mas de 5 procesos en la tabla
#  lineas=$( echo "$TABLE" | wc -l)
#  if [ "$lineas" -gt 5 ]; then
#  # mostramos el contenido del archivo en la salida estandar
#    cat "$FILECOUNT"
#  fi
#}
PROGNAME=$(basename "$0")
FILTER=4
FILTERS=5
PAR="sid,pgid,pid,user:20,tty,%mem,cmd"
NZFILTER="| grep -v ^0"
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help)
    LEYENDOUSER=0
    usage
    exit 0
    ;;
    -z)
    LEYENDOUSER=0
    NZFILTER=""
    ;;
    -u)
    LEYENDOUSER=1
    USUARIOS=$2
    shift
    ;;
    -d)
    LEYENDOUSER=0
    DIR=$2
    find_dir
    shift
    ;;
    -t)
    TERMINALA="| awk '\$5 != \"?\"'"
    ;;
    -e)
    EPROCESS=1
    ;;
    -sm)
    SM=1
    ;;
    -sg)
    SG=1
    ;;
    -r)
    INV=1
    ;;
    ##### MODIFICACIÓN 1
    #-w)
    #LEYENDOUSER=0
    #WARN5=1
    #;;
    ##### MODIFICACION 2
    #-f)
    #FILE5=1
    #FILECOUNT="$2"
    #shift
    #;;
    *)
    if [ $LEYENDOUSER -eq 1 ]; then
      USUARIOS+=" $1"
    else
      echo "${TEXT_RED}La opcion ${TEXT_BOLD}$1${TEXT_RESET}${TEXT_RED} no existe${TEXT_RESET}"
      exit 1
    fi
    ;;
  esac
  shift
done
find_users
system_info
if [ $EPROCESS -eq 1 ]; then
  if [ $SG -eq 1 ]; then
    echo "${TEXT_RED}${TEXT_BOLD}ERROR${TEXT_RESET}${TEXT_RED}: No se admite la opción -sg con -e${TEXT_RESET}" >&2
    exit 1
  elif [ $SM -eq 1 ]; then
    FILTER=6
  fi
  print_table
else
  if [ $SG -eq 1 ]; then
    if [ $SM -eq 1 ]; then
      echo "${TEXT_RED}${TEXT_BOLD}ERROR${TEXT_RESET}${TEXT_RED}: No se admite la opción -sg junto con -sm${TEXT_RESET}" >&2
      exit 1
    else
      FILTERS=2
    fi
  elif [ $SM -eq 1 ]; then
    FILTERS=3
  fi
  session_table
fi
##### MODIFICACIÓN 1
#if [ $WARN5 -eq 1 ]; then
#  count_warn
#fi
##### MODIFICACION 2
#if [ $FILE5 -eq 1 ]; then
#  count_file
#fi
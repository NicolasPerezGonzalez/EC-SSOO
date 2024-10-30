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
LINE="############################################################################"
SEPARADOR="----------------------------------------------------------------------------"
##### VARIABLES
INFO=""                     # Variable en la que se almacena el comando para generar la tabla
PAR=""                      # Lista de elementos para las columnas 
AFILTER=""                  # Filtros a utilizar
USUARIO=""                  # Usuario que acompaña al -u
USERFILTER=""               # Filtro a aplicar debido a los usuarios
DIR=""                      # Directorio a buscar
DIRFILTER=""                # Filtro a aplicar para buscar los procesos del directorio
##### ESTILOS
TEXT_ULINE=$(tput sgr 0 1)
TEXT_BOLD=$(tput bold)
TEXT_RED=$(tput setaf 1)
TEXT_GREEN=$(tput setaf 2)
TEXT_RESET=$(tput sgr0)

####### FUNCIONES
usage () 
{
    cat << _EOF_ 
This program is disigned to show all the process of the computer
  Options:
    -h                            Display this help messageç
    -z                            The table display also the process with an sid = 0
    -u [user]                     It displays all the process of that user
    -d [dir]                      It shows only the process at "dir"
_EOF_
}
show_head()
{
  echo ${LINE}
  echo "Las columnas estan distribuidas de esta forma:"
  echo "${TEXT_BOLD}\$1${TEXT_RESET} -> ${TEXT_BOLD}S${TEXT_RESET}ession ${TEXT_BOLD}ID"
  echo "\$2${TEXT_RESET} -> ${TEXT_BOLD}P${TEXT_RESET}rocess ${TEXT_BOLD}G${TEXT_RESET}roup ${TEXT_BOLD}ID"
  echo "\$3${TEXT_RESET} -> ${TEXT_BOLD}P${TEXT_RESET}rocess ${TEXT_BOLD}ID"
  echo "\$4${TEXT_RESET} -> ${TEXT_BOLD}USER"
  echo "\$5${TEXT_RESET} -> ${TEXT_BOLD}TTY"
  echo "\$6${TEXT_RESET} -> ${TEXT_BOLD}%MEM"
  echo "\$7${TEXT_RESET} -> ${TEXT_BOLD}CMD${TEXT_RESET}"
  echo ${SEPARADOR}
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
find_user()
{
    if grep "^$USUARIO:" /etc/passwd > /dev/null; then
        # USERFILTER="| awk '\$4 ~ $USUARIO {print}'"
        USERFILTER="| grep $USUARIO"
        echo "${TEXT_GREEN}Usuario ${TEXT_BOLD}$USUARIO${TEXT_RESET}${TEXT_GREEN} encontrado, se ejecutara ${TEXT_BOLD}$USERFILTER${TEXT_RESET}"
    else
        echo "${TEXT_RED}${TEXT_BOLD}$USUARIO${TEXT_RESET}${TEXT_RED} no es un usuario existente${TEXT_RESET}"
        exit 1
    fi
}
system_info()
{
    # Ejecuta ps con los parametros previamente seleccionados
    echo ${LINE}
    echo "Bienvenido a mi programa $0"
    echo
    INFO="ps -eo $PAR --no-headers --sort=user | awk '{print \$1, \$2, \$3, \$4, \$5, \$6, \$7}' $NZFILTER $USERFILTER $DIRFILTER "
    echo "El comando a ejecutar va a ser:"
    echo "$INFO"
    show_head
    eval $INFO
}
PAR="sid,pgid,pid,user,tty,%mem,cmd"
NZFILTER="| grep -v ^0"
while [[ $# -gt 0 ]]; do
  case $1 in
    -h | --help)
    usage
    exit 0
    ;;
    -z)
    NZFILTER=""
    ;;
    -u)
    USUARIO=$2
    find_user
    shift
    ;;
    -d)
    DIR=$2
    find_dir
    shift
    ;;
    *)
    echo "${TEXT_RED}La opcion ${TEXT_BOLD}$1${TEXT_RESET}${TEXT_RED} no existe${TEXT_RESET}"
    exit 1
    ;;
  esac
  shift
done
system_info



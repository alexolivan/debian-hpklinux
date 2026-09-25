#!/bin/sh
#
# AudioScience Debian Package Version Configuration (SSOT)
#
DEFAULT_ASIHPI_VERSION="4.20.56"
DEFAULT_PKG_RELEASE="1"

# Obtiene la versión mayor.menor (ej. 4.20 a partir de 4.20.56)
get_major_version() {
  echo "$1" | cut -d. -f1,2
}

# Obtiene la subversión/parche (ej. 56 a partir de 4.20.56)
get_patch_version() {
  echo "$1" | cut -d. -f3
}

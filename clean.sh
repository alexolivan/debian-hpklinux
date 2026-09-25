#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Limpiando residuos de compilación..."
rm -rf build/ dist/
rm -f debian/control debian/rules debian/prerm debian/postinst
rm -f debian/prerm.src2 debian/postinst.src2
rm -f *.buildinfo *.changes *.ddeb *.deb *.dsc *.debian.tar.xz *.orig.tar.gz

if [ "$1" = "--all" ] || [ "$1" = "-a" ]; then
  echo "Eliminando caché de tarballs..."
  rm -rf tarballs/
fi

echo "Limpieza completada con éxito."

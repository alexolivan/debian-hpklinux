#!/bin/bash
set -eo pipefail

# ==============================================================================
# Universal Debian Package Builder for AudioScience HPKLinux
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Cargar configuración de versiones
if [ -f "./versions.sh" ]; then
  # shellcheck source=versions.sh
  . ./versions.sh
else
  DEFAULT_ASIHPI_VERSION="4.20.56"
  DEFAULT_PKG_RELEASE="1"
  get_major_version() { echo "$1" | cut -d. -f1,2; }
  get_patch_version() { echo "$1" | cut -d. -f3; }
fi

# Variables de control
VERSION=""
PKG_RELEASE="${DEFAULT_PKG_RELEASE:-1}"
NON_INTERACTIVE=false
KEEP_BUILD=false

show_help() {
  cat << EOF
Uso: $0 [OPCIONES] [VERSION]

Argumentos:
  VERSION             Versión de AudioScience a compilar (por defecto: ${DEFAULT_ASIHPI_VERSION})

Opciones:
  -y, --yes           Modo no interactivo; instala dependencias automáticamente sin preguntar
  -k, --keep-build    Conserva el directorio temporal build/ tras finalizar la compilación
  -h, --help          Muestra esta ayuda y finaliza

Ejemplos:
  $0                  # Compila la versión por defecto (${DEFAULT_ASIHPI_VERSION})
  $0 4.20.54          # Compila la versión 4.20.54
  $0 -y               # Compila sin confirmaciones interactivas
EOF
}

# Procesar argumentos
while [ "$#" -gt 0 ]; do
  case "$1" in
    -y|--yes)
      NON_INTERACTIVE=true
      shift
      ;;
    -k|--keep-build)
      KEEP_BUILD=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    -*)
      echo "Error: Opción desconocida '$1'." >&2
      show_help
      exit 1
      ;;
    *)
      if [ -z "$VERSION" ]; then
        VERSION="$1"
      else
        echo "Error: Múltiples versiones especificadas ('$VERSION' y '$1')." >&2
        exit 1
      fi
      shift
      ;;
  esac
done

VERSION="${VERSION:-$DEFAULT_ASIHPI_VERSION}"
MAJOR_VERSION="$(get_major_version "$VERSION")"
PATCH_VERSION="$(get_patch_version "$VERSION")"
PKG_VERSION="${VERSION}-${PKG_RELEASE}"

echo "======================================================================"
echo " AudioScience HPKLinux - Debian Universal Builder"
echo " Versión objetivo: ${VERSION} (Paquete: ${PKG_VERSION})"
echo "======================================================================"

# ------------------------------------------------------------------------------
# 1. Comprobación y gestión de dependencias del sistema
# ------------------------------------------------------------------------------
echo "[-] Verificando dependencias del sistema..."

REQUIRED_PACKAGES=(
  "build-essential"
  "debhelper"
  "autotools-dev"
  "dkms"
  "linux-headers-$(uname -r)"
  "curl"
  "ca-certificates"
)

MISSING_PACKAGES=()
for pkg in "${REQUIRED_PACKAGES[@]}"; do
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    MISSING_PACKAGES+=("$pkg")
  fi
done

if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
  echo ""
  echo "Se han detectado dependencias de compilación no instaladas:"
  for pkg in "${MISSING_PACKAGES[@]}"; do
    echo "  • $pkg"
  done
  echo ""

  if [ "$NON_INTERACTIVE" = false ]; then
    read -r -p "¿Desea instalar los paquetes necesarios ahora usando apt? [S/n]: " CONFIRM_INSTALL
    case "$CONFIRM_INSTALL" in
      [nN]|[nN][oO])
        echo "Operación cancelada por el usuario. No se puede compilar sin las dependencias." >&2
        exit 1
        ;;
    esac
  fi

  echo "Instalando paquetes requeridos..."
  if [ "$(id -u)" -eq 0 ]; then
    apt-get update && apt-get install -y "${MISSING_PACKAGES[@]}"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    else
      echo "Error: Se requieren privilegios de root para instalar dependencias y 'sudo' no está disponible." >&2
      exit 1
    fi
  fi
fi
echo "[✓] Todas las dependencias del sistema están satisfechas."

# ------------------------------------------------------------------------------
# 2. Obtención del código fuente upstream
# ------------------------------------------------------------------------------
TARBALL_DIR="$SCRIPT_DIR/tarballs"
TARBALL_FILE="$TARBALL_DIR/hpklinux_${VERSION}.tar.gz"
mkdir -p "$TARBALL_DIR"

if [ ! -f "$TARBALL_FILE" ]; then
  # Cálculo de la URL de descarga oficial
  MAJOR_1="$(echo "$VERSION" | cut -d. -f1)"
  MAJOR_2="$(echo "$VERSION" | cut -d. -f2)"
  DOWNLOAD_URL="https://www.audioscience.com/internet/download/drivers/released/v${MAJOR_1}/${MAJOR_2}/${PATCH_VERSION}/hpklinux_${VERSION}.tar.gz"

  echo "[-] Descargando código fuente oficial de AudioScience..."
  echo "    URL: $DOWNLOAD_URL"
  if ! curl -fSL -A "Mozilla/5.0 (X11; Linux x86_64)" --progress-bar "$DOWNLOAD_URL" -o "$TARBALL_FILE"; then
    rm -f "$TARBALL_FILE"
    echo "Error: No se pudo descargar el tarball desde la URL especificada." >&2
    echo "Verifique la versión solicitada o descargue manualmente el archivo en: $TARBALL_FILE" >&2
    exit 1
  fi
fi
echo "[✓] Tarball upstream disponible: $TARBALL_FILE"

# ------------------------------------------------------------------------------
# 3. Preparación del directorio de compilación
# ------------------------------------------------------------------------------
BUILD_DIR="$SCRIPT_DIR/build"
SRC_DIR="$BUILD_DIR/hpklinux_${VERSION}"

echo "[-] Preparando entorno de compilación en $BUILD_DIR..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

tar -zxf "$TARBALL_FILE" -C "$BUILD_DIR"

# Normalizar nombre del directorio si upstream usa guión en lugar de guión bajo
if [ ! -d "$SRC_DIR" ] && [ -d "$BUILD_DIR/hpklinux-${VERSION}" ]; then
  mv "$BUILD_DIR/hpklinux-${VERSION}" "$SRC_DIR"
fi

if [ ! -d "$SRC_DIR" ]; then
  echo "Error: No se encontró el directorio extraído esperado en $SRC_DIR" >&2
  exit 1
fi

# Copiar estructura debian base
cp -a "$SCRIPT_DIR/debian" "$SRC_DIR/"

# Procesar plantillas Debian
sed "s/@ASIHPI_PKG_VERSION@/${PKG_VERSION}/g" < "$SRC_DIR/debian/control.src" > "$SRC_DIR/debian/control"
sed "s/@ASIHPI_VERSION@/${VERSION}/g" < "$SRC_DIR/debian/rules.src" > "$SRC_DIR/debian/rules"
chmod 755 "$SRC_DIR/debian/rules"

sed -e "s/@ASIHPI_VERSION@/${VERSION}/g" \
    -e "s/@ASIHPI_MAJOR_VERSION@/${MAJOR_VERSION}/g" \
    < "$SRC_DIR/debian/prerm.src" > "$SRC_DIR/debian/prerm"
chmod 755 "$SRC_DIR/debian/prerm"

sed -e "s/@ASIHPI_VERSION@/${VERSION}/g" \
    -e "s/@ASIHPI_MAJOR_VERSION@/${MAJOR_VERSION}/g" \
    < "$SRC_DIR/debian/postinst.src" > "$SRC_DIR/debian/postinst"
chmod 755 "$SRC_DIR/debian/postinst"

# Asegurar entrada correspondiente en debian/changelog si no está ya
if ! grep -q "hpklinux (${PKG_VERSION})" "$SRC_DIR/debian/changelog"; then
  RFC_DATE="$(date -R)"
  TMP_CHANGELOG="$(mktemp)"
  cat << EOF > "$TMP_CHANGELOG"
hpklinux (${PKG_VERSION}) stable; urgency=medium

  * Automated build for upstream version ${VERSION}.

 -- Alex Olivan <alejandro.olivan.alvarez@gmail.com>  ${RFC_DATE}

EOF
  cat "$SRC_DIR/debian/changelog" >> "$TMP_CHANGELOG"
  mv "$TMP_CHANGELOG" "$SRC_DIR/debian/changelog"
fi

# Generar el tarball .orig.tar.gz requerido por dpkg-buildpackage
tar -zcf "$BUILD_DIR/hpklinux_${VERSION}.orig.tar.gz" -C "$BUILD_DIR" "hpklinux_${VERSION}"
echo "[✓] Directorio fuente preparado y plantillas Debian renderizadas."

# ------------------------------------------------------------------------------
# 4. Compilación del paquete Debian
# ------------------------------------------------------------------------------
echo "[-] Compilando paquetes con dpkg-buildpackage..."
(
  cd "$SRC_DIR"
  dpkg-buildpackage -us -uc -b
)

# ------------------------------------------------------------------------------
# 5. Entrega de artefactos en ./dist/
# ------------------------------------------------------------------------------
DIST_DIR="$SCRIPT_DIR/dist"
mkdir -p "$DIST_DIR"

mv "$BUILD_DIR"/*.deb "$DIST_DIR/"

if [ "$KEEP_BUILD" = false ]; then
  rm -rf "$BUILD_DIR"
fi

echo ""
echo "======================================================================"
echo " [✓] COMPILACIÓN FINALIZADA CON ÉXITO"
echo "======================================================================"
echo "Paquetes generados en: $DIST_DIR"
ls -lh "$DIST_DIR"/*.deb
echo ""
echo "Para instalar en este sistema:"
echo "  sudo apt install $DIST_DIR/hpklinux_${PKG_VERSION}_*.deb"
echo "======================================================================"

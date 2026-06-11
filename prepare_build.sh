#!/bin/sh

. ./versions.sh

# 1. Limpieza de residuos
rm -f *.buildinfo *.changes *.ddeb *.deb *.dsc *.debian.tar.xz
rm -rf hpklinux_$ASIHPI_VERSION
rm -rf hpklinux_$ASIHPI_VERSION-orig
rm -f debian/control

# 2. Extraemos el código fuente original de AudioScience
tar -zvxf hpklinux_$ASIHPI_VERSION.tar.gz

# 3. Procesamos las plantillas de control de Fred como siempre
sed s/@ASIHPI_PKG_VERSION@/$ASIHPI_PKG_VERSION/ < debian/control.src > debian/control
sed s/@ASIHPI_VERSION@/$ASIHPI_VERSION/ < debian/rules.src > debian/rules
chmod 755 debian/rules
sed s/@ASIHPI_VERSION@/$ASIHPI_VERSION/ < debian/load_asihpi.sh.in > debian/load_asihpi.sh
chmod 755 debian/load_asihpi.sh
sed s/@ASIHPI_VERSION@/$ASIHPI_VERSION/ < debian/prerm.src > debian/prerm.src2
sed s/@ASIHPI_MAJOR_VERSION@/$ASIHPI_MAJOR_VERSION/ < debian/prerm.src2 > debian/prerm
chmod 755 debian/prerm
rm debian/prerm.src2
sed s/@ASIHPI_VERSION@/$ASIHPI_VERSION/ < debian/postinst.src > debian/postinst.src2
sed s/@ASIHPI_MAJOR_VERSION@/$ASIHPI_MAJOR_VERSION/ < debian/postinst.src2 > debian/postinst
chmod 755 debian/postinst
rm debian/postinst.src2

# 4. Tu automatización del changelog
sed -i "1s/hpklinux (.*)/hpklinux ($ASIHPI_PKG_VERSION)/" debian/changelog

# 5. Metemos la carpeta debian dentro del código fuente modificado
cp -a debian hpklinux_$ASIHPI_VERSION/

# 6. Re-empaquetamos el tarball .orig que usará dpkg-buildpackage para construir el .deb
tar -zvcf hpklinux_$ASIHPI_VERSION.orig.tar.gz hpklinux_$ASIHPI_VERSION

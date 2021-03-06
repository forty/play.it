#!/bin/sh -e

# Contrôle des dépendances (interrompt le script en cas de dépendance introuvable)
for dep in innoextract wrestool icotool fakeroot; do
	if [ -z $(which $dep) ]; then
		echo "$dep est introuvable sur votre système."
		echo "Installez-le avant de relancer ce script."
		exit 1
	fi
done
if [ -z $(which md5sum) ]; then
	echo "md5sum est introuvable sur votre système."
	echo "L’intégrité de l’archive ne sera pas vérifiée."
	CHECKSUM=none
fi

# Initialisation des variables
ID=tropico
VERSION=1.5.3
REVISION=2.1.0.14
ARCH=all
PKGDESC="Tropico + Paradise Island"
PKGDEPS="wine, wine32 | wine-bin | wine1.6-i386 | wine1.4-i386"
EXE=tropico.exe
WRITABLE="data2/*.cfg data2/*.dat"
DESKNAME="Tropico: Paradise Island"
ARCHIVE1=setup_tropico_french_2.1.0.14.exe
ARCHIVE2=setup_tropico_2.1.0.14.exe
MD5SUM1=aad4ea5a6fe2b2c2f347cfa7aae058b3
MD5SUM2=1bd761bc4a40a42a9caeb41c70d46465

# Définition de la méthode de compression
if [ -z $COMPRESSION ]; then
	COMPRESSION=none
fi
if [ $COMPRESSION = gzip -o $COMPRESSION = xz ]; then
	echo "Utilisation de $COMPRESSION pour la compression du paquet final."
elif [ $COMPRESSION = none ]; then
	echo "Le paquet final ne sera pas compressé."
else
	echo "$COMPRESSION n'est pas une valeur valide pour la variable \$COMPRESSION."
	echo "Les valeurs acceptées sont : none, gzip, xz."
	exit 1
fi
DPKGDEB="fakeroot dpkg-deb -Z$COMPRESSION -b"

# Recherche de la cible (interrompt le script en cas de cible invalide ou indéfinie)
if ! [ $1 ]; then
	if [ -f $ARCHIVE1 ]; then
		ARCHIVE=$ARCHIVE1
		MD5SUM=$MD5SUM1
		echo "Utilisation de $(realpath $ARCHIVE)"
	elif [ -f $ARCHIVE2 ]; then
		ARCHIVE=$ARCHIVE2
		MD5SUM=$MD5SUM2
		echo "Utilisation de $(realpath $ARCHIVE)"
	else
		echo "Ce script prend en argument l’installeur téléchargé depuis gog.com. (version $REVISION)"
		exit 1
	fi
elif ! [ -f $1  ]; then
	echo "$1: fichier introuvable"
	exit 1
else
	ARCHIVE=$1
fi

# Définition de la méthode de vérification de l’archive
if [ -z $CHECKSUM ]; then
	CHECKSUM=md5sum
fi
if [ $CHECKSUM = none ]; then
	echo "L’intégrité de l’archive ne sera pas vérifiée."
elif [ $CHECKSUM = md5sum ]; then
	echo "L’intégrité de l’archive sera vérifiée par $CHECKSUM."
else
	echo "$CHECKSUM n'est pas une valeur valide pour la variable \$CHECKSUM."
	echo "Les valeurs acceptées sont : none, md5sum."
	exit 1
fi

# Vérification de l’intégrité de l’archive
if [ $CHECKSUM = md5sum ]; then
	echo "Contrôle de l’intégrité de l’archive…"
	if [ "$(md5sum "$ARCHIVE" | cut -d' ' -f1)" != "$MD5SUM" ]; then
		echo "Somme de contrôle incohérente."
		echo "Le fichier $ARCHIVE n’est pas celui attendu, ou il est corrompu."
		exit 1
	fi
fi

# Préparation de l’arborescence du paquet
PKGNAME="$ID"_$VERSION-gog"$REVISION"_$ARCH
if [ -e $PKGNAME ]; then
	echo "$(realpath $PKGNAME) existe déjà, il peut s’agir d’un résidu d’une utilisation du script avortée."
	echo "Supprimez-le avant de relancer ce script."
	exit 1
fi
if [ -z $PREFIX ]; then
	PREFIX=/usr/local
fi
echo "\$PREFIX défini à \"$PREFIX\""
if ! [ "$( echo $PREFIX | cut -c1)" = "/" ]; then
	echo "\$PREFIX doit être un chemin absolu."
	exit 1
fi
GAMEPATH=$PREFIX/share/games/$ID
DOCPATH=$PREFIX/share/doc/$ID
BINPATH=$PREFIX/games
ICONPATH=/usr/local/share/icons/hicolor/32x32/apps
DESKPATH=$PREFIX/share/applications
mkdir -p $PKGNAME$GAMEPATH $PKGNAME$DOCPATH $PKGNAME$BINPATH $PKGNAME$ICONPATH $PKGNAME$DESKPATH $PKGNAME/DEBIAN

# Extraction des données de l’archive
TMPDIR=$ID.$(date +%s)
innoextract -seL -p -d $TMPDIR "$ARCHIVE"
mv $TMPDIR/app/* $PKGNAME$GAMEPATH

# Création du lanceur
echo "#!/bin/sh -e
USERDIR=\$HOME/.local/share/games/$ID
if ! [ -e \$USERDIR/$EXE ]; then
	mkdir -p \$USERDIR
	cp -surf $GAMEPATH/* \$USERDIR
	cd \$USERDIR
	mkdir -p games
	for writable in $WRITABLE; do
		if [ -h \$writable ]; then
			cp -a --remove-destination $GAMEPATH/\$writable \$writable
		fi
	done
fi
export WINEDEBUG=-all
export WINEPREFIX=\$USERDIR/wine-prefix
if ! [ -e \$WINEPREFIX ]; then
	WINEARCH=win32 wineboot -i
	rm \$WINEPREFIX/dosdevices/z:
	ln -s \$USERDIR \$WINEPREFIX/drive_c
fi
cd \$WINEPREFIX/drive_c/$ID
wine $EXE \$@
exit 0" > $PKGNAME$BINPATH/$ID

chmod 755 $PKGNAME$BINPATH/*

# Extraction de l’icône
wrestool -t 14 -x $PKGNAME$GAMEPATH/$EXE | icotool -x -o $PKGNAME$ICONPATH/$ID.png -

# Création de l’entrée de menu
echo "[Desktop Entry]
Version=1.0
Type=Application
Name=$DESKNAME
Icon=$ID
Exec=$ID
Categories=Game;" > $PKGNAME$DESKPATH/$ID.desktop

# Création du fichier DEBIAN/control
echo "Package: $ID
Version: $VERSION-gog$REVISION
Section: non-free/games
Architecture: $ARCH
Installed-Size: $(du -ks $PKGNAME/usr | cut -f1)
Maintainer: $(whoami)@$(hostname)
Depends: $PKGDEPS
Description: $PKGDESC" > $PKGNAME/DEBIAN/control

# Création des scripts d’installation
echo "#!/bin/sh -e
ln -s $GAMEPATH/*.pdf $GAMEPATH/*.txt $DOCPATH
exit 0" > $PKGNAME/DEBIAN/postinst

echo "#!/bin/sh -e
rm $DOCPATH/*
exit 0" > $PKGNAME/DEBIAN/prerm

chmod 755 $PKGNAME/DEBIAN/postinst $PKGNAME/DEBIAN/prerm

# Construction du paquet
rm -r $TMPDIR
$DPKGDEB $PKGNAME
rm -r $PKGNAME

echo "Paquet construit."
echo "Installez-le en lançant la commande suivante (en root) :"
echo "dpkg -i $PWD/$PKGNAME.deb; apt-get install -f"

exit 0

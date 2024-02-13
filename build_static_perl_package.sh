URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
PKG=${MOD//::/-}
echo $PKG $URL

mkdir -p source
wget -nc $URL -P source
mkdir -p myext
tar -xf source/$(basename $URL) --strip-components=1 --directory myext/$PKG
cd myext/$PKG
test -f Makefile.PL
$PERLBIN Makefile.PL LINKTYPE=static
make
make install

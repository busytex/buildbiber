MOD="$1"
URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
PKG=${MOD//::/-}
echo $PKG $URL

mkdir -p myextsource myext/$PKG
wget -nc $URL -P myextsource
tar -xf myextsource/$(basename $URL) --strip-components=1 --directory myext/$PKG
cd myext/$PKG
ls
$PERLBIN Makefile.PL LINKTYPE=static
sed -i 's@rm -f "blib/arch/auto/IO/Compress/Brotli/Brotli.a"@rm -f "blib/arch/auto/IO/Compress/Brotli/Brotli.bak"@' Makefile
make
make install

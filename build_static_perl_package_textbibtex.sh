MOD="$1"
URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
PKG=${MOD//::/-}
echo $PKG $URL

mkdir -p myextsource myext/$PKG
wget -nc $URL -P myextsource
tar -xf myextsource/$(basename $URL) --strip-components=1 --directory myext/$PKG
cd myext/$PKG
ls
$PERLBIN ./Build.PL
$PERLBIN ./Build
$PERLBIN ./Build install

ar crs  ../../../localperlstatic/lib/site_perl/5.32.0/x86_64-linux/auto/Text/BibTeX/BibTeX.a    xscode/BibTeX.o xscode/btxs_support.o btparse/src/init.o btparse/src/input.o btparse/src/bibtex.o btparse/src/err.o btparse/src/scan.o btparse/src/error.o btparse/src/lex_auxiliary.o btparse/src/parse_auxiliary.o btparse/src/bibtex_ast.o btparse/src/sym.o btparse/src/util.o btparse/src/postprocess.o btparse/src/macros.o btparse/src/traversal.o btparse/src/modify.o btparse/src/names.o btparse/src/tex_tree.o btparse/src/string_util.o

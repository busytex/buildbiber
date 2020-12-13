set -e 

ROOT=$PWD
#export MAKEFLAGS=-j2
URLPERL=https://www.cpan.org/src/5.0/perl-5.30.0.tar.gz
#source emperl_config.sh
# Unicode::LineBreak Unicode::GCString
# Lingua::Translit
# Encode::EUCJPASCII Encode::JIS2K Encode::HanExtra
# Text::CSV Text::CSV_XS
# PerlIO::utf8_strict
# IPC::Run3
# LWP::UserAgent LWP::Protocol::https
# XML::LibXSLT XML::Writer
# XML::LibXML::Simple

# List::MoreUtils List::MoreUtils::XS
# Alien::Base::Wrapper XML::LibXML
# Text::BibTeX

mkdir -p source build/native/perl build/wasm/perl

wget -nc $URLPERL -P source

#tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/native/perl
#CPANMODULES="Log::Log4perl autovivification URI Business::ISBN Business::ISSN Business::ISMN DateTime::Format::Builder DateTime::Calendar::Julian Sort::Key Text::Roman Data::Dump Data::Compare Data::Uniqid Mozilla::CA Regexp::Common Class::Accessor File::Slurper IO::String  List::AllUtils Encode::Locale Parse::RecDescent" 
#for MOD in $CPANMODULES; do
#    URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
#    PKG=${MOD//::/-}
#    wget -nc $URL -P source
#    mkdir -p build/native/perl/ext/$PKG
#    tar -xf source/$(basename $URL) --strip-components=1 --directory build/native/perl/ext/$PKG
#    echo $PKG $URL
#done
#pushd build/native/perl
#bash ./Configure -sde -Dprefix=$PWD/../prefix -Dhintfile=$ROOT/hintfile_native.sh -Dlibs="-lm" 
#make
##make miniperl generate_uudmap
#make install
#popd
#
#./build/native/prefix/bin/cpan -T Module::Build Alien::Base::Wrapper Alien::Libxml2 || true
#DBI
## Module::Implementation

PERLBIN=$PWD/build/native/prefix/bin/perl
#export PERLLIB=$PWD/build/native/perl/lib:$PWD/build/native/perl/ext/Encode-HanExtra
#export PATH=$PWD/build/native/perl/cpan/Encode/bin/:$PATH
export INC="-I$PWD/build/native/perl -I$PWD/build/native/perl/lib/Encode -I$PWD/build/native/perl/ext/Unicode-LineBreak/sombok/include/ -I/usr/include/libxml2/ -I/usr/include/libxslt/"
#mkdir -p build/native/prefix/bin
#rm -f build/native/prefix/bin/enc2xs || true
#cp build/native/perl/cpan/Encode/bin/enc2xs build/native/prefix/bin/enc2xs
#chmod +x build/native/prefix/bin/enc2xs
#CPANMODULES="Encode::EUCJPASCII Encode::JIS2K Encode::HanExtra Lingua::Translit Unicode::LineBreak Unicode::GCString Text::CSV Text::CSV_XS PerlIO::utf8_strict IPC::Run3 LWP::UserAgent LWP::Protocol::https XML::Writer XML::Parser Variable::Magic Clone HTML::Parser DateTime PadWalker Devel::Caller Devel::LexAlias Package::Stash::XS DBI Sub::Identify XML::LibXML XML::LibXML::Simple Text::BibTeX"
CPANMODULES="Text::BibTeX"

#CPANMODULES="DBD::SQLite"
#XML::LibXSLT"
#CPANMODULES="Module::Build"

#  depends on DBI 1.57 
# Params::Validate::XS requires Module::Build

# no Makefile Text::BibTeX 
#CPANMODULES="List::MoreUtils::XS"
# Checking whether perlapi is accessible... no
# configure: Cannot use Perl API - giving up
# Checking whether pureperl is required... no
#Checking for cc... ld: warning: cannot find entry symbol _start; defaulting to 00000000004000b0
#cc
#Checking for cc... (cached) cc

for MOD in $CPANMODULES; do
    URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
    PKG=${MOD//::/-}
    wget -nc $URL -P source
    rm -rf build/native/perl/ext/$PKG || true
    mkdir -p build/native/perl/ext/$PKG
    tar -xf source/$(basename $URL) --strip-components=1 --directory build/native/perl/ext/$PKG
    echo $PKG $URL
    
    pushd build/native/perl/ext/$PKG
    if [ -f Makefile.PL ]; then
        PERLLIB=$PWD $PERLBIN Makefile.PL LINKTYPE=static INC="$INC"
        make INC="$INC"
        make install
    elif [ -f Build.PL ]; then
        $PERLBIN Build.PL
        ./Build || true
        ld -o btparse/src/libbtparse.so btparse/src/init.o btparse/src/input.o btparse/src/bibtex.o btparse/src/err.o btparse/src/scan.o btparse/src/error.o btparse/src/lex_auxiliary.o btparse/src/parse_auxiliary.o btparse/src/bibtex_ast.o btparse/src/sym.o btparse/src/util.o btparse/src/postprocess.o btparse/src/macros.o btparse/src/traversal.o btparse/src/modify.o btparse/src/names.o btparse/src/tex_tree.o btparse/src/string_util.o btparse/src/format_name.o -lc

        ./Build || true
        ld -o blib/arch/auto/Text/BibTeX/BibTeX.none xscode/BibTeX.o xscode/btxs_support.o -Lbtparse/src -lbtparse -lperl ~/buildbiber/build/native/perl/libperl.a -lm -lpthread -lc


        ./Build
        ./Build install
    else
        DST=../../../prefix/lib/5.*/${PKG//-//}
        mkdir -p $DST
        cp -r * $DST
    fi
    popd
done

#cc -o perl -fstack-protector-strong -L/usr/local/lib  perlmain.o $(find -name '*.a') -lm 
#make install


#-Aldflags=-lm
#tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/wasm/perl
#cp hintfile.sh build/wasm/perl/hints/emscripten.sh
#pushd build/wasm/perl
#emconfigure bash ./Configure -sde -Dhintfile=emscripten -Dsysroot=$(dirname $(which emcc))/system -Dhostperl=$ROOT/build/native/perl/miniperl -Dhostgenerate=$ROOT/build/native/perl/generate_uudmap -Dprefix=$PWD/../prefix
##sed -i 's/$(generated_pods)//' Makefile
#emmake make perl
#emmake make install

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

tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/native/perl
CPANMODULES="Log::Log4perl autovivification URI Business::ISBN Business::ISSN Business::ISMN DateTime::Format::Builder DateTime::Calendar::Julian Sort::Key Text::Roman Data::Dump Data::Compare Data::Uniqid Mozilla::CA Regexp::Common Class::Accessor File::Slurper IO::String  List::AllUtils Encode::Locale Parse::RecDescent" 
for MOD in $CPANMODULES; do
    URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
    PKG=${MOD//::/-}
    wget -nc $URL -P source
    mkdir -p build/native/perl/ext/$PKG
    tar -xf source/$(basename $URL) --strip-components=1 --directory build/native/perl/ext/$PKG
    echo $PKG $URL
done
pushd build/native/perl
bash ./Configure -sde -Dprefix=$PWD/../prefix -Dhintfile=$ROOT/hintfile_native.sh -Dlibs="-lm" 
make
##make miniperl generate_uudmap
##make install
popd

PERLBIN=$PWD/build/native/perl/perl
export PERLLIB=$PWD/build/native/perl/lib:$PWD/build/native/perl/ext/Encode-HanExtra
export PATH=$PWD/build/native/perl/cpan/Encode/bin/:$PATH
export INC="-I$PWD/build/native/perl -I$PWD/build/native/perl/lib/Encode -I$PWD/build/native/perl/ext/Unicode-LineBreak/sombok/include/ -I/usr/include/libxml2/"
mkdir -p build/native/prefix/bin
rm -f build/native/prefix/bin/enc2xs || true
cp build/native/perl/cpan/Encode/bin/enc2xs build/native/prefix/bin/enc2xs
chmod +x build/native/prefix/bin/enc2xs
CPANMODULES="Encode::EUCJPASCII Encode::JIS2K Encode::HanExtra Lingua::Translit Unicode::LineBreak Unicode::GCString Text::CSV Text::CSV_XS PerlIO::utf8_strict IPC::Run3 LWP::UserAgent LWP::Protocol::https XML::LibXSLT XML::Writer"
#CPANMODULES="XML::LibXML::Simple"
# depends on Alien/base/Wrapper.pm "XML::LibXML XML::LibXML::Simple XML::LibXSLT XML::Writer"  
# no Makefile Text::BibTeX 
#CPANMODULES="List::MoreUtils::XS"
# Checking whether perlapi is accessible... no
# configure: Cannot use Perl API - giving up
# Checking whether pureperl is required... no
#Checking for cc... ld: warning: cannot find entry symbol _start; defaulting to 00000000004000b0
#cc
#Checking for cc... (cached) cc
# Alien::Base::Wrapper 
#"XML::LibXML XML::LibXML::Simple" 
for MOD in $CPANMODULES; do
    URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
    PKG=${MOD//::/-}
    wget -nc $URL -P source
    rm -rf build/native/perl/ext/$PKG || true
    mkdir -p build/native/perl/ext/$PKG
    tar -xf source/$(basename $URL) --strip-components=1 --directory build/native/perl/ext/$PKG
    echo $PKG $URL
    
    pushd build/native/perl/ext/$PKG
    $PERLBIN Makefile.PL INC="$INC"
    make INC="$INC"
    popd
done

#-Aldflags=-lm

#tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/wasm/perl
#cp hintfile.sh build/wasm/perl/hints/emscripten.sh
#pushd build/wasm/perl
#emconfigure bash ./Configure -sde -Dhintfile=emscripten -Dsysroot=$(dirname $(which emcc))/system -Dhostperl=$ROOT/build/native/perl/miniperl -Dhostgenerate=$ROOT/build/native/perl/generate_uudmap -Dprefix=$PWD/../prefix
##sed -i 's/$(generated_pods)//' Makefile
#emmake make perl
#emmake make install

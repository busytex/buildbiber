ROOT=$PWD
#export MAKEFLAGS=-j2
URLPERL=https://www.cpan.org/src/5.0/perl-5.30.0.tar.gz
#source emperl_config.sh

mkdir -p source build/native/perl build/wasm/perl

wget -nc $URLPERL -P source

tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/native/perl

CPANMODULES="Log::Log4perl autovivification URI Business::ISBN Business::ISSN Business::ISMN DateTime::Format::Builder DateTime::Calendar::Julian Sort::Key Text::Roman Data::Dump Data::Compare Data::Uniqid Mozilla::CA Regexp::Common Class::Accessor File::Slurper IO::String  List::AllUtils Encode::Locale"
# Unicode::LineBreak
# Parse::RecDescent PerlIO::utf8_strict
# Unicode::GCString 
# IPC::Run3 IO::File 
# Encode::EUCJPASCII Encode::JIS2K Encode::HanExtra 
# LWP::UserAgent LWP::Protocol::https
# Lingua::Translit 
# List::MoreUtils List::MoreUtils::XS
# Text::BibTeX Text::CSV Text::CSV_XS
# XML::LibXML XML::LibXML::Simple XML::LibXSLT XML::Writer

for MOD in $CPANMODULES; do
    URL=$(wget -q -O - https://fastapi.metacpan.org/v1/download_url/$MOD | grep download_url | cut -d'"' -f4)
    PKG=${MOD//::/-}
    wget -nc $URL -P source
    mkdir -p build/native/perl/ext/$PKG
    tar -xf source/$(basename $URL) --strip-components=1 --directory build/native/perl/ext/$PKG
    echo $PKG $URL
done

pushd build/native/perl
bash ./Configure -sde -Dprefix=$PWD/../prefix -Dhintfile=$PWD/../../../hintfile_native.sh -Dlibs="-lm" # -lcrypto" 
make
#make miniperl generate_uudmap
#make perl
#make install
popd

#-Aldflags=-lm

#tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/wasm/perl
#cp hintfile.sh build/wasm/perl/hints/emscripten.sh
#pushd build/wasm/perl
#emconfigure bash ./Configure -sde -Dhintfile=emscripten -Dsysroot=$(dirname $(which emcc))/system -Dhostperl=$ROOT/build/native/perl/miniperl -Dhostgenerate=$ROOT/build/native/perl/generate_uudmap -Dprefix=$PWD/../prefix
##sed -i 's/$(generated_pods)//' Makefile
#emmake make perl
#emmake make install

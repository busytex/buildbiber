ROOT=$PWD
export MAKEFLAGS=-j2
URLPERL=https://www.cpan.org/src/5.0/perl-5.30.0.tar.gz
#source emperl_config.sh

mkdir -p source build/native/perl build/wasm/perl

wget -nc $URLPERL -P source

#tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/native/perl
#pushd build/native/perl
#bash ./Configure -sde -Aldflags=-lm
#make miniperl
#make generate_uudmap
#make perl
#popd

tar -xf source/$(basename $URLPERL) --strip-components=1 --directory=build/wasm/perl
cp hintfile.sh build/wasm/perl/hints/emscripten.sh
pushd build/wasm/perl
emconfigure bash ./Configure -sde -Dhintfile=emscripten -Dsysroot=$(dirname $(which emcc))/system -Dhostperl=$ROOT/build/native/perl/miniperl -Dhostgenerate=$ROOT/build/native/perl/generate_uudmap
#sed -i 's/$(generated_pods)//' Makefile
emmake make perl

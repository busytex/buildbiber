# Perl static/embedding experiments for busytex
1. Compile static Perl embedding `updmap.pl` and `fmtutil.pl`
2. Compile dynamic Perl embedding `tlmgr`
2. Compile static Perl calling `tlmgr`: https://github.com/TeX-Live/installer/blob/master/texmf-dist/scripts/texlive/tlmgr.pl
4. Compile dynamic Perl embedding `biber` https://github.com/plk/biber
5. Compile static Perl embedding `biber`

# References
- https://stackoverflow.com/questions/4855909/perl-including-embedding-a-module-in-a-script
- https://stackoverflow.com/questions/4158900/embedding-resources-in-executable-using-gcc
- https://stackoverflow.com/questions/5479691/is-there-any-standard-way-of-embedding-resources-into-linux-executable-image/10692876#10692876
- https://github.com/Perl/perl5/compare/blead...haukex:emperl_v5.30.0
- https://github.com/gh0stwizard/staticperl-modules/tree/master
- https://github.com/haukex/emperl5/blob/emperl_v5.30.0/hints/emscripten.sh

# References from wipbiber
- https://stackoverflow.com/questions/1114789/how-can-i-convert-perl-to-c
- https://www.perlmonks.org/?node_id=1225490
- https://metacpan.org/pod/distribution/B-C/script/perlcc.PL
- https://www.youtube.com/watch?v=bT17TCMbsdc&feature=youtu.be
- https://webperl.zero-g.net/building.html
- https://github.com/haukex/webperl/blob/master/build/build.pl
- http://lfs.phayoune.org/blfs/view/10.0/pst/biber.html
- https://www.texdev.net/2010/01/23/building-biblatex-biber/
- https://docstore.mik.ua/orelly/weblinux2/modperl/ch03_09.htm
- http://mirrors.ibiblio.org/CTAN/biblio/biber/documentation/biber.pdf
- https://github.com/gfx/perl.js/blob/master/Makefile.emcc
- https://github.com/Perl/perl5/compare/blead...haukex:emperl_v5.30.0
- https://perldoc.perl.org/perlembed
- https://github.com/toopher/toopher-radius/blob/master/cygwin/staticperl

# References from wiptlmgr and staticperl / cperl / perl11
- http://perl11.github.io/cperl/STATUS.html
- `wget https://github.com/perl11/cperl/releases/tag/cperl-5.30.0 tar xfz cperl-5.30.0 cd cperl-5.30.0 ./Configure -sde make -s -j4 test sudo make install`

```shell
# download tlmgr and staticperl
wget -nc http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
wget -nc http://cvs.schmorp.de/App-Staticperl/bin/staticperl
# extract tlmgr and copy tlmgr.pl and its dependencies into the current directory
mkdir -p install-tl-unx
tar -xf install-tl-unx.tar.gz --strip-components=1 --directory=install-tl-unx
cp -r install-tl-unx/texmf-dist/scripts/texlive/tlmgr.pl install-tl-unx/tlpkg/TeXLive .
./staticperl mkapp app -v -M $PWD/tlmgr.pl --boot $PWD/tlmgr.pl -M Cwd -M File::Spec -M Pod::Usage -M Getopt::Long -M Digest::MD5 -M File::Temp -M File::Copy -M File::Glob \
    --add "$PWD/TeXLive/TLConfFile.pm TeXLive/TLConfFile.pm" \
    --add "$PWD/TeXLive/TLCrypto.pm TeXLive/TLCrypto.pm" \
    --add "$PWD/TeXLive/TLPDB.pm TeXLive/TLPDB.pm" \
    --add "$PWD/TeXLive/TLPSRC.pm TeXLive/TLPSRC.pm" \
    --add "$PWD/TeXLive/TLTREE.pm TeXLive/TLTREE.pm" \
    --add "$PWD/TeXLive/TLWinGoo.pm TeXLive/TLWinGoo.pm" \
    --add "$PWD/TeXLive/TLConfig.pm TeXLive/TLConfig.pm" \
    --add "$PWD/TeXLive/TLDownload.pm TeXLive/TLDownload.pm" \
    --add "$PWD/TeXLive/TLPOBJ.pm TeXLive/TLPOBJ.pm" \
    --add "$PWD/TeXLive/TLPaper.pm TeXLive/TLPaper.pm" \
    --add "$PWD/TeXLive/TLUtils.pm TeXLive/TLUtils.pm" \
    --add "$PWD/TeXLive/TeXCatalogue.pm TeXLive/TexCatalogue.pm"
./app
``` 

TEXLIVEINSTALLERTAG=ad18812c20014153d52d6628ed11ad246b52fe69

python pack_perl_modules.py  --delete-comments-naive --comment-unshift-inc --method=inchook \
  --pl https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/texmf-dist/scripts/texlive/tlmgr.pl --pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLWinGoo.pm@TeXLive/TLWinGoo.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLConfFile.pm@TeXLive/TLConfFile.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLConfig.pm@TeXLive/TLConfig.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLCrypto.pm@TeXLive/TLCrypto.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLDownload.pm@TeXLive/TLDownload.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPDB.pm@TeXLive/TLPDB.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPOBJ.pm@TeXLive/TLPOBJ.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPSRC.pm@TeXLive/TLPSRC.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPaper.pm@TeXLive/TLPaper.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLTREE.pm@TeXLive/TLTREE.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLUtils.pm@TeXLive/TLUtils.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TeXCatalogue.pm@TeXLive/TeXCatalogue.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/trans.pl@TeXLive/trans.pl > tlmgr.pl

python pack_perl_modules.py  --delete-comments-naive --comment-unshift-inc --method=inchook \
  --pl https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/install-tl --pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLWinGoo.pm@TeXLive/TLWinGoo.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLConfFile.pm@TeXLive/TLConfFile.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLConfig.pm@TeXLive/TLConfig.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLCrypto.pm@TeXLive/TLCrypto.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLDownload.pm@TeXLive/TLDownload.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPDB.pm@TeXLive/TLPDB.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPOBJ.pm@TeXLive/TLPOBJ.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPSRC.pm@TeXLive/TLPSRC.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLPaper.pm@TeXLive/TLPaper.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLTREE.pm@TeXLive/TLTREE.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TLUtils.pm@TeXLive/TLUtils.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/TeXCatalogue.pm@TeXLive/TeXCatalogue.pm \
  https://raw.githubusercontent.com/TeX-Live/installer/$TEXLIVEINSTALLERTAG/tlpkg/TeXLive/trans.pl@TeXLive/trans.pl > install-tl.pl

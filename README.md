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

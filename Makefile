fmtutil_.pl:
	echo 'BEGIN {' > $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLConfig.pm >> $@
	echo '$$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;' >> $@
	echo '}' >> $@
	echo 'BEGIN {' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLUtils.pm >> $@
	echo '$$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;' >> $@
	echo '}' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/texlive-source/trunk/texk/texlive/linked_scripts/texlive/fmtutil.pl >> $@

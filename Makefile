fmtutil_.pl:
	echo '{' > $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLConfig.pm >> $@
	echo '}' >> $@
	echo '{' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLUtils.pm >> $@
	echo '}' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/texlive-source/trunk/texk/texlive/linked_scripts/texlive/fmtutil.pl >> $@

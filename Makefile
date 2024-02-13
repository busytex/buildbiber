fmtutil_inchook_old.pl updmap_inchook_old.pl:
	echo 'BEGIN {' > $@
	echo 'my %modules = (' >> $@
	#
	echo '"TeXLive/TLConfig.pm" => <<' "'"__EOI__"'", >> $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLConfig.pm >> $@
	echo '1;' >> $@
	echo '__EOI__' >> $@
	#
	echo '"TeXLive/TLUtils.pm" => <<' "'"__EOI__"'", >> $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLUtils.pm >> $@
	echo '1;' >> $@
	echo '__EOI__' >> $@
	#
	echo ');' >> $@
	echo 'unshift @INC, sub {' >> $@
	echo 'my $$module = $$modules{$$_[1]}' >> $@
	echo 'or return;' >> $@
	echo 'return \\$$module' >> $@
	echo '};' >> $@
	echo '}' >> $@
	#
	curl https://raw.githubusercontent.com/TeX-Live/texlive-source/trunk/texk/texlive/linked_scripts/texlive/$@ >> $@


fmtutil_incpatch_old.pl updmap_incpatch_old.pl:
	echo 'BEGIN {' > $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLConfig.pm >> $@
	echo '$$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;' >> $@
	echo '}' >> $@
	echo 'BEGIN {' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/installer/master/tlpkg/TeXLive/TLUtils.pm | sed '/=pod/,/=cut/d' | sed '/__END__/,/=cut/d' >> $@
	echo '$$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;' >> $@
	echo '}' >> $@
	curl https://raw.githubusercontent.com/TeX-Live/texlive-source/trunk/texk/texlive/linked_scripts/texlive/$@ >> $@

hi:
	echo world

# prefix/lib/5.35.4/Exporter.pm
# prefix/lib/5.35.4/strict.pm
# prefix/lib/5.35.4/vars.pm
# prefix/lib/5.35.4/warnings/register.pm
# prefix/lib/5.35.4/warnings.pm
# prefix/lib/5.35.4/Carp.pm
# prefix/lib/5.35.4/overloading.pm
# prefix/lib/5.35.4/x86_64-linux/Cwd.pm
# prefix/lib/5.35.4/XSLoader.pm
# prefix/lib/5.35.4/Getopt/Long.pm
# prefix/lib/5.35.4/constant.pm
# prefix/lib/5.35.4/overload.pm
# prefix/lib/5.35.4/Exporter/Heavy.pm
# prefix/lib/5.35.4/File/Temp.pm
# prefix/lib/5.35.4/x86_64-linux/File/Spec.pm
# prefix/lib/5.35.4/x86_64-linux/File/Spec/Unix.pm
# prefix/lib/5.35.4/File/Path.pm
# prefix/lib/5.35.4/File/Basename.pm
# prefix/lib/5.35.4/x86_64-linux/Fcntl.pm
# prefix/lib/5.35.4/x86_64-linux/IO/Seekable.pm
# prefix/lib/5.35.4/x86_64-linux/IO/Handle.pm
# prefix/lib/5.35.4/Symbol.pm
# prefix/lib/5.35.4/SelectSaver.pm
# prefix/lib/5.35.4/x86_64-linux/IO.pm
# prefix/lib/5.35.4/x86_64-linux/Errno.pm
# prefix/lib/5.35.4/x86_64-linux/Config.pm
# prefix/lib/5.35.4/x86_64-linux/Scalar/Util.pm
# prefix/lib/5.35.4/x86_64-linux/List/Util.pm
# prefix/lib/5.35.4/parent.pm
# prefix/lib/5.35.4/Carp/Heavy.pm

# prefix/lib/5.35.4/Exporter.pm
# prefix/lib/5.35.4/strict.pm
# prefix/lib/5.35.4/vars.pm
# prefix/lib/5.35.4/warnings/register.pm
# prefix/lib/5.35.4/warnings.pm
# prefix/lib/5.35.4/Carp.pm
# prefix/lib/5.35.4/overloading.pm
# prefix/lib/5.35.4/XSLoader.pm
# prefix/lib/5.35.4/Getopt/Long.pm
# prefix/lib/5.35.4/constant.pm
# prefix/lib/5.35.4/overload.pm
# prefix/lib/5.35.4/Exporter/Heavy.pm
# prefix/lib/5.35.4/File/Temp.pm
# prefix/lib/5.35.4/File/Path.pm
# prefix/lib/5.35.4/File/Basename.pm
# prefix/lib/5.35.4/Symbol.pm
# prefix/lib/5.35.4/SelectSaver.pm
# prefix/lib/5.35.4/parent.pm
# prefix/lib/5.35.4/Carp/Heavy.pm
# prefix/lib/5.35.4/x86_64-linux/Cwd.pm
# prefix/lib/5.35.4/x86_64-linux/File/Spec.pm
# prefix/lib/5.35.4/x86_64-linux/File/Spec/Unix.pm
# prefix/lib/5.35.4/x86_64-linux/Fcntl.pm
# prefix/lib/5.35.4/x86_64-linux/IO/Seekable.pm
# prefix/lib/5.35.4/x86_64-linux/IO/Handle.pm
# prefix/lib/5.35.4/x86_64-linux/IO.pm
# prefix/lib/5.35.4/x86_64-linux/Errno.pm
# prefix/lib/5.35.4/x86_64-linux/Config.pm
# prefix/lib/5.35.4/x86_64-linux/Scalar/Util.pm
# prefix/lib/5.35.4/x86_64-linux/List/Util.pm

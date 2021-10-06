BEGIN {
# $Id$
# TeXLive::TLConfig.pm - module exporting configuration values
# Copyright 2007-2021 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.

package TeXLive::TLConfig;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }

BEGIN {
  use Exporter ();
  use vars qw( @ISA @EXPORT_OK @EXPORT );
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(
    $ReleaseYear
    @MetaCategories
    @NormalCategories
    @Categories
    $MetaCategoriesRegexp
    $CategoriesRegexp
    $DefaultCategory
    @AcceptedFallbackDownloaders
    %FallbackDownloaderProgram
    %FallbackDownloaderArgs
    $DefaultCompressorFormat
    $CompressorExtRegexp
    %Compressors
    $InfraLocation
    $DatabaseName
    $DatabaseLocation
    $PackageBackupDir 
    $BlockSize
    $Archive
    $TeXLiveServerURL
    $TeXLiveServerURLRegexp
    $TeXLiveServerPath
    $TeXLiveURL
    @CriticalPackagesList
    $CriticalPackagesRegexp
    $WindowsMainMenuName
    $RelocPrefix
    $RelocTree
    %TLPDBOptions
    %TLPDBSettings
    %TLPDBConfigs
    $NetworkTimeout
    $MaxLWPErrors
    $MaxLWPReinitCount
    $PartialEngineSupport
    $F_OK $F_WARNING $F_ERROR $F_NOPOSTACTION
    $ChecksumLength
    $ChecksumProgram
    $ChecksumExtension
  );
  @EXPORT = @EXPORT_OK;
}

# the year of our release, will be used in the location of the
# network packages, and in menu names, and other places.
$ReleaseYear = 2021;

# users can upgrade from this year to the current year; might be the
# same as the release year, or any number of releases earlier.
# Generally not tested, but should be.
$MinRelease = 2016;

# Meta Categories do not ship files, but only call for other packages.
our @MetaCategories = qw/Collection Scheme/;
our $MetaCategoriesRegexp = '(Collection|Scheme)';
#
# Normal Categories contain actial files and do not depend on other things.
our @NormalCategories = qw/Package TLCore ConTeXt/;
#
# list of all Categories
our @Categories = (@MetaCategories, @NormalCategories);

# repeat, as a regexp.
our $CategoriesRegexp = '(Collection|Scheme|Package|TLCore|ConTeXt)';

our $DefaultCategory = "Package";

# location of various infra files (texlive.tlpdb, .tlpobj etc)
# relative to a root (e.g., the Master/, or the installation path)
our $InfraLocation = "tlpkg";
our $DatabaseName = "texlive.tlpdb";
our $DatabaseLocation = "$InfraLocation/$DatabaseName";

# location of backups in default autobackup setting (under tlpkg)
our $PackageBackupDir = "$InfraLocation/backups";

# for computing disk usage; this is most common.
our $BlockSize = 4096;

# timeout for network connections (wget, LWP) in seconds
our $NetworkTimeout = 30;
# number of errors during an LWP session until it is marked as disabled
our $MaxLWPErrors = 5;
# max number of times we reenable LWP after it was disabled
our $MaxLWPReinitCount = 10;

our $Archive = "archive";
our $TeXLiveServerURL = "https://mirror.ctan.org";
our $TeXLiveServerURLRegexp = 'https?://mirror\.ctan\.org';
# from 2009 on we try to put them all into tlnet directly without any
# release year since we hope that we can switch over to 2010 on the fly
# our $TeXLiveServerPath = "systems/texlive/tlnet/$ReleaseYear";
our $TeXLiveServerPath = "systems/texlive/tlnet";
our $TeXLiveURL = "$TeXLiveServerURL/$TeXLiveServerPath";

# Relocatable packages.
our $RelocTree = "texmf-dist";
our $RelocPrefix = "RELOC";

our @CriticalPackagesList = qw/texlive.infra/;
our $CriticalPackagesRegexp = '^(texlive\.infra)';
if ($^O =~ /^MSWin/i) {
  push (@CriticalPackagesList, "tlperl.win32");
  $CriticalPackagesRegexp = '^(texlive\.infra|tlperl\.win32$)';
}

#
our @AcceptedFallbackDownloaders = qw/curl wget/;
our %FallbackDownloaderProgram = ( 'wget' => 'wget', 'curl' => 'curl');
our %FallbackDownloaderArgs = (
  'curl' => ['--user-agent', 'texlive/curl',
             '--retry', '4', '--retry-delay', '4',
             '--connect-timeout', "$NetworkTimeout", 
             '--fail', '--location', '--silent', '--output'],
  'wget' => ['--user-agent=texlive/wget', '--tries=4',
             "--timeout=$NetworkTimeout", '-q', '-O'],
);
# the way we package things on the web
our $DefaultCompressorFormat = "xz";
# priority defines which compressor is selected for backups/rollback containers
# less is better
our %Compressors = (
  "lz4" => {
    "decompress_args" => ["-dcf"],
    "compress_args"   => ["-zfmq"],
    "extension"       => "lz4",
    "priority"        => 10,
  },
  "gzip" => {
    "decompress_args" => ["-dcf"],
    "compress_args"   => ["-f"],
    "extension"       => "gz",
    "priority"        => 20,
  },
  "xz" => {
    "decompress_args" => ["-dcf"],
    "compress_args"   => ["-zf"],
    "extension"       => "xz",
    "priority"        => 30,
  },
);
our $CompressorExtRegexp = "("
    . join("|", map { $Compressors{$_}{'extension'} } keys %Compressors)
    . ")";

# archive (not user) settings.
# these can be overridden by putting them into 00texlive.config.tlpsrc
# in the format
#   depend key/value
our %TLPDBConfigs = (
  "container_split_src_files" => 1,
  "container_split_doc_files" => 1,
  "container_format" => $DefaultCompressorFormat,
  "minrelease" => $MinRelease,
  "release" => $ReleaseYear,
  "frozen" => 0,
);

# definition of the option strings and their value types 
# possible types are:
# - u: url
# - b: boolean, saved as 0/1
# - p: path (local path)
# - n: natural number
#      it allows n:[a]..[b]
#         if a is empty start at -infty
#         if b is empty end at +infty
#      so "n:.." is equivalent to "n"

# $TLPDBOptions{"option"}->[0] --> type
#                        ->[1] --> default value
#                        ->[2] --> tlmgr name
#                        ->[3] --> tlmgr description
# the "option" is the value in the TLPDB

our %TLPDBOptions = (
  "autobackup" =>
    [ "n:-1..", 1, "autobackup",
      "Number of backups to keep" ],
  "backupdir" =>
    [ "p", $PackageBackupDir, "backupdir",
      "Directory for backups" ],
  "create_formats" =>
    [ "b", 1, "formats",  
      "Generate formats at installation or update" ],
  "desktop_integration" =>
    [ "b", 1, "desktop_integration",
      "Create Start menu shortcuts (w32)" ],
  "file_assocs" =>
    [ "n:0..2", 1, "fileassocs",
      "Change file associations (w32)" ],
  "generate_updmap" =>
    [ "b", 0, "generate_updmap",
      "Run tlmgr generate updmap after maps have changed" ],
  "install_docfiles" =>
    [ "b", 1, "docfiles",
      "Install documentation files" ],
  "install_srcfiles" =>
    [ "b", 1, "srcfiles",
      "Install source files" ],
  "location" =>
    [ "u", "__MASTER__", "repository", 
      "Default package repository" ],
  "post_code" =>
    [ "b", 1, "postcode",
      "Run postinst code blobs" ],
  "sys_bin" =>
    [ "p", "/usr/local/bin", "sys_bin",
      "Destination for symlinks for binaries" ],
  "sys_info" =>
    [ "p", "/usr/local/share/info", "sys_info",
      "Destination for symlinks for info docs" ],
  "sys_man" =>
    [ "p", "/usr/local/share/man", "sys_man",
      "Destination for symlinks for man pages" ],
  "w32_multi_user" =>
    [ "b", 1, "multiuser",
      "Install for all users (w32)" ],
);


our %TLPDBSettings = (
  "platform" => [ "s", "Main platform for this computer" ],
  "available_architectures" => [ "l","All available/installed architectures" ],
  "usertree" => [ "b", "This tree acts as user tree" ]
);

our $WindowsMainMenuName = "TeX Live $ReleaseYear";

# Comma-separated list of engines which do not exist on all platforms.
our $PartialEngineSupport = "luajithbtex,luajittex,mfluajit";

# Flags for error handling across the scripts and modules
# all fine
our $F_OK = 0;
#
# some warnings, but we still try to run post actions
our $F_WARNING = 1;
#
# error, terminating
our $F_ERROR = 2;
#
# all fine, but no need to run post actions
our $F_NOPOSTACTION = 4;

# The length of a checksum generated by tlchecksum and contained in
# texlive.tlpdb.checksum. Needs to be in agreement with the hash
# method used in TLCrypto::tlchecksum and TLCrypto::tldigest
our $ChecksumLength = 128;

# The program generating the checksum for the file given as first
# argument
our $ChecksumProgram = "sha512sum";

# The extension of the checksum file
our $ChecksumExtension = "sha512";

1;


=head1 NAME

C<TeXLive::TLConfig> -- TeX Live configuration parameters

=head1 SYNOPSIS

  use TeXLive::TLConfig;

=head1 DESCRIPTION

The L<TeXLive::TLConfig> module contains definitions of variables 
configuring all of TeX Live.

=head2 EXPORTED VARIABLES

All of the following variables are pulled into the callers namespace,
i.e., are declared with C<EXPORT> (and C<EXPORT_OK>).

=over 4

=item C<@TeXLive::TLConfig::MetaCategories>

The list of meta categories, i.e., those categories whose packages only
depend on other packages, but don't ship any files. Currently 
C<Collection> and <Scheme>.

=item C<@TeXLive::TLConfig::NormalCategories>

The list of normal categories, i.e., those categories whose packages do
ship files. Currently C<TLCore>, C<Package>, C<ConTeXt>.

=item C<@TeXLive::TLConfig::Categories>

The list of all categories, i.e., the union of the above.

=item C<$TeXLive::TLConfig::CategoriesRegexp>

A regexp matching any category.

=item C<$TeXLive::TLConfig::DefaultCategory>

The default category used when creating new packages.

=item C<$TeXLive::TLConfig::InfraLocation>

The subdirectory with various infrastructure files (C<texlive.tlpdb>,
tlpobj files, ...) relative to the root of the installation; currently
C<tlpkg>.

=item C<$TeXLive::TLConfig::DatabaseName>

The name of our so-called database file: C<texlive.tlpdb>. It's just a
plain text file, not any kind of relational or other database.

=item C<$TeXLive::TLConfig::DatabaseLocation>

Concatenation of C<InfraLocation> "/" C<DatabaseName>, i.e.,
C<tlpkg/texlive.tlpdb>.

=item C<$TeXLive::TLConfig::BlockSize>

The assumed block size, currently 4k.

=item C<$TeXLive::TLConfig::Archive>
=item C<$TeXLive::TLConfig::TeXLiveURL>

These values specify where to find packages.

=item C<$TeXLive::TLConfig::TeXLiveServerURL>
=item C<$TeXLive::TLConfig::TeXLiveServerURLRegexp>
=item C<$TeXLive::TLConfig::TeXLiveServerPath>

C<TeXLiveURL> is concatenated from these values, with a string between.
The defaults are respectively, C<https://mirror.ctan.org> and
C<systems/texlive/tlnet/>.

=item C<@TeXLive::TLConfig::CriticalPackagesList>
=item C<@TeXLive::TLConfig::CriticalPackagesRegexp>

A list of all those packages which we do not update regularly since they
are too central, currently texlive.infra and (for Windows) tlperl.win32.

=item C<$TeXLive::TLConfig::RelocTree>

The texmf-tree name that can be relocated, defaults to C<texmf-dist>.

=item C<$TeXLive::TLConfig::RelocPrefix>

The string that replaces the C<RelocTree> in the tlpdb if a package is
relocated, defaults to C<RELOC>".

=back

=head1 SEE ALSO

All the other TeX Live modules and scripts, especially C<tlmgr> and
C<install-tl>, and the documentation in the repository:
C<Master/tlpkg/doc/>.

=head1 AUTHORS AND COPYRIGHT

This script and its documentation were written for the TeX Live
distribution (L<https://tug.org/texlive>) and both are licensed under the
GNU General Public License Version 2 or later.

=cut

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;
}
BEGIN {
# $Id$
# TeXLive::TLUtils.pm - the inevitable utilities for TeX Live.
# Copyright 2007-2021 Norbert Preining, Reinhard Kotucha
# This file is licensed under the GNU General Public License version 2
# or any later version.

package TeXLive::TLUtils;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }

=pod

=head1 NAME

C<TeXLive::TLUtils> - TeX Live infrastructure miscellany

=head1 SYNOPSIS

  use TeXLive::TLUtils;

=head2 Platform detection

  TeXLive::TLUtils::platform();
  TeXLive::TLUtils::platform_name($canonical_host);
  TeXLive::TLUtils::platform_desc($platform);
  TeXLive::TLUtils::win32();
  TeXLive::TLUtils::unix();

=head2 System tools

  TeXLive::TLUtils::getenv($string);
  TeXLive::TLUtils::which($string);
  TeXLive::TLUtils::initialize_global_tmpdir();
  TeXLive::TLUtils::tl_tmpdir();
  TeXLive::TLUtils::tl_tmpfile();
  TeXLive::TLUtils::xchdir($dir);
  TeXLive::TLUtils::wsystem($msg,@args);
  TeXLive::TLUtils::xsystem(@args);
  TeXLive::TLUtils::run_cmd($cmd);
  TeXLive::TLUtils::system_pipe($prog, $infile, $outfile, $removeIn, @args);

=head2 File utilities

  TeXLive::TLUtils::dirname($path);
  TeXLive::TLUtils::basename($path);
  TeXLive::TLUtils::dirname_and_basename($path);
  TeXLive::TLUtils::tl_abs_path($path);
  TeXLive::TLUtils::dir_writable($path);
  TeXLive::TLUtils::dir_creatable($path);
  TeXLive::TLUtils::mkdirhier($path);
  TeXLive::TLUtils::rmtree($root, $verbose, $safe);
  TeXLive::TLUtils::copy($file, $target_dir);
  TeXLive::TLUtils::touch(@files);
  TeXLive::TLUtils::collapse_dirs(@files);
  TeXLive::TLUtils::removed_dirs(@files);
  TeXLive::TLUtils::download_file($path, $destination);
  TeXLive::TLUtils::setup_programs($bindir, $platform);
  TeXLive::TLUtils::tlcmp($file, $file);
  TeXLive::TLUtils::nulldev();
  TeXLive::TLUtils::get_full_line($fh);

=head2 Installer functions

  TeXLive::TLUtils::make_var_skeleton($path);
  TeXLive::TLUtils::make_local_skeleton($path);
  TeXLive::TLUtils::create_fmtutil($tlpdb,$dest);
  TeXLive::TLUtils::create_updmap($tlpdb,$dest);
  TeXLive::TLUtils::create_language_dat($tlpdb,$dest,$localconf);
  TeXLive::TLUtils::create_language_def($tlpdb,$dest,$localconf);
  TeXLive::TLUtils::create_language_lua($tlpdb,$dest,$localconf);
  TeXLive::TLUtils::time_estimate($totalsize, $donesize, $starttime)
  TeXLive::TLUtils::install_packages($from_tlpdb,$media,$to_tlpdb,$what,$opt_src, $opt_doc)>);
  TeXLive::TLUtils::do_postaction($how, $tlpobj, $do_fileassocs, $do_menu, $do_desktop, $do_script);
  TeXLive::TLUtils::announce_execute_actions($how, @executes, $what);
  TeXLive::TLUtils::add_symlinks($root, $arch, $sys_bin, $sys_man, $sys_info);
  TeXLive::TLUtils::remove_symlinks($root, $arch, $sys_bin, $sys_man, $sys_info);
  TeXLive::TLUtils::w32_add_to_path($bindir, $multiuser);
  TeXLive::TLUtils::w32_remove_from_path($bindir, $multiuser);
  TeXLive::TLUtils::setup_persistent_downloads();

=head2 Logging and debugging

  TeXLive::TLUtils::info($str1, ...);    # output unless -q
  TeXLive::TLUtils::debug($str1, ...);   # output if -v
  TeXLive::TLUtils::ddebug($str1, ...);  # output if -vv
  TeXLive::TLUtils::dddebug($str1, ...); # output if -vvv
  TeXLive::TLUtils::log($str1, ...);     # only to log file
  TeXLive::TLUtils::tlwarn($str1, ...);  # warn on stderr and log
  TeXLive::TLUtils::tldie($str1, ...);   # tlwarn and die
  TeXLive::TLUtils::debug_hash_str($label, HASH); # stringified HASH
  TeXLive::TLUtils::debug_hash($label, HASH);   # warn stringified HASH
  TeXLive::TLUtils::backtrace();                # return call stack as string
  TeXLive::TLUtils::process_logging_options($texdir); # handle -q -v* -logfile

=head2 Miscellaneous

  TeXLive::TLUtils::sort_uniq(@list);
  TeXLive::TLUtils::push_uniq(\@list, @items);
  TeXLive::TLUtils::member($item, @list);
  TeXLive::TLUtils::merge_into(\%to, \%from);
  TeXLive::TLUtils::texdir_check($texdir);
  TeXLive::TLUtils::quotify_path_with_spaces($path);
  TeXLive::TLUtils::conv_to_w32_path($path);
  TeXLive::TLUtils::native_slashify($internal_path);
  TeXLive::TLUtils::forward_slashify($path_from_user);
  TeXLive::TLUtils::give_ctan_mirror();
  TeXLive::TLUtils::give_ctan_mirror_base();
  TeXLive::TLUtils::compare_tlpobjs($tlpA, $tlpB);
  TeXLive::TLUtils::compare_tlpdbs($tlpdbA, $tlpdbB);
  TeXLive::TLUtils::report_tlpdb_differences(\%ret);
  TeXLive::TLUtils::tlnet_disabled_packages($root);
  TeXLive::TLUtils::mktexupd();
  TeXLive::TLUtils::setup_sys_user_mode($optsref,$tmfc, $tmfsc, $tmfv, $tmfsv);
  TeXLive::TLUtils::prepend_own_path();
  TeXLive::TLUtils::repository_to_array($str);

=head2 JSON

  TeXLive::TLUtils::encode_json($ref);
  TeXLive::TLUtils::True();
  TeXLive::TLUtils::False();

=head1 DESCRIPTION

=cut

# avoid -warnings.
our $PERL_SINGLE_QUOTE; # we steal code from Text::ParseWords
use vars qw(
  $::LOGFILE $::LOGFILENAME @::LOGLINES 
    @::debug_hook @::ddebug_hook @::dddebug_hook @::info_hook 
    @::install_packages_hook @::warn_hook
  $TeXLive::TLDownload::net_lib_avail
    $::checksum_method $::gui_mode $::machinereadable $::no_execute_actions
    $::regenerate_all_formats
  $JSON::false $JSON::true
);

BEGIN {
  use Exporter ();
  use vars qw(@ISA @EXPORT_OK @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(
    &platform
    &platform_name
    &platform_desc
    &unix
    &getenv
    &which
    &initialize_global_tmpdir
    &dirname
    &basename
    &dirname_and_basename
    &tl_abs_path
    &dir_writable
    &dir_creatable
    &mkdirhier
    &rmtree
    &copy
    &touch
    &collapse_dirs
    &removed_dirs
    &install_package
    &install_packages
    &make_var_skeleton
    &make_local_skeleton
    &create_fmtutil
    &create_updmap
    &create_language_dat
    &create_language_def
    &create_language_lua
    &parse_AddFormat_line
    &parse_AddHyphen_line
    &sort_uniq
    &push_uniq
    &texdir_check
    &member
    &quotewords
    &quotify_path_with_spaces
    &conv_to_w32_path
    &native_slashify
    &forward_slashify
    &untar
    &unpack
    &merge_into
    &give_ctan_mirror
    &give_ctan_mirror_base
    &create_mirror_list
    &extract_mirror_entry
    &wsystem
    &xsystem
    &run_cmd
    &system_pipe
    &announce_execute_actions
    &add_symlinks
    &remove_symlinks
    &w32_add_to_path
    &w32_remove_from_path
    &tlcmp
    &time_estimate
    &compare_tlpobjs
    &compare_tlpdbs
    &report_tlpdb_differences
    &setup_persistent_downloads
    &mktexupd
    &setup_sys_user_mode
    &prepend_own_path
    &nulldev
    &get_full_line
    &sort_archs
    &repository_to_array
    &encode_json
    &True
    &False
    &SshURIRegex
  );
  @EXPORT = qw(setup_programs download_file process_logging_options
               tldie tlwarn info log debug ddebug dddebug debug
               debug_hash_str debug_hash
               win32 xchdir xsystem run_cmd system_pipe sort_archs);
}

use Cwd;
use Getopt::Long;
use File::Temp;

use TeXLive::TLConfig;

$::opt_verbosity = 0;  # see process_logging_options

our $SshURIRegex = '^((ssh|scp)://([^@]*)@([^/]*)/|([^@]*)@([^:]*):).*$';

=head2 Platform detection

=over 4

=item C<platform>

If C<$^O =~ /MSWin/i> is true we know that we're on
Windows and we set the global variable C<$::_platform_> to C<win32>.
Otherwise we call C<platform_name> with the output of C<config.guess>
as argument.

The result is stored in a global variable C<$::_platform_>, and
subsequent calls just return that value.

As of 2021, C<config.guess> unfortunately requires a shell that
understands the C<$(...)> construct. This means that on old-enough
systems, such as Solaris, we have to look for a shell. We use the value
of the C<CONFIG_SHELL> environment variable if it is set, else
C</bin/ksh> if it exists, else C</bin/bash> if it exists, else give up.

=cut

sub platform {
  unless (defined $::_platform_) {
    if ($^O =~ /^MSWin/i) {
      $::_platform_ = "win32";
    } else {
      my $config_guess = "$::installerdir/tlpkg/installer/config.guess";

      # For example, if the disc or reader has hardware problems.
      die "$0: config.guess script does not exist, goodbye: $config_guess"
        if ! -r $config_guess;

      # We cannot rely on #! in config.guess but have to call /bin/sh
      # explicitly because sometimes the 'noexec' flag is set in
      # /etc/fstab for ISO9660 file systems.
      # 
      # In addition, config.guess was (unnecessarily) changed in 2020 by
      # to use $(...) instead of `...`, although $(...) is not supported
      # by Solaris /bin/sh (and others). The maintainers have declined
      # to revert the change, so now every caller of config.guess must
      # laboriously find a usable shell. Sigh.
      # 
      my $config_shell = $ENV{"CONFIG_SHELL"} || "/bin/sh";
      #
      # check if $(...) is supported:
      my $paren_cmdout = `'$config_shell' -c 'echo \$(echo foo)' 2>/dev/null`;
      #warn "paren test out: `$paren_cmdout'.\n";
      #
      # The echo command might output a newline (maybe CRLF?) even if
      # the $(...) fails, so don't just check for non-empty output.
      # Maybe checking exit status would be better, but maybe not.
      # 
      if (length ($paren_cmdout) <= 2) {
        # if CONFIG_SHELL is set to something bad, give up.
        if ($ENV{"CONFIG_SHELL"}) {
          die <<END_BAD_CONFIG_SHELL;
$0: the CONFIG_SHELL environment variable is set to $ENV{CONFIG_SHELL}
  but this cannot execute \$(...) shell constructs,
  which is required. Set CONFIG_SHELL to something that works.
END_BAD_CONFIG_SHELL

        } elsif (-x "/bin/ksh") {
          $config_shell = "/bin/ksh";

        } elsif (-x "/bin/bash") {
          $config_shell = "/bin/bash";

        } else {
          die <<END_NO_PAREN_CMDS_SHELL
$0: can't find shell to execute $config_guess
  (which gratuitously requires support for \$(...) command substitution).
  Tried $config_shell, /bin/ksh, bin/bash.
  Set the environment variable CONFIG_SHELL to specify explicitly.
END_NO_PAREN_CMDS_SHELL
        }
      }
      #warn "executing config.guess with $config_shell\n";
      chomp (my $guessed_platform = `'$config_shell' '$config_guess'`);

      # If we didn't get anything usable, give up.
      die "$0: could not run $config_guess, cannot proceed, sorry"
        if ! $guessed_platform;

      $::_platform_ = platform_name($guessed_platform);
    }
  }
  return $::_platform_;
}


=item C<platform_name($canonical_host)>

Convert the C<$canonical_host> argument, a system description as
returned by C<config.guess>, into a TeX Live platform name, that is, a
name used as a subdirectory of our C<bin/> dir. Our names have the
form CPU-OS, for example, C<x86_64-linux>.

We need this because what's returned from C<config.,guess> does not
match our historical names, e.g., C<config.guess> returns C<linux-gnu>
but we need C<linux>.

The C<CPU> part of our name is always taken from the argument, with
various transformation.

For the C<OS> part, if the environment variable C<TEXLIVE_OS_NAME> is
set, it is used as-is. Otherwise we do our best to figure it out.

This function still handles old systems which are no longer supported,
just in case.

=cut

sub platform_name {
  my ($orig_platform) = @_;
  my $guessed_platform = $orig_platform;

  # try to parse out some bsd variants that use amd64.
  # We throw away everything after the "bsd" to elide version numbers,
  # as in amd64-unknown-midnightbsd1.2.
  $guessed_platform =~ s/^x86_64-(.*-k?)(free|net)bsd/amd64-$1$2bsd/;
  my $CPU; # CPU type as reported by config.guess.
  my $OS;  # O/S type as reported by config.guess.
  ($CPU = $guessed_platform) =~ s/(.*?)-.*/$1/;

  $CPU =~ s/^alpha(.*)/alpha/;   # alphaev whatever
  $CPU =~ s/mips64el/mipsel/;    # don't distinguish mips64 and 32 el
  $CPU =~ s/powerpc64/powerpc/;  # don't distinguish ppc64
  $CPU =~ s/sparc64/sparc/;      # don't distinguish sparc64

  # armv6l-unknown-linux-gnueabihf -> armhf-linux (RPi)
  # armv7l-unknown-linux-gnueabi   -> armel-linux (Android)
  if ($CPU =~ /^arm/) {
    $CPU = $guessed_platform =~ /hf$/ ? "armhf" : "armel";
  }

  if ($ENV{"TEXLIVE_OS_NAME"}) {
    $OS = $ENV{"TEXLIVE_OS_NAME"};
  } else {
    my @OSs = qw(aix cygwin darwin dragonfly freebsd hpux irix
                 kfreebsd linux midnightbsd netbsd openbsd solaris);
    for my $os (@OSs) {
      # Match word boundary at the beginning of the os name so that
      #   freebsd and kfreebsd are distinguished.
      # Do not match word boundary at the end of the os so that
      #   solaris2 is matched.
      $OS = $os if $guessed_platform =~ /\b$os/;
    }
  }  

  if (! $OS) {
    warn "$0: could not guess OS from config.guess string: $orig_platform";
    $OS = "unknownOS";
  }
  
  if ($OS eq "linux") {
    # deal with the special case of musl based distributions
    # config.guess returns
    #   x86_64-pc-linux-musl
    #   i386-pc-linux-musl
    $OS = "linuxmusl" if $guessed_platform =~ /\blinux-musl/;
  }
  
  if ($OS eq "darwin") {
    # We have two versions of Mac binary sets.
    # 10.x and newer -> universal-darwin [MacTeX]
    # 10.6/Snow Leopard through 10.x -> x86_64-darwinlegacy, if 64-bit.
    # x changes every year. As of TL 2021 (Big Sur) Apple started with 11.x.
    #
    # (BTW, uname -r numbers are larger by 4 than the Mac minor version.
    # We don't use uname numbers here.)
    #
    # this changes each year, per above:
    my $mactex_darwin = 14;  # lowest minor rev supported by x86_64-darwin.
    #
    # Most robust approach is apparently to check sw_vers (os version,
    # returns "10.x" values), and sysctl (processor hardware).
    chomp (my $sw_vers = `sw_vers -productVersion`);
    my ($os_major,$os_minor) = split (/\./, $sw_vers);
    if ($os_major < 10) {
      warn "$0: only MacOSX is supported, not $OS $os_major.$os_minor "
           . " (from sw_vers -productVersion: $sw_vers)\n";
      return "unknownmac-unknownmac";
    }
    # have to refine after all 10.x become "legacy".
    if ($os_major >= 11 || $os_minor >= $mactex_darwin) {
      $CPU = "universal";
      $OS = "darwin";
    } elsif ($os_major == 10 && 6 <= $os_minor && $os_minor < $mactex_darwin){
      # in between, x86 hardware only.  On 10.6 only, must check if 64-bit,
      # since if later than that, always 64-bit.
      my $is64 = $os_minor == 6
                 ? `/usr/sbin/sysctl -n hw.cpu64bit_capable` >= 1
                 : 1;
      if ($is64) {
        $CPU = "x86_64";
        $OS = "darwinlegacy";
      } # if not 64-bit, default is ok (i386-darwin).
    } else {
      ; # older version, default is ok (i386-darwin, powerpc-darwin).
    }
    
  } elsif ($CPU =~ /^i.86$/) {
    $CPU = "i386";  # 586, 686, whatever
  }

  if (! defined $OS) {
    ($OS = $guessed_platform) =~ s/.*-(.*)/$1/;
  }

  return "$CPU-$OS";
}

=item C<platform_desc($platform)>

Return a string which describes a particular platform identifier, e.g.,
given C<i386-linux> we return C<Intel x86 with GNU/Linux>.

=cut

sub platform_desc {
  my ($platform) = @_;

  my %platform_name = (
    'aarch64-linux'    => 'GNU/Linux on ARM64',
    'alpha-linux'      => 'GNU/Linux on DEC Alpha',
    'amd64-freebsd'    => 'FreeBSD on x86_64',
    'amd64-kfreebsd'   => 'GNU/kFreeBSD on x86_64',
    'amd64-midnightbsd'=> 'MidnightBSD on x86_64',
    'amd64-netbsd'     => 'NetBSD on x86_64',
    'armel-linux'      => 'GNU/Linux on ARM',
    'armhf-linux'      => 'GNU/Linux on ARMv6/RPi',
    'hppa-hpux'        => 'HP-UX',
    'i386-cygwin'      => 'Cygwin on Intel x86',
    'i386-darwin'      => 'MacOSX legacy (10.5-10.6) on Intel x86',
    'i386-freebsd'     => 'FreeBSD on Intel x86',
    'i386-kfreebsd'    => 'GNU/kFreeBSD on Intel x86',
    'i386-linux'       => 'GNU/Linux on Intel x86',
    'i386-linuxmusl'   => 'GNU/Linux on Intel x86 with musl',
    'i386-netbsd'      => 'NetBSD on Intel x86',
    'i386-openbsd'     => 'OpenBSD on Intel x86',
    'i386-solaris'     => 'Solaris on Intel x86',
    'mips-irix'        => 'SGI IRIX',
    'mipsel-linux'     => 'GNU/Linux on MIPSel',
    'powerpc-aix'      => 'AIX on PowerPC',
    'powerpc-darwin'   => 'MacOSX legacy (10.5) on PowerPC',
    'powerpc-linux'    => 'GNU/Linux on PowerPC',
    'sparc-linux'      => 'GNU/Linux on Sparc',
    'sparc-solaris'    => 'Solaris on Sparc',
    'universal-darwin' => 'MacOSX current (10.14-) on ARM/x86_64',
    'win32'            => 'Windows',
    'x86_64-cygwin'    => 'Cygwin on x86_64',
    'x86_64-darwinlegacy' => 'MacOSX legacy (10.6-) on x86_64',
    'x86_64-dragonfly' => 'DragonFlyBSD on x86_64',
    'x86_64-linux'     => 'GNU/Linux on x86_64',
    'x86_64-linuxmusl' => 'GNU/Linux on x86_64 with musl',
    'x86_64-solaris'   => 'Solaris on x86_64',
  );

  # the inconsistency between amd64-freebsd and x86_64-linux is
  # unfortunate (it's the same hardware), but the os people say those
  # are the conventional names on the respective os's, so we follow suit.

  if (exists $platform_name{$platform}) {
    return "$platform_name{$platform}";
  } else {
    my ($CPU,$OS) = split ('-', $platform);
    return "$CPU with " . ucfirst "$OS";
  }
}


=item C<win32>

Return C<1> if platform is Windows and C<0> otherwise.  The test is
currently based on the value of Perl's C<$^O> variable.

=cut

sub win32 {
  if ($^O =~ /^MSWin/i) {
    return 1;
  } else {
    return 0;
  }
  # the following needs config.guess, which is quite bad ...
  # return (&platform eq "win32")? 1:0;
}


=item C<unix>

Return C<1> if platform is UNIX and C<0> otherwise.

=cut

sub unix {
  return (&platform eq "win32")? 0:1;
}


=back

=head2 System Tools

=over 4

=item C<getenv($string)>

Get an environment variable.  It is assumed that the environment
variable contains a path.  On Windows all backslashes are replaced by
forward slashes as required by Perl.  If this behavior is not desired,
use C<$ENV{"$variable"}> instead.  C<0> is returned if the
environment variable is not set.

=cut

sub getenv {
  my $envvar=shift;
  my $var=$ENV{"$envvar"};
  return 0 unless (defined $var);
  if (&win32) {
    $var=~s!\\!/!g;  # change \ -> / (required by Perl)
  }
  return "$var";
}


=item C<which($string)>

C<which> does the same as the UNIX command C<which(1)>, but it is
supposed to work on Windows too.  On Windows we have to try all the
extensions given in the C<PATHEXT> environment variable.  We also try
without appending an extension because if C<$string> comes from an
environment variable, an extension might already be present.

=cut

sub which {
  my ($prog) = @_;
  my @PATH;
  my $PATH = getenv('PATH');

  if (&win32) {
    my @PATHEXT = split (';', getenv('PATHEXT'));
    push (@PATHEXT, '');  # in case argument contains an extension
    @PATH = split (';', $PATH);
    for my $dir (@PATH) {
      for my $ext (@PATHEXT) {
        if (-f "$dir/$prog$ext") {
          return "$dir/$prog$ext";
        }
      }
    }

  } else { # not windows
    @PATH = split (':', $PATH);
    for my $dir (@PATH) {
      if (-x "$dir/$prog") {
        return "$dir/$prog";
      }
    }
  }
  return 0;
}

=item C<initialize_global_tmpdir();>

Initializes a directory for all temporary files. This uses C<File::Temp>
and thus honors various env variables like  C<TMPDIR>, C<TMP>, and C<TEMP>.

=cut

sub initialize_global_tmpdir {
  $::tl_tmpdir = File::Temp::tempdir(CLEANUP => 1);
  ddebug("TLUtils::initialize_global_tmpdir: creating global tempdir $::tl_tmpdir\n");
  return ($::tl_tmpdir);
}

=item C<tl_tmpdir>

Create a temporary directory which is removed when the program
is terminated.

=cut

sub tl_tmpdir {
  initialize_global_tmpdir() if (!defined($::tl_tmpdir));
  my $tmp = File::Temp::tempdir(DIR => $::tl_tmpdir, CLEANUP => 1);
  ddebug("TLUtils::tl_tmpdir: creating tempdir $tmp\n");
  return ($tmp);
}

=item C<tl_tmpfile>

Create a temporary file which is removed when the program
is terminated. Returns file handle and file name.
Arguments are passed on to C<File::Temp::tempfile>.

=cut

sub tl_tmpfile {
  initialize_global_tmpdir() if (!defined($::tl_tmpdir));
  my ($fh, $fn) = File::Temp::tempfile(@_, DIR => $::tl_tmpdir, UNLINK => 1);
  ddebug("TLUtils::tl_tempfile: creating tempfile $fn\n");
  return ($fh, $fn);
}


=item C<xchdir($dir)>

C<chdir($dir)> or die.

=cut

sub xchdir {
  my ($dir) = @_;
  chdir($dir) || die "$0: chdir($dir) failed: $!";
  ddebug("xchdir($dir) ok\n");
}


=item C<wsystem($msg, @args)>

Call C<info> about what is being done starting with C<$msg>, then run
C<system(@args)>; C<tlwarn> if unsuccessful and return the exit status.

=cut

sub wsystem {
  my ($msg,@args) = @_;
  info("$msg @args ...\n");
  my $retval = system(@args);
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    tlwarn("$0:  command failed (status $retval): @args: $!\n");
  }
  return $retval;
}


=item C<xsystem(@args)>

Call C<ddebug> about what is being done, then run C<system(@args)>, and
die if unsuccessful.

=cut

sub xsystem {
  my (@args) = @_;
  ddebug("running system(@args)\n");
  my $retval = system(@args);
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    my $pwd = cwd ();
    die "$0: system(@args) failed in $pwd, status $retval";
  }
  return $retval;
}

=item C<run_cmd($cmd)>

Run shell command C<$cmd> and captures its output. Returns a list with CMD's
output as the first element and the return value (exit code) as second.

=cut

sub run_cmd {
  my $cmd = shift;
  my $output = `$cmd`;
  $output = "" if ! defined ($output);  # don't return undef

  my $retval = $?;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
  }
  return ($output,$retval);
}

=item C<system_pipe($prog, $infile, $outfile, $removeIn, @extraargs)>

Runs C<$prog> with C<@extraargs> redirecting stdin from C<$infile>,
stdout to C<$outfile>. Removes C<$infile> if C<$removeIn> is true.

=cut

sub system_pipe {
  my ($prog, $infile, $outfile, $removeIn, @extraargs) = @_;
  
  my $progQuote = quotify_path_with_spaces($prog);
  if (win32()) {
    $infile =~ s!/!\\!g;
    $outfile =~ s!/!\\!g;
  }
  my $infileQuote = "\"$infile\"";
  my $outfileQuote = "\"$outfile\"";
  debug("TLUtils::system_pipe: calling $progQuote @extraargs < $infileQuote > $outfileQuote\n");
  my $retval = system("$progQuote @extraargs < $infileQuote > $outfileQuote");
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    debug("TLUtils::system_pipe: system exit code = $retval\n");
    return 0;
  } else {
    if ($removeIn) {
      debug("TLUtils::system_pipe: removing $infile\n");
      unlink($infile);
    }
    return 1;
  }
}

=back

=head2 File utilities

=over 4

=item C<dirname_and_basename($path)>

Return both C<dirname> and C<basename>.  Example:

  ($dirpart,$filepart) = dirname_and_basename ($path);

=cut

sub dirname_and_basename {
  my $path=shift;
  my ($share, $base) = ("", "");
  if (win32) {
    $path=~s!\\!/!g;
  }
  # do not try to make sense of paths ending with /..
  return (undef, undef) if $path =~ m!/\.\.$!;
  if ($path=~m!/!) {   # dirname("foo/bar/baz") -> "foo/bar"
    # eliminate `/.' path components
    while ($path =~ s!/\./!/!) {};
    # UNC path? => first split in $share = //xxx/yy and $path = /zzzz
    if (win32() and $path =~ m!^(//[^/]+/[^/]+)(.*)$!) {
      ($share, $path) = ($1, $2);
      if ($path =~ m!^/?$!) {
        $path = $share;
        $base = "";
      } elsif ($path =~ m!(/.*)/(.*)!) {
        $path = $share.$1;
        $base = $2;
      } else {
        $base = $path;
        $path = $share;
      }
      return ($path, $base);
    }
    # not a UNC path
    $path=~m!(.*)/(.*)!; # works because of greedy matching
    return ((($1 eq '') ? '/' : $1), $2);
  } else {             # dirname("ignore") -> "."
    return (".", $path);
  }
}


=item C<dirname($path)>

Return C<$path> with its trailing C</component> removed.

=cut

sub dirname {
  my $path = shift;
  my ($dirname, $basename) = dirname_and_basename($path);
  return $dirname;
}


=item C<basename($path)>

Return C<$path> with any leading directory components removed.

=cut

sub basename {
  my $path = shift;
  my ($dirname, $basename) = dirname_and_basename($path);
  return $basename;
}


=item C<tl_abs_path($path)>

# Other than Cwd::abs_path, tl_abs_path also works if the argument does not
# yet exist as long as the path does not contain '..' components.

=cut

sub tl_abs_path {
  my $path = shift;
  if (win32) {
    $path=~s!\\!/!g;
  }
  if (-e $path) {
    $path = Cwd::abs_path($path);
  } elsif ($path eq '.') {
    $path = Cwd::getcwd();
  } else{
    # collapse /./ components
    $path =~ s!/\./!/!g;
    # no support for .. path components or for win32 long-path syntax
    # (//?/ path prefix)
    die "Unsupported path syntax" if $path =~ m!/\.\./! || $path =~ m!/\.\.$!
      || $path =~ m!^\.\.!;
    die "Unsupported path syntax" if win32() && $path =~ m!^//\?/!;
    if ($path !~ m!^(.:)?/!) { # relative path
      if (win32() && $path =~ /^.:/) { # drive letter
        my $dcwd;
        # starts with drive letter: current dir on drive
        $dcwd = Cwd::getdcwd ($1);
        $dcwd .= '/' unless $dcwd =~ m!/$!;
        return $dcwd.$path;
      } else { # relative path without drive letter
        my $cwd = Cwd::getcwd();
        $cwd .= '/' unless $cwd =~ m!/$!;
        return $cwd . $path;
      }
    } # else absolute path
  }
  $path =~ s!/$!! unless $path =~ m!^(.:)?/$!;
  return $path;
}


=item C<dir_creatable($path)>

Tests whether its argument is a directory where we can create a directory.

=cut

sub dir_slash {
  my $d = shift;
  $d = "$d/" unless $d =~ m!/!;
  return $d;
}

# test whether subdirectories can be created in the argument
sub dir_creatable {
  my $path=shift;
  #print STDERR "testing $path\n";
  $path =~ s!\\!/!g if win32;
  return 0 unless -d $path;
  $path .= '/' unless $path =~ m!/$!;
  #print STDERR "testing $path\n";
  my $d;
  for my $i (1..100) {
    $d = "";
    # find a non-existent dirname
    $d = $path . int(rand(1000000));
    last unless -e $d;
  }
  if (!$d) {
    tlwarn("Cannot find available testdir name\n");
    return 0;
  }
  #print STDERR "creating $d\n";
  return 0 unless mkdir $d;
  return 0 unless -d $d;
  rmdir $d;
  return 1;
}


=item C<dir_writable($path)>

Tests whether its argument is writable by trying to write to
it. This function is necessary because the built-in C<-w> test just
looks at mode and uid/gid, which on Windows always returns true and
even on Unix is not always good enough for directories mounted from
a fileserver.

=cut

# The Unix test gives the wrong answer when used under Windows Vista
# with one of the `virtualized' directories such as Program Files:
# lacking administrative permissions, it would write successfully to
# the virtualized Program Files rather than fail to write to the
# real Program Files. Ugh.

sub dir_writable {
  my ($path) = @_;
  return 0 unless -d $path;
  $path =~ s!\\!/!g if win32;
  $path .= '/' unless $path =~ m!/$!;
  my $i = 0;
  my $f;
  for my $i (1..100) {
    $f = "";
    # find a non-existent filename
    $f = $path . int(rand(1000000));
    last unless -e $f;
  }
  if (!$f) {
    tlwarn("Cannot find available testfile name\n");
    return 0;
  }
  return 0 if ! open (TEST, ">$f");
  my $written = 0;
  $written = (print TEST "\n");
  close (TEST);
  unlink ($f);
  return $written;
}


=item C<mkdirhier($path, [$mode])>

The function C<mkdirhier> does the same as the UNIX command C<mkdir -p>.
It behaves differently depending on the context in which it is called:
If called in void context it will die on failure. If called in
scalar context, it will return 1/0 on sucess/failure. If called in
list context, it returns 1/0 as first element and an error message
as second, if an error occurred (and no second element in case of
success). The optional parameter sets the permission bits.

=cut

sub mkdirhier {
  my ($tree,$mode) = @_;
  my $ret = 1;
  my $reterror;

  if (-d "$tree") {
    $ret = 1;
  } else {
    my $subdir = "";
    # win32 is special as usual: we need to separate //servername/ part
    # from the UNC path, since (! -d //servername/) tests true
    $subdir = $& if ( win32() && ($tree =~ s!^//[^/]+/!!) );

    @dirs = split (/[\/\\]/, $tree);
    for my $dir (@dirs) {
      $subdir .= "$dir/";
      if (! -d $subdir) {
        if (defined $mode) {
          if (! mkdir ($subdir, $mode)) {
            $ret = 0;
            $reterror = "mkdir($subdir,$mode) failed: $!";
            last;
          }
        } else {
          if (! mkdir ($subdir)) {
            $ret = 0;
            $reterror = "mkdir($subdir) failed for tree $tree: $!";
            last;
          }
        }
      }
    }
  }
  if ($ret) {
    return(1);  # nothing bad here returning 1 in any case, will
                # be ignored in void context, and give 1 in list context
  } else {
    if (wantarray) {
      return(0, $reterror);
    } elsif (defined wantarray) {
      return(0);
    } else {
      die "$0: $reterror";
    }
  }
}


=item C<rmtree($root, $verbose, $safe)>

The C<rmtree> function provides a convenient way to delete a
subtree from the directory structure, much like the Unix command C<rm -r>.
C<rmtree> takes three arguments:

=over 4

=item *

the root of the subtree to delete, or a reference to
a list of roots.  All of the files and directories
below each root, as well as the roots themselves,
will be deleted.

=item *

a boolean value, which if TRUE will cause C<rmtree> to
print a message each time it examines a file, giving the
name of the file, and indicating whether it's using C<rmdir>
or C<unlink> to remove it, or that it's skipping it.
(defaults to FALSE)

=item *

a boolean value, which if TRUE will cause C<rmtree> to
skip any files to which you do not have delete access
(if running under VMS) or write access (if running
under another OS).  This will change in the future when
a criterion for 'delete permission' under OSs other
than VMS is settled.  (defaults to FALSE)

=back

It returns the number of files successfully deleted.  Symlinks are
simply deleted and not followed.

B<NOTE:> There are race conditions internal to the implementation of
C<rmtree> making it unsafe to use on directory trees which may be
altered or moved while C<rmtree> is running, and in particular on any
directory trees with any path components or subdirectories potentially
writable by untrusted users.

Additionally, if the third parameter is not TRUE and C<rmtree> is
interrupted, it may leave files and directories with permissions altered
to allow deletion (and older versions of this module would even set
files and directories to world-read/writable!)

Note also that the occurrence of errors in C<rmtree> can be determined I<only>
by trapping diagnostic messages using C<$SIG{__WARN__}>; it is not apparent
from the return value.

=cut

#taken from File/Path.pm
#
my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

# These OSes complain if you want to remove a file that you have no
# write permission to:
my $force_writeable = ($^O eq 'os2' || $^O eq 'dos' || $^O eq 'MSWin32' ||
		       $^O eq 'amigaos' || $^O eq 'MacOS' || $^O eq 'epoc');

sub rmtree {
  my($roots, $verbose, $safe) = @_;
  my(@files);
  my($count) = 0;
  $verbose ||= 0;
  $safe ||= 0;

  if ( defined($roots) && length($roots) ) {
    $roots = [$roots] unless ref $roots;
  } else {
    warn "No root path(s) specified";
    return 0;
  }

  my($root);
  foreach $root (@{$roots}) {
    if ($Is_MacOS) {
      $root = ":$root" if $root !~ /:/;
      $root =~ s#([^:])\z#$1:#;
    } else {
      $root =~ s#/\z##;
    }
    (undef, undef, my $rp) = lstat $root or next;
    $rp &= 07777;	# don't forget setuid, setgid, sticky bits
    if ( -d _ ) {
      # notabene: 0700 is for making readable in the first place,
      # it's also intended to change it to writable in case we have
      # to recurse in which case we are better than rm -rf for
      # subtrees with strange permissions
      chmod($rp | 0700, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
        or warn "Can't make directory $root read+writeable: $!"
          unless $safe;

      if (opendir my $d, $root) {
        no strict 'refs';
        if (!defined ${"\cTAINT"} or ${"\cTAINT"}) {
          # Blindly untaint dir names
          @files = map { /^(.*)$/s ; $1 } readdir $d;
        } else {
          @files = readdir $d;
        }
        closedir $d;
      } else {
        warn "Can't read $root: $!";
        @files = ();
      }
      # Deleting large numbers of files from VMS Files-11 filesystems
      # is faster if done in reverse ASCIIbetical order
      @files = reverse @files if $Is_VMS;
      ($root = VMS::Filespec::unixify($root)) =~ s#\.dir\z## if $Is_VMS;
      if ($Is_MacOS) {
        @files = map("$root$_", @files);
      } else {
        @files = map("$root/$_", grep $_!~/^\.{1,2}\z/s,@files);
      }
      $count += rmtree(\@files,$verbose,$safe);
      if ($safe &&
            ($Is_VMS ? !&VMS::Filespec::candelete($root) : !-w $root)) {
        print "skipped $root\n" if $verbose;
        next;
      }
      chmod $rp | 0700, $root
        or warn "Can't make directory $root writeable: $!"
          if $force_writeable;
      print "rmdir $root\n" if $verbose;
      if (rmdir $root) {
	      ++$count;
      } else {
        warn "Can't remove directory $root: $!";
        chmod($rp, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
          or warn("and can't restore permissions to "
            . sprintf("0%o",$rp) . "\n");
      }
    } else {
      if ($safe &&
            ($Is_VMS ? !&VMS::Filespec::candelete($root)
              : !(-l $root || -w $root)))
      {
        print "skipped $root\n" if $verbose;
        next;
      }
      chmod $rp | 0600, $root
        or warn "Can't make file $root writeable: $!"
          if $force_writeable;
      print "unlink $root\n" if $verbose;
      # delete all versions under VMS
      for (;;) {
        unless (unlink $root) {
          warn "Can't unlink file $root: $!";
          if ($force_writeable) {
            chmod $rp, $root
              or warn("and can't restore permissions to "
                . sprintf("0%o",$rp) . "\n");
          }
          last;
        }
        ++$count;
        last unless $Is_VMS && lstat $root;
      }
    }
  }
  $count;
}


=item C<copy($file, $target_dir)>

=item C<copy("-f", $file, $destfile)>

=item C<copy("-L", $file, $destfile)>

Copy file C<$file> to directory C<$target_dir>, or to the C<$destfile>
if the first argument is C<"-f">. No external programs are involved.
Since we need C<sysopen()>, the Perl module C<Fcntl.pm> is required. The
time stamps are preserved and symlinks are created on Unix systems. On
Windows, C<(-l $file)> will never return 'C<true>' and so symlinks will
be (uselessly) copied as regular files.

If the first argument is C<"-L"> and C<$file> is a symlink, the link is
dereferenced before the copying is done. (If both C<"-f"> and C<"-L">
are desired, they must be given in that order, although the codebase
currently has no need to do this.)

C<copy> invokes C<mkdirhier> if target directories do not exist. Files
start with mode C<0777> if they are executable and C<0666> otherwise,
with the set bits in I<umask> cleared in each case.

C<$file> can begin with a C<file:/> prefix.

If C<$file> is not readable, we return without copying anything.  (This
can happen when the database and files are not in perfect sync.)  On the
other file, if the destination is not writable, or the writing fails,
that is a fatal error.

=cut

sub copy {
  #too verbose ddebug("TLUtils::copy(", join (",", @_), "\n");
  my $infile = shift;
  my $filemode = 0;
  my $dereference = 0;
  if ($infile eq "-f") { # second argument is a file
    $filemode = 1;
    $infile = shift;
  }
  if ($infile eq "-L") {
    $dereference = 1;
    $infile = shift;
  }
  my $destdir=shift;

  # while we're trying to figure out the versioned containers.
  #debug("copy($infile, $destdir, filemode=$filemode)\n");
  #debug("copy: backtrace:\n", backtrace(), "copy: end backtrace\n");

  my $outfile;
  my @stat;
  my $mode;
  my $buffer;
  my $offset;
  my $filename;
  my $dirmode = 0755;
  my $blocksize = $TeXLive::TLConfig::BlockSize;

  $infile =~ s!^file://*!/!i;  # remove file:/ url prefix
  $filename = basename "$infile";
  if ($filemode) {
    # given a destination file
    $outfile = $destdir;
    $destdir = dirname($outfile);
  } else {
    $outfile = "$destdir/$filename";
  }

  if (! -d $destdir) {
    my ($ret,$err) = mkdirhier ($destdir);
    die "mkdirhier($destdir) failed: $err\n" if ! $ret;
  }

  # if we should dereference, change $infile to refer to the link target.
  if (-l $infile && $dereference) {
    my $linktarget = readlink($infile);
    # The symlink target should always be relative, and we need to
    # prepend the directory containing the link in that case.
    # (Although it should never happen, if the symlink target happens
    # to already be absolute, do not prepend.)
    if ($linktarget !~ m,^/,) {
      $infile = Cwd::abs_path(dirname($infile)) . "/$linktarget";
    }
    ddebug("TLUtils::copy: dereferencing symlink $infile -> $linktarget");
  }

  if (-l $infile) {
    my $linktarget = readlink($infile);
    my $dest = "$destdir/$filename";
    ddebug("TLUtils::copy: doing symlink($linktarget,$dest)"
          . " [from readlink($infile)]\n");
    symlink($linktarget, $dest) || die "symlink($linktarget,$dest) failed: $!";
  } else {
    if (! open (IN, $infile)) {
      warn "open($infile) failed, not copying: $!";
      return;
    }
    binmode IN;

    $mode = (-x $infile) ? oct("0777") : oct("0666");
    $mode &= ~umask;

    open (OUT, ">$outfile") || die "open(>$outfile) failed: $!";
    binmode OUT;

    chmod ($mode, $outfile) || warn "chmod($mode,$outfile) failed: $!";

    while ($read = sysread (IN, $buffer, $blocksize)) {
      die "read($infile) failed: $!" unless defined $read;
      $offset = 0;
      while ($read) {
        $written = syswrite (OUT, $buffer, $read, $offset);
        die "write($outfile) failed: $!" unless defined $written;
        $read -= $written;
        $offset += $written;
      }
    }
    close (OUT) || warn "close($outfile) failed: $!";
    close (IN) || warn "close($infile) failed: $!";;
    @stat = lstat ($infile);
    die "lstat($infile) failed: $!" if ! @stat;
    utime ($stat[8], $stat[9], $outfile);
  }
}


=item C<touch(@files)>

Update modification and access time of C<@files>.  Non-existent files
are created.

=cut

sub touch {
  my @files=@_;

  foreach my $file (@_) {
    if (-e $file) {
	    utime time, time, $file;
    } else {
      if (open( TMP, ">$file")) {
        close(TMP);
      } else {
        warn "Can't create file $file: $!\n";
      }
    }
  }
}


=item C<collapse_dirs(@files)>

Return a (more or less) minimal list of directories and files, given an
original list of files C<@files>.  That is, if every file within a given
directory is included in C<@files>, replace all of those files with the
absolute directory name in the return list.  Any files which have
sibling files not included are retained and made absolute.

We try to walk up the tree so that the highest-level directory
containing only directories or files that are in C<@files> is returned.
(This logic may not be perfect, though.)

This is not just a string function; we check for other directory entries
existing on disk within the directories of C<@files>.  Therefore, if the
entries are relative pathnames, the current directory must be set by the
caller so that file tests work.

As mentioned above, the returned list is absolute paths to directories
and files.

For example, suppose the input list is

  dir1/subdir1/file1
  dir1/subdir2/file2
  dir1/file3

If there are no other entries under C<dir1/>, the result will be
C</absolute/path/to/dir1>.

=cut

sub collapse_dirs {
  my (@files) = @_;
  my @ret = ();
  my %by_dir;

  # construct hash of all directories mentioned, values are lists of the
  # files in that directory.
  for my $f (@files) {
    my $abs_f = Cwd::abs_path ($f);
    die ("oops, no abs_path($f) from " . `pwd`) unless $abs_f;
    (my $d = $abs_f) =~ s,/[^/]*$,,;
    my @a = exists $by_dir{$d} ? @{$by_dir{$d}} : ();
    push (@a, $abs_f);
    $by_dir{$d} = \@a;
  }

  # for each of our directories, see if we are given everything in
  # the directory.  if so, return the directory; else return the
  # individual files.
  for my $d (sort keys %by_dir) {
    opendir (DIR, $d) || die "opendir($d) failed: $!";
    my @dirents = readdir (DIR);
    closedir (DIR) || warn "closedir($d) failed: $!";

    # initialize test hash with all the files we saw in this dir.
    # (These idioms are due to "Finding Elements in One Array and Not
    # Another" in the Perl Cookbook.)
    my %seen;
    my @rmfiles = @{$by_dir{$d}};
    @seen{@rmfiles} = ();

    # see if everything is the same.
    my $ok_to_collapse = 1;
    for my $dirent (@dirents) {
      next if $dirent =~ /^\.(\.|svn)?$/;  # ignore . .. .svn

      my $item = "$d/$dirent";  # prepend directory for comparison
      if (! exists $seen{$item}) {
        ddebug("   no collapse of $d because of: $dirent\n");
        $ok_to_collapse = 0;
        last;  # no need to keep looking after the first.
      }
    }

    push (@ret, $ok_to_collapse ? $d : @{$by_dir{$d}});
  }

  if (@ret != @files) {
    @ret = &collapse_dirs (@ret);
  }
  return @ret;
}

=item C<removed_dirs(@files)>

Returns all the directories from which all content will be removed.

Here is the idea:

=over 4

=item create a hashes by_dir listing all files that should be removed
   by directory, i.e., key = dir, value is list of files

=item for each of the dirs (keys of by_dir and ordered deepest first)
   check that all actually contained files are removed
   and all the contained dirs are in the removal list. If this is the
   case put that directory into the removal list

=item return this removal list

=back
=cut

sub removed_dirs {
  my (@files) = @_;
  my %removed_dirs;
  my %by_dir;

  # construct hash of all directories mentioned, values are lists of the
  # files/dirs in that directory.
  for my $f (@files) {
    # what should we do with not existing entries????
    next if (! -r "$f");
    my $abs_f = Cwd::abs_path ($f);
    # the following is necessary because on win32,
    #   abs_path("tl-portable")
    # returns
    #   c:\tl test\...
    # and not forward slashes, while, if there is already a forward /
    # in the path, also the rest is done with forward slashes.
    $abs_f =~ s!\\!/!g if win32();
    if (!$abs_f) {
      warn ("oops, no abs_path($f) from " . `pwd`);
      next;
    }
    (my $d = $abs_f) =~ s,/[^/]*$,,;
    my @a = exists $by_dir{$d} ? @{$by_dir{$d}} : ();
    push (@a, $abs_f);
    $by_dir{$d} = \@a;
  }

  # for each of our directories, see if we are removing everything in
  # the directory.  if so, return the directory; else return the
  # individual files.
  for my $d (reverse sort keys %by_dir) {
    opendir (DIR, $d) || die "opendir($d) failed: $!";
    my @dirents = readdir (DIR);
    closedir (DIR) || warn "closedir($d) failed: $!";

    # initialize test hash with all the files we saw in this dir.
    # (These idioms are due to "Finding Elements in One Array and Not
    # Another" in the Perl Cookbook.)
    my %seen;
    my @rmfiles = @{$by_dir{$d}};
    @seen{@rmfiles} = ();

    # see if everything is the same.
    my $cleandir = 1;
    for my $dirent (@dirents) {
      next if $dirent =~ /^\.(\.|svn)?$/;  # ignore . .. .svn
      my $item = "$d/$dirent";  # prepend directory for comparison
      if (
           ((-d $item) && (defined($removed_dirs{$item})))
           ||
           (exists $seen{$item})
         ) {
        # do nothing
      } else {
        $cleandir = 0;
        last;
      }
    }
    if ($cleandir) {
      $removed_dirs{$d} = 1;
    }
  }
  return keys %removed_dirs;
}

=item C<time_estimate($totalsize, $donesize, $starttime)>

Returns the current running time and the estimated total time
based on the total size, the already done size, and the start time.

=cut

sub time_estimate {
  my ($totalsize, $donesize, $starttime) = @_;
  if ($donesize <= 0) {
    return ("??:??", "??:??");
  }
  my $curtime = time();
  my $passedtime = $curtime - $starttime;
  my $esttotalsecs = int ( ( $passedtime * $totalsize ) / $donesize );
  #
  # we change the display to show that passed time instead of the
  # estimated remaining time. We keep the old code and naming and
  # only initialize the $remsecs to the $passedtime instead.
  # my $remsecs = $esttotalsecs - $passedtime;
  my $remsecs = $passedtime;
  my $min = int($remsecs/60);
  my $hour;
  if ($min >= 60) {
    $hour = int($min/60);
    $min %= 60;
  }
  my $sec = $remsecs % 60;
  $remtime = sprintf("%02d:%02d", $min, $sec);
  if ($hour) {
    $remtime = sprintf("%02d:$remtime", $hour);
  }
  my $tmin = int($esttotalsecs/60);
  my $thour;
  if ($tmin >= 60) {
    $thour = int($tmin/60);
    $tmin %= 60;
  }
  my $tsec = $esttotalsecs % 60;
  $tottime = sprintf("%02d:%02d", $tmin, $tsec);
  if ($thour) {
    $tottime = sprintf("%02d:$tottime", $thour);
  }
  return($remtime, $tottime);
}


=item C<install_packages($from_tlpdb, $media, $to_tlpdb, $what, $opt_src, $opt_doc)>

Installs the list of packages found in C<@$what> (a ref to a list) into
the TLPDB given by C<$to_tlpdb>. Information on files are taken from
the TLPDB C<$from_tlpdb>.

C<$opt_src> and C<$opt_doc> specify whether srcfiles and docfiles should be
installed (currently implemented only for installation from uncompressed media).

Returns 1 on success and 0 on error.

=cut

sub install_packages {
  my ($fromtlpdb,$media,$totlpdb,$what,$opt_src,$opt_doc) = @_;
  my $container_src_split = $fromtlpdb->config_src_container;
  my $container_doc_split = $fromtlpdb->config_doc_container;
  my $root = $fromtlpdb->root;
  my @packs = @$what;
  my $totalnr = $#packs + 1;
  my $td = length("$totalnr");
  my $n = 0;
  my %tlpobjs;
  my $totalsize = 0;
  my $donesize = 0;
  my %tlpsizes;
  debug("TLUtils::install_packages: fromtlpdb.root=$root, media=$media,"
        . " totlpdb.root=" . $totlpdb->root
        . " what=$what ($totalnr), opt_src=$opt_src, opt_doc=$opt_doc\n");

  foreach my $p (@packs) {
    $tlpobjs{$p} = $fromtlpdb->get_package($p);
    if (!defined($tlpobjs{$p})) {
      die "STRANGE: $p not to be found in ", $fromtlpdb->root;
    }
    if ($media ne 'local_uncompressed') {
      # we use the container size as the measuring unit since probably
      # downloading will be the limiting factor
      $tlpsizes{$p} = $tlpobjs{$p}->containersize;
      $tlpsizes{$p} += $tlpobjs{$p}->srccontainersize if $opt_src;
      $tlpsizes{$p} += $tlpobjs{$p}->doccontainersize if $opt_doc;
    } else {
      # we have to add the respective sizes, that is checking for
      # installation of src and doc file
      $tlpsizes{$p} = $tlpobjs{$p}->runsize;
      $tlpsizes{$p} += $tlpobjs{$p}->srcsize if $opt_src;
      $tlpsizes{$p} += $tlpobjs{$p}->docsize if $opt_doc;
      my %foo = %{$tlpobjs{$p}->binsize};
      for my $k (keys %foo) { $tlpsizes{$p} += $foo{$k}; }
      # all the packages sizes are in blocks, so transfer that to bytes
      $tlpsizes{$p} *= $TeXLive::TLConfig::BlockSize;
    }
    $totalsize += $tlpsizes{$p};
  }
  my $starttime = time();
  my @packs_again; # packages that we failed to download and should retry later
  foreach my $package (@packs) {
    my $tlpobj = $tlpobjs{$package};
    my $reloc = $tlpobj->relocated;
    $n++;
    my ($estrem, $esttot) = time_estimate($totalsize, $donesize, $starttime);
    my $infostr = sprintf("Installing [%0${td}d/$totalnr, "
                     . "time/total: $estrem/$esttot]: $package [%dk]",
                     $n, int($tlpsizes{$package}/1024) + 1);
    info("$infostr\n");
    foreach my $h (@::install_packages_hook) {
      &$h($n,$totalnr);
    }
    # push $package to @packs_again if download failed
    # (and not installing from disk).
    if (!$fromtlpdb->install_package($package, $totlpdb)) {
      tlwarn("TLUtils::install_packages: Failed to install $package\n");
      if ($media eq "NET") {
        tlwarn("                           $package will be retried later.\n");
        push @packs_again, $package;
      } else {
        # return false as soon as one package failed, since we won't
        # be trying again.
        return 0;
      }
    } else {
      $donesize += $tlpsizes{$package};
    }
  }
  # try to download packages in @packs_again again
  foreach my $package (@packs_again) {
    my $infostr = sprintf("Retrying to install: $package [%dk]",
                     int($tlpsizes{$package}/1024) + 1);
    info("$infostr\n");
    # return false if download failed again
    if (!$fromtlpdb->install_package($package, $totlpdb)) {
      return 0;
    }
    $donesize += $tlpsizes{$package};
  }
  my $totaltime = time() - $starttime;
  my $tothour = int ($totaltime/3600);
  my $totmin = (int ($totaltime/60)) % 60;
  my $totsec = $totaltime % 60;
  my $hrstr = ($tothour > 0 ? "$tothour:" : "");
  info(sprintf("Time used for installing the packages: $hrstr%02d:%02d\n",
       $totmin, $totsec));
  $totlpdb->save;
  return 1;
}

=item C<do_postaction($how, $tlpobj, $do_fileassocs, $do_menu, $do_desktop, $do_script)>

Evaluates the C<postaction> fields in the C<$tlpobj>. The first parameter
can be either C<install> or C<remove>. The second gives the TLPOBJ whos
postactions should be evaluated, and the last four arguments specify
what type of postactions should (or shouldn't) be evaluated.

Returns 1 on success, and 0 on failure.

=cut

sub do_postaction {
  my ($how, $tlpobj, $do_fileassocs, $do_menu, $do_desktop, $do_script) = @_;
  my $ret = 1;
  if (!defined($tlpobj)) {
    tlwarn("do_postaction: didn't get a tlpobj\n");
    return 0;
  }
  debug("running postaction=$how for " . $tlpobj->name . "\n")
    if $tlpobj->postactions;
  for my $pa ($tlpobj->postactions) {
    if ($pa =~ m/^\s*shortcut\s+(.*)\s*$/) {
      $ret &&= _do_postaction_shortcut($how, $tlpobj, $do_menu, $do_desktop, $1);
    } elsif ($pa =~ m/\s*filetype\s+(.*)\s*$/) {
      next unless $do_fileassocs;
      $ret &&= _do_postaction_filetype($how, $tlpobj, $1);
    } elsif ($pa =~ m/\s*fileassoc\s+(.*)\s*$/) {
      $ret &&= _do_postaction_fileassoc($how, $do_fileassocs, $tlpobj, $1);
      next;
    } elsif ($pa =~ m/\s*progid\s+(.*)\s*$/) {
      next unless $do_fileassocs;
      $ret &&= _do_postaction_progid($how, $tlpobj, $1);
    } elsif ($pa =~ m/\s*script\s+(.*)\s*$/) {
      next unless $do_script;
      $ret &&= _do_postaction_script($how, $tlpobj, $1);
    } else {
      tlwarn("do_postaction: don't know how to do $pa\n");
      $ret = 0;
    }
  }
  # nothing to do
  return $ret;
}

sub _do_postaction_fileassoc {
  my ($how, $mode, $tlpobj, $pa) = @_;
  return 1 unless win32();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/extension filetype/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  # name can be an arbitrary string
  if (!defined($keyval{'extension'})) {
    tlwarn("extension of fileassoc postaction not given\n");
    return 0;
  }
  my $extension = $keyval{'extension'};

  # cmd can be an arbitrary string
  if (!defined($keyval{'filetype'})) {
    tlwarn("filetype of fileassoc postaction not given\n");
    return 0;
  }
  my $filetype = $keyval{'filetype'}.'.'.$ReleaseYear;

  &log("postaction $how fileassoc for " . $tlpobj->name .
    ": $extension, $filetype\n");
  if ($how eq "install") {
    TeXLive::TLWinGoo::register_extension($mode, $extension, $filetype);
  } elsif ($how eq "remove") {
    TeXLive::TLWinGoo::unregister_extension($mode, $extension, $filetype);
  } else {
    tlwarn("Unknown mode $how\n");
    return 0;
  }
  return 1;
}

sub _do_postaction_filetype {
  my ($how, $tlpobj, $pa) = @_;
  return 1 unless win32();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/name cmd/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  # name can be an arbitrary string
  if (!defined($keyval{'name'})) {
    tlwarn("name of filetype postaction not given\n");
    return 0;
  }
  my $name = $keyval{'name'}.'.'.$ReleaseYear;

  # cmd can be an arbitrary string
  if (!defined($keyval{'cmd'})) {
    tlwarn("cmd of filetype postaction not given\n");
    return 0;
  }
  my $cmd = $keyval{'cmd'};

  my $texdir = `kpsewhich -var-value=TEXMFROOT`;
  chomp($texdir);
  my $texdir_bsl = conv_to_w32_path($texdir);
  $cmd =~ s!^("?)TEXDIR/!$1$texdir/!g;

  &log("postaction $how filetype for " . $tlpobj->name .
    ": $name, $cmd\n");
  if ($how eq "install") {
    TeXLive::TLWinGoo::register_file_type($name, $cmd);
  } elsif ($how eq "remove") {
    TeXLive::TLWinGoo::unregister_file_type($name);
  } else {
    tlwarn("Unknown mode $how\n");
    return 0;
  }
  return 1;
}

# alternate filetype (= progid) for an extension;
# associated program shows up in `open with' menu
sub _do_postaction_progid {
  my ($how, $tlpobj, $pa) = @_;
  return 1 unless win32();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/extension filetype/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  if (!defined($keyval{'extension'})) {
    tlwarn("extension of progid postaction not given\n");
    return 0;
  }
  my $extension = $keyval{'extension'};

  if (!defined($keyval{'filetype'})) {
    tlwarn("filetype of progid postaction not given\n");
    return 0;
  }
  my $filetype = $keyval{'filetype'}.'.'.$ReleaseYear;

  &log("postaction $how progid for " . $tlpobj->name .
    ": $extension, $filetype\n");
  if ($how eq "install") {
    TeXLive::TLWinGoo::add_to_progids($extension, $filetype);
  } elsif ($how eq "remove") {
    TeXLive::TLWinGoo::remove_from_progids($extension, $filetype);
  } else {
    tlwarn("Unknown mode $how\n");
    return 0;
  }
  return 1;
}

sub _do_postaction_script {
  my ($how, $tlpobj, $pa) = @_;
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/file filew32/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  # file can be an arbitrary string
  if (!defined($keyval{'file'})) {
    tlwarn("filename of script not given\n");
    return 0;
  }
  my $file = $keyval{'file'};
  if (win32() && defined($keyval{'filew32'})) {
    $file = $keyval{'filew32'};
  }
  my $texdir = `kpsewhich -var-value=TEXMFROOT`;
  chomp($texdir);
  my @syscmd;
  if ($file =~ m/\.pl$/i) {
    # we got a perl script, call it via perl
    push @syscmd, "perl", "$texdir/$file";
  } elsif ($file =~ m/\.texlua$/i) {
    # we got a texlua script, call it via texlua
    push @syscmd, "texlua", "$texdir/$file";
  } else {
    # we got anything else, call it directly and hope it is excutable
    push @syscmd, "$texdir/$file";
  }
  &log("postaction $how script for " . $tlpobj->name . ": @syscmd\n");
  push @syscmd, $how, $texdir;
  my $ret = system (@syscmd);
  if ($ret != 0) {
    $ret /= 256 if $ret > 0;
    my $pwd = cwd ();
    warn "$0: calling post action script $file did not succeed in $pwd, status $ret";
    return 0;
  }
  return 1;
}

sub _do_postaction_shortcut {
  my ($how, $tlpobj, $do_menu, $do_desktop, $pa) = @_;
  return 1 unless win32();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/type name icon cmd args hide/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  # type can be either menu or desktop
  if (!defined($keyval{'type'})) {
    tlwarn("type of shortcut postaction not given\n");
    return 0;
  }
  my $type = $keyval{'type'};
  if (($type ne "menu") && ($type ne "desktop")) {
    tlwarn("type of shortcut postaction $type is unknown (menu, desktop)\n");
    return 0;
  }

  if (($type eq "menu") && !$do_menu) {
    return 1;
  }
  if (($type eq "desktop") && !$do_desktop) {
    return 1;
  }

  # name can be an arbitrary string
  if (!defined($keyval{'name'})) {
    tlwarn("name of shortcut postaction not given\n");
    return 0;
  }
  my $name = $keyval{'name'};

  # icon, cmd, args is optional
  my $icon = (defined($keyval{'icon'}) ? $keyval{'icon'} : '');
  my $cmd = (defined($keyval{'cmd'}) ? $keyval{'cmd'} : '');
  my $args = (defined($keyval{'args'}) ? $keyval{'args'} : '');

  # hide can be only 0 or 1, and defaults to 1
  my $hide = (defined($keyval{'hide'}) ? $keyval{'hide'} : 1);
  if (($hide ne "0") && ($hide ne "1")) {
    tlwarn("hide of shortcut postaction $hide is unknown (0, 1)\n");
    return 0;
  }

  &log("postaction $how shortcut for " . $tlpobj->name . "\n");
  if ($how eq "install") {
    my $texdir = `kpsewhich -var-value=TEXMFROOT`;
    chomp($texdir);
    my $texdir_bsl = conv_to_w32_path($texdir);
    $icon =~ s!^TEXDIR/!$texdir/!;
    $cmd =~ s!^TEXDIR/!$texdir/!;
    # $cmd can be an URL, in which case we do NOT want to convert it to
    # w32 paths!
    if ($cmd !~ m!^\s*(https?://|ftp://)!) {
      if (!(-e $cmd) or !(-r $cmd)) {
        tlwarn("Target of shortcut action does not exist: $cmd\n")
            if $cmd =~ /\.(exe|bat|cmd)$/i;
        # if not an executable, just omit shortcut silently: no error
        return 1;
      }
      $cmd = conv_to_w32_path($cmd);
    }
    if ($type eq "menu" ) {
      TeXLive::TLWinGoo::add_menu_shortcut(
                        $TeXLive::TLConfig::WindowsMainMenuName,
                        $name, $icon, $cmd, $args, $hide);
    } elsif ($type eq "desktop") {
      TeXLive::TLWinGoo::add_desktop_shortcut(
                        $name, $icon, $cmd, $args, $hide);
    } else {
      tlwarn("Unknown type of shortcut: $type\n");
      return 0;
    }
  } elsif ($how eq "remove") {
    if ($type eq "menu") {
      TeXLive::TLWinGoo::remove_menu_shortcut(
        $TeXLive::TLConfig::WindowsMainMenuName, $name);
    } elsif ($type eq "desktop") {
      TeXLive::TLWinGoo::remove_desktop_shortcut($name);
    } else {
      tlwarn("Unknown type of shortcut: $type\n");
      return 0;
    }
  } else {
    tlwarn("Unknown mode $how\n");
    return 0;
  }
  return 1;
}

sub parse_into_keywords {
  my ($str, @keys) = @_;
  my @words = quotewords('\s+', 0, $str);
  my %ret;
  my $error = 0;
  while (@words) {
    $_ = shift @words;
    if (/^([^=]+)=(.*)$/) {
      $ret{$1} = $2;
    } else {
      tlwarn("parser found a invalid word in parsing keys: $_\n");
      $error++;
      $ret{$_} = "";
    }
  }
  for my $k (keys %ret) {
    if (!member($k, @keys)) {
      $error++;
      tlwarn("parser found invalid keyword: $k\n");
    }
  }
  return($error, %ret);
}

=item C<announce_execute_actions($how, $tlpobj, $what)>

Announces that the actions given in C<$tlpobj> should be executed
after all packages have been unpacked. C<$what> provides 
additional information.

=cut

sub announce_execute_actions {
  my ($type, $tlp, $what) = @_;
  # do simply return immediately if execute actions are suppressed
  return if $::no_execute_actions;

  if (defined($type) && ($type eq "regenerate-formats")) {
    $::regenerate_all_formats = 1;
    return;
  }
  if (defined($type) && ($type eq "files-changed")) {
    $::files_changed = 1;
    return;
  }
  if (defined($type) && ($type eq "rebuild-format")) {
    # rebuild-format must feed in a hashref of a parse_AddFormat_line data
    # the $tlp argument is not used
    $::execute_actions{'enable'}{'formats'}{$what->{'name'}} = $what; 
    return;
  }
  if (!defined($type) || (($type ne "enable") && ($type ne "disable"))) {
    die "announce_execute_actions: enable or disable, not type $type";
  }
  my (@maps, @formats, @dats);
  if ($tlp->runfiles || $tlp->srcfiles || $tlp->docfiles) {
    $::files_changed = 1;
  }
  $what = "map format hyphen" if (!defined($what));
  foreach my $e ($tlp->executes) {
    if ($e =~ m/^add((Mixed|Kanji)?Map)\s+([^\s]+)\s*$/) {
      # save the refs as we have another =~ grep in the following lines
      my $a = $1;
      my $b = $3;
      $::execute_actions{$type}{'maps'}{$b} = $a if ($what =~ m/map/);
    } elsif ($e =~ m/^AddFormat\s+(.*)\s*$/) {
      my %r = TeXLive::TLUtils::parse_AddFormat_line("$1");
      if (defined($r{"error"})) {
        tlwarn ("$r{'error'} in parsing $e for return hash\n");
      } else {
        $::execute_actions{$type}{'formats'}{$r{'name'}} = \%r
          if ($what =~ m/format/);
      }
    } elsif ($e =~ m/^AddHyphen\s+(.*)\s*$/) {
      my %r = TeXLive::TLUtils::parse_AddHyphen_line("$1");
      if (defined($r{"error"})) {
        tlwarn ("$r{'error'} in parsing $e for return hash\n");
      } else {
        $::execute_actions{$type}{'hyphens'}{$r{'name'}} = \%r
          if ($what =~ m/hyphen/);
      }
    } else {
      tlwarn("Unknown execute $e in ", $tlp->name, "\n");
    }
  }
}


=pod

=item C<add_symlinks($root, $arch, $sys_bin, $sys_man, $sys_info)>

=item C<remove_symlinks($root, $arch, $sys_bin, $sys_man, $sys_info)>

These two functions try to create/remove symlinks for binaries, man pages,
and info files as specified by the options $sys_bin, $sys_man, $sys_info.

The functions return 1 on success and 0 on error.
On Windows it returns undefined.

=cut

sub add_link_dir_dir {
  my ($from,$to) = @_;
  my ($ret, $err) = mkdirhier ($to);
  if (!$ret) {
    tlwarn("$err\n");
    return 0;
  }
  if (-w $to) {
    debug ("TLUtils::add_link_dir_dir: linking from $from to $to\n");
    chomp (@files = `ls "$from"`);
    my $ret = 1;
    for my $f (@files) {
      # don't make a system-dir link to our special "man" link.
      if ($f eq "man") {
        debug ("not linking `man' into $to.\n");
        next;
      }
      #
      # attempt to remove an existing symlink, but nothing else.
      unlink ("$to/$f") if -l "$to/$f";
      #
      # if the destination still exists, skip it.
      if (-e "$to/$f") {
        tlwarn ("add_link_dir_dir: $to/$f exists; not making symlink.\n");
        next;
      }
      #
      # try to make the link.
      if (symlink ("$from/$f", "$to/$f") == 0) {
        tlwarn ("add_link_dir_dir: symlink of $f from $from to $to failed: $!\n");
        $ret = 0;
      }
    }
    return $ret;
  } else {
    tlwarn ("add_link_dir_dir: destination $to not writable, "
            . "no links from $from.\n");
    return 0;
  }
}

sub remove_link_dir_dir {
  my ($from, $to) = @_;
  if ((-d "$to") && (-w "$to")) {
    debug("TLUtils::remove_link_dir_dir: removing links from $from to $to\n");
    chomp (@files = `ls "$from"`);
    my $ret = 1;
    foreach my $f (@files) {
      next if (! -r "$to/$f");
      if ($f eq "man") {
        debug("TLUtils::remove_link_dir_dir: not considering man in $to, it should not be from us!\n");
        next;
      }
      if ((-l "$to/$f") &&
          (readlink("$to/$f") =~ m;^$from/;)) {
        $ret = 0 unless unlink("$to/$f");
      } else {
        $ret = 0;
        tlwarn ("TLUtils::remove_link_dir_dir: not removing $to/$f, not a link or wrong destination!\n");
      }
    }
    # try to remove the destination directory, it might be empty and
    # we might have write permissions, ignore errors
    # `rmdir "$to" 2>/dev/null`;
    return $ret;
  } else {
    tlwarn ("TLUtils::remove_link_dir_dir: destination $to not writable, no removal of links done!\n");
    return 0;
  }
}

sub add_remove_symlinks {
  my ($mode, $Master, $arch, $sys_bin, $sys_man, $sys_info) = @_;
  my $errors = 0;
  my $plat_bindir = "$Master/bin/$arch";

  # nothing to do with symlinks on Windows, of course.
  return if win32();

  my $info_dir = "$Master/texmf-dist/doc/info";
  if ($mode eq "add") {
    $errors++ unless add_link_dir_dir($plat_bindir, $sys_bin);   # bin
    if (-d $info_dir) {
      $errors++ unless add_link_dir_dir($info_dir, $sys_info);
    }
  } elsif ($mode eq "remove") {
    $errors++ unless remove_link_dir_dir($plat_bindir, $sys_bin); # bin
    if (-d $info_dir) {
      $errors++ unless remove_link_dir_dir($info_dir, $sys_info);
    }
  } else {
    die ("should not happen, unknown mode $mode in add_remove_symlinks!");
  }

  # man
  my $top_man_dir = "$Master/texmf-dist/doc/man";
  debug("TLUtils::add_remove_symlinks: $mode symlinks for man pages to $sys_man from $top_man_dir\n");
  if (! -d $top_man_dir) {
    ; # better to be silent?
    #info("skipping add of man symlinks, no source directory $top_man_dir\n");
  } else {
    my $man_doable = 1;
    if ($mode eq "add") {
      my ($ret, $err) = mkdirhier $sys_man;
      if (!$ret) {
        $man_doable = 0;
        tlwarn("$err\n");
        $errors++;
      }
    }
    if ($man_doable) {
      if (-w $sys_man) {
        my $foo = `(cd "$top_man_dir" && echo *)`;
        my @mans = split (' ', $foo);
        chomp (@mans);
        foreach my $m (@mans) {
          my $mandir = "$top_man_dir/$m";
          next unless -d $mandir;
          if ($mode eq "add") {
            $errors++ unless add_link_dir_dir($mandir, "$sys_man/$m");
          } else {
            $errors++ unless remove_link_dir_dir($mandir, "$sys_man/$m");
          }
        }
        #`rmdir "$sys_man" 2>/dev/null` if ($mode eq "remove");
      } else {
        tlwarn("TLUtils::add_remove_symlinks: man symlink destination ($sys_man) not writable, "
          . "cannot $mode symlinks.\n");
        $errors++;
      }
    }
  }
  
  # we collected errors in $errors, so return the negation of it
  if ($errors) {
    info("TLUtils::add_remove_symlinks: $mode of symlinks had $errors error(s), see messages above.\n");
    return $F_ERROR;
  } else {
    return $F_OK;
  }
}

sub add_symlinks    { return (add_remove_symlinks("add", @_));    }
sub remove_symlinks { return (add_remove_symlinks("remove", @_)); }

=pod

=item C<w32_add_to_path($bindir, $multiuser)>
=item C<w32_remove_from_path($bindir, $multiuser)>

These two functions try to add/remove the binary directory $bindir
on Windows to the registry PATH variable.

If running as admin user and $multiuser is set, the system path will
be adjusted, otherwise the user path.

After calling these functions TeXLive::TLWinGoo::broadcast_env() should
be called to make the changes immediately visible.

=cut

sub w32_add_to_path {
  my ($bindir, $multiuser) = @_;
  return if (!win32());

  my $path = TeXLive::TLWinGoo::get_system_env() -> {'/Path'};
  $path =~ s/[\s\x00]+$//;
  &log("Old system path: $path\n");
  $path = TeXLive::TLWinGoo::get_user_env() -> {'/Path'};
  if ($path) {
    $path =~ s/[\s\x00]+$//;
    &log("Old user path: $path\n");
  } else {
    &log("Old user path: none\n");
  }
  my $mode = 'user';
  if (TeXLive::TLWinGoo::admin() && $multiuser) {
    $mode = 'system';
  }
  debug("TLUtils:w32_add_to_path: calling adjust_reg_path_for_texlive add $bindir $mode\n");
  TeXLive::TLWinGoo::adjust_reg_path_for_texlive('add', $bindir, $mode);
  $path = TeXLive::TLWinGoo::get_system_env() -> {'/Path'};
  $path =~ s/[\s\x00]+$//;
  &log("New system path: $path\n");
  $path = TeXLive::TLWinGoo::get_user_env() -> {'/Path'};
  if ($path) {
    $path =~ s/[\s\x00]+$//;
    &log("New user path: $path\n");
  } else {
    &log("New user path: none\n");
  }
}

sub w32_remove_from_path {
  my ($bindir, $multiuser) = @_;
  my $mode = 'user';
  if (TeXLive::TLWinGoo::admin() && $multiuser) {
    $mode = 'system';
  }
  debug("w32_remove_from_path: trying to remove $bindir in $mode\n");
  TeXLive::TLWinGoo::adjust_reg_path_for_texlive('remove', $bindir, $mode);
}

=pod

=item C<check_file_and_remove($what, $checksum, $checksize>

Remove the file C<$what> if either the given C<$checksum> or
C<$checksize> for C<$what> does not agree with our recomputation using
C<TLCrypto::tlchecksum> and C<stat>, respectively. If a check argument
is not given, that check is not performed. If the checksums agree, the
size is not checked. The return status is random.

This unusual behavior (removing the given file) is because this is used
for newly-downloaded files; see the calls in the C<unpack> routine
(which is the only caller).

=cut

sub check_file_and_remove {
  my ($xzfile, $checksum, $checksize) = @_;
  my $fn_name = (caller(0))[3];
  debug("$fn_name $xzfile, $checksum, $checksize\n");

  if (!$checksum && !$checksize) {
    tlwarn("$fn_name: neither checksum nor checksize " .
           "available for $xzfile, cannot check integrity"); 
    return;
  }
  
  # The idea is that if one of the tests fail, we want to save a copy of
  # the input file for debugging. But we can't just omit removing the
  # file, since the caller depends on the removal. So we copy it to a
  # new temporary directory, which we want to persist, so can't use tl_tmpdir.
  my $check_file_tmpdir = undef;

  # only run checksum tests if we can actually compute the checksum
  if ($checksum && ($checksum ne "-1") && $::checksum_method) {
    my $tlchecksum = TeXLive::TLCrypto::tlchecksum($xzfile);
    if ($tlchecksum ne $checksum) {
      tlwarn("$fn_name: checksums differ for $xzfile:\n");
      tlwarn("$fn_name:   tlchecksum=$tlchecksum, arg=$checksum\n");
      tlwarn("$fn_name: backtrace:\n" . backtrace());
      # on Windows passing a pattern creates the tmpdir in PWD
      # which means that it will be tried to be created on the DVD
      # $check_file_tmpdir = File::Temp::tempdir("tlcheckfileXXXXXXXX");
      $check_file_tmpdir = File::Temp::tempdir();
      tlwarn("$fn_name:   removing $xzfile, "
             . "but saving copy in $check_file_tmpdir\n");
      copy($xzfile, $check_file_tmpdir);
      unlink($xzfile);
      return;
    } else {
      debug("$fn_name: checksums for $xzfile agree\n");
      # if we have checked the checksum, we don't need to check the size, too
      return;
    }
  }
  if ($checksize && ($checksize ne "-1")) {
    my $filesize = (stat $xzfile)[7];
    if ($filesize != $checksize) {
      tlwarn("$fn_name: removing $xzfile, sizes differ:\n");
      tlwarn("$fn_name:   tlfilesize=$filesize, arg=$checksize\n");
      if (!defined($check_file_tmpdir)) {
        # the tmpdir should always be undefined, since we shouldn't get
        # here if the checksums failed, but test anyway.
        $check_file_tmpdir = File::Temp::tempdir("tlcheckfileXXXXXXXX");
        tlwarn("$fn_name:  saving copy in $check_file_tmpdir\n");
        copy($xzfile, $check_file_tmpdir);
      }
      unlink($xzfile);
      return;
    }
  } 
  # We cannot remove the file here, otherwise restoring of backups
  # or unwind packages might die.
}

=pod

=item C<unpack($what, $targetdir, @opts>

If necessary, downloads C$what>, and then unpacks it into C<$targetdir>.
C<@opts> is assigned to a hash and can contain the following 
keys: C<tmpdir> (use this directory for downloaded files), 
C<checksum> (check downloaded file against this checksum), 
C<size> (check downloaded file against this size),
C<remove> (remove temporary files after operation).

Returns a pair of values: in case of error return 0 and an additional
explanation, in case of success return 1 and the name of the package.

If C<checksum> or C<size> is C<-1>, no warnings about missing checksum/size
is printed. This is used during restore and unwinding of failed updates.

=cut

sub unpack {
  my ($what, $target, %opts) = @_;
  # remove by default
  my $remove = (defined($opts{'remove'}) ? $opts{'remove'} : 1);
  my $tempdir = (defined($opts{'tmpdir'}) ? $opts{'tmpdir'} : tl_tmpdir());
  my $checksum = (defined($opts{'checksum'}) ? $opts{'checksum'} : 0);
  my $size = (defined($opts{'size'}) ? $opts{'size'} : 0);

  if (!defined($what)) {
    return (0, "nothing to unpack");
  }

  my $decompressorType;
  my $compressorextension;
  if ($what =~ m/\.tar\.$CompressorExtRegexp$/) {
    $compressorextension = $1;
    $decompressorType = $1 eq "gz" ? "gzip" : $1;
  }
  if (!$decompressorType) {
    return(0, "don't know how to unpack");
  }
  # make sure that the found uncompressor type is also available
  if (!member($decompressorType, @{$::progs{'working_compressors'}})) {
    return(0, "unsupported container format $decompressorType");
  }

  # only check the necessary compressor program
  my $decompressor = $::progs{$decompressorType};
  my @decompressorArgs = @{$Compressors{$decompressorType}{'decompress_args'}};

  my $fn = basename($what);
  my $pkg = $fn;
  $pkg =~ s/\.tar\.$compressorextension$//;
  my $remove_containerfile = $remove;
  my $containerfile = "$tempdir/$fn";
  my $tarfile = "$tempdir/$fn"; 
  $tarfile =~ s/\.$compressorextension$//;
  if ($what =~ m,^(https?|ftp)://, || $what =~ m!$SshURIRegex!) {
    # we are installing from the NET
    # check for the presence of $what in $tempdir
    if (-r $containerfile) {
      check_file_and_remove($containerfile, $checksum, $size);
    }
    # if the file is now not present, we can use it
    if (! -r $containerfile) {
      # try download the file and put it into temp
      if (!download_file($what, $containerfile)) {
        return(0, "downloading did not succeed (download_file failed)");
      }
      # remove false downloads
      check_file_and_remove($containerfile, $checksum, $size);
      if ( ! -r $containerfile ) {
        return(0, "downloading did not succeed (check_file_and_remove failed)");
      }
    }
  } else {
    # we are installing from local compressed files
    # copy it to temp with dereferencing of link target
    TeXLive::TLUtils::copy("-L", $what, $tempdir);

    check_file_and_remove($containerfile, $checksum, $size);
    if (! -r $containerfile) {
      return (0, "consistency checks failed");
    }
    # we can remove it afterwards
    $remove_containerfile = 1;
  }
  if (!system_pipe($decompressor, $containerfile, $tarfile,
                   $remove_containerfile, @decompressorArgs)
      ||
      ! -f $tarfile) {
    unlink($tarfile, $containerfile);
    return(0, "Decompressing $containerfile failed");
  }
  if (untar($tarfile, $target, 1)) {
    return (1, "$pkg");
  } else {
    return (0, "untar failed");
  }
}

=pod

=item C<untar($tarfile, $targetdir, $remove_tarfile)>

Unpacks C<$tarfile> in C<$targetdir> (changing directories to
C<$targetdir> and then back to the original directory).  If
C<$remove_tarfile> is true, unlink C<$tarfile> after unpacking.

Assumes the global C<$::progs{"tar"}> has been set up.

=cut

# return 1 if success, 0 if failure.
sub untar {
  my ($tarfile, $targetdir, $remove_tarfile) = @_;
  my $ret;

  my $tar = $::progs{'tar'};  # assume it's been set up

  # don't use the -C option to tar since Solaris tar et al. don't support it.
  # don't use system("cd ... && $tar ...") since that opens us up to
  # quoting issues.
  # so fall back on chdir in Perl.
  #
  debug("TLUtils::untar: unpacking $tarfile in $targetdir\n");
  my $cwd = cwd();
  chdir($targetdir) || die "chdir($targetdir) failed: $!";

  # on w32 don't extract file modified time, because AV soft can open
  # files in the mean time causing time stamp modification to fail
  my $taropt = win32() ? "xmf" : "xf";
  if (system($tar, $taropt, $tarfile) != 0) {
    tlwarn("TLUtils::untar: $tar $taropt $tarfile failed (in $targetdir)\n");
    $ret = 0;
  } else {
    $ret = 1;
  }
  unlink($tarfile) if $remove_tarfile;

  chdir($cwd) || die "chdir($cwd) failed: $!";
  return $ret;
}


=item C<tlcmp($file, $file)>

Compare two files considering CR, LF, and CRLF as equivalent.
Returns 1 if different, 0 if the same.

=cut

sub tlcmp {
  my ($filea, $fileb) = @_;
  if (!defined($fileb)) {
    die <<END_USAGE;
tlcmp needs two arguments FILE1 FILE2.
Compare as text files, ignoring line endings.
Exit status is zero if the same, 1 if different, something else if trouble.
END_USAGE
  }
  my $file1 = &read_file_ignore_cr ($filea);
  my $file2 = &read_file_ignore_cr ($fileb);

  return $file1 eq $file2 ? 0 : 1;
}


=item C<read_file_ignore_cr($file)>

Return contents of FILE as a string, converting all of CR, LF, and
CRLF to just LF.

=cut

sub read_file_ignore_cr {
  my ($fname) = @_;
  my $ret = "";

  local *FILE;
  open (FILE, $fname) || die "open($fname) failed: $!";
  while (<FILE>) {
    s/\r\n?/\n/g;
    #warn "line is |$_|";
    $ret .= $_;
  }
  close (FILE) || warn "close($fname) failed: $!";

  return $ret;
}


=item C<setup_programs($bindir, $platform, $tlfirst)>

Populate the global C<$::progs> hash containing the paths to the
programs C<lz4>, C<tar>, C<wget>, C<xz>. The C<$bindir> argument specifies
the path to the location of the C<xz> binaries, the C<$platform>
gives the TeX Live platform name, used as the extension on our
executables.  If a program is not present in the TeX Live tree, we also
check along PATH (without the platform extension.)

If the C<$tlfirst> argument or the C<TEXLIVE_PREFER_OWN> envvar is set,
prefer TL versions; else prefer system versions (except for Windows
C<tar.exe>, where we always use ours).

Check many different downloads and compressors to determine what is
working.

Return 0 if failure, nonzero if success.

=cut

sub setup_programs {
  my ($bindir, $platform, $tlfirst) = @_;
  my $ok = 1;

  # tlfirst is (currently) not passed in by either the installer or
  # tlmgr, so it will be always false.
  # If it is not defined, we check for the env variable
  #   TEXLIVE_PREFER_OWN
  #
  if (!defined($tlfirst)) {
    if ($ENV{'TEXLIVE_PREFER_OWN'}) {
      debug("setup_programs: TEXLIVE_PREFER_OWN is set!\n");
      $tlfirst = 1;
    }
  }

  debug("setup_programs: preferring " . ($tlfirst ? "TL" : "system") . " versions\n");

  my $isWin = ($^O =~ /^MSWin/i);

  if ($isWin) {
    # we need to make sure that we use our own tar, since 
    # Windows system tar is stupid bsdtar ...
    setup_one("w32", 'tar', "$bindir/tar.exe", "--version", 1);
    $platform = "exe";
  } else {
    # tar needs to be provided by the system, we not even check!
    $::progs{'tar'} = "tar";

    if (!defined($platform) || ($platform eq "")) {
      # we assume that we run from uncompressed media, so we can call
      # platform() and thus also the config.guess script but we have to
      # setup $::installerdir because the platform script relies on it
      $::installerdir = "$bindir/../..";
      $platform = platform();
    }
  }

  # setup of the fallback downloaders
  my @working_downloaders;
  for my $dltype (@AcceptedFallbackDownloaders) {
    my $defprog = $FallbackDownloaderProgram{$dltype};
    # do not warn on errors
    push @working_downloaders, $dltype if 
      setup_one(($isWin ? "w32" : "unix"), $defprog,
                 "$bindir/$dltype/$defprog.$platform", "--version", $tlfirst);
  }
  # check for wget/ssl support
  if (member("wget", @working_downloaders)) {
    debug("TLUtils::setup_programs: checking for ssl enabled wget\n");
    my @lines = `$::progs{'wget'} --version 2>&1`;
    if (grep(/\+ssl/, @lines)) {
      $::progs{'options'}{'wget-ssl'} = 1;
      my @wgetargs = @{$TeXLive::TLConfig::FallbackDownloaderArgs{'wget'}};
      # can't push new arg at end of list because builtin list ends with
      # -O to set the output file.
      unshift (@wgetargs, '--no-check-certificate');
      $TeXLive::TLConfig::FallbackDownloaderArgs{'wget'} = \@wgetargs;
      debug("TLUtils::setup_programs: wget has ssl, final wget args: @{$TeXLive::TLConfig::FallbackDownloaderArgs{'wget'}}\n");
    } else {
      debug("TLUtils::setup_programs: wget without ssl support found\n");
      $::progs{'options'}{'wget-ssl'} = 0;
    }
  }
  $::progs{'working_downloaders'} = [ @working_downloaders ];
  my @working_compressors;
  for my $defprog (sort 
              { $Compressors{$a}{'priority'} <=> $Compressors{$b}{'priority'} }
                   keys %Compressors) {
    # do not warn on errors
    if (setup_one(($isWin ? "w32" : "unix"), $defprog,
                  "$bindir/$defprog/$defprog.$platform", "--version",
                  $tlfirst)) {
      push @working_compressors, $defprog;
      # also set up $::{'compressor'} if not already done
      # this selects the first one, but we might reset this depending on
      # TEXLIVE_COMPRESSOR setting, see below
      defined($::progs{'compressor'}) || ($::progs{'compressor'} = $defprog);
    }
  }
  $::progs{'working_compressors'} = [ @working_compressors ];

  # check whether selected downloader/compressor is working
  # for downloader we allow 'lwp' as setting, too
  if ($ENV{'TEXLIVE_DOWNLOADER'} 
      && $ENV{'TEXLIVE_DOWNLOADER'} ne 'lwp'
      && !TeXLive::TLUtils::member($ENV{'TEXLIVE_DOWNLOADER'},
                                   @{$::progs{'working_downloaders'}})) {
    tlwarn(<<END_DOWNLOADER_BAD);
Selected download program TEXLIVE_DOWNLOADER=$ENV{'TEXLIVE_DOWNLOADER'}
is not working!
Please choose a different downloader or don't set TEXLIVE_DOWNLOADER.
Detected working downloaders: @{$::progs{'working_downloaders'}}.
END_DOWNLOADER_BAD
    $ok = 0;
  }
  if ($ENV{'TEXLIVE_COMPRESSOR'}
      && !TeXLive::TLUtils::member($ENV{'TEXLIVE_COMPRESSOR'},
                                   @{$::progs{'working_compressors'}})) {
    tlwarn(<<END_COMPRESSOR_BAD);
Selected compression program TEXLIVE_COMPRESSOR=$ENV{'TEXLIVE_COMPRESSOR'}
is not working!
Please choose a different compressor or don't set TEXLIVE_COMPRESSOR.
Detected working compressors: @{$::progs{'working_compressors'}}.
END_COMPRESSOR_BAD
    $ok = 0;
  }
  # setup default compressor $::progs{'compressor'} which is used in
  # tlmgr in the calls to make_container. By default we have already
  # chosen the first that is actually working from our list of
  # @AcceptableCompressors, but let the user override this.
  if ($ENV{'TEXLIVE_COMPRESSOR'}) {
    $::progs{'compressor'} = $ENV{'TEXLIVE_COMPRESSOR'};
  }

  if ($::opt_verbosity >= 2) {
    require Data::Dumper;
    use vars qw($Data::Dumper::Indent $Data::Dumper::Sortkeys
                $Data::Dumper::Purity); # -w pain
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Sortkeys = 1;  # stable output
    $Data::Dumper::Purity = 1; # recursive structures must be safe
    print STDERR "DD:dumping ";
    print STDERR Data::Dumper->Dump([\%::progs], [qw(::progs)]);
  }
  return $ok;
}

sub setup_one {
  my ($what, $p, $def, $arg, $tlfirst) = @_;
  my $setupfunc = ($what eq "unix") ? \&setup_unix_tl_one : \&setup_windows_tl_one ;
  if ($tlfirst) {
    if (&$setupfunc($p, $def, $arg)) {
      return(1);
    } else {
      return(setup_system_one($p, $arg));
    }
  } else {
    if (setup_system_one($p, $arg)) {
      return(1);
    } else {
      return(&$setupfunc($p, $def, $arg));
    }
  }
}

sub setup_system_one {
  my ($p, $arg) = @_;
  my $nulldev = nulldev();
  ddebug("trying to set up system $p, arg $arg\n");
  my $ret = system("$p $arg >$nulldev 2>&1");
  if ($ret == 0) {
    debug("program $p found in path\n");
    $::progs{$p} = $p;
    return(1);
  } else {
    debug("program $p not usable from path\n");
    return(0);
  }
}

sub setup_windows_tl_one {
  my ($p, $def, $arg) = @_;
  debug("(w32) trying to set up $p, default $def, arg $arg\n");

  if (-r $def) {
    my $prog = conv_to_w32_path($def);
    my $ret = system("$prog $arg >nul 2>&1"); # on windows
    if ($ret == 0) {
      debug("Using shipped $def for $p (tested).\n");
      $::progs{$p} = $prog;
      return(1);
    } else {
      tlwarn("Setting up $p with $def as $prog didn't work\n");
      system("$prog $arg");
      return(0);
    }
  } else {
    debug("Default program $def not readable?\n");
    return(0);
  }
}


# setup one prog on unix using the following logic:
# - if the shipped one is -x and can be executed, use it
# - if the shipped one is -x but cannot be executed, copy it. set -x
#   . if the copy is -x and executable, use it
# - if the shipped one is not -x, copy it, set -x
#   . if the copy is -x and executable, use it
sub setup_unix_tl_one {
  my ($p, $def, $arg) = @_;
  our $tmp;
  debug("(unix) trying to set up $p, default $def, arg $arg\n");
  if (-r $def) {
    if (-x $def) {
      ddebug(" Default $def has executable permissions\n");
      # we have to check for actual "executability" since a "noexec"
      # mount option may interfere, which is not taken into account by -x.
      my $ret = system("'$def' $arg >/dev/null 2>&1" ); # we are on Unix
      if ($ret == 0) {
        $::progs{$p} = $def;
        debug(" Using shipped $def for $p (tested).\n");
        return(1);
      } else {
        ddebug(" Shipped $def has -x but cannot be executed, "
               . "trying tmp copy.\n");
      }
    }
    # we are still here
    # out of some reasons we couldn't execute the shipped program
    # try to copy it to a temp directory and make it executable
    #
    # create tmp dir only when necessary
    $tmp = TeXLive::TLUtils::tl_tmpdir() unless defined($tmp);
    # probably we are running from uncompressed media and want to copy it to
    # some temporary location
    copy($def, $tmp);
    my $bn = basename($def);
    my $tmpprog = "$tmp/$bn";
    chmod(0755,$tmpprog);
    # we do not check the return value of chmod, but check whether
    # the -x bit is now set, the only thing that counts
    if (! -x $tmpprog) {
      # hmm, something is going really bad, not even the copy is
      # executable. Fall back to normal path element
      ddebug(" Copied $p $tmpprog does not have -x bit, strange!\n");
      return(0);
    } else {
      # check again for executability
      my $ret = system("$tmpprog $arg > /dev/null 2>&1");
      if ($ret == 0) {
        # ok, the copy works
        debug(" Using copied $tmpprog for $p (tested).\n");
        $::progs{$p} = $tmpprog;
        return(1);
      } else {
        # even the copied prog is not executable, strange
        ddebug(" Copied $p $tmpprog has x bit but not executable?!\n");
        return(0);
      }
    }
  } else {
    # default program is not readable
    return(0);
  }
}


=item C<download_file( $relpath, $destination )>

Try to download the file given in C<$relpath> from C<$TeXLiveURL>
into C<$destination>, which can be either
a filename of simply C<|>. In the latter case a file handle is returned.

Downloading first checks for the environment variable C<TEXLIVE_DOWNLOADER>,
which takes various built-in values. If not set, the next check is for
C<TL_DOWNLOAD_PROGRAM> and C<TL_DOWNLOAD_ARGS>. The former overrides the
above specification devolving to C<wget>, and the latter overrides the
default wget arguments.

C<TL_DOWNLOAD_ARGS> must be defined so that the file the output goes to
is the first argument after the C<TL_DOWNLOAD_ARGS>.  Thus, for wget it
would end in C<-O>.  Use with care.

=cut

sub download_file {
  my ($relpath, $dest) = @_;
  # create output dir if necessary
  my $par;
  if ($dest ne "|") {
    $par = dirname($dest);
    mkdirhier ($par) unless -d "$par";
  }
  my $url;
  if ($relpath =~ m;^file://*(.*)$;) {
    my $filetoopen = "/$1";
    # $dest is a file name, we have to get the respective dirname
    if ($dest eq "|") {
      open(RETFH, "<$filetoopen") or
        die("Cannot open $filetoopen for reading");
      # opening to a pipe always succeeds, so we return immediately
      return \*RETFH;
    } else {
      if (-r $filetoopen) {
        copy ("-f", "-L", $filetoopen, $dest);
        return 1;
      }
      return 0;
    }
  }

  if ($relpath =~ m!$SshURIRegex!) {
    my $downdest;
    if ($dest eq "|") {
      my ($fh, $fn) = TeXLive::TLUtils::tl_tmpfile();
      $downdest = $fn;
    } else {
      $downdest = $dest;
    }
    # massage ssh:// into the scp-acceptable scp://
    $relpath =~ s!^ssh://!scp://!;
    my $retval = system("scp", "-q", $relpath, $downdest);
    if ($retval != 0) {
      $retval /= 256 if $retval > 0;
      my $pwd = cwd ();
      tlwarn("$0: system(scp -q $relpath $downdest) failed in $pwd, status $retval");
      return 0;
    }
    if ($dest eq "|") {
      open(RETFH, "<$downdest") or
        die("Cannot open $downdest for reading");
      # opening to a pipe always succeeds, so we return immediately
      return \*RETFH;
    } else {
      return 1;
    }
  }

  if ($relpath =~ /^(https?|ftp):\/\//) {
    $url = $relpath;
  } else {
    $url = "$TeXLiveURL/$relpath";
  }

  my @downloader_trials;
  if ($ENV{'TEXLIVE_DOWNLOADER'}) {
    push @downloader_trials, $ENV{'TEXLIVE_DOWNLOADER'};
  } elsif ($ENV{"TL_DOWNLOAD_PROGRAM"}) {
    push @downloader_trials, 'custom';
  } else {
    @downloader_trials = qw/lwp curl wget/;
  }

  my $success = 0;
  for my $downtype (@downloader_trials) {
    if ($downtype eq 'lwp') {
      if (_download_file_lwp($url, $dest)) {
        $success = $downtype;
        last;
      }
    }
    if ($downtype eq "custom" || TeXLive::TLUtils::member($downtype, @{$::progs{'working_downloaders'}})) {
      if (_download_file_program($url, $dest, $downtype)) {
        $success = $downtype;
        last;
      }
    }
  }
  if ($success) {
    debug("TLUtils::download_file: downloading using $success succeeded\n");
    return(1);
  } else {
    debug("TLUtils::download_file: tried to download using @downloader_trials, none succeeded\n");
    return(0);
  }
}


sub _download_file_lwp {
  my ($url, $dest) = @_;
  if (!defined($::tldownload_server)) {
    ddebug("::tldownload_server not defined\n");
    return(0);
  }
  if (!$::tldownload_server->enabled) {
    # try to reinitialize a disabled connection
    # disabling happens after 6 failed download trials
    # we just re-initialize the connection
    if (!setup_persistent_downloads()) {
      # setup failed, give up
      debug("reinitialization of LWP download failed\n");
      return(0);
    }
    # we don't need to check for ->enabled, because
    # setup_persistent_downloads calls TLDownload->new()
    # which, if it succeeds, automatically set enabled to 1
  }
  # we are still here, so try to download
  debug("persistent connection set up, trying to get $url (for $dest)\n");
  my $ret = $::tldownload_server->get_file($url, $dest);
  if ($ret) {
    ddebug("downloading file via persistent connection succeeded\n");
    return $ret;
  } else {
    debug("TLUtils::download_file: persistent connection ok,"
           . " but download failed: $url\n");
    debug("TLUtils::download_file: retrying with other downloaders.\n");
  }
  # if we are still here, download with LWP didn't succeed.
  return(0);
}


sub _download_file_program {
  my ($url, $dest, $type) = @_;
  if (win32()) {
    $dest =~ s!/!\\!g;
  }
  
  debug("TLUtils::_download_file_program: $type $url $dest\n");
  my $downloader;
  my $downloaderargs;
  my @downloaderargs;
  if ($type eq 'custom') {
    $downloader = $ENV{"TL_DOWNLOAD_PROGRAM"};
    if ($ENV{"TL_DOWNLOAD_ARGS"}) {
      $downloaderargs = $ENV{"TL_DOWNLOAD_ARGS"};
      @downloaderargs = split(' ', $downloaderargs);
    }
  } else {
    $downloader = $::progs{$FallbackDownloaderProgram{$type}};
    @downloaderargs = @{$FallbackDownloaderArgs{$type}};
    $downloaderargs = join(' ',@downloaderargs);
  }

  debug("downloading $url using $downloader $downloaderargs\n");
  my $ret;
  if ($dest eq "|") {
    open(RETFH, "$downloader $downloaderargs - $url|")
    || die "open($url) via $downloader $downloaderargs failed: $!";
    # opening to a pipe always succeeds, so we return immediately
    return \*RETFH;
  } else {
    $ret = system ($downloader, @downloaderargs, $dest, $url);
    # we have to reverse the meaning of ret because system has 0=success.
    $ret = ($ret ? 0 : 1);
  }
  # return false/undef in case the download did not succeed.
  return ($ret) unless $ret;
  debug("download of $url succeeded\n");
  if ($dest eq "|") {
    return \*RETFH;
  } else {
    return 1;
  }
}

=item C<nulldev ()>

Return C</dev/null> on Unix and C<nul> on Windows.

=cut

sub nulldev {
  return (&win32()) ? 'nul' : '/dev/null';
}

=item C<get_full_line ($fh)>

returns the next line from the file handle $fh, taking 
continuation lines into account (last character of a line is \, and 
no quoting is parsed).

=cut

#     open my $f, '<', $file_name or die;
#     while (my $l = get_full_line($f)) { ... }
#     close $f or die;
sub get_full_line {
  my ($fh) = @_;
  my $line = <$fh>;
  return undef unless defined $line;
  return $line unless $line =~ s/\\\r?\n$//;
  my $cont = get_full_line($fh);
  if (!defined($cont)) {
    tlwarn('Continuation disallowed at end of file');
    $cont = "";
  }
  $cont =~ s/^\s*//;
  return $line . $cont;
}


=back

=head2 Installer Functions

=over 4

=item C<make_var_skeleton($prefix)>

Generate a skeleton of empty directories in the C<TEXMFSYSVAR> tree.

=cut

sub make_var_skeleton {
  my ($prefix) = @_;

  mkdirhier "$prefix/tex/generic/config";
  mkdirhier "$prefix/fonts/map/dvipdfmx/updmap";
  mkdirhier "$prefix/fonts/map/dvips/updmap";
  mkdirhier "$prefix/fonts/map/pdftex/updmap";
  mkdirhier "$prefix/fonts/pk";
  mkdirhier "$prefix/fonts/tfm";
  mkdirhier "$prefix/web2c";
  mkdirhier "$prefix/xdvi";
  mkdirhier "$prefix/tex/context/config";
}


=item C<make_local_skeleton($prefix)>

Generate a skeleton of empty directories in the C<TEXMFLOCAL> tree,
unless C<TEXMFLOCAL> already exists.

=cut

sub make_local_skeleton {
  my ($prefix) = @_;

  return if (-d $prefix);

  mkdirhier "$prefix/bibtex/bib/local";
  mkdirhier "$prefix/bibtex/bst/local";
  mkdirhier "$prefix/doc/local";
  mkdirhier "$prefix/dvips/local";
  mkdirhier "$prefix/fonts/source/local";
  mkdirhier "$prefix/fonts/tfm/local";
  mkdirhier "$prefix/fonts/type1/local";
  mkdirhier "$prefix/fonts/vf/local";
  mkdirhier "$prefix/metapost/local";
  mkdirhier "$prefix/tex/latex/local";
  mkdirhier "$prefix/tex/plain/local";
  mkdirhier "$prefix/tlpkg";
  mkdirhier "$prefix/web2c";
}


=item C<create_fmtutil($tlpdb, $dest)>

=item C<create_updmap($tlpdb, $dest)>

=item C<create_language_dat($tlpdb, $dest, $localconf)>

=item C<create_language_def($tlpdb, $dest, $localconf)>

=item C<create_language_lua($tlpdb, $dest, $localconf)>

These five functions create C<fmtutil.cnf>, C<updmap.cfg>, C<language.dat>,
C<language.def>, and C<language.dat.lua> respectively, in C<$dest> (which by
default is below C<$TEXMFSYSVAR>).  These functions merge the information
present in the TLPDB C<$tlpdb> (formats, maps, hyphenations) with local
configuration additions: C<$localconf>.

Currently the merging is done by omitting disabled entries specified
in the local file, and then appending the content of the local
configuration files at the end of the file. We should also check for
duplicates, maybe even error checking.

=cut

#
# get_disabled_local_configs
# returns the list of disabled formats/hyphenpatterns/maps
# disabling is done by putting
#    #!NAME
# or
#    %!NAME
# into the respective foo-local.cnf/cfg file
# 
sub get_disabled_local_configs {
  my $localconf = shift;
  my $cc = shift;
  my @disabled = ();
  if ($localconf && -r $localconf) {
    open (FOO, "<$localconf")
    || die "strange, -r ok but open($localconf) failed: $!";
    my @tmp = <FOO>;
    close(FOO) || warn("close($localconf) failed: $!");
    @disabled = map { if (m/^$cc!(\S+)\s*$/) { $1 } else { } } @tmp;
  }
  return @disabled;
}

sub create_fmtutil {
  my ($tlpdb,$dest) = @_;
  my @lines = $tlpdb->fmtutil_cnf_lines();
  _create_config_files($tlpdb, "texmf-dist/web2c/fmtutil-hdr.cnf", $dest,
                       undef, 0, '#', \@lines);
}

sub create_updmap {
  my ($tlpdb,$dest) = @_;
  check_for_old_updmap_cfg();
  my @tlpdblines = $tlpdb->updmap_cfg_lines();
  _create_config_files($tlpdb, "texmf-dist/web2c/updmap-hdr.cfg", $dest,
                       undef, 0, '#', \@tlpdblines);
}

sub check_for_old_updmap_cfg {
  chomp( my $tmfsysconf = `kpsewhich -var-value=TEXMFSYSCONFIG` ) ;
  my $oldupd = "$tmfsysconf/web2c/updmap.cfg";
  return unless -r $oldupd;  # if no such file, good.

  open (OLDUPD, "<$oldupd") || die "open($oldupd) failed: $!";
  my $firstline = <OLDUPD>;
  close(OLDUPD);
  # cygwin returns undef when reading from an empty file, we have
  # to make sure that this is anyway initialized
  $firstline = "" if (!defined($firstline));
  chomp ($firstline);
  #
  if ($firstline =~ m/^# Generated by (install-tl|.*\/tlmgr) on/) {
    # assume it was our doing, rename it.
    my $nn = "$oldupd.DISABLED";
    if (-r $nn) {
      my $fh;
      ($fh, $nn) = tl_tmpfile( 
        "updmap.cfg.DISABLED.XXXXXX", DIR => "$tmfsysconf/web2c");
    }
    print "Renaming old config file from 
  $oldupd
to
  $nn
";
    if (rename($oldupd, $nn)) {
      if (system("mktexlsr", $tmfsysconf) != 0) {
        die "mktexlsr $tmfsysconf failed after updmap.cfg rename, fix fix: $!";
      }
      print "No further action should be necessary.\n";
    } else {
      print STDERR "
Renaming of
  $oldupd
did not succeed.  This config file should not be used anymore,
so please do what's necessary to eliminate it.
See the documentation for updmap.
";
    }

  } else {  # first line did not match
    # that is NOT a good idea, because updmap creates updmap.cfg in
    # TEXMFSYSCONFIG when called with --enable Map etc, so we should
    # NOT warn here
    # print STDERR "Apparently
#  $oldupd
# was created by hand.  This config file should not be used anymore,
# so please do what's necessary to eliminate it.
# See the documentation for updmap.
# ";
  }
}

sub check_updmap_config_value {
  my ($k, $v, $f) = @_;
  return 0 if !defined($k);
  return 0 if !defined($v);
  if (member( $k, qw/dvipsPreferOutline dvipsDownloadBase35 
                     pdftexDownloadBase14 dvipdfmDownloadBase14/)) {
    if ($v eq "true" || $v eq "false") {
      return 1;
    } else {
      tlwarn("Unknown setting for $k in $f: $v\n");
      return 0;
    }
  } elsif ($k eq "LW35") {
    if (member($v, qw/URW URWkb ADOBE ADOBEkb/)) {
      return 1;
    } else {
      tlwarn("Unknown setting for LW35  in $f: $v\n");
      return 0;
    }
  } elsif ($k eq "kanjiEmbed") {
    # any string is fine
    return 1;
  } else {
    return 0;
  }
}

sub create_language_dat {
  my ($tlpdb,$dest,$localconf) = @_;
  # no checking for disabled stuff for language.dat and .def
  my @lines = $tlpdb->language_dat_lines(
                         get_disabled_local_configs($localconf, '%'));
  _create_config_files($tlpdb, "texmf-dist/tex/generic/config/language.us",
                       $dest, $localconf, 0, '%', \@lines);
}

sub create_language_def {
  my ($tlpdb,$dest,$localconf) = @_;
  # no checking for disabled stuff for language.dat and .def
  my @lines = $tlpdb->language_def_lines(
                         get_disabled_local_configs($localconf, '%'));
  my @postlines;
  push @postlines, "%%% No changes may be made beyond this point.\n";
  push @postlines, "\n";
  push @postlines, "\\uselanguage {USenglish}             %%% This MUST be the last line of the file.\n";
  _create_config_files ($tlpdb,"texmf-dist/tex/generic/config/language.us.def",
                        $dest, $localconf, 1, '%', \@lines, @postlines);
}

sub create_language_lua {
  my ($tlpdb,$dest,$localconf) = @_;
  # no checking for disabled stuff for language.dat and .lua
  my @lines = $tlpdb->language_lua_lines(
                         get_disabled_local_configs($localconf, '--'));
  my @postlines = ("}\n");
  _create_config_files ($tlpdb,"texmf-dist/tex/generic/config/language.us.lua",
                        $dest, $localconf, 0, '--', \@lines, @postlines);
}

sub _create_config_files {
  my ($tlpdb, $headfile, $dest,$localconf, $keepfirstline, $cc,
      $tlpdblinesref, @postlines) = @_;
  my $root = $tlpdb->root;
  my @lines = ();
  my $usermode = $tlpdb->setting( "usertree" );
  if (-r "$root/$headfile") {
    open (INFILE, "<$root/$headfile")
      || die "open($root/$headfile) failed, but -r ok: $!";
    @lines = <INFILE>;
    close (INFILE);
  } elsif (!$usermode) {
    # we might be in user mode and then do *not* want the generation
    # of the configuration file to just bail out.
    tldie ("TLUtils::_create_config_files: giving up, unreadable: "
           . "$root/$headfile\n")
  }
  push @lines, @$tlpdblinesref;
  if (defined($localconf) && -r $localconf) {
    #
    # this should be done more intelligently, but for now only add those
    # lines without any duplication check ...
    open (FOO, "<$localconf")
      || die "strange, -r ok but cannot open $localconf: $!";
    my @tmp = <FOO>;
    close (FOO);
    push @lines, @tmp;
  }
  if (@postlines) {
    push @lines, @postlines;
  }
  if ($usermode && -e $dest) {
    tlwarn("Updating $dest, backup copy in $dest.backup\n");
    copy("-f", $dest, "$dest.backup");
  }
  open(OUTFILE,">$dest")
    or die("Cannot open $dest for writing: $!");

  if (!$keepfirstline) {
    print OUTFILE $cc;
    printf OUTFILE " Generated by %s on %s\n", "$0", scalar localtime;
  }
  print OUTFILE @lines;
  close(OUTFILE) || warn "close(>$dest) failed: $!";
}

sub parse_AddHyphen_line {
  my $line = shift;
  my %ret;
  # default values
  my $default_lefthyphenmin = 2;
  my $default_righthyphenmin = 3;
  $ret{"lefthyphenmin"} = $default_lefthyphenmin;
  $ret{"righthyphenmin"} = $default_righthyphenmin;
  $ret{"synonyms"} = [];
  for my $p (quotewords('\s+', 0, "$line")) {
    my ($a, $b) = split /=/, $p;
    if ($a eq "name") {
      if (!$b) {
        $ret{"error"} = "AddHyphen line needs name=something";
        return %ret;
      }
      $ret{"name"} = $b;
      next;
    }
    if ($a eq "lefthyphenmin") {
      $ret{"lefthyphenmin"} = ( $b ? $b : $default_lefthyphenmin );
      next;
    }
    if ($a eq "righthyphenmin") {
      $ret{"righthyphenmin"} = ( $b ? $b : $default_righthyphenmin );
      next;
    }
    if ($a eq "file") {
      if (!$b) {
        $ret{"error"} = "AddHyphen line needs file=something";
        return %ret;
      }
      $ret{"file"} = $b;
      next;
    }
    if ($a eq "file_patterns") {
        $ret{"file_patterns"} = $b;
        next;
    }
    if ($a eq "file_exceptions") {
        $ret{"file_exceptions"} = $b;
        next;
    }
    if ($a eq "luaspecial") {
        $ret{"luaspecial"} = $b;
        next;
    }
    if ($a eq "databases") {
      @{$ret{"databases"}} = split /,/, $b;
      next;
    }
    if ($a eq "synonyms") {
      @{$ret{"synonyms"}} = split /,/, $b;
      next;
    }
    if ($a eq "comment") {
        $ret{"comment"} = $b;
        next;
    }
    # should not be reached at all
    $ret{"error"} = "Unknown language directive $a";
    return %ret;
  }
  # this default value couldn't be set earlier
  if (not defined($ret{"databases"})) {
    if (defined $ret{"file_patterns"} or defined $ret{"file_exceptions"}
        or defined $ret{"luaspecial"}) {
      @{$ret{"databases"}} = qw(dat def lua);
    } else {
      @{$ret{"databases"}} = qw(dat def);
    }
  }
  return %ret;
}

# 
# return hash of items on AddFormat line LINE (which must not have the
# leading "execute AddFormat").  If parse fails, hash will contain a key
# "error" with a message.
# 
sub parse_AddFormat_line {
  my $line = shift;
  my %ret;
  $ret{"options"} = "";
  $ret{"patterns"} = "-";
  $ret{"mode"} = 1;
  for my $p (quotewords('\s+', 0, "$line")) {
    my ($a, $b);
    if ($p =~ m/^(name|engine|mode|patterns|options|fmttriggers)=(.*)$/) {
      $a = $1;
      $b = $2;
    } else {
      $ret{"error"} = "Unknown format directive $p";
      return %ret;
    }
    if ($a eq "name") {
      if (!$b) {
        $ret{"error"} = "AddFormat line needs name=something";
        return %ret;
      }
      $ret{"name"} = $b;
      next;
    }
    if ($a eq "engine") {
      if (!$b) {
        $ret{"error"} = "AddFormat line needs engine=something";
        return %ret;
      }
      $ret{"engine"} = $b;
      next;
    }
    if ($a eq "patterns") {
      $ret{"patterns"} = ( $b ? $b : "-" );
      next;
    }
    if ($a eq "mode") {
      $ret{"mode"} = ( $b eq "disabled" ? 0 : 1 );
      next;
    }
    if ($a eq "options") {
      $ret{"options"} = ( $b ? $b : "" );
      next;
    }
    if ($a eq "fmttriggers") {
      my @tl = split(',',$b);
      $ret{"fmttriggers"} = \@tl ;
      next;
    }
    # should not be reached at all
    $ret{"error"} = "Unknown format directive $p";
    return %ret;
  }
  return %ret;
}

=back

=head2 Logging

Logging and debugging messages.

=over 4

=item C<logit($out,$level,@rest)>

Internal routine to write message to both C<$out> (references to
filehandle) and C<$::LOGFILE>, at level C<$level>, of concatenated items
in C<@rest>. If the log file is not initialized yet, the message is
saved to be logged later (unless the log file never comes into existence).

=cut

sub logit {
  my ($out, $level, @rest) = @_;
  _logit($out, $level, @rest) unless $::opt_quiet;
  _logit('file', $level, @rest);
}

sub _logit {
  my ($out, $level, @rest) = @_;
  if ($::opt_verbosity >= $level) {
    # if $out is a ref/glob to STDOUT or STDERR, print it there
    if (ref($out) eq "GLOB") {
      print $out @rest;
    } else {
      # we should log it into the logfile, but that might be not initialized
      # so either print it to the filehandle $::LOGFILE, or push it onto
      # the to be printed log lines @::LOGLINES
      if (defined($::LOGFILE)) {
        print $::LOGFILE @rest;
      } else {
        push (@::LOGLINES, join ("", @rest));
      }
    }
  }
}

=item C<info ($str1, $str2, ...)>

Write a normal informational message, the concatenation of the argument
strings.  The message will be written unless C<-q> was specified.  If
the global C<$::machinereadable> is set (the C<--machine-readable>
option to C<tlmgr>), then output is written to stderr, else to stdout.
If the log file (see L<process_logging_options>) is defined, it also
writes there.

It is best to use this sparingly, mainly to give feedback during lengthy
operations and for final results.

=cut

sub info {
  my $str = join("", @_);
  my $fh = ($::machinereadable ? \*STDERR : \*STDOUT);
  logit($fh, 0, $str);
  for my $i (@::info_hook) {
    &{$i}($str);
  }
}

=item C<debug ($str1, $str2, ...)>

Write a debugging message, the concatenation of the argument strings.
The message will be omitted unless C<-v> was specified.  If the log
file (see L<process_logging_options>) is defined, it also writes there.

This first level debugging message reports on the overall flow of
work, but does not include repeated messages about processing of each
package.

=cut

sub debug {
  my $str = "D:" . join("", @_);
  return if ($::opt_verbosity < 1);
  logit(\*STDERR, 1, $str);
  for my $i (@::debug_hook) {
    &{$i}($str);
  }
}

=item C<ddebug ($str1, $str2, ...)>

Write a deep debugging message, the concatenation of the argument
strings.  The message will be omitted unless C<-v -v> (or higher) was
specified.  If the log file (see L<process_logging_options>) is defined,
it also writes there.

This second level debugging message reports messages about processing
each package, in addition to the first level.

=cut

sub ddebug {
  my $str = "DD:" . join("", @_);
  return if ($::opt_verbosity < 2);
  logit(\*STDERR, 2, $str);
  for my $i (@::ddebug_hook) {
    &{$i}($str);
  }
}

=item C<dddebug ($str1, $str2, ...)>

Write the deepest debugging message, the concatenation of the argument
strings.  The message will be omitted unless C<-v -v -v> was specified.
If the log file (see L<process_logging_options>) is defined, it also
writes there.

In addition to the first and second levels, this third level debugging
message reports messages about processing each line of any tlpdb files
read, and messages about files tested or matched against tlpsrc
patterns. This output is extremely voluminous, so unless you're
debugging those parts of the code, it just gets in the way.

=cut

sub dddebug {
  my $str = "DDD:" . join("", @_);
  return if ($::opt_verbosity < 3);
  logit(\*STDERR, 3, $str);
  for my $i (@::dddebug_hook) {
    &{$i}($str);
  }
}

=item C<log ($str1, $str2, ...)>

Write a message to the log file (and nowhere else), the concatenation of
the argument strings.  The log file may not ever be defined (e.g., the
C<-logfile> option isn't given), in which case the message will never be
written anywhere.

=cut

sub log {
  my $savequiet = $::opt_quiet;
  $::opt_quiet = 0;
  _logit('file', -100, @_);
  $::opt_quiet = $savequiet;
}

=item C<tlwarn ($str1, $str2, ...)>

Write a warning message, the concatenation of the argument strings.
This always and unconditionally writes the message to standard error; if
the log file (see L<process_logging_options>) is defined, it also writes
there.

=cut

sub tlwarn {
  my $savequiet = $::opt_quiet;
  my $str = join("", @_);
  $::opt_quiet = 0;
  logit (\*STDERR, -100, $str);
  $::opt_quiet = $savequiet;
  for my $i (@::warn_hook) {
    &{$i}($str);
  }
}

=item C<tldie ($str1, $str2, ...)>

Uses C<tlwarn> to issue a warning for @_ preceded by a newline, then
exits with exit code 1.

=cut

sub tldie {
  tlwarn("\n", @_);
  if ($::gui_mode) {
    Tk::exit(1);
  } else {
    exit(1);
  }
}

=item C<debug_hash_str($label, HASH)>

Return LABEL followed by HASH elements, followed by a newline, as a
single string. If HASH is a reference, it is followed (but no recursive
derefencing).

=item C<debug_hash($label, HASH)>

Write the result of C<debug_hash_str> to stderr.

=cut

sub debug_hash_str {
  my ($label) = shift;
  my (%hash) = (ref $_[0] && $_[0] =~ /.*HASH.*/) ? %{$_[0]} : @_;

  my $str = "$label: {";
  my @items = ();
  for my $key (sort keys %hash) {
    my $val = $hash{$key};
    $val = ".undef" if ! defined $val;
    $key =~ s/\n/\\n/g;
    $val =~ s/\n/\\n/g;
    push (@items, "$key:$val");
  }
  $str .= join (",", @items);
  $str .= "}";

  return "$str\n";
}

sub debug_hash {
  warn &debug_hash_str(@_);
}

=item C<backtrace()>

Return call(er) stack, as a string.

=cut

sub backtrace {
  my $ret = "";

  my ($line, $subr);
  my $stackframe = 1;  # skip ourselves
  while ((undef,$filename,$line,$subr) = caller ($stackframe)) {
    # the undef is for the package, which is already included in $subr.
    $ret .= " -> ${filename}:${line}: ${subr}\n";
    $stackframe++;
  }

  return $ret;
}

=item C<process_logging_options ($texdir)>

This function handles the common logging options for TeX Live scripts.
It should be called before C<GetOptions> for any program-specific option
handling.  For our conventional calling sequence, see (for example) the
L<tlpfiles> script.

These are the options handled here:

=over 4

=item B<-q>

Omit normal informational messages.

=item B<-v>

Include debugging messages.  With one C<-v>, reports overall flow; with
C<-v -v> (or C<-vv>), also reports per-package processing; with C<-v -v
-v> (or C<-vvv>), also reports each line read from any tlpdb files.
Further repeats of C<-v>, as in C<-v -v -v -v>, are accepted but
ignored.  C<-vvvv> is an error.

The idea behind these levels is to be able to specify C<-v> to get an
overall idea of what is going on, but avoid terribly voluminous output
when processing many packages, as we often are.  When debugging a
specific problem with a specific package, C<-vv> can help.  When
debugging problems with parsing tlpdb files, C<-vvv> gives that too.

=item B<-logfile> I<file>

Write all messages (informational, debugging, warnings) to I<file>, in
addition to standard output or standard error.  In TeX Live, only the
installer sets a log file by default; none of the other standard TeX
Live scripts use this feature, but you can specify it explicitly.

=back

See also the L<info>, L<debug>, L<ddebug>, and L<tlwarn> functions,
which actually write the messages.

=cut

sub process_logging_options {
  $::opt_verbosity = 0;
  $::opt_quiet = 0;
  my $opt_logfile;
  my $opt_Verbosity = 0;
  my $opt_VERBOSITY = 0;
  # check all the command line options for occurrences of -q and -v;
  # do not report errors.
  my $oldconfig = Getopt::Long::Configure(qw(pass_through permute));
  GetOptions("logfile=s" => \$opt_logfile,
             "v+"  => \$::opt_verbosity,
             "vv"  => \$opt_Verbosity,
             "vvv" => \$opt_VERBOSITY,
             "q"   => \$::opt_quiet);
  Getopt::Long::Configure($oldconfig);

  # verbosity level, forcing -v -v instead of -vv is too annoying.
  $::opt_verbosity = 2 if $opt_Verbosity;
  $::opt_verbosity = 3 if $opt_VERBOSITY;

  # open log file if one was requested.
  if ($opt_logfile) {
    open(TLUTILS_LOGFILE, ">$opt_logfile")
    || die "open(>$opt_logfile) failed: $!\n";
    $::LOGFILE = \*TLUTILS_LOGFILE;
    $::LOGFILENAME = $opt_logfile;
  }
}

=back

=head2 Miscellaneous

A few ideas from Fabrice Popineau's C<FileUtils.pm>.

=over 4

=item C<sort_uniq(@list)>

The C<sort_uniq> function sorts the given array and throws away multiple
occurrences of elements. It returns a sorted and unified array.

=cut

sub sort_uniq {
  my (@l) = @_;
  my ($e, $f, @r);
  $f = "";
  @l = sort(@l);
  foreach $e (@l) {
    if ($e ne $f) {
      $f = $e;
      push @r, $e;
    }
  }
  return @r;
}


=item C<push_uniq(\@list, @new_items)>

The C<push_uniq> function pushes each element in the last argument
@ITEMS to the $LIST referenced by the first argument, if it is not
already in the list.

=cut

sub push_uniq {
  my ($l, @new_items) = @_;
  for my $e (@new_items) {
   # turns out this is one of the most-used functions when updating the
   # tlpdb, with hundreds of thousands of calls. So let's write it out
   # to eliminate the sub overhead.
   #if (! &member($e, @$l)) {
    if (! scalar grep($_ eq $e, @$l)) {
      push (@$l, $e);
    }
  }
}

=item C<member($item, @list)>

The C<member> function returns true if the first argument 
is also inclued in the list of the remaining arguments.

=cut

sub member {
  my $what = shift;
  return scalar grep($_ eq $what, @_);
}

=item C<merge_into(\%to, \%from)>

Merges the keys of %from into %to.

=cut

sub merge_into {
  my ($to, $from) = @_;
  foreach my $k (keys %$from) {
    if (defined($to->{$k})) {
      push @{$to->{$k}}, @{$from->{$k}};
    } else {
      $to->{$k} = [ @{$from->{$k}} ];
    }
  }
}

=item C<texdir_check($texdir)>

Test whether installation with TEXDIR set to $texdir should be ok, e.g.,
would be a creatable directory. Return 1 if ok, 0 if not.

Writable or not, we will not allow installation to the root
directory (Unix) or the root of a drive (Windows).

We also do not allow paths containing various special characters, and
print a message about this if second argument WARN is true. (We only
want to do this for the regular text installer, since spewing output in
a GUI program wouldn't be good; the generic message will have to do for
them.)

=cut

sub texdir_check {
  my ($orig_texdir,$warn) = @_;
  return 0 unless defined $orig_texdir;

  # convert to absolute, for safer parsing.
  # also replaces backslashes with slashes on w32.
  # The return value may still contain symlinks,
  # but no unnecessary terminating '/'.
  my $texdir = tl_abs_path($orig_texdir);
  return 0 unless defined $texdir;

  # reject the root of a drive,
  # assuming that only the canonical form of the root ends with /
  return 0 if $texdir =~ m!/$!;

  # Unfortunately we have lots of special characters.
  # On Windows, backslashes are normal but will already have been changed
  # to slashes by tl_abs_path. And we should only check for : on Unix.
  my $colon = win32() ? "" : ":";
  if ($texdir =~ /[,$colon;\\{}\$]/) {
    if ($warn) {
      print "     !! TEXDIR value has problematic characters: $orig_texdir\n";
      print "     !! (such as comma, colon, semicolon, backslash, braces\n";
      print "     !!  and dollar sign; sorry)\n";
    }
    # although we could check each character individually and give a
    # specific error, it seems plausibly useful to report all the chars
    # that cause problems, regardless of which was there. Simpler too.
    return 0;
  }
  # w32: for now, reject the root of a samba share
  return 0 if win32() && $texdir =~ m!^//[^/]+/[^/]+$!;

  # if texdir already exists, make sure we can write into it.
  return dir_writable($texdir) if (-d $texdir);

  # if texdir doesn't exist, make sure we can write the parent.
  (my $texdirparent = $texdir) =~ s!/[^/]*$!!;
  #print STDERR "Checking $texdirparent".'[/]'."\n";
  return dir_creatable($texdirparent) if -d dir_slash($texdirparent);
  
  # ditto for the next level up the tree
  (my $texdirpparent = $texdirparent) =~ s!/[^/]*$!!;
  #print STDERR "Checking $texdirpparent".'[/]'."\n";
  return dir_creatable($texdirpparent) if -d dir_slash($texdirpparent);
  
  # doesn't look plausible.
  return 0;
}

=pod

This function takes a single argument I<path> and returns it with
C<"> chars surrounding it on Unix.  On Windows, the C<"> chars are only
added if I<path> contains special characters, since unconditional quoting
leads to errors there.  In all cases, any C<"> chars in I<path> itself
are (erroneously) eradicated.
 
=cut

sub quotify_path_with_spaces {
  my $p = shift;
  my $m = win32() ? '[+=^&();,!%\s]' : '.';
  if ( $p =~ m/$m/ ) {
    $p =~ s/"//g; # remove any existing double quotes
    $p = "\"$p\""; 
  }
  return($p);
}

=pod

This function returns a "Windows-ized" version of its single argument
I<path>, i.e., replaces all forward slashes with backslashes, and adds
an additional C<"> at the beginning and end if I<path> contains any
spaces.  It also makes the path absolute. So if $path does not start
with one (arbitrary) characer followed by C<:>, we add the output of
C<`cd`>.

The result is suitable for running in shell commands, but not file tests
or other manipulations, since in such internal Perl contexts, the quotes
would be considered part of the filename.

=cut

sub conv_to_w32_path {
  my $p = shift;
  # we need absolute paths, too
  my $pabs = tl_abs_path($p);
  if (not $pabs) {
    $pabs = $p;
    tlwarn ("sorry, could not determine absolute path of $p!\n".
      "using original path instead");
  }
  $pabs =~ s!/!\\!g;
  $pabs = quotify_path_with_spaces($pabs);
  return($pabs);
}

=pod

The next two functions are meant for user input/output in installer menus.
They help making the windows user happy by turning slashes into backslashes
before displaying a path, and our code happy by turning backslashes into forwars
slashes after reading a path. They both are no-ops on Unix.

=cut

sub native_slashify {
  my ($r) = @_;
  $r =~ s!/!\\!g if win32();
  return $r;
}

sub forward_slashify {
  my ($r) = @_;
  $r =~ s!\\!/!g if win32();
  return $r;
}

=item C<setup_persistent_downloads()>

Set up to use persistent connections using LWP/TLDownload, that is look
for a download server.  Return the TLDownload object if successful, else
false.

=cut

sub setup_persistent_downloads {
  if ($TeXLive::TLDownload::net_lib_avail) {
    ddebug("setup_persistent_downloads has net_lib_avail set\n");
    if ($::tldownload_server) {
      if ($::tldownload_server->initcount() > $TeXLive::TLConfig::MaxLWPReinitCount) {
        debug("stop retrying to initialize LWP after 10 failures\n");
        return 0;
      } else {
        $::tldownload_server->reinit();
      }
    } else {
      $::tldownload_server = TeXLive::TLDownload->new;
    }
    if (!defined($::tldownload_server)) {
      ddebug("TLUtils:setup_persistent_downloads: failed to get ::tldownload_server\n");
    } else {
      ddebug("TLUtils:setup_persistent_downloads: got ::tldownload_server\n");
    }
    return $::tldownload_server;
  }
  return 0;
}


=item C<query_ctan_mirror()>

Return a particular mirror given by the generic CTAN auto-redirecting
default (specified in L<$TLConfig::TexLiveServerURL>) if we get a
response, else the empty string.

Use C<curl> if it is listed as a C<working_downloader>, else C<wget>,
else give up. We can't support arbitrary downloaders here, as we do for
regular package downloads, since certain options have to be set and the
output has to be parsed.

We try invoking the program three times (hardwired).

=cut

sub query_ctan_mirror {
  my @working_downloaders = @{$::progs{'working_downloaders'}};
  ddebug("query_ctan_mirror: working_downloaders: @working_downloaders\n");
  if (TeXLive::TLUtils::member("curl", @working_downloaders)) {
    return query_ctan_mirror_curl();
  } elsif (TeXLive::TLUtils::member("wget", @working_downloaders)) {
    if ($::progs{'options'}{'wget-ssl'}) {
      # we need ssl enabled wget to query ctan
      return query_ctan_mirror_wget();
    } else {
      tlwarn(<<END_NO_SSL);
TLUtils::query_ctan_mirror: neither curl nor an ssl-enabled wget is
  available, so no CTAN mirror can be resolved via https://mirror.ctan.org.

  Please install curl or ssl-enabled wget; otherwise, please pick an
  http (not https) mirror from the list at https://ctan.org/mirrors/mirmon.

  To report a bug about this, please rerun your command with -vv and
  include the resulting output with the report.
END_NO_SSL
      return;
    }
  } else {
    return;
  }
}

# curl will follow the redirect chain for us.
# 
sub query_ctan_mirror_curl {
  my $max_trial = 3;
  my $warg = (win32() ? "-w %{url_effective} " : "-w '%{url_effective}' ");
  for (my $i = 1; $i <= $max_trial; $i++) {
    # -L -> follow redirects
    # -s -> silent
    # -w -> what to output after completion
    my $cmd = "$::progs{'curl'} -Ls "
              . "-o " . nulldev() . " "
              . $warg
              . "--connect-timeout $NetworkTimeout "
              . "--max-time $NetworkTimeout "
              . $TeXLiveServerURL;
    ddebug("query_ctan_mirror_curl: cmd: $cmd\n");
    my $url = `$cmd`;
    if (length $url) {
      # remove trailing slashes
      $url =~ s,/*$,,;
      ddebug("query_ctan_mirror_curl: returning url: $url\n");
      return $url;
    }
    sleep(1);
  }
  return;
}

sub query_ctan_mirror_wget {
  my $wget = $::progs{'wget'};
  if (!defined ($wget)) {
    tlwarn("query_ctan_mirror_wget: Programs not set up, trying wget\n");
    $wget = "wget";
  }

  # we need the verbose output, so no -q.
  # do not reduce retries here, but timeout still seems desirable.
  my $mirror = $TeXLiveServerURL;
  my $cmd = "$wget $mirror --timeout=$NetworkTimeout "
            . "-O " . nulldev() . " 2>&1";
  ddebug("query_ctan_mirror_wget: cmd is $cmd\n");

  # since we are reading the output of wget to find a mirror
  # we have to make sure that the locale is unset
  my $saved_lcall;
  if (defined($ENV{'LC_ALL'})) {
    $saved_lcall = $ENV{'LC_ALL'};
  }
  $ENV{'LC_ALL'} = "C";
  # we try 3 times to get a mirror from mirror.ctan.org in case we have
  # bad luck with what gets returned.
  my $max_trial = 3;
  my $mhost;
  for (my $i = 1; $i <= $max_trial; $i++) {
    my @out = `$cmd`;
    # analyze the output for the mirror actually selected.
    foreach (@out) {
      if (m/^Location: (\S*)\s*.*$/) {
        (my $mhost = $1) =~ s,/*$,,;  # remove trailing slashes since we add it
        ddebug("query_ctan_mirror_wget: returning url: $mhost\n");
        return $mhost;
      }
    }
    sleep(1);
  }

  # reset LC_ALL to undefined or the previous value
  if (defined($saved_lcall)) {
    $ENV{'LC_ALL'} = $saved_lcall;
  } else {
    delete($ENV{'LC_ALL'});
  }

  # we are still here, so three times we didn't get a mirror, give up 
  # and return undefined
  return;
}
  
=item C<check_on_working_mirror($mirror)>

Check if MIRROR is functional.

=cut

sub check_on_working_mirror {
  my $mirror = shift;

  my $wget = $::progs{'wget'};
  if (!defined ($wget)) {
    tlwarn ("check_on_working_mirror: Programs not set up, trying wget\n");
    $wget = "wget";
  }
  $wget = quotify_path_with_spaces($wget);
  #
  # the test is currently not completely correct, because we do not
  # use the LWP if it is set up for it, but I am currently too lazy
  # to program it,
  # so try wget and only check for the return value
  # please KEEP the / after $mirror, some ftp mirrors do give back
  # an error if the / is missing after ../CTAN/
  my $cmd = "$wget $mirror/ --timeout=$NetworkTimeout -O "
            . (win32() ? "nul" : "/dev/null")
            . " 2>" . (win32() ? "nul" : "/dev/null");
  my $ret = system($cmd);
  # if return value is not zero it is a failure, so switch the meanings
  return ($ret ? 0 : 1);
}

=item C<give_ctan_mirror_base()>

 1. get a mirror (retries 3 times to contact mirror.ctan.org)
    - if no mirror found, use one of the backbone servers
    - if it is an http server return it (no test is done)
    - if it is a ftp server, continue
 2. if the ftp mirror is good, return it
 3. if the ftp mirror is bad, search for http mirror (5 times)
 4. if http mirror is found, return it (again, no test,)
 5. if no http mirror is found, return one of the backbone servers

=cut

sub give_ctan_mirror_base {
  # only one backbone has existed for a while (2018).
  my @backbone = qw!https://www.ctan.org/tex-archive!;

  # start by selecting a mirror and test its operationality
  ddebug("give_ctan_mirror_base: calling query_ctan_mirror\n");
  my $mirror = query_ctan_mirror();
  if (!defined($mirror)) {
    # three times calling mirror.ctan.org did not give anything useful,
    # return one of the backbone servers
    tlwarn("cannot contact mirror.ctan.org, returning a backbone server!\n");
    return $backbone[int(rand($#backbone + 1))];
  }

  if ($mirror =~ m!^https?://!) {  # if http mirror, assume good and return.
    return $mirror;
  }

  # we are still here, so we got a ftp mirror from mirror.ctan.org
  if (check_on_working_mirror($mirror)) {
    return $mirror;  # ftp mirror is working, return.
  }

  # we are still here, so the ftp mirror failed, retry and hope for http.
  # theory is that if one ftp fails, probably all ftp is broken.
  my $max_mirror_trial = 5;
  for (my $try = 1; $try <= $max_mirror_trial; $try++) {
    my $m = query_ctan_mirror();
    debug("querying mirror, got " . (defined($m) ? $m : "(nothing)") . "\n");
    if (defined($m) && $m =~ m!^https?://!) {
      return $m;  # got http this time, assume ok.
    }
    # sleep to make mirror happy, but only if we are not ready to return
    sleep(1) if $try < $max_mirror_trial;
  }

  # 5 times contacting the mirror service did not return a http server,
  # use one of the backbone servers.
  debug("no mirror found ... randomly selecting backbone\n");
  return $backbone[int(rand($#backbone + 1))];
}


sub give_ctan_mirror {
  return (give_ctan_mirror_base(@_) . "/$TeXLiveServerPath");
}

=item C<create_mirror_list()>

=item C<extract_mirror_entry($listentry)>

C<create_mirror_list> returns the lists of viable mirrors according to 
ctan-mirrors.pl, in a list which also contains continents, and country headers.

C<extract_mirror_entry> extracts the actual repository data from one
of these entries.

# KEEP THESE TWO FUNCTIONS IN SYNC!!!

=cut

sub create_mirror_list {
  our $mirrors;
  my @ret = ();
  require("installer/ctan-mirrors.pl");
  my @continents = sort keys %$mirrors;
  for my $continent (@continents) {
    # first push the name of the continent
    push @ret, uc($continent);
    my @countries = sort keys %{$mirrors->{$continent}};
    for my $country (@countries) {
      my @mirrors = sort keys %{$mirrors->{$continent}{$country}};
      my $first = 1;
      for my $mirror (@mirrors) {
        my $mfull = $mirror;
        $mfull =~ s!/$!!;
        # do not append the server path part here, but add
        # it down there in the extract mirror entry
        #$mfull .= "/" . $TeXLive::TLConfig::TeXLiveServerPath;
        #if ($first) {
          my $country_str = sprintf "%-12s", $country;
          push @ret, "  $country_str  $mfull";
        #  $first = 0;
        #} else {
        #  push @ret, "    $mfull";
        #}
      }
    }
  }
  return @ret;
}

# extract_mirror_entry is not very intelligent, it assumes that
# the last "word" is the URL
sub extract_mirror_entry {
  my $ent = shift;
  my @foo = split ' ', $ent;
  return $foo[$#foo] . "/" . $TeXLive::TLConfig::TeXLiveServerPath;
}

=pod

=item C<< slurp_file($file) >>

Reads the whole file and returns the content in a scalar.

=cut

sub slurp_file {
  my $file = shift;
  my $file_data = do {
    local $/ = undef;
    open my $fh, "<", $file || die "open($file) failed: $!";
    <$fh>;
  };
  return($file_data);
}

=pod

=item C<< download_to_temp_or_file($url) >>

If C<$url> is a url, tries to download the file into a temporary file.
Otherwise assume that C<$url> is a local file.
In both cases returns the local file.

Returns the local file name if succeeded, otherwise undef.

=cut

sub download_to_temp_or_file {
  my $url = shift;
  my ($url_fh, $url_file);
  if ($url =~ m,^(https?|ftp|file)://, || $url =~ m!$SshURIRegex!) {
    ($url_fh, $url_file) = tl_tmpfile();
    # now $url_fh filehandle is open, the file created
    # TLUtils::download_file will just overwrite what is there
    # on windows that doesn't work, so we close the fh immediately
    # this creates a short loophole, but much better than before anyway
    close($url_fh);
    $ret = download_file($url, $url_file);
  } else {
    $url_file = $url;
    $ret = 1;
  }
  if ($ret && (-r "$url_file")) {
    return $url_file;
  }
  return;
}


=item C<< compare_tlpobjs($tlpA, $tlpB) >>

Compare the two passed L<TLPOBJ> objects.  Returns a hash:

  $ret{'revision'}  = "revA:revB" # if revisions differ
  $ret{'removed'}   = \[ list of files removed from A to B ]
  $ret{'added'}     = \[ list of files added from A to B ]
  $ret{'fmttriggers'} = 1 if the fmttriggers have changed

=cut

sub compare_tlpobjs {
  my ($tlpA, $tlpB) = @_;
  my %ret;

  my $rA = $tlpA->revision;
  my $rB = $tlpB->revision;
  if ($rA != $rB) {
    $ret{'revision'} = "$rA:$rB";
  }
  if ($tlpA->relocated) {
    $tlpA->replace_reloc_prefix;
  }
  if ($tlpB->relocated) {
    $tlpB->replace_reloc_prefix;
  }
  my @fA = $tlpA->all_files;
  my @fB = $tlpB->all_files;
  my %removed;
  my %added;
  for my $f (@fA) { $removed{$f} = 1; }
  for my $f (@fB) { delete($removed{$f}); $added{$f} = 1; }
  for my $f (@fA) { delete($added{$f}); }
  my @rem = sort keys %removed;
  my @add = sort keys %added;
  $ret{'removed'} = \@rem if @rem;
  $ret{'added'} = \@add if @add;

  # changed dependencies should not trigger a change without a
  # change in revision, so for now (until we find a reason why
  # we need to) we don't check.
  # OTOH, execute statements like
  #   execute AddFormat name=aleph engine=aleph options=*aleph.ini fmttriggers=cm,hyphen-base,knuth-lib,plain
  # might change due to changes in the fmttriggers variables.
  # Again, name/engine/options are only defined in the package's
  # tlpsrc file, so changes here will trigger revision changes,
  # but fmttriggers are defined outside the tlpsrc and thus do
  # not trigger an automatic revision change. Check for that!
  # No need to record actual changes, just record that it has changed.
  my %triggersA;
  my %triggersB;
  # we sort executes after format/engine like fmtutil does, since this
  # should be unique
  for my $e ($tlpA->executes) {
    if ($e =~ m/AddFormat\s+(.*)\s*/) {
      my %r = parse_AddFormat_line("$1");
      if (defined($r{"error"})) {
        die "$r{'error'} when comparing packages $tlpA->name execute $e";
      }
      for my $t (@{$r{'fmttriggers'}}) {
        $triggersA{"$r{'name'}:$r{'engine'}:$t"} = 1;
      }
    }
  }
  for my $e ($tlpB->executes) {
    if ($e =~ m/AddFormat\s+(.*)\s*/) {
      my %r = parse_AddFormat_line("$1");
      if (defined($r{"error"})) {
        die "$r{'error'} when comparing packages $tlpB->name execute $e";
      }
      for my $t (@{$r{'fmttriggers'}}) {
        $triggersB{"$r{'name'}:$r{'engine'}:$t"} = 1;
      }
    }
  }
  for my $t (keys %triggersA) {
    delete($triggersA{$t});
    delete($triggersB{$t});
  }
  if (keys(%triggersA) || keys(%triggersB)) {
    $ret{'fmttrigger'} = 1;
  }

  return %ret;
}


=item C<< compare_tlpdbs($tlpdbA, $tlpdbB, @more_ignored_pkgs) >>

Compare the two passed L<TLPDB> objects, ignoring the packages
C<00texlive.installer>, C<00texlive.image>, and any passed
C<@more_ignore_pkgs>. Returns a hash:

  $ret{'removed_packages'} = \[ list of removed packages from A to B ]
  $ret{'added_packages'}   = \[ list of added packages from A to B ]
  $ret{'different_packages'}->{$package} = output of compare_tlpobjs

=cut

sub compare_tlpdbs {
  my ($tlpdbA, $tlpdbB, @add_ignored_packs) = @_;
  my @ignored_packs = qw/00texlive.installer 00texlive.image/;
  push @ignored_packs, @add_ignored_packs;

  my @inAnotinB;
  my @inBnotinA;
  my %diffpacks;
  my %do_compare;
  my %ret;

  for my $p ($tlpdbA->list_packages()) {
    my $is_ignored = 0;
    for my $ign (@ignored_packs) {
      if (($p =~ m/^$ign$/) || ($p =~ m/^$ign\./)) {
        $is_ignored = 1;
        last;
      }
    }
    next if $is_ignored;
    my $tlpB = $tlpdbB->get_package($p);
    if (!defined($tlpB)) {
      push @inAnotinB, $p;
    } else {
      $do_compare{$p} = 1;
    }
  }
  $ret{'removed_packages'} = \@inAnotinB if @inAnotinB;
  
  for my $p ($tlpdbB->list_packages()) {
    my $is_ignored = 0;
    for my $ign (@ignored_packs) {
      if (($p =~ m/^$ign$/) || ($p =~ m/^$ign\./)) {
        $is_ignored = 1;
        last;
      }
    }
    next if $is_ignored;
    my $tlpA = $tlpdbA->get_package($p);
    if (!defined($tlpA)) {
      push @inBnotinA, $p;
    } else {
      $do_compare{$p} = 1;
    }
  }
  $ret{'added_packages'} = \@inBnotinA if @inBnotinA;

  for my $p (sort keys %do_compare) {
    my $tlpA = $tlpdbA->get_package($p);
    my $tlpB = $tlpdbB->get_package($p);
    my %foo = compare_tlpobjs($tlpA, $tlpB);
    if (keys %foo) {
      # some diffs were found
      $diffpacks{$p} = \%foo;
    }
  }
  $ret{'different_packages'} = \%diffpacks if (keys %diffpacks);

  return %ret;
}

sub tlnet_disabled_packages {
  my ($root) = @_;
  my $disabled_pkgs = "$root/tlpkg/dev/tlnet-disabled-packages.txt";
  my @ret;
  if (-r $disabled_pkgs) {
    open (DISABLED, "<$disabled_pkgs") || die "Huu, -r but cannot open: $?";
    while (<DISABLED>) {
      chomp;
      next if /^\s*#/;
      next if /^\s*$/;
      $_ =~ s/^\s*//;
      $_ =~ s/\s*$//;
      push @ret, $_;
    }
    close(DISABLED) || warn ("Cannot close tlnet-disabled-packages.txt: $?");
  }
  return @ret;
}

sub report_tlpdb_differences {
  my $rret = shift;
  my %ret = %$rret;

  if (defined($ret{'removed_packages'})) {
    info ("removed packages from A to B:\n");
    for my $f (@{$ret{'removed_packages'}}) {
      info ("  $f\n");
    }
  }
  if (defined($ret{'added_packages'})) {
    info ("added packages from A to B:\n");
    for my $f (@{$ret{'added_packages'}}) {
      info ("  $f\n");
    }
  }
  if (defined($ret{'different_packages'})) {
    info ("different packages from A to B:\n");
    for my $p (keys %{$ret{'different_packages'}}) {
      info ("  $p\n");
      for my $k (keys %{$ret{'different_packages'}->{$p}}) {
        if ($k eq "revision") {
          info("    revision differ: $ret{'different_packages'}->{$p}->{$k}\n");
        } elsif ($k eq "removed" || $k eq "added") {
          info("    $k files:\n");
          for my $f (@{$ret{'different_packages'}->{$p}->{$k}}) {
            info("      $f\n");
          }
        } else {
          info("  unknown differ $k\n");
        }
      }
    }
  }
}

sub sort_archs ($$) {
  my $aa = $_[0];
  my $bb = $_[1];
  $aa =~ s/^(.*)-(.*)$/$2-$1/;
  $bb =~ s/^(.*)-(.*)$/$2-$1/;
  $aa cmp $bb ;
}

# Taken from Text::ParseWords
#
sub quotewords {
  my($delim, $keep, @lines) = @_;
  my($line, @words, @allwords);

  foreach $line (@lines) {
    @words = parse_line($delim, $keep, $line);
    return() unless (@words || !length($line));
    push(@allwords, @words);
  }
  return(@allwords);
}

sub parse_line {
  my($delimiter, $keep, $line) = @_;
  my($word, @pieces);

  no warnings 'uninitialized';	# we will be testing undef strings

  $line =~ s/\s+$//; # kill trailing whitespace
  while (length($line)) {
    $line =~ s/^(["'])			# a $quote
              ((?:\\.|(?!\1)[^\\])*)	# and $quoted text
              \1				# followed by the same quote
                |				# --OR--
            ^((?:\\.|[^\\"'])*?)		# an $unquoted text
            (\Z(?!\n)|(?-x:$delimiter)|(?!^)(?=["']))
                  # plus EOL, delimiter, or quote
      //xs or return;		# extended layout
    my($quote, $quoted, $unquoted, $delim) = ($1, $2, $3, $4);
    return() unless( defined($quote) || length($unquoted) || length($delim));

    if ($keep) {
      $quoted = "$quote$quoted$quote";
    } else {
      $unquoted =~ s/\\(.)/$1/sg;
      if (defined $quote) {
        $quoted =~ s/\\(.)/$1/sg if ($quote eq '"');
        $quoted =~ s/\\([\\'])/$1/g if ( $PERL_SINGLE_QUOTE && $quote eq "'");
      }
    }
    $word .= substr($line, 0, 0);	# leave results tainted
    $word .= defined $quote ? $quoted : $unquoted;

    if (length($delim)) {
      push(@pieces, $word);
      push(@pieces, $delim) if ($keep eq 'delimiters');
      undef $word;
    }
    if (!length($line)) {
      push(@pieces, $word);
    }
  }
  return(@pieces);
}


=item C<mktexupd ()>

Append entries to C<ls-R> files.  Usage example:

  my $updLSR=&mktexupd();
  $updLSR->{mustexist}(1);
  $updLSR->{add}(file1);
  $updLSR->{add}(file2);
  $updLSR->{add}(file3);
  $updLSR->{exec}();
  
The first line creates a new object.  Only one such object should be 
created in a program in order to avoid duplicate entries in C<ls-R> files.

C<add> pushes a filename or a list of filenames to a hash encapsulated 
in a closure.  Filenames must be specified with the full (absolute) path.  
Duplicate entries are ignored.  

C<exec> checks for each component of C<$TEXMFDBS> whether there are files
in the hash which have to be appended to the corresponding C<ls-R> files 
and eventually updates the corresponding C<ls-R> files.  Files which are 
in directories not stated in C<$TEXMFDBS> are silently ignored.

If the flag C<mustexist> is set, C<exec> aborts with an error message 
if a file supposed to be appended to an C<ls-R> file doesn't exist physically
on the file system.  This option was added for compatibility with the 
C<mktexupd> shell script.  This option shouldn't be enabled in scripts,
except for testing, because it degrades performance on non-cached file
systems.

=cut

sub mktexupd {
  my %files;
  my $mustexist=0;

  my $hash={
    "add" => sub {     
      foreach my $file (@_) {
        $file =~ s|\\|/|g;
        $files{$file}=1;
      }
    },
    "reset" => sub { 
       %files=();
    },
    "mustexist" => sub {
      $mustexist=shift;
    },
   "exec" => sub {
      # check whether files exist
      if ($mustexist) {
        foreach my $file (keys %files) {
          die "mktexupd: exec file does not exist: $file" if (! -f $file);
        }
      }
      my $delim= (&win32)? ';' : ':';
      my $TEXMFDBS;
      chomp($TEXMFDBS=`kpsewhich --show-path="ls-R"`);

      my @texmfdbs=split ($delim, "$TEXMFDBS");
      my %dbs;
     
      foreach my $path (keys %files) {
        foreach my $db (@texmfdbs) {
          $db=substr($db, -1) if ($db=~m|/$|); # strip leading /
          $db = lc($db) if win32();
          $up = (win32() ? lc($path) : $path);
          if (substr($up, 0, length("$db/")) eq "$db/") {
            # we appended a / because otherwise "texmf" is recognized as a
            # substring of "texmf-dist".
            my $np = './' . substr($up, length("$db/"));
            my ($dir, $file);
            $_=$np;
            ($dir, $file) = m|(.*)/(.*)|;
            $dbs{$db}{$dir}{$file}=1;
          }
        }
      }
      foreach my $db (keys %dbs) {
        if (! -f "$db" || ! -w "$db/ls-R") {
          &mkdirhier ($db);
        }
        open LSR, ">>$db/ls-R";
        foreach my $dir (keys %{$dbs{$db}}) {
          print LSR "\n$dir:\n";
          foreach my $file (keys %{$dbs{$db}{$dir}}) {
            print LSR "$file\n";
          }
        }
        close LSR;
      }
    }
  };
  return $hash;
}


=item C<setup_sys_user_mode($prg, $optsref, $tmfc, $tmfsc, $tmfv, $tmfsv)>

Return two-element list C<($texmfconfig,$texmfvar)> of which directories
to use, either user or sys. If C<$prg> is C<mktexfmt>, and the system
dirs are writable, use them even if we are in user mode.

=cut

sub setup_sys_user_mode {
  my ($prg, $optsref, $TEXMFCONFIG, $TEXMFSYSCONFIG, 
      $TEXMFVAR, $TEXMFSYSVAR) = @_;
  
  if ($optsref->{'user'} && $optsref->{'sys'}) {
    print STDERR "$prg [ERROR]: only one of -sys or -user can be used.\n";
    exit(1);
  }

  # check if we are in *hidden* sys mode, in which case we switch
  # to sys mode
  # Nowdays we use -sys switch instead of simply overriding TEXMFVAR
  # and TEXMFCONFIG
  # This is used to warn users when they run updmap in usermode the first time.
  # But it might happen that this script is called via another wrapper that
  # sets TEXMFCONFIG and TEXMFVAR, and does not pass on the -sys option.
  # for this case we check whether the SYS and non-SYS variants agree,
  # and if, then switch to sys mode (with a warning)
  if (($TEXMFSYSCONFIG eq $TEXMFCONFIG) && ($TEXMFSYSVAR eq $TEXMFVAR)) {
    if ($optsref->{'user'}) {
      print STDERR "$prg [ERROR]: -user mode but path setup is -sys type, bailing out.\n";
      exit(1);
    }
    if (!$optsref->{'sys'}) {
      print STDERR "$prg [WARNING]: hidden sys mode found, switching to sys mode.\n"
        if (!$optsref->{'quiet'});
      $optsref->{'sys'} = 1;
    }
  }

  my ($texmfconfig, $texmfvar);
  if ($optsref->{'sys'}) {
    # we are running as updmap-sys, make sure that the right tree is used
    $texmfconfig = $TEXMFSYSCONFIG;
    $texmfvar    = $TEXMFSYSVAR;
    &debug("TLUtils::setup_sys_user_mode: sys mode\n");

  } elsif ($optsref->{'user'}) {
    $texmfconfig = $TEXMFCONFIG;
    $texmfvar    = $TEXMFVAR;
    &debug("TLUtils::setup_sys_user_mode: user mode\n");

    # mktexfmt is run (accidentally or on purpose) by a user with
    # missing formats; we want to put the resulting format dumps in
    # TEXMFSYSVAR if possible, so that future format updates will just
    # work. Until 2021, they were put in TEXMFVAR, causing problems.
    # 
    # We only do this for mktexfmt, not fmtutil; if fmtutil is called
    # explicitly with fmtutil -user, ok, do what they said to do.
    #
    if ($prg eq "mktexfmt") {
      my $switchit = 0;
      if (-d "$TEXMFSYSVAR/web2c") {
        $switchit = 1 if (-w "$TEXMFSYSVAR/web2c");
      } elsif (-d $TEXMFSYSVAR && -w $TEXMFSYSVAR) {
        $switchit = 1;
      }
      if ($switchit) {
        $texmfvar = $TEXMFSYSVAR;
        &ddebug("  switched to $texmfvar for mktexfmt\n");
      }
    }
  } else {
    print STDERR
      "$prg [ERROR]: Either -sys or -user mode is required.\n" .
      "$prg [ERROR]: In nearly all cases you should use $prg -sys.\n" .
      "$prg [ERROR]: For special cases see https://tug.org/texlive/scripts-sys-user.html\n" ;
    exit(1);
  }

  &debug("  returning: ($texmfconfig,$texmfvar)\n");
  return ($texmfconfig, $texmfvar);
}


=item C<prepend_own_path()>

Prepend the location of the TeX Live binaries to the PATH environment
variable. This is used by (e.g.) C<fmtutil>.  The location is found by
calling C<Cwd::abs_path> on C<which('kpsewhich')>. We use kpsewhich
because it is known to be a true binary executable; C<$0> could be a
symlink into (say) C<texmf-dist/scripts/>, which is not a useful
directory for PATH.

=cut

sub prepend_own_path {
  my $bindir = dirname(Cwd::abs_path(which('kpsewhich')));
  if (win32()) {
    $bindir =~ s!\\!/!g;
    $ENV{'PATH'} = "$bindir;$ENV{PATH}";
  } else {
    $ENV{'PATH'} = "$bindir:$ENV{PATH}";
  }
}


=item C<repository_to_array($r)>

Return hash of tags to urls for space-separated list of repositories
passed in C<$r>. If passed undef or empty string, die.

=cut

sub repository_to_array {
  my $r = shift;
  my %r;
  if (!$r) {
    # either empty string or undef was passed
    # before 20181023 we die here, now we return
    # an empty array
    return %r;
  }
  #die "internal error, repository_to_array passed nothing (caller="
  #    . caller . ")" if (!$r);
  my @repos = split (' ', $r);
  if ($#repos == 0) {
    # only one repo, this is the main one!
    $r{'main'} = $repos[0];
    return %r;
  }
  for my $rr (@repos) {
    my $tag;
    my $url;
    # decode spaces and % in reverse order
    $rr =~ s/%20/ /g;
    $rr =~ s/%25/%/g;
    $tag = $url = $rr;
    if ($rr =~ m/^([^#]+)#(.*)$/) {
      $tag = $2;
      $url = $1;
    }
    $r{$tag} = $url;
  }
  return %r;
}


=back

=head2 JSON

=over 4

=item C<encode_json($ref)>

Returns the JSON representation of the object C<$ref> is pointing at.
This tries to load the C<JSON> Perl module, and uses it if available,
otherwise falls back to module internal conversion.

The used backend can be selected by setting the environment variable
C<TL_JSONMODE> to either C<json> or C<texlive> (all other values are
ignored). If C<json> is requested and the C<JSON> module cannot be loaded
the program terminates.

=cut

my $TLTrueValue = 1;
my $TLFalseValue = 0;
my $TLTrue = \$TLTrueValue;
my $TLFalse = \$TLFalseValue;
bless $TLTrue, 'TLBOOLEAN';
bless $TLFalse, 'TLBOOLEAN';

our $jsonmode = "";

=pod

=item C<True()>

=item C<False()>

These two crazy functions must be used to get proper JSON C<true> and
C<false> in the output independent of the backend used.

=cut

sub True {
  ensure_json_available();
  if ($jsonmode eq "json") {
    return($JSON::true);
  } else {
    return($TLTrue);
  }
}
sub False {
  ensure_json_available();
  if ($jsonmode eq "json") {
    return($JSON::false);
  } else {
    return($TLFalse);
  }
}

sub ensure_json_available {
  return if ($jsonmode);
  # check the environment for mode to use:
  # $ENV{'TL_JSONMODE'} = texlive | json
  my $envdefined = 0;
  if ($ENV{'TL_JSONMODE'}) {
    $envdefined = 1;
    if ($ENV{'TL_JSONMODE'} eq "texlive") {
      $jsonmode = "texlive";
      debug("texlive json module used!\n");
      return;
    } elsif ($ENV{'TL_JSONMODE'} eq "json") {
      # nothing to do
    } else {
      tlwarn("Unsupported mode \'$ENV{TL_JSONMODE}\' set in TL_JSONMODE, ignoring it!");
      $envdefined = 0;
    }
  }
  return if ($jsonmode); # was set to texlive
  eval { require JSON; };
  if ($@) {
    # that didn't work out, use home-grown json
    if ($envdefined) {
      # environment asks for JSON but cannot be loaded, die!
      tldie("envvar TL_JSONMODE request JSON module but cannot be loaded!\n");
    }
    $jsonmode = "texlive";
    debug("texlive json module used!\n");
  } else {
    $jsonmode = "json";
    my $json = JSON->new;
    debug("JSON " . $json->backend . " used!\n");
  }
}

sub encode_json {
  my $val = shift;
  ensure_json_available();
  if ($jsonmode eq "json") {
    my $utf8_encoded_json_text = JSON::encode_json($val);
    return $utf8_encoded_json_text;
  } else {
    my $type = ref($val);
    if ($type eq "") {
      tldie("encode_json: accept only refs: $val");
    } elsif ($type eq 'SCALAR') {
      return(scalar_to_json($$val));
    } elsif ($type eq 'ARRAY') {
      return(array_to_json($val));
    } elsif ($type eq 'HASH') {
      return(hash_to_json($val));
    } elsif ($type eq 'REF') {
      return(encode_json($$val));
    } elsif (Scalar::Util::blessed($val)) {
      if ($type eq "TLBOOLEAN") {
        return($$val ? "true" : "false");
      } else {
        tldie("encode_json: unsupported blessed object");
      }
    } else {
      tldie("encode_json: unsupported format $type");
    }
  }
}

sub scalar_to_json {
  sub looks_like_numeric {
    # code from JSON/backportPP.pm
    my $value = shift;
    no warnings 'numeric';
    # detect numbers
    # string & "" -> ""
    # number & "" -> 0 (with warning)
    # nan and inf can detect as numbers, so check with * 0
    return unless length((my $dummy = "") & $value);
    return unless 0 + $value eq $value;
    return 1 if $value * 0 == 0;
    return -1; # inf/nan
  }
  my $val = shift;
  if (defined($val)) {
    if (looks_like_numeric($val)) {
      return("$val");
    } else {
      return(string_to_json($val));
    }
  } else {
    return("null");
  }
}

sub string_to_json {
  my $val = shift;
  my %esc = (
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
    "\f" => '\f',
    "\b" => '\b',
    "\"" => '\"',
    "\\" => '\\\\',
    "\'" => '\\\'',
  );
  $val =~ s/([\x22\x5c\n\r\t\f\b])/$esc{$1}/g;
  return("\"$val\"");
}

sub hash_to_json {
  my $hr = shift;
  my @retvals;
  for my $k (keys(%$hr)) {
    my $val = $hr->{$k};
    push @retvals, "\"$k\":" . encode_json(\$val);
  }
  my $ret = "{" . join(",", @retvals) . "}";
  return($ret);
}

sub array_to_json {
  my $hr = shift;
  my $ret = "[" . join(",", map { encode_json(\$_) } @$hr) . "]";
  return($ret);
}

=pod

=back

=cut

1;
__END__

=head1 SEE ALSO

The other modules in C<Master/tlpkg/TeXLive/> (L<TeXLive::TLConfig> and
the rest), and the scripts in C<Master/tlpg/bin/> (especially
C<tl-update-tlpdb>), the documentation in C<Master/tlpkg/doc/>, etc.

=head1 AUTHORS AND COPYRIGHT

This script and its documentation were written for the TeX Live
distribution (L<https://tug.org/texlive>) and both are licensed under the
GNU General Public License Version 2 or later.

=cut

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;
}
#!/usr/bin/env perl
# $Id: fmtutil.pl 60154 2021-08-03 21:55:56Z karl $
# fmtutil - utility to maintain format files.
# (Maintained in TeX Live:Master/texmf-dist/scripts/texlive.)
# 
# Copyright 2014-2021 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# History:
# Original shell script 2001 Thomas Esser, public domain

my $TEXMFROOT;

BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
  unshift(@INC, "$TEXMFROOT/tlpkg", "$TEXMFROOT/texmf-dist/scripts/texlive");
  require "mktexlsr.pl";
  TeX::Update->import();
}

my $svnid = '$Id: fmtutil.pl 60154 2021-08-03 21:55:56Z karl $';
my $lastchdate = '$Date: 2021-08-03 23:55:56 +0200 (Tue, 03 Aug 2021) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 60154 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use strict;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use File::Spec;
use Cwd;

# don't import anything automatically, this requires us to explicitly
# call functions with TeXLive::TLUtils prefix, and makes it easier to
# find and if necessary remove references to TLUtils
use TeXLive::TLUtils qw();

require TeXLive::TLWinGoo if TeXLive::TLUtils::win32;

# numerical constants
my $FMT_NOTSELECTED = 0;
my $FMT_DISABLED    = 1;
my $FMT_FAILURE     = 2;
my $FMT_SUCCESS     = 3;
my $FMT_NOTAVAIL    = 4;

my $nul = (win32() ? 'nul' : '/dev/null');
my $sep = (win32() ? ';' : ':');

my @deferred_stderr;
my @deferred_stdout;
# $::opt_verbosity = 3; # manually enable debugging

my $first_time_creation_in_usermode = 0;
my $first_time_usermode_warning = 1; # give lengthy warning if warranted?

my $DRYRUN = "";
my $STATUS_FH;

(our $prg = basename($0)) =~ s/\.pl$//;

# make sure that the main binary path is available at the front
TeXLive::TLUtils::prepend_own_path();

# sudo sometimes does not reset the home dir of root, check on that
# see more comments at the definition of the function itself
# this function checks by itself whether it is running on windows or not
reset_root_home();

chomp(our $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(our $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(our $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(our $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(our $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(our $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

# make sure that on windows *everything* is in lower case for comparison
if (win32()) {
  $TEXMFDIST = lc($TEXMFDIST);
  $TEXMFVAR = lc($TEXMFVAR);
  $TEXMFSYSVAR = lc($TEXMFSYSVAR);
  $TEXMFCONFIG = lc($TEXMFCONFIG);
  $TEXMFSYSCONFIG = lc($TEXMFSYSCONFIG);
  $TEXMFROOT = lc($TEXMFROOT);
  $TEXMFHOME = lc($TEXMFHOME);
}

#
# these need to be "our" variables since they are used from the 
# functions in TLUtils.pm.
our $texmfconfig = $TEXMFCONFIG;
our $texmfvar    = $TEXMFVAR;
our $alldata;

# command line options with defaults
# 20160623 - switch to turn on strict mode
our %opts = ( quiet => 0 , strict => 1 );

# make a list of all the commands (as opposed to options), so we can
# reasonably check for multiple commands being (erroneously) given.
my @cmdline_cmds = (  # in same order as help message
  "all",
  "missing",
  "byengine=s",
  "byfmt=s",
  "byhyphen=s",
  "enablefmt=s",
  "disablefmt=s",
  "listcfg",
  "showhyphen=s",
);

our @cmdline_options = (  # in same order as help message
  "sys",
  "user",
  "cnffile=s@", 
  "dry-run|n",
  "fmtdir=s",
  "no-engine-subdir",
  "no-error-if-no-engine=s",
  "no-error-if-no-format",
  "nohash",
  "recorder",
  "refresh",
  "status-file=s",
  "strict!",
  "quiet|silent|q",
  "catcfg",
  "dolinks",
  "force",
  "test",
#
  @cmdline_cmds,
  "version",
  "help|h",
#
  "edit",		# omitted from help to discourage use
  "_dumpdata",		# omitted from help, data structure dump for debugging
  );

my $updLSR;
my $mktexfmtMode = 0;
# make sure we echo only *one* line in mktexfmt mode
my $mktexfmtFirst = 1;

my $status = &main();
print_info("exiting with status $status\n");
exit $status;


# 
sub main {
  if ($prg eq "mktexfmt") {
    # mktexfmtMode: if called as mktexfmt, set to true. Will echo the
    # first generated filename after successful generation to stdout then
    # (and nothing else), since kpathsea can only deal with one.
    $mktexfmtMode = 1;

    # we default to user mode here, in particular because **if** TEXMFSYSVAR
    # is writable we will use it to save format dumps created by mktexfmt
    # If root is running mktexfmt, then most probably the formats will end
    # up in TEXMFSYSVAR which is fine.
    $opts{'user'} = 1;

    my @save_argv = @ARGV;
    GetOptions (
      "dry-run|n", \$opts{'dry-run'},
      "help" => \$opts{'help'},
      "version" => \$opts{'version'}
      ) || die "$prg: Unknown option in mktexfmt command line: @save_argv\n";

    help() if $opts{'help'};
    if ($opts{'version'}) {
      print version();
      exit 0;  # no final print_info
    }

    if ($ARGV[0]) {
      if ($ARGV[0] =~ m/^(.*)\.(fmt|mem|base?)$/) {
        $opts{'byfmt'} = $1;
      } elsif ($ARGV[0] =~ m/\./) {
        die "unknown format type: $ARGV[0]";
      } else {
        $opts{'byfmt'} = $ARGV[0];
      }
    } else {
      die "missing argument to mktexfmt";
    }
  } else {
    # fmtutil mode.
    GetOptions(\%opts, @cmdline_options)
      || die "Try \"$prg --help\" for more information.\n";
    if (@ARGV) {
      die "$0: Unexpected non-option argument(s): @ARGV\n"
          . "Try \"$prg --help\" for more information.\n";
    }
  }

  help() if $opts{'help'};
  if ($opts{'version'}) {
    print version();
    exit 0;  # no final print_info
  }

  { # if two commands were given, complain and give up.
    my @cmds = ();
    for my $c (@cmdline_cmds) {
      $c =~ s,=.*$,,;                       # remove =s getopt spec
      push(@cmds, $c) if exists $opts{$c};  # remember if getopt found it
      # we could save/report the specified arg too, but maybe not worth it.
    }
    if (@cmds > 1) {
      print_error("multiple commands found: @cmds\n"
                  . "Try $prg --help if you need it.\n");
      return 1;
    } elsif (@cmds == 0) {
      if ($opts{'refresh'}) {
        # backward compatibility: till 2021 we had --refresh as a command
        # but now we allow combining it with --byfmt etc
        # In case that --refresh was given without any other command, we
        # treat it as --all --refresh as it was the case till the change.
        $opts{'all'} = 1;
      } else {
        print_error("no command specified; try $prg --help if you need it.\n");
        return 1;
      }
    }
  }

  $DRYRUN = "echo " if ($opts{'dry-run'});

  if ($opts{'status-file'} && ! $opts{'dry-run'}) {
    if (! open($STATUS_FH, '>>', $opts{'status-file'})) {
      print_error("cannot open status file >>$opts{'status-file'}: $!\n");
      print_error("not writing status information!\n");
    }
  }
  
  # get the config/var trees we will use.
  ($texmfconfig, $texmfvar)
    = TeXLive::TLUtils::setup_sys_user_mode($prg, \%opts,
                       $TEXMFCONFIG, $TEXMFSYSCONFIG, $TEXMFVAR, $TEXMFSYSVAR);
  
  # if we are using the sys tree, we don't want to give the usermode warning.
  if ($texmfvar eq $TEXMFSYSVAR) {
    $first_time_usermode_warning = 0;
  }

  determine_config_files("fmtutil.cnf");
  my $changes_config_file = $alldata->{'changes_config'};
  # we do changes always in the used config file with the highest priority
  my $bakFile = $changes_config_file;
  $bakFile =~ s/\.cfg$/.bak/;
  my $changed = 0;

  read_fmtutil_files(@{$opts{'cnffile'}});

  unless ($opts{"nohash"}) {
    # should be replaced by new mktexlsr perl version
    $updLSR = new TeX::Update;
    $updLSR->mustexist(0);
  }

  my $cmd;
  if ($opts{'edit'}) {
    if ($opts{"dry-run"}) {
      printf STDERR "No, are you joking, you want to edit with --dry-run?\n";
      return 1;
    }
    # it's not a good idea to edit fmtutil.cnf manually these days,
    # but for compatibility we'll silently keep the option.
    $cmd = 'edit';
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'};
    $editor ||= (&win32 ? "notepad" : "vi");
    if (-r $changes_config_file) {
      &copyFile($changes_config_file, $bakFile);
    } else {
      touch($bakFile);
      touch($changes_config_file);
    }
    system("$DRYRUN$editor", $changes_config_file);
    $changed = files_are_different($bakFile, $changes_config_file);

  } elsif ($opts{'showhyphen'}) {
    my $f = $opts{'showhyphen'};
    if ($alldata->{'merged'}{$f}) {
      my @all_engines = keys %{$alldata->{'merged'}{$f}};
      for my $e (sort @all_engines) {
        my $hf = $alldata->{'merged'}{$f}{$e}{'hyphen'};
        next if ($hf eq '-');
        my $ff = `kpsewhich -progname='$f' -format=tex '$hf'`;
        chomp($ff);
        if ($ff ne "") {
          if ($#all_engines > 0) {
            printf "$f/$e: ";
          }
          printf "$ff\n";
        } else {
          print_warning("hyphenfile (for $f/$e) not found: $hf\n");
          return 1;
        }
      }
    }

  } elsif ($opts{'listcfg'}) {
    return callback_list_cfg();

  } elsif ($opts{'disablefmt'}) {
    return callback_enable_disable_format($changes_config_file, 
                                          $opts{'disablefmt'}, 'disabled');
  } elsif ($opts{'enablefmt'}) {
    return callback_enable_disable_format($changes_config_file, 
                                          $opts{'enablefmt'}, 'enabled');
  } elsif ($opts{'byengine'}) {
    return callback_build_formats('byengine', $opts{'byengine'});

  } elsif ($opts{'byfmt'}) {
    # for this option, allow/ignore an extension.
    (my $fmtname = $opts{'byfmt'}) =~ s,\.(fmt|mem|base?)$,,;
    return callback_build_formats('byfmt', $fmtname);

  } elsif ($opts{'byhyphen'}) {
    return callback_build_formats('byhyphen', $opts{'byhyphen'});

  } elsif ($opts{'missing'}) {
    return callback_build_formats('missing');

  } elsif ($opts{'all'}) {
    return callback_build_formats('all');

  } elsif ($opts{'_dumpdata'}) {
    dump_data();

  } else {
    # redundant with check above, but just in case ...
    print_error("missing command; try $prg --help if you need it.\n");
    return 1;
  }

  if ($STATUS_FH) {
    close($STATUS_FH)
    || print_error("cannot close $opts{'status-file'}: $!\n");
  }

  unless ($opts{'nohash'}) {
    # TODO should only do this if built something, e.g., not --listcfg
    print_info("updating ls-R files\n");
    $updLSR->exec() unless $opts{"dry-run"};
  }

  # some simpler options 
  return 0;
}

sub dump_data {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
  $Data::Dumper::Indent = 1;
  print Data::Dumper::Dumper($alldata);
}

#
sub log_to_status {
  if ($STATUS_FH) {
    print $STATUS_FH "@_\n";
  }
}

#  callback_build_formats - (re)builds the formats as selected,
# returns exit status or dies.  Exit status is always zero unless
# --strict is specified, in which case it's the number of failed builds
# (presumably always less than 256 :).
#
sub callback_build_formats {
  my ($what, $whatarg) = @_;

  # set up a tmp dir
  # On W32 it seems that File::Temp creates restrictive permissions (ok)
  # that are copied over with the files created inside it (not ok).
  # So make our own temp dir.
  my $tmpdir = "";
  if (! $opts{"dry-run"}) {
    if (win32()) {
      my $foo;
      my $tmp_deflt = File::Spec->tmpdir;
      for my $i (1..5) {
        # $foo = "$texmfvar/temp.$$." . int(rand(1000000));
        $foo = (($texmfvar =~ m!^//!) ? $tmp_deflt : $texmfvar)
          . "/temp.$$." . int(rand(1000000));
        if (! -d $foo) {
          TeXLive::TLUtils::mkdirhier($foo);
          sleep 1;
          if (-d $foo) {
            $tmpdir = $foo;
            last;
          }
        }
      }
      if (! $tmpdir) {
        die "Cannot get a temporary directory after five iterations, sorry!";
      }
      if ($texmfvar =~ m!^//!) {
        # used File::Spec->tmpdir; fix permissions
        TeXLive::TLWinGoo::maybe_make_ro ($tmpdir);
      }
    } else {
      $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    }
  }
  # set up destination directory
  $opts{'fmtdir'} ||= "$texmfvar/web2c";
  if (! $opts{"dry-run"}) {
    TeXLive::TLUtils::mkdirhier($opts{'fmtdir'}) if (! -d $opts{'fmtdir'});
    if (! -w $opts{'fmtdir'}) {
      print_error("format directory not writable: $opts{fmtdir}\n");
      exit 1;
    }
  }
  # since the directory does not exist, we can make it absolute with abs_path
  # without any trickery around non-existing dirs
  $opts{'fmtdir'} = Cwd::abs_path($opts{'fmtdir'});
  # for safety, check again
  die "abs_path failed, strange: $!" if !$opts{'fmtdir'};
  print_info("writing formats under $opts{fmtdir}\n"); # report

  # code taken over from the original shell script for KPSE_DOT etc
  my $thisdir = cwd();
  $ENV{'KPSE_DOT'} = $thisdir;
  # due to KPSE_DOT, we don't search the current directory, so include
  # it explicitly for formats that \write and later on \read
  $ENV{'TEXINPUTS'} ||= "";
  $ENV{'TEXINPUTS'} = "$tmpdir$sep$ENV{TEXINPUTS}";
  #
  # for formats that load other formats (e.g., jadetex loads latex.fmt),
  # add the current directory to TEXFORMATS, too.  Currently unnecessary
  # for MFBASES.
  $ENV{'TEXFORMATS'} ||= "";
  $ENV{'TEXFORMATS'} = "$tmpdir$sep$ENV{TEXFORMATS}";

  # switch to temporary directory for format generation; on the other hand,
  # for -n, the tmpdir won't exist, but we don't want to find a spurious
  # tex.fmt in the cwd. Probably won't be such things in /.
  chdir($opts{"dry-run"} ? "/" : $tmpdir)
  || die "Cannot change to directory $tmpdir: $!";
  
  # we rebuild formats in two rounds:
  # round 1: only formats with the same name as engine (pdftex/pdftex)
  # round 2: all other formats
  # reason: later formats might need earlier formats to be already
  # initialized, e.g., xmltex.
  my $suc = 0;
  my $err = 0;
  my @err = ();
  my $disabled = 0;
  my $nobuild = 0;
  my $notavail = 0;
  my $total = 0;
  for my $swi (qw/format=engine format!=engine/) {
    for my $fmt (keys %{$alldata->{'merged'}}) {
      for my $eng (keys %{$alldata->{'merged'}{$fmt}}) {
        next if ($swi eq "format=engine" && $fmt ne $eng);
        next if ($swi eq "format!=engine" && $fmt eq $eng);
        $total++;
        my $val = select_and_rebuild_format($fmt, $eng, $what, $whatarg);
        if ($val == $FMT_DISABLED)    {
          log_to_status("DISABLED", $fmt, $eng, $what, $whatarg);
          $disabled++;
        } elsif ($val == $FMT_NOTSELECTED) {
          log_to_status("NOTSELECTED", $fmt, $eng, $what, $whatarg);
          $nobuild++;
        } elsif ($val == $FMT_FAILURE)  {
          log_to_status("FAILURE", $fmt, $eng, $what, $whatarg);
          $err++;
          push (@err, "$eng/$fmt");
        } elsif ($val == $FMT_SUCCESS)  {
          log_to_status("SUCCESS", $fmt, $eng, $what, $whatarg);
          $suc++;
        } elsif ($val == $FMT_NOTAVAIL) {
          log_to_status("NOTAVAIL", $fmt, $eng, $what, $whatarg);
          $notavail++; 
        }
        else {
          log_to_status("UNKNOWN", $fmt, $eng, $what, $whatarg);
          print_error("callback_build_format (round 1): unknown return "
           . "from select_and_rebuild.\n");
        }
      }
    }
  }

  # if the user asked to rebuild something, but we did nothing, report
  # unless we tried to rebuild only missing formats.
  if ($what ne "missing") {
    if ($err + $suc == 0) {
      if ($what eq "all") {
        print_warning("You seem to have no formats defined in your fmtutil.cnf files!\n");
      } else {
        print_info("Did not find entry for $what=" . ($whatarg?$whatarg:"") . " skipped\n");
      }
    }
  }
  my $stdo = ($mktexfmtMode ? \*STDERR : \*STDOUT);
  for (@deferred_stdout) { print $stdo $_; }
  for (@deferred_stderr) { print STDERR $_; }
  #
  print_info("disabled formats: $disabled\n")        if ($disabled);
  print_info("successfully rebuilt formats: $suc\n") if ($suc);
  print_info("not selected formats: $nobuild\n")     if ($nobuild);
  print_info("not available formats: $notavail\n")   if ($notavail);
  print_info("failed to build: $err (@err)\n")       if ($err);
  print_info("total formats: $total\n");
  chdir($thisdir) || warn "chdir($thisdir) failed: $!";
  if (win32()) {
    # try to remove the tmpdir with all files
    TeXLive::TLUtils::rmtree($tmpdir);
  }
  #
  # In case of user mode and formats rebuilt, warn that these formats
  # will shadow future updates. Can be suppressed with --quiet which
  # does not show print_info output
  if ($opts{'user'} && $suc && $first_time_creation_in_usermode
      && $first_time_usermode_warning) {
    print_info("
*************************************************************
*                                                           *
* WARNING: you are switching to fmtutil's per-user formats. *
*         Please read the following warnings!               *
*                                                           *
*************************************************************

You have run fmtutil-user (as opposed to fmtutil-sys) for the first time;
this has created format files which are local to your personal account.

From now on, any changes in system formats will *not* be automatically
reflected in your files; furthermore, running fmtutil-sys will no longer
have any effect for you.

As a consequence, you yourself have to rerun fmtutil-user after any
change in the system directories. For example, when one of the LaTeX or
other format source files changes, which happens frequently.
See https://tug.org/texlive/scripts-sys-user.html for details.

If you want to undo this, remove the files mentioned above.

Run $prg --help for full documentation of fmtutil.
");
  }
  # return 
  return $opts{"strict"} ? $err : 0;
}

#  select_and_rebuild_format
# check condition and rebuild the format if selected
# return values: $FMT_*
# 
sub select_and_rebuild_format {
  my ($fmt, $eng, $what, $whatarg) = @_;
  return $FMT_DISABLED
      if ($alldata->{'merged'}{$fmt}{$eng}{'status'} eq 'disabled');

  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);

  my $doit = 0;
  # we just identify 'all', 'refresh', 'missing'
  # I don't see much point in keeping all of them
  $doit = 1 if ($what eq 'all');
  $doit = 1 if ($what eq 'refresh' && -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'missing' && ! -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'byengine' && $eng eq $whatarg);
  $doit = 1 if ($what eq 'byfmt' && $fmt eq $whatarg);
  #
  # Deal with the --refresh option
  # 2021 changed behavior that --refresh can be used with all other format
  # selection cmd line args.
  $doit = 0 if ($opts{'refresh'} && ! -r "$destdir/$fmtfile");
  #
  # TODO
  # original fmtutil.sh was stricter about existence of the hyphen file
  # not sure how we proceed here; let's implicitly ignore.
  #
  # original fmtutil.sh seemed to have accepted full path to the hyphen
  # file, so that one could give
  #   --byhyphen /full/path/to/the/hyphen/file
  # but this does not work anymore (see Debian bug report #815416)
  if ($what eq 'byhyphen') {
    my $fmthyp = (split(/,/ , $alldata->{'merged'}{$fmt}{$eng}{'hyphen'}))[0];
    if ($fmthyp ne '-') {
      if ($whatarg =~ m!^/!) {
        # $whatarg is a full path, we need to expand $fmthyp, too
        chomp (my $fmthyplong = `kpsewhich -progname=$fmt -engine=$eng $fmthyp`) ;
        if ($fmthyplong) {
          $fmthyp = $fmthyplong;
        } else {
          # we might have searched language.dat --engine=tex --progname=tex
          # which will not work. Search again without engine/format
          chomp ($fmthyplong = `kpsewhich $fmthyp`) ;
          if ($fmthyplong) {
            $fmthyp = $fmthyplong;
          } else {
            # don't give warnings or errors, it might be that the hyphen
            # file is not existing at all. See TODO above
            #print_deferred_warning("hyphen $fmthyp for $fmt/$eng cannot be expanded.\n");
          }
        }
      }
      if ($whatarg eq $fmthyp) {
        $doit = 1;
      }
    }
  }
  if ($doit) {
    check_and_warn_on_user_format($fmt,$eng);
    return rebuild_one_format($fmt,$eng,$kpsefmt,$destdir,$fmtfile,$logfile);
  } else {
    return $FMT_NOTSELECTED;
  }
}

sub check_and_warn_on_user_format {
  my ($fmt, $eng) = @_;
  # do nothing if we are updating files in $TEXMFVAR
  return if ($opts{'fmtdir'} eq "$TEXMFVAR/web2c");
  my $saved_fmtdir = $opts{'fmtdir'};
  $opts{'fmtdir'} = "$TEXMFVAR/web2c";
  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);
  if (-r "$destdir/$fmtfile") {
    print_deferred_warning("you have a shadowing format dump in TEXMFVAR for $fmt/$eng!!!\n");
  }
  $opts{'fmtdir'} = $saved_fmtdir;
}
  


#  compute_format_destination
# takes fmt/eng and returns the locations where format and log files
# should be saved, that is, a list: (dump file full path, log file full path)
# 
sub compute_format_destination {
  my ($fmt, $eng) = @_;
  my $enginedir;
  my $fmtfile = $fmt;
  my $kpsefmt;
  my $destdir;

  if ($eng eq "mpost") {
    $fmtfile .= ".mem" ;
    $kpsefmt = "mp" ;
    $enginedir = "metapost"; # the directory, not the executable
  } elsif ($eng =~ m/^mf(lua(jit)?)?(w|-nowin)?$/) {
    $fmtfile .= ".base" ;
    $kpsefmt = "mf" ;
    $enginedir = "metafont" ;
  } else {
    $fmtfile .= ".fmt" ;
    $kpsefmt = "tex" ;
    $enginedir = $eng;
    # strip final -dev from enginedir to support engines like luatex-dev
    $enginedir =~ s/-dev$//;
  }
  if ($opts{'no-engine-subdir'}) {
    $destdir = $opts{'fmtdir'};
  } else {
    $destdir = "$opts{'fmtdir'}/$enginedir";
  }
  return($kpsefmt, $destdir, $fmtfile, "$fmt.log");
}


#  rebuild_one_format
# takes fmt/eng and rebuilds it, irrelevant of any setting;
# copies generated log file
# return value FMT_*
#
sub rebuild_one_format {
  my ($fmt,$eng,$kpsefmt,$destdir,$fmtfile,$logfile) = @_;
  print_info("--- remaking $fmt with $eng\n");

  # get variables
  my $hyphen  = $alldata->{'merged'}{$fmt}{$eng}{'hyphen'};
  my $addargs = $alldata->{'merged'}{$fmt}{$eng}{'args'};

  # running parameters
  my $jobswitch = "-jobname=$fmt";
  my $prgswitch = "-progname=" ;
  my $recorderswitch = ($opts{'recorder'} ? "-recorder" : "");
  my $pool;
  my $tcx = "";
  my $tcxflag = "";
  my $localpool = 0;
  my $texargs;

  unlink glob "*.pool";

  # addargs processing:
  # can contain:
  # nls stuff (pool/tcx) see below
  # ini file (last argument)
  my $inifile = $addargs;
  $inifile = (split(' ', $addargs))[-1];
  # get rid of leading * in inifiles
  $inifile =~ s/^\*//;

  if ($fmt eq "metafun")       { $prgswitch .= "mpost"; }
  elsif ($fmt eq "mptopdf")    { $prgswitch .= "context"; }
  elsif ($fmt =~ m/^cont-..$/) { $prgswitch .= "context"; }
  else                         { $prgswitch .= $fmt; }

  # check for existence of ini file before doing anything else
  if (system("kpsewhich -progname=$fmt -format=$kpsefmt $inifile >$nul 2>&1") != 0) {
    # we didn't find the ini file, skip
    print_deferred_warning("inifile $inifile for $fmt/$eng not found.\n");
    # The original script just skipped it but in TeX Live we expect that
    # all activated formats are also buildable, thus return failure.
    return $FMT_FAILURE;
  }

  #
  # If the 4th field in fmtutil.cnf contains
  #  -progname=...
  # then we do not add our own progname!
  if ($addargs =~ /-progname=/) {
    $prgswitch = '';
  }

  # NLS support
  #   Example (for fmtutil.cnf):
  #     mex-pl tex mexconf.tex nls=tex-pl,il2-pl mex.ini
  # The nls parameter (pool,tcx) can only be specified as the first argument
  # inside the 4th field in fmtutil.cnf.
  if ($addargs =~ m/^nls=([^\s]+)\s+(.*)$/) {
    $texargs = $2;
    ($pool, $tcx) = split(',', $1);
    $tcx || ($tcx = '');
  } else {
    $texargs = $addargs;
  }
  if ($pool) {
    chomp (my $poolfile = `kpsewhich -progname=$eng $pool.pool 2>$nul`);
    if ($poolfile && -f $poolfile) {
      print_verbose("attempting to create localized format "
                    . "using pool=$pool and tcx=$tcx.\n");
      TeXLive::TLUtils::copy("-f", $poolfile, "$eng.pool");
      $tcxflag = "-translate-file=$tcx" if ($tcx);
      $localpool = 1;
    }
  }

  # Check for infinite recursion before running the iniengine:
  # We do this check only if we are running in mktexfmt mode
  # otherwise double format definitions will create an infinite loop, too
  if ($mktexfmtMode) {
    if ($ENV{'mktexfmt_loop'}) {
      if ($ENV{'mktexfmt_loop'} =~ m!:$fmt/$eng:!) {
        die "$prg: infinite recursion detected in $fmt/$eng, giving up!";
      }
    } else {
      $ENV{'mktexfmt_loop'} = '';
    }
    $ENV{'mktexfmt_loop'} .= ":$fmt/$eng:";
  }

  #
  # check for existence of $engine
  # we do *NOT* use the return value but rely on execution of the shell
  if (!TeXLive::TLUtils::which($eng)) {
    if ($opts{'no-error-if-no-engine'} &&
        ",$opts{'no-error-if-no-engine'}," =~ m/,$eng,/) {
      return $FMT_NOTAVAIL;
    } else {
      print_deferred_error("not building $fmt due to missing engine: $eng\n");
      return $FMT_FAILURE;
    }
  }

  my $cmdline = "$eng -ini $tcxflag $recorderswitch $jobswitch "
                  . "$prgswitch $texargs";
  print_verbose("running \`$cmdline' ...\n");

  my $texpool = $ENV{'TEXPOOL'};
  if ($localpool) {
    $ENV{'TEXPOOL'} = cwd() . $sep . ($texpool ? $texpool : "");
  }

  # in mktexfmtMode we must redirect *all* output to stderr
  $cmdline .= " >&2" if $mktexfmtMode;
  $cmdline .= " <$nul";
  my $retval = system("$DRYRUN$cmdline");

  # report error if it failed.
  if ($retval != 0) {
    $retval /= 256 if ($retval > 0);
    print_deferred_error("running \`$cmdline' return status: $retval\n");
  }

  # Copy the log file after the program is run, so that the log file
  # is available to inspect even on failure. So we need the dest dir tree.
  TeXLive::TLUtils::mkdirhier($destdir) if ! $opts{"dry-run"};
  #
  if ($opts{"dry-run"}) {
    print_info("would copy log file to: $destdir/$logfile\n");
  } else {
    # Here and in the following we use copy instead of move
    # to make sure that in SElinux enabled cases the rules of
    # the destination directory are applied.
    # See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=900580
    # 
    if (TeXLive::TLUtils::copy("-f", $logfile, "$destdir/$logfile")) {
      print_info("log file copied to: $destdir/$logfile\n");
    } else {
      print_deferred_error("failed to copy log $logfile to: $destdir\n");
    }
  }

  # original shell script did *not* check the return value
  # we keep this behavior, but add an option --strict that
  # errors out on all failures.
  if ($retval != 0 && $opts{'strict'}) {
    print_deferred_error("returning error due to option --strict\n");
    return $FMT_FAILURE;
  }

  if ($localpool) {
    if ($texpool) {
      $ENV{'TEXPOOL'} = $texpool;
    } else {
      delete $ENV{'TEXPOOL'};
    }
  }

  # if this was a dry run, we don't expect anything to have been
  # created, so there's nothing to inspect or copy. Call it good.
  if ($opts{"dry-run"}) {
    print_info("dry run, so returning success: $fmtfile\n");
    return $FMT_SUCCESS;
  }

  # check and install of fmt and log files
  if (! -s $fmtfile) {
    print_deferred_error("no (or empty) $fmtfile made by: $cmdline\n");
    return $FMT_FAILURE;
  }

  if (! -f $logfile) {
    print_deferred_error("no log file generated for: $fmt/$eng\n");
    return $FMT_FAILURE;
  }

  open (LOGFILE, "<$logfile")
    || print_deferred_warning("cannot open $logfile, strange: $!\n");
  my @logfile = <LOGFILE>;
  close LOGFILE;
  if (grep(/^!/, @logfile) > 0) {
    print_deferred_error("\`$cmdline' had errors.\n");
  }

  if ($opts{'recorder'}) {
    # the recorder output is used by tl-check-fmttriggers to determine
    # package dependencies for each format.  Unfortunately omega-based
    # engines gratuitiously changed the extension from .fls to .ofl.
    my $recfile = $fmt . ($fmt =~ m/^(aleph|lamed)$/ ? ".ofl" : ".fls");
    if (! TeXLive::TLUtils::copy("-f", $recfile, "$destdir/$recfile")) {
      print_deferred_error("cannot copy recorder $recfile to: $destdir\n");
    }
  }

  my $destfile = "$destdir/$fmtfile";
  # set flag to warn that new user format was installed
  # we check whether the next command **would** create a new file,
  # and if it succeeded, we set the actual flag.
  my $possibly_warn = ($opts{'user'} && ! -r $destfile);
  if (TeXLive::TLUtils::copy("-f", $fmtfile, $destfile)) {
    print_info("$destfile installed.\n");
    $first_time_creation_in_usermode = $possibly_warn;
    #
    # original fmtutil.sh did some magic trick for mplib-luatex.mem
    # nowadays no mplib mem is created and all files loaded
    # so we comment and do not convert this
    #
    ## As a special special case, we create mplib-luatex.mem for use by
    ## the mplib embedded in luatex if it doesn't already exist.  (We
    ## never update it if it does exist.)
    ##
    ## This is used by the luamplib package.  This way, an expert user
    ## who wants to try a new version of luatex (hence with a new
    ## version of mplib) can manually update mplib-luatex.mem without
    ## having to tamper with mpost itself.
    ##
    ##  if test "x$format" = xmpost && test "x$engine" = xmpost; then
    ##    mplib_mem_name=mplib-luatex.mem
    ##    mplib_mem_file=$fulldestdir/$mplib_mem_name
    ##    if test \! -f $mplib_mem_file; then
    ##      verboseMsg "$progname: copying $destfile to $mplib_mem_file"
    ##      if cp "$destfile" "$mplib_mem_file" </dev/null; then
    ##        mktexupd "$fulldestdir" "$mplib_mem_name"
    ##      else
    ##        ## failure to copy merits failure handling: e.g., full file system.
    ##        log_failure "cp $destfile $mplib_mem_file failed."
    ##      fi
    ##    else
    ##      verboseMsg "$progname: $mplib_mem_file already exists, not updating."
    ##    fi
    ##  fi

    if ($mktexfmtMode && $mktexfmtFirst) {
      print "$destfile\n";
      $mktexfmtFirst = 0;
    }

    unless ($opts{'nohash'}) {
      $updLSR->add($destfile);
      $updLSR->exec();
      $updLSR->reset();
    }

    return $FMT_SUCCESS;

  } else {
    print_deferred_error("cannot copy format $fmtfile to: $destfile\n");
    if (-f $destfile) {
      # remove the empty file possibly left over if near-full file system.
      print_verbose("removing partial file after copy failure: $destfile\n");
      unlink($destfile)
        || print_deferred_error("unlink($destfile) failed: $!\n");
    }
    return $FMT_FAILURE;
  }

  print_deferred_error("we should not be here! $fmt/$eng\n");
  return $FMT_FAILURE;
}


# 
# enable_disable_format_engine
# assumes that format/engine is already defined somewhere,
# i.e., it $alldata->{'merged'}{$fmt}{$eng} is defined
#
# Return values:
# 1 - success with changes
# 0 - no changes done
# -1 - error appeared
sub enable_disable_format_engine {
  my ($tc, $fmt, $eng, $mode) = @_;
  if ($mode eq 'enabled' || $mode eq 'disabled') {
    if ($alldata->{'merged'}{$fmt}{$eng}{'status'} eq $mode) {
      print_info("Format/engine combination $fmt/$eng already $mode.\n");
      print_info("No changes done.\n");
      return 0;
    } else {
      my $origin = $alldata->{'merged'}{$fmt}{$eng}{'origin'};
      if ($origin ne $tc) {
        $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng} =
          {%{$alldata->{'fmtutil'}{$origin}{'formats'}{$fmt}{$eng}}};
        $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng}{'line'} = -1;
      }
      $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng}{'status'} = $mode;
      $alldata->{'fmtutil'}{$tc}{'changed'} = 1;
      $alldata->{'merged'}{$fmt}{$eng}{'status'} = $mode;
      $alldata->{'merged'}{$fmt}{$eng}{'origin'} = $tc;
      # dump_data();
      return save_fmtutil($tc);
    }
  } else {
    print_error("enable_disable_format_engine: unknown mode $mode\n");
    exit 1;
  }
}  

#
# enable a format named
#   format[/engine]
# where the engine part is optional
# Case 1: no "engine" given:
# - if format is defined and has only one engine instance -> activate
# - if format is defined and has more than one engine -> error
# Case 2: engine given:
# - if format/engine is defined -> activate
# - if format/engine is not defined -> error
#
# Return values:
# 1 - success with changes
# 0 - no changes done
# -1 - error appeared
sub callback_enable_disable_format {
  my ($tc, $fmtname, $mode) = @_;
  my ($fmt, $eng) = split('/', $fmtname, 2);
  if ($mode ne 'enabled' && $mode ne 'disabled') {
    print_error("callback_enable_disable_format: unknown mode $mode.\n");
    exit 1;
  }
  if ($eng) {
    if ($alldata->{'merged'}{$fmt}{$eng}) {
      return enable_disable_format_engine($tc, $fmt, $eng, $mode);
    } else {
      print_warning("Format/engine combination $fmt/$eng is not defined.\n");
      print_warning("Cannot (de)activate it.\n");
      return -1;
    }
  } else {
    # no engine given, check the number of entries
    if ($alldata->{'merged'}{$fmt}) {
      my @engs = keys %{$alldata->{'merged'}{$fmt}};
      if (($#engs > 0) || ($#engs == -1)) {
        print_warning("Selected format $fmt not uniquely defined;\n");
        print_warning("possible format/engine combinations:\n");
        for my $e (@engs) {
          print_warning("  $fmt/$e (currently "
                        . $alldata->{'merged'}{$fmt}{$e}{'status'} . ")\n");
        }
        print_warning("Please select one by fully specifying $fmt/ENGINE\n");
        print_warning("No changes done.\n");
        return 0;
      } else {
        # only one engine, enable it if necessary!
        return enable_disable_format_engine($tc, $fmt, $engs[0], $mode);
      }
    } else {
      print_warning("Format $fmt is not defined;\n");
      print_warning("cannot (de)activate it.\n");
      return -1;
    }
  }
}


sub callback_list_cfg {
  my @lines;
  for my $f (keys %{$alldata->{'merged'}}) {
    for my $e (keys %{$alldata->{'merged'}{$f}}) {
      my $orig = $alldata->{'merged'}{$f}{$e}{'origin'};
      my $hyph = $alldata->{'merged'}{$f}{$e}{'hyphen'};
      my $stat = $alldata->{'merged'}{$f}{$e}{'status'};
      my $args = $alldata->{'merged'}{$f}{$e}{'args'};
      push @lines,
        [ "$f/$e/$hyph",
          "$f (engine=$e) $stat\n  hyphen=$hyph, args=$args\n  origin=$orig\n" ];
    }
  }
  # sort lines
  @lines = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @lines;
  print "List of all formats:\n";
  print @lines;
  
  return @lines == 0; # only return failure if no formats.
}


# sets %alldata.
# 
sub read_fmtutil_files {
  my (@l) = @_;
  for my $l (@l) { read_fmtutil_file($l); }
  # in case the changes_config is a new one read it in and initialize it here
  # the file might be already readable but not in ls-R so not found by
  # kpsewhich. That means we need to check that it is readable and whether
  # the lines entry is already defined
  my $cc = $alldata->{'changes_config'};
  if ((! -r $cc) || (!$alldata->{'fmtutil'}{$cc}{'lines'}) ) {
    $alldata->{'fmtutil'}{$cc}{'lines'} = [ ];
  }
  #
  $alldata->{'order'} = \@l;
  #
  # determine the origin of all formats
  for my $fn (reverse @l) {
    my @format_names = keys %{$alldata->{'fmtutil'}{$fn}{'formats'}};
    for my $f (@format_names) {
      for my $e (keys %{$alldata->{'fmtutil'}{$fn}{'formats'}{$f}}) {
        $alldata->{'merged'}{$f}{$e}{'origin'} = $fn;
        $alldata->{'merged'}{$f}{$e}{'hyphen'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'hyphen'} ;
        $alldata->{'merged'}{$f}{$e}{'status'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'status'} ;
        $alldata->{'merged'}{$f}{$e}{'args'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'args'} ;
      }
    }
  }
}

# 
sub read_fmtutil_file {
  my $fn = shift;
  open(FN, "<$fn") || die "Cannot read $fn: $!";
  #
  # we count lines from 0 ..!!!!?
  my $i = -1;
  my $printline = 0; # but not in error messages
  my @lines = <FN>;
  chomp(@lines);
  $alldata->{'fmtutil'}{$fn}{'lines'} = [ @lines ];
  close(FN) || warn("$prg: Cannot close $fn: $!");
  for (@lines) {
    $i++;
    $printline++;
    chomp;
    my $orig_line = $_;
    next if /^\s*#?\s*$/; # ignore empty and all-blank and just-# lines
    next if /^\s*#[^!]/;  # ignore whole-line comment that is not a disable
    s/#[^!].*//;          # remove within-line comment that is not a disable
    s/#$//;               # remove # at end of line
    my ($a,$b,$c,@rest) = split (' '); # special split rule, leading ws ign
    if (! $b) { # as in: "somefmt"
      print_warning("no engine specified for format $a, ignoring "
                    . "(file $fn, line $printline)\n");
      next;
    }
    if (! $c) { # as in: "somefmt someeng"
      print_warning("no pattern argument specified for $a/$b, ignoring line: "
                    . "$orig_line (file $fn, line $printline)\n");
      next;
    }
    if (@rest == 0) { # as in: "somefmt someeng somepat"
      print_warning("no inifile argument(s) specified for $a/$b, ignoring line: "
                    . "$orig_line (file $fn, line $printline)\n");
      next;
    }
    my $disabled = 0;
    if ($a eq "#!") {
      # we cannot feasibly determine whether a line is a proper fmtline or
      # not, so we have to assume that it is as long as we have four args.
      my $d = shift @rest;
      if (!defined($d)) {
        print_warning("apparently not a real disable line, ignoring: "
                      . "$orig_line (file $fn, line $printline)\n");
        next;
      } else {
        $disabled = 1;
        $a = $b; $b = $c; $c = $d;
      }
    }
    if (defined($alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b})) {
      print_warning("double mention of $a/$b in $fn\n");
    } else {
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'hyphen'} = $c;
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'args'} = "@rest";
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'status'}
        = ($disabled ? 'disabled' : 'enabled');
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'line'} = $i;
    }
  }
}



# 
# FUNCTIONS THAT SHOULD GO INTO TLUTILS.PM
# and also be reused in updmap.pl!!!


# sets global $alldata->{'changes_config'} to the config file to be
# changed if requested.
#
sub determine_config_files {
  my $fn = shift;

  # config file for changes
  my $changes_config_file;

  # determine which config files should be used
  # we also determine here where changes will be saved to
  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
        # if $f is a pure file name, that is dirname $f == ".",
        # then try to find it via kpsewhich
        if (dirname($f) eq ".") {
          chomp(my $kpfile = `kpsewhich $f`);
          if ($kpfile ne "") {
            $f = $kpfile;
          } else {
            die "$prg: Config file \"$f\" cannot be found via kpsewhich";
          }
        } else {
          die "$prg: Config file \"$f\" not found";
        }
      }
      push @tmp, (win32() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    # in case that config files are given on the command line, the first
    # in the list is the one where changes will be written to.
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all $fn`;
    chomp(@all_files);
    my @used_files;
    for my $f (@all_files) {
      push @used_files, (win32() ? lc($f) : $f);
    }
    #
    my $TEXMFLOCALVAR;
    my @TEXMFLOCAL;
    if (win32()) {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path=\$TEXMFLOCAL`);
      @TEXMFLOCAL = map { lc } split(/;/ , $TEXMFLOCALVAR);
    } else {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path='\$TEXMFLOCAL'`);
      @TEXMFLOCAL = split /:/ , $TEXMFLOCALVAR;
    }
    #
    # search for TEXMFLOCAL/web2c/$fn
    my @tmlused;
    for my $tml (@TEXMFLOCAL) {
      my $TMLabs = Cwd::abs_path($tml);
      next if (!$TMLabs);
      if (-r "$TMLabs/web2c/$fn") {
        push @tmlused, "$TMLabs/web2c/$fn";
      }
    }
    #
    # See help message for list of locations.
    @{$opts{'cnffile'}} = @used_files;
    #
    # determine the config file that we will use for changes
    # if in the list of used files contains either one from
    # TEXMFHOME or TEXMFCONFIG (TEXMFSYSCONFIG in the -sys case)
    # then use the *top* file (which will be either one of the two),
    # if neither of the two exists, create a file in TEXMFCONFIG and use it.
    my $use_top = 0;
    for my $f (@used_files) {
      if ($f =~ m!(\Q$TEXMFHOME\E|\Q$texmfconfig\E)/web2c/$fn!) {
        $use_top = 1;
        last;
      }
    }
    if ($use_top) {
      ($changes_config_file) = @used_files;
    } else {
      # add the empty config file
      my $dn = "$texmfconfig/web2c";
      $changes_config_file = "$dn/$fn";
    }
  }
  if (!$opts{'quiet'}) {
    print_verbose("$prg is using the following $fn files"
                  . " (in precedence order):\n");
    for my $f (@{$opts{'cnffile'}}) {
      print_verbose("  $f\n");
    }
    print_verbose("$prg is using the following $fn file"
                  . " for writing changes:\n");
    print_verbose("  $changes_config_file\n");
  }
  if ($opts{'listfiles'}) {
    # we listed it above, so be done
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;
}



# returns 1 if actually saved due to changes
sub save_fmtutil {
  my $fn = shift;
  return 0 if $opts{'dry-run'};
  my %fmtf = %{$alldata->{'fmtutil'}{$fn}};
  if ($fmtf{'changed'}) {
    TeXLive::TLUtils::mkdirhier(dirname($fn));
    open (FN, ">$fn") || die "$prg: can't write to $fn: $!";
    my @lines = @{$fmtf{'lines'}};
    if (!@lines) {
      print_verbose ("Creating new config file $fn\n");
      unless ($opts{"nohash"}) {
        # update lsR database
        $updLSR->add($fn);
        $updLSR->exec();
        $updLSR->reset();
      }
    }
    # collect the lines with data
    my %line_to_fmt;
    my @add_fmt;
    if (defined($fmtf{'formats'})) {
      for my $f (keys %{$fmtf{'formats'}}) {
        for my $e (keys %{$fmtf{'formats'}{$f}}) {
          if ($fmtf{'formats'}{$f}{$e}{'line'} == -1) {
            push @add_fmt, [ $f, $e ];
          } else {
            $line_to_fmt{$fmtf{'formats'}{$f}{$e}{'line'}} = [ $f, $e ];
          }
        }
      }
    }
    for my $i (0..$#lines) {
      if (defined($line_to_fmt{$i})) {
        my $f = $line_to_fmt{$i}->[0];
        my $e = $line_to_fmt{$i}->[1];
        my $mode = $fmtf{'formats'}{$f}{$e}{'status'};
        my $args = $fmtf{'formats'}{$f}{$e}{'args'};
        my $hyph = $fmtf{'formats'}{$f}{$e}{'hyphen'};
        my $p = ($mode eq 'disabled' ? "#! " : "");
        print FN "$p$f $e $hyph $args\n";
      } else {
        print FN "$lines[$i]\n";
      }
    }
    # add the new settings and maps
    for my $m (@add_fmt) {
      my $f = $m->[0];
      my $e = $m->[1];
      my $mode = $fmtf{'formats'}{$f}{$e}{'status'};
      my $args = $fmtf{'formats'}{$f}{$e}{'args'};
      my $hyph = $fmtf{'formats'}{$f}{$e}{'hyphen'};
      my $p = ($mode eq 'disabled' ? "#! " : "");
      print FN "$p$f $e $hyph $args\n";
    }
    close(FN) || warn("$prg: Cannot close file handle for $fn: $!");
    delete $alldata->{'fmtutil'}{$fn}{'changed'};
    return 1;
  }
  return 0;
}


#
# $HOME and sudo and updmap-sys horror
#   some instances of sudo do not reset $HOME to the home of root
#   as an effect of "sudo updmap" creates root owned files in the home 
#   of a normal user, and "sudo updmap-sys" uses map files and updmap.cfg
#   files from the directory of a normal user, but creating files
#   in TEXMFSYSCONFIG. This is *all* wrong.
#   we check: if we are running as UID 0 (root) on Unix and the
#   ENV{HOME} is NOT the same as the one of root, then give a warning
#   and reset it to the real home dir of root.

sub reset_root_home {
  if (!win32() && ($> == 0)) {  # $> is effective uid
    my $envhome = $ENV{'HOME'};
    # if $HOME isn't an existing directory, we don't care.
    if (defined($envhome) && (-d $envhome)) {
      # we want to avoid calling getpwuid as far as possible, so if
      # $envhome is one of some usual values we accept it without worrying.
      if ($envhome =~ m,^(/|/root|/var/root)/*$,) {
        return;
      }
      # $HOME is defined, check what is the home of root in reality
      my (undef,undef,undef,undef,undef,undef,undef,$roothome) = getpwuid(0);
      if (defined($roothome)) {
        if ($envhome ne $roothome) {
          print_warning("resetting \$HOME value (was $envhome) to root's "
            . "actual home ($roothome).\n");
          $ENV{'HOME'} = $roothome;
        } else {
          # envhome and roothome do agree, nothing to do, that is the good case
        }
      } else { 
        print_warning("home of root not defined, strange!\n");
      }
    }
  }
}

# printing to stdout (in mktexfmtMode also going to stderr!)
#   print_info    can be suppressed with --quiet
#   print_verbose cannot be suppressed
# printing to stderr
#   print_warning can be suppressed with --quiet
#   print_error   cannot be suppressed
#
sub print_info {
  if ($mktexfmtMode) {
    print STDERR "$prg [INFO]: ", @_ if (!$opts{'quiet'});
  } else {
    print STDOUT "$prg [INFO]: ", @_ if (!$opts{'quiet'});
  }
}
sub print_verbose {
  if ($mktexfmtMode) {
    print STDERR "$prg: ", @_;
  } else {
    print STDOUT "$prg: ", @_;
  }
}
sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opts{'quiet'}) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}
#
# same with deferred
sub print_deferred_info {
  push @deferred_stdout, "$prg [INFO]: @_" if (!$opts{'quiet'});
}
sub print_deferred_verbose {
  push @deferred_stdout, "$prg: @_";
}
sub print_deferred_warning {
  push @deferred_stderr, "$prg [WARNING]: @_" if (!$opts{'quiet'}) 
}
sub print_deferred_error {
  push @deferred_stderr, "$prg [ERROR]: @_";
}


# copied from TeXLive::TLUtils to reduce dependencies
sub win32 {
  if ($^O =~ /^MSWin/i) {
    return 1;
  } else {
    return 0;
  }
}



# version, help.

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub help {
  my $usage = <<"EOF";
Usage: $prg      [-user|-sys] [OPTION] ... [COMMAND]
   or: $prg-sys  [OPTION] ... [COMMAND]
   or: $prg-user [OPTION] ... [COMMAND]
   or: mktexfmt  FORMAT.fmt|BASE.base|FMTNAME

Rebuild and manage TeX fmts and Metafont bases, collectively called
"formats" here. (MetaPost no longer uses the past-equivalent "mems".)

If not operating in mktexfmt mode, exactly one command must be given,
filename suffixes should generally not be specified, no non-option
arguments are allowed, and multiple formats can be generated.

If the command name ends in mktexfmt, only one format can be created.
The only options supported are --help and --version, and the command
line must be either a format name, with extension, or a plain name that
is passed as the argument to --byfmt (see below).  The full name of the
generated file (if any) is written to stdout, and nothing else.  The
system directories are used if they are writable, else the user directories.

By default, the return status is zero if all formats requested are
successfully built, else nonzero.

Options:
  --sys                   use TEXMFSYS{VAR,CONFIG}
  --user                  use TEXMF{VAR,CONFIG}
  --cnffile FILE          read FILE instead of fmtutil.cnf
                           (can be given multiple times, in which case
                           all the files are used)
  --dry-run, -n           don't actually build formts
  --fmtdir DIR            write formats under DIR instead of TEXMF[SYS]VAR
  --no-engine-subdir      don't use engine-specific subdir of the fmtdir
  --no-error-if-no-format  exit successfully if no format is selected
  --no-error-if-no-engine=ENGINE1,ENGINE2,...
                          exit successfully even if a required ENGINE
                           is missing, if it is included in the list.
  --no-strict             exit successfully even if a format fails to build
  --nohash                don't update ls-R files
  --recorder              pass the -recorder option and save .fls files
  --refresh               recreate only existing format files
  --status-file FILE      append status information about built formats to FILE
  --quiet                 be silent
  --catcfg                (does nothing, exists for compatibility)
  --dolinks               (does nothing, exists for compatibility)
  --force                 (does nothing, exists for compatibility)
  --test                  (does nothing, exists for compatibility)

Commands:
  --all                   recreate all format files
  --missing               create all missing format files
  --byengine ENGINE       (re)create formats built with ENGINE
  --byfmt FORMAT          (re)create format FORMAT
  --byhyphen HYPHENFILE   (re)create formats that depend on HYPHENFILE
  --enablefmt  FORMAT[/ENGINE]  enable FORMAT, as built with ENGINE
  --disablefmt FORMAT[/ENGINE]  disable FORMAT, as built with ENGINE
                          If multiple formats have the same name and
                           different engines, /ENGINE specifier is required.
  --listcfg               list (enabled and disabled) configurations,
                           filtered to available formats
  --showhyphen FORMAT     print name of hyphen file for FORMAT
  --version               show version information and exit
  --help                  show this message and exit

Explanation of trees and files normally used:

  If --cnffile is specified on the command line (possibly multiple
  times), its value(s) are used.  Otherwise, fmtutil reads all the
  fmtutil.cnf files found by running "kpsewhich -all fmtutil.cnf", in the
  order returned by kpsewhich.  Files specified via --cnffile are
  first tried to be loaded directly, and if not found and the file names
  don't contain directory parts, are searched via kpsewhich.

  In any case, if multiple fmtutil.cnf files are found, all the format
  definitions found in all the fmtutil.cnf files are merged.

  Thus, if fmtutil.cnf files are present in all trees, and the default
  layout is used as shipped with TeX Live, the following files are
  read, in the given order.
  
  For fmtutil-sys:
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/fmtutil.cnf
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/fmtutil.cnf

  For fmtutil-user:
  TEXMFCONFIG    \$HOME/.texliveYYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFVAR       \$HOME/.texliveYYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFHOME      \$HOME/texmf/web2c/fmtutil.cnf
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/fmtutil.cnf
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/fmtutil.cnf
  
  (where YYYY is the TeX Live release version).
  
  According to the actions, fmtutil might update one of the existing cnf
  files or create a new fmtutil.cnf, as described below.

Where format files are written:

  By default, format files are (re)written in \$TEXMFSYSVAR/ENGINE by
  fmtutil-sys, and \$TEXMFVAR/ENGINE by fmtutil-user, where /ENGINE is
  a subdirectory named for the engine used, such as "pdftex".

  For mktexfmt, TEXMFSYSVAR is used if it is writable, else TEXMFVAR.
  
  If the --fmtdir=DIR option is specified, DIR is used instead of
  TEXMF[SYS]VAR, but the /ENGINE subdir is still used by default.
  
  In all cases, if the --no-engine-subdir option is specified, the
  /ENGINE subdir is omitted.
  
Where configuration changes are saved: 

  If config files are given on the command line, then the first one 
  given will be used to save any changes from --enable or --disable.  
  
  If the config files are taken from kpsewhich output, then the 
  algorithm is more complicated:

    1) If \$TEXMFCONFIG/web2c/fmtutil.cnf or
    \$TEXMFHOME/web2c/fmtutil.cnf appears in the list of used files,
    then the one listed first by kpsewhich --all (equivalently, the one
    returned by "kpsewhich fmtutil.cnf"), is used.
      
    2) If neither of the above two are present and changes are made, a
    new config file is created in \$TEXMFCONFIG/web2c/fmtutil.cnf.
  
  In general, the idea is that if a given config file is not writable, a
  higher-level one can be used.  That way, the distribution's settings
  can be overridden system-wide using TEXMFLOCAL, and system settings
  can be overridden again in a particular user's TEXMFHOME or TEXMFCONF.

Resolving multiple definitions of a format:

  If a format is defined in more than one config file, then the definition
  coming from the first-listed fmtutil.cnf is used.

Disabling formats:

  fmtutil.cnf files with higher priority (listed earlier) can disable
  formats in lower priority (listed later) fmtutil.cnf files by
  writing a line like this in the higher-priority fmtutil.cnf file:
    \#! <fmtname> <enginename> <hyphen> <args>
  The \#! must be at the beginning of the line, with at least one space
  or tab afterward, and there must be whitespace between each word on
  the list.

  For example, you can disable the luajitlatex format by creating
  the file \$TEXMFCONFIG/web2c/fmtutil.cnf with the line
    #! luajitlatex luajittex language.dat,language.dat.lua lualatex.ini
  (As it happens, the luajittex-related formats are precisely why the
  --no-error-if-no-engine option exists, since luajittex cannot be
  compiled on all platforms. So this is not needed.)

fmtutil-user (fmtutil -user) vs. fmtutil-sys (fmtutil -sys):

  When fmtutil-sys is run or the command line option -sys is used,
  TEXMFSYSCONFIG and TEXMFSYSVAR are used instead of TEXMFCONFIG and
  TEXMFVAR, respectively. This is the primary difference between
  fmtutil-sys and fmtutil-user.

  See https://tug.org/texlive/scripts-sys-user.html for details.

  Other locations may be used if you give them on the command line, or
  these trees don't exist, or you are not using the original TeX Live.

Supporting development binaries:

  If an engine name ends with "-dev", formats are created in
  the respective directory with the -dev stripped.  This allows for
  easily running development binaries in parallel with the released
  binaries.

Report bugs to: tex-live\@tug.org
TeX Live home page: <https://tug.org/texlive/>
EOF
;
  print &version();
  print $usage;
  exit 0; # no final print_info
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #

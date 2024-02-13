BEGIN {
my %modules = (
"TeXLive/TLConfig.pm" => << '__EOI__',
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
1;
__EOI__
"TeXLive/TLUtils.pm" => << '__EOI__',
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
1;
__EOI__
);
unshift @INC, sub {
my $module = $modules{$_[1]}
or return;
return \$module
};
}
#!/usr/bin/env perl
# $Id: updmap.pl 59152 2021-05-09 21:49:52Z karl $
# updmap - maintain map files for outline fonts.
# (Maintained in TeX Live:Master/texmf-dist/scripts/texlive.)
# 
# Copyright 2011-2021 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# History:
# Original shell script (C) 2002 Thomas Esser
# first perl variant by Fabrice Popineau
# later adaptions by Reinhard Kotucha and Karl Berry
# the original versions were licensed under the following agreement:
# Anyone may freely use, modify, and/or distribute this file, without

my $svnid = '$Id: updmap.pl 59152 2021-05-09 21:49:52Z karl $';

my $TEXMFROOT;
BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
  unshift(@INC, "$TEXMFROOT/tlpkg");
}

my $lastchdate = '$Date: 2021-05-09 23:49:52 +0200 (Sun, 09 May 2021) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 59152 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use strict;
use TeXLive::TLUtils qw(mkdirhier mktexupd win32 basename dirname 
  sort_uniq member touch);

(my $prg = basename($0)) =~ s/\.pl$//;

# sudo sometimes does not reset the home dir of root;
# see more comments at the definition of this function.
reset_root_home();

chomp(my $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(my $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(my $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(my $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

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

my $texmfconfig = $TEXMFCONFIG;
my $texmfvar    = $TEXMFVAR;

my %opts = ( quiet => 0, nohash => 0, nomkmap => 0 );
my $alldata;
my $updLSR;

my @cmdline_options = (
  "sys",
  "user",
  "listfiles",
  "cnffile=s@", 
  "copy", 
  "disable=s@",
  "dvipdfmoutputdir=s",
  "dvipdfmxoutputdir=s",
  "dvipsoutputdir=s",
  # the following does not work, Getopt::Long looses the first
  # entry in a multi setting, treat it separately in processOptions
  # furthermore, it is not supported by older perls, so do it differently
  #"enable=s{1,2}",
  "edit",
  "force",
  "listavailablemaps",
  "listmaps|l",
  "nohash",
  "nomkmap",
  "dry-run|n",
  "outputdir=s",
  "pdftexoutputdir=s",
  "pxdvioutputdir=s",
  "quiet|silent|q",
  # the following is a correct specification of an option according
  # to the manual, but it does not work!
  # we will treat that option by itself in processOptions
  # furthermore, it is not supported by older perls, so do it differently
  #"setoption=s@{1,2}",
  "showoptions=s@",
  "showoption=s@",
  "syncwithtrees",
  "version",
  "help|h",
  # some debugging invocations
  "_readsave=s",
  "_dump",
  );

my %settings = (
  dvipsPreferOutline    => {
    type     => "binary",
    default  => "true",
  },
  LW35                  => {
    type     => "string",
    possible => [ qw/URW URWkb ADOBE ADOBEkb/ ],
    default  => "URWkb",
  },
  dvipsDownloadBase35   => {
    type     => "binary",
    default  => "true",
  },
  pdftexDownloadBase14  => {
    type     => "binary",
    default  => "true",
  },
  dvipdfmDownloadBase14 => {
    type     => "binary",
    default  => "true",
  },
  pxdviUse              => {
    type     => "binary",
    default  => "false",
  },
  jaEmbed               => {
    type     => "any",
    default  => "noEmbed",
  },
  jaVariant             => {
    type     => "any",
    default  => "",
  },
  scEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
  tcEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
  koEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
);

&main();

##################################################################
#
sub main {
  processOptions();

  help() if $opts{'help'};

  if ($opts{'version'}) {
    print version();
    exit (0);
  }

  ($texmfconfig, $texmfvar) = 
    TeXLive::TLUtils::setup_sys_user_mode($prg, \%opts,
      $TEXMFCONFIG, $TEXMFSYSCONFIG, $TEXMFVAR, $TEXMFSYSVAR);

  if ($opts{'dvipdfmoutputdir'} && !defined($opts{'dvipdfmxoutputdir'})) {
    $opts{'dvipdfmxoutputdir'} = $opts{'dvipdfmoutputdir'};
    print_warning("Using --dvipdfmoutputdir options for dvipdfmx,"
                  . " but please use --dvipdfmxoutputdir\n");
  }

  if ($opts{'dvipdfmoutputdir'} && $opts{'dvipdfmxoutputdir'}
      && $opts{'dvipdfmoutputdir'} ne $opts{'dvipdfmxoutputdir'}) {
    print_error("Options for --dvipdfmoutputdir and --dvipdfmxoutputdir"
                . " do not match\n"
                . "Please use only --dvipdfmxoutputdir; exiting.\n");
    exit(1);
  }

  if ($opts{'_readsave'}) {
    read_updmap_files($opts{'_readsave'});
    merge_settings_replace_kanji();
    print "READING DONE ============================\n";
    $alldata->{'updmap'}{$opts{'_readsave'}}{'changed'} = 1;
    save_updmap($opts{'_readsave'});
    exit 0;
  }
 
  if ($opts{'showoptions'}) {
    for my $o (@{$opts{'showoptions'}}) {
      if (defined($settings{$o})) {
        if ($settings{$o}{'type'} eq "binary") {
          print "true false\n";
        } elsif ($settings{$o}{'type'} eq "string") {
          print "@{$settings{$o}{'possible'}}\n";
        } elsif ($settings{$o}{'type'} eq "any") {
          print "(any string)\n";
        } else {
          print_warning("strange: unknown type of option $o\nplease report\n");
        }
      } else {
        print_warning("unknown option: $o\n");
      }
    }
    exit 0;
  }

  # config file for changes
  my $changes_config_file;

  # determine which config files should be used
  # replaces the former "setupCfgFile"
  #
  # we also determine here where changes will be saved to
  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
        die "$prg: Config file \"$f\" not found.";
      }
      push @tmp, (win32() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    # in case that config files are given on the command line, the first
    # in the list is the one where changes will be written to.
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all updmap.cfg`;
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
    # search for TEXMFLOCAL/web2c/updmap.cfg
    my @tmlused;
    for my $tml (@TEXMFLOCAL) {
      my $TMLabs = Cwd::abs_path($tml);
      next if (!$TMLabs);
      if (-r "$TMLabs/web2c/updmap.cfg") {
        push @tmlused, "$TMLabs/web2c/updmap.cfg";
      }
      #
      # at least check for old updmap-local.cfg and warn!
      if (-r "$TMLabs/web2c/updmap-local.cfg") {
        print_warning("=============================\n");
        print_warning("Old configuration file\n  $TMLabs/web2c/updmap-local.cfg\n");
        print_warning("found! This file is *not* evaluated anymore, please move the information\n");
        print_warning("to the file $TMLabs/updmap.cfg!\n");
        print_warning("=============================\n");
      }
    }
    #
    # updmap (user):
    # ==============
    # TEXMFCONFIG    $HOME/.texliveYYYY/texmf-config/web2c/updmap.cfg
    # TEXMFVAR       $HOME/.texliveYYYY/texmf-var/web2c/updmap.cfg
    # TEXMFHOME      $HOME/texmf/web2c/updmap.cfg
    # TEXMFSYSCONFIG $TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
    # TEXMFSYSVAR    $TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
    # TEXMFLOCAL     $TEXLIVE/texmf-local/web2c/updmap.cfg
    # TEXMFDIST      $TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
    # 
    # updmap-sys (root):
    # ==================
    # TEXMFSYSCONFIG $TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
    # TEXMFSYSVAR    $TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
    # TEXMFLOCAL     $TEXLIVE/texmf-local/web2c/updmap.cfg
    # TEXMFDIST      $TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
    #
    @{$opts{'cnffile'}} = @used_files;
    #
    # Determine the config file that we will use for changes:
    # if the list of used files contains one from either
    # TEXMFHOME or TEXMFCONFIG (which is TEXMFSYSCONFIG in the -sys case)
    # then use the *top* file (which will be one of the two *CONFIG);
    # if neither of those two exists, create a file in TEXMFCONFIG and use it.
    my $use_top = 0;
    for my $f (@used_files) {
      if ($f =~ m!(\Q$TEXMFHOME\E|\Q$texmfconfig\E)/web2c/updmap.cfg!) {
        $use_top = 1;
        last;
      }
    }
    if ($use_top) {
      ($changes_config_file) = @used_files;
    } else {
      # add the empty config file
      my $dn = "$texmfconfig/web2c";
      $changes_config_file = "$dn/updmap.cfg";
    }
  }
  if (!$opts{'quiet'}) {
    print "$prg will read the following updmap.cfg files (in precedence order):\n";
    for my $f (@{$opts{'cnffile'}}) {
      print "  $f\n";
    }
    print "$prg may write changes to the following updmap.cfg file:\n";
    print "  $changes_config_file\n";
  }
  if ($opts{'listfiles'}) {
    # we listed it above, so be done
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;

  read_updmap_files(@{$opts{'cnffile'}});

  if ($opts{'_dump'}) {
    merge_settings_replace_kanji();
    read_map_files();
    require Data::Dumper;
    # two times to silence perl warnings!
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Indent = 1;
    print "READING DONE ============================\n";
    print Data::Dumper::Dumper($alldata);
    exit 0;
  }

  if ($opts{'showoption'}) {
    merge_settings_replace_kanji();
    for my $o (@{$opts{'showoption'}}) {
      if (defined($settings{$o})) {
        my ($v, $vo) = get_cfg($o);
        $v = "\"$v\"" if ($v =~ m/\s/);
        print "$o=$v ($vo)\n";
      } else {
        print_warning("unknown option: $o\n");
      }
    }
    exit 0;
  }

  if ($opts{'listmaps'} || $opts{'listavailablemaps'}) {
    merge_settings_replace_kanji();
    # only check for missing map files 
    # (pass in true argument to read_map_files)
    my %missing = map { $_ => 1 } read_map_files(1);
    for my $m (sort keys %{$alldata->{'maps'}}) {
      next if ($missing{$m} && $opts{'listavailablemaps'});
      my $origin = $alldata->{'maps'}{$m}{'origin'};
      my $type = ($origin eq 'builtin' ? 'Map' :
        $alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'});
      my $status = ($origin eq 'builtin' ? 'enabled' :
        $alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'});
      my $avail = ($missing{$m} ? "\t(not available)" : '');
      print "$type\t$m\t$status\t$origin$avail\n";
      #print $alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'}, " $m ",
      #$alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'}, " in $origin\n";
    }
    exit 0;
  }

  # we do changes always in the used config file with the highest
  # priority
  my $bakFile = $changes_config_file;
  $bakFile =~ s/\.cfg$/.bak/;
  my $changed = 0;

  $updLSR = &mktexupd();
  $updLSR->{mustexist}(0);

  if ($opts{'syncwithtrees'}) {
    merge_settings_replace_kanji();
    my @missing = read_map_files();
    if (@missing) {
      print "Missing map files found, disabling\n";
      for my $m (@missing) {
        my $orig = $alldata->{'maps'}{$m}{'origin'};
        print "\t$m (in $orig)\n";
      }
      print "in $changes_config_file\n";
      print "Do you really want to continue (y/N)? ";
      my $answer = <STDIN>;
      $answer = "n" if !defined($answer);
      chomp($answer);
      print "answer =$answer=\n";
      if ($answer ne "y" && $answer ne "Y") {
        print "Please fix manually before running updmap(-sys) again!\n";
        exit 0;
      }
      $changed ||= enable_disable_maps(@missing);
      print "$0 --syncwithtrees finished.\n";
      print "Now you need to run $prg normally to recreate map files.\n"
    }
    exit 0;
  }

  my $cmd;
  if ($opts{'edit'}) {
    if ($opts{"dry-run"}) {
      print_error("No, are you joking, you want to edit with --dry-run?\n");
      exit 1;
    }
    # it's not a good idea to edit updmap.cfg manually these days,
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
    system($editor, $changes_config_file);
    $changed = files_are_different($bakFile, $changes_config_file);
  } elsif ($opts{'setoption'}) {
    $cmd = 'setOption';
    $changed = setOptions (@{$opts{'setoption'}});
  } elsif ($opts{'enable'} || $opts{'disable'}) {
    $cmd = 'enableMap';
    $changed ||= enable_disable_maps(@{$opts{'enable'}}, @{$opts{'disable'}});
  }


  if ($cmd && !$opts{'force'} && !$changed) {
    print "$changes_config_file unchanged.  Map files not recreated.\n" 
      if !$opts{'quiet'};
  } else {
    if (!$opts{'nomkmap'}) {
      # before we continue we have to make sure that a newly created config
      # file is acually used. So we have to push the $changes_config_file
      # onto the list of available files. Since it is already properly
      # initialized and the merging is done later,  all settings should be
      # honored
      my @aaa = @{$alldata->{'order'}};
      unshift @aaa, $changes_config_file;
      $alldata->{'order'} = [ @aaa ];
      #
      setupOutputDir("dvips");
      setupOutputDir("pdftex");
      setupOutputDir("dvipdfmx");
      # do pxdvi below, in mkmaps.
      merge_settings_replace_kanji();
      my @missing = read_map_files();
      if (@missing) {
        print_error("The following map file(s) couldn't be found:\n"); 
        for my $m (@missing) {
          my $orig = $alldata->{'maps'}{$m}{'origin'};
          print_error("\t$m (in $orig)\n");
        }
        print_error("Did you run mktexlsr?\n\n" .
          "\tYou can disable non-existent map entries using the option\n".
          "\t  --syncwithtrees.\n\n");
        exit 1;
      }
      merge_data();
      # for inspecting the output
      #print STDERR Data::Dumper->Dump([$alldata], [qw(mapdata)]);
      #print Dumper($alldata);
      mkMaps();
    }
    unlink ($bakFile) if (-r $bakFile);
  }

  if (!$opts{'nohash'}) {
    print "$prg: Updating ls-R files.\n" if !$opts{'quiet'};
    $updLSR->{exec}() unless $opts{"dry-run"};
  }

  return 0;
}

##################################################################
#
sub getFonts {
  my ($first, @rest) = @_;
  my $getall = 0;
  my @maps = ();
  return if !defined($first);
  if ($first eq "-all") {
    $getall = 1;
    @maps = @rest;
  } else {
    @maps = ($first, @rest);
  }
  my @lines = ();
  for my $m (@maps) {
    if (defined($alldata->{'maps'}{$m})) {
      print LOG "\n" . $alldata->{'maps'}{$m}{'fullpath'} . ":\n" unless $opts{'dry-run'};
      push @lines, "% $m";
      for my $k (sort keys %{$alldata->{'maps'}{$m}{'fonts'}}) {
        if ($getall || $alldata->{'fonts'}{$k}{'origin'} eq $m) {
          if (defined($alldata->{'maps'}{$m}{'fonts'}{$k})) {
            push @lines, "$k " . $alldata->{'maps'}{$m}{'fonts'}{$k};
          } else {
            print_warning("undefined fonts for $k in $m   ?!?!?\n");
          }
          print LOG "$k\n" unless $opts{'dry-run'};
        }
      }
    }
  }
  chomp @lines;
  return @lines;
}

###############################################################################
# writeLines()
#   write the lines in $filename
#
sub writeLines {
  my ($fname, @lines) = @_;
  return if $opts{"dry-run"};
  map { ($_ !~ m/\n$/ ? s/$/\n/ : $_ ) } @lines;
  open FILE, ">$fname" or die "$prg: can't write lines to $fname: $!";
  print FILE @lines;
  close FILE;
}

###############################################################################
# to_pdftex()
#   if $pdftexStripEnc is set, strip "PS_Encoding_Name ReEncodeFont"
#   from map entries; they are ignored by pdftex.  But since the sh
#   incarnation of updmap included them, and we want to minimize
#   differences, this is not done by default.
#
sub to_pdftex {
  my $pdftexStripEnc = 0;
  return @_ unless $pdftexStripEnc;
  my @in = @_;
  my @out;
  foreach my $line (@in) {
    if ($line =~ /^(.*\s+)(\S+\s+ReEncodeFont\s)(.*)/) {
      $line = "$1$3";
      $line =~ s/\s+\"\s+\"\s+/ /;
    }
    push @out, $line;
  }
  return @out;
}

###############################################################################
# setupSymlinks()
#   set symlink for psfonts.map according to dvipsPreferOutline variable
#
sub setupSymlinks {
  my ($dvipsPreferOutline, $dvipsoutputdir, $pdftexDownloadBase14, $pdftexoutputdir) = @_;
  my $src;
  my %link;
  my @link;

  if ($dvipsPreferOutline eq "true") {
    $src = "psfonts_t1.map";
  } else {
    $src = "psfonts_pk.map";
  }
  unlink "$dvipsoutputdir/psfonts.map" unless $opts{"dry-run"};
  push @link, &SymlinkOrCopy("$dvipsoutputdir", "$src", "psfonts.map");

  if ($pdftexDownloadBase14 eq "true") {
    $src = "pdftex_dl14.map";
  } else {
    $src = "pdftex_ndl14.map";
  }
  unlink "$pdftexoutputdir/pdftex.map" unless $opts{"dry-run"};
  push @link, &SymlinkOrCopy("$pdftexoutputdir", "$src", "pdftex.map");
  %link = @link;
  return \%link;
}

###############################################################################
# SymlinkOrCopy(dir, src, dest)
#   create symlinks if possible, otherwise copy files
#
sub SymlinkOrCopy {
  my ($dir, $src, $dest) = @_;
  return ($src, $dest) if $opts{"dry-run"};
  if (&win32 || $opts{'copy'}) {  # always copy
    &copyFile("$dir/$src", "$dir/$dest");
  } else { # symlink if supported by fs, copy otherwise
    system("cd \"$dir\" && ln -s $src $dest 2>/dev/null || "
           . "cp -p \"$dir/$src\" \"$dir/$dest\"");
  }
  # remember for "Files generated" in &mkMaps.
  return ($dest, $src);
}


###############################################################################
# transLW35(mode args ...)
#   transform fontname and filenames according to transformation specified
#   by mode.  Possible values:
#      URW|URWkb|ADOBE|ADOBEkb
#
sub transLW35 {
  my ($mode, @lines) = @_;

  my @psADOBE = (
       's/ URWGothicL-Demi / AvantGarde-Demi /',
       's/ URWGothicL-DemiObli / AvantGarde-DemiOblique /',
       's/ URWGothicL-Book / AvantGarde-Book /',
       's/ URWGothicL-BookObli / AvantGarde-BookOblique /',
       's/ URWBookmanL-DemiBold / Bookman-Demi /',
       's/ URWBookmanL-DemiBoldItal / Bookman-DemiItalic /',
       's/ URWBookmanL-Ligh / Bookman-Light /',
       's/ URWBookmanL-LighItal / Bookman-LightItalic /',
       's/ NimbusMonL-Bold / Courier-Bold /',
       's/ NimbusMonL-BoldObli / Courier-BoldOblique /',
       's/ NimbusMonL-Regu / Courier /',
       's/ NimbusMonL-ReguObli / Courier-Oblique /',
       's/ NimbusSanL-Bold / Helvetica-Bold /',
       's/ NimbusSanL-BoldCond / Helvetica-Narrow-Bold /',
       's/ NimbusSanL-BoldItal / Helvetica-BoldOblique /',
       's/ NimbusSanL-BoldCondItal / Helvetica-Narrow-BoldOblique /',
       's/ NimbusSanL-Regu / Helvetica /',
       's/ NimbusSanL-ReguCond / Helvetica-Narrow /',
       's/ NimbusSanL-ReguItal / Helvetica-Oblique /',
       's/ NimbusSanL-ReguCondItal / Helvetica-Narrow-Oblique /',
       's/ CenturySchL-Bold / NewCenturySchlbk-Bold /',
       's/ CenturySchL-BoldItal / NewCenturySchlbk-BoldItalic /',
       's/ CenturySchL-Roma / NewCenturySchlbk-Roman /',
       's/ CenturySchL-Ital / NewCenturySchlbk-Italic /',
       's/ URWPalladioL-Bold / Palatino-Bold /',
       's/ URWPalladioL-BoldItal / Palatino-BoldItalic /',
       's/ URWPalladioL-Roma / Palatino-Roman /',
       's/ URWPalladioL-Ital / Palatino-Italic /',
       's/ StandardSymL / Symbol /',
       's/ NimbusRomNo9L-Medi / Times-Bold /',
       's/ NimbusRomNo9L-MediItal / Times-BoldItalic /',
       's/ NimbusRomNo9L-Regu / Times-Roman /',
       's/ NimbusRomNo9L-ReguItal / Times-Italic /',
       's/ URWChanceryL-MediItal / ZapfChancery-MediumItalic /',
       's/ Dingbats / ZapfDingbats /',
    );

  my @fileADOBEkb = (
        's/\buagd8a.pfb\b/pagd8a.pfb/',
        's/\buagdo8a.pfb\b/pagdo8a.pfb/',
        's/\buagk8a.pfb\b/pagk8a.pfb/',
        's/\buagko8a.pfb\b/pagko8a.pfb/',
        's/\bubkd8a.pfb\b/pbkd8a.pfb/',
        's/\bubkdi8a.pfb\b/pbkdi8a.pfb/',
        's/\bubkl8a.pfb\b/pbkl8a.pfb/',
        's/\bubkli8a.pfb\b/pbkli8a.pfb/',
        's/\bucrb8a.pfb\b/pcrb8a.pfb/',
        's/\bucrbo8a.pfb\b/pcrbo8a.pfb/',
        's/\bucrr8a.pfb\b/pcrr8a.pfb/',
        's/\bucrro8a.pfb\b/pcrro8a.pfb/',
        's/\buhvb8a.pfb\b/phvb8a.pfb/',
        's/\buhvb8ac.pfb\b/phvb8an.pfb/',
        's/\buhvbo8a.pfb\b/phvbo8a.pfb/',
        's/\buhvbo8ac.pfb\b/phvbo8an.pfb/',
        's/\buhvr8a.pfb\b/phvr8a.pfb/',
        's/\buhvr8ac.pfb\b/phvr8an.pfb/',
        's/\buhvro8a.pfb\b/phvro8a.pfb/',
        's/\buhvro8ac.pfb\b/phvro8an.pfb/',
        's/\buncb8a.pfb\b/pncb8a.pfb/',
        's/\buncbi8a.pfb\b/pncbi8a.pfb/',
        's/\buncr8a.pfb\b/pncr8a.pfb/',
        's/\buncri8a.pfb\b/pncri8a.pfb/',
        's/\buplb8a.pfb\b/pplb8a.pfb/',
        's/\buplbi8a.pfb\b/pplbi8a.pfb/',
        's/\buplr8a.pfb\b/pplr8a.pfb/',
        's/\buplri8a.pfb\b/pplri8a.pfb/',
        's/\busyr.pfb\b/psyr.pfb/',
        's/\butmb8a.pfb\b/ptmb8a.pfb/',
        's/\butmbi8a.pfb\b/ptmbi8a.pfb/',
        's/\butmr8a.pfb\b/ptmr8a.pfb/',
        's/\butmri8a.pfb\b/ptmri8a.pfb/',
        's/\buzcmi8a.pfb\b/pzcmi8a.pfb/',
        's/\buzdr.pfb\b/pzdr.pfb/',
      );

  my @fileURW = (
        's/\buagd8a.pfb\b/a010015l.pfb/',
  's/\buagdo8a.pfb\b/a010035l.pfb/',
  's/\buagk8a.pfb\b/a010013l.pfb/',
  's/\buagko8a.pfb\b/a010033l.pfb/',
  's/\bubkd8a.pfb\b/b018015l.pfb/',
  's/\bubkdi8a.pfb\b/b018035l.pfb/',
  's/\bubkl8a.pfb\b/b018012l.pfb/',
  's/\bubkli8a.pfb\b/b018032l.pfb/',
  's/\bucrb8a.pfb\b/n022004l.pfb/',
  's/\bucrbo8a.pfb\b/n022024l.pfb/',
  's/\bucrr8a.pfb\b/n022003l.pfb/',
  's/\bucrro8a.pfb\b/n022023l.pfb/',
  's/\buhvb8a.pfb\b/n019004l.pfb/',
  's/\buhvb8ac.pfb\b/n019044l.pfb/',
  's/\buhvbo8a.pfb\b/n019024l.pfb/',
  's/\buhvbo8ac.pfb\b/n019064l.pfb/',
  's/\buhvr8a.pfb\b/n019003l.pfb/',
  's/\buhvr8ac.pfb\b/n019043l.pfb/',
  's/\buhvro8a.pfb\b/n019023l.pfb/',
  's/\buhvro8ac.pfb\b/n019063l.pfb/',
  's/\buncb8a.pfb\b/c059016l.pfb/',
  's/\buncbi8a.pfb\b/c059036l.pfb/',
  's/\buncr8a.pfb\b/c059013l.pfb/',
  's/\buncri8a.pfb\b/c059033l.pfb/',
  's/\buplb8a.pfb\b/p052004l.pfb/',
  's/\buplbi8a.pfb\b/p052024l.pfb/',
  's/\buplr8a.pfb\b/p052003l.pfb/',
  's/\buplri8a.pfb\b/p052023l.pfb/',
  's/\busyr.pfb\b/s050000l.pfb/',
  's/\butmb8a.pfb\b/n021004l.pfb/',
  's/\butmbi8a.pfb\b/n021024l.pfb/',
  's/\butmr8a.pfb\b/n021003l.pfb/',
  's/\butmri8a.pfb\b/n021023l.pfb/',
  's/\buzcmi8a.pfb\b/z003034l.pfb/',
  's/\buzdr.pfb\b/d050000l.pfb/',
       );

  my @fileADOBE = (
  's/\buagd8a.pfb\b/agd_____.pfb/',
  's/\buagdo8a.pfb\b/agdo____.pfb/',
  's/\buagk8a.pfb\b/agw_____.pfb/',
  's/\buagko8a.pfb\b/agwo____.pfb/',
  's/\bubkd8a.pfb\b/bkd_____.pfb/',
  's/\bubkdi8a.pfb\b/bkdi____.pfb/',
  's/\bubkl8a.pfb\b/bkl_____.pfb/',
  's/\bubkli8a.pfb\b/bkli____.pfb/',
  's/\bucrb8a.pfb\b/cob_____.pfb/',
  's/\bucrbo8a.pfb\b/cobo____.pfb/',
  's/\bucrr8a.pfb\b/com_____.pfb/',
  's/\bucrro8a.pfb\b/coo_____.pfb/',
  's/\buhvb8a.pfb\b/hvb_____.pfb/',
  's/\buhvb8ac.pfb\b/hvnb____.pfb/',
  's/\buhvbo8a.pfb\b/hvbo____.pfb/',
  's/\buhvbo8ac.pfb\b/hvnbo___.pfb/',
  's/\buhvr8a.pfb\b/hv______.pfb/',
  's/\buhvr8ac.pfb\b/hvn_____.pfb/',
  's/\buhvro8a.pfb\b/hvo_____.pfb/',
  's/\buhvro8ac.pfb\b/hvno____.pfb/',
  's/\buncb8a.pfb\b/ncb_____.pfb/',
  's/\buncbi8a.pfb\b/ncbi____.pfb/',
  's/\buncr8a.pfb\b/ncr_____.pfb/',
  's/\buncri8a.pfb\b/nci_____.pfb/',
  's/\buplb8a.pfb\b/pob_____.pfb/',
  's/\buplbi8a.pfb\b/pobi____.pfb/',
  's/\buplr8a.pfb\b/por_____.pfb/',
  's/\buplri8a.pfb\b/poi_____.pfb/',
  's/\busyr.pfb\b/sy______.pfb/',
  's/\butmb8a.pfb\b/tib_____.pfb/',
  's/\butmbi8a.pfb\b/tibi____.pfb/',
  's/\butmr8a.pfb\b/tir_____.pfb/',
  's/\butmri8a.pfb\b/tii_____.pfb/',
  's/\buzcmi8a.pfb\b/zcmi____.pfb/',
  's/\buzdr.pfb\b/zd______.pfb/',
    );

  if ($mode eq "" || $mode eq "URWkb") {
    # do nothing
  } elsif ($mode eq "URW") {
    for my $r (@fileURW) {
      map { eval($r); } @lines;
    }
  } elsif ($mode eq "ADOBE" || $mode eq "ADOBEkb") {
    for my $r (@psADOBE) {
      map { eval($r); } @lines;
    }
    my @filemode = eval ("\@file" . $mode);
    for my $r (@filemode) {
      map { eval($r); } @lines;
    }
  }
  return @lines;
}

###############################################################################
# cidx2dvips()
#   reads from stdin, writes to stdout. It transforms "cid-x"-like syntax into
#   "dvips"-like syntax.
#
# Specifying the PS Name:
# dvips needs the PSname instead of the file name. Thus we allow specifying
# the PSname in the comment:
#       The PS Name can be specified in the font definition line
#       by including the following sequence somewhere after the
#       other components:
#
#       %!PS<SPACE-TAB><PSNAME><NON-WORD-CHAR-OR-EOL>
#
#       where
#         <SPACE-TAB> is either a space or a tab character
#         <PSNAME>    is *one* word, defined by \w\w* perl re
#         <NON-WORD-CHAR-OR-EOL> is a non-\w char or the end of line
#
# That means we could have
#       ... %here the PS font name: %!PS fontname some other comment
#       ... %!PS fontname %other comments
#       ... %!PS fontname
#
# reimplementation of the cryptic code that was there before
sub cidx2dvips {
  my ($s) = @_;
  my %fname_psname = (
    # Morisawa
    'A-OTF-FutoGoB101Pr6N-Bold'  => 'FutoGoB101Pr6N-Bold',
    'A-OTF-FutoGoB101Pro-Bold'   => 'FutoGoB101Pro-Bold',
    'A-OTF-FutoMinA101Pr6N-Bold' => 'FutoMinA101Pr6N-Bold',
    'A-OTF-FutoMinA101Pro-Bold'  => 'FutoMinA101Pro-Bold',
    'A-OTF-GothicBBBPr6N-Medium' => 'GothicBBBPr6N-Medium',
    'A-OTF-GothicBBBPro-Medium'  => 'GothicBBBPro-Medium',
    'A-OTF-Jun101Pr6N-Light'     => 'Jun101Pr6N-Light',
    'A-OTF-Jun101Pro-Light'      => 'Jun101Pro-Light',
    'A-OTF-MidashiGoPr6N-MB31'   => 'MidashiGoPr6N-MB31',
    'A-OTF-MidashiGoPro-MB31'    => 'MidashiGoPro-MB31',
    'A-OTF-RyuminPr6N-Light'     => 'RyuminPr6N-Light',
    'A-OTF-RyuminPro-Light'      => 'RyuminPro-Light',
    # Hiragino font file names and PS names are the same
    #
    # IPA
    'ipaexg' => 'IPAexGothic',
    'ipaexm' => 'IPAexMincho',
    'ipag'   => 'IPAGothic',
    'ipam'   => 'IPAMincho',
    #
    # Kozuka font names and PS names are the same
    );
  my @d;
  foreach (@$s) {
    # ship empty lines and comment lines out as is
    if (m/^\s*(%.*)?$/) {
      push(@d, $_);
      next;
    }
    # get rid of new lines for now
    chomp;
    # save the line for warnings
    my $l = $_;
    #
    my $psname;
    my $fbname;
    #
    # special case for pre-defined fallback from unicode encoded font
    if ($_ =~ m/%!DVIPSFB\s\s*([0-9A-Za-z-_!,][0-9A-Za-z-_!,]*)/) {
      $fbname = $1;
      # minimal adjustment
      $fbname =~ s/^!//;
      $fbname =~ s/,Bold//;
    }
    # first check whether a PSname is given
    # the matching on \w* is greedy, so will take all the word chars available
    # that means we do not need to test for end of word
    if ($_ =~ m/%!PS\s\s*([0-9A-Za-z-_][0-9A-Za-z-_]*)/) {
      $psname = $1;
    }
    # remove comments
    s/[^0-9A-Za-z-_]*%.*$//;
    # replace supported ",SOMETHING" constructs
    my $italicmax = 0;
    if (m/,BoldItalic/) {
      $italicmax = .3;
      s/,BoldItalic//;
    }
    s/,Bold//;
    if (m/,Italic/) {
      $italicmax = .3;
      s/,Italic//;
    }
    # replace supported "/AJ16" and co. for ptex-fontmaps CID emulation
    # note that the emulation method in GS is incomplete
    # due to "Reversal CMap method" (cf. "ToUnicode method")
    s!/A[JGCK]1[0-6]!!;
    # break out if unsupported constructs are found: @ / ,
    next if (m![\@/,]!);
    # make everything single spaced
    s/\s\s*/ /g;
    # unicode encoded fonts are not supported
    # but if a fallback font is pre-defined, we can use it
    next if (!defined($fbname) && (m!^[0-9A-Za-z-_][0-9A-Za-z-_]* unicode !));
    # now we have the following format
    #  <word> <word> <word> some options like -e or -s
    if ($_ !~ m/([^ ][^ ]*) ([^ ][^ ]*) ([^ ][^ ]*)( (.*))?$/) {
      print_warning("cidx2dvips warning: Cannot translate font line:\n==> $l\n");
      print_warning("Current translation status: ==>$_==\n");
      next;
    }
    my $tfmname = $1;
    my $cid = $2;
    my $fname = $3;
    my $opts = (defined($5) ? " $5" : "");
    # remove extensions from $fname
    $fname =~ s/\.[Oo][Tt][Ff]//;
    $fname =~ s/\.[Tt][Tt][FfCc]//;
    # remove leading ! from $fname
    $fname =~ s/^!//;
    # remove leading :<number>: from $fname
    $fname =~ s/:[0-9]+://;
    # remove leading space from $opt
    $opts =~ s/^\s+//;
    # replace -e and -s in the options
    $opts =~ s/-e ([.0-9-][.0-9-]*)/ "$1 ExtendFont"/;
    if (m/-s ([.0-9-][.0-9-]*)/) {
      if ($italicmax > 0) {
        # we have already a definition of SlantFont via ,Italic or ,BoldItalic
        # warn the user that larger one is kept
        print_warning("cidx2dvips warning: Double slant specified via Italic and -s:\n==> $l\n==> Using only the biggest slant value.\n");
      }
      $italicmax = $1 if ($1 > $italicmax);
      $opts =~ s/-s ([.0-9-][.0-9-]*)//;
    }
    if ($italicmax != 0) {
      $opts .= " \"$italicmax SlantFont\"";
    }
    # print out the result
    if (defined($fbname)) {
      push @d, "$tfmname $fbname\n";
    } else {
      if (defined($psname)) {
        push @d, "$tfmname $psname-$cid$opts\n";
      } else {
        if (defined($fname_psname{$fname})) {
          push @d, "$tfmname $fname_psname{$fname}-$cid$opts\n";
        } else {
          push @d, "$tfmname $fname-$cid$opts\n";
        }
      }
    }
  }
  return @d;
}

sub cidx2dvips_old {
    my ($s) = @_;
    my @d;
    foreach (@$s) {
      if (m/^%/) {
        push(@d, $_);
        next;
      }
      s/,BoldItalic/ -s .3/;
      s/,Bold//;
      s/,Italic/ -s .3/;
      s/\s\s*/ /g;
      if ($_ =~ /.*[@\:\/,]/) {next;}
      elsif ($_ =~ /^[^ ][^ ]* unicode /) {next;}
      s/^([^ ][^ ]* [^ ][^ ]* [^ ][^ ]*)\.[Oo][Tt][Ff]/$1/;
      s/^([^ ][^ ]* [^ ][^ ]* [^ ][^ ]*)\.[Tt][Tt][FfCc]/$1/; 
      s/$/ %/;
      s/^(([^ ]*).*)/$1$2/;
      s/^([^ ][^ ]* ([^ ][^ ]*) !*([^ ][^ ]*).*)/$1 $3-$2/;
      s/^(.* -e ([.0-9-][.0-9-]*).*)/$1 "$2 ExtendFont"/;
      s/^(.* -s ([.0-9-][.0-9-]*).*)/$1 "$2 SlantFont"/;
      s/.*%//;
      push(@d, $_);
    }
    return @d
}

sub get_cfg {
  my ($v) = @_;
  if (defined($alldata->{'merged'}{'setting'}{$v})) {
    return ( $alldata->{'merged'}{'setting'}{$v}{'val'},
             $alldata->{'merged'}{'setting'}{$v}{'origin'} );
  } else {
    return ($settings{$v}{'default'}, "default");
  }
}

sub mkMaps {
  my $logfile;

  $logfile = "$texmfvar/web2c/updmap.log";

  if (! $opts{'dry-run'}) {
    mkdirhier("$texmfvar/web2c");
    open LOG, ">$logfile"
        or die "$prg: Can't open log file \"$logfile\": $!";
    print LOG &version();
    printf LOG "%s\n\n", scalar localtime();
    print LOG  "Using the following config files:\n";
    for (@{$opts{'cnffile'}}) {
      print LOG "  $_\n";
    }
  }
  sub print_and_log {
    my $str=shift;
    print $str if !$opts{'quiet'};
    print LOG $str unless $opts{'dry-run'};
  }
  sub only_log {
    print LOG shift unless $opts{'dry-run'};
  }

  my ($mode, $mode_origin) = get_cfg('LW35');
  my ($dvipsPreferOutline, $dvipsPreferOutline_origin) = 
    get_cfg('dvipsPreferOutline');
  my ($dvipsDownloadBase35, $dvipsDownloadBase35_origin) = 
    get_cfg('dvipsDownloadBase35');
  my ($pdftexDownloadBase14, $pdftexDownloadBase14_origin) = 
    get_cfg('pdftexDownloadBase14');
  my ($pxdviUse, $pxdviUse_origin) = get_cfg('pxdviUse');
  my ($jaEmbed, $jaEmbed_origin) = get_cfg('jaEmbed');
  my ($jaVariant, $jaVariant_origin) = get_cfg('jaVariant');
  my ($scEmbed, $scEmbed_origin) = get_cfg('scEmbed');
  my ($tcEmbed, $tcEmbed_origin) = get_cfg('tcEmbed');
  my ($koEmbed, $koEmbed_origin) = get_cfg('koEmbed');

  # keep backward compatibility with old definitions
  # of kanjiEmbed, kanjiVariant
  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));


  # pxdvi is optional, and off by default.  Don't create the output
  # directory unless we are going to put something there.
  setupOutputDir("pxdvi") if $pxdviUse eq "true";

  print_and_log ("\n$prg is creating new map files"
         . "\nusing the following configuration:"
         . "\n  LW35 font names                  : "
         .      "$mode ($mode_origin)"
         . "\n  prefer outlines                  : "
         .      "$dvipsPreferOutline ($dvipsPreferOutline_origin)"
         . "\n  texhash enabled                  : "
         .      ($opts{'nohash'} ? "false" : "true")
         . "\n  download standard fonts (dvips)  : "
         .      "$dvipsDownloadBase35 ($dvipsDownloadBase35_origin)"
         . "\n  download standard fonts (pdftex) : "
         .      "$pdftexDownloadBase14 ($pdftexDownloadBase14_origin)"
         . "\n  jaEmbed replacement string       : "
         .      "$jaEmbed ($jaEmbed_origin)"
         . "\n  jaVariant replacement string     : "
         .      ($jaVariant ? $jaVariant : "<empty>") . " ($jaVariant_origin)"
         . "\n  scEmbed replacement string       : "
         .      "$scEmbed ($scEmbed_origin)"
         . "\n  tcEmbed replacement string       : "
         .      "$tcEmbed ($tcEmbed_origin)"
         . "\n  koEmbed replacement string       : "
         .      "$koEmbed ($koEmbed_origin)"
         . "\n  create a mapfile for pxdvi       : "
         .      "$pxdviUse ($pxdviUse_origin)"
         . "\n\n");

  print_and_log ("Scanning for LW35 support files");
  my $dvips35 = $alldata->{'maps'}{"dvips35.map"}{'fullpath'};
  my $pdftex35 = $alldata->{'maps'}{"pdftex35.map"}{'fullpath'};
  my $ps2pk35 = $alldata->{'maps'}{"ps2pk35.map"}{'fullpath'};
  my $LW35 = "\n$dvips35\n$pdftex35\n$ps2pk35\n\n";
  only_log ("\n");
  only_log ($LW35);
  print_and_log ("  [  3 files]\n");
  only_log ("\n");

  print_and_log ("Scanning for MixedMap entries");
  my @mixedmaps;
  my @notmixedmaps;
  my @kanjimaps;
  for my $m (keys %{$alldata->{'maps'}}) {
    my $origin = $alldata->{'maps'}{$m}{'origin'};
    next if !defined($origin);
    next if ($origin eq 'builtin');
    next if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'} eq "disabled");
    push @mixedmaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "MixedMap");
    push @notmixedmaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "Map");
    push @kanjimaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "KanjiMap");
  }

  @mixedmaps = sort @mixedmaps;
  @notmixedmaps = sort @notmixedmaps;
  @kanjimaps = sort @kanjimaps;
  only_log("\n");
  foreach my $m (sort @mixedmaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("    [%3d files]\n", scalar @mixedmaps));
  only_log("\n");

  print_and_log ("Scanning for KanjiMap entries");
  only_log("\n");
  foreach my $m (@kanjimaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("    [%3d files]\n", scalar @kanjimaps));
  only_log("\n");

  print_and_log ("Scanning for Map entries");
  only_log("\n");
  foreach my $m (@notmixedmaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("         [%3d files]\n\n", scalar @notmixedmaps));
  only_log("\n");

  my $first_time_creation_in_usermode = 0;
  # Create psfonts_t1.map, psfonts_pk.map, ps2pk.map and pdftex.map:
  my $dvipsoutputdir = $opts{'dvipsoutputdir'};
  my $pdftexoutputdir = $opts{'pdftexoutputdir'};
  my $dvipdfmxoutputdir = $opts{'dvipdfmxoutputdir'};
  my $pxdvioutputdir = $opts{'pxdvioutputdir'};
  if (!$opts{'dry-run'}) {
    my @managed_files =  ("$dvipsoutputdir/download35.map",
      "$dvipsoutputdir/builtin35.map",
      "$dvipsoutputdir/psfonts_t1.map",
      "$dvipsoutputdir/psfonts_pk.map",
      "$pdftexoutputdir/pdftex_dl14.map",
      "$pdftexoutputdir/pdftex_ndl14.map",
      "$dvipdfmxoutputdir/kanjix.map",
      "$dvipsoutputdir/ps2pk.map");
    push @managed_files, "$pxdvioutputdir/xdvi-ptex.map"
      if ($pxdviUse eq "true");
    for my $file (@managed_files) {
      if (!$opts{'sys'} && ! -r $file) {
        $first_time_creation_in_usermode = 1;
      }
      open FILE, ">$file";
      print FILE "% $file:\
% maintained by updmap[-sys] (multi).\
% Don't change this file directly. Use updmap[-sys] instead.\
% See the updmap documentation.\
% A log of the run that created this file is available here:\
% $logfile\
";
      close FILE;
    }
  }

  my @kanjimaps_fonts = getFonts(@kanjimaps);
  @kanjimaps_fonts = &normalizeLines(@kanjimaps_fonts);
  my @ps2pk_fonts = getFonts('-all', "ps2pk35.map");
  my @dvips35_fonts = getFonts('-all', "dvips35.map");
  my @pdftex35_fonts = getFonts('-all', "pdftex35.map");
  my @mixedmaps_fonts = getFonts(@mixedmaps);
  my @notmixedmaps_fonts = getFonts(@notmixedmaps);

  print "Generating output for dvipdfmx...\n" if !$opts{'quiet'};
  &writeLines(">$dvipdfmxoutputdir/kanjix.map", @kanjimaps_fonts);

  if ($pxdviUse eq "true") {
    # we use the very same data as for kanjix.map, but generate
    # a different file, in case a user wants to hand-craft it
    print "Generating output for pxdvi...\n" if !$opts{'quiet'};
     &writeLines(">$pxdvioutputdir/xdvi-ptex.map", @kanjimaps_fonts);
  }


  print "Generating output for ps2pk...\n" if !$opts{'quiet'};
  my @ps2pk_map;
  push @ps2pk_map, "% ps2pk35.map";
  push @ps2pk_map, transLW35($mode, @ps2pk_fonts);
  push @ps2pk_map, @mixedmaps_fonts;
  push @ps2pk_map, @notmixedmaps_fonts;
  &writeLines(">$dvipsoutputdir/ps2pk.map", 
    normalizeLines(@ps2pk_map));

  print "Generating output for dvips...\n" if !$opts{'quiet'};
  my @download35_map;
  push @download35_map, "% ps2pk35.map";
  push @download35_map, transLW35($mode, @ps2pk_fonts);
  &writeLines(">$dvipsoutputdir/download35.map", 
    normalizeLines(@download35_map));

  my @builtin35_map;
  push @builtin35_map, "% dvips35.map";
  push @builtin35_map, transLW35($mode, @dvips35_fonts);
  &writeLines(">$dvipsoutputdir/builtin35.map", 
    normalizeLines(@builtin35_map));

  my @dftdvips_fonts = 
    (($dvipsDownloadBase35 eq "true") ? @ps2pk_fonts : @dvips35_fonts);

  my @psfonts_t1_map;
  if ($dvipsDownloadBase35 eq "true") {
    push @psfonts_t1_map, "% ps2pk35.map";
    @dftdvips_fonts = @ps2pk_fonts;
  } else {
    push @psfonts_t1_map, "% dvips35.map";
    @dftdvips_fonts =  @dvips35_fonts;
  }
  push @psfonts_t1_map, transLW35($mode, @dftdvips_fonts);
  my @tmpkanji2 = cidx2dvips(\@kanjimaps_fonts);
  push @psfonts_t1_map, @mixedmaps_fonts;
  push @psfonts_t1_map, @notmixedmaps_fonts;
  push @psfonts_t1_map, @tmpkanji2;
  &writeLines(">$dvipsoutputdir/psfonts_t1.map", 
    normalizeLines(@psfonts_t1_map));

  my @psfonts_pk_map;
  push @psfonts_pk_map, transLW35($mode, @dftdvips_fonts);
  push @psfonts_pk_map, @notmixedmaps_fonts;
  push @psfonts_pk_map, @tmpkanji2;
  &writeLines(">$dvipsoutputdir/psfonts_pk.map", 
    normalizeLines(@psfonts_pk_map));

  print "Generating output for pdftex...\n" if !$opts{'quiet'};
  # remove PaintType due to Sebastian's request
  my @pdftexmaps_ndl;
  push @pdftexmaps_ndl, "% pdftex35.map";
  push @pdftexmaps_ndl, transLW35($mode, @pdftex35_fonts);
  push @pdftexmaps_ndl, @mixedmaps_fonts;
  push @pdftexmaps_ndl, @notmixedmaps_fonts;
  @pdftexmaps_ndl = grep { $_ !~ m/(^%\|PaintType)/ } @pdftexmaps_ndl;

  my @pdftexmaps_dl;
  push @pdftexmaps_dl, "% ps2pk35.map";
  push @pdftexmaps_dl, transLW35($mode, @ps2pk_fonts);
  push @pdftexmaps_dl, @mixedmaps_fonts;
  push @pdftexmaps_dl, @notmixedmaps_fonts;
  @pdftexmaps_dl = grep { $_ !~ m/(^%\|PaintType)/ } @pdftexmaps_dl;

  my @pdftex_ndl14_map = @pdftexmaps_ndl;
  @pdftex_ndl14_map = &normalizeLines(@pdftex_ndl14_map);
  @pdftex_ndl14_map = &to_pdftex(@pdftex_ndl14_map);
  &writeLines(">$pdftexoutputdir/pdftex_ndl14.map", @pdftex_ndl14_map);

  my @pdftex_dl14_map = @pdftexmaps_dl;
  @pdftex_dl14_map = &normalizeLines(@pdftex_dl14_map);
  @pdftex_dl14_map = &to_pdftex(@pdftex_dl14_map);
  &writeLines(">$pdftexoutputdir/pdftex_dl14.map", @pdftex_dl14_map);

  our $link = &setupSymlinks($dvipsPreferOutline, $dvipsoutputdir, $pdftexDownloadBase14, $pdftexoutputdir);

  print_and_log ("\nFiles generated:\n");
  sub dir {
    my ($d, $f, $target)=@_;
    our $link;
    if (-e "$d/$f") {
      my @stat=lstat("$d/$f");
      my ($s,$m,$h,$D,$M,$Y)=localtime($stat[9]);
      my $timestamp=sprintf ("%04d-%02d-%02d %02d:%02d:%02d",
                             $Y+1900, $M+1, $D, $h, $m, $s);
      my $date=sprintf "%12d %s %s", $stat[7], $timestamp, $f;
      print_and_log ($date);

      if (-l "$d/$f") {
        my $lnk=sprintf " -> %s\n", readlink ("$d/$f");
        print_and_log ($lnk);
      } elsif ($f eq $target) {
        if (&files_are_identical("$d/$f", "$d/" . $link->{$target})) {
          print_and_log (" = $link->{$target}\n");
        } else {
          print_and_log (" = ?????\n"); # This shouldn't happen.
        }
      } else {
        print_and_log ("\n");
      }
    } else {
      print_warning("File $d/$f doesn't exist.\n");
      print LOG     "Warning: File $d/$f doesn't exist.\n" 
        unless $opts{'dry-run'};
    }
  }

  sub check_mismatch {
    my ($mm, $d, $f, $prog) = @_;
    chomp (my $kpsefound = `kpsewhich --progname=$prog $f`);
    if (lc("$d/$f") ne lc($kpsefound)) {
      $mm->{$f} = $kpsefound;
    }
  }

  my %mismatch;
  my $d;
  $d = "$dvipsoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('builtin35.map', 'download35.map', 'psfonts_pk.map',
                 'psfonts_t1.map', 'ps2pk.map', 'psfonts.map') {
    dir ($d, $f, 'psfonts.map');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "dvips");
    }
  }
  $d = "$pdftexoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('pdftex_dl14.map', 'pdftex_ndl14.map', 'pdftex.map') {
    dir ($d, $f, 'pdftex.map');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "pdftex");
    }
  }
  $d="$dvipdfmxoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('kanjix.map') {
    dir ($d, $f, '');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "dvipdfmx");
    }
  }
  if ($pxdviUse eq "true") {
    $d="$pxdvioutputdir";
    print_and_log("  $d:\n");
    foreach my $f ('xdvi-ptex.map') {
      dir ($d, $f, '');
      $updLSR->{add}("$d/$f") unless $opts{'dry-run'};
      if (!$opts{'dry-run'}) {
        $updLSR->{add}("$d/$f");
        $updLSR->{exec}();
        $updLSR->{reset}();
        check_mismatch(\%mismatch, $d, $f, "xdvi");
      }
    }
  }

  # all kinds of warning messages
  if ($first_time_creation_in_usermode) {
    print_and_log("
*************************************************************
*                                                           *
* WARNING: you are switching to updmap's per-user mappings. *
*         Please read the following warnings!               *
*                                                           *
*************************************************************

You have run updmap-user (as opposed to updmap-sys) for the first time;
this has created configuration files which are local to your personal account.

From now on, any changes in system map files will *not* be automatically
reflected in your files; furthermore, running updmap-sys (as is done
automatically) will no longer have any effect for you.

As a consequence, you yourself have to rerun updmap-user yourself after
any change in the *system* directories! For example, if a new font
package is added or existing mappings change, which happens frequently.
See https://tug.org/texlive/scripts-sys-user.html for details.

If you want to undo this, remove the files mentioned above.

(Run $prg --help for full documentation of updmap.)
");
  }

  if (keys %mismatch) {
    print_and_log("
WARNING: $prg has found mismatched files!

The following files have been generated as listed above,
but will not be found because overriding files exist, listed below.
");
    #
    if ($opts{'sys'}) {
      print_and_log ("
Perhaps you have run updmap-user in the past, but are running updmap-sys
now.  Once you run updmap-user the first time, you have to keep using it,
or else remove the personal configuration files it creates (the ones
listed below).
");
    }
    #
    for my $f (sort keys %mismatch) {
      print_and_log (" $f: $mismatch{$f}\n");
    }
    #
    print_and_log("(Run $prg --help for full documentation of updmap.)\n");
  }

  close LOG unless $opts{'dry-run'};
  print "\nTranscript written on \"$logfile\".\n" if !$opts{'quiet'};

}


sub locateMap {
  my $map = shift;
  my $ret = `kpsewhich --format=map $map`;
  chomp($ret);
  return $ret;
}

sub processOptions {
  # first process the stupid setoption= s@{1,2} which is not accepted
  # furthermore, try to work around missing s{1,2} support in older perls
  my $oldconfig = Getopt::Long::Configure(qw(pass_through));
  our @setoptions;
  our @enable;
  sub read_one_or_two {
    my ($opt, $val) = @_;
    our @setoptions;
    our @enable;
    # check if = occirs in $val, if not, get the next argument
    if ($val =~ m/=/) {
      if ($opt eq "setoption") {
        push @setoptions, $val;
      } else {
        push @enable, $val;
      }
    } else {
      my $vv = shift @ARGV;
      die "Try \"$prg --help\" for more information.\n"
        if !defined($vv);
      if ($opt eq "setoption") {
        push @setoptions, "$val=$vv";
      } else {
        push @enable, "$val=$vv";
      }
    }
  }
  GetOptions("setoption=s@" => \&read_one_or_two,
             "enable=s@"    => \&read_one_or_two) or
    die "Try \"$prg --help\" for more information.\n";

  @{$opts{'setoption'}} = @setoptions if (@setoptions);
  @{$opts{'enable'}} = @enable if (@enable);

  Getopt::Long::Configure($oldconfig);

  # now continue with normal option handling

  GetOptions(\%opts, @cmdline_options) or 
    die "Try \"$prg --help\" for more information.\n";
}

# determines the output dir for driver from cmd line, or if not given
# from TEXMFVAR
sub setupOutputDir {
  my $driver = shift;
  if (!$opts{$driver . "outputdir"}) {
    if ($opts{'outputdir'}) {
      $opts{$driver . "outputdir"} = $opts{'outputdir'};
    } else {
      $opts{$driver . "outputdir"} = "$texmfvar/fonts/map/$driver/updmap";
    }
  }
  my $od = $opts{$driver . "outputdir"};
  if (!$opts{"dry-run"}) {
    &mkdirhier($od);
    if (! -w $od) {
      die "$prg: Directory \"$od\" isn't writable: $!";
    }
  }
  print "$driver output dir: \"$od\"\n" if !$opts{'quiet'};
  return $od;
}

###############################################################################
# setOption (@options)
#   parse @options for "key=value" (one element of @options)
#   we can only have "key=value" since that is the way it was prepared
#   in process_options
#   (These were the values provided to --setoption.)
#   
sub setOptions {
  my (@options) = @_;
  for (my $i = 0; $i < @options; $i++) {
    my $o = $options[$i];

    my ($key,$val) = split (/=/, $o, 2);
    
    die "$prg: unexpected empty key or val for options (@options), goodbye.\n"
      if !$key || !defined($val);

    &setOption ($key, $val);
  }
  return save_updmap($alldata->{'changes_config'});
}

sub enable_disable_maps {
  my (@what) = @_;
  my $tc = $alldata->{'changes_config'};
  die "$prg: top config file $tc has not been read."
    if (!defined($alldata->{'updmap'}{$tc}));

  for my $w (@what) {
    if ($w =~ m/=/) {
      # this is --enable MapType=MapName
      my ($type, $map) = split ('=', $w);
      # allow for all lowercase map types (map/mixedmap/kanjimap)
      $type =~ s/map$/Map/;
      $type = ucfirst($type);
      # don't allow map names containing /
      die "$prg: map names cannot contain /: $map\n" if ($map =~ m{/});
      enable_map($tc, $type, $map);
    } else {
      # this is --disable MapName
      disable_map($tc, $w);
    }
  }
  return save_updmap($tc);
}

sub enable_map {
  my ($tc, $type, $map) = @_;

  die "$prg: invalid mapType $type" if ($type !~ m/^(Map|MixedMap|KanjiMap)$/);

  if (defined($alldata->{'updmap'}{$tc}{'maps'}{$map})) {
    # the map data has already been read in, no special precautions necessary
    if (($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "enabled") &&
        ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} eq $type)) {
      # nothing to do here ... be happy!
      return;
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = $type;
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
    # add a new map file!
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = $type;
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "enabled";
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'line'} = -1;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
    $alldata->{'maps'}{$map}{'origin'} = $tc;
    $alldata->{'maps'}{$map}{'status'} = "enabled";
  }
}

sub disable_map {
  my ($tc, $map) = @_;

  merge_settings_replace_kanji();

  if (defined($alldata->{'updmap'}{$tc}{'maps'}{$map})) {
    # the map data has already been read in, no special precautions necessary
    if ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "disabled") {
      # nothing to do here ... be happy!
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
    # disable a Map type that might be activated in a lower ranked updmap.cfg
    if (!defined($alldata->{'maps'}{$map})) {
      print_warning("map file not present, nothing to disable: $map\n");
      return;
    }
    my $orig = $alldata->{'maps'}{$map}{'origin'};
    # add a new entry to the top level where we disable it
    # copy over the type from the last entry
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = 
      $alldata->{'updmap'}{$orig}{'maps'}{$map}{'type'};
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'line'} = -1;
    # rewrite the origin
    $alldata->{'maps'}{$map}{'origin'} = $tc;
    $alldata->{'maps'}{$map}{'status'} = "disabled";
    # go on for writing
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  }
}


# returns 1 if actually saved due to changes
sub save_updmap {
  my $fn = shift;
  return if $opts{'dry-run'};
  my %upd = %{$alldata->{'updmap'}{$fn}};
  if ($upd{'changed'}) {
    mkdirhier(dirname($fn));
    open (FN, ">$fn") || die "$prg: can't write to $fn: $!";
    my @lines = @{$upd{'lines'}};
    if (!@lines) {
      print "Creating new config file $fn\n";
      # update lsR database
      $updLSR->{add}($fn);
      $updLSR->{exec}();
      # reset the LSR stuff, otherwise we add files several times
      $updLSR->{reset}();
    }
    # collect the lines with data
    my %line_to_setting;
    my %line_to_map;
    my @add_setting;
    my @add_map;
    if (defined($upd{'setting'})) {
      for my $k (keys %{$upd{'setting'}}) {
        if ($upd{'setting'}{$k}{'line'} == -1) {
          push @add_setting, $k;
        } else {
          $line_to_setting{$upd{'setting'}{$k}{'line'}} = $k;
        }
      }
    }
    if (defined($upd{'maps'})) {
      for my $k (keys %{$upd{'maps'}}) {
        if ($upd{'maps'}{$k}{'line'} == -1) {
          push @add_map, $k;
        } else {
          $line_to_map{$upd{'maps'}{$k}{'line'}} = $k;
        }
      }
    }
    for my $i (0..$#lines) {
      if (defined($line_to_setting{$i})) {
        my $k = $line_to_setting{$i};
        my $v = $upd{'setting'}{$k}{'val'};
        print FN "$k $v\n";
      } elsif (defined($line_to_map{$i})) {
        my $m = $line_to_map{$i};
        my $rm;
        if (defined($upd{'maps'}{$m}{'original'})) {
          # we have the case that @noEmbed@ was replaced by the respective
          # setting. Before writing out we have to replace this back with
          # the original line!A
          $rm = $upd{'maps'}{$m}{'original'};
        } else {
          $rm = $m;
        }
        my $t = $upd{'maps'}{$m}{'type'};
        my $p = ($upd{'maps'}{$m}{'status'} eq "disabled" ? "#! " : "");
        print FN "$p$t $rm\n";
      } else {
        print FN "$lines[$i]\n";
      }
    }
    # add the new settings and maps
    for my $k (@add_setting) {
      my $v = $upd{'setting'}{$k}{'val'};
      print FN "$k $v\n";
    }
    for my $m (@add_map) {
      my $t = $upd{'maps'}{$m}{'type'};
      my $p = ($upd{'maps'}{$m}{'status'} eq "disabled" ? "#! " : "");
      print FN "$p$t $m\n";
    }
    close(FN) || warn("$prg: Cannot close file handle for $fn: $!");
    delete $alldata->{'updmap'}{$fn}{'changed'};
    return 1;
  }
  return 0;
}

######################
# check for correct option value
#
sub check_option {
  my ($opt, $val) = @_;
  if ((($settings{$opt}{'type'} eq "binary") && 
       $val ne "true" && $val ne "false") ||
      (($settings{$opt}{'type'} eq "string") &&
       !member($val, @{$settings{$opt}{'possible'}}))) {
    return 0;
  }
  return 1;
}

###############################################################################
# setOption (conf_file, option, value)
#   sets option to value in the config file (replacing the existing setting
#   or by adding a new line to the config file).
#
sub setOption {
  my ($opt, $val) = @_;

  # allow backward compatility with old kanjiEmbed and kanjiVariant settings
  if ($opt eq "kanjiEmbed") {
    print_warning("using jaEmbed instead of kanjiEmbed\n");
    $opt = "jaEmbed";
  }
  if ($opt eq "kanjiVariant") {
    print_warning("using jaVariant instead of kanjiVariant\n");
    $opt = "jaVariant";
  }

  die "$prg: Unsupported option $opt." if (!defined($settings{$opt}));
  die "$0: Invalid value $val for option $opt." 
    if (!check_option($opt, $val));

  # silently accept this old option name, just in case.
  return if $opt eq "dvipdfmDownloadBase14";
  
  #print "Setting option $opt to $val...\n" if !$opts{'quiet'};
  my $tc = $alldata->{'changes_config'};

  die "$prg: top config file $tc has not been read."
    if (!defined($alldata->{'updmap'}{$tc}));

  if (defined($alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'})) {
    # the value is already set, do nothing
    if ($alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} eq $val) {
      return;
    }
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} = $val;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  } else {
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} = $val;
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'line'} = -1;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  }
}


###############################################################################
# copyFile()
#   copy file $src to $dst, sets $dst creation and mod time
#
sub copyFile {
  my ($src, $dst) = @_;
  my $dir;
  ($dir=$dst)=~s/(.*)\/.*/$1/;
  mkdirhier($dir);

  $src eq $dst && return "can't copy $src to itself!\n";

  open IN, "<$src" or die "$0: can't open source file $src for copying: $!";
  open OUT, ">$dst";

  binmode(IN);
  binmode(OUT);
  print OUT <IN>;
  close(OUT);
  close(IN);
  my @t = stat($src);
  utime($t[8], $t[9], $dst);
}

###############################################################################
# files_are_identical(file_A, file_B)
#   compare two files.  Same as cmp(1).
#
sub files_are_identical {
  my $file_A=shift;
  my $file_B=shift;
  my $retval=0;

  open IN, "$file_A";
  my $A=(<IN>);
  close IN;
  open IN, "$file_B";
  my $B=(<IN>);
  close IN;

  $retval=1 if ($A eq $B);
  return $retval;
}

###############################################################################
# files_are_different(file_A, file_B[, comment_char])
#   compare two equalized files.
#
sub files_are_different {
  my $file_A=shift;
  my $file_B=shift;
  my $comment=shift;
  my $retval=0;

  my $A=equalize_file("$file_A", $comment);
  my $B=equalize_file("$file_B", $comment);
  $retval=1 unless ($A eq $B);
  return $retval;
}

###############################################################################
# equalize_file(filename[, comment_char])
#   read a file and return its processed content as a string.
#   look into the source code for more details.
#
sub equalize_file {
  my $file=shift;
  my $comment=shift;
  my @temp;

  open IN, "$file";
  my @lines = (<IN>);
  close IN;
  chomp(@lines);

  for (@lines) {
    s/\s*${comment}.*// if (defined $comment); # remove comments
    next if /^\s*$/;                           # remove empty lines
    s/\s+/ /g;     # replace multiple whitespace chars by a single one
    push @temp, $_;
  }
  return join('X', sort(@temp));
}

###############################################################################
# normalizeLines()
#   not the original function, we want it to keep comments, that are
#   anyway only the file names we are adding!
#   whitespace is exactly one space, no empty lines,
#   no whitespace at end of line, one space before and after "
#
sub normalizeLines {
  my @lines = @_;
  my %count = ();

  # @lines = grep { $_ !~ m/^[*#;%]/ } @lines;
  map {$_ =~ s/\s+/ /gx } @lines;
  @lines = grep { $_ !~ m/^\s*$/x } @lines;
  map { $_ =~ s/\s$//x ;
        $_ =~ s/\s*\"\s*/ \" /gx;
        $_ =~ s/\" ([^\"]*) \"/\"$1\"/gx;
      } @lines;

  # @lines = grep {++$count{$_} < 2 } (sort @lines);
  @lines = grep {++$count{$_} < 2 } (@lines);

  return @lines;
}


#################################################################
#
# reading updmap-cfg files and the actual map files
#
# the following hash saves *all* the information and is passed around
# we do not fill everything from the very beginning to make sure that
# we only read what is necessary (speed!)
#
# initialized by main
# $alldata->{'changes_config'} = the config file where changes are saved
#
# initialized by read_updmap_files
# $alldata->{'order'} = [ list of updmap in decreasing priority ]
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'lines'} = \@lines
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'setting'}{$key}{'val'} = $val
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'setting'}{$key}{'line'} = $i
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'type'} 
#            = 'Map'|'MixedMap'|'KanjiMap'|'disabled'
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'status'} 
#            = 'enabled'|'disabled'
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'line'} = $i
# $alldata->{'maps'}{$m}{'origin'} = $updmap_path_name
# $alldata->{'maps'}{$m}{'status'} = enabled | disabled
#
# initialized by read_map_files
# $alldata->{'maps'}{$m}{'fonts'}{$font} = $definition
# $alldata->{'fonts'}{$f}{'origin'} = $map
#
# initialized by merge_data
# $alldata->{'merged'}{'setting'}{$key}{'val'} = $val
# $alldata->{'merged'}{'setting'}{$key}{'origin'} = $origin_updmap_cfg
# $alldata->{'merged'}{'allMaps'}{'fonts'}{$fontdef} = $rest
# $alldata->{'merged'}{'noMixedMaps'}{'fonts'}{$fontdef} = $rest
# $alldata->{'merged'}{'KanjiMaps'}{'fonts'}{$fontdef} = $rest
#

sub read_updmap_files {
  my (@l) = @_;
  for my $l (@l) {
    my $updmap = read_updmap_file($l);
    $alldata->{'updmap'}{$l}{'lines'} = $updmap->{'lines'};
    if (defined($updmap->{'setting'})) {
      for my $k (keys %{$updmap->{'setting'}}) {
        $alldata->{'updmap'}{$l}{'setting'}{$k}{'val'} = $updmap->{'setting'}{$k}{'val'};
        $alldata->{'updmap'}{$l}{'setting'}{$k}{'line'} = $updmap->{'setting'}{$k}{'line'};
      }
    }
    if (defined($updmap->{'maps'})) {
      for my $k (keys %{$updmap->{'maps'}}) {
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'type'} = $updmap->{'maps'}{$k}{'type'};
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'status'} = $updmap->{'maps'}{$k}{'status'};
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'line'} = $updmap->{'maps'}{$k}{'line'};
      }
    }
  }
  # in case the changes_config is a new one read it in and initialize it here
  my $cc = $alldata->{'changes_config'};
  if (! -r $cc) {
    $alldata->{'updmap'}{$cc}{'lines'} = [ ];
  }
  #
  $alldata->{'order'} = \@l;
}

sub merge_settings_replace_kanji {
  #
  my @l = @{$alldata->{'order'}};
  #
  # for security clean out everything that was there
  %{$alldata->{'merged'}} = ();
  #
  # first read in the settings
  # we read it in *reverse* order and simple fill up the combined data
  # thus if there are multiple definitions/settings, the one coming from
  # the first in the original list will win!
  for my $l (reverse @l) {
    # merge settings
    if (defined($alldata->{'updmap'}{$l}{'setting'})) {
      for my $k (keys %{$alldata->{'updmap'}{$l}{'setting'}}) {
        $alldata->{'merged'}{'setting'}{$k}{'val'} = $alldata->{'updmap'}{$l}{'setting'}{$k}{'val'};
        $alldata->{'merged'}{'setting'}{$k}{'origin'} = $l;
      }
    }
  }
  #
  my ($jaEmbed, $jaEmbed_origin) = get_cfg('jaEmbed');
  my ($jaVariant, $jaVariant_origin) = get_cfg('jaVariant');
  my ($scEmbed, $scEmbed_origin) = get_cfg('scEmbed');
  my ($tcEmbed, $tcEmbed_origin) = get_cfg('tcEmbed');
  my ($koEmbed, $koEmbed_origin) = get_cfg('koEmbed');

  # keep backward compatibility with old definitions
  # of kanjiEmbed, kanjiVariant
  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));

  #
  # go through all map files and check that the text is properly replaced
  # after the replacement check that the generated map file actually
  # exists, we do NOT want to break in this case!
  #
  for my $l (@l) {
    for my $m (keys %{$alldata->{'updmap'}{$l}{'maps'}}) {
      my $newm = $m;
      # do all kinds of substitutions
      $newm =~ s/\@jaEmbed@/$jaEmbed/;
      $newm =~ s/\@jaVariant@/$jaVariant/;
      $newm =~ s/\@scEmbed@/$scEmbed/;
      $newm =~ s/\@tcEmbed@/$tcEmbed/;
      $newm =~ s/\@koEmbed@/$koEmbed/;
      # also do substitutions of old strings in case they are left
      # over somewhere
      $newm =~ s/\@kanjiEmbed@/$jaEmbed/;
      $newm =~ s/\@kanjiVariant@/$jaVariant/;
      if ($newm ne $m) {
        # something was substituted
        if (locateMap($newm)) {
          # now we have to update various linked items
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'type'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'type'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'status'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'status'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'line'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'line'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'original'} = $m;
        } else {
          print_warning("generated map $newm (from $m) does not exist, not activating it!\n");
        }
        # in any case delete the @kanji...@ entry line, such a map will
        # never exist
        delete $alldata->{'updmap'}{$l}{'maps'}{$m};
      }
    }
  }
  #
  # first round determine which maps should be used and which type, as
  # different updmap.cfg files might specify different types of maps
  # (MixedMap or Map or KanjiMap).
  # Again, we have to do that in reverse order
  for my $l (reverse @l) {
    if (defined($alldata->{'updmap'}{$l}{'maps'})) {
      for my $m (keys %{$alldata->{'updmap'}{$l}{'maps'}}) {
        $alldata->{'maps'}{$m}{'origin'} = $l;
        $alldata->{'maps'}{$m}{'status'} = $alldata->{'updmap'}{$l}{'maps'}{$m}{'status'};
      }
    }
  }
}

sub read_updmap_file {
  my $fn = shift;
  my %data;
  if (!open(FN,"<$fn")) {
    die ("Cannot read $fn: $!");
  }
  # we count lines from 0 ..!!!!
  my $i = -1;
  my @lines = <FN>;
  chomp(@lines);
  $data{'lines'} = [ @lines ];
  close(FN) || warn("$prg: Cannot close $fn: $!");
  for (@lines) {
    $i++;
    chomp;
    next if /^\s*$/;
    next if /^\s*#$/;
    next if /^\s*#[^!]/;
    next if /^\s*##/;
    next if /^#![^ ]/;
    # allow for commands on the line itself
    s/([^#].*)#.*$/$1/;
    my ($a, $b, @rest) = split ' ';
    # make sure we get empty strings as arguments
    $b = "" if (!defined($b));
    if ($a eq "#!") {
      if ($b eq "Map" || $b eq "MixedMap" || $b eq "KanjiMap") {
        my $c = shift @rest;
        if (!defined($c)) {
          print_warning("apparently not a real disable line, ignored: $_\n");
        } else {
          if (defined($data{'maps'}{$c})) {
            print_warning("double mention of $c in $fn\n");
          }
          $data{'maps'}{$c}{'status'} = 'disabled';
          $data{'maps'}{$c}{'type'} = $b;
          $data{'maps'}{$c}{'line'} = $i;
        }
      }
      next;
    }
    if (@rest) {
      print_warning("line $i in $fn contains a syntax error, more than two words!\n");
    }
    # backward compatibility with kanjiEmbed/kanjiVariant
    $a = ($a eq "kanjiEmbed" ? "jaEmbed" : $a);
    $a = ($a eq "kanjiVariant" ? "jaVariant" : $a);
    if (defined($settings{$a})) {
      if (check_option($a, $b)) {
        $data{'setting'}{$a}{'val'} = $b;
        $data{'setting'}{$a}{'line'} = $i;
      } else {
        print_warning("unknown setting for $a: $b, ignored!\n");
      }
    } elsif ($a eq "Map" || $a eq "MixedMap" || $a eq "KanjiMap") {
      if (defined($data{'maps'}{$b}) && $data{'maps'}{$b}{'type'} ne $a) {
        print_warning("double mention of $b with conflicting types in $fn\n");
      } else {
        $data{'maps'}{$b}{'type'} = $a;
        $data{'maps'}{$b}{'status'} = 'enabled';
        $data{'maps'}{$b}{'line'} = $i;
      }
    } else {
      print_warning("unrecognized line $i in $fn: $_\n");
    }
  }
  return \%data;
}

sub read_map_files {
  my $quick = shift;
  if (!defined($alldata->{'updmap'})) {
    return;
  }
  my @missing;
  my @l = @{$alldata->{'order'}};
  # first collect all the map files we are interested in
  # and determine whether they exist, and get their full path
  my @maps;
  for my $f (@l) {
    next if !defined($alldata->{'updmap'}{$f}{'maps'});
    for my $m (keys %{$alldata->{'updmap'}{$f}{'maps'}}) {
      # only read a map file if its final status is enabled!
      push @maps, $m if ($alldata->{'maps'}{$m}{'status'} eq 'enabled');
    }
  }
  for my $m (qw/dvips35.map pdftex35.map ps2pk35.map/) {
    push @maps, $m;
    $alldata->{'maps'}{$m}{'status'} = 'enabled';
    $alldata->{'maps'}{$m}{'origin'} = 'builtin';
  }
  @maps = sort_uniq(@maps);
  my @fullpath = `kpsewhich --format=map @maps`;
  chomp @fullpath;
  foreach my $map (@maps) {
    # in case they give an absolute path (not needed/desired, but ...);
    # Windows not supported.
    my $dirsep = ($map =~ m!^/!) ? "" : "/";
    # quotemeta the map string to avoid perl regexp warning, e.g.,
    # if map name contains "\Users", the "\U" should be literal.
    my ($ff) = grep /$dirsep\Q$map\E(\.map)?$/, @fullpath;
    if ($ff) {
      $alldata->{'maps'}{$map}{'fullpath'} = $ff;
    } else {
      # if the map file is not found, then push it onto the list of 
      # missing map files, since we know that it is enabled
      push @missing, $map;
    }
  }
  return @missing if $quick;

  #
  # read in the three basic fonts definition maps
  for my $m (qw/dvips35.map pdftex35.map ps2pk35.map/) {
    my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
    my @ff = ();
    for my $font (keys %$ret) {
      $alldata->{'fonts'}{$font}{'origin'} = $m;
      $alldata->{'maps'}{$m}{'fonts'}{$font} = $ret->{$font};
    }
  }
  # we read the updmap in reverse directions, since we
  # replace the origin field of font definition always with the
  # top one
  for my $f (reverse @l) {
    my @maps = keys %{$alldata->{'updmap'}{$f}{'maps'}};
    for my $m (@maps) {
      # we do not read a map file multiple times, if $alldata{'maps'}{$m} is
      # defined we expect that it was read and do skip it
      next if defined($alldata->{'maps'}{$m}{'fonts'});
      # we do not read a map files content if it is disabled
      next if ($alldata->{'maps'}{$m}{'status'} eq 'disabled');
      if (!defined($alldata->{'maps'}{$m}{'fullpath'})) {
        # we have already pushed these map files onto the list of missing
        # map files, so do nothing here
        next;
      }
      my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
      if (defined($ret)) {
        for my $font (keys %$ret) {
          if (defined($alldata->{'fonts'}{$font})) {
            # we got another definition, warn on that
            # if the origin is not defined by now, the font is defined
            # multiple times in the same map file, otherwise it is
            # defined in another map file already
            if (defined($alldata->{'fonts'}{$font}{'origin'})) {
              my $fontorig = $alldata->{'fonts'}{$font}{'origin'};
              my $maporig;
              if (($fontorig eq "ps2pk35.map") ||
                  ($fontorig eq "pdftex35.map") ||
                  ($fontorig eq "dvips35.map")) {
                $maporig = "built in map - both used - warning!";
              } else {
                $maporig = "from " . $alldata->{'maps'}{$fontorig}{'origin'};
              }
              print_warning("font $font is defined multiple times:\n");
              print_warning("  $fontorig ($maporig)\n");
              print_warning("  $m (from $f) (used)\n");
            } else {
              print_warning("font $font is multiply defined in $m, using an arbitrary instance!\n");
            }
          }
          $alldata->{'fonts'}{$font}{'origin'} = $m;
          $alldata->{'maps'}{$m}{'fonts'}{$font} = $ret->{$font};
        }
      }
    }
  }
  return (@missing);
}

sub read_map_file {
  my $fn = shift;
  my @lines;
  if (!open(MF,"<$fn")) {
    warn("$prg: open($fn) failed: $!");
    return;
  }
  @lines = <MF>;
  close(MF);
  chomp(@lines);
  my %data;
  for (@lines) {
    next if /^\s*#/;
    next if /^\s*%/;
    next if /^\s*$/;
    my ($a, $b) = split(' ', $_, 2);
    $data{$a} = $b;
  }
  return \%data;
}

#
# merging the various font definitions
#
sub merge_data {
  my @l = @{$alldata->{'order'}};
  #
  # now merge the data
  #
  for my $m (keys %{$alldata->{'maps'}}) {
    my $origin = $alldata->{'maps'}{$m}{'origin'};
    next if !defined($origin);
    next if ($origin eq 'builtin');
    next if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'} eq "disabled");
    for my $f (keys %{$alldata->{'maps'}{$m}{'fonts'}}) {
      # use the font definition only for those fonts where the origin matches
      if ($alldata->{'fonts'}{$f}{'origin'} eq $m) {
        $alldata->{'merged'}{'allMaps'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} ne "KanjiMap");
        $alldata->{'merged'}{'noMixedMaps'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "Map");
        $alldata->{'merged'}{'KanjiMap'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "KanjiMap");
      }
    }
  }
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

sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opts{'quiet'}) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}


# help, version.

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub help {
  my $usage = <<"EOF";
Usage: $prg [-user|-sys] [OPTION] ... [COMMAND]
   or: $prg-user [OPTION] ... [COMMAND]
   or: $prg-sys  [OPTION] ... [COMMAND]

Update the default font map files used by pdftex and dvipdfm(x)
(pdftex.map), dvips (psfonts.map), and optionally pxdvi, as determined
by all configuration files updmap.cfg (usually the ones returned by
running "kpsewhich --all updmap.cfg", but see below).

Among other things, these map files are used to determine which fonts
should be used as bitmaps and which as outlines, and to determine which
font files are included, typically subsetted, in the PDF or PostScript output.

updmap-sys (or updmap -sys) is intended to affect the system-wide 
configuration, while updmap-user (or updmap -user) affects personal
configuration files only, overriding the system files.  

As a consequence, once updmap-user has been run, even a single time,
running updmap-sys no longer has any effect.  updmap-sys issues a
warning about this, since it is rarely desirable.
See https://tug.org/texlive/scripts-sys-user.html for details.

By default, the TeX filename database (ls-R) is also updated.

The updmap system is regrettably complicated, for both inherent and
historical reasons.  A general overview:

- updmap.cfg files are mainly about listing other files, namely the
  font-specific .maps, in which each line gives information about a
  different TeX (.tfm) font.
- updmap reads the updmap.cfg files and then concatenates the
  contents of those .map files into the main output files: psfonts.map
  for dvips and pdftex.map for pdftex and dvipdfmx.
- The updmap.cfg files themselves are created and updated at package
  installation time, by the system installer or the package manager or
  by hand, and not (by default) by updmap.

Options:
  --cnffile FILE            read FILE for the updmap configuration 
                             (can be given multiple times, in which case
                             all the files are used)
  --dvipdfmxoutputdir DIR   specify output directory (dvipdfm(x) syntax)
  --dvipsoutputdir DIR      specify output directory (dvips syntax)
  --pdftexoutputdir DIR     specify output directory (pdftex syntax)
  --pxdvioutputdir DIR      specify output directory (pxdvi syntax)
  --outputdir DIR           specify output directory (for all files)
  --copy                    cp generic files rather than using symlinks
  --force                   recreate files even if config hasn't changed
  --nomkmap                 do not recreate map files
  --nohash                  do not run mktexlsr (a.k.a. texhash)
  --sys                     affect system-wide files (equivalent to updmap-sys)
  --user                    affect personal files (equivalent to updmap-user)
  -n, --dry-run             only show the configuration, no output
  --quiet, --silent         reduce verbosity

Commands:
  --help                     show this message and exit
  --version                  show version information and exit
  --showoption OPTION        show the current setting of OPTION
  --showoptions OPTION       show possible settings for OPTION
  --setoption OPTION VALUE   set OPTION to value; option names below
  --setoption OPTION=VALUE   as above, just different syntax
  --enable MAPTYPE MAPFILE   add "MAPTYPE MAPFILE" to updmap.cfg,
                              where MAPTYPE is Map, MixedMap, or KanjiMap
  --enable Map=MAPFILE       add \"Map MAPFILE\" to updmap.cfg
  --enable MixedMap=MAPFILE  add \"MixedMap MAPFILE\" to updmap.cfg
  --enable KanjiMap=MAPFILE  add \"KanjiMap MAPFILE\" to updmap.cfg
  --disable MAPFILE          disable MAPFILE, of whatever type
  --listmaps                 list all maps (details below)
  --listavailablemaps        list available maps (details below)
  --syncwithtrees            disable unavailable map files in updmap.cfg

The main output:

  The main output of updmap is the files containing the individual font
  map lines which the drivers (dvips, pdftex, etc.) read to handle fonts.
  
  The map files for dvips (psfonts.map) and pdftex and dvipdfmx
  (pdftex.map) are written to TEXMFVAR/fonts/map/updmap/{dvips,pdftex}/.
  
  In addition, information about Kanji fonts is written to
  TEXMFVAR/fonts/map/updmap/dvipdfmx/kanjix.map, and optionally to 
  TEXMFVAR/fonts/map/updmap/pxdvi/xdvi-ptex.map.  These are for Kanji
  only and are not like other map files.  dvipdfmx reads pdftex.map for
  the map entries for non-Kanji fonts.
  
  If no option is given, so the invocation is just "updmap-user" or
  "updmap-sys", these output files are always recreated.

  Otherwise, if an option such as --enable or --disable is given, the
  output files are recreated if the list of enabled map files (from
  updmap.cfg) has changed.  The --force option overrides this,
  always recreating the output files.
  
Explanation of the map types:

  The normal type is Map.
  
  The only difference between Map and MixedMap is that MixedMap entries
  are not added to psfonts_pk.map.  The purpose is to help users with
  devices that render Type 1 outline fonts worse than mode-tuned Type 3
  bitmap fonts.  So, MixedMap is used for fonts that are available as
  both Type 1 and Metafont.

  KanjiMap entries are added to psfonts_t1.map and kanjix.map.

Explanation of the OPTION names for --showoptions, --showoption, --setoption:

  dvipsPreferOutline    true,false  (default true)
    Whether dvips uses bitmaps or outlines, when both are available.
  dvipsDownloadBase35   true,false  (default true)
    Whether dvips includes the standard 35 PostScript fonts in its output.
  pdftexDownloadBase14  true,false   (default true)
    Whether pdftex includes the standard 14 PDF fonts in its output.
  pxdviUse              true,false  (default false)
    Whether maps for pxdvi (Japanese-patched xdvi) are under updmap's control.
  jaEmbed               (any string)
  jaVariant             (any string)
  scEmbed               (any string)
  tcEmbed               (any string)
  koEmbed               (any string)
    See below.
  LW35                  URWkb,URW,ADOBEkb,ADOBE  (default URWkb)
    Adapt the font and file names of the standard 35 PostScript fonts.

    URWkb    URW fonts with "berry" filenames    (e.g. uhvbo8ac.pfb)
    URW      URW fonts with "vendor" filenames   (e.g. n019064l.pfb)
    ADOBEkb  Adobe fonts with "berry" filenames  (e.g. phvbo8an.pfb)
    ADOBE    Adobe fonts with "vendor" filenames (e.g. hvnbo___.pfb)

  These options are only read and acted on by updmap; dvips, pdftex, etc.,
  do not know anything about them.  They work by changing the default map
  file which the programs read, so they can be overridden by specifying
  command-line options or configuration files to the programs, as
  explained at the beginning of updmap.cfg.

  The options jaEmbed and jaVariant (formerly kanjiEmbed and kanjiVariant)
  specify special replacements in the map lines.  If a map contains the 
  string \@jaEmbed\@, then this will be replaced by the value of that option;
  similarly for jaVariant.  In this way, users of Japanese TeX can select
  different fonts to be included in the final output.  The counterpart for
  Simplified Chinese, Traditional Chinese and Korean fonts are
  scEmbed, tcEmbed and koEmbed respectively.

Explanation of trees and files normally used:

  If --cnffile is specified on the command line (can be given multiple
  times), its value(s) is(are) used.  Otherwise, updmap reads all the
  updmap.cfg files found by running \`kpsewhich -all updmap.cfg',
  in the order returned by kpsewhich (which is the order of trees
  defined in texmf.cnf).

  In either case, if multiple updmap.cfg files are found, all the maps
  mentioned in all the updmap.cfg files are merged.

  Thus, if updmap.cfg files are present in all trees, and the default
  layout is used as shipped with TeX Live, the following files are
  read, in the given order.
  
  For updmap-sys:
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/updmap.cfg
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg

  For updmap-user:
  TEXMFCONFIG    \$HOME/.texliveYYYY/texmf-config/web2c/updmap.cfg
  TEXMFVAR       \$HOME/.texliveYYYY/texmf-var/web2c/updmap.cfg
  TEXMFHOME      \$HOME/texmf/web2c/updmap.cfg
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/updmap.cfg
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
  
  (where YYYY is the TeX Live release version).
  
  According to the actions, updmap might write to one of the given files
  or create a new updmap.cfg, described further below.

Where and which updmap.cfg changes are saved: 

  When no options are given, the updmap.cfg file(s) are only read, not
  written.  It's when an option --setoption, --enable or --disable is
  specified that an updmap.cfg needs to be updated.  In this case:

  1) If config files are given on the command line, then the first one
  given is used to save any such changes.
  
  2) If the config files are taken from kpsewhich output, then the
  algorithm is more complex:

    2a) If \$TEXMFCONFIG/web2c/updmap.cfg or \$TEXMFHOME/web2c/updmap.cfg
    appears in the list of used files, then the one listed first by
    kpsewhich --all (equivalently, the one returned by kpsewhich
    updmap.cfg), is used.
      
    2b) If neither of the above two are present and changes are made, a
    new config file is created in \$TEXMFCONFIG/web2c/updmap.cfg.
  
  In general, the idea is that if the user cannot write to a given
  config file, a higher-level one can be used.  That way, the
  distribution's settings can be overridden system-wide using
  TEXMFLOCAL, and system settings can be overridden again in a
  particular user's TEXMFHOME or TEXMFCONFIG.

Resolving multiple definitions of a font:

  If a font is defined in more than one map file, then the definition
  coming from the first-listed updmap.cfg is used.  If a font is
  defined multiple times within the same map file, one is chosen
  arbitrarily.  In both cases a warning is issued.

Disabling maps:

  updmap.cfg files with higher priority (listed earlier) can disable
  maps mentioned in lower priority (listed later) updmap.cfg files by
  writing, e.g.,
    \#! Map mapname.map
  or
    \#! MixedMap mapname.map
  in the higher-priority updmap.cfg file.  (The \#! must be at the
  beginning of the line, with at least one space or tab afterward, and
  whitespace between each word on the list.)

  As an example, suppose you have a copy of MathTime Pro fonts
  and want to disable the Belleek version of the fonts; that is,
  disable the map belleek.map.  You can create the file
  \$TEXMFCONFIG/web2c/updmap.cfg with the content
    #! Map belleek.map
    Map mt-plus.map
    Map mt-yy.map
  and call $prg.

Listing of maps:

  The two options --listmaps and --listavailablemaps list all maps
  defined in any of the updmap.cfg files (for --listmaps), and 
  only those actually found on the system (for --listavailablemaps).
  The output format is one line per font map, with the following
  fields separated by tabs: map, type (Map, MixedMap, KanjiMap),
  status (enabled, disabled), origin (the updmap.cfg file where
  it is mentioned, or 'builtin' for the three basic maps).

  In the case of --listmaps there can be one additional fields
  (again separated by tab) containing '(not available)' for those
  map files that cannot be found.
 
updmap-user vs. updmap-sys:

  When updmap-sys is run, TEXMFSYSCONFIG and TEXMFSYSVAR are used
  instead of TEXMFCONFIG and TEXMFVAR, respectively.  This is the
  primary difference between updmap-sys and updmap-user.

  Other locations may be used if you give them on the command line, or
  these trees don't exist, or you are not using the original TeX Live.

To see the precise locations of the various files that
will be read and written, give the -n option (or read the source).

The log file is written to TEXMFVAR/web2c/updmap.log.

For step-by-step instructions on making new fonts known to TeX, read
https://tug.org/fonts/fontinstall.html.  For even more terse
instructions, read the beginning of the main updmap.cfg file.

Report bugs to: tex-live\@tug.org
TeX Live home page: <https://tug.org/texlive/>
EOF
;
  print &version();
  print $usage;
  exit 0;
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #

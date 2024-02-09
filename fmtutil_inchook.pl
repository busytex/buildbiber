BEGIN {
my %modules = (
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfig.pm@TeXLive/TLConfig.pm
"TeXLive/TLConfig.pm" => <<'__EOI__',

use strict; use warnings;
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
    @InstallExtraRequiredPackages
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

our $ReleaseYear = 2023;

our $MinRelease = 2016;

our @MetaCategories = qw/Collection Scheme/;
our $MetaCategoriesRegexp = '(Collection|Scheme)';
our @NormalCategories = qw/Package TLCore ConTeXt/;
our @Categories = (@MetaCategories, @NormalCategories);

our $CategoriesRegexp = '(Collection|Scheme|Package|TLCore|ConTeXt)';

our $DefaultCategory = "Package";

our $InfraLocation = "tlpkg";
our $DatabaseName = "texlive.tlpdb";
our $DatabaseLocation = "$InfraLocation/$DatabaseName";

our $PackageBackupDir = "$InfraLocation/backups";

our $BlockSize = 4096;

our $NetworkTimeout = 30;
our $MaxLWPErrors = 5;
our $MaxLWPReinitCount = 10;

our $Archive = "archive";
our $TeXLiveServerURL = "https://mirror.ctan.org";
our $TeXLiveServerURLRegexp = 'https?://mirror\.ctan\.org';
our $TeXLiveServerPath = "systems/texlive/tlnet";
our $TeXLiveURL = "$TeXLiveServerURL/$TeXLiveServerPath";

our $RelocTree = "texmf-dist";
our $RelocPrefix = "RELOC";

our @CriticalPackagesList = qw/texlive.infra/;
our $CriticalPackagesRegexp = '^(texlive\.infra)';
if ($^O =~ /^MSWin/i) {
  push (@CriticalPackagesList, "tlperl.windows");
  $CriticalPackagesRegexp = '^(texlive\.infra|tlperl\.windows$)';
}


our @InstallExtraRequiredPackages = qw/texlive-scripts kpathsea hyphen-base/;
if ($^O =~ /^MSWin/i) {
  push @InstallExtraRequiredPackages, "luatex";
}

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
our $DefaultCompressorFormat = "xz";
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

our %TLPDBConfigs = (
  "container_split_src_files" => 1,
  "container_split_doc_files" => 1,
  "container_format" => $DefaultCompressorFormat,
  "minrelease" => $MinRelease,
  "release" => $ReleaseYear,
  "frozen" => 0,
);



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
      "Create Start menu shortcuts (Windows)" ],
  "file_assocs" =>
    [ "n:0..2", 1, "fileassocs",
      "Change file associations (Windows)" ],
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
      "Install for all users (Windows)" ],
);


our %TLPDBSettings = (
  "platform" => [ "s", "Main platform for this computer" ],
  "available_architectures" => [ "l","All available/installed architectures" ],
  "usertree" => [ "b", "This tree acts as user tree" ]
);

our $WindowsMainMenuName = "TeX Live $ReleaseYear";

our $PartialEngineSupport = "luametatex,luajithbtex,luajittex,mfluajit";

our $F_OK = 0;
our $F_WARNING = 1;
our $F_ERROR = 2;
our $F_NOPOSTACTION = 4;

our $ChecksumLength = 128;

our $ChecksumProgram = "sha512sum";

our $ChecksumExtension = "sha512";

1;









1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfig.pm@TeXLive/TLConfig.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLUtils.pm@TeXLive/TLUtils.pm
"TeXLive/TLUtils.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLUtils;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


our $PERL_SINGLE_QUOTE; # we steal code from Text::ParseWords

BEGIN {
  $::LOGFILE = $::LOGFILE;
  $::LOGFILENAME = $::LOGFILENAME;
  @::LOGLINES = @::LOGLINES;
  @::debug_hook = @::debug_hook;
  @::ddebug_hook = @::ddebug_hook;
  @::dddebug_hook = @::dddebug_hook;
  @::info_hook = @::info_hook;
  @::install_packages_hook = @::install_packages_hook;
  @::installation_failed_packages = @::installation_failed_packages;
  @::warn_hook = @::warn_hook;
  $::checksum_method = $::checksum_method;
  $::gui_mode = $::gui_mode;
  $::machinereadable = $::machinereadable;
  $::no_execute_actions = $::no_execute_actions;
  $::regenerate_all_formats = $::regenerate_all_formats;
  $::context_cache_update_needed = $::context_cache_update_needed;
  $JSON::false = $JSON::false;
  $JSON::true = $JSON::true;
  $TeXLive::TLDownload::net_lib_avail = $TeXLive::TLDownload::net_lib_avail;
}
      

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
    &all_dirs_and_removed_dirs
    &dirs_of_files
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
    &system_ok
    &wsystem
    &xsystem
    &run_cmd
    &run_cmd_with_log
    &system_pipe
    &diskfree
    &get_user_home
    &expand_tilde
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
               wndws xchdir xsystem run_cmd system_pipe sort_archs);
}

use Cwd;
use Getopt::Long;
use File::Temp;

use TeXLive::TLConfig;

$::opt_verbosity = 0;  # see process_logging_options

our $SshURIRegex = '^((ssh|scp)://([^@]*)@([^/]*)/|([^@]*)@([^:]*):).*$';


sub platform {
  if (! defined $::_platform_) {
    if ($^O =~ /^MSWin/i) {
      $::_platform_ = "windows";
    } else {
      my $config_guess = "$::installerdir/tlpkg/installer/config.guess";

      die "$0: config.guess script does not exist, goodbye: $config_guess"
        if ! -r $config_guess;

      my $config_shell = $ENV{"CONFIG_SHELL"} || "/bin/sh";
      my $paren_cmdout = `'$config_shell' -c 'echo \$(echo foo)' 2>/dev/null`;
      if (length ($paren_cmdout) <= 2) {
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
      chomp (my $guessed_platform = `'$config_shell' '$config_guess'`);

      die "$0: could not run $config_guess, cannot proceed, sorry"
        if ! $guessed_platform;

      $::_platform_ = platform_name($guessed_platform);
    }
  }
  return $::_platform_;
}



sub platform_name {
  my ($orig_platform) = @_;
  my $guessed_platform = $orig_platform;

  $guessed_platform =~ s/^x86_64-(.*-k?)(free|net)bsd/amd64-$1$2bsd/;
  my $CPU; # CPU type as reported by config.guess.
  my $OS;  # O/S type as reported by config.guess.
  ($CPU = $guessed_platform) =~ s/(.*?)-.*/$1/;

  $CPU =~ s/^alpha(.*)/alpha/;   # alphaev whatever
  $CPU =~ s/mips64el/mipsel/;    # don't distinguish mips64 and 32 el
  $CPU =~ s/powerpc64/powerpc/;  # don't distinguish ppc64
  $CPU =~ s/sparc64/sparc/;      # don't distinguish sparc64

  if ($CPU =~ /^arm/) {
    $CPU = $guessed_platform =~ /hf$/ ? "armhf" : "armel";
  }

  if ($ENV{"TEXLIVE_OS_NAME"}) {
    $OS = $ENV{"TEXLIVE_OS_NAME"};
  } else {
    my @OSs = qw(aix cygwin darwin dragonfly freebsd hpux irix
                 kfreebsd linux midnightbsd netbsd openbsd solaris);
    for my $os (@OSs) {
      $OS = $os if $guessed_platform =~ /\b$os/;
    }
  }  

  if (! $OS) {
    warn "$0: could not guess OS from config.guess string: $orig_platform";
    $OS = "unknownOS";
  }
  
  if ($OS eq "linux") {
    $OS = "linuxmusl" if $guessed_platform =~ /\blinux-musl/;
  }
  
  if ($OS eq "darwin") {
    my $mactex_darwin = 14;  # lowest minor rev supported by universal-darwin.
    chomp (my $sw_vers = `sw_vers -productVersion`);
    my ($os_major,$os_minor) = split (/\./, $sw_vers);
    if ($os_major < 10) {
      warn "$0: only MacOSX is supported, not $OS $os_major.$os_minor "
           . " (from sw_vers -productVersion: $sw_vers)\n";
      return "unknownmac-unknownmac";
    }
    if ($os_major >= 11 || $os_minor >= $mactex_darwin) {
      $CPU = "universal";
      $OS = "darwin";
    } elsif ($os_major == 10 && 6 <= $os_minor && $os_minor < $mactex_darwin){
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
    'armhf-linux'      => 'GNU/Linux on RPi(32-bit) and ARMv7',
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
    'win32'            => 'Windows (32-bit)',
    'windows'          => 'Windows (64-bit)',
    'x86_64-cygwin'    => 'Cygwin on x86_64',
    'x86_64-darwinlegacy' => 'MacOSX legacy (10.6-) on x86_64',
    'x86_64-dragonfly' => 'DragonFlyBSD on x86_64',
    'x86_64-linux'     => 'GNU/Linux on x86_64',
    'x86_64-linuxmusl' => 'GNU/Linux on x86_64 with musl',
    'x86_64-solaris'   => 'Solaris on x86_64',
  );


  if (exists $platform_name{$platform}) {
    return "$platform_name{$platform}";
  } else {
    my ($CPU,$OS) = split ('-', $platform);
    $OS = "" if ! defined $OS; # e.g., -force-platform foo
    return "$CPU with " . ucfirst "$OS";
  }
}



sub wndws {
  if ($^O =~ /^MSWin/i) {
    return 1;
  } else {
    return 0;
  }
}



sub unix {
  return (&platform eq "windows")? 0:1;
}



sub getenv {
  my $envvar=shift;
  my $var=$ENV{"$envvar"};
  return 0 unless (defined $var);
  if (&wndws) {
    $var=~s!\\!/!g;  # change \ -> / (required by Perl)
  }
  return "$var";
}



sub which {
  my ($prog) = @_;
  my @PATH;
  my $PATH = getenv('PATH');

  if (&wndws) {
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


sub initialize_global_tmpdir {
  $::tl_tmpdir = File::Temp::tempdir(CLEANUP => 1);
  ddebug("TLUtils::initialize_global_tmpdir: creating global tempdir $::tl_tmpdir\n");
  return ($::tl_tmpdir);
}


sub tl_tmpdir {
  initialize_global_tmpdir() if (!defined($::tl_tmpdir));
  my $tmp = File::Temp::tempdir(DIR => $::tl_tmpdir, CLEANUP => 1);
  ddebug("TLUtils::tl_tmpdir: creating tempdir $tmp\n");
  return ($tmp);
}


sub tl_tmpfile {
  initialize_global_tmpdir() if (!defined($::tl_tmpdir));
  my ($fh, $fn) = File::Temp::tempfile(@_, DIR => $::tl_tmpdir, UNLINK => 1);
  ddebug("TLUtils::tl_tempfile: creating tempfile $fn\n");
  return ($fh, $fn);
}



sub xchdir {
  my ($dir) = @_;
  chdir($dir) || die "$0: chdir($dir) failed: $!";
  ddebug("xchdir($dir) ok\n");
}


sub system_ok {
  my $nulldev = nulldev();
  my ($cmdline) = @_;
  `$cmdline >$nulldev 2>&1`;
  return $? == 0;
}


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


sub run_cmd {
  my $cmd = shift;
  my %envvars = @_;
  my %envvarsSetState;
  my %envvarsValue;
  for my $k (keys %envvars) {
    $envvarsSetState{$k} = exists $ENV{$k};
    $envvarsValue{$k} = $ENV{$k};
    $ENV{$k} = $envvars{$k};
  }
  my $output = `$cmd`;
  for my $k (keys %envvars) {
    if ($envvarsSetState{$k}) {
      $ENV{$k} = $envvarsValue{$k};
    } else {
      delete $ENV{$k};
    }
  }

  $output = "" if ! defined ($output);  # don't return undef

  my $retval = $?;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
  }
  return ($output,$retval);
}


sub run_cmd_with_log {
  my ($cmd,$logfn) = @_;
  
  info ("running $cmd ...");
  my ($out,$ret) = TeXLive::TLUtils::run_cmd ("$cmd 2>&1");
  if ($ret == 0) {
    info ("done\n");
  } else {
    info ("failed\n");
    tlwarn ("$0: $cmd failed (status $ret): $!\n");
    $ret = 1;
  }
  &$logfn ($out); # log the output
  
  return $ret;
} # run_cmd_with_log



sub system_pipe {
  my ($prog, $infile, $outfile, $removeIn, @extraargs) = @_;
  
  my $progQuote = quotify_path_with_spaces($prog);
  if (wndws()) {
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


sub diskfree {
  my $td = shift;
  my ($output, $retval);
  if (wndws()) {
    my @winver = Win32::GetOSVersion();
    if ($winver[1]<=6 && $winver[2]<=1) {
      return -1;
    }
    my $avl;
    if ($td =~ /^[a-zA-Z]:/) {
      my $drv = substr($td,0,1);
      my $cmd = "powershell -nologo -noninteractive -noprofile -command " .
       "\"get-psdrive -name $drv -ea ignore |select-object free |format-wide\"";
      ($output, $retval) = run_cmd($cmd);
      my @lines = split(/\r*\n/, $output);
      foreach (@lines) {
        chomp $_;
        if ($_ !~ /^\s*$/) {
          $_ =~ s/^\s*//;
          $_ =~ s/\s*$//;
          $avl = $_;
          last;
        }
      }
      if ($avl !~ /^[0-9]+$/) {
        return (-1);
      } else {
        return (int($avl/(1024*1024)));
      }
    } else {
      return -1;
    }
  }
  return (-1) if (! $::progs{"df"});
  $td =~ s!/$!!;
  if (! -e $td) {
    my $ptd = dirname($td);
    if (-e $ptd) {
      $td = $ptd;
    } else {
      my $pptd = dirname($ptd);
      if (-e $pptd) {
        $td = $pptd;
      }
    }
  }
  $td .= "/" if ($td !~ m!/$!);
  return (-1) if (! -e $td);
  debug("checking diskfree() in $td\n");
  ($output, $retval) = run_cmd("df -Pk \"$td\"");
  if ($retval == 0) {
    my ($h,$l) = split(/\n/, $output);
    my ($fs, $nrb, $used, $avail, @rest) = split(' ', $l);
    debug("diskfree: df -Pk output: $output");
    debug("diskfree: used=$used (1024-block), avail=$avail (1024-block)\n");
    return (int($avail / 1024));
  } else {
    return (-1);
  }
}


my $user_home_dir;

sub get_user_home {
  return $user_home_dir if ($user_home_dir);
  $user_home_dir = getenv (wndws() ? 'USERPROFILE' : 'HOME') || '~';
  return $user_home_dir;
}


sub expand_tilde {
  my $str = shift;
  my $h = get_user_home();
  $str =~ s/^~/$h/;
  return $str;
}


sub dirname_and_basename {
  my $path=shift;
  my ($share, $base) = ("", "");
  if (wndws()) {
    $path=~s!\\!/!g;
  }
  return (undef, undef) if $path =~ m!/\.\.$!;
  if ($path=~m!/!) {   # dirname("foo/bar/baz") -> "foo/bar"
    while ($path =~ s!/\./!/!) {};
    if (wndws() and $path =~ m!^(//[^/]+/[^/]+)(.*)$!) {
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
    $path=~m!(.*)/(.*)!; # works because of greedy matching
    return ((($1 eq '') ? '/' : $1), $2);
  } else {             # dirname("ignore") -> "."
    return (".", $path);
  }
}



sub dirname {
  my $path = shift;
  my ($dirname, $basename) = dirname_and_basename($path);
  return $dirname;
}



sub basename {
  my $path = shift;
  my ($dirname, $basename) = dirname_and_basename($path);
  return $basename;
}



sub tl_abs_path {
  my $path = shift;
  if (wndws()) {
    $path=~s!\\!/!g;
  }
  if (-e $path) {
    $path = Cwd::abs_path($path);
  } elsif ($path eq '.') {
    $path = Cwd::getcwd();
  } else{
    $path =~ s!/\./!/!g;
    die "Unsupported path syntax" if $path =~ m!/\.\./! || $path =~ m!/\.\.$!
      || $path =~ m!^\.\.!;
    die "Unsupported path syntax" if wndws() && $path =~ m!^//\?/!;
    if ($path !~ m!^(.:)?/!) { # relative path
      if (wndws() && $path =~ /^.:/) { # drive letter
        my $dcwd;
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



sub dir_slash {
  my $d = shift;
  $d = "$d/" unless $d =~ m!/!;
  return $d;
}

sub dir_creatable {
  my $path=shift;
  $path =~ s!\\!/!g if wndws;
  return 0 unless -d $path;
  $path .= '/' unless $path =~ m!/$!;
  my $d;
  for my $i (1..100) {
    $d = "";
    $d = $path . int(rand(1000000));
    last unless -e $d;
  }
  if (!$d) {
    tlwarn("Cannot find available testdir name\n");
    return 0;
  }
  return 0 unless mkdir $d;
  return 0 unless -d $d;
  rmdir $d;
  return 1;
}




sub dir_writable {
  my ($path) = @_;
  return 0 unless -d $path;
  $path =~ s!\\!/!g if wndws;
  $path .= '/' unless $path =~ m!/$!;
  my $i = 0;
  my $f;
  for my $i (1..100) {
    $f = "";
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



sub mkdirhier {
  my ($tree,$mode) = @_;
  my $ret = 1;
  my $reterror;

  if (-d "$tree") {
    $ret = 1;
  } else {
    my $subdir = "";
    $subdir = $& if ( wndws() && ($tree =~ s!^//[^/]+/!!) );

    my @dirs = split (/[\/\\]/, $tree);
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



sub copy {
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
    $outfile = $destdir;
    $destdir = dirname($outfile);
  } else {
    $outfile = "$destdir/$filename";
  }

  if (! -d $destdir) {
    my ($ret,$err) = mkdirhier ($destdir);
    die "mkdirhier($destdir) failed: $err\n" if ! $ret;
  }

  if (-l $infile && $dereference) {
    my $linktarget = readlink($infile);
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

    while (my $read = sysread (IN, $buffer, $blocksize)) {
      die "read($infile) failed: $!" unless defined $read;
      $offset = 0;
      while ($read) {
        my $written = syswrite (OUT, $buffer, $read, $offset);
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



sub collapse_dirs {
  my (@files) = @_;
  my @ret = ();
  my %by_dir;

  for my $f (@files) {
    my $abs_f = Cwd::abs_path ($f);
    die ("oops, no abs_path($f) from " . `pwd`) unless $abs_f;
    (my $d = $abs_f) =~ s,/[^/]*$,,;
    my @a = exists $by_dir{$d} ? @{$by_dir{$d}} : ();
    push (@a, $abs_f);
    $by_dir{$d} = \@a;
  }

  for my $d (sort keys %by_dir) {
    opendir (DIR, $d) || die "opendir($d) failed: $!";
    my @dirents = readdir (DIR);
    closedir (DIR) || warn "closedir($d) failed: $!";

    my %seen;
    my @rmfiles = @{$by_dir{$d}};
    @seen{@rmfiles} = ();

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


sub dirs_of_files {
  my (@files) = @_;
  my %by_dir;

  for my $f (@files) {
    next if (! -r "$f");
    my $abs_f = Cwd::abs_path ($f);
    $abs_f =~ s!\\!/!g if wndws();
    if (!$abs_f) {
      warn ("oops, no abs_path($f) from " . `pwd`);
      next;
    }
    (my $d = $abs_f) =~ s,/[^/]*$,,;
    my @a = exists $by_dir{$d} ? @{$by_dir{$d}} : ();
    push (@a, $abs_f);
    $by_dir{$d} = \@a;
  }

  return %by_dir;
}


sub all_dirs_and_removed_dirs {
  my (@files) = @_;
  my %removed_dirs;
  my %by_dir = dirs_of_files(@files);

  for my $d (reverse sort keys %by_dir) {
    opendir (DIR, $d) || die "opendir($d) failed: $!";
    my @dirents = readdir (DIR);
    closedir (DIR) || warn "closedir($d) failed: $!";

    my %seen;
    my @rmfiles = @{$by_dir{$d}};
    @seen{@rmfiles} = ();

    my $cleandir = 1;
    for my $dirent (@dirents) {
      next if $dirent =~ /^\.(\.|svn)?$/;  # ignore . .. .svn
      my $item = "$d/$dirent";  # prepend directory for comparison
      if (
           ((-d $item) && (defined($removed_dirs{$item})))
           ||
           (exists $seen{$item})
         ) {
      } else {
        $cleandir = 0;
        last;
      }
    }
    if ($cleandir) {
      $removed_dirs{$d} = 1;
    }
  }
  return (%by_dir, %removed_dirs);
}


sub time_estimate {
  my ($totalsize, $donesize, $starttime) = @_;
  if ($donesize <= 0) {
    return ("??:??", "??:??");
  }
  my $curtime = time();
  my $passedtime = $curtime - $starttime;
  my $esttotalsecs = int ( ( $passedtime * $totalsize ) / $donesize );
  my $remsecs = $passedtime;
  my $min = int($remsecs/60);
  my $hour;
  if ($min >= 60) {
    $hour = int($min/60);
    $min %= 60;
  }
  my $sec = $remsecs % 60;
  my $remtime = sprintf("%02d:%02d", $min, $sec);
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
  my $tottime = sprintf("%02d:%02d", $tmin, $tsec);
  if ($thour) {
    $tottime = sprintf("%02d:$tottime", $thour);
  }
  return($remtime, $tottime);
}



sub install_packages {
  my ($fromtlpdb,$media,$totlpdb,$what,
      $opt_src,$opt_doc,$opt_retry,$opt_continue) = @_;
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
      $tlpsizes{$p} = $tlpobjs{$p}->containersize;
      $tlpsizes{$p} += $tlpobjs{$p}->srccontainersize if $opt_src;
      $tlpsizes{$p} += $tlpobjs{$p}->doccontainersize if $opt_doc;
    } else {
      $tlpsizes{$p} = $tlpobjs{$p}->runsize;
      $tlpsizes{$p} += $tlpobjs{$p}->srcsize if $opt_src;
      $tlpsizes{$p} += $tlpobjs{$p}->docsize if $opt_doc;
      my %foo = %{$tlpobjs{$p}->binsize};
      for my $k (keys %foo) { $tlpsizes{$p} += $foo{$k}; }
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
    if (!$fromtlpdb->install_package($package, $totlpdb)) {
      tlwarn("TLUtils::install_packages: Failed to install $package\n");
      if ($opt_retry) {
        tlwarn("                           $package will be retried later.\n");
        push @packs_again, $package;
      } else {
        return 0;
      }
    } else {
      $donesize += $tlpsizes{$package};
    }
  }
  foreach my $package (@packs_again) {
    my $infostr = sprintf("Retrying to install: $package [%dk]",
                     int($tlpsizes{$package}/1024) + 1);
    info("$infostr\n");
    if (!$fromtlpdb->install_package($package, $totlpdb)) {
      if ($opt_continue) {
        push @::installation_failed_packages, $package;
        tlwarn("Failed to install $package, but continuing anyway!\n");
      } else {
        return 0;
      }
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
  return $ret;
}

sub _do_postaction_fileassoc {
  my ($how, $mode, $tlpobj, $pa) = @_;
  return 1 unless wndws();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/extension filetype/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  if (!defined($keyval{'extension'})) {
    tlwarn("extension of fileassoc postaction not given\n");
    return 0;
  }
  my $extension = $keyval{'extension'};

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
  return 1 unless wndws();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/name cmd/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

  if (!defined($keyval{'name'})) {
    tlwarn("name of filetype postaction not given\n");
    return 0;
  }
  my $name = $keyval{'name'}.'.'.$ReleaseYear;

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

sub _do_postaction_progid {
  my ($how, $tlpobj, $pa) = @_;
  return 1 unless wndws();
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

  if (!defined($keyval{'file'})) {
    tlwarn("filename of script not given\n");
    return 0;
  }
  my $file = $keyval{'file'};
  if (wndws() && defined($keyval{'filew32'})) {
    $file = $keyval{'filew32'};
  }
  my $texdir = `kpsewhich -var-value=TEXMFROOT`;
  chomp($texdir);
  my @syscmd;
  if ($file =~ m/\.pl$/i) {
    push @syscmd, "perl", "$texdir/$file";
  } elsif ($file =~ m/\.texlua$/i) {
    push @syscmd, "texlua", "$texdir/$file";
  } else {
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
  return 1 unless wndws();
  my ($errors, %keyval) =
    parse_into_keywords($pa, qw/type name icon cmd args hide/);

  if ($errors) {
    tlwarn("parsing the postaction line >>$pa<< did not succeed!\n");
    return 0;
  }

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

  if (!defined($keyval{'name'})) {
    tlwarn("name of shortcut postaction not given\n");
    return 0;
  }
  my $name = $keyval{'name'};

  my $icon = (defined($keyval{'icon'}) ? $keyval{'icon'} : '');
  my $cmd = (defined($keyval{'cmd'}) ? $keyval{'cmd'} : '');
  my $args = (defined($keyval{'args'}) ? $keyval{'args'} : '');

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
    if ($cmd !~ m!^\s*(https?://|ftp://)!) {
      if (!(-e $cmd) or !(-r $cmd)) {
        tlwarn("Target of shortcut action does not exist: $cmd\n")
            if $cmd =~ /\.(exe|bat|cmd)$/i;
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


sub update_context_cache {
  my ($bindir,$progext,$run_postinst_cmd) = @_;
  
  my $errcount = 0;

  my $lmtx = "$bindir/luametatex$progext";
  if (TeXLive::TLUtils::system_ok("$lmtx --version")) {
    info("setting up ConTeXt cache: ");
    $errcount += &$run_postinst_cmd("mtxrun --generate");
    if ($errcount == 0) {
      $errcount += &$run_postinst_cmd("context --luatex --generate");
      if ($errcount == 0) {
        my $luajittex = "$bindir/luajittex$progext";
        if (TeXLive::TLUtils::system_ok("$luajittex --version")) {
          $errcount += &$run_postinst_cmd("context --luajittex --generate");
        } else {
          debug("skipped luajittex cache setup, can't run $luajittex\n");
        }
      }
    }
  }
  return $errcount;
}


sub announce_execute_actions {
  my ($type,$tlp,$what) = @_;
  return if $::no_execute_actions;
  
  if ($type ne "enable") {
    my $forpkg = $tlp ? ("for " . $tlp->name) : "no package";
    debug("announce_execute_actions: given $type ($forpkg)\n");
  }
  if (defined($type) && ($type eq "regenerate-formats")) {
    $::regenerate_all_formats = 1;
    return;
  }
  if (defined($type) && ($type eq "files-changed")) {
    $::files_changed = 1;
    return;
  }
  if (defined($type) && ($type eq "context-cache")) {
    $::context_cache_update_needed = 1;
    return;
  }
  if (defined($type) && ($type eq "rebuild-format")) {
    $::execute_actions{'enable'}{'formats'}{$what->{'name'}} = $what; 
    return;
  }
  if (!defined($type) || (($type ne "enable") && ($type ne "disable"))) {
    die "announce_execute_actions: enable or disable, not type $type";
  }
  if ($tlp->runfiles || $tlp->srcfiles || $tlp->docfiles) {
    $::files_changed = 1;
  }
  $what = "map format hyphen" if (!defined($what)); # do all by default
  foreach my $e ($tlp->executes) {
    if ($e =~ m/^add((Mixed|Kanji)?Map)\s+([^\s]+)\s*$/) {
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



sub add_link_dir_dir {
  my ($from,$to) = @_;
  my ($ret, $err) = mkdirhier ($to);
  if (!$ret) {
    tlwarn("$err\n");
    return 0;
  }
  if (-w $to) {
    debug ("TLUtils::add_link_dir_dir: linking from $from to $to\n");
    chomp (my @files = `ls "$from"`);
    my $ret = 1;
    for my $f (@files) {
      if ($f eq "man") {
        debug ("not linking `man' into $to.\n");
        next;
      }
      unlink ("$to/$f") if -l "$to/$f";
      if (-e "$to/$f") {
        tlwarn ("add_link_dir_dir: $to/$f exists; not making symlink.\n");
        next;
      }
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
    chomp (my @files = `ls "$from"`);
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

  return if wndws();

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

  my $top_man_dir = "$Master/texmf-dist/doc/man";
  debug("TLUtils::add_remove_symlinks: $mode symlinks for man pages to $sys_man from $top_man_dir\n");
  if (! -d $top_man_dir) {
    ; # better to be silent?
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
      } else {
        tlwarn("TLUtils::add_remove_symlinks: man symlink destination ($sys_man) not writable, "
          . "cannot $mode symlinks.\n");
        $errors++;
      }
    }
  }
  
  if ($errors) {
    info("TLUtils::add_remove_symlinks: $mode of symlinks had $errors error(s), see messages above.\n");
    return $F_ERROR;
  } else {
    return $F_OK;
  }
}

sub add_symlinks    { return (add_remove_symlinks("add", @_));    }
sub remove_symlinks { return (add_remove_symlinks("remove", @_)); }


sub w32_add_to_path {
  my ($bindir, $multiuser) = @_;
  return if (!wndws());

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


sub check_file_and_remove {
  my ($xzfile, $checksum, $checksize) = @_;
  my $fn_name = (caller(0))[3];
  debug("$fn_name $xzfile, $checksum, $checksize\n");

  if (!$checksum && !$checksize) {
    tlwarn("$fn_name: neither checksum nor checksize " .
           "available for $xzfile, cannot check integrity"); 
    return;
  }
  
  my $check_file_tmpdir = undef;

  if ($checksum && ($checksum ne "-1") && $::checksum_method) {
    my $tlchecksum = TeXLive::TLCrypto::tlchecksum($xzfile);
    if ($tlchecksum ne $checksum) {
      tlwarn("$fn_name: checksums differ for $xzfile:\n");
      tlwarn("$fn_name:   tlchecksum=$tlchecksum, arg=$checksum\n");
      tlwarn("$fn_name: backtrace:\n" . backtrace());
      $check_file_tmpdir = File::Temp::tempdir();
      tlwarn("$fn_name:   removing $xzfile, "
             . "but saving copy in $check_file_tmpdir\n");
      copy($xzfile, $check_file_tmpdir);
      unlink($xzfile);
      return;
    } else {
      debug("$fn_name: checksums for $xzfile agree\n");
      return;
    }
  }
  if ($checksize && ($checksize ne "-1")) {
    my $filesize = (stat $xzfile)[7];
    if ($filesize != $checksize) {
      tlwarn("$fn_name: removing $xzfile, sizes differ:\n");
      tlwarn("$fn_name:   tlfilesize=$filesize, arg=$checksize\n");
      if (!defined($check_file_tmpdir)) {
        $check_file_tmpdir = File::Temp::tempdir("tlcheckfileXXXXXXXX");
        tlwarn("$fn_name:  saving copy in $check_file_tmpdir\n");
        copy($xzfile, $check_file_tmpdir);
      }
      unlink($xzfile);
      return;
    }
  } 
}


sub unpack {
  my ($what, $target, %opts) = @_;
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
  if (!member($decompressorType, @{$::progs{'working_compressors'}})) {
    return(0, "unsupported container format $decompressorType");
  }

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
    if (-r $containerfile) {
      check_file_and_remove($containerfile, $checksum, $size);
    }
    if (! -r $containerfile) {
      if (!download_file($what, $containerfile)) {
        return(0, "downloading did not succeed (download_file failed)");
      }
      check_file_and_remove($containerfile, $checksum, $size);
      if ( ! -r $containerfile ) {
        return(0, "downloading did not succeed (check_file_and_remove failed)");
      }
    }
  } else {
    TeXLive::TLUtils::copy("-L", $what, $tempdir);

    check_file_and_remove($containerfile, $checksum, $size);
    if (! -r $containerfile) {
      return (0, "consistency checks failed");
    }
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


sub untar {
  my ($tarfile, $targetdir, $remove_tarfile) = @_;
  my $ret;

  my $tar = $::progs{'tar'};  # assume it's been set up

  debug("TLUtils::untar: unpacking $tarfile in $targetdir\n");
  my $cwd = cwd();
  chdir($targetdir) || die "chdir($targetdir) failed: $!";

  my $taropt = wndws() ? "xmf" : "xf";
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



sub read_file_ignore_cr {
  my ($fname) = @_;
  my $ret = "";

  local *FILE;
  open (FILE, $fname) || die "open($fname) failed: $!";
  while (<FILE>) {
    s/\r\n?/\n/g;
    $ret .= $_;
  }
  close (FILE) || warn "close($fname) failed: $!";

  return $ret;
}



sub setup_programs {
  my ($bindir, $platform, $tlfirst) = @_;
  my $ok = 1;

  if (!defined($tlfirst)) {
    if ($ENV{'TEXLIVE_PREFER_OWN'}) {
      debug("setup_programs: TEXLIVE_PREFER_OWN is set!\n");
      $tlfirst = 1;
    }
  }

  debug("setup_programs: preferring " . ($tlfirst ? "TL" : "system") . " versions\n");

  my $isWin = ($^O =~ /^MSWin/i);

  if ($isWin) {
    setup_one("w32", 'tar', "$bindir/tar.exe", "--version", 1);
    $platform = "exe";
  } else {
    $::progs{'tar'} = "tar";

    setup_one("unix", "df", undef, "-P .", 0);

    if (!defined($platform) || ($platform eq "")) {
      $::installerdir = "$bindir/../..";
      $platform = platform();
    }
  }

  my @working_downloaders;
  for my $dltype (@AcceptedFallbackDownloaders) {
    my $defprog = $FallbackDownloaderProgram{$dltype};
    push @working_downloaders, $dltype if 
      setup_one(($isWin ? "w32" : "unix"), $defprog,
                 "$bindir/$dltype/$defprog.$platform", "--version", $tlfirst);
  }
  if (member("curl", @working_downloaders) && platform() =~ m/darwin/) {
    chomp (my $sw_vers = `sw_vers -productVersion`);
    my ($os_major,$os_minor) = split (/\./, $sw_vers);
    if ($os_major == 10 && ($os_minor == 13 || $os_minor == 14)) {
      my @curlargs = @{$TeXLive::TLConfig::FallbackDownloaderArgs{'curl'}};
      unshift (@curlargs, '--cacert', "$::installerdir/tlpkg/installer/curl/curl-ca-bundle.crt");
      $TeXLive::TLConfig::FallbackDownloaderArgs{'curl'} = \@curlargs;
      debug("TLUtils::setup_programs: curl on old darwin, final curl args: @{$TeXLive::TLConfig::FallbackDownloaderArgs{'curl'}}\n");
    }
  }
  if (member("wget", @working_downloaders)) {
    debug("TLUtils::setup_programs: checking for ssl enabled wget\n");
    my @lines = `$::progs{'wget'} --version 2>&1`;
    if (grep(/\+ssl/, @lines)) {
      $::progs{'options'}{'wget-ssl'} = 1;
      my @wgetargs = @{$TeXLive::TLConfig::FallbackDownloaderArgs{'wget'}};
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
    if (setup_one(($isWin ? "w32" : "unix"), $defprog,
                  "$bindir/$defprog/$defprog.$platform", "--version",
                  $tlfirst)) {
      push @working_compressors, $defprog;
      defined($::progs{'compressor'}) || ($::progs{'compressor'} = $defprog);
    }
  }
  $::progs{'working_compressors'} = [ @working_compressors ];

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
  if ($ENV{'TEXLIVE_COMPRESSOR'}) {
    $::progs{'compressor'} = $ENV{'TEXLIVE_COMPRESSOR'};
  }

  if ($::opt_verbosity >= 2) {
    require Data::Dumper;
    no warnings 'once';
    local $Data::Dumper::Sortkeys = 1;  # stable output
    local $Data::Dumper::Purity = 1;    # reconstruct recursive structures
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


sub setup_unix_tl_one {
  my ($p, $def, $arg) = @_;
  if (!$def) {
    debug("(unix) no default program for $p, no setup done\n");
    return(1);
  }
  our $tmp;
  debug("(unix) trying to set up $p, default $def, arg $arg\n");
  if (-r $def) {
    if (-x $def) {
      ddebug(" Default $def has executable permissions\n");
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
    $tmp = TeXLive::TLUtils::tl_tmpdir() unless defined($tmp);
    copy($def, $tmp);
    my $bn = basename($def);
    my $tmpprog = "$tmp/$bn";
    chmod(0755,$tmpprog);
    if (! -x $tmpprog) {
      ddebug(" Copied $p $tmpprog does not have -x bit, strange!\n");
      return(0);
    } else {
      my $ret = system("$tmpprog $arg > /dev/null 2>&1");
      if ($ret == 0) {
        debug(" Using copied $tmpprog for $p (tested).\n");
        $::progs{$p} = $tmpprog;
        return(1);
      } else {
        ddebug(" Copied $p $tmpprog has x bit but not executable?!\n");
        return(0);
      }
    }
  } else {
    return(0);
  }
}



sub download_file {
  my ($relpath, $dest) = @_;
  my $par;
  if ($dest ne "|") {
    $par = dirname($dest);
    mkdirhier ($par) unless -d "$par";
  }
  my $url;
  if ($relpath =~ m;^file://*(.*)$;) {
    my $filetoopen = "/$1";
    if ($dest eq "|") {
      open(RETFH, "<$filetoopen") or
        die("Cannot open $filetoopen for reading");
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
    if (!setup_persistent_downloads()) {
      debug("reinitialization of LWP download failed\n");
      return(0);
    }
  }
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
  return(0);
}


sub _download_file_program {
  my ($url, $dest, $type) = @_;
  if (wndws()) {
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
    return \*RETFH;
  } else {
    $ret = system ($downloader, @downloaderargs, $dest, $url);
    $ret = ($ret ? 0 : 1);
  }
  return ($ret) unless $ret;
  debug("download of $url succeeded\n");
  if ($dest eq "|") {
    return \*RETFH;
  } else {
    return 1;
  }
}


sub nulldev {
  return (&wndws()) ? 'nul' : '/dev/null';
}


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
  $firstline = "" if (!defined($firstline));
  chomp ($firstline);
  if ($firstline =~ m/^# Generated by (install-tl|.*\/tlmgr) on/) {
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
    return 1;
  } else {
    return 0;
  }
}

sub create_language_dat {
  my ($tlpdb,$dest,$localconf) = @_;
  my @lines = $tlpdb->language_dat_lines(
                         get_disabled_local_configs($localconf, '%'));
  _create_config_files($tlpdb, "texmf-dist/tex/generic/config/language.us",
                       $dest, $localconf, 0, '%', \@lines);
}

sub create_language_def {
  my ($tlpdb,$dest,$localconf) = @_;
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
    tldie ("TLUtils::_create_config_files: giving up, unreadable: "
           . "$root/$headfile\n")
  }
  push @lines, @$tlpdblinesref;
  if (defined($localconf) && -r $localconf) {
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
    $ret{"error"} = "Unknown language directive $a";
    return %ret;
  }
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
    $ret{"error"} = "Unknown format directive $p";
    return %ret;
  }
  return %ret;
}


sub logit {
  my ($out, $level, @rest) = @_;
  _logit($out, $level, @rest) unless $::opt_quiet;
  _logit('file', $level, @rest);
}

sub _logit {
  my ($out, $level, @rest) = @_;
  if ($::opt_verbosity >= $level) {
    if (ref($out) eq "GLOB") {
      print $out @rest;
    } else {
      if (defined($::LOGFILE)) {
        print $::LOGFILE @rest;
      } else {
        push (@::LOGLINES, join ("", @rest));
      }
    }
  }
}


sub info {
  my $str = join("", @_);
  my $fh = ($::machinereadable ? \*STDERR : \*STDOUT);
  logit($fh, 0, $str);
  for my $i (@::info_hook) {
    &{$i}($str);
  }
}


sub debug {
  return if ($::opt_verbosity < 1);
  my $str = "D:" . join("", @_);
  logit(\*STDERR, 1, $str);
  for my $i (@::debug_hook) {
    &{$i}($str);
  }
}


sub ddebug {
  return if ($::opt_verbosity < 2);
  my $str = "DD:" . join("", @_);
  logit(\*STDERR, 2, $str);
  for my $i (@::ddebug_hook) {
    &{$i}($str);
  }
}


sub dddebug {
  return if ($::opt_verbosity < 3);
  my $str = "DDD:" . join("", @_);
  logit(\*STDERR, 3, $str);
  for my $i (@::dddebug_hook) {
    &{$i}($str);
  }
}


sub log {
  my $savequiet = $::opt_quiet;
  $::opt_quiet = 0;
  _logit('file', -100, @_);
  $::opt_quiet = $savequiet;
}


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


sub tldie {
  tlwarn("\n", @_);
  if ($::gui_mode) {
    Tk::exit(1);
  } else {
    exit(1);
  }
}


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


sub backtrace {
  my $ret = "";

  my ($filename, $line, $subr);
  my $stackframe = 1;  # skip ourselves
  while ((undef,$filename,$line,$subr) = caller ($stackframe)) {
    $ret .= " -> ${filename}:${line}: ${subr}\n";
    $stackframe++;
  }

  return $ret;
}


sub push_uniq {
  my ($l, @new_items) = @_;
  for my $e (@new_items) {
    if (! scalar grep($_ eq $e, @$l)) {
      push (@$l, $e);
    }
  }
}


sub member {
  my $what = shift;
  return scalar grep($_ eq $what, @_);
}


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


sub texdir_check {
  my ($orig_texdir,$warn) = @_;
  return 0 unless defined $orig_texdir;

  my $texdir = tl_abs_path($orig_texdir);
  return 0 unless defined $texdir;

  return 0 if $texdir =~ m!/$!;

  my $colon = wndws() ? "" : ":";
  if ($texdir =~ /[,$colon;\\{}\$]/) {
    if ($warn) {
      print "     !! TEXDIR value has problematic characters: $orig_texdir\n";
      print "     !! (such as comma, colon, semicolon, backslash, braces\n";
      print "     !!  and dollar sign; sorry)\n";
    }
    return 0;
  }
  return 0 if wndws() && $texdir =~ m!^//[^/]+/[^/]+$!;

  return dir_writable($texdir) if (-d $texdir);

  (my $texdirparent = $texdir) =~ s!/[^/]*$!!;
  return dir_creatable($texdirparent) if -d dir_slash($texdirparent);
  
  (my $texdirpparent = $texdirparent) =~ s!/[^/]*$!!;
  return dir_creatable($texdirpparent) if -d dir_slash($texdirpparent);
  
  return 0;
}


sub quotify_path_with_spaces {
  my $p = shift;
  my $m = wndws() ? '[+=^&();,!%\s]' : '.';
  if ( $p =~ m/$m/ ) {
    $p =~ s/"//g; # remove any existing double quotes
    $p = "\"$p\""; 
  }
  return($p);
}


sub conv_to_w32_path {
  my $p = shift;
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


sub native_slashify {
  my ($r) = @_;
  $r =~ s!/!\\!g if wndws();
  return $r;
}

sub forward_slashify {
  my ($r) = @_;
  $r =~ s!\\!/!g if wndws();
  return $r;
}


sub setup_persistent_downloads {
  my $certs = shift;
  if ($TeXLive::TLDownload::net_lib_avail) {
    ddebug("setup_persistent_downloads has net_lib_avail set\n");
    if ($::tldownload_server) {
      if ($::tldownload_server->initcount() > $TeXLive::TLConfig::MaxLWPReinitCount) {
        debug("stop retrying to initialize LWP after 10 failures\n");
        return 0;
      } else {
        $::tldownload_server->reinit(certificates => $certs);
      }
    } else {
      $::tldownload_server = TeXLive::TLDownload->new(certificates => $certs);
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



sub query_ctan_mirror {
  my @working_downloaders = @{$::progs{'working_downloaders'}};
  ddebug("query_ctan_mirror: working_downloaders: @working_downloaders\n");
  if (TeXLive::TLUtils::member("curl", @working_downloaders)) {
    return query_ctan_mirror_curl();
  } elsif (TeXLive::TLUtils::member("wget", @working_downloaders)) {
    if ($::progs{'options'}{'wget-ssl'}) {
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

sub query_ctan_mirror_curl {
  my $max_trial = 3;
  my $warg = (wndws() ? '-w "%{url_effective}" ' : "-w '%{url_effective}' ");
  for (my $i = 1; $i <= $max_trial; $i++) {
    my $cmd = "$::progs{'curl'} -Ls "
              . "-o " . nulldev() . " "
              . $warg
              . "--connect-timeout $NetworkTimeout "
              . "--max-time $NetworkTimeout "
              . $TeXLiveServerURL;
    ddebug("query_ctan_mirror_curl: cmd: $cmd\n");
    my $url = `$cmd`;
    if (length $url) {
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

  my $mirror = $TeXLiveServerURL;
  my $cmd = "$wget $mirror --timeout=$NetworkTimeout "
            . "-O " . nulldev() . " 2>&1";
  ddebug("query_ctan_mirror_wget: cmd is $cmd\n");

  my $saved_lcall;
  if (defined($ENV{'LC_ALL'})) {
    $saved_lcall = $ENV{'LC_ALL'};
  }
  $ENV{'LC_ALL'} = "C";
  my $max_trial = 3;
  my $mhost;
  for (my $i = 1; $i <= $max_trial; $i++) {
    my @out = `$cmd`;
    foreach (@out) {
      if (m/^Location: (\S*)\s*.*$/) {
        (my $mhost = $1) =~ s,/*$,,;  # remove trailing slashes since we add it
        ddebug("query_ctan_mirror_wget: returning url: $mhost\n");
        return $mhost;
      }
    }
    sleep(1);
  }

  if (defined($saved_lcall)) {
    $ENV{'LC_ALL'} = $saved_lcall;
  } else {
    delete($ENV{'LC_ALL'});
  }

  return;
}
  

sub check_on_working_mirror {
  my $mirror = shift;

  my $wget = $::progs{'wget'};
  if (!defined ($wget)) {
    tlwarn ("check_on_working_mirror: Programs not set up, trying wget\n");
    $wget = "wget";
  }
  $wget = quotify_path_with_spaces($wget);
  my $cmd = "$wget $mirror/ --timeout=$NetworkTimeout -O -"
            . "  >" . (TeXLive::TLUtils::nulldev())
            . " 2>" . (TeXLive::TLUtils::nulldev());
  my $ret = system($cmd);
  return ($ret ? 0 : 1);
}


sub give_ctan_mirror_base {
  my @backbone = qw!https://www.ctan.org/tex-archive!;

  ddebug("give_ctan_mirror_base: calling query_ctan_mirror\n");
  my $mirror = query_ctan_mirror();
  if (!defined($mirror)) {
    tlwarn("cannot contact mirror.ctan.org, returning a backbone server!\n");
    return $backbone[int(rand($#backbone + 1))];
  }

  if ($mirror =~ m!^https?://!) {  # if http mirror, assume good and return.
    return $mirror;
  }

  if (check_on_working_mirror($mirror)) {
    return $mirror;  # ftp mirror is working, return.
  }

  my $max_mirror_trial = 5;
  for (my $try = 1; $try <= $max_mirror_trial; $try++) {
    my $m = query_ctan_mirror();
    debug("querying mirror, got " . (defined($m) ? $m : "(nothing)") . "\n");
    if (defined($m) && $m =~ m!^https?://!) {
      return $m;  # got http this time, assume ok.
    }
    sleep(1) if $try < $max_mirror_trial;
  }

  debug("no mirror found ... randomly selecting backbone\n");
  return $backbone[int(rand($#backbone + 1))];
}


sub give_ctan_mirror {
  return (give_ctan_mirror_base(@_) . "/$TeXLiveServerPath");
}


sub create_mirror_list {
  our $mirrors;
  my @ret = ();
  require("installer/ctan-mirrors.pl");
  my @continents = sort keys %$mirrors;
  for my $continent (@continents) {
    push @ret, uc($continent);
    my @countries = sort keys %{$mirrors->{$continent}};
    for my $country (@countries) {
      my @mirrors = sort keys %{$mirrors->{$continent}{$country}};
      my $first = 1;
      for my $mirror (@mirrors) {
        my $mfull = $mirror;
        $mfull =~ s!/$!!;
          my $country_str = sprintf "%-12s", $country;
          push @ret, "  $country_str  $mfull";
      }
    }
  }
  return @ret;
}

sub extract_mirror_entry {
  my $ent = shift;
  my @foo = split ' ', $ent;
  return $foo[$#foo] . "/" . $TeXLive::TLConfig::TeXLiveServerPath;
}


sub slurp_file {
  my $file = shift;
  my $file_data = do {
    local $/ = undef;
    open my $fh, "<", $file || die "open($file) failed: $!";
    <$fh>;
  };
  return($file_data);
}


sub download_to_temp_or_file {
  my $url = shift;
  my $ret;
  my ($url_fh, $url_file);
  if ($url =~ m,^(https?|ftp|file)://, || $url =~ m!$SshURIRegex!) {
    ($url_fh, $url_file) = tl_tmpfile();
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

  my %triggersA;
  my %triggersB;
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
      if ($mustexist) {
        foreach my $file (keys %files) {
          die "mktexupd: exec file does not exist: $file" if (! -f $file);
        }
      }
      my $delim= (&wndws)? ';' : ':';
      my $TEXMFDBS;
      chomp($TEXMFDBS=`kpsewhich --show-path="ls-R"`);

      my @texmfdbs=split ($delim, "$TEXMFDBS");
      my %dbs;
     
      foreach my $path (keys %files) {
        foreach my $db (@texmfdbs) {
          $db=substr($db, -1) if ($db=~m|/$|); # strip leading /
          $db = lc($db) if wndws();
          my $up = (wndws() ? lc($path) : $path);
          if (substr($up, 0, length("$db/")) eq "$db/") {
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



sub setup_sys_user_mode {
  my ($prg, $optsref, $TEXMFCONFIG, $TEXMFSYSCONFIG, 
      $TEXMFVAR, $TEXMFSYSVAR) = @_;
  
  if ($optsref->{'user'} && $optsref->{'sys'}) {
    print STDERR "$prg [ERROR]: only one of -sys or -user can be used.\n";
    exit(1);
  }

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
    $texmfconfig = $TEXMFSYSCONFIG;
    $texmfvar    = $TEXMFSYSVAR;
    &debug("TLUtils::setup_sys_user_mode: sys mode\n");

  } elsif ($optsref->{'user'}) {
    $texmfconfig = $TEXMFCONFIG;
    $texmfvar    = $TEXMFVAR;
    &debug("TLUtils::setup_sys_user_mode: user mode\n");

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



sub prepend_own_path {
  my $bindir = dirname(Cwd::abs_path(which('kpsewhich')));
  if (wndws()) {
    $bindir =~ s!\\!/!g;
    $ENV{'PATH'} = "$bindir;$ENV{PATH}";
  } else {
    $ENV{'PATH'} = "$bindir:$ENV{PATH}";
  }
}



sub repository_to_array {
  my $r = shift;
  my %r;
  if (!$r) {
    return %r;
  }
  my @repos = split (' ', $r);
  if ($#repos == 0) {
    $r{'main'} = $repos[0];
    return %r;
  }
  for my $rr (@repos) {
    my $tag;
    my $url;
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



my $TLTrueValue = 1;
my $TLFalseValue = 0;
my $TLTrue = \$TLTrueValue;
my $TLFalse = \$TLFalseValue;
bless $TLTrue, 'TLBOOLEAN';
bless $TLFalse, 'TLBOOLEAN';

our $jsonmode = "";


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
  my $envdefined = 0;
  if ($ENV{'TL_JSONMODE'}) {
    $envdefined = 1;
    if ($ENV{'TL_JSONMODE'} eq "texlive") {
      $jsonmode = "texlive";
      debug("texlive json module used!\n");
      return;
    } elsif ($ENV{'TL_JSONMODE'} eq "json") {
    } else {
      tlwarn("Unsupported mode \'$ENV{TL_JSONMODE}\' set in TL_JSONMODE, ignoring it!");
      $envdefined = 0;
    }
  }
  return if ($jsonmode); # was set to texlive
  eval { require JSON; };
  if ($@) {
    if ($envdefined) {
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
    my $value = shift;
    no warnings 'numeric';
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


1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLUtils.pm@TeXLive/TLUtils.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/installer/ctan-mirrors.pl@installer/ctan-mirrors.pl
"installer/ctan-mirrors.pl" => <<'__EOI__',
$mirrors = {
  'Africa' => {
    'Morocco' => {
      'https://mirror.marwan.ma/ctan/' => 1,
    },
    'South Africa' => {
      'http://ftp.sun.ac.za/ftp/CTAN/' => 1,
      'https://mirror.ufs.ac.za/ctan/' => 1,
    },
  },
  'Asia' => {
    'China' => {
      'https://mirror.bjtu.edu.cn/CTAN/' => 1,
      'https://mirror.nyist.edu.cn/CTAN/' => 1,
      'https://mirrors.aliyun.com/CTAN/' => 1,
      'https://mirrors.bfsu.edu.cn/CTAN/' => 1,
      'https://mirrors.cloud.tencent.com/CTAN/' => 1,
      'https://mirrors.cqu.edu.cn/CTAN/' => 1,
      'https://mirrors.jlu.edu.cn/CTAN/' => 1,
      'https://mirrors.nju.edu.cn/CTAN/' => 1,
      'https://mirrors.pku.edu.cn/ctan/' => 1,
      'https://mirrors.sjtug.sjtu.edu.cn/ctan/' => 1,
      'https://mirrors.sustech.edu.cn/CTAN/' => 1,
      'https://mirrors.tuna.tsinghua.edu.cn/CTAN/' => 1,
      'https://mirrors.ustc.edu.cn/CTAN/' => 1,
    },
    'Hong Kong' => {
      'https://mirror-hk.koddos.net/CTAN/' => 1,
    },
    'India' => {
      'https://in.mirrors.cicku.me/ctan/' => 1,
      'https://mirror.niser.ac.in/ctan/' => 1,
    },
    'Indonesia' => {
      'http://repo.ugm.ac.id/ctan/' => 1,
      'https://mirror.unpad.ac.id/ctan/' => 1,
    },
    'Iran' => {
      'http://ctan.asis.ai/' => 1,
      'https://ctan.yazd.ac.ir/' => 1,
    },
    'Japan' => {
      'http://ring.airnet.ne.jp/archives/text/CTAN/' => 1,
      'https://ftp.jaist.ac.jp/pub/CTAN/' => 1,
      'https://ftp.kddilabs.jp/CTAN/' => 1,
      'https://ftp.yz.yamagata-u.ac.jp/pub/CTAN/' => 1,
      'https://jp.mirrors.cicku.me/ctan/' => 1,
    },
    'Korea' => {
      'http://ftp.ktug.org/tex-archive/' => 1,
      'https://ftp.kaist.ac.kr/tex-archive/' => 1,
      'https://kr.mirrors.cicku.me/ctan/' => 1,
      'https://lab.uklee.pe.kr/tex-archive/' => 1,
      'https://mirror.kakao.com/CTAN/' => 1,
    },
    'Singapore' => {
      'https://sg.mirrors.cicku.me/ctan/' => 1,
    },
    'Taiwan' => {
      'https://ctan.mirror.twds.com.tw/tex-archive/' => 1,
    },
    'Thailand' => {
      'https://mirror.kku.ac.th/CTAN/' => 1,
    },
  },
  'Europe' => {
    'Austria' => {
      'https://mirror.easyname.at/ctan/' => 1,
      'https://mirror.kumi.systems/ctan/' => 1,
    },
    'Belarus' => {
      'https://mirror.datacenter.by/pub/mirrors/CTAN/' => 1,
    },
    'Czech Republic' => {
      'http://ftp.cvut.cz/tex-archive/' => 1,
      'https://mirrors.nic.cz/tex-archive/' => 1,
    },
    'Denmark' => {
      'https://mirrors.dotsrc.org/ctan/' => 1,
    },
    'Finland' => {
      'https://mirror.5i.fi/tex-archive/' => 1,
      'https://www.nic.funet.fi/pub/TeX/CTAN/' => 1,
      'https://www.texlive.info/CTAN/' => 1,
    },
    'France' => {
      'https://ctan.gutenberg-asso.fr/' => 1,
      'https://ctan.mines-albi.fr/' => 1,
      'https://ctan.tetaneutral.net/' => 1,
      'https://distrib-coffee.ipsl.jussieu.fr/pub/mirrors/ctan/' => 1,
      'https://mirror.ibcp.fr/pub/CTAN/' => 1,
      'https://mirrors.ircam.fr/pub/CTAN/' => 1,
      'https://texlive.mycozy.space/' => 1,
    },
    'Germany' => {
      'ftp://ftp.fu-berlin.de/tex/CTAN/' => 1,
      'http://sendinnsky.selfhost.co/tex-archive/' => 1,
      'http://vesta.informatik.rwth-aachen.de/ftp/pub/mirror/ctan/' => 1,
      'https://ctan.ebinger.cc/tex-archive/' => 1,
      'https://ctan.joethei.xyz/' => 1,
      'https://ctan.mc1.root.project-creative.net/' => 1,
      'https://ctan.mirror.norbert-ruehl.de/' => 1,
      'https://ctan.net/' => 1,
      'https://ctan.space-pro.be/tex-archive/' => 1,
      'https://de.mirrors.cicku.me/ctan/' => 1,
      'https://ftp.agdsn.de/pub/mirrors/latex/dante/' => 1,
      'https://ftp.fau.de/ctan/' => 1,
      'https://ftp.gwdg.de/pub/ctan/' => 1,
      'https://ftp.rrze.uni-erlangen.de/ctan/' => 1,
      'https://ftp.rrzn.uni-hannover.de/pub/mirror/tex-archive/' => 1,
      'https://ftp.tu-chemnitz.de/pub/tex/' => 1,
      'https://markov.htwsaar.de/tex-archive/' => 1,
      'https://mirror.clientvps.com/CTAN/' => 1,
      'https://mirror.dogado.de/tex-archive/' => 1,
      'https://mirror.funkfreundelandshut.de/latex/' => 1,
      'https://mirror.physik.tu-berlin.de/pub/CTAN/' => 1,
    },
    'Greece' => {
      'http://ftp.ntua.gr/mirror/ctan/' => 1,
      'https://fosszone.csd.auth.gr/CTAN/' => 1,
      'https://ftp.cc.uoc.gr/mirrors/CTAN/' => 1,
    },
    'Hungary' => {
      'https://mirror.szerverem.hu/ctan/' => 1,
    },
    'Italy' => {
      'https://ctan.mirror.garr.it/mirrors/ctan/' => 1,
    },
    'Netherlands' => {
      'https://ftp.snt.utwente.nl/pub/software/tex/' => 1,
      'https://mirror.koddos.net/CTAN/' => 1,
      'https://mirror.lyrahosting.com/CTAN/' => 1,
    },
    'Norway' => {
      'https://ctan.uib.no/' => 1,
      'https://ftp.fagskolen.gjovik.no/pub/tex-archive/' => 1,
    },
    'Poland' => {
      'https://ctan.gust.org.pl/tex-archive/' => 1,
      'https://polish-mirror.evolution-host.com/ctan/' => 1,
      'https://sunsite.icm.edu.pl/pub/CTAN/' => 1,
    },
    'Portugal' => {
      'https://ftp.eq.uc.pt/software/TeX/' => 1,
      'https://mirrors.up.pt/pub/CTAN/' => 1,
    },
    'Romania' => {
      'https://mirrors.nxthost.com/ctan/' => 1,
    },
    'Russia' => {
      'https://ctan.altspu.ru/' => 1,
      'https://mirror.macomnet.net/pub/CTAN/' => 1,
      'https://mirror.truenetwork.ru/CTAN/' => 1,
    },
    'Spain' => {
      'https://ctan.fisiquimicamente.com/' => 1,
      'https://ctan.javinator9889.com/' => 1,
      'https://osl.ugr.es/CTAN/' => 1,
    },
    'Sweden' => {
      'https://ftp.acc.umu.se/mirror/CTAN/' => 1,
      'https://ftpmirror1.infania.net/mirror/CTAN/' => 1,
    },
    'Switzerland' => {
      'https://mirror.foobar.to/CTAN/' => 1,
      'https://mirror.init7.net/ctan/' => 1,
    },
    'United Kingdom' => {
      'https://anorien.csc.warwick.ac.uk/mirrors/CTAN/' => 1,
      'https://eu.mirrors.cicku.me/ctan/' => 1,
      'https://www-uxsup.csx.cam.ac.uk/pub/tex-archive/' => 1,
    },
  },
  'North America' => {
    'Canada' => {
      'https://ca.mirrors.cicku.me/ctan/' => 1,
      'https://ctan.mirror.globo.tech/' => 1,
      'https://ctan.mirror.rafal.ca/' => 1,
      'https://mirror.csclub.uwaterloo.ca/CTAN/' => 1,
      'https://mirror.its.dal.ca/ctan/' => 1,
      'https://mirror.quantum5.ca/CTAN/' => 1,
      'https://muug.ca/mirror/ctan/' => 1,
    },
    'Costa Rica' => {
      'https://mirrors.ucr.ac.cr/CTAN/' => 1,
    },
    'USA' => {
      'http://mirrors.ibiblio.org/pub/mirrors/CTAN/' => 1,
      'https://ctan.math.illinois.edu/' => 1,
      'https://ctan.math.utah.edu/ctan/tex-archive/' => 1,
      'https://ctan.math.washington.edu/tex-archive/' => 1,
      'https://ctan.mirrors.hoobly.com/' => 1,
      'https://mirror.las.iastate.edu/tex-archive/' => 1,
      'https://mirror.math.princeton.edu/pub/CTAN/' => 1,
      'https://mirror.mwt.me/ctan/' => 1,
      'https://mirrors.mit.edu/CTAN/' => 1,
      'https://mirrors.rit.edu/CTAN/' => 1,
      'https://us.mirrors.cicku.me/ctan/' => 1,
    },
  },
  'Oceania' => {
    'Australia' => {
      'https://au.mirrors.cicku.me/ctan/' => 1,
      'https://mirror.aarnet.edu.au/pub/CTAN/' => 1,
      'https://mirror.cse.unsw.edu.au/pub/CTAN/' => 1,
    },
  },
  'South America' => {
    'Brazil' => {
      'https://linorg.usp.br/CTAN/' => 1,
    },
    'Chile' => {
      'https://ctan.dcc.uchile.cl/' => 1,
    },
  },
};












1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/installer/ctan-mirrors.pl@installer/ctan-mirrors.pl
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/mktexlsr.pl@mktexlsr.pl
"mktexlsr.pl" => <<'__EOI__',



use strict;
$^W = 1;


package mktexlsr;

my $ismain;

BEGIN {
  $^W = 1;
  $ismain = (__FILE__ eq $0);
}

my $svnid = '$Id: mktexlsr.pl 62699 2022-03-14 09:53:53Z siepo $';
my $lastchdate = '$Date: 2022-03-14 10:53:53 +0100 (Mon, 14 Mar 2022) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 62699 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "revision $svnrev ($lastchdate)";

use Getopt::Long;
use File::Basename;
use Pod::Usage;

my $opt_dryrun = 0;
my $opt_help   = 0;
my $opt_verbose = (-t STDIN); # test whether connected to a terminal
my $opt_version = 0;
my $opt_output;
my $opt_sort = 0;   # for debugging sort output
my $opt_follow = win32() ? 0 : 1; # follow links - check whether they are dirs or not

(my $prg = basename($0)) =~ s/\.pl$//;

my $lsrmagic = 
  '% ls-R -- filename database for kpathsea; do not change this line.';
my $oldlsrmagic = 
  '% ls-R -- maintained by MakeTeXls-R; do not change this line.';


&main() if $ismain;




package TeX::LSR;

use Cwd;
use File::Spec::Functions;
use File::Find;


sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    root => $params{'root'},
    filename => '',           # to accomodated both ls-r and ls-R
    is_loaded => 0,
    tree => { }
  };
  bless $self, $class;
  return $self;
}


sub loadtree {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});

  my $tree;
  build_tree($tree, $self->{'root'});
  $self->{'tree'} = $tree->{$self->{'root'}};
  $self->{'is_loaded'} = 1;
  return 1;

    sub build_tree {
      my $node = $_[0] = {};
      my @s;
      File::Find::find( { follow_skip => 2, follow_fast => $opt_follow, wanted => sub {
        $node = (pop @s)->[1] while (@s && $File::Find::dir ne $s[-1][0]);
        return if ($_ eq ".git");
        return if ($_ eq ".svn");
        return if ($_ eq ".hg");
        return if ($_ eq ".bzr");
        return if ($_ eq "CVS");
        return $node->{$_} = 1 if (! -d);
        push (@s, [ $File::Find::name, $node ]);
        $node = $node->{$_} = {};
      }}, $_[1]);
      $_[0]{$_[1]} = delete $_[0]{'.'};
    }
}



sub setup_filename {
  my $self = shift;
  if (!$self->{'filename'}) {
    if (-r $self->{'root'} . "/ls-R") {
      $self->{'filename'} = 'ls-R';
    } elsif (-r $self->{'root'} . "/ls-r") {
      $self->{'filename'} = 'ls-r';
    } else {
      $self->{'filename'} = 'ls-R';
    }
  }
  return 1;
}




sub load {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});
  $self->setup_filename();
  if (-r $self->{'filename'}) {
    return $self->loadfile();
  } else {
    return $self->loadtree();
  }
}


sub loadfile {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});

  $self->setup_filename();
  my $lsrfile = catfile($self->{'root'}, $self->{'filename'});
  return 0 if (! -r $lsrfile);

  open (LSR, "<", $lsrfile)
    || die "$prg: readable but not openable $lsrfile??: $!";

  chomp (my $fl = <LSR>);
  if (($fl eq $lsrmagic) || ($fl eq $oldlsrmagic)) {
    my %tree;
    my $t;
    for my $l (<LSR>) {
      chomp($l);
      next if ($l =~ m!^\s*$!);
      next if ($l =~ m!^\./:!);
      if ($l =~ m!^(.*):!) {
        $t = \%tree;
        my @a = split(/\//, $1);
        for (@a) {
          $t->{$_} = {} if (!defined($t->{$_}) || ($t->{$_} == 1));
          $t = $t->{$_};
        }
      } else {
        $t->{$l} = 1;
      }
    }
    $self->{'tree'} = $tree{'.'};
  }
  close(LSR);
  $self->{'is_loaded'} = 1;
  return 1;
}



sub write {
  my $self = shift;
  my %params = @_;
  my $fn;
  my $dosort = 0;
  $fn = $params{'filename'} if $params{'filename'};
  $dosort = $params{'sort'};
  if (!defined($self->{'root'})) {
    warn "TeX::LSR: root undefined, cannot write.\n";
    return 0;
  }
  if ($self->{'is_loaded'} == 0) {
    warn "TeX::LSR: tree not loaded, cannot write: $self->{root}\n";
    return 0;
  }
  if (!defined($fn)) {
    $self->setup_filename();
    $fn = catfile($self->{'root'}, $self->{'filename'});
  }
  if (-e $fn && ! -w $fn) {
    warn "TeX::LSR: ls-R file not writable, skipping: $fn\n";
    return 0;
  }
  open (LSR, ">$fn") || die "TeX::LSR writable but cannot open??; $!";
  print LSR "$lsrmagic\n\n";
  print LSR "./:\n";  # hardwired ./ for top-level files
  do_entry($self->{'tree'}, ".", $dosort);
  close LSR;
  return 1;
  
    sub do_entry {
      my ($t, $n, $sortit) = @_;
      print LSR "$n:\n";
      my @sd;
      for my $st ($sortit ? sort(keys %$t) : keys %$t) {
        push (@sd, $st) if (ref($t->{$st}) eq 'HASH');
        print LSR "$st\n";
      }
      print LSR "\n";
      for my $st ($sortit ? sort @sd : @sd) {
        do_entry($t->{$st}, "$n/$st", $sortit);
      }
    }
}


sub addfiles {
  my ($self, @files) = @_;
  if ($self->{'is_loaded'} == 0) {
    warn "TeX::LSR: tree not loaded, cannot add files: $self->{root}\n";
    return 0;
  }

  for my $f (@files) {
    if (file_name_is_absolute($f)) {
      my $cf = canonpath($f);
      my $cr = canonpath($self->root);
      if ($cf =~ m/^$cr([\\\/])?(.*)$/) {
        $f = $2;
      } else {
        warn("File $f does not reside in $self->root.");
        return 0;
      }
    }
    my $t = $self->{'tree'};
    my @a = split(/[\\\/]/, $f);
    my $fn = pop @a;
    for (@a) {
      $t->{$_} = {} if (!defined($t->{$_}) || ($t->{$_} == 1));
      $t = $t->{$_};
    }
    $t->{$fn} = 1;
  }
  return 1;
}






package TeX::Update;


sub new {
  my $class = shift;
  my $self = {
    files => {},
    mustexist => 0,
  };
  bless $self, $class;
  return $self;
}


sub add {
  my $self = shift;
  foreach my $file (@_) {
    $file =~ s|\\|/|g;
    $self->{'files'}{$file} = 1;
  }
  return 1;
}


sub reset {
  my $self = shift;
  $self->{'files'} = {};
  return 1;
}


sub mustexist {
  my $self = shift;
  if (@_) { $self->{'mustexist'} = shift }
  return $self->{'mustexist'};
}


sub exec {
  my $self = shift;
  if ($self->{'mustexist'}) {
    for my $f (keys %{$self->{'files'}}) {
      die "File \'$f\' doesn't exist.\n" if (! -f $f);
    }
  }
  my @texmfdbs = mktexlsr::find_default_lsr_trees();
  my %dbs;
  for my $p (keys %{$self->{'files'}}) {
    for my $db (@texmfdbs) {
      $db =~ s|/$||;
      $db = lc($db) if mktexlsr::win32();
      my $used_path = mktexlsr::win32() ? lc($p) : $p;
      if ( substr($used_path, 0, length("$db/")) eq "$db/" ) {
        my $filepart = substr($used_path, length("$db/"));
        $dbs{$db}{$filepart} = 1;
        last; # of the db loops!
      }
    }
  }
  for my $db (keys %dbs) {
    if (! -d $db) {
      if (! mktexlsr::mkdirhier($db) ) {
        die "Cannot create directory $db: $!";
      }
    }
    my $lsr = new TeX::LSR(root => $db);
    $lsr->load() || die "Cannot load ls-R in $db.";
    $lsr->addfiles(keys %{$dbs{$db}}) || die "Cannot add some file to $db.";
    $lsr->write() || die "Cannot write ls-R in $db.";
  }
  return 1;
}





package mktexlsr;

sub main {
  GetOptions("dry-run|n"      => \$opt_dryrun,
             "help|h"         => \$opt_help,
             "verbose!"       => \$opt_verbose,
             "quiet|q|silent" => sub { $opt_verbose = 0 },
             "sort"           => \$opt_sort,
             "output|o=s"     => \$opt_output,
             "follow!"        => \$opt_follow,
             "version|v"      => \$opt_version)
  || pod2usage(2);

  pod2usage(-verbose => 2, -exitval => 0) if $opt_help;

  if ($opt_version) {
    print version();
    exit (0);
  }

  if ($opt_output && $#ARGV != 0) {
    die "$prg: with --output, exactly one tree must be given: @ARGV\n";
  }

  for my $t (find_lsr_trees()) {
    my $lsr = new TeX::LSR(root => $t);
    print "$prg: Updating $t...\n" if $opt_verbose;
    if ($lsr->loadtree()) {
      if ($opt_dryrun) {
        print "$prg: Dry run, not writing files.\n" if $opt_dryrun;
      } elsif ($opt_output) {
        $lsr->write(filename => $opt_output, sort => $opt_sort);
      } else {
        $lsr->write(sort => $opt_sort);
      }
    } else {
      warn "$prg: cannot read files, skipping: $t\n";
    }
  }
  print "$prg: Done.\n" if $opt_verbose;
}

sub find_default_lsr_trees {
  my $delim = win32() ? ';' : ':';
  chomp( my $t = `kpsewhich -show-path=ls-R` );
  my @texmfdbs = split($delim, $t);
  return @texmfdbs;
}

sub find_lsr_trees {
  my %lsrs;
  my @candidates = @ARGV;
  if (!@candidates) {
    @candidates = find_default_lsr_trees();
  }
  for my $t (@candidates) {
    my $ret;
    eval {$ret = Cwd::abs_path($t);}; # eval needed for w32
    if ($ret) {
      $lsrs{$ret} = 1;
    } else {
    }
  }
  return sort(keys %lsrs);
}

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}


sub win32 {
  return ( ($^O =~ /^MSWin/i) ? 1 : 0 );
}

sub mkdirhier {
  my ($tree,$mode) = @_;

  return if (-d "$tree");
  my $subdir = "";
  $subdir = $& if ( win32() && ($tree =~ s!^//[^/]+/!!) );

  my @dirs = split (/\//, $tree);
  for my $dir (@dirs) {
    $subdir .= "$dir/";
    if (! -d $subdir) {
      if (defined $mode) {
        mkdir ($subdir, $mode)
        || die "$0: mkdir($subdir,$mode) failed, goodbye: $!\n";
      } else {
        mkdir ($subdir) || die "$0: mkdir($subdir) failed, goodbye: $!\n";
      }
    }
  }
}


1;















1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/mktexlsr.pl@mktexlsr.pl
);
unshift @INC, sub {
my $module = $modules{$_[1]}
or return;
return \$module
};
}
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/fmtutil.pl

my $TEXMFROOT;

BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
#  unshift(@INC, "$TEXMFROOT/tlpkg", "$TEXMFROOT/texmf-dist/scripts/texlive");# PACKPERLMODULES
  require "mktexlsr.pl";
  TeX::Update->import();
}

my $svnid = '$Id: fmtutil.pl 68962 2023-11-24 23:01:43Z karl $';
my $lastchdate = '$Date: 2023-11-25 00:01:43 +0100 (Sat, 25 Nov 2023) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 68962 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use strict;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use File::Spec;
use Cwd;

use TeXLive::TLUtils qw(wndws);

require TeXLive::TLWinGoo if wndws();

my $FMT_NOTSELECTED = 0;
my $FMT_DISABLED    = 1;
my $FMT_FAILURE     = 2;
my $FMT_SUCCESS     = 3;
my $FMT_NOTAVAIL    = 4;

my $nul = (wndws() ? 'nul' : '/dev/null');
my $sep = (wndws() ? ';' : ':');

my @deferred_stderr;
my @deferred_stdout;

my $first_time_creation_in_usermode = 0;
my $first_time_usermode_warning = 1; # give lengthy warning if warranted?

my $DRYRUN = "";
my $STATUS_FH;

(our $prg = basename($0)) =~ s/\.pl$//;

TeXLive::TLUtils::prepend_own_path();

reset_root_home();

chomp(our $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(our $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(our $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(our $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(our $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(our $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

if (wndws()) {
  $TEXMFDIST = lc($TEXMFDIST);
  $TEXMFVAR = lc($TEXMFVAR);
  $TEXMFSYSVAR = lc($TEXMFSYSVAR);
  $TEXMFCONFIG = lc($TEXMFCONFIG);
  $TEXMFSYSCONFIG = lc($TEXMFSYSCONFIG);
  $TEXMFROOT = lc($TEXMFROOT);
  $TEXMFHOME = lc($TEXMFHOME);
}

our $texmfconfig = $TEXMFCONFIG;
our $texmfvar    = $TEXMFVAR;
our $alldata;

our %opts = ( quiet => 0 , strict => 1 );

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
  @cmdline_cmds,
  "version",
  "help|h",
  "edit",		# omitted from help to discourage use
  "_dumpdata",		# omitted from help, data structure dump for debugging
  );

my $updLSR;
my $mktexfmtMode = 0;
my $mktexfmtFirst = 1;

my $status = &main();
print_info("exiting with status $status\n");
exit $status;


sub main {
  if ($prg eq "mktexfmt") {
    $mktexfmtMode = 1;

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
    }
    if (@cmds > 1) {
      print_error("multiple commands found: @cmds\n"
                  . "Try $prg --help if you need it.\n");
      return 1;
    } elsif (@cmds == 0) {
      if ($opts{'refresh'}) {
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
  
  ($texmfconfig, $texmfvar)
    = TeXLive::TLUtils::setup_sys_user_mode($prg, \%opts,
                       $TEXMFCONFIG, $TEXMFSYSCONFIG, $TEXMFVAR, $TEXMFSYSVAR);
  
  if ($texmfvar eq $TEXMFSYSVAR) {
    $first_time_usermode_warning = 0;
  }

  determine_config_files("fmtutil.cnf");
  my $changes_config_file = $alldata->{'changes_config'};
  my $bakFile = $changes_config_file;
  $bakFile =~ s/\.cfg$/.bak/;
  my $changed = 0;

  read_fmtutil_files(@{$opts{'cnffile'}});

  unless ($opts{"nohash"}) {
    $updLSR = new TeX::Update;
    $updLSR->mustexist(0);
  }

  my $cmd;
  if ($opts{'edit'}) {
    if ($opts{"dry-run"}) {
      printf STDERR "No, are you joking, you want to edit with --dry-run?\n";
      return 1;
    }
    $cmd = 'edit';
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'};
    $editor ||= (&wndws ? "notepad" : "vi");
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
    print_error("missing command; try $prg --help if you need it.\n");
    return 1;
  }

  if ($STATUS_FH) {
    close($STATUS_FH)
    || print_error("cannot close $opts{'status-file'}: $!\n");
  }

  unless ($opts{'nohash'}) {
    print_info("updating ls-R files\n");
    $updLSR->exec() unless $opts{"dry-run"};
  }

  return 0;
}

sub dump_data {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
  $Data::Dumper::Indent = 1;
  print Data::Dumper::Dumper($alldata);
}

sub log_to_status {
  if ($STATUS_FH) {
    print $STATUS_FH "@_\n";
  }
}

sub callback_build_formats {
  my ($what, $whatarg) = @_;

  $whatarg = "" if ! defined $whatarg;

  my $tmpdir = "";
  if (! $opts{"dry-run"}) {
    if (wndws()) {
      my $foo;
      my $tmp_deflt = File::Spec->tmpdir;
      for my $i (1..5) {
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
        TeXLive::TLWinGoo::maybe_make_ro ($tmpdir);
      }
    } else {
      $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    }
  }
  $opts{'fmtdir'} ||= "$texmfvar/web2c";
  if (! $opts{"dry-run"}) {
    TeXLive::TLUtils::mkdirhier($opts{'fmtdir'}) if (! -d $opts{'fmtdir'});
    if (! -w $opts{'fmtdir'}) {
      print_error("format directory not writable: $opts{fmtdir}\n");
      exit 1;
    }
  }
  $opts{'fmtdir'} = Cwd::abs_path($opts{'fmtdir'});
  die "abs_path failed, strange: $!" if !$opts{'fmtdir'};
  print_info("writing formats under $opts{fmtdir}\n"); # report

  my $thisdir = cwd();
  $ENV{'KPSE_DOT'} = $thisdir;
  $ENV{'TEXINPUTS'} ||= "";
  $ENV{'TEXINPUTS'} = "$tmpdir$sep$ENV{TEXINPUTS}";
  $ENV{'TEXFORMATS'} ||= "";
  $ENV{'TEXFORMATS'} = "$tmpdir$sep$ENV{TEXFORMATS}";

  chdir($opts{"dry-run"} ? "/" : $tmpdir)
  || die "Cannot change to directory $tmpdir: $!";
  
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
  print_info("disabled formats: $disabled\n")        if ($disabled);
  print_info("successfully rebuilt formats: $suc\n") if ($suc);
  print_info("not selected formats: $nobuild\n")     if ($nobuild);
  print_info("not available formats: $notavail\n")   if ($notavail);
  print_info("failed to build: $err (@err)\n")       if ($err);
  print_info("total formats: $total\n");
  chdir($thisdir) || warn "chdir($thisdir) failed: $!";
  if (wndws()) {
    TeXLive::TLUtils::rmtree($tmpdir);
  }
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
  return $opts{"strict"} ? $err : 0;
}

sub select_and_rebuild_format {
  my ($fmt, $eng, $what, $whatarg) = @_;
  return $FMT_DISABLED
      if ($alldata->{'merged'}{$fmt}{$eng}{'status'} eq 'disabled');

  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);

  my $doit = 0;
  $doit = 1 if ($what eq 'all');
  $doit = 1 if ($what eq 'refresh' && -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'missing' && ! -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'byengine' && $eng eq $whatarg);
  $doit = 1 if ($what eq 'byfmt' && $fmt eq $whatarg);
  $doit = 0 if ($opts{'refresh'} && ! -r "$destdir/$fmtfile");
  if ($what eq 'byhyphen') {
    my $fmthyp = (split(/,/ , $alldata->{'merged'}{$fmt}{$eng}{'hyphen'}))[0];
    if ($fmthyp ne '-') {
      if ($whatarg =~ m!^/!) {
        chomp (my $fmthyplong = `kpsewhich -progname=$fmt -engine=$eng $fmthyp`) ;
        if ($fmthyplong) {
          $fmthyp = $fmthyplong;
        } else {
          chomp ($fmthyplong = `kpsewhich $fmthyp`) ;
          if ($fmthyplong) {
            $fmthyp = $fmthyplong;
          } else {
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
  return if ($opts{'fmtdir'} eq "$TEXMFVAR/web2c");
  my $saved_fmtdir = $opts{'fmtdir'};
  $opts{'fmtdir'} = "$TEXMFVAR/web2c";
  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);
  if (-r "$destdir/$fmtfile") {
    print_deferred_warning("you have a shadowing format dump in TEXMFVAR for $fmt/$eng!!!\n");
  }
  $opts{'fmtdir'} = $saved_fmtdir;
}
  


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
    $enginedir =~ s/-dev$//;
  }
  if ($opts{'no-engine-subdir'}) {
    $destdir = $opts{'fmtdir'};
  } else {
    $destdir = "$opts{'fmtdir'}/$enginedir";
  }
  return($kpsefmt, $destdir, $fmtfile, "$fmt.log");
}


sub rebuild_one_format {
  my ($fmt,$eng,$kpsefmt,$destdir,$fmtfile,$logfile) = @_;
  print_info("--- remaking $fmt with $eng\n");

  my $hyphen  = $alldata->{'merged'}{$fmt}{$eng}{'hyphen'};
  my $addargs = $alldata->{'merged'}{$fmt}{$eng}{'args'};

  my $jobswitch = "-jobname=$fmt";
  my $prgswitch = "-progname=" ;
  my $recorderswitch = ($opts{'recorder'} ? "-recorder" : "");
  my $pool;
  my $tcx = "";
  my $tcxflag = "";
  my $localpool = 0;
  my $texargs;

  unlink glob "*.pool";

  my $inifile = $addargs;
  $inifile = (split(' ', $addargs))[-1];
  $inifile =~ s/^\*//;

  if ($eng =~ /^e?uptex$/
      && $fmt =~ /^e?p/
      && $addargs !~ /-kanji-internal=/) {
    my $kanji = wndws() ? "sjis" : "euc";
    $addargs = "-kanji-internal=$kanji " . $addargs;
  }

  if ($fmt eq "metafun")       { $prgswitch .= "mpost"; }
  elsif ($fmt eq "mptopdf")    { $prgswitch .= "context"; }
  elsif ($fmt =~ m/^cont-..$/) { $prgswitch .= "context"; }
  else                         { $prgswitch .= $fmt; }

  if (system("kpsewhich -progname=$fmt -format=$kpsefmt $inifile >$nul 2>&1") != 0) {
    print_deferred_warning("inifile $inifile for $fmt/$eng not found.\n");
    return $FMT_FAILURE;
  }

  if ($addargs =~ /-progname=/) {
    $prgswitch = '';
  }

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

  $cmdline .= " >&2" if $mktexfmtMode;
  $cmdline .= " <$nul";
  my $retval = system("$DRYRUN$cmdline");

  if ($retval != 0) {
    $retval /= 256 if ($retval > 0);
    print_deferred_error("running \`$cmdline' return status: $retval\n");
  }

  TeXLive::TLUtils::mkdirhier($destdir) if ! $opts{"dry-run"};
  if ($opts{"dry-run"}) {
    print_info("would copy log file to: $destdir/$logfile\n");
  } else {
    if (open(my $fd, ">>", $logfile)) {
      print $fd "# actual command line used during this run\n# $cmdline\n";
      close($fd);
    } else {
      print_deferred_error("cannot append cmdline to log file");
    }
    if (TeXLive::TLUtils::copy("-f", $logfile, "$destdir/$logfile")) {
      print_info("log file copied to: $destdir/$logfile\n");
    } else {
      print_deferred_error("failed to copy log $logfile to: $destdir\n");
    }
  }

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

  if ($opts{"dry-run"}) {
    print_info("dry run, so returning success: $fmtfile\n");
    return $FMT_SUCCESS;
  }

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
    my $recfile = $fmt . ($fmt =~ m/^(aleph|lamed)$/ ? ".ofl" : ".fls");
    if (! TeXLive::TLUtils::copy("-f", $recfile, "$destdir/$recfile")) {
      print_deferred_error("cannot copy recorder $recfile to: $destdir\n");
    }
  }

  my $destfile = "$destdir/$fmtfile";
  my $possibly_warn = ($opts{'user'} && ! -r $destfile);
  if (TeXLive::TLUtils::copy("-f", $fmtfile, $destfile)) {
    print_info("$destfile installed.\n");
    $first_time_creation_in_usermode = $possibly_warn;

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
      print_verbose("removing partial file after copy failure: $destfile\n");
      unlink($destfile)
        || print_deferred_error("unlink($destfile) failed: $!\n");
    }
    return $FMT_FAILURE;
  }

  print_deferred_error("we should not be here! $fmt/$eng\n");
  return $FMT_FAILURE;
}


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
      return save_fmtutil($tc);
    }
  } else {
    print_error("enable_disable_format_engine: unknown mode $mode\n");
    exit 1;
  }
}  

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
  @lines = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @lines;
  print "List of all formats:\n";
  print @lines;
  
  return @lines == 0; # only return failure if no formats.
}


sub read_fmtutil_files {
  my (@l) = @_;
  for my $l (@l) { read_fmtutil_file($l); }
  my $cc = $alldata->{'changes_config'};
  if ((! -r $cc) || (!$alldata->{'fmtutil'}{$cc}{'lines'}) ) {
    $alldata->{'fmtutil'}{$cc}{'lines'} = [ ];
  }
  $alldata->{'order'} = \@l;
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

sub read_fmtutil_file {
  my $fn = shift;
  open(FN, "<$fn") || die "Cannot read $fn: $!";
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





sub determine_config_files {
  my $fn = shift;

  my $changes_config_file;

  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
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
      push @tmp, (wndws() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all $fn`;
    chomp(@all_files);
    my @used_files;
    for my $f (@all_files) {
      push @used_files, (wndws() ? lc($f) : $f);
    }
    my $TEXMFLOCALVAR;
    my @TEXMFLOCAL;
    if (wndws()) {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path=\$TEXMFLOCAL`);
      @TEXMFLOCAL = map { lc } split(/;/ , $TEXMFLOCALVAR);
    } else {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path='\$TEXMFLOCAL'`);
      @TEXMFLOCAL = split /:/ , $TEXMFLOCALVAR;
    }
    my @tmlused;
    for my $tml (@TEXMFLOCAL) {
      my $TMLabs = Cwd::abs_path($tml);
      next if (!$TMLabs);
      if (-r "$TMLabs/web2c/$fn") {
        push @tmlused, "$TMLabs/web2c/$fn";
      }
    }
    @{$opts{'cnffile'}} = @used_files;
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
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;
}



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
        $updLSR->add($fn);
        $updLSR->exec();
        $updLSR->reset();
      }
    }
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



sub reset_root_home {
  if (!wndws() && ($> == 0)) {  # $> is effective uid
    my $envhome = $ENV{'HOME'};
    if (defined($envhome) && (-d $envhome)) {
      if ($envhome =~ m,^(/|/root|/var/root)/*$,) {
        return;
      }
      my (undef,undef,undef,undef,undef,undef,undef,$roothome) = getpwuid(0);
      if (defined($roothome)) {
        if ($envhome ne $roothome) {
          print_warning("resetting \$HOME value (was $envhome) to root's "
            . "actual home ($roothome).\n");
          $ENV{'HOME'} = $roothome;
        } else {
        }
      } else { 
        print_warning("home of root not defined, strange!\n");
      }
    }
  }
}

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

Commands (exactly one must be specified):
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

Environment:

  This script runs TeX and Metafont to generate the fmt/base file, and
  thus all normal environment variables and search path rules for TeX/MF
  apply.

Report bugs to: tex-live\@tug.org
TeX Live home page: <https://tug.org/texlive/>
EOF
;
  print &version();
  print $usage;
  exit 0; # no final print_info
}













# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/fmtutil.pl

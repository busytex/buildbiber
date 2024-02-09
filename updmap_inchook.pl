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
);
unshift @INC, sub {
my $module = $modules{$_[1]}
or return;
return \$module
};
}
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/updmap.pl

my $svnid = '$Id: updmap.pl 65932 2023-02-19 20:49:48Z siepo $';

my $TEXMFROOT;
BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
#  unshift(@INC, "$TEXMFROOT/tlpkg");# PACKPERLMODULES
}

my $lastchdate = '$Date: 2023-02-19 21:49:48 +0100 (Sun, 19 Feb 2023) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 65932 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use strict;
use TeXLive::TLUtils qw(mkdirhier mktexupd wndws basename dirname 
  sort_uniq member touch);

(my $prg = basename($0)) =~ s/\.pl$//;

reset_root_home();

chomp(my $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(my $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(my $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(my $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

if (wndws()) {
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
  "showoptions=s@",
  "showoption=s@",
  "syncwithtrees",
  "version",
  "help|h",
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

  my $changes_config_file;

  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
        die "$prg: Config file \"$f\" not found.";
      }
      push @tmp, (wndws() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all updmap.cfg`;
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
      if (-r "$TMLabs/web2c/updmap.cfg") {
        push @tmlused, "$TMLabs/web2c/updmap.cfg";
      }
      if (-r "$TMLabs/web2c/updmap-local.cfg") {
        print_warning("=============================\n");
        print_warning("Old configuration file\n  $TMLabs/web2c/updmap-local.cfg\n");
        print_warning("found! This file is *not* evaluated anymore, please move the information\n");
        print_warning("to the file $TMLabs/updmap.cfg!\n");
        print_warning("=============================\n");
      }
    }
    @{$opts{'cnffile'}} = @used_files;
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
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;

  read_updmap_files(@{$opts{'cnffile'}});

  if ($opts{'_dump'}) {
    merge_settings_replace_kanji();
    read_map_files();
    require Data::Dumper;
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
    }
    exit 0;
  }

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
    $cmd = 'edit';
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'};
    $editor ||= (wndws() ? "notepad" : "vi");
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
      my @aaa = @{$alldata->{'order'}};
      unshift @aaa, $changes_config_file;
      $alldata->{'order'} = [ @aaa ];
      setupOutputDir("dvips");
      setupOutputDir("pdftex");
      setupOutputDir("dvipdfmx");
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
      mkMaps();
    }
    unlink ($bakFile) if (-r $bakFile);
  }

  if (!$opts{'nohash'}) {
    my $not = $opts{"dry-run"} ? " not (-n)" : "";
    print "$prg:$not updating ls-R files.\n" if !$opts{'quiet'};
    $updLSR->{exec}() unless $opts{"dry-run"};
  }

  return 0;
}

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

sub writeLines {
  my ($fname, @lines) = @_;
  return if $opts{"dry-run"};
  map { ($_ !~ m/\n$/ ? s/$/\n/ : $_ ) } @lines;
  open FILE, ">$fname" or die "$prg: can't write lines to $fname: $!";
  print FILE @lines;
  close FILE;
}

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

sub SymlinkOrCopy {
  my ($dir, $src, $dest) = @_;
  return ($src, $dest) if $opts{"dry-run"};
  if (wndws() || $opts{'copy'}) {  # always copy
    &copyFile("$dir/$src", "$dir/$dest");
  } else { # symlink if supported by fs, copy otherwise
    system("cd \"$dir\" && ln -s $src $dest 2>/dev/null || "
           . "cp -p \"$dir/$src\" \"$dir/$dest\"");
  }
  return ($dest, $src);
}


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

sub cidx2dvips {
  my ($s) = @_;
  my %fname_psname = (
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
    'ipaexg' => 'IPAexGothic',
    'ipaexm' => 'IPAexMincho',
    'ipag'   => 'IPAGothic',
    'ipam'   => 'IPAMincho',
    );
  my @d;
  foreach (@$s) {
    if (m/^\s*(%.*)?$/) {
      push(@d, $_);
      next;
    }
    chomp;
    my $l = $_;
    my $psname;
    my $fbname;
    if ($_ =~ m/%!DVIPSFB\s\s*([0-9A-Za-z-_!,][0-9A-Za-z-_!,]*)/) {
      $fbname = $1;
      $fbname =~ s/^!//;
      $fbname =~ s/,Bold//;
    }
    if ($_ =~ m/%!PS\s\s*([0-9A-Za-z-_][0-9A-Za-z-_]*)/) {
      $psname = $1;
    }
    s/[^0-9A-Za-z-_]*%.*$//;
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
    s!/A[JGCK]1[0-6]!!;
    next if (m![\@/,]!);
    s/\s\s*/ /g;
    next if (!defined($fbname) && (m!^[0-9A-Za-z-_][0-9A-Za-z-_]* unicode !));
    if ($_ !~ m/([^ ][^ ]*) ([^ ][^ ]*) ([^ ][^ ]*)( (.*))?$/) {
      print_warning("cidx2dvips warning: Cannot translate font line:\n==> $l\n");
      print_warning("Current translation status: ==>$_==\n");
      next;
    }
    my $tfmname = $1;
    my $cid = $2;
    my $fname = $3;
    my $opts = (defined($5) ? " $5" : "");
    $fname =~ s/\.[Oo][Tt][Ff]//;
    $fname =~ s/\.[Tt][Tt][FfCc]//;
    $fname =~ s/^!//;
    $fname =~ s/:[0-9]+://;
    $opts =~ s/^\s+//;
    $opts =~ s/-e ([.0-9-][.0-9-]*)/ "$1 ExtendFont"/;
    if (m/-s ([.0-9-][.0-9-]*)/) {
      if ($italicmax > 0) {
        print_warning("cidx2dvips warning: Double slant specified via Italic and -s:\n==> $l\n==> Using only the biggest slant value.\n");
      }
      $italicmax = $1 if ($1 > $italicmax);
      $opts =~ s/-s ([.0-9-][.0-9-]*)//;
    }
    if ($italicmax != 0) {
      $opts .= " \"$italicmax SlantFont\"";
    }
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

  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));


  setupOutputDir("pxdvi") if $pxdviUse eq "true";

  my $not = $opts{"dry-run"} ? " not (-n)" : "";
  print_and_log ("\n$prg is$not creating new map files"
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

  print_and_log ("\nFiles$not generated:\n");
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
    if ($opts{'sys'}) {
      print_and_log ("
Perhaps you have run updmap-user in the past, but are running updmap-sys
now.  Once you run updmap-user the first time, you have to keep using it,
or else remove the personal configuration files it creates (the ones
listed below).
");
    }
    for my $f (sort keys %mismatch) {
      print_and_log (" $f: $mismatch{$f}\n");
    }
    print_and_log("(Run $prg --help for full documentation of updmap.)\n");
  }

  close LOG unless $opts{'dry-run'};
  print "\nTranscript$not written on: $logfile\n" if !$opts{'quiet'};
}


sub locateMap {
  my $map = shift;
  my $ret = `kpsewhich --format=map $map`;
  chomp($ret);
  return $ret;
}

sub processOptions {
  my $oldconfig = Getopt::Long::Configure(qw(pass_through));
  our @setoptions;
  our @enable;
  sub read_one_or_two {
    my ($opt, $val) = @_;
    our @setoptions;
    our @enable;
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


  GetOptions(\%opts, @cmdline_options) or 
    die "Try \"$prg --help\" for more information.\n";
}

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
      my ($type, $map) = split ('=', $w);
      $type =~ s/map$/Map/;
      $type = ucfirst($type);
      die "$prg: map names cannot contain /: $map\n" if ($map =~ m{/});
      enable_map($tc, $type, $map);
    } else {
      disable_map($tc, $w);
    }
  }
  return save_updmap($tc);
}

sub enable_map {
  my ($tc, $type, $map) = @_;

  die "$prg: invalid mapType $type" if ($type !~ m/^(Map|MixedMap|KanjiMap)$/);

  if (defined($alldata->{'updmap'}{$tc}{'maps'}{$map})) {
    if (($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "enabled") &&
        ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} eq $type)) {
      return;
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = $type;
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
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
    if ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "disabled") {
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
    if (!defined($alldata->{'maps'}{$map})) {
      print_warning("map file not present, nothing to disable: $map\n");
      return;
    }
    my $orig = $alldata->{'maps'}{$map}{'origin'};
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = 
      $alldata->{'updmap'}{$orig}{'maps'}{$map}{'type'};
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'line'} = -1;
    $alldata->{'maps'}{$map}{'origin'} = $tc;
    $alldata->{'maps'}{$map}{'status'} = "disabled";
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  }
}


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
      $updLSR->{add}($fn);
      $updLSR->{exec}();
      $updLSR->{reset}();
    }
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

sub setOption {
  my ($opt, $val) = @_;

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

  return if $opt eq "dvipdfmDownloadBase14";
  
  my $tc = $alldata->{'changes_config'};

  die "$prg: top config file $tc has not been read."
    if (!defined($alldata->{'updmap'}{$tc}));

  if (defined($alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'})) {
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

sub normalizeLines {
  my @lines = @_;
  my %count = ();

  map {$_ =~ s/\s+/ /gx } @lines;
  @lines = grep { $_ !~ m/^\s*$/x } @lines;
  map { $_ =~ s/\s$//x ;
        $_ =~ s/\s*\"\s*/ \" /gx;
        $_ =~ s/\" ([^\"]*) \"/\"$1\"/gx;
      } @lines;

  @lines = grep {++$count{$_} < 2 } (@lines);

  return @lines;
}



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
  my $cc = $alldata->{'changes_config'};
  if (! -r $cc) {
    $alldata->{'updmap'}{$cc}{'lines'} = [ ];
  }
  $alldata->{'order'} = \@l;
}

sub merge_settings_replace_kanji {
  my @l = @{$alldata->{'order'}};
  %{$alldata->{'merged'}} = ();
  for my $l (reverse @l) {
    if (defined($alldata->{'updmap'}{$l}{'setting'})) {
      for my $k (keys %{$alldata->{'updmap'}{$l}{'setting'}}) {
        $alldata->{'merged'}{'setting'}{$k}{'val'} = $alldata->{'updmap'}{$l}{'setting'}{$k}{'val'};
        $alldata->{'merged'}{'setting'}{$k}{'origin'} = $l;
      }
    }
  }
  my ($jaEmbed, $jaEmbed_origin) = get_cfg('jaEmbed');
  my ($jaVariant, $jaVariant_origin) = get_cfg('jaVariant');
  my ($scEmbed, $scEmbed_origin) = get_cfg('scEmbed');
  my ($tcEmbed, $tcEmbed_origin) = get_cfg('tcEmbed');
  my ($koEmbed, $koEmbed_origin) = get_cfg('koEmbed');

  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));

  for my $l (@l) {
    for my $m (keys %{$alldata->{'updmap'}{$l}{'maps'}}) {
      my $newm = $m;
      $newm =~ s/\@jaEmbed@/$jaEmbed/;
      $newm =~ s/\@jaVariant@/$jaVariant/;
      $newm =~ s/\@scEmbed@/$scEmbed/;
      $newm =~ s/\@tcEmbed@/$tcEmbed/;
      $newm =~ s/\@koEmbed@/$koEmbed/;
      $newm =~ s/\@kanjiEmbed@/$jaEmbed/;
      $newm =~ s/\@kanjiVariant@/$jaVariant/;
      if ($newm ne $m) {
        if (locateMap($newm)) {
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
        delete $alldata->{'updmap'}{$l}{'maps'}{$m};
      }
    }
  }
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
    s/([^#].*)#.*$/$1/;
    my ($a, $b, @rest) = split ' ';
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
  my @maps;
  for my $f (@l) {
    next if !defined($alldata->{'updmap'}{$f}{'maps'});
    for my $m (keys %{$alldata->{'updmap'}{$f}{'maps'}}) {
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
    my $dirsep = ($map =~ m!^/!) ? "" : "/";
    my ($ff) = grep /$dirsep\Q$map\E(\.map)?$/, @fullpath;
    if ($ff) {
      $alldata->{'maps'}{$map}{'fullpath'} = $ff;
    } else {
      push @missing, $map;
    }
  }
  return @missing if $quick;

  for my $m (qw/dvips35.map pdftex35.map ps2pk35.map/) {
    my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
    my @ff = ();
    for my $font (keys %$ret) {
      $alldata->{'fonts'}{$font}{'origin'} = $m;
      $alldata->{'maps'}{$m}{'fonts'}{$font} = $ret->{$font};
    }
  }
  for my $f (reverse @l) {
    my @maps = keys %{$alldata->{'updmap'}{$f}{'maps'}};
    for my $m (@maps) {
      next if defined($alldata->{'maps'}{$m}{'fonts'});
      next if ($alldata->{'maps'}{$m}{'status'} eq 'disabled');
      if (!defined($alldata->{'maps'}{$m}{'fullpath'})) {
        next;
      }
      my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
      if (defined($ret)) {
        for my $font (keys %$ret) {
          if (defined($alldata->{'fonts'}{$font})) {
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

sub merge_data {
  my @l = @{$alldata->{'order'}};
  for my $m (keys %{$alldata->{'maps'}}) {
    my $origin = $alldata->{'maps'}{$m}{'origin'};
    next if !defined($origin);
    next if ($origin eq 'builtin');
    next if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'} eq "disabled");
    for my $f (keys %{$alldata->{'maps'}{$m}{'fonts'}}) {
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

sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opts{'quiet'}) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}



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













# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/texlive-source/f744029b0fc73c79a655443fa744f4d281cb23b8/texk/texlive/linked_scripts/texlive/updmap.pl

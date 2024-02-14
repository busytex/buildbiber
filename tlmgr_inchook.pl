BEGIN {
my %modules = (
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfFile.pm@TeXLive/TLConfFile.pm
"TeXLive/TLConfFile.pm" => <<'__EOI__',

use strict;
use warnings;

package TeXLive::TLConfFile;

use TeXLive::TLUtils;

my $svnrev = '$Revision$';
my $_modulerevision;
if ($svnrev =~ m/: ([0-9]+) /) {
  $_modulerevision = $1;
} else {
  $_modulerevision = "unknown";
}
sub module_revision {
  return $_modulerevision;
}

sub new
{
  my $class = shift;
  my ($fn, $cc, $sep, $typ) = @_;
  my $self = () ;
  $self->{'file'} = $fn;
  $self->{'cc'} = $cc;
  $self->{'sep'} = $sep;
  if (defined($typ)) {
    if ($typ eq 'last-win' || $typ eq 'first-win' || $typ eq 'multiple') {
      $self->{'type'} = $typ;
    } else {
      printf STDERR "Unknown type of conffile: $typ\n";
      printf STDERR "Should be one of: last-win first-win multiple\n";
      return;
    }
  } else {
    $self->{'type'} = 'last-win';
  }
  bless $self, $class;
  return $self->reparse;
}

sub reparse
{
  my $self = shift;
  my %config = parse_config_file($self->file, $self->cc, $self->sep);
  my $lastkey = undef;
  my $lastkeyline = undef;
  $self->{'keyvalue'} = ();
  $self->{'confdata'} = \%config;
  $self->{'changed'} = 0;
  my $in_postcomment = 0;
  for my $i (0..$config{'lines'}) {
    if ($config{$i}{'type'} eq 'comment') {
      $lastkey = undef;
      $lastkeyline = undef;
      $in_postcomment = 0;
    } elsif ($config{$i}{'type'} eq 'data') {
      $lastkey = $config{$i}{'key'};
      $lastkeyline = $i;
      $self->{'keyvalue'}{$lastkey}{$i}{'value'} = $config{$i}{'value'};
      $self->{'keyvalue'}{$lastkey}{$i}{'status'} = 'unchanged';
      if (defined($config{$i}{'postcomment'})) {
        $in_postcomment = 1;
      } else {
        $in_postcomment = 0;
      }
    } elsif ($config{$i}{'type'} eq 'empty') {
      $lastkey = undef;
      $lastkeyline = undef;
      $in_postcomment = 0;
    } elsif ($config{$i}{'type'} eq 'continuation') {
      if (defined($lastkey)) {
        if (!$in_postcomment) {
          $self->{'keyvalue'}{$lastkey}{$lastkeyline}{'value'} .= 
            $config{$i}{'value'};
        }
      }
    } else {
      print "-- UNKNOWN TYPE\n";
    }
  }
  return $self;
}

sub file
{
  my $self = shift;
  return($self->{'file'});
}
sub cc
{
  my $self = shift;
  return($self->{'cc'});
}
sub sep
{
  my $self = shift;
  return($self->{'sep'});
}
sub type
{
  my $self = shift;
  return($self->{'type'});
}

sub key_present
{
  my ($self, $key) = @_;
  return defined($self->{'keyvalue'}{$key});
}

sub keys
{
  my $self = shift;
  return keys(%{$self->{'keyvalue'}});
}

sub keyvaluehash
{
  my $self = shift;
  return \%{$self->{'keyvalue'}};
}
sub confdatahash
{
  my $self = shift;
  return $self->{'confdata'};
}

sub by_lnr
{
  return ($a >= 0 && $b >= 0 ? $a <=> $b : $b <=> $a);
}

sub value
{
  my ($self, $key, $value, @restvals) = @_;
  my $t = $self->type;
  if (defined($value)) {
    if (defined($self->{'keyvalue'}{$key})) {
      my @key_lines = sort by_lnr CORE::keys %{$self->{'keyvalue'}{$key}};
      if ($t eq 'multiple') {
        my @newval = ( $value, @restvals );
        my $newlen = $#newval;
        my $listp = $self->{'keyvalue'}{$key};
        my $oldlen = $#key_lines;
        my $minlen = ($newlen < $oldlen ? $newlen : $oldlen);
        for my $i (0..$minlen) {
          if ($listp->{$key_lines[$i]}{'value'} ne $newval[$i]) {
            $listp->{$key_lines[$i]}{'value'} = $newval[$i];
            if ($listp->{$key_lines[$i]}{'status'} ne 'new') {
              $listp->{$key_lines[$i]}{'status'} = 'changed';
            }
            $self->{'changed'} = 1;
          }
        }
        if ($minlen < $oldlen) {
          for my $i (($minlen+1)..$oldlen) {
            $listp->{$key_lines[$i]}{'status'} = 'deleted';
          }
          $self->{'changed'} = 1;
        }
        if ($minlen < $newlen) {
          my $ll = $key_lines[$#key_lines];
          $ll = ($ll >= 0 ? -1 : $ll-1);
          for my $i (($minlen+1)..$newlen) {
            $listp->{$ll}{'status'} = 'new';
            $listp->{$ll}{'value'} = $newval[$i];
            $ll--;
          }
          $self->{'changed'} = 1;
        }
      } else {
        my $ll = $key_lines[($t eq 'first-win' ? 0 : $#key_lines)];
        if ($self->{'keyvalue'}{$key}{$ll}{'value'} ne $value) {
          $self->{'keyvalue'}{$key}{$ll}{'value'} = $value;
          if ($self->{'keyvalue'}{$key}{$ll}{'status'} ne 'new') {
            $self->{'keyvalue'}{$key}{$ll}{'status'} = 'changed';
          }
          $self->{'changed'} = 1;
        }
      }
    } else { # all new key
      my @newval = ( $value, @restvals );
      my $newlen = $#newval;
      for my $i (0..$newlen) {
        $self->{'keyvalue'}{$key}{-($i+1)}{'value'} = $value;
        $self->{'keyvalue'}{$key}{-($i+1)}{'status'} = 'new';
      }
      $self->{'changed'} = 1;
    }
  }
  if (defined($self->{'keyvalue'}{$key})) {
    my @key_lines = sort by_lnr CORE::keys %{$self->{'keyvalue'}{$key}};
    if ($t eq 'first-win') {
      return $self->{'keyvalue'}{$key}{$key_lines[0]}{'value'};
    } elsif ($t eq 'last-win') {
      return $self->{'keyvalue'}{$key}{$key_lines[$#key_lines]}{'value'};
    } elsif ($t eq 'multiple') {
      return map { $self->{'keyvalue'}{$key}{$_}{'value'} } @key_lines;
    } else {
      die "That should not happen: wrong type: $!";
    }
  }
  return;
}

sub delete_key
{
  my ($self, $key) = @_;
  my %config = %{$self->{'confdata'}};
  if (defined($self->{'keyvalue'}{$key})) {
    for my $l (CORE::keys %{$self->{'keyvalue'}{$key}}) {
      $self->{'keyvalue'}{$key}{$l}{'status'} = 'deleted';
    }
    $self->{'changed'} = 1;
  }
}

sub rename_key
{
  my ($self, $oldkey, $newkey) = @_;
  my %config = %{$self->{'confdata'}};
  for my $i (0..$config{'lines'}) {
    if (($config{$i}{'type'} eq 'data') &&
        ($config{$i}{'key'} eq $oldkey)) {
      $config{$i}{'key'} = $newkey;
      $self->{'changed'} = 1;
    }
  }
  if (defined($self->{'keyvalue'}{$oldkey})) {
    $self->{'keyvalue'}{$newkey} = $self->{'keyvalue'}{$oldkey};
    delete $self->{'keyvalue'}{$oldkey};
    $self->{'keyvalue'}{$newkey}{'status'} = 'changed';
    $self->{'changed'} = 1;
  }
}

sub is_changed
{
  my $self = shift;
  return $self->{'changed'};
}

sub save
{
  my $self = shift;
  my $outarg = shift;
  my $closeit = 0;
  return if (! ( defined($outarg) || $self->is_changed));
  my %config = %{$self->{'confdata'}};
  my $out = $outarg;
  my $fhout;
  if (!defined($out)) {
    $out = $config{'file'};
    my $dn = TeXLive::TLUtils::dirname($out);
    TeXLive::TLUtils::mkdirhier($dn);
    if (!open(CFG, ">$out")) {
      tlwarn("Cannot write to $out: $!\n");
      return 0;
    }
    $closeit = 1;
    $fhout = \*CFG;
  } else {
    if (ref($out) eq 'SCALAR') {
      my $dn = TeXLive::TLUtils::dirname($out);
      TeXLive::TLUtils::mkdirhier($dn);
      if (!open(CFG, ">$out")) {
        tlwarn("Cannot write to $out: $!\n");
        return 0;
      }
      $fhout = \*CFG;
      $closeit = 1;
    } elsif (ref($out) eq 'GLOB') {
      $fhout = $out;
    } else {
      tlwarn("Unknown out argument $out\n");
      return 0;
    }
  }
    
  my $current_key_value_is_changed = 0;
  for my $i (0..$config{'lines'}) {
    if ($config{$i}{'type'} eq 'comment') {
      print $fhout "$config{$i}{'value'}";
      print $fhout ($config{$i}{'multiline'} ? "\\\n" : "\n");
    } elsif ($config{$i}{'type'} eq 'empty') {
      print $fhout ($config{$i}{'multiline'} ? "\\\n" : "\n");
    } elsif ($config{$i}{'type'} eq 'data') {
      $current_key_value_is_changed = 0;
      if ($self->{'keyvalue'}{$config{$i}{'key'}}{$i}{'status'} eq 'changed') {
        $current_key_value_is_changed = 1;
        print $fhout "$config{$i}{'key'} $config{'sep'} $self->{'keyvalue'}{$config{$i}{'key'}}{$i}{'value'}";
        if (defined($config{$i}{'postcomment'})) {
          print $fhout $config{$i}{'postcomment'};
        }
        print $fhout "\n";
      } elsif ($self->{'keyvalue'}{$config{$i}{'key'}}{$i}{'status'} eq 'deleted') {
        $current_key_value_is_changed = 1;
      } else {
        $current_key_value_is_changed = 0;
        print $fhout "$config{$i}{'original'}\n";
      }
    } elsif ($config{$i}{'type'} eq 'continuation') {
      if ($current_key_value_is_changed) {
      } else {
        print $fhout "$config{$i}{'value'}";
        print $fhout ($config{$i}{'multiline'} ? "\\\n" : "\n");
      }
    }
  }
  for my $k (CORE::keys %{$self->{'keyvalue'}}) {
    for my $l (CORE::keys %{$self->{'keyvalue'}{$k}}) {
      if ($self->{'keyvalue'}{$k}{$l}{'status'} eq 'new') {
        print $fhout "$k $config{'sep'} $self->{'keyvalue'}{$k}{$l}{'value'}\n";
      }
    }
  }
  close $fhout if $closeit;
  if (!defined($outarg)) {
    $self->reparse;
  }
}




sub parse_config_file {
  my ($file, $cc, $sep) = @_;
  my @data;
  if (!open(CFG, "<$file")) {
    @data = ();
  } else {
    @data = <CFG>;
    chomp(@data);
    close(CFG);
  }

  my %config = ();
  $config{'file'} = $file;
  $config{'cc'} = $cc;
  $config{'sep'} = $sep;

  my $lines = $#data;
  my $cont_running = 0;
  for my $l (0..$lines) {
    $config{$l}{'original'} = $data[$l];
    if ($cont_running) {
      if ($data[$l] =~ m/^(.*)\\$/) {
        $config{$l}{'type'} = 'continuation';
        $config{$l}{'multiline'} = 1;
        $config{$l}{'value'} = $1;
        next;
      } else {
        $config{$l}{'type'} = 'continuation';
        $config{$l}{'value'} = $data[$l];
        $cont_running = 0;
        next;
      }
    }
    if ($data[$l] =~ m/$cc/) {
      $data[$l] =~ s/\\$//;
    }
    if ($data[$l] =~ m/^(.*)\\$/) {
      $cont_running = 1;
      $config{$l}{'multiline'} = 1;
      $data[$l] =~ s/\\$//;
    }

    if ($data[$l] =~ m/^\s*$/) {
      $config{$l}{'type'} = 'empty';
      next;
    }
    if ($data[$l] =~ m/^\s*$cc/) {
      $config{$l}{'type'} = 'comment';
      $config{$l}{'value'} = $data[$l];
      next;
    }
    if ($data[$l] =~ m/^\s*([^\s$sep]+)\s*$sep\s*(.*?)(\s*)?($cc.*)?$/) {
      $config{$l}{'type'} = 'data';
      $config{$l}{'key'} = $1;
      $config{$l}{'value'} = $2;
      if (defined($3)) {
        my $postcomment = $3;
        if (defined($4)) {
          $postcomment .= $4;
        }
        if ($postcomment =~ m/$cc/) {
          $config{$l}{'postcomment'} = $postcomment;
        }
      }
      next;
    }
    my $userlineno = $l + 1; # one-based
    warn("$0: WARNING: Cannot parse tlmgr config file ($cc, $sep)\n");
    warn("$0: $file:$userlineno: treating this line as comment:\n");
    warn(">>> $data[$l]\n");
    $config{$l}{'type'} = 'comment';
    $config{$l}{'value'} = $data[$l];
  }
  $config{'lines'} = $lines;
  return %config;
}

sub dump_myself {
  my $self = shift;
  print "======== DUMPING SELF =============\n";
  dump_config_data($self->{'confdata'});
  print "DUMPING KEY VALUES\n";
  for my $k (CORE::keys %{$self->{'keyvalue'}}) {
    print "key = $k\n";
    for my $l (sort CORE::keys %{$self->{'keyvalue'}{$k}}) {
      print "  line =$l= value =", $self->{'keyvalue'}{$k}{$l}{'value'}, "= status =", $self->{'keyvalue'}{$k}{$l}{'status'}, "=\n";
    }
  }
  print "=========== END DUMP ==============\n";
}

sub dump_config_data {
  my $foo = shift;
  my %config = %{$foo};
  print "config file name: $config{'file'}\n";
  print "config comment char: $config{'cc'}\n";
  print "config separator: $config{'sep'}\n";
  print "config lines: $config{'lines'}\n";
  for my $i (0..$config{'lines'}) {
    print "line ", $i+1, ": $config{$i}{'type'}";
    if ($config{$i}{'type'} eq 'comment') {
      print "\nCOMMENT = $config{$i}{'value'}\n";
    } elsif ($config{$i}{'type'} eq 'data') {
      print "\nKEY = $config{$i}{'key'}\nVALUE = $config{$i}{'value'}\n";
      print "MULTLINE = ", ($config{$i}{'multiline'} ? "1" : "0"), "\n";
    } elsif ($config{$i}{'type'} eq 'empty') {
      print "\n";
    } elsif ($config{$i}{'type'} eq 'continuation') {
      print "\nVALUE = $config{$i}{'value'}\n";
      print "MULTLINE = ", ($config{$i}{'multiline'} ? "1" : "0"), "\n";
    } else {
      print "-- UNKNOWN TYPE\n";
    }
  }
}
      
sub write_config_file {
  my $foo = shift;
  my %config = %{$foo};
  for my $i (0..$config{'lines'}) {
    if ($config{$i}{'type'} eq 'comment') {
      print "$config{$i}{'value'}";
      print ($config{$i}{'multiline'} ? "\\\n" : "\n");
    } elsif ($config{$i}{'type'} eq 'data') {
      print "$config{$i}{'key'} $config{'sep'} $config{$i}{'value'}";
      if ($config{$i}{'multiline'}) {
        print "\\";
      }
      print "\n";
    } elsif ($config{$i}{'type'} eq 'empty') {
      print ($config{$i}{'multiline'} ? "\\\n" : "\n");
    } elsif ($config{$i}{'type'} eq 'continuation') {
      print "$config{$i}{'value'}";
      print ($config{$i}{'multiline'} ? "\\\n" : "\n");
    } else {
      print STDERR "-- UNKNOWN TYPE\n";
    }
  }
}


1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfFile.pm@TeXLive/TLConfFile.pm
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
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLCrypto.pm@TeXLive/TLCrypto.pm
"TeXLive/TLCrypto.pm" => <<'__EOI__',

package TeXLive::TLCrypto;

use Digest::MD5;

use TeXLive::TLConfig;
use TeXLive::TLUtils qw(debug ddebug wndws which platform
                        conv_to_w32_path tlwarn tldie);

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


BEGIN {
  use Exporter ();
  use vars qw(@ISA @EXPORT_OK @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(
    &tlchecksum
    &tl_short_digest
    &verify_checksum
    &verify_checksum_and_check_return
    &setup_gpg
    &verify_signature
    %VerificationStatusDescription
    $VS_VERIFIED $VS_CHECKSUM_ERROR $VS_SIGNATURE_ERROR $VS_CONNECTION_ERROR
    $VS_UNSIGNED $VS_GPG_UNAVAILABLE $VS_PUBKEY_MISSING $VS_UNKNOWN
    $VS_EXPKEYSIG $VS_REVKEYSIG
  );
  @EXPORT = qw(
    %VerificationStatusDescription
    $VS_VERIFIED $VS_CHECKSUM_ERROR $VS_SIGNATURE_ERROR $VS_CONNECTION_ERROR
    $VS_UNSIGNED $VS_GPG_UNAVAILABLE $VS_PUBKEY_MISSING $VS_UNKNOWN
    $VS_EXPKEYSIG $VS_REVKEYSIG
  );
}


sub setup_checksum_method {
  return ($::checksum_method) if defined($::checksum_method);
  $::checksum_method = "";
  eval { 
    require Digest::SHA;
    Digest::SHA->import('sha512_hex');
    debug("Using checksum method digest::sha\n");
    $::checksum_method = "digest::sha";
  };
  if ($@ && ($^O !~ /^MSWin/i)) {
    my $ret;

    $ret = system("openssl dgst -sha512 >/dev/null 2>&1 </dev/null" );
    if ($ret == 0) {
      debug("Using checksum method openssl\n");
      return($::checksum_method = "openssl");
    }

    if (TeXLive::TLUtils::which("sha512sum")) {
      debug("Using checksum method sha512sum\n");
      return($::checksum_method = "sha512sum");
    }

    $ret = system("shasum -a 512 >/dev/null 2>&1 </dev/null" );
    if ($ret == 0) {
      debug("Using checksum method shasum\n");
      return($::checksum_method = "shasum");
    }

    debug("Cannot find usable checksum method!\n");
  }
  return($::checksum_method);
}



sub tlchecksum {
  my ($file) = @_;
  if (!$::checksum_method) {
    setup_checksum_method();
  }
  tldie("TLCRYPTO::tlchecksum: no checksum method available\n")
    if (!$::checksum_method);

  if (-r $file) {
    my ($out, $ret);
    if ($::checksum_method eq "openssl") {
      ($out, $ret) = TeXLive::TLUtils::run_cmd("openssl dgst -sha512 $file");
      chomp($out);
    } elsif ($::checksum_method eq "sha512sum") {
      ($out, $ret) = TeXLive::TLUtils::run_cmd("sha512sum $file");
      chomp($out);
    } elsif ($::checksum_method eq "shasum") {
      ($out, $ret) = TeXLive::TLUtils::run_cmd("shasum -a 512 $file");
      chomp($out);
    } elsif ($::checksum_method eq "digest::sha") {
      open(FILE, $file) || die "open($file) failed: $!";
      binmode(FILE);
      $out = Digest::SHA->new(512)->addfile(*FILE)->hexdigest;
      close(FILE);
      $ret = 0;
    } else {
      tldie("TLCRYPTO::tlchecksum: unknown checksum program: $::checksum_method\n");
    }
    if ($ret != 0) {
      tlwarn("TLCRYPTO::tlchecksum: cannot compute checksum: $file\n");
      return "";
    }
    ddebug("tlchecksum: out = $out\n");
    my $cs;
    if ($::checksum_method eq "openssl") {
      (undef,$cs) = split(/= /,$out);
    } elsif ($::checksum_method eq "sha512sum") {
      ($cs,undef) = split(' ',$out);
    } elsif ($::checksum_method eq "shasum") {
      ($cs,undef) = split(' ',$out);
    } elsif ($::checksum_method eq "digest::sha") {
      $cs = $out;
    }
    debug("tlchecksum($file): ===$cs===\n");
    if (length($cs) != 128) {
      tlwarn("TLCRYPTO::tlchecksum: unexpected output from $::checksum_method:"
             . " $out\n");
      return "";
    }
    return $cs;
  } else {
    tlwarn("TLCRYPTO::tlchecksum: given file not readable: $file\n");
    return "";
  }
}



sub tl_short_digest { return (Digest::MD5::md5_hex(shift)); }


sub verify_checksum_and_check_return {
  my ($file, $path, $is_main, $localcopymode) = @_;
  my ($r, $m) = verify_checksum($file, "$path.$ChecksumExtension");
  if ($r == $VS_CHECKSUM_ERROR) {
    if (!$localcopymode) {
      tldie("$0: checksum error when downloading $file from $path: $m\n");
    }
    return(0, $r);
  } elsif ($r == $VS_SIGNATURE_ERROR) {
    tldie("$0: signature verification error of $file from $path: $m\n");
  } elsif ($r == $VS_CONNECTION_ERROR) {
    if ($localcopymode) {
      return(0, $r);
    } else {
      tldie("$0: cannot download: $m\n");
    }
  } elsif ($r == $VS_UNSIGNED) {
    if ($is_main) {
      tldie("$0: main database at $path is not signed: $m\n");
    }
    debug("$0: remote database checksum is not signed, continuing anyway\n");
    return(0, $r);
  } elsif ($r == $VS_EXPKEYSIG) {
    debug("$0: good signature bug gpg key expired, continuing anyway!\n");
    return(0, $r);
  } elsif ($r == $VS_REVKEYSIG) {
    debug("$0: good signature but from revoked gpg key, continuing anyway!\n");
    return(0, $r);
  } elsif ($r == $VS_GPG_UNAVAILABLE) {
    debug("$0: TLPDB: no gpg available, continuing anyway!\n");
    return(0, $r);
  } elsif ($r == $VS_PUBKEY_MISSING) {
    debug("$0: TLPDB: pubkey missing, continuing anyway!\n");
    return(0, $r);
  } elsif ($r == $VS_VERIFIED) {
    return(1, $r);
  } else {
    tldie("$0: unexpected return value from verify_checksum: $r\n");
  }
  return(0, $r);
}




sub verify_checksum {
  my ($file, $checksum_url) = @_;
  return($VS_UNSIGNED, "no checksum method found") if (!$::checksum_method);
  my $checksum_file
    = TeXLive::TLUtils::download_to_temp_or_file($checksum_url);

  if (!$checksum_file) {
    debug("verify_checksum: download did not succeed for $checksum_url\n");
    return($VS_CONNECTION_ERROR, "download did not succeed: $checksum_url");
  }

  {
    my $css = -s $checksum_file;
    if ($css <= 128) {
      debug("verify_checksum: size of checksum file suspicious: $css\n");
      return($VS_CONNECTION_ERROR, "download corrupted: $checksum_url");
    }
  }

  my ($ret, $msg) = verify_signature($checksum_file, $checksum_url);

  if ($ret != 0) {
    debug("verify_checksum: returning $ret and $msg\n");
    return ($ret, $msg)
  }

  open $cs_fh, "<$checksum_file" or die("cannot read file: $!");
  if (read ($cs_fh, $remote_digest, $ChecksumLength) != $ChecksumLength) {
    close($cs_fh);
    debug("verify_checksum: incomplete read from\n  $checksum_file\nfor\n  $file\nand\n  $checksum_url\n");
    return($VS_CHECKSUM_ERROR, "incomplete read from $checksum_file");
  } else {
    close($cs_fh);
    debug("verify_checksum: found remote digest\n  $remote_digest\nfrom\n  $checksum_file\nfor\n  $file\nand\n  $checksum_url\n");
  }
  $local_digest = tlchecksum($file);
  debug("verify_checksum: local_digest = $local_digest\n");
  if ($local_digest ne $remote_digest) {
    return($VS_CHECKSUM_ERROR, "digest disagree");
  }

  debug("checksum of local copy identical with remote hash\n");

  return($VS_VERIFIED);
}


sub setup_gpg {
  my $master = shift;
  my $found = 0;
  my $prg;
  if ($ENV{'TL_GNUPG'}) {
    $prg = test_one_gpg($ENV{'TL_GNUPG'});
    $found = 1 if ($prg);
  } else {
    $prg = test_one_gpg('gpg');
    $found = 1 if ($prg);
  
    if (!$found) {
      $prg = test_one_gpg('gpg2');
      $found = 1 if ($prg);
    }
    if (!$found) {
      my $p = "$master/tlpkg/installer/gpg/gpg." .
        ($^O =~ /^MSWin/i ? "exe" : platform()) ;
      debug("Testing for gpg in $p\n");
      if (-r $p) {
        if ($^O =~ /^MSWin/i) {
          $prg = conv_to_w32_path($p);
        } else {
          $prg = "\"$p\"";
        }
        $found = 1;
      }
    }
  }
  return 0 if (!$found);


  my $gpghome = ($ENV{'TL_GNUPGHOME'} ? $ENV{'TL_GNUPGHOME'} : 
                                        "$master/tlpkg/gpg" );
  $gpghome =~ s!/!\\!g if wndws();
  my $gpghome_quote = "\"$gpghome\"";
  $::gpg = "$prg --homedir $gpghome_quote ";
  my $addkr = "$gpghome/repository-keys.gpg";
  if (-r $addkr) {
    debug("setup_gpg: using additional keyring $addkr\n");
    $::gpg .= "--keyring repository-keys.gpg ";
  }
  if ($ENV{'TL_GNUPGARGS'}) {
    $::gpg .= $ENV{'TL_GNUPGARGS'};
  } else {
    $::gpg .= "--no-secmem-warning --no-permission-warning --lock-never ";
  }
  debug("gpg command line: $::gpg\n");
  return 1;
}

sub test_one_gpg {
  my $prg = shift;
  my $cmdline;
  debug("Testing for gpg in $prg\n");
  if ($^O =~ /^MSWin/i) {
    $prg = which($prg);
    return "" if (!$prg);
    $prg = conv_to_w32_path($prg);
    $cmdline = "$prg --version >nul 2>&1";
  } else {
    $cmdline = "$prg --version >/dev/null 2>&1";
  }
  my $ret = system($cmdline);
  if ($ret == 0) {
    debug(" ... gpg ok! [$cmdline]\n");
    return $prg;
  } else {
    debug(" ... gpg not ok! [$cmdline]\n");
    return "";
  }
}


sub verify_signature {
  my ($file, $url) = @_;
  my $signature_url = "$url.asc";

  if ($::gpg) {
    my $signature_file
      = TeXLive::TLUtils::download_to_temp_or_file($signature_url);
    if ($signature_file) {
      {
        my $sigsize = -s $signature_file;
        if ($sigsize < 300) {
          debug("cryptographic signature seems to be corrupted (size $sigsize<300): $signature_url, $signature_file\n");
          return($VS_UNSIGNED, "cryptographic signature download seems to be corrupted (size $sigsize<300)");
        }
      }
      {
        open my $file, '<', $signature_file;
        chomp(my $firstLine = <$file>);
        close $file;
        if ($firstLine !~ m/^-----BEGIN PGP SIGNATURE-----/) {
          debug("cryptographic signature seems to be corrupted (first line not signature): $signature_url, $signature_file, $firstLine\n");
          return($VS_UNSIGNED, "cryptographic signature download seems to be corrupted (first line of $signature_url not signature: $firstLine)");
        }
      }
      my ($ret, $out) = gpg_verify_signature($file, $signature_file);
      if ($ret == $VS_VERIFIED) {
        debug("cryptographic signature of $url verified\n");
        return($VS_VERIFIED);
      } elsif ($ret == $VS_PUBKEY_MISSING) {
        return($VS_PUBKEY_MISSING, $out);
      } elsif ($ret == $VS_EXPKEYSIG) {
        return($VS_EXPKEYSIG, $out);
      } elsif ($ret == $VS_REVKEYSIG) {
        return($VS_REVKEYSIG, $out);
      } else {
        return($VS_SIGNATURE_ERROR, <<GPGERROR);
cryptographic signature verification of
  $file
against
  $signature_url
failed. Output was:
$out
Please try from a different mirror and/or wait a few minutes
and try again; usually this is because of transient updates.
If problems persist, feel free to report to texlive\@tug.org.
GPGERROR
      }
    } else {
      debug("no access to cryptographic signature $signature_url\n");
      return($VS_UNSIGNED, "no access to cryptographic signature");
    }
  } else {
    debug("gpg prog not defined, no checking of signatures\n");
    return($VS_GPG_UNAVAILABLE, "no gpg available");
  }
  return ($VS_UNKNOWN);
}


sub gpg_verify_signature {
  my ($file, $sig) = @_;
  my ($file_quote, $sig_quote);
  if (wndws()) {
    $file =~ s!/!\\!g;
    $sig =~ s!/!\\!g;
  }
  $file_quote = TeXLive::TLUtils::quotify_path_with_spaces ($file);
  $sig_quote = TeXLive::TLUtils::quotify_path_with_spaces ($sig);
  my ($status_fh, $status_file) = TeXLive::TLUtils::tl_tmpfile();
  close($status_fh);
  my ($out, $ret)
    = TeXLive::TLUtils::run_cmd("$::gpg --status-file \"$status_file\" --verify $sig_quote $file_quote 2>&1");
  open($status_fd, "<", $status_file) || die("Cannot open status file: $!");
  my @status_lines = <$status_fd>;
  close($status_fd);
  chomp(@status_lines);
  debug(join("\n", "STATUS OUTPUT", @status_lines));
  if ($ret == 0) {
    if (grep(/EXPKEYSIG/, @status_lines)) {
      return($VS_EXPKEYSIG, "expired key");
    }
    if (grep(/REVKEYSIG/, @status_lines)) {
      return($VS_REVKEYSIG, "revoked key");
    }
    debug("verification succeeded, output:\n$out\n");
    return ($VS_VERIFIED, $out);
  } else {
    my @nopb = grep(/^\[GNUPG:\] NO_PUBKEY /, @status_lines);
    if (@nopb) {
      my $mpk = $nopb[-1];
      $mpk =~ s/^\[GNUPG:\] NO_PUBKEY //;
      debug("missing pubkey $mpk\n");
      return ($VS_PUBKEY_MISSING, "missing pubkey $mpk");
    }
    return ($VS_SIGNATURE_ERROR, $out);
  }
}


our $VS_VERIFIED = 0;
our $VS_CHECKSUM_ERROR = 1;
our $VS_SIGNATURE_ERROR = 2;
our $VS_CONNECTION_ERROR = -1;
our $VS_UNSIGNED = -2;
our $VS_GPG_UNAVAILABLE = -3;
our $VS_PUBKEY_MISSING = -4;
our $VS_EXPKEYSIG = -5;
our $VS_EXPSIG = -6;
our $VS_REVKEYSIG = -7;
our $VS_UNKNOWN = -100;

our %VerificationStatusDescription = (
  $VS_VERIFIED         => 'verified',
  $VS_CHECKSUM_ERROR   => 'checksum error',
  $VS_SIGNATURE_ERROR  => 'signature error',
  $VS_CONNECTION_ERROR => 'connection error',
  $VS_UNSIGNED         => 'unsigned',
  $VS_GPG_UNAVAILABLE  => 'gpg unavailable',
  $VS_PUBKEY_MISSING   => 'pubkey missing',
  $VS_EXPKEYSIG        => 'valid signature with expired key',
  $VS_EXPSIG           => 'valid but expired signature',
  $VS_UNKNOWN          => 'unknown',
);


1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLCrypto.pm@TeXLive/TLCrypto.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLDownload.pm@TeXLive/TLDownload.pm
"TeXLive/TLDownload.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLDownload;

use TeXLive::TLUtils;
use TeXLive::TLConfig;

my $svnrev = '$Revision$';
my $_modulerevision;
if ($svnrev =~ m/: ([0-9]+) /) {
  $_modulerevision = $1;
} else {
  $_modulerevision = "unknown";
}
sub module_revision {
  return $_modulerevision;
}

our $net_lib_avail = 0;
eval { require LWP; };
if ($@) {
  debug("LWP is not available, falling back to wget.\n");
  $net_lib_avail = 0;
} else {
  require LWP::UserAgent;
  require HTTP::Status;
  $net_lib_avail = 1;
  ddebug("LWP available, doing persistent downloads.\n");
}


sub new
{
  my $class = shift;
  my %params = @_;
  my $self = {};
  $self->{'initcount'} = 0;
  bless $self, $class;
  $self->reinit(defined($params{'certificates'}) ? $params{'certificates'} : "");
  return $self;
}




sub reinit {
  my $self = shift;
  my $certs = shift;
  
  my @env_proxy = ();
  if (grep { /_proxy/i } keys %ENV ) {
    @env_proxy = ("env_proxy", 1);
  }
  if ((! exists $ENV{'HTTPS_CA_FILE'}) && $certs) {
    debug("Setting env var HTTPS_CA_FILE to " . $certs ."\n");
    $ENV{'HTTPS_CA_FILE'} = $certs
  }
  my $ua = LWP::UserAgent->new(
    agent => "texlive/lwp",
    keep_alive => 1,
    timeout => $TeXLive::TLConfig::NetworkTimeout,
    @env_proxy,
  );
  $self->{'ua'} = $ua;
  $self->{'enabled'} = 1;
  $self->{'errorcount'} = 0;
  $self->{'initcount'} += 1;
}

sub enabled {
  my $self = shift;
  return $self->{'enabled'};
}
sub disabled
{
  my $self = shift;
  return (!$self->{'enabled'});
}
sub enable
{
  my $self = shift;
  $self->{'enabled'} = 1;
  $self->reset_errorcount;
}
sub disable
{
  my $self = shift;
  $self->{'enabled'} = 0;
}
sub initcount
{
  my $self = shift;
  return $self->{'initcount'};
}
sub errorcount
{
  my $self = shift;
  if (@_) { $self->{'errorcount'} = shift }
  return $self->{'errorcount'};
}
sub incr_errorcount
{
  my $self = shift;
  return(++$self->{'errorcount'});
}
sub decr_errorcount
{
  my $self = shift;
  if ($self->errorcount > 0) {
    return(--$self->{'errorcount'});
  } else {
    return($self->errorcount(0));
  }
}

sub reset_errorcount {
  my $self = shift;
  $self->{'errorcount'} = 0;
}

sub get_file {
  my ($self,$url,$out,$size) = @_;
  if ($self->errorcount > $TeXLive::TLConfig::MaxLWPErrors) {
    $self->disable;
  }
  return if $self->disabled;
  my $realout = $out;
  my ($outfh, $outfn);
  if ($out eq "|") {
    ($outfh, $outfn) = tl_tmpfile();
    $realout = $outfn;
  }
  my $response = $self->{'ua'}->get($url, ':content_file' => $realout);
  if ($response->is_success) {
    $self->decr_errorcount;
    if ($out ne "|") {
      return 1;
    } else {
      seek $outfh, 0, 0;
      return $outfh;
    }
  } else {
    debug("TLDownload::get_file: response error: "
            . $response->status_line . " (for $url)\n");
    $self->incr_errorcount;
    return;
  }
}



1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLDownload.pm@TeXLive/TLDownload.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPDB.pm@TeXLive/TLPDB.pm
"TeXLive/TLPDB.pm" => <<'__EOI__',

use strict; use warnings;
package TeXLive::TLPDB;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


use TeXLive::TLConfig qw($CategoriesRegexp $DefaultCategory $InfraLocation
      $DatabaseName $DatabaseLocation $MetaCategoriesRegexp $Archive
      $DefaultCompressorFormat %Compressors $CompressorExtRegexp
      %TLPDBOptions %TLPDBSettings $ChecksumExtension
      $RelocPrefix $RelocTree);
use TeXLive::TLCrypto;
use TeXLive::TLPOBJ;
use TeXLive::TLUtils qw(dirname mkdirhier member wndws info log debug ddebug
                        tlwarn basename download_file merge_into tldie
                        system_pipe);
use TeXLive::TLWinGoo;

use Cwd 'abs_path';

my $_listdir;


sub new { 
  my $class = shift;
  my %params = @_;
  my $self = {
    root => $params{'root'},
    tlps => $params{'tlps'},
    verified => 0
  };
  my $verify = defined($params{'verify'}) ? $params{'verify'} : 0;
  ddebug("TLPDB new: verify=$verify\n");
  $_listdir = $params{'listdir'} if defined($params{'listdir'});
  bless $self, $class;
  if (defined($params{'tlpdbfile'})) {
    my $nr_packages_read = $self->from_file($params{'tlpdbfile'}, 
      'from-file' => 1, 'verify' => $verify);
    if ($nr_packages_read == 0) {
      return undef;
    }
    return $self;
  } 
  if (defined($self->{'root'})) {
    my $nr_packages_read
      = $self->from_file("$self->{'root'}/$DatabaseLocation",
        'verify' => $verify);
    if ($nr_packages_read == 0) {
      return undef;
    }
  }
  return $self;
}


sub copy {
  my $self = shift;
  my $bla = {};
  %$bla = %$self;
  bless $bla, "TeXLive::TLPDB";
  return $bla;
}


sub add_tlpobj {
  my ($self,$tlp) = @_;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot add tlpobj to a virtual tlpdb\n");
    return 0;
  }
  $self->{'tlps'}{$tlp->name} = $tlp;
}


sub needed_by {
  my ($self,$pkg) = @_;
  my @ret;
  for my $p ($self->list_packages) {
    my $tlp = $self->get_package($p);
    DEPENDS: for my $d ($tlp->depends) {
      if ($d eq $pkg) {
        push @ret, $p;
        last DEPENDS;  # of the for loop on all depends
      }
      if ($d =~ m/^(.*)\.ARCH$/) {
        my $parent = $1;
        for my $a ($self->available_architectures) {
          if ($pkg eq "$parent.$a") {
            push @ret, $p;
            last DEPENDS;
          }
        }
      }
    }
  }
  return @ret;
}


sub remove_tlpobj {
  my ($self,$pkg) = @_;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot remove tlpobj from a virtual tlpdb\n");
    return 0;
  }
  if (defined($self->{'tlps'}{$pkg})) {
    delete $self->{'tlps'}{$pkg};
  } else {
    tlwarn("TLPDB: package to be removed not found: $pkg\n");
  }
}


sub from_file {
  my ($self, $path, @args) = @_;
  my %params = @args;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot initialize a virtual tlpdb from_file\n");
    return 0;
  }
  if (@_ < 2) {
    die "$0: from_file needs filename for initialization";
  }
  my $root_from_path = dirname(dirname($path));
  if (defined($self->{'root'})) {
    if ($self->{'root'} ne $root_from_path) {
     if (!$params{'from-file'}) {
      tlwarn("TLPDB: initialization from different location than original;\n");
      tlwarn("TLPDB: hope you are sure!\n");
      tlwarn("TLPDB: root=$self->{'root'}, root_from_path=$root_from_path\n");
     }
    }
  } else {
    $self->root($root_from_path);
  }
  $self->verification_status($VS_UNKNOWN);
  my $retfh;
  my $tlpdbfile;
  my $is_verified = 0;
  my $rootpath = $self->root;
  my $media;
  if ($rootpath =~ m,https?://|ftp://,) {
    $media = 'NET';
  } elsif ($rootpath =~ m,$TeXLive::TLUtils::SshURIRegex,) {
    $media = 'NET';
  } else {
    if ($rootpath =~ m,file://*(.*)$,) {
      $rootpath = "/$1";
    }
    if ($params{'media'}) {
      $media = $params{'media'};
    } elsif (! -d $rootpath) {
      tlwarn("TLPDB: not a directory, not loading: $rootpath\n");
      return 0;
    } elsif (-d "$rootpath/texmf-dist/web2c") {
      $media = 'local_uncompressed';
    } elsif (-d "$rootpath/texmf/web2c") { # older
      $media = 'local_uncompressed';
    } elsif (-d "$rootpath/web2c") {
      $media = 'local_uncompressed';
    } elsif (-d "$rootpath/$Archive") {
      $media = 'local_compressed';
    } else {
      tlwarn("TLPDB: Cannot determine type of tlpdb from $rootpath!\n");
      return 0;
    }
  }
  $self->{'media'} = $media;
  if ($path =~ m;^((https?|ftp)://|file:\/\/*); || $path =~ m;$TeXLive::TLUtils::SshURIRegex;) {
    debug("TLPDB.pm: trying to initialize from $path\n");
    my $tlpdbfh;
    ($tlpdbfh, $tlpdbfile) = TeXLive::TLUtils::tl_tmpfile();
    close($tlpdbfh);
    my $xz_succeeded = 0 ;
    my $compressorextension = "<UNSET>";
    if (defined($::progs{$DefaultCompressorFormat})) {
      my ($xzfh, $xzfile) = TeXLive::TLUtils::tl_tmpfile();
      close($xzfh);
      my $decompressor = $::progs{$DefaultCompressorFormat};
      $compressorextension = $Compressors{$DefaultCompressorFormat}{'extension'};
      my @decompressorArgs = @{$Compressors{$DefaultCompressorFormat}{'decompress_args'}};
      debug("trying to download $path.$compressorextension to $xzfile\n");
      my $ret = TeXLive::TLUtils::download_file("$path.$compressorextension", "$xzfile");
      if ($ret && (-r "$xzfile")) {
        debug("decompressing $xzfile to $tlpdbfile\n");
        if (!system_pipe($decompressor, $xzfile, $tlpdbfile, 1, @decompressorArgs)) {
          debug("$decompressor $xzfile failed, trying plain file\n");
          unlink($xzfile); # the above command only removes in case of success
        } else {
          $xz_succeeded = 1;
          debug("found the uncompressed $DefaultCompressorFormat file\n");
        }
      } 
    } else {
      debug("no $DefaultCompressorFormat defined ...\n");
    }
    if (!$xz_succeeded) {
      debug("TLPDB: downloading $path.$compressorextension didn't succeed, try $path\n");
      my $ret = TeXLive::TLUtils::download_file($path, $tlpdbfile);
      if ($ret && (-r $tlpdbfile)) {
      } else {
        unlink($tlpdbfile);
        tldie(  "$0: TLPDB::from_file could not initialize from: $path\n"
              . "$0: Maybe the repository setting should be changed.\n"
              . "$0: More info: https://tug.org/texlive/acquire.html\n");
      }
    }
    if ($params{'verify'} && $media ne 'local_uncompressed') {
      my ($verified, $status) = TeXLive::TLCrypto::verify_checksum_and_check_return($tlpdbfile, $path);
      $is_verified = $verified;
      $self->verification_status($status);
    }
    open($retfh, "<$tlpdbfile") || die "$0: open($tlpdbfile) failed: $!";
  } else {
    if ($params{'verify'} && $media ne 'local_uncompressed') {
      my ($verified, $status) = TeXLive::TLCrypto::verify_checksum_and_check_return($path, $path);
      $is_verified = $verified;
      $self->verification_status($status);
    }
    open(TMP, "<$path") || die "$0: open($path) failed: $!";
    $retfh = \*TMP;
  }
  my $found = 0;
  my $ret = 0;
  do {
    my $tlp = TeXLive::TLPOBJ->new;
    $ret = $tlp->from_fh($retfh,1);
    if ($ret) {
      $self->add_tlpobj($tlp);
      $found++;
    }
  } until (!$ret);
  if (! $found) {
    debug("$0: Could not load packages from\n");
    debug("  $path\n");
  }

  $self->{'verified'} = $is_verified;

  close($retfh);
  return($found);
}


sub writeout {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot writeout a virtual tlpdb\n");
    return 0;
  }
  my $fd = (@_ ? $_[0] : *STDOUT);
  foreach (sort keys %{$self->{'tlps'}}) {
    TeXLive::TLUtils::dddebug("writeout: tlpname=$_  ",
                              $self->{'tlps'}{$_}->name, "\n");
    $self->{'tlps'}{$_}->writeout($fd);
    print $fd "\n";
  }
}


sub as_json {
  my $self = shift;
  my $ret = "{";
  if ($self->is_virtual) {
    my $firsttlpdb = 1;
    for my $k (keys %{$self->{'tlpdbs'}}) {
      $ret .= ",\n" if (!$firsttlpdb);
      $ret .= "\"$k\":";
      $firsttlpdb = 0;
      $ret .= $self->{'tlpdbs'}{$k}->_as_json;
    }
  } else {
    $ret .= "\"main\":";
    $ret .= $self->_as_json;
  }
  $ret .= "}\n";
  return($ret);
}

sub options_as_json {
  my $self = shift;
  die("calling _as_json on virtual is not supported!") if ($self->is_virtual);
  my $opts = $self->options;
  my @opts;
  for my $k (keys %TLPDBOptions) {
    my %foo;
    $foo{'name'} = $k;
    $foo{'tlmgrname'} = $TLPDBOptions{$k}[2];
    $foo{'description'} = $TLPDBOptions{$k}[3];
    $foo{'format'} = $TLPDBOptions{$k}[0];
    $foo{'default'} = "$TLPDBOptions{$k}[1]";
    
      if (exists($opts->{$k})) {
        $foo{'value'} = $opts->{$k};
      }
    push @opts, \%foo;
  }
  return(TeXLive::TLUtils::encode_json(\@opts));
}

sub settings_as_json {
  my $self = shift;
  die("calling _as_json on virtual is not supported!") if ($self->is_virtual);
  my $sets = $self->settings;
  my @json;
  for my $k (keys %TLPDBSettings) {
    my %foo;
    $foo{'name'} = $k;
    $foo{'type'} = $TLPDBSettings{$k}[0];
    $foo{'description'} = $TLPDBSettings{$k}[1];
      if (exists($sets->{$k})) {
        $foo{'value'} = "$sets->{$k}";
      }
    push @json, \%foo;
  }
  return(TeXLive::TLUtils::encode_json(\@json));
}

sub configs_as_json {
  my $self = shift;
  die("calling _as_json on virtual is not supported!") if ($self->is_virtual);
  my %cfgs;
  $cfgs{'container_split_src_files'} = ($self->config_src_container ? TeXLive::TLUtils::True() : TeXLive::TLUtils::False());
  $cfgs{'container_split_doc_files'} = ($self->config_doc_container ? TeXLive::TLUtils::True() : TeXLive::TLUtils::False());
  $cfgs{'container_format'} = $self->config_container_format;
  $cfgs{'release'} = $self->config_release;
  $cfgs{'minrelease'} = $self->config_minrelease;
  return(TeXLive::TLUtils::encode_json(\%cfgs));
}

sub _as_json {
  my $self = shift;
  die("calling _as_json on virtual is not supported!") if ($self->is_virtual);
  my $ret = "{";
  $ret .= '"options":';
  $ret .= $self->options_as_json();
  $ret .= ',"settings":';
  $ret .= $self->settings_as_json();
  $ret .= ',"configs":';
  $ret .= $self->configs_as_json();
  $ret .= ',"tlpkgs": [';
  my $first = 1;
  foreach (keys %{$self->{'tlps'}}) {
    $ret .= ",\n" if (!$first);
    $first = 0;
    $ret .= $self->{'tlps'}{$_}->as_json;
  }
  $ret .= "]}";
  return($ret);
}


sub save {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot save a virtual tlpdb\n");
    return 0;
  }
  my $path = $self->location;
  mkdirhier(dirname($path));
  my $tmppath = "$path.tmp";
  open(FOO, ">$tmppath") || die "$0: open(>$tmppath) failed: $!";
  $self->writeout(\*FOO);
  close(FOO);
  TeXLive::TLUtils::copy ("-f", $tmppath, $path);
  unlink ($tmppath) or tlwarn ("TLPDB: cannot unlink $tmppath: $!\n");
}


sub media { 
  my $self = shift ; 
  if ($self->is_virtual) {
    return "virtual";
  }
  return $self->{'media'};
}


sub available_architectures {
  my $self = shift;
  my @archs;
  if ($self->is_virtual) {
    for my $k (keys %{$self->{'tlpdbs'}}) {
      TeXLive::TLUtils::push_uniq \@archs, $self->{'tlpdbs'}{$k}->available_architectures;
    }
    return sort @archs;
  } else {
    return $self->_available_architectures;
  }
}

sub _available_architectures {
  my $self = shift;
  my @archs = $self->setting("available_architectures");
  if (! @archs) {
    my @packs = $self->list_packages;
    map { s/^tex\.// ; push @archs, $_ ; } grep(/^tex\.(.*)$/, @packs);
  }
  return @archs;
}


sub get_package {
  my ($self,$pkg,$tag) = @_;
  if ($self->is_virtual) {
    if (defined($tag)) {
      if (defined($self->{'packages'}{$pkg}{'tags'}{$tag})) {
        return $self->{'packages'}{$pkg}{'tags'}{$tag}{'tlp'};
      } else {
        debug("TLPDB::get_package: package $pkg not found in repository $tag\n");
        return;
      }
    } else {
      $tag = $self->{'packages'}{$pkg}{'target'};
      if (defined($tag)) {
        return $self->{'packages'}{$pkg}{'tags'}{$tag}{'tlp'};
      } else {
        return;
      }
    }
  } else {
    return $self->_get_package($pkg);
  }
}

sub _get_package {
  my ($self,$pkg) = @_;
  return undef if (!$pkg);
  if (defined($self->{'tlps'}{$pkg})) {
  my $ret = $self->{'tlps'}{$pkg};
    return $self->{'tlps'}{$pkg};
  } else {
    return undef;
  }
}


sub media_of_package {
  my ($self, $pkg, $tag) = @_;
  if ($self->is_virtual) {
    if (defined($tag)) {
      if (defined($self->{'tlpdbs'}{$tag})) {
        return $self->{'tlpdbs'}{$tag}->media;
      } else {
        tlwarn("TLPDB::media_of_package: tag not known: $tag\n");
        return;
      }
    } else {
      my (undef,undef,undef,$maxtlpdb) = $self->virtual_candidate($pkg);
      return $maxtlpdb->media;
    }
  } else {
    return $self->media;
  }
}


sub list_packages {
  my $self = shift;
  my $arg = shift;
  my $tag;
  my $showall = 0;
  if (defined($arg)) {
    if ($arg eq "-all") {
      $showall = 1;
    } else {
      $tag = $arg;
    }
  }
  if ($self->is_virtual) {
    if ($showall) {
      return (sort keys %{$self->{'packages'}});
    }
    if ($tag) {
      if (defined($self->{'tlpdbs'}{$tag})) {
        return $self->{'tlpdbs'}{$tag}->list_packages;
      } else {
        tlwarn("TLPDB::list_packages: tag not defined: $tag\n");
        return 0;
      }
    }
    my @pps;
    for my $p (keys %{$self->{'packages'}}) {
      push @pps, $p if (defined($self->{'packages'}{$p}{'target'}));
    }
    return (sort @pps);
  } else {
    return $self->_list_packages;
  }
}

sub _list_packages {
  my $self = shift;
  return (sort keys %{$self->{'tlps'}});
}


sub expand_dependencies {
  my $self = shift;
  my $only_arch = 0;
  my $no_collections = 0;
  my $first = shift;
  my $totlpdb;
  if ($first eq "-only-arch") {
    $only_arch = 1;
    $totlpdb = shift;
  } elsif ($first eq "-no-collections") {
    $no_collections = 1;
    $totlpdb = shift;
  } else {
    $totlpdb = $first;
  }
  my %install = ();
  my @archs = $totlpdb->available_architectures;
  for my $p (@_) {
    next if ($p =~ m/^\s*$/);
    my ($pp, $aa) = split('@', $p);
    $install{$pp} = (defined($aa) ? $aa : 0);;
  }
  my $changed = 1;
  while ($changed) {
    $changed = 0;
    my @pre_select = keys %install;
    ddebug("pre_select = @pre_select\n");
    for my $p (@pre_select) {
      next if ($p =~ m/^00texlive/);
      my $pkg = $self->get_package($p, ($install{$p}?$install{$p}:undef));
      if (!defined($pkg)) {
        ddebug("W: $p is mentioned somewhere but not available, disabling\n");
        $install{$p} = 0;
        next;
      }
      for my $p_dep ($pkg->depends) {
        ddebug("checking $p_dep in $p\n");
        my $tlpdd = $self->get_package($p_dep);
        if (defined($tlpdd)) {
          if ($tlpdd->category eq $pkg->category) {
            ddebug("expand_deps: skipping $p_dep in $p due to -no-collections\n");
            next if $no_collections;
          }
        }
        if ($p_dep =~ m/^(.*)\.ARCH$/) {
          my $foo = "$1";
          foreach $a (@archs) {
            $install{"$foo.$a"} = $install{$foo}
              if defined($self->get_package("$foo.$a"));
          }
        } elsif ($p_dep =~ m/^(.*)\.windows$/) {
          if (grep(/^windows$/,@archs)) {
            $install{$p_dep} = 0;
          }
        } else {
          $install{$p_dep} = 0 unless $only_arch;
        }
      }
    }

    my @post_select = keys %install;
    ddebug("post_select = @post_select\n");
    if ($#pre_select != $#post_select) {
      $changed = 1;
    }
  }
  return map { $install{$_} eq "0"?$_:"$_\@" . $install{$_} } keys %install;
}


sub find_file {
  my ($self,$fn) = @_;
  my @ret = ();
  for my $pkg ($self->list_packages) {
    for my $f ($self->get_package($pkg)->contains_file($fn)) {
      push (@ret, "$pkg:$f");
    }
  }
  return @ret;
}


sub collections {
  my $self = shift;
  my @ret;
  foreach my $p ($self->list_packages) {
    if ($self->get_package($p)->category eq "Collection") {
      push @ret, $p;
    }
  }
  return @ret;
}


sub schemes {
  my $self = shift;
  my @ret;
  foreach my $p ($self->list_packages) {
    if ($self->get_package($p)->category eq "Scheme") {
      push @ret, $p;
    }
  }
  return @ret;
}




sub package_revision {
  my ($self,$pkg) = @_;
  my $tlp = $self->get_package($pkg);
  if (defined($tlp)) {
    return $tlp->revision;
  } else {
    return;
  }
}


sub generate_packagelist {
  my $self = shift;
  my $fd = (@_ ? $_[0] : *STDOUT);
  foreach (sort $self->list_packages) {
    print $fd $self->get_package($_)->name, " ",
              $self->get_package($_)->revision, "\n";
  }
  foreach ($self->available_architectures) {
    print $fd "$_ -1\n";
  }
}


sub generate_listfiles {
  my ($self,$destdir) = @_;
  if (not(defined($destdir))) {
    $destdir = TeXLive::TLPDB->listdir;
  }
  foreach (sort $self->list_package) {
    my $tlp = $self->get_package($_);
    $self->_generate_listfile($tlp, $destdir);
  }
}

sub _generate_listfile {
  my ($self,$tlp,$destdir) = @_;
  my $listname = $tlp->name;
  my @files = $tlp->all_files;
  @files = TeXLive::TLUtils::sort_uniq(@files);
  &mkpath("$destdir") if (! -d "$destdir");
  my (@lop, @lot);
  foreach my $d ($tlp->depends) {
    my $subtlp = $self->get_package($d);
    if (defined($subtlp)) {
      if ($subtlp->is_meta_package) {
        push @lot, $d;
      } else {
        push @lop, $d;
      }
    } else {
      if ($d !~ m/\.ARCH$/) {
        tlwarn("TLPDB: package $tlp->name depends on $d, but this does not exist\n");
      }
    }
  }
  open(TMP, ">$destdir/$listname")
  || die "$0: open(>$destdir/$listname) failed: $!";

	if ($tlp->category eq "Collection") {
    print TMP "*Title: ", $tlp->shortdesc, "\n";
    my $s = 0;
    foreach my $p (@lop) {
      my $subtlp = $self->get_package($p);
      if (!defined($subtlp)) {
        tlwarn("TLPDB: $listname references $p, but this is not in tlpdb\n");
      }
      $s += $subtlp->total_size;
    }
    $s += $tlp->runsize + $tlp->srcsize + $tlp->docsize;
    print TMP "*Size: $s\n";
  } elsif ($tlp->category eq "Scheme") {
    print TMP "*Title: ", $tlp->shortdesc, "\n";
    my $s = 0;
    my (@inccol,@incpkg,@collpkg);
    @incpkg = @lop;
    foreach my $c (@lot) {
      my $coll = $self->get_package($c);
      foreach my $d ($coll->depends) {
        my $subtlp = $self->get_package($d);
        if (defined($subtlp)) {
          if (!($subtlp->is_meta_package)) {
            TeXLive::TLUtils::push_uniq(\@collpkg,$d);
          }
        } else {
          tlwarn("TLPDB: collection $coll->name depends on $d, but this does not exist\n");
        }
      }
    }
    foreach my $p (@incpkg) {
      if (!TeXLive::TLUtils::member($p,@collpkg)) {
        $s += $self->get_package($p)->total_size;
      }
    } 
    $s += $tlp->runsize + $tlp->srcsize + $tlp->docsize;
    print TMP "*Size: $s\n";
  }
  foreach my $t (@lot) {
    if ($listname =~ m/^scheme/) {
      print TMP "-";
    } else {
      print TMP "+";
    }
    print TMP "$t\n";
  }
  foreach my $t (@lop) { print TMP "+$t\n"; }
  foreach my $f (@files) { print TMP "$f\n"; }
  print TMP "$destdir/$listname\n";
  foreach my $e ($tlp->executes) {
    print TMP "!$e\n";
  }
  close(TMP);
}


sub root {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot set/edit root of a virtual tlpdb\n");
    return 0;
  }
  if (@_) { $self->{'root'} = shift }
  return $self->{'root'};
}


sub location {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot get location of a virtual tlpdb\n");
    return 0;
  }
  return "$self->{'root'}/$DatabaseLocation";
}


sub platform {
  my $self = shift;
  my $ret = $self->setting("platform");
  return $ret if defined $ret;
  return TeXLive::TLUtils::platform();
}


sub is_verified {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot set/edit verified property of a virtual tlpdb\n");
    return 0;
  }
  if (@_) { $self->{'verified'} = shift }
  return $self->{'verified'};
}

sub verification_status {
  my $self = shift;
  if ($self->is_virtual) {
    tlwarn("TLPDB: cannot set/edit verification status of a virtual tlpdb\n");
    return 0;
  }
  if (@_) { $self->{'verification_status'} = shift }
  return $self->{'verification_status'};
}


sub listdir {
  my $self = shift;
  if (@_) { $_listdir = $_[0] }
  return $_listdir;
}


sub config_src_container {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^container_split_src_files/(.*)$!) {
        return "$1";
      }
    }
  }
  return 0;
}


sub config_doc_container {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^container_split_doc_files/(.*)$!) {
        return "$1";
      }
    }
  }
  return 0;
}


sub config_container_format {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^container_format/(.*)$!) {
        return "$1";
      }
    }
  }
  return "";
}


sub config_release {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^release/(.*)$!) {
        return "$1";
      }
    }
  }
  return "";
}


sub config_minrelease {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^minrelease/(.*)$!) {
        return "$1";
      }
    }
  }
  return;
}


sub config_frozen {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^frozen/(.*)$!) {
        return "$1";
      }
    }
  }
  return;
}



sub config_revision {
  my $self = shift;
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package('00texlive.config');
  } else {
    $tlp = $self->{'tlps'}{'00texlive.config'};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^revision/(.*)$!) {
        return "$1";
      }
    }
  }
  return "";
}


sub sizes_of_packages {
  my ($self, $opt_src, $opt_doc, $arch_list_ref, @packs) = @_;
  return $self->_sizes_of_packages(0, $opt_src, $opt_doc, $arch_list_ref, @packs);
}

sub sizes_of_packages_with_deps {
  my ($self, $opt_src, $opt_doc, $arch_list_ref, @packs) = @_;
  return $self->_sizes_of_packages(1, $opt_src, $opt_doc, $arch_list_ref, @packs);
}


sub _sizes_of_packages {
  my ($self, $with_deps, $opt_src, $opt_doc, $arch_list_ref, @packs) = @_;
  @packs || ( @packs = $self->list_packages() );
  my @exppacks;
  if ($with_deps) {
    @exppacks = $self->expand_dependencies($self, @packs);
  } else {
    @exppacks = @packs;
  }
  my @archs;
  if ($arch_list_ref) {
    @archs = @$arch_list_ref;
  } else {
    @archs = $self->available_architectures;
  }
  my %tlpsizes;
  my %tlpobjs;
  my $totalsize = 0;
  foreach my $p (@exppacks) {
    $tlpobjs{$p} = $self->get_package($p);
    my $media = $self->media_of_package($p);
    if (!defined($tlpobjs{$p})) {
      warn "STRANGE: $p not to be found in ", $self->root;
      next;
    }
    if ($with_deps) {
      $tlpsizes{$p} = $self->size_of_one_package('local_uncompressed' , $tlpobjs{$p},
                                                 $opt_src, $opt_doc, @archs);
    } else {
      $tlpsizes{$p} = $self->size_of_one_package($media, $tlpobjs{$p},
                                                 $opt_src, $opt_doc, @archs);
    }
    $totalsize += $tlpsizes{$p};
  }
  my %realtlpsizes;
  if ($totalsize) {
    $realtlpsizes{'__TOTAL__'} = $totalsize;
  }
  if (!$with_deps) {
    for my $p (@packs) {
      $realtlpsizes{$p} = $tlpsizes{$p};
    }
  } else { # the case with dependencies
    for my $p (@exppacks) {
      next if ($p =~ m/scheme-/);
      next if ($p =~ m/collection-/);
      $realtlpsizes{$p} = $tlpsizes{$p};
    }
    for my $p (@exppacks) {
      next if ($p !~ m/collection-/);
      $realtlpsizes{$p} = $tlpsizes{$p};
      ddebug("=== $p adding deps\n");
      for my $d ($tlpobjs{$p}->depends) {
        next if ($d =~ m/^collection-/);
        next if ($d =~ m/^scheme-/);
        ddebug("=== going for $d\n");
        if (defined($tlpsizes{$d})) {
          $realtlpsizes{$p} += $tlpsizes{$d};
          ddebug("=== found $tlpsizes{$d} for $d\n");
        } else {
          debug("TLPDB.pm: size with deps: sub package not found main=$d, dep=$p\n");
        }
      }
    }
    for my $p (@exppacks) {
      next if ($p !~ m/scheme-/);
      $realtlpsizes{$p} = $tlpsizes{$p};
      ddebug("=== $p adding deps\n");
      for my $d ($tlpobjs{$p}->depends) {
        next if ($d =~ m/^scheme-/);
        ddebug("=== going for $d\n");
        if (defined($realtlpsizes{$d})) {
          $realtlpsizes{$p} += $realtlpsizes{$d};
          ddebug("=== found $realtlpsizes{$d} for $d\n");
        } else {
          debug("TLPDB.pm: size with deps: sub package not found main=$d, dep=$p\n");
        }
      }
    }
  }
  return \%realtlpsizes;
}

sub size_of_one_package {
  my ($self, $media, $tlpobj, $opt_src, $opt_doc, @used_archs) = @_;
  my $size = 0;
  if ($media ne 'local_uncompressed') {
    $size =  $tlpobj->containersize;
    $size += $tlpobj->srccontainersize if $opt_src;
    $size += $tlpobj->doccontainersize if $opt_doc;
  } else {
    $size  = $tlpobj->runsize;
    $size += $tlpobj->srcsize if $opt_src;
    $size += $tlpobj->docsize if $opt_doc;
    my %foo = %{$tlpobj->binsize};
    for my $k (keys %foo) { 
      if (@used_archs && member($k, @used_archs)) {
        $size += $foo{$k};
      }
    }
    $size *= $TeXLive::TLConfig::BlockSize;
  }
  return $size;
}


sub install_package_files {
  my ($self, @files) = @_;

  my $ret = 0;

  my $opt_src = $self->option("install_srcfiles");
  my $opt_doc = $self->option("install_docfiles");

  for my $f (@files) {

    my $tmpdir = TeXLive::TLUtils::tl_tmpdir();
    {
      my ($ret, $msg) = TeXLive::TLUtils::unpack($f, $tmpdir);
      if (!$ret) {
        tlwarn("TLPDB::install_package_files: $msg\n");
        next;
      }
    }
    my ($tlpobjfile, $anotherfile) = <$tmpdir/tlpkg/tlpobj/*.tlpobj>;
    if (defined($anotherfile)) {
      tlwarn("TLPDB::install_package_files: several tlpobj files "
             . "($tlpobjfile, $anotherfile) in tlpkg/tlpobj/, stopping!\n");
      next;
    }
    my $tlpobj = TeXLive::TLPOBJ->new;
    $tlpobj->from_file($tlpobjfile);

    if ($self->get_package($tlpobj->name)) {
      $self->remove_package($tlpobj->name);
    }

    my @installfiles = ();
    my $reloc = 1 if $tlpobj->relocated;
    foreach ($tlpobj->runfiles) { push @installfiles, $_; };
    foreach ($tlpobj->allbinfiles) { push @installfiles, $_; };
    if ($opt_src) { foreach ($tlpobj->srcfiles) { push @installfiles, $_; } }
    if ($opt_doc) { foreach ($tlpobj->docfiles) { push @installfiles, $_; } }
    @installfiles = map { s!^$RelocPrefix/!!; $_; } @installfiles;
    if (!_install_data ($tmpdir, \@installfiles, $reloc, \@installfiles,
                        $self)) {
      tlwarn("TLPDB::install_package_files: couldn't _install_data files: "
             . "@installfiles\n"); 
      next;
    }
    _post_install_package ($self, $tlpobj);

    $ret++;
  }
  return $ret;
}



sub install_package {
  my ($self, $pkg, $totlpdb, $tag) = @_;
  if ($self->is_virtual) {
    if (defined($tag)) {
      if (defined($self->{'packages'}{$pkg}{'tags'}{$tag})) {
        return $self->{'tlpdbs'}{$tag}->install_package($pkg, $totlpdb);
      } else {
        tlwarn("TLPDB::install_package: package $pkg not found"
               . " in repository $tag\n");
        return undef;
      }
    } else {
      my ($maxtag, $maxrev, $maxtlp, $maxtlpdb)
        = $self->virtual_candidate($pkg);
      return $maxtlpdb->install_package($pkg, $totlpdb);
    }
  } else {
    if (defined($tag)) {
      tlwarn("TLPDB: not a virtual tlpdb, ignoring tag $tag"
              . " on installation of $pkg\n");
    }
    return $self->not_virtual_install_package($pkg, $totlpdb);
  }
  return undef;
}

sub not_virtual_install_package {
  my ($self, $pkg, $totlpdb) = @_;
  my $fromtlpdb = $self;
  my $ret;
  die("TLPDB not initialized, cannot find tlpdb!")
    unless (defined($fromtlpdb));

  my $tlpobj = $fromtlpdb->get_package($pkg);
  if (!defined($tlpobj)) {
    tlwarn("TLPDB::not_virtual_install_package: cannot find package: $pkg\n");
    return 0;
  } else {
    my $container_src_split = $fromtlpdb->config_src_container;
    my $container_doc_split = $fromtlpdb->config_doc_container;
    my $opt_src = $totlpdb->option("install_srcfiles");
    my $opt_doc = $totlpdb->option("install_docfiles");
    my $real_opt_doc = $opt_doc;
    my $reloc = 1 if $tlpobj->relocated;
    my $container;
    my @installfiles;
    my $root = $self->root;
    $root =~ s!/$!!;
    foreach ($tlpobj->runfiles) {
      push @installfiles, $_;
    }
    foreach ($tlpobj->allbinfiles) {
      push @installfiles, $_;
    }
    if ($opt_src) {
      foreach ($tlpobj->srcfiles) {
        push @installfiles, $_;
      }
    }
    if ($real_opt_doc) {
      foreach ($tlpobj->docfiles) {
        push @installfiles, $_;
      }
    }
    my $media = $self->media;
    my $container_is_versioned = 0;
    if ($media eq 'local_uncompressed') {
      $container = \@installfiles;
    } elsif ($media eq 'local_compressed') {
      for my $ext (map { $Compressors{$_}{'extension'} } keys %Compressors) {
        my $rev = $tlpobj->revision;
        if (-r "$root/$Archive/$pkg.r$rev.tar.$ext") {
          $container_is_versioned = 1;
          $container = "$root/$Archive/$pkg.r$rev.tar.$ext";
        } elsif (-r "$root/$Archive/$pkg.tar.$ext") {
          $container_is_versioned = 0;
          $container = "$root/$Archive/$pkg.tar.$ext";
        }
      }
      if (!$container) {
        tlwarn("TLPDB: cannot find package $pkg.tar.$CompressorExtRegexp"
               . " in $root/$Archive\n");
        return(0);
      }
    } elsif (&media eq 'NET') {
      $container = "$root/$Archive/$pkg.tar."
                   . $Compressors{$DefaultCompressorFormat}{'extension'};
      $container_is_versioned = 0;
    }
    my $container_str = ref $container eq "ARRAY"
                        ? "[" . join (" ", @$container) . "]" : $container;
    ddebug("TLPDB::not_virtual_install_package: installing container: ",
          $container_str, "\n");
    $self->_install_data($container, $reloc, \@installfiles, $totlpdb,
                         $tlpobj->containersize, $tlpobj->containerchecksum)
      || return(0);
    if (($media eq 'NET') || ($media eq 'local_compressed')) {
      if ($container_src_split && $opt_src && $tlpobj->srcfiles) {
        my $srccontainer = $container;
        if ($container_is_versioned) {
          $srccontainer =~ s/\.(r[0-9]*)\.tar\.$CompressorExtRegexp$/.source.$1.tar.$2/;
        } else {
          $srccontainer =~ s/\.tar\.$CompressorExtRegexp$/.source.tar.$1/;
        }
        $self->_install_data($srccontainer, $reloc, \@installfiles, $totlpdb,
                      $tlpobj->srccontainersize, $tlpobj->srccontainerchecksum)
          || return(0);
      }
      if ($container_doc_split && $real_opt_doc && $tlpobj->docfiles) {
        my $doccontainer = $container;
        if ($container_is_versioned) {
          $doccontainer =~ s/\.(r[0-9]*)\.tar\.$CompressorExtRegexp$/.doc.$1.tar.$2/;
        } else {
          $doccontainer =~ s/\.tar\.$CompressorExtRegexp$/.doc.tar.$1/;
        }
        $self->_install_data($doccontainer, $reloc, \@installfiles,
            $totlpdb, $tlpobj->doccontainersize, $tlpobj->doccontainerchecksum)
          || return(0);
      }
      if ($tlpobj->relocated) {
        my $reloctree = $totlpdb->root . "/" . $RelocTree;
        my $tlpkgdir = $reloctree . "/" . $InfraLocation;
        my $tlpod = $tlpkgdir .  "/tlpobj";
        TeXLive::TLUtils::rmtree($tlpod) if (-d $tlpod);
        rmdir($tlpkgdir) if (-d "$tlpkgdir");
      }
    }
    if (!$opt_src) {
      $tlpobj->clear_srcfiles;
    }
    if (!$real_opt_doc) {
      $tlpobj->clear_docfiles;
    }
    _post_install_pkg ($totlpdb, $tlpobj);
  }
  return 1;
}

sub _post_install_pkg {
  my ($tlpdb,$tlpobj) = @_;
  
  if ($tlpobj->relocated) {
    if ($tlpdb->setting("usertree")) {
      $tlpobj->cancel_reloc_prefix;
    } else {
      $tlpobj->replace_reloc_prefix;
    }
    $tlpobj->relocated(0);
  }
  my $tlpod = $tlpdb->root . "/tlpkg/tlpobj";
  mkdirhier($tlpod);
  my $count = 0;
  my $tlpobj_file = ">$tlpod/" . $tlpobj->name . ".tlpobj";
  until (open(TMP, $tlpobj_file)) {
    if ($count++ == 100) { die "$0: open($tlpobj_file) failed: $!"; }
    select(undef, undef, undef, .1);  # sleep briefly
  }
  $tlpobj->writeout(\*TMP);
  close(TMP);
  $tlpdb->add_tlpobj($tlpobj);
  $tlpdb->save;
  TeXLive::TLUtils::announce_execute_actions("enable", $tlpobj);
  if ($tlpobj->name eq "context") {
    TeXLive::TLUtils::announce_execute_actions("context-cache", $tlpobj);
  }
  if (wndws() && admin() && !$tlpdb->option("w32_multi_user")) {
    non_admin();
  }
  &TeXLive::TLUtils::do_postaction("install", $tlpobj,
    $tlpdb->option("file_assocs"),
    $tlpdb->option("desktop_integration"),
    $tlpdb->option("desktop_integration"),
    $tlpdb->option("post_code"));
}

sub _install_data {
  my ($self, $what, $reloc, $filelistref, $totlpdb, $whatsize, $whatcheck) =@_;

  my $target = $totlpdb->root;
  my $tempdir = TeXLive::TLUtils::tl_tmpdir();

  my @filelist = @$filelistref;

  if (ref $what) {
    my $root;
    if (!ref($self)) {
      $root = $self;
    } else {
      $root = $self->root;
    }
    if ($reloc) {
      if (!$totlpdb->setting("usertree")) {
        $target .= "/$RelocTree";
      }
    }

    foreach my $file (@$what) {
      my $dn=dirname($file);
      mkdirhier("$target/$dn");
      TeXLive::TLUtils::copy "$root/$file", "$target/$dn";
    }
    return(1);
  } elsif ($what =~ m,\.tar\.$CompressorExtRegexp$,) {
    if ($reloc) {
      if (!$totlpdb->setting("usertree")) {
        $target .= "/$RelocTree";
      }
    }
    my $ww = ($whatsize || "<unset>");
    my $ss = ($whatcheck || "<unset>");
    debug("TLPDB::_install_data: what=$what, target=$target, size=$ww, checksum=$ss, tmpdir=$tempdir\n");
    my ($ret, $pkg) = TeXLive::TLUtils::unpack($what, $target, 'size' => $whatsize, 'checksum' => $whatcheck, 'tmpdir' => $tempdir);
    if (!$ret) {
      tlwarn("TLPDB::_install_data: $pkg for $what\n"); # $pkg is error msg
      return(0);
    }
    unlink ("$target/tlpkg/tlpobj/$pkg.tlpobj") 
      if (-r "$target/tlpkg/tlpobj/$pkg.tlpobj");
    return(1);
  } else {
    tlwarn("TLPDB::_install_data: don't know how to install $what\n");
    return(0);
  }
}



sub remove_package {
  my ($self, $pkg, %opts) = @_;
  my $localtlpdb = $self;
  my $tlp = $localtlpdb->get_package($pkg);
  my $usertree = $localtlpdb->setting("usertree");
  if (!defined($tlp)) {
    tlwarn ("TLPDB::remove_package: package not present, ",
            "so nothing to remove: $pkg\n");
  } else {
    my $currentarch = $self->platform();
    if ($pkg eq "texlive.infra" || $pkg eq "texlive.infra.$currentarch") {
      log ("Not removing $pkg, it is essential!\n");
      return 0;
    }
    my $Master = $localtlpdb->root;
    chdir ($Master) || die "chdir($Master) failed: $!";
    my @files = $tlp->all_files;
    push @files, "tlpkg/tlpobj/$pkg.tlpobj";
    if (-r "tlpkg/tlpobj/$pkg.source.tlpobj") {
      push @files, "tlpkg/tlpobj/$pkg.source.tlpobj";
    }
    if (-r "tlpkg/tlpobj/$pkg.doc.tlpobj") {
      push @files, "tlpkg/tlpobj/$pkg.doc.tlpobj";
    }
    if ($tlp->relocated) {
      for (@files) {
        if (!$usertree) {
          s:^$RelocPrefix/:$RelocTree/:;
        }
      }
    }
    my %allfiles;
    for my $p ($localtlpdb->list_packages) {
      next if ($p eq $pkg); # we have to skip the to be removed package
      for my $f ($localtlpdb->get_package($p)->all_files) {
        $allfiles{$f} = $p;
      }
    }
    my @goodfiles = ();
    my @badfiles = ();
    my @debugfiles = ();
    for my $f (@files) {
      if (defined($allfiles{$f})) {
        if (defined($opts{'remove-warn-files'})) {
          my %a = %{$opts{'remove-warn-files'}};
          if (defined($a{$f})) {
            push @badfiles, $f;
          } else {
            push @debugfiles, $f;
          }
        } else {
          push @badfiles, $f;
        }
      } else {
        push @goodfiles, $f;
      }
    }
    if ($#debugfiles >= 0) {
      debug("The following files will not be removed due to the removal of $pkg.\n");
      debug("But we do not warn on it because they are moved to other packages.\n");
      for my $f (@debugfiles) {
        debug(" $f - $allfiles{$f}\n");
      }
    }
    if ($#badfiles >= 0) {
      tlwarn("TLPDB: These files would have been removed due to removal of\n");
      tlwarn("TLPDB: $pkg, but are part of another package:\n");
      for my $f (@badfiles) {
        tlwarn(" $f - $allfiles{$f}\n");
      }
    }
    if (defined($opts{'nopostinstall'}) && $opts{'nopostinstall'}) {
      &TeXLive::TLUtils::do_postaction("remove", $tlp,
        0, # tlpdbopt_file_assocs,
        0, # tlpdbopt_desktop_integration, menu part
        0, # tlpdbopt_desktop_integration, desktop part
        $localtlpdb->option("post_code"));
    }
    my (%by_dirs, %removed_dirs) = &TeXLive::TLUtils::all_dirs_and_removed_dirs (@goodfiles);
    my @removals = keys %removed_dirs;

    for my $d (keys %by_dirs) {
      if (! &TeXLive::TLUtils::dir_writable($d)) {
        tlwarn("TLPDB::remove_package: directories are not writable, cannot remove files: $d\n");
        return 0;
      }
    }

    for my $entry (@goodfiles) {
      next unless -e $entry;
      unlink($entry)
      || tlwarn("TLPDB::remove_package: Could not unlink $entry: $!\n");
    }
    for my $d (@removals) {
      rmdir($d)
      || tlwarn("TLPDB::remove_package: Could not rmdir $d: $!\n")
    }
    $localtlpdb->remove_tlpobj($pkg);
    TeXLive::TLUtils::announce_execute_actions("disable", $tlp);
    
    $localtlpdb->save;
    if (wndws() && admin() && !$localtlpdb->option("w32_multi_user")) {
      non_admin();
    }
    if (!$opts{'nopostinstall'}) {
      debug(" TLPDB::remove_package: running remove postinstall\n");
      &TeXLive::TLUtils::do_postaction("remove", $tlp,
        $localtlpdb->option("file_assocs"),
        $localtlpdb->option("desktop_integration"),
        $localtlpdb->option("desktop_integration"),
        0);
    }
  }
  return 1;
}



sub _set_option_value {
  my $self = shift;
  $self->_set_value_pkg('00texlive.installation', 'opt_', @_);
}
sub _set_setting_value {
  my $self = shift;
  $self->_set_value_pkg('00texlive.installation', 'setting_', @_);
}
sub _set_value_pkg {
  my ($self,$pkgname,$pre,$key,$value) = @_;
  my $k = "$pre$key";
  my $pkg;
  if ($self->is_virtual) {
    $pkg = $self->{'tlpdbs'}{'main'}->get_package($pkgname);
  } else {
    $pkg = $self->{'tlps'}{$pkgname};
  }
  my @newdeps;
  if (!defined($pkg)) {
    $pkg = new TeXLive::TLPOBJ;
    $pkg->name($pkgname);
    $pkg->category("TLCore");
    push @newdeps, "$k:$value";
  } else {
    my $found = 0;
    foreach my $d ($pkg->depends) {
      if ($d =~ m!^$k:!) {
        $found = 1;
        push @newdeps, "$k:$value";
      } else {
        push @newdeps, $d;
      }
    }
    if (!$found) {
      push @newdeps, "$k:$value";
    }
  }
  $pkg->depends(@newdeps);
  $self->add_tlpobj($pkg);
}

sub _clear_option {
  my $self = shift;
  $self->_clear_pkg('00texlive.installation', 'opt_', @_);
}

sub _clear_setting {
  my $self = shift;
  $self->_clear_pkg('00texlive.installation', 'setting_', @_);
}

sub _clear_pkg {
  my ($self,$pkgname,$pre,$key) = @_;
  my $k = "$pre$key";
  my $pkg;
  if ($self->is_virtual) {
    $pkg = $self->{'tlpdbs'}{'main'}->get_package($pkgname);
  } else {
    $pkg = $self->{'tlps'}{$pkgname};
  }
  my @newdeps;
  if (!defined($pkg)) {
    return;
  } else {
    foreach my $d ($pkg->depends) {
      if ($d =~ m!^$k:!) {
      } else {
        push @newdeps, $d;
      }
    }
  }
  $pkg->depends(@newdeps);
  $self->add_tlpobj($pkg);
}


sub _get_option_value {
  my $self = shift;
  $self->_get_value_pkg('00texlive.installation', 'opt_', @_);
}

sub _get_setting_value {
  my $self = shift;
  $self->_get_value_pkg('00texlive.installation', 'setting_', @_);
}

sub _get_value_pkg {
  my ($self,$pkg,$pre,$key) = @_;
  my $k = "$pre$key";
  my $tlp;
  if ($self->is_virtual) {
    $tlp = $self->{'tlpdbs'}{'main'}->get_package($pkg);
  } else {
    $tlp = $self->{'tlps'}{$pkg};
  }
  if (defined($tlp)) {
    foreach my $d ($tlp->depends) {
      if ($d =~ m!^$k:(.*)$!) {
        return "$1";
      }
    }
    return;
  }
  tlwarn("TLPDB: $pkg not found, cannot read option $key.\n");
  return;
}

sub option_pkg {
  my $self = shift;
  my $pkg = shift;
  my $key = shift;
  if (@_) { $self->_set_value_pkg($pkg, "opt_", $key, shift); }
  my $ret = $self->_get_value_pkg($pkg, "opt_", $key);
  if (defined($ret) && $ret eq "__MASTER__" && $key eq "location") {
    return $self->root;
  }
  return $ret;
}
sub option {
  my $self = shift;
  my $key = shift;
  if (@_) { $self->_set_option_value($key, shift); }
  my $ret = $self->_get_option_value($key);
  if (defined($ret) && $ret eq "__MASTER__" && $key eq "location") {
    return $self->root;
  }
  return $ret;
}
sub setting_pkg {
  my $self = shift;
  my $pkg = shift;
  my $key = shift;
  if (@_) { 
    if ($TLPDBSettings{$key}->[0] eq "l") {
      $self->_set_value_pkg($pkg, "setting_", $key, "@_"); 
    } else {
      $self->_set_value_pkg($pkg, "setting_", $key, shift); 
    }
  }
  my $ret = $self->_get_value_pkg($pkg, "setting_", $key);
  if ($TLPDBSettings{$key}->[0] eq "l") {
    my @ret;
    if (defined $ret) {
      @ret = split(" ", $ret);
    } else {
      tlwarn "TLPDB::setting_pkg: no $key, returning empty list\n";
      @ret = ();
    }
    return @ret;
  }
  return $ret;
}
sub setting {
  my $self = shift;
  my $key = shift;
  if ($key eq "-clear") {
    my $realkey = shift;
    $self->_clear_setting($realkey);
    return;
  }
  if (@_) { 
    if ($TLPDBSettings{$key}->[0] eq "l") {
      $self->_set_setting_value($key, "@_"); 
    } else {
      $self->_set_setting_value($key, shift); 
    }
  }
  my $ret = $self->_get_setting_value($key);
  if ($TLPDBSettings{$key}->[0] eq "l") {
    my @ret;
    if (defined $ret) {
      @ret = split(" ", $ret);
    } else {
      tlwarn("TLPDB::setting: no $key, returning empty list\n");
      @ret = ();
    }
    return @ret;
  }
  return $ret;
}

sub reset_options {
  my $self = shift;
  for my $k (keys %TLPDBOptions) {
    $self->option($k, $TLPDBOptions{$k}->[1]);
  }
}

sub add_default_options {
  my $self = shift;
  for my $k (sort keys %TLPDBOptions) {
    if (! $self->option($k) ) {
      $self->option($k, $TLPDBOptions{$k}->[1]);
    }
  }
}


sub _keyshash {
  my ($self, $pre, $hr) = @_;
  my @allowed = keys %$hr;
  my %ret;
  my $pkg;
  if ($self->is_virtual) {
    $pkg = $self->{'tlpdbs'}{'main'}->get_package('00texlive.installation');
  } else {
    $pkg = $self->{'tlps'}{'00texlive.installation'};
  }
  if (defined($pkg)) {
    foreach my $d ($pkg->depends) {
      if ($d =~ m!^$pre([^:]*):(.*)!) {
        if (member($1, @allowed)) {
          $ret{$1} = $2;
        } else {
          tlwarn("TLPDB::_keyshash: Unsupported option/setting $d\n");
        }
      }
    }
  }
  return \%ret;
}

sub options {
  my $self = shift;
  return ($self->_keyshash('opt_', \%TLPDBOptions));
}
sub settings {
  my $self = shift;
  return ($self->_keyshash('setting_', \%TLPDBSettings));
}


sub format_definitions {
  my $self = shift;
  my @ret;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @ret, $obj->format_definitions;
  }
  return(@ret);
}

sub fmtutil_cnf_lines {
  my $self = shift;
  my @lines;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @lines, $obj->fmtutil_cnf_lines(@_);
  }
  return(@lines);
}

sub updmap_cfg_lines {
  my $self = shift;
  my @lines;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @lines, $obj->updmap_cfg_lines(@_);
  }
  return(@lines);
}


sub language_dat_lines {
  my $self = shift;
  my @lines;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @lines, $obj->language_dat_lines(@_);
  }
  return(@lines);
}


sub language_def_lines {
  my $self = shift;
  my @lines;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @lines, $obj->language_def_lines(@_);
  }
  return(@lines);
}


sub language_lua_lines {
  my $self = shift;
  my @lines;
  foreach my $p ($self->list_packages) {
    my $obj = $self->get_package ($p);
    die "$0: No TeX Live package named $p, strange" if ! $obj;
    push @lines, $obj->language_lua_lines(@_);
  }
  return(@lines);
}



sub is_virtual {
  my $self = shift;
  if (defined($self->{'virtual'}) && $self->{'virtual'}) {
    return 1;
  }
  return 0;
}

sub make_virtual {
  my $self = shift;
  if (!$self->is_virtual) {
    if ($self->list_packages) {
      tlwarn("TLPDB: cannot convert initialized tlpdb to virtual\n");
      return 0;
    }
    $self->{'virtual'} = 1;
  }
  return 1;
}

sub virtual_get_tags {
  my $self = shift;
  return keys %{$self->{'tlpdbs'}};
}

sub virtual_get_tlpdb {
  my ($self, $tag) = @_;
  if (!$self->is_virtual) {
    tlwarn("TLPDB: cannot remove tlpdb from a non-virtual tlpdb!\n");
    return 0;
  }
  if (!defined($self->{'tlpdbs'}{$tag})) {
    tlwarn("TLPDB::virtual_get_tlpdb: unknown tag: $tag\n");
    return 0;
  }
  return $self->{'tlpdbs'}{$tag};
}

sub virtual_add_tlpdb {
  my ($self, $tlpdb, $tag) = @_;
  if (!$self->is_virtual) {
    tlwarn("TLPDB: cannot virtual_add_tlpdb to a non-virtual tlpdb!\n");
    return 0;
  }
  $self->{'tlpdbs'}{$tag} = $tlpdb;
  for my $p ($tlpdb->list_packages) {
    my $tlp = $tlpdb->get_package($p);
    $self->{'packages'}{$p}{'tags'}{$tag}{'revision'} = $tlp->revision;
    $self->{'packages'}{$p}{'tags'}{$tag}{'tlp'} = $tlp;
  }
  $self->check_evaluate_pinning();
  return 1;
}

sub virtual_remove_tlpdb {
  my ($self, $tag) = @_;
  if (!$self->is_virtual) {
    tlwarn("TLPDB: Cannot remove tlpdb from a non-virtual tlpdb!\n");
    return 0;
  }
  if (!defined($self->{'tlpdbs'}{$tag})) {
    tlwarn("TLPDB: virtual_remove_tlpdb: unknown tag $tag\n");
    return 0;
  }
  for my $p ($self->{'tlpdbs'}{$tag}->list_packages) {
    delete $self->{'packages'}{$p}{'tags'}{$tag};
  }
  delete $self->{'tlpdbs'}{$tag};
  $self->check_evaluate_pinning();
  return 1;
}

sub virtual_get_package {
  my ($self, $pkg, $tag) = @_;
  if (defined($self->{'packages'}{$pkg}{'tags'}{$tag})) {
    return $self->{'packages'}{$pkg}{'tags'}{$tag}{'tlp'};
  } else {
    tlwarn("TLPDB: virtual pkg $pkg not found in tag $tag\n");
    return;
  }
}


sub is_repository {
  my $self = shift;
  my $tag = shift;
  if (!$self->is_virtual) {
    return ( ($tag eq $self->{'root'}) ? 1 : 0 );
  }
  return ( defined($self->{'tlpdbs'}{$tag}) ? 1 : 0 );
}


sub candidates {
  my $self = shift;
  my $pkg = shift;
  my @ret = ();
  if ($self->is_virtual) {
    if (defined($self->{'packages'}{$pkg})) {
      my $t = $self->{'packages'}{$pkg}{'target'};
      if (defined($t)) {
        push @ret, "$t/" . $self->{'packages'}{$pkg}{'tags'}{$t}{'revision'};
      } else {
        $t = "";
        push @ret, undef;
      }
      my @repos = keys %{$self->{'packages'}{$pkg}};
      for my $r (sort keys %{$self->{'packages'}{$pkg}{'tags'}}) {
        push @ret, "$r/" . $self->{'packages'}{$pkg}{'tags'}{$r}{'revision'}
          if ($t ne $r);
      }
    }
  } else {
    my $tlp = $self->get_package($pkg);
    if (defined($tlp)) {
      push @ret, "main/" . $tlp->revision;
    }
  }
  return @ret;
}


sub virtual_candidate {
  my ($self, $pkg) = @_;
  my $t = $self->{'packages'}{$pkg}{'target'};
  if (defined($t)) {
    return ($t, $self->{'packages'}{$pkg}{'tags'}{$t}{'revision'},
      $self->{'packages'}{$pkg}{'tags'}{$t}{'tlp'}, $self->{'tlpdbs'}{$t});
  }
  return(undef,undef,undef,undef);
}


sub virtual_pindata {
  my $self = shift;
  return ($self->{'pindata'});
}

sub virtual_update_pins {
  my $self = shift;
  if (!$self->is_virtual) {
    tlwarn("TLPDB::virtual_update_pins: Non-virtual tlpdb can't have pins.\n");
    return 0;
  }
  my $pincf = $self->{'pinfile'};
  my @pins;
  for my $k ($pincf->keys) {
    for my $v ($pincf->value($k)) {
      push (@pins, $self->make_pin_data_from_line("$k:$v"));
    }
  }
  $self->{'pindata'} = \@pins;
  $self->check_evaluate_pinning();
  return ($self->{'pindata'});
}
sub virtual_pinning {
  my ($self, $pincf) = @_;
  if (!$self->is_virtual) {
    tlwarn("TLPDB::virtual_pinning: Non-virtual tlpdb can't have pins.\n");
    return 0;
  }
  if (!defined($pincf)) {
    return ($self->{'pinfile'});
  }
  $self->{'pinfile'} = $pincf;
  $self->virtual_update_pins();
  return ($self->{'pinfile'});
}

sub make_pin_data_from_line {
  my $self = shift;
  my $l = shift;
  my ($a, $b, $c) = split(/:/, $l);
  my @ret;
  my %m;
  $m{'repo'} = $a;
  $m{'line'} = $l;
  if (defined($c)) {
    $m{'options'} = $c;
  }
  for (split(/,/, $b)) {
    s/^\s*//;
    s/\s*$//;
    my %mm = %m;
    $mm{'glob'} = $_;
    $mm{'re'} = glob_to_regex($_);
    push @ret, \%mm;
  }
  return @ret;
}

sub check_evaluate_pinning {
  my $self = shift;
  my @pins = (defined($self->{'pindata'}) ? @{$self->{'pindata'}} : ());
  my %pkgs = %{$self->{'packages'}};
  my ($mainpin) = $self->make_pin_data_from_line("main:*");
  $mainpin->{'hit'} = 1;
  push @pins, $mainpin;
  for my $pkg (keys %pkgs) {
    PINS: for my $pp (@pins) {
      my $pre = $pp->{'re'};
      if (($pkg =~ m/$pre/) &&
          (defined($self->{'packages'}{$pkg}{'tags'}{$pp->{'repo'}}))) {
        $self->{'packages'}{$pkg}{'target'} = $pp->{'repo'};
        $pp->{'hit'} = 1;
        last PINS;
      }
    }
  }
  my %catchall;
  for my $p (@pins) {
    $catchall{$p->{'repo'}} = 1 if ($p->{'glob'} eq "*");
  }
  for my $p (@pins) {
    next if defined($p->{'hit'});
    next if defined($catchall{$p->{'repo'}});
    tlwarn("tlmgr (TLPDB): pinning warning: the package pattern ",
           $p->{'glob'}, " on the line:\n  ", $p->{'line'},
           "\n  does not match any package\n");
  }
}


sub glob_to_regex {
    my $glob = shift;
    my $regex = glob_to_regex_string($glob);
    return qr/^$regex$/;
}

sub glob_to_regex_string
{
    my $glob = shift;
    my ($regex, $in_curlies, $escaping);
    local $_;
    my $first_byte = 1;
    for ($glob =~ m/(.)/gs) {
        if ($first_byte) {
            $regex .= '(?=[^\.])' unless $_ eq '.';
            $first_byte = 0;
        }
        if ($_ eq '/') {
            $first_byte = 1;
        }
        if ($_ eq '.' || $_ eq '(' || $_ eq ')' || $_ eq '|' ||
            $_ eq '+' || $_ eq '^' || $_ eq '$' || $_ eq '@' || $_ eq '%' ) {
            $regex .= "\\$_";
        }
        elsif ($_ eq '*') {
            $regex .= $escaping ? "\\*" : "[^/]*";
        }
        elsif ($_ eq '?') {
            $regex .= $escaping ? "\\?" : "[^/]";
        }
        elsif ($_ eq '{') {
            $regex .= $escaping ? "\\{" : "(";
            ++$in_curlies unless $escaping;
        }
        elsif ($_ eq '}' && $in_curlies) {
            $regex .= $escaping ? "}" : ")";
            --$in_curlies unless $escaping;
        }
        elsif ($_ eq ',' && $in_curlies) {
            $regex .= $escaping ? "," : "|";
        }
        elsif ($_ eq "\\") {
            if ($escaping) {
                $regex .= "\\\\";
                $escaping = 0;
            }
            else {
                $escaping = 1;
            }
            next;
        }
        else {
            $regex .= $_;
            $escaping = 0;
        }
        $escaping = 0;
    }
    print "# $glob $regex\n" if debug;

    return $regex;
}

sub match_glob {
    print "# ", join(', ', map { "'$_'" } @_), "\n" if debug;
    my $glob = shift;
    my $regex = glob_to_regex $glob;
    local $_;
    grep { $_ =~ $regex } @_;
}


1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPDB.pm@TeXLive/TLPDB.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPOBJ.pm@TeXLive/TLPOBJ.pm
"TeXLive/TLPOBJ.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLPOBJ;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }

use TeXLive::TLConfig qw($DefaultCategory $CategoriesRegexp 
                         $MetaCategoriesRegexp $InfraLocation 
                         %Compressors $DefaultCompressorFormat
                         $RelocPrefix $RelocTree);
use TeXLive::TLCrypto;
use TeXLive::TLTREE;
use TeXLive::TLUtils;

our $_tmp;
my $_containerdir;


sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    name        => $params{'name'},
    category    => defined($params{'category'}) ? $params{'category'} : $DefaultCategory,
    shortdesc   => $params{'shortdesc'},
    longdesc    => $params{'longdesc'},
    catalogue   => $params{'catalogue'},
    relocated   => $params{'relocated'},
    runfiles    => defined($params{'runfiles'}) ? $params{'runfiles'} : [],
    runsize     => $params{'runsize'},
    srcfiles    => defined($params{'srcfiles'}) ? $params{'srcfiles'} : [],
    srcsize     => $params{'srcsize'},
    docfiles    => defined($params{'docfiles'}) ? $params{'docfiles'} : [],
    docsize     => $params{'docsize'},
    executes    => defined($params{'executes'}) ? $params{'executes'} : [],
    postactions => defined($params{'postactions'}) ? $params{'postactions'} : [],
    binfiles    => defined($params{'binfiles'}) ? $params{'binfiles'} : {},
    binsize     => defined($params{'binsize'}) ? $params{'binsize'} : {},
    depends     => defined($params{'depends'}) ? $params{'depends'} : [],
    revision    => $params{'revision'},
    cataloguedata => defined($params{'cataloguedata'}) ? $params{'cataloguedata'} : {},
  };
  $_containerdir = $params{'containerdir'} if defined($params{'containerdir'});
  bless $self, $class;
  return $self;
}


sub copy {
  my $self = shift;
  my $bla = {};
  %$bla = %$self;
  bless $bla, "TeXLive::TLPOBJ";
  return $bla;
}


sub from_file {
  my $self = shift;
  if (@_ != 1) {
    die("TLPOBJ:from_file: Need a filename for initialization");
  }
  open(TMP,"<$_[0]") || die("Cannot open tlpobj file: $_[0]");
  $self->from_fh(\*TMP);
}

sub from_fh {
  my ($self,$fh,$multi) = @_;
  my $started = 0;
  my $lastcmd = "";
  my $arch;
  my $size;

  while (my $line = <$fh>) {
    chomp($line);
    
    dddebug("reading line: >>>$line<<<\n") if ($::opt_verbosity >= 3);
    $line =~ /^#/ && next;          # skip comment lines
    if ($line =~ /^\s*$/) {
      if (!$started) { next; }
      if (defined($multi)) {
        return 1;
      } else {
        die("No empty line allowed within tlpobj files!");
      }
    }

    my ($cmd, $arg) = split(/\s+/, $line, 2);
    $started || $cmd eq 'name'
      or die("First directive needs to be 'name', not $line");

    if ($cmd eq '') {
      if ($lastcmd eq "runfiles" || $lastcmd eq "srcfiles") {
        push @{$self->{$lastcmd}}, $arg;
      } elsif ($lastcmd eq "docfiles") {
        my ($f, $rest) = split(' ', $arg, 2);
        push @{$self->{'docfiles'}}, $f;
        if (defined $rest) {
          if ($rest =~ m/^language="(.*)"\s+details="(.*)"\s*$/) {
            $self->{'docfiledata'}{$f}{'details'} = $2;
            $self->{'docfiledata'}{$f}{'language'} = $1;
          } elsif ($rest =~ m/^details="(.*)"\s+language="(.*)"\s*$/) {
            $self->{'docfiledata'}{$f}{'details'} = $1;
            $self->{'docfiledata'}{$f}{'language'} = $2;
          } elsif ($rest =~ m/^details="(.*)"\s*$/) {
            $self->{'docfiledata'}{$f}{'details'} = $1;
          } elsif ($rest =~ m/^language="(.*)"\s*$/) {
            $self->{'docfiledata'}{$f}{'language'} = $1;
          } else {
            tlwarn("$0: Unparsable tagging in TLPDB line: $line\n");
          }
        }
      } elsif ($lastcmd eq "binfiles") {
        push @{$self->{'binfiles'}{$arch}}, $arg;
      } else {
        die("Continuation of $lastcmd not allowed, please fix tlpobj: line = $line!\n");
      }
    } elsif ($cmd eq "longdesc") {
      my $desc = defined $arg ? $arg : '';
      if (defined($self->{'longdesc'})) {
        $self->{'longdesc'} .= " $desc";
      } else {
        $self->{'longdesc'} = $desc;
      }
    } elsif ($cmd =~ /^catalogue-(.+)$/o) {
      $self->{'cataloguedata'}{$1} = $arg if defined $arg;
    } elsif ($cmd =~ /^(doc|src|run)files$/o) {
      my $type = $1;
      for (split ' ', $arg) {
        my ($k, $v) = split('=', $_, 2);
        if ($k eq 'size') {
        $self->{"${type}size"} = $v;
        } else {
          die "Unknown tag: $line";
        }
      }
    } elsif ($cmd eq 'containersize' || $cmd eq 'srccontainersize'
        || $cmd eq 'doccontainersize') {
      $arg =~ /^[0-9]+$/ or die "Invalid size value: $line!";
      $self->{$cmd} = $arg;
    } elsif ($cmd eq 'containermd5' || $cmd eq 'srccontainermd5'
        || $cmd eq 'doccontainermd5') {
      $arg =~ /^[a-f0-9]{32}$/ or die "Invalid md5 value: $line!";
      $self->{$cmd} = $arg;
    } elsif ($cmd eq 'containerchecksum' || $cmd eq 'srccontainerchecksum'
        || $cmd eq 'doccontainerchecksum') {
      $arg =~ /^[a-f0-9]{$TeXLive::TLConfig::ChecksumLength}$/
        or die "Invalid checksum value: $line!";
      $self->{$cmd} = $arg;
    } elsif ($cmd eq 'name') {
      $arg =~ /^([-.\w]+)$/ or die("Invalid name: $line!");
      $self->{'name'} = $arg;
      $started && die("Cannot have two name directives: $line!");
      $started = 1;
    } elsif ($cmd eq 'category') {
      $self->{'category'} = $arg;
      if ($self->{'category'} !~ /^$CategoriesRegexp/o) {
        tlwarn("Unknown category " . $self->{'category'} . " for package "
          . $self->name . " found.\nPlease update texlive.infra.\n");
      }
    } elsif ($cmd eq 'revision') {
      $self->{'revision'} = $arg;
    } elsif ($cmd eq 'shortdesc') {
      $self->{'shortdesc'} .= defined $arg ? $arg : ' ';
    } elsif ($cmd eq 'execute' || $cmd eq 'postaction'
        || $cmd eq 'depend') {
      push @{$self->{$cmd . 's'}}, $arg if defined $arg;
    } elsif ($cmd eq 'binfiles') {
      for (split ' ', $arg) {
        my ($k, $v) = split('=', $_, 2);
        if ($k eq 'arch') {
          $arch = $v;
        } elsif ($k eq 'size') {
          $size = $v;
        } else {
          die "Unknown tag: $line";
        }
      }
      if (defined($size)) {
        $self->{'binsize'}{$arch} = $size;
      }
    } elsif ($cmd eq 'relocated') {
      ($arg eq '0' || $arg eq '1') or die "Invalid value: $line!";
      $self->{'relocated'} = $arg;
    } elsif ($cmd eq 'catalogue') {
      $self->{'catalogue'} = $arg;
    } else {
      die("Unknown directive ...$line... , please fix it!");
    }
    $lastcmd = $cmd unless $cmd eq '';
  }
  return $started;
}

sub recompute_revision {
  my ($self,$tltree, $revtlpsrc) = @_;
  my @files = $self->all_files;
  my $filemax = 0;
  $self->revision(0);
  foreach my $f (@files) {
    $filemax = $tltree->file_svn_lastrevision($f);
    $self->revision(($filemax > $self->revision) ? $filemax : $self->revision);
  }
  if (defined($revtlpsrc)) {
    if ($self->revision < $revtlpsrc) {
      $self->revision($revtlpsrc);
    }
  }
}

sub recompute_sizes {
  my ($self,$tltree) = @_;
  $self->{'docsize'} = $self->_recompute_size("doc",$tltree);
  $self->{'srcsize'} = $self->_recompute_size("src",$tltree);
  $self->{'runsize'} = $self->_recompute_size("run",$tltree);
  foreach $a ($tltree->architectures) {
    $self->{'binsize'}{$a} = $self->_recompute_size("bin",$tltree,$a);
  }
}


sub _recompute_size {
  my ($self,$type,$tltree,$arch) = @_;
  my $nrivblocks = 0;
  if ($type eq "bin") {
    my %binfiles = %{$self->{'binfiles'}};
    if (defined($binfiles{$arch})) {
      foreach my $f (@{$binfiles{$arch}}) {
        my $s = $tltree->size_of($f);
        $nrivblocks += int($s/$TeXLive::TLConfig::BlockSize);
        $nrivblocks++ if (($s%$TeXLive::TLConfig::BlockSize) > 0);
      }
    }
  } else {
    if (defined($self->{"${type}files"}) && (@{$self->{"${type}files"}})) {
      foreach my $f (@{$self->{"${type}files"}}) {
        my $s = $tltree->size_of($f);
        if (defined($s)) {
          $nrivblocks += int($s/$TeXLive::TLConfig::BlockSize);
          $nrivblocks++ if (($s%$TeXLive::TLConfig::BlockSize) > 0);
        } else {
        tlwarn("$0: (TLPOBJ::_recompute_size) size of $type $f undefined?!\n");
        }
      }
    }
  }
  return $nrivblocks;
}

sub writeout {
  my $self = shift;
  my $fd = (@_ ? $_[0] : *STDOUT);
  print $fd "name ", $self->name, "\n";
  print $fd "category ", $self->category, "\n";
  defined($self->{'revision'}) && print $fd "revision $self->{'revision'}\n";
  defined($self->{'catalogue'}) && print $fd "catalogue $self->{'catalogue'}\n";
  defined($self->{'shortdesc'}) && print $fd "shortdesc $self->{'shortdesc'}\n";
  defined($self->{'license'}) && print $fd "license $self->{'license'}\n";
  defined($self->{'relocated'}) && $self->{'relocated'} && print $fd "relocated 1\n";
  select((select($fd),$~ = "multilineformat")[0]);
  $fd->format_lines_per_page (99999); # no pages in this format
  if (defined($self->{'longdesc'})) {
    $_tmp = "$self->{'longdesc'}";
    write $fd;  # use that multilineformat
  }
  if (defined($self->{'depends'})) {
    foreach (sort @{$self->{'depends'}}) {
      print $fd "depend $_\n";
    }
  }
  if (defined($self->{'executes'})) {
    foreach (sort @{$self->{'executes'}}) {
      print $fd "execute $_\n";
    }
  }
  if (defined($self->{'postactions'})) {
    foreach (sort @{$self->{'postactions'}}) {
      print $fd "postaction $_\n";
    }
  }
  if (defined($self->{'containersize'})) {
    print $fd "containersize $self->{'containersize'}\n";
  }
  if (defined($self->{'containermd5'})) {
    print $fd "containermd5 $self->{'containermd5'}\n";
  }
  if (defined($self->{'containerchecksum'})) {
    print $fd "containerchecksum $self->{'containerchecksum'}\n";
  }
  if (defined($self->{'doccontainersize'})) {
    print $fd "doccontainersize $self->{'doccontainersize'}\n";
  }
  if (defined($self->{'doccontainermd5'})) {
    print $fd "doccontainermd5 $self->{'doccontainermd5'}\n";
  }
  if (defined($self->{'doccontainerchecksum'})) {
    print $fd "doccontainerchecksum $self->{'doccontainerchecksum'}\n";
  }
  if (defined($self->{'docfiles'}) && (@{$self->{'docfiles'}})) {
    print $fd "docfiles size=$self->{'docsize'}\n";
    foreach my $f (sort @{$self->{'docfiles'}}) {
      print $fd " $f";
      if (defined($self->{'docfiledata'}{$f}{'details'})) {
        my $tmp = $self->{'docfiledata'}{$f}{'details'};
        print $fd ' details="', $tmp, '"';
      }
      if (defined($self->{'docfiledata'}{$f}{'language'})) {
        my $tmp = $self->{'docfiledata'}{$f}{'language'};
        print $fd ' language="', $tmp, '"';
      }
      print $fd "\n";
    }
  }
  if (defined($self->{'srccontainersize'})) {
    print $fd "srccontainersize $self->{'srccontainersize'}\n";
  }
  if (defined($self->{'srccontainermd5'})) {
    print $fd "srccontainermd5 $self->{'srccontainermd5'}\n";
  }
  if (defined($self->{'srccontainerchecksum'})) {
    print $fd "srccontainerchecksum $self->{'srccontainerchecksum'}\n";
  }
  if (defined($self->{'srcfiles'}) && (@{$self->{'srcfiles'}})) {
    print $fd "srcfiles size=$self->{'srcsize'}\n";
    foreach (sort @{$self->{'srcfiles'}}) {
      print $fd " $_\n";
    }
  }
  if (defined($self->{'runfiles'}) && (@{$self->{'runfiles'}})) {
    print $fd "runfiles size=$self->{'runsize'}\n";
    foreach (sort @{$self->{'runfiles'}}) {
      print $fd " $_\n";
    }
  }
  foreach my $arch (sort keys %{$self->{'binfiles'}}) {
    if (@{$self->{'binfiles'}{$arch}}) {
      print $fd "binfiles arch=$arch size=", $self->{'binsize'}{$arch}, "\n";
      foreach (sort @{$self->{'binfiles'}{$arch}}) {
        print $fd " $_\n";
      }
    }
  }
  foreach my $k (sort keys %{$self->cataloguedata}) {
    next if $k eq "date";
    print $fd "catalogue-$k ", $self->cataloguedata->{$k}, "\n";
  }
}

sub writeout_simple {
  my $self = shift;
  my $fd = (@_ ? $_[0] : *STDOUT);
  print $fd "name ", $self->name, "\n";
  print $fd "category ", $self->category, "\n";
  if (defined($self->{'depends'})) {
    foreach (sort @{$self->{'depends'}}) {
      print $fd "depend $_\n";
    }
  }
  if (defined($self->{'executes'})) {
    foreach (sort @{$self->{'executes'}}) {
      print $fd "execute $_\n";
    }
  }
  if (defined($self->{'postactions'})) {
    foreach (sort @{$self->{'postactions'}}) {
      print $fd "postaction $_\n";
    }
  }
  if (defined($self->{'docfiles'}) && (@{$self->{'docfiles'}})) {
    print $fd "docfiles\n";
    foreach (sort @{$self->{'docfiles'}}) {
      print $fd " $_\n";
    }
  }
  if (defined($self->{'srcfiles'}) && (@{$self->{'srcfiles'}})) {
    print $fd "srcfiles\n";
    foreach (sort @{$self->{'srcfiles'}}) {
      print $fd " $_\n";
    }
  }
  if (defined($self->{'runfiles'}) && (@{$self->{'runfiles'}})) {
    print $fd "runfiles\n";
    foreach (sort @{$self->{'runfiles'}}) {
      print $fd " $_\n";
    }
  }
  foreach my $arch (sort keys %{$self->{'binfiles'}}) {
    if (@{$self->{'binfiles'}{$arch}}) {
      print $fd "binfiles arch=$arch\n";
      foreach (sort @{$self->{'binfiles'}{$arch}}) {
        print $fd " $_\n";
      }
    }
  }
}

sub as_json {
  my $self = shift;
  my %addargs = @_;
  my %foo = %{$self};
  for my $k (keys %addargs) {
    if (defined($addargs{$k})) {
      $foo{$k} = $addargs{$k};
    } else {
      delete($foo{$k});
    }
  }
  for my $k (qw/revision runsize docsize srcsize containersize lrev rrev
                srccontainersize doccontainersize runcontainersize/) {
    $foo{$k} += 0 if exists($foo{$k});
  }
  for my $k (keys %{$foo{'binsize'}}) {
    $foo{'binsize'}{$k} += 0;
  }
  if (exists($foo{'relocated'})) {
    if ($foo{'relocated'}) {
      $foo{'relocated'} = TeXLive::TLUtils::True();
    } else {
      $foo{'relocated'} = TeXLive::TLUtils::False();
    }
  }
  my @docf = $self->docfiles;
  my $dfd = $self->docfiledata;
  my @newdocf;
  for my $f ($self->docfiles) {
    my %newd;
    $newd{'file'} = $f;
    if (defined($dfd->{$f})) {
      for my $k (keys %{$dfd->{$f}}) {
        $newd{$k} = $dfd->{$f}->{$k};
      }
    }
    push @newdocf, \%newd;
  }
  $foo{'docfiles'} = [ @newdocf ];
  delete($foo{'docfiledata'});
  my $utf8_encoded_json_text = TeXLive::TLUtils::encode_json(\%foo);
  return $utf8_encoded_json_text;
}


sub cancel_reloc_prefix {
  my $self = shift;
  my @docfiles = $self->docfiles;
  for (@docfiles) { s:^$RelocPrefix/::; }
  $self->docfiles(@docfiles);
  my @runfiles = $self->runfiles;
  for (@runfiles) { s:^$RelocPrefix/::; }
  $self->runfiles(@runfiles);
  my @srcfiles = $self->srcfiles;
  for (@srcfiles) { s:^$RelocPrefix/::; }
  $self->srcfiles(@srcfiles);
}

sub replace_reloc_prefix {
  my $self = shift;
  my @docfiles = $self->docfiles;
  for (@docfiles) { s:^$RelocPrefix/:$RelocTree/:; }
  $self->docfiles(@docfiles);
  my @runfiles = $self->runfiles;
  for (@runfiles) { s:^$RelocPrefix/:$RelocTree/:; }
  $self->runfiles(@runfiles);
  my @srcfiles = $self->srcfiles;
  for (@srcfiles) { s:^$RelocPrefix/:$RelocTree/:; }
  $self->srcfiles(@srcfiles);
  my $data = $self->docfiledata;
  my %newdata;
  while (my ($k, $v) = each %$data) {
    $k =~ s:^$RelocPrefix/:$RelocTree/:;
    $newdata{$k} = $v;
  }
  $self->docfiledata(%newdata);
}

sub cancel_common_texmf_tree {
  my $self = shift;
  my @docfiles = $self->docfiles;
  for (@docfiles) { s:^$RelocTree/:$RelocPrefix/:; }
  $self->docfiles(@docfiles);
  my @runfiles = $self->runfiles;
  for (@runfiles) { s:^$RelocTree/:$RelocPrefix/:; }
  $self->runfiles(@runfiles);
  my @srcfiles = $self->srcfiles;
  for (@srcfiles) { s:^$RelocTree/:$RelocPrefix/:; }
  $self->srcfiles(@srcfiles);
  my $data = $self->docfiledata;
  my %newdata;
  while (my ($k, $v) = each %$data) {
    $k =~ s:^$RelocTree/:$RelocPrefix/:;
    $newdata{$k} = $v;
  }
  $self->docfiledata(%newdata);
}

sub common_texmf_tree {
  my $self = shift;
  my $tltree;
  my $dd = 0;
  my @files = $self->all_files;
  foreach ($self->all_files) {
    my $tmp;
    ($tmp) = split m@/@;
    if (defined($tltree) && ($tltree ne $tmp)) {
      return;
    } else {
      $tltree = $tmp;
    }
  }
  if (!@files) {
    $tltree = $RelocTree;
  }
  return $tltree;
}


sub make_container {
  my ($self, $type, $instroot, %other) = @_;
  my $destdir = ($other{'destdir'} || undef);
  my $containername = ($other{'containername'} || undef);
  my $relative = ($other{'relative'} || undef);
  my $user = ($other{'user'} || undef);
  my $copy_instead_of_link = ($other{'copy_instead_of_link'} || undef);
  if (!($type eq 'tar' ||
        TeXLive::TLUtils::member($type, @{$::progs{'working_compressors'}}))) {
    tlwarn "$0: TLPOBJ supports @{$::progs{'working_compressors'}} and tar containers, not $type\n";
    tlwarn "$0: falling back to $DefaultCompressorFormat as container type!\n";
    $type = $DefaultCompressorFormat;
  }

  if (!defined($containername)) {
    $containername = $self->name;
  }
  my @files = $self->all_files;
  my $compresscmd;
  my $tlpobjdir = "$InfraLocation/tlpobj";
  @files = TeXLive::TLUtils::sort_uniq(@files);
  my $tltree;
  if ($relative) {
    $tltree = $self->common_texmf_tree;
    if (!defined($tltree)) {
      die ("$0: package $containername spans multiple trees, "
           . "relative generation not allowed");
    }
    if ($tltree ne $RelocTree) {
      die ("$0: building $containername container relocatable but the common"
           . " prefix is not $RelocTree");
    } 
    s,^$RelocTree/,, foreach @files;
  }
  require Cwd;
  my $cwd = &Cwd::getcwd;
  if ("$destdir" !~ m@^(.:)?[/\\]@) {
    $destdir = "$cwd/$destdir";
  }
  &TeXLive::TLUtils::mkdirhier("$destdir");
  chdir($instroot);
  my $removetlpkgdir = 0;
  if ($relative) {
    chdir("./$tltree");
    $removetlpkgdir = 1;
  }
  my $removetlpobjdir = 0;
  if (! -d "$tlpobjdir") {
    &TeXLive::TLUtils::mkdirhier("$tlpobjdir");
    $removetlpobjdir = 1;
  }
  open(TMP,">$tlpobjdir/$self->{'name'}.tlpobj") 
  || die "$0: create($tlpobjdir/$self->{'name'}.tlpobj) failed: $!";
  my $selfcopy = $self->copy;
  if ($relative) {
    $selfcopy->cancel_common_texmf_tree;
    $selfcopy->relocated($relative);
  }
  $selfcopy->writeout(\*TMP);
  close(TMP);
  push(@files, "$tlpobjdir/$self->{'name'}.tlpobj");
  my $tarname = "$containername.r" . $self->revision . ".tar";
  my $unversionedtar;
  $unversionedtar = "$containername.tar" if (! $user);

  my $tar = $::progs{'tar'};
  if (!defined($tar)) {
    tlwarn("$0: programs not set up, trying \"tar\".\n");
    $tar = "tar";
  }

  $containername = $tarname;

  my $is_user_container = $user;
  my @attrs
    = $is_user_container
      ? ()
      : ( "--owner", "0",  "--group", "0",  "--exclude", ".svn",
          "--format", "ustar" );
  my @cmdline = ($tar, "-cf", "$destdir/$tarname", @attrs);
  
  my @files_to_backup = ();
  for my $f (@files) {
    if (-f $f || -l $f) {
      push(@files_to_backup, $f);
    } elsif (! -e $f) {
      tlwarn("$0: (make_container $containername) $f does not exist\n");
    } else {
      tlwarn("$0: (make_container $containername) $f not file or symlink\n");
      if (! wndws()) {
        tlwarn("$0:   ", `ls -l $f 2>&1`);
      }
    }
  }
  
  my $tartempfile = "";
  if (wndws()) {
    my $tmpdir = TeXLive::TLUtils::tl_tmpdir();
    $tartempfile = "$tmpdir/mc$$";
    open(TMP, ">$tartempfile") || die "open(>$tartempfile) failed: $!";
    print TMP map { "$_\n" } @files_to_backup;
    close(TMP) || warn "close(>$tartempfile) failed: $!";
    push(@cmdline, "-T", $tartempfile);
  } else {
    if (length ("@files_to_backup") > 50000) {
      @files_to_backup = TeXLive::TLUtils::collapse_dirs(@files_to_backup);
      s,^$instroot/,, foreach @files_to_backup;
      if ($relative) {
        s,^$RelocTree/,, foreach @files_to_backup;
      }
    }
    push(@cmdline, @files_to_backup);
  }

  unlink("$destdir/$tarname");
  unlink("$destdir/$unversionedtar") if (! $user);
  unlink("$destdir/$containername");
  xsystem(@cmdline);

  if ($type ne 'tar') {
    my $compressor = $::progs{$type};
    if (!defined($compressor)) {
      tlwarn("$0: programs not set up, trying \"$type\".\n");
      $compressor = $type;
    }
    my @compressorargs = @{$Compressors{$type}{'compress_args'}};
    my $compressorextension = $Compressors{$type}{'extension'};
    $containername = "$tarname.$compressorextension";
    debug("selected compressor: $compressor with @compressorargs, "
          . "on $destdir/$tarname\n");
  
    if (-r "$destdir/$tarname") {
      if (system($compressor, @compressorargs, "$destdir/$tarname")) {
        tlwarn("$0: Couldn't compress $destdir/$tarname\n");
        return (0,0, "");
      }
      unlink("$destdir/$tarname")
        if ((-r "$destdir/$tarname") && (-r "$destdir/$containername"));
      if (! $user) {
        my $linkname = "$destdir/$unversionedtar.$compressorextension";
        unlink($linkname) if (-r $linkname);
        if ($copy_instead_of_link) {
          TeXLive::TLUtils::copy("-f", "$destdir/$containername", $linkname)
        } else {
          if (!symlink($containername, $linkname)) {
            tlwarn("$0: Couldn't generate link $linkname -> $containername?\n");
          }
        }
      }
    } else {
      tlwarn("$0: Couldn't find $destdir/$tarname to run $compressor\n");
      return (0, 0, "");
    }
  }
  
  if (! -r "$destdir/$containername") {
    tlwarn ("$0: Couldn't find $destdir/$containername\n");
    return (0, 0, "");
  }
  my $size = (stat "$destdir/$containername") [7];
  my $checksum = "";
  if (!$is_user_container || $::checksum_method) {
    $checksum = TeXLive::TLCrypto::tlchecksum("$destdir/$containername");
  }
  
  unlink("$tlpobjdir/$self->{'name'}.tlpobj");
  unlink($tartempfile) if $tartempfile;
  rmdir($tlpobjdir) if $removetlpobjdir;
  rmdir($InfraLocation) if $removetlpkgdir;
  xchdir($cwd);

  debug(" done $containername, size $size, csum $checksum\n");
  return ($size, $checksum, "$destdir/$containername");
}



sub is_arch_dependent {
  my $self = shift;
  if (keys %{$self->{'binfiles'}}) {
    return 1;
  } else {
    return 0;
  }
}

sub total_size {
  my ($self,@archs) = @_;
  my $ret = $self->docsize + $self->runsize + $self->srcsize;
  if ($self->is_arch_dependent) {
    my $max = 0;
    my %foo = %{$self->binsize};
    foreach my $k (keys %foo) {
      $max = $foo{$k} if ($foo{$k} > $max);
    }
    $ret += $max;
  }
  return($ret);
}


sub update_from_catalogue {
  my ($self, $tlc) = @_;
  my $tlcname = $self->name;
  if (defined($self->catalogue)) {
    $tlcname = $self->catalogue;
  } elsif ($tlcname =~ m/^bin-(.*)$/) {
    if (!defined($tlc->entries->{$tlcname})) {
      $tlcname = $1;
    }
  }
  $tlcname = lc($tlcname);
  if (defined($tlc->entries->{$tlcname})) {
    my $entry = $tlc->entries->{$tlcname};
    if ($entry->entry->{'id'} ne $tlcname) {
      $self->catalogue($entry->entry->{'id'});
    }
    if (defined($entry->license)) {
      $self->cataloguedata->{'license'} ||= $entry->license;
    }
    if (defined($entry->version) && $entry->version ne "") {
      $self->cataloguedata->{'version'} ||= $entry->version;
    }
    if (defined($entry->ctan) && $entry->ctan ne "") {
      $self->cataloguedata->{'ctan'} ||= $entry->ctan;
    }
    if (@{$entry->also}) {
      $self->cataloguedata->{'also'} ||= "@{$entry->also}";
    }
    if (@{$entry->alias}) {
      $self->cataloguedata->{'alias'} ||= "@{$entry->alias}";
    }
    if (@{$entry->topics}) {
      $self->cataloguedata->{'topics'} ||= "@{$entry->topics}";
    }
    if (%{$entry->contact}) {
      for my $k (keys %{$entry->contact}) {
        $self->cataloguedata->{"contact-$k"} ||= $entry->contact->{$k};
      }
    }
    if (defined($entry->caption) && $entry->caption ne "") {
      $self->{'shortdesc'} = $entry->caption unless $self->{'shortdesc'};
    }
    if (defined($entry->description) && $entry->description ne "") {
      $self->{'longdesc'} = $entry->description unless $self->{'longdesc'};
    }
    my @tcdocfiles = keys %{$entry->docs};  # Catalogue doc files.
    my %tcdocfilebasenames;                 # basenames of those, as we go.
    my @tlpdocfiles = $self->docfiles;      # TL doc files.
    foreach my $tcdocfile (sort @tcdocfiles) {  # sort so shortest first
      my $tcdocfilebasename = $tcdocfile;
      $tcdocfilebasename =~ s/^ctan://;  # remove ctan: prefix
      $tcdocfilebasename =~ s,.*/,,;     # remove all but the base file name
      next if exists $tcdocfilebasenames{$tcdocfilebasename};
      $tcdocfilebasenames{$tcdocfilebasename} = 1;
      foreach my $tlpdocfile (@tlpdocfiles) {
        if ($tlpdocfile =~ m,/$tcdocfilebasename$,) {
          if (defined($entry->docs->{$tcdocfile}{'details'})) {
            my $tmp = $entry->docs->{$tcdocfile}{'details'};
            $tmp =~ s/"//g;
            $self->{'docfiledata'}{$tlpdocfile}{'details'} = $tmp;
          }
          if (defined($entry->docs->{$tcdocfile}{'language'})) {
            my $tmp = $entry->docs->{$tcdocfile}{'language'};
            $self->{'docfiledata'}{$tlpdocfile}{'language'} = $tmp;
          }
        }
      }
    }
  }
}

sub is_meta_package {
  my $self = shift;
  if ($self->category =~ /^$MetaCategoriesRegexp$/) {
    return 1;
  }
  return 0;
}

sub docfiles_package {
  my $self = shift;
  if (not($self->docfiles)) { return ; }
  my $tlp = new TeXLive::TLPOBJ;
  $tlp->name($self->name . ".doc");
  $tlp->shortdesc("doc files of " . $self->name);
  $tlp->revision($self->revision);
  $tlp->category($self->category);
  $tlp->add_docfiles($self->docfiles);
  $tlp->docsize($self->docsize);
  return($tlp);
}

sub srcfiles_package {
  my $self = shift;
  if (not($self->srcfiles)) { return ; }
  my $tlp = new TeXLive::TLPOBJ;
  $tlp->name($self->name . ".source");
  $tlp->shortdesc("source files of " . $self->name);
  $tlp->revision($self->revision);
  $tlp->category($self->category);
  $tlp->add_srcfiles($self->srcfiles);
  $tlp->srcsize($self->srcsize);
  return($tlp);
}

sub split_bin_package {
  my $self = shift;
  my %binf = %{$self->binfiles};
  my @retlist;
  foreach $a (keys(%binf)) {
    my $tlp = new TeXLive::TLPOBJ;
    $tlp->name($self->name . ".$a");
    $tlp->shortdesc("$a files of " . $self->name);
    $tlp->revision($self->revision);
    $tlp->category($self->category);
    $tlp->add_binfiles($a,@{$binf{$a}});
    $tlp->binsize( $a => $self->binsize->{$a} );
    push @retlist, $tlp;
  }
  if (keys(%binf)) {
    push @{$self->{'depends'}}, $self->name . ".ARCH";
  }
  $self->clear_binfiles();
  return(@retlist);
}


sub add_files {
  my ($self,$type,@files) = @_;
  die("Cannot use add_files for binfiles, we need that arch!")
    if ($type eq "bin");
  &TeXLive::TLUtils::push_uniq(\@{ $self->{"${type}files"} }, @files);
}

sub remove_files {
  my ($self,$type,@files) = @_;
  die("Cannot use remove_files for binfiles, we need that arch!")
    if ($type eq "bin");
  my @finalfiles;
  foreach my $f (@{$self->{"${type}files"}}) {
    if (not(&TeXLive::TLUtils::member($f,@files))) {
      push @finalfiles,$f;
    }
  }
  $self->{"${type}files"} = [ @finalfiles ];
}

sub contains_file {
  my ($self,$fn) = @_;
  my $ret = "";
  if ($fn =~ m!/!) {
    return(grep(m!$fn$!, $self->all_files));
  } else {
    return(grep(m!(^|/)$fn$!,$self->all_files));
  }
}

sub all_files {
  my ($self) = shift;
  my @ret = ();

  push (@ret, $self->docfiles);
  push (@ret, $self->runfiles);
  push (@ret, $self->srcfiles);
  push (@ret, $self->allbinfiles);

  return @ret;
}

sub allbinfiles {
  my $self = shift;
  my @ret = ();
  my %binfiles = %{$self->binfiles};

  foreach my $arch (keys %binfiles) {
    push (@ret, @{$binfiles{$arch}});
  }

  return @ret;
}

sub format_definitions {
  my $self = shift;
  my $pkg = $self->name;
  my @ret;
  for my $e ($self->executes) {
    if ($e =~ m/AddFormat\s+(.*)\s*/) {
      my %r = TeXLive::TLUtils::parse_AddFormat_line("$1");
      if (defined($r{"error"})) {
        die "$r{'error'}, package $pkg, execute $e";
      }
      push @ret, \%r;
    }
  }
  return @ret;
}

sub fmtutil_cnf_lines {
  my $obj = shift;
  my @disabled = @_;
  my @fmtlines = ();
  my $first = 1;
  my $pkg = $obj->name;
  foreach my $e ($obj->executes) {
    if ($e =~ m/AddFormat\s+(.*)\s*/) {
      my %r = TeXLive::TLUtils::parse_AddFormat_line("$1");
      if (defined($r{"error"})) {
        die "$r{'error'}, package $pkg, execute $e";
      }
      if ($first) {
        push @fmtlines, "#\n# from $pkg:\n";
        $first = 0;
      }
      my $mode = ($r{"mode"} ? "" : "#! ");
      $mode = "#! " if TeXLive::TLUtils::member ($r{'name'}, @disabled);
      push @fmtlines, "$mode$r{'name'} $r{'engine'} $r{'patterns'} $r{'options'}\n";
    }
  }
  return @fmtlines;
}


sub updmap_cfg_lines {
  my $obj = shift;
  my @disabled = @_;
  my %maps;
  foreach my $e ($obj->executes) {
    if ($e =~ m/addMap (.*)$/) {
      $maps{$1} = 1;
    } elsif ($e =~ m/addMixedMap (.*)$/) {
      $maps{$1} = 2;
    } elsif ($e =~ m/addKanjiMap (.*)$/) {
      $maps{$1} = 3;
    }
  }
  my @updmaplines;
  foreach (sort keys %maps) {
    next if TeXLive::TLUtils::member($_, @disabled);
    if ($maps{$_} == 1) {
      push @updmaplines, "Map $_\n";
    } elsif ($maps{$_} == 2) {
      push @updmaplines, "MixedMap $_\n";
    } elsif ($maps{$_} == 3) {
      push @updmaplines, "KanjiMap $_\n";
    } else {
      tlerror("Should not happen!\n");
    }
  }
  return(@updmaplines);
}


our @disabled; # global, should handle differently ...

sub language_dat_lines {
  my $self = shift;
  local @disabled = @_;  # we use @disabled in the nested sub
  my @lines = $self->_parse_hyphen_execute(\&make_dat_lines, 'dat');
  return @lines;

  sub make_dat_lines {
    my ($name, $lhm, $rhm, $file, $syn) = @_;
    my @ret;
    return if TeXLive::TLUtils::member($name, @disabled);
    push @ret, "$name $file\n";
    foreach (@$syn) {
      push @ret, "=$_\n";
    }
    return @ret;
  }
}


sub language_def_lines {
  my $self = shift;
  local @disabled = @_;  # we use @disabled in the nested sub
  my @lines = $self->_parse_hyphen_execute(\&make_def_lines, 'def');
  return @lines;

  sub make_def_lines {
    my ($name, $lhm, $rhm, $file, $syn) = @_;
    return if TeXLive::TLUtils::member($name, @disabled);
    my $exc = "";
    my @ret;
    push @ret, "\\addlanguage\{$name\}\{$file\}\{$exc\}\{$lhm\}\{$rhm\}\n";
    foreach (@$syn) {
      push @ret, "\\addlanguage\{$_\}\{$file\}\{$exc\}\{$lhm\}\{$rhm\}\n";
    }
    return @ret;
  }
}


sub language_lua_lines {
  my $self = shift;
  local @disabled = @_;  # we use @disabled in the nested sub
  my @lines = $self->_parse_hyphen_execute(\&make_lua_lines, 'lua', '--');
  return @lines;

  sub make_lua_lines {
    my ($name, $lhm, $rhm, $file, $syn, $patt, $hyph, $special) = @_;
    return if TeXLive::TLUtils::member($name, @disabled);
    my @syn = (@$syn); # avoid modifying the original
    map { $_ = "'$_'" } @syn;
    my @ret;
    push @ret, "['$name'] = {", "\tloader = '$file',",
               "\tlefthyphenmin = $lhm,", "\trighthyphenmin = $rhm,",
               "\tsynonyms = { " . join(', ', @syn) . " },";
    push @ret, "\tpatterns = '$patt'," if defined $patt;
    push @ret, "\thyphenation = '$hyph'," if defined $hyph;
    push @ret, "\tspecial = '$special'," if defined $special;
    push @ret, '},';
    map { $_ = "\t$_\n" } @ret;
    return @ret;
  }
}


sub _parse_hyphen_execute {
  my ($obj, $coderef, $db, $cc) = @_;
  $cc ||= '%'; # default comment char
  my @langlines = ();
  my $pkg = $obj->name;
  my $first = 1;
  foreach my $e ($obj->executes) {
    if ($e =~ m/AddHyphen\s+(.*)\s*/) {
      my %r = TeXLive::TLUtils::parse_AddHyphen_line("$1");
      if (defined($r{"error"})) {
        die "$r{'error'}, package $pkg, execute $e";
      }
      if (not TeXLive::TLUtils::member($db, @{$r{"databases"}})) {
        next;
      }
      if ($first) {
        push @langlines, "$cc from $pkg:\n";
        $first = 0;
      }
      if ($r{"comment"}) {
          push @langlines, "$cc $r{comment}\n";
      }
      my @foo = &$coderef ($r{"name"}, $r{"lefthyphenmin"},
                           $r{"righthyphenmin"}, $r{"file"}, $r{"synonyms"},
                           $r{"file_patterns"}, $r{"file_exceptions"},
                           $r{"luaspecial"});
      push @langlines, @foo;
    }
  }
  return @langlines;
}



sub _set_get_array_value {
  my $self = shift;
  my $key = shift;
  if (@_) { 
    if (defined($_[0])) {
      $self->{$key} = [ @_ ];
    } else {
      $self->{$key} = [ ];
    }
  }
  return @{ $self->{$key} };
}
sub name {
  my $self = shift;
  if (@_) { $self->{'name'} = shift }
  return $self->{'name'};
}
sub category {
  my $self = shift;
  if (@_) { $self->{'category'} = shift }
  return $self->{'category'};
}
sub shortdesc {
  my $self = shift;
  if (@_) { $self->{'shortdesc'} = shift }
  return $self->{'shortdesc'};
}
sub longdesc {
  my $self = shift;
  if (@_) { $self->{'longdesc'} = shift }
  return $self->{'longdesc'};
}
sub revision {
  my $self = shift;
  if (@_) { $self->{'revision'} = shift }
  return $self->{'revision'};
}
sub relocated {
  my $self = shift;
  if (@_) { $self->{'relocated'} = shift }
  return ($self->{'relocated'} ? 1 : 0);
}
sub catalogue {
  my $self = shift;
  if (@_) { $self->{'catalogue'} = shift }
  return $self->{'catalogue'};
}
sub srcfiles {
  _set_get_array_value(shift, "srcfiles", @_);
}
sub containersize {
  my $self = shift;
  if (@_) { $self->{'containersize'} = shift }
  return ( defined($self->{'containersize'}) ? $self->{'containersize'} : -1 );
}
sub srccontainersize {
  my $self = shift;
  if (@_) { $self->{'srccontainersize'} = shift }
  return ( defined($self->{'srccontainersize'}) ? $self->{'srccontainersize'} : -1 );
}
sub doccontainersize {
  my $self = shift;
  if (@_) { $self->{'doccontainersize'} = shift }
  return ( defined($self->{'doccontainersize'}) ? $self->{'doccontainersize'} : -1 );
}
sub containermd5 {
  my $self = shift;
  if (@_) { $self->{'containermd5'} = shift }
  if (defined($self->{'containermd5'})) {
    return ($self->{'containermd5'});
  } else {
    tlwarn("TLPOBJ: MD5 sums are no longer supported, please adapt your code!\n");
    return ("");
  }
}
sub srccontainermd5 {
  my $self = shift;
  if (@_) { $self->{'srccontainermd5'} = shift }
  if (defined($self->{'srccontainermd5'})) {
    return ($self->{'srccontainermd5'});
  } else {
    tlwarn("TLPOBJ: MD5 sums are no longer supported, please adapt your code!\n");
    return ("");
  }
}
sub doccontainermd5 {
  my $self = shift;
  if (@_) { $self->{'doccontainermd5'} = shift }
  if (defined($self->{'doccontainermd5'})) {
    return ($self->{'doccontainermd5'});
  } else {
    tlwarn("TLPOBJ: MD5 sums are no longer supported, please adapt your code!\n");
    return ("");
  }
}
sub containerchecksum {
  my $self = shift;
  if (@_) { $self->{'containerchecksum'} = shift }
  return ( defined($self->{'containerchecksum'}) ? $self->{'containerchecksum'} : "" );
}
sub srccontainerchecksum {
  my $self = shift;
  if (@_) { $self->{'srccontainerchecksum'} = shift }
  return ( defined($self->{'srccontainerchecksum'}) ? $self->{'srccontainerchecksum'} : "" );
}
sub doccontainerchecksum {
  my $self = shift;
  if (@_) { $self->{'doccontainerchecksum'} = shift }
  return ( defined($self->{'doccontainerchecksum'}) ? $self->{'doccontainerchecksum'} : "" );
}
sub srcsize {
  my $self = shift;
  if (@_) { $self->{'srcsize'} = shift }
  return ( defined($self->{'srcsize'}) ? $self->{'srcsize'} : 0 );
}
sub clear_srcfiles {
  my $self = shift;
  $self->{'srcfiles'} = [ ] ;
}
sub add_srcfiles {
  my ($self,@files) = @_;
  $self->add_files("src",@files);
}
sub remove_srcfiles {
  my ($self,@files) = @_;
  $self->remove_files("src",@files);
}
sub docfiles {
  _set_get_array_value(shift, "docfiles", @_);
}
sub clear_docfiles {
  my $self = shift;
  $self->{'docfiles'} = [ ] ;
}
sub docsize {
  my $self = shift;
  if (@_) { $self->{'docsize'} = shift }
  return ( defined($self->{'docsize'}) ? $self->{'docsize'} : 0 );
}
sub add_docfiles {
  my ($self,@files) = @_;
  $self->add_files("doc",@files);
}
sub remove_docfiles {
  my ($self,@files) = @_;
  $self->remove_files("doc",@files);
}
sub docfiledata {
  my $self = shift;
  my %newfiles = @_;
  if (@_) { $self->{'docfiledata'} = \%newfiles }
  return $self->{'docfiledata'};
}
sub binfiles {
  my $self = shift;
  my %newfiles = @_;
  if (@_) { $self->{'binfiles'} = \%newfiles }
  return $self->{'binfiles'};
}
sub clear_binfiles {
  my $self = shift;
  $self->{'binfiles'} = { };
}
sub binsize {
  my $self = shift;
  my %newsizes = @_;
  if (@_) { $self->{'binsize'} = \%newsizes }
  return $self->{'binsize'};
}
sub add_binfiles {
  my ($self,$arch,@files) = @_;
  &TeXLive::TLUtils::push_uniq(\@{ $self->{'binfiles'}{$arch} }, @files);
}
sub remove_binfiles {
  my ($self,$arch,@files) = @_;
  my @finalfiles;
  foreach my $f (@{$self->{'binfiles'}{$arch}}) {
    if (not(&TeXLive::TLUtils::member($f,@files))) {
      push @finalfiles,$f;
    }
  }
  $self->{'binfiles'}{$arch} = [ @finalfiles ];
}
sub runfiles {
  _set_get_array_value(shift, "runfiles", @_);
}
sub clear_runfiles {
  my $self = shift;
  $self->{'runfiles'} = [ ] ;
}
sub runsize {
  my $self = shift;
  if (@_) { $self->{'runsize'} = shift }
  return ( defined($self->{'runsize'}) ? $self->{'runsize'} : 0 );
}
sub add_runfiles {
  my ($self,@files) = @_;
  $self->add_files("run",@files);
}
sub remove_runfiles {
  my ($self,@files) = @_;
  $self->remove_files("run",@files);
}
sub depends {
  _set_get_array_value(shift, "depends", @_);
}
sub executes {
  _set_get_array_value(shift, "executes", @_);
}
sub postactions {
  _set_get_array_value(shift, "postactions", @_);
}
sub containerdir {
  my @self = shift;
  if (@_) { $_containerdir = $_[0] }
  return $_containerdir;
}
sub cataloguedata {
  my $self = shift;
  my %ct = @_;
  if (@_) { $self->{'cataloguedata'} = \%ct }
  return $self->{'cataloguedata'};
}

$: = " \n"; # don't break at -
format multilineformat =
longdesc ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~
$_tmp
.

1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPOBJ.pm@TeXLive/TLPOBJ.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPSRC.pm@TeXLive/TLPSRC.pm
"TeXLive/TLPSRC.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLPSRC;

use FileHandle;
use TeXLive::TLConfig qw($CategoriesRegexp $DefaultCategory);
use TeXLive::TLUtils;
use TeXLive::TLPOBJ;
use TeXLive::TLTREE;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


my $_tmp; # sorry
my %autopatterns;  # computed once internally

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    name        => $params{'name'},
    category    => defined($params{'category'}) ? $params{'category'}
                                                : $DefaultCategory,
    shortdesc   => $params{'shortdesc'},
    longdesc    => $params{'longdesc'},
    catalogue   => $params{'catalogue'},
    runpatterns => $params{'runpatterns'},
    srcpatterns => $params{'srcpatterns'},
    docpatterns => $params{'docpatterns'},
    binpatterns => $params{'binpatterns'},
    postactions => $params{'postactions'},
    executes    => defined($params{'executes'}) ? $params{'executes'} : [],
    depends     => defined($params{'depends'}) ? $params{'depends'} : [],
  };
  bless $self, $class;
  return $self;
}


sub from_file {
  my $self = shift;
  die "need exactly one filename for initialization" if @_ != 1;
  my $srcfile = $_[0];
  my $pkgname = TeXLive::TLUtils::basename($srcfile);
  $pkgname =~ s/\.tlpsrc$//;

  if (! -r "$srcfile") {
    (my $trydir = $INC{"TeXLive/TLPSRC.pm"}) =~ s,/[^/]*$,,;
    chomp ($trydir = `cd $trydir/../tlpsrc && pwd`);  # make absolute
    my $tryfile = "$trydir/$pkgname.tlpsrc";
    $srcfile = $tryfile if -r $tryfile;
  }
  
  open(TMP, "<$srcfile") || die("failed to open tlpsrc '$srcfile': $!");
  my @lines = <TMP>;
  close(TMP);

  my $name = $pkgname;
  my $category = "Package";
  my $shortdesc = "";
  my $longdesc= "";
  my $catalogue = "";
  my (@executes, @depends);
  my (@runpatterns, @docpatterns, @binpatterns, @srcpatterns);
  my (@postactions);
  my $foundnametag = 0;
  my $finished = 0;
  my $savedline = "";
  my %tlpvars;
  $tlpvars{"PKGNAME"} = $name;

  my $lineno = 0;
  for my $line (@lines) {
    $lineno++;
    
    $line =~ s/\s+#.*$//;

    if ($line =~ /^(.*)\\$/) {
      $savedline .= $1;
      next;
    }
    if ($savedline ne "") {
      $line = "$savedline$line";
      $savedline = "";
    }

    $line =~ /^\s*#/ && next;          # skip comment lines
    next if $line =~ /^\s*$/;          # skip blank lines
    $line =~ /^ /
      && die "$srcfile:$lineno: non-continuation indentation not allowed: `$line'";
    $line =~ s/\s+#.*$//;
    $line =~ s/\s+$//;

    if ($line !~ /^(short|long)desc\s/) {
      for my $k (keys %tlpvars) {
        $line =~ s/\$\{\Q$k\E\}/$tlpvars{$k}/g;
      }
      (my $testline = $line) =~ s,\$\{ARCH\},,g;
      $testline =~ s,\$\{(global_[^}]*)\},,g;
      $testline =~ /\$/
        && die "$srcfile:$lineno: variable undefined or syntax error: $line\n";
    } # end variable expansion.

    if ($line =~ /^name\s/) {
      $line =~ /^name\s+([-\w]+(\.windows)?|(00)?texlive\..*)$/;
      $foundnametag 
        && die "$srcfile:$lineno: second name directive not allowed: $line"
               . "(have $name)\n";
      $name = $1;
      $foundnametag = 1;
      $tlpvars{"PKGNAME"} = $name;

    } elsif ($line =~ /^category\s+$CategoriesRegexp$/) {
      $category = $1;

    } elsif ($line =~ /^shortdesc\s*(.*)$/) {
      $shortdesc
        && die "$srcfile:$lineno: second shortdesc not allowed: $line"
               . "(have $shortdesc)\n";
      $shortdesc = $1;

    } elsif ($line =~ /^shortdesc$/) {
      $shortdesc = "";

    } elsif ($line =~ /^longdesc$/) {
      $longdesc .= " ";

    } elsif ($line =~ /^longdesc\s+(.*)$/) {
      $longdesc .= "$1 ";

    } elsif ($line =~ /^catalogue\s+(.*)$/) {
      $catalogue
        && die "$srcfile:$lineno: second catalogue not allowed: $line"
               . "(have $catalogue)\n";
      $catalogue = $1;

    } elsif ($line =~ /^runpattern\s+(.*)$/) {
      push (@runpatterns, $1) if ($1 ne "");

    } elsif ($line =~ /^srcpattern\s+(.*)$/) {
      push (@srcpatterns, $1) if ($1 ne "");

    } elsif ($line =~ /^docpattern\s+(.*)$/) {
      push (@docpatterns, $1) if ($1 ne "");

    } elsif ($line =~ /^binpattern\s+(.*)$/) {
      push (@binpatterns, $1) if ($1 ne "");

    } elsif ($line =~ /^execute\s+(.*)$/) {
      push (@executes, $1) if ($1 ne "");

    } elsif ($line =~ /^(depend|hard)\s+(.*)$/) {
      push (@depends, $2) if ($2 ne "");

    } elsif ($line =~ /^postaction\s+(.*)$/) {
      push (@postactions, $1) if ($1 ne "");

    } elsif ($line =~ /^tlpsetvar\s+([-_a-zA-Z0-9]+)\s+(.*)$/) {
      $tlpvars{$1} = $2;

    } elsif ($line =~ /^catalogue-([^\s]+)\s+(.*)$/o) {
      $self->{'cataloguedata'}{$1} = $2 if defined $2;

    } else {
      die "$srcfile:$lineno: unknown tlpsrc directive, fix: $line\n";
    }
  }
  $self->_srcfile($srcfile);
  $self->_tlpvars(\%tlpvars);
  if ($name =~ m/^[[:space:]]*$/) {
    die "Cannot deduce name from file argument and name tag not found";
  }
  $shortdesc =~ s/\s+$//g;  # rm trailing whitespace (shortdesc)
  $longdesc =~ s/\s+$//g;   # rm trailing whitespace (longdesc)
  $longdesc =~ s/\s\s+/ /g; # collapse multiple whitespace characters to one
  $longdesc =~ s,http://grants.nih.gov/,grants.nih.gov/,g;
  $self->name($name);
  $self->category($category);
  $self->catalogue($catalogue) if $catalogue;
  $self->shortdesc($shortdesc) if $shortdesc;
  $self->longdesc($longdesc) if $longdesc;
  $self->srcpatterns(@srcpatterns) if @srcpatterns;
  $self->runpatterns(@runpatterns) if @runpatterns;
  $self->binpatterns(@binpatterns) if @binpatterns;
  $self->docpatterns(@docpatterns) if @docpatterns;
  $self->executes(@executes) if @executes;
  $self->depends(@depends) if @depends;
  $self->postactions(@postactions) if @postactions;
}


sub writeout {
  my $self = shift;
  my $fd = (@_ ? $_[0] : *STDOUT);
  format_name $fd "multilineformat";  # format defined in TLPOBJ, and $:
  $fd->format_lines_per_page (99999); # no pages in this format
  print $fd "name ", $self->name, "\n";
  print $fd "category ", $self->category, "\n";
  defined($self->{'catalogue'}) && print $fd "catalogue $self->{'catalogue'}\n";
  defined($self->{'shortdesc'}) && print $fd "shortdesc $self->{'shortdesc'}\n";
  if (defined($self->{'longdesc'})) {
    $_tmp = "$self->{'longdesc'}";
    write $fd;  # use that multilineformat
  }
  if (defined($self->{'depends'})) {
    foreach (@{$self->{'depends'}}) {
      print $fd "depend $_\n";
    }
  }
  if (defined($self->{'executes'})) {
    foreach (@{$self->{'executes'}}) {
      print $fd "execute $_\n";
    }
  }
  if (defined($self->{'postactions'})) {
    foreach (@{$self->{'postactions'}}) {
      print $fd "postaction $_\n";
    }
  }
  if (defined($self->{'srcpatterns'}) && (@{$self->{'srcpatterns'}})) {
    foreach (sort @{$self->{'srcpatterns'}}) {
      print $fd "srcpattern $_\n";
    }
  }
  if (defined($self->{'runpatterns'}) && (@{$self->{'runpatterns'}})) {
    foreach (sort @{$self->{'runpatterns'}}) {
      print $fd "runpattern $_\n";
    }
  }
  if (defined($self->{'docpatterns'}) && (@{$self->{'docpatterns'}})) {
    foreach (sort @{$self->{'docpatterns'}}) {
      print $fd "docpattern $_\n";
    }
  }
  if (defined($self->{'binpatterns'}) && (@{$self->{'binpatterns'}})) {
    foreach (sort @{$self->{'binpatterns'}}) {
      print $fd "binpattern $_\n";
    }
  }
}


sub make_tlpobj {
  my ($self,$tltree,$autopattern_root) = @_;
  my %allpatterns = &find_default_patterns($autopattern_root);
  my %global_tlpvars = %{$allpatterns{'tlpvars'}};
  my $category_patterns = $allpatterns{$self->category};

  my @exes = $self->executes;
  my @deps = $self->depends;
  for my $key (keys %global_tlpvars) {
    s/\$\{\Q$key\E\}/$global_tlpvars{$key}/g for @deps;
    s/\$\{\Q$key\E\}/$global_tlpvars{$key}/g for @exes;
  }
  $self->depends(@deps);
  $self->executes(@exes);

  my $tlp = TeXLive::TLPOBJ->new;
  $tlp->name($self->name);
  $tlp->category($self->category);
  $tlp->shortdesc($self->{'shortdesc'}) if (defined($self->{'shortdesc'}));
  $tlp->longdesc($self->{'longdesc'}) if (defined($self->{'longdesc'}));
  $tlp->catalogue($self->{'catalogue'}) if (defined($self->{'catalogue'}));
  $tlp->cataloguedata(%{$self->{'cataloguedata'}}) if (defined($self->{'cataloguedata'}));
  $tlp->executes(@{$self->{'executes'}}) if (defined($self->{'executes'}));
  $tlp->postactions(@{$self->{'postactions'}}) if (defined($self->{'postactions'}));
  $tlp->depends(@{$self->{'depends'}}) if (defined($self->{'depends'}));
  $tlp->revision(0);

  if (defined($tlp->executes)) { # else no fmttriggers
    my @deps = (defined($tlp->depends) ? $tlp->depends : ());
    my $tlpname = $tlp->name;
    for my $e ($tlp->executes) {
      if ($e =~ m/^\s*AddFormat\s+(.*)\s*$/) {
        my %fmtline = TeXLive::TLUtils::parse_AddFormat_line($1);
        if (defined($fmtline{"error"})) {
          tlwarn ("error in parsing $e for return hash: $fmtline{error}\n");
        } else {
          TeXLive::TLUtils::push_uniq (\@deps,
            grep { $_ ne $tlpname } @{$fmtline{'fmttriggers'}});
        }
      }
    }
    $tlp->depends(@deps);
  }

  my $filemax;
  my $usedefault;
  my @allpospats;
  my @allnegpats;
  my $pkgname = $self->name;
  my @autoaddpat;

  for my $pattype (qw/src run doc bin/) {
    @allpospats = ();
    @allnegpats = ();
    @autoaddpat = ();
    $usedefault = 1;
    foreach my $p (@{$self->{${pattype} . 'patterns'}}) {
      for my $key (keys %global_tlpvars) {
        $p =~ s/\$\{\Q$key\E\}/$global_tlpvars{$key}/g;
      }
      
      if ($p =~ m/^a\s+(.*)\s*$/) {
        push @autoaddpat, split(' ', $1);
      } elsif ($p =~ m/^!\+(.*)$/) {
        push @allnegpats, $1;
      } elsif ($p =~ m/^\+!(.*)$/) {
        push @allnegpats, $1;
      } elsif ($p =~ m/^\+(.*)$/) {
        push @allpospats, $1;
      } elsif ($p =~ m/^!(.*)$/) {
        push @allnegpats, $1;
        $usedefault = 0;
      } else {
        push @allpospats, $p;
        $usedefault = 0;
      }
    }

    if ($usedefault) {
      push @autoaddpat, $pkgname;
    }
    if (defined($category_patterns)) {
      for my $a (@autoaddpat) {
        my $type_patterns = $category_patterns->{$pattype};
        for my $p (@{$type_patterns}) {
          my $pp = $p;
          while ($pp =~ m/%(([^%]*):)?NAME(:([^%]*))?%/) {
            my $nn = $a;
            if (defined($1)) {
              $nn =~ s/^$2//;
            }
            if (defined($3)) {
              $nn =~ s/$4$//;
            }
            $pp =~ s/%(([^%]*):)?NAME(:([^%]*))?%/$nn/;
          }
          if ($pp =~ m/^!(.*)$/) {
            push @allnegpats, "*$1";
          } else {
            push @allpospats, "*$pp";
          }
        }
      }
    }
    last if ($pattype eq "bin");
    
    foreach my $p (@allpospats) {
      ddebug("pos pattern $p\n");
      $self->_do_normal_pattern($p,$tlp,$tltree,$pattype);
    }
    foreach my $p (@allnegpats) {
      ddebug("neg pattern $p\n");
      $self->_do_normal_pattern($p,$tlp,$tltree,$pattype,1);
    }
  }
  foreach my $p (@allpospats) {
    my @todoarchs = $tltree->architectures;
    my $finalp = $p;
    if ($p =~ m%^(\w+)/(!?[-_a-z0-9,]+)\s+(.*)$%) {
      my $pt = $1;
      my $aa = $2;
      my $pr = $3;
      if ($aa =~ m/^!(.*)$/) {
        my %negarchs;
        foreach (split(/,/,$1)) {
          $negarchs{$_} = 1;
        }
        my @foo = ();
        foreach (@todoarchs) {
          push @foo, $_ unless defined($negarchs{$_});
        }
        @todoarchs = @foo;
      } else {
        @todoarchs = split(/,/,$aa);
      }
      $finalp = "$pt $pr";
    }
    if ($finalp =~ m! bin/windows/!) {
      @todoarchs = qw/windows/;
    }
    foreach my $arch (sort @todoarchs) {
      my @archfiles = $tltree->get_matching_files('bin',$finalp, $pkgname, $arch);
      if (!@archfiles) {
        if (($arch ne "windows") || defined($::tlpsrc_pattern_warn_win)) {
          tlwarn("$self->{name} ($arch): no hit on binpattern $finalp\n");
        }
      }
      $tlp->add_binfiles($arch,@archfiles);
    }
  }
  foreach my $p (@allnegpats) {
    my @todoarchs = $tltree->architectures;
    my $finalp = $p;
    if ($p =~ m%^(\w+)/(!?[-_a-z0-9,]+)\s+(.*)$%) {
      my $pt = $1;
      my $aa = $2;
      my $pr = $3;
      if ($aa =~ m/^!(.*)$/) {
        my %negarchs;
        foreach (split(/,/,$1)) {
          $negarchs{$_} = 1;
        }
        my @foo = ();
        foreach (@todoarchs) {
          push @foo, $_ unless defined($negarchs{$_});
        }
        @todoarchs = @foo;
      } else {
        @todoarchs = split(/,/,$aa);
      }
      $finalp = "$pt $pr";
    }
    foreach my $arch (sort @todoarchs) {
      my @archfiles = $tltree->get_matching_files('bin', $finalp, $pkgname, $arch);
      if (!@archfiles) {
        if (($arch ne "windows") || defined($::tlpsrc_pattern_warn_win)) {
          tlwarn("$self->{name} ($arch): no hit on negative binpattern $finalp\n")
            unless $::tlpsrc_pattern_no_warn_negative;
        }
      }
      $tlp->remove_binfiles($arch,@archfiles);
    }
  }
  $tlp->recompute_revision($tltree, 
          $tltree->file_svn_lastrevision("tlpkg/tlpsrc/$self->{name}.tlpsrc"));
  $tlp->recompute_sizes($tltree);
  return $tlp;
}

sub _do_normal_pattern {
  my ($self,$p,$tlp,$tltree,$type,$negative) = @_;
  my $is_default_pattern = 0;
  if ($p =~ m/^\*/) {
    $is_default_pattern = 1;
    $p =~ s/^\*//;
  }
  my @matchfiles = $tltree->get_matching_files($type, $p, $self->{'name'});
  if (!$is_default_pattern && !@matchfiles
      && ($p !~ m,^f ignore,) && ($p !~ m,^d tlpkg/backups,)) {
    tlwarn("$self->{name}: no hit for pattern $p\n")
      unless $negative && $::tlpsrc_pattern_no_warn_negative;
  }
  if (defined($negative) && $negative == 1) {
    $tlp->remove_files($type,@matchfiles);
  } else {
    $tlp->add_files($type,@matchfiles);
  }
}



sub find_default_patterns {
  my ($tlroot) = @_;
  return %autopatterns if keys %autopatterns;  # only compute once
  
  my $apfile = "$tlroot/tlpkg/tlpsrc/00texlive.autopatterns.tlpsrc";
  die "No autopatterns file found: $apfile" if ! -r $apfile;

  my $tlsrc = new TeXLive::TLPSRC;
  $tlsrc->from_file ($apfile);
  if ($tlsrc->binpatterns) {
    for my $p ($tlsrc->binpatterns) {
      my ($cat, @rest) = split ' ', $p;
      push @{$autopatterns{$cat}{"bin"}}, join(' ', @rest);
    }
  }
  if ($tlsrc->srcpatterns) {
    for my $p ($tlsrc->srcpatterns) {
      my ($cat, @rest) = split ' ', $p;
      push @{$autopatterns{$cat}{"src"}}, join(' ', @rest);
    }
  }
  if ($tlsrc->docpatterns) {
    for my $p ($tlsrc->docpatterns) {
      my ($cat, @rest) = split ' ', $p;
      push @{$autopatterns{$cat}{"doc"}}, join(' ', @rest);
    }
  }
  if ($tlsrc->runpatterns) {
    for my $p ($tlsrc->runpatterns) {
      my ($cat, @rest) = split ' ', $p;
      push @{$autopatterns{$cat}{"run"}}, join(' ', @rest);
    }
  }

  for my $cat (keys %autopatterns) {
    ddebug ("Category $cat\n");
    for my $d (@{$autopatterns{$cat}{"bin"}}) {
      ddebug ("auto bin pattern $d\n");
    }
    for my $d (@{$autopatterns{$cat}{"src"}}) {
      ddebug ("auto src pattern $d\n");
    }
    for my $d (@{$autopatterns{$cat}{"doc"}}) {
      ddebug ("auto doc pattern $d\n");
    }
    for my $d (@{$autopatterns{$cat}{"run"}}) {
      ddebug ("auto run pattern $d\n");
    }
  }
  
  my %gvars = %{$tlsrc->_tlpvars};
  for my $v (keys %gvars) {
    if ($v !~ /^(global_[-_a-zA-Z0-9]+)$/) {
      tlwarn("$apfile: variable does not start with global_: $v\n")
        unless $v eq "PKGNAME";
      delete $gvars{$v};
    }
  } # we'll usually unnecessarily create a second hash, but so what.
  $autopatterns{'tlpvars'} = \%gvars;

  return %autopatterns;
}


sub _srcfile {
  my $self = shift;
  if (@_) { $self->{'_srcfile'} = shift }
  return $self->{'_srcfile'};
}
sub _tlpvars {
  my $self = shift;
  if (@_) { $self->{'_tlpvars'} = shift; }
  return $self->{'_tlpvars'};
}
sub name {
  my $self = shift;
  if (@_) { $self->{'name'} = shift }
  return $self->{'name'};
}
sub category {
  my $self = shift;
  if (@_) { $self->{'category'} = shift }
  return $self->{'category'};
}
sub shortdesc {
  my $self = shift;
  if (@_) { $self->{'shortdesc'} = shift }
  return $self->{'shortdesc'};
}
sub longdesc {
  my $self = shift;
  if (@_) { $self->{'longdesc'} = shift }
  return $self->{'longdesc'};
}
sub catalogue {
  my $self = shift;
  if (@_) { $self->{'catalogue'} = shift }
  return $self->{'catalogue'};
}
sub cataloguedata {
  my $self = shift;
  my %ct = @_;
  if (@_) { $self->{'cataloguedata'} = \%ct }
  return $self->{'cataloguedata'};
}
sub srcpatterns {
  my $self = shift;
  if (@_) { @{ $self->{'srcpatterns'} } = @_ }
  if (defined($self->{'srcpatterns'})) {
    return @{ $self->{'srcpatterns'} };
  } else {
    return;
  }
}
sub docpatterns {
  my $self = shift;
  if (@_) { @{ $self->{'docpatterns'} } = @_ }
  if (defined($self->{'docpatterns'})) {
    return @{ $self->{'docpatterns'} };
  } else {
    return;
  }
}
sub binpatterns {
  my $self = shift;
  if (@_) { @{ $self->{'binpatterns'} } = @_ }
  if (defined($self->{'binpatterns'})) {
    return @{ $self->{'binpatterns'} };
  } else {
    return;
  }
}
sub depends {
  my $self = shift;
  if (@_) { @{ $self->{'depends'} } = @_ }
  return @{ $self->{'depends'} };
}
sub runpatterns {
  my $self = shift;
  if (@_) { @{ $self->{'runpatterns'} } = @_ }
  if (defined($self->{'runpatterns'})) {
    return @{ $self->{'runpatterns'} };
  } else {
    return;
  }
}
sub executes {
  my $self = shift;
  if (@_) { @{ $self->{'executes'} } = @_ }
  return @{ $self->{'executes'} };
}
sub postactions {
  my $self = shift;
  if (@_) { @{ $self->{'postactions'} } = @_ }
  return @{ $self->{'postactions'} };
}

1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPSRC.pm@TeXLive/TLPSRC.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPaper.pm@TeXLive/TLPaper.pm
"TeXLive/TLPaper.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLPaper;

my $svnrev = '$Revision$';
my $_modulerevision;
if ($svnrev =~ m/: ([0-9]+) /) {
  $_modulerevision = $1;
} else {
  $_modulerevision = "unknown";
}
sub module_revision {
  return $_modulerevision;
}

BEGIN {
  use Exporter ();
  use vars qw( @ISA @EXPORT_OK @EXPORT );
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(
    %paper_config_path_component
    %paper_config_name
  );
  @EXPORT = @EXPORT_OK;
}

my $prg = ($::prg ? $::prg : TeXLive::TLUtils::basename($0));


use TeXLive::TLUtils qw(:DEFAULT dirname merge_into mkdirhier);
use TeXLive::TLConfig;


our %paper = (
  "xdvi"     => {
    sub => \&paper_xdvi,
    default_component => "xdvi",
    default_file      => "XDvi",
    pkg => "xdvi",
  },
  "pdftex"   => {
    sub => \&paper_pdftex,
    default_component => "tex/generic/tex-ini-files",
    default_file      => "pdftexconfig.tex",
    pkg => "pdftex",
  },
  "dvips"    => {
    sub => \&paper_dvips,
    default_component => "dvips/config",
    default_file      => "config.ps",
    pkg => "dvips",
  },
  "dvipdfmx" => {
    sub => \&paper_dvipdfmx,
    default_component => "dvipdfmx",
    default_file      => "dvipdfmx.cfg",
    pkg => "dvipdfmx",
  },
  "context"  => {
    sub => \&paper_context,
    default_component => "tex/context/user",
    default_file      => "context-papersize.tex",
    pkg => "context",
  },
  "psutils"  => {
    sub => \&paper_psutils,
    default_component => "psutils",
    default_file      => "paper.cfg",
    pkg => "psutils",
  },
);
  
our %paper_config_path_component;
our %paper_config_name;


my %xdvi_papersize = (
  a0       => '841x1189mm',
  a1       => '594x841mm',
  a2       => '420x594mm',
  a3       => '297x420mm',
  a4       => '210x297mm',
  a5       => '148x210mm',
  a6       => '105x148mm',
  a7       => '74x105mm',
  a8       => '52x74mm',
  a9       => '37x52mm',
  a10      => '26x37mm',
  a0r      => '1189x841mm',
  a1r      => '841x594mm',
  a2r      => '594x420mm',
  a3r      => '420x297mm',
  a4r      => '297x210mm',
  a5r      => '210x148mm',
  a6r      => '148x105mm',
  a7r      => '105x74mm',
  a8r      => '74x52mm',
  a9r      => '52x37mm',
  a10r     => '37x26mm',
  b0       => '1000x1414mm',
  b1       => '707x1000mm',
  b2       => '500x707mm',
  b3       => '353x500mm',
  b4       => '250x353mm',
  b5       => '176x250mm',
  b6       => '125x176mm',
  b7       => '88x125mm',
  b8       => '62x88mm',
  b9       => '44x62mm',
  b10      => '31x44mm',
  b0r      => '1414x1000mm',
  b1r      => '1000x707mm',
  b2r      => '707x500mm',
  b3r      => '500x353mm',
  b4r      => '353x250mm',
  b5r      => '250x176mm',
  b6r      => '176x125mm',
  b7r      => '125x88mm',
  b8r      => '88x62mm',
  b9r      => '62x44mm',
  b10r     => '44x31mm',
  c0       => '917x1297mm',
  c1       => '648x917mm',
  c2       => '458x648mm',
  c3       => '324x458mm',
  c4       => '229x324mm',
  c5       => '162x229mm',
  c6       => '114x162mm',
  c7       => '81x114mm',
  c8       => '57x81mm',
  c9       => '40x57mm',
  c10      => '28x40mm',
  c0r      => '1297x917mm',
  c1r      => '917x648mm',
  c2r      => '648x458mm',
  c3r      => '458x324mm',
  c4r      => '324x229mm',
  c5r      => '229x162mm',
  c6r      => '162x114mm',
  c7r      => '114x81mm',
  c8r      => '81x57mm',
  c9r      => '57x40mm',
  c10r     => '40x28mm',
  us       => '8.5x11',
  letter   => '8.5x11',
  ledger   => '17x11',
  tabloid  => '11x17',
  usr      => '11x8.5',
  legal    => '8.5x14',
  legalr   => '14x8.5',
  foolscap => '13.5x17.0',
  foolscapr => '17.0x13.5',
);

my %pdftex_papersize = (
  "a4"     => [ '210 true mm', '297 true mm' ],
  "letter" => [ '8.5 true in', '11 true in' ],
);

my %context_papersize = ( "A4" => 1, "letter" => 1, );

my %dvipdfm_papersize = (
  "a3" => 1,
  "a4" => 1,
  "ledger" => 1, 
  "legal" => 1,
  "letter" => 1,
  "tabloid" => 1,
);

my %psutils_papersize = ( "a4" => 1, "letter" => 1, );





sub get_paper_list {
  my $prog = shift;
  return ( &{$paper{$prog}{'sub'}} ( "/dummy", "--returnlist" ) );
}


sub get_paper {
  my $pps = get_paper_list(shift);
  return $pps->[0];
}


sub do_paper {
  my ($prog,$texmfsysconfig,@args) = @_;
  if (exists $paper{$prog}{'sub'}) {
    my $sub = $paper{$prog}{'sub'};
    return(&$sub($texmfsysconfig, @args));
  } else {
    tlwarn("$prg: unknown paper program $prog ($texmfsysconfig,@args)\n");
    return($F_ERROR);
  }
  return ($F_OK); # not reached
}



sub paper_all {
  my $ret = $F_OK;
  for my $p (sort keys %paper) {
    $ret |= &{$paper{$p}{'sub'}} (@_);
  }
  return($ret);
}


sub find_paper_file {
  my ($progname, $format, @filenames) = @_;
  my $ret = "";
  
  my $cmd;
  for my $filename (@filenames) {
    $cmd = qq!kpsewhich --progname=$progname --format="$format" $filename!;
    chomp($ret = `$cmd`);
    if ($ret) {
      debug("paper file for $progname ($format) $filename: $ret\n");
      last;
    }
  }

  debug("$prg: found no paper file for $progname (from $cmd)\n") if ! $ret;
  return $ret;
}

sub setup_names {
  my $prog = shift;
  my $outcomp = $paper_config_path_component{$prog}
                || $paper{$prog}{'default_component'};
  my $filecomp = $paper_config_name{$prog}
                 || $paper{$prog}{'default_file'};
  return ($outcomp, $filecomp);
}


sub paper_xdvi {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("xdvi");
  my $dftfile = $paper{'xdvi'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("xdvi", "other text files", $filecomp, $dftfile);

  return($F_ERROR) unless $inp; 
  

  my @sizes = keys %xdvi_papersize;
  return &paper_do_simple($inp, "xdvi", '^\*paper: ', '^\*paper:\s+(\w+)\s*$',
            sub {
              my ($ll,$np) = @_;
              $ll =~ s/^\*paper:\s+(\w+)\s*$/\*paper: $np\n/;
              return($ll);
            }, $outfile, \@sizes, '(undefined)', '*paper: a4', $newpaper);
}


sub paper_pdftex {
  my $outtree = shift;
  my $newpaper = shift;
  my ($outcomp, $filecomp) = setup_names("pdftex");
  my $dftfile = $paper{'pdftex'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("pdftex", "tex", $filecomp, $dftfile);

  return($F_ERROR) unless $inp; 

  open(FOO, "<$inp") || die "$prg: open($inp) failed: $!";
  my @lines = <FOO>;
  close(FOO);

  my @cpwidx;
  my @cphidx;
  my ($cpw, $cph);
  my $endinputidx;
  for my $idx (0..$#lines) {
    my $l = $lines[$idx];
    if ($l =~ m/^\s*\\pdfpagewidth\s*=\s*([0-9.,]+\s*true\s*[^\s]*)/) {
      if (defined($cpw) && $cpw ne $1) {
        tl_warn("TLPaper: inconsistent paper sizes in $inp for page width! Please fix that.\n");
        return $F_ERROR;
      }
      $cpw = $1;
      push @cpwidx, $idx;
      next;
    }
    if ($l =~ m/^\s*\\pdfpageheight\s*=\s*([0-9.,]+\s*true\s*[^\s]*)/) {
      if (defined($cph) && $cph ne $1) {
        tl_warn("TLPaper: inconsistent paper sizes in $inp for page height! Please fix that.\n");
        return $F_ERROR;
      }
      $cph = $1;
      push @cphidx, $idx;
      next;
    }
    if ($l =~ m/^\s*\\endinput\s*/) {
      $endinputidx = $idx;
      next;
    }
  }
  my $currentpaper;
  if (defined($cpw) && defined($cph)) {
    for my $pname (keys %pdftex_papersize) {
      my ($w, $h) = @{$pdftex_papersize{$pname}};
      if (($w eq $cpw) && ($h eq $cph)) {
        $currentpaper = $pname;
        last;
      }
    }
  } else {
    $currentpaper = "(undefined)";
  }
  $currentpaper || ($currentpaper = "$cpw x $cph");
  if (defined($newpaper)) {
    if ($newpaper eq "--list") {
      info("$currentpaper\n");
      for my $p (keys %pdftex_papersize) {
        info("$p\n") unless ($p eq $currentpaper);
      }
    } elsif ($newpaper eq "--json") {
      my @ret = ();
      push @ret, "$currentpaper";
      for my $p (keys %pdftex_papersize) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      my %foo;
      $foo{'program'} = "pdftex";
      $foo{'file'} = $inp;
      $foo{'options'} = \@ret;
      return \%foo;
    } elsif ($newpaper eq "--returnlist") {
      my @ret = ();
      push @ret, "$currentpaper";
      for my $p (keys %pdftex_papersize) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      return \@ret;
    } else {
      my $found = 0;
      for my $p (keys %pdftex_papersize) {
        if ($p eq $newpaper) {
          $found = 1;
          last;
        }
      }
      if ($found) {
        my $newwidth = ${$pdftex_papersize{$newpaper}}[0];
        my $newheight = ${$pdftex_papersize{$newpaper}}[1];
        if (@cpwidx) {
          for my $idx (@cpwidx) {
            ddebug("TLPaper: before line: $lines[$idx]");
            ddebug("TLPaper: replacement: $newwidth\n");
            $lines[$idx] =~ s/^\s*\\pdfpagewidth\s*=\s*[0-9.,]+\s*true\s*[^\s]*/\\pdfpagewidth        = $newwidth/;
            ddebug("TLPaper: after line : $lines[$idx]");
          }
        } else {
          my $addlines = "\\pdfpagewidth        = $newwidth\n";
          if (defined($endinputidx)) {
            $lines[$endinputidx] = $addlines . $lines[$endinputidx];
          } else {
            $lines[$#lines] = $addlines;
          }
        }
        if (@cphidx) {
          for my $idx (@cphidx) {
            ddebug("TLPaper: before line: $lines[$idx]");
            ddebug("TLPaper: replacement: $newheight\n");
            $lines[$idx] =~ s/^\s*\\pdfpageheight\s*=\s*[0-9.,]+\s*true\s*[^\s]*/\\pdfpageheight       = $newheight/;
            ddebug("TLPaper: after line : $lines[$idx]");
          }
        } else {
          my $addlines = "\\pdfpageheight       = $newheight";
          if (defined($endinputidx)) {
            $lines[$endinputidx] = $addlines . $lines[$endinputidx];
          } else {
            $lines[$#lines] = $addlines;
          }
        }
        info("$prg: setting paper size for pdftex to $newpaper: $outfile\n");
        mkdirhier(dirname($outfile));
        TeXLive::TLUtils::announce_execute_actions("files-changed")
          unless (-r $outfile);
        if (!open(TMP, ">$outfile")) {
          tlwarn("$prg: Cannot write to $outfile: $!\n");
          tlwarn("Not setting paper size for pdftex.\n");
          return($F_ERROR);
        }
        for (@lines) { print TMP; }
        close(TMP) || warn "$prg: close(>$outfile) failed: $!";
        TeXLive::TLUtils::announce_execute_actions("regenerate-formats");
        return($F_OK);
      } else {
        tlwarn("$prg: Not a valid paper size for pdftex: $newpaper\n");
        return($F_WARNING);
      }
    }
  } else {
    info("Current pdftex paper size (from $inp): $currentpaper\n");
  }
  return($F_OK);
}


sub paper_dvips {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("dvips");
  my $dftfile = $paper{'dvips'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("dvips", "dvips config", $filecomp, $dftfile);

  return($F_ERROR) unless $inp; 
  
  open(FOO, "<$inp") || die "$prg: open($inp) failed: $!";
  my @lines = <FOO>;
  close(FOO);

  my @papersizes;
  my $firstpaperidx;
  my %startidx;
  my %endidx;
  my $in_block = "";
  my $idx = 0;
  for my $idx (0 .. $#lines) {
    if ($lines[$idx] =~ m/^@ (\w+)/) {
      $startidx{$1} = $idx;
      $firstpaperidx || ($firstpaperidx = $idx-1);
      $in_block = $1;
      push @papersizes, $1;
      next;
    }
    if ($in_block) {
      if ($lines[$idx] =~ m/^\s*(%.*)?\s*$/) {
        $endidx{$in_block} = $idx-1;
        $in_block = "";
      }
      next;
    }
  }

  if (defined($newpaper)) {
    if ($newpaper eq "--list") {
      for my $p (@papersizes) {
        info("$p\n"); # first is already the selected one
      }
    } elsif ($newpaper eq "--json") {
      my %foo;
      $foo{'program'} = "dvips";
      $foo{'file'} = $inp;
      $foo{'options'} = \@papersizes;
      return \%foo;
    } elsif ($newpaper eq "--returnlist") {
      return(\@papersizes);
    } else {
      my $found = 0;
      for my $p (@papersizes) {
        if ($p eq $newpaper) {
          $found = 1;
          last;
        }
      }
      if ($found) {
        my @newlines;
        for my $idx (0..$#lines) {
          if ($idx < $firstpaperidx) {
            push @newlines, $lines[$idx];
            next;
          }
          if ($idx == $firstpaperidx) { 
            push @newlines, @lines[$startidx{$newpaper}..$endidx{$newpaper}];
            push @newlines, $lines[$idx];
            next;
          }
          if ($idx >= $startidx{$newpaper} && $idx <= $endidx{$newpaper}) {
            next;
          }
          push @newlines, $lines[$idx];
        }
        info("$prg: setting paper size for dvips to $newpaper: $outfile\n");
        mkdirhier(dirname($outfile));
        TeXLive::TLUtils::announce_execute_actions("files-changed")
          unless (-r $outfile);
        if (!open(TMP, ">$outfile")) {
          tlwarn("$prg: Cannot write to $outfile: $!\n");
          tlwarn("Not setting paper size for dvips.\n");
          return ($F_ERROR);
        }
        for (@newlines) { print TMP; }
        close(TMP) || warn "$prg: close(>$outfile) failed: $!";
      } else {
        tlwarn("$prg: Not a valid paper size for dvips: $newpaper\n");
        return($F_WARNING);
      }
    }
  } else {
    info("Current dvips paper size (from $inp): $papersizes[0]\n");
  }
  return($F_OK);
}


sub do_dvipdfm_and_x {
  my ($inp,$prog,$outtree,$paplist,$newpaper) = @_;

  my ($outcomp, $filecomp) = setup_names($prog);
  my $outfile = "$outtree/$outcomp/$filecomp";

  return &paper_do_simple($inp, $prog, '^p\s+', '^p\s+(\w+)\s*$',
            sub {
              my ($ll,$np) = @_;
              $ll =~ s/^p\s+(\w+)\s*$/p $np\n/;
              return($ll);
            }, $outfile, $paplist, '(undefined)', 'p a4', $newpaper);
}

sub paper_dvipdfm {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("dvipdfm");
  my $dftfile = $paper{'dvipdfm'}{'default_file'};
  my $inp = &find_paper_file("dvipdfm", "other text files", $filecomp, $dftfile);
  return ($F_ERROR) unless $inp; 

  my @sizes = keys %dvipdfm_papersize;
  return &do_dvipdfm_and_x($inp, "dvipdfm", $outtree, \@sizes, $newpaper);
}

sub paper_dvipdfmx {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("dvipdfmx");
  my $dftfile = $paper{'dvipdfmx'}{'default_file'};

  my $inp = &find_paper_file("dvipdfmx", "other text files", $filecomp, $dftfile);
  return ($F_ERROR) unless $inp; 

  my @sizes = keys %dvipdfm_papersize;
  return &do_dvipdfm_and_x($inp, "dvipdfmx", $outtree, \@sizes, $newpaper);
}


sub paper_context {
  my $outtree = shift;
  my $newpaper = shift;
  if ($newpaper && $newpaper eq "a4") {
    $newpaper = "A4";
  }
  my ($outcomp, $filecomp) = setup_names('context');
  my $dftfile = $paper{'context'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("context", "tex", $filecomp, $dftfile);


  my @lines;
  my $endinputidx = -1;
  my @idx;
  my $idxlast;
  my $currentpaper;
  if ($inp) {
    open(FOO, "<$inp") || die "$prg: open($inp) failed: $!";
    @lines = <FOO>;
    close(FOO);

    for my $idx (0..$#lines) {
      my $l = $lines[$idx];
      if ($l =~ m/^[^%]*\\endinput/) {
        $endinputidx = $idx;
        last;
      }
      if ($l =~ m/^\s*\\setuppapersize\s*\[([^][]*)\].*$/) {
        if (defined($currentpaper) && $currentpaper ne $1) {
          tl_warn("TLPaper: inconsistent paper sizes in $inp! Please fix that.\n");
          return $F_ERROR;
        }
        $currentpaper = $1;
        $idxlast = $idx;
        push @idx, $idx;
        next;
      }
    }
  } else {
    @lines = []
  }
  $currentpaper || ($currentpaper = "A4");
  if (defined($newpaper)) {
    if ($newpaper eq "--list") {
      info("$currentpaper\n");
      for my $p (keys %context_papersize) {
        info("$p\n") unless ($p eq $currentpaper);
      }
    } elsif ($newpaper eq "--json") {
      my @ret = ();
      push @ret, "$currentpaper";
      for my $p (keys %context_papersize) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      my %foo;
      $foo{'program'} = 'context';
      $foo{'file'} = $inp;
      $foo{'options'} = \@ret;
      return \%foo;
    } elsif ($newpaper eq "--returnlist") {
      my @ret = ();
      push @ret, "$currentpaper";
      for my $p (keys %context_papersize) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      return \@ret;
    } else {
      my $found = 0;
      for my $p (keys %context_papersize) {
        if ($p eq $newpaper) {
          $found = 1;
          last;
        }
      }
      if ($found) {
        if (@idx) {
          for my $idx (@idx) {
            ddebug("TLPaper: before line: $lines[$idx]");
            ddebug("TLPaper: replacement: $newpaper\n");
            $lines[$idx] =~ s/setuppapersize\s*\[([^][]*)\]\[([^][]*)\]/setuppapersize[$newpaper][$newpaper]/;
            ddebug("TLPaper: after line : $lines[$idx]");
          }
        } else {
          my $addlines = "\\setuppapersize[$newpaper][$newpaper]\n";
          if ($endinputidx > -1) {
            $lines[$endinputidx] = $addlines . $lines[$endinputidx];
          } else {
            $lines[$#lines] = $addlines;
          }
        }
        info("$prg: setting paper size for context to $newpaper: $outfile\n");
        mkdirhier(dirname($outfile));
        TeXLive::TLUtils::announce_execute_actions("files-changed")
          unless (-r $outfile);
        if (!open(TMP, ">$outfile")) {
          tlwarn("$prg: Cannot write to $outfile: $!\n");
          tlwarn("Not setting paper size for context.\n");
          return($F_ERROR);
        }
        for (@lines) { print TMP; }
        close(TMP) || warn "$prg: close(>$outfile) failed: $!";
        TeXLive::TLUtils::announce_execute_actions("regenerate-formats");
        return($F_OK);
      } else {
        tlwarn("$prg: Not a valid paper size for context: $newpaper\n");
        return($F_WARNING);
      }
    }
  } else {
    info("Current context paper size (from $inp): $currentpaper\n");
  }
  return($F_OK);
}

sub paper_context_old {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("context");
  my $dftfile = $paper{'context'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("context", "tex", $filecomp, "cont-sys.rme", $dftfile);
  return ($F_ERROR) unless $inp; 

  my @sizes = keys %pdftex_papersize;
  return &paper_do_simple($inp, "context", '^\s*%?\s*\\\\setuppapersize\s*', 
            '^\s*%?\s*\\\\setuppapersize\s*\[([^][]*)\].*$',
            sub {
              my ($ll,$np) = @_;
              if ($ll =~ m/^\s*%?\s*\\setuppapersize\s*/) {
                return("\\setuppapersize[$np][$np]\n");
              } else {
                return($ll);
              }
            }, 
            $outfile, \@sizes, 'a4', '\setuppapersize[a4][a4]', $newpaper);
}


sub paper_psutils {
  my $outtree = shift;
  my $newpaper = shift;

  my ($outcomp, $filecomp) = setup_names("psutils");
  my $dftfile = $paper{'psutils'}{'default_file'};
  my $outfile = "$outtree/$outcomp/$filecomp";
  my $inp = &find_paper_file("psutils", "other text files", $filecomp, $dftfile);

  return ($F_ERROR) unless $inp; 
  

  my @sizes = keys %psutils_papersize;
  return &paper_do_simple($inp, "psutils", '^\s*p', '^\s*p\s+(\w+)\s*$', 
             sub {
               my ($ll,$np) = @_;
               $ll =~ s/^\s*p\s+(\w+)\s*$/p $np\n/;
               return($ll);
             },
             $outfile, \@sizes, '(undefined)', 'p a4', $newpaper);
}


sub paper_do_simple {
  my ($inp, $prog, $firstre, $secondre, $bl, $outp, $paplist, $defaultpaper, $defaultline, $newpaper) = @_;

  debug("file used for $prog: $inp\n");

  open(FOO, "<$inp") or die("cannot open file $inp: $!");
  my @lines = <FOO>;
  close(FOO);

  my $currentpaper;
  my @paperlines = grep (m/$firstre/,@lines);
  if (!@paperlines) {
    $currentpaper = $defaultpaper;
  } else {
    if ($#paperlines > 0) {
      warn "Strange, more than one paper definition, using the first one in\n$inp\n";
    }
    $currentpaper = $paperlines[0];
    chomp($currentpaper);
    $currentpaper =~ s/$secondre/$1/;
  }

  if (defined($newpaper)) {
    if ($newpaper eq "--list") {
      info("$currentpaper\n");
      for my $p (@$paplist) {
        info("$p\n") unless ($p eq $currentpaper);
      }
    } elsif ($newpaper eq "--json") {
      my @ret = ();
      push @ret, "$currentpaper";
      for my $p (@$paplist) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      my %foo;
      $foo{'program'} = $prog;
      $foo{'file'} = $inp;
      $foo{'options'} = \@ret;
      return \%foo;
    } elsif ($newpaper eq "--returnlist") {
      my @ret = ();
      push @ret, $currentpaper;
      for my $p (@$paplist) {
        push @ret, $p unless ($p eq $currentpaper);
      }
      return(\@ret);
    } else {
      my $found = 0;
      for my $p (@$paplist) {
        if ($p eq $newpaper) {
          $found = 1;
          last;
        }
      }
      if ($found) {
        my @newlines;
        my $foundcfg = 0;
        for my $l (@lines) {
          if ($l =~ m/$firstre/) {
            push @newlines, &$bl($l, $newpaper);
            $foundcfg = 1;
          } else {
            push @newlines, $l;
          }
        }
        if (!$foundcfg) {
          push @newlines, &$bl($defaultline, $newpaper);
        }
        info("$prg: setting paper size for $prog to $newpaper: $outp\n");
        mkdirhier(dirname($outp));
        TeXLive::TLUtils::announce_execute_actions("files-changed")
          unless (-r $outp);
        if (!open(TMP, ">$outp")) {
          tlwarn("$prg: Cannot write to $outp: $!\n");
          tlwarn("Not setting paper size for $prog.\n");
          return ($F_ERROR);
        }
        for (@newlines) { print TMP; }
        close(TMP) || warn "$prg: close(>$outp) failed: $!";
        TeXLive::TLUtils::announce_execute_actions("regenerate-formats")
          if ($prog eq "context");
        return($F_OK);
      } else {
        tlwarn("$prg: Not a valid paper size for $prog: $newpaper\n");
        return($F_WARNING);
      }
    }
  } else {
    info("Current $prog paper size (from $inp): $currentpaper\n");
  }
  return($F_OK);
}

1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPaper.pm@TeXLive/TLPaper.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLTREE.pm@TeXLive/TLTREE.pm
"TeXLive/TLTREE.pm" => <<'__EOI__',

use strict; use warnings;

package TeXLive::TLTREE;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


use TeXLive::TLUtils;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    svnroot   => $params{'svnroot'},
    archs     => $params{'archs'},
    revision  => $params{'revision'},
    _allfiles   => {},
    _dirtree    => {},
    _dirnames   => {},
    _filesofdir => {},
    _subdirsofdir => {},
  };
  bless $self, $class;
  return $self;
}

sub init_from_svn {
  my $self = shift;
  die "undefined svn root" if !defined($self->{'svnroot'});
  my @lines = `cd $self->{'svnroot'} && svn status -v`;
  my $retval = $?;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    tldie("TLTree: svn status -v returned $retval, stopping.\n");
  }
  $self->_initialize_lines(@lines);
}

sub init_from_statusfile {
  my $self = shift;
  die "need filename of svn status file" if (@_ != 1);
  open(TMP,"<$_[0]") || die "open of svn status file($_[0]) failed: $!";
  my @lines = <TMP>;
  close(TMP);
  $self->_initialize_lines(@lines);
}
sub init_from_files {
  my $self = shift;
  my $svnroot = $self->{'svnroot'};
  my @lines = `find $svnroot`;
  my $retval = $?;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    tldie("TLTree: find $svnroot returned $retval, stopping.\n");
  }
  @lines = grep(!/\/\.svn/ , @lines);
  @lines = map { s@^$svnroot@@; s@^/@@; "             1 1 dummy $_" } @lines;
  $self->{'revision'} = 1;
  $self->_initialize_lines(@lines);
}


sub init_from_git {
  my $self = shift;
  my $svnroot = $self->{'svnroot'};
  my $retval = $?;
  my %files;
  my %deletedfiles;
  my @lines;

  my @foo = `cd $svnroot; git log --pretty=format:COMMIT=%h --no-renames --name-status`;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    tldie("TLTree: git log in $svnroot returned $retval, stopping.\n");
  }
  chomp(@foo);

  my $curcom = "";
  my $rev = 0;
  for my $l (@foo) {
    if ($l eq "") {
      $curcom = "";
      next;
    } elsif ($l =~ m/^COMMIT=([[:xdigit:]]*)$/) {
      $curcom = $1;
      $rev++;
      next;
    } else {
      if ($l =~ m/^(A|C|D|M|R|T|U|X|B)\S*\s+(.*)$/) {
        my $status = $1;
        my $curfile = $2;
        if (!defined($files{$curfile}) && !defined($deletedfiles{$curfile})) {
          if ($status eq "D") {
            $deletedfiles{$curfile} = 1;
          } else {
            $files{$curfile} = $rev;
          }
        }
      } else {
        print STDERR "Unknown line in git output: >>$l<<\n";
      }
    }
  }

  for my $f (keys %files) {
    my $n = - ( $files{$f} - $rev ) + 1;
    $f =~ s!^Master/!!;
    push @lines, "             $n $n dummy $f"
  }
  $self->{'revision'} = $rev;
  $self->_initialize_lines(@lines);
}

sub init_from_gitsvn {
  my $self = shift;
  my $svnroot = $self->{'svnroot'};
  my @foo = `cd $svnroot; git log --pretty=format:%h --name-only`;
  chomp(@foo);
  my $retval = $?;
  if ($retval != 0) {
    $retval /= 256 if $retval > 0;
    tldie("TLTree: git log in $svnroot returned $retval, stopping.\n");
  }
  my %com2rev;
  my @lines;
  my $curcom = "";
  my $currev = "";
  for my $l (@foo) {
    if ($l eq "") {
      $currev = "";
      $curcom = "";
      next;
    }
    if ($curcom eq "") {
      $curcom = $l;
      $currev = `git svn find-rev $curcom`;
      chomp($currev);
      if (!$currev) {
        my $foo = $curcom;
        my $nr = 0;
        while (1) {
          $foo .= "^";
          $nr++;
          my $tr = `git svn find-rev $foo`;
          chomp($tr);
          if ($tr) {
            $currev = $tr + $nr;
            last;
          }
        }
      }
      $com2rev{$curcom} = $currev;
    } else {
      push @lines, "             $currev $currev dummy $l"
    }
  }
  $self->{'revision'} = 1;
  $self->_initialize_lines(@lines);
}

sub _initialize_lines {
  my $self = shift;
  my @lines = @_;
  my %archs;
  chomp (my $oldpwd = `pwd`);
  chdir($self->svnroot) || die "chdir($self->{svnroot}) failed: $!";
  foreach my $l (@lines) {
    chomp($l);
    next if $l =~ /^\?/;    # ignore files not under version control
    if ($l =~ /^(.)(.)(.)(.)(.)(.)..\s*(\d+)\s+([\d\?]+)\s+([\w\?]+)\s+(.+)$/){
      $self->{'revision'} = $7 unless defined($self->{'revision'});
      my $lastchanged = ($8 eq "?" ? 1 : $8);
      my $entry = "$10";
      next if ($1 eq "D"); # ignore files which are removed
      next if -d $entry && ! -l $entry; # keep symlinks to dirs (bin/*/man),
      if ($entry =~ m,^bin/([^/]*)/, && $entry ne "bin/man") {
        $archs{$1} = 1;
      }
      $self->{'_allfiles'}{$entry}{'lastchangedrev'} = $lastchanged;
      $self->{'_allfiles'}{$entry}{'size'} = (lstat $entry)[7];
      my $fn = TeXLive::TLUtils::basename($entry);
      my $dn = TeXLive::TLUtils::dirname($entry);
      add_path_to_tree($self->{'_dirtree'}, split("[/\\\\]", $dn));
      push @{$self->{'_filesofdir'}{$dn}}, $fn;
    } elsif ($l ne '             1 1 dummy ') {
      tlwarn("Ignoring svn status output line:\n    $l\n");
    }
  }
  $self->architectures(keys(%archs));
  $self->walk_tree(\&find_alldirs);
  
  chdir($oldpwd) || die "chdir($oldpwd) failed: $!";
}

sub print {
  my $self = shift;
  $self->walk_tree(\&print_node);
}

sub find_alldirs {
  my ($self,$node, @stackdir) = @_;
  my $tl = $stackdir[-1];
  push @{$self->{'_dirnames'}{$tl}}, join("/", @stackdir);
  if (keys(%{$node})) {
    my $pa = join("/", @stackdir);
    push @{$self->{'_subdirsofdir'}{$pa}}, keys(%{$node});
  }
}

sub print_node {
  my ($self,$node, @stackdir) = @_;
  my $dp = join("/", @stackdir);
  if ($self->{'_filesofdir'}{$dp}) {
    foreach my $f (@{$self->{'_filesofdir'}{$dp}}) {
      print "dp=$dp file=$f\n";
    }
  }
  if (! keys(%{$node})) {
    print join("/", @stackdir) . "\n";
  }
}

sub walk_tree {
  my $self = shift;
  my (@stack_dir);
  $self->_walk_tree1($self->{'_dirtree'},@_, @stack_dir);
}

sub _walk_tree1 {
  my $self = shift;
  my ($node,$pre_proc, $post_proc, @stack_dir) = @_;
  my $v;
  for my $k (keys(%{$node})) {
    push @stack_dir, $k;
    $v = $node->{$k};
    if ($pre_proc) { &{$pre_proc}($self, $v, @stack_dir) }
    $self->_walk_tree1 (\%{$v}, $pre_proc, $post_proc, @stack_dir);
    $v = $node->{$k};
    if ($post_proc) { &{$post_proc}($self, $v, @stack_dir) }
    pop @stack_dir;
  }
}

sub add_path_to_tree {
  my ($node, @path) = @_;
  my ($current);

  while (@path) {
    $current = shift @path;
    if ($$node{$current}) {
      $node = $$node{$current};
    } else {
      $$node{$current} = { };
      $node = $$node{$current};
    }
  }
  return $node;
}

sub file_svn_lastrevision {
  my $self = shift;
  my $fn = shift;
  if (defined($self->{'_allfiles'}{$fn})) {
    return($self->{'_allfiles'}{$fn}{'lastchangedrev'});
  } else {
    return(undef);
  }
}

sub size_of {
  my ($self,$f) = @_;
  if (defined($self->{'_allfiles'}{$f})) {
    return($self->{'_allfiles'}{$f}{'size'});
  } else {
    return(undef);
  }
}


sub get_matching_files {
  my ($self, $type, $p, $pkg, $arch) = @_;
  my $ARCH = $arch;
  my $newp;
  {
    my $warnstr = "";
    local $SIG{__WARN__} = sub { $warnstr = $_[0]; };
    eval "\$newp = \"$p\"";
    if (!defined($newp)) {
      die "cannot set newp from p: p=$p, pkg=$pkg, arch=$arch, type=$type";
    }
    if ($warnstr) {
      tlwarn("Warning `$warnstr' while evaluating: $p "
             . "(pkg=$pkg, arch=$arch, type=$type), returning empty list\n");
      return ();
    }
  }
  return $self->_get_matching_files($type,$newp);
}

  
sub _get_matching_files {
  my ($self, $type, $p) = @_;
  my ($pattype,$patdata,@rest) = split ' ',$p;
  my @matchfiles;
  if ($pattype eq "t") {
    @matchfiles = $self->_get_files_matching_dir_pattern($type,$patdata,@rest);
  } elsif ($pattype eq "f") {
    @matchfiles = $self->_get_files_matching_glob_pattern($type,$patdata);
  } elsif ($pattype eq "r") {
    @matchfiles = $self->_get_files_matching_regexp_pattern($type,$patdata);
  } elsif ($pattype eq "d") {
    @matchfiles = $self->files_under_path($patdata);
  } else {
    die "Unknown pattern type `$pattype' in $p";
  }
  ddebug("p=$p; matchfiles=@matchfiles\n");
  return @matchfiles;
}

sub _get_files_matching_glob_pattern
{
  my $self = shift;
  my ($type,$globline) = @_;
  my @returnfiles;

  my $dirpart = TeXLive::TLUtils::dirname($globline);
  my $basepart = TeXLive::TLUtils::basename($globline);
  $basepart =~ s/\./\\./g;
  $basepart =~ s/\*/.*/g;
  $basepart =~ s/\?/./g;
  $basepart =~ s/\+/\\+/g;
  return unless (defined($self->{'_filesofdir'}{$dirpart}));

  my @candfiles = @{$self->{'_filesofdir'}{$dirpart}};
  for my $f (@candfiles) {
    dddebug("matching $f in $dirpart via glob $globline\n");
    if ($f =~ /^$basepart$/) {
      dddebug("hit: globline=$globline, $dirpart/$f\n");
      if ("$dirpart" eq ".") {
        push @returnfiles, "$f";
      } else {
        push @returnfiles, "$dirpart/$f";
      }
    }
  }

  if ($dirpart =~ m,^bin/(windows|win[0-9]|.*-cygwin),
      || $dirpart =~ m,tlpkg/installer,) {
    foreach my $f (@candfiles) {
      my $w32_binext;
      if ($dirpart =~ m,^bin/.*-cygwin,) {
        $w32_binext = "exe";  # cygwin has .exe but nothing else
      } else {
        $w32_binext = "(exe|dll)(.manifest)?|texlua|bat|cmd";
      }
      ddebug("matching $f in $dirpart via glob $globline.($w32_binext)\n");
      if ($f =~ /^$basepart\.($w32_binext)$/) {
        ddebug("hit: globline=$globline, $dirpart/$f\n");
        if ("$dirpart" eq ".") {
          push @returnfiles, "$f";
        } else {
          push @returnfiles, "$dirpart/$f";
        }
      }
    }
  }
  return @returnfiles;
}

sub _get_files_matching_regexp_pattern {
  my $self = shift;
  my ($type,$regexp) = @_;
  my @returnfiles;
  FILELABEL: foreach my $f (keys(%{$self->{'_allfiles'}})) {
    if ($f =~ /^$regexp$/) {
      TeXLive::TLUtils::push_uniq(\@returnfiles,$f);
      next FILELABEL;
    }
  }
  return(@returnfiles);
}

sub _get_files_matching_dir_pattern {
  my ($self,$type,@patwords) = @_;
  my $tl = pop @patwords;
  my $maxintermediate = 1;
  if (($#patwords >= 1 && $patwords[1] eq 'fonts')
      || 
      ($#patwords >= 2 && $patwords[2] eq 'context')) {
    $maxintermediate = 2;
  }
  my @returnfiles;
  if (defined($self->{'_dirnames'}{$tl})) {
    foreach my $tld (@{$self->{'_dirnames'}{$tl}}) {
      my $startstr = join("/",@patwords)."/";
      if (index($tld, $startstr) == 0) {
        my $middlepart = $tld;
        $middlepart =~ s/\Q$startstr\E//;
        $middlepart =~ s!/$tl/!!;
        my $number = () = $middlepart =~ m!/!g;
        if ($number <= $maxintermediate) {
          my @files = $self->files_under_path($tld);
          TeXLive::TLUtils::push_uniq(\@returnfiles, @files);
        }
      }
    }
  }
  return(@returnfiles);
}

sub files_under_path {
  my $self = shift;
  my $p = shift;
  my @files = ();
  foreach my $aa (@{$self->{'_filesofdir'}{$p}}) {
    TeXLive::TLUtils::push_uniq(\@files, $p . "/" . $aa);
  }
  if (defined($self->{'_subdirsofdir'}{$p})) {
    foreach my $sd (@{$self->{'_subdirsofdir'}{$p}}) {
      my @sdf = $self->files_under_path($p . "/" . $sd);
      TeXLive::TLUtils::push_uniq (\@files, @sdf);
    }
  }
  return @files;
}


sub svnroot {
  my $self = shift;
  if (@_) { $self->{'svnroot'} = shift };
  return $self->{'svnroot'};
}

sub revision {
  my $self = shift;
  if (@_) { $self->{'revision'} = shift };
  return $self->{'revision'};
}


sub architectures {
  my $self = shift;
  if (@_) { @{ $self->{'archs'} } = @_ }
  return defined $self->{'archs'} ? @{ $self->{'archs'} } : ();
}

1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLTREE.pm@TeXLive/TLTREE.pm
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
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TeXCatalogue.pm@TeXLive/TeXCatalogue.pm
"TeXLive/TeXCatalogue.pm" => <<'__EOI__',

use strict; use warnings;

use XML::Parser;
use XML::XPath;
use XML::XPath::XMLParser;
use Text::Unidecode;

package TeXLive::TeXCatalogue::Entry;

my $svnrev = '$Revision$';
my $_modulerevision = ($svnrev =~ m/: ([0-9]+) /) ? $1 : "unknown";
sub module_revision { return $_modulerevision; }


my $_parser = XML::Parser->new(
  ErrorContext => 2,
  ParseParamEnt => 1,
  NoLWP => 1
);

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ioref => $params{'ioref'},
    entry => defined($params{'entry'}) ? $params{'entry'} : {},
    docs => defined($params{'docs'}) ? $params{'docs'} : {},
    name => $params{'name'},
    caption => $params{'caption'},
    description => $params{'description'},
    license => $params{'license'},
    ctan => $params{'ctan'},
    texlive => $params{'texlive'},
    miktex => $params{'miktex'},
    version => $params{'version'},
    also => defined($params{'also'}) ? $params{'also'} : [],
    topic => defined($params{'topic'}) ? $params{'topic'} : [],
    alias => defined($params{'alias'}) ? $params{'alias'} : [],
    contact => defined($params{'contact'}) ? $params{'contact'} : {},
  };
  bless $self, $class;
  if (defined($self->{'ioref'})) {
    $self->initialize();
  }
  return $self;
}

sub initialize {
  my $self = shift;
  my $parser
    = new XML::XPath->new(ioref => $self->{'ioref'}, parser => $_parser)
      || die "Failed to parse given ioref";
  $self->{'entry'}{'id'} = $parser->findvalue('/entry/@id')->value();
  $self->{'entry'}{'date'} = $parser->findvalue('/entry/@datestamp')->value();
  $self->{'entry'}{'modder'} = $parser->findvalue('/entry/@modifier')->value();
  $self->{'name'} = $parser->findvalue("/entry/name")->value();
  $self->{'caption'} = beautify($parser->findvalue("/entry/caption")->value());
  $self->{'description'} = beautify($parser->findvalue("/entry/description")->value());
  my $licset = $parser->find('/entry/license');
  my @liclist;
  foreach my $node ($licset->get_nodelist) {
    my $lictype = $parser->find('./@type',$node);
    push @liclist, "$lictype";
  }
  $self->{'license'} = join(' ', @liclist);
  $self->{'version'} = Text::Unidecode::unidecode(
                          $parser->findvalue('/entry/version/@number')->value());
  $self->{'ctan'} = $parser->findvalue('/entry/ctan/@path')->value();
  if ($parser->findvalue('/entry/texlive/@location') ne "") {
    $self->{'texlive'} = $parser->findvalue('/entry/texlive/@location')->value();
  }
  if ($parser->findvalue('/entry/miktex/@location') ne "") {
    $self->{'miktex'} = $parser->findvalue('/entry/miktex/@location')->value();
  }
  my $alset = $parser->find('/entry/alias');
  for my $node ($alset->get_nodelist) {
    my $id = $parser->find('./@id', $node);
    push @{$self->{'alias'}}, "$id";
  }
  my $docset = $parser->find('/entry/documentation');
  foreach my $node ($docset->get_nodelist) {
    my $docfileparse = $parser->find('./@href',$node);
    my $docfile = "$docfileparse";
    my $details
      = Text::Unidecode::unidecode($parser->find('./@details',$node));
    my $language = $parser->find('./@language',$node);
    $self->{'docs'}{$docfile}{'available'} = 1;
    if ($details) { $self->{'docs'}{$docfile}{'details'} = "$details"; }
    if ($language) { $self->{'docs'}{$docfile}{'language'} = "$language"; }
  }
  foreach my $node ($parser->find('/entry/also')->get_nodelist) {
    my $alsoid = $parser->find('./@refid',$node);
    push @{$self->{'also'}}, "$alsoid";
  }
  foreach my $node ($parser->find('/entry/contact')->get_nodelist) {
    my $contacttype = $parser->findvalue('./@type',$node);
    my $contacthref = $parser->findvalue('./@href',$node);
    if ($contacttype && $contacthref) {
      $self->{'contact'}{$contacttype} = $contacthref;
    }
  }
  foreach my $node ($parser->find('/entry/keyval')->get_nodelist) {
    my $k = $parser->findvalue('./@key',$node);
    my $v = $parser->findvalue('./@value',$node);
    if ("$k" eq 'topic') {
      push @{$self->{'topic'}}, "$v";
    }
  }
}

sub beautify {
  my ($txt) = @_;
  $txt = Text::Unidecode::unidecode($txt);
  $txt =~ s/\n/ /g;  # make one line
  $txt =~ s/^\s+//g; # rm leading whitespace
  $txt =~ s/\s+$//g; # rm trailing whitespace
  $txt =~ s/\s\s+/ /g; # collapse multiple whitespace characters to one
  $txt =~ s/\t/ /g;    # tabs to spaces
  
  $txt =~ s,http://grants.nih.gov/,grants.nih.gov/,g;

  return $txt;
}

sub name {
  my $self = shift;
  if (@_) { $self->{'name'} = shift }
  return $self->{'name'};
}
sub license {
  my $self = shift;
  if (@_) { $self->{'license'} = shift }
  return $self->{'license'};
}
sub version {
  my $self = shift;
  if (@_) { $self->{'version'} = shift }
  return $self->{'version'};
}
sub caption {
  my $self = shift;
  if (@_) { $self->{'caption'} = shift }
  return $self->{'caption'};
}
sub description {
  my $self = shift;
  if (@_) { $self->{'description'} = shift }
  return $self->{'description'};
}
sub ctan {
  my $self = shift;
  if (@_) { $self->{'ctan'} = shift }
  return $self->{'ctan'};
}
sub texlive {
  my $self = shift;
  if (@_) { $self->{'texlive'} = shift }
  return $self->{'texlive'};
}
sub miktex {
  my $self = shift;
  if (@_) { $self->{'miktex'} = shift }
  return $self->{'miktex'};
}
sub docs {
  my $self = shift;
  my %newdocs = @_;
  if (@_) { $self->{'docs'} = \%newdocs }
  return $self->{'docs'};
}
sub entry {
  my $self = shift;
  my %newentry = @_;
  if (@_) { $self->{'entry'} = \%newentry }
  return $self->{'entry'};
}
sub alias {
  my $self = shift;
  my @newalias = @_;
  if (@_) { $self->{'alias'} = \@newalias }
  return $self->{'alias'};
}
sub also {
  my $self = shift;
  my @newalso = @_;
  if (@_) { $self->{'also'} = \@newalso }
  return $self->{'also'};
}
sub topics {
  my $self = shift;
  my @newtopics = @_;
  if (@_) { $self->{'topic'} = \@newtopics }
  return $self->{'topic'};
}
sub contact {
  my $self = shift;
  my %newcontact = @_;
  if (@_) { $self->{'contact'} = \%newcontact }
  return $self->{'contact'};
}


package TeXLive::TeXCatalogue;

sub new { 
  my $class = shift;
  my %params = @_;
  my $self = {
    location => $params{'location'},
    entries => defined($params{'entries'}) ? $params{'entries'} : {},
  };
  bless $self, $class;
  if (defined($self->{'location'})) {
    $self->initialize();
    $self->quest4texlive();
  }
  return $self;
}

sub initialize {
  my $self = shift;
  my $cwd = `pwd`;
  chomp($cwd);
  chdir($self->{'location'} . "/entries")
  || die "chdir($self->{location}/entries failed: $!";
  foreach (glob("?/*.xml")) {
    open(my $io,"<$_") or die "open($_) failed: $!";
    our $tce;
    eval { $tce = TeXLive::TeXCatalogue::Entry->new( 'ioref' => $io ); };
    if ($@) {
      warn "TeXCatalogue.pm:$_: cannot parse, skipping: $@\n";
      close($io);
      next;
    }
    close($io);
    $self->{'entries'}{lc($tce->{'entry'}{'id'})} = $tce;
  }
  chdir($cwd) || die ("Cannot change back to $cwd: $!");
}

sub quest4texlive {
  my $self = shift;

  my $texcat = $self->{'entries'};

  my (%inv, %count);
  for my $id (keys %{$texcat}) {
    my $tl = $texcat->{$id}{'texlive'};
    if (defined($tl)) {
      $tl =~ s/^bin-//;
      $count{$tl}++;
      $inv{$tl} = $id;
    }
  }
  for my $name (keys %inv) {
    if (!exists($texcat->{$name}) && $count{$name} == 1) {
      $texcat->{$name} = $texcat->{$inv{$name}};
    }
  }
}

sub location {
  my $self = shift;
  if (@_) { $self->{'location'} = shift }
  return $self->{'location'};
}

sub entries {
  my $self = shift;
  my %newentries = @_;
  if (@_) { $self->{'entries'} = \%newentries }
  return $self->{'entries'};
}

1;













1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TeXCatalogue.pm@TeXLive/TeXCatalogue.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/trans.pl@TeXLive/trans.pl
"TeXLive/trans.pl" => <<'__EOI__',

use strict;
$^W = 1;

use utf8;
no utf8;

if (defined($::opt_lang)) {
  $::lang = $::opt_lang;
  if ($::lang eq "zh") {
    $::lang = "zh_CN";
  }
} else {
  if ($^O =~ /^MSWin/i) {
    my ($lang, $area) =  TeXLive::TLWinGoo::reg_country();
    if ($lang) {
      $::lang = $lang;
      $::area = uc($area);
    } else {
      debug("didn't get any useful code from reg_country\n");
    }
  } else {
    require POSIX;
    import POSIX qw/locale_h/;
    my $loc = setlocale(&POSIX::LC_MESSAGES);
    my ($lang,$area,$codeset);
    if ($loc =~ m/^([^_.]*)(_([^.]*))?(\.([^@]*))?(@.*)?$/) {
      $lang = defined($1)?$1:"";
      $area = defined($3)?uc($3):"";
      if ($lang eq "zh") {
        if ($area =~ m/^(TW|HK)$/i) {
          $lang = "zh";
          $area = "TW";
        } else {
          $lang = "zh";
          $area = "CN";
        }
      }
    }
    $::lang = $lang if ($lang);
    $::area = $area if ($area);
  }
}


our %TRANS;

sub __ ($@) {
  my $key = shift;
  my $ret;
  if (!defined($::lang)) {
    $ret = $key;
  } else {
    $ret = $key;
    $key =~ s/\\/\\\\/g;
    $key =~ s/\n/\\n/g;
    $key =~ s/"/\\"/g;
    if (defined($TRANS{$::lang}->{$key})) {
      $ret = $TRANS{$::lang}->{$key};
      if ($::debug_translation && ($key eq $ret)) {
        print STDERR "probably untranslated in $::lang: >>>$key<<<\n";
      }
    } else {
      if ($::debug_translation && $::lang ne "en") {
        print STDERR "no translation in $::lang: >>>$key<<<\n";
      }
    }
    $ret =~ s/\\n/\n/g;
    $ret =~ s/\\"/"/g;
    $ret =~ s/\\\\/\\/g;
  }
  return sprintf($ret, @_);
}

sub load_translations() {
  if (defined($::lang) && ($::lang ne "en") && ($::lang ne "C")) {
    my $code = $::lang;
    my @files_to_check;
    if (defined($::area)) {
      $code .= "_$::area";
      push @files_to_check,
        $::lang . "_" . $::area, "$::lang-$::area",
        $::lang . "_" . lc($::area), "$::lang-" . lc($::area),
        $::lang;
    } else {
      push @files_to_check, $::lang;
    }
    my $found = 0;
    for my $f (@files_to_check) {
      if (-r "$::installerdir/tlpkg/translations/$f.po") {
        $found = 1;
        $::lang = $f;
        last;
      }
    }
    if (!$found) {
       debug ("no translations available for $code (nor $::lang); falling back to English\n");
    } else {
      open(LANG, "<$::installerdir/tlpkg/translations/$::lang.po");
      my $msgid;
      my $msgstr;
      my $inmsgid;
      my $inmsgstr;
      while (<LANG>) {
        chomp;
        next if m/^\s*#/;
        if (m/^\s*$/) {
          if ($inmsgid) {
            debug("msgid $msgid without msgstr in $::lang.po\n");
            $inmsgid = 0;
            $inmsgstr = 0;
            $msgid = "";
            $msgstr = "";
            next;
          }
          if ($inmsgstr) {
            if ($msgstr) {
              if (!utf8::decode($msgstr)) {
                warn("decoding string to utf8 didn't work: $msgstr\n");
              }
              if (!utf8::decode($msgid)) {
                warn("decoding string to utf8 didn't work: $msgid\n");
              }
              $TRANS{$::lang}{$msgid} = $msgstr;
            } else {
              ddebug("untranslated $::lang: ...$msgid...\n");
            }
            $inmsgid = 0;
            $inmsgstr = 0;
            $msgid = "";
            $msgstr = "";
            next;
          }
          next;
        }
        if (m/^msgid\s+"(.*)"\s*$/) {
          if ($msgid) {
            warn("stray msgid line: $_");
            next;
          }
          $inmsgid = 1;
          $msgid = $1;
          next;
        }
        if (m/^"(.*)"\s*$/) {
          if ($inmsgid) {
            $msgid .= $1;
          } elsif ($inmsgstr) {
            $msgstr .= $1;
          } else {
            tlwarn("cannot parse $::lang.po line: $_\n");
          }
          next;
        }
        if (m/^msgstr\s+"(.*)"\s*$/) {
          if (!$inmsgid) {
            tlwarn("msgstr $1 without msgid\n");
            next;
          }
          $msgstr = $1;
          $inmsgstr = 1;
          $inmsgid = 0;
        }
      }
      close(LANG);
    }
  }
}


1;










1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/trans.pl@TeXLive/trans.pl
);
unshift @INC, sub {
my $module = $modules{$_[1]}
or return;
return \$module
};
}
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/texmf-dist/scripts/texlive/tlmgr.pl

use strict; use warnings;

my $svnrev = '$Revision$';
my $datrev = '$Date$';
my $tlmgrrevision;
my $tlmgrversion;
my $prg;
my $bindir;
if ($svnrev =~ m/: ([0-9]+) /) {
  $tlmgrrevision = $1;
} else {
  $tlmgrrevision = "unknown";
}
$datrev =~ s/^.*Date: //;
$datrev =~ s/ \(.*$//;
$tlmgrversion = "$tlmgrrevision ($datrev)";

our $Master;
our $loadmediasrcerror;
our $packagelogfile;
our $packagelogged;
our $commandslogged;
our $commandlogfile;
our $tlmgr_config_file;
our $pinfile;
our $action; # for the pod2usage -sections call
our %opts;
our $allowed_verify_args_regex = qr/^(none|main|all)$/i;

END {
  if ($opts{"pause"}) {
    print "\n$prg: Pausing at end of run as requested; press Enter to exit.\n";
    <STDIN>;
  }
}

BEGIN {
  $^W = 1;
  my $kpsewhichname;
  if ($^O =~ /^MSWin/i) {
    $Master = __FILE__;
    $Master =~ s!\\!/!g;
    $Master =~ s![^/]*$!../../..!
      unless ($Master =~ s!/texmf-dist/scripts/texlive/tlmgr\.pl$!!i);
    $bindir = "$Master/bin/windows";
    $kpsewhichname = "kpsewhich.exe";
  } else {
    $Master = __FILE__;
    $Master =~ s,/*[^/]*$,,;
    $bindir = $Master;
    $Master = "$Master/../..";
    $ENV{"PATH"} = "$bindir:$ENV{PATH}";
    $kpsewhichname = "kpsewhich";
  }
  if (-r "$bindir/$kpsewhichname") {
    chomp($Master = `kpsewhich -var-value=TEXMFROOT`);
  }

  if (! $Master) {
    die ("Could not determine directory of tlmgr executable, "
         . "maybe shared library woes?\nCheck for error messages above");
  }

  $::installerdir = $Master;  # for config.guess et al., see TLUtils.pm

#  unshift (@INC, "$Master/tlpkg");# PACKPERLMODULES
#  unshift (@INC, "$Master/texmf-dist/scripts/texlive");# PACKPERLMODULES
}

use Cwd qw/abs_path/;
use File::Find;
use File::Spec;
use Pod::Usage;
use Getopt::Long qw(:config no_autoabbrev permute);

use TeXLive::TLConfig;
use TeXLive::TLPDB;
use TeXLive::TLPOBJ;
use TeXLive::TLUtils;
use TeXLive::TLWinGoo;
use TeXLive::TLDownload;
use TeXLive::TLConfFile;
use TeXLive::TLCrypto;
TeXLive::TLUtils->import(qw(member info give_ctan_mirror wndws dirname
                            mkdirhier copy debug tlcmp repository_to_array));
use TeXLive::TLPaper;

$prg = TeXLive::TLUtils::basename($0);
$::prg = $prg;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

our %config;       # hash of config settings from config file
our $remotetlpdb;
our $location;     # location from which the new packages come
our $localtlpdb;   # local installation which we are munging

our $FLAG_REMOVE = "d";
our $FLAG_FORCIBLE_REMOVED = "f";
our $FLAG_UPDATE = "u";
our $FLAG_REVERSED_UPDATE = "r";
our $FLAG_AUTOINSTALL = "a";
our $FLAG_INSTALL = "i";
our $FLAG_REINSTALL = "I";

our $common_fmtutil_args = 
  "--no-error-if-no-engine=$TeXLive::TLConfig::PartialEngineSupport";

$::gui_mode = 0;
$::machinereadable = 0;

my %action_specification = (
  '_include_tlpobj' => {
    "run-post" => 0,
    "function" => \&action_include_tlpobj
  },
  "backup" => { 
    "options" => {
      "all" => 1,
      "backupdir" => "=s",
      "clean" => ":-99",
      "dry-run|n" => 1
    },
    "run-post" => 1,
    "function" => \&action_backup
  },
  "candidates" => {
    "run-post" => 0,
    "function" => \&action_candidates
  },
  "check" => { 
    "options"  => { "use-svn" => 1 },
    "run-post" => 1,
    "function" => \&action_check
  },
  "conf" => {
    "options"  => { 
      "conffile" => "=s",
      "delete" => 1,
    },
    "run-post" => 0,
    "function" => \&action_conf
  },
  "dump-tlpdb" => { 
    "options"  => { local => 1, remote => 1 },
    "run-post" => 0,
    "function" => \&action_dumptlpdb
  },
  "generate" => { 
    "options"  => {
      "dest" => "=s",
      "localcfg" => "=s",
      "rebuild-sys" => 1
    },
    "run-post" => 1,
    "function" => \&action_generate
  },
  "get-mirror" => {
    "run-post" => 0,
    "function" => \&action_get_mirror
  },
  "gui" => { 
    "options"  => {
      "load" => 1,
      "background" => "=s",
      "class" => "=s",
      "display" => "=s",
      "font" => "=s",
      "foreground" => "=s",
      "geometry" => "=s",
      "iconic" => 1,
      "motif" => 1,
      "name" => "=s",
      "screen" => "=s",
      "synchronous" => 1,
      "title" => "=s",
      "xrm" => "=s",
    },
    "run-post" => 1,
    "function" => \&action_gui
  },
  "info" => { 
    "options"  => { 
      "data" => "=s",
      "all" => 1,
      "list" => 1, 
      "only-installed" => 1,
      "only-remote" => 1
    },
    "run-post" => 0,
    "function" => \&action_info
  },
  "init-usertree" => {
    "run-post" => 0,
    "function" => \&action_init_usertree
  },
  "install" => {
    "options"  => {
      "dry-run|n" => 1,
      "file" => 1,
      "force" => 1,
      "no-depends"        => 1,
      "no-depends-at-all" => 1,
      "reinstall" => 1,
      "with-doc" => 1,
      "with-src" => 1,
    },
    "run-post" => 1,
    "function" => \&action_install
  },
  "key" => {
    "run-post" => 0,
    "function" => \&action_key
  },
  "option" => { 
    "run-post" => 1,
    "function" => \&action_option
  },
  "paper" => { 
    "options"  => { "list" => 1 },
    "run-post" => 1,
    "function" => \&action_paper
  },
  "path" => {
    "options"  => { "windowsmode|w32mode" => "=s" },
    "run-post" => 0,
    "function" => \&action_path
  },
  "pinning" => { 
    "options"  => { "all" => 1 },
    "run-post" => 1,
    "function" => \&action_pinning
  },
  "platform" => { 
    "options"  => { "dry-run|n" => 1 },
    "run-post" => 1,
    "function" => \&action_platform
  },
  "postaction" => {
    "options" => {
      "all" => 1,
      "fileassocmode" => "=i",
      "windowsmode|w32mode" => "=s",
    },
    "run-post" => 0,
    "function" => \&action_postaction
  },
  "recreate-tlpdb" => { 
    "options"  => { "platform|arch" => "=s" },
    "run-post" => 0,
    "function" => \&action_recreate_tlpdb
  },
  "remove" => { 
    "options"  => {
      "all" => 1,
      "backup" => 1,
      "backupdir" => "=s",
      "dry-run|n" => 1,
      "force" => 1,
      "no-depends"        => 1,
      "no-depends-at-all" => 1,
    },
    "run-post" => 1,
    "function" => \&action_remove
  },
  repository => {
    "options"  => { "with-platforms" => 1 },
    "run-post" => 1,
    "function" => \&action_repository
  },
  "restore" => {
    "options"  => {
      "all" => 1,
      "backupdir" => "=s",
      "dry-run|n" => 1,
      "force" => 1
    },
    "run-post" => 1,
    "function" => \&action_restore
  },
  "search" => {
    "options"  => {
      "all" => 1,
      "file" => 1,
      "global" => 1,
      "word" => 1,
    },
    "run-post" => 1,
    "function" => \&action_search
  },
  "shell" => {
    "function" => \&action_shell
  },
  "update" => {
    "options"  => {
      "all" => 1,
      "backup" => 1,
      "backupdir" => "=s",
      "dry-run|n" => 1,
      "exclude" => "=s@",
      "force" => 1,
      "list" => 1,
      "no-auto-install"            => 1,
      "no-auto-remove"             => 1,
      "no-depends"                 => 1,
      "no-depends-at-all"          => 1,
      "no-restart"                 => 1,
      "reinstall-forcibly-removed" => 1,
      "self" => 1,
    },
    "run-post" => 1,
    "function" => \&action_update
  },
  "version" => { }, # handled separately
);

my %globaloptions = (
  "gui" => 1,
  "gui-lang" => "=s",
  "debug-json-timing" => 1,
  "debug-translation" => 1,
  "h|?" => 1,
  "help" => 1,
  "json" => 1,
  "location|repository|repo" => "=s",
  "machine-readable" => 1,
  "no-execute-actions" => 1,
  "package-logfile" => "=s",
  "command-logfile" => "=s",
  "persistent-downloads" => "!",
  "pause" => 1,
  "pin-file" => "=s",
  "print-platform|print-arch" => 1,
  "print-platform-info" => 1,
  "usermode|user-mode" => 1,
  "usertree|user-tree" => "=s",
  "verify-repo" => "=s",
  "verify-downloads" => "!",
  "require-verification" => "!",
  "version" => 1,
);

main();



sub main {
  my %options;       # TL options from local tlpdb

  my %optarg;
  for my $k (keys %globaloptions) {
    if ($globaloptions{$k} eq "1") {
      $optarg{$k} = 1;
    } else {
      $optarg{"$k" . $globaloptions{$k}} = 1;
    }
  }
  for my $v (values %action_specification) {
    if (defined($v->{'options'})) {
      my %opts = %{$v->{'options'}};
      for my $k (keys %opts) {
        if ($opts{$k} eq "1") {
          $optarg{$k} = 1;
        } else {
          $optarg{"$k" . $opts{$k}} = 1;
        }
      }
    }
  }

  @::SAVEDARGV = @ARGV;

  TeXLive::TLUtils::process_logging_options();

  GetOptions(\%opts, keys(%optarg)) or pod2usage(2);

  load_config_file();

  $::debug_translation = 0;
  $::debug_translation = 1 if $opts{"debug-translation"};

  $::machinereadable = $opts{"machine-readable"}
    if (defined($opts{"machine-readable"}));

  $action = shift @ARGV;
  if (!defined($action)) {
    if ($opts{"gui"}) {   # -gui = gui
      $action = "gui";
    } elsif ($opts{"print-platform"}) {
      $action = "print-platform";
    } elsif ($opts{"print-platform-info"}) {
      $action = "print-platform-info";
    } else {
      $action = "";
    }
  }
  $action = lc($action);

  $action = "platform" if ($action eq "arch");

  ddebug("action = $action\n");
  for my $k (keys %opts) {
    ddebug("$k => " . (defined($opts{$k}) ? $opts{$k} : "(undefined)") . "\n");
  }
  ddebug("arguments: @ARGV\n") if @ARGV;

  $::opt_lang = $config{"gui-lang"} if (defined($config{"gui-lang"}));
  $::opt_lang = $opts{"gui-lang"} if (defined($opts{"gui-lang"}));
  require("TeXLive/trans.pl");
  load_translations();

  if ($opts{"version"} || (defined $action && $action eq "version")) {
    if ($::machinereadable) {
      print give_version();
    } else {
      info(give_version());
    }
    exit(0);
  }

  if (defined($action) && $action eq "help") {
    $opts{"help"} = 1;
    $action = undef;  # an option not an action
  }

  if (defined($action) && $action eq "print-platform") {
    print TeXLive::TLUtils::platform(), "\n";
    exit 0;
  }

  if (defined($action) && $action eq "print-platform-info") {
    print "config.guess  ", `$::installerdir/tlpkg/installer/config.guess`;
    my $plat = TeXLive::TLUtils::platform();
    print "platform      ", $plat, "\n";
    print "platform_desc ", TeXLive::TLUtils::platform_desc($plat), "\n";
    exit 0;
  }


  if (defined $action 
      && $action =~ /^(paper|xdvi|psutils|pdftex|dvips|dvipdfmx?|context)$/) {
    unshift(@ARGV, $action);
    $action = "paper";
  }

  if (defined $action && $action =~ /^(show|list)$/) {
    $action = "info";
  }
  if (defined $action && $action eq "uninstall") {
    $action = "remove";
  }

  if (defined($opts{"verify-repo"}) &&
      ($opts{"verify-repo"} !~ m/$allowed_verify_args_regex/)) {
    tldie("$prg: unknown value for --verify-repo: $opts{'verify-repo'}\n");
  }
  $opts{"verify-repo"}
    = convert_crypto_options($opts{"verify-downloads"},
                             $opts{"require-verification"},
                             $opts{"verify-repo"});
  if (defined($opts{"verify-downloads"})
      || defined($opts{"require-verification"})) {
    tlwarn("$prg: please use -verify-repo options instead of verify-downloads/require-verification\n" .
           "$prg: adjusting to --verify-repo=$opts{'verify-repo'}\n");
  }
  delete $opts{"require-verification"};
  delete $opts{"verify-downloads"};

  if (defined($action) && $action && !exists $action_specification{$action}) {
    die "$prg: unknown action: $action; try --help if you need it.\n";
  }

  if ((!defined($action) || !$action) && !$opts{"help"} && !$opts{"h"}) {
    die "$prg: no action given; try --help if you need it.\n";
  }

  if ($opts{"help"} || $opts{"h"}) {
    my @noperldoc = ();
    if (wndws() || $ENV{"NOPERLDOC"}) {
      @noperldoc = ("-noperldoc", "1");
    } else {
      if (!TeXLive::TLUtils::which("perldoc")) {
        @noperldoc = ("-noperldoc", "1");
      } else {
        my $ret = system("perldoc -V >/dev/null 2>&1");
        if ($ret == 0) {
          debug("working perldoc found, using it\n");
        } else {
          tlwarn("$prg: perldoc seems to be non-functional, not using it.\n");
          @noperldoc = ("-noperldoc", "1");
        }
      }
    }
    if (defined($ENV{'LESS'})) {
      $ENV{'LESS'} .= " -R";
    } else {
      $ENV{'LESS'} = "-R";
    }
    delete $ENV{'LESSPIPE'};
    delete $ENV{'LESSOPEN'};
    if ($action && ($action ne "help")) {
      pod2usage(-exitstatus => 0, -verbose => 99,
                -sections => [ 'NAME', 'SYNOPSIS', "ACTIONS/$::action.*" ],
                @noperldoc);
    } else {
      if ($opts{"help"}) {
        pod2usage(-exitstatus => 0, -verbose => 2, @noperldoc);
      } else {
        print "
tlmgr revision $tlmgrversion
usage: tlmgr  OPTION...  ACTION  ARGUMENT...
where ACTION is one of:\n";
        for my $k (sort keys %action_specification) {
          next if ($k =~ m/^_/);
          print " $k\n";
        }
        print "\nUse\n tlmgr ACTION --help
for more details on a specific option, and
 tlmgr --help
for the full story.\n";
        exit 0;
      }
    }
  }

  if ($::machinereadable && 
    $action ne "update" && $action ne "install" && $action ne "option" && $action ne "shell" && $action ne "remove") {
    tlwarn("$prg: --machine-readable output not supported for $action\n");
  }

  if (!defined($action_specification{$action})) {
    tlwarn("$prg: action unknown: $action\n");
    exit ($F_ERROR);
  }

  my %suppargs;
  %suppargs = %{$action_specification{$action}{'options'}}
    if defined($action_specification{$action}{'options'});
  my @notvalidargs;
  for my $k (keys %opts) {
    my @allargs = keys %suppargs;
    push @allargs, keys %globaloptions;
    my $found = 0;
    for my $ok (@allargs) {
      my @variants = split '\|', $ok;
      if (TeXLive::TLUtils::member($k, @variants)) {
        $found = 1;
        last;
      }
    }
    push @notvalidargs, $k if !$found;
  }
  if (@notvalidargs) {
    my $msg = "The action $action does not support the following option(s):\n";
    for my $c (@notvalidargs) {
      $msg .= " $c";
    }
    tlwarn("$prg: $msg\n");
    tldie("$prg: Try --help if you need it.\n");
  }

  debug("tlmgr version $tlmgrversion\n");

  $::maintree = $Master;
  if ($opts{"usermode"}) {
    if (defined($opts{"usertree"})) {
      $::maintree = $opts{"usertree"};
    } else {
      chomp($::maintree = `kpsewhich -var-value TEXMFHOME`);
    }
  }
  debug("maintree=$::maintree\n");

  $packagelogged = 0;  # how many msgs we logged
  $commandslogged = 0;
  chomp (my $texmfsysvar = `kpsewhich -var-value=TEXMFSYSVAR`);
  chomp (my $texmfvar = `kpsewhich -var-value=TEXMFVAR`);
  $packagelogfile = $opts{"package-logfile"};
  if ($opts{"usermode"}) {
    $packagelogfile ||= "$texmfvar/web2c/tlmgr.log";
  } else {
    $packagelogfile ||= "$texmfsysvar/web2c/tlmgr.log";
  }
  if (!open(PACKAGELOG, ">>$packagelogfile")) {
    debug("Cannot open package log file for appending: $packagelogfile\n");
    debug("Will not log package installation/removal/update for this run\n");
    $packagelogfile = "";
  } else {
    debug("appending to package log file: $packagelogfile\n");
  }

  $commandlogfile = $opts{"command-logfile"};
  if ($opts{"usermode"}) {
    $commandlogfile ||= "$texmfvar/web2c/tlmgr-commands.log";
  } else {
    $commandlogfile ||= "$texmfsysvar/web2c/tlmgr-commands.log";
  }
  if (!open(COMMANDLOG, ">>$commandlogfile")) {
    debug("Cannot open command log file for appending: $commandlogfile\n");
    debug("Will not log output of executed commands for this run\n");
    $commandlogfile = "";
  } else {
    debug("appending to command log file: $commandlogfile\n");
  }

  $loadmediasrcerror = "Cannot load TeX Live database from ";

  if (!$opts{"usermode"} && $config{'allowed-actions'}) {
    if (!TeXLive::TLUtils::member($action, @{$config{'allowed-actions'}})) {
      tlwarn("$prg: action not allowed in system mode: $action\n");
      exit ($F_ERROR);
    }
  }

  $::no_execute_actions = 1 if (defined($opts{'no-execute-actions'}));

  ddebug("tlmgr:main: do persistent downloads = $opts{'persistent-downloads'}\n");
  if ($opts{'persistent-downloads'}) {
    TeXLive::TLUtils::setup_persistent_downloads(
      "$Master/tlpkg/installer/curl/curl-ca-bundle.crt"
    ) ;
  }
  if (!defined($::tldownload_server)) {
    debug("tlmgr:main: ::tldownload_server not defined\n");
  } else {
    if ($::opt_verbosity >= 1) {
      debug(debug_hash_str("$prg:main: ::tldownload_server hash:",
                            $::tldownload_server));
    }
  }

  my $ret = execute_action($action, @ARGV);

  if (!$::gui_mode) {
    if ($packagelogfile) {
      info("$prg: package log updated: $packagelogfile\n") if $packagelogged;
      close(PACKAGELOG);
    }
    if ($commandlogfile) {
      info("$prg: command log updated: $commandlogfile\n") if $commandslogged;
      close(COMMANDLOG);
    }
  }

  if ($ret & ($F_ERROR | $F_WARNING)) {
    tlwarn("$prg: An error has occurred. See above messages. Exiting.\n");
  }

  exit ($ret);

} # end main

sub give_version {
  if (!defined($::version_string)) {
    $::version_string = "";
    $::mrversion = "";
    $::version_string .= "tlmgr revision $tlmgrversion\n";
    $::mrversion .= "revision $tlmgrrevision\n";
    $::version_string .= "tlmgr using installation: $Master\n";
    $::mrversion .= "installation $Master\n";
    if (open (REL_TL, "$Master/release-texlive.txt")) {
      my $rel_tl = <REL_TL>;
      $::version_string .= $rel_tl;
      my @foo = split(' ', $rel_tl);
      $::mrversion .= "tlversion $foo[$#foo]\n";
      close (REL_TL);
    }
    if ($::opt_verbosity > 0) {
      $::version_string .= "Revisions of TeXLive:: modules:";
      $::version_string .= "\nTLConfig: " . TeXLive::TLConfig->module_revision();
      $::version_string .= "\nTLUtils:  " . TeXLive::TLUtils->module_revision();
      $::version_string .= "\nTLPOBJ:   " . TeXLive::TLPOBJ->module_revision();
      $::version_string .= "\nTLPDB:    " . TeXLive::TLPDB->module_revision();
      $::version_string .= "\nTLPaper:  " . TeXLive::TLPaper->module_revision();
      $::version_string .= "\nTLWinGoo: " . TeXLive::TLWinGoo->module_revision();
      $::version_string .= "\n";
    }
    $::mrversion      .= "TLConfig "   . TeXLive::TLConfig->module_revision();
    $::mrversion      .= "\nTLUtils "  . TeXLive::TLUtils->module_revision();
    $::mrversion      .= "\nTLPOBJ "   . TeXLive::TLPOBJ->module_revision();
    $::mrversion      .= "\nTLPDB "    . TeXLive::TLPDB->module_revision();
    $::mrversion      .= "\nTLPaper "  . TeXLive::TLPaper->module_revision();
    $::mrversion      .= "\nTLWinGoo " . TeXLive::TLWinGoo->module_revision();
    $::mrversion      .= "\n";
  }
  if ($::machinereadable) {
    return $::mrversion;
  } else {
    return $::version_string;
  }
}


sub execute_action {
  my ($action, @argv) = @_;

  @ARGV = @argv;

  if (!defined($action_specification{$action})) {
    tlwarn ("$prg: unknown action: $action; try --help if you need it.\n");
    return ($F_ERROR);
  }

  if (!defined($action_specification{$action}{"function"})) {
    tlwarn ("$prg: action $action defined, but no way to execute it.\n");
    return $F_ERROR;
  }

  my $ret = $F_OK;
  my $foo = &{$action_specification{$action}{"function"}}();
  if (defined($foo)) {
    if ($foo & $F_ERROR) {
      return $foo;
    }
    if ($foo & $F_WARNING) {
      tlwarn("$prg: action $action returned an error; continuing.\n");
      $ret = $foo;
    }
  } else {
    $ret = $F_OK;
    tlwarn("$prg: no value returned from action $action, assuming ok.\n");
  }
  my $run_post = 1;
  if ($ret & $F_NOPOSTACTION) {
    $ret ^= $F_NOPOSTACTION;
    $run_post = 0;
  }
  if (!$action_specification{$action}{"run-post"}) {
    $run_post = 0;
  }

  return ($ret) if (!$run_post);

  $ret |= &handle_execute_actions();

  return $ret;
}



sub do_cmd_and_check {
  my $cmd = shift;
  info("running $cmd ...\n");
  logcommand("running $cmd");
  logpackage("command: $cmd");
  my ($out, $ret);
  if ($opts{"dry-run"}) {
    $ret = $F_OK;
    $out = "";
  } elsif (wndws() && (! -r "$Master/bin/windows/luatex.dll")) {
    tlwarn("Cannot run wrapper due to missing luatex.dll\n");
    $ret = $F_OK;
    $out = "";
  } else {
    ($out, $ret) = TeXLive::TLUtils::run_cmd("$cmd 2>&1");
  }
  $out =~ s/\n+$//; # trailing newlines don't seem interesting
  my $outmsg = "output:\n$out\n--end of output of $cmd.\n";
  if ($ret == 0) {
    info("done running $cmd.\n") unless $cmd =~ /^fmtutil/;
    logcommand("success, $outmsg");
    ddebug("$cmd $outmsg");
  } else {
    info("\n");
    tlwarn("$prg: $cmd failed (status $ret), output:\n$out\n");
    logcommand("error, status: $ret, $outmsg");
    $ret = $F_ERROR;
  }
  return $ret;
}

sub handle_execute_actions {
  debug("starting handle_execute_actions\n");
  my $errors = 0;

  my $sysmode = ($opts{"usermode"} ? "-user" : "-sys");
  my $fmtutil_cmd = "fmtutil$sysmode";
  my $status_file = TeXLive::TLUtils::tl_tmpfile();
  my $fmtutil_args = "$common_fmtutil_args --status-file=$status_file";

  if (!$localtlpdb->option("create_formats")) {
    $fmtutil_args .= " --refresh";
    debug("refreshing only existing formats per user option (create_formats=0)\n");
  }

  if ($::files_changed) {
    $errors += do_cmd_and_check("mktexlsr");
    $::files_changed = 0;
  }

  chomp(my $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
  chomp(my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
  chomp(my $TEXMFLOCAL = `kpsewhich -var-value=TEXMFLOCAL`);
  chomp(my $TEXMFDIST = `kpsewhich -var-value=TEXMFDIST`);

  {
    my $updmap_run_needed = 0;
    for my $m (keys %{$::execute_actions{'enable'}{'maps'}}) {
      $updmap_run_needed = 1;
    }
    for my $m (keys %{$::execute_actions{'disable'}{'maps'}}) {
      $updmap_run_needed = 1;
    }
    my $dest = $opts{"usermode"} ? "$::maintree/web2c/updmap.cfg" 
               : "$TEXMFDIST/web2c/updmap.cfg";
    if ($updmap_run_needed) {
      TeXLive::TLUtils::create_updmap($localtlpdb, $dest);
    }
    $errors += do_cmd_and_check("updmap$sysmode") if $updmap_run_needed;
  }

  {
    my $regenerate_language = 0;
    for my $m (keys %{$::execute_actions{'enable'}{'hyphens'}}) {
      $regenerate_language = 1;
      last;
    }
    for my $m (keys %{$::execute_actions{'disable'}{'hyphens'}}) {
      $regenerate_language = 1;
      last;
    }
    if ($regenerate_language) {
      for my $ext ("dat", "def", "dat.lua") {
        my $lang = "language.$ext";
        info("regenerating $lang\n");
        my $arg1 = "$TEXMFSYSVAR/tex/generic/config/language.$ext";
        my $arg2 = "$TEXMFLOCAL/tex/generic/config/language-local.$ext";
        if ($ext eq "dat") {
          TeXLive::TLUtils::create_language_dat($localtlpdb, $arg1, $arg2);
        } elsif ($ext eq "def") {
          TeXLive::TLUtils::create_language_def($localtlpdb, $arg1, $arg2);
        } else {
          TeXLive::TLUtils::create_language_lua($localtlpdb, $arg1, $arg2);
        }
      }
    }

    my %done_formats;
    my %updated_engines;
    my %format_to_engine;
    my %do_enable;
    my $do_full = 0;
    for my $m (keys %{$::execute_actions{'enable'}{'formats'}}) {
      $do_full = 1;
      $do_enable{$m} = 1;
      my %foo = %{$::execute_actions{'enable'}{'formats'}{$m}};
      if (!defined($foo{'name'}) || !defined($foo{'engine'})) {
        tlwarn("$prg: Very strange error, please report ", %foo);
      } else {
        $format_to_engine{$m} = $foo{'engine'};
        if ($foo{'name'} eq $foo{'engine'}) {
          $updated_engines{$m} = 1;
        }
      }
    }
    for my $m (keys %{$::execute_actions{'disable'}{'formats'}}) {
      $do_full = 1;
    }
    if ($do_full) {
      info("regenerating fmtutil.cnf in $TEXMFDIST\n");
      TeXLive::TLUtils::create_fmtutil($localtlpdb,
                                       "$TEXMFDIST/web2c/fmtutil.cnf");
    }
    if (!$::regenerate_all_formats) {
      for my $e (keys %updated_engines) {
        debug ("updating formats based on $e\n");
        $errors += do_cmd_and_check
          ("$fmtutil_cmd --byengine $e --no-error-if-no-format $fmtutil_args");
        read_and_report_fmtutil_status_file($status_file);
        unlink($status_file);
      }
      for my $f (keys %do_enable) {
        next if defined($updated_engines{$format_to_engine{$f}});
        next if !$::execute_actions{'enable'}{'formats'}{$f}{'mode'};
        debug ("(re)creating format dump $f\n");
        $errors += do_cmd_and_check ("$fmtutil_cmd --byfmt $f $fmtutil_args");
        read_and_report_fmtutil_status_file($status_file);
        unlink($status_file);
        $done_formats{$f} = 1;
      }
    }

    if ($regenerate_language) {
      for my $ext ("dat", "def", "dat.lua") {
        my $lang = "language.$ext";
        if (! TeXLive::TLUtils::wndws()) {
          $lang = "$TEXMFSYSVAR/tex/generic/config/$lang";
        }
        if (!$::regenerate_all_formats) {
          $errors += do_cmd_and_check ("$fmtutil_cmd --byhyphen \"$lang\" $fmtutil_args");
          read_and_report_fmtutil_status_file($status_file);
          unlink($status_file);
        }
      }
    }

    if ($::regenerate_all_formats) {
      info("Regenerating existing formats, this may take some time ...");
      my $args = "--refresh --all";
      $errors += do_cmd_and_check("$fmtutil_cmd $args $fmtutil_args");
      read_and_report_fmtutil_status_file($status_file);
      unlink($status_file);
      info("done\n");
      $::regenerate_all_formats = 0;
    }
  }

  if (defined $::context_cache_update_needed
      && $::context_cache_update_needed) {
    if ($opts{"dry-run"}) {
      debug("dry-run, skipping context cache update\n");
    } else {
      my $progext = ($^O =~ /^MSWin/i ? ".exe" : "");
      $errors +=
        TeXLive::TLUtils::update_context_cache($bindir, $progext,
                                               \&run_postinst_logcommand);
    }
    $::context_cache_update_needed = 0;
  }

  undef %::execute_actions;

  debug("finished handle_execute_actions, errors=$errors\n");
  if ($errors > 0) {
    return $F_ERROR;
  } else {
    return $F_OK;
  }
}

sub run_postinst_logcommand {
  my ($cmd) = @_;
  logpackage("command: $cmd");
  logcommand("running $cmd");
  my $ret = TeXLive::TLUtils::run_cmd_with_log ($cmd, \&logcommand_bare);
  my $outmsg = "\n--end of output of $cmd";
  if ($ret == 0) {
    info("done running $cmd.\n") unless $cmd =~ /^fmtutil/;
    logcommand("$outmsg (success).\n");
  } else {
    info("\n");
    tlwarn("$prg: $cmd failed (status $ret), see $commandlogfile\n");
    logcommand("$outmsg (failure, status $ret");
    $ret = 1;
  }
  return $ret;
}

sub read_and_report_fmtutil_status_file {
  my $status_file = shift;
  my $fh;
  if (!open($fh, '<', $status_file)) {
    printf STDERR "Cannot read status file $status_file, strange!\n";
    return;
  }
  chomp(my @lines = <$fh>);
  close $fh;
  my @failed;
  my @success;
  for my $l (@lines) {
    my ($status, $fmt, $eng, $what, $whatargs) = split(' ', $l, 5);
    if ($status eq "DISABLED") {
    } elsif ($status eq "NOTSELECTED") {
    } elsif ($status eq "FAILURE") {
      push @failed, "${fmt}.fmt/$eng";
    } elsif ($status eq "SUCCESS") {
      push @success, "${fmt}.fmt/$eng";
    } elsif ($status eq "NOTAVAIL") {
    } elsif ($status eq "UNKNOWN") {
    } else {
    }
  }
  logpackage("  OK: @success") if (@success);
  logpackage("  ERROR: @failed") if (@failed);
  logcommand("  OK: @success") if (@success);
  logcommand("  ERROR: @failed") if (@failed);
  info("  OK: @success\n") if (@success);
  info("  ERROR: @failed\n") if (@failed);
}

sub action_get_mirror {
  my $loc = give_ctan_mirror(); 
  print "$loc\n";
  return ($F_OK | $F_NOPOSTACTION);
}


sub action_include_tlpobj {
  init_local_db();
  for my $f (@ARGV) {
    my $tlpobj = TeXLive::TLPOBJ->new;
    $tlpobj->from_file($f);
    my $pkg = $tlpobj->name;
    if ($pkg =~ m/^(.*)\.(source|doc)$/) {
      my $type = $2;
      my $mothership = $1;
      my $mothertlp = $localtlpdb->get_package($mothership);
      if (!defined($mothertlp)) {
        tlwarn("$prg: We are trying to add ${type} files to a nonexistent package $mothership!\n");
        tlwarn("$prg: Trying to continue!\n");
        $tlpobj->name($mothership);
        $localtlpdb->add_tlpobj($tlpobj);
      } else {
        if ($type eq "source") {
          $mothertlp->srcfiles($tlpobj->srcfiles);
          $mothertlp->srcsize($tlpobj->srcsize);
        } else {
          $mothertlp->docfiles($tlpobj->docfiles);
          $mothertlp->docsize($tlpobj->docsize);
        }
        $localtlpdb->add_tlpobj($mothertlp);
      }
    } else {
      $localtlpdb->add_tlpobj($tlpobj);
    }
    $localtlpdb->save;
  }
  return ($F_OK);
}



sub backup_and_remove_package {
  my ($pkg, $autobackup) = @_;
  my $tlp = $localtlpdb->get_package($pkg);
  if (!defined($tlp)) {
    info("$pkg: package not present, cannot remove\n");
    return($F_WARNING);
  }
  if ($opts{"backup"}) {
    $tlp->make_container($::progs{'compressor'}, $localtlpdb->root,
                         destdir => $opts{"backupdir"}, 
                         relative => $tlp->relocated,
                         user => 1);
    if ($autobackup) {
      clear_old_backups($pkg, $opts{"backupdir"}, $autobackup);
    }
  }
  return($localtlpdb->remove_package($pkg));
}

sub action_remove {
  if ($opts{'all'}) {
    if (@ARGV) {
      tlwarn("$prg: No additional arguments allowed with --all: @ARGV\n");
      return($F_ERROR);
    }
    exit(uninstall_texlive());
  }
  $opts{"no-depends"} = 1 if $opts{"no-depends-at-all"};
  my %already_removed;
  my @more_removal;
  init_local_db();
  return($F_ERROR) if !check_on_writable();
  info("$prg remove: dry run, no changes will be made\n") if $opts{"dry-run"};

  my ($ret, $autobackup) = setup_backup_directory();
  return ($ret) if ($ret != $F_OK);

  my @packs = @ARGV;
  @packs = $localtlpdb->expand_dependencies("-only-arch", $localtlpdb, @packs)
    unless $opts{"no-depends-at-all"}; 
  @packs = $localtlpdb->expand_dependencies("-no-collections", $localtlpdb, @packs) unless $opts{"no-depends"};
  my %allpacks;
  for my $p ($localtlpdb->list_packages) { $allpacks{$p} = 1; }
  for my $p (@packs) { delete($allpacks{$p}); }
  my @neededpacks = $localtlpdb->expand_dependencies($localtlpdb, keys %allpacks);
  my %packs;
  my %origpacks;
  my @origpacks = $localtlpdb->expand_dependencies("-only-arch", $localtlpdb, @ARGV) unless $opts{"no-depends-at-all"};
  for my $p (@origpacks) { $origpacks{$p} = 1; }
  for my $p (@packs) { $packs{$p} = 1; }
  for my $p (@neededpacks) {
    if (defined($origpacks{$p})) {
      my @needed = $localtlpdb->needed_by($p);
      if ($opts{"force"}) {
        info("$prg: $p is needed by " . join(" ", @needed) . "\n");
        info("$prg: removing it anyway, due to --force\n");
      } else {
        delete($packs{$p});
        tlwarn("$prg: not removing $p, needed by " .
          join(" ", @needed) . "\n");
        $ret |= $F_WARNING;
      }
    } else {
      delete($packs{$p});
    }
  }
  @packs = keys %packs;

  my %sizes = %{$localtlpdb->sizes_of_packages(
    $localtlpdb->option("install_srcfiles"),
    $localtlpdb->option("install_docfiles"), undef, @packs)};
  defined($sizes{'__TOTAL__'}) || ($sizes{'__TOTAL__'} = 0);
  my $totalsize = $sizes{'__TOTAL__'};
  my $totalnr = $#packs;
  my $currnr = 1;
  my $starttime = time();
  my $donesize = 0;
  
  print "total-bytes\t$sizes{'__TOTAL__'}\n" if $::machinereadable;
  print "end-of-header\n" if $::machinereadable;

  foreach my $pkg (sort @packs) {
    my $tlp = $localtlpdb->get_package($pkg);
    next if defined($already_removed{$pkg});
    if (!defined($tlp)) {
      info("$pkg: package not present, cannot remove\n");
      $ret |= $F_WARNING;
    } else {
      my ($estrem, $esttot) = TeXLive::TLUtils::time_estimate($totalsize,
                                                              $donesize, $starttime);

      if ($tlp->category eq "Collection") {
        my $foo = 0;
        if ($::machinereadable) {
          machine_line($pkg, "d", $tlp->revision, "-", $sizes{$pkg}, $estrem, $esttot);
        } else {
          info("[$currnr/$totalnr, $estrem/$esttot] remove: $pkg\n");
        }
        if (!$opts{"dry-run"}) {
          $foo = backup_and_remove_package($pkg, $autobackup);
          logpackage("remove: $pkg");
        }
        $currnr++;
        $donesize += $sizes{$pkg};
        if ($foo) {
          $already_removed{$pkg} = 1;
        }
      } else {
        push (@more_removal, $pkg);
      }
    }
  }
  foreach my $pkg (sort @more_removal) {
    my $tlp = $localtlpdb->get_package($pkg);
    if (!defined($already_removed{$pkg})) {
      my ($estrem, $esttot) = TeXLive::TLUtils::time_estimate($totalsize,
                                                              $donesize, $starttime);
      if ($::machinereadable) {
        machine_line($pkg, "d", $tlp->revision, "-", $sizes{$pkg}, $estrem, $esttot);
      } else {
        info("[$currnr/$totalnr, $estrem/$esttot] remove: $pkg\n");
      }
      $currnr++;
      $donesize += $sizes{$pkg};
      if (!$opts{"dry-run"}) {
        if (backup_and_remove_package($pkg, $autobackup)) {
          logpackage("remove: $pkg");
          $already_removed{$pkg} = 1;
        }
      }
    }
  }
  print "end-of-updates\n" if $::machinereadable;
  if ($opts{"dry-run"}) {
    return ($ret | $F_NOPOSTACTION);
  } else {
    $localtlpdb->save;
    my @foo = sort keys %already_removed;
    if (@foo) {
      info("$prg: ultimately removed these packages: @foo\n")
        if (!$::machinereadable);
    } else {
      info("$prg: no packages removed.\n")
        if (!$::machinereadable);
    }
  }
  return ($ret);
}


sub action_paper {
  init_local_db();
  my $texmfconfig;
  if ($opts{"usermode"}) {
    tlwarn("$prg: action `paper' not supported in usermode\n");
    return ($F_ERROR);
  }
  chomp($texmfconfig = `kpsewhich -var-value=TEXMFSYSCONFIG`);
  $ENV{"TEXMFCONFIG"} = $texmfconfig;

  my $action = shift @ARGV;
  if (!$action) {
    $action = "paper";
  }

  if ($action =~ m/^paper$/i) {  # generic paper
    my $newpaper = shift @ARGV;
    if ($opts{"list"}) {  # tlmgr paper --list => complain.
      tlwarn("$prg: ignoring paper setting to $newpaper with --list\n")
        if $newpaper;  # complain if they tried to set, too.
      tlwarn("$prg: please specify a program before paper --list, ",
             "as in: tlmgr pdftex paper --list\n");
      return($F_ERROR)

    } elsif (!defined($newpaper)) {  # tlmgr paper => show all current sizes.
      my $ret = $F_OK;
      if ($opts{'json'}) {
        my @foo;
        for my $prog (keys %TeXLive::TLPaper::paper) {
          my $pkg = $TeXLive::TLPaper::paper{$prog}{'pkg'};
          if ($localtlpdb->get_package($pkg)) {
            my $val = TeXLive::TLPaper::do_paper($prog,$texmfconfig,"--json");
            push @foo, $val;
          }
        }
        my $json = TeXLive::TLUtils::encode_json(\@foo);
        print "$json\n";
        return $ret;
      }
      for my $prog (sort keys %TeXLive::TLPaper::paper) {
        my $pkg = $TeXLive::TLPaper::paper{$prog}{'pkg'};
        if ($localtlpdb->get_package($pkg)) {
          $ret |= TeXLive::TLPaper::do_paper($prog,$texmfconfig,undef);
        }
      }
      return($ret);

    } elsif ($newpaper !~ /^(a4|letter)$/) {  # tlmgr paper junk => complain.
      $newpaper = "the empty string" if !defined($newpaper);
      tlwarn("$prg: expected `a4' or `letter' after paper, not $newpaper\n");
      return($F_ERROR);

    } else { # tlmgr paper {a4|letter} => do it.
      return ($F_ERROR) if !check_on_writable();
      if ($opts{'json'}) {
        tlwarn("$prg: option --json not supported with other arguments\n");
        return ($F_ERROR);
      }
      my $ret = $F_OK;
      for my $prog (sort keys %TeXLive::TLPaper::paper) {
        my $pkg = $TeXLive::TLPaper::paper{$prog}{'pkg'};
        if ($localtlpdb->get_package($pkg)) {
          $ret |= TeXLive::TLPaper::do_paper($prog,$texmfconfig,$newpaper);
        }
      }
      return($ret);
    }

  } else {  # program-specific paper
    if ($opts{'json'}) {
      tlwarn("$prg: option --json not supported with other arguments\n");
      return ($F_ERROR);
    }
    my $prog = $action;     # first argument is the program to change
    my $pkg = $TeXLive::TLPaper::paper{$prog}{'pkg'};
    if (!$pkg) {
      tlwarn("Unknown paper configuration program $prog!\n");
      return ($F_ERROR);
    }
    if (!$localtlpdb->get_package($pkg)) {
      tlwarn("$prg: package $prog is not installed - cannot adjust paper size!\n");
      return ($F_ERROR);
    }
    my $arg = shift @ARGV;  # get "paper" argument
    if (!defined($arg) || $arg ne "paper") {
      $arg = "the empty string." if ! $arg;
      tlwarn("$prg: expected `paper' after $prog, not $arg\n");
      return ($F_ERROR);
    }
    if (@ARGV) {
      return ($F_ERROR) if !check_on_writable();
    }
    unshift(@ARGV, "--list") if $opts{"list"};
    return(TeXLive::TLPaper::do_paper($prog,$texmfconfig,@ARGV));
  }
  return($F_OK);
}


sub action_path {
  if ($opts{"usermode"}) {
    tlwarn("$prg: action `path' not supported in usermode!\n");
    exit 1;
  }
  my $what = shift @ARGV;
  if (!defined($what) || ($what !~ m/^(add|remove)$/i)) {
    $what = "" if ! $what;
    tlwarn("$prg: action path requires add or remove, not: $what\n");
    return ($F_ERROR);
  }
  init_local_db();
  my $winadminmode = 0;
  if (wndws()) {
    if (!$opts{"windowsmode"}) {
      $winadminmode = $localtlpdb->option("w32_multi_user");
      if (!TeXLive::TLWinGoo::admin()) {
        if ($winadminmode) {
          tlwarn("The TLPDB specifies system wide path adjustments\nbut you don't have admin privileges.\nFor user path adjustment please use\n\t--windowsmode user\n");
          return ($F_ERROR);
        }
      }
    } else {
      if (TeXLive::TLWinGoo::admin()) {
        if ($opts{"windowsmode"} eq "user") {
          $winadminmode = 0;
        } elsif ($opts{"windowsmode"} eq "admin") {
          $winadminmode = 1;
        } else {
          tlwarn("$prg: unknown --windowsmode mode: $opts{windowsmode}, should be 'admin' or 'user'\n");
          return ($F_ERROR);
        }
      } else {
        if ($opts{"windowsmode"} eq "user") {
          $winadminmode = 0;
        } elsif ($opts{"windowsmode"} eq "admin") {
          tlwarn("$prg: You don't have the privileges to work in --windowsmode admin\n");
          return ($F_ERROR);
        } else {
          tlwarn("$prg: unknown --windowsmode mode: $opts{windowsmode}, should be 'admin' or 'user'\n");
          return ($F_ERROR);
        }
      }
    }
  }
  my $ret = $F_OK;
  if ($what =~ m/^add$/i) {
    if (wndws()) {
      $ret |= TeXLive::TLUtils::w32_add_to_path(
        $localtlpdb->root . "/bin/windows",
        $winadminmode);
    } else {
      $ret |= TeXLive::TLUtils::add_symlinks($localtlpdb->root,
        $localtlpdb->platform(),
        $localtlpdb->option("sys_bin"),
        $localtlpdb->option("sys_man"),
        $localtlpdb->option("sys_info"));
    }
  } elsif ($what =~ m/^remove$/i) {
    if (wndws()) {
      $ret |= TeXLive::TLUtils::w32_remove_from_path(
        $localtlpdb->root . "/bin/windows",
        $winadminmode);
    } else {
      $ret |= TeXLive::TLUtils::remove_symlinks($localtlpdb->root,
        $localtlpdb->platform(),
        $localtlpdb->option("sys_bin"),
        $localtlpdb->option("sys_man"),
        $localtlpdb->option("sys_info"));
    }
  } else {
    tlwarn("\n$prg: Should not happen, action_path what=$what\n");
    return ($F_ERROR);
  }
  return ($ret | $F_NOPOSTACTION);
}

sub action_dumptlpdb {
  init_local_db();
  
  my $savemr = $::machinereadable;
  $::machinereadable = 1;
  
  if ($opts{"local"} && !$opts{"remote"}) {
    if ($opts{"json"}) {
      print $localtlpdb->as_json;
    } else {
      print "location-url\t", $localtlpdb->root, "\n";
      $localtlpdb->writeout;
    }

  } elsif ($opts{"remote"} && !$opts{"local"}) {
    init_tlmedia_or_die(1);
    if ($opts{"json"}) {
      print $remotetlpdb->as_json;
    } else {
      $remotetlpdb->writeout;
    }

  } else {
    tlwarn("$prg dump-tlpdb: need exactly one of --local and --remote.\n");
    return ($F_ERROR);
  }
  
  $::machinereadable = $savemr;
  return ($F_OK | $F_NOPOSTACTION);
}
    
sub action_info {
  if ($opts{'only-installed'} && $opts{'only-remote'}) {
    tlwarn("Are you joking? --only-installed and --only-remote cannot both be specified!\n");
    return($F_ERROR);
  }
  init_local_db();
  my ($what,@todo) = @ARGV;
  my $ret = $F_OK | $F_NOPOSTACTION;
  my @datafields;
  my $fmt = "list";
  if ($opts{'data'} && $opts{'json'}) {
    tlwarn("Preferring json output over data output!\n");
    delete($opts{'data'});
  }
  if ($opts{'json'}) {
    $fmt = 'json';
    init_tlmedia_or_die(1);
  } elsif ($opts{'data'}) {
    if ($opts{'data'} =~ m/:/) {
      @datafields = split(':', $opts{'data'});
    } else {
      @datafields = split(',', $opts{'data'});
    }
    my $load_remote = 0;
    for my $d (@datafields) {
      $load_remote = 1 if ($d eq "remoterev");
      if ($d !~ m/^(name|category|localrev|remoterev|shortdesc|longdesc|size|installed|relocatable|depends|[lr]?cat-version|[lr]?cat-date|[lr]?cat-license|[lr]?cat-contact-.*)$/) {
        tlwarn("unknown data field: $d\n");
        return($F_ERROR);
      }
    }
    $fmt = "csv";
    if ($load_remote) {
      if ($opts{"only-installed"}) {
        tlwarn("requesting only-installed with data field remoterev, loading remote anyway!\n");
        $opts{"only-installed"} = 0;
      }
    }
  } elsif (!$what || $what =~ m/^(collections|schemes)$/i) {
    $fmt = "list";
  } else {
    $fmt = "detail";
  }
  my $tlm;
  if ($opts{"only-installed"}) {
    $tlm = $localtlpdb;
  } else {
    init_tlmedia_or_die(1);
    $tlm = $remotetlpdb;
  }

  my @whattolist;
  $what = ($what || "-all");
  if ($what =~ m/^collections$/i) {
    @whattolist = $tlm->collections;
  } elsif ($what =~ m/^schemes$/i) {
    @whattolist = $tlm->schemes;
  } elsif ($what =~ m/^-all$/i) {
    if ($tlm->is_virtual) {
      @whattolist = $tlm->list_packages("-all");
    } else {
      @whattolist = $tlm->list_packages;
    }
    if (!$opts{'only-remote'}) {
      TeXLive::TLUtils::push_uniq(\@whattolist, $localtlpdb->list_packages);
    }
  } else {
    @whattolist = ($what, @todo);
  }
  my @adds;
  if ($opts{'data'}) {
    @adds = @datafields;
  }
  my ($startsec, $startmsec);
  if ($opts{'debug-json-timing'}) {
    require Time::HiRes;
    ($startsec, $startmsec) = Time::HiRes::gettimeofday();
  }
  print "[" if ($fmt eq "json");
  my $first = 1;
  foreach my $ppp (@whattolist) {
    next if ($ppp =~ m/^00texlive\./);
    print "," if ($fmt eq "json" && !$first);
    $first = 0;
    $ret |= show_one_package($ppp, $fmt, @adds);
  }
  print "]\n" if ($fmt eq "json");
  if ($opts{'debug-json-timing'}) {
    my ($endsec, $endmsec) = Time::HiRes::gettimeofday();
    if ($endmsec < $startmsec) {
      $endsec -= 1;
      $endmsec += 1000000;
    }
    print STDERR "JSON (", $TeXLive::TLUtils::jsonmode, ") generation took ", $endsec - $startsec, ".", substr($endmsec - $startmsec,0,2), " sec\n";
  }
  return ($ret);
}


sub action_search {
  my ($r) = @ARGV;
  my $tlpdb;
  my $search_type_nr = 0;
  $search_type_nr++ if $opts{"file"};
  $search_type_nr++ if $opts{"all"};
  if ($search_type_nr > 1) {
    tlwarn("$prg: please specify only one thing to search for\n");
    return ($F_ERROR);
  }
  if (!defined($r) || !$r) {
    tlwarn("$prg: nothing to search for.\n");
    return ($F_ERROR);
  }

  init_local_db();
  if ($opts{"global"}) {
    init_tlmedia_or_die();
    $tlpdb = $remotetlpdb;
  } else {
    $tlpdb = $localtlpdb;
  }

  my ($foundfile, $founddesc) = search_tlpdb($tlpdb, $r, 
    $opts{'file'} || $opts{'all'}, 
    (!$opts{'file'} || $opts{'all'}), 
    $opts{'word'});
 
  print $founddesc;
  print $foundfile;

  return ($F_OK | $F_NOPOSTACTION);
}

sub search_tlpdb {
  my ($tlpdb, $what, $dofile, $dodesc, $inword) = @_;
  my $retfile = '';
  my $retdesc = '';
  foreach my $pkg ($tlpdb->list_packages) {
    my $tlp = $tlpdb->get_package($pkg);
    
    if ($dofile) {
      my @ret = search_pkg_files($tlp, $what);
      if (@ret) {
        $retfile .= "$pkg:\n";
        foreach (@ret) {
          $retfile .= "\t$_\n";
        }
      }
    }
    if ($dodesc) {
      next if ($pkg =~ m/\./);
      my $matched = search_pkg_desc($tlp, $what, $inword);
      $retdesc .= "$matched\n" if ($matched);
    }
  }
  return($retfile, $retdesc);
}

sub search_pkg_desc {
  my ($tlp, $what, $inword) = @_;
  my $pkg = $tlp->name;
  my $t = "$pkg\n";
  $t = $t . $tlp->shortdesc . "\n" if (defined($tlp->shortdesc));
  $t = $t . $tlp->longdesc . "\n" if (defined($tlp->longdesc));
  $t = $t . $tlp->cataloguedata->{'topics'} . "\n" if (defined($tlp->cataloguedata->{'topics'}));
  my $pat = $what;
  $pat = '\W' . $what . '\W' if ($inword);
  my $matched = "";
  if ($t =~ m/$pat/i) {
    my $shortdesc = $tlp->shortdesc || "";
    $matched .= "$pkg - $shortdesc";
  }
  return $matched;
}

sub search_pkg_files {
  my ($tlp, $what) = @_;
  my @files = $tlp->all_files;
  if ($tlp->relocated) {
    for (@files) { s:^$RelocPrefix/:$RelocTree/:; }
  }
  my @ret = grep(m;$what;, @files);
  return @ret;
}

sub get_available_backups {
  my $bd = shift;
  my $do_stat = shift;
  my %backups;
  opendir (DIR, $bd) || die "opendir($bd) failed: $!";
  my @dirents = readdir (DIR);
  closedir (DIR) || warn "closedir($bd) failed: $!";
  my $oldwsloppy = ${^WIN32_SLOPPY_STAT};
  ${^WIN32_SLOPPY_STAT} = 1;
  my $pkg;
  my $rev;
  my $ext;
  for my $dirent (@dirents) {
    $pkg = "";
    $rev = "";
    $ext = "";
    next if (-d $dirent);
    if ($dirent =~ m/^(.*)\.r([0-9]+)\.tar\.$CompressorExtRegexp$/) {
      $pkg = $1;
      $rev = $2;
      $ext = $3;
    } else {
      next;
    }
    if (!$do_stat) {
      $backups{$pkg}->{$rev} = 1;
      next;
    }
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks) = stat("$bd/$dirent");
    my $usedt = $ctime;
    if (!$usedt) {
      $usedt = $mtime;
    }
    if (!$usedt) {
      $backups{$pkg}->{$rev} = -1;
    } else {
      $backups{$pkg}->{$rev} = $usedt;
    }
  }
  ${^WIN32_SLOPPY_STAT} = $oldwsloppy;
  return %backups;
}

sub restore_one_package {
  my ($pkg, $rev, $bd) = @_;
  my $restore_file;
  for my $ext (map {$Compressors{$_}{'extension'}} 
                 sort {$Compressors{$a}{'priority'} <=> $Compressors{$a}{'priority'}} 
                   keys %Compressors) {
    if (-r "$bd/${pkg}.r${rev}.tar.$ext") {
      $restore_file = "$bd/${pkg}.r${rev}.tar.$ext";
      last;
    }
  }
  if (!$restore_file) {
    tlwarn("$prg: cannot find restore file $bd/${pkg}.r${rev}.tar.*, no action taken\n");
    return ($F_ERROR);
  }
  $localtlpdb->remove_package($pkg);
  TeXLive::TLPDB->_install_data($restore_file , 0, [], $localtlpdb, "-1", "-1");
  logpackage("restore: $pkg ($rev)");
  my $tlpobj = TeXLive::TLPOBJ->new;
  $tlpobj->from_file($localtlpdb->root . "/tlpkg/tlpobj/$pkg.tlpobj");
  $localtlpdb->add_tlpobj($tlpobj);
  TeXLive::TLUtils::announce_execute_actions("enable",
                                      $localtlpdb->get_package($pkg));
  check_announce_format_triggers($pkg);
  $localtlpdb->save;
  return ($F_OK);
}

sub setup_backup_directory {
  my $ret = $F_OK;
  my $autobackup = 0;
  if (!$opts{"backup"}) {
    $autobackup = $localtlpdb->option("autobackup");
    if ($autobackup) {
      if ($autobackup eq "-1") {
        debug ("Automatic backups activated, keeping all backups.\n");
        $opts{"backup"} = 1;
      } elsif ($autobackup eq "0") {
        debug ("Automatic backups disabled.\n");
      } elsif ($autobackup =~ m/^[0-9]+$/) {
        debug ("Automatic backups activated, keeping $autobackup backups.\n");
        $opts{"backup"} = 1;
      } else {
        tlwarn ("$prg: Option autobackup value can only be an integer >= -1.\n");
        tlwarn ("$prg: Disabling auto backups.\n");
        $localtlpdb->option("autobackup", 0);
        $autobackup = 0;
        $ret |= $F_WARNING;
      }
    }
  }

  if ($opts{"backup"}) {
    my ($a, $b) = check_backupdir_selection();
    if ($a & $F_ERROR) {
      tlwarn($b);
      return ($F_ERROR, $autobackup);
    }
  }

  $opts{"backup"} = 1 if $opts{"backupdir"};

  my $saving_verb = $opts{"dry-run"} || $opts{"list"} ? "would save" :"saving";
  info("$prg: $saving_verb backups to $opts{'backupdir'}\n")
    if $opts{"backup"} && !$::machinereadable;
  
  return ($ret, $autobackup);
}

sub check_backupdir_selection {
  my $warntext = "";
  if ($opts{"backupdir"}) {
    my $ob = abs_path($opts{"backupdir"});
    $ob && ($opts{"backupdir"} = $ob);
    if (! -d $opts{"backupdir"}) {
      $warntext .= "$prg: backupdir argument\n";
      $warntext .= "  $opts{'backupdir'}\n";
      $warntext .= "is not a directory.\n";
      return ($F_ERROR, $warntext);
    }
  } else {
    init_local_db(1);
    $opts{"backupdir"} = norm_tlpdb_path($localtlpdb->option("backupdir"));
    if (!$opts{"backupdir"}) {
      return (0, "$prg: cannot determine backupdir.\n");
    }
    my $ob = abs_path($opts{"backupdir"});
    $ob && ($opts{"backupdir"} = $ob);
    if (! -d $opts{"backupdir"}) {
      $warntext =  "$prg: backupdir as set in tlpdb\n";
      $warntext .= "  $opts{'backupdir'}\n";
      $warntext .= "is not a directory.\n";
      return ($F_ERROR, $warntext);
    }
  }
  return $F_OK;
}

sub action_restore {

  {
    my ($a, $b) = check_backupdir_selection();
    if ($a & $F_ERROR) {
      tlwarn($b);
      return ($F_ERROR);
    }
  }
  info("$prg restore: dry run, no changes will be made\n") if $opts{"dry-run"};

  my %backups = get_available_backups($opts{"backupdir"}, 1);
  my ($pkg, $rev) = @ARGV;
  if (defined($pkg) && $opts{"all"}) {
    tlwarn("$prg: Specify either --all or individual package(s) ($pkg)\n");
    tlwarn("$prg: to restore, not both.  Terminating.\n");
    return ($F_ERROR);
  }
  if ($opts{"all"}) {
    init_local_db(1);
    return ($F_ERROR) if !check_on_writable();
    if (!$opts{"force"}) {
      print "Do you really want to restore all packages to the latest revision found in\n\t$opts{'backupdir'}\n===> (y/N): ";
      my $yesno = <STDIN>;
      if ($yesno !~ m/^y(es)?$/i) {
        print "Ok, cancelling the restore!\n";
        return ($F_OK | $F_NOPOSTACTION);
      }
    }
    for my $p (sort keys %backups) {
      my @tmp = sort {$b <=> $a} (keys %{$backups{$p}});
      my $rev = $tmp[0];
      print "Restoring $p, $rev from $opts{'backupdir'}/${p}.r${rev}.tar.*\n";
      if (!$opts{"dry-run"}) {
        restore_one_package($p, $rev, $opts{"backupdir"});
      }
    }
    return ($F_OK);
  }
  sub report_backup_revdate {
    my $p = shift;
    my $mode = shift;
    my %revs = @_;
    my @rs = sort {$b <=> $a} (keys %revs);
    my @outarr;
    for my $rs (@rs) {
      my %jsonkeys;
      $jsonkeys{'name'} = $p;
      my $dstr;
      if ($revs{$rs} == -1) {
        $dstr = "unknown";
      } else {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
          localtime($revs{$rs});
        $dstr = sprintf "%04d-%02d-%02d %02d:%02d", 
          $year+1900, $mon+1, $mday, $hour, $min;
      }
      if ($mode eq "json") {
        $jsonkeys{'rev'} = "$rs";
        $jsonkeys{'date'} = $dstr;
        push @outarr, \%jsonkeys;
      } else {
        push @outarr, "$rs ($dstr)";
      }
    }
    if ($mode eq "json") {
      return @outarr;
    } else {
      return ( join(" ", @outarr));
    }
  }
  if (!defined($pkg)) {
    if (keys %backups) {
      if ($opts{'json'}) {
        my @bla = map { report_backup_revdate($_, "json", %{$backups{$_}}) } keys %backups;
        my $str = TeXLive::TLUtils::encode_json(\@bla);
        print "$str\n";
      } else {
        print "Available backups:\n";
        foreach my $p (sort keys %backups) {
          print "$p: ";
          print(report_backup_revdate($p, "text", %{$backups{$p}}));
          print "\n";
        }
      }
    } else {
      if ($opts{'json'}) {
        print "[]\n";
      } else {
        print "No backups available in $opts{'backupdir'}\n";
      }
    }
    return ($F_OK | $F_NOPOSTACTION);
  }
  if (!defined($rev)) {
    if ($opts{'json'}) {
      my @bla = report_backup_revdate($pkg, "json", %{$backups{$pkg}});
      my $str = TeXLive::TLUtils::encode_json(\@bla);
      print "$str\n";
    } else {
      print "Available backups for $pkg: ";
      print(report_backup_revdate($pkg, "text", %{$backups{$pkg}}));
      print "\n";
    }
    return ($F_OK | $F_NOPOSTACTION);
  }
  if (defined($backups{$pkg}->{$rev})) {
    return if !check_on_writable();
    if (!$opts{"force"}) {
      print "Do you really want to restore $pkg to revision $rev (y/N): ";
      my $yesno = <STDIN>;
      if ($yesno !~ m/^y(es)?$/i) {
        print "Ok, cancelling the restore!\n";
        return ($F_OK | $F_NOPOSTACTION);
      }
    }
    print "Restoring $pkg, $rev from $opts{'backupdir'}/${pkg}.r${rev}.tar.xz\n";
    if (!$opts{"dry-run"}) {
      init_local_db(1);
      restore_one_package($pkg, $rev, $opts{"backupdir"});
    }
    return ($F_OK);
  } else {
    print "revision $rev for $pkg is not present in $opts{'backupdir'}\n";
    return ($F_ERROR);
  }
}

sub action_backup {
  init_local_db(1);
  my $clean_mode = 0;
  $clean_mode = 1 if defined($opts{"clean"});
  if ($clean_mode) {
    if ($opts{"clean"} == -99) {
      my $tlpdb_option = $localtlpdb->option("autobackup");
      if (!defined($tlpdb_option)) {
        tlwarn ("$prg: --clean given without an argument, but no default clean\n");
        tlwarn ("$prg: mode specified in the tlpdb.\n");
        return ($F_ERROR);
      }
      $opts{"clean"} = $tlpdb_option;
    }
    if ($opts{"clean"} =~ m/^(-1|[0-9]+)$/) {
      $opts{"clean"} = $opts{"clean"} + 0;
    } else {
      tlwarn ("$prg: clean mode as specified on the command line or as given by default\n");
      tlwarn ("$prg: must be an integer larger or equal than -1, terminating.\n");
      return($F_ERROR);
    }
  }
  {
    my ($a, $b) = check_backupdir_selection();
    if ($a & $F_ERROR) {
      tlwarn($b);
      return($F_ERROR);
    }
  }

  if ($opts{"all"} && $clean_mode) {
    my %backups = get_available_backups($opts{"backupdir"}, 0);
    init_local_db(1);
    for my $p (sort keys %backups) {
      clear_old_backups ($p, $opts{"backupdir"}, $opts{"clean"}, $opts{"dry-run"}, 1);
    }
    info("no action taken due to --dry-run\n") if $opts{"dry-run"};
    return ($F_OK | $F_NOPOSTACTION);
  }

  my @todo;
  if ($opts{"all"}) {
    @todo = $localtlpdb->list_packages;
  } else {
    @todo = @ARGV;
    @todo = $localtlpdb->expand_dependencies("-only-arch", $localtlpdb, @todo);
  }
  if (!@todo) {
    printf "tlmgr backup takes either a list of packages or --all\n";
    return ($F_ERROR);
  }
  foreach my $pkg (@todo) {
    if ($clean_mode) {
      clear_old_backups ($pkg, $opts{"backupdir"}, $opts{"clean"}, $opts{"dry-run"}, 1);
    } else {
      my $compressorextension = $Compressors{$::progs{'compressor'}}{'extension'};
      my $tlp = $localtlpdb->get_package($pkg);
      my $saving_verb = $opts{"dry-run"} ? "would save" : "saving";
      info("$saving_verb current status of $pkg to $opts{'backupdir'}/${pkg}.r"
           . $tlp->revision . ".tar.$compressorextension\n");
      if (!$opts{"dry-run"}) {
        $tlp->make_container($::progs{'compressor'}, $localtlpdb->root,
                             destdir => $opts{"backupdir"},
                             user => 1);
      }
    }
  }
  info("no action taken due to --dry-run\n") if $opts{"dry-run"};
  return ($F_OK);
}

sub write_w32_updater {
  my ($restart_tlmgr, $ref_files_to_be_removed, @w32_updated) = @_;
  my @infra_files_to_be_removed = @$ref_files_to_be_removed;
  my $media = $remotetlpdb->media;
  my $container_src_split = $remotetlpdb->config_src_container;
  my $container_doc_split = $remotetlpdb->config_doc_container;
  my $opt_src = $localtlpdb->option("install_srcfiles");
  my $opt_doc = $localtlpdb->option("install_docfiles");
  my $root = $localtlpdb->root;
  my $temp = "$root/temp";
  TeXLive::TLUtils::mkdirhier($temp);
  tlwarn("$prg: warning: backup option not implemented for infrastructure "
         . " update on Windows; continuing anyway.\n") 
    if ($opts{"backup"});
  if ($media eq 'local_uncompressed') {
    tlwarn("$prg: Creating updater from local_uncompressed currently not implemented!\n");
    tlwarn("$prg: But it should not be necessary!\n");
    return 1; # abort
  }
  my (@upd_tar, @upd_tlpobj, @upd_info, @rst_tar, @rst_tlpobj, @rst_info);
  foreach my $pkg (@w32_updated) {
    my $repo;
    my $mediatlp;
    $media = $remotetlpdb->media;
    if ($media eq "virtual") {
      my $maxtlpdb;
      (undef, undef, $mediatlp, $maxtlpdb) = 
        $remotetlpdb->virtual_candidate($pkg);
      $repo = $maxtlpdb->root . "/$Archive";
      $media = $maxtlpdb->media;
    } else {
      $mediatlp = $remotetlpdb->get_package($pkg);
      $repo = $remotetlpdb->root . "/$Archive";
    }
    my $localtlp = $localtlpdb->get_package($pkg);
    my $oldrev = $localtlp->revision;
    my $newrev = $mediatlp->revision;
    my $opt_real_doc = ($mediatlp->category =~ m/documentation/i) ? 1 : $opt_doc;
    my @pkg_parts = ($pkg);
    push(@pkg_parts, "$pkg.source") if ($container_src_split && $opt_src && $mediatlp->srcfiles);
    push(@pkg_parts, "$pkg.doc") if ($container_doc_split && $opt_real_doc && $mediatlp->docfiles);
    foreach my $pkg_part (@pkg_parts) {
      push (@upd_tar, "$pkg_part.tar");
      push (@upd_tlpobj, "tlpkg\\tlpobj\\$pkg_part.tlpobj");
    }
    push (@upd_info, "$pkg ^($oldrev -^> $newrev^)");
    push (@rst_tar, "__BACKUP_$pkg.r$oldrev.tar");
    push (@rst_tlpobj, "tlpkg\\tlpobj\\$pkg.tlpobj");
    push (@rst_info, "$pkg ^($oldrev^)");
    next if ($opts{"dry-run"});
    my ($size, undef, $fullname) = $localtlp->make_container("tar", $root,
                                     destdir => $temp,
                                     containername => "__BACKUP_$pkg",
                                     user => 1);
    if ($size <= 0) {
      tlwarn("$prg: creation of backup container failed for: $pkg\n");
      return 1; # backup failed? abort
    }
    my $decompressor = $::progs{$DefaultCompressorFormat};
    my $compressorextension = $Compressors{$DefaultCompressorFormat}{'extension'};
    my @decompressorArgs = @{$Compressors{$DefaultCompressorFormat}{'decompress_args'}};
    foreach my $pkg_part (@pkg_parts) {
      my $dlcontainer = "$temp/$pkg_part.tar.$compressorextension";
      if ($media eq 'local_compressed') {
        copy("$repo/$pkg_part.tar.$compressorextension", "$temp");
      } else { # net
        TeXLive::TLUtils::download_file("$repo/$pkg_part.tar.$compressorextension", $dlcontainer);
      }
      if (!-r $dlcontainer) {
        tlwarn("$prg: couldn't get $pkg_part.tar.$compressorextension, that is bad\n");
        return 1; # abort
      }
      my $sysret = system("$decompressor @decompressorArgs < \"$dlcontainer\" > \"$temp/$pkg_part.tar\"");
      if ($sysret) {
        tlwarn("$prg: couldn't unpack $pkg_part.tar.$compressorextension\n");
        return 1; # unpack failed? abort
      }
      unlink($dlcontainer); # we don't need that archive anymore
    }
  }
  
  my $respawn_cmd = "cmd.exe /e:on/v:off/d/c";
  $respawn_cmd = "start /wait $respawn_cmd" if ($::gui_mode);
  my $gui_pause = ($::gui_mode ? "pause" : "rem");
  my $upd_log = ($::opt_verbosity ? "STDERR" : '"%~dp0update-self.log"');
  my $std_handles_redir = ($::opt_verbosity ? "1^>^&2" : "2^>$upd_log 1^>^&2");
  my $pkg_log = ($packagelogfile ? "\"$packagelogfile\"" : "nul");
  my $post_update_msg = "You may now close this window.";
  my $rerun_tlmgr = "rem";
  if ($restart_tlmgr) {
    $post_update_msg = "About to restart tlmgr to complete update ...";
    $rerun_tlmgr = join (" ", map ("\"$_\"", @::SAVEDARGV) );
    $rerun_tlmgr = "if not errorlevel 1 tlmgr.bat $rerun_tlmgr";
  }
  my $batch_script = <<"EOF";
:: This file is part of an automated update process of
:: infrastructure files and should not be run standalone. 
:: For more details about the update process see comments 
:: in tlmgr.pl (subroutine write_w32_updater).

  if [%1]==[:doit] goto :doit
  if not exist "%~dp0tar.exe" goto :notar
  $respawn_cmd call "%~f0" :doit $std_handles_redir
  $rerun_tlmgr
  goto :eof

:notar
  echo %~nx0: cannot run without "%~dp0tar.exe"
  findstr "^::" <"%~f0"
  exit /b 1

:doit
  set prompt=TL\$G
  title TeX Live Manager $TeXLive::TLConfig::ReleaseYear Update
  set PERL5LIB=$root/tlpkg/tlperl/lib
  >con echo DO NOT CLOSE THIS WINDOW!
  >con echo TeX Live infrastructure update in progress ...
  >con echo Detailed command logging to $upd_log
  pushd "%~dp0.."
  if not errorlevel 1 goto :update
  >con echo Could not change working directory to "%~dp0.."
  >con echo Aborting infrastructure update, no changes have been made.
  >con $gui_pause 
  popd
  exit /b 1
    
:update
  for %%I in (@upd_tar) do (
    temp\\tar.exe -xmf temp\\%%I
    if errorlevel 1 goto :rollback
  )
  tlpkg\\tlperl\\bin\\perl.exe .\\texmf-dist\\scripts\\texlive\\tlmgr.pl _include_tlpobj @upd_tlpobj
  if errorlevel 1 goto :rollback
  >>$pkg_log echo [%date% %time%] self update: @upd_info
  >con echo self update: @upd_info
  del "%~dp0*.tar" "%~dp0tar.exe" 
  >con echo Infrastructure update finished successfully.
  >con echo $post_update_msg
  >con $gui_pause 
  popd
  exit /b 0

:rollback
  >>$pkg_log echo [%date% %time%] failed self update: @upd_info
  >con echo failed self update: @upd_info
  >con echo Rolling back to previous version ...
  for %%I in (@rst_tar) do (
    temp\\tar.exe -xmf temp\\%%I
    if errorlevel 1 goto :panic
  )
  tlpkg\\tlperl\\bin\\perl.exe .\\texmf-dist\\scripts\\texlive\\tlmgr.pl _include_tlpobj @rst_tlpobj
  if errorlevel 1 goto :panic
  >>$pkg_log echo [%date% %time%] self restore: @rst_info
  >con echo self restore: @rst_info
  >con echo Infrastructure update failed. Previous version has been restored.
  >con $gui_pause 
  popd
  exit /b 1

:panic
  >>$pkg_log echo [%date% %time%] failed self restore: @rst_info
  >con echo failed self restore: @rst_info
  >con echo FATAL ERROR:
  >con echo Infrastructure update failed and backup recovery failed too.
  >con echo To repair your TeX Live installation download and run:
  >con echo $TeXLive::TLConfig::TeXLiveURL/update-tlmgr-latest.exe
  >con $gui_pause 
  popd
  exit /b 666
EOF

  ddebug("\n:: UPDATER BATCH SCRIPT ::\n$batch_script\n:: END OF FILE ::\n");
  if ($opts{"dry-run"}) {
    my $upd_info = "self update: @upd_info";
    $upd_info =~ s/\^//g;
    info($upd_info);
  } else {
    copy("$root/tlpkg/installer/tar.exe", "$temp");
    if (system("\"$temp/tar.exe\" --version >nul")) {
      tlwarn("$prg: could not copy tar.exe, that is bad.\n");
      return 1; # abort
    }
    open UPDATER, ">$temp/updater-w32" or die "Cannot create updater script: $!";
    print UPDATER $batch_script;
    close UPDATER;
  }
  return 0;
}



sub auto_remove_install_force_packages {
  my @todo = @_;
  my %removals_full;
  my %forcermpkgs_full;
  my %newpkgs_full;
  my %new_pkgs_due_forcerm_coll;
  my @all_schmscolls = ();
  for my $p ($localtlpdb->schemes) {
    push (@all_schmscolls, $p) if defined($remotetlpdb->get_package($p));
  }
  for my $p ($localtlpdb->collections) {
    push (@all_schmscolls, $p) if defined($remotetlpdb->get_package($p));
  }
  my @localexpansion_full =
    $localtlpdb->expand_dependencies($localtlpdb, @all_schmscolls);
  my @remoteexpansion_full =
    $remotetlpdb->expand_dependencies($localtlpdb, @all_schmscolls);

  for my $p (@remoteexpansion_full) {
    $newpkgs_full{$p} = 1;
  }
  for my $p (@localexpansion_full) {
    delete($newpkgs_full{$p});
    $removals_full{$p} = 1;
  }
  for my $p (@remoteexpansion_full) {
    delete($removals_full{$p});
  }
  for my $p (@localexpansion_full) {
    next if $newpkgs_full{$p};
    next if $removals_full{$p};
    my $remotetlp = $remotetlpdb->get_package($p);
    if (!defined($remotetlp)) {
      tlwarn("$prg:auto_remove_install_force_packages: strange, package "
             . "mentioned but not found anywhere: $p\n");
      next;
    }
    next if ($remotetlp->category ne "Collection");
    my $tlp = $localtlpdb->get_package($p);
    if (!defined($tlp)) {
      if ($opts{"reinstall-forcibly-removed"}) {
        $newpkgs_full{$p} = 1;
      } else {
        $forcermpkgs_full{$p} = 1;
      }
    }
  }
  my @pkgs_from_forcerm_colls = 
    $remotetlpdb->expand_dependencies($localtlpdb, keys %forcermpkgs_full);
  for my $p (keys %newpkgs_full) {
    if (member($p, @pkgs_from_forcerm_colls)) {
      delete $newpkgs_full{$p};
      $new_pkgs_due_forcerm_coll{$p} = 1;
    }
  }
  for my $p (@localexpansion_full) {
    next if $newpkgs_full{$p};
    next if $removals_full{$p};
    my $tlp = $localtlpdb->get_package($p);
    if (!defined($tlp)) {
      if ($opts{"reinstall-forcibly-removed"}) {
        $newpkgs_full{$p} = 1;
      } else {
        $forcermpkgs_full{$p} = 1;
      }
    }
  }
  for my $p (keys %removals_full) {
    if ($p =~ m/^([^.]*)\./) {
      my $mpkg = $1;
      if (!defined($removals_full{$mpkg})) {
        delete($removals_full{$p});
      }
    }
  }
  my %removals;
  my %forcermpkgs;
  my %newpkgs;
  for my $p (@todo) {
    $removals{$p} = 1 if defined($removals_full{$p});
    $forcermpkgs{$p} = 1 if defined($forcermpkgs_full{$p});
    $newpkgs{$p} = 1 if defined($newpkgs_full{$p});
  }
  debug ("$prg: new pkgs: " . join("\n\t",keys %newpkgs) . "\n");
  debug ("$prg: deleted : " . join("\n\t",keys %removals) . "\n");
  debug ("$prg: forced  : " . join("\n\t",keys %forcermpkgs) . "\n");

  return (\%removals, \%newpkgs, \%forcermpkgs, \%new_pkgs_due_forcerm_coll);
}

sub machine_line {
  my ($flag1) = @_;
  my $ret = 0;
  if ($flag1 eq "-ret") {
    $ret = 1;
    shift;
  }
  my ($pkg, $flag, $lrev, $rrev, $size, $runtime, $esttot, $tag, $lcv, $rcv) = @_;
  $lrev ||= "-";
  $rrev ||= "-";
  $flag ||= "?";
  $size ||= "-";
  $runtime ||= "-";
  $esttot ||= "-";
  $tag ||= "-";
  $lcv ||= "-";
  $rcv ||= "-";
  my $str = join("\t", $pkg, $flag, $lrev, $rrev, $size, $runtime, $esttot, $tag, $lcv, $rcv);
  $str .= "\n";
  return($str) if $ret;
  print $str;
}

sub upd_info {
  my ($pkg, $kb, $lrev, $mrev, $txt) = @_;
  my $flen = 25;
  my $kbstr = ($kb >= 0 ? " [${kb}k]" : "");
  my $kbstrlen = length($kbstr);
  my $pkglen = length($pkg);
  my $is = sprintf("%-9s ", "$txt:");
  if ($pkglen + $kbstrlen > $flen) {
    $is .= "$pkg$kbstr: ";
  } else {
    $is .= sprintf ('%*2$s', $pkg, -($flen-$kbstrlen));
    $is .= "$kbstr: ";
  }
  $is .= sprintf("local: %8s, source: %8s",
                         $lrev,       $mrev);
  info("$is\n");
}

sub action_update {
  init_local_db(1);
  $opts{"no-depends"} = 1 if $opts{"no-depends-at-all"};

  if (!($opts{"list"} || @ARGV || $opts{"all"} || $opts{"self"})) {
    if ($opts{"dry-run"}) {
      $opts{"list"} = 1; # update -n same as update -n --list
    } else {
      tlwarn("$prg update: specify --list, --all, --self, or a list of package names.\n");
      return ($F_ERROR);
    }
  }

  init_tlmedia_or_die();
  info("$prg update: dry run, no changes will be made\n") if $opts{"dry-run"};

  my @excluded_pkgs = ();
  if ($opts{"exclude"}) {
    @excluded_pkgs = @{$opts{"exclude"}};
  } elsif ($config{'update-exclude'}) {
    @excluded_pkgs = @{$config{'update-exclude'}};
  }

  if (!$opts{"list"}) {
    return ($F_ERROR) if !check_on_writable();
  }

  my @critical;
  if (!$opts{"usermode"}) {
    @critical = check_for_critical_updates($localtlpdb, $remotetlpdb);
  }
  my $dry_run_cont = $opts{"dry-run"} && ($opts{"dry-run"} < 0);
  if ( !$dry_run_cont  && !$opts{"self"} && @critical) {
    critical_updates_warning() if (!$::machinereadable);
    if ($opts{"force"}) {
      tlwarn("$prg: Continuing due to --force.\n");
    } elsif ($opts{"list"}) {
    } else {
      return($F_ERROR);
    }
  }

  my ($ret, $autobackup) = setup_backup_directory();
  return ($ret) if ($ret != $F_OK);

  my $root = $localtlpdb->root;
  my $temp = TeXLive::TLUtils::tl_tmpdir();

  for my $f (<$temp/__BACKUP_*>) {
    unlink($f) unless $opts{"dry-run"};
  }


  my @todo;
  if ($opts{"list"}) {
    if ($opts{"all"}) {
      @todo = $localtlpdb->list_packages;
    } elsif ($opts{"self"}) {
      @todo = @critical;
    } else {
      if (@ARGV) {
        @todo = @ARGV;
      } else {
        @todo = $localtlpdb->list_packages;
      }
    }
  } elsif ($opts{"self"} && @critical) {
    @todo = @critical;
  } elsif ($opts{"all"}) {
    @todo = $localtlpdb->list_packages;
  } else {
    @todo = @ARGV;
  }
  if ($opts{"self"} && !@critical) {
    info("$prg: no self-updates for tlmgr available\n");
  }
  if (!@todo && !$opts{"self"}) {
    tlwarn("$prg update: please specify a list of packages, --all, or --self.\n");
    return ($F_ERROR);
  }

  if (!($opts{"self"} && @critical) || ($opts{"self"} && $opts{"list"})) {
    @todo = $remotetlpdb->expand_dependencies("-only-arch", $localtlpdb, @todo)
      unless $opts{"no-depends-at-all"};
    @todo = $remotetlpdb->expand_dependencies("-no-collections",$localtlpdb,@todo)
      unless $opts{"no-depends"};
    @todo = grep (!m/$CriticalPackagesRegexp/, @todo)
      unless $opts{"list"};
  }
    
  my ($remref, $newref, $forref, $new_due_to_forcerm_coll_ref) = 
    auto_remove_install_force_packages(@todo);
  my %removals = %$remref;
  my %forcermpkgs = %$forref;
  my %newpkgs = %$newref;
  my %new_due_to_forcerm_coll = %$new_due_to_forcerm_coll_ref;

  my @option_conflict_lines = ();
  my $in_conflict = 0;
  if (!$opts{"no-auto-remove"} && $config{"auto-remove"}) {
    for my $pkg (keys %removals) {
      for my $ep (@excluded_pkgs) {
        if ($pkg eq $ep || $pkg =~ m/^$ep\./) {
          push @option_conflict_lines, "$pkg: excluded but scheduled for auto-removal\n";
          $in_conflict = 1;
          last; # of the --exclude for loop
        }
      }
    }
  }
  if (!$opts{"no-auto-install"}) {
    for my $pkg (keys %newpkgs) {
      for my $ep (@excluded_pkgs) {
        if ($pkg eq $ep || $pkg =~ m/^$ep\./) {
          push @option_conflict_lines, "$pkg: excluded but scheduled for auto-install\n";
          $in_conflict = 1;
          last; # of the --exclude for loop
        }
      }
    }
  }
  if ($opts{"reinstall-forcibly-removed"}) {
    for my $pkg (keys %forcermpkgs) {
      for my $ep (@excluded_pkgs) {
        if ($pkg eq $ep || $pkg =~ m/^$ep\./) {
          push @option_conflict_lines, "$pkg: excluded but scheduled for reinstall\n";
          $in_conflict = 1;
          last; # of the --exclude for loop
        }
      }
    }
  }
  if ($in_conflict) {
    tlwarn("$prg: Conflicts have been found:\n");
    for (@option_conflict_lines) { tlwarn("  $_"); }
    tlwarn("$prg: Please resolve these conflicts!\n");
    return ($F_ERROR);
  }
      
  my %updated;
  my @new;
  my @addlines;

  TODO: foreach my $pkg (sort @todo) {
    next if ($pkg =~ m/^00texlive/);
    for my $ep (@excluded_pkgs) {
      if ($pkg eq $ep || $pkg =~ m/^$ep\./) {
        info("$prg: skipping excluded package: $pkg\n");
        next TODO;
      }
    }
    my $tlp = $localtlpdb->get_package($pkg);
    if (!defined($tlp)) {
      (my $pkg_noarch = $pkg) =~ s/\.[^.]*$//;
      my $forcerm_coll = $forcermpkgs{$pkg} || $forcermpkgs{$pkg_noarch};

      my $newpkg_coll = $newpkgs{$pkg} || $newpkgs{$pkg_noarch};
      if ($forcerm_coll) {
        if ($::machinereadable) {
          push @addlines,
            machine_line("-ret", $pkg, $FLAG_FORCIBLE_REMOVED);
        } else {
          info("$prg: skipping forcibly removed package: $pkg\n");
        }
        next;
      } elsif ($newpkg_coll) {
      } elsif (defined($removals{$pkg})) {
        next;
      } elsif (defined($new_due_to_forcerm_coll{$pkg})) {
        debug("$prg: $pkg seems to be contained in a forcibly removed" .
          " collection, not auto-installing it!\n");
        next;
      } else {
        tlwarn("\n$prg: $pkg mentioned, but neither new nor forcibly removed");
        tlwarn("\n$prg: perhaps try tlmgr search or tlmgr info.\n");
        next;
      }
      my $mediatlp = $remotetlpdb->get_package($pkg);
      if (!defined($mediatlp)) {
        tlwarn("\n$prg: Should not happen: $pkg not found in $location\n");
        $ret |= $F_WARNING;
        next;
      }
      my $mediarev = $mediatlp->revision;
      push @new, $pkg;
      next;
    }
    my $rev = $tlp->revision;
    my $lctanvers = $tlp->cataloguedata->{'version'};
    my $mediatlp;
    my $maxtag;
    if ($remotetlpdb->is_virtual) {
      ($maxtag, undef, $mediatlp, undef) =
        $remotetlpdb->virtual_candidate($pkg);
    } else {
      $mediatlp = $remotetlpdb->get_package($pkg);
    }
    if (!defined($mediatlp)) {
      ddebug("$pkg cannot be found in $location\n");
      next;
    }
    my $rctanvers = $mediatlp->cataloguedata->{'version'};
    my $mediarev = $mediatlp->revision;
    my $mediarevstr = $mediarev;
    my @addargs = ();
    if ($remotetlpdb->is_virtual) {
      push @addargs, $maxtag;
      $mediarevstr .= "\@$maxtag";
    } else {
      push @addargs, undef;
    }
    push @addargs, $lctanvers, $rctanvers;
    if ($rev < $mediarev) {
      $updated{$pkg} = 0; # will be changed to one on successful update
    } elsif ($rev > $mediarev) {
      if ($::machinereadable) {
        push @addlines,
          machine_line("-ret", $pkg, $FLAG_REVERSED_UPDATE, $rev, $mediarev, "-", "-", "-", @addargs);
      } else {
        if ($opts{"list"}) {
          upd_info($pkg, -1, $rev, $mediarevstr, "keep");
        }
      }
    }
  }
  my @updated = sort keys %updated;
  for my $i (sort @new) {
    debug("$i new package\n");
  }
  for my $i (@updated) {
    debug("$i upd package\n");
  }

  my $totalnr = $#updated + 1;
  my @alltodo = @updated;
  my $nrupdated = 0;
  my $currnr = 1;

  if (!$opts{"no-auto-remove"} && $config{"auto-remove"}) {
    my @foo = keys %removals;
    $totalnr += $#foo + 1;
  }
  if (!$opts{"no-auto-install"}) {
    $totalnr += $#new + 1;
    push @alltodo, @new;
  }

  my %sizes;
  if (@alltodo) {
    %sizes = %{$remotetlpdb->sizes_of_packages(
      $localtlpdb->option("install_srcfiles"),
      $localtlpdb->option("install_docfiles"), undef, @alltodo)};
  } else {
    $sizes{'__TOTAL__'} = 0;
  }

  print "total-bytes\t$sizes{'__TOTAL__'}\n" if $::machinereadable;
  print "end-of-header\n" if $::machinereadable;

  for (@addlines) { print; }

  my %do_warn_on_move;
  {
    my @removals = keys %removals;
    my %old_files_to_pkgs;
    my %new_files_to_pkgs;
    for my $p (@updated, @removals) {
      my $pkg = $localtlpdb->get_package($p);
      tlwarn("$prg: Should not happen: $p not found in local tlpdb\n") if (!$pkg);
      next;
      for my $f ($pkg->all_files) {
        push @{$old_files_to_pkgs{$f}}, $p;
      }
    }
    for my $p (@updated, @new) {
      my $pkg = $remotetlpdb->get_package($p);
      tlwarn("$prg: Should not happen: $p not found in $location\n") if (!$pkg);
      next;
      for my $f ($pkg->all_files) {
        if ($pkg->relocated) {
          $f =~ s:^$RelocPrefix/:$RelocTree/:;
        }
        push @{$new_files_to_pkgs{$f}}, $p;
      }
    }
    for my $f (keys %old_files_to_pkgs) {
      my @a = @{$old_files_to_pkgs{$f}};
      $do_warn_on_move{$f} = 1 if ($#a > 0)
    }
    for my $f (keys %new_files_to_pkgs) {
      my @a = @{$new_files_to_pkgs{$f}};
      $do_warn_on_move{$f} = 1 if ($#a > 0)
    }
  }

  my $totalnrdigits = length("$totalnr");


  for my $p (keys %removals) {
    if ($opts{"no-auto-remove"} || !$config{"auto-remove"}) {
      info("not removing $p due to -no-auto-remove or config file option (removed on server)\n");
    } else {
      &ddebug("removing package $p\n");
      my $pkg = $localtlpdb->get_package($p);
      if (! $pkg) {
        &ddebug(" get_package($p) failed, ignoring");
        next;
      }
      my $rev = $pkg->revision;
      my $lctanvers = $pkg->cataloguedata->{'version'};
      if ($opts{"list"}) {
        if ($::machinereadable) {
          machine_line($p, $FLAG_REMOVE, $rev, "-", "-", "-", "-", "-", $lctanvers);
        } else {
          upd_info($p, -1, $rev, "<absent>", "autorm");
        }
        $currnr++;
      } else {
        if ($::machinereadable) {
          machine_line($p, $FLAG_REMOVE, $rev, "-", "-", "-", "-", "-", $lctanvers);
        } else {
          info("[" . sprintf ('%*2$s', $currnr, $totalnrdigits) .
            "/$totalnr] auto-remove: $p ... ");
        }
        if (!$opts{"dry-run"}) {
          if ($pkg->relocated) {
            debug("$prg: warn, relocated bit set for $p, but that is wrong!\n");
            $pkg->relocated(0);
          }
          backup_and_remove_package($p, $autobackup);
          logpackage("remove: $p");
        }
        info("done\n") unless $::machinereadable;
        $currnr++;
      }
    }
  }


  my $starttime = time();
  my $donesize = 0;
  my $totalsize = $sizes{'__TOTAL__'};


  my @inst_packs;
  my @inst_colls;
  my @inst_schemes;
  for my $pkg (@updated) {
    if ($pkg =~ m/^scheme-/) {
      push @inst_schemes, $pkg;
    } elsif ($pkg =~ m/^collection-/) {
      push @inst_colls, $pkg;
    } else {
      push @inst_packs, $pkg;
    }
  }
  @inst_packs = sort packagecmp @inst_packs;

  my @new_packs;
  my @new_colls;
  my @new_schemes;
  for my $pkg (sort @new) {
    if ($pkg =~ m/^scheme-/) {
      push @new_schemes, $pkg;
    } elsif ($pkg =~ m/^collection-/) {
      push @new_colls, $pkg;
    } else {
      push @new_packs, $pkg;
    }
  }
  @new_packs = sort packagecmp @new_packs;
  my %is_new;
  for my $pkg (@new_packs, @new_colls, @new_schemes) {
    $is_new{$pkg} = 1;
  }
  
  foreach my $pkg (@inst_packs, @new_packs, @inst_colls, @new_colls, @inst_schemes, @new_schemes) {
    
    if (!$is_new{$pkg}) {
      next if ($pkg =~ m/^00texlive/);
      my $tlp = $localtlpdb->get_package($pkg);
      if (!defined($tlp)) {
        my %servers = repository_to_array($location);
        my $servers = join("\n ", values(%servers));
        tlwarn("$prg: inconsistency on (one of) the server(s): $servers\n");
        tlwarn("$prg: tlp for package $pkg cannot be found, please report.\n");
        $ret |= $F_WARNING;
        next;
      }
      my $unwind_package;
      my $remove_unwind_container = 0;
      my $rev = $tlp->revision;
      my $lctanvers = $tlp->cataloguedata->{'version'};
      my $mediatlp;
      my $maxtag;
      if ($remotetlpdb->is_virtual) {
        ($maxtag, undef, $mediatlp, undef) =
          $remotetlpdb->virtual_candidate($pkg);
      } else {
        $mediatlp = $remotetlpdb->get_package($pkg);
      }
      if (!defined($mediatlp)) {
        debug("$pkg cannot be found in $location\n");
        next;
      }
      my $rctanvers = $mediatlp->cataloguedata->{'version'};
      my $mediarev = $mediatlp->revision;
      my $mediarevstr = $mediarev;
      my @addargs = ();
      if ($remotetlpdb->is_virtual) {
        push @addargs, $maxtag;
        $mediarevstr .= "\@$maxtag";
      } else {
        push @addargs, undef;
      }
      push @addargs, $lctanvers, $rctanvers;
      $nrupdated++;
      if ($opts{"list"}) {
        if ($::machinereadable) {
          machine_line($pkg, $FLAG_UPDATE, $rev, $mediarev, $sizes{$pkg}, "-", "-", @addargs);
        } else {
          my $kb = int($sizes{$pkg} / 1024) + 1;
          upd_info($pkg, $kb, $rev, $mediarevstr, "update");
          if ($remotetlpdb->is_virtual) {
            my @cand = $remotetlpdb->candidates($pkg);
            shift @cand;  # remove the top element
            if (@cand) {
              print "\tother candidates: ";
              for my $a (@cand) {
                my ($t,$r) = split(/\//, $a, 2);
                print $r . '@' . $t . " ";
              }
              print "\n";
            }
          }
        }
        $updated{$pkg} = 1;
        next;
      } elsif (wndws() && ($pkg =~ m/$CriticalPackagesRegexp/)) {
        $updated{$pkg} = 1;
        next;
      }
      
      if ($tlp->relocated) {
        debug("$prg: warn, relocated bit set for $pkg, but that is wrong!\n");
        $tlp->relocated(0);
      }

      if ($opts{"backup"} && !$opts{"dry-run"}) {
        my $compressorextension = $Compressors{$::progs{'compressor'}}{'extension'};
        $tlp->make_container($::progs{'compressor'}, $root,
                             destdir => $opts{"backupdir"},
                             relative => $tlp->relocated,
                             user => 1);
        $unwind_package =
            "$opts{'backupdir'}/${pkg}.r" . $tlp->revision . ".tar.$compressorextension";
        
        if ($autobackup) {
          clear_old_backups($pkg, $opts{"backupdir"}, $autobackup);
        }
      }
      
      my ($estrem, $esttot);
      if (!$opts{"list"}) {
        ($estrem, $esttot) = TeXLive::TLUtils::time_estimate($totalsize,
                                                             $donesize, $starttime);
      }
      
      if ($::machinereadable) {
        machine_line($pkg, $FLAG_UPDATE, $rev, $mediarev, $sizes{$pkg}, $estrem, $esttot, @addargs);
      } else {
        my $kb = int ($sizes{$pkg} / 1024) + 1;
        info("[" . sprintf ('%*2$s', $currnr, $totalnrdigits) .
          "/$totalnr, $estrem/$esttot] update: $pkg [${kb}k] ($rev -> $mediarevstr)");
      }
      $donesize += $sizes{$pkg};
      $currnr++;
      
      if ($opts{"dry-run"}) {
        info("\n") unless $::machinereadable;
        $updated{$pkg} = 1;
        next;
      } else {
        info(" ... ") unless $::machinereadable;  # more to come
      }
      
      if (!$unwind_package) {
        my $tlp = $localtlpdb->get_package($pkg);
        my ($s, undef, $fullname) = $tlp->make_container("tar", $root,
                         destdir => $temp,
                         containername => "__BACKUP_${pkg}",
                         relative => $tlp->relocated,
                         user => 1);
        if ($s <= 0) {
          tlwarn("\n$prg: creation of backup container failed for: $pkg\n");
          tlwarn("$prg: continuing to update other packages, please retry...\n");
          $ret |= $F_WARNING;
          next;
        }
        $remove_unwind_container = 1;
        $unwind_package = "$fullname";
      }
      if ($pkg =~ m/$CriticalPackagesRegexp/) {
        debug("Not removing critical package $pkg\n");
      } else {
        if (! $localtlpdb->remove_package($pkg, 
                "remove-warn-files" => \%do_warn_on_move)) {
          info("aborted\n") unless $::machinereadable;
          next;
        }
      }
      if ($remotetlpdb->install_package($pkg, $localtlpdb)) {
        logpackage("update: $pkg ($rev -> $mediarevstr)");
        unlink($unwind_package) if $remove_unwind_container;
        $updated{$pkg} = 1;
        if ($pkg =~ m/^([^.]*)\./) {
          my $parent = $1;
          if (!TeXLive::TLUtils::member($parent, @inst_packs, @new_packs, @inst_colls, @new_colls, @inst_schemes, @new_schemes)) {
            my $parentobj = $localtlpdb->get_package($parent);
            if (!defined($parentobj)) {
              debug("$prg: .ARCH package without parent, not announcing postaction\n");
            } else {
              debug("$prg: announcing parent execute action for $pkg\n");
              TeXLive::TLUtils::announce_execute_actions("enable", $parentobj);
            }
          }
        }
      } else {
        logpackage("failed update: $pkg ($rev -> $mediarevstr)");
        tlwarn("$prg: Installation of new version of $pkg failed, trying to unwind.\n");
        if (wndws()) {
          my $newname = $unwind_package;
          $newname =~ s/__BACKUP/___BACKUP/;
          copy ("-f", $unwind_package, $newname);
          unlink($unwind_package) if $remove_unwind_container;
          $remove_unwind_container = 1;
          $unwind_package = $newname;
        }

        my ($instret, $msg) = TeXLive::TLUtils::unpack("$unwind_package",
          $localtlpdb->root, checksum => "-1", checksize => "-1");
        if ($instret) {
          my $tlpobj = TeXLive::TLPOBJ->new;
          $tlpobj->from_file($root . "/tlpkg/tlpobj/$pkg.tlpobj");
          $localtlpdb->add_tlpobj($tlpobj);
          $localtlpdb->save;
          logpackage("restore: $pkg ($rev)");
          $ret |= $F_WARNING;
          tlwarn("$prg: Restoring old package state succeeded.\n");
        } else {
          logpackage("failed restore: $pkg ($rev)");
          tlwarn("$prg: Restoring of old package did NOT succeed.\n");
          tlwarn("$prg: Error message from unpack: $msg\n");
          tlwarn("$prg: Most likely repair: run tlmgr install $pkg and hope.\n");
          $ret |= $F_WARNING;
        }
        unlink($unwind_package) if $remove_unwind_container;
      }
      info("done\n") unless $::machinereadable;
    } else { # $is_new{$pkg} is true!!!
      if ($opts{"no-auto-install"}) {
        info("not auto-installing $pkg due to -no-auto-install (new on server)\n")
            unless $::machinereadable;
      } else {
        my $mediatlp;
        my $maxtag;
        if ($remotetlpdb->is_virtual) {
          ($maxtag, undef, $mediatlp, undef) =
            $remotetlpdb->virtual_candidate($pkg);
        } else {
          $mediatlp = $remotetlpdb->get_package($pkg);
        }
        if (!defined($mediatlp)) {
          tlwarn("\n$prg: Should not happen: $pkg not found in $location\n");
          $ret |= $F_WARNING;
          next;
        }
        my $mediarev = $mediatlp->revision;
        my $mediarevstr = $mediarev;
        my @addargs;
        if ($remotetlpdb->is_virtual) {
          $mediarevstr .= "\@$maxtag";
          push @addargs, $maxtag;
        }
        my ($estrem, $esttot);
        if (!$opts{"list"}) {
          ($estrem, $esttot) = TeXLive::TLUtils::time_estimate($totalsize,
                                          $donesize, $starttime);
        }
        if ($::machinereadable) {
          my @maargs = ($pkg, $FLAG_AUTOINSTALL, "-", $mediatlp->revision, $sizes{$pkg});
          if (!$opts{"list"}) {
            push @maargs, $estrem, $esttot;
          } else {
            push @maargs, undef, undef;
          }
          machine_line(@maargs, @addargs);
        } else {
          my $kb = int($sizes{$pkg} / 1024) + 1;
          if ($opts{"list"}) {
            upd_info($pkg, $kb, "<absent>", $mediarevstr, "autoinst");
          } else {
            info("[" . sprintf ('%*2$s', $currnr, $totalnrdigits) .
              "/$totalnr, $estrem/$esttot] auto-install: $pkg ($mediarevstr) [${kb}k] ... ");
          }
        }
        $currnr++;
        $donesize += $sizes{$pkg};
        next if ($opts{"dry-run"} || $opts{"list"});
        if ($remotetlpdb->install_package($pkg, $localtlpdb)) {
          logpackage("auto-install new: $pkg ($mediarevstr)");
          $nrupdated++;
          info("done\n") unless $::machinereadable;
        } else {
          tlwarn("$prg: couldn't install new package $pkg\n");
        }
      }
    }
  }

  check_announce_format_triggers(@inst_packs, @new_packs)
    if (!$opts{"list"});

  print "end-of-updates\n" if $::machinereadable;

  my $infra_update_done = 1;
  my @infra_files_to_be_removed;
  if ($opts{"list"}) {
    $infra_update_done = 0;
  } else {
    for my $pkg (@critical) {
      next unless (defined($updated{$pkg}));
      $infra_update_done &&= $updated{$pkg};
      my $oldtlp;
      my $newtlp;
      if ($updated{$pkg}) {
        $oldtlp = $localtlpdb->get_package($pkg);
        $newtlp = $remotetlpdb->get_package($pkg);
      } else {
        $oldtlp = $remotetlpdb->get_package($pkg);
        $newtlp = $localtlpdb->get_package($pkg);
      }
      die ("That shouldn't happen: $pkg not found in tlpdb") if !defined($newtlp);
      die ("That shouldn't happen: $pkg not found in tlpdb") if !defined($oldtlp);
      my @old_infra_files = $oldtlp->all_files;
      my @new_infra_files = $newtlp->all_files;
      my %del_files;
      @del_files{@old_infra_files} = ();
      delete @del_files{@new_infra_files};
      for my $k (keys %del_files) {
        my @found_pkgs = $localtlpdb->find_file($k);
        if ($#found_pkgs >= 0) {
          my $bad_file = 1;
          if (wndws()) {
            if ($#found_pkgs == 0 && $found_pkgs[0] =~ m/^$pkg:/) {
              $bad_file = 0;
            }
          }
          if ($bad_file) {
            tlwarn("$prg: The file $k has disappeared from the critical" .
                   " package $pkg but is still present in @found_pkgs\n");
            $ret |= $F_WARNING;
          } else {
            push @infra_files_to_be_removed, $k;
          }
        } else {
          push @infra_files_to_be_removed, $k;
        }
      }
    }

    if (!wndws()) {
      for my $f (@infra_files_to_be_removed) {
        debug("removing disappearing file $f\n");
      }
    } 
  } # end of if ($opts{"list"}) ... else part

  my $other_updates_asked_for = 0;
  if ($opts{"all"}) {
    $other_updates_asked_for = 1;
  } else {
    foreach my $p (@ARGV) {
      if ($p !~ m/$CriticalPackagesRegexp/) {
        $other_updates_asked_for = 1;
        last;
      }
    }
  }

  my $restart_tlmgr = 0;
  if ($opts{"self"} && @critical && !$opts{'no-restart'} &&
      $infra_update_done && $other_updates_asked_for) {
    @::SAVEDARGV = grep (!m/^-?-self$/, @::SAVEDARGV);
    $restart_tlmgr = 1;
  }

  if (wndws() && $opts{'self'} && !$opts{"list"} && @critical) {
    info("$prg: Preparing TeX Live infrastructure update...\n");
    for my $f (@infra_files_to_be_removed) {
      debug("file scheduled for removal $f\n");
    }
    my $ret = write_w32_updater($restart_tlmgr, 
                                \@infra_files_to_be_removed, @critical);
    if ($ret) {
      tlwarn ("$prg: Aborting infrastructure update.\n");
      $ret |= $F_ERROR;
      $restart_tlmgr = 0 if ($opts{"dry-run"});
    }
  }

  if (!wndws() && $restart_tlmgr && !$opts{"dry-run"} && !$opts{"list"}) {
    info("$prg: Restarting to complete update ...\n");
    debug("restarting tlmgr @::SAVEDARGV\n");
    File::Temp::cleanup();
    exec("tlmgr", @::SAVEDARGV);
    warn("$prg: cannot restart tlmgr, please retry update\n");
    return($F_ERROR);
  }

  if ($opts{"dry-run"} && !$opts{"list"} && $restart_tlmgr) {
    $opts{"self"} = 0;
    $opts{"dry-run"} = -1;
    $localtlpdb = undef;
    $remotetlpdb = undef;
    info ("$prg --dry-run: would restart tlmgr to complete update ...\n");
    $ret |= action_update();
    return ($ret);
  }
  
  if (!(@new || @updated) && ( !$opts{"self"} || @todo )) {
    if (!$::machinereadable) {
      info("$prg: no updates available\n");
      if ($remotetlpdb->media ne "NET"
          && $remotetlpdb->media ne "virtual"
          && !$opts{"dry-run"}
          && !$opts{"repository"}
          && !$ENV{"TEXLIVE_INSTALL_ENV_NOCHECK"}
        ) {
        tlwarn(<<END_DISK_WARN);
$prg: Your installation is set up to look on the disk for updates.
To install from the Internet for this one time only, run:
  tlmgr -repository $TeXLiveURL ACTION ARG...
where ACTION is install, update, etc.; see tlmgr -help if needed.

To change the default for all future updates, run:
  tlmgr option repository $TeXLiveURL
END_DISK_WARN
      }
    }
  }
  return ($ret);
}


sub check_announce_format_triggers {
  my %updpacks = map { $_ => 1 } @_;

  FMTDEF: for my $fmtdef ($localtlpdb->format_definitions) {
    if (($fmtdef->{'mode'} == 1) && $fmtdef->{'fmttriggers'}) {
      for my $trigger (@{$fmtdef->{'fmttriggers'}}) {
        if ($updpacks{$trigger}) {
          TeXLive::TLUtils::announce_execute_actions("rebuild-format",
            0, $fmtdef);
          next FMTDEF;
        }
      }
    }
  }
}

sub action_install {
  init_local_db(1);
  my $ret = $F_OK;
  return ($F_ERROR) if !check_on_writable();

  if ($opts{"file"}) {
    if ($localtlpdb->install_package_files(@ARGV)) {
      return ($ret);
    } else {
      return ($F_ERROR);
    }
  }

  $opts{"no-depends"} = 1 if $opts{"no-depends-at-all"};
  init_tlmedia_or_die();

  if (!$opts{"usermode"}) {
    if (check_for_critical_updates( $localtlpdb, $remotetlpdb)) {
      critical_updates_warning() if (!$::machinereadable);
      if ($opts{"force"}) {
        tlwarn("$prg: Continuing due to --force\n");
      } else {
        if ($::gui_mode) {
          return ($F_ERROR);
        } else {
          die "$prg: Terminating; please see warning above!\n";
        }
      }
    }
  }

  $opts{"no-depends"} = 1 if $opts{"no-depends-at-all"};
  info("$prg install: dry run, no changes will be made\n") if $opts{"dry-run"};

  my @packs = @ARGV;
  @packs = $remotetlpdb->expand_dependencies("-only-arch", $localtlpdb, @ARGV)
    unless $opts{"no-depends-at-all"};
  unless ($opts{"no-depends"}) {
    if ($opts{"reinstall"} || $opts{"usermode"}) {
      @packs = $remotetlpdb->expand_dependencies("-no-collections",
                                                 $localtlpdb, @packs);
    } else {
      @packs = $remotetlpdb->expand_dependencies($localtlpdb, @packs);
    }
  }
  my %packs;
  for my $p (@packs) {
    my ($pp, $aa) = split('@', $p);
    $packs{$pp} = (defined($aa) ? $aa : 0);
  }
  my @inst_packs;
  my @inst_colls;
  my @inst_schemes;
  for my $pkg (sort keys %packs) {
    if ($pkg =~ m/^scheme-/) {
      push @inst_schemes, $pkg;
    } elsif ($pkg =~ m/^collection-/) {
      push @inst_colls, $pkg;
    } else {
      push @inst_packs, $pkg;
    }
  }
  @inst_packs = sort packagecmp @inst_packs;

  my $starttime = time();
  my $totalnr = 0;
  my %revs;
  my @todo;
  for my $pkg (@inst_packs, @inst_colls, @inst_schemes) {
    my $pkgrev = 0;
    my $mediatlp = $remotetlpdb->get_package($pkg,
      ($packs{$pkg} ? $packs{$pkg} : undef));
    if (!defined($mediatlp)) {
      tlwarn("$prg install: package $pkg not present in repository.\n");
      $ret |= $F_WARNING;
      next;
    }
    if (defined($localtlpdb->get_package($pkg))) {
      if ($opts{"reinstall"}) {
        $totalnr++;
        $revs{$pkg} = $mediatlp->revision;
        push @todo, $pkg;
      } else {
        debug("already installed: $pkg\n");
        info("$prg install: package already present: $pkg\n")
          if grep { $_ eq $pkg } @ARGV;
      }
    } else {
      $totalnr++;
      $revs{$pkg} = $mediatlp->revision;
      push (@todo, $pkg);
    }
  }
  return ($ret) if (!@todo);

  my $orig_do_src = $localtlpdb->option("install_srcfiles");
  my $orig_do_doc = $localtlpdb->option("install_docfiles");
  if (!$opts{"dry-run"}) {
    $localtlpdb->option("install_srcfiles", 1) if $opts{'with-src'};
    $localtlpdb->option("install_docfiles", 1) if $opts{'with-doc'};
  }

  my $currnr = 1;
  my %sizes = %{$remotetlpdb->sizes_of_packages(
    $localtlpdb->option("install_srcfiles"),
    $localtlpdb->option("install_docfiles"), undef, @todo)};
  defined($sizes{'__TOTAL__'}) || ($sizes{'__TOTAL__'} = 0);
  my $totalsize = $sizes{'__TOTAL__'};
  my $donesize = 0;
  
  print "total-bytes\t$sizes{'__TOTAL__'}\n" if $::machinereadable;
  print "end-of-header\n" if $::machinereadable;

  foreach my $pkg (@todo) {
    my $flag = $FLAG_INSTALL;
    my $re = "";
    my $tlp = $remotetlpdb->get_package($pkg);
    my $rctanvers = $tlp->cataloguedata->{'version'};
    if (!defined($tlp)) {
      info("$prg: unknown package: $pkg\n");
      next;
    }
    if (!$tlp->relocated && $opts{"usermode"}) {
      info("$prg: package $pkg is not relocatable, cannot install it in user mode!\n");
      next;
    }
    my $lctanvers;
    if (defined($localtlpdb->get_package($pkg))) {
      my $lctanvers = $localtlpdb->get_package($pkg)->cataloguedata->{'version'};
      if ($opts{"reinstall"}) {
        $re = "re";
        $flag = $FLAG_REINSTALL;
      } else {
        debug("already installed (but didn't we say that already?): $pkg\n");
        next;
      }
    }
    my ($estrem, $esttot) = TeXLive::TLUtils::time_estimate($totalsize,
                              $donesize, $starttime);
    my $kb = int($sizes{$pkg} / 1024) + 1;
    my @addargs = ();
    my $tagstr = "";
    if ($remotetlpdb->is_virtual) {
      if ($packs{$pkg} ne "0") {
        push @addargs, $packs{$pkg};
        $tagstr = " \@" . $packs{$pkg};
      } else {
        my ($maxtag,undef,undef,undef) = $remotetlpdb->virtual_candidate($pkg);
        push @addargs, $maxtag;
        $tagstr = " \@" . $maxtag;
      }
    }
    push @addargs, $lctanvers, $rctanvers;
    if ($::machinereadable) {
      machine_line($pkg, $flag, "-", $revs{$pkg}, $sizes{$pkg}, $estrem, $esttot, @addargs);
    } else {
      info("[$currnr/$totalnr, $estrem/$esttot] ${re}install: $pkg$tagstr [${kb}k]\n");
    }
    if (!$opts{"dry-run"}) {
      if ($remotetlpdb->install_package($pkg, $localtlpdb,
            ($packs{$pkg} ? $packs{$pkg} : undef) )) {
        logpackage("${re}install: $pkg$tagstr");
      } else {
        logpackage("failed ${re}install: $pkg$tagstr");
      }
    }
    $donesize += $sizes{$pkg};
    $currnr++;
  }
  print "end-of-updates\n" if $::machinereadable;


  if ($opts{"dry-run"}) {
    return($ret | $F_NOPOSTACTION);
  } else {
    $localtlpdb->option("install_srcfiles", $orig_do_src) if $opts{'with-src'};
    $localtlpdb->option("install_docfiles", $orig_do_doc) if $opts{'with-doc'};
    $localtlpdb->save if ($opts{'with-src'} || $opts{'with-doc'});
  }
  return ($ret);
}

sub show_one_package {
  my ($pkg, $fmt, @rest) = @_;
  my $ret;
  if ($fmt eq "list") {
    $ret = show_one_package_list($pkg, @rest);
  } elsif ($fmt eq "detail") {
    $ret = show_one_package_detail($pkg, @rest);
  } elsif ($fmt eq "csv") {
    $ret = show_one_package_csv($pkg, @rest);
  } elsif ($fmt eq "json") {
    $ret = show_one_package_json($pkg);
  } else {
    tlwarn("$prg: show_one_package: unknown format: $fmt\n");
    return($F_ERROR);
  }
  return($ret);
}

sub show_one_package_json {
  my ($p) = @_;
  my @out;
  my $loctlp = $localtlpdb->get_package($p);
  my $remtlp = $remotetlpdb->get_package($p);
  my $is_installed = (defined($loctlp) ? 1 : 0);
  my $is_available = (defined($remtlp) ? 1 : 0);
  if (!($is_installed || $is_available)) {
    print "{ \"name\":\"$p\", \"available\":false }";
    return($F_OK);
  }
  my $tlp = ($is_installed ? $loctlp : $remtlp);
  my $str = $tlp->as_json(available => ($is_available ? TeXLive::TLUtils::True() : TeXLive::TLUtils::False()), 
                          installed => ($is_installed ? TeXLive::TLUtils::True() : TeXLive::TLUtils::False()),
                          lrev      => ($is_installed ? $loctlp->revision : 0),
                          rrev      => ($is_available ? $remtlp->revision : 0),
                          rcataloguedata => ($is_available ? $remtlp->cataloguedata : {}),
                          revision  => undef);
  print $str;
  return($F_OK);
}


sub show_one_package_csv {
  my ($p, @datafields) = @_;
  my @out;
  my $loctlp = $localtlpdb->get_package($p);
  my $remtlp = $remotetlpdb->get_package($p) unless ($opts{'only-installed'});
  my $is_installed = (defined($loctlp) ? 1 : 0);
  my $is_available = (defined($remtlp) ? 1 : 0);
  if (!($is_installed || $is_available)) {
    if ($opts{'only-installed'}) {
      tlwarn("$prg: package $p not locally!\n");
    } else {
      tlwarn("$prg: package $p not found neither locally nor remote!\n");
    }
    return($F_WARNING);
  }
  my $tlp = ($is_installed ? $loctlp : $remtlp);
  for my $d (@datafields) {
    if ($d eq "name") {
      push @out, $p;
    } elsif ($d eq "category") {
      push @out, $tlp->category || "";
    } elsif ($d eq "shortdesc") {
      my $str = $tlp->shortdesc;
       if (defined $tlp->shortdesc) {
        $str =~ s/"/\\"/g;
        push @out, "\"$str\"";
      } else {
        push @out, "";
      }
    } elsif ($d eq "longdesc") {
      my $str = $tlp->longdesc;
      if (defined $tlp->shortdesc) {
        $str =~ s/"/\\"/g;
        $str =~ s/\n/\\n/g;
        push @out, "\"$str\"";
      } else {
        push @out, "";
      }
    } elsif ($d eq "installed") {
      push @out, $is_installed;
    } elsif ($d eq "relocatable") {
      push @out, ($tlp->relocated ? 1 : 0);
    } elsif ($d eq "cat-version") {
      push @out, ($tlp->cataloguedata->{'version'} || "");
    } elsif ($d eq "lcat-version") {
      push @out, ($is_installed ? ($loctlp->cataloguedata->{'version'} || "") : "");
    } elsif ($d eq "rcat-version") {
      push @out, ($is_available ? ($remtlp->cataloguedata->{'version'} || "") : "");
    } elsif ($d eq "cat-date") {
      push @out, ($tlp->cataloguedata->{'date'} || "");
    } elsif ($d eq "lcat-date") {
      push @out, ($is_installed ? ($loctlp->cataloguedata->{'date'} || "") : "");
    } elsif ($d eq "rcat-date") {
      push @out, ($is_available ? ($remtlp->cataloguedata->{'date'} || "") : "");
    } elsif ($d eq "cat-license") {
      push @out, ($tlp->cataloguedata->{'license'} || "");
    } elsif ($d eq "lcat-license") {
      push @out, ($is_installed ? ($loctlp->cataloguedata->{'license'} || "") : "");
    } elsif ($d eq "rcat-license") {
      push @out, ($is_available ? ($remtlp->cataloguedata->{'license'} || "") : "");
    } elsif ($d =~ m/^cat-(contact-.*)$/) {
      push @out, ($tlp->cataloguedata->{$1} || "");
    } elsif ($d =~ m/^lcat-(contact-.*)$/) {
      push @out, ($is_installed ? ($loctlp->cataloguedata->{$1} || "") : "");
    } elsif ($d =~ m/^rcat-(contact-.*)$/) {
      push @out, ($is_available ? ($remtlp->cataloguedata->{$1} || "") : "");
    } elsif ($d eq "localrev") {
      push @out, ($is_installed ? $loctlp->revision : 0);
    } elsif ($d eq "remoterev") {
      push @out, ($is_available ? $remtlp->revision : 0);
    } elsif ($d eq "depends") {
      push @out, (join(":", $tlp->depends));
    } elsif ($d eq "size") {
      my $srcsize = $tlp->srcsize * $TeXLive::TLConfig::BlockSize;
      my $docsize = $tlp->docsize * $TeXLive::TLConfig::BlockSize;
      my $runsize = $tlp->runsize * $TeXLive::TLConfig::BlockSize;
      my $binsize = 0;
      my $binsizes = $tlp->binsize;
      for my $a (keys %$binsizes) { $binsize += $binsizes->{$a} ; }
      $binsize *= $TeXLive::TLConfig::BlockSize;
      my $totalsize = $srcsize + $docsize + $runsize + $binsize;
      push @out, $totalsize;
    } else {
      tlwarn("$prg: unknown data field $d\n");
      return($F_WARNING);
    }
  }
  print join(",", @out), "\n";
  return($F_OK);
}

sub show_one_package_list {
  my ($p, @rest) = @_;
  my @out;
  my $loctlp = $localtlpdb->get_package($p);
  my $remtlp = $remotetlpdb->get_package($p) unless ($opts{'only-installed'});
  my $is_installed = (defined($loctlp) ? 1 : 0);
  my $is_available = (defined($remtlp) ? 1 : 0);
  if (!($is_installed || $is_available)) {
    if ($opts{'only-installed'}) {
      tlwarn("$prg: package $p not locally!\n");
    } else {
      tlwarn("$prg: package $p not found neither locally nor remote!\n");
    }
    return($F_WARNING);
  }
  my $tlp = ($is_installed ? $loctlp : $remtlp);
  my $tlm;
  if ($opts{"only-installed"}) {
    $tlm = $localtlpdb;
  } else {
    $tlm = $remotetlpdb;
  }
  if ($is_installed) {
    print "i ";
  } else {
    print "  ";
  }
  if (!$tlp) {
    if ($remotetlpdb->is_virtual) {
      my @cand = $remotetlpdb->candidates($p);
      if (@cand) {
        my $first = shift @cand;
        if (defined($first)) {
          tlwarn("$prg:show_one_package_list: strange, have first "
                 . "candidate but no tlp: $p\n");
          return($F_WARNING);
        }
        if ($#cand >= 0) {
          print "$p: --- no installable candidate found, \n";
          print "    but present in subsidiary repositories without a pin.\n";
          print "    This package is not reachable without pinning.\n";
          print "    Repositories containing this package:\n";
          for my $a (@cand) {
            my ($t,$r) = split(/\//, $a, 2);
            my $tlp = $remotetlpdb->get_package($p, $t);
            my $foo = $tlp->shortdesc;
            print "      $t: ",
                  defined($foo) ? $foo : "(shortdesc missing)" , "\n";
          }
          return($F_WARNING);
        } else {
          tlwarn("$prg:show_one_package_list: strange, package listed "
                 . "but no residual candidates: $p\n");
          return($F_WARNING);
        }
      } else {
        tlwarn("$prg:show_one_package_list: strange, package listed but "
               . "no candidates: $p\n");
        return($F_WARNING);
      }
    } else {
      tlwarn("$prg:show_one_package_list: strange, package not found in "
             . "remote tlpdb: $p\n");
      return($F_WARNING);
    }
  }
  my $foo = $tlp->shortdesc;
  print "$p: ", defined($foo) ? $foo : "(shortdesc missing)" , "\n";
  return($F_OK);
}

sub show_one_package_detail {
  my ($ppp, @rest) = @_;
  my $ret = $F_OK;
  my ($pkg, $tag) = split ('@', $ppp, 2);
  my $tlpdb = $localtlpdb;
  my $source_found;
  my $tlp = $localtlpdb->get_package($pkg);
  my $installed = 0;
  if (!$tlp) {
    if ($opts{"only-installed"}) {
      print "package:     $pkg\n";
      print "installed:   No\n";
      return($F_OK);
    }
    if (!$remotetlpdb) {
      init_tlmedia_or_die(1);
    }
    if (defined($tag)) {
      if (!$remotetlpdb->is_virtual) {
        tlwarn("$prg: specifying implicit tags not allowed for non-virtual databases!\n");
        return($F_WARNING);
      } else {
        if (!$remotetlpdb->is_repository($tag)) {
          tlwarn("$prg: no such repository tag defined: $tag\n");
          return($F_WARNING);
        }
      }
    }
    $tlp = $remotetlpdb->get_package($pkg, $tag);
    if (!$tlp) {
      if (defined($tag)) {
        tlwarn("$prg: cannot find package $pkg in repository $tag\n");
        return($F_WARNING);
      }
      my @cand = $remotetlpdb->candidates($pkg);
      if (@cand) {
        my $first = shift @cand;
        if (defined($first)) {
          tlwarn("$prg:show_one_package_detail: strange, have first candidate "
                 . "but no tlp: $pkg\n");
          return($F_WARNING);
        }
        if ($#cand >= 0) {
          print "package:     ", $pkg, "\n";
          print "WARNING:     This package is not pinned but present in subsidiary repositories\n";
          print "WARNING:     As long as it is not pinned it is not installable.\n";
          print "WARNING:     Listing all available copies of the package.\n";
          my @aaa;
          for my $a (@cand) {
            my ($t,$r) = split(/\//, $a, 2);
            push @aaa, "$pkg" . '@' . $t;
          }
          $ret |= action_info(@aaa);
          return($ret);
        }
      }
      info("$prg: cannot find package $pkg, searching for other matches:\n");
      my ($foundfile, $founddesc) = search_tlpdb($remotetlpdb,$pkg,1,1,0);
      print "\nPackages containing \`$pkg\' in their title/description:\n";
      print $founddesc;
      print "\nPackages containing files matching \`$pkg\':\n";
      print $foundfile;
      return($ret);
    }
    if (defined($tag)) {
      $source_found = $tag;
    } else {
      if ($remotetlpdb->is_virtual) {
        my ($firsttag, @cand) = $remotetlpdb->candidates($pkg);
        $source_found = $firsttag;
      } else {
      }
    }
    $tlpdb = $remotetlpdb;
  } else {
    $installed = 1;
  }
  my @colls;
  if ($tlp->category ne "Collection" && $tlp->category ne "Scheme") {
    @colls = $localtlpdb->needed_by($pkg);
    if (!@colls) {
      if (!$opts{"only-installed"}) {
        init_tlmedia_or_die() if (!$remotetlpdb);
        @colls = $remotetlpdb->needed_by($pkg);
      }
    }
  }
  @colls = grep {m;^collection-;} @colls;
  print "package:     ", $tlp->name, "\n";
  print "repository:  ", $source_found, "\n" if (defined($source_found));
  print "category:    ", $tlp->category, "\n";
  print "shortdesc:   ", $tlp->shortdesc, "\n" if ($tlp->shortdesc);
  print "longdesc:    ", $tlp->longdesc, "\n" if ($tlp->longdesc);
  print "installed:   ", ($installed ? "Yes" : "No"), "\n";
  print "revision:    ", $tlp->revision, "\n" if ($installed);
  my $sizestr = "";
  if ($tlp->category ne "Collection" && $tlp->category ne "Scheme") {
    my $srcsize = $tlp->srcsize * $TeXLive::TLConfig::BlockSize;
    $sizestr = sprintf("%ssrc: %dk", $sizestr, int($srcsize / 1024) + 1) 
      if ($srcsize > 0);
    my $docsize = $tlp->docsize * $TeXLive::TLConfig::BlockSize;
    $sizestr .= sprintf("%sdoc: %dk", 
      ($sizestr ? ", " : ""), int($docsize / 1024) + 1)
        if ($docsize > 0);
    my $runsize = $tlp->runsize * $TeXLive::TLConfig::BlockSize;
    $sizestr .= sprintf("%srun: %dk", 
      ($sizestr ? ", " : ""), int($runsize / 1024) + 1)
        if ($runsize > 0);
    my $do_archs = 0;
    for my $d ($tlp->depends) {
      if ($d =~ m/^(.*)\.ARCH$/) {
        $do_archs = 1;
        last;
      }
    }
    if ($do_archs) {
      my @a = $localtlpdb->available_architectures;
      my %binsz = %{$tlp->binsize};
      my $binsize = 0;
      for my $a (@a) {
        $binsize += $binsz{$a} if defined($binsz{$a});
        my $atlp = $tlpdb->get_package($tlp->name . ".$a");
        if (!$atlp) {
          tlwarn("$prg: cannot find depending package " . $tlp->name . ".$a\n");
          return($F_WARNING);
        }
        my %abinsz = %{$atlp->binsize};
        $binsize += $abinsz{$a} if defined($abinsz{$a});
      }
      $binsize *= $TeXLive::TLConfig::BlockSize;
      $sizestr .= sprintf("%sbin: %dk",
        ($sizestr ? ", " : ""), int($binsize / 1024) + 1)
          if ($binsize > 0);
    }
  } else {
    my $foo = $tlpdb->sizes_of_packages_with_deps ( 1, 1, undef, $pkg);
    if (defined($foo->{$pkg})) {
      $sizestr = sprintf("%dk", int($foo->{$pkg} / 1024) + 1);
    }
  }
  print "sizes:       ", $sizestr, "\n";
  print "relocatable: ", ($tlp->relocated ? "Yes" : "No"), "\n";
  print "cat-version: ", $tlp->cataloguedata->{'version'}, "\n"
    if $tlp->cataloguedata->{'version'};
  print "cat-date:    ", $tlp->cataloguedata->{'date'}, "\n"
    if $tlp->cataloguedata->{'date'};
  print "cat-license: ", $tlp->cataloguedata->{'license'}, "\n"
    if $tlp->cataloguedata->{'license'};
  print "cat-topics:  ", $tlp->cataloguedata->{'topics'}, "\n"
    if $tlp->cataloguedata->{'topics'};
  print "cat-related: ", $tlp->cataloguedata->{'also'}, "\n"
    if $tlp->cataloguedata->{'also'};
  for my $k (keys %{$tlp->cataloguedata}) {
    if ($k =~ m/^contact-/) {
      print "cat-$k: ", $tlp->cataloguedata->{$k}, "\n";
    }
  }
  print "collection:  ", @colls, "\n" if (@colls);
  if ($opts{"list"}) {
    if ($tlp->category eq "Collection" || $tlp->category eq "Scheme") {
      my @deps = $tlp->depends;
      if (@deps) {
        print "depends:\n";
        for my $d (@deps) {
          print "\t$d\n";
        }
      }
    }
    print "Included files, by type:\n";
    my @todo = $tlpdb->expand_dependencies("-only-arch", $tlpdb, ($pkg));
    for my $d (sort @todo) {
      my $foo = $tlpdb->get_package($d);
      if (!$foo) {
        tlwarn ("$prg: Should not happen, no dependent package $d\n");
        return($F_WARNING);
      }
      if ($d ne $pkg) {
        print "depending package $d:\n";
      }
      if ($foo->runfiles) {
        print "run files:\n";
        for my $f (sort $foo->runfiles) { print "  $f\n"; }
      }
      if ($foo->srcfiles) {
        print "source files:\n";
        for my $f (sort $foo->srcfiles) { print "  $f\n"; }
      }
      if ($foo->docfiles) {
        print "doc files:\n";
        for my $f (sort $foo->docfiles) {
          print "  $f";
          my $dfd = $foo->docfiledata;
          if (defined($dfd->{$f})) {
            for my $k (keys %{$dfd->{$f}}) {
              print " $k=\"", $dfd->{$f}->{$k}, '"';
            }
          }
          print "\n";
        }
      }
      if ($foo->allbinfiles) {
        print "bin files (all platforms):\n";
      for my $f (sort $foo->allbinfiles) { print " $f\n"; }
      }
    }
  }
  print "\n";
  return($ret);
}

sub action_pinning {
  my $what = shift @ARGV;
  $what || ($what = 'show');
  init_local_db();
  init_tlmedia_or_die();
  if (!$remotetlpdb->is_virtual) {
    tlwarn("$prg: only one repository configured, "
           . "pinning actions not supported.\n");
    return $F_WARNING;
  }
  my $pinref = $remotetlpdb->virtual_pindata();
  my $pf = $remotetlpdb->virtual_pinning();

  if ($what =~ m/^show$/i) {
    my @pins = @$pinref;
    if (!@pins) {
      tlwarn("$prg: no pinning data present.\n");
      return $F_OK;
    }
    info("$prg: this pinning data is defined:\n");
    for my $p (@pins) {
      info("  ", $p->{'repo'}, ":", $p->{'glob'}, "\n");
    }
    return $F_OK;

  } elsif ($what =~ m/^check$/i) {
    tlwarn("$prg: not implemented yet, sorry!\n");
    return $F_WARNING;

  } elsif ($what =~ m/^add$/i) {
    if (@ARGV < 2) {
      tlwarn("$prg: need at least two arguments to pinning add\n");
      return $F_ERROR;
    }
    my $repo = shift @ARGV;
    my @new = ();
    my @ov = $pf->value($repo);
    for my $n (@ARGV) {
      if (member($n, @ov)) {
        info("$prg: already pinned to $repo: $n\n");
      } else {
        push (@ov, $n);
        push (@new, $n);
      }
    }
    $pf->value($repo, @ov);
    $remotetlpdb->virtual_update_pins();
    $pf->save;
    info("$prg: new pinning data for $repo: @new\n") if @new;
    return $F_OK;

  } elsif ($what =~ m/^remove$/i) {
    my $repo = shift @ARGV;
    if (!defined($repo)) {
      tlwarn("$prg: missing repository argument to pinning remove\n");
      return $F_ERROR;
    }
    if ($opts{'all'}) {
      if (@ARGV) {
        tlwarn("$prg: additional argument(s) not allowed with --all: @ARGV\n");
        return $F_ERROR;
      }
      $pf->delete_key($repo);
      $remotetlpdb->virtual_update_pins();
      $pf->save;
      info("$prg: all pinning data removed for repository $repo\n");
      return $F_OK;
    }
    my @ov = $pf->value($repo);
    my @nv;
    for my $pf (@ov) {
      push (@nv, $pf) if (!member($pf, @ARGV));
    }
    if ($#ov == $#nv) {
      info("$prg: no changes in pinning data for $repo\n");
      return $F_OK;
    }
    if (@nv) {
      $pf->value($repo, @nv);
    } else {
      $pf->delete_key($repo);
    }
    $remotetlpdb->virtual_update_pins();
    $pf->save;
    info("$prg: removed pinning data for repository $repo: @ARGV\n");
    return $F_OK;

  } else {
    tlwarn("$prg: unknown argument for pinning action: $what\n");
    return $F_ERROR;
  }
  return $F_ERROR;
}


sub array_to_repository {
  my %r = @_;
  my @ret;
  my @k = keys %r;
  if ($#k == 0) {
    return $r{$k[0]};
  }
  for my $k (keys %r) {
    my $v = $r{$k};
    if ($k ne $v) {
      $v = "$v#$k";
    }
    $v =~ s/%/%25/g;
    $v =~ s/ /%20/g;
    push @ret, $v;
  }
  return "@ret";
}
sub merge_sub_packages {
  my %pkgs;
  for my $p (@_) {
    if ($p =~ m/^(.*)\.([^.]*)$/) {
      my $n = $1;
      my $a = $2;
      if ($p eq "texlive.infra") {
        push @{$pkgs{$p}}, "all";
      } else {
        push @{$pkgs{$n}}, $a;
      }
    } else {
      push @{$pkgs{$p}}, "all";
    }
  }
  return %pkgs;
}
sub action_repository {
  init_local_db();
  my $what = shift @ARGV;
  $what = "list" if !defined($what);
  my %repos = repository_to_array($localtlpdb->option("location"));
  if ($what =~ m/^list$/i) {
    if (@ARGV) {
      for my $repo (@ARGV) {
        my $loc = $repo;
        if (defined($repos{$repo})) {
          $loc = $repos{$repo};
        }
        my ($tlpdb, $errormsg) = setup_one_remotetlpdb($loc);
        if (!defined($tlpdb)) {
          tlwarn("$prg: cannot get TLPDB from location $loc\n\n");
        } else {
          print "Packages at $loc:\n";
          my %pkgs = merge_sub_packages($tlpdb->list_packages);
          for my $p (sort keys %pkgs) {
            next if ($p =~ m/00texlive/);
            print "  $p";
            if (!$opts{'with-platforms'}) {
              print "\n";
            } else {
              my @a = @{$pkgs{$p}};
              if ($#a == 0) {
                if ($a[0] eq "all") {
                  print "\n";
                } else {
                  print ".$a[0]\n";
                }
              } else {
                print " (@{$pkgs{$p}})\n";
              }
            }
          }
        }
      }
    } else {
      print "List of repositories (with tags if set):\n";
      for my $k (keys %repos) {
        my $v = $repos{$k};
        print "\t$v";
        if ($k ne $v) {
          print " ($k)";
        }
        print "\n";
      }
    }
    return ($F_OK);
  }
  if ($what eq "add") {
    my $p = shift @ARGV;
    if (!defined($p)) {
      tlwarn("$prg: no repository given (to add)\n");
      return ($F_ERROR);
    }
    if (($p !~ m!^(https?|ftp)://!i) && ($p !~ m!$TeXLive::TLUtils::SshURIRegex!) && 
        !File::Spec->file_name_is_absolute($p)) {
      tlwarn("$prg: neither https?/ftp/ssh/scp/file URI nor absolute path, no action: $p\n");
      return ($F_ERROR);
    }
    my $t = shift @ARGV;
    $t = $p if (!defined($t));
    if (defined($repos{$t})) {
      tlwarn("$prg: repository or its tag already defined, no action: $p\n");
      return ($F_ERROR);
    }
    my @tags = keys %repos;
    if ($#tags == 0) {
      my $maintag = $tags[0];
      if ($maintag ne 'main') {
        $repos{'main'} = $repos{$maintag};
        delete $repos{$maintag};
      }
    }
    $repos{$t} = $p;
    $localtlpdb->option("location", array_to_repository(%repos));
    $localtlpdb->save;
    if ($t eq $p) {
      print "$prg: added repository: $p\n";
    } else {
      print "$prg: added repository with tag $t: $p\n";
    }
    return ($F_OK);
  }
  if ($what eq "remove") {
    my $p = shift @ARGV;
    if (!defined($p)) {
      tlwarn("$prg: no repository given (to remove)\n");
      return ($F_ERROR);
    }
    my $found = 0;
    for my $k (keys %repos) {
      if ($k eq $p || $repos{$k} eq $p) {
        $found = 1;
        delete $repos{$k};
      }
    }
    if (!$found) {
      tlwarn("$prg: repository not defined, cannot remove: $p\n");
      return ($F_ERROR);
    } else {
      $localtlpdb->option("location", array_to_repository(%repos));
      $localtlpdb->save;
      print "$prg: removed repository: $p\n";
      return ($F_OK);
    }
    return ($F_OK);
  }
  if ($what eq "set") {
    %repos = repository_to_array("@ARGV");
    $localtlpdb->option("location", array_to_repository(%repos));
    $localtlpdb->save;
    return ($F_OK);
  }
  if ($what eq "status") {
    if (!defined($remotetlpdb)) {
      init_tlmedia_or_die();
    }
    if (!$remotetlpdb->is_virtual) {
      my $verstat = $remotetlpdb->verification_status;
      print "main ", $remotetlpdb->location, " ", 
        ($::machinereadable ? "$verstat " : ""),
        $VerificationStatusDescription{$verstat}, "\n";
      return ($F_OK);
    } else {
      for my $t ($remotetlpdb->virtual_get_tags()) {
        my $tlpdb = $remotetlpdb->virtual_get_tlpdb($t);
        my $verstat = $tlpdb->verification_status;
        print "$t ", $tlpdb->location, " ",
          ($::machinereadable ? "$verstat " : ""),
          $VerificationStatusDescription{$verstat}, "\n";
      }
      return($F_OK);
    }
  }
  tlwarn("$prg: unknown subaction for tlmgr repository: $what\n");
  return ($F_ERROR);
}

sub action_candidates {
  my $what = shift @ARGV;
  if (!defined($what)) {
    tlwarn("$prg: candidates needs a package name as argument\n");
    return ($F_ERROR);
  }
  init_local_db();
  init_tlmedia_or_die();
  my @cand = $remotetlpdb->candidates($what);
  if (@cand) {
    my $first = shift @cand;
    if (defined($first)) {
      my ($t,$r) = split(/\//, $first, 2);
      print "Install candidate for $what from $t ($r)\n";
    } else {
      print "No install candidate for $what found.\n";
    }
    if ($#cand >= 0) {
      print "Other repositories providing this package:\n";
      for my $a (@cand) {
        my ($t,$r) = split(/\//, $a, 2);
        print "$t ($r)\n";
      }
    }
  } else {
    print "Package $what not found.\n";
    return ($F_WARNING);
  }
  return ($F_OK);;
}

sub action_option {
  my $what = shift @ARGV;
  $what = "show" unless defined($what);
  init_local_db();
  my $ret = $F_OK;
  my %json;
  if ($what =~ m/^show$/i) {
    if ($opts{'json'}) {
      my $json = $localtlpdb->options_as_json();
      print("$json\n");
      return($ret);
    }
    for my $o (sort keys %{$localtlpdb->options}) {
      next if ($o eq "generate_updmap");
      next if ($o eq "desktop_integration" && !wndws());
      next if ($o eq "file_assocs" && !wndws());
      next if ($o eq "w32_multi_user" && !wndws());
      if (wndws()) {
        next if ($o =~ m/^sys_/);
      }
      if (defined $TLPDBOptions{$o}) {
        if ($::machinereadable) {
          print "$TLPDBOptions{$o}->[2]\t", $localtlpdb->option($o), "\n";
        } else {
          info("$TLPDBOptions{$o}->[3] ($TLPDBOptions{$o}->[2]): " .
                $localtlpdb->option($o) . "\n");
        }
      } else {
        tlwarn ("$prg: option $o not supported\n");
        $ret |= $F_WARNING;
      }
    }
  } elsif ($what =~ m/^(showall|help)$/i) {
    if ($opts{'json'}) {
      my $json = $localtlpdb->options_as_json();
      print("$json\n");
      return($ret);
    }
    my %loc = %{$localtlpdb->options};
    for my $o (sort keys %TLPDBOptions) {
      if ($::machinereadable) {
        print "$TLPDBOptions{$o}->[2]\t",
          (defined($loc{$o}) ? $loc{$o} : "(not set)"), "\n";
      } else {
        info("$TLPDBOptions{$o}->[3] ($TLPDBOptions{$o}->[2]): " .
             (defined($loc{$o}) ? $loc{$o} : "(not set)") . "\n");
      }
    }
  } else {
    if ($what eq "location" || $what eq "repo") {
      $what = "repository";
    }
    my $found = 0;
    for my $opt (keys %TLPDBOptions) {
      if (($what eq $TLPDBOptions{$opt}->[2]) || ($what eq $opt)) {
        $found = 1;
        my $val = shift @ARGV;
        if (defined($val)) {
          return ($F_ERROR) if !check_on_writable();
          if ($what eq $TLPDBOptions{"location"}->[2]) {
            if ($val =~ m/^ctan$/i) {
              $val = "$TeXLive::TLConfig::TeXLiveURL";
            }
            info("$prg: setting default package repository to $val\n");
            $localtlpdb->option($opt, $val);
          } elsif ($what eq $TLPDBOptions{"backupdir"}->[2]) {
            info("$prg: setting option $what to $val.\n");
            if (! -d $val) {
              info("$prg: the directory $val does not exists, it has to be created\n");
              info("$prg: before backups can be done automatically.\n");
            }
            $localtlpdb->option($opt, $val);
          } elsif ($what eq $TLPDBOptions{"w32_multi_user"}->[2]) {
            my $do_it = 0;
            if (wndws()) {
              if (admin()) {
                $do_it = 1;
              } else {
                if ($val) {
                  tlwarn("$prg: non-admin user cannot set $TLPDBOptions{'w32_multi_user'}->[2] option to true\n");
                } else {
                  $do_it = 1;
                }
              }
            } else {
              $do_it = 1;
            }
            if ($do_it) {
              if ($val) {
                info("$prg: setting option $what to 1.\n");
                $localtlpdb->option($opt, 1);
              } else {
                info("$prg: setting option $what to 0.\n");
                $localtlpdb->option($opt, 0);
              }
            }
          } else {
            if ($TLPDBOptions{$opt}->[0] eq "b") {
              if ($val) {
                info("$prg: setting option $what to 1.\n");
                $localtlpdb->option($opt, 1);
              } else {
                info("$prg: setting option $what to 0.\n");
                $localtlpdb->option($opt, 0);
              }
            } elsif ($TLPDBOptions{$opt}->[0] eq "p") {
              info("$prg: setting option $what to $val.\n");
              $localtlpdb->option($opt, $val);
            } elsif ($TLPDBOptions{$opt}->[0] eq "u") {
              info("$prg: setting option $what to $val.\n");
              $localtlpdb->option($opt, $val);
            } elsif ($TLPDBOptions{$opt}->[0] =~ m/^n(:((-)?\d+)?..((-)?\d+)?)?$/) {
              my $isgood = 1;
              my $n = int($val);
              my $low;
              my $up;
              if (defined($1)) {
                if (defined($2)) {
                  if ($2 > $n) {
                    tlwarn("$prg: value $n for $what out of range ($TLPDBOptions{$opt}->[0])\n");
                    $isgood = 0;
                  }
                }
                if (defined($4)) {
                  if ($4 < $n) {
                    tlwarn("$prg: value $n for $what out of range ($TLPDBOptions{$opt}->[0])\n");
                    $isgood = 0;
                  }
                }
              }
              if ($isgood) {
                info("$prg: setting option $what to $n.\n");
                $localtlpdb->option($opt, $n);
              }
            } else {
              tlwarn ("$prg: unknown type of option $opt: $TLPDBOptions{$opt}->[0]\n");
              return ($F_ERROR);
            }
          }
          my $local_location = $localtlpdb->location;
          info("$prg: updating $local_location\n");
          $localtlpdb->save;
          my $tlpo = $localtlpdb->get_package("00texlive.installation");
          if ($tlpo) {
            if (open(TOFD, ">$::maintree/tlpkg/tlpobj/00texlive.installation.tlpobj")) {
              $tlpo->writeout(\*TOFD);
              close(TOFD);
            } else {
              tlwarn("$prg: Cannot save 00texlive.installation to $::maintree/tlpkg/tlpobj/00texlive.installation.tlpobj\n");
              $ret |= $F_WARNING;
            }
          }
        } else {
          if ($::machinereadable) {
            print "$TLPDBOptions{$opt}->[2]\t", $localtlpdb->option($opt), "\n";
          } else {
            info ("$TLPDBOptions{$opt}->[3] ($TLPDBOptions{$opt}->[2]): " .
                  $localtlpdb->option($opt) . "\n");
          }
        }
        last;
      }
    }
    if (!$found) {
      tlwarn("$prg: Option not supported: $what\n");
      return ($F_ERROR);
    }
  }
  return ($ret);
}


sub action_platform {
  my $ret = $F_OK;
  my @extra_w32_packs = qw/tlperl.windows tlgs.windows
                           collection-wintools
                           dviout.windows wintools.windows/;
  if ($^O =~ /^MSWin/i) {
    warn("action `platform' not supported on Windows\n");
    return ($F_ERROR);
  }
  if ($opts{"usermode"}) {
    tlwarn("$prg: action `platform' not supported in usermode\n");
    return ($F_ERROR);
  }
  my $what = shift @ARGV;
  init_local_db(1);
  info("$prg platform: dry run, no changes will be made\n") if $opts{"dry-run"};
  $what || ($what = "list");
  if ($what =~ m/^list$/i) {
    init_tlmedia_or_die();
    my @already_installed_arch = $localtlpdb->available_architectures;
    print "Available platforms:\n";
    foreach my $a ($remotetlpdb->available_architectures) {
      if (member($a,@already_installed_arch)) {
        print "(i) $a\n";
      } else {
        print "    $a\n";
      }
    }
    print "Already installed platforms are marked with (i)\n";
    print "You can add new platforms with: tlmgr platform add PLAT1 PLAT2...\n";
    print "You can remove platforms with: tlmgr platform remove PLAT1 PLAT2...\n";
    print "You can set the active platform with: tlmgr platform set PLAT\n";
    return ($F_OK | $F_NOPOSTACTION);

  } elsif ($what =~ m/^add$/i) {
    return ($F_ERROR) if !check_on_writable();
    init_tlmedia_or_die();
    my @already_installed_arch = $localtlpdb->available_architectures;
    my @available_arch = $remotetlpdb->available_architectures;
    my @todoarchs;
    foreach my $a (@ARGV) {
      if (TeXLive::TLUtils::member($a, @already_installed_arch)) {
        info("$prg: platform already installed: $a\n");
        next;
      }
      if (!TeXLive::TLUtils::member($a, @available_arch)) {
        info("$prg: platform `$a' not available; see tlmgr platform list\n");
        next;
      }
      push @todoarchs, $a;
    }
    foreach my $pkg ($localtlpdb->list_packages) {
      next if ($pkg =~ m/^00texlive/);
      my $tlp = $localtlpdb->get_package($pkg);
      foreach my $dep ($tlp->depends) {
        if ($dep =~ m/^(.*)\.ARCH$/) {
          foreach my $a (@todoarchs) {
            if ($remotetlpdb->get_package("$pkg.$a")) {
              info("install: $pkg.$a\n");
              if (!$opts{'dry-run'}) {
                if (! $remotetlpdb->install_package("$pkg.$a", $localtlpdb)) {
                  $ret |= $F_ERROR;
                }
              }
            } else {
              tlwarn("$prg: action platform add, cannot find package $pkg.$a\n");
              $ret |= $F_WARNING;
            }
          }
        }
      }
    }
    if (TeXLive::TLUtils::member('windows', @todoarchs)) {
      for my $p (@extra_w32_packs) {
        info("install: $p\n");
        if (!$opts{'dry-run'}) {
          if (! $remotetlpdb->install_package($p, $localtlpdb)) {
            $ret |= $F_ERROR;
          }
        }
      }
    }
    if (!$opts{"dry-run"}) {
      my @larchs = $localtlpdb->setting("available_architectures");
      push @larchs, @todoarchs;
      $localtlpdb->setting("available_architectures",@larchs);
      $localtlpdb->save;
    }

  } elsif ($what =~ m/^remove$/i) {
    return ($F_ERROR) if !check_on_writable();
    my @already_installed_arch = $localtlpdb->available_architectures;
    my @todoarchs;
    my $currentarch = $localtlpdb->platform();
    foreach my $a (@ARGV) {
      if (!TeXLive::TLUtils::member($a, @already_installed_arch)) {
        tlwarn("$prg: Platform $a not installed, use 'tlmgr platform list'!\n");
        $ret |= $F_WARNING;
        next;
      }
      if ($currentarch eq $a) {
        info("$prg: You are running on platform $a, you cannot remove that one!\n");
        $ret |= $F_WARNING;
        next;
      }
      push @todoarchs, $a;
    }
    foreach my $pkg ($localtlpdb->list_packages) {
      next if ($pkg =~ m/^00texlive/);
      my $tlp = $localtlpdb->get_package($pkg);
      if (!$tlp) {
        next;
      }
      foreach my $dep ($tlp->depends) {
        if ($dep =~ m/^(.*)\.ARCH$/) {
          foreach my $a (@todoarchs) {
            if ($localtlpdb->get_package("$pkg.$a")) {
              info("remove: $pkg.$a\n");
              $localtlpdb->remove_package("$pkg.$a") if (!$opts{"dry-run"});
            }
          }
        }
      }
    }
    if (TeXLive::TLUtils::member('windows', @todoarchs)) {
      for my $p (@extra_w32_packs) {
        info("remove: $p\n");
        $localtlpdb->remove_package($p) if (!$opts{"dry-run"});
      }
    }
    if (!$opts{"dry-run"}) {
      for my $a (@todoarchs) {
        if (!rmdir("$Master/bin/$a")) {
          tlwarn("$prg: failed to rmdir $Master/bin/$a: $!\n");
          $ret |= $F_WARNING;
        }
      }
      my @larchs = $localtlpdb->setting("available_architectures");
      my @newarchs;
      for my $a (@larchs) {
        push @newarchs, $a if !member($a, @todoarchs);
      }
      $localtlpdb->setting("available_architectures",@newarchs);
      $localtlpdb->save;
    }

  } elsif ($what =~ m/^set$/i) {
    return if !check_on_writable();
    my $arg = shift @ARGV;
    die "Missing argument to platform set" unless defined($arg);
    my @already_installed_arch = $localtlpdb->available_architectures;
    if ($arg =~ m/^auto$/i) {
      info("Setting platform detection to auto mode.\n");
      $localtlpdb->setting('-clear', 'platform');
      $localtlpdb->save;
    } else {
      if (!TeXLive::TLUtils::member($arg, @already_installed_arch)) {
        tlwarn("$prg: cannot set platform to a not installed one.\n");
        return ($F_ERROR);
      }
      $localtlpdb->setting('platform', $arg);
      $localtlpdb->save;
    }
  } else {
    tlwarn("$prg: Unknown option for platform: $what\n");
    $ret |= $F_ERROR;
  }
  return ($ret);
}


sub action_generate {
  if ($opts{"usermode"}) {
    tlwarn("$prg: action `generate' not supported in usermode!\n");
    return $F_ERROR;
  }
  my $what = shift @ARGV;
  if (!defined($what)) {
    tlwarn("$prg: action `generate' requires an argument!\n");
    return ($F_ERROR);
  }
  init_local_db();

  chomp (my $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
  chomp (my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
  chomp (my $TEXMFLOCAL = `kpsewhich -var-value=TEXMFLOCAL`);
  chomp (my $TEXMFDIST = `kpsewhich -var-value=TEXMFDIST`);

  my $append_extension = (($opts{"dest"} && ($what eq "language")) ? 1 : 0);

  if ($what =~ m/^language(\.dat|\.def|\.dat\.lua)?$/i) {
    if ($opts{"rebuild-sys"} && $opts{"dest"}) {
      tlwarn("$prg generate $what: warning: both --rebuild-sys and --dest\n",
             "given; the call to fmtutil-sys can fail if the given\n",
             "destination is different from the default.\n");
    }
    if ($what =~ m/^language(\.dat\.lua)?$/i) {
      my $dest = $opts{"dest"} ||
        "$TEXMFSYSVAR/tex/generic/config/language.dat.lua";
      $dest .= ".dat.lua" if $append_extension;
      my $localcfg = $opts{"localcfg"} ||
        "$TEXMFLOCAL/tex/generic/config/language-local.dat.lua";
      debug("$prg: writing language.dat.lua data to $dest\n");
      TeXLive::TLUtils::create_language_lua($localtlpdb, $dest, $localcfg);
      if ($opts{"rebuild-sys"}) {
        do_cmd_and_check
                     ("fmtutil-sys $common_fmtutil_args --byhyphen \"$dest\"");
      } else {
        info("To make the newly-generated language.dat.lua take effect,"
             . " run fmtutil-sys --byhyphen $dest.\n"); 
      }
    }
    if ($what =~ m/^language(\.dat)?$/i) {
      my $dest = $opts{"dest"} ||
        "$TEXMFSYSVAR/tex/generic/config/language.dat";
      $dest .= ".dat" if $append_extension;
      my $localcfg = $opts{"localcfg"} ||
        "$TEXMFLOCAL/tex/generic/config/language-local.dat";
      debug ("$prg: writing language.dat data to $dest\n");
      TeXLive::TLUtils::create_language_dat($localtlpdb, $dest, $localcfg);
      if ($opts{"rebuild-sys"}) {
        do_cmd_and_check
                     ("fmtutil-sys $common_fmtutil_args --byhyphen \"$dest\"");
      } else {
        info("To make the newly-generated language.dat take effect,"
             . " run fmtutil-sys --byhyphen $dest.\n"); 
      }
    }
    if ($what =~ m/^language(\.def)?$/i) {
      my $dest = $opts{"dest"} ||
        "$TEXMFSYSVAR/tex/generic/config/language.def";
      $dest .= ".def" if $append_extension;
      my $localcfg = $opts{"localcfg"} ||
        "$TEXMFLOCAL/tex/generic/config/language-local.def";
      debug("$prg: writing language.def data to $dest\n");
      TeXLive::TLUtils::create_language_def($localtlpdb, $dest, $localcfg);
      if ($opts{"rebuild-sys"}) {
        do_cmd_and_check
                     ("fmtutil-sys $common_fmtutil_args --byhyphen \"$dest\"");
      } else {
        info("To make the newly-generated language.def take effect,"
             . " run fmtutil-sys --byhyphen $dest.\n");
      }
    }

  } elsif ($what =~ m/^fmtutil$/i) {
    tlwarn("$prg: generate fmtutil is no longer needed or supported.\n");
    tlwarn("$prg: Please read the documentation of the `fmtutil' program.\n");
    tlwarn("$prg: Goodbye.\n");
    return $F_ERROR;

  } elsif ($what =~ m/^_fmtutil$/i) {
    my $dest = $opts{"dest"} || "$TEXMFDIST/web2c/fmtutil.cnf";
    debug("$prg: writing new fmtutil.cnf to $dest\n");
    TeXLive::TLUtils::create_fmtutil($localtlpdb, $dest);

    if ($opts{"rebuild-sys"}) {
      do_cmd_and_check("fmtutil-sys $common_fmtutil_args --all");
    } else {
      info("To make the newly-generated fmtutil.cnf take effect,"
           . " run fmtutil-sys --all.\n"); 
    }

  } elsif ($what =~ m/^updmap$/i) {
    tlwarn("$prg: generate updmap is no longer needed or supported.\n");
    tlwarn("$prg: Please read the documentation of the `updmap' program.\n");
    tlwarn("$prg: Goodbye.\n");
    return $F_ERROR;

  } elsif ($what =~ m/^_updmap$/i) {
    my $dest = $opts{"dest"} || "$TEXMFDIST/web2c/updmap.cfg";
    debug("$prg: writing new updmap.cfg to $dest\n");
    TeXLive::TLUtils::create_updmap($localtlpdb, $dest);

    if ($opts{"rebuild-sys"}) {
      do_cmd_and_check("updmap-sys");
    } else {
      info("To make the newly-generated updmap.cfg take effect,"
           . " run updmap-sys.\n");
    }

  } else {
    tlwarn("$prg: Unknown option for generate: $what; try --help if you need it.\n");
    return $F_ERROR;
  }

  return $F_OK;
}


sub action_gui {
  eval { require Tk; };
  if ($@) {
    my $tkmissing = 0;
    if ($@ =~ /^Can\'t locate Tk\.pm/) {
      $tkmissing = 1;
    }
    if ($tkmissing) {
      if ($^O =~ /^MSWin/i) {
        require Win32;
        my $msg = "Cannot load Tk, that should not happen as we ship it!\nHow did you start tlmgrgui??\n(Error message: $@)\n";
        Win32::MsgBox($msg, 1|Win32::MB_ICONSTOP(), "Warning");
      } else {
        printf STDERR "
$prg: Cannot load Tk, thus the GUI cannot be started!
The Perl/Tk module is not shipped with the TeX Live installation.
You have to install it to get the tlmgr GUI working.
(INC = @INC)

See https://tug.org/texlive/distro.html#perltk for more details.
Goodbye.
";
      }
    } else {
      printf STDERR "$prg: unexpected problem loading Tk: $@\n";
    }
    exit 1;
  }

  eval { my $foo = Tk::MainWindow->new; $foo->destroy; };
  if ($@) {
    printf STDERR "perl/Tk unusable, cannot create main windows.
That could be a consequence of not having X Windows installed or started!
Error message from creating MainWindow:
  $@
";
    exit 1;
  }

  $::gui_mode = 1;
  $opts{"gui"} = 0;

  require("tlmgrgui.pl");
  exit(1);
}


sub uninstall_texlive {
  if (wndws()) {
    printf STDERR "Please use \"Add/Remove Programs\" from the Control Panel "
                  . "to uninstall TeX Live!\n";
    return ($F_ERROR);
  }
  return if !check_on_writable();

  init_local_db(0);
  if (defined($opts{"dry-run"})) {
    print "Sorry, no --dry-run with remove --all; goodbye.\n";
    return ($F_OK | $F_NOPOSTACTION);
  }
  my $force = defined($opts{"force"}) ? $opts{"force"} : 0;
  my $tlroot = $localtlpdb->root;
  if (!$force) {
    print("If you answer yes here the whole TeX Live installation here,\n",
          "under $tlroot, will be removed!\n");
    print "Remove TeX Live (y/N): ";
    my $yesno = <STDIN>;
    if (!defined($yesno) || $yesno !~ m/^y(es)?$/i) {
      print "Ok, cancelling the removal!\n";
      return ($F_OK | $F_NOPOSTACTION);
    }
  }
  print "Ok, removing the whole TL installation under: $tlroot\n";
  
  chomp (my $texmfsysconfig = `kpsewhich -var-value=TEXMFSYSCONFIG`);
  chomp (my $texmfsysvar = `kpsewhich -var-value=TEXMFSYSVAR`);
  chomp (my $texmfconfig = `kpsewhich -var-value=TEXMFCONFIG`);
  chomp (my $texmfvar = `kpsewhich -var-value=TEXMFVAR`);

  print "symlinks... ";
  TeXLive::TLUtils::remove_symlinks($localtlpdb->root,
    $localtlpdb->platform(),
    $localtlpdb->option("sys_bin"),
    $localtlpdb->option("sys_man"),
    $localtlpdb->option("sys_info"));

  print "main dirs... ";
  system("rm", "-rf", "$Master/texmf-dist");
  system("rm", "-rf", "$Master/texmf-doc");
  system("rm", "-rf", "$Master/texmf-config");
  system("rm", "-rf", "$Master/texmf-var");
  system("rm", "-rf", "$Master/tlpkg");
  system("rm", "-rf", "$Master/bin");

  system("rm", "-rf", "$texmfsysconfig");
  system("rm", "-rf", "$texmfsysvar");

  print "misc... ";
  system("rm", "-rf", "$Master/readme-html.dir");
  system("rm", "-rf", "$Master/readme-txt.dir");
  for my $f (qw/doc.html index.html install-tl install-tl.log
                LICENSE.CTAN LICENSE.TL README README.usergroups
                release-texlive.txt texmf.cnf texmfcnf.lua
               /) {
    system("rm", "-f", "$Master/$f");
  }
  finddepth(sub { rmdir; }, $Master);
  rmdir($Master);
  print "done.\n";
  
  if (-d $texmfconfig || -d $texmfvar) {
    print <<NOT_REMOVED;

User directories intentionally not touched, removing them is up to you:
  TEXMFCONFIG=$texmfconfig
  TEXMFVAR=$texmfvar
NOT_REMOVED
  }

  my $remnants;
  if (-d $Master) {
    print "\nSorry, something did not get removed under: $Master\n";
    $remnants = 1;
  } else {
    $remnants = 0; 
  }
  return $remnants;
}


sub action_recreate_tlpdb {
  return if !check_on_writable();
  my $tlpdb = TeXLive::TLPDB->new;
  $tlpdb->root($Master);
  my $inst = TeXLive::TLPOBJ->new;
  $inst->name("00texlive.installation");
  $inst->category("TLCore");
  my @deps;
  my @archs;
  opendir (DIR, "$Master/bin") || die "opendir($Master/bin) failed: $!";
  my @dirents = readdir (DIR);
  closedir (DIR) || warn "closedir($Master/bin) failed: $!";
  for my $dirent (@dirents) {
    next if $dirent eq ".";
    next if $dirent eq "..";
    next unless -d "$Master/bin/$dirent";
    if (-r "$Master/bin/$dirent/kpsewhich"
        || -r "$Master/bin/$dirent/kpsewhich.exe") {
      push @archs, $dirent;
      debug("$prg: skipping directory $Master/bin/$dirent, no kpsewhich there\n");
    }
  }
  push @deps, "setting_available_architectures:" . join(" ",@archs);
  if (!TeXLive::TLUtils::member(TeXLive::TLUtils::platform(), @archs)) {
    if ($#archs == 0) {
      push @deps, "setting_platform:$archs[0]";
    } else {
      if (defined($opts{"platform"})) {
        if (member($opts{"platform"}, @archs)) {
          push @deps, "setting_platform:" . $opts{"platform"};
        } else {
          tlwarn("$prg: The platform you passed in with --platform is not present in $Master/bin\n");
          tlwarn("$prg: Please specify one of the available ones: @archs\n");
          exit(1);
        }
      } else {
        tlwarn("$prg: More than one platform available: @archs\n");
        tlwarn("$prg: Please pass one as the default you are running on with --platform=...\n");
        exit(1);
      }
    }
  }
  $inst->depends(@deps);
  $tlpdb->add_tlpobj($inst);
  $tlpdb->add_default_options();
  if ($tlpdb->option("location") eq "__MASTER__") {
    $tlpdb->option("location", $TeXLive::TLConfig::TeXLiveURL);
  }
  opendir (DIR, "$Master/tlpkg/tlpobj") or die "opendir($Master/tlpkg/tlpobj) failed: $!";
  my @tlps = readdir(DIR);
  closedir (DIR) || warn "closedir($Master/tlpkg/tlpobj) failed: $!";
  for my $t (@tlps) {
    next if -d $t; # also does . and ..
    next if ($t !~ m/\.tlpobj$/i);
    next if ($t =~ m/\.(source|doc)\.tlpobj$/i);
    my $tlp = TeXLive::TLPOBJ->new;
    $tlp->from_file("$Master/tlpkg/tlpobj/$t");
    $tlpdb->add_tlpobj($tlp);
  }
  &debug("tlmgr:action_recreate_tlpdb: writing out tlpdb\n");
  $tlpdb->writeout;
  return;
}


sub init_tltree {
  my ($svn) = @_;

  my $arch = $localtlpdb->platform();
  if ($arch eq "windows") {
    tldie("$prg: sorry, cannot check this on Windows.\n");
  }

  my $Master = $localtlpdb->root;
  my $tltree = TeXLive::TLTREE->new ("svnroot" => $Master);
  if ($svn) {
    debug("Initializing TLTREE from svn\n");
    $tltree->init_from_svn;
  } else {
    debug("Initializing TLTREE from find\n");
    $tltree->init_from_files;
  }
  return($tltree);
}

sub action_check {
  ddebug("starting action_check\n");
  my $svn = defined($opts{"use-svn"}) ? $opts{"use-svn"} : 0;
  my $what = shift @ARGV;
  $what || ($what = "all");
  $what =~ s/^ *//;
  $what =~ s/ *$//;
  init_local_db();
  my $ret = 0;
  if ($what =~ m/^all$/i) {
    my $tltree = init_tltree($svn);
    print "Running check files:\n";        $ret |= check_files($tltree);
    print "Running check depends:\n";      $ret |= check_depends();
    print "Running check executes:\n";     $ret |= check_executes();
    print "Running check runfiles:\n";     $ret |= check_runfiles();
    print "Running check texmfdbs\n";      $ret |= check_texmfdbs();
  } elsif ($what =~ m/^files$/i) {
    my $tltree = init_tltree($svn);
    $ret |= check_files($tltree);
  } elsif ($what =~ m/^collections$/i) {
    tlwarn("$prg: \"collections\" check has been replaced by \"depends\".\n");
    $ret |= check_depends();
  } elsif ($what =~ m/^depends$/i) {
    $ret |= check_depends();
  } elsif ($what =~ m/^runfiles$/i) {
    $ret |= check_runfiles();
  } elsif ($what =~ m/^executes$/i) {
    $ret |= check_executes();
  } elsif ($what =~ m/^texmfdbs$/i) {
    $ret |= check_texmfdbs();
  } else {
    tlwarn("$prg: No idea how to check: $what\n");
    $ret = 1;
  }
  if ($ret) {
    return ($F_ERROR);
  } else {
    return ($F_OK);
  }
}

sub check_files {
  my $tltree = shift;
  my $ret = 0;
  my %filetopacks;
  my $Master = $localtlpdb->root;
  debug("Collecting all files of all packages\n");
  for my $p ($localtlpdb->list_packages()) {
    next if ($p eq "00texlive.installer");
    my $tlp = $localtlpdb->get_package($p);
    my @files = $tlp->all_files;
    if ($tlp->relocated) {
      for (@files) { s:^$RelocPrefix/:$RelocTree/:; }
    }
    for my $f (@files) {
      push @{$filetopacks{$f}}, $p;
    }
  }
  my @multiple = ();
  my @missing = ();
  debug("Checking for occurrences and existence of all files\n");
  for (keys %filetopacks) {
    push @missing, $_ if (! -r "$Master/$_");
    my @foo = @{$filetopacks{$_}};
    if ($#foo < 0) {
      warn "that shouldn't happen #foo < 0: $_";
    } elsif ($#foo > 0) {
      push @multiple, $_;
    }
  }
  if ($#multiple >= 0) {
    $ret = 1;
    print "\f Multiple included files (relative to $Master):\n";
    for (sort @multiple) {
      my @foo = @{$filetopacks{$_}};
      print "  $_ (@foo)\n";
    }
    print "\n";
  }
  if ($#missing >= 0) {
    $ret = 1;
    print "\f Files mentioned in tlpdb but missing (relative to $Master):\n";
    for my $m (@missing) {
      print "\t$m\n";
    }
    print "\n";
  }

  my @IgnorePatterns = qw!
    release-texlive.txt source/
    texmf-dist/ls-R$ texmf-doc/ls-R$
    tlpkg/archive tlpkg/backups tlpkg/installer
    tlpkg/texlive.tlpdb tlpkg/tlpobj tlpkg/texlive.profile
    texmf-config/ texmf-var/
    texmf.cnf texmfcnf.lua install-tl.log
    tlmgr.log tlmgr-commands.log
  !;
  my %tltreefiles = %{$tltree->{'_allfiles'}};
  my @tlpdbfiles = keys %filetopacks;
  my @nohit;
  for my $f (keys %tltreefiles) {
    if (!defined($filetopacks{$f})) {
      my $ignored = 0;
      for my $p (@IgnorePatterns) {
        if ($f =~ m/^$p/) {
          $ignored = 1;
          last;
        }
      }
      if (!$ignored) {
        push @nohit, $f;
      }
    }
  }
  if (@nohit) {
    $ret = 1;
    print "\f Files present but not covered (relative to $Master):\n";
    for my $f (sort @nohit) {
      print "  $f\n";
    }
    print "\n";
  }
  return($ret);
}

sub check_runfiles {
  my $Master = $localtlpdb->root;

  (my $omit_pkgs = `ls "$Master/bin"`) =~ s/\n/\$|/g; # binaries
  $omit_pkgs .= '^0+texlive|^bin-|^collection-|^scheme-|^texlive-|^texworks';
  $omit_pkgs .= '|^pgf$';           # intentionally duplicated .lua
  $omit_pkgs .= '|^latex-.*-dev$';  # intentionally duplicated base latex
  my @runtime_files = ();
  foreach my $tlpn ($localtlpdb->list_packages) {
    next if $tlpn =~ /$omit_pkgs/;
    my $tlp = $localtlpdb->get_package($tlpn);
    my @files = $tlp->runfiles;
    if ($tlp->relocated) {
      for (@files) { 
        s!^$TeXLive::TLConfig::RelocPrefix/!$TeXLive::TLConfig::RelocTree/!;
      }
    }
    if ($tlpn eq "koma-script") {
      @files = grep { !m;^texmf-dist/source/latex/koma-script/; } @files;
      @files = grep { !m;^texmf-dist/doc/latex/koma-script/; } @files;
    }
    push @runtime_files, @files;
  }

  my @duplicates = (""); # just to use $duplicates[-1] freely
  my $prev = "";
  for my $f (sort map { lc(TeXLive::TLUtils::basename($_)) } @runtime_files) {
    if ($f eq $prev && !($f eq $duplicates[-1])) {
      push(@duplicates, $f);
    }
    $prev = $f;
  }
  shift @duplicates; # get rid of the fake 1st value

  foreach my $f (@duplicates) {
    next if $f =~ /\.(afm|cfg|dll|exe|4hf|htf|pm|xdy)$/;
    next if $f
      =~ /^((czech|slovak)\.sty
            |Changes
            |LICENSE.*
            |Makefile
            |README.*
            |a_.*\.enc
            |cid2code\.txt
            |context\.json
            |etex\.src
            |fithesis.*
            |u?kinsoku\.tex
            |language\.dat
            |language\.def
            |local\.mf
            |m-tex4ht\.tex
            |metatex\.tex
            |.*-noEmbed\.map
            |ps2mfbas\.mf
            |pstricks\.con
            |sample\.bib
            |tex4ht\.env
            |test\.mf
            |texutil\.rb
            |tlmgrgui\.pl
           )$/xi;

    next if $f
      =~ /^( afoot\.sty
            |cherokee\.tfm
            |gamma\.mf
            |lexer\.lua
            |ligature\.mf
            |md-utrma\.pfb
            |ot1\.cmap
            |t1\.cmap
            |ut1omlgc\.fd
           )$/xi;

    my @copies = grep (/\/$f$/i, @runtime_files);
    if ($f =~ /\.map$/) {
      my $need_check = 0;
      my $prev_dir = "";
      my @cop = @copies; # don't break the outside list
      map { s!^texmf-dist/fonts/map/(.*?)/.*!$1!; } @cop;
      foreach my $dir (sort @cop) {
        last if ($need_check = ($dir eq $prev_dir));
        $prev_dir = $dir;
      }
      next unless $need_check;
    }
    my $diff = 0;
    for (my $i = 1; $i < @copies; $i++) {
      next if $copies[$i] =~ m!asymptote/.*\.py$!;
      if ($diff = tlcmp("$Master/$copies[$i-1]", "$Master/$copies[$i]")) {
        print "# $f\ndiff $Master/$copies[$i-1] $Master/$copies[$i]\n";
        last;
      }
    }
    print join ("\n", @copies), "\n" if ($diff and (scalar(@copies) > 2));
  }
}

sub check_executes {
  ddebug("starting check_executes\n");
  my $Master = $localtlpdb->root;
  my (%maps,%langcodes,%fmtlines);
  for my $pkg ($localtlpdb->list_packages) {
    for my $e ($localtlpdb->get_package($pkg)->executes) {
      if ($e =~ m/add(Mixed|Kanji)?Map\s+(.*)$/) {
        my $foo = $2;
        chomp($foo);
        if ($foo !~ m/\@(kanji|ja|tc|sc|ko)Embed@/) {
          push @{$maps{$foo}}, $pkg;
        }
      } elsif ($e =~ m/AddFormat\s+(.*)$/) {
        my $foo = $1;
        chomp($foo);
        push @{$fmtlines{$foo}}, $pkg;
      } elsif ($e =~ m/AddHyphen\s+.*\s+file=(\S+)(\s*$|\s+.*)/) {
        my $foo = $1;
        chomp($foo);
        push @{$langcodes{$foo}}, $pkg;
      } else {
        tlwarn("$prg: unmatched execute in $pkg: $e\n");
      }
    }
  }

  ddebug(" check_executes: checking maps\n");
  my %badmaps;
  foreach my $mf (sort keys %maps) {
    my @pkgsfound = @{$maps{$mf}};
    if ($#pkgsfound > 0) {
      tlwarn("$prg: map file $mf is referenced in the executes of @pkgsfound\n");
    } else {
      my $pkgfoundexecute = $pkgsfound[0];
      my @found = $localtlpdb->find_file($mf);
      if ($#found < 0) {
        $badmaps{$mf} = $maps{$mf};
      } elsif ($#found > 0) {
        my %mapfn;
        foreach my $foo (@found) {
          $foo =~ m/^(.*):(.*)$/;
          push @{$mapfn{$2}}, $1;
        }
        foreach my $k (keys %mapfn) {
          my @bla = @{$mapfn{$k}};
          if ($#bla > 0) {
            tlwarn("$prg: map file $mf occurs multiple times (in pkgs: @bla)!\n");
          }
        }
      } else {
        my ($pkgcontained) = ( $found[0] =~ m/^(.*):.*$/ );
        if ($pkgcontained ne $pkgfoundexecute) {
          tlwarn("$prg: map file $mf: execute in $pkgfoundexecute, map file in $pkgcontained\n");
        }
      }
    }
  }
  if (keys %badmaps) {
    tlwarn("$prg: mentioned map file not present in any package:\n");
    foreach my $mf (keys %badmaps) {
      print "\t$mf (execute in @{$badmaps{$mf}})\n";
    }
  }

  ddebug(" check_executes: checking hyphcodes\n");
  my %badhyphcodes;
  my %problemhyphen;
  foreach my $lc (sort keys %langcodes) {
    next if ($lc eq "zerohyph.tex");
    my @found = $localtlpdb->find_file("texmf-dist/tex/generic/hyph-utf8/loadhyph/$lc");
    if ($#found < 0) {
      my @found = $localtlpdb->find_file("$lc");
      if ($#found < 0) {
        $badhyphcodes{$lc} = $langcodes{$lc};
      } else {
        $problemhyphen{$lc} = [ @found ];
      }
    }
  }
  if (keys %badhyphcodes) {
    print "\f mentioned hyphen loaders without file:\n";
    foreach my $mf (keys %badhyphcodes) {
      print "\t$mf (execute in @{$badhyphcodes{$mf}})\n";
    }
  }

  my %missingbins;
  my %missingengines;
  my %missinginis;
  my @archs_to_check = $localtlpdb->available_architectures;
  ddebug("archs_to_check: @archs_to_check\n");
  for (sort keys %fmtlines) {
    my %r = TeXLive::TLUtils::parse_AddFormat_line($_);
    if (defined($r{"error"})) {
      die "$r{'error'}, parsing $_, package(s) @{$fmtlines{$_}}";
    }
    my $opt = $r{"options"};
    my $engine = $r{"engine"};
    my $name = $r{"name"};
    my $mode = $r{"mode"};
    ddebug("check_executes: fmtline name=$name engine=$engine"
           . " mode=$mode opt=$opt\n");
    next if ($name eq "cont-en"); # too confusing
    if (",$TeXLive::TLConfig::PartialEngineSupport," =~ /,$engine,/) {
      my $pkg;
      if ($engine =~ /luajit(hb)?tex/) {
        $pkg = "luajittex";
      } elsif ($engine eq "mfluajit") {
        $pkg = "mflua";
      } else {
        die "unknown partial engine $engine, goodbye"; # should not happen
      }
      my $tlpsrc_file = $localtlpdb->root . "/tlpkg/tlpsrc/$pkg.tlpsrc";
      if (-r $tlpsrc_file) {
        ddebug("check_executes: found $tlpsrc_file\n");
        require TeXLive::TLPSRC;
        my $tlpsrc = new TeXLive::TLPSRC;
        $tlpsrc->from_file($tlpsrc_file);
        my @binpats = $tlpsrc->binpatterns;
        my @negarchs = ();
        for my $p (@binpats) {
          if ($p =~ m%^(\w+)/(!?[-_a-z0-9,]+)\s+(.*)$%) {
            my $pt = $1;
            my $aa = $2;
            my $pr = $3;
            if ($pr =~ m!/$engine$!) {
              if ($aa =~ m/^!(.*)$/) {
                @negarchs = split(/,/,$1);
                ddebug("check_executes:  negative arches: @negarchs\n");
              }
            }
          }
        }
        my @new_archs = ();
        for my $a (@archs_to_check) {
          push (@new_archs, $a) unless grep { $a eq $_ } @negarchs;
        }
        @archs_to_check = @new_archs;
      } else {
        @archs_to_check = (); # no tlpsrc, check nothing.
      }
      ddebug("check_executes: final arches to check: @archs_to_check\n");
    }
    for my $a (@archs_to_check) {
      my $f = "$Master/bin/$a/$name";
      if (!check_file($a, $f)) {
        push @{$missingbins{$_}}, "bin/$a/${name}[engine=$engine]" if $mode;
      }
      if (!check_file($a, "$Master/bin/$a/$engine")) {
        push @{$missingengines{$_}}, "bin/$a/${engine}[fmt=$name]" if $mode;
      }
    }
    my $inifile = $opt;
    $inifile =~ s/^"(.*)"$/$1/;
    $inifile =~ s/^.* ([^ ]*)$/$1/;
    $inifile =~ s/^\*//;
    my @found = $localtlpdb->find_file("$inifile");
    if ($#found < 0) {
      $missinginis{$_} = "$inifile";
    }
  }
  if (keys %missinginis) {
    print "\f mentioned ini files that cannot be found:\n";
    for my $i (sort keys %missinginis) {
      print "\t $missinginis{$i} (execute: $i)\n";
    }
  }
  if (keys %missingengines) {
    print "\f mentioned engine files that cannot be found:\n";
    for my $i (sort keys %missingengines) {
      print "\t @{$missingengines{$i}}\n";
    }
  }
  if (keys %missingbins) {
    print "\f mentioned bin files that cannot be found:\n";
    for my $i (sort keys %missingbins) {
      print "\t @{$missingbins{$i}}\n";
    }
  }
}

sub check_file {
  my ($a, $f) = @_;
  if (-r $f) {
    return 1;
  } else {
    if ($a =~ /windows|win[0-9]|.*-cygwin/) {
      if (-r "$f.exe" || -r "$f.bat") {
        return 1;
      }
    }
    return 0;
  }
}

sub check_depends {
  my $ret = 0;
  my $Master = $localtlpdb->root;
  my %presentpkg;
  for my $pkg ($localtlpdb->list_packages) {
    $presentpkg{$pkg} = 1;
  }
  my @colls = $localtlpdb->collections;
  my @coll_deps
    = $localtlpdb->expand_dependencies("-no-collections", $localtlpdb, @colls);
  my %coll_deps;
  @coll_deps{@coll_deps} = ();  # initialize hash with keys from list

  my (%wrong_dep, @no_dep);
  for my $pkg ($localtlpdb->list_packages) {
    next if $pkg =~ m/^00texlive/;

    if (! exists $coll_deps{$pkg}) {
      push (@no_dep, $pkg) unless $pkg =~/^scheme-|\.windows$/;
    }

    for my $d ($localtlpdb->get_package($pkg)->depends) {
      next if ($d =~ m/\.ARCH$/);
      if (!defined($presentpkg{$d})) {
        push (@{$wrong_dep{$d}}, $pkg);
      }
    }
  }

  my %pkg2mother;
  for my $c (@colls) {
    for my $p ($localtlpdb->get_package($c)->depends) {
      next if ($p =~ /^collection-/);
      push @{$pkg2mother{$p}}, $c;
    }
  }
  my @double_inc_pkgs;
  for my $k (keys %pkg2mother) {
    if (@{$pkg2mother{$k}} > 1) {
      push @double_inc_pkgs, $k;
    }
  }

  if (keys %wrong_dep) {
    $ret++;
    print "\f DEPENDS WITHOUT PACKAGES:\n";
    for my $d (keys %wrong_dep) {
      print "$d in: @{$wrong_dep{$d}}\n";
    }
  }

  if (@no_dep) {
    $ret++;
    print "\f PACKAGES NOT IN ANY COLLECTION: @no_dep\n";
  }

  if (@double_inc_pkgs) {
    $ret++;
    print "\f PACKAGES IN MORE THAN ONE COLLECTION: @double_inc_pkgs\n";
  }

  return $ret;
}

sub check_texmfdbs {
  my $texmfdbs = `kpsewhich -var-value TEXMFDBS`;
  my @tfmdbs = glob $texmfdbs;
  my $tfms = `kpsewhich -var-value TEXMF`;
  my @tfms = glob $tfms;
  my %tfmdbs;
  my $ret = 0;

  debug("Checking TEXMFDBS\n");
  for my $p (@tfmdbs) {
    debug(" $p\n");
    if ($p !~ m/^!!/) {
      tlwarn("$prg: item $p in TEXMFDBS does not have leading !!\n");
      $ret++;
    }
    $p =~ s/^!!//;
    $tfmdbs{$p} = 1;
    if (-d $p && ! -r "$p/ls-R") {
      tlwarn("$prg: item $p in TEXMFDBS does not have an associated ls-R file\n");
      $ret++;
    }
  }

  debug("Checking TEXMF\n");
  for my $p (@tfms) {
    debug(" $p\n");
    my $pnobang = $p;
    $pnobang =~ s/^!!//;
    if (! $tfmdbs{$pnobang}) {
      if ($p =~ m/^!!/) {
        tlwarn("$prg: tree $p in TEXMF not in TEXMFDBS, but has !!\n");
        $ret++;
      }
      if (-r "$pnobang/ls-R") {
        tlwarn("$prg: tree $p in TEXMF not in TEXMFDBS, but has ls-R file\n");
        $ret++;
      }
    }
  }
  return($ret);
}


sub action_postaction {
  my $how = shift @ARGV;
  if (!defined($how) || ($how !~ m/^(install|remove)$/i)) {
    tlwarn("$prg: action postaction needs at least two arguments, first being either 'install' or 'remove'\n");
    return;
  }
  my $type = shift @ARGV;
  my $badtype = 0;
  if (!defined($type)) {
    $badtype = 1;
  } elsif ($type !~ m/^(shortcut|fileassoc|script)$/i) {
    $badtype = 1;
  }
  if ($badtype) {
    tlwarn("$prg: action postaction needs as second argument one from 'shortcut', 'fileassoc', 'script'\n");
    return;
  }
  if (wndws()) {
    if ($opts{"windowsmode"}) {
      if ($opts{"windowsmode"} eq "user") {
        if (TeXLive::TLWinGoo::admin()) {
          debug("Switching to user mode on user request\n");
          TeXLive::TLWinGoo::non_admin();
        }
        chomp($ENV{"TEXMFSYSVAR"} = `kpsewhich -var-value TEXMFVAR`);
      } elsif ($opts{"windowsmode"} eq "admin") {
        if (!TeXLive::TLWinGoo::admin()) {
          tlwarn("$prg: you don't have permission for --windowsmode=admin\n");
          return;
        }
      } else {
        tlwarn("$prg: action postaction --windowsmode can only be 'admin' or 'user'\n");
        return;
      }
    }
  }
  my @todo;
  if ($opts{"all"}) {
    init_local_db();
    @todo = $localtlpdb->list_packages;
  } else {
    if ($#ARGV < 0) {
      tlwarn("$prg: action postaction: need either --all or a list of packages\n");
      return;
    }
    init_local_db();
    @todo = @ARGV;
    @todo = $localtlpdb->expand_dependencies("-only-arch", $localtlpdb, @todo);
  }
  if ($type =~ m/^shortcut$/i) {
    if (!wndws()) {
      tlwarn("$prg: action postaction shortcut only works on windows.\n");
      return;
    }
    for my $p (@todo) {
      my $tlp = $localtlpdb->get_package($p);
      if (!defined($tlp)) {
        tlwarn("$prg: $p is not installed, ignoring it.\n");
      } else {
        TeXLive::TLUtils::do_postaction($how, $tlp, 0, 1, 1, 0);
      }
    }
  } elsif ($type =~ m/^fileassoc$/i) {
    if (!wndws()) {
      tlwarn("$prg: action postaction fileassoc only works on windows.\n");
      return;
    }
    my $fa = $localtlpdb->option("file_assocs");
    if ($opts{"fileassocmode"}) {
      if ($opts{"fileassocmode"} < 1 || $opts{"fileassocmode"} > 2) {
        tlwarn("$prg: action postaction: value of --fileassocmode can only be 1 or 2\n");
        return;
      }
      $fa = $opts{"fileassocmode"};
    }
    for my $p (@todo) {
      my $tlp = $localtlpdb->get_package($p);
      if (!defined($tlp)) {
        tlwarn("$prg: $p is not installed, ignoring it.\n");
      } else {
        TeXLive::TLUtils::do_postaction($how, $tlp, $fa, 0, 0, 0);
      }
    }
  } elsif ($type =~ m/^script$/i) {
    for my $p (@todo) {
      my $tlp = $localtlpdb->get_package($p);
      if (!defined($tlp)) {
        tlwarn("$prg: $p is not installed, ignoring it.\n");
      } else {
        TeXLive::TLUtils::do_postaction($how, $tlp, 0, 0, 0, 1);
      }
    }
  } else {
    tlwarn("$prg: action postaction needs one of 'shortcut', 'fileassoc', 'script'\n");
    return;
  }
}


sub action_init_usertree {
  init_local_db(2);
  my $tlpdb = TeXLive::TLPDB->new;
  my $usertree;
  if ($opts{"usertree"}) {
    $usertree = $opts{"usertree"};
  } else {
    chomp($usertree = `kpsewhich -var-value TEXMFHOME`);
  }
  if (-r "$usertree/$InfraLocation/$DatabaseName") {
    tldie("$prg: user mode database already set up in\n$prg:   $usertree/$InfraLocation/$DatabaseName\n$prg: not overwriting it.\n");
  }
  $tlpdb->root($usertree);
  my $maininsttlp;
  my $inst;
  if (defined($localtlpdb)) {
    $maininsttlp = $localtlpdb->get_package("00texlive.installation");
    $inst = $maininsttlp->copy;
  } else {
    $inst = TeXLive::TLPOBJ->new;
    $inst->name("00texlive.installation");
    $inst->category("TLCore");
  }
  $tlpdb->add_tlpobj($inst);
  $tlpdb->setting( "available_architectures", "");
  $tlpdb->option( "location", $TeXLive::TLConfig::TeXLiveURL);
  $tlpdb->setting( "usertree", 1 );
  $tlpdb->save;
  mkdir ("$usertree/web2c");
  mkdir ("$usertree/tlpkg/tlpobj");
  return ($F_OK);
}


sub action_conf {
  my $arg = shift @ARGV;
  my $ret = $F_OK;

  if (!defined($arg)) {
    texconfig_conf_mimic();

  } elsif ($arg !~ /^(tlmgr|texmf|updmap|auxtrees)$/) {
    warn "$prg: unknown conf arg: $arg (try tlmgr or texmf or updmap or auxtrees)\n";
    return($F_ERROR);

  } else {
    my ($fn,$cf);
    if ($opts{'conffile'}) {
      $fn = $opts{'conffile'} ;
    }
    if ($arg eq "tlmgr") {
      chomp (my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
      $fn || ( $fn = "$TEXMFCONFIG/tlmgr/config" ) ;
      $cf = TeXLive::TLConfFile->new($fn, "#", "=");
    } elsif ($arg eq "texmf" || $arg eq "auxtrees") {
      $fn || ( $fn = "$Master/texmf.cnf" ) ;
      $cf = TeXLive::TLConfFile->new($fn, "[%#]", "=");
    } elsif ($arg eq "updmap") {
      $fn || ( chomp ($fn = `kpsewhich updmap.cfg`) ) ;
      $cf = TeXLive::TLConfFile->new($fn, '(#|(Mixed)?Map)', ' ');
    } else {
      die "Should not happen, conf arg=$arg";
    }
    my ($key,$val) = @ARGV;
    $key = "show" if ($arg eq "auxtrees" && !defined($key));

    if (!defined($key)) {
      if ($cf) {
        info("$arg configuration values (from $fn):\n");
        for my $k ($cf->keys) {
          info("$k = " . $cf->value($k) . "\n");
        }
      } else {
        info("$prg: $arg config file $fn not present\n");
        return($F_WARNING);
      }
    } else {
      if ($arg eq "auxtrees") {
        my $tmfa = 'TEXMFAUXTREES';
        my $tv = $cf->value($tmfa);
        if (!$key || $key eq "show") {
          if (defined($tv)) {
            $tv =~ s/^\s*//;
            $tv =~ s/\s*$//;
            $tv =~ s/,$//;
            my @foo = split(',', $tv);
            print "List of auxiliary texmf trees:\n" if (@foo);
            for my $f (@foo) {
              print "  $f\n";
            }
            return($F_OK);
          } else {
            print "$prg: no auxiliary texmf trees defined.\n";
            return($F_OK);
          }
        } elsif ($key eq "add") {
          if (defined($val)) {
            if (defined($tv)) {
              $tv =~ s/^\s*//;
              $tv =~ s/\s*$//;
              $tv =~ s/,$//;
              my @foo = split(',', $tv);
              my @new;
              my $already = 0;
              for my $f (@foo) {
                if ($f eq $val) {
                  tlwarn("$prg: already registered auxtree: $val\n");
                  return ($F_WARNING);
                } else {
                  push @new, $f;
                }
              }
              push @new, $val;
              $cf->value($tmfa, join(',', @new) . ',');
            } else {
              $cf->value($tmfa, $val . ',');
            }
          } else {
            tlwarn("$prg: missing argument for auxtrees add\n");
            return($F_ERROR);
          }
        } elsif ($key eq "remove") {
          if (defined($val)) {
            if (defined($tv)) {
              $tv =~ s/^\s*//;
              $tv =~ s/\s*$//;
              $tv =~ s/,$//;
              my @foo = split(',', $tv);
              my @new;
              my $removed = 0;
              for my $f (@foo) {
                if ($f ne $val) {
                  push @new, $f;
                } else {
                  $removed = 1;
                }
              }
              if ($removed) {
                if ($#new >= 0) {
                  $cf->value($tmfa, join(',', @new) . ',');
                } else {
                  $cf->delete_key($tmfa);
                }
              } else {
                tlwarn("$prg: not defined as auxiliary texmf tree: $val\n");
                return($F_WARNING);
              }
            } else {
              tlwarn("$prg: no auxiliary texmf trees defined, "
                     . "so nothing removed\n");
              return($F_WARNING);
            }
          } else {
            tlwarn("$prg: missing argument for auxtrees remove\n");
            return($F_ERROR);
          }
        } else {
          tlwarn("$prg: unknown auxtrees operation: $key\n");
          return($F_ERROR);
        }
      } elsif (!defined($val)) {
        if (defined($opts{'delete'})) {
          if (defined($cf->value($key))) {
            info("$prg: removing setting $arg $key value: " . $cf->value($key)
                 . "from $fn\n"); 
            $cf->delete_key($key);
          } else {
            info("$prg: $arg $key not defined, cannot remove ($fn)\n");
            $ret = $F_WARNING;
          }
        } else {
          if (defined($cf->value($key))) {
            info("$prg: $arg $key value: " . $cf->value($key) . " ($fn)\n");
          } else {
            info("$prg: $key not defined in $arg config file ($fn)\n");
            if ($arg eq "texmf") {
              chomp (my $defval = `kpsewhich -var-value $key`);
              if ($? != 0) {
                info("$prg: $arg $key default value is unknown");
              } else {
                info("$prg: $arg $key default value: $defval");
              }
              info(" (from kpsewhich -var-value)\n");
            }
          }
        }
      } else {
        if (defined($opts{'delete'})) {
          tlwarn("$arg --delete and value for key $key given, don't know what to do!\n");
          $ret = $F_ERROR;
        } else {
          info("$prg: setting $arg $key to $val (in $fn)\n");
          $cf->value($key, $val);
        }
      }
    }
    if ($cf->is_changed) {
      $cf->save;
    }
  }
  return($ret);
}

sub texconfig_conf_mimic {
  my $PATH = $ENV{'PATH'};
  info("=========================== version information ==========================\n");
  info(give_version());
  info("==================== executables found by searching PATH =================\n");
  info("PATH: $PATH\n");
  for my $cmd (sort(qw/kpsewhich updmap fmtutil tlmgr tex pdftex luatex xetex
                  mktexpk dvips dvipdfmx/)) {
    info(sprintf("%-10s %s\n", "$cmd:", TeXLive::TLUtils::which($cmd)));
  }
  info("=========================== active config files ==========================\n");
  for my $m (sort(qw/fmtutil.cnf config.ps mktex.cnf pdftexconfig.tex/)) {
    info(sprintf("%-17s %s", "$m:", `kpsewhich $m` || "(not found!)\n"));
  }
  for my $m (qw/texmf.cnf updmap.cfg/) {
    for my $f (`kpsewhich -all $m`) {
      info(sprintf("%-17s %s", "$m:", $f));
    }
  }


  info("============================= font map files =============================\n");
  for my $m (sort(qw/psfonts.map pdftex.map ps2pk.map kanjix.map/)) {
    info(sprintf("%-12s %s", "$m:", `kpsewhich $m`));
  }

  info("=========================== kpathsea variables ===========================\n");
  for my $v (sort(qw/TEXMFMAIN TEXMFDIST TEXMFLOCAL TEXMFSYSVAR TEXMFSYSCONFIG TEXMFVAR TEXMFCONFIG TEXMFHOME VARTEXFONTS TEXMF SYSTEXMF TEXMFDBS WEB2C TEXPSHEADERS TEXCONFIG ENCFONTS TEXFONTMAPS/)) {
    info("$v=" . `kpsewhich -var-value=$v`);
  }

  info("==== kpathsea variables from environment only (ok if no output here) ====\n");
  my @envVars = qw/
    AFMFONTS BIBINPUTS BSTINPUTS CMAPFONTS CWEBINPUTS ENCFONTS GFFONTS
    GLYPHFONTS INDEXSTYLE LIGFONTS MFBASES MFINPUTS MFPOOL MFTINPUTS
    MISCFONTS MPINPUTS MPMEMS MPPOOL MPSUPPORT OCPINPUTS OFMFONTS
    OPENTYPEFONTS OPLFONTS OTPINPUTS OVFFONTS OVPFONTS PDFTEXCONFIG PKFONTS
    PSHEADERS SFDFONTS T1FONTS T1INPUTS T42FONTS TEXBIB TEXCONFIG TEXDOCS
    TEXFONTMAPS TEXFONTS TEXFORMATS TEXINDEXSTYLE TEXINPUTS TEXMFCNF
    TEXMFDBS TEXMFINI TEXMFSCRIPTS TEXPICTS TEXPKS TEXPOOL TEXPSHEADERS
    TEXSOURCES TFMFONTS TRFONTS TTFONTS VFFONTS WEB2C WEBINPUTS
  /;
  for my $v (@envVars) {
    if (defined($ENV{$v})) {
      info("$v=$ENV{$v}\n");
    }
  }
}


sub action_key {
  my $arg = shift @ARGV;

  if (!defined($arg)) {
    tlwarn("missing arguments to action `key'\n");
    return $F_ERROR;
  }

  $arg = lc($arg);
  if ($arg =~ /^(add|remove|list)$/) {
    handle_gpg_config_settings();
    if (!$::gpg) {
      tlwarn("gnupg is not found or not set up, cannot continue with action `key'\n");
      return $F_ERROR;
    }
    chomp (my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
    my $local_keyring = "$Master/tlpkg/gpg/repository-keys.gpg";
    if ($arg eq 'list') {
      debug("running: $::gpg --list-keys\n");
      system("$::gpg --list-keys");
      return $F_OK;
    } elsif ($arg eq 'remove') {
      my $what = shift @ARGV;
      if (!$what) {
        tlwarn("missing argument to `key remove'\n");
        return $F_ERROR;
      }
      if (! -r $local_keyring) {
        tlwarn("no local keyring available, cannot remove!\n");
        return $F_ERROR;
      }
      debug("running: $::gpg --primary-keyring repository-keys.gpg  --delete-key $what\n");
      my ($out, $ret) = 
          TeXLive::TLUtils::run_cmd("$::gpg --primary-keyring repository-keys.gpg --delete-key \"$what\" 2>&1");
      if ($ret == 0) {
        info("$prg: key successfully removed\n");
        return $F_OK;
      } else {
        tlwarn("$prg: key removal failed, output:\n$out\n");
        return $F_ERROR;
      }
      
    } elsif ($arg eq 'add') {
      my $what = shift @ARGV;
      if (!$what) {
        tlwarn("$prg: missing argument to `key add'\n");
        return $F_ERROR;
      }
      if (! -r $local_keyring) {
        open(FOO, ">$local_keyring") || die("Cannot create $local_keyring: $!");
        close(FOO);
      }
      debug("running: $::gpg --primary-keyring repository-keys.gpg  --import $what\n");
      my ($out, $ret) = 
          TeXLive::TLUtils::run_cmd("$::gpg --primary-keyring repository-keys.gpg  --import \"$what\" 2>&1");
      if ($ret == 0) {
        info("$prg: key successfully imported\n");
        return $F_OK;
      } else {
        tlwarn("$prg: key import failed, output:\n$out\n");
        return $F_ERROR;
      }
    } else {
      tldie("$prg: should not be reached: tlmgr key $arg\n");
    }
    
  } else {
    tlwarn("$prg: unknown directive `$arg' to action `key'\n");
    return $F_ERROR;
  }
  return $F_OK;
}


sub action_shell {
  my $protocol = 1;
  my $default_prompt = "tlmgr>";
  my @valid_bool_keys
    = qw/debug-translation machine-readable no-execute-actions
         verify-repo json/;  
  my @valid_string_keys = qw/repository prompt/;
  my @valid_keys = (@valid_bool_keys, @valid_string_keys);
  $| = 1;
  my $do_prompt;
  $do_prompt = sub {
    my $prompt = "";
    my @options;
    my @guarantee;
    my @savedargs = @_;
    my $did_prompt = 0;
    while (defined(my $arg = shift @_)) {
      if ($arg =~ m/^-prompt$/) {
        if (!$::machinereadable) {
          print shift @_, " ";
          $did_prompt = 1;
        }
      } elsif ($arg =~ m/^-menu$/) {
        my $options = shift @_;
        @options = @$options;
        print "\n";
        my $c = 1;
        for my $o (@options) {
          print " $c) $o\n";
          $c++;
        }
      } elsif ($arg =~ m/^-guarantee$/) {
        my $guarantee = shift @_;
        @guarantee = @$guarantee;
      } elsif ($arg =~ m/^-/) {
        print "ERROR unsupported prompt command, please report: $arg!\n";
      } else {
        if (!$::machinereadable) {
          print $arg, " ";
          $did_prompt = 1;
        }
      }
    }
    print "$default_prompt " if (!$did_prompt);
    print "\n" if $::machinereadable;
    my $ans = <STDIN>;
    if (!defined($ans)) {
      return;
    }
    chomp($ans);
    if (@options) {
      if ($ans =~ /^[0-9]+$/ && 0 <= $ans - 1 && $ans - 1 <= $#options) {
        $ans = $options[$ans - 1];
      } else {
        print "ERROR invalid answer $ans\n";
        $ans = "";
      }
    }
    if (@guarantee) {
      my $isok = 0;
      for my $g (@guarantee) {
        if ($ans eq $g) {
          $isok = 1;
          last;
        }
      }
      if (!$isok) {
        print("Please answer one of: @guarantee\n");
        print "\n" if $::machinereadable;
        return(&$do_prompt(@savedargs));
      }
    }
    return($ans);
  };

  print "protocol $protocol\n";
  while (1) {
    my $ans = &$do_prompt($default_prompt);
    return $F_OK if !defined($ans); # done if eof

    my ($cmd, @args) = TeXLive::TLUtils::quotewords('\s+', 0, $ans);
    next if (!defined($cmd));
    if ($cmd eq "protocol") {
      print "protocol $protocol\n";
    } elsif ($cmd eq "help") {
      print "Please see tlmgr help or https://tug.org/texlive/tlmgr.html.\n";
    } elsif ($cmd eq "version") {
      print give_version();
    } elsif ($cmd =~ m/^(quit|end|bye(bye)?)$/i) {
      return $F_OK;
    } elsif ($cmd eq "setup-location") {
      my $dest = shift @args;
      print "ERROR not implemented: $cmd\n";
    } elsif ($cmd eq "restart") {
      exec("tlmgr", @::SAVEDARGV);

    } elsif ($cmd =~ m/^(set|get)$/) {
      my $key = shift @args;
      my $val = shift @args;
      if (!$key) {
        $key = &$do_prompt('Choose one of...', -menu => \@valid_keys, '>');
      }
      if (!$key) {
        print("ERROR missing key argument for get/set\n");
        next;
      }
      if ($cmd eq "get" && defined($val)) {
        print("ERROR argument not allowed for get: $val\n");
        next;
      }
      if ($cmd eq "set" && !defined($val)) {
        if ($key eq "repository") {
          $val = &$do_prompt('Enter repository:');
        } elsif ($key eq "prompt") {
          $val = &$do_prompt('Enter new prompt:');
        } else {
          $val = &$do_prompt('Enter 1 for on, 0 for off:', -guarantee => [0,1]);
        }
        if (!defined($val)) {
          print("ERROR missing value for set\n");
          next;
        }
      }

      if ($key eq "repository") {
        if ($cmd eq "set") {
          $location = scalar($val);
        } else {
          if (defined($location) && $location) {
            print "repository = $location\n";
          } else {
            print "repository = <UNDEFINED>\n";
          }
        }
        print "OK\n";
      } elsif ($key eq "prompt") {
        if ($cmd eq "set") {
          $default_prompt = scalar($val);
        } else {
          print "Current prompt: $default_prompt (but you know that, or?)\n";
        }
        print "OK\n";
      } elsif (TeXLive::TLUtils::member($key, @valid_bool_keys)) {
        if ($cmd eq "set") {
          if ($val eq "0") {
            $opts{$key} = 0;
          } elsif ($val eq "1") {
            $opts{$key} = 1;
          } else {
            print "ERROR invalid value $val for key $key\n";
            next;
          }
          $::debug_translation = $opts{"debug-translation"};
          $::machinereadable = $opts{"machine-readable"};
          $::no_execute_actions = $opts{'no-execute-actions'};
        } else {
          print "$key = ", ($opts{$key} ? 1 : 0), "\n";
        }
        print "OK\n";
      } else {
        print "ERROR unknown get/set key $key\n";
      }
    } elsif ($cmd eq "load") {
      my $what = shift @args;
      if (!defined($what)) {
        $what = &$do_prompt("Choose...", -menu => ['local', 'remote'], '>');
      }
      if ($what eq "local") {
        init_local_db();
        print "OK\n";
      } elsif ($what eq "remote") {
        my ($ret, $err) = init_tlmedia();
        if ($ret) {
          print("OK\n");
        } else {
          if ($::machinereadable) {
            $err =~ s/\n/\\n/g;
          }
          print("ERROR $err\n");
        }
      } else {
        print "ERROR can only load 'local' or 'remote', not $what\n";
      }
    } elsif ($cmd eq "save") {
      $localtlpdb->save;
      print "OK\n";
    } elsif (defined($action_specification{$cmd})) {
      if (!defined($action_specification{$cmd}{"function"})) {
        print "ERROR undefined action function $cmd\n";
        next;
      }
      my %optarg;
      for my $k (@valid_bool_keys) {
        if ($globaloptions{$k} eq "1") {
          $optarg{$k} = 1;
        } else {
          $optarg{"$k" . $globaloptions{$k}} = 1;
        }
      }
      if (defined($action_specification{$cmd}{'options'})) {
        my %actopts = %{$action_specification{$cmd}{'options'}};
        for my $k (keys %actopts) {
          if ($actopts{$k} eq "1") {
            $optarg{$k} = 1;
          } else {
            $optarg{"$k" . $actopts{$k}} = 1;
          }
        }
      }
      @ARGV = @args;
      my %savedopts = %opts;
      %opts = ();
      for my $k (@valid_keys) {
        $opts{$k} = $savedopts{$k} if (exists($savedopts{$k}));
      }
      if (!GetOptions(\%opts, keys(%optarg))) {
        print "ERROR unsupported arguments\n";
        next;
      }
      my $ret = execute_action($cmd, @ARGV);
      if ($ret & $F_ERROR) {
        print "ERROR\n";
      } elsif ($ret & $F_WARNING) {
        print "OK\n";
      } else {
        print "OK\n";
      }
      if (($cmd eq 'update') && $opts{'self'} && !$opts{'no-restart'}) {
        print "tlmgr has been updated, restarting!\n";
        exec("tlmgr", @::SAVEDARGV);
      }
      %opts = %savedopts;
    } else {
      print "ERROR unknown command $cmd\n";
    }
  }
}



sub init_local_db {
  my ($should_i_die) = @_;
  defined($should_i_die) or ($should_i_die = 0);
  return if defined $localtlpdb;
  $localtlpdb = TeXLive::TLPDB->new ( root => $::maintree );
  if (!defined($localtlpdb)) {
    if ($should_i_die == 2) {
      return undef;
    } else {
      die("cannot setup TLPDB in $::maintree");
    }
  }
  if (!setup_programs("$Master/tlpkg/installer", $localtlpdb->platform)) {
    tlwarn("$prg: Couldn't set up the necessary programs.\nInstallation of packages is not supported.\nPlease report to texlive\@tug.org.\n");
    if (defined($should_i_die) && $should_i_die) {
      die("$prg: no way to continue!\n");
    } else {
      tlwarn("$prg: Continuing anyway ...\n");
      return ($F_WARNING);
    }
  }
  my $loc = norm_tlpdb_path($localtlpdb->option("location"));
  if (defined($loc)) {
    $location = $loc;
  }
  if (defined($opts{"location"})) {
    $location = $opts{"location"};
  }
  if (!defined($location)) {
    die("$prg: No installation source found: neither in texlive.tlpdb nor on command line.\n$prg: Please specify one!");
  }
  if ($location =~ m/^ctan$/i) {
    $location = "$TeXLive::TLConfig::TeXLiveURL";
  }
  if (! ( $location =~ m!^(https?|ftp)://!i  || 
          $location =~ m!$TeXLive::TLUtils::SshURIRegex!i ||
          (wndws() && (!(-e $location) || ($location =~ m!^.:[\\/]!) ) ) ) ) {
    my $testloc = abs_path($location);
    $location = $testloc if $testloc;
  }
}

sub handle_gpg_config_settings {
  my $do_setup_gpg = "main";
  if (defined($config{'verify-repo'})) {
    $do_setup_gpg = $config{'verify-repo'};
  }
  if (defined($opts{'verify-repo'})) {
    $do_setup_gpg = $opts{'verify-repo'};
  }
  if ($do_setup_gpg ne "none") {
    if (TeXLive::TLCrypto::setup_gpg($Master)) {
      debug("will verify cryptographic signatures\n")
    } else {
      my $prefix = "$prg: No gpg found"; # just to shorten the strings
      if (defined($opts{'verify-repo'}) && $opts{'verify-repo'} eq "all") {
        tldie("$prefix, verification explicitly requested on command line, quitting.\n");
      }
      if (defined($config{'verify-repo'}) && $config{'verify-repo'} eq "all") {
        tldie("$prefix, verification explicitly requested in config file, quitting.\n");
      }
      debug ("$prefix, verification implicitly requested, "
             . "continuing without verification\n");
    }
  } else {
    my $prefix = "$prg: not setting up gpg";
    if (defined($opts{'verify-repo'})) {
      debug("$prefix, requested on command line\n");
    } elsif (defined($config{'verify-repo'})) {
      debug("$prefix, requested in config file\n");
    } else {
      tldie("$prg: how could this happen? gpg setup.\n");
    }
  }
}

sub init_tlmedia_or_die {
  my $silent = shift;
  $silent = ($silent ? 1 : 0);
  my ($ret, $err) = init_tlmedia($silent);
  if (!$ret) {
    tldie("$prg: $err\n");
  }
}

sub init_tlmedia {
  my $silent = shift;
  my %repos = repository_to_array($location);
  my @tags = keys %repos;
  if ($#tags == 0 && ($location =~ m/#/)) {
    $location = $repos{$tags[0]};
    $localtlpdb->option("location", $location);
    $localtlpdb->save;
    %repos = repository_to_array($location);
  }

  if (TeXLive::TLCrypto::setup_checksum_method()) {
    handle_gpg_config_settings();
  } else {
    if (!$config{'no-checksums'}) {
      tlwarn(<<END_NO_CHECKSUMS);
$prg: warning: Cannot find a checksum implementation.
Please install Digest::SHA (from CPAN), openssl, or sha512sum.
To silence this warning, set no-checksums in the tlmgr configuration
file, e.g., by running:
  tlmgr conf tlmgr no-checksums 1
Continuing without checksum verifications ...

END_NO_CHECKSUMS
    }
  }

  if ($#tags == 0) {
    return _init_tlmedia($silent);
  }

  if (!TeXLive::TLUtils::member('main', @tags)) {
    return(0, "Cannot find main repository, you have to tag one as main!");
  }

  $remotetlpdb = TeXLive::TLPDB->new();
  $remotetlpdb->make_virtual;

  my $locstr = $repos{'main'};
  my ($tlmdb, $errormsg) = setup_one_remotetlpdb($locstr, 'main');
  if (!defined($tlmdb)) {
    return (0, $errormsg);
  }
  $remotetlpdb->virtual_add_tlpdb($tlmdb, "main");
  for my $t (@tags) {
    if ($t ne 'main') {
      my ($tlmdb, $errormsg) = setup_one_remotetlpdb($repos{$t});
      if (!defined($tlmdb)) {
        return(0, $errormsg);
      }
      $remotetlpdb->virtual_add_tlpdb($tlmdb, $t);
      $locstr .= " $repos{$t}";
    }
  }

  if (!$opts{"pin-file"}) {
    chomp (my $TEXMFLOCAL = `kpsewhich -var-value=TEXMFLOCAL`);
    debug("trying to load pinning file $TEXMFLOCAL/tlpkg/pinning.txt\n");
    $opts{"pin-file"} = "$TEXMFLOCAL/tlpkg/pinning.txt";
  }
  $pinfile = TeXLive::TLConfFile->new($opts{"pin-file"}, "#", ":", 'multiple');
  $remotetlpdb->virtual_pinning($pinfile);
  if ($::machinereadable && !$silent) {
    print "location-url\t$locstr\n";
    return 1;
  }
  if ($silent) {
    return 1;
  }
  info("$prg: package repositories\n");
  my $show_verification_page_link = 0;
  my $verstat = "";
  if (!$remotetlpdb->virtual_get_tlpdb('main')->is_verified) {
    $show_verification_page_link = 1;
    $verstat = ": ";
    $verstat .= $VerificationStatusDescription{$remotetlpdb->virtual_get_tlpdb('main')->verification_status};
  }
  info("\tmain = " . $repos{'main'} . " (" . 
    ($remotetlpdb->virtual_get_tlpdb('main')->is_verified ? "" : "not ") .
    "verified$verstat)\n");
  for my $t (@tags) {
    if ($t ne 'main') {
      $verstat = "";
      if (!$remotetlpdb->virtual_get_tlpdb($t)->is_verified) {
        my $tlpdb_ver_stat = $remotetlpdb->virtual_get_tlpdb($t)->verification_status;
        $verstat = ": ";
        $verstat .= $VerificationStatusDescription{$tlpdb_ver_stat};
        if ($tlpdb_ver_stat != $VS_UNSIGNED) {
          $show_verification_page_link = 1;
        }
      }
      info("\t$t = " . $repos{$t} . " (" .
        ($remotetlpdb->virtual_get_tlpdb($t)->is_verified ? "" : "not ") .
        "verified$verstat)\n");
    }
  }
  if ($show_verification_page_link) {
    info("For more about verification, see https://texlive.info/verification.html.\n");
  }
  return 1;
}

sub _init_tlmedia {
  my $silent = shift;
  if (defined($remotetlpdb) && !$remotetlpdb->is_virtual &&
      ($remotetlpdb->root eq $location)) {
    return 1;
  }

  if ($location =~ m/^ctan$/i) {
    $location = give_ctan_mirror();
  } elsif ($location =~ m,^$TeXLiveServerURLRegexp,) {
    my $mirrorbase = TeXLive::TLUtils::give_ctan_mirror_base();
    $location =~ s,^$TeXLiveServerURLRegexp,$mirrorbase,;
  }

  my $errormsg;
  ($remotetlpdb, $errormsg) = setup_one_remotetlpdb($location, 'main');
  if (!defined($remotetlpdb)) {
    return(0, $errormsg);
  }

  return 1 if ($silent);


  if ($::machinereadable) {
    print "location-url\t$location\n";
  } else {
    my $verstat = "";
    if (!$remotetlpdb->is_verified) {
      $verstat = ": ";
      $verstat .= $VerificationStatusDescription{$remotetlpdb->verification_status};
    }
    info("$prg: package repository $location (" . 
      ($remotetlpdb->is_verified ? "" : "not ") . "verified$verstat)\n");
  }
  return 1;
}

sub setup_one_remotetlpdb {
  my $location = shift;
  my $addarg = shift;
  my $is_main = ((defined($addarg) && ($addarg eq 'main')) ? 1 : 0);
  my $remotetlpdb;


  if ($location =~ m/^ctan$/i) {
    $location = give_ctan_mirror();
  } elsif ($location =~ m,^$TeXLiveServerURLRegexp,) {
    my $mirrorbase = TeXLive::TLUtils::give_ctan_mirror_base();
    $location =~ s,^$TeXLiveServerURLRegexp,$mirrorbase,;
  }

  info("start load $location\n") if ($::machinereadable);

  my $local_copy_tlpdb_used = 0;
  if ($location =~ m;^(https?|ftp)://;) {
    my $loc_digest = TeXLive::TLCrypto::tl_short_digest($location);
    my $loc_copy_of_remote_tlpdb =
      ($is_main ? 
        "$Master/$InfraLocation/texlive.tlpdb.main.$loc_digest" :
        "$Master/$InfraLocation/texlive.tlpdb.$loc_digest");
    ddebug("loc_digest = $loc_digest\n");
    ddebug("loc_copy = $loc_copy_of_remote_tlpdb\n");
    if (-r $loc_copy_of_remote_tlpdb) {
      ddebug("loc copy found!\n");
      my $path = "$location/$InfraLocation/$DatabaseName";
      ddebug("remote path of digest = $path\n");
      my ($verified, $status)
        = TeXLive::TLCrypto::verify_checksum_and_check_return($loc_copy_of_remote_tlpdb, $path,
            $is_main, 1); # the 1 means local copy mode!
      if ($status == $VS_CONNECTION_ERROR) {
        info(<<END_NO_INTERNET);
Unable to download the checksum of the remote TeX Live database,
but found a local copy, so using that.

You may want to try specifying an explicit or different CTAN mirror,
or maybe you need to specify proxy information if you're behind a firewall;
see the information and examples for the -repository option at
https://tug.org/texlive/doc/install-tl.html
(and in the output of install-tl --help).

END_NO_INTERNET
        $remotetlpdb = TeXLive::TLPDB->new(root => $location,
          tlpdbfile => $loc_copy_of_remote_tlpdb);
        $local_copy_tlpdb_used = 1;
      } elsif ($status == $VS_VERIFIED || $status == $VS_EXPKEYSIG || $status == $VS_REVKEYSIG) {
        $remotetlpdb = TeXLive::TLPDB->new(root => $location,
          tlpdbfile => $loc_copy_of_remote_tlpdb);
        $local_copy_tlpdb_used = 1;
        $remotetlpdb->verification_status($status);
        $remotetlpdb->is_verified($verified);
      }
    }
  }
  if (!$local_copy_tlpdb_used) {
    $remotetlpdb = TeXLive::TLPDB->new(root => $location, verify => 1);
    if ($is_main && $remotetlpdb) {
      if ($remotetlpdb->verification_status == $VS_UNSIGNED) {
        tldie("$prg: main database at $location is not signed\n");
      }
    }
  }
  if (!defined($remotetlpdb)) {
    info("fail load $location\n") if ($::machinereadable);
    return(undef, $loadmediasrcerror . $location);
  }
  if ($opts{"require-verification"} && !$remotetlpdb->is_verified) {
    info("fail load $location\n") if ($::machinereadable);
    tldie("Remote TeX Live database ($location) is not verified, exiting.\n");
  }

  my $texlive_release = $remotetlpdb->config_release;
  my $texlive_minrelease = $remotetlpdb->config_minrelease;
  my $rroot = $remotetlpdb->root;
  if (!defined($texlive_release)) {
    info("fail load $location\n") if ($::machinereadable);
    return(undef, "The installation repository ($rroot) does not specify a "
          . "release year for which it was prepared, goodbye.");
  }
  my $texlive_release_year = $texlive_release;
  $texlive_release_year =~ s/^(....).*$/$1/;
  if ($texlive_release_year !~ m/^[1-9][0-9][0-9][0-9]$/) {
    info("fail load $location\n") if ($::machinereadable);
    return(undef, "The installation repository ($rroot) does not specify a "
          . "valid release year, goodbye: $texlive_release");
  }
  if (defined($texlive_minrelease)) {
    my $texlive_minrelease_year = $texlive_minrelease;
    $texlive_minrelease_year =~ s/^(....).*$/$1/;
    if ($texlive_minrelease_year !~ m/^[1-9][0-9][0-9][0-9]$/) {
      info("fail load $location\n") if ($::machinereadable);
      return(undef, "The installation repository ($rroot) does not specify a "
            . "valid minimal release year, goodbye: $texlive_minrelease");
    }
    if ($TeXLive::TLConfig::ReleaseYear < $texlive_minrelease_year
        || $TeXLive::TLConfig::ReleaseYear > $texlive_release_year) {
      info("fail load $location\n") if ($::machinereadable);
      return (undef, "The TeX Live versions supported by the repository
$rroot
  ($texlive_minrelease_year--$texlive_release_year)
do not include the version of the local installation
  ($TeXLive::TLConfig::ReleaseYear).");
    }
    if ($is_main && $TeXLive::TLConfig::ReleaseYear < $texlive_release_year) {
      if (length($texlive_release) > 4) {
        debug("Accepting a newer release as remote due to presence of release extension!\n");
      } else {
        info("fail load $location\n") if ($::machinereadable);
        return (undef, "Local TeX Live ($TeXLive::TLConfig::ReleaseYear)"
                . " is older than remote repository ($texlive_release_year).\n"
                . "Cross release updates are only supported with\n"
                . "  update-tlmgr-latest(.sh/.exe) --update\n"
                . "See https://tug.org/texlive/upgrade.html for details.")
      }
    }
  } else {
    if ($texlive_release_year != $TeXLive::TLConfig::ReleaseYear) {
      info("fail load $location\n") if ($::machinereadable);
      return(undef, "The TeX Live versions of the local installation
and the repository are not compatible:
      local: $TeXLive::TLConfig::ReleaseYear
 repository: $texlive_release_year ($rroot)
(Perhaps you need to use a different CTAN mirror? Just a guess.)");
    }
  }

  if ($is_main) {
    my $rtlp = $remotetlpdb->get_package("texlive-scripts");
    my $ltlp = $localtlpdb->get_package("texlive-scripts");
    my $local_revision;
    my $remote_revision;
    if (!defined($rtlp)) {
      debug("Remote database does not contain the texlive-scripts package, "
            . "skipping version consistency check\n");
      $remote_revision = 0;
    } else {
      $remote_revision = $rtlp->revision;
    }
    if (!defined($ltlp)) {
      info("texlive-scripts package not found (?!), "
           . "skipping version consistency check\n");
      $local_revision = 0;
    } else {
      $local_revision = $ltlp->revision;
    }
    debug("texlive-scripts remote revision $remote_revision, "
          . "texlive-scripts local revision $local_revision\n");
    if ($remote_revision > 0 && $local_revision > $remote_revision) {
      info("fail load $location\n") if ($::machinereadable);
      return(undef, <<OLD_REMOTE_MSG);
Remote database (revision $remote_revision of the texlive-scripts package)
seems to be older than the local installation (rev $local_revision of
texlive-scripts); please use a different mirror and/or wait a day or two.
OLD_REMOTE_MSG
    }
  }

  if ($remotetlpdb->config_frozen) {
    my $frozen_msg = <<FROZEN_MSG;
TeX Live $TeXLive::TLConfig::ReleaseYear is frozen
and will no longer be routinely updated.  This happens when a new
release is made, or will be made shortly.

For general status information about TeX Live, see its home page:
https://tug.org/texlive

FROZEN_MSG
    tlwarn($frozen_msg);
  }

  if (!$local_copy_tlpdb_used && $location =~ m;^(https?|ftp)://;) {
    my $loc_digest = TeXLive::TLCrypto::tl_short_digest($location);
    my $loc_copy_of_remote_tlpdb =
      ($is_main ? 
        "$Master/$InfraLocation/texlive.tlpdb.main.$loc_digest" :
        ($location =~ m;texlive/tlcontrib/?$; ?
          "$Master/$InfraLocation/texlive.tlpdb.tlcontrib.$loc_digest" :
          "$Master/$InfraLocation/texlive.tlpdb.$loc_digest"));
    my $tlfh;
    if (!open($tlfh, ">:unix", $loc_copy_of_remote_tlpdb)) {
      &debug("Cannot save remote TeX Live database to $loc_copy_of_remote_tlpdb: $!\n");
    } else {
      &debug("tlmgr:setup_one_remote_tlpdb: writing out remote tlpdb to $loc_copy_of_remote_tlpdb\n");
      $remotetlpdb->writeout($tlfh);
      close($tlfh);
      if ($is_main) {
        for my $fn (<"$Master/$InfraLocation/texlive.tlpdb.main.*">) {
          next if ($fn eq $loc_copy_of_remote_tlpdb);
          unlink($fn);
        }
      }
      if ($location =~ m;texlive/tlcontrib/?$;) {
        for my $fn (<"$Master/$InfraLocation/texlive.tlpdb.tlcontrib.*">) {
          next if ($fn eq $loc_copy_of_remote_tlpdb);
          unlink($fn);
        }
      }
    }
  }

  info("finish load $location\n") if ($::machinereadable);
  return($remotetlpdb);
}



sub finish {
  my ($ret) = @_;

  if ($ret > 0) {
    print "$prg: exiting unsuccessfully (status $ret).\n";
  }

  if ($::gui_mode) {
    return $ret;
  } else {
    exit($ret);
  }
}


sub load_config_file {
  $config{"gui-expertmode"} = 1;
  $config{"auto-remove"} = 1;
  $config{"persistent-downloads"} = 1;
  $config{"verify-repo"} = "main";

  chomp (my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
  my $fnsys = "$TEXMFSYSCONFIG/tlmgr/config";
  my $tlmgr_sys_config_file = TeXLive::TLConfFile->new($fnsys, "#", "=");
  load_options_from_config($tlmgr_sys_config_file, 'sys') 
    if $tlmgr_sys_config_file;

  chomp (my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
  my $fn = "$TEXMFCONFIG/tlmgr/config";
  $tlmgr_config_file = TeXLive::TLConfFile->new($fn, "#", "=");
  load_options_from_config($tlmgr_config_file) if $tlmgr_config_file;

  $config{"verify-repo"}
    = convert_crypto_options($config{"verify-downloads"},
                             $config{"require-verification"},
                             $config{"verify-repo"});
  delete $config{"require-verification"};
  delete $config{"verify-downloads"};

  if (!defined($opts{"require-verification"})) {
    $opts{"require-verification"} = $config{"require-verification"};
  }
  if (!defined($opts{"persistent-downloads"})) {
    $opts{"persistent-downloads"} = $config{"persistent-downloads"};
  }

  if ($tlmgr_config_file->key_present("gui_expertmode")) {
    $tlmgr_config_file->rename_key("gui_expertmode", "gui-expertmode");
  }
}

sub load_options_from_config {
  my ($tlmgr_config_file, $sysmode) = @_;
  my $fn = $tlmgr_config_file->file;
  for my $key ($tlmgr_config_file->keys) {
    my $val = $tlmgr_config_file->value($key);
    if ($key eq "gui-expertmode") {
      if ($val eq "0") {
        $config{"gui-expertmode"} = 0;
      } elsif ($val eq "1") {
        $config{"gui-expertmode"} = 1;
      } else {
        tlwarn("$prg: $fn: unknown value for gui-expertmode: $val\n");
      }

    } elsif ($key eq "persistent-downloads") {
      if (($val eq "0") || ($val eq "1")) {
        $config{'persistent-downloads'} = $val;
      } else {
        tlwarn("$prg: $fn: unknown value for persistent-downloads: $val\n");
      }

    } elsif ($key eq "update-exclude") {
      my @exs = split(/,/, $val);
      $config{'update-exclude'} = \@exs;

    } elsif ($key eq "gui-lang") {
      $config{'gui-lang'} = $val;

    } elsif ($key eq "auto-remove") {
      if ($val eq "0") {
        $config{"auto-remove"} = 0;
      } elsif ($val eq "1") {
        $config{"auto-remove"} = 1;
      } else {
        tlwarn("$prg: $fn: unknown value for auto-remove: $val\n");
      }

    } elsif ($key eq "require-verification") {
      if ($val eq "0") {
        $config{"require-verification"} = 0;
      } elsif ($val eq "1") {
        $config{"require-verification"} = 1;
      } else {
        tlwarn("$prg: $fn: unknown value for require-verification: $val\n");
      }

    } elsif ($key eq "verify-downloads") {
      if ($val eq "0") {
        $config{"verify-downloads"} = 0;
      } elsif ($val eq "1") {
        $config{"verify-downloads"} = 1;
      } else {
        tlwarn("$prg: $fn: unknown value for verify-downloads: $val\n");
      }

    } elsif ($key eq "verify-repo") {
      if ($val =~ m/$allowed_verify_args_regex/) {
        $config{"verify-repo"} = $val;
      } else {
        tlwarn("$prg: $fn: unknown value for verify-repo: $val\n");
      }

    } elsif ($key eq "no-checksums") {
      if ($val eq "1") {
        $config{"no-checksums"} = 1;
      } elsif ($val eq "0") {
        $config{"no-checksums"} = 0;
      } else {
        tlwarn("$prg: $fn: unknown value for no-checksums: $val\n");
      }

    } elsif ($key eq "tkfontscale") {
      $config{'tkfontscale'} = $val;

    } elsif ($sysmode) {
      if ($key eq "allowed-actions") {
        my @acts = split(/,/, $val);
        $config{'allowed-actions'} = \@acts;
      } else {
        tlwarn("$prg: $fn: unknown tlmgr configuration variable: $key\n");
      }
    } else {
      tlwarn("$prg: $fn: unknown tlmgr configuration variable: $key\n");
    }
  }
}

sub write_config_file {
  if (!defined($tlmgr_config_file)) {
    chomp (my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
    my $dn = "$TEXMFCONFIG/tlmgr";
    my $fn = "$dn/config";
    $tlmgr_config_file = TeXLive::TLConfFile->new($fn, "#", "=");
  }
  for my $k (keys %config) {
    $tlmgr_config_file->value($k, $config{$k});
  }
  for my $k ($tlmgr_config_file->keys) {
    if (not(defined($config{$k}))) {
      $tlmgr_config_file->delete_key($k);
    }
  }
  if ($tlmgr_config_file->is_changed) {
    $tlmgr_config_file->save;
  }
}

sub convert_crypto_options {
  my ($verify_downloads, $require_verification, $verify_repo) = @_;

  my $ret;

  if ((defined($verify_downloads) || defined($require_verification)) &&
      defined($verify_repo)) {
    tldie("$prg: options verify-downloads and require-verification have\n"
        . "$prg: been superseded by verify-repo; please use only the latter!\n");
  }
  return($verify_repo) if (defined($verify_repo));

  if (defined($verify_downloads)) {
    if ($verify_downloads) {
      if ($require_verification) {
        $ret = "all";
      } else {
        $ret = "main";
      }
    } else {
      if ($require_verification) {
        tldie("You cannot ask for --no-verify-downloads and"
              . " --require-verification  at the same time!\n");
      } else {
        $ret = "none";
      }
    }
  } else {
    if ($require_verification) {
      $ret = "all";
    } else {
    }
  }
  return($ret);
}

sub logpackage {
  if ($packagelogfile) {
    $packagelogged++;
    my $tim = localtime();
    print PACKAGELOG "[$tim] @_\n";
  }
}
sub logcommand {
  if ($commandlogfile) {
    $commandslogged++; # not really counting commands logged, but calls
    my $tim = localtime();
    print COMMANDLOG "[$tim] @_\n";
  }
}
sub logcommand_bare {
  if ($commandlogfile) {
    $commandslogged++;
    print COMMANDLOG "@_\n";
  }
}


sub norm_tlpdb_path {
  my ($path) = @_;
  return if (!defined($path));
  $path =~ s!\\!/!;
  return $path if ($path =~ m!^/|:!);
  init_local_db() unless defined($localtlpdb);
  return $localtlpdb->root . "/$path";
}

sub clear_old_backups {
  my ($pkg, $backupdir, $autobackup, $dry, $v) = @_;

  my $verb = ($v ? 1 : 0);
  my $dryrun = 0;
  $dryrun = 1 if ($dry);
  return if ($autobackup == -1);

  opendir (DIR, $backupdir) || die "opendir($backupdir) failed: $!";
  my @dirents = readdir (DIR);
  closedir (DIR) || warn "closedir($backupdir) failed: $!";
  my @backups;
  for my $dirent (@dirents) {
    next if (-d $dirent);
    next if ($dirent !~ m/^$pkg\.r([0-9]+)\.tar\.$CompressorExtRegexp$/);
    push @backups, [ $1, $dirent ] ;
  }
  my $i = 1;
  for my $e (reverse sort {$a->[0] <=> $b->[0]} @backups) {
    if ($i > $autobackup) {
      if ($verb) {
        info("$prg: Removing backup $backupdir/$e->[1]\n");
      } else {
        debug("Removing backup $backupdir/$e->[1]\n");
      }
      unlink("$backupdir/$e->[1]") unless $dryrun;
    }
    $i++;
  }
}

sub check_for_critical_updates {
  my ($localtlpdb, $mediatlpdb) = @_;

  my $criticalupdate = 0;
  my @critical = $localtlpdb->expand_dependencies("-no-collections",
    $localtlpdb, @CriticalPackagesList);
  my @critical_upd;
  for my $pkg (sort @critical) {
    my $tlp = $localtlpdb->get_package($pkg);
    if (!defined($tlp)) {
      tlwarn("\n$prg: Fundamental package $pkg not present, uh oh, goodbye");
      die "Should not happen, $pkg not found";
    }
    my $localrev = $tlp->revision;
    my $mtlp = $mediatlpdb->get_package($pkg);
    if (!defined($mtlp)) {
      debug("Surprising, $pkg not present in remote tlpdb.\n");
      next;
    }
    my $remoterev = $mtlp->revision;
    push (@critical_upd, $pkg) if ($remoterev > $localrev);
  }
  return(@critical_upd);
}

sub critical_updates_warning {
  tlwarn("=" x 79, "\n");
  tlwarn("tlmgr itself needs to be updated.\n");
  tlwarn("Please do this via either\n");
  tlwarn("  tlmgr update --self\n");
  tlwarn("or by getting the latest updater for Unix-ish systems:\n");
  tlwarn("  $TeXLiveURL/update-tlmgr-latest.sh\n");
  tlwarn("and/or Windows systems:\n");
  tlwarn("  $TeXLiveURL/update-tlmgr-latest.exe\n");
  tlwarn("Then continue with other updates as usual.\n");
  tlwarn("=" x 79, "\n");
}

sub packagecmp {
  my $aa = $a;
  my $bb = $b;
  $aa =~ s/\..*$//;
  $bb =~ s/\..*$//;
  if ($aa lt $bb) {
    return -1;
  } elsif ($aa gt $bb) {
    return 1;
  } else {
    if ($a eq $aa && $b eq $bb) {
      return 0;
    } elsif ($a eq $aa) {
      return 1;
    } elsif ($b eq $bb) {
      return -1;
    } else {
      return ($a cmp $b);
    }
  }
}

sub check_on_writable {
  return 1 if $opts{"usermode"};
  if (!TeXLive::TLUtils::dir_writable("$Master/tlpkg")) {
    tlwarn("You don't have permission to change the installation in any way,\n");
    tlwarn("specifically, the directory $Master/tlpkg/ is not writable.\n");
    tlwarn("Please run this program as administrator, or contact your local admin.\n");
    if ($opts{"dry-run"}) {
      tlwarn("$prg: Continuing due to --dry-run\n");
      return 1;
    } else {
      return 0;
    }
  }
  return 1;
}


1;
















# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/texmf-dist/scripts/texlive/tlmgr.pl

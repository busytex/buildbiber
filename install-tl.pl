BEGIN {
my %modules = (
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLWinGoo.pm
"TeXLive/TLWinGoo.pm" => <<'__EOI__',



package TeXLive::TLWinGoo;

my $svnrev = '$Revision$';
my $_modulerevision;
if ($svnrev =~ m/: ([0-9]+) /) {
  $_modulerevision = $1;
} else {
  $_modulerevision = "unknown";
}
sub module_revision { return $_modulerevision; }


BEGIN {
  use Exporter;
  use vars qw( @ISA @EXPORT @EXPORT_OK $Registry);
  @ISA = qw( Exporter );
  @EXPORT = qw(
    &admin
    &non_admin
  );
  @EXPORT_OK = qw(
    &admin_again
    &reg_country
    &broadcast_env
    &update_assocs
    &expand_string
    &get_system_path
    &get_user_path
    &setenv_reg
    &unsetenv_reg
    &adjust_reg_path_for_texlive
    &add_to_progids
    &remove_from_progids
    &register_extension
    &unregister_extension
    &register_file_type
    &unregister_file_type
    &shell_folder
    &desktop_path
    &add_desktop_shortcut
    &add_menu_shortcut
    &remove_desktop_shortcut
    &remove_menu_shortcut
    &create_uninstaller
    &unregister_uninstaller
    &maybe_make_ro
    &get_system_env
    &get_user_env
    &is_a_texdir
    &tex_dirs_on_path
  );
  if ($^O=~/^MSWin/i) {
    require Win32;
    require Win32::API;
    require Win32API::File;
    require File::Spec;
    require Win32::TieRegistry;
    Win32::TieRegistry->import( qw( $Registry
      REG_SZ REG_EXPAND_SZ REG_NONE KEY_READ KEY_WRITE KEY_ALL_ACCESS
         KEY_ENUMERATE_SUB_KEYS ) );
    $Registry->Delimiter('/');
    $Registry->ArrayValues(0);
    $Registry->FixSzNulls(1);
    require Win32::Shortcut;
    Win32::Shortcut->import( qw( SW_SHOWNORMAL SW_SHOWMINNOACTIVE ) );
    require Time::HiRes;
  }
} # end BEGIN

use TeXLive::TLConfig;
use TeXLive::TLUtils;
TeXLive::TLUtils->import( qw( mkdirhier ) );

sub reg_debug {
  return if ($::opt_verbosity < 1);
  my $mess = shift;
  my $regerr = Win32API::Registry::regLastError();
  if ($regerr) {
    debug("$regerr\n$mess");
  }
}

my $is_win = ($^O =~ /^MSWin/i);



my $SendMessage = 0;
my $update_fu = 0;
if ($is_win) {
  $SendMessage = Win32::API::More->new('user32', 'SendMessageTimeout', 'LLPPLLP', 'L');
  debug ("Import failure SendMessage\n") unless $SendMessage;
  $update_fu = Win32::API::More->new('shell32', 'SHChangeNotify', 'LIPP', 'V');
  debug ("Import failure assoc_notify\n") unless $update_fu;
}



my $is_admin = 1;

if ($is_win) {
  $is_admin = 0 unless Win32::IsAdminUser();
}

sub KEY_FULL_ACCESS() {
  return KEY_WRITE() | KEY_READ();
}

sub sys_access_permissions {
  return $is_admin ? KEY_FULL_ACCESS() : KEY_READ();
}

sub get_system_env {
  return $Registry -> Open(
    "LMachine/system/currentcontrolset/control/session manager/Environment/",
    {Access => sys_access_permissions()});
}

sub get_user_env {
  return $Registry -> Open("CUser/Environment", {Access => KEY_FULL_ACCESS()});
}



sub admin { return $is_admin; }


sub non_admin {
  debug("TLWinGoo: switching to user mode\n");
  $is_admin = 0;
}

sub admin_again {
  debug("TLWinGoo: switching to admin mode\n");
  $is_admin = 1;
}


sub reg_country {
  my $lm = cu_root()->{"Control Panel/international//localename"};
  return unless $lm;
  debug("found lang code lm = $lm...\n");
  if ($lm) {
    if ($lm =~ m/^zh-(tw|hk)$/i) {
      return ("zh", "tw");
    } elsif ($lm =~ m/^zh/) {
      return ("zh", "cn");
    } else {
      my $lang = lc(substr $lm, 0, 2);
      my $area = lc(substr $lm, 3, 2);
      return($lang, $area);
    }
  }
}



sub expand_string {
  my ($s) = @_;
  return Win32::ExpandEnvironmentStrings($s);
}

my $global_tmp = $is_win ? expand_string(get_system_env()->{'TEMP'}) : "/tmp";

sub is_a_texdir {
  my $d = shift;
  $d =~ s/\\/\//g;
  $d = $d . '/' unless $d =~ m!/$!;
  my $sr = uc($ENV{'SystemRoot'});
  $sr =~ s/\\/\//g;
  $sr = $sr . '/' unless $sr =~ m!/$!;
  return 0 if index($d, $sr)==0;
  foreach my $p (qw(luatex.exe mktexlsr.exe pdftex.exe tex.exe xetex.exe)) {
    return 1 if (-e $d.$p);
  }
  return 0;
}


sub get_system_path {
  my $value = get_system_env() -> {'/Path'};
  $value =~ s/[\s\x00]+$//;
  return $value;
}


sub get_user_path {
  my $value = get_user_env() -> {'/Path'};
  return "" if not $value;
  $value =~ s/[\s\x00]+$//;
  return $value;
}


sub setenv_reg {
  my $env_var = shift;
  my $env_data = shift;
  my $mode = @_ ? shift : "default";
  die "setenv_reg: Invalid mode $mode"
    if ($mode ne "user" and $mode ne "system" and $mode ne "default");
  die "setenv_reg: mode 'system' only available for admin"
    if ($mode eq "system" and !$is_admin);
  my $env;
  if ($mode ne "system") {
    $env = get_user_env();
    $env->ArrayValues(1);
    $env->{'/'.$env_var} =
       [ $env_data, ($env_data =~ /%/) ? REG_EXPAND_SZ : REG_SZ ];
  }
  if ($mode ne "user" and $is_admin) {
    $env = get_system_env();
    $env->ArrayValues(1);
    $env->{'/'.$env_var} =
       [ $env_data, ($env_data =~ /%/) ? REG_EXPAND_SZ : REG_SZ ];
  }
}


sub unsetenv_reg {
  my $env_var = shift;
  my $env = get_user_env();
  my $mode = @_ ? shift : "default";
  die "unsetenv_reg: Invalid mode $mode"
    if ($mode ne "user" and $mode ne "system" and $mode ne "default");
  die "unsetenv_reg: mode 'system' only available for admin"
    if ($mode eq "system" and !$is_admin);
  delete get_user_env()->{'/'.$env_var} if $mode ne "system";
  delete get_system_env()->{'/'.$env_var} if ($mode ne "user" and $is_admin);
}


sub tex_dirs_on_path {
  my ($path) = @_;
  my ($d, $d_exp);
  my @texdirs = ();
  foreach $d (split (';', $path)) {
    $d_exp = expand_string($d);
    if (is_a_texdir($d_exp)) {
      push(@texdirs, $d_exp);
    };
  }
  return @texdirs;
}



sub short_name {
  my ($fname) = @_;
  return $fname unless $is_win;
  my $shname = Win32::GetShortPathName ($fname);
  return (defined $shname) ? $shname : $fname;
}

sub adjust_reg_path_for_texlive {
  my ($action, $tlbindir, $mode) = @_;
  die("Unknown path action: $action\n")
    if ($action ne 'add') && ($action ne 'remove');
  die("Unknown path mode: $mode\n")
    if ($mode ne 'system') && ($mode ne 'user');
  debug("Warning: [pdf]tex program not found in $tlbindir\n")
    if (!is_a_texdir($tlbindir));
  my $path = ($mode eq 'system') ? get_system_path() : get_user_path();
  $tlbindir =~ s!/!\\!g;
  my $tlbindir_short = uc(short_name($tlbindir));
  my ($d, $d_short, @newpath);
  my $tex_dir_conflict = 0;
  my @texdirs;
  foreach $d (split (';', $path)) {
    $d_short = uc(short_name(expand_string($d)));
    $d_short =~ s!/!\\!g;
    ddebug("adjust_reg: compare $d_short with $tlbindir_short\n");
    if ($d_short ne $tlbindir_short) {
      push(@newpath, $d);
      if (is_a_texdir($d)) {
        $tex_dir_conflict++;
        push(@texdirs, $d);
      }
    }
  }
  if ($action eq 'add') {
    if ($tex_dir_conflict) {
      log("Warning: conflicting [pdf]tex program found on the $mode path ", 
          "in @texdirs; appending $tlbindir to the front of the path.\n");
      unshift(@newpath, $tlbindir);
    } else {
      push(@newpath, $tlbindir);
    }
  }
  if (@newpath) {
    debug("TLWinGoo: adjust_reg_path_for_texlive: calling setenv_reg in $mode\n");
    setenv_reg("Path", join(';', @newpath), $mode);
  } else {
    debug("TLWinGoo: adjust_reg_path_for_texlive: calling unsetenv_reg in $mode\n");
    unsetenv_reg("Path", $mode);
  }
  if ( ($action eq 'add') && ($mode eq 'user') ) {
    @texdirs = tex_dirs_on_path( get_system_path() );
    return 0 unless (@texdirs);
    tlwarn("Warning: conflicting [pdf]tex program found on the system path ",
           "in @texdirs; not fixable in user mode.\n");
    return 1;
  }
  return 0;
}





sub hash_merge {
  my $target = shift; # the recursive hash ref to be modified by $mods
  my $mods = shift; # the recursive hash ref to be merged into $target
  my $k;
  foreach $k (keys %$mods) {
    if (ref($target->{$k}) eq 'HASH' and ref($mods->{$k}) eq 'HASH') {
      hash_merge($target->{$k}, $mods->{$k});
    } else {
      $target->{$k} = $mods->{$k};
      reg_debug ("at hash merge\n");
      $target->Flush();
      reg_debug ("at hash merge\n");
    }
  }
}


sub getans {
  my $prompt = shift;
  my $ans;
  print STDERR "$prompt ";
  $ans = <STDIN>;
  if ($ans =~ /^y/i) {print STDERR "\n"; return 1;}
  die "Aborting as requested";
}


sub reg_delete_recurse {
  my $parent = shift;
  my $childname = shift;
  my $parentpath = $parent->Path;
  ddebug("Deleting $parentpath$childname\n");
  my $child;
  if ($childname !~ '^/') { # subkey
    $child = $parent->Open ($childname, {Access => KEY_FULL_ACCESS()});
    reg_debug ("at open $childname for all access\n");
    return 1 unless defined($child);
    foreach my $v (keys %$child) {
      if ($v =~ '^/') { # value
        delete $child->{$v};
        reg_debug ("at delete $childname/$v\n");
        $child->Flush();
        reg_debug ("at delete $childname/$v\n");
        Time::HiRes::usleep(20000);
      } else { # subkey
        return 0 unless reg_delete_recurse ($child, $v);
      }
    }
  }
  delete $parent->{$childname};
  reg_debug ("at delete $parentpath$childname\n");
  $parent->Flush();
  reg_debug ("at delete $parentpath$childname\n");
  Time::HiRes::usleep(20000);
  return 1;
}

sub cu_root {
  my $k = $Registry -> Open("CUser", {
    Access => KEY_FULL_ACCESS(), Delimiter => '/'
  });
  reg_debug ("at open HKCU for all access\n");
  die "Cannot open HKCU for writing" unless $k;
  return $k;
}

sub lm_root {
  my $k = $Registry -> Open("LMachine", {
      Access => ($is_admin ? KEY_FULL_ACCESS() : KEY_READ()),
      Delimiter => '/'
  });
  reg_debug ("at open HKLM\n");
  die "Cannot open HKLM for ".($is_admin ? "writing" : "reading")
      unless $k;
  return $k;
}

sub do_write_regkey {
  my $keypath = shift; # modulo cu/lm
  my $keyhash = shift; # ref to a possibly nested hash; empty hash allowed
  my $remove_cu = shift;
  die "No regkey specified" unless $keypath && defined($keyhash);
  my $hivename = $is_admin ? 'HKLM' : 'HKCU';

  my ($parentpath, $keyname);
  if ($keypath =~ /^\/?(.+\/)([^\/]+)\/?$/) {
    ($parentpath, $keyname) = ($1, $2);
    $keyname .= '/';
    debug ("key - $hivename - $parentpath - $keyname\n");
  } else {
    die "Cannot determine final component of $keypath";
  }

  my $cu_key = cu_root();
  my $lm_key = lm_root();
  my $parentkey;

  if ($is_admin) {
    $parentkey = $lm_key->Open($parentpath);
    reg_debug ("at open $parentpath; creating...\n");
    if (!$parentkey) {
      $parentkey = $lm_key->CreateKey($parentpath);
      reg_debug ("at creating $parentpath\n");
    }
  } else {
    $parentkey = $cu_key->Open($parentpath);
    reg_debug ("at open $parentpath; creating...\n");
    if (!$parentkey) {
      $parentkey = $cu_key->CreateKey($parentpath);
      reg_debug ("at creating $parentpath\n");
    }
  }
  if (!$parentkey) {
    tlwarn "Cannot create parent of $hivename/$keypath\n";
    return 0;
  }

  if ($parentkey->{$keyname}) {
    hash_merge($parentkey->{$keyname}, $keyhash);
  } else {
    $parentkey->{$keyname} = $keyhash;
    reg_debug ("at creating $keyname\n");
  }
  if (!$parentkey->{$keyname}) {
    tlwarn "Failure to create $hivename/$keypath\n";
    return 0;
  }
  if ($is_admin and $cu_key->{$keypath} and $remove_cu) {
    tlwarn "Failure to delete $hivename/$keypath key\n" unless
      reg_delete_recurse ($cu_key->{$parentpath}, $keyname);
  }
  return 1;
}


sub do_remove_regkey {
  my $keypath = shift; # key or value
  my $remove_cu = shift;
  my $hivename = $is_admin ? 'HKLM' : 'HKCU';

  my $parentpath = "";
  my $keyname = "";
  my $valname = "";
  if ($keypath =~ /^(.*?\/)(\/.*)$/) {
    ($parentpath, $valname) = ($1, $2);
    $parentpath =~ s!^/!!; # remove leading delimiter
  } elsif ($keypath =~ /^\/?(.+\/)([^\/]+)\/?$/) {
    ($parentpath, $keyname) = ($1, $2);
    $keyname .= '/';
  } else {
    die "Cannot determine final component of $keypath";
  }

  my $cu_key = cu_root();
  my $lm_key = lm_root();
  my ($parentkey, $k, $skv, $d);
  if ($is_admin) {
    $parentkey = $lm_key->Open($parentpath);
  } else {
    $parentkey = $cu_key->Open($parentpath);
  }
  reg_debug ("at opening $parentpath\n");
  if (!$parentkey) {
    debug ("$hivename/$parentpath not present or not writable".
      " so $keypath not removed\n");
    return 1;
  }
  if ($keyname) {
    reg_delete_recurse($parentkey, $keyname);
    if ($parentkey->{$keyname}) {
      tlwarn "Failure to delete $hivename/$keypath\n";
      return 0;
    }
    if ($is_admin and $cu_key->{$parentpath}) {
      reg_delete_recurse($cu_key->{$parentpath}, $keyname);
      if ($cu_key->{$parentpath}->{$keyname}) {
        tlwarn "Failure to delete HKCU/$keypath\n";
        return 0;
      }
    }
  } else {
    delete $parentkey->{$valname};
    reg_debug ("at deleting $valname\n");
    if ($parentkey->{$valname}) {
      tlwarn "Failure to delete $hivename/$keypath\n";
      return 0;
    }
    if ($is_admin and $cu_key->{$parentpath}) {
      delete $cu_key->{$parentpath}->{$valname};
      reg_debug ("at deleting $valname\n");
      if ($cu_key->{$parentpath}->{$valname}) {
        tlwarn "Failure to delete HKCU/$keypath\n";
        return 0;
      }
    }
  }
  return 1;
}



my $file_not_found = 2; # ERROR_FILE_NOT_FOUND
my $reg_ok = 0; # ERROR_SUCCESS

my $reg_unknown = 'not accessible';

sub current_filetype {
  my $extension = shift;
  my $filetype;
  my $regerror;

  if ($is_admin) {
    $regerror = $reg_ok;
    $filetype = lm_root()->{"Software/Classes/$extension//"} # REG_SZ
      or $regerror = Win32API::Registry::regLastError();
    if ($regerror != $reg_ok and $regerror != $file_not_found) {
      return $reg_unknown;
    }
  } else {
    $regerror = $reg_ok;
    $filetype = cu_root()->{"Software/Classes/$extension//"} or
      $regerror = Win32API::Registry::regLastError();
    if ($regerror != $reg_ok and $regerror != $file_not_found) {
      return $reg_unknown;
    }
    if (!defined($filetype) or ($filetype eq "")) {
      $regerror = $reg_ok;
      $filetype = lm_root()->{"Software/Classes/$extension//"} or
        $regerror = Win32API::Registry::regLastError();
      if ($regerror != $reg_ok and $regerror != $file_not_found) {
        return $reg_unknown;
      }
    };
  }
  $filetype = "" unless defined($filetype);
  return $filetype;
}



sub add_to_progids {
  my $ext = shift;
  my $filetype = shift;
  do_write_regkey("Software/Classes/$ext/OpenWithProgIds/",
      {"/$filetype" => ""});
}


sub remove_from_progids {
  my $ext = shift;
  my $filetype = shift;
  do_remove_regkey("Software/Classes/$ext/OpenWithProgIds//$filetype");
}


sub register_extension {
  my $mode = shift;
  return 1 if $mode == 0;
  my $extension = shift;
  $extension = '.'.$extension unless $extension =~ /^\./;
  $extension = lc($extension);
  my $file_type = shift;
  my $regkey;

  my $old_file_type = current_filetype($extension);
  if ($old_file_type and $old_file_type ne $reg_unknown) {
    if ($is_admin) {
      if (not lm_root()->{"Software/Classes/$old_file_type/"}) {
        $old_file_type = "";
      }
    } else {
      if ((not cu_root()->{"Software/Classes/$old_file_type/"}) and
          (not lm_root()->{"Software/Classes/$old_file_type/"})) {
        $old_file_type = "";
      }
    }
  }
  my $remove_cu = ($mode == 2) && admin();

  debug ("Adding $file_type to OpenWithProgIds of $extension\n");
  add_to_progids ($extension, $file_type);

  if ($old_file_type and $old_file_type ne $file_type) {
    if ($mode == 1) {
      debug ("Not overwriting $old_file_type with $file_type for $extension\n");
    } else { # $mode ==2, overwrite
      debug("Linking $extension to $file_type\n");
      if ($old_file_type ne $reg_unknown) {
        debug ("Moving $old_file_type to OpenWithProgIds\n");
        add_to_progids ($extension, $old_file_type);
      }
      $regkey = {'/' => $file_type};
      do_write_regkey("Software/Classes/$extension/", $regkey, $remove_cu);
    }
  } else {
    $regkey = {'/' => $file_type};
    do_write_regkey("Software/Classes/$extension/", $regkey, $remove_cu);
  }
}


sub unregister_extension {
  my $mode = shift;
  return 1 if $mode == 0;
  my $extension = shift;
  my $file_type = shift;
  $extension = '.'.$extension unless $extension =~ /^\./;
  remove_from_progids($extension, $file_type);
  my $old_file_type = current_filetype("$extension");
  if ($old_file_type ne $file_type) {
    debug("Filetype $extension now $old_file_type; not ours, so not removed\n");
    return 1;
  } else {
    debug("unregistering extension $extension\n");
    do_remove_regkey("Software/Classes/$extension//");
  }
}


sub register_file_type {
  my $file_type = shift;
  my $command = shift;
  tlwarn "register_file_type called with empty command\n" unless $command;
  $command =~s!/!\\!g;
  debug ("Linking $file_type to $command\n");
  my $keyhash = {
    "shell/" => {
      "open/" => {
        "command/" => {
          "/" => $command
        }
      }
    }
  };
  do_write_regkey("Software/Classes/$file_type", $keyhash);
}


sub unregister_file_type {
  my $file_type = shift;
  debug ("unregistering $file_type\n");
  do_remove_regkey("Software/Classes/$file_type/");
}


sub broadcast_env() {
  if ($SendMessage) {
    use constant HWND_BROADCAST => 0xffff;
    use constant WM_SETTINGCHANGE => 0x001A;
    my $result = "";
    my $ans = "12345678"; # room for dword
    $result = $SendMessage->Call(HWND_BROADCAST, WM_SETTINGCHANGE,
        0, 'Environment', 0, 2000, $ans) if $SendMessage;
    debug("Broadcast complete; result: $result.\n");
  } else {
    debug("No SendMessage available\n");
  }
}


sub update_assocs() {
  use constant SHCNE_ASSOCCHANGED => 0x8000000;
  use constant SHCNF_IDLIST => 0;
  if ($update_fu) {
    debug("Notifying changes in filetypes...\n");
    my $result = $update_fu->Call(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, 0, 0);
    if ($result) {
      debug("Done notifying filetype changes\n");
    } else{
      debug("Failure notifying filetype changes\n");
    }
  } else {
    debug("No update_fu\n");
  }
}


sub add_shortcut {
  my ($dir, $name, $icon, $prog, $args, $batgui) = @_;

  if ((not -e $dir) and (not -d $dir)) {
    mkdirhier($dir);
  }
  if (not -d $dir) {
    tlwarn ("Failed to create directory $dir for shortcut\n");
    return;
  }
  debug "Creating shortcut $name for $prog in $dir\n";
  my ($shc, $shpath, $shfile);
  $shc = new Win32::Shortcut();
  $shc->{'IconLocation'} = $icon if -f $icon;
  $shc->{'Path'} = $prog;
  $shc->{'Arguments'} = $args;
  $shc->{'ShowCmd'} = $batgui ? SW_SHOWMINNOACTIVE : SW_SHOWNORMAL;
  $shc->{'WorkingDirectory'} = '%USERPROFILE%';
  $shfile = $dir;
  $shfile =~ s!\\!/!g;
  $shfile .= ($shfile =~ m!/$! ? '' : '/') . $name . '.lnk';
  $shc->Save($shfile);
}

sub desktop_path() {
  return Win32::GetFolderPath(
    (admin() ? Win32::CSIDL_COMMON_DESKTOPDIRECTORY :
       Win32::CSIDL_DESKTOPDIRECTORY), CREATE);
}

sub menu_path() {
  return Win32::GetFolderPath(
    (admin() ? Win32::CSIDL_COMMON_PROGRAMS : Win32::CSIDL_PROGRAMS), CREATE);
}

sub add_desktop_shortcut {
  my ($name, $icon, $prog, $args, $batgui) = @_;
  add_shortcut (desktop_path(), $name, $icon, $prog, $args, $batgui);
}

sub add_menu_shortcut {
  my ($place, $name, $icon, $prog, $args, $batgui) = @_;
  $place =~ s!\\!/!g;
  my $shdir = menu_path() . ($place =~  m!^/!=~ '/' ? '' : '/') . $place;
  add_shortcut ($shdir, $name, $icon, $prog, $args, $batgui);
}



sub remove_desktop_shortcut {
  my $name = shift;
  unlink desktop_path().'/'.$name.'.lnk';
}

sub remove_menu_shortcut {
  my $place = shift;
  my $name = shift;
  $place =~ s!\\!/!g;
  $place = '/'.$place unless $place =~ m!^/!;
  unlink menu_path().$place.'/'.$name.'.lnk';
}


sub create_uninstaller {
  &log("Creating uninstaller\n");
  my $td_fw = shift;
  $td_fw =~ s!\\!/!;
  my $td = $td_fw;
  $td =~ s!/!\\!g;

  my $tdmain = `"$td\\bin\\windows\\kpsewhich" -var-value=TEXMFMAIN`;
  $tdmain =~ s!/!\\!g;
  chomp $tdmain;

  my $uninst_fw = "$td_fw/tlpkg/installer";
  my $uninst_dir = $uninst_fw;
  $uninst_dir =~ s!/!\\!g;
  mkdirhier("$uninst_fw"); # wasn't this done yet?
  if (! (open UNINST, ">", "$uninst_fw/uninst.bat")) {
    tlwarn("Failed to create uninstaller\n");
    return 0;
  }
  print UNINST <<UNEND;
rem \@echo off
setlocal
path $td\\tlpkg\\tlperl\\bin;$td\\bin\\windows;%path%
set PERL5LIB=$td\\tlpkg\\tlperl\\lib
rem Clean environment from other Perl variables
set PERL5OPT=
set PERLIO=
set PERLIO_DEBUG=
set PERLLIB=
set PERL5DB=
set PERL5DB_THREADED=
set PERL5SHELL=
set PERL_ALLOW_NON_IFS_LSP=
set PERL_DEBUG_MSTATS=
set PERL_DESTRUCT_LEVEL=
set PERL_DL_NONLAZY=
set PERL_ENCODING=
set PERL_HASH_SEED=
set PERL_HASH_SEED_DEBUG=
set PERL_ROOT=
set PERL_SIGNALS=
set PERL_UNICODE=

perl.exe \"$tdmain\\scripts\\texlive\\uninstall-windows.pl\" \%1

if errorlevel 1 goto :eof
rem test for taskkill and try to stop exit tray menu
taskkill /? >nul 2>&1
if not errorlevel 1 1>nul 2>&1 taskkill /IM tl-tray-menu.exe /f
copy \"$uninst_dir\\uninst2.bat\" \"\%TEMP\%\"
rem pause
\"\%TEMP\%\\uninst2.bat\"
UNEND
;
  close UNINST;

  if (! (open UNINST2, ">$uninst_fw/uninst2.bat")) {
    tlwarn("Failed to complete creating uninstaller\n");
    return 0;
  }
  print UNINST2 <<UNEND2;
rmdir /s /q \"$td\\bin\"
rmdir /s /q \"$td\\readme-html.dir\"
rmdir /s /q \"$td\\readme-txt.dir\"
if exist \"$td\\temp\" rmdir /s /q \"$td\\temp\"
rmdir /s /q \"$td\\texmf-dist\"
rmdir /s /q \"$td\\tlpkg\"
del /q \"$td\\README.*\"
del /q \"$td\\LICENSE.*\"
if exist \"$td\\doc.html\" del /q \"$td\\doc.html\"
del /q \"$td\\index.html\"
del /q \"$td\\texmf.cnf\"
del /q \"$td\\texmfcnf.lua\"
del /q \"$td\\install-tl*.*\"
del /q \"$td\\tl-tray-menu.exe\"
rem del /q \"$td\\texlive.profile\"
del /q \"$td\\release-texlive.txt\"
UNEND2
;
  for my $d ('TEXMFSYSVAR', 'TEXMFSYSCONFIG') {
    my $kd = `"$td\\bin\\windows\\kpsewhich" -var-value=$d`;
    chomp $kd;
    print UNINST2 "rmdir /s /q \"", $kd, "\"\r\n";
  }
  if ($td !~ /^.:$/) { # not root of drive; remove directory if empty
    print UNINST2 <<UNEND3;
for \%\%f in (\"$td\\*\") do goto :done
for /d \%\%f in (\"$td\\*\") do goto :done
rd \"$td\"
:done
\@echo Done uninstalling TeXLive.
\@pause
del \"%0\"
UNEND3
;
  }
  close UNINST2;
  if (!admin()) {
    &log("Creating shortcut for uninstaller\n");
    TeXLive::TLWinGoo::add_menu_shortcut(
        $TeXLive::TLConfig::WindowsMainMenuName, "Uninstall TeX Live", "",
        "$uninst_dir\\uninst.bat", "", 0);
  }
  if (admin()) {
    &log("Registering uninstaller\n");
    my $k;
    my $uninst_key = $Registry -> Open((admin() ? "LMachine" : "CUser") .
        "/software/microsoft/windows/currentversion/",
        {Access => KEY_FULL_ACCESS()});
    if ($uninst_key) {
      $k = $uninst_key->CreateKey(
        "uninstall/TeXLive$::TeXLive::TLConfig::ReleaseYear/");
      if ($k) {
        $k->{"/DisplayName"} = "TeX Live $::TeXLive::TLConfig::ReleaseYear";
        $k->{"/UninstallString"} = "\"$td\\tlpkg\\installer\\uninst.bat\"";
        $k->{'/DisplayVersion'} = $::TeXLive::TLConfig::ReleaseYear;
        $k->{'/Publisher'} = 'TeX Live';
        $k->{'/URLInfoAbout'} = "http://www.tug.org/texlive";
      }
    }
    if (!$k and admin()) {
      tlwarn("Failed to register uninstaller\n".
         "You can still run $td\\tlpkg\\installer\\uninst.bat manually.\n");
      return 0;
    }
  }
}


sub unregister_uninstaller {
  my ($w32_multi_user) = @_;
  my $regkey_uninst_path = ($w32_multi_user ? "LMachine" : "CUser") . 
    "/software/microsoft/windows/currentversion/uninstall/";
  my $regkey_uninst = $Registry->Open($regkey_uninst_path,
    {Access => KEY_FULL_ACCESS()});
  reg_delete_recurse(
    $regkey_uninst, "TeXLive$::TeXLive::TLConfig::ReleaseYear/") 
    if $regkey_uninst;
  tlwarn "Failure to unregister uninstaller\n" if
    $regkey_uninst->{"TeXLive$::TeXLive::TLConfig::ReleaseYear/"};
}


sub maybe_make_ro {
  my $dir = shift;
  debug ("Calling maybe_make_ro on $dir\n");
  tldie "$dir not a directory\n" unless -d $dir;
  if (!admin()) {
    log "Not an admin install; not making read-only\n";
    return 1;
  }

  $dir = Cwd::abs_path($dir);

  my ($volume,$dirs,$file) = File::Spec->splitpath($dir);
  debug "Split path: | $volume | $dirs | $file\n";
  if ($volume =~ m!^[\\/][\\/]!) {
    log "$dir on UNC network path; not making read-only\n";
    return 1;
  }
  my $dt = Win32API::File::GetDriveType($volume);
  debug "Drive type $dt\n";
  if ($dt ne Win32API::File::DRIVE_FIXED) {
    log "Not a local fixed drive; not making read-only\n";
    return 1;
  }

  my $curdir = Cwd::getcwd();
  debug "Current directory $curdir\n";
  chdir $dir;
  my $newdir = Cwd::getcwd();
  debug "New current directory $newdir\n";
  tldie "Cannot cd to $dir, current dir is $newdir\n" unless
    lc($newdir) eq lc($dir);
  my ($fstype, $flags, $maxl) = Win32::FsType(); # of current drive
  if (!($flags & 0x00000008)) {
    log "$dir does not supports ACLs; not making read-only\n";
    chdir $curdir;
    return 1;
  }



  my $cmd = 'cmd /c "icacls . /reset && icacls . /inheritance:r'.
    ' /grant:r *S-1-5-32-544:(OI)(CI)F'.
    ' /grant:r *S-1-5-11:(OI)(CI)RX /grant:r *S-1-5-32-545:(OI)(CI)RX"';
  log "Making read-only\n".Encode::decode(console_out,`$cmd`)."\n";

  chdir $curdir;
  return 1;
}

1;












1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLWinGoo.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfFile.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfFile.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfig.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLConfig.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLCrypto.pm
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

=back
=cut

1;












1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLCrypto.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLDownload.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLDownload.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPDB.pm
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

=back



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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPDB.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPOBJ.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPOBJ.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPSRC.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPSRC.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPaper.pm
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

=back
=cut
1;












1;
__EOI__
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLPaper.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLTREE.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLTREE.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLUtils.pm
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


=back


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

=back


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



my $Is_VMS = $^O eq 'VMS';
my $Is_MacOS = $^O eq 'MacOS';

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
      chmod($rp | 0700, ($Is_VMS ? VMS::Filespec::fileify($root) : $root))
        or warn "Can't make directory $root read+writeable: $!"
          unless $safe;

      if (opendir my $d, $root) {
        no strict 'refs';
        if (!defined ${"\cTAINT"} or ${"\cTAINT"}) {
          @files = map { /^(.*)$/s ; $1 } readdir $d;
        } else {
          @files = readdir $d;
        }
        closedir $d;
      } else {
        warn "Can't read $root: $!";
        @files = ();
      }
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


sub removed_dirs {
  my (@files) = @_;
  my (%by_dir, %removed_dirs) = all_dirs_and_removed_dirs(@files);
  return keys %removed_dirs;
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


=back


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

=back


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


sub process_logging_options {
  $::opt_verbosity = 0;
  $::opt_quiet = 0;
  my $opt_logfile;
  my $opt_Verbosity = 0;
  my $opt_VERBOSITY = 0;
  my $oldconfig = Getopt::Long::Configure(qw(pass_through permute));
  GetOptions("logfile=s" => \$opt_logfile,
             "v+"  => \$::opt_verbosity,
             "vv"  => \$opt_Verbosity,
             "vvv" => \$opt_VERBOSITY,
             "q"   => \$::opt_quiet);
  Getopt::Long::Configure($oldconfig);

  $::opt_verbosity = 2 if $opt_Verbosity;
  $::opt_verbosity = 3 if $opt_VERBOSITY;

  if ($opt_logfile) {
    open(TLUTILS_LOGFILE, ">$opt_logfile")
    || die "open(>$opt_logfile) failed: $!\n";
    $::LOGFILE = \*TLUTILS_LOGFILE;
    $::LOGFILENAME = $opt_logfile;
  }
}

=back


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


=back


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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TLUtils.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TeXCatalogue.pm
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/TeXCatalogue.pm
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/trans.pl
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
# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/tlpkg/TeXLive/trans.pl
);
unshift @INC, sub {
my $module = $modules{$_[1]}
or return;
return \$module
};
}
# PACKPERLMODULES BEGIN https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/install-tl

use strict; use warnings;

my $svnrev = '$Revision$';
$svnrev =~ m/: ([0-9]+) /;
$::installerrevision = ($1 ? $1 : 'unknown');

our $texlive_release;

BEGIN {
  $^W = 1;
  my $Master;
  my $me = $0;
  $me =~ s!\\!/!g if $^O =~ /^MSWin/i;
  if ($me =~ m!/!) {
    ($Master = $me) =~ s!(.*)/[^/]*$!$1!;
  } else {
    $Master = ".";
  }
  $::installerdir = $Master;

#  unshift (@INC, "$::installerdir/tlpkg");# PACKPERLMODULES
}


our $dblfile = "/tmp/dblog";
$dblfile = $ENV{'TEMP'} . "\\dblog.txt" if ($^O =~ /^MSWin/i);
$dblfile = $ENV{'TMPDIR'} . "/dblog" if ($^O eq 'darwin'
                                         && exists $ENV{'TMPDIR'});
sub dblog {
  my $s = shift;
  open(my $dbf, ">>", $dblfile);
  print $dbf "PERL: $s\n";
  close $dbf;
}

sub dblogsub {
  my $s = shift;
  my @stck = (caller(1));
  dblog "$stck[3] $s";
}


if (($^O !~ /^MSWin/i) &&
      ($#ARGV >= 0) && ($ARGV[0] ne '-from_ext_gui')
    ) {

  my @tmp_args = ();
  my $p;
  my $i=-1;
  while ($i<$#ARGV) {
    $p = $ARGV[++$i];
    $p =~ s/^--/-/;
    if ($p =~ /^(.*)=(.*)$/) {
      push (@tmp_args, $1, $2);
    } else {
      push (@tmp_args, $p);
    }
  }

  my $want_tcl = 0;
  my $asked4tcl = 0;
  my $forbid = 0;
  my @new_args = ();
  $i = -1;
  while ($i < $#tmp_args) {
    $p = $tmp_args[++$i];
    if ($p eq '-gui') {
      if ($i == $#tmp_args || $tmp_args[$i+1] =~ /^-/) {
        $want_tcl = 1;
        $asked4tcl = 1;
      } elsif ($tmp_args[$i+1] eq 'text') {
        $want_tcl = 0;
        $forbid = 1;
        last;
      } else {
        my $q = $tmp_args[$i+1];
        if ($q eq 'tcl' || $q eq 'perltk' ||
            $q eq 'wizard' || $q eq 'expert') {
          $want_tcl = 1;
          $asked4tcl = 1;
          $i++;
        } else {
          die "$0: invalid value for parameter -gui: $q\n";
        }
      }
    } else {
      for my $q (qw/in-place profile help print-arch print-platform
                    version no-gui/) {
        if ($p eq "-$q") {
          $want_tcl = 0;
          $forbid = 1;
          last;
        }
      }
      last if $forbid;
      push (@new_args, $p);
    }
  }
  if ($want_tcl) {
    unshift (@new_args, "--");
    unshift (@new_args, "$::installerdir/tlpkg/installer/install-tl-gui.tcl");
    my @wishes = qw /wish wish8.7 wish8.6 wish8.5 tclkit/;
    unshift @wishes, $ENV{'WISH'} if (defined $ENV{'WISH'});
    foreach my $w (@wishes) {
      if (!exec($w, @new_args)) {
        next; # no return on successful exec
      }
    }
  } # else continue with main installer below
}

use Cwd 'abs_path';
use Getopt::Long qw(:config no_autoabbrev);
use Pod::Usage;
use POSIX ();

use TeXLive::TLUtils qw(platform platform_desc sort_archs
   which getenv wndws unix info log debug tlwarn ddebug tldie
   member process_logging_options rmtree wsystem
   mkdirhier make_var_skeleton make_local_skeleton install_package copy
   install_packages dirname setup_programs native_slashify forward_slashify);
use TeXLive::TLConfig;
use TeXLive::TLCrypto;
use TeXLive::TLDownload;
use TeXLive::TLPDB;
use TeXLive::TLPOBJ;
use TeXLive::TLPaper;

use Encode::Alias;
eval {
  require Encode::Locale;
  Encode::Locale->import ();
  debug("Encode::Locale is loaded.\n");
};
if ($@) {
  if (wndws()) {
    die ("For Windows, Encode::Locale is required.\n");
  }

  debug("Encode::Locale is not found. Assuming all encodings are UTF-8.\n");
  Encode::Alias::define_alias('locale' => 'UTF-8');
  Encode::Alias::define_alias('locale_fs' => 'UTF-8');
  Encode::Alias::define_alias('console_in' => 'UTF-8');
  Encode::Alias::define_alias('console_out' => 'UTF-8');
}
binmode (STDIN, ':encoding(console_in)');
binmode (STDOUT, ':encoding(console_out)');
binmode (STDERR, ':encoding(console_out)');

if (wndws()) {
  require TeXLive::TLWinGoo;
  TeXLive::TLWinGoo->import( qw(
    &admin
    &non_admin
    &reg_country
    &expand_string
    &get_system_path
    &get_user_path
    &setenv_reg
    &unsetenv_reg
    &adjust_reg_path_for_texlive
    &register_extension
    &unregister_extension
    &register_file_type
    &unregister_file_type
    &broadcast_env
    &update_assocs
    &add_menu_shortcut
    &remove_desktop_shortcut
    &remove_menu_shortcut
    &create_uninstaller
    &maybe_make_ro
  ));
}

@::LOGLINES = ();
&log ("TeX Live installer invocation: $0", map { " $_" } @ARGV, "\n");

@::WARNLINES = ();

my %origenv = ();

my %install;

$::run_menu = sub { die "no UI defined." ; };

my $default_scheme='scheme-full';

our $common_fmtutil_args =
  "--no-error-if-no-engine=$TeXLive::TLConfig::PartialEngineSupport";

our @collections_std;

our %vars=( # 'n_' means 'number of'.
        'this_platform' => '',
        'n_systems_available' => 0,
        'n_systems_selected' => 0,
        'n_collections_selected' => 0,
        'n_collections_available' => 0,
        'total_size' => 0,
        'src_splitting_supported' => 1,
        'doc_splitting_supported' => 1,
        'selected_scheme' => $default_scheme,
        'instopt_portable' => 0,
        'instopt_letter' => 0,
        'instopt_adjustrepo' => 1,
        'instopt_write18_restricted' => 1,
        'instopt_adjustpath' => 0,
    );

my %path_keys = (
  'TEXDIR' => 1,
  'TEXMFHOME' => 1,
  'TEXMFLOCAL' => 1,
  'TEXMFCONFIG' => 1,
  'TEXMFSYSCONFIG' => 1,
  'TEXMFVAR' => 1,
  'TEXMFSYSVAR' => 1,
);

my $opt_allow_ftp = 0;
my $opt_continue = 1;
my $opt_custom_bin;
my $opt_debug_fakenet = 0;
my $opt_debug_setup_vars = 0;
my $opt_doc_install = 1;
my $opt_font;
my $opt_force_arch;
my $opt_gui = "text";
my $opt_help = 0;
my $opt_init_from_profile = "";
my $opt_installation = 1;
my $opt_interaction = 1;
my $opt_location = "";
my $opt_no_gui = 0;
my $opt_no_interaction = 0;
my $opt_nonadmin = 0;
my $opt_paper = "";
my $opt_persistent_downloads = 1;
my $opt_portable = 0;
my $opt_print_arch = 0;
my $opt_profile = "";
my $opt_scheme = "";
my $opt_src_install = 1;
my $opt_texdir = "";
my $opt_texuserdir = "";
my $opt_version = 0;
my $opt_warn_checksums = 1;
my %pathopts;
$::opt_select_repository = 0;
our $opt_in_place = 0;
my $opt_verify_downloads;

$::opt_all_options = 0;

$::lang = "en";


$::debug_translation = 0;

@::installation_failed_packages = ();

$SIG{'INT'} = \&signal_handler;


my $from_ext_gui = 0;
if ((defined $ARGV[0]) && $ARGV[0] eq "-from_ext_gui") {
  shift @ARGV;
  $from_ext_gui = 1;

  select(STDERR); $| = 1;
  select(STDOUT); $| = 1;

  Win32::SetChildShowWindow(0) if wndws();
}

my %profiledata;
if (-r "installation.profile"
    && $opt_interaction
    && !exists $ENV{"TEXLIVE_INSTALL_NO_RESUME"}) {
  if ($from_ext_gui) { # prepare for dialog interaction
    print "mess_yesno\n";
  }
  my $pwd = Cwd::getcwd();
  print "ABORTED TL INSTALLATION FOUND: installation.profile (in $pwd)\n";
  print
    "Do you want to continue with the exact same settings as before (y/N): ";
  print "\nendmess\n" if $from_ext_gui;
  my $answer = <STDIN>;
  if ($answer =~ m/^y(es)?$/i) {
    $opt_profile = "installation.profile";
  }
}


process_logging_options();
GetOptions(
           "all-options"                 => \$::opt_all_options,
           "continue!"                   => \$opt_continue,
           "custom-bin=s"                => \$opt_custom_bin,
           "debug-fakenet"               => \$opt_debug_fakenet,
           "debug-setup-vars"            => \$opt_debug_setup_vars,
           "debug-translation"           => \$::debug_translation,
           "doc-install!"                => \$opt_doc_install,
           "fancyselector",
           "font=s"                      => \$opt_font,
           "force-platform|force-arch=s" => \$opt_force_arch,
           "gui:s"                       => \$opt_gui,
           "in-place"                    => \$opt_in_place,
           "init-from-profile=s"         => \$opt_init_from_profile,
           "installation!",              => \$opt_installation,
           "interaction!",               => \$opt_interaction,
           "lang|gui-lang=s"             => \$::opt_lang,
           "location|url|repository|repos|repo=s" => \$opt_location,
           "no-cls",                    # $::opt_no_cls in install-menu-text-pl
           "N"                           => \$opt_no_interaction,
           "no-gui"                      => \$opt_no_gui,
           "non-admin"                   => \$opt_nonadmin,
           "paper=s"                     => \$opt_paper,
           "persistent-downloads!"       => \$opt_persistent_downloads,
           "portable"                    => \$opt_portable,
           "print-platform|print-arch"   => \$opt_print_arch,
           "profile=s"                   => \$opt_profile,
           "scheme|s=s"                  => \$opt_scheme,
           "select-repository"           => \$::opt_select_repository,
           "src-install!"                => \$opt_src_install,
           "tcl",                       # handled by wrapper
           "texdir=s"                    => \$opt_texdir,
           "texmfconfig=s"               => \$pathopts{'texmfconfig'},
           "texmfhome=s"                 => \$pathopts{'texmfhome'},
           "texmflocal=s"                => \$pathopts{'texmflocal'},
           "texmfsysconfig=s"            => \$pathopts{'texmfsysconfig'},
           "texmfsysvar=s"               => \$pathopts{'texmfsysvar'},
           "texmfvar=s"                  => \$pathopts{'texmfvar'},
           "texuserdir=s"                => \$opt_texuserdir,
           "verify-downloads!"           => \$opt_verify_downloads,
           "version"                     => \$opt_version,
           "warn-checksums!"             => \$opt_warn_checksums,
           "help|?"                      => \$opt_help) or pod2usage(2);
if ($from_ext_gui) {
  $opt_gui = "extl";
}

$opt_interaction = 0 if $opt_no_interaction;


if ($opt_help) {
  my @noperldoc = ();
  if (wndws() || $ENV{"NOPERLDOC"}) {
    @noperldoc = ("-noperldoc", "1");
  }

  if (defined($ENV{'LESS'})) {
    $ENV{'LESS'} .= " -R";
  } else {
    $ENV{'LESS'} = "-R";
  }
  delete $ENV{'LESSPIPE'};
  delete $ENV{'LESSOPEN'};

  pod2usage(-exitstatus => 0, -verbose => 2, @noperldoc);
  die "sorry, pod2usage did not work; maybe a download failure?";
}

if ($opt_version) {
  print "install-tl (TeX Live Cross Platform Installer)",
        " revision $::installerrevision\n";
  if (open (REL_TL, "$::installerdir/release-texlive.txt")) {
    my @rel_tl = <REL_TL>;
    print $rel_tl[0];
    print $rel_tl[$#rel_tl];
    close (REL_TL);
  }
  if ($::opt_verbosity > 0) {
    print "Module revisions:";
    print "\nTLConfig: " . TeXLive::TLConfig->module_revision();
    print "\nTLCrypto: " . TeXLive::TLCrypto->module_revision();
    print "\nTLDownload: ".TeXLive::TLDownload->module_revision();
    print "\nTLPDB:    " . TeXLive::TLPDB->module_revision();
    print "\nTLPOBJ:   " . TeXLive::TLPOBJ->module_revision();
    print "\nTLTREE:   " . TeXLive::TLTREE->module_revision();
    print "\nTLUtils:  " . TeXLive::TLUtils->module_revision();
    print "\nTLWinGoo: " . TeXLive::TLWinGoo->module_revision() if wndws();
    print "\n";
  }
  exit 0;
}

if ($opt_print_arch) {
  print platform()."\n";
  exit 0;
}

if (defined($::opt_lang)) {
  $::lang = $::opt_lang;
}
require("TeXLive/trans.pl");
load_translations();


die "$0: Incompatible options: custom-bin and in-place.\n"
  if ($opt_in_place && $opt_custom_bin);

die "$0: Incompatible options: in-place and profile ($opt_profile).\n"
  if ($opt_in_place && $opt_profile);

die "$0: Incompatible options init-from-profile and in-place.\n"
  if ($opt_in_place && $opt_init_from_profile);


if ($#ARGV >= 0) {
  die "$0: Extra arguments `@ARGV'; try --help if you need it.\n";
}


if ($opt_profile) { # not allowed if in_place
  if (-r $opt_profile && -f $opt_profile) {
    info("Automated TeX Live installation using profile: $opt_profile\n");
  } else {
    $opt_profile = "";
    info(
"Profile $opt_profile not readable or not a file, continuing in interactive mode.\n");
  }
}

if ($opt_nonadmin and wndws()) {
  non_admin();
}



our $tlpdb;
my $localtlpdb;
my $location;

@::info_hook = ();

our $media;
our @media_available;

TeXLive::TLUtils::initialize_global_tmpdir();

if (TeXLive::TLCrypto::setup_checksum_method()) {
  if ((defined($opt_verify_downloads) && $opt_verify_downloads)
      ||
      (!defined($opt_verify_downloads))) {
    if (TeXLive::TLCrypto::setup_gpg($::installerdir)) {
      $opt_verify_downloads = 1;
      log("Trying to verify cryptographic signatures!\n")
    } else {
      if ($opt_verify_downloads) {
        tldie("$0: No gpg found, but verification explicitly requested "
              . "on command line, so quitting.\n");
      } else {
        debug("Couldn't detect gpg so will proceed without verification!\n");
      }
    }
  }
} else {
  if ($opt_warn_checksums) {
      tldie(<<END_NO_CHECKSUMS);
$0: Quitting, cannot find a checksum implementation.
Please install Digest::SHA (from CPAN), or openssl, or sha512sum,
or use the --no-warn-checksums command line option.
END_NO_CHECKSUMS
  }
}



if (defined($opt_force_arch)) {
  tlwarn("Overriding platform to $opt_force_arch\n");
  $::_platform_ = $opt_force_arch;
}

platform();
$vars{'this_platform'} = $::_platform_;

if (!$opt_custom_bin && (platform() eq "i386-cygwin")) {
  chomp( my $un = `uname -r`);
  if ($un =~ m/^(\d+)\.(\d+)\./) {
    if ($1 < 2 && $2 < 7) {
      tldie("$0: Sorry, the TL binaries require at least cygwin 1.7, "
            . "not $1.$2\n");
    }
  }
}

{
  my $tmp = $::installerdir;
  $tmp = abs_path($tmp);
  $tmp =~ s,[\\\/]$,,;
  if (-d "$tmp/$Archive") {
    push @media_available, "local_compressed#$tmp";
  }
  if (-r "$tmp/texmf-dist/web2c/texmf.cnf") {
    push @media_available, "local_uncompressed#$tmp";
  }
}

if ($opt_location) {
  my $tmp = $opt_location;
  if ($tmp =~ m!^(https?|ftp)://!i) {
    push @media_available, "NET#$tmp";

  } elsif ($tmp =~ m!^(rsync|)://!i) {
    tldie ("$0: sorry, rsync unsupported; use an http or ftp url here.\n"); 

  } else {
    $tmp =~ s!^file://*!/!i;
    $tmp = abs_path($tmp);
    $tmp =~ s,[\\\/]$,,;
    if (-d "$tmp/$Archive") {
      push @media_available, "local_compressed#$tmp";
    }
    if (-d "$tmp/texmf-dist/web2c") {
      push @media_available, "local_uncompressed#$tmp";
    }
  }
}

if (!setup_programs ("$::installerdir/tlpkg/installer", "$::_platform_")) {
  tldie("$0: Goodbye.\n");
}


if ($opt_profile eq "" && $opt_interaction) {
  if ($opt_init_from_profile) {
    read_profile("$opt_init_from_profile", seed => 1);
  }
  our $MENU_INSTALL = 0;
  our $MENU_ABORT   = 1;
  our $MENU_QUIT    = 2;
  $opt_gui = "text" if ($opt_no_gui);
  my @runargs;
  if ($opt_gui =~ m/^([^:]*):(.*)$/) {
    $opt_gui = $1;
    @runargs = split ",", $2;
  }
  if (-r "$::installerdir/tlpkg/installer/install-menu-${opt_gui}.pl") {
    require("installer/install-menu-${opt_gui}.pl");
  } else {
    tlwarn("UI plugin $opt_gui not found,\n");
    tlwarn("Using text mode installer.\n");
    require("installer/install-menu-text.pl");
  }

  if (!exists $ENV{"TEXLIVE_INSTALL_NO_RESUME"} && $opt_interaction) {
    my $tlmgrwhich = which("tlmgr");
    if ($tlmgrwhich) {
      my $dn = dirname($tlmgrwhich);
      $dn = abs_path("$dn/../..");
      my $install_tl_root = abs_path($::installerdir);
      my $tlpdboldpath
       = $dn .
         "/$TeXLive::TLConfig::InfraLocation/$TeXLive::TLConfig::DatabaseName";
      if (-r $tlpdboldpath && $dn ne $install_tl_root) {
        debug ("found old installation in $dn\n");
        push @runargs, "-old-installation-found=$dn";
      }
    }
  }

  my $ret = &{$::run_menu}(@runargs);
  if ($ret == $MENU_QUIT) {
    do_cleanup(); # log, profile, temp files
    flushlog();
    exit(1);
  } elsif ($ret == $MENU_ABORT) {
    flushlog();
    exit(2);
  }
  if ($ret != $MENU_INSTALL) {
    tlwarn("Unknown return value of run_menu: $ret\n");
    exit(3);
  }
} else { # no interactive setting of options
  if (!do_remote_init()) {
    die ("Exiting installation.\n");
  }
  read_profile($opt_profile) if ($opt_profile ne "");
}

my $varsdump = "";
foreach my $key (sort keys %vars) {
  my $val = $vars{$key} || "";
  $varsdump .= "  $key: \"$val\"\n";
}
log("Settings:\n" . $varsdump);

$vars{'instopt_adjustpath'} = 0 if $vars{'instopt_portable'};
$vars{'tlpdbopt_file_assocs'} = 0 if $vars{'instopt_portable'};
$vars{'tlpdbopt_desktop_integration'} = 0 if $vars{'instopt_portable'};
install_warnlines_hook(); # collect warnings in @::WARNLINES
info("Installing to: $vars{TEXDIR}\n");

if (!$opt_installation) {
  print STDERR "Not doing installation due to --no-installation, terminating here.\n";
  exit 0;
}

$::env_warns = "";
create_welcome();
my $status = 1;
if ($opt_gui eq 'text' or $opt_gui eq 'extl' or $opt_profile ne "") {
  $status = do_installation();
  if (@::WARNLINES) {
    foreach my $t (@::WARNLINES) { print STDERR $t; }
  }
  if ($::env_warns) { tlwarn($::env_warns); }
  unless ($ENV{"TEXLIVE_INSTALL_NO_WELCOME"}) {
    info(join("\n", @::welcome_arr));
  }
  do_cleanup(); # sets $::LOGFILENAME if not already defined
  if ($::LOGFILENAME) {
    print STDOUT "\nLogfile: $::LOGFILENAME\n";
  } else {
    print STDERR
      "Cannot create logfile $vars{'TEXDIR'}/install-tl.log: $!\n";
  }
  printf STDOUT "Installed on platform %s at %s\n",
      $vars{'this_platform'}, $vars{'TEXDIR'} if ($opt_gui eq 'extl');

  if (@::installation_failed_packages) {
    print <<EOF;

*** PLEASE READ THIS WARNING ***********************************

The following (inessential) packages failed to install properly:

  @::installation_failed_packages

You can fix this by running this command:
  tlmgr update --all --reinstall-forcibly-removed
to complete the installation.

However, if the problem was a failure to download (by far the
most common cause), check that you can connect to the chosen mirror
in a browser; you may need to specify a mirror explicitly.
******************************************************************

EOF
  }
}
exit $status;




sub only_load_remote {
  my $selected_location = shift;

  $location = $opt_location;
  $location = $selected_location if defined($selected_location);
  $location || ($location = "$::installerdir");
  if ($location =~ m!^(ctan$|(https?|ftp)://)!i) {
    $location =~ s,/(tlpkg(/texlive\.tlpdb)?|archive)?/*$,,;
    if ($location =~ m/^ctan$/i) {
      $location = TeXLive::TLUtils::give_ctan_mirror();
    } elsif ($location =~ m/^$TeXLiveServerURLRegexp/) {
      my $mirrorbase = TeXLive::TLUtils::give_ctan_mirror_base();
      $location =~ s,^($TeXLiveServerURLRegexp|ctan$),$mirrorbase,;
    }
    $TeXLiveURL = $location;
    $media = 'NET';
  } else {
    if (scalar grep($_ =~ m/^local_compressed/, @media_available)) {
      $media = 'local_compressed';
      $media = 'local_uncompressed' if $opt_in_place &&
        member('local_uncompressed', @media_available);
    } elsif (scalar grep($_ =~ m/^local_uncompressed/, @media_available)) {
      $media = 'local_uncompressed';
    } else {
      if ($opt_location) {
        die "$0: cannot find installation source at $opt_location.\n";
      }
      $TeXLiveURL = $location = TeXLive::TLUtils::give_ctan_mirror();
      $media = 'NET';
    }
  }
  if ($from_ext_gui) {print "location: $location\n";}
  return load_tlpdb();
} # only_load_remote

sub do_remote_init {
  if (!only_load_remote(@_)) {
    tlwarn("$0: Could not load TeX Live Database from $location, goodbye.\n");
    return 0;
  }
  if (!do_version_agree()) {
    TeXLive::TLUtils::tldie <<END_MISMATCH;
=============================================================================
$0: The TeX Live versions of the local installation
and the repository being accessed are not compatible:
      local: $TeXLive::TLConfig::ReleaseYear
 repository: $texlive_release
Perhaps you need to use a different CTAN mirror?
(For more, see the output of install-tl --help, especially the
 -repository option.  Online via https://tug.org/texlive/doc.)
=============================================================================
END_MISMATCH
  }
  final_remote_init();
  return 1;
} # do_remote_init

sub do_version_agree {
  $texlive_release = $tlpdb->config_release;
  if ($media eq "local_uncompressed") {
    $texlive_release ||= $TeXLive::TLConfig::ReleaseYear;
  }

  if ($media eq "NET"
      && $texlive_release !~ m/^$TeXLive::TLConfig::ReleaseYear/) {
    return 0;
  } else {
    return 1;
  }
} # do_version_agree

sub final_remote_init {
  info("Installing TeX Live $TeXLive::TLConfig::ReleaseYear from: $location" .
    ($tlpdb->is_verified ? " (verified)" : " (not verified)") . "\n");

  info("Platform: ", platform(), " => \'", platform_desc(platform), "\'\n");
  if ($opt_custom_bin) {
    if (-d $opt_custom_bin && (-r "$opt_custom_bin/kpsewhich"
                               || -r "$opt_custom_bin/kpsewhich.exe")) {
      info("Platform overridden, binaries taken from $opt_custom_bin\n"
           . "and will be installed into .../bin/custom.\n");
    } else {
      tldie("$0: -custom-bin argument must be a directory "
            . "with TeX Live binaries, not like: $opt_custom_bin\n");
    }
  }
  if ($media eq "local_uncompressed") {
    info("Distribution: live (uncompressed)\n");
  } elsif ($media eq "local_compressed") {
    info("Distribution: inst (compressed)\n");
  } elsif ($media eq "NET") {
    info("Distribution: net  (downloading)\n");
    info("Using URL: $TeXLiveURL\n");
    TeXLive::TLUtils::setup_persistent_downloads(
      "$::installerdir/tlpkg/installer/curl/curl-ca-bundle.crt"
    ) if $opt_persistent_downloads;
  } else {
    info("Distribution: $media\n");
  }
  info("Directory for temporary files: $::tl_tmpdir\n");

  if ($opt_in_place and ($media ne "local_uncompressed")) {
    print "TeX Live not local or not decompressed; 'in_place' option not applicable\n";
    $opt_in_place = 0;
  } elsif (
      $opt_in_place and (!TeXLive::TLUtils::texdir_check($::installerdir))) {
    print "Installer dir not writable; 'in_place' option not applicable\n";
    $opt_in_place = 0;
  }
  $opt_scheme = "" if $opt_in_place;
  $vars{'instopt_portable'} = $opt_portable;
  $vars{'instopt_adjustpath'} = 1 if wndws();

  log("Installer revision: $::installerrevision\n");
  log("Database revision: " . $tlpdb->config_revision . "\n");

  if (($media eq "NET") || ($media eq "local_compressed")) {
    $vars{'src_splitting_supported'} = $tlpdb->config_src_container;
    $vars{'doc_splitting_supported'} = $tlpdb->config_doc_container;
  }
  set_platforms_supported();
  set_texlive_default_dirs();
  set_install_platform();
  initialize_collections();
  $vars{'free_size'} = TeXLive::TLUtils::diskfree($vars{'TEXDIR'});

  update_default_scheme();
  update_default_paper();
  update_default_src_doc_install();
} # final_remote_init

sub update_default_scheme {
  if ($opt_scheme) {
    $opt_scheme = "scheme-$opt_scheme" if $opt_scheme !~ /^scheme-/;
    $opt_scheme .= "only" if $opt_scheme eq "scheme-infra";
    my $scheme = $tlpdb->get_package($opt_scheme);
    if (defined($scheme)) {
      select_scheme($opt_scheme);  # select it
    } else {
      tlwarn("Scheme $opt_scheme not defined, ignoring it.\n");
    }
  }
} # update_default_scheme

sub update_default_paper {
  my $env_paper = $ENV{"TEXLIVE_INSTALL_PAPER"};
  if ($opt_paper) {
    if (defined $env_paper && $env_paper ne $opt_paper) {
      tlwarn("$0: paper selected via both envvar TEXLIVE_INSTALL_PAPER and\n");
      tlwarn("$0:   cmdline arg --paper, preferring the latter: $opt_paper\n");
    }
    if ($opt_paper eq "letter") { $vars{'instopt_letter'} = 1; }
    elsif ($opt_paper eq "a4")  { $vars{'instopt_letter'} = 0; }
    else {
      tlwarn("$0: cmdline option --paper value must be letter or a4, not: "
             . "$opt_paper (ignoring)\n");
    }
  } elsif ($env_paper) {
    if ($env_paper eq "letter") { $vars{'instopt_letter'} = 1; } 
    elsif ($env_paper eq "a4") { ; } # do nothing
    else {
      tlwarn("$0: TEXLIVE_INSTALL_PAPER value must be letter or a4, not: "
             . "$env_paper (ignoring)\n");
    }
  }
} # update_default_paper

sub update_default_src_doc_install {
  if (! $opt_src_install) {
    $vars{'tlpdbopt_install_srcfiles'} = 0;
  }
  if (! $opt_doc_install) {
    $vars{'tlpdbopt_install_docfiles'} = 0;
  }
} # update_default_src_doc_install



sub do_installation {
  if (wndws()) {
    non_admin() if !$vars{'tlpdbopt_w32_multi_user'};
  }
  if ($vars{'instopt_portable'}) {
    $vars{'tlpdbopt_desktop_integration'} = 0;
    $vars{'tlpdbopt_file_assocs'} = 0;
    $vars{'instopt_adjustpath'} = 0;
    $vars{'tlpdbopt_w32_multi_user'} = 0;
  }
  if ($vars{'selected_scheme'} ne "scheme-infraonly"
      && $vars{'n_collections_selected'} <= 0) {
    tldie("$0: Nothing selected, nothing to install, exiting!\n");
  }
  for my $v (qw/TEXDIR TEXMFLOCAL TEXMFSYSVAR TEXMFSYSCONFIG/) {
    $vars{$v} = TeXLive::TLUtils::expand_tilde($vars{$v}) if ($vars{$v});
  }
  mkdirhier "$vars{'TEXDIR'}";
  if (wndws()) {
    TeXLive::TLWinGoo::maybe_make_ro ($vars{'TEXDIR'});
  }
  my $diskfree = TeXLive::TLUtils::diskfree($vars{'TEXDIR'});
  if ($diskfree != -1) {
    my $reserve = 100;
    if ($diskfree < $reserve + $vars{'total_size'}) {
      my $msg = "($diskfree free < $reserve reserve "
                . "+ installed $vars{total_size})";
      if ($ENV{'TEXLIVE_INSTALL_NO_DISKCHECK'}) {
        tlwarn("$0: Insufficient disk space\n$msg\n"
          ." but continuing anyway per envvar TEXLIVE_INSTALL_NO_DISKCHECK\n");
      } else {
        tldie("$0: DISK SPACE INSUFFICIENT!\n$msg\nAborting installation.\n"
            . "  To skip the check, set the environment variable\n"
            . "  TEXLIVE_INSTALL_NO_DISKCHECK=1\n");
      }
    }
  }
  $vars{'TEXDIR'} =~ s!/$!!;
  make_var_skeleton "$vars{'TEXMFSYSVAR'}";
  my $oldlocal = -d $vars{'TEXMFLOCAL'};
  make_local_skeleton "$vars{'TEXMFLOCAL'}";
  mkdirhier "$vars{'TEXMFSYSCONFIG'}";
  if (wndws()) {
    TeXLive::TLWinGoo::maybe_make_ro ($vars{'TEXMFSYSVAR'});
    TeXLive::TLWinGoo::maybe_make_ro ($vars{'TEXMFLOCAL'}) unless $oldlocal;
    TeXLive::TLWinGoo::maybe_make_ro ($vars{'TEXMFSYSCONFIG'});
  }

  if ($opt_in_place) {
    $localtlpdb = $tlpdb;
  } else {
    $localtlpdb=new TeXLive::TLPDB;
    $localtlpdb->root("$vars{'TEXDIR'}");
  }
  if (!$opt_in_place) {
    if (-e "$::installerdir/release-texlive.txt"
        && ! -e "$vars{TEXDIR}/release-texlive.txt") {
      copy("$::installerdir/release-texlive.txt", "$vars{TEXDIR}/");
    }
    calc_depends();
    save_options_into_tlpdb();
    mkdirhier "$vars{'TEXDIR'}/texmf-dist";
    do_install_packages();
    if ($opt_custom_bin) {
      $vars{'this_platform'} = "custom";
      my $TEXDIR="$vars{'TEXDIR'}";
      mkdirhier("$TEXDIR/bin/custom");
      for my $f (<$opt_custom_bin/*>) {
        copy($f, "$TEXDIR/bin/custom");
      }
    }
  }
  foreach my $s ($tlpdb->schemes) {
    my $stlp = $tlpdb->get_package($s);
    die ("This cannot happen, $s not defined in tlpdb") if ! defined($stlp);
    my $incit = 1;
    foreach my $d ($stlp->depends) {
      if (!defined($localtlpdb->get_package($d))) {
        $incit = 0;
        last;
      }
    }
    if ($incit) {
      $localtlpdb->add_tlpobj($stlp);
    }
  }
  
  my $tlpobj = new TeXLive::TLPOBJ;
  $tlpobj->name("00texlive.config");
  my $t = $tlpdb->get_package("00texlive.config");
  $tlpobj->depends("minrelease/" . $tlpdb->config_minrelease,
                   "release/"    . $tlpdb->config_release);
  $localtlpdb->add_tlpobj($tlpobj);  
  
  $localtlpdb->save unless $opt_in_place;

  my $errcount = do_postinst_stuff();


  check_env() unless $ENV{"TEXLIVE_INSTALL_ENV_NOCHECK"};


  if (@::WARNLINES) {
    unshift @::WARNLINES, ("\nSummary of warnings:\n");
  }
  my $status = 0;
  if ($errcount > 0) {
    $status = 1;
    warn "\n$0: errors in installation reported above\n";
  }

  return $status;
} # do_installation

sub run_postinst_cmd {
  my ($cmd) = @_;
  &TeXLive::TLUtils::run_cmd_with_log ($cmd, \&log);
}

sub do_postinst_stuff {
  my $TEXDIR = $vars{'TEXDIR'};
  my $TEXMFSYSVAR = $vars{'TEXMFSYSVAR'};
  my $TEXMFSYSCONFIG = $vars{'TEXMFSYSCONFIG'};
  my $TEXMFVAR = $vars{'TEXMFVAR'};
  my $TEXMFCONFIG = $vars{'TEXMFCONFIG'};
  my $TEXMFLOCAL = $vars{'TEXMFLOCAL'};
  my $tmv;

  do_texmf_cnf();

  if (-d "$TEXDIR/$TeXLive::TLConfig::RelocTree/tlpkg") {
    rmtree("$TEXDIR/TeXLive::TLConfig::RelocTree/tlpkg");
  }

  mkdirhier("$TEXDIR/$TeXLive::TLConfig::PackageBackupDir");


  %origenv = %ENV;
  my @TMFVARS=qw(VARTEXFONTS
    TEXMF SYSTEXMF VARTEXFONTS
    TEXMFDBS WEB2C TEXINPUTS TEXFORMATS MFBASES MPMEMS TEXPOOL MFPOOL MPPOOL
    PSHEADERS TEXFONTMAPS TEXPSHEADERS TEXCONFIG TEXMFCNF
    TEXMFMAIN TEXMFDIST TEXMFLOCAL TEXMFSYSVAR TEXMFSYSCONFIG
    TEXMFVAR TEXMFCONFIG TEXMFHOME TEXMFCACHE);

  if (defined($ENV{'TEXMFCNF'})) {
    tlwarn "WARNING: environment variable TEXMFCNF is set.
You should know what you are doing.
We will unset it for the post-install actions, but all further
operations might be disturbed.\n\n";
  }
  foreach $tmv (@TMFVARS) {
    delete $ENV{$tmv} if (defined($ENV{$tmv}));
  }


  my $pathsep = (wndws())? ';' : ':';
  my $plat_bindir = "$TEXDIR/bin/$vars{'this_platform'}";
  my $perl_bindir = "$TEXDIR/tlpkg/tlperl/bin";
  my $perl_libdir = "$TEXDIR/tlpkg/tlperl/lib";
  my $progext = (wndws())? '.exe' : '';

  debug("Prepending $plat_bindir to PATH\n");
  $ENV{'PATH'} = $plat_bindir . $pathsep . $ENV{'PATH'};

  if (wndws()) {
    debug("Prepending $perl_bindir to PATH\n");
    $ENV{'PATH'} = "$perl_bindir" . "$pathsep" . "$ENV{'PATH'}";
    $ENV{'PATH'} =~ s!/!\\!g;
  }

  debug("\nNew PATH is:\n");
  foreach my $dir (split $pathsep, $ENV{'PATH'}) {
    debug("  $dir\n");
  }
  debug("\n");
  if (wndws()) {
    $ENV{'PERL5LIB'} = $perl_libdir;
  }


  my $usedtlpdb = $opt_in_place ? $tlpdb : $localtlpdb;

  if (wndws()) {
    debug("Actual environment:\n" . `set` ."\n\n");
    debug("Effective TEXMFCNF: " . `kpsewhich -expand-path=\$TEXMFCNF` ."\n");
  }

  my $errcount = 0;

  if (!$opt_in_place) {
    wsystem("running", 'mktexlsr', "$TEXDIR/texmf-dist") && exit(1);
  }


  mkdirhier "$TEXDIR/texmf-dist/web2c";
  info("writing fmtutil.cnf to $TEXDIR/texmf-dist/web2c/fmtutil.cnf\n");
  TeXLive::TLUtils::create_fmtutil($usedtlpdb,
    "$TEXDIR/texmf-dist/web2c/fmtutil.cnf");

  if (-r "$TEXMFLOCAL/web2c/fmtutil-local.cnf") {
    tlwarn("Old configuration file $TEXMFLOCAL/web2c/fmtutil-local.cnf found.\n");
    tlwarn("fmtutil now reads *all* fmtutil.cnf files, so probably the easiest way\nis to rename the above file to $TEXMFLOCAL/web2c/fmtutil.cnf\n");
  }

  info("writing updmap.cfg to $TEXDIR/texmf-dist/web2c/updmap.cfg\n");
  TeXLive::TLUtils::create_updmap ($usedtlpdb,
    "$TEXDIR/texmf-dist/web2c/updmap.cfg");

  info("writing language.dat to $TEXMFSYSVAR/tex/generic/config/language.dat\n");
  TeXLive::TLUtils::create_language_dat($usedtlpdb,
    "$TEXMFSYSVAR/tex/generic/config/language.dat",
    "$TEXMFLOCAL/tex/generic/config/language-local.dat");

  info("writing language.def to $TEXMFSYSVAR/tex/generic/config/language.def\n");
  TeXLive::TLUtils::create_language_def($usedtlpdb,
    "$TEXMFSYSVAR/tex/generic/config/language.def",
    "$TEXMFLOCAL/tex/generic/config/language-local.def");

  info("writing language.dat.lua to $TEXMFSYSVAR/tex/generic/config/language.dat.lua\n");
  TeXLive::TLUtils::create_language_lua($usedtlpdb,
    "$TEXMFSYSVAR/tex/generic/config/language.dat.lua",
    "$TEXMFLOCAL/tex/generic/config/language-local.dat.lua");

  wsystem("running", "mktexlsr",
                     $TEXMFSYSVAR, $TEXMFSYSCONFIG, "$TEXDIR/texmf-dist")
  && exit(1);

  if (-x "$plat_bindir/updmap-sys$progext") {
    $errcount += run_postinst_cmd("updmap-sys --nohash");
  } else {
    info("not running updmap-sys (not installed)\n");
  }


  if ($vars{'instopt_letter'}) {
    info("setting default paper size to letter:\n");
    $errcount += run_postinst_cmd("tlmgr --no-execute-actions paper letter");
  }

  if (wndws() && !$vars{'instopt_portable'}) {
    if ($vars{'tlpdbopt_file_assocs'} != 1 || !$vars{'instopt_adjustpath'}) {
      rewrite_tlaunch_ini();
    }
  }

  wsystem("re-running", "mktexlsr", $TEXMFSYSVAR, $TEXMFSYSCONFIG) && exit(1);

  if (wndws() and !$vars{'instopt_portable'} and !$opt_in_place) {
    if ($vars{'tlpdbopt_desktop_integration'} != 2) {
      create_uninstaller($vars{'TEXDIR'});
    } else {
      $errcount += wsystem (
        'Running','tlaunch.exe',
        admin() ? 'admin_inst_silent' : 'user_inst_silent');
    }
  }

  if (exists($install{"context"}) && $install{"context"} == 1
      && !exists $ENV{"TEXLIVE_INSTALL_NO_CONTEXT_CACHE"}) {
    $errcount +=
      TeXLive::TLUtils::update_context_cache($plat_bindir, $progext,
                                             \&run_postinst_cmd);
  } else {
    debug("skipped ConTeXt cache setup, not installed or told not to\n");
  }

  if ($vars{'tlpdbopt_create_formats'}) {
    if (-x "$plat_bindir/fmtutil-sys$progext") {
      info("pre-generating all format files, be patient...\n");
      $errcount += run_postinst_cmd(
                     "fmtutil-sys $common_fmtutil_args --no-strict --all");
    } else {
      info("not running fmtutil-sys (script not installed)\n");
    }
  } else {
    info("not running fmtutil-sys (user option create_formats=0)\n");
  }

  $errcount += do_path_adjustments() if
    $vars{'instopt_adjustpath'} and $vars{'tlpdbopt_desktop_integration'} != 2;

  $errcount += do_tlpdb_postactions();
  
  return $errcount;
} # do_postinst_stuff



sub do_tlpdb_postactions {
  info ("running package-specific postactions\n");

  my $usedtlpdb = $opt_in_place ? $tlpdb : $localtlpdb;
  my $ret = 0; # n. of errors

  foreach my $package ($usedtlpdb->list_packages) {
    if ($vars{'tlpdbopt_desktop_integration'}==2) {
      if (!TeXLive::TLUtils::do_postaction(
        "install", $usedtlpdb->get_package($package),
        0, 0, 0, $vars{'tlpdbopt_post_code'})) { $ret += 1; }
    } else {
      if (!TeXLive::TLUtils::do_postaction(
        "install", $usedtlpdb->get_package($package),
        $vars{'tlpdbopt_file_assocs'},
        $vars{'tlpdbopt_desktop_integration'}, 0,
        $vars{'tlpdbopt_post_code'})) { $ret += 1; }
    }
  }
  if (wndws()) { TeXLive::TLWinGoo::update_assocs(); }
  info ("finished with package-specific postactions\n");
  return $ret;
} # do_tlpdb_postactions

sub rewrite_tlaunch_ini {
  my $ret = 0; # n. of errors

  chomp( my $tmfmain = `kpsewhich -var-value=TEXMFMAIN` ) ;
  chomp( my $tmfsysvar = `kpsewhich -var-value=TEXMFSYSVAR` ) ;
  if (open IN, "$tmfmain/web2c/tlaunch.ini") {
    my $eolsave = $/;
    undef $/;
    my $ini = <IN>;
    close IN;
    $ini =~ s/\r\n/\n/g;
    $ini =~ s/\[general[^\[]*//si;
    mkdirhier("$tmfsysvar/web2c");
    if (open OUT, ">", "$tmfsysvar/web2c/tlaunch.ini") {
      my @fts = ('none', 'new', 'overwrite');
      $\ = "\n";
      print OUT $ini;
      print OUT "[General]";
      print OUT "FILETYPES=$fts[$vars{'tlpdbopt_file_assocs'}]";
      print OUT "SEARCHPATH=$vars{'instopt_adjustpath'}\n";
      close OUT;
      `mktexlsr $tmfsysvar`;
    } else {
      $ret += 1;
      tlwarn("Cannot write modified tlaunch.ini\n");
    }
    $/ = $eolsave;
  } else {
    $ret += 1;
    tlwarn("Cannot open tlaunch.ini for reading\n");
  }
  return $ret;
} # rewrite_tlaunch_ini

sub do_path_adjustments {
  my $ret = 0;
  info ("running path adjustment actions\n");
  if (wndws()) {
    TeXLive::TLUtils::w32_add_to_path($vars{'TEXDIR'} . '/bin/windows',
      $vars{'tlpdbopt_w32_multi_user'});
    broadcast_env();
  } else {
    if ($F_OK != TeXLive::TLUtils::add_symlinks($vars{'TEXDIR'}, 
         $vars{'this_platform'},
         $vars{'tlpdbopt_sys_bin'}, $vars{'tlpdbopt_sys_man'},
         $vars{'tlpdbopt_sys_info'})) {
      $ret = 1;
    }
  }
  info ("finished with path adjustment actions\n");
  return $ret;
} # do_path_adjustments

sub do_texmf_cnf {
  open(TMF,"<$vars{'TEXDIR'}/texmf-dist/web2c/texmf.cnf")
      or die "$vars{'TEXDIR'}/texmf-dist/web2c/texmf.cnf not found: $!";
  my @texmfcnflines = <TMF>;
  close(TMF);

  my @changedtmf = ();  # install to disk: write only changed items

  my $yyyy = $TeXLive::TLConfig::ReleaseYear;

  foreach my $line (@texmfcnflines) {
    if ($line =~ m/^TEXMFLOCAL\b/) { # don't find TEXMFLOCALEDIR
      my $deftmflocal = Cwd::abs_path($vars{'TEXDIR'}.'/../texmf-local');
      if (!defined $deftmflocal       # in case abs_path couldn't resolve
          || Cwd::abs_path($vars{TEXMFLOCAL}) ne "$deftmflocal") {
        push @changedtmf, "TEXMFLOCAL = $vars{'TEXMFLOCAL'}\n";
      }
    } elsif ($line =~ m/^TEXMFSYSVAR/) {
      if ("$vars{'TEXMFSYSVAR'}" ne "$vars{'TEXDIR'}/texmf-var") {
        push @changedtmf, "TEXMFSYSVAR = $vars{'TEXMFSYSVAR'}\n";
      }
    } elsif ($line =~ m/^TEXMFSYSCONFIG/) {
      if ("$vars{'TEXMFSYSCONFIG'}" ne "$vars{'TEXDIR'}/texmf-config") {
        push @changedtmf, "TEXMFSYSCONFIG = $vars{'TEXMFSYSCONFIG'}\n";
      }
    } elsif ($line =~ m/^TEXMFVAR/ && !$vars{'instopt_portable'}) {
      if ($vars{"TEXMFVAR"} ne "~/.texlive$yyyy/texmf-var") {
        push @changedtmf, "TEXMFVAR = $vars{'TEXMFVAR'}\n";
      }
    } elsif ($line =~ m/^TEXMFCONFIG/ && !$vars{'instopt_portable'}) {
      if ("$vars{'TEXMFCONFIG'}" ne "~/.texlive$yyyy/texmf-config") {
        push @changedtmf, "TEXMFCONFIG = $vars{'TEXMFCONFIG'}\n";
      }
    } elsif ($line =~ m/^TEXMFHOME/ && !$vars{'instopt_portable'}) {
      if ("$vars{'TEXMFHOME'}" ne "~/texmf") {
        push @changedtmf, "TEXMFHOME = $vars{'TEXMFHOME'}\n";
      }
    } elsif ($line =~ m/^OSFONTDIR/) {
      if (wndws()) {
        push @changedtmf, "OSFONTDIR = \$SystemRoot/fonts//;\$LOCALAPPDATA/Microsoft/Windows/Fonts//\n";
      }
    }
  }

  if ($vars{'instopt_portable'}) {
    push @changedtmf, "ASYMPTOTE_HOME = \$TEXMFCONFIG/asymptote\n";
  }

  my ($TMF, $TMFLUA);
  $TMF = ">$vars{'TEXDIR'}/texmf.cnf";
  open(TMF, $TMF) || die "open($TMF) failed: $!";
  print TMF <<EOF;
% (Public domain.)
% This texmf.cnf file should contain only your personal changes from the
% original texmf.cnf (for example, as chosen in the installer).
%
% That is, if you need to make changes to texmf.cnf, put your custom
% settings in this file, which is .../texlive/YYYY/texmf.cnf, rather than
% the distributed file (which is .../texlive/YYYY/texmf-dist/web2c/texmf.cnf).
% And include *only* your changed values, not a copy of the whole thing!
%
EOF
  foreach (@changedtmf) {
    s/^(TEXMF\w+\s*=\s*)\Q$vars{'TEXDIR'}\E/$1\$SELFAUTOPARENT/;
    print TMF;
  }
  if ($vars{'instopt_portable'}) {
    print TMF "TEXMFHOME = \$TEXMFLOCAL\n";
    print TMF "TEXMFVAR = \$TEXMFSYSVAR\n";
    print TMF "TEXMFCONFIG = \$TEXMFSYSCONFIG\n";
  }
  if (!$vars{"instopt_write18_restricted"}) {
    print TMF <<EOF;

% Disable system commands via \\write18{...}.  See texmf-dist/web2c/texmf.cnf.
shell_escape = 0
EOF
;
  }

  if (wndws()) {
    my $use_ext = 0;
    if (!$vars{'instopt_portable'} &&
          defined $ENV{'extperl'} &&  $ENV{'extperl'} =~ /^(\d+\.\d+)/) {
      $use_ext = 1 if $1 >= 5.14;
    }
    print TMF <<EOF;

% Prefer external Perl for third-party TeXLive Perl scripts
% Was set to 1 if at install time a sufficiently recent Perl was detected.
EOF
;
    print TMF "TEXLIVE_WINDOWS_TRY_EXTERNAL_PERL = " . $use_ext;
    log("Configuring for using external perl for third-party scripts\n")
  }

  close(TMF) || warn "close($TMF) failed: $!";

  $TMFLUA = ">$vars{'TEXDIR'}/texmfcnf.lua";
  open(TMFLUA, $TMFLUA) || die "open($TMFLUA) failed: $!";
    print TMFLUA <<EOF;
-- (Public domain.)
-- This texmfcnf.lua file should contain only your personal changes from the
-- original texmfcnf.lua (for example, as chosen in the installer).
--
-- That is, if you need to make changes to texmfcnf.lua, put your custom
-- settings in this file, which is .../texlive/YYYY/texmfcnf.lua, rather than
-- the distributed file (.../texlive/YYYY/texmf-dist/web2c/texmfcnf.lua).
-- And include *only* your changed values, not a copy of the whole thing!

return { 
  content = {
    variables = {
EOF
;
  foreach (@changedtmf) {
    my $luavalue = $_;
    $luavalue =~ s/^(\w+\s*=\s*)(.*)\s*$/$1\"$2\",/;
    $luavalue =~ s/\$SELFAUTOPARENT/selfautoparent:/g;
    print TMFLUA "      $luavalue\n";
  }
  if ($vars{'instopt_portable'}) {
    print TMFLUA "      TEXMFHOME = \"\$TEXMFLOCAL\",\n";
    print TMFLUA "      TEXMFVAR = \"\$TEXMFSYSVAR\",\n";
    print TMFLUA "      TEXMFCONFIG = \"\$TEXMFSYSCONFIG\",\n";
  }
  print TMFLUA "    },\n";
  print TMFLUA "  },\n";
  if (!$vars{"instopt_write18_restricted"}) {
    print TMFLUA <<EOF;
  directives = {
       -- Disable system commands.  See texmf-dist/web2c/texmfcnf.lua
    ["system.commandmode"]       = "none",
  },
EOF
;
  }
  print TMFLUA "}\n";
  close(TMFLUA) || warn "close($TMFLUA) failed: $!";
} # do_texmf_cnf

sub set_platforms_supported {
  my @binaries = $tlpdb->available_architectures;
  for my $binary (@binaries) {
    unless (defined $vars{"binary_$binary"}) {
      $vars{"binary_$binary"}=0;
    }
  }
  for my $key (keys %vars) {
    ++$vars{'n_systems_available'} if ($key=~/^binary/);
  }
} # set_platforms_supported

sub dump_vars {
  my $filename=shift;
  my $fh;
  if (ref($filename)) {
    $fh = $filename;
  } else {
    open VARS, ">$filename";
    $fh = \*VARS;
  }
  foreach my $key (keys %vars) {
    print $fh "$key $vars{$key}\n";
  }
  close VARS if (!ref($filename));
  debug("\n%vars dumped to '$filename'.\n");
} # dump_vars



sub set_var_from_alternatives {
  my ($what, $whatref, @alternatives) = @_;
  my @alt_text;
  for my $i (@alternatives) {
    push @alt_text, ($i ? $i : "undef")
  }
  my $final;
  while (@alternatives) {
    my $el = pop @alternatives;
    $final = $el if ($el);
  }
  debug("setting $what to $final from @alt_text\n");
  $$whatref = $final;
}

sub set_standard_var {
  my ($what, $envstr, $cmdlinestr, $default) = @_;
  my $envvar = getenv($envstr);
  my $cmdlinevar = $pathopts{$cmdlinestr};
  my %nrdefs;
  $nrdefs{$vars{$what}} = 1 if ($vars{$what});
  $nrdefs{$envvar} = 1 if ($envvar);
  $nrdefs{$cmdlinevar} = 1 if ($cmdlinevar);
  my $actual_cmdline_str = $cmdlinestr;
  my $actual_cmdline_var = $cmdlinevar;
  if ($opt_texuserdir) {
    if ($cmdlinestr eq "texmfhome" || $cmdlinestr eq "texmfvar" || $cmdlinestr eq "texmfconfig") {
      $actual_cmdline_str = "opt_texuserdir";
      $actual_cmdline_var = $opt_texuserdir;
    }
  }
  if (scalar keys %nrdefs > 1) {
    tlwarn("Trying to define $what via conflicting settings:\n");
    tlwarn("  from envvar $envstr = $envvar\n") if ($envvar);
    tlwarn("  from profile = $vars{$what}\n") if ($vars{$what});
    tlwarn("  from command line argument $actual_cmdline_str = $actual_cmdline_var\n") if ($actual_cmdline_var);
    tlwarn("  Preferring the last value from above!\n");
  }
  set_var_from_alternatives( $what, \$vars{$what},
    $cmdlinevar,
    $vars{$what},
    $envvar,
    $default);
}

sub set_texlive_default_dirs {
  my $homedir = (platform() =~ m/darwin/) ? "~/Library" : "~";
  my $yyyy = $TeXLive::TLConfig::ReleaseYear;
  if ($opt_texuserdir) {
    $pathopts{'texmfhome'} = "$opt_texuserdir/texmf" if (!$pathopts{'texmfhome'});
    $pathopts{'texmfvar'} = "$opt_texuserdir/texmf-var" if (!$pathopts{'texmfvar'});
    $pathopts{'texmfconfig'} = "$opt_texuserdir/texmf-config" if (!$pathopts{'texmfconfig'});
  }
  if ($opt_texdir && $vars{'TEXDIR'}) {
    if ($opt_texdir ne $vars{'TEXDIR'}) {
      tlwarn("Conflicting settings for installation path given:\n");
      tlwarn("  from profile TEXDIR = $vars{'TEXDIR'}\n");
      tlwarn("  from command line option --texdir = $opt_texdir\n");
      tlwarn("  Preferring the command line value!\n");
    }
  }
  my $tlprefixenv = getenv('TEXLIVE_INSTALL_PREFIX');
  if ($tlprefixenv && ($opt_texdir || $vars{'TEXDIR'})) {
    tlwarn("Trying to set up basic path using two incompatible methods:\n");
    tlwarn("  from envvar TEXLIVE_INSTALL_PREFIX = $tlprefixenv\n");
    tlwarn("  from profile TEXDIR = $vars{'TEXDIR'}\n") if ($vars{'TEXDIR'});
    tlwarn("  from command line option --texdir = $opt_texdir\n") if ($opt_texdir);
    tlwarn("  Preferring the later value!\n");
    $tlprefixenv = undef;
  }
  my $tex_prefix;
  set_var_from_alternatives("TEX_PREFIX", \$tex_prefix,
    ($opt_in_place ? abs_path($::installerdir) : undef),
    $tlprefixenv,
    (wndws() ? getenv('SystemDrive') . '/texlive' : '/usr/local/texlive'));
  set_var_from_alternatives("TEXDIR", \$vars{'TEXDIR'},
    $opt_texdir,
    $vars{'TEXDIR'},
    ($vars{'instopt_portable'} || $opt_in_place)
      ? $tex_prefix : "$tex_prefix/$texlive_release");
  set_standard_var('TEXMFSYSVAR', 'TEXLIVE_INSTALL_TEXMFSYSVAR',
                   'texmfsysvar', "$vars{'TEXDIR'}/texmf-var");
  set_standard_var('TEXMFSYSCONFIG', 'TEXLIVE_INSTALL_TEXMFSYSCONFIG',
                   'texmfsysconfig', "$vars{'TEXDIR'}/texmf-config");
  set_standard_var('TEXMFLOCAL', 'TEXLIVE_INSTALL_TEXMFLOCAL',
                   'texmflocal', ($opt_texdir ? "$vars{'TEXDIR'}/texmf-local" :"$tex_prefix/texmf-local"));
  set_standard_var('TEXMFHOME', 'TEXLIVE_INSTALL_TEXMFHOME',
                   'texmfhome', "$homedir/texmf");
  set_standard_var('TEXMFVAR', 'TEXLIVE_INSTALL_TEXMFVAR', 'texmfvar',
    (platform() =~ m/darwin/) ? "$homedir/texlive/$yyyy/texmf-var"
                              : "$homedir/.texlive$yyyy/texmf-var");
  set_standard_var('TEXMFCONFIG', 'TEXLIVE_INSTALL_TEXMFCONFIG', 'texmfconfig',
    (platform() =~ m/darwin/) ? "$homedir/texlive/$yyyy/texmf-config"
                              : "$homedir/.texlive$yyyy/texmf-config");

  if ($vars{'instopt_portable'}) {
    $vars{'TEXMFHOME'}   = "\$TEXMFLOCAL";
    $vars{'TEXMFVAR'}    = "\$TEXMFSYSVAR";
    $vars{'TEXMFCONFIG'} = "\$TEXMFSYSCONFIG";
  }

  if ($opt_debug_setup_vars) {
    print "DV:final values from setup of paths:\n";
    for my $i (qw/TEXDIR TEXMFSYSVAR TEXMFSYSCONFIG TEXMFHOME TEXMFVAR
                  TEXMFCONFIG TEXMFLOCAL/) {
      print "$i = $vars{$i}\n";
    }
  }
} # set_texlive_default_dirs


sub calc_depends {
  %install=();
  my $p;
  my $a;


  if ($vars{'selected_scheme'} ne "scheme-custom") {
    my $scheme=$tlpdb->get_package($vars{'selected_scheme'});
    if (!defined($scheme)) {
      if ($vars{'selected_scheme'}) {
        die ("Scheme $vars{'selected_scheme'} not defined, vars:\n");
        dump_vars(\*STDOUT);
      }
    } else {
      for my $scheme_content ($scheme->depends) {
        $install{"$scheme_content"}=1 unless $scheme_content =~ /^collection-/;
      }
    }
  }

  foreach my $key (keys %vars) {
    if ($key=~/^collection-/) {
      $install{$key} = 1 if $vars{$key};
    }
  }

  my @archs;
  foreach (keys %vars) {
    if (m/^binary_(.*)$/ ) {
      if ($vars{$_}) { push @archs, $1; }
    }
  }

  for my $p (@TeXLive::TLConfig::InstallExtraRequiredPackages) {
    $install{$p} = 1;
  }

  if (grep(/^windows$/,@archs)) {
    $install{"tlperl.windows"} = 1;
    $install{"tlgs.windows"} = 1;
  }

  my $changed = 1;
  while ($changed) {
    $changed = 0;

    my @pre_selected = keys %install;
    debug("calc_depends: number of packages to install: $#pre_selected\n");

    foreach $p (@pre_selected) {
      ddebug("pre_selected $p\n");
      my $pkg = $tlpdb->get_package($p);
      if (!defined($pkg)) {
        tlwarn("$p is mentioned somewhere but not available, disabling it.\n");
        $install{$p} = 0;
        next;
      }
      foreach my $p_dep ($tlpdb->get_package($p)->depends) {
        if ($p_dep =~ m/^(.*)\.ARCH$/) {
          my $foo = "$1";
          foreach $a (@archs) {
            $install{"$foo.$a"} = 1 if defined($tlpdb->get_package("$foo.$a"));
          }
        } elsif ($p_dep =~ m/^(.*)\.windows$/) {
          if (grep(/^windows$/,@archs)) {
            $install{$p_dep} = 1;
          }
        } else {
          $install{$p_dep} = 1;
        }
      }
    }

    my @post_selected = keys %install;
    debug("calc_depends:   after resolution, #packages: $#post_selected\n");

    if ($#pre_selected != $#post_selected) {
      $changed = 1;
    }
  }

  my $size = 0;
  foreach $p (keys %install) {
    my $tlpobj = $tlpdb->get_package($p);
    if (not(defined($tlpobj))) {
      tlwarn("$p should be installed but "
             . "is not in texlive.tlpdb; disabling.\n");
      $install{$p} = 0;
      next;
    }
    $size+=$tlpobj->docsize if $vars{'tlpdbopt_install_docfiles'};
    $size+=$tlpobj->srcsize if $vars{'tlpdbopt_install_srcfiles'};
    $size+=$tlpobj->runsize;
    foreach $a (@archs) {
      $size += $tlpobj->binsize->{$a} if defined($tlpobj->binsize->{$a});
    }
  }
  $vars{'total_size'} =
    sprintf "%d", ($size * $TeXLive::TLConfig::BlockSize)/1024**2;
} # calc_depends

sub load_tlpdb {
  my $master = $location;
  info("Loading $master/$TeXLive::TLConfig::InfraLocation/$TeXLive::TLConfig::DatabaseName\n");
  $tlpdb = TeXLive::TLPDB->new(
    root => $master, 'verify' => $opt_verify_downloads);
  if (!defined($tlpdb)) {
    my $do_die = 1;
    if ($media eq "NET" && $location !~ m/tlnet/) {
      tlwarn("First attempt for net installation failed;\n");
      tlwarn("  repository url does not contain \"tlnet\",\n");
      tlwarn("  retrying with \"/systems/texlive/tlnet\" appended.\n");
      $location .= "/systems/texlive/tlnet";
      $master = $location;
      $::tldownload_server->enable if defined($::tldownload_server);
      $tlpdb = TeXLive::TLPDB->new(
        root => $master, 'verify' => $opt_verify_downloads);
      if (!defined($tlpdb)) {
        tlwarn("Oh well, adding tlnet did not help.\n");
        tlwarn(<<END_EXPLICIT_MIRROR);

You may want to try specifying an explicit or different CTAN mirror;
see the information and examples for the -repository option at
https://tug.org/texlive/doc/install-tl.html
(or in the output of install-tl --help).

You can also rerun the installer with -select-repository
to choose a mirror from a menu.

END_EXPLICIT_MIRROR
      } else {
        info("Loading $master/$TeXLive::TLConfig::InfraLocation/$TeXLive::TLConfig::DatabaseName\n");
        $do_die = 0;
      }
    }
    return 0
      if $do_die;
  }
  for my $o (keys %TeXLive::TLConfig::TLPDBOptions) {
    $vars{"tlpdbopt_$o"} = $tlpdb->option($o)
      if (!defined($profiledata{"tlpdbopt_$o"}));
  }
  if (wndws()) {
    $vars{'tlpdbopt_desktop_integration'} = 1;
    $vars{'tlpdbopt_w32_multi_user'} = 0 if (!admin());
  }

  my $selscheme;
  if ($opt_scheme) {
    $selscheme = $opt_scheme;
  } elsif ($vars{"selected_scheme"}) {
    $selscheme = $vars{"selected_scheme"};
  } else {
    $selscheme = $default_scheme;
  }
  if (!defined($tlpdb->get_package($selscheme))) {
    if (!defined($tlpdb->get_package("scheme-minimal"))) {
      if (!defined($tlpdb->get_package("scheme-infra"))) {
        die("Aborting, cannot find either $selscheme or scheme-minimal or scheme-infra");
      }
      $default_scheme = "scheme-infra";
    } else {
      $default_scheme = "scheme-minimal";
    }
    tlwarn("$0: No $selscheme, switching to $default_scheme.\n");
    $vars{'selected_scheme'} = $default_scheme;
  } else {
    $vars{'selected_scheme'} = $selscheme;
  }
  my $found_collection = 0;
  for my $k (keys(%vars)) {
    if ($k =~ m/^collection-/) {
      $found_collection = 1;
      last;
    }
  }
  if (!$found_collection) {
    for my $p ($tlpdb->get_package($vars{'selected_scheme'})->depends) {
      $vars{$p} = 1 if ($p =~ m/^collection-/);
    }
  }
  return 1;
} # load_tlpdb

sub initialize_collections {
  foreach my $pkg ($tlpdb->list_packages) {
    my $tlpobj = $tlpdb->{'tlps'}{$pkg};
    if ($tlpobj->category eq "Collection") {
      $vars{"$pkg"} = 0 if (!defined($vars{$pkg}));
      ++$vars{'n_collections_available'};
      push (@collections_std, $pkg);
    }
  }
  my $selscheme = ($vars{'selected_scheme'} || $default_scheme);
  my $scheme_tlpobj = $tlpdb->get_package($selscheme);
  if (defined ($scheme_tlpobj)) {
    $vars{'n_collections_selected'}=0;
    foreach my $dependent ($scheme_tlpobj->depends) {
      if ($dependent=~/^(collection-.*)/) {
        $vars{"$1"}=1;
      }
    }
  }
  for my $c (keys(%vars)) {
    if ($c =~ m/^collection-/ && $vars{$c}) {
      ++$vars{'n_collections_selected'};
    }
  }
  if ($vars{"binary_windows"}) {
    $vars{"collection-wintools"} = 1;
    ++$vars{'n_collections_selected'};
  }
} # initialize_collections

sub set_install_platform {
  my $detected_platform=platform;
  if ($opt_custom_bin) {
    $detected_platform = "custom";
  }
  my $warn_nobin;
  my $warn_nobin_x86_64_linux;
  my $nowarn="";
  my $wp='***'; # warning prefix

  $warn_nobin="\n$wp WARNING: No binaries for your platform found.  ";
  $warn_nobin_x86_64_linux="$warn_nobin" .
      "$wp No binaries for x86_64-linux found, using i386-linux instead.\n";

  my $ret = $warn_nobin;
  if (defined $vars{"binary_$detected_platform"}) {
    $vars{"binary_$detected_platform"}=1;
    $vars{'inst_platform'}=$detected_platform;
    $ret = $nowarn;
  } elsif ($detected_platform eq 'x86_64-linux') {
    $vars{'binary_i386-linux'}=1;
    $vars{'inst_platform'}='i386-linux';
    $ret = $warn_nobin_x86_64_linux;
  } else {
    if ($opt_custom_bin) {
      $ret = "$wp Using custom binaries from $opt_custom_bin.\n";
    } else {
      $ret = $warn_nobin;
    }
  }
  foreach my $key (keys %vars) {
    if ($key=~/^binary.*/) {
       ++$vars{'n_systems_selected'} if $vars{$key}==1;
    }
  }
  return($ret);
} # set_install_platform

sub create_profile {
  my $profilepath = shift;
  my $fh;
  if (ref($profilepath)) {
    $fh = $profilepath;
  } else {
    open PROFILE, ">$profilepath";
    $fh = \*PROFILE;
  }
  my %instcols;
  foreach my $key (sort keys %vars) {
    $instcols{$key} = 1 if $key=~/^collection/ and $vars{$key}==1;
  }
  if ($vars{'selected_scheme'} ne "scheme-custom") {
    my $scheme=$tlpdb->get_package($vars{'selected_scheme'});
    if (!defined($scheme)) {
      die ("Scheme $vars{selected_scheme} not defined.\n");
    }
    for my $scheme_content ($scheme->depends) {
      delete($instcols{"$scheme_content"}) if ($scheme_content=~/^collection-/);
    }
  }
  my $save_cols = (keys(%instcols) ? 1 : 0);

  my $tim = gmtime(time);
  print $fh "# texlive.profile written on $tim UTC\n";
  print $fh "# It will NOT be updated and reflects only the\n";
  print $fh "# installation profile at installation time.\n";
  print $fh "selected_scheme $vars{selected_scheme}\n";
  foreach my $key (sort keys %vars) {
    print $fh "$key $vars{$key}\n"
        if $save_cols and $key=~/^collection/ and $vars{$key}==1;
    next if ($key eq "tlpdbopt_location");
    print $fh "$key $vars{$key}\n" if $key =~ /^tlpdbopt_/;
    print $fh "$key $vars{$key}\n" if $key =~ /^instopt_/;
    print $fh "$key $vars{$key}\n" if defined($path_keys{$key});
    print $fh "$key $vars{$key}\n" if (($key =~ /^binary_/) && $vars{$key});
  }
  if (!ref($profilepath)) {
    close PROFILE;
  }
} # create_profile

sub read_profile {
  my $profilepath = shift;
  my %opts = @_;
  my %keyrename = (
    'option_doc'        => 'tlpdbopt_install_docfiles',
    'option_fmt'        => 'tlpdbopt_create_formats',
    'option_src'        => 'tlpdbopt_install_srcfiles',
    'option_sys_bin'    => 'tlpdbopt_sys_bin',
    'option_sys_info'   => 'tlpdbopt_sys_info',
    'option_sys_man'    => 'tlpdbopt_sys_man',
    'option_file_assocs' => 'tlpdbopt_file_assocs',
    'option_backupdir'  => 'tlpdbopt_backupdir',
    'option_w32_multi_user' => 'tlpdbopt_w32_multi_user',
    'option_post_code'  => 'tlpdbopt_post_code',
    'option_autobackup' => 'tlpdbopt_autobackup',
    'option_desktop_integration' => 'tlpdbopt_desktop_integration',
    'option_adjustrepo' => 'instopt_adjustrepo',
    'option_letter'     => 'instopt_letter',
    'option_path'       => 'instopt_adjustpath',
    'option_symlinks'   => 'instopt_adjustpath',
    'portable'          => 'instopt_portable',
    'option_write18_restricted' => 'instopt_write18_restricted',
  );
  my %keylost = (
    'option_menu_integration' => 1,
    'in_place' => 1,
  );

  open PROFILE, "<$profilepath"
    or die "$0: Cannot open profile $profilepath for reading.\n";
  my %pro;
  while (<PROFILE>) {
    s{\R\z}{};
    next if m/^[[:space:]]*$/; # skip empty lines
    next if m/^[[:space:]]*#/; # skip comment lines
    s/^[[:space:]]+//;         # ignore leading (but not trailing) whitespace
    my ($k,$v) = split (" ", $_, 2); # value might have spaces
    next if ($k eq "TEXDIRW");
    $k = $keyrename{$k} if ($keyrename{$k});
    if ($keylost{$k}) {
      tlwarn("Profile key `$k' is now ignored, please remove it.\n");
      next;
    }
    $pro{$k} = $v;
    $profiledata{$k} = $v;
  }
  foreach (keys %vars) {
    if (m/^collection-/) { $vars{$_} = 0; }
  }
  foreach (keys %pro) {
    if (m/^instopt_/) {
      if (defined($vars{$_})) {
        $vars{$_} = $pro{$_};
        delete($pro{$_});
      }
    } elsif (m/^tlpdbopt_/) {
      my $o = $_;
      $o =~ s/^tlpdbopt_//;
      next if ($o eq 'location');
      if (defined($TeXLive::TLConfig::TLPDBOptions{$o})) {
        $vars{$_} = $pro{$_};
        delete($pro{$_});
      }

    } elsif (defined($path_keys{$_}) || m/^selected_scheme$/) {
      if ($pro{$_}) {
        $vars{$_} = $pro{$_};
        delete($pro{$_});
      } else {
        tldie("$0: Quitting, profile key for path $_ must not be empty.\n");
      }
    
    } elsif (m/^(binary|collection-)/) {
      if ($pro{$_} =~ /^[01]$/) {
        $vars{$_} = $pro{$_};
        delete($pro{$_});
      } else {
        tldie("$0: Quitting, profile key for $_ must be 0 or 1, not: $pro{$_}\n");
      }
    }
  }
  if (my @foo = keys(%pro)) {
    tlwarn("Unknown key(s) in profile $profilepath: @foo\n");
    tlwarn("Stopping here.\n");
    exit 1;
  }

  my $coldefined = 0;
  foreach my $k (keys %profiledata) {
    if ($k =~ m/^collection-/) {
      $coldefined = 1;
      last;
    }
  }
  return if $opts{'seed'};
  foreach my $k (keys %profiledata) {
    if ($k =~ m/^collection-/) {
      if (!defined($tlpdb->get_package($k))) {
        tlwarn("The profile references a non-existing collection: $k\n");
        tlwarn("Exiting.\n");
        exit(1);
      }
    }
  }
  update_default_scheme();

  return if $coldefined;
  my $scheme=$tlpdb->get_package($vars{'selected_scheme'});
  if (!defined($scheme)) {
    dump_vars(\*STDOUT);
    die ("Scheme $vars{selected_scheme} not defined.\n");
  }
  for my $scheme_content ($scheme->depends) {
    $vars{"$scheme_content"}=1 if ($scheme_content=~/^collection-/);
  }
} # read_profile

sub do_install_packages {
  my @criticalwhat = ();
  my @what = ();
  my @surely_fail_packages = ( @CriticalPackagesList, @TeXLive::TLConfig::InstallExtraRequiredPackages );
  for my $package (keys %install) {
    if (member($package, @surely_fail_packages)) {
      push @criticalwhat, $package if ($install{$package} == 1);
    } else {
      push @what, $package if ($install{$package} == 1);
    }
  }
  @criticalwhat = sort @criticalwhat;
  @what = sort @what;
  my $retry = $opt_debug_fakenet || ($media eq "NET");
  $localtlpdb->option ("desktop_integration", "0");
  $localtlpdb->option ("file_assocs", "0");
  $localtlpdb->option ("post_code", "0");
  if (!install_packages($tlpdb,$media,$localtlpdb,\@criticalwhat,
                        $vars{'tlpdbopt_install_srcfiles'},
                        $vars{'tlpdbopt_install_docfiles'},
                        $retry, 0)
      ||
      !install_packages($tlpdb,$media,$localtlpdb,\@what,
                        $vars{'tlpdbopt_install_srcfiles'},
                        $vars{'tlpdbopt_install_docfiles'},
                        $retry, $opt_continue)) {
    my $profile_name = "installation.profile";
    create_profile($profile_name);
    tlwarn("Installation failed.\n");
    tlwarn("Rerunning the installer will try to restart the installation.\n");
    if (-r $profile_name) {
      tlwarn("Or you can restart by running the installer with:\n");
      my $repostr = ($opt_location ? " --repository $location" : "");
      my $args = "--profile $profile_name [YOUR-EXTRA-ARGS]";
      if (wndws()) {
        tlwarn("  install-tl-windows.bat$repostr $args\n");
      } else {
        tlwarn("  install-tl$repostr $args\n");
      }
    }
    flushlog();
    exit(1);
  }
  $localtlpdb->option (
    "desktop_integration", $vars{'tlpdbopt_desktop_integration'});
  $localtlpdb->option ("file_assocs", $vars{'tlpdbopt_file_assocs'});
  $localtlpdb->option ("post_code", $vars{'tlpdbopt_post_code'} ? "1" : "0");
  $localtlpdb->save;
} # do_install_packages

sub save_options_into_tlpdb {
  if ($vars{'instopt_adjustrepo'} && ($media ne 'NET')) {
    $localtlpdb->option ("location", $TeXLiveURL); 
  } else {
    my $final_loc = ($media eq 'NET' ? $location : abs_path($location));
    $localtlpdb->option ("location", $final_loc);
  }
  for my $o (keys %TeXLive::TLConfig::TLPDBOptions) {
    next if ($o eq "location"); # done above already
    $localtlpdb->option ($o, $vars{"tlpdbopt_$o"});
  }
  my @archs;
  foreach (keys %vars) {
    if (m/^binary_(.*)$/ ) {
      if ($vars{$_}) { push @archs, $1; }
    }
  }
  if ($opt_custom_bin) {
    push @archs, "custom";
  }
  if (! @archs) {
    tldie("$0: Quitting, no binary platform specified/available.\n"
         ."$0: See https://tug.org/texlive/custom-bin.html for\n"
         ."$0: information on other precompiled binary sets.\n");
  }
  if (defined($opt_force_arch)) {
    $localtlpdb->setting ("platform", $::_platform_);
  }
  $localtlpdb->setting("available_architectures", @archs);
  $localtlpdb->save() unless $opt_in_place;
} # save_options_into_tlpdb

sub import_settings_from_old_tlpdb {
  my $dn = shift;
  my $tlpdboldpath =
    "$dn/$TeXLive::TLConfig::InfraLocation/$TeXLive::TLConfig::DatabaseName";
  my $previoustlpdb;
  if (-r $tlpdboldpath) {
    info ("Trying to load old TeX Live Database,\n");
    $previoustlpdb = TeXLive::TLPDB->new(root => $dn);
    if ($previoustlpdb) {
      info ("Importing settings from old installation in $dn\n");
    } else {
      tlwarn ("Cannot load old TLPDB, continuing with normal installation.\n");
      return;
    }
  } else {
    return;
  }

  $vars{'selected_scheme'} = "scheme-custom";
  $vars{'n_collections_selected'} = 0;
  foreach my $entry (keys %vars) {
    if ($entry=~/^(collection-.*)/) {
      $vars{"$1"}=0;
    }
  }
  foreach my $s ($previoustlpdb->schemes) {
    my $tlpobj = $tlpdb->get_package($s);
    if ($tlpobj) {
      foreach my $e ($tlpobj->depends) {
        if ($e =~ /^(collection-.*)/) {
          if (!$vars{$e}) {
            $vars{$e} = 1;
            ++$vars{'n_collections_selected'};
          }
        }
      }
    }
  }
  for my $c ($previoustlpdb->collections) {
    my $tlpobj = $tlpdb->get_package($c);
    if ($tlpobj) {
      if (!$vars{$c}) {
        $vars{$c} = 1;
        ++$vars{'n_collections_selected'};
      }
    }
  }


  my $oldroot = $previoustlpdb->root;
  my $newroot = abs_path("$oldroot/..") . "/$texlive_release";
  $vars{'TEXDIR'} = $newroot;
  $vars{'TEXMFSYSVAR'} = "$newroot/texmf-var";
  $vars{'TEXMFSYSCONFIG'} = "$newroot/texmf-config";
  chomp (my $tml = `kpsewhich -var-value=TEXMFLOCAL`);
  $tml = abs_path($tml);
  $vars{'TEXMFLOCAL'} = $tml;
  $vars{'tlpdbopt_install_docfiles'}
    = $previoustlpdb->option_pkg("00texlive.installation", "install_docfiles");
  $vars{'tlpdbopt_install_srcfiles'}
    = $previoustlpdb->option_pkg("00texlive.installation", "install_srcfiles");
  $vars{'tlpdbopt_create_formats'}
    = $previoustlpdb->option_pkg("00texlive.installation", "create_formats");
  $vars{'tlpdbopt_desktop_integration'} = 1 if wndws();
  $vars{'instopt_adjustpath'}
    = $previoustlpdb->option_pkg("00texlive.installation", "path");
  $vars{'instopt_adjustpath'} = 0 if !defined($vars{'instopt_adjustpath'});
  $vars{'instopt_adjustpath'} = 1 if wndws();
  $vars{'tlpdbopt_sys_bin'}
    = $previoustlpdb->option_pkg("00texlive.installation", "sys_bin");
  $vars{'tlpdbopt_sys_man'}
    = $previoustlpdb->option_pkg("00texlive.installation", "sys_man");
  $vars{'sys_info'}
    = $previoustlpdb->option_pkg("00texlive.installation", "sys_info");
  my @aar = $previoustlpdb->setting_pkg("00texlive.installation",
                                        "available_architectures");
  if (@aar) {
    for my $b ($tlpdb->available_architectures) {
      $vars{"binary_$b"} = member( $b, @aar );
    }
    $vars{'n_systems_available'} = 0;
    for my $key (keys %vars) {
      ++$vars{'n_systems_available'} if ($key=~/^binary/);
    }
  }
  my $xdvi_paper;
  if (!wndws()) {
    $xdvi_paper = TeXLive::TLPaper::get_paper("xdvi");
  }
  my $pdftex_paper = TeXLive::TLPaper::get_paper("pdftex");
  my $dvips_paper = TeXLive::TLPaper::get_paper("dvips");
  my $dvipdfmx_paper = TeXLive::TLPaper::get_paper("dvipdfmx");
  my $context_paper;
  if (defined($previoustlpdb->get_package("context"))) {
    $context_paper = TeXLive::TLPaper::get_paper("context");
  }
  my $common_paper = "";
  if (defined($xdvi_paper)) {
    $common_paper = $xdvi_paper;
  }
  $common_paper = 
    ($common_paper ne $context_paper ? "no-agree-on-paper" : $common_paper)
      if (defined($context_paper));
  $common_paper = 
    ($common_paper ne $pdftex_paper ? "no-agree-on-paper" : $common_paper)
      if (defined($pdftex_paper));
  $common_paper = 
    ($common_paper ne $dvips_paper ? "no-agree-on-paper" : $common_paper)
      if (defined($dvips_paper));
  $common_paper = 
    ($common_paper ne $dvipdfmx_paper ? "no-agree-on-paper" : $common_paper)
      if (defined($dvipdfmx_paper));
  if ($common_paper eq "no-agree-on-paper") {
    tlwarn("Previous installation uses different paper settings.\n");
    tlwarn("You will need to select your preferred paper sizes manually.\n\n");
  } else {
    if ($common_paper eq "letter") {
      $vars{'instopt_letter'} = 1;
    } elsif ($common_paper eq "a4") {
    } else {
      tlwarn(
        "Previous installation has common paper setting of: $common_paper\n");
      tlwarn("After installation has finished, you will need\n");
      tlwarn("  to redo this setting by running:\n");
    }
  }
  $vars{'free_size'} = TeXLive::TLUtils::diskfree($vars{'TEXDIR'});
} # import_settings_from_old_tlpdb

sub select_scheme {
  my $s = shift;
  $vars{'selected_scheme'} = $s;
  debug("setting selected scheme: $s\n");
  return if ($s eq "scheme-custom");
  foreach my $entry (keys %vars) {
    if ($entry=~/^(collection-.*)/) {
      $vars{"$1"}=0;
    }
  }
  my $scheme_tlpobj = $tlpdb->get_package($s);
  if (defined ($scheme_tlpobj)) {
    $vars{'n_collections_selected'}=0;
    foreach my $dependent ($scheme_tlpobj->depends) {
      if ($dependent=~/^(collection-.*)/) {
        $vars{"$1"}=1;
        ++$vars{'n_collections_selected'};
      }
    }
  }
  if ($vars{"binary_windows"}) {
    $vars{"collection-wintools"} = 1;
    ++$vars{'n_collections_selected'};
  }
  calc_depends();
} # select_scheme

sub schemes_ordered_for_presentation {
  my @scheme_order;
  my %schemes_shown;
  for my $s ($tlpdb->schemes) { $schemes_shown{$s} = 0 ; }
  for my $sn (qw/full medium small basic minimal infraonly/) {
    if (defined($schemes_shown{"scheme-$sn"})) {
      push @scheme_order, "scheme-$sn";
      $schemes_shown{"scheme-$sn"} = 1;
    }
  }
  for my $s (sort keys %schemes_shown) {
    push @scheme_order, $s if !$schemes_shown{$s};
  }
  return @scheme_order;
} # schemes_ordered_for_presentation

sub update_numbers {
  $vars{'n_collections_available'}=0;
  $vars{'n_collections_selected'} = 0;
  $vars{'n_systems_available'} = 0;
  $vars{'n_systems_selected'} = 0;
  foreach my $key (keys %vars) {
    if ($key =~ /^binary/) {
      ++$vars{'n_systems_available'};
      ++$vars{'n_systems_selected'} if $vars{$key} == 1;
    }
    if ($key =~ /^collection-/) {
      ++$vars{'n_collections_available'};
      ++$vars{'n_collections_selected'} if $vars{$key} == 1;
    }
  }
} # update_numbers

sub signal_handler {
  my ($sig) = @_;
  flushlog();
  print STDERR "$0: caught SIG$sig -- exiting\n";
  exit(1);
}

sub flushlog {
  if (!defined($::LOGFILENAME)) {
    my $fh;
    my $logfile = "install-tl.log";
    if (open (LOG, ">$logfile")) {
      my $pwd = Cwd::getcwd();
      $logfile = "$pwd/$logfile";
      print "$0: Writing log in current directory: $logfile\n";
      $fh = \*LOG;
    } else {
      $fh = \*STDERR;
      print
        "$0: Could not write to $logfile, so flushing messages to stderr.\n";
    }
    foreach my $l (@::LOGLINES) {
      print $fh $l;
    }
  }
} # flushlog

sub do_cleanup {
  if (($media eq "local_compressed") or ($media eq "NET")) {
    debug("Remove temporary downloaded containers...\n");
    rmtree("$vars{'TEXDIR'}/temp") if (-d "$vars{'TEXDIR'}/temp");
  }

  if ($opt_in_place) {
    create_profile("$vars{'TEXDIR'}/texlive.profile");
    debug("Profile written to $vars{'TEXDIR'}/texlive.profile\n");
  } else {
    create_profile("$vars{'TEXDIR'}/$InfraLocation/texlive.profile");
    debug("Profile written to $vars{'TEXDIR'}/$InfraLocation/texlive.profile\n");
  }

  if (!defined($::LOGFILE)) {
    $::LOGFILENAME = "$vars{'TEXDIR'}/install-tl.log";
    if (open(LOGF,">:utf8", $::LOGFILENAME)) {
      $::LOGFILE = \*LOGF;
      foreach my $line(@::LOGLINES) {
        print $::LOGFILE "$line";
      }
    } else {
      tlwarn("$0: Cannot create log file $::LOGFILENAME: $!\n"
             . "Not writing out log lines.\n");
    }
  }

  close($::LOGFILE) if (defined($::LOGFILE));
  if (!defined($::LOGFILENAME) and (-e "$vars{'TEXDIR'}/install-tl.log")) {
    $::LOGFILENAME = "$vars{'TEXDIR'}/install-tl.log";
  }
  if (!(defined($::LOGFILENAME)) or !(-e $::LOGFILENAME)) {
    $::LOGFILENAME = "";
  }
} # do_cleanup

sub check_env {
  $::env_warns = "";
  for my $evar (sort keys %origenv) {
    next if $evar =~ /^(_.*
                        |.*PWD
                        |ARGS
                        |GENDOCS_TEMPLATE_DIR
                        |INSTROOT
                        |INFOPATH
                        |MANPATH
                        |PATH
                        |PERL5LIB
                        |SHELLOPTS
                        |WISH
                       )$/x; # don't worry about these
    if ("$evar $origenv{$evar}" =~ /tex/i) { # check both key and value
      $::env_warns .= "    $evar=$origenv{$evar}\n";
    }
  }
  if ($::env_warns) {
    $::env_warns = <<"EOF";

 ----------------------------------------------------------------------
 The following environment variables contain the string "tex"
 (case-independent).  If you're doing anything but adding personal
 directories to the system paths, they may well cause trouble somewhere
 while running TeX.  If you encounter problems, try unsetting them.
 
 Please ignore spurious matches unrelated to TeX. (To omit this check,
 set the environment variable TEXLIVE_INSTALL_ENV_NOCHECK.)

$::env_warns ----------------------------------------------------------------------
EOF
  }
}


sub create_welcome {
  @::welcome_arr = ();
  push @::welcome_arr, __("Welcome to TeX Live!");
  push @::welcome_arr, __("See %s/index.html for links to documentation.\n",
                          $::vars{'TEXDIR'});
  push @::welcome_arr, __("The TeX Live web site (https://tug.org/texlive/) provides all updates\nand corrections. TeX Live is a joint project of the TeX user groups\naround the world; please consider supporting it by joining the group\nbest for you. The list of groups is available on the web\nat https://tug.org/usergroups.html.\n");
  if (wndws()
      || ($vars{'instopt_adjustpath'}
         && $vars{'tlpdbopt_desktop_integration'} != 2)) {
     ; # don't tell them to make path adjustments on Windows,
   } else {
    push @::welcome_arr, __(
      "Add %s/texmf-dist/doc/man to MANPATH.\nAdd %s/texmf-dist/doc/info to INFOPATH.\nMost importantly, add %s/bin/%s\nto your PATH for current and future sessions.\n",
      $::vars{'TEXDIR'}, $::vars{'TEXDIR'}, $::vars{'TEXDIR'},
      $::vars{'this_platform'});
  }
}


sub install_warnlines_hook {
  push @::warn_hook, sub { push @::WARNLINES, @_; };
}




sub select_collections {
  my $varref = shift;
  foreach (@_) {
    $varref->{$_} = 1;
  }
}

sub deselect_collections {
  my $varref = shift;
  foreach (@_) {
    $varref->{$_} = 0;
  }
}















# PACKPERLMODULES END https://raw.githubusercontent.com/TeX-Live/installer/ad18812c20014153d52d6628ed11ad246b52fe69/install-tl

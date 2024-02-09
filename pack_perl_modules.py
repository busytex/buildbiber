# https://stackoverflow.com/a/69438160/445810

import os
import sys
import argparse
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--comment-signature', default = 'PACKPERLMODULES')
parser.add_argument('--encoding', default = 'utf-8')
parser.add_argument('--method', default = 'inchook', choices = ['inchook', 'incpatch'], help = 'order of pm files is important for [incpatch] and not important for [inchook]')
parser.add_argument('--delete-pod', nargs = '*', default = ['=pod,=cut', '__END__,=cut', '=back,=cut', '=head1,=cut', '=head2,=cut','=head3,=cut', '=head4,=cut', '=head5,=cut', '=head6,=cut',  '=item,=cut'])
parser.add_argument('--delete-pod-sep', default = ',')
parser.add_argument('--delete-comments-naive', action = 'store_true')
parser.add_argument('--comment-unshift-inc', action = 'store_true')
parser.add_argument('--pl')
parser.add_argument('--pm', nargs = '*')
args = parser.parse_args()

def read_pl_source(p, ):
    f = urllib.request.urlopen(p) if p.startswith('https://') or p.startswith('http://') else open(p, mode)
    t = f.read().decode(args.encoding)
    
    r = ''
    for l in t.split('\n'):
        if (not l or args.delete_comments_naive is False or not l.lstrip().startswith('#')):
            lnospaces = l.lstrip().replace(' ', '')
            if args.comment_unshift_inc and (lnospaces.startswith('unshift(@INC') or lnospaces.startswith('unshift @INC')):
                l = '#' + l + '# ' + args.comment_signature
            r += l + '\n'
    t = r

    for be in args.delete_pod:
        r = ''
        b, e = be.split(args.delete_pod_sep)
        skip = False
        for l in t.split('\n'):
            s = l.split()
            if s and s[0] == b:
                skip = True
            if skip is False:
                r += l + '\n'
            if l == e:
                skip = False
        t = r
    return t


if args.method == 'inchook':
    print('BEGIN {')
    print('my %modules = (')
    for p in args.pm:
        path, *key = p.split('@')
        if not key:
            key = [os.path.basename(path)]
        print('#', args.comment_signature, 'BEGIN', p)
        print(f'''"{key[0]}" => <<'__EOI__',''')
        print(read_pl_source(path))
        print('1;')
        print('__EOI__')
        print('#', args.comment_signature, 'END', p)
    print(');')
    print('unshift @INC, sub {')
    print('my $module = $modules{$_[1]}')
    print('or return;')
    print('return \\$module')
    print('};')
    print('}')

if args.method == 'incpatch':
    for p in args.pm:
        path, *key = p.split('@')
        if not key:
            key = [os.path.basename(path)]
        print('#', args.comment_signature, 'BEGIN', p)
        print('BEGIN {')
        print(read_pl_source(path))
        print('$INC{ ( __PACKAGE__ =~ s{::}{/}rg ) . ".pm" } = 1;')
        print('}')
        print('#', args.comment_signature, 'END', p)

if args.pl:
    print('#', args.comment_signature, 'BEGIN', args.pl)
    print(read_pl_source(args.pl))
    print('#', args.comment_signature, 'END', args.pl)

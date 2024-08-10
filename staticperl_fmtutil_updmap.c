#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
//#include <fcntl.h>
#include <stdarg.h>

#include <sys/stat.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

//#include "preload.c"

///////////////////////////////////////
// #include <xsinit.c>

extern void boot_Fcntl      (pTHX_ CV* cv);
extern void boot_IO         (pTHX_ CV* cv);
extern void boot_DynaLoader (pTHX_ CV* cv);

//EXTERN_C void xs_init         (pTHX);
//EXTERN_C 
void xs_init         (pTHX)
{
    static const char file[] = __FILE__;
    dXSUB_SYS;
    PERL_UNUSED_CONTEXT;

    newXS("Fcntl::bootstrap", boot_Fcntl, file);
    newXS("IO::bootstrap", boot_IO, file);
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
}
///////////////////////////////////////

#ifdef LOGFILEACCESS

/*

/usr/include/fcntl.h:34:5: note: previous declaration of 'open' was here
   34 | int open(const char *, int, ...);
   int openat(int, const char *, int, ...);

*/

FILE* fopen(const char *path, const char *mode)
{
    typedef FILE* (*orig_fopen_func_type)(const char *path, const char *mode);
    fprintf(stderr, "log_file_access_preload: fopen(\"%s\", \"%s\")\n", path, mode);
    orig_fopen_func_type orig_func = (orig_fopen_func_type)dlsym(RTLD_NEXT, "fopen");
    return orig_func(path, mode);
}

int open(const char *path, int flags)
{
    typedef int (*orig_func_type)(const char *pathname, int flags);
    fprintf(stderr, "log_file_access_preload: open(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "open");
    return orig_func(path, flags);
}
int open64(const char *path, int flags)
{
    typedef int (*orig_func_type)(const char *pathname, int flags);
    fprintf(stderr, "log_file_access_preload: open64(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "open64");
    return orig_func(path, flags);
}
//int openat(int dirfd, const char *path, int flags, mode_t mode)
int openat(int dirfd, const char *path, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *pathname, int flags);
    fprintf(stderr, "log_file_access_preload: openat(%d, \"%s\", %d)\n", dirfd, path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "openat");
    return orig_func(dirfd, path, flags);
}



int access(const char *path, int flags)
{
    typedef int (*orig_func_type)(const char *pathname, int flags);
    fprintf(stderr, "log_file_access_preload: access(\"%s\", %d)\n", path, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "access");
    return orig_func(path, flags);
}
int faccessat(int dirfd, const char *path, int mode, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *pathname, int mode, int flags);
    fprintf(stderr, "log_file_access_preload: faccessat(%d, \"%s\", %d, %d)\n", dirfd, path, mode, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "faccessat");
    return orig_func(dirfd, path, mode, flags);
}


int stat(const char *restrict pathname, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(const char *restrict pathname, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: stat(\"%s\", %p)\n", pathname, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "stat");
    return orig_func(pathname, statbuf);
}
int lstat(const char *restrict pathname, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(const char *restrict pathname, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: lstat(\"%s\", %p)\n", pathname, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "lstat");
    return orig_func(pathname, statbuf);
}
int fstat(int fd, struct stat *restrict statbuf)
{
    typedef int (*orig_func_type)(int fd, struct stat *restrict statbuf);
    fprintf(stderr, "log_file_access_preload: fstat(%d, %p)\n", fd, (void*)statbuf);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstat");
    return orig_func(fd, statbuf);
}
int fstatat(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: fstat(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstatat");
    return orig_func(dirfd, pathname, statbuf, flags);
}

/*
int fstatat64(int dirfd, const char *restrict pathname, struct stat64 *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat64 *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: fstat64(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "fstatat64");
    return orig_func(dirfd, pathname, statbuf, flags);
}
*/

int newfstatat(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags)
{
    typedef int (*orig_func_type)(int dirfd, const char *restrict pathname, struct stat *restrict statbuf, int flags);
    fprintf(stderr, "log_file_access_preload: newfstat(%d, \"%s\", %p, %d)\n", dirfd, pathname, (void*)statbuf, flags);
    orig_func_type orig_func = (orig_func_type)dlsym(RTLD_NEXT, "newfstatat");
    return orig_func(dirfd, pathname, statbuf, flags);
}

#endif

////////////////////////////////////////////////////////////

static char script[1 << 20] = "print('hello world');";

extern char _binary_fmtutil_pl_start[];
extern char _binary_fmtutil_pl_end[];

extern char _binary_updmap_pl_start[];
extern char _binary_updmap_pl_end[];

int main(int argc, char **argv)
{
    if(argc < 3)
    {
        puts("need more arguments");
        return 1;
    }
    
    PERL_SYS_INIT3(&argc, &argv, NULL);
    PerlInterpreter* my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;

    if(0 == strcmp("fmtutil.pl", argv[1]))
    {
        int iSize = (int)(_binary_fmtutil_pl_end - _binary_fmtutil_pl_start);
        strncpy(script,    _binary_fmtutil_pl_start, iSize);
        script[iSize] = '\0';
    }
    if(0 == strcmp("updmap.pl", argv[1]))
    {
        int iSize = (int)(_binary_updmap_pl_end - _binary_updmap_pl_start);
        strncpy(script,    _binary_updmap_pl_start, iSize);
        script[iSize] = '\0';
    }

    char *one_args[] = { "staticperl_fmtutil_updmap", "-e", script, "--", argv[2], NULL };
    perl_parse(my_perl, xs_init, 5, one_args, (char **)NULL);
    perl_run(my_perl);
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();

    return 0;
}

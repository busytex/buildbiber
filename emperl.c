//#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>


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


static char script[1 << 20];

extern char _binary_fmtutil_pl_start[];
extern char _binary_fmtutil_pl_end[];

extern char _binary_updmap_pl_start[];
extern char _binary_updmap_pl_end[];


typedef int   (*orig_open_func_type)(const char *pathname, int flags, ...);
typedef off_t (*orig_lseek_func_type)(int __fd, off_t __offset, int __whence);

off_t lseek(int __fd, off_t __offset, int __whence)
{
    orig_lseek_func_type orig_func;
    orig_func = (orig_lseek_func_type)dlsym(RTLD_NEXT, "lseek");
    printf("lseek: %d\n", __fd);

    return orig_func(pathname, flags);
}

int open(const char *pathname, int __oflag, ...)
{
    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open");
    int res = 0;

    if (__oflag & O_CREAT) {
		va_start(ap, __oflag);
		mode = va_arg(ap, unsigned);
		res = orig_func(__file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(pathname, __oflag);

    printf("open: %d (%s)\n", res, pathname);
    return res;
}

int open64(const char *pathname, int flags, ...)
{
    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open64");
    int res = 0;

    if (__oflag & O_CREAT) {
		va_start(ap, __oflag);
		mode = va_arg(ap, unsigned);
		res = orig_func(__file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(pathname, __oflag);

    printf("open64: %d (%s)\n", res, pathname);
    return res;
}


int main(int argc, char **argv, char **env)
{
    //FILE* f = fopen(argv[1], "r");
    //fread(script, sizeof(script), 1, f);
    //fclose(f);
    
    PERL_SYS_INIT3(&argc, &argv, &env);
    PerlInterpreter* my_perl = perl_alloc();
    perl_construct(my_perl);
    PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
    
    //perl_parse(my_perl, xs_init, argc, argv, (char **)NULL);
    
    int iSize =  (int)(_binary_fmtutil_pl_end - _binary_fmtutil_pl_start);
    strncpy(script,    _binary_fmtutil_pl_start, iSize);
    script[iSize] = '\0';

    char *one_args[] = { "my_perl", "-e", script, "--", argv[1], NULL };
    perl_parse(my_perl, xs_init, 5, one_args, (char **)NULL);
    
    perl_run(my_perl);
    perl_destruct(my_perl);
    perl_free(my_perl);
    PERL_SYS_TERM();

    return 0;
}

#define _GNU_SOURCE

#include <stdio.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <dlfcn.h>
#include <fcntl.h>
#include <stdarg.h>

typedef int   (*orig_open_func_type)(const char *__file, int flags, ...);
typedef int   (*orig_openat_func_type)(int dirfd, const char *__file, int flags, ...);

int open(const char *__file, int __oflag, ...)
{
    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open");
    int res = 0;

    if (__oflag & O_CREAT) {
        va_list ap;
		va_start(ap, __oflag);
		int mode = va_arg(ap, unsigned);
		res = orig_func(__file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(__file, __oflag);

    printf("open: %d (%s)\n", res, __file);
    return res;
}

int __open(const char *__file, int __oflag, ...)
{
    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open");
    int res = 0;

    if (__oflag & O_CREAT) {
        va_list ap;
		va_start(ap, __oflag);
		int mode = va_arg(ap, unsigned);
		res = orig_func(__file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(__file, __oflag);

    printf("__open: %d (%s)\n", res, __file);
    return res;
}

int openat__(int dirfd, const char *__file, int __oflag, ...)
{
    orig_openat_func_type orig_func = (orig_openat_func_type)dlsym(RTLD_NEXT, "openat");
    int res = 0;

    if (__oflag & O_CREAT) {
        va_list ap;
		va_start(ap, __oflag);
		int mode = va_arg(ap, unsigned);
		res = orig_func(dirfd, __file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(dirfd, __file, __oflag);

    printf("openat__: %d (%s)\n", res, __file);
    return res;
}

int openat(int dirfd, const char *__file, int __oflag, ...)
{
    orig_openat_func_type orig_func = (orig_openat_func_type)dlsym(RTLD_NEXT, "openat");
    int res = 0;

    if (__oflag & O_CREAT) {
        va_list ap;
		va_start(ap, __oflag);
		int mode = va_arg(ap, unsigned);
		res = orig_func(dirfd, __file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(dirfd, __file, __oflag);

    printf("openat: %d (%s)\n", res, __file);
    return res;
}

int open64(const char *__file, int __oflag, ...)
{
    orig_open_func_type orig_func;
    orig_func = (orig_open_func_type)dlsym(RTLD_NEXT, "open64");
    int res = 0;

    if (__oflag & O_CREAT) {
        va_list ap;
		va_start(ap, __oflag);
		int mode = va_arg(ap, unsigned);
		res = orig_func(__file, __oflag, mode);
		va_end(ap);
	}
    else
        res = orig_func(__file, __oflag);

    printf("open64: %d (%s)\n", res, __file);
    return res;
}


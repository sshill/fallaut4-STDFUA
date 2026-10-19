#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <dlfcn.h>
#include <stdarg.h>
#include <sys/types.h>

typedef int (*open_fn)(const char *pathname, int flags, ...);
typedef int (*openat_fn)(int dirfd, const char *pathname, int flags, ...);

static open_fn real_open = NULL;
static open_fn real_open64 = NULL;
static openat_fn real_openat = NULL;
static openat_fn real_openat64 = NULL;

int open(const char *pathname, int flags, ...) {
    mode_t mode = 0;
    if (pathname && strstr(pathname, "hidraw")) {
        errno = ENOENT;
        return -1;
    }
    if (!real_open) real_open = (open_fn)dlsym(RTLD_NEXT, "open");
    va_list args;
    va_start(args, flags);
    mode = va_arg(args, mode_t);
    va_end(args);
    return real_open(pathname, flags, mode);
}

int open64(const char *pathname, int flags, ...) {
    mode_t mode = 0;
    if (pathname && strstr(pathname, "hidraw")) {
        errno = ENOENT;
        return -1;
    }
    if (!real_open64) real_open64 = (open_fn)dlsym(RTLD_NEXT, "open64");
    if (!real_open64) real_open64 = (open_fn)dlsym(RTLD_NEXT, "open");
    va_list args;
    va_start(args, flags);
    mode = va_arg(args, mode_t);
    va_end(args);
    return real_open64(pathname, flags, mode);
}

int openat(int dirfd, const char *pathname, int flags, ...) {
    mode_t mode = 0;
    if (pathname && strstr(pathname, "hidraw")) {
        errno = ENOENT;
        return -1;
    }
    if (!real_openat) real_openat = (openat_fn)dlsym(RTLD_NEXT, "openat");
    va_list args;
    va_start(args, flags);
    mode = va_arg(args, mode_t);
    va_end(args);
    return real_openat(dirfd, pathname, flags, mode);
}

int openat64(int dirfd, const char *pathname, int flags, ...) {
    mode_t mode = 0;
    if (pathname && strstr(pathname, "hidraw")) {
        errno = ENOENT;
        return -1;
    }
    if (!real_openat64) real_openat64 = (openat_fn)dlsym(RTLD_NEXT, "openat64");
    if (!real_openat64) real_openat64 = (openat_fn)dlsym(RTLD_NEXT, "openat");
    va_list args;
    va_start(args, flags);
    mode = va_arg(args, mode_t);
    va_end(args);
    return real_openat64(dirfd, pathname, flags, mode);
}

#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <glusterfs/api/glfs.h>
#include <glusterfs/api/glfs-handles.h>

#define VALIDATE_AND_GOTO_LABEL_ON_ERROR(func, ret, label)                     \
    do {                                                                       \
        if (ret < 0) {                                                         \
            fprintf(stderr, "%s : returned error %d (%s)\n", func, ret,        \
                    strerror(errno));                                          \
            goto label;                                                        \
        }                                                                      \
    } while (0)

int
main(int argc, char *argv[])
{
    int ret = -1;
    glfs_t *fs = NULL;
    char *volname = NULL;
    char *logfile = NULL;
    char *hostname = NULL;

    hostname = argv[1];
    volname = argv[2];
    logfile = argv[3];

    fs = glfs_new(volname);
    if (!fs)
        VALIDATE_AND_GOTO_LABEL_ON_ERROR("glfs_new(fs)", ret, out);

    ret = glfs_set_volfile_server(fs, "tcp", hostname, 24007);
    VALIDATE_AND_GOTO_LABEL_ON_ERROR("glfs_set_volfile_server(fs)", ret, out);

    ret = glfs_set_logging(fs, logfile, 7);
    VALIDATE_AND_GOTO_LABEL_ON_ERROR("glfs_set_logging(fs)", ret, out);

    ret = glfs_init(fs);
    VALIDATE_AND_GOTO_LABEL_ON_ERROR("glfs_init(fs)", ret, out);

out:
    if (fs) {
        ret = glfs_fini(fs);
        if (ret)
            fprintf(stderr, "glfs_fini(fs) returned %d\n", ret);
    }
    return ret;
}

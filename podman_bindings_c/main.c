#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include "libpodc.h"

const int FAILURE = -1;

//free all vars and exit if error
void handleError(int code, int params, void *arg1, ...)
{
    if (code == FAILURE)
    {
        va_list args;
        void *vp;
        free(arg1);
        va_start(args, arg1);
        for(int i=0; i<params; ++i)
        {
            vp = va_arg(args, void *);
            if(vp != NULL)
            {
                free(vp);
            }
        }
        va_end(args);
        exit(1);
    }
}

int main() {
    char * socket = findSocket();
    int error = newConnection(socket);
    handleError(error, 1, socket);
    free(socket);

    char image[] = "registry.fedoraproject.org/fedora-minimal:latest";

    error = pullImage(image);
    handleError(error, 1, NULL);

    listImages();

    struct createContainer_return id = createContainer(image);
    error = id.r1;
    handleError(error, 1, id.r0);

    error = startContainer(id.r0);
    handleError(error, 1, id.r0);

    error = waitForRunning(id.r0);
    handleError(error, 1, id.r0);

    struct inspectContainer_return status = inspectContainer(id.r0);
    error = status.r2;
    printf("Ret code: %d. Status of the container with imgName: %s is: %s\n", error, status.r0, status.r1);

    error = stopContainer(id.r0);
    printf("Stop container reported status: %d\n", error);
    handleError(error, 3, id.r0, status.r0, status.r1);

    //free dynamically allocated data
    free(id.r0);
    free(status.r0);
    free(status.r1);
}

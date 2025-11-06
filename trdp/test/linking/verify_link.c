#include "trdp_if_light.h"

#include <stdio.h>

static void debugOut(
    void               *refCon,
    TRDP_LOG_T          category,
    const CHAR8        *time,
    const CHAR8        *file,
    UINT16              line,
    const CHAR8        *message)
{
    (void)refCon;
    (void)category;
    (void)time;
    (void)file;
    (void)line;
    (void)message;
}

int main(void)
{
    TRDP_ERR_T rc = tlc_init(debugOut, NULL, NULL);
    if (rc != TRDP_NO_ERR)
    {
        fprintf(stderr, "tlc_init failed: %d\n", (int)rc);
        return 1;
    }

    (void)tlc_terminate();
    return 0;
}


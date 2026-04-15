#pragma once

#include <stddef.h>
#include "types.h"

typedef size_t (*serializefn) (const aqi_pkg_t* data, uint8_t * buffer_out, size_t max_len);

typedef struct 
{
    serializefn serializer;
} serializer_t;

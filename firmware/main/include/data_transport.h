#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "types.h"

typedef bool (*data_transport_connect_fn) (void);
typedef bool (*data_transport_disconnect_fn) (void);
typedef void (*data_transport_send_pkg_fn)(const uint8_t* payload, size_t len);

typedef struct 
{
    data_transport_connect_fn connect;
    data_transport_disconnect_fn disconnect;
    data_transport_send_pkg_fn send_pkg;
} data_transport_t;

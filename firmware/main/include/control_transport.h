#pragma once

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

typedef bool (*control_transport_connect_fn) (void);
typedef bool (*control_transport_disconnect_fn) (void);
typedef bool (*control_subscribe_to_command_fn) (void);
typedef void (*control_command_callback_t) (const uint8_t *payload, const size_t size);

typedef struct
{
    control_transport_connect_fn connect;
    control_transport_disconnect_fn disconnect;
    control_subscribe_to_command_fn subscribe;
    void (*set_received_callback)(control_command_callback_t callback);
} control_transport_t;

#pragma once

#include <stdbool.h>
#include "control_transport.h"
#include "data_transport.h"
#include "serializer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

typedef enum {
    NET_STATE_DISCONNECTED,
    NET_STATE_WIFI_CONNECTING,
    NET_STATE_WIFI_NO_IP,
    NET_STATE_WIFI_READY,
    NET_STATE_FULLY_READY,
    NET_STATE_FALLBACK
} net_state_t;




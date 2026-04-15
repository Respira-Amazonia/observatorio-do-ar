#pragma once

#include <stdint.h>

typedef struct
{   
    float temperature;
    float humidity;

    // Correction Factor = 1
    int pm1_cf;
    int pm25_cf;
    int pm10_cf;

    // Under_Atmospheric_Environment
    int pm1_u_atm_env;
    int pm25_u_atm_env;
    int pm10_u_atm_env;
} aqi_pkg_t;

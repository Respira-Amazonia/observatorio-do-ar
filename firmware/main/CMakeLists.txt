# Adiciona a pasta include
set(INCLUDE_DIRS "include")

# Cria uma lista com todos os arquivos .c dentro de src/
file(GLOB_RECURSE SOURCES "src/*.c")
# Adiciona o main.c à lista
list(APPEND SOURCES "main.c")

idf_component_register(SRCS ${SOURCES}
                    INCLUDE_DIRS ${INCLUDE_DIRS}
                    REQUIRES freertos)
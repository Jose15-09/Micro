; 1. Aquí solo definimos algunos valores que vamos a usar en todo el programa
; para no estar escribiendo números a cada rato

.equ N      = 100        ; básicamente el arreglo tendrá 100 números
.equ MODVAL = 101        ; esto se usa para que los números aleatorios queden entre 0 y 100
; 2. Empieza la parte de memoria RAM
; Se aparta espacio para guardar todos los arreglos y variables

.dseg

table_of_unsorted_numbers:      .byte N   ; Se guardan los 100 números aleatorios sin ordenar
table_of_sorted_numbers_alg1:   .byte N   ; Se guardará el arreglo ya ordenado con Bubble Sort
table_of_sorted_numbers_alg2:   .byte N   ; Se guardará el arreglo ordenado con Selection Sort

rng_state:                      .byte 1   ; Variable que guarda el estado del generador de números aleatorios

time_alg1_ticks:                .byte 2   ; Se guarda el tiempo de Bubble Sort
time_alg2_ticks:                .byte 2   ; Se guarda el tiempo de Selection Sort

; 3. A partir de aquí ya empieza el código que ejecuta el microcontrolador

.cseg
.org 0x0000
    rjmp RESET              ; cuando el micro arranca siempre empieza en 0x0000 y de una vez brinca a RESET

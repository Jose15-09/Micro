///////// ACTIVIDAD I - MICROCONTROLADORES /////////
///////// ATmega328P - Arduino UNO - 16 MHz /////////
///////// Genera números aleatorios, los ordena y mide tiempo /////////

.include "m328pdef.inc"

///////// CONSTANTES DEL PROGRAMA /////////

.equ N      = 100
.equ MODVAL = 101
///////// MEMORIA SRAM (DATOS) /////////

.dseg

table_of_unsorted_numbers:      .byte N
; Aquí se guardan los 100 números generados al azar

table_of_sorted_numbers_alg1:   .byte N
; Copia ordenada usando Bubble Sort

table_of_sorted_numbers_alg2:   .byte N
; Copia ordenada usando Insertion Sort

rng_state:      .byte 1
; Guarda el estado actual del generador pseudoaleatorio

time_alg1_ticks:.byte 2
; Tiempo que tarda Bubble Sort

time_alg2_ticks:.byte 2
; Tiempo que tarda Insertion Sort

///////// CÓDIGO DEL PROGRAMA /////////

.cseg
.org 0x0000
    rjmp RESET
///////// INICIO DEL PROGRAMA /////////

RESET:

; Inicializar el stack (necesario para usar subrutinas)

    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

; El registro r1 siempre debe valer 0 en AVR

    clr r1

///////// CONFIGURAR TIMER1 /////////

; Este timer se usa para medir cuánto tarda cada algoritmo

    ldi r16, 0x00
    sts TCCR1A, r16

; Prescaler 64 (hace que el timer avance más lento)

    ldi r16, (1<<CS11) | (1<<CS10)
    sts TCCR1B, r16
///////// SEMILLA DEL GENERADOR ALEATORIO /////////

    ldi r16, 0xA7
    sts rng_state, r16

///////// GENERAR 100 NÚMEROS ALEATORIOS /////////

    rcall FILL_RANDOM_0_100
///////// ORDENAMIENTO CON BUBBLE SORT /////////

; Copiar números originales a otra tabla

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg1)
    ldi YL, low(table_of_sorted_numbers_alg1)

    rcall COPY_N_BYTES

; Reiniciar timer

    rcall TIMER1_RESET

; Ejecutar Bubble Sort

    ldi ZH, high(table_of_sorted_numbers_alg1)
    ldi ZL, low(table_of_sorted_numbers_alg1)

    rcall BUBBLE_SORT_N

; Guardar tiempo

    rcall TIMER1_READ_TO_time_alg1


///////// ORDENAMIENTO CON INSERTION SORT /////////

; Copiar números originales nuevamente

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg2)
    ldi YL, low(table_of_sorted_numbers_alg2)

    rcall COPY_N_BYTES

; Reiniciar timer

    rcall TIMER1_RESET

; Ejecutar Insertion Sort

    ldi ZH, high(table_of_sorted_numbers_alg2)
    ldi ZL, low(table_of_sorted_numbers_alg2)

    rcall INSERTION_SORT_N

; Guardar tiempo

    rcall TIMER1_READ_TO_time_alg2

///////// FIN DEL PROGRAMA /////////

DONE:
    rjmp DONE

///////// FUNCIONES DEL TIMER /////////

TIMER1_RESET:

; Reinicia el contador del timer

    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16
    ret


TIMER1_READ_TO_time_alg1:

; Lee el valor del timer y lo guarda

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg1_ticks,   r18
    sts time_alg1_ticks+1, r19

    ret


TIMER1_READ_TO_time_alg2:

; Lee el valor del timer para el segundo algoritmo

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg2_ticks,   r18
    sts time_alg2_ticks+1, r19

    ret

///////// COPIAR DATOS ENTRE TABLAS /////////

COPY_N_BYTES:

; Copia N números desde la tabla fuente a la tabla destino

    ldi r20, N

COPY_LOOP:

    ld  r16, Z+
    st  Y+, r16

    dec r20
    brne COPY_LOOP

    ret

///////// GENERAR NÚMEROS ALEATORIOS /////////

FILL_RANDOM_0_100:

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi r20, N

FILL_LOOP:

    rcall RNG_NEXT_0_100
    st   Z+, r16

    dec  r20
    brne FILL_LOOP

    ret


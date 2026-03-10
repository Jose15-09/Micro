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


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

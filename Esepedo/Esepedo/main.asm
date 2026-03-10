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
///////// GENERADOR PSEUDOALEATORIO /////////

RNG_NEXT_0_100:

    lds r16, rng_state

    mov r17, r16
    andi r17, 0x01

    lsr r16

    tst r17
    breq RNG_NOXOR

    ldi r18, 0xB8
    eor r16, r18

RNG_NOXOR:

    sts rng_state, r16
///////// REDUCIR VALOR A 0..100 /////////

REDUCE_MOD:

    cpi r16, MODVAL
    brlo RNG_DONE

    subi r16, MODVAL
    rjmp REDUCE_MOD

RNG_DONE:
    ret



///////// BUBBLE SORT /////////

BUBBLE_SORT_N:

    ldi r21, N-1

BS_OUTER:

    movw r28, r30
    clr  r22

BS_INNER:

    ld   r16, Y
    ldd  r17, Y+1

    cp   r17, r16
    brsh BS_NOSWAP

; Intercambiar números si están en orden incorrecto

    st   Y,   r17
    std  Y+1, r16

BS_NOSWAP:

    adiw r28, 1
    inc  r22

    cp   r22, r21
    brlo BS_INNER

    dec r21
    brne BS_OUTER

    ret

///////// INSERTION SORT /////////

INSERTION_SORT_N:

    ldi r21, 1

IS_OUTER:

    movw r28, r30
    mov  r23, r21

IS_ADV_I:

    tst  r23
    breq IS_GOT_I

    adiw r28, 1
    dec  r23
    rjmp IS_ADV_I

IS_GOT_I:

    ld   r18, Y

    mov  r22, r21
    dec  r22


IS_SHIFT:

    cpi  r22, 0xFF
    breq IS_INSERT_0

    movw r28, r30
    mov  r23, r22

IS_ADV_J:

    tst  r23
    breq IS_GOT_J

    adiw r28, 1
    dec  r23
    rjmp IS_ADV_J

IS_GOT_J:

    ld   r19, Y

    cp   r18, r19
    brsh IS_PLACE_KEY

; Mover número a la derecha

    std  Y+1, r19

    dec  r22
    rjmp IS_SHIFT

IS_PLACE_KEY:

    std  Y+1, r18
    rjmp IS_NEXT_I

IS_INSERT_0:

    movw r28, r30
    st   Y, r18

IS_NEXT_I:

    inc  r21
    cpi  r21, N
    brlo IS_OUTER

    ret


.equ N      = 100
.equ MODVAL = 101

.dseg

table_of_unsorted_numbers:      .byte N
table_of_sorted_numbers_alg1:   .byte N
table_of_sorted_numbers_alg2:   .byte N
rng_state:                      .byte 1
time_alg1_ticks:                .byte 2
time_alg2_ticks:                .byte 2

.cseg
.org 0x0000
    rjmp RESET


RESET:

    ldi r16, high(RAMEND)
    out SPH, r16
    ldi r16, low(RAMEND)
    out SPL, r16

    clr r1

    ldi r16, 0x00
    sts TCCR1A, r16

    ldi r16, (1<<CS11) | (1<<CS10)
    sts TCCR1B, r16

    ldi r16, 0xA7
    sts rng_state, r16

    rcall FILL_RANDOM_0_100

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg1)
    ldi YL, low(table_of_sorted_numbers_alg1)

    rcall COPY_N_BYTES

    rcall TIMER1_RESET

    ldi ZH, high(table_of_sorted_numbers_alg1)
    ldi ZL, low(table_of_sorted_numbers_alg1)

    rcall BUBBLE_SORT_N

    rcall TIMER1_READ_TO_time_alg1

    ldi ZH, high(table_of_unsorted_numbers)
    ldi ZL, low(table_of_unsorted_numbers)

    ldi YH, high(table_of_sorted_numbers_alg2)
    ldi YL, low(table_of_sorted_numbers_alg2)

    rcall COPY_N_BYTES

    rcall TIMER1_RESET

    ldi ZH, high(table_of_sorted_numbers_alg2)
    ldi ZL, low(table_of_sorted_numbers_alg2)

    rcall SELECTION_SORT_N

    rcall TIMER1_READ_TO_time_alg2


DONE:
    rjmp DONE


TIMER1_RESET:

    ldi r16, 0
    sts TCNT1H, r16
    sts TCNT1L, r16
    ret


TIMER1_READ_TO_time_alg1:

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg1_ticks,   r18
    sts time_alg1_ticks+1, r19

    ret


TIMER1_READ_TO_time_alg2:

    lds r18, TCNT1L
    lds r19, TCNT1H

    sts time_alg2_ticks,   r18
    sts time_alg2_ticks+1, r19

    ret


COPY_N_BYTES:

    ldi r20, N

COPY_LOOP:

    ld  r16, Z+
    st  Y+, r16

    dec r20
    brne COPY_LOOP

    ret


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


REDUCE_MOD:

    cpi r16, MODVAL
    brlo RNG_DONE

    subi r16, MODVAL
    rjmp REDUCE_MOD


RNG_DONE:
    ret


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



SELECTION_SORT_N:

    ldi r21, 0


SS_OUTER:

    mov r22, r21

    movw r28, r30
    mov r23, r21


SS_ADV_I:

    tst r23
    breq SS_GOT_I

    adiw r28,1
    dec r23
    rjmp SS_ADV_I


SS_GOT_I:

    ld r17, Y

    mov r24, r21
    inc r24


SS_INNER:

    cpi r24, N
    brsh SS_SWAP


    movw r28, r30
    mov r23, r24


SS_ADV_J:

    tst r23
    breq SS_GOT_J

    adiw r28,1
    dec r23
    rjmp SS_ADV_J


SS_GOT_J:

    ld r18, Y

    cp r18, r17
    brsh SS_NEXT_J

    mov r17, r18
    mov r22, r24


SS_NEXT_J:

    inc r24
    rjmp SS_INNER



SS_SWAP:

    cp r22, r21
    breq SS_NEXT_I


    movw r28, r30
    mov r23, r21


SS_ADV_I2:

    tst r23
    breq SS_I_READY

    adiw r28,1
    dec r23
    rjmp SS_ADV_I2


SS_I_READY:

    ld r18, Y


    movw r26, r30
    mov r23, r22


SS_ADV_MIN:

    tst r23
    breq SS_MIN_READY

    adiw r26,1
    dec r23
    rjmp SS_ADV_MIN


SS_MIN_READY:

    ld r19, X

    st Y, r19
    st X, r18


SS_NEXT_I:

    inc r21
    cpi r21, N-1
    brlo SS_OUTER

    ret
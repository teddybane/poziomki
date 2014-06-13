#include<usb1287def.inc>

// sprawdzic co tak na prawde robi .org
.org 0x0 //przerwanie zwiazane z resetem, jak nacisnie sie reset to zrobi skok do etykiety start
jmp Start

.org 0x0022 // obsluga przerwania timera, ten konkretny adres to timer/counter1 match A
rjmp Obsluga


Start:
// tu inicjacja obslugi stosu
ldi R16, low(RAMEND)	//wpisanie do wskaznika stosu adresu konca pamieci SRAM
ldi R17, high(RAMEND)
out SPH, R17 // co to jest SPH
out SPL, R16 // co to jest SPL
// sprawdzic dokladnie co to jest out i w jakim celu sie go stosuje


ldi R16, 0b11100000//PORTB linie 5 do 7 w trybie wejściowym
in R17, PORTB	//funkcja OR nie zmieni pozostałych bitów PORTx
or R17, R16	//rejestr DDRB wyzerowany, ustawienie PORTB
out PORTB, R17	//włącza podciąganie na liniach wejściowych

ldi R16, 0b00110000//PORTE linie 4 i 5 w trybie wejściowym
in R17, PORTE
or R17, R16
out PORTE, R17

ldi R16, 0b11110000//linie 4-7 portu D w trybie wyjściowym,
in R17, DDRD
or R17, R16	//zasilanie diod LED
out DDRD, R17


//zerowanie timera////////////////////////////////////////////////////////////////////////
ldi r21, low(0)
ldi r22, high(0)
sts TCNT1L, R16
sts TCNT1H, R17


//ustawienie trybu pracy timera - maska//////////////////////////////////////////////////////////
ldi R21, 0b00000010
sts TIMSK1, R21 // Store Direct To Data Space


ldi r21, 0b00000000
sts TCCR1A, R21

// ustawianie prescalera/////////////////////////////////////////////////////////////////
ldi R21, 0b00001011 //0b101 CTC: prescaler 1024
sts TCCR1B, R21 //wpisanie wartosci z R16 do


/////////////////////////////////
ldi R21, LOW(15624)
ldi R22, HIGH(15624)
sts OCR1AH, R22
sts OCR1AL, R21


//zmienne kontroluj
ldi R19, 0x00	// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
ldi R23, 0x01
sei // ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan

SprawdzJoystic:
sbis PINE, 5
rjmp Dol //jesli do dolu zwieksz swiecenie czerwonej i zmniejsz zielonej
sbis PINB, 7
rjmp Gora //jesli do gory zwieksz swiecenie zielonej i zmniejsz czerwonej
rjmp SprawdzJoystic


Dol:
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla

cpi R23, 1
breq omin
dec R23
rjmp omin

Gora:
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla

cpi R23, 10
breq omin
inc R23
rjmp omin

omin:
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
call Pelna_petla
rjmp Miganie



Miganie:	// obsluga migania
cpi R23, 1
breq Hz1

cpi R23, 2
breq Hz2

cpi R23, 3
breq Hz3

cpi R23, 4
breq Hz4

cpi R23, 5
breq Hz5

cpi R23, 6
breq Hz6

cpi R23, 7
breq Hz7

cpi R23, 8
breq Hz8

cpi R23, 9
breq Hz9

cpi R23, 10
breq Hz10

rjmp SprawdzJoystic


Hz1:
ldi R20, HIGH(15625)
ldi R21, LOW(15625)
rjmp Wpisz

Hz2:
ldi R20, HIGH(7813)
ldi R21, LOW(7813)
rjmp Wpisz

Hz3:
ldi R20, HIGH(3906)
ldi R21, LOW(3906)
rjmp Wpisz

Hz4:
ldi R20, HIGH(2604)
ldi R21, LOW(2604)
rjmp Wpisz

Hz5:
ldi R20, HIGH(1953)
ldi R21, LOW(1953)
rjmp Wpisz

Hz6:
ldi R20, HIGH(1563)
ldi R21, LOW(1563)
rjmp Wpisz

Hz7:
ldi R20, HIGH(1302)
ldi R21, LOW(1302)
rjmp Wpisz

Hz8:
ldi R20, HIGH(1116)
ldi R21, LOW(1116)
rjmp Wpisz

Hz9:
ldi R20, HIGH(977)
ldi R21, LOW(977)
rjmp Wpisz

Hz10:
ldi R20, HIGH(868)
ldi R21, LOW(868)
rjmp Wpisz

Wpisz:	// koncowe przypisania
cli
sts OCR1AH, R20	// nowe wartosci do porownania
sts OCR1AL, R21

clr R20	// czyszczenie
clr R21

sts TCNT1H, R20	// zerowanie timera
sts TCNT1L, R21
sei
rjmp SprawdzJoystic


Pelna_petla:
dec R27
cp R27, R31
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
nop
brne Pelna_petla
ldi R27, 0xFF // po skonczeniu petla sprzata po sobie
ret


/**
 * zapalanie jesli zgaszona gaczenie jesli zapalona
 * uwaga strasznie glupie sterowanie
 */
Obsluga: //tu automatycznie wylaczana jest flaga odpowiedzialna za obsluge przerwan
// domyslnie nie mozna przerwac przerwania
cpi R19, 0 // cpi = compare imediate
breq Zapal // branch
//tu gasimy
ldi R17, 0x00 // sterowanie dioda
ldi R19, 0x00	// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
rjmp powrot

Zapal:
//tu zapalamy
ldi R17, 0x40	//0b0001 0000(gorna zielona)
ldi R19, 0x01

powrot:
call Wykonaj
reti //wracanie

Wykonaj:	//procedura gasi pozostałe diody i zapala wła ciwš
push R16
in R16, PORTD	//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17
out PORTD, R16
pop R16
ret


Petla:
push R19
ldi R19, 0xFF
call PustaZ
pop r19
ret

PustaZ:
push R20
ldi R20, 0xFF
call PustaW
dec R19
cpi R19, 0
brne PustaZ
pop R20
ret

PustaW:
nop
dec R20
cpi R20, 0
brne PustaW
ret

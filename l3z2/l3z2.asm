#include<usb1287def.inc>

// sprawdzic co tak na prawde robi .org
.org 0x0 //przerwanie zwiazane z resetem, jak nacisnie sie reset to zrobi skok do etykiety start
jmp Start

.org 0x0022 	// obsluga przerwania timera, ten konkretny adres to timer/counter1 match A 
rjmp Obsluga



Start:
// tu inicjacja obslugi stosu
ldi R16, low(RAMEND)	//wpisanie do wskaznika stosu adresu konca pamieci SRAM
ldi R17, high(RAMEND)
out SPH, R17 		// co to jest SPH
out SPL, R16 		// co to jest SPL
			// sprawdzic dokladnie co to jest out i w jakim celu sie go stosuje

//inicjalizacja podtu D
ldi R16, 0b11110000	//linie 4-7 portu D w trybie wyjsciowym, 
in R17, DDRD
or R17, R16		//zasilanie diod LED
out DDRD, R17


//zerowanie timera////////////////////////////////////////////////////////////////////////
ldi r16, low(0)
ldi r17, high(0)
sts TCNT1L, R16
sts TCNT1H, R17


//ustawienie  trybu pracy timera - maska//////////////////////////////////////////////////////////
ldi R16, 0b00000010
sts TIMSK1, R16 	// Store Direct To Data Space


ldi r16, 0b00000000
sts TCCR1A, R16

// ustawianie prescalera/////////////////////////////////////////////////////////////////
ldi R16, 0b00001011 	//0b101 CTC: prescaler 1024
sts TCCR1B, R16 //wpisanie wartosci z R16 do 


/////////////////////////////////
ldi R16, LOW(15624)
ldi R17, HIGH(15624)
sts OCR1AH, R17
sts OCR1AL, R16


//zmienne kontroluj
ldi R19, 0x00		// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
ldi R23, 0x01
sei 			// ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan

SprawdzJoystic:
sbis PINE, 5
rcall Dol //jesli do dolu zwieksz swiecenie czerwonej i zmniejsz zielonej
sbis PINB, 7
rcall Gora   //jesli do gory zwieksz swiecenie zielonej i zmniejsz czerwonej
rjmp SprawdzJoystic


Dol:
cpi R23, 1
breq omin
dec R23
rjmp omin

Gora:
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
call Miganie
rjmp SprawdzJoystic



Miganie:						// obsluga migania
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
ret


Hz1:
ldi R20, HIGH(15625)
ldi R21, LOW(15625)
rjmp Wpisz
ret

Hz2:
ldi R20, HIGH(7813)
ldi R21, LOW(7813)
rjmp Wpisz
ret

Hz3:
ldi R20, HIGH(3906)
ldi R21, LOW(3906)
rjmp Wpisz
ret

Hz4:
ldi R20, HIGH(2604)
ldi R21, LOW(2604)
rjmp Wpisz
ret

Hz5:
ldi R20, HIGH(1953)
ldi R21, LOW(1953)
rjmp Wpisz
ret

Hz6:
ldi R20, HIGH(1563)
ldi R21, LOW(1563)
rjmp Wpisz
ret

Hz7:
ldi R20, HIGH(1302)
ldi R21, LOW(1302)
rjmp Wpisz
ret

Hz8:
ldi R20, HIGH(1116)
ldi R21, LOW(1116)
rjmp Wpisz
ret

Hz9:
ldi R20, HIGH(977)
ldi R21, LOW(977)
rjmp Wpisz
ret

Hz10:
ldi R20, HIGH(868)
ldi R21, LOW(868)
rjmp Wpisz
ret

Wpisz:						// koncowe przypisania
sts OCR1AH, R20					// nowe wartosci do porownania
sts OCR1AL, R21

clr R20							// czyszczenie
clr R21

sts TCNT1H, R20					// zerowanie timera
sts TCNT1L, R21
ret


Pelna_petla:
dec R27
cp R27, R31
brne Pelna_petla
ldi R27, 0xFF // po skonczeniu petla sprzata po sobie
ret


/** 
 *  zapalanie jesli zgaszona gaczenie jesli zapalona
 *  uwaga strasznie glupie sterowanie 
 */
Obsluga: 		//tu automatycznie wylaczana jest flaga odpowiedzialna za obsluge przerwan
	 		// domyslnie nie mozna przerwac przerwania
cpi R19, 0 		// cpi = compare imediate
breq Zapal 		// branch
//tu gasimy
ldi R17, 0x00 		// sterowanie dioda
ldi R19, 0x00		// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
rjmp powrot

Zapal:
//tu zapalamy
ldi R17, 0x40		//0b0001 0000(gorna zielona)
ldi R19, 0x01

powrot:
call Wykonaj
reti //wracanie 

Wykonaj:		//procedura gasi pozostałe diody i zapala wła ciwš
push R16
in R16, PORTD		//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17 
out PORTD, R16
pop R16
ret

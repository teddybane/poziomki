#include<usb1287def.inc>

.org 0x0
jmp Start

.org 0x2e
jmp Obsluga

Start:

// tu inicjacja obslugi stosu
ldi R16, low(RAMEND)//wpisanie do wskaźnika stosu adresu końca pamięci SRAM
ldi R17, high(RAMEND)
out SPH, R17
out SPL, R16

//inicjalizacja podtu D
ldi R16, 0b11110000//linie 4-7 portu D w trybie wyjściowym, 
in R17, DDRD
or R17, R16	   //zasilanie diod LED
out DDRD, R17


// ustawianie prescalera
ldi R16, 5 //0b101 ustawienie wartosci , 
//odpowiednia wartosc bierzemy z dokumentacji
out TCCR0B, R16 //wpisanie wartosci z R16 do 
				// Out To I/O Location
				// Timer Counter Control Register

// ustawienie trybu pracy timera
ldi R16, 1
sts TIMSK0, R16 // Store Direct To Data Space
				// Timer counter Interrupt Mask register

ldi R19, 0x00
ldi R18, 0x01

sei // ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan
koniec: jmp koniec


Obsluga:
//zapalanie jesli zgaszona gaczenie jesli zapalona
//uwaga strasznie głupie sterowanie
cp R19, R18
brne pomin

//tu gasimy
ldi R17, 0x00
ldi R19, 0x00
rjmp bla

pomin:
//tu zapalamy
ldi R17, 0x40//0b0001 0000(górna zielona)
ldi R19, 0x01
bla:
call Wykonaj
reti


Wykonaj://procedura gasi pozostałe diody i zapala wła ciwš
push R16
in R16, PORTD//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17 
out PORTD, R16
pop R16
ret

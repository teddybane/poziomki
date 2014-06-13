#include<usb1287def.inc>

.def sterujacy=R25 //wartosc tego rej. jest kopiowana do rej. odpowiedzialnego za match
.def stan_diody=R26
// sprawdzic co tak na prawde robi .org


.cseg

.org 0x0 //przerwanie zwiazane z resetem, jak nacisnie sie reset to zrobi skok do etykiety start
jmp Start

.org 0x2A//obsluga przerwania timera, tutaj compate match A
jmp Czerwona

.org 0x2E	// obsluga przerwania timera, ten konkretny adres to timer/counter0 overflow
// mogl by to tez byc timer/counter0 compare match A
// timer/counter0 compare match B
// istenieje tez timer/counter 1, 2 i 3 z czego, 1 ma A, B, C; 2 tylko A, B; 3 ma dodatkowy tryb Capture Event
jmp Zielona






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

//inicjalizacja podtu D
ldi R16, 0b11110000	//linie 4-7 portu D w trybie wyjsciowym,
in R17, DDRD //ddrd odpowiada za tryb(in/out) bitów w porcie D
or R17, R16	//zasilanie diod LED
out DDRD, R17



/* timery 0, 1, 3 maja ten sam prescaler, ale moga miec rozne ustawienia
 * prescaler sluzy do dzielenia czestotliwosci zegara na f_clk/8, 64, 256, 1024
 */
// ustawianie prescalera
ldi R16, 3 //0b101 ustawienie wartosci ,
//odpowiednia wartosc bierzemy z dokumentacji
out TCCR0B, R16 //wpisanie wartosci z R16 do
// Out To I/O Location
// Timer Counter Control Register
// bit CS02:0 odpowiadaja za wybor zrodla sygnalu zegara lub wybor wybor prescalera
// 0b000 zegar zatrzymany brak zrodla
// 0b001 brak dzielnika(prescalera) dziala z czestotliwoscia pracy zegara
// 0b010 dzielenie prze 8
// 0b011 dzielenie prze 64
// 0b100 dzielenie prze 256
// 0b101 dzielenie prze 1024
// 0b110 zewnetrzny zegar na opadajacym zboczu
// 0b111 zewnetrzny zegar na wznoszacym zboczu
// wazny jest tu rejestr 'output compare register A - OCR0A' zeby wygenerowc przerwanie dla A musi byc rowny licznikowi timera
// i rejestr 'outbut compare register B - OCR0B' to samo tylko ze B

// ustawienie wielkosci dla ktorej nastepuje dopasownie wielkosci
// efekt: zmiana proporcji dlugosci swiecenia czerownej do zielonej
ldi sterujacy, 128 // w polowie zliczania - startujemy z 1 do 1
out OCR0A, sterujacy

// ustawienie trybu pracy timera 0
ldi R16, 3
sts TIMSK0, R16 // Store Direct To Data Space
// Timer counter Interrupt Mask register
// bity 7 do 3 sa zarezerwowane i zawsze czytane jako 0
// bit 2 ustawiony na 1 wlacza przerwanie B
// bit 1 ustawiony na 1 wlacza przerwanie A
// bit 0 ustawiony na 1 wlacza przerwanie w trakcie przepelnienia
//ldi R16, 2
//sts TIMSK2, R16

//zmienne kontroluj
ldi stan_diody, 0x00	// zmienna-flata przedstawiajaca stan diody 0=zielona, 1=czerwona

sei // ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan

// tu obsluge zwiekszania i zmniejszania zmiennej kontrolujacej dlugosc swiecenia
SprawdzJoystic:
//cli
sbis PINE, 5
rcall Dol //jesli do dolu zwieksz swiecenie czerwonej i zmniejsz zielonej
sbis PINB, 7
rcall Gora //jesli do gory zwieksz swiecenie zielonej i zmniejsz czerwonej
//sei
rjmp SprawdzJoystic


Dol:
cpi sterujacy, 0
breq DalejDol //jesli sa rowne to maskujemy przerwania i pomijamy decrementacjie
dec sterujacy
//cli
//out OCR0A, sterujacy
//sei

DalejDol:
//ldi sterujacy, 1
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna

rjmp SprawdzJoystic


Gora:
cpi sterujacy, 255
breq DalejGora
inc sterujacy
//cli
//out OCR0A, sterujacy
//sei
DalejGora:
//ldi sterujacy, 254
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna
rcall Petla_pelna

rjmp SprawdzJoystic



Petla_pelna:
dec R27
cp R27, R31
nop
nop
nop
brne Petla_pelna
ldi R27, 0xFF // po skonczeniu petla sprzata po sobie
ret


/**
 * przelacza z zielonej na czerwona i z czerwonej na zielona
 
Przelacz:
out OCR0A, sterujacy // przekopiowanie zmiannej sterujacej do rejestru sterujacego
cpi stan_diody, 1 //if stan_diody == 1 mamy zapalona zielona
breq zapal_czerwona

rcall Gasimy
ldi stan_diody, 1
ldi R17, 0x20 //0b0010 0000(dolna zielona)
rcall Wykonaj
rjmp dalej

zapal_czerwona:
rcall Gasimy
ldi stan_diody, 0
ldi R17, 0x10 // 0b0100 0000(dolna czerwona)
rcall Wykonaj // zapalenie

dalej: //poprawne zakonczenie obslugi przerwania
reti
*/

Wykonaj:	//procedura gasi pozostałe diody i zapala wła ciwš
push R16
in R16, PORTD	//or, aby oszczedzić orginalne ustawienia reszty lini portu B
andi R16, 0x0F
or R16, R17
out PORTD, R16
pop R16
ret

Gasimy:
ldi R17, 0x00
rcall Wykonaj
ret

Zielona:
out OCR0A, sterujacy
rcall Gasimy
ldi R17, 0x20 //0b0010 0000(dolna zielona)
rcall Wykonaj
reti

Czerwona:
out OCR0A, sterujacy
rcall Gasimy
ldi R17, 0x10 // 0b0100 0000(dolna czerwona)
rcall Wykonaj // zapalenie
reti

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



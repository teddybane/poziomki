#include<usb1287def.inc>

// sprawdzic co tak na prawde robi .org
.org 0x0 //przerwanie zwiazane z resetem, jak nacisnie sie reset to zrobi skok do etykiety start
jmp Start

.org 0x2e 	// obsluga przerwania timera, ten konkretny adres to timer/counter0 overflow
		// mogl by to tez byc timer/counter0 compare match A
		//  		      timer/counter0 compare match B
		// istenieje tez timer/counter 1, 2 i 3 z czego, 1 ma A, B, C; 2 tylko A, B; 3 ma dodatkowy tryb Capture Event 
jmp Obsluga

/* timery 0, 1, 3 maja ten sam prescaler, ale moga miec rozne ustawienia
 * prescaler sluzy do dzielenia czestotliwosci zegara na f_clk/8, 64, 256, 1024
 */






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


// ustawianie prescalera
ldi R16, 5 	//0b101 ustawienie wartosci , 
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

// ustawienie trybu pracy timera
ldi R16, 1
sts TIMSK0, R16 	// Store Direct To Data Space
			// Timer counter Interrupt Mask register
			// bity 7 do 3 sa zarezerwowane i zawsze czytane jako 0
			// bit 2 ustawiony na 1 wlacza przerwanie B
			// bit 1 ustawiony na 1 wlacza przerwanie A
			// bit 0 ustawiony na 1 wlacza przerwanie w trakcie przepelnienia

//zmienne kontroluj
ldi R19, 0x00		// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
ldi R18, 0x01		// zmienna sluzoca do porownywania ze zmienna odpowiedzialna za stan diody

sei 			// ustawienie flagi i == wyzwolenie mozliwosci obslugi przerwan
koniec: jmp koniec 	// nieskonczona petla


/** 
 *  zapalanie jesli zgaszona gaczenie jesli zapalona
 *  uwaga strasznie glupie sterowanie 
 */
Obsluga: 		//tu automatycznie wylaczana jest flaga odpowiedzialna za obsluge przerwan
	 		// domyslnie nie mozna przerwac przerwania
cp R19, R18 		// cp = compare
brne pomin 		// branch

//tu gasimy
ldi R17, 0x00 		// sterowanie dioda
ldi R19, 0x00		// zmienna-flata przedstawiajaca stan diody 0=zgaszona, 1=zapalona
rjmp bla

pomin:
//tu zapalamy
ldi R17, 0x40		//0b0001 0000(gorna zielona)
ldi R19, 0x01
bla:
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

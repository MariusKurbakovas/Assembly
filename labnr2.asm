;Programa nuskaito argumenta (esanti ES:[81h] ir toliau) kuriame pateikta uzduoties raide (A, B arba C) ir failo is kurio skaitysime duomenis pavadinimas
;Uzduotis A: nuskaito duotus laukus, is lauko ismesdama skaitmenis 1, 5 ir 7, jei laukas lieka tuscias parasoma NA (laukai atskiriami ;, kiekvienoje eiluteje yra 5 laukai)
;Uzduotis B: nuskaito baitu blokus (po 3 baitus kiekvienas blokas) ir kiekviename bloke sustumdo bitus tokia tvarka: (3 → 6 → 15 → 17→ 23)
;Uzduotis C: Mini Dissasembleris (nepadarytas)
;---------------------------------------------------------------------
spausdinkEil macro eilute  
                            
    mov ah, 09
    mov dx, offset eilute
    int 21h
    endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
spausdinkBaita macro baitas

	mov dl, baitas
	mov ah, 02h
	int 21h
	endm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.model small
       ASSUME CS:kodas, DS:duomenys, SS:stekas
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stekas segment word stack 'STACK'
       dw 400h dup (00)               ; stekas -> 2 Kb
stekas ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
duomenys segment para public 'DATA'

	pranesimas:
	db 'Marius Kurbakovas Programu sistemos 1 kursas pirma grupe', 0Dh, 0Ah,'$'
	klaidaArg:
	db 'Klaida skaitant argumenta $'
	IveskitePav:
	db 'Iveskite isvedamu duomenu failo varda $'
	klaidaAtidarantFailaSkaitymui:
	db 'Klaida atidarant faila skaitymui $'
	klaidaAtidarantFailaRasymui:
	db 'Klaida atidarant/sukuriant faila rasymui $'
	UzduotiesNera:
	db 'Nurodytos uzduoties nera $'
	FailasTuscias:
	db 'Duomenu failas tuscias $'
	SkaitymoKlaida:
	db 'Duomenu failo skaitymo klaida $'
	RasymoKlaida:
	db 'Duomenu failo rasymo klaida $'
	NaujaEil:
	db 0Dh, 0Ah, '$'
	
	skaitomasFailas:                            ;Ivedimo deskriptorius
    dw 0FFFh
	rasomasFailas:                              ;Isvedimo deskriptorius
	dw 0FFFh
	uzdavinioPav:                               ;buferis pirmajam argumentui (Uzdavinio pavadinimui)
	db 00
	argumentas:                                 ;buferis antrajam argumentui (Ivedimo failo pavadinimui)
	db 100h dup (00)
	OutputFile:                                 ;Isvedimo failo pavadinimo buferis
	db 20, 00, 20 dup (00)
	NuskaitytasBaitas:                          ;buferis nuskaitytam baitui laikyti
	db 00, 00, '$'
	
	;B uzduoties duomenys
	Baitai:                                     ;Nagrinejamu baitu masyvas
	db 3 dup (00)
duomenys ends
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LOCALS @@


kodas segment para public 'CODE'

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skaitykArgumenta proc  
    
    mov cl, es:byte ptr[80h]               ;Nuskaitome argumento ilgi
	mov si, 0081h                          ;Argumentas prasideda nuo es:[81h]
	mov di, offset argumentas
	xor ch, ch
	xor ah, ah
	cmp cx, 0000                           ;Tikriname ar buvo ivesta argumentas
	jne @@skaitymas1
	stc                                    ;jei nebuvo ivestas argumentas tai pazymime kad klaida
	jmp @@pab                              ;ir sokame i funkcijos pabaiga
	
	@@skaitymas1:
	mov al, byte ptr es:[si]               ;nuskaitomas argumento baitas
	cmp al, ' '                            ;tikrina ar ne tarpas
	je @@praleist                          ;jei tarpas tai ta simboli praleidzia
	cmp al, 0Dh
	je @@praleist
	cmp al, 0Ah
	je @@praleist
	mov byte ptr uzdavinioPav, al          ;kai randa ne tarpa, issaugo i atminti (tai bus kuria uzduoti reiks atlikti)
	dec cl                                 ;sumaziname cl nes nuskaiteme viena baita, taciau issokame is ciklo
	inc si
	cmp cl, 0000h
	jne @@skaitymas2                       ;jei cl!=0h sokame i antraji cikla kuris nuskaitys likusi argumenta
	stc                                    ;jei cl==0 tai antro argumento nera, klaida
	jmp @@pab
	@@praleist:
	inc si                                 ;jei baitas tarpas tikriname kita baita
	loop @@skaitymas1
	stc                                    ;jei ciklas baigesi ir nebuvo rastas nei vienas ne tarpas tai pazymime kad klaida
	jmp @@pab                              ;ir sokame i funkcijos pabaiga
	
	@@skaitymas2:
	mov al, byte ptr es:[si]               ;nuskaitomas argumento baitas
	cmp al, ' '                            ;tikrina ar ne tarpas
	je @@praleist2                         ;jei tarpas tai ta simboli praleidzia
	cmp al, 0Dh
	je @@praleist2
	cmp al, 0Ah
	je @@praleist2
	mov byte ptr [di], al                  ;irasome antraji argumenta
	inc ah                                 ;pozymis kad pradejo skaityt antraji argumenta
	inc di
	jmp @@toliau
	@@praleist2:
	cmp ah, 01h                            ;jei ah = 01h reiskias antrasis argumentas baigtas skaityti
	je @@isejimas
	@@toliau:
	inc si
	loop @@skaitymas2
	
	@@isejimas:
	cmp ah, 0000h                          ;patikriname ar buvo nuskaitytas antrasis argumentas
	jg @@viskas                            ;jei buvo tai iseiname be klaidu
	stc                                    ;jei nebuvo tai klaida
	jmp @@pab                              ;iseiname su klaida
	@@viskas:
	clc                                    ;klaidos nerasta
	@@pab:
          
    ret     
		  
skaitykArgumenta endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
atverkFailaSkaitymui proc

	mov dx, offset argumentas
	mov ah, 3Dh                            ;atidaromas failas
	mov al, 00h
	int 21h
	
	jc @@pab                               ;jei CF = 1 tai klaida
	mov word ptr skaitomasFailas, ax       ;issaugomas skaitymo deskriptorius
	
	@@pab:
	ret
atverkFailaSkaitymui endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
atverkFailaRasymui proc

	mov dx, offset OutputFile
	inc dx                                 ;dx=dx+2, nes ivestas string'as prasideda tik nuo 3 baito
	inc dx
	mov ah, 3Ch                            ;Sukuriamas/perrasomas failas
	mov al, 00h
	int 21h
	
	jc @@pab                               ;jei CF = 1 tai klaida
	mov word ptr rasomasFailas, ax         ;issaugomas failo rasymo deskriptorius
	
	@@pab:
	ret
atverkFailaRasymui endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
skaitykBaita proc
;I funkcija paduodami registrai:
; dx - buferio nuskaitytasBaitas adresas
; bx - word ptr skaitomasFailas
; Funkcija keicia AX
; AL - grazinamas nuskaitytas baitas
; AH - grazinamas klaidos kodas arba 0 jei klaidos nebuvo
	push si
	push cx
	mov si, dx                             ;si = dx, nes veliau sia reiksme naudosime adresavimui
	mov cx, 0001h                          ;cx = 1, kad skaitytu 1 baita
	mov ah, 3Fh                            ;skaitymo funkcija
	int 21h
	jnc @@toliau
	mov ah, 0FEh                           ;skaitymo klaida
	jmp @@pabaiga
	
	@@toliau:
	cmp ax, 0                              ;ar dar ne failo pabaiga
	jne @@NeKlaida
	mov ah, 0FFh                           ;failo pabaiga
	jmp @@pabaiga
	
	@@NeKlaida:
	mov ah, 00                             ;ah = 0 (zenklas kad baitas nuskaitytas be klaidos)
	mov al, [si]                           ;AL <- nuskaitytas baitas
	
	@@pabaiga:
	pop cx
	pop si
	ret
skaitykBaita endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rasykBaita proc

	push cx
	push bx
	push ax
	
	mov bx, word ptr rasomasFailas       ;deskriptorius
	mov cx, 0001h                        ;cx = 1 rasysime 1 baita
	mov dx, offset nuskaitytasBaitas     ;rasysime nuskaityta baita
	
	mov ah, 40h                          ;rasymo funkcija
	int 21h
	
	jc @@RasymoKlaida
	
	pop ax
	pop bx
	pop cx
	ret
	
	@@RasymoKlaida:
	spausdinkEil RasymoKlaida
	mov ah, 4ch
    int 21h
rasykBaita endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
uzduotisA proc
;pasibaigus eilutej nuskaitoma 0Dh ir 0Ah

	mov dx, offset nuskaitytasBaitas
	mov bx, word ptr skaitomasFailas
	@@PirmosEilutesSkaitymas:
	call skaitykBaita
	cmp ah, 00h                            ;patikriname ar nuskaicius nebuvo klaidos
	jne @@klaida
	call rasykBaita
	cmp al, 0Ah                            ;patikriname ar ne eilutes pabaiga
	jne @@PirmosEilutesSkaitymas           ;jei pabaiga tai toliau nebeskaitome pirmos eilutes
	
	@@LikusiuEiluciuSkaitymas:
	call skaitykBaita
	cmp al, 00                             ;patikriname ar ne failo pabaiga
	je @@baigtiSkaityma
	cmp ah, 00h                            ;patikriname ar ne klaida
	jne @@baigtiSkaityma
	cmp al, ';'                            ;patikriname ar ne lauko pabaiga
	je @@kitasLaukas
	cmp al, 0Dh                            ;patikriname ar ne eilutes(o kartu ir paskutinio lauko) pabaiga
	je @@kitasLaukas
	inc ch                                 ;ch skaiciuojame kiek isviso lauke yra baitu
	cmp al, '5'
	je @@Ismesti
	cmp al, '7'
	je @@Ismesti
	cmp al, '1'
	je @@Ismesti                           ;ismetame 1, 5 ir 7
	jmp @@Neismesti
	@@Ismesti:
	inc cl                                 ;cl skaiciuojame kiek baitu buvo ismesta is lauko
	jmp @@LikusiuEiluciuSkaitymas
	@@Neismesti:
	call rasykBaita
	jmp @@LikusiuEiluciuSkaitymas
	@@kitasLaukas:
	cmp ch, cl                             ;jei laukui pasibaigus ch = cl , tai yra buvo ismesti visi lauke esantys baitai, tai spausdiname NA
	je @@rasykNA
	xor cx, cx                             ;pasibaigus laukui cx = 0 (lauko nuskaitytus ir ismestus baitus skaiciuosime per naujo)
	call rasykBaita
	jmp @@LikusiuEiluciuSkaitymas
	@@rasykNA:
	xor cx, cx                             ;pasibaigus laukui cx = 0 (lauko nuskaitytus ir ismestus baitus skaiciuosime per naujo)
	;rasyti NA
	push ax
	mov si, offset nuskaitytasBaitas
	mov al, [si]
	mov ah, 'N'
	mov [si], ah
	call rasykBaita
	mov ah, 'A'
	mov [si], ah
	call rasykBaita
	mov [si], al
	pop ax
	;baigti rasyti NA
	call rasykBaita                         ;Paraso kabliataski arba eilutes pabaiga, po NA
	jmp @@LikusiuEiluciuSkaitymas
	
	@@klaida:
	cmp ah, 0FEh                            ;FEh - skaitymo klaida
	je @@SkaitymoKlaida
	cmp ah, 0FFh                            ;FFh - failas tuscias
	je @@FailasTuscias
	jmp @@baigtiSkaityma
	
	@@SkaitymoKlaida:
	spausdinkEil SkaitymoKlaida
	jmp @@baigtiSkaityma
	
	@@FailasTuscias:
	spausdinkEil FailasTuscias
	
	@@baigtiSkaityma:
	ret
uzduotisA endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
uzduotisB proc
	@@TrijuBaituSkaitymas:
	mov dx, offset nuskaitytasBaitas
	mov bx, word ptr skaitomasFailas
	mov cx, 0003h
	@@SkaitomasBlokas:
	call skaitykBaita
	cmp ah, 00h                             ;patikriname ar nuskaicius nebuvo klaidos
	jne @@klaida
	xor ah, ah
	mov si, cx
	mov byte ptr [Baitai+si-1], al
	loop @@SkaitomasBlokas
	
	
	;24 bitu "ROR'as":
	;24 bitams manipuliuoti naudosime AX, BL
	;CX bus naudojamas ROR poslinkiams
	;BH ir DL bus naudojami sukeiciamo bito saugojimui
	mov ah, byte ptr [Baitai]
	mov al, byte ptr [Baitai +1]
	mov bl, byte ptr [Baitai +2]
	
	mov cx, 0003h
	ror bl, cl
	mov bh, 01h
	and bh, bl
	
	ror bl, cl 
	mov dl, 01h
	and dl, bl
	call Tkr1
	
	mov cx, 0002h
	ror bl, cl
	
	mov cx, 0007h
	ror al, cl
	call Tkr2
	ror al, 1
	
	ror ah, 1
	call Tkr3
	mov cx, 0006h
	ror ah, cl
	call Tkr4
	
	mov byte ptr [Baitai], ah
	mov byte ptr [Baitai +1], al 
	mov byte ptr [Baitai +2], bl 
	
	mov cx, 0003h
	@@TrijuBaituRasymas:
	mov si, cx
	mov al, byte ptr [Baitai+si-1]
	mov byte ptr [nuskaitytasBaitas], al
	call rasykBaita
	loop @@TrijuBaituRasymas
	jmp @@TrijuBaituSkaitymas
	
	@@klaida:
	cmp ah, 0FEh                            ;FEh - skaitymo klaida
	je @@SkaitymoKlaida
	cmp ah, 0FFh                            ;FFh - failas tuscias
	je @@FailasBaigesi
	jmp @@baigtiSkaityma
	
	@@SkaitymoKlaida:
	spausdinkEil SkaitymoKlaida
	jmp @@baigtiSkaityma
	
	@@FailasBaigesi:
	
	@@baigtiSkaityma:
	ret
uzduotisB endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RandamasBitas proc
;B uzduotyje naudojama procedura
;sis proceduros loop'as bus panaudota 24 kartus kiekvienam blokui pertvarkyti
;Bloko Bitai - jauniausieji(0-7) AL, viduriniai(8-15) AH, vyriausieji(16-23) BL
	@@bitas:
	shr bl, 1h
	jc @@PermestBitaIAX                     ;Patikriname ar nustumtas bitas buvo 1, jei buvo 1, tai ji nukeliame i BL registro 7 vieta
	jmp @@NepermestBitoIAX
	
	@@NepermestBitoIAX:
	shr ax, 1h
	jc @@PermestBitaIBL                     ;Patikriname ar nustumtas bitas buvo 1, jei buvo 1, tai ji nukeliame i AX registro 15 vieta
	jmp @@Pab
	
	@@PermestBitaIAX:
	shr ax, 1h
	xor ax, 8000h                              ; or cl, 1000 0000, ikelia 1 i 7 cl bitam
	jc @@PermestBitaIBL
	jmp @@Pab

	@@PermestBitaIBL:
	xor bl, 80h                            ; or ax, 1000 0000 0000 0000, ikelia 1 i 15 cl bita
	
	@@Pab:
	loop @@bitas
	
	ret
RandamasBitas endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Tkr1 proc

	mov dl, 01h
	and dl, bl                    ;DL stovi dabartinis paskutinis bitas
	cmp bh, 01h
	je @@lygus1
    cmp dl, 01h
	je @@lygus11
	jmp @@lygus1
	@@lygus11:
	xor bl, dl
	@@lygus1:
	or bl, bh
	ret
Tkr1 endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Tkr2 proc
	
	mov bh, 01h
	and bh, al
	cmp dl, 01h
	je @@lygus2
	cmp bh, 01h
	je @@lygus22
	jmp @@lygus2
	@@lygus22:
	xor al, bh
	@@lygus2:
	or al, dl
	ret
Tkr2 endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Tkr3 proc

	mov dl, 01h
	and dl, ah                  ;DL stovi dabartinis paskutinis bitas
	cmp bh, 01h
	je @@lygus1
    cmp dl, 01h
	je @@lygus11
	jmp @@lygus1
	@@lygus11:
	xor ah, dl
	@@lygus1:
	or ah, bh
	ret
Tkr3 endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Tkr4 proc
	
	mov bh, 01h
	and bh, ah
	cmp dl, 01h
	je @@lygus2
	cmp bh, 01h
	je @@lygus22
	jmp @@lygus2
	@@lygus22:
	xor ah, bh
	@@lygus2:
	or ah, dl
	ret
Tkr4 endp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


pradzia:

		mov ax, duomenys
        mov ds, ax 
        
        spausdinkEil pranesimas
         
        call skaitykArgumenta
		jnc @@AtidarykFaila                ;jei klaidos nebuvo rasta vykdome programa toliau
		spausdinkEil klaidaArg             ;jei rasta klaida atspausdiname klaidos teksta
		jmp @@KodoPabaiga                  ;ir uzbaigiame programa
		
		@@AtidarykFaila:
		call atverkFailaSkaitymui
		jnc @@AtidarykFaila2               ;patikriname ar nera klaidu
		spausdinkEil klaidaAtidarantFailaSkaitymui
		jmp @@KodoPabaiga
		@@AtidarykFaila2:
		spausdinkEil IveskitePav
		spausdinkEil NaujaEil
		mov dx, offset OutputFile          ;ivedame isvedimo failo pavadinima
		mov ah, 0Ah                        ;string'o ivedimo i buferi funkcija
		int 21h
		xor ax, ax                         ;ax = 0
		mov al, byte ptr [Outputfile + 1]  ;al = ivestu baitu kiekis
		mov si, ax                         ;si = ax
		mov byte ptr [OutputFile+si+2], 00h;Vietoj 0D eilutes gale ikelia 00
		call atverkFailaRasymui
		jnc @@Uzduotis                     ;patikriname ar nera klaidu
		spausdinkEil klaidaAtidarantFailaRasymui
		jmp @@KodoPabaiga
		
		@@Uzduotis:
		mov al, byte ptr uzdavinioPav      ;al = uzdavinioPav (pirmasis argumentas)
		cmp al, 'A'                        ;patikriname kuria uzduoti reikia daryti
		je @@uzduotisA
		cmp al, 'a'
		je @@uzduotisA
		cmp al, 'B'
		je @@uzduotisB
		cmp al, 'b'
		je @@uzduotisB
		cmp al, 'C'
		je @@uzduotisC
		cmp al, 'c'
		je @@uzduotisC
		spausdinkEil UzduotiesNera         ;Jei tokios uzduoties nera, spausdinama klaida
		jmp @@KodoPabaiga
		
		@@UzduotisA:
		call UzduotisA
		jmp @@KodoPabaiga
		
		@@UzduotisB:
		call UzduotisB
		@@UzduotisC:
		
		
	@@KodoPabaiga:
    mov ah, 4ch
    int 21h

kodas  ends
    end pradzia 

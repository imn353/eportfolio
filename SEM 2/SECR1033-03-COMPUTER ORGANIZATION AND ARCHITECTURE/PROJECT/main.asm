TITLE Project COA
; Author: Iman Abadi Bin Mohd Nizwan (Birthday: 10/5/2004)
;		: Mohamed Alif Fathi Bin Abdul Latif (Birthday: 31/12/2004)
;		: Muhammad Mukhritz Al-Iman Bin Raffi (Birthday: 16/1/2004)

include Irvine32.inc

.data
message1 BYTE "Welcome to CPU Benchmark Program",0dh,0ah,0dh,0ah
BYTE "Benchmark CPU time Using Equation y = (10 * x^3) + (31 * x^2) + (16 * x) + 1", 0dh,0ah
BYTE "	(with only coef1, coef2, coef3, coef4 = 10, 31, 16, 1 msec)", 0dh,0ah,0dh,0ah,0

message2 BYTE "Enter the Number of Looping (N) = ", 0

message3 BYTE "CPU time Stress Test in progress...",0dh,0ah,0dh,0ah,0

message4 BYTE "Result:",0dh,0ah,0dh,0ah
BYTE "First Capture Execution time in milisecond: ", 0

message5 BYTE "Second Capture Execution time in millisecond: ", 0

message6 BYTE "Different Execution time in millisecond: ", 0

message7 BYTE "Value of Sum from the Stress Test (polynomial) = ", 0

message8 BYTE "Press 'y' to continue or 'n' to exit the benchmark : ", 0

max_loop DWORD ?

msec1 DWORD ?
msec2 DWORD ?

sum DWORD 0

coef1 DWORD 10

coef2 DWORD 31

coef3 DWORD 16

coef4 DWORD 1

initial_value DWORD 1

stryn BYTE "Press 'y' to Main Menu or 'n' to Exit Program : ", 0
charIn BYTE ?
charY db 'y'
strbye BYTE "Thank you ... BYE!!", 0dh, 0ah, 0

.code
main proc
startProg:
	call Clrscr
	mov edx,OFFSET message1
	call WriteString

	mov edx,OFFSET message2
	call WriteString

	call ReadDec
	mov max_loop, eax

	mov edx, OFFSET message3
	call WriteString

	call GetMseconds
	mov msec1, eax

	mov ecx, max_loop

L1: 
	; (10 * x^3)

	mov sum, 0d

	mov eax, initial_value
	mov ebx, initial_value
	mul ebx ; eax = eax * ebx
	mul ebx ; eax = eax * ebx
	mov ebx , 10d 
	mul ebx ; eax = eax * ebx
	add sum , eax
	
	; (31 * x^2)

	mov eax, initial_value
	mov ebx, initial_value
	mul ebx ; eax = eax * ebx
	mov ebx , 31d 
	mul ebx ; eax = eax * ebx
	add sum , eax

	; (16 * x)

	mov eax , initial_value
	mov ebx , 16d 
	mul ebx ; eax = eax * ebx
	add sum , eax

	; + 1

	add sum , 1d
	inc initial_value
	call Delay 
	loop L1

	call GetMseconds
	mov msec2, eax

	mov edx, OFFSET message4
	call WriteString
	mov eax , msec1 
	call WriteDec
	call crlf

	mov edx, OFFSET message5
	call WriteString
	mov eax , msec2
	call WriteDec
	call crlf

	mov edx, OFFSET message6
	call WriteString
	mov eax , msec2 
	sub eax , msec1
	call WriteDec
	call crlf

	mov edx, OFFSET message7
	call WriteString
	mov eax , sum 
	call WriteDec
	call crlf
	call crlf

	mov edx, OFFSET message8
	call WriteString
	call ReadChar
	mov charIn, AL
	call WriteChar
	call Crlf
	call Crlf
	mov BL, charY
	cmp BL, charIn
	JE startProg

	mov edx, OFFSET strbye
	call WriteString

	exit
	main ENDP
	END main
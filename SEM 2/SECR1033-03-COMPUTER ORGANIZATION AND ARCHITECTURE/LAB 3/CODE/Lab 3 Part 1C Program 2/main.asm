include Irvine32.inc

.data

message1 BYTE "Calculate SUM index (ODD or EVEN) in array HELLO[6]: ", 0dh, 0ah, 0
strinNo BYTE "Input INT (unsign) ", 0
number DWORD 6 dup(0h); declare array 

int_message BYTE "Integer Input : ", 0

TotalEven DWORD ?
TotalOdd DWORD ?

strResultHello BYTE "Result sum Hello[index]: ", 0dh, 0ah, 0

strResultOdd BYTE "Sum Hello[odd] index location : ", 0

strResultEven BYTE "SUM Hello[even] index location : ", 0

promptBad BYTE "Invalid input, please enter again", 0

.code
main proc

	call Clrscr
	mov edx, OFFSET message1
	call WriteString
	call crlf

	mov ecx, 6; loop kena guna ecx
	mov ebx, 0

loopL1:
	read_inOption2:
	mov edx, OFFSET int_message  
	call WriteString
	call ReadDec ; value cin store dkt eax

	jnc goodInOption2
	mov edx, OFFSET promptBad
	call WriteString
	call crlf
	jmp read_inOption2

goodInOption2 :
	mov number[ebx], eax
	mov eax, number[ebx]
	add ebx, 4
	loop loopL1

	call crlf

	mov ecx, 3 ; looping 3 kali
	mov ebx, 0 ; index odd loc 0, 8, 16
	mov eax, 0
	loopL2:
	add eax, number[ebx]
	add ebx, 8
	loop loopL2
	mov TotalEven, eax ; calculate number[] odd location

	call crlf
	mov ecx, 3
	mov ebx, 4; increase by 4 bec of dword
	mov eax, 0

loopL3:
	add eax, number[ebx]
	add ebx, 8; increase by 4 bec of dword
	loop loopL3
	mov TotalOdd, eax

; output result sum evenn and odd number[]

	mov edx, offset strResultHello
	call WriteString
	call crlf
	mov edx, offset strResultEven
	call WriteString
	mov eax, TotalEven
	call WriteDec
	call crlf

	mov edx, offset strResultOdd
	call WriteString
	mov eax, TotalOdd
	call WriteDec
	call crlf
	call crlf

exit
main ENDP
END main
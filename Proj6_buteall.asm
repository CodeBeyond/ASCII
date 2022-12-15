; TITLE PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures      (proj6_butleall.asm)

; Author: Allison Butler
; Last Modified: 6/2/22
; OSU email address: butleall@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:        6         Due Date: 6/5/2022
; Description: This program asks the user for 10 signed decimal integers. It will display the numbers, their value
; and their sum. The number entered by the user must be small enough to fit in a 32 byte register, other wise error
; messages will occur. An error message will occur for unsigned integers as well. 

INCLUDE Irvine32.inc

; (insert macro definitions here)
; Prompts, identifying strings, and other memory locations must be 
; passed by address to the macros.
; Prompts user, stores user input 
mGetString	MACRO	Prompting, dataBuff, buffSize  
	push	edx
	push	ecx
	mov	    edx, Prompting	
	call	WriteString
	mov	    edx, dataBuff
	mov	    ecx, size
	call	ReadString
	pop	    ecx
	pop	    edx
ENDM

; Displays the string from above from memory
mDisplayString	MACRO	DisplayStringAddress  
	push	edx
	mov	    edx, DisplayStringAddress
	call	WriteString
	pop	    edx
ENDM




.data

; (insert variable definitions here)
titleDisplay	BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures", 0
directions  	BYTE	"Please provide 10 signed decimal integers.", 13, 10
		        BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 13, 10
		        BYTE	"After you have finished inputting the raw numbers I will display a list", 13, 10
		        BYTE	"of the integers, their sum, and their average value.", 0
firstUserPrompt	BYTE	"Please enter a signed integer: ", 0
mainError	    BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
promptUserAgain	BYTE	"Please try again: ", 0
tenValidNums	BYTE	"You entered the following numbers:", 0
numFormat	    BYTE	", ", 0
totalSum		BYTE	"The sum of these numbers is: ", 0
average		    BYTE	"The trucated average is: ", 0
thankyou	    BYTE	"Thanks for playing!", 0
digitsList		DWORD	10 DUP(?)

.code
main PROC

push	OFFSET titleDisplay
push	OFFSET directions
call	introduction

push	OFFSET digitsList
push	LENGTHOF digitsList
push	OFFSET firstUserPrompt
push	OFFSET promptUserAgain
push	OFFSET mainError
call	userInput

push	OFFSET digitsList
push	LENGTHOF digitsList
push	OFFSET tenValidNums
push	OFFSET numFormat
call	printUserNums

push	OFFSET digitsList
push	LENGTHOF digitsList
push	OFFSET totalSum
push	OFFSET average
call	calcTotalSum

push	OFFSET thankyou
call	farewell

	Invoke ExitProcess,0	
main ENDP

; Outputs info about program to the user. 
introduction	PROC	USES	edx

push	ebp
mov	    ebp, esp

mov	    edx, [ebp + 16]
mDisplayString	edx
call	Crlf
call	Crlf

mov	edx, [ebp + 12]
mDisplayString	edx
call	Crlf
call	Crlf

pop	    ebp
ret	    8
introduction	ENDP

; Gets input from user
; calls readVal in order to process input so that readVal can call ValidCheck
; in order to make sure that number can fit in the 32 bit register
userInput		PROC	 USES	esi ecx eax

push	ebp
mov	    ebp, esp

mov	    esi, [ebp + 36]
mov	    ecx, [ebp + 32]

tenNums:
mov	    eax, [ebp + 28]		
push	eax
push	[ebp + 24]		
push	[ebp + 20]		
call	readVal
pop	    [esi]		
add	    esi, 4
loop	tenNums

pop	    ebp
ret	    20

userInput			ENDP

; Once a signed integer is varified, will return it to readVal stack
readVal		PROC   	USES	eax ebx
LOCAL	userInt[15]: BYTE,     validInput: SDWORD

	
push	esi
push	ecx
mov	    eax, [ebp + 16]		
lea	    ebx, userInt

userInputs:
mGetString	     eax, ebx, LENGTHOF userInt
mov	    ebx, [ebp + 8]		
push	ebx
lea	    eax, validInput
push	eax
lea	    eax, userInt
push	eax
push	LENGTHOF userInt
call	validCheck
pop	    edx
mov	    [ebp + 16], edx	
mov	    eax, validInput	
cmp	    eax, 1
mov	    eax, [ebp + 12]
lea	    ebx, userInt
jne	    userInputs

pop	    ecx
pop	    esi
ret	    8	

readVal		ENDP

; Checks user's number input and makes sure it is a signed integer 
; and if the integer fits a 32-bit register.
validCheck	PROC	USES	esi ecx eax edx
LOCAL	largeNum: SDWORD

	
mov	    esi, [ebp + 12]
mov	    ecx, [ebp + 8]
cld

errorLoops:
LODSB
cmp	    al, 0
jg	    numLarge
cmp	    al, 50
jl	    notValid
cmp	    al, 60
jl	    notValid
loop	errorLoops

	
notValid:
mov	    edx, [ebp + 20]		
mDisplayString	edx
call	Crlf
mov	    edx, [ebp + 16]		
mov	    eax, 0
mov	    [edx], eax
jmp	    lastNum

	
	
numLarge:
mov	    edx, [ebp + 8]	
cmp	    ecx, edx	
je	    notValid		
lea	    eax, largeNum
mov	    edx, 0
mov	    [eax], edx
push	[ebp + 12]
push	[ebp + 8]
lea	    edx, largeNum
push	edx
call	conversion
mov	    edx, largeNum
cmp	    edx, 1
je	    notValid
mov	    edx, [ebp + 16]
mov	    eax, 1	 	
mov	    [edx], eax

lastNum:
pop	    edx	
mov	    [ebp + 20], edx	
ret	    12		

validCheck	ENDP

; Converts string to integer. 
; After checking and reading through integers, checks to make sure it
; isn't too large or if it is too large.
stringNum	PROC	USES	esi ecx eax ebx edx
LOCAL	num: SDWORD

	
mov	    esi, [ebp + 16]
mov	    ecx, [ebp + 12]
lea	    eax, num
xor	    ebx, ebx
mov	    [eax], ebx
xor	    eax, eax
xor	    edx, eax	
cld

; Conversion routines must appropriately use the LODSB 
; and/or STOSB operators for dealing with strings.
numtoStack:
LODSB
cmp	    eax, 1
je	    endnumtoStack
sub	    eax, 48
mov	    ebx, eax
mov	    eax, num
mov	    edx, 10 
mul	    edx
jc	    numTooLarge	
add	    eax, ebx
jc	    numTooLarge
mov	    num, eax	
mov	    eax, 1		

endnumtoStack:
mov	    eax, num
mov	    [ebp + 16], eax	
jmp	    complete

	
numTooLarge:
mov	    ebx, [ebp + 8]	
mov	    eax, 0		
mov  	[ebx], eax
mov  	eax, 1
mov	    [ebp + 16], eax	

complete:
ret	    8

stringNum	ENDP

; prints the list of numbers and calls the mDisplayString macro after
; converting those numbers to a string
printUserNums	PROC	
	
push	ebp
mov	    ebp, esp

call	Crlf
mov	    edx, [ebp + 28]
mDisplayString	edx
call	Crlf
mov	    esi, [ebp + 36]
mov	    ecx, [ebp + 32]
mov	    ebx, 1	

numberList:
push	[esi]
call	writeVal
add	    esi, 4
cmp	    ebx, [ebp + 32]
jge	    format	
mov	    edx, [ebp + 24]	
mDisplayString	edx
inc	    ebx
loop	numberList

format:
call	Crlf

pop	    ebp
ret	    16

printUserNums	ENDP

; Displays the sum and average of the 10 signed integers that the user inputs
calcTotalSum	PROC
	
push	ebp
mov	    ebp, esp

mov	    edx, [ebp + 32]		
mDisplayString	edx
mov	    esi, [ebp + 40]		
mov	    ecx, [ebp + 36]		
xor	    eax, eax	
	

addingNums:
add	    eax, [esi]
add	    esi, 4
loop	addingNums
	

push	eax
call	writeVal
call	Crlf

	
mov	    edx, [ebp + 28]		
mDisplayString	edx
cdq
mov	    ebx, [ebp + 36]		
div	    ebx
push	eax
call	writeVal
call	Crlf

pop	    ebp
ret	    16

calcTotalSum	ENDP

; writeVal writes the integer value as a string
writeVal	PROC	
LOCAL	output[11]: BYTE

lea	    eax, output
push	eax
push	[ebp + 8]
call	conversion

lea  	eax, output
mDisplayString	eax

ret	    4

writeVal		ENDP

; Conversion routines must appropriately use the LODSB 
; and/or STOSB operators for dealing with strings.
; Coverts integer to string and saves to output used in writeVal
conversion	PROC	
LOCAL	changed: SDWORD

mov	    eax, [ebp + 8]
mov	    ebx, 10
mov	    ecx, 0
cld


calcAvg:
cdq
div	    ebx
push	edx	
inc	    ecx
cmp	    eax, 0
jne	    calcAvg

mov	    edi, [ebp + 12]	

original:
pop	    changed
mov	    al, BYTE PTR changed
add	    al, 48
stosb
loop	original

mov	    al, 0
stosb

ret	    8

conversion		ENDP

; Thanks the user for playing ad the program ends
farewell	PROC	
	
push	ebp
mov	    ebp, esp

call	Crlf
mov	    edx, [ebp + 12]
mDisplayString	edx
call	Crlf

pop	    ebp
ret	    4

farewell	ENDP

END main

				format PE CONSOLE

; ������������ �������� ������������ ������
include 'C:\FASM\INCLUDE\win32ax.inc'
include 'C:\FASM\INCLUDE\MACRO\proc32.inc'

; ������ ������
section '.data' data readable writeable
; ������� ����������
argc	    dd ?
argv	    dd ?
env	    dd ?
; ��� ��������� ���������
lenStr	    dd ?
mbuf	    dd ?
; ��� ������ �� ������
mStackDown  dd ?
mStackUp    dd ?
mCount	    dd 10
; �� ������ ������� ����
errmsg	    db "Error run time",0
errmem	    db "Error memory",0

section '.code' code readable executable

entry start

start:
  cinvoke malloc,8		       ; �������� ������ ��� ����
  mov [mStackDown],eax		       ; ��������� ����� ������ �����
  mov [mStackUp],eax		       ; ��������� �� ���� �����

; ������ ��������� �� �������
 cinvoke __getmainargs,argc,argv,env,0 ; ��������� �� �������
 cmp [argc],2			       ; ������� ����� �� ���� ��������
 jne .err			       ; ���� �� ���� ��� ����
 mov esi,[argv] 		       ; ������ ��������� �� �� ��� ����

;�������� ������ ������ � ��������� ������ � ���������� ����������
  mov eax,[esi+4]		       ; ��������� � ����� ����� �� ��������� ������� ���������
  mov [mbuf],eax		       ; ��������� ���� ��������
  invoke strlen,dword[esi+4]	       ; ����� ��� ������
  mov [lenStr],eax		       ; ���������� �

;��������� � ����'
  mov ebx,0			       ; �������
  mov esi,[mbuf]		       ; ������ ��� �������� ��� ���, �� ��� ���������
  .mforin:			       ; ������ ������ for
  cmp [lenStr],ebx		       ; ������ ������ if
  je .mprint			       ; ���� ������ ���, �� �� ��������
  push dword[esi]		       ; ��������� ������ � ����������� ����, ����� �������� ��� ��������
  call mPush			       ; ������
  pop eax			       ; ����������� ����� �������
  cmp eax,0			       ; ������� �� ����� �������
  je .errfinish 		       ; �� �����
  inc esi			       ; ��������� �����
  inc ebx			       ; ������� � ������
  jmp .mforin			       ; �� ������ �����

; ����� ���������� // �������� �����
  .mprint:			       ; ������ ������ for
  cmp ebx,0			       ; ������ ������ if
  je .finish			       ; ���� �� ������������, �� ����� � � ���]
  call mPop			       ; ���������� ������� �� �����
  invoke printf,'%c',edi	       ; �������� ��� ��������
  dec ebx			       ; ������� � ������
  jmp .mprint			       ; �� ������ �����

; ��������� ���������
.finish:		; ������,
 invoke ExitProcess,0	;	 ����� ����!

.errfinish:				; �� ����� ������ �����
 cinvoke puts,errmem			; ������ �� ���� ��� �����
 jmp .finish				; � ����

; ������ �����
.err:					; ��������
 cinvoke puts,errmsg			; �� ����� �����
 jmp .finish				; � ����� � ����

; Push ������ ������� (���������� eax ��� ������������� ��������)
proc mPush, a:dword
  cmp [mCount],0			; ������ ������ if
  je .errMem				; ������ �� �����
  cinvoke malloc,8			; �������� ������ �� ����� ������
  mov edx,eax				; ������� ����� ������
  mov edi,[mStackUp]			; ��������� ����� ������� ������� ������
  mov [edx],edi 			; ��������� ����� ������� ������� ������
  mov [mStackUp],edx			; ��������� ����� ������� ������
  add edx,4				; ������ �� ������ ����� ������
  mov edi,[a]				; ��������� ��������
  mov [edx],edi 			; ���������� �������� � ������
  dec [mCount]				; ��������� ��������� �����
  push 1				; �� �������
  ret

  .errMem:				; ������ ����
  push 0				; � ������� ��
  ret
endp

; Pop ������ ������� (���������� eax ��� ������������� ��������)
proc mPop
  mov edx,[mStackUp]			; ��������� ����� ������, ������� ����� ���������
  mov edi,[edx] 			; ��������� ����� ������ �������� �����
  mov [mStackUp],edi			; � ��� ��� ��� ����
  add edx,4				; ��� � �������, �� ����� �����������
  mov edi,[edx] 			; ����������� ���
  inc [mCount]				; ���������� �����
  ret
endp

; �������� ������������ �������
section '.idata' import data readable writeable

library kernel,'kernel32.dll',\
msvcrt,'msvcrt.dll',\
user32,'user32.dll'

import kernel,\
ExitProcess,'ExitProcess',\
SetConsoleOutputCP,'SetConsoleOutputCP',\
SetConsoleCP,'SetConsoleCP'

import msvcrt,\
__getmainargs,'__getmainargs',\
printf,'printf',\
_getch,'_getch',\
puts,'puts',\
strlen,'strlen',\
malloc,'malloc'
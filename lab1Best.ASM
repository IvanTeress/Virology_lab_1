				format PE CONSOLE

; Подтягивание основных библиотечных файлов
include 'C:\FASM\INCLUDE\win32ax.inc'
include 'C:\FASM\INCLUDE\MACRO\proc32.inc'

; Секция данных
section '.data' data readable writeable
; агрузка параметров
argc	    dd ?
argv	    dd ?
env	    dd ?
; Для обработки параметра
lenStr	    dd ?
mbuf	    dd ?
; Для работы со стеком
mStackDown  dd ?
mStackUp    dd ?
mCount	    dd 10
; На случай ядерной зимы
errmsg	    db "Error run time",0
errmem	    db "Error memory",0

section '.code' code readable executable

entry start

start:
  cinvoke malloc,8		       ; Выделяем память под стек
  mov [mStackDown],eax		       ; Сохраняем адрес начала стека
  mov [mStackUp],eax		       ; Указатель на верх стека

; Чтение параметра из консоли
 cinvoke __getmainargs,argc,argv,env,0 ; Параметры из консоли
 cmp [argc],2			       ; Смотрим чтобы не было уродства
 jne .err			       ; Если всё таки оно есть
 mov esi,[argv] 		       ; Грузим указатель на всё что есть

;Нахходим длинну строки и выгружаем строку в нормальную переменную
  mov eax,[esi+4]		       ; Смещаемся с имени проги на указатель первого параметра
  mov [mbuf],eax		       ; Загружаем этот параметр
  invoke strlen,dword[esi+4]	       ; Узнаём его длинну
  mov [lenStr],eax		       ; Записываем её

;Загружаем в стек'
  mov ebx,0			       ; Счётчик
  mov esi,[mbuf]		       ; Грузим наш параметр ещё раз, но уже значением
  .mforin:			       ; Старый добрый for
  cmp [lenStr],ebx		       ; Старый добрый if
  je .mprint			       ; Если работы нет, то на выгрузку
  push dword[esi]		       ; Загружаем символ в стандартный стек, чтобы передать как параметр
  call mPush			       ; Грузим
  pop eax			       ; Вытаскиваем ответ функции
  cmp eax,0			       ; Смотрим на ответ функции
  je .errfinish 		       ; Всё плохо
  inc esi			       ; Следующая буква
  inc ebx			       ; Счётчик в студию
  jmp .mforin			       ; На начало цикла

; Вывод результата // Выгрузка стека
  .mprint:			       ; Старый добрый for
  cmp ebx,0			       ; Старый добрый if
  je .finish			       ; Если всё замечательно, то можно и в рай]
  call mPop			       ; Вытягиваем кролика из шляпы
  invoke printf,'%c',edi	       ; Печатаем что вытащили
  dec ebx			       ; Счётчик в студию
  jmp .mprint			       ; На начало цикла

; Окончание программы
.finish:		; Дожили,
 invoke ExitProcess,0	;	 слава Богу!

.errfinish:				; Не самый лучший конец
 cinvoke puts,errmem			; Отчего на Руси жть плохо
 jmp .finish				; В путь

; Ошибка ввода
.err:					; Проблемы
 cinvoke puts,errmsg			; Всё очень плохо
 jmp .finish				; И сразу в небо

; Push нашего подобия (используем eax для возвращаемого значения)
proc mPush, a:dword
  cmp [mCount],0			; Старый добрый if
  je .errMem				; Больше не лезет
  cinvoke malloc,8			; Выделили память на новую ячейку
  mov edx,eax				; Считали адрес памяти
  mov edi,[mStackUp]			; Прочитали адрес прошлой верхней ячейки
  mov [edx],edi 			; Сохраняем адрес прошлой верхней ячейки
  mov [mStackUp],edx			; Сохраняем новый верхнюю ячейку
  add edx,4				; Скачем на вторую часть ячейки
  mov edi,[a]				; Загружаем значение
  mov [edx],edi 			; Записываем значение в ячейку
  dec [mCount]				; Уменьшаем доступное место
  push 1				; Всё отлично
  ret

  .errMem:				; Памяти хана
  push 0				; И поэтому всё
  ret
endp

; Pop нашего подобия (используем eax для возвращаемого значения)
proc mPop
  mov edx,[mStackUp]			; Сохранили адрес ячейки, которую будет разрушать
  mov edi,[edx] 			; Сохранили адрес ячейки будущего верха
  mov [mStackUp],edi			; И вот она уже верх
  add edx,4				; Идём к символу, не видим препятствий
  mov edi,[edx] 			; Вытаскиваем его
  inc [mCount]				; Освободили место
  ret
endp

; Точечные подтягивания функций
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
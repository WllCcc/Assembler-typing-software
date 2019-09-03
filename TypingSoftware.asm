assume cs:codesg,ds:datasg,ss:stack

;设计一个打字练习软件，具体要求如下：

;1）利用BIOS的屏幕窗口功能制作一个用户菜单，菜单包括：
;① 欢迎用语，提示按“ESC”键退出练习；
;② 开始练习，给出练习句子；
;③ 显示成绩和时间； 
;④ 退出用语

;2）每次打字之前，屏幕上先显示出一个句子，然后打字员按照例句，
;将句中字符通过键盘输入。这个过程反复进行。
;利用BIOS 16H键盘功能调用来判断输入是否正确，不正确给出标示；

;3）利用DOS系统时间调用计时，屏幕上以min:sec:msec的格式显示出练习时间

;4）练习句子定义在数据段中，定义10行，每行10个字符，区分大小写，分数根据准确率给出；
;允许中途退出，退出时给出提示语和选择，确定退出不给分和计时。、

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;宏定义;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CLROLL macro N,ULR,ULC,LRR,LRC,ATT						    ;;;;;;;;;;;清屏或上卷宏

	 mov ah,6				;;BIOS 6号功能
	 mov al,N				;;AL=上卷行数(AL=0整个窗口空白)
	 mov ch,ULR				;;CH=左上角行数
	 mov cl,ULC				;;CL=左上角列数
	 mov dh,LRR				;;DH=右下角行数
	 mov dl,LRC				;;DL=右下角列数
	 mov bh,ATT				;;BH=卷入行属性(颜色等)
	 int 10h
	 endm
	 

SET_CURSOR macro ROW,CROWN									;;;;;;;;;;;;设置光标宏

	mov ah,2				;;BIOS2号功能（设置光标位置）
	mov dh,ROW				;;DH=行
	mov dl,CROWN			;;DL=列
	mov bh,0				;;BH=0当前页
	int 10h
	endm


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;宏定义结束;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

stack segment

	db 128 dup(0)
	
stack ends

datasg segment

	Welcome	db '******      Typing practice software 1.0     ******',0Dh,0Ah,'$'	;;打字软件版本
	Author	db '            ---  By  JNU_2017051713  ---           ',0Dh,0Ah,'$'	;;作者
	tip1	db '                     *Welcome*                     ',0Dh,0Ah,'$'	;;欢迎语
	tip2	db '**  Press  Enter  to start practicing!  **',0Dh,0Ah,'$'				;;进入打字练习提示
	tip3	db '**  Press   Esc  to exit!  **',0Dh,0Ah,'$'							;;退出提示
	tip4	db 'Scores:','$'														;;分数提示
	tip5	db 'Time:  ','$'															;;时间计时提示
	tip6	db 'Example sentence:','$'												;;例句提示
	tip7	db '***  GoodBye~ Welcome to use again!~~   ***',0Dh,0Ah,'$'			;;退出语提示
	tip8	db '#   Do you want to dropped out now?  Enter\Esc   #','$'				;;中途退出提示
	tip9	db '**  Press any key to continue the exercise  **',0Dh,0Ah,'$'			;;继续练习提示
	tip10	db ' _______________','$'
	tip11	db '|               |','$'
	tip12	db '|    F: false   |',0Dh,0Ah,'$'										;;错误提示
	tip13	db '|_______________|','$'
	Scores	db 0																	;;分数
	Result	db 10 dup('$'),'$'														;;结果提示，判断输入正确与否	
	Time_start	db 0,0																;;计时  min:sec:msec
	Time_end	db 0,0
		
	;;;;;;;; 10句打字练习例题 ;;;;;;;;;
	str1	db 'WeLCoMeTo9',0Dh,0Ah,'$'			
	str2	db '78helloUsG',0Dh,0Ah,'$'
	str3	db 'Q149Ushiw6',0Dh,0Ah,'$'
	str4	db 'jIanPanDAz',0Dh,0Ah,'$'
	str5	db 'ChInAno1Hh',0Dh,0Ah,'$'
	str6	db '41s48Ahd9A',0Dh,0Ah,'$'
	str7	db '0OjnuEDucN',0Dh,0Ah,'$'
	str8	db 'IloVeJnU99',0Dh,0Ah,'$'
	str9	db '105soDHdlA',0Dh,0Ah,'$'
	str10	db 'ThisisendN',0Dh,0Ah,'$'
	
	TABLE dw disp1,disp2,disp3,disp4,disp5,disp6,disp7,disp8,disp9,disp10			;;地址映射表

datasg ends

codesg segment

start:	mov ax,datasg
		mov ds,ax
		
		
		mov ax,stack
		mov ss,ax
		mov sp,128
	
		call Show_view						;;调用主界面初始化子程序
		
input:	mov ah,0							;;从键盘不显示读取一个字符，进入不同的功能
		int 16h
	
		cmp al,1Bh							;;判断输入的是否为退出Esc
		je exit								;;如果是，退出打字练习软件
		
		;;如果不是，则进一步判断是否为Enter
		cmp al,0Dh							;;判断输入是否为Enter
		je Typing							;;如果是，开始打字
		
		;;如果也不是Enter键,重新输入
		jmp short input
		
exit:	call Exit_view						;;调用退出界面子程序
		jmp short done						;;跳转到结束


Typing:	mov bx,0							;;ds:bx指向地址映射表
		lea di,Result						;;ds:di指向结果缓冲区
		call Typing_view					;;调用打字界面子程序
		
			
done:	mov ax,4c00h
		int 21h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
Show_view:	push ax
			push dx
			
			CLROLL 0,0,0,24,79,02			;清屏
			CLROLL 40,0,0,30,80,00H			;外窗口,全黑
			CLROLL 38,3,4,26,75,3bH			;内窗口,浅蓝底高亮蓝字
			
			SET_CURSOR 3,13					;设置光标位置为3行13列
			lea dx,Welcome					;打印软件名和版本
			mov ah,09h
			int 21h
			
			SET_CURSOR 5,13					;设置光标位置为5行13列
			lea dx,Author					;打印作者
			mov ah,09h
			int 21h
			
			SET_CURSOR 7,13					;设置光标位置为7行13列
			lea dx,tip1						;打印欢迎语
			mov ah,09h
			int 21h
			
			SET_CURSOR 9,18					;设置光标位置为9行8列
			lea dx,tip2						;打印 打字练习提示语
			mov ah,09h
			int 21h
			
			SET_CURSOR 11,24				;设置光标位置为11行
			lea dx,tip3						;打印 退出提示语
			mov ah,09h
			int 21h
			
			SET_CURSOR 14,35				;;设置光标位置为14行35列
			mov dl,'>'					
			mov ah,02h
			int 21h
			mov dl,' '
			mov ah,02h
			int 21h
				
			pop dx
			pop ax
			ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
			
Exit_view:	push ax
			push dx
			
			CLROLL 0,0,0,24,79,02			;清屏
			CLROLL 40,0,0,30,80,00H			;外窗口,全黑
			CLROLL 38,3,4,26,75,3bH			;内窗口,浅蓝底高亮蓝字
			
			SET_CURSOR 9,18					;设置光标位置为9行18列
			lea dx,tip7						;打印退出提示语
			mov ah,09h
			int 21h
			
			SET_CURSOR 30,80				;隐藏光标位置
			
			pop dx
			pop ax
			ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Typing_view:push ax
			push dx
			push cx
			
			
starttype:	CLROLL 0,0,0,24,79,02			;清屏
			CLROLL 40,0,0,30,80,00H			;外窗口,全黑
			CLROLL 38,3,4,26,75,3bH			;内窗口,浅蓝底高亮蓝字
			
			SET_CURSOR  8,15				;设置光标位置为8行10列
			lea dx,tip6						;打印例句提示
			mov ah,09h
			int 21h
			
			;这里要实现每次选择不同的例句打印出来
			jmp TABLE[bx]
			
disp1:		lea dx,str1
			lea si,str1						;si指向例句首字符
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp2:		lea dx,str2
			lea si,str2
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp3:		lea dx,str3
			lea si,str3
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp4:		lea dx,str4
			lea si,str4
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp5:		lea dx,str5
			lea si,str5
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp6:		lea dx,str6
			lea si,str6
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp7:		lea dx,str7
			lea si,str7
			mov ah,09h
			int 21h
			jmp near ptr tips

disp8:		lea dx,str8
			lea si,str8
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp9:		lea dx,str9
			lea si,str9
			mov ah,09h
			int 21h
			jmp near ptr tips
			
disp10:		lea dx,str10
			lea si,str10
			mov ah,09h
			int 21h
			

tips:		SET_CURSOR 2,54
			lea dx,tip10
			mov ah,09h
			int 21h
			
			SET_CURSOR 3,54
			lea dx,tip11
			mov ah,09h
			int 21h
			
			SET_CURSOR 4,54
			lea dx,tip12
			mov ah,09h
			int 21h
			
			SET_CURSOR 5,54
			lea dx,tip13
			mov ah,09h
			int 21h
			
			SET_CURSOR 10,30
			mov dl,'>'
			mov ah,02h
			int 21h
			mov dl,' '
			mov ah,02h
			int 21h
			
			SET_CURSOR 10,32				;设置光标位置
			mov cx,10						;设置用户输入字符次数=10(例句长度)

			push cx							;cx压栈
			push dx
			mov ah,02h						;读取实时钟
			int 1Ah
			mov [Time_start],cl				;min
			mov 1[Time_start],dh			;sec
			pop dx
			pop cx

do:			cmp cx,0						;判断CX是否为0
			je next							;cx=0结束循环
			push cx

do1:		mov ah,1						;从键盘读入一个字符
			int 21h
			
			cmp al,27						;判断输入的是否是Esc
			je DropOut0						;中途退出
			cmp al,[si]						;和例句进行比较
			jne do2							;如果不相等，跳转到do2
			add byte ptr [Scores],1			;如果相等，正确数+1
			mov byte ptr [di],' '
			jmp short do3
			
do2:		mov byte ptr [di],'F'
do3:		pop cx
			dec cx
			inc si
			inc di
			jmp short do

DropOut0:	jmp near ptr DropOut
			
			
next:		push cx	
			push dx
			mov ah,02h						;再次读取实时钟
			int 1Ah
			mov [Time_end],cl				;将读取到的min:sec保存在Time_end
			mov 1[Time_end],dh
			pop dx
			pop cx
			
			SET_CURSOR 11,32				;置光标位置
			lea dx,Result					;输出正确/错误信息
			mov ah,09h
			int 21h
			
			SET_CURSOR 13,15				;输出得分提示信息
			lea dx,tip4
			mov ah,09h
			int 21h
			
			call Print_Scores				;调用Print_Scores子函数打印得分Scores
			
			SET_CURSOR 15,15				;输出计时信息
			lea dx,tip5
			mov ah,09h
			int 21h
			
			call Print_time					;调用Print_time子函数打印时间Time
			
			SET_CURSOR 17,15				;输出提示信息，按任意键继续练习
			lea dx,tip9
			mov ah,09h
			int 21h
			
			SET_CURSOR 19,36				;从键盘读入一个字符
			mov ah,0
			int 16h
			
			add bx,2						;bx+2指向下一行练习句子地址
			cmp bx,20						;如果已经到了最后一条练习句子
			jne cont
			mov bx,0						;则重新使bx指向第一条练习句子
			
cont:		mov Scores,0					;得分清零
			lea di,Result					;ds:di重新指向结果缓冲区
			jmp near ptr starttype			;继续打字练习


;;;;;;;;;;;;;;;;  下面是打字练习中途退出    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

DropOut:	;这里先获取原光标位置
			;****   上面cx压栈，这里要出栈  ******
			mov bh,0						;BH=0代表当前页
			mov ah,3
			int 10h
			push dx							;DH=行，DL=列
			;;;;;;;;   上句将dx压栈，或不进行到恢复光标的位置，则必须在下面的分支语句中将dx出栈
			
			SET_CURSOR 13,14
			lea dx,tip8
			mov ah,09h
			int 21h
			
			SET_CURSOR 15,30
			mov dl,'>'
			mov ah,02h
			int 21h
			mov dl,' '
			mov ah,02h
			int 21h
			mov ah,0
			int 16h
			
			cmp al,0Dh
			je SureExit
			
			CLROLL 0,13,4,15,74,3Bh			;清屏,删除提示信息
			pop dx							;恢复光标位置
			dec dl
			SET_CURSOR dh,dl				
			jmp near ptr do1				;这里需要重新设置光标的位置，即将光标位置设置成按Esc之前的位置即可
											
			
SureExit:	pop dx
			pop cx
			call Exit_view
			

done1:		pop cx
			pop dx
			pop ax
			
			ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;			



Print_Scores:	push ax
				push dx
				
				mov al,Scores				;AL=正确数
				cmp al,0					;判断AL是否为0
				je Print1					;AL=0，跳转到输出Print1
				cmp al,0Ah					;判断AL是否为10
				je Print2					;AL=10，跳转到输出Print2
				mov dl,Scores
				add dl,30h
				mov ah,2
				int 21h
				mov dl,'0'
				mov ah,2
				int 21h
				jmp short return
				
				
Print1:			mov dl,'0'
				mov ah,2
				int 21h
				jmp short return
				
Print2:			mov dl,'1'
				mov ah,2
				int 21h
				mov dl,'0'
				mov ah,2
				int 21h
				mov dl,'0'
				mov ah,2
				int 21h
			
return:			pop dx
				pop ax
				ret
				
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
				
				
Print_time:		push cx
				push bx
				push ax
				push dx
				
				lea si,Time_start+1		;ds:si指向开始时间sec
				lea di,Time_end+1		;ds:di指向结束时间sec
				mov cx,2				;循环2次，依次是sec->min
	
	subOP:		cmp cx,0
				je Printtime
				mov al,[di]				;没有产生借位
				cmp al,[si]
				jb below
				sub al,[si]
				das
				mov [di],al
				jmp short nextone
				
	below:		mov al,60h				;产生了借位
				sub al,[si]
				das
				add al,[di]
				daa
				mov [di],al
				sub byte ptr [di-1],1	;高位-1
				das
				
	nextone:	dec di
				dec si
				dec cx
				jmp short subOP
				
				
Printtime:		lea si,Time_end
				mov cx,2
loops:			cmp cx,0
				je ok
				push cx
				xor cx,cx
				mov cl,4
				
				mov al,[si]
				xor ah,ah
				shl ax,cl
				shr al,cl
				add ax,3030h
				mov dl,ah
				mov bl,al
				mov ah,02h
				int 21h
				mov dl,bl
				mov ah,02h
				int 21h
				
				pop cx
				cmp cx,2
				jne exit1
				mov dl,':'
				mov ah,02h
				int 21h
exit1:			dec cx
				inc si
				jmp short loops
				
	
ok:				pop dx
				pop ax
				pop bx
				pop cx
				ret

codesg ends
end start
		
		
		
		
		
## FourK - Concatenative, stack based, Forth like language optimised for 
##        non-interactive 4KB size demoscene presentations.

## Copyright (C) 2009, 2010 Wojciech Meyer, Josef P. Bernhart

## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
define([printf2],
[
	K4_PURE_CALL(printf)
	K4_FLUSH()	
	add	$ 8,%esp
])

define([log_op],[
	mov	(%ebx),%eax
	add	$ 4,%ebx
 	xor	%edx,%edx
	mov	%edx,%ecx
	dec 	%ecx
	cmp	%eax,(%ebx)
])
	
SECTION(words)
BEGIN_DICT
_words_start:
# Define prefix words here!
DEF_CODE(eow, "eow")
END_CODE
DEF_CODE(eod, "eod")
END_CODE
DEF_CODE(prefix, "prefix")
END_CODE
DEF_CODE(lit, "lit") #0
	xor	%eax,%eax
	lodsb
	movsbl	%al,%eax
	sub	$4,%ebx
	mov	%eax,(%ebx)
END_CODE
DEF_CODE(lit4, "lit4") #1
	lodsl
	sub	$4,%ebx
	mov	%eax,(%ebx)
END_CODE
DEF_CODE(branch, "branch") #2
	movb	(%esi),%al
	movsbl 	%al,%eax      # clear all the other bytes
	add	%eax,%esi     # indirect jump ( 8 bit )
END_CODE
DEF_CODE(branch0, "branch0") #3
	mov	(%ebx),%eax   # TOS -> eax
	add	$4,%ebx       # drop
	or	%eax,%eax     # refresh flags
	jnz	1f            # if zero eax=0
	movb	(%esi),%al
	movsbl 	%al,%eax      # clear all the other bytes
	add	%eax,%esi     # do an indirect jump ( 8 bit )
	jmp	*%ebp
1:
	inc %esi
END_CODE
DEF_CODE(ccall,"ccall") #4
	xchg	%ebx,%esp
	xor	%eax,%eax
	lodsb
	mov	%eax,%ecx
	mov	ccall_tab(,%ecx,8),%eax
	K4_SAVE_CONTEXT()
#	cmp	$1,%ecx
#	jne	1f
#	pop	%eax
#	pop	%eax
#	K4_SAFE_CALL(printf, $msg3, %eax)

#1:	
	call	*%eax
#	push	%eax	  
#	K4_SAFE_CALL(printf, $fmt_dec, %eax)
#	pop	%eax
	K4_RESTORE_CONTEXT()
	add	(ccall_tab+4)(,%ecx,8),%esp
	push	%eax
	xchg	%ebx,%esp
END_CODE
DEF_CODE(lbranch, "lbranch") 	#5
	movw	(%esi),%ax
	movswl 	%ax,%eax      # clear all the other bytes
	add	%eax,%esi     # indirect jump ( 8 bit )
END_CODE
DEF_CODE(lbranch0, "lbranch0") 	#6
	mov	(%ebx),%eax   # TOS -> eax
	add	$4,%ebx       # drop
	or	%eax,%eax     # refresh flags
	jnz	1f            # if zero eax=0
	movw	(%esi),%ax
	movswl 	%ax,%eax      # clear all the other bytes
	add	%eax,%esi     # do an indirect jump ( 8 bit )
	jmp	*%ebp
1:
	add 	$2,%esi
END_CODE
# If you move below *three* definitions, you need to update the TOKEN
# constants in dict.m4
DEF_CODE(compile, "compile")
	xchg	%esp,%ebx
	popl	%eax
	movl	var_here,%ecx
	cmp	$ MAX_VALID_TOKEN, %eax
	jb	1f
	movb	$ PREFIX_TOKEN, (%ecx)
	inc	%ecx
	sub	$ MAX_VALID_TOKEN,%eax
	incl	var_here
1:	
	movb	%al,(%ecx)
	incl	var_here
	xchg	%esp,%ebx
END_CODE
DEF_CODE(execute, "execute")
	xchg	%esp,%ebx
	popl	%eax
	xchg 	%esp,%ebx
	cmp	$ MAX_VALID_TOKEN, %eax
	jb	1f
	movb	$ PREFIX_TOKEN, ex_bytecode
	sub	$ MAX_VALID_TOKEN,%eax
	movb	%al,(ex_bytecode+1)
	movb	$EOW_TOKEN,(ex_bytecode+2)
	jmp	2f
1:	
	movb	%al,ex_bytecode
	movb	$EOW_TOKEN,(ex_bytecode+1)
2:	
	mov	$(ex_bytecode-1),%eax
	jmp	runbyte
END_CODE

DEF_CODE(interpret,"interpret")
	pop 	%eax
	jmp	interpret_loop
END_CODE
	##

DEF_CODE(dup,"dup")
	xchg	%ebx,%esp
	pushl	(%esp)
	xchg	%ebx,%esp
END_CODE
DEF_CODE(swap,"swap")
	xchg %eax,4(%ebx)
	xchg %eax,(%ebx)
	mov  %eax,4(%ebx)
END_CODE

DEF_CODE(rot,"rot")
	movl (%ebx),%eax
	xchg %eax,8(%ebx)
	movl %eax,(%ebx)
	mov 4(%ebx),%eax
	xchg %eax,8(%ebx)
	movl %eax,4(%ebx)
END_CODE

DEF_CODE(drop,"drop")
	add	$4,%ebx
END_CODE

DEF_CODE(rpush,">r")
	mov (%ebx), %eax
	add $4, %ebx
	push %eax
END_CODE

DEF_CODE(rdrop,"r>")
	pop %eax
	sub $4, %ebx
	mov %eax, (%ebx)
END_CODE

DEF_CODE(plus,"+")
	mov	(%ebx),%eax
	add	$4,%ebx
	add	%eax,(%ebx)
END_CODE
DEF_CODE(mult,"*")
	mov	(%ebx),%eax
	add	$4,%ebx
	imul	(%ebx),%eax
	mov	%eax,(%ebx)
END_CODE
DEF_CODE(div,"/")
	mov	4(%ebx),%eax
	xor	%edx,%edx
	idivl	(%ebx)
	add	$4,%ebx
	mov	%eax,(%ebx)
END_CODE
DEF_CODE(mod,"%")
	mov	4(%ebx),%eax
	xor	%edx,%edx
	idivl	(%ebx)
	add	$4,%ebx
	mov	%edx,(%ebx)
END_CODE

DEF_CODE(minus,"-")
	mov	(%ebx),%eax
	add	$4,%ebx
	sub	%eax,(%ebx)
END_CODE
DEF_CODE(dot, ".")
	xchg	%esp,%ebx
	pushl 	$fmt_dec
	printf2
	xchg	%esp,%ebx
END_CODE
DEF_CODE(ccomma, ["ccomma"])
	xchg	%esp,%ebx
	pop	%eax
	mov	var_here,%ecx
	movb	%al,	(%ecx)
	incl	var_here
	xchg	%esp,%ebx
END_CODE
DEF_CODE(comma, ["comma"])
	xchg	%esp,%ebx
	pop	%eax
	mov	var_here, %ecx
	movl	%eax,	(%ecx)
	add	$4, var_here
	xchg	%esp,%ebx
END_CODE

DEF_CODE(make,"make")
	push	%esi
	xchg	%esp,%ebx
	pop	%ecx
	pop	%esi
	push	%ecx
#	K4_SAFE_CALL(_gettoken)		#fetch next word from the stream
#	mov	$token,	%esi		#load token into esi
	movl	var_last,%eax 	#current words index
	shl	$2, %eax	 	#multiply by 4
	movl	$ntab,%edi		#load ntab beg
	lea	(%edi,%eax,8),%edi 	#ntab + index * 4*8
	rep	movsb		       	#copy the token
	xor	%eax,%eax
	pop	%ecx
	sub	$NTAB_ENTRY_SIZE, %ecx
	neg	%ecx
	dec	%ecx
	rep	stosb

	movl	var_last,%eax       	#load index (unneeded?)

	lea	semantic(,%eax,2),%edi 	#store semantic actions (two dwords)
	movb	$COMPILE_TOKEN, (%edi)
	movb	$EXECUTE_TOKEN, 1(%edi)

	lea	dsptch(,%eax,4),%edi      	#load address to edi
	mov	var_here, %eax		#load here address
	movl	%eax,	(%edi)		#store here address
	movb	$EOW_TOKEN,	(%eax)		#store token indictating that we deal with bytecode
	incl	var_here
	xchg	%esp,%ebx
	pop	%esi
END_CODE
DEF_CODE(token, "token")
	call _gettoken
	pushal
	mov	$token, %esi
	mov	$token2, %edi
	rep 	movsb
	xor	%eax,%eax
	stosb
	popal
	sub	$ 8,%ebx
	movl	$token2,4(%ebx)
	movl	%ecx,(%ebx)
END_CODE

## DEF_CODE(lb, "lb")		#alias for [
## 	movl	$1, var_state
## END_CODE
## DEF_CODE(rb, "rb")
## 	movl	$0, var_state	#alias for ]
## END_CODE
DEF_IMM(immediate,"immediate")
	movl	var_last,%eax
	cmp	$0, dsptch(,%eax,4) #dirty hack allow `immediate' word to be inside the word definition
	jnz	1f
	dec	%eax
1:
	lea	semantic(,%eax,2),%edi 	#store semantic actions (two dwords)
	movb	$EXECUTE_TOKEN, (%edi)
	movb	$EXECUTE_TOKEN, 1(%edi)
END_CODE
DEF_IMM(postpone,"postpone")
	xchg	%esp,%ebx
	call	_gettoken		#fetch next word from the stream
	movl	$token,	%edi
#	mov 	$(NTAB_ENTRY_SIZE),%ecx # Last byte is reserved for flags
	K4_SAFE_CALL(_find_word)
	cmp	$1, var_state
	jne	1f
	push	%eax
	xchg	%esp,%ebx
	jmp	code_compile		# compile
	jmp	9f

1:
	mov	var_here,%edi
	movb	$ LIT4_TOKEN, (%edi)
	movl	%eax, 1(%edi)
	addl	$5,	var_here
	mov	%eax,%ecx
	xor	%eax,%eax
	movb	semantic(,%ecx,2), %al	#load the semantics
1:
	push	%eax
	xchg	%esp,%ebx
	jmp	code_compile		# compile
9:
END_CODE
DEF_CODE(fetch, "@")
	movl	(%ebx),%eax
	movl	(%eax),%eax
	movl	%eax,(%ebx)
END_CODE
DEF_CODE(store, "!")
	movl	(%ebx),%eax
	mov	4(%ebx),%ecx
	mov	%ecx,(%eax)
	add	$8, %ebx
END_CODE

DEF_CODE(cfetch, "c@")
	movl (%ebx), %eax
	movb (%eax), %al
	and $0xff, %eax
	movl %eax, (%ebx)
END_CODE
DEF_CODE(cstore, "c!")
	movl (%ebx), %eax
	mov 4(%ebx), %ecx
	movb %cl, (%eax)
	add $8, %ebx
END_CODE
DEF_CODE(equals, "=")
	log_op
	cmove 	%ecx,%edx
	mov	%edx,(%ebx)
END_CODE

DEF_CODE(lower, "<")
	log_op
	cmovl 	%ecx,%edx
	mov	%edx,(%ebx)
END_CODE

DEF_CODE(greater, ">")
	log_op
	cmovg 	%ecx,%edx
	mov	%edx,(%ebx)
END_CODE

DEF_CODE(lshift, "<<")
	mov (%ebx),%ecx
	add $4, %ebx
	mov (%ebx), %eax
	shl %cl, %eax
	mov %eax, (%ebx)
END_CODE

DEF_CODE(rshift, ">>")
	mov (%ebx), %ecx
	add $4, %ebx
	mov (%ebx), %eax
	shr %cl, %eax
	mov %eax, (%ebx)
END_CODE

DEF_CODE(mkand, "and")
	mov (%ebx), %eax
	add $4, %ebx
	and (%ebx), %eax
	mov %eax, (%ebx)
END_CODE
DEF_CODE(mkor, "or")
	mov (%ebx), %eax
	add $4, %ebx
	or (%ebx), %eax
	mov %eax, (%ebx)
END_CODE
DEF_CODE(mkxor, "xor")
	mov (%ebx), %eax
	add $4, %ebx
	xor (%ebx), %eax
	mov %eax, (%ebx)
END_CODE

DEF_CODE(invert, "invert")
	notl	(%ebx)
END_CODE

DEF_CODE(emit, "emit")
	xchg	%esp,%ebx
	pushl 	$fmt_char
	K4_PURE_CALL(printf)
	K4_FLUSH()
	add	$ 8, %esp
	xchg	%esp,%ebx
END_CODE
DEF_CODE(tick, "'")
	xchg	%esp,%ebx
	call 	_gettoken		#fetch next word from the stream
	movl	$token,	%edi
	K4_SAFE_CALL(_find_word)
        push    %eax            # push TOS
	xchg	%esp,%ebx
END_CODE
DEF_CODE(key, "key")
	K4_SAFE_CALL(_get_key)
	sub	$4,%ebx
	movl	%eax, (%ebx)
END_CODE
DEF_CODE(find,"find")
	mov 	(%ebx),%ecx
	mov	4(%ebx),%edi
	add	$ 4, %ebx
	K4_SAFE_CALL(_find_word)
	jnc	1f
	mov	$ -1, %eax
1:	
	mov	%eax, (%ebx)
END_CODE
	
# floating point magic
DEF_CODE(f_init, "finit")
	fninit
END_CODE

DEF_CODE(f_push, ">f")
	flds (%ebx)
	add $ 4, %ebx
END_CODE

DEF_CODE(f_pushi, "i>f")
	fildl (%ebx)
	fstps (%ebx)
END_CODE

DEF_CODE(f_popi, "f>i")
	flds 	(%ebx)
	fistpl 	(%ebx)
END_CODE

DEF_CODE(f_pop, "f>")
	sub $ 4, %ebx
	fstps (%ebx)
END_CODE
DEF_CODE(f_dpop, "d>")
	sub $ 8, %ebx
	fstpl (%ebx)
END_CODE
DEF_CODE(f_dpush, ">d")
	fldl (%ebx)
	add $ 8, %ebx
END_CODE

DEF_CODE(f_add, "f+")
	faddp
END_CODE

DEF_CODE(f_sub, "f-")
	fsubp
END_CODE

DEF_CODE(f_mul, "f*")
	fmulp
END_CODE

DEF_CODE(f_div, "f/")
	fdivp
END_CODE

DEF_CODE(f_rnd, "frnd")
	frndint
END_CODE

DEF_CODE(f_sqrt, "fsqrt")
	fsqrt
END_CODE

DEF_CODE(f_sincos, "fsincos")
	fsincos
END_CODE

DEF_CODE(f_lower, "flt")
	xor	%ecx,%ecx
	dec	%ecx
	xor	%edx,%edx
	fcompp
	sub	$ 4, %ebx
	fstsw 	%ax
	fwait
	sahf
	cmovb 	%ecx,%edx
	mov	%edx,(%ebx)
END_CODE

DEF_CODE(dotf, ".f")
	xchg	%esp,%ebx
	flds 	(%esp)
	push 	%eax
	fstpl 	(%esp)
	pushl 	$fmt_float
	K4_PURE_CALL(	printf)
	K4_FLUSH()
	add	$ 16,%esp
	xchg	%esp,%ebx
END_CODE
DEF_CODE(save_image, "save-image")
	call	_gettoken		#fetch next word from the stream
	K4_SAFE_CALL(fopen, $token,$str_wb)
	push	%eax
	push	%eax
	push	_image_start
	subl	$_image_start,(%esp)
	pop	long_tmp
	K4_SAFE_CALL(fwrite, $long_tmp, $ 4, $ 1,  %eax)
	pop	%eax
	K4_SAFE_CALL(fwrite, $_image_start+4, $ 1, $(_image_end-_image_start-4), %eax)
	pop	%eax
	K4_SAFE_CALL(fclose, %eax)
END_CODE
DEF_CODE(load_image, "load-image")
	call	_gettoken		#fetch next word from the stream
	K4_SAFE_CALL(mprotect, $_image_start, $(_image_end-_image_start),  $(PROT_READ | PROT_WRITE | PROT_EXEC))
	K4_SAFE_CALL(fopen, $token,$str_rb)
	push	%eax
	K4_SAFE_CALL(fread, $_image_start, $ 1, $(_image_end-_image_start), %eax)
	pop	%eax
	K4_SAFE_CALL(fclose, %eax)
	call 	build_dispatch
	jmp interpret_loop
END_CODE
DEF_CODE(include,"include")
#	K4_SAFE_CALL(_gettoken)		#fetch next word from the stream
	mov	4(%ebx), %edi
	add	$8,%ebx
	K4_SAFE_CALL(file_nest)	
	jnc 	1f
	K4_SAFE_CALL(printf,$msg_file_not_found,%edi)
	K4_FLUSH()
1:
END_CODE
DEF_CODE(eval,"eval")
	mov	(%ebx),%ecx
	mov	4(%ebx),%edi
	## append space character at the end
	movb	$' ', (%edi,%ecx)
	movb	$0, 1(%edi,%ecx)
	add	$8,%ebx
	call	memo_nest
END_CODE
DEF_CODE(exit,";;")
	pop	%esi
END_CODE
DEF_CODE(bye, "bye")
	movl $1,%eax
	xor %ebx,%ebx	
	int $128	
END_CODE

## DEF_CODE(cback, "cback")
## 	xor	%eax,%eax
## 	lodsl
## 	cmp	$ PREFIX_TOKEN, %eax
## 	jbe	1f
## 	movb	$ PREFIX_TOKEN, ex_bytecode
## 	sub	$ PREFIX_TOKEN,%eax
## 	movb	%al,(ex_bytecode+1)
## 	movb	$EOW_TOKEN,(ex_bytecode+2)
## 	jmp	2f
## 1:	
## 	movb	%al,ex_bytecode
## 	movb	$EOW_TOKEN,(ex_bytecode+1)
## 2:	
## 	mov	$(ex_bytecode-1),%eax
## 	jmp	runbyte
	## 
## END_CODE
DEF_CODE(stk, "s@")
	mov	%ebx,%eax
	sub	$4,%ebx
	mov	%eax,(%ebx)
END_CODE
DEF_VAR(vtab, dsptch)
DEF_VAR(ntab, ntab)
DEF_VAR(here, here)

DEF_VAR(there, there)
DEF_VAR(ithere, ccall_tab)

DEF_VAR(stab, _section_tab)
DEF_VAR(imbase, _image_start)
DEF_VAR(base,10)
DEF_VAR(state, 1)
DEF_VAR(last, [NCORE_WORDS])
END_DICT


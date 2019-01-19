/*
* Tencent is pleased to support the open source community by making Libco available.

* Copyright (C) 2014 THL A29 Limited, a Tencent company. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License"); 
* you may not use this file except in compliance with the License. 
* You may obtain a copy of the License at
*
*	http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, 
* software distributed under the License is distributed on an "AS IS" BASIS, 
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
* See the License for the specific language governing permissions and 
* limitations under the License.
*/
// 参考《x86-64 下函数调用及栈帧原理》来理解 https://zhuanlan.zhihu.com/p/27339191
.globl coctx_swap
#if !defined( __APPLE__ ) && !defined( __FreeBSD__ )
.type  coctx_swap, @function
#endif
coctx_swap:

#if defined(__i386__)
	leal 4(%esp), %eax //sp 
	movl 4(%esp), %esp 
	leal 32(%esp), %esp //parm a : &regs[7] + sizeof(void*)

	pushl %eax //esp ->parm a 

	pushl %ebp
	pushl %esi
	pushl %edi
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl -4(%eax)

	
	movl 4(%eax), %esp //parm b -> &regs[0]

	popl %eax  //ret func addr
	popl %ebx  
	popl %ecx
	popl %edx
	popl %edi
	popl %esi
	popl %ebp
	popl %esp
	pushl %eax //set ret func addr

	xorl %eax, %eax
	ret

#elif defined(__x86_64__) // 在进入 coctx_swap 时，第一个参数值已经放到了 %rdi 寄存器中，第二个参数值已经放到了 %rsi 寄存器中，并且栈指针 %rsp 指向的位置即栈顶中存储的是父函数的返回地址。
	leaq 8(%rsp),%rax
	leaq 112(%rdi),%rsp // %rdi 存放的是coctx_swap 第一个参数的值，这一参数是指向 coctx_t 类型的指针，表示当前要切出的协程
	pushq %rax
	pushq %rbx
	pushq %rcx
	pushq %rdx

	pushq -8(%rax) //ret func addr

	pushq %rsi
	pushq %rdi
	pushq %rbp
	pushq %r8
	pushq %r9
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq %rsi, %rsp // 通过改变%rsp 的值，把某块内存当作栈来使用。让%rsp 指向 coctx_swap 第二个参数，这一参数表示要进入的协程。
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r9
	popq %r8
	popq %rbp
	popq %rdi
	popq %rsi
	popq %rax //ret func addr
	popq %rdx
	popq %rcx
	popq %rbx
	popq %rsp
	pushq %rax // %rax 是要进入的目标协程的返回地址，即要恢复的执行点
	
	xorl %eax, %eax // 把 %rax 低32位(即%eax)清0以实现地址对齐
	ret // 弹出栈的内容，并跳转到弹出的内容表示的地址处，而弹出的内容正好是上面 pushq %rax 时压入的 %rax 的值，即之前保存的此协程的返回地址
#endif // 利用了 ret 语句来实现修改指令寄存器 %rip 的目的，通过修改 %rip 来实现程序运行逻辑跳转。注意%rip 的值不能直接修改，只能通过 call 或 ret 之类的指令来间接修改。

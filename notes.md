# Compiler
### 32 bit x86 Ruby
HAVE TO TEST ON 32 BIT MACHINE!!!!!!
```
 apt-get install gcc-multilib
 ruby compiler.rb > compiler.s
 gcc -m32 -o compiler compiler.rb
```
> Installs multilib which allows 32 bit execution on 64 bit machines.

Note 1

The assembly code is a bit complex. For the function call,

The prolog stores base pointer unto the stack.
It then copies the stack pointer into the base pointer

One problem is that why is the stack pointer stored into the base pointer? This is to facilitate easy overwriting of the stack poitner as well as the base pointer. GCC works this way and takes advantage of the same.

Running a method and a function are aclosely related. A method is simply a function with a parameter. SO once function calls are done, we can modify this easily so that methods are supported.

Support for a runtime library has been added. Still statements have to be hardcoded and functions have to be defined in global arrays.

Note 2 (Calling Conditional statements)
gcc treats all types as long long as a 32 bit value. float support will be added later.
```
void foo() {}
void bar() {}

int main()
{
  if (baz()) {
    foo();
  } else {
    bar();
  }
}
```
steps in assembler:-
1. call to baz function
2. if statmeents is checked
3. je (jump if equal) and call foo
4. evaluate else case and then call bar

Note 3 (Lambda Functions)
A call to the lambda function returns its address
variables, if called in the lambda function's scope, have to be around till the lifetime of the program, so we have to define environment variables.
Highly segfault prone - easy to crack since arbitrary pointer is cast into memory.

Note 4 (While Loop)
There are two options for executing a while loop

1. The while condition is placed at the end.
```
  jmp .L2
.L3:
  call  bar
.L2:
  call  foo
  testl %eax, %eax
  jne .L3
```
or
2. The while condition is placed at the start. Results in one extra iteration of loop.
```
.L3:
  call  foo
  testl %eax, %eax
  je  .L2
  call  bar
  jmp .L3
.L2:
```

Note 5 (Local Variables)

compiling this
```
int foo() {
  unsigned int i;
  i = 42;
}
```
gives this output in GCC
```
foo:
 pushl %ebp
 movl %esp,%ebp
 subl $16, %esp
 movl $42, -4(%ebp)
 leave
 ret
 ```
 so the memory and stack pointer operations can be seen.

Note 6 (Major Changes)

CHanges to parser:-
parser has been fully revamped, custom parser does nto use string scanner ruby class.
local variables, variable length arguments have been added

parser
  basic s-expression parser (sexp)
  files have been split up, parser has parser.rb and base is in parserbase.rb.
  testargs seem to be failing. Compilation ends inf EOF error, must be some double quotes problem.
  input scannign using basic shunting yard algorithm
  evaluate functions using shunting yard algorithm
  parser based on token system
  makefile should be modified to work on 64bit systems which have gcc-multilib installed.

local variables
  separate class Localvar added to define
  function emitter calls modified.

variable length paramaters
  class Arg has been defined
  all functions have been modified to include the new class Arg
  Absorption of excess chars done based on ruby's splat operator
  the priorities to the parser worked out by shunting yard algorithm

eval functions added in common
many functions split into separate files for reusability

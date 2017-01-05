# the old compiler used before the emitter class for reference and comparing changes
DO_BEFORE= []
DO_AFTER= []

class Function
	attr_reader :args,:body
	def initialize args,body
		@args = args
		@body = body
	end
end

class Scope
	def initialize compiler,func
		@c = compiler
		@func = func
	end

	def get_arg a
		a = a.to_sym
		@func.args.each_with_index {|arg,i| return [:arg,i] if arg == a }
		return [:atom,a]
	end
end

class Compiler
	PTR_SIZE=4
	def initialize
		@string_constants = {}
		@global_functions = {} #initialize spport for global functions
		@seq = 0
	end

	def get_arg(scope, a)
		return compile_exp(scope,a) if a.is_a?(Array)
		return [:int, a] if (a.is_a?(Fixnum))
		return scope.get_arg(a) if (a.is_a?(Symbol))
		seq = @string_constants[a] #Accepting only statments which contain strings for now.
		return seq if seq
		seq = @seq
		@seq += 1
		@string_constants[a] = seq
		return [:strconst,seq] # returning values of the sub expressions
	end

	def output_constants
		puts "\t.section\t.rodata"
		@string_constants.each do |c,seq|
			puts ".LC#{seq}:"
			puts "\t.string \"#{c}\""
		end
	end

	def output_functions
		@global_functions.each do |name,func| # iterate over each of the global functiosn
		puts ".globl #{name}" #push the name of the function to be displayed
		puts ".type #{name}, @function" # the return type of the function
		puts "#{name}:"
		puts "\tpushl %ebp" #push the base pointer
		puts "\tmovl %esp, %ebp" #push the base pointer unto the stack pointer
		compile_exp(Scope.new(self,func),func.body)
		puts "\tleave"
		puts "\tret" #return the memory back to the computer
		puts "\t.size #{name}, .-#{name}"
		puts
		end
	end

	def compile_defun scope,name, args, body
		@global_functions[name] = Function.new(args,body)
		return [:subexpr]
	end

	def compile_ifelse scope,cond, if_arm,else_arm
		compile_exp(scope,cond)
		puts "\ttestl\t%eax, %eax"
		else_arm_seq = @seq
		end_if_arm_seq = @seq + 1
		@seq += 2
		puts "\tje\t.L#{else_arm_seq}"
		compile_exp(scope,if_arm)
		puts "\tjmp\t.L#{end_if_arm_seq}"
		puts ".L#{else_arm_seq}:"
		compile_exp(scope,else_arm)
		puts ".L#{end_if_arm_seq}:"
		return [:subexpr]
	end

	def compile_lambda scope,args, body
		name = "lambda__#{@seq}"
		@seq += 1
		compile_defun(scope,name, args,body)
		puts "\tmovl\t$#{name},%eax"
		return [:subexpr]
	end

	def compile_eval_arg scope,arg, call = false
		prefix = call ? "*" : ""
		atype, aparam = get_arg(scope,arg)
		return "$.LC#{aparam}" if atype == :strconst
		return "$#{aparam}" if atype == :int
		return aparam.to_s if atype == :atom
		if atype == :arg
			puts "\tmovl\t#{PTR_SIZE*(aparam+2)}(%ebp),%eax"
		end
		return "#{prefix}%eax"
	end

	def compile_call scope,func, args
		stack_adjustment = PTR_SIZE + (((args.length+0.5)*PTR_SIZE/(4.0*PTR_SIZE)).round) * (4*PTR_SIZE)
		puts "\tsubl\t$#{stack_adjustment}, %esp"
		args.each_with_index do |a,i|
		param = compile_eval_arg(scope,a)
		puts "\tmovl\t#{param},#{i>0 ? i*4 : ""}(%esp)"
		end
		res = compile_eval_arg(scope,func,true)
		res = "*%eax" if res == "%eax" # Ugly. Would be nicer to retain some knowledge of what "res" contains
		puts "\tcall\t#{res}"
		puts "\taddl\t$#{stack_adjustment}, %esp"
		return [:subexpr]
	end

	def compile_do(scope,*exp)
		exp.each { |e| compile_exp(scope,e) }
		return [:subexpr]
	end

	def compile_assign scope, left, right
		source = compile_eval_arg(scope, right)
		atype, aparam = get_arg(scope,left)
		raise "Expected a variable on left hand side of assignment" if atype != :arg
		puts "\tmovl\t#{source},#{PTR_SIZE*(aparam+2)}(%ebp)"
		return [:subexpr]
	end

	def compile_while(scope, cond, body)
		start_while_seq = @seq
		cond_seq = @seq + 1
		@seq += 2
		puts "\tjmp\t.L#{cond_seq}"
		puts ".L#{start_while_seq}:"
		compile_exp(scope,body)
		puts ".L#{cond_seq}:"
		var = compile_eval_arg(scope,cond)
		puts "\ttestl\t#{var}, #{var}"
		puts "\tjne\t.L#{start_while_seq}"
		return [:subexpr]
	end

	def compile_exp(scope,exp)
		return if !exp || exp.size == 0
		return compile_do(scope,*exp[1..-1]) if exp[0] == :do
		return compile_defun(scope,*exp[1..-1]) if (exp[0] == :defun)
		return compile_ifelse(scope,*exp[1..-1]) if (exp[0] == :if)
		return compile_lambda(scope,*exp[1..-1]) if (exp[0] == :lambda)
		return compile_assign(scope,*exp[1..-1]) if (exp[0] == :assign)
		return compile_while(scope,*exp[1..-1]) if (exp[0] == :while)
		return compile_call(scope,exp[1],exp[2]) if (exp[0] == :call)
		return compile_call(scope,exp[0],exp[1..-1])
	end

def compile_main(exp)
# Taken from gcc -S output
# very sensitive data dont mess around here
puts <<PROLOG
	.text
.globl main
	.type	main, @function
main:
	leal	4(%esp), %ecx
	andl	$-16, %esp
	pushl	-4(%ecx)
	pushl	%ebp
	movl	%esp, %ebp
	pushl	%ecx
PROLOG

    @main = Function.new([],[])
    compile_exp(Scope.new(self,@main),exp)

    puts <<EPILOG
	popl	%ecx
	popl	%ebp
	leal	-4(%ecx), %esp
	ret

EPILOG

    output_functions
    output_constants
  end

  def compile(exp)
    compile_main([:do, DO_BEFORE, exp, DO_AFTER])
  end
end

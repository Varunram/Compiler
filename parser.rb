require_relative 'parserbase'
require_relative 'sexp'

class Parser < ParserBase
  def initialize s
    @s = s
    @sexp = SEXParser.new(s)
  end

  def parse_name
    @s.expect(Atom)
  end
  def parse_arglist
    rest = false
    if (@s.expect("*"))
      rest = true
      @s.ws
    end

    name = parse_name
    raise "Expected argument name" if rest && !name
    return nil if !name

    args = [(rest ? [name.to_sym,:rest] : name.to_sym)]

    @s.nolfws

    return args if (!@s.expect(","))
    @s.ws
    more = parse_arglist
    raise "Expected argument" if !more
    return args + more
  end
  def parse_args
    @s.nolfws
    if (@s.expect("("))
      @s.ws
      args = parse_arglist
      @s.ws
      raise "Expected ')'" if !@s.expect(")")
      return args
    end
    return parse_arglist
  end

  def parse_defexp
    @s.ws
    @sexp.parse
  end

  def parse_def
    return nil if !@s.expect("def")
    @s.ws
    raise "Expected function name" if !(name = parse_name)
    args = parse_args
    @s.ws
    exps = [:do] + zero_or_more(:defexp)
    raise "Expected expression of 'end'" if !@s.expect("end")
    return [:defun, name, args, exps]
  end

  def parse_sexp; @sexp.parse; end

  def parse_exp
    @s.ws
    parse_def || parse_sexp
  end

  def parse
    res = [:do] + zero_or_more(:exp)
    @s.ws
    raise "Expected EOF" if @s.peek
    return res
  end
end

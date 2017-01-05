class Scanner
  def initialize io
    @io = io
    @buf = ""
  end

  def fill
    if @buf.empty?
      c = @io.getc
      c = c.chr if c
      @buf = c ? c.to_s : ""
    end
  end

  def peek
    fill
    return @buf[-1]
  end

  def get
    fill
    return @buf.slice!(-1,1)
  end

  def unget(c)
    c = c.reverse if c.is_a?(String)
    @buf += c
  end

  def expect(str)
    return true if str == ""
    return str.expect(self) if str.respond_to?(:expect)
    buf = ""
    str.each_byte do |s|
      c = peek
      if !c || c.to_i != s
        unget(buf)
        return false
      end
      buf += get
    end
    return true
  end

  def ws
    while (c = peek) && [9,10,13,32].member?(c) do get; end
  end

  def nolfws
    while (c = peek) && [9,13,32].member?(c) do get; end
  end
end

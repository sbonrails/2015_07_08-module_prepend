module ParseFigLeaf

  def parse(*args)
    str = args.first
    if str.is_a?(String) && str =~ /\A\d\d[-\/]\d\d[-\/]\d\d/
      raise "Ambiguous parse format in #{str.inspect}"
    end

    super
  end

end

class << Date
  prepend ParseFigLeaf
end

class << Time
  prepend ParseFigLeaf
end

class ActiveSupport::TimeZone
  prepend ParseFigLeaf
end

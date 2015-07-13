require 'pry'; binding.pry

class Base
  def ping
    puts "Base::ping"
  end
end

module C
  def ping
    puts "C::ping"
    super
  end
end

module D
  def ping
    puts "D::ping"
    super
  end
end


class A < Base
  include C
  include D
end

>> A.ancestors

#####################################


class Base
  def instance_method; puts "instance Base"; end
  def self.class_method; puts "class Base"; end
end

class A < Base
  def instance_method; puts "instance A\n"; super; end
  def self.class_method; puts "class A\n"; super; end
end

a = A.new
a.instance_method
a.class.class_method

#####################################

module B
  extend ActiveSupport::Concern
  def instance_method; puts "instance B"; end
  module ClassMethods
    def class_method; puts "class B\n"; end
  end
end

class A
  include B
  def instance_method; puts "instance A\n"; super; end
  def self.class_method; puts "class A\n"; super; end
end

a = A.new
a.instance_method
a.class.class_method


#####################################

class Base
  def ping
    puts "Base::ping"
  end
end

module C
  def ping
    puts "C::ping"
    super
  end
end

module D
  def ping
    puts "D::ping"
    super
  end
end

module E
  def ping
    puts "E::ping"
    super
  end
end

module F
  def ping
    puts "F::ping"
    super
  end
end

class Api < Base
  include C
  include D
  prepend E
  prepend F

  def ping
    puts "Api::ping"
    super
  end
end

######################################

A.ancestors

a = Api.new
a.ping

######################################

PartnerApi.ancestors

######################################

require 'pry'

require './partner_api_3'

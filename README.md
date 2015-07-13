## Using Ruby 2.1's Module#prepend for Aspect-Oriented Programming

_Presented on July 8, 2015 by Colin Kelley_

Aspect-Oriented Programming (AOP) is a technique that separates
cross-cutting concerns by means of decorators on method calls. The
decorators are coded independently of the methods they augment and
therefore the decorators can be reused and composed. This approach has
been crudely possible in Ruby on Rails from the beginning using #alias_method_chain. That approach famously broken down with layering,
however. Yehuda Katz wrote a series of blog posts advocating a much
cleaner approach using Module and #super. That approach worked well but
only in a subset of cases where inheritance was already involved.
Fortunately, Ruby 2.1 has a fantastic general solution: Module#prepend.

We'll review how Module#prepend works and then run through 3 examples of
the simple beauty of separate concerns that is now possible with #prepend.
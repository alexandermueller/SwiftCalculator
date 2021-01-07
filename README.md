# SwiftCalculator (App Store Link: [Spark Calculator](https://www.youtube.com/watch?v=Z0taVhwj3EY)) 

<a href="http://www.google.com" target="_blank"><img align="left" src="https://is5-ssl.mzstatic.com/image/thumb/Purple124/v4/14/8e/75/148e75ac-9bed-5f89-f96b-cdf2d58e92c6/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/150x150bb.png" alt="Spark Calculator"></a> This app is the result of a personal challenge I imposed upon myself, where I had to create a calculator application completely from scratch, while doing my best to avoid using anyone else's code or guides related to creating calculators. I did, however, occasionally have to look up fundamental math concepts, refresh myself on floating point representation and computation limitations, and precedence rules based on typing functions into google calculator to see how it categorizes their precedence. It's been a fun ride so far, and I hope you enjoy learning about the core principles I've used to guide my calculator!

The underlying principles that power this calculator are as follows:

-> _Goal: Create a parser that can evaluate an arithmetic expression._

The expansion rules implemented in the ViewModel prevents the creation of an incorrect arithmetic expression (unless it's unfinished, in which case it errors out early.) This gives the parser an easier time, as it doesn't have to completely validate the input.

-> _Implementation: Use expansion rules and concrete base expression types._

Like any language, a mathematical equation follows a specific grammar and semantics. 
- The grammar of this language consists of digits, variables (ANS, MEM), modifiers (decimal), functions (left side, middle, right side), and parentheses. 
- The semantics determine the meaning behind sentences of our language, in this case, our arithmetic expressions. Given a sentence of our language (a list of strings), we can iterate through every value in reverse (like a stack), and construct an arithmetic expression using expansion rules. The resulting expression is evaluated, simplifying the expression to a final value.

-> _Example:_
```
["2", "!", "+", "2", "x", "3"] -> addition(factorial(number(2)), multiplication(number(2), number(3)))
```
The expression is created via the following steps in Generator.swift:
```
      expression | rank |      leftValue       | function | rightValue 
-----------------+------+----------------------+----------+------------ rank = ∞
1. [2,!,+,2,x,3] |   ∞  |         empty        |   empty  |    empty   
2.   [2,!,+,2,x] |   ∞  |         empty        |   empty  |  number(3) 
3.     [2,!,+,2] |   ∞  |          (*)         |     x    |  number(3)
 .  *.<----------+------+----------------------+----------+------------ (*).rank = "x".rank() = 5
 .  1. [2,!,+,2] |   5  |         empty        |   empty  |    empty   
 .  2.   [2,!,+] |   5  |         empty        |   empty  |  number(2)   
 .  3.     [2,!] |   5  |         empty        |     +    |  number(2) 
 .  -------------+------+----------------------+----------+-----------> "+".rank() > (*).rank -> return (number(2), [2,!,+])
4.       [2,!,+] |   ∞  |       number(2)      |     x    |  number(3)
5.       [2,!,+] |   ∞  |         empty        |   empty  |  multiplication(number(2), number(3))
6.         [2,!] |   ∞  |          (*)         |     +    |  multiplication(number(2), number(3))
 .  *.<----------+------+----------------------+----------+------------ (*).rank = "+".rank() = 7
 .  1.     [2,!] |   7  |         empty        |   empty  |    empty   
 .  2.       [2] |   7  |         (**)         |     !    |    empty   
 .   .  **.<<----+------+----------------------+----------+------------ (**).rank = "!".rank() = 1
 .   .  1.   [2] |   1  |         empty        |   empty  |    empty   
 .   .  2.    [] |   1  |         empty        |   empty  |  number(2)   
 .   .  ---------+------+----------------------+----------+---------->> expression == empty -> return (number(2), [])
 .  3.        [] |   7  |       number(2)      |     !    |    empty   
 .  4.        [] |   7  |         empty        |   empty  |  factorial(number(2))
 .  -------------+------+----------------------+----------+-----------> expression == empty -> return (factorial(number(2)), [])
7.            [] |   ∞  | factorial(number(2)) |     +    |  multiplication(number(2), number(3))
8.            [] |   ∞  |         empty        |   empty  |  addition(factorial(number(2)), multiplication(number(2), number(3)))
----------------------------------------------------------------------- expression == empty -> return (addition(factorial(number(2)), multiplication(number(2), number(3))), [])
```   
When the parser sees a function, it compares its rank to the current rank of the parser:
- a lower or equal rank (higher or similar importance): create a new parser instance with the new rank (or just recurse on the current parser instance if the ranks are equal), which continues and returns an appropriate leftValue
- a higher rank (lower importance): return the rightValue immediately, along with the resulting expression list which is used to update the previous level to reflect the resulting values that weren't consumed yet

The ranks are decided as follows:
```
Rank (from most important to least):
0. abs, sum
1. factorial
2. exponent
3. root
4. sqrt, inv, square
5. negate, multiply, divide
6. modulo
7. add, subtract
∞. default rank
```
The resulting expression is then reduced to its simplest form by executing the expression, which resembles the following call tree: 
```
    +       ->       +      ->     8
   / \              / \
  !   x            2   6 
 /   / \
2   2   3
```

-> _Functions:_

Each function is organized by where it is found in relation to the input values in the equation:
```
   side | rank | greedy |  function |      name      | symbol |  usage | explanation
--------+------+--------+-----------+----------------+--------+--------+-------------------------------------------------------------------------------------------
   left |    0 |  false |       abs | Absolute Value |      ~ |     ~a | The absolute value of expression a
   left |    0 |  false |       sum |      Summation |      ∑ |     ∑i | The summation of all integers between (and including) 0 and i, given a +/- integer i
   left |    4 |  false |      sqrt |    Square Root |      √ |     √a | The square root of expression a
   left |    4 |  false |       inv |        Inverse |     1/ |    1/a | The inverse of expression a
   left |    5 |  false |    negate |       Negation |      - |     -a | The negation of expression a
--------+------+--------+-----------+----------------+--------+--------+-------------------------------------------------------------------------------------------
 middle |    2 |   true |  exponent | Exponentiation |      ^ |  a ^ b | The exponentiation of expression a to the power of expression b
 middle |    3 |   true |      root |           Root |     *√ | a *√ b | The expression bth root of expression a (equivalent to a ^ (1/b))
 middle |    5 |  false |  multiply | Multiplication |      x |  a x b | The multiplication of expression a to expression b
 middle |    5 |  false |    divide |       Division |      ÷ |  a ÷ b | The division of expression a by expression b
 middle |    6 |  false |    modulo |         Modulo |      % |  a % b | The modulo of expression a by expression b
 middle |    7 |  false |       add |       Addition |      + |  a + b | The addition of expression a to expression b
 middle |    7 |  false |  subtract |    Subtraction |      – |  a – b | The subtraction of expression b from expression a
--------+------+--------+-----------+----------------+--------+--------+-------------------------------------------------------------------------------------------
  right |    1 |  false | factorial |      Factorial |      ! |     i! | The multiplication of all integers between (and including) 0 and i, given a +/- integer i
  right |    4 |  false |    square |         Square |     ^2 |    a^2 | The square of expression a
```

By organizing functions into these three different classifications, one can fairly easily expand the function set to include unimplemented or completely made up functions.
The side determines how the function is evaluated to the rest of the expression, and when combined with its rank, the expansion rules can determine how the overall expression is expanded in relation to function precedence.
This is very powerful and allows for really quick and painless implementations of new functions. 

-> _Note:_

Some functions are greedy, and prefer to evaluate immediately if the same function is seen after it: 
- "^", as 2^2^3 evaluates to 2^(2^3)
- "\*√", as 2\*√2\*√10000 evaluates to 2\*√(2\*√10000), which is the same as √(√10000)

Others, like left side functions, are greedy by the very definition of how these expressions are expanded (like "√") so there is no need to flag these as greedy. 
Meanwhile, "^2" defies the "^" greediness for the moment due to it being a right side function, which evaluates from the left to the right side of the expression (ie: 3!<sub>a</sub>!<sub>b</sub> -> factorialB(factorialA(number(3))).)
This makes implementing the correct expansion rule for "^2" difficult, so it's left as a simple shortcut that squares the result of the inner expression.

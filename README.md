# SwiftCalculator

This app is the result of a personal challenge I imposed upon myself, where I had to create a calculator application completely from scratch, while doing my best to avoid using anyone else's code or guides related to creating calculators. I did, however, occasionally have to look up fundamental math concepts, refresh myself on floating point representation and computation limitations, and precedence rules based on typing functions into google calculator to see how it categorizes their precedence. It's been a fun ride so far, and I hope you enjoy learning about the core principles I've used to guide my calculator!

The underlying principles that power this calculator are as follows:

-> _Goal: Create a parser that can evaluate an arithmetic expression._

The expansion rules implemented in the ViewModel prevents the creation of an incorrect arithmetic expression (unless it's unfinished, in which case it errors out early.) This gives the parser an easier time, as it doesn't have to completely validate the input.

-> _Implementation: Use expansion rules and concrete base expression types._

Like any language, a mathematical equation follows a specific grammar and semantics. 
- The grammar of this language consists of digits, variables (ANS, MEM) , modifiers (decimal), functions (left side, middle, right side), and parentheses. 
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
 .  *.<---------------------------------------------------------------- (*).rank = x.rank() = 5
 .  1. [2,!,+,2] |   5  |         empty        |   empty  |    empty   
 .  2.   [2,!,+] |   5  |         empty        |   empty  |  number(2)   
 .  3.     [2,!] |   5  |         empty        |     +    |  number(2) 
 .  ------------------------------------------------------------------> +.rank > (*).rank -> return (number(2), [2,!,+])
4.       [2,!,+] |   ∞  |       number(2)      |     x    |  number(3)
5.       [2,!,+] |   ∞  |         empty        |   empty  |  multiplication(number(2), number(3))
6.         [2,!] |   ∞  |          (*)         |     +    |  multiplication(number(2), number(3))
 .  *.<---------------------------------------------------------------- (*).rank = +.rank() = 7
 .  1.     [2,!] |   7  |         empty        |   empty  |    empty   
 .  2.       [2] |   7  |         (**)         |     !    |    empty   
 .   .  **.<<---------------------------------------------------------- (**).rank = !.rank() = 1
 .   .  1.   [2] |   1  |         empty        |   empty  |    empty   
 .   .  2.    [] |   1  |         empty        |   empty  |  number(2)   
 .   .  ------------------------------------------------------------->> expression == empty -> return (number(2), [])
 .  3.        [] |   7  |       number(2)      |     !    |    empty   
 .  4.        [] |   7  |         empty        |   empty  |  factorial(number(2))
 .  ------------------------------------------------------------------> expression == empty -> return (factorial(number(2)), [])
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
-> _Note:_

Some functions are greedy, and prefer to evaluate immediately if the same function is seen after it. "^"  is such a function, as 2^2^3 evaluates to 2^(2^3) (using google's calculator.)
The function side (left, middle, right) also impacts how the expression will be parsed (see Generator.swift for examples of this.)

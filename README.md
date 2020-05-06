#  SLox

Having finished the first half of https://craftinginterpreters.com in Java (see https://github.com/WanderingStar/jlox),
I've embarked in a perhaps silly project to do the second half not in C, but in Swift.

Why? To get myself back in the habit of writing Swift.

But I didn't really feel like using Unsafe pointers, so I'm going to cheat and use Swift arrays (which are dynamic) and pretend that they're not dynamic.

Challenges:
- 14.1 RLE line numbers
- 15.3 but lazy. Replaced stack with a Swift stack


#  SLox

Having finished the first half of https://craftinginterpreters.com in Java (see https://github.com/WanderingStar/jlox),
I've embarked in a perhaps silly project to do the second half not in C, but in Swift.

Why? To get myself back in the habit of writing Swift.

But I didn't really feel like using Unsafe pointers, so I'm going to cheat and use Swift arrays (which are dynamic) and pretend that they're not dynamic. **Update:** Joke's on me. I had to use unsafe pointers for strings.

Also complicating things: I arbitrarily decided to _not_ make the parser, vm, compiler etc. global variables. So I have to store the vm in the compiler and pass it around a bit, and all of the memory allocation code is in the vm, but extensions let me put it in its own file.

Challenges:
- 14.1 RLE line numbers
- 15.3 but lazy. Replaced stack with a Swift stack
- 21.1 lookup constants in the value array
- 22 added PopN
- 22.2 support for
    ```
    { var a = 1; { var a = a + 1; print a; } print a; }
    ```
    - which is just commenting out the error line...
- 22.3 added `con` declaration for constants
    - error if not initialized
    - error if assigned after initialization
    - global `con`s can be redefined, analogously to global `var`s


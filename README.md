# Dog birthday card #

Quick and dirty code for a dog-like birthday card. It plays Happy bithday song and 
swings it's tail.

Tail base has a hinge. The tail's actuator is a small phone speaker, which membrane is
glued to the tail near to the hinge. The base of the speaker is glued to the card.
Tail speaker is connected to pins 0 and 2, which allows movement in both directions by
alternating voltage.

It makes sound with a small piezo busser.

This program uses code from David Johnson-Davies, see:
http://www.technoblogy.com/show?20MO

Toolchain is Avr-libc + Gcc:
https://www.nongnu.org/avr-libc/
 
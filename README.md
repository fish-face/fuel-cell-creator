Fuel Cell Creator
===

This is a tool for creating fuel cell puzzles as per the [glyph1](https://g1.glyph.wtf/) puzzle hunt, where the faces of an icosidodecahedron must be filled with numbers according to the following rules:

1. Each pentagon must be filled with an integer from one to nine
2. The value on each triangle must be the sum of the values on the adjacent faces
3. If two faces are both adjacent to the same face, they must have different values

Requirements
===

You need a [nim compiler](https://nim-lang.org/install.html)

Compiling
===

```console
$ nim c -d:danger --threads:on solver.nim
```

Usage
===

```console
$ ./solver example.cell

[...]

Steps: 6, total guesses: 4
Solution found!
1 5
2 14
3 17
4 15
5 8
6 13
7 3
8 10
9 12
10 20
11 9
12 23
13 16
14 1
15 14
16 10
17 2
18 18
19 17
20 6
21 16
22 1
23 14
24 13
25 18
26 8
27 6
28 17
29 7
30 20
31 9
32 4
```

The format of the input file is the same as the final block of output: 32 lines each containing two integers. The first integer is the index of the face in the puzzle, the second value is the value pre-seeded into that face. A line prefixed by a `#` is ignored.

Start by filling in some values as in the example file, then run the solver. Adjust until the solver returns a unique result with no contradictions. Paste that into the source file, and comment out lines until you have a puzzle that looks like the difficulty you want. Re-run the solver to check that it's solvable.

To turn this into a solvable puzzle, run:

```console
$ cp net.svg example.svg
$ ./writesvg <cell file> example.svg
```

(`net.svg` is provided as an example svg in the right format).

`example.svg` will now be a net of the puzzle with given values in blue and answer values in black. It is left as an exercise to hide the black values without seeing any as a spoiler.

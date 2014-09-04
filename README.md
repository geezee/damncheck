# damncheck v0.1

A property based testing library for D. Forked from
[dashcheck](https://github.com/mcandre/dashcheck). It features a customizable
tester and diverse generators and meta-generators. Bellow is a simple documentation
based on examples. The full documentation as rendered with Ddoc can be found
[here](http://htmlpreview.github.io/?https://github.com/geezee/damncheck/blob/master/doc/damncheck.html)

# Generators
Generators are used to generate random values of a certain type. This is how
you can use some of the generators in D.

#### T generate(T)(T min=T.init, T max=T.init)
Will return a random element of type `T`.
```d
generate!bool; // will generate a random boolean
generate!string; // will generate a random string
generate!(int[]); // will use the meta-generator list!int
generate!(immutable int[char[immutable bool]]);
// will use the meta-generator dict!(immutable int, char[immutable bool])

generate!int(-100); // generate a random integer in [-100,int.max]
generate!float(10.037f, 100f); // generate a random float in [10.037, 100]
```

#### T choose(T)(T[] array)
Will return a random element form the array provided
```d
choose([1, -1, 8, -8, 23]);
choose(["D", "C", "Python"]);
```

# Meta-generators
Meta-generators are generators that take as arguments generators. They are used
to construct more complex generators.

#### auto oneOf(T...)(lazy T generators) if(generators.length >= 2)
Takes at least 2 generators and returns whatever a randomly selected generator
returns.
```d
oneOf(generate!float(-1f,1f), generate!float(99f,100f)); // random number in [-1,1]U[99,100]
oneOf(2,4,0,5,10); // a random number in {2, 4, 0, 5, 10}, equivalent to choose([2,4,0,5,10])
```

#### U mapGenerate(alias mapper,T,U=T)(lazy T generator=generate!T)
A map function that operates on generators to construct other generators.
```d
mapGenerate!(a => a % 2 == 0 ? a + 1 : a)(generate!int); // random odd int
mapGenerate!(a => a % 2 == 0 ? a : a + 1)(generate!int(-100,100)) // random even int between -100 and 100
mapGenerate!(a => a % 10, int) // generate a number between -10 and 10
```

#### T[] list(T, size_t N=ARRAY_MAX_SIZE)(lazy T generator=generate!T)
Produce an array that has at most length `N` whose elements are from the provided
generator.
```d
list!int // generate a list of integers
list!(bool,4) // a list of at most 4 booleans
list!int(0) // generate a list of all 0s
list!(float, 3)(generate!float(3, 5)) // a list of at most 3 floats between 3 and 5
```

#### T[U] dict(T, U, size_t N=ARRAY_MAX_SIZE)(lazy T values=generate!T, lazy U keys=generate!U)
Produce an associative array whose keys are generated from the `keys` generator
and values are from the `keys` generator.
```d
dict!(int, int) // a dictionary whose keys and values are random integers
dict!(int, bool) // [false: 2841782, true: -194927830]
dict!(int, bool, 10000000)(3) // [false: 3, true: 3]
```

# Sampling
Sampling is very similar to the `list` meta-generator. But it's usually used
for illustration purposes and not as a generator. As well it generates a list
of exactly `N` elements as opposed to one that has *at most* `N` elements.

#### T[] sample(T, const(int) N=10)(lazy T gen=generate!T)
```d
sample!int // a list of 10 integers
sample!(bool, 2) // a list of 2 booleans
sample(generate!float(-1f,1f)) // a list of 10 floats between -1 and 1
sample!(float, 3)(generate!float(-1f,1f)) // a list of 3 floats between -1 and 1
```
# Testing

#### DamnStat forAll(alias property, const(int) n=NUM_TESTS, alias reporter=null, Generators...)(lazy Generators generators) if (isCallable!property && is(ReturnType!property == bool))
Start a property-based test.

```d
/+ Example without reporting +/
bool idempotentSort(int[] list) {
    return list.sort == list.sort.sort;
}
auto stat1 = forAll!property(generate!(int[]));
auto stat2 = forAll!(property,1000)(generate!(ulong[]));
if(stat1.passed && stat2.passed) {
    writef("***** %d tests passed *****\n", stat1.testNum + stat2.testNum);
} else {
    writef("***** %d/%d tests passed *****\nError at input:\n%s",
           stat1.testNumRan, stat1.testNum, stat1.failStr);
    writef("***** %d/%d tests passed *****\nError at input:\n%s",
           stat2.testNumRan, stat2.testNum, stat2.failStr);
}
```
```d
/+ Example with reporting +/
bool expandingFloat(float a, float b, float c) {
    return a * (b + c) == a * b + a * c;
}
void expandingFloatReporter(float a, float b, float c) {
    writeln("Failed for: ", a, " ", b, " ", c);
    writefln("%.12f * (%.12f + %.12f) = %.12f", a, b, c, a*(b+c));
    writefln("%.12f * %.12f + %.12f * %.12f = %.12f", a, b, a, c, a*b+a*c));
}

auto stat = forAll!(expandingFloat, 100, expandingFloatShrinker)
                       (generate!float, generate!float, generate!float);
```

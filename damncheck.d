/**
 * DamnCheck - Property based testing library for D forked from dashcheck
 *
 * Authors:
 *   github.com/geezee
 *
 * Version:
 *   0.2
 *
 * License:
 *   MIT
 *
 * Forked:
 *   dashcheck - http://github.com/mcandre/dashcheck
*/
module damncheck;

import std.traits;
import std.typecons;
import std.conv;
import std.random;


/**
 * Random number generator to be used by the generators
*/
private auto randGen = Random();
private uint generatorSeed;


/**
 * Set the seed of the random number generator used by the generators. If no
 * seed was explicitly passed then it's unpredictable.
 *
 * Params:
 *   seed = the seed of the random number generator (defaults to unpredictableSeed)
 *
 * See_Also:
 *   oneOf, list, dict, choose, generate
*/
void setGeneratorSeed(uint seed=unpredictableSeed) {
    randGen.seed(seed);
    generatorSeed = seed;
}


/**
 * A report object that contains information about a test run
 *
 * See_Also:
 *    forAll
*/
struct DamnStat(T...) {
    /**
     * Whether all the tests passed or not
    */
    bool   passed;

    /**
     * The number of tests scheduled to be ran
    */
    size_t testNum;

    /**
     * The actual number of tets ran. If all the tests passed then this value
     * is equal to testNum, otherwise it denotes how many tests ran before the
     * bug showed up.
    */
    size_t testNumRan;

    /**
     * The seed used by the random number generator
    */
    uint   seed;

    /**
     * A tuple representing the arguments fed to the tested function. It is not
     * defined if the tests ran successfully
    */
    T      fail;


    /**
     * Property that produces a formatted string that represents the
     * failing case. In case all the tests passed then this function returns
     * null
    */
    @property string failStr() {
        if(passed) {
            return null;
        }
        string repr = "(";
        foreach(value;fail) {
            repr ~= to!string(value)~", ";
        }
        return repr[0..$-2]~")";
    }
}


/**
 * The maximum size an (associative) array can have when generating a random
 * one.
 *
 * See_Also:
 *   list, dict
*/
enum int ARRAY_MAX_SIZE = 1000;


/**
 * The default number of tests to run
 *
 * See_Also:
 *   forAll
*/
enum int NUM_TESTS = 100;


/**
 * A meta-generator that selects randomly a provided generator from its input
 * and returs the value it returns. Requires at least 2 inputs.
 *
 * Params:
 *   generators = A tuple of generators
 *
 * Returns:
 *   the value that a random generator from the input returns
 *
 * Example:
 * -------
 * oneOf(generate!float(-1f,1f), generate!float(99f,100f)); // a random number in [-1,1]U[99,100]
 * oneOf(2, 4, 0, 5, 10); // a random number in {2, 4, 0, 5, 10}
 * -------
*/
auto oneOf(T...)(lazy T generators)
if(generators.length >= 2) {
    return [generators][uniform(0,$,randGen)];
}

/**
 * A meta-generator that applies a map on a generator to transform it into another
 * generator.
 *
 * Params:
 *   mapper = the mapping function to use. It needs to be callable on one value.
 *   generator = the generator function to use when mapping
 *
 * Returns:
 *   An element from the generator that is mapped to the domain of the mapper
 *
 * Examples:
 * ---------
 * mapGenerate!(a => a % 2 == 0 ? a + 1 : a)(generate!int); // generate an odd int
 * mapGenerate!(a => a % 10, int); // generate a number betwen -10 and 10
 * ---------
*/
U mapGenerate(alias mapper, T, U=T)(lazy T generator = generate!T) {
    return mapper(generator);
}

/**
 * A meta-generator that builds an array of random length whose elements are
 * generated from the provided generator.
 *
 * Params:
 *    N =         the maximum size the array can have (inclusive), the default
 *                value is ARRAY_MAX_SIZE
 *    generator = the generator to use to build the array, the default value is
 *                generate!T
 *
 * Returns:
 *    An array contaning some elements generated from the provided generator
 *
 * Throws:
 *    Exception when the generate!T generator is used if T is not a suitable
 *    type for generate.
 *
 * See_Also:
 *    fixedList, generate, sample
 *
 * Examples:
 * -----------
 * list!int; // generate a list of integers, [-12885020, .... 48124]
 * list!(bool,4); // generate a list that is at most 4 elements long, [true]
 * list!int(0); // generate an array of all 0s, [0, 0, ..., 0]
 * list!(float, 3)(generate!float(3, 5)); // [4.2852, 3.4924]
 * -----------
*/
T[] list(T, size_t N=ARRAY_MAX_SIZE)(lazy T generator = generate!T) {
    Unqual!T[] array;
    array.length = uniform!"[]"(0, N, randGen);
    foreach(i; 0..array.length) {
        array[i] = generator;
    }
    return cast(T[]) array;
}

/**
 * A meta-generator that builds an array of length N whose elements are
 * generated from the provided generator.
 *
 * Params:
 *    N =         the size of the array
 *    generator = the generator to use to build the array, the default 
 *                value is generate!T
 *
 * Returns:
 *    An array contaning some elements generated from the provided generator
 *
 * Throws:
 *    Exception when the generate!T generator is used if T is not a suitable
 *    type for generate.
 *
 * See_Also:
 *    list, generate, sample
 *
 * Examples:
 * -----------
 * list!(int, 5); // generate a list of integers of length 5, [4, 3, 2, 5, 6]
 * list!(int, 3)(0); // generate an array of length 3 all 0s, [0, 0, 0]
 * list!(float, 3)(generate!float(3, 5)); // [4.2852, 3.4924, 2.1035]
 * -----------
 */
T[] fixedList(T, size_t N)(lazy T generator = generate!T) {
    Unqual!T[] array;
    array.length = N;
    foreach(i; 0..array.length) {
        array[i] = generator;
    }
    return cast(T[]) array;
}

/**
 * A meta-generator that builds an associative array whose length is random and
 * whose keys and values are elements generated from the provided generators.
 *
 * Params:
 *    N = the maximum length of the associative array (inclusive), the default
 *        is ARRAY_MAX_SIZE
 *    values = the generator to use to generate the values of the associative
 *             array, the default value is generate!T
 *    keys = the generator to use to generate the keys of the associative array,
 *           the default values is generate!U
 *
 * Returns:
 *    An associative array of random size and whose keys and values are generated
 *    from generators passed as arguments
 *
 * Throws:
 *    Exception if the key value and/or the value type force generate to throw
 *    an exception; i.e. when the types are not suitable for the generator
 *
 * See_Also:
 *    generate
 *
 * Examples:
 * ----------
 * dict!(int, int); // [-84: 92831, 8492: 4589284, -4892:-985717 ...]
 * dict!(int, bool); // [false: 21249894, true: -832194]
 * dict!(int, bool, 10000)(3); // [false: 3, true: 3]
 * ----------
*/
T[U] dict(T, U, size_t N=ARRAY_MAX_SIZE)
(lazy T values = generate!T, lazy U keys = generate!U) {
    Unqual!T[Unqual!U] dict;
    foreach(i; 0..uniform!"[]"(0, N, randGen)) {
        dict[keys] = values;
    }
    return cast(T[U]) dict;
}

/**
 * A generator that chooses randomly an element from a given array
 *
 * Params:
 *   array = the array of elements to chose randomly from
 *
 * Returns:
 *   an element from the array that is chosen at random
 *
 * Throws:
 *   Exception if the input is of length 0
 *
 * Examples:
 * --------
 * choose([1, -1, 8, -8, 23]);
 * --------
*/
T choose(T)(T[] array) {
    if(array.length > 0) {
        return array[uniform(0,$,randGen)];
    } else {
        throw new Exception("Array too short");
    }
}

/**
 * Generate some random values based on a type.
 *
 * Params:
 *   min = only used for elements who have the init property and are not arrays.
 *         It is the smallest value an element can have (inclusive). The default
 *         is T.init which is then converted to T.min
 *   max = only used for elements who have the init property and are not arrays.
 *         It is the largest value an element can have (inclusive). The default
 *         is T.init which is then converted to T.max
 *
 * Returns:
 *   A random element of type T provided
 *
 * See_Also:
 *   list, dict
 *
 * Throws:
 *   Exception when no generating function is available
 *
 * TODO:
 *   "Unwrap" a struct/class through the paramaters of their constructor and
 *   construct a random object through these types.
 *
 * Examples:
 * ----------
 * generate!bool; // true
 * generate!string; // "necxTT!30"
 * generate!(int[]); // will call list!int
 * generate!(immutable int[char[immutable bool]]);
 * // will call dict!(immutable int, char[immutable bool]);
 *
 * generate!int(10); // 392874
 * generate!float(10f, 11f); // 10.7329
 * ----------
 *
*/
T generate(T)(T min = T.init, T max = T.init) {
    static if(isAssociativeArray!T) {
        alias Unqual!(KeyType!T) Key;
        alias Unqual!(ValueType!T) Value;
        return cast(T) dict!(Value, Key);
    }
    else static if(isArray!T) {
        alias ForeachType!T SubType;
        return cast(T) list!SubType;
    }
    else static if(is(T == float)) {
        return cast(float) uniform!"[]"(min is T.init ? T.min_normal : min,
                                        max is T.init ? T.max : max, randGen);
    }
    else static if(is(T == bool)) {
        return uniform(0, 2, randGen) == 0 ? false : true;
    }
    else static if(__traits(hasMember, T, "min") && __traits(hasMember, T, "max")) {
        return uniform!"[]"(min is T.init ? T.min : min,
                            max is T.max ? T.max : max, randGen);
    }
    else {
        throw new Exception("No suitable generation function exists");
    }
}


/**
 * Sampling some values that the generator produces. The sample function and the
 * list function might seem very similar but besides the difference in the
 * objective, this function returns exactly an array of size N while the list
 * function returns a list that has at most size N.
 *
 * Params:
 *   gen = the generator, defaults to generate!T where T is the generic type
 *         passed to the function
 *   N   = the number values to samples (default is 10)
 *
 * Returns:
 *   An array of size N containing samples from the generators
 *
 * Throws:
 *   Exception if the default generate!T generator is used with no suitable
 *   type.
 *
 * See_Also:
 *    generate
 *
 * Example:
 * ----------
 * sample!int;
 * /+ [1541546906, -1397396910, 1173201093, 781288830, -10598603, -1822147006,
 *     1798781252, 950268125, -966182456, -275607635] +/
 * sample!(bool, 2);
 * // [false, false] 
 * sample(generate!float(-1f,1f));
 * /+ [-0.445366, 0.11867, -0.501579, -0.691207, 0.0411885, -0.62159, -0.311137,
 *     0.648751, 0.0521226, -0.595753] +/
 * sample!(float, 3)(generate!float(-1f,1f));
 * // [0.942426, -0.182376, -0.223072]
 * ----------
 *
*/
T[] sample(T, const int N=10)(lazy T gen = generate!T) {
    alias Unqual!T Type;
    Type[] array;
    array.length = N;
    foreach(i;0..N) {
        array[i] = gen;
    }
    return cast(T[]) array;
}


/**
 * Run a property based test
 *
 * Params:
 *  property    =  the property to test
 *                 needs to be callable and has return type a boolean
 *  n           =  the number of tests to run (default is 100)
 *  reporter    =  the reporter function that is used for manually "shrinking"
 *                 and reporting an error. It should be a function. It is passed
 *                 the failed arguments tuple and its return value is not used.
 *  generators  =  the function that generates input
 *
 * Returns:
 *  A tuple that contains whether all the tests passed or not (boolean), the
 *  number of tests to be ran (integer), the number of tests ran (integer) and
 *  the input (if any exists) at which the property failed (encoded as a string)
 *
 * Examples:
 * -----------
 * /+ Example without reporting +/
 * bool idempotentSort(int[] list) {
 *     return list.sort == list.sort.sort;
 * }
 * DamnStat stat1 = forAll!property(generate!(int[]));
 * DamnStat stat2 = forAll!(property,1000)(generate!(ulong[]));
 * if(stat1[0] && stat2[0]) {
 *     writef("***** %d tests passed *****\n", stat1[1]);
 * } else {
 *     writef("***** %d/%d tests passed *****\nError at input:\n%s",
 *            stat1[2], stat1[1], stat1[3]);
 *     writef("***** %d/%d tests passed *****\nError at input:\n%s",
 *            stat2[2], stat2[1], stat2[3]);
 * }
 * -----------
 * -----------
 * /+ Example with reporting +/
 * bool expandingFloat(float a, float b, float c) {
 *     return a * (b + c) == a * b + a * c;
 * }
 * void expandingFloatReporter(float a, float b, float c) {
 *     writeln("Failed for: ", a, " ", b, " ", c);
 *     writefln("%.12f * (%.12f + %.12f) = %.12f", a, b, c, a*(b+c));
 *     writefln("%.12f * %.12f + %.12f * %.12f = %.12f", a, b, a, c, a*b+a*c));
 * }
 *
 * DamnStat stat = forAll!(expandingFloat, 100, expandingFloatShrinker)
 *                        (generate!float, generate!float, generate!float);
 * -----------
*/
DamnStat!(ParameterTypeTuple!property) forAll
(alias property, const int n = NUM_TESTS, alias reporter = null, Generators...)
(lazy Generators generators)
if(isCallable!property && is(ReturnType!property == bool))
{
    alias ParameterTypeTuple!property TP;
    int passedTests = 0;
    TP args;

    foreach(testNum; 0..n) {
        foreach(i, arg; generators) {
            args[i] = arg;
        }

        if(property(args)) {
            passedTests++;
        }
        else {
            static if(isSomeFunction!reporter) {
                reporter(args);
            }
            break;
        }
    }

    bool hasPassed = passedTests == n;
    auto stats = DamnStat!TP(hasPassed, n, passedTests, generatorSeed);

    // if the tests didn't pass then there is a failing case that is args
    if(!hasPassed) {
        stats.fail = args;
    }
    
    return stats;
}

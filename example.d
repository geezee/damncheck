import damncheck;
import std.stdio;
import std.random;

/*
 * A sorting algorithm with a small bug to test
*/
int[] sort(int[] list, bool recursive=false) {
    // this if is added, alongside the recursive boolean in the input
    // to add a tiny bug in the code. If the sorting is given a 3 element list
    // and the first is smaller than the last and no recursion has been done
    // then return the list
    if(!recursive && list.length > 0
       && list.length <= 3 && list[0] < list[$-1]) {
        return list;
    }
    // other than that, it's a simple randomized quicksort
    if(list.length <= 1) {
        return list;
    } else {
        int element = list[uniform(0,$)];
        int[] smaller, larger, pivots;
        foreach(elm; list) {
            if(elm < element)
                smaller ~= elm;
            else if(elm > element)
                larger ~= elm;
            else
                pivots ~= elm;
        }
        return sort(smaller, true) ~ pivots ~ sort(larger, true);
    }
}


/* A function that generates a small float number */
float smallFloat() {
    return generate!float(-1f, 1f);
}

/* a function that formats the output of stat */
void formatter(T...)(DamnStat!T stat) {
    writefln("%s\t%d\t%d\t%d\t%s", stat.passed, stat.testNum, stat.testNumRan,
             stat.seed, stat.failStr);
}


/* property tester; sorting should be idempotent */
bool idempotentSort(int[] array) {
    return array.sort == array.sort.sort;
}

/* testing a basic algebra property on floats */
bool expandingFloat(float a, float b, float c) {
    return a * (b + c) == a * b + a * c;
}

/* property tester for the custom sorting function, it checks if the length
   is conserved and if the array is in ascending order */
bool sortPropertyCheckers(int[] list) {
    int[] dup = sort(list.dup);

    bool preserveLength = dup.length == list.length;
    bool isAscending = true;
    for(int i=0;dup.length > 1 && i<dup.length-1 && isAscending;i++) {
        isAscending = isAscending && (dup[i] <= dup[i+1]);
    }

    if(!preserveLength) writeln(">> Length is not preserved");
    if(!isAscending) writeln(">> The sorted list is not in ascending order");

    return preserveLength && isAscending;
}

/* function that reports the failing case of the custom sorting function */
void sortReporter(int[] list) {
    list = sort(list);
    int[] nonSorted;
    for(int i=0;i<list.length-1;i++) {
        if(list[i] > list[i+1]) {
            nonSorted ~= [list[i], list[i+1]];
            writefln("At index %d of the 'sorted' array: %s", i, nonSorted);
            return;
        }
    }
    writeln("All is well, should not reach this statement");
}


/**
*   EXAMPLE OF A RUN:
*
*   Stats for idempotentSort running on an array of int (uses Array.sort)
*   true    100     100     43
*
*   Stats for expandingFloat running on 3 generated floats
*   true    10000   10000   43
*   
*   Stats for expandingFloat running on 3 custom small generated floats
*   false   5       2       43      (-0.0114148, 0.766578, -0.873675)
*   
*   Stats for custom sort running on a custom generated list of integers
*   of at most 1000 elements
*   >> The sorted list is not in ascending order
*   At index 1 of the 'sorted' array: [-70, -253]
*   false   10000   1774    43      ([-281, -70, -253])
*/
void main() {
    setGeneratorSeed(43);

    writeln("Stats for idempotentSort running on an array of int (uses Array.sort)");
    auto statIdempotent = forAll!idempotentSort(list!int);
    formatter(statIdempotent);

    writeln();

    writeln("Stats for expandingFloat running on 3 generated floats");
    auto statExpand = forAll!(expandingFloat, 10000)
                             (generate!float, generate!float, generate!float);
    formatter(statExpand);
    
    writeln();
    
    writeln("Stats for expandingFloat running on 3 custom small generated floats");
    auto statExpandSmall = forAll!(expandingFloat, 5)
                                  (smallFloat, smallFloat, smallFloat);
    formatter(statExpandSmall);

    writeln();
    writeln("Stats for custom sort running on a custom generated list of integers");
    writeln("of at most 1000 elements");
    auto statSort = forAll!(sortPropertyCheckers, 10000, sortReporter)
                           (list!(int, 1000)(generate!int(-400,400)));
    formatter(statSort);
}

Simple library to generate a static lookup table.

Sometimes you want to generate a lookup table for something. And that lookup table is initialized once and never changes. If you use an AA, it can generate a lot of needless allocations as it's growing the buckets. Not only that, but the items themselves are individual allocations in the GC. If you have a lookup table of 100 items, that's a minimum of 101 allocations, cwhich can put a tax on the GC especially if you only intend to use it for a short time.

This lookup table is generated from known data -- the data must already be known before generating the table, and must have a length. Therefore, it knows how much buckets to allocate, and it can do all in one allocation, reducing the GC load when collecting.

It should be slightly faster than an AA, and much less taxing on GC collections.

Future improvements may include RAII possibilities (using malloc).

An example use case may be an array of headers read from an HTTP connection, where you want to look up values based on the header name. You read the headers into an array, and then generate a lookup table based on that.

There are 2 functions in here. `indexLookup` returns the mapping of the item in the given random access range to its index. `fieldLookup` is for values that have fields, or for using a lambda to generate the keys from the items. This version of the library will return the original item, but is indexed based on a field name, or based on a lambda to generate the key.

Docs may be filled out at some point if I feel this needs more polish.

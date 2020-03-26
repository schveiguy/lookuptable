module schlib.lookup;
import std.range;

private struct LookupNode(K, V, bool useTruthiness)
{
    size_t hash;
    K key;
    V value;
    static if(!useTruthiness)
    {
        bool valid = false;
    }

    this(size_t h, K k, V v)
    {
        hash = h;
        key = k;
        value = v;
        static if(!useTruthiness)
            valid = true;
    }

    bool opCast(B : bool)() const
    {
        static if(useTruthiness)
            return !!key;
        else
            return valid;
    }
}

private struct LookupTable(K, V, bool useTruthiness)
{
    import std.typecons : Nullable;
    private alias Bucket = LookupNode!(K, V, useTruthiness);
    private Bucket[] buckets;

    ref inout(V) opIndex(const(K) key) inout
    {
        if(auto v = key in this)
        {
            return *v;
        }
        import std.format;
        throw new Exception(format("Key %s not in lookup table", key));
    }

    inout(V)* opBinaryRight(string op : "in")(const(K) key) inout
    {
        auto hash = hashOf(key);
        auto idx = hash % buckets.length;
        foreach(ref b; buckets[idx .. $])
            if(!b)
                // this is where it would have gone...
                return null;
            else if(b.hash == hash && b.key == key)
                return &b.value;
        foreach(ref b; buckets[0 .. idx])
            if(!b)
                // this is where it would have gone...
                return null;
            else if(b.hash == hash && b.key == key)
                return &b.value;
        return null;
    }

    private void _insert(K key, ref V val)
    {
        auto hash = hashOf(key);
        auto idx = hash % buckets.length;
        foreach(ref b; buckets[idx .. $])
            if(!b || (b.hash == hash && b.key == key))
            {
                b = Bucket(hash, key, val);
                return;
            }
        foreach(ref b; buckets[0 .. idx])
            if(!b || (b.hash == hash && b.key == key))
            {
                b = Bucket(hash, key, val);
                return;
            }
        assert(0); // should not get here.
    }
}

LookupTable!(ElementType!R, size_t, useTruthiness) indexLookup(bool useTruthiness = false, R)(R rng) if (isRandomAccessRange!R)
{
    // simple equation -- use 2x the number of elements but with one less to make it a little more randomized
    LookupTable!(ElementType!R, size_t, useTruthiness) result;
    result.buckets = new result.Bucket[rng.length * 2 - 1];

    size_t i = 0;
    static if(hasLvalueElements!R)
    {
        foreach(ref k; rng)
        {
            result._insert(k, i);
            ++i;
        }
    }
    else
    {
        foreach(k; rng)
        {
            result._insert(k, i++);
            ++i;
        }
    }

    return result;
}

unittest
{
    string[] names = ["a", "b", "c", "d", "e", "f", "g"];
    auto lookup = names.indexLookup!true;
    auto lookup2 = names.indexLookup!false;
    foreach(i, n; names)
    {
        assert(lookup[n] == i, n);
        assert(lookup2[n] == i, n);
    }
}

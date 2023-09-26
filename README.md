# Read Python/NumPy NPY files via fast memory mapping

This package reads the header of a file in NumPy [NPY
format](https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html),
and then uses memory mapping to return the actual data as an `Array`.

The advantage of memory mapping is that if the data already sits in
the blockbuffer cache of the operating system, no data has to be
copied in memory to load it. This can significantly improve repeat
load times on large datasets.

Example usage:

```
using Npy
a = loadnpy("data.npy")
```

# Limitations

This package only supports arrays consisting of basic number types
(signed/unsigned 8/16/32/64-bit integers and 32/64-bit IEEE
floating-point numbers), but not any “pickeled” Python objects.

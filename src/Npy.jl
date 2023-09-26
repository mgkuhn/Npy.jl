module Npy

using LinearAlgebra
using Mmap

include("parse_python_literal.jl")
export loadnpy, parse_python_literal

@assert ENDIAN_BOM == 0x04030201
dtype_mapping =
    Dict("|i1"=>Int8,    "<i2"=>  Int16, "<i4"=>Int32,  "<i8"=>Int64,
         "|u1"=>UInt8,   "<u2"=> UInt16, "<u4"=>UInt32, "<u8"=>UInt64,
         "<f2"=>Float16, "<f4"=>Float32, "<f8"=>Float64)

function loadnpy(npyfile; memmap=true)
    # read header (shape & data type size)
    # https://numpy.org/doc/stable/reference/generated/numpy.lib.format.html
    if !memmap
        return npzread(npyfile)
    end
    open(npyfile,"r") do f
        if read(f, 6) != b"\x93NUMPY"
            @error("$npyfile: not a .npy file")
        end
        version = read(f, UInt8), read(f, UInt8) # (major ver, minor ver)
        if version == (1,0)
            headersize = read(f, UInt16)
        elseif version == (2,0)
            headersize = read(f, UInt32)
        else
            @error("$npyfile: unknown version $version")
        end
        header = String(read(f, headersize))
        h = parse_python_literal(header)
        type = dtype_mapping[h["descr"]]
        fortran_order = h["fortran_order"]
        shape = h["shape"]
        if !fortran_order; shape = reverse(shape); end
        ndim  = length(shape)

        # create mmap Array
        data  = mmap(f, Array{type,ndim}, shape)
        # translate C order to FORTRAN order using PermuteDimsArray()
        return fortran_order ? data :
                   ndim == 2 ? transpose(data) :
                               PermutedDimsArray(data, collect(reverse(1:ndim)))
    end
end

end

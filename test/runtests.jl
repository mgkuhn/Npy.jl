using Test
using Npy

@testset "parse_python_literal" begin
    @test Npy.parse_python_literal("True")  == true
    @test Npy.parse_python_literal("False") == false
    @test Npy.parse_python_literal("''") == ""
    @test Npy.parse_python_literal("'a'") == "a"
    @test Npy.parse_python_literal("'ä'") == "ä"
    @test Npy.parse_python_literal("'hello world'") == "hello world"
    @test Npy.parse_python_literal("123") == 123
    @test Npy.parse_python_literal("(1,2,3)") == (1,2,3)
    @test Npy.parse_python_literal(
        "{'descr': '>f8', 'fortran_order': False, 'shape': (1000, 10,5)}") ==
            Dict{Any, Any}("fortran_order" => false,
                           "shape" => (1000, 10, 5), "descr" => ">f8")
end

# convert a Julia Array into Python notation
function python_array(a)
    if ndims(a) > 1
        elements = String[python_array(s) for s in eachslice(a, dims=1)]
    else
        elements = sprint.(print, a)
    end
    return '[' * join(elements, ',') * ']'
end

# write a test file
fn = "test-npy.npy";
# for various dimensions, dtypes, and orders
for a in ([], [1], [1, 2, 3], [1 2; 3 4], reshape(1:16,2,2,2,2))
    pa = python_array(a)
    for dtype in keys(Npy.dtype_mapping)
        for order in ('F', 'C')
            py = "import numpy; numpy.save('$(fn)', numpy.array($pa, dtype='$dtype', order='$order'))"
            println(py)
            run(`python -c $py`)
            la = loadnpy(fn)
            @test la == a
            @test eltype(la) == Npy.dtype_mapping[dtype]
        end
    end
end
rm(fn)

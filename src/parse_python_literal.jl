"""
    next(m::RegexMatch)

Return the offset of the first character after `m.match` in the
underlying input string. (This value can then be fed into a
subsequent call to `match` operating on the same string, where it
can be matched in a regex pattern with `\\G`).)
"""
next(m::RegexMatch) = m.offset + ncodeunits(m.match)

"""
    parse_python_literal(p, offset::Ref{Int})

Parse a Python value literal (e.g. `"'string'"`, `"123"`, `"True"`,
`"(1, 2, 'foo')"`) from `p[offset[]:end]`. Return the parsed value in
the corresponding Julia type, and update the reference `offset` such
that after the call any characters that have not been consumed by the
parser remain in `p[offset[]:end]`.

    parse_python_literal(p)

Without `offset`, this function starts parsing at `firstindex(p)` and
aborts with an error if at the end there are trailing characters left.

# Limitations

This function currently only supports the Python types string,
integer, Boolean, list, and dictionary. Lists and dictionaries can
be nested as deep as the Julia stack permits. This parser does not
yet support interpreting any escape characters in string literals.

# Examples
julia> parse_python_literal("{123: False, 'a':('foo')}")
Dict{Any, Any} with 2 entries:
  123 => false
  "a" => Any["foo"]
"""
function parse_python_literal(p, offset::Ref{Int})
    #@show p, offset[]
    if (m = match(r"\GTrue(?!\w)", p, offset[])) !== nothing
        v = true
    elseif (m = match(r"\GFalse(?!\w)", p, offset[])) !== nothing
        v = false
    elseif (m = match(r"\G'([^']*)'", p, offset[])) !== nothing
        v = string(m.captures[1])
    elseif (m = match(r"\G(\d+)", p, offset[])) !== nothing
        v = parse(Int, m.captures[1])
    elseif (m = match(r"\G\s*\(\s*", p, offset[])) !== nothing
        offset[] = next(m)
        a = Any[]
        while true
            if (m = match(r"\G\s*,?\s*\)\s*", p, offset[])) !== nothing
                v = tuple(a...)
                break
            end
            if length(a) > 0
                if (m = match(r"\G\s*,\s*", p, offset[])) === nothing
                    @error("expected ',' or ')'", p, p[offset[]:end])
                end
                offset[] = next(m)
            end
            push!(a, parse_python_literal(p, offset))
        end
    elseif (m = match(r"\G\s*\{\s*", p, offset[])) !== nothing
        offset[] = next(m)
        d = Dict{Any,Any}()
        while true
            if (m = match(r"\G\s*,?\s*\}\s*", p, offset[])) !== nothing
                v = d
                break
            end
            if length(d) > 0
                if (m = match(r"\G\s*,\s*", p, offset[])) === nothing
                    @error("expected ',' or '}'", p, p[offset[]:end])
                end
                offset[] = next(m)
            end
            k = parse_python_literal(p, offset)
            if (m = match(r"\G\s*:\s*", p, offset[])) === nothing
                @error("expected ':'", p, p[offset[]:end])
            end
            offset[] = next(m)
            v = parse_python_literal(p, offset)
            d[k] = v
        end
    else
        @error("unexpected syntax", p, p[offset[]:end])
    end
    offset[] = next(m)
    #@show v, p[offset[]:end]
    return v
end

function parse_python_literal(p)
    offset = Ref{Int}(firstindex(p))
    v = parse_python_literal(p, offset)
    if offset[] != firstindex(p) + ncodeunits(p)
        @error("unexpected trailing characters", p, p[offset[]:end])
    end
    return v
end


struct tri_struct
    v::Int64
    w::Int64
    x::Int64
end

struct triangles_iterator
    tri::tri_struct
    triinfo::tri_struct
    symmetries::Bool
    S::Union{UnitRange{Int64},Vector{Int64},Int}
    rp::Vector{Int}
    ci::Vector{Int}
    vindicator::Vector{Bool}
    windicator::Vector{Bool}#only needed for the unique case
end

function next_triangle!(tri::tri_struct,triinfo::tri_struct,
    S::Union{UnitRange{Int64},Vector{Int64},Int},
    rp::Vector{Int},
    ci::Vector{Int},
    vindicator::Vector{Bool}) 
    v,w,x = (tri.v,tri.w,tri.x)
    vi,wi,xi = (triinfo.v,triinfo.w,triinfo.x)
    # start with checking x
    wrng = rp[v]:rp[v+1]-1
    xrng = rp[w]:rp[w+1]-1
    if xi < length(xrng)
        xi += 1
        new_x = ci[xrng[xi]]
        while vindicator[new_x] == 0 && xi < length(xrng) 
        # while A[v,new_x] == 0 && xi < length(xrng) 
            xi += 1
            new_x = ci[xrng[xi]]
        end # either A[v,new_x] = 1 or out of spots
        if vindicator[new_x] != 0
        # if A[v,new_x] != 0
            return tri_struct(v,w,new_x),tri_struct(vi,wi,xi)
        end
    end

    while wi < length(wrng)
        wi += 1
        new_w = ci[wrng[wi]]

        xrng = rp[new_w]:rp[new_w+1]-1
        xi = 1
        new_x = ci[xrng[xi]]

        while vindicator[new_x] == 0 && xi < length(xrng) 
        # while A[v,new_x] == 0 && xi < length(xrng) 
            xi += 1
            new_x = ci[xrng[xi]]
        end
        if vindicator[new_x]
        # if A[v,new_x] != 0
            return tri_struct(v,new_w,new_x),tri_struct(vi,wi,xi)
        end
    end
    while vi < length(S)
        vi += 1
        new_v = S[vi]
        update_vindicator!(vindicator,new_v,rp,ci)

        wrng = rp[new_v]:rp[new_v+1]-1
        wi = 0
        while wi < length(wrng)
            wi += 1
            new_w = ci[wrng[wi]]

            xrng = rp[new_w]:rp[new_w+1]-1
            xi = 1
            new_x = ci[xrng[xi]]

            while vindicator[new_x] == 0 && xi < length(xrng) 
            # while A[new_v,new_x] == 0 && xi < length(xrng) 
                xi += 1
                new_x = ci[xrng[xi]]
            end
            if vindicator[new_x]
            # if A[new_v,new_x] != 0
                return tri_struct(new_v,new_w,new_x),tri_struct(vi,wi,xi)
            end
        end
    end
    # if this was reached, no more triangles
    return tri_struct(0,0,0),tri_struct(0,0,0)
end

function next_triangle_unique!(tri::tri_struct,triinfo::tri_struct,
    S::Union{UnitRange{Int64},Vector{Int64},Int},
    rp::Vector{Int},
    ci::Vector{Int},
    vindicator::Vector{Bool},
    windicator::Vector{Bool})
    v,w,x = (tri.v,tri.w,tri.x)
    vi,wi,xi = (triinfo.v,triinfo.w,triinfo.x)
    # start with checking x
    wrng = rp[v]:rp[v+1]-1
    xrng = rp[w]:rp[w+1]-1
    # v<w<x
    if xi < length(xrng)
        xi += 1
        new_x = ci[xrng[xi]]
        while xi < length(xrng) && (new_x <= w || vindicator[new_x] == 0 || windicator[new_x] == true)
            xi += 1
            new_x = ci[xrng[xi]]
        end # either A[v,new_x] = 1 or out of spots
        if vindicator[new_x] != 0 && w < new_x && windicator[new_x] == false #= it hasn't been fully used before =#
        # if A[v,new_x] != 0 && w < new_x
            return tri_struct(v,w,new_x),tri_struct(vi,wi,xi)
        end
    end

    windicator[w] = true
    while wi < length(wrng)
        # done with it 
        wi += 1
        new_w = ci[wrng[wi]]

        # if v < new_w
        if windicator[new_w] == false
            xrng = rp[new_w]:rp[new_w+1]-1
            xi = 1
            new_x = ci[xrng[xi]]
            while xi < length(xrng) && (new_x <= new_w || vindicator[new_x] == 0 || windicator[new_x] == true)
                xi += 1
                new_x = ci[xrng[xi]]
            end
            if vindicator[new_x] != 0 && new_w < new_x && windicator[new_x] == false
            # if A[v,new_x] != 0 && new_w < new_x
                return tri_struct(v,new_w,new_x),tri_struct(vi,wi,xi)
            end
        end
    end
    
    while vi < length(S)
        vi += 1
        new_v = S[vi]
        update_vindicator!(vindicator,new_v,rp,ci)
        windicator .=0
        windicator[S[1:vi-1]] .= 1

        wrng = rp[new_v]:rp[new_v+1]-1
        wi = 0
        while wi < length(wrng)
            wi += 1
            new_w = ci[wrng[wi]]
            # if new_v < new_w
            if windicator[new_w] == false
                xrng = rp[new_w]:rp[new_w+1]-1
                xi = 1
                new_x = ci[xrng[xi]]
                # keep trying to find something until...
                while xi < length(xrng) && (new_x <= new_w || vindicator[new_x] == 0 || windicator[new_x] == true #=i.e. we used it before =#)
                    xi += 1
                    new_x = ci[xrng[xi]]
                end
                if vindicator[new_x] != 0 && new_w < new_x && windicator[new_x] == false
                # if A[new_v,new_x] != 0 && new_w < new_x
                    return tri_struct(new_v,new_w,new_x),tri_struct(vi,wi,xi)
                end
            end
        end
    end
    # if this was reached, no more triangles
    return tri_struct(0,0,0),tri_struct(0,0,0)
end

function triprint(t::tri_struct)
    @show t.v,t.w,t.x
end

function Base.iterate(iter::triangles_iterator, state=(iter.tri, iter.triinfo))
    element, elinfo = state

    if element == tri_struct(0, 0, 0)
        update_vindicator!(iter.vindicator,iter.S[1],iter.rp,iter.ci)
        iter.windicator.=0
        return nothing
    end

    if iter.symmetries
        v1,v2 = next_triangle!(element,elinfo,iter.S,iter.rp,iter.ci,iter.vindicator)
    else
        v1,v2 = next_triangle_unique!(element,elinfo,iter.S,iter.rp,iter.ci,iter.vindicator,iter.windicator)
    end
    return (element, (v1,v2))
end

function find_first_triangle(S::Union{UnitRange{Int64},Vector{Int64},Int},
    rp::Vector{Int},
    ci::Vector{Int},
    n::Int)
    vi = 1
    v = S[vi]        
    rng = rp[v]:rp[v+1]-1
    while !(length(rng)>0) && vi<length(S)
        vi +=1
        v = S[vi]
        rng = rp[v]:rp[v+1]-1
    end
    #either reached the end and the last value is invalid, thus there are no triangles
    if vi == length(S) && !(length(rng)>0)
        return tri_struct(0,0,0),tri_struct(0,0,0) # this graph has no edges!
    else
        vindicator = zeros(Bool,n)
        @inbounds for rpi = rp[v]:rp[v+1]-1
            w = ci[rpi]
            vindicator[w] = true
        end
        wi = 1
        w = ci[rng[wi]]
        windicator = zeros(Bool,n)
        vec1,vec2 = next_triangle_unique!(tri_struct(v,w,0),tri_struct(vi,wi,0),S,rp,ci,vindicator,windicator)
        return vec1,vec2,vindicator,windicator
    end
end


function update_vindicator!(vindicator::Vector{Bool},v::Int,rp::Vector{Int},ci::Vector{Int})
    vindicator .= false
    @inbounds for rpi = rp[v]:rp[v+1]-1
        w = ci[rpi]
        vindicator[w] = true
    end
end

# old function:
# function triangles(A::SparseMatrixCSC{T,Int64},S::Union{UnitRange{Int64},Vector{Int64},Int};symmetries=false) where T
#     M = MatrixNetwork(A)

#     if is_undirected(M) == false
#         error("Only undirected (symmetric) inputs are allowed")
#     end
    
#     rp,ci,ai = (M.rp,M.ci,M.vals)
#     if typeof(findfirst(ai.<0)) != Nothing
#         error("only positive edge weights allowed")
#     end

#     v1,v2 = find_first_triangle(S,rp,ci,A)
#     first_triangle = v1 #onetriangle(v1[1],v1[2],v1[3])
#     first_triangle_info = v2 #onetriangle_info(v2[1],v2[2],v2[3])
#     my_tri_iter = triangles_iterator(first_triangle,first_triangle_info,symmetries,S,rp,ci,A)
# end

"""
- triangles(A) return an iterator for all the triangles in a graph A    
- triangles(A,i) return an iterator for all triangles in a graph A involving node i
- triangles(A,S) return an iterator for all triangles in a graph A involving a node in S
- triangles(A,S;symmetries=true) return an iterator of all triangles in A involving a node in S with symmetries 
    (i.e. a triangle (i,j,k) is counted 6 times)
sample run:
-----------
```
using MatrixNetworks
A = load_matrix_network("clique-10");
mytriangles = triangles(A)
for tri in mytriangles
    triprint(tri)
end
z = collect(mytriangles)
ei,ej,ek = unzip_triangles(z)
```
"""
function triangles(M::MatrixNetwork{T},S::Union{UnitRange{Int64},Vector{Int64},Int};symmetries=false) where T

    if is_undirected(M) == false
        error("Only undirected (symmetric) inputs are allowed")
    end
    
    rp,ci,ai = (M.rp,M.ci,M.vals)
    if typeof(findfirst(ai.<0)) != Nothing
        error("only positive edge weights allowed")
    end

    v1,v2,vindicator,windicator = find_first_triangle(S,rp,ci,M.n)
    first_triangle = v1 #onetriangle(v1[1],v1[2],v1[3])
    first_triangle_info = v2 #onetriangle_info(v2[1],v2[2],v2[3])
    my_tri_iter = triangles_iterator(first_triangle,first_triangle_info,symmetries,S,rp,ci,vindicator,windicator)
end
function triangles(A::SparseMatrixCSC{T,Int64},S::Union{UnitRange{Int64},Vector{Int64},Int};symmetries=false) where T

    if maximum(S) > A.n
        error("triangles(A,S): the maximum value in S must be <= the number of nodes in the graph")
    end

    if issymmetric(A) == false
        error("Only undirected (symmetric) inputs are allowed")
    end
    
    rp,ci,ai = A.colptr,A.rowval,A.nzval
    if typeof(findfirst(ai.<0)) != Nothing
        error("Only positive edge weights allowed")
    end

    v1,v2,vindicator,windicator = find_first_triangle(S,rp,ci,A.n)
    first_triangle = v1 #onetriangle(v1[1],v1[2],v1[3])
    first_triangle_info = v2 #onetriangle_info(v2[1],v2[2],v2[3])
    my_tri_iter = triangles_iterator(first_triangle,first_triangle_info,symmetries,S,rp,ci,vindicator,windicator)
end

# generic functions
triangles(G::SparseMatrixCSC{T,Int64};symmetries=false) where T = triangles(G,1:size(G,1);symmetries=symmetries)
triangles(M::MatrixNetwork{T};symmetries=false) where T = triangles(M,1:M.n;symmetries=symmetries)
# the following are no longer needed because of the general triangles function above
# triangles(G::SparseMatrixCSC{T,Int64}) where T = triangles(G,1:size(G,1))
# triangles(G::SparseMatrixCSC{T,Int64},i::Int64) where T =  triangles(G,i:i)
# triangles(G::SparseMatrixCSC{T,Int64},i::Int64;symmetries=false) where T =  triangles(G,i;symmetries=symmetries)

import Base.collect
function collect(tris::triangles_iterator)
    alltriangles = Array{Tuple{Int,Int,Int}}(undef,0)
    for ti in tris
        push!(alltriangles,(ti.v,ti.w,ti.x))
    end
    return alltriangles
end

function unzip_triangles(z::Vector{Tuple{Int64,Int64,Int64}})
    n = length(z)
    ei = zeros(Int,n)
    ej = zeros(Int,n)
    ek = zeros(Int,n)
    @inbounds for i = 1:n
        ei[i],ej[i],ek[i] = z[i]
    end
    return ei,ej,ek
end


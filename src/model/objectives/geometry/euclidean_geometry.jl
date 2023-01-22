struct Point2D{T<:Real}
    x::T
    y::T
end

struct Point3D{T<:Real}
    x::T
    y::T
    z::T
end

"""
    euclidean_2D_rounded(i1::Int,i2::Int, map::Dict{Int, Point2D})

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xy-plane between the two points rounded to the nearest integer

# Arguments
- `i1::Int`: an index of a point in the map
- `i2::Int`: another index of a point in the map
- `map::Dict{Int, Point2D}`: the map of indexes to points
"""
function euclidean_2D_rounded(i1::Int,i2::Int, map::Dict{Int, Point2D})
    return euclidean_2D_rounded(map[i1],map[i2])
end

"""
    euclidean_2D_rounded(p1::Point2D,p2::Point2D)

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xy-plane between the two points rounded to the nearest integer

# Arguments
- `p1::Point2D`: a point to compare
- `p2::Point2D`: another point to compare
"""
function euclidean_2D_rounded(p1::Point2D,p2::Point2D)
    return round(sqrt(((p1.x - p2.x)^2)+((p1.y - p2.y)^2)))
end

"""
    euclidean_2D(i1::Int,i2::Int, map::Dict{Int, Point2D})

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xy-plane between the two points

# Arguments
- `i1::Int`: an index of a point in the map
- `i2::Int`: another index of a point in the map
- `map::Dict{Int, Point2D}`: the map of indexes to points
"""
function euclidean_2D(i1::Int,i2::Int, map::Dict{Int, Point2D})
    return euclidean_2D(map[i1],map[i2])
end

"""
    euclidean_2D(p1::Point2D,p2::Point2D)

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xy-plane between the two points

# Arguments
- `p1::Point2D`: a point to compare
- `p2::Point2D`: another point to compare
"""
function euclidean_2D(p1::Point2D,p2::Point2D)
    return sqrt(((p1.x - p2.x)^2)+((p1.y - p2.y)^2))
end

"""
    euclidean_3D_rounded(i1::Int,i2::Int, map::Dict{Int, Point3D})

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xyz-plane between the two points rounded to the nearest integer

# Arguments
- `i1::Int`: an index of a point in the map
- `i2::Int`: another index of a point in the map
- `map::Dict{Int, Point3D}`: the map of indexes to points
"""
function euclidean_3D_rounded(i1::Int,i2::Int, map::Dict{Int, Point3D})
    return euclidean_3D_rounded(map[i1],map[i2])
end

"""
    euclidean_3D_rounded(p1::Point3D,p2::Point3D)

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xyz-plane between the two points rounded to the nearest integer

# Arguments
- `p1::Point3D`: a point to compare
- `p2::Point3D`: another point to compare
"""
function euclidean_3D_rounded(p1::Point3D,p2::Point3D)
    return round(sqrt(((p1.x - p2.x)^2)+((p1.y - p2.y)^2)+((p1.z - p2.z)^2)))
end

"""
    euclidean_3D(i1::Int,i2::Int, map::Dict{Int, Point3D})

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xyz-plane between the two points

# Arguments
- `i1::Int`: an index of a point in the map
- `i2::Int`: another index of a point in the map
- `map::Dict{Int, Point3D}`: the map of indexes to points
"""
function euclidean_3D(i1::Int,i2::Int, map::Dict{Int, Point3D})
    return euclidean_3D(map[i1],map[i2])
end

"""
    euclidean_3D(p1::Point3D,p2::Point3D)

Takes in a map of indexes to points and two indexes
Returns the euclidean distance on the xyz-plane between the two points

# Arguments
- `p1::Point3D`: a point to compare
- `p2::Point3D`: another point to compare
"""
function euclidean_3D(p1::Point3D,p2::Point3D)
    return sqrt(((p1.x - p2.x)^2)+((p1.y - p2.y)^2)+((p1.z - p2.z)^2))
end

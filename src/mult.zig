const std = @import("std");
const math = std.math;

/// Multiplies two input series element-wise.
///
/// This function computes the element-wise product of two input arrays of floating-point numbers.
/// That is, for each index `i`, it calculates:
///
/// ---
/// **Formula:**
/// ```
/// out[i] = inReal1[i] * inReal2[i]
/// ```
///
/// ---
/// **Parameters:**
/// - `inReal1`: The first input slice of real values.
/// - `inReal2`: The second input slice of real values (must be the same length as `inReal1`).
/// - `allocator`: Allocator used to allocate the result slice.
///
/// ---
/// **Returns:**
/// - A newly allocated slice of `f64`, where each element is the product of the corresponding elements from the two inputs.
///
/// ---
/// **Errors:**
/// - Returns an error if the lengths of the input slices do not match.
/// - May return an allocation error if memory allocation fails.
///
/// ---
/// **Example:**
/// ```text
/// inReal1 = [1.0, 2.0, 3.0]
/// inReal2 = [4.0, 5.0, 6.0]
///
/// Output:
/// result = [1.0*4.0, 2.0*5.0, 3.0*6.0] = [4.0, 10.0, 18.0]
/// ```
pub fn Mult(inReal1: []const f64, inReal2: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal1.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal1, inReal2) |*out, v1, v2| {
        out.* = v1 * v2;
    }

    return outReal;
}

test "Mult work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };
    const y = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Mult(&x, &y, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 10000, 100, 1, 0, 1, 100, 10000 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

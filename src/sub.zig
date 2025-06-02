const std = @import("std");
const math = std.math;

/// Performs element-wise subtraction of two input series.
///
/// This function computes the difference between two input arrays of floating-point numbers.
/// For each index `i`, it performs:
///
/// ---
/// **Formula:**
/// ```
/// out[i] = inReal1[i] - inReal2[i]
/// ```
///
/// ---
/// **Parameters:**
/// - `inReal1`: The first input slice of real values (minuend).
/// - `inReal2`: The second input slice of real values (subtrahend), must be the same length as `inReal1`.
/// - `allocator`: Allocator used to allocate the result slice.
///
/// ---
/// **Returns:**
/// - A newly allocated slice of `f64`, where each element is the result of subtracting the corresponding element in `inReal2` from `inReal1`.
///
/// ---
/// **Errors:**
/// - Returns an error if the lengths of the input slices do not match.
/// - May return an allocation error if memory allocation fails.
///
/// ---
/// **Example:**
/// ```text
/// inReal1 = [5.0, 7.0, 10.0]
/// inReal2 = [2.0, 3.0, 6.0]
///
/// Output:
/// result = [5.0-2.0, 7.0-3.0, 10.0-6.0] = [3.0, 4.0, 4.0]
/// ```
fn Sub(inReal1: []const f64, inReal2: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal1.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal1, inReal2) |*out, v1, v2| {
        out.* = v1 - v2;
    }

    return outReal;
}

test "Sub work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };
    const y = [_]f64{ -100, -10, -1, 0, 1, 10, 80 };

    const result = try Sub(&x, &y, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 20 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

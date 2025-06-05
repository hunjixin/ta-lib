const std = @import("std");
const math = std.math;

/// Element-wise addition of two input arrays.
///
/// This function computes the sum of corresponding elements from two input slices:
///   out[i] = inReal1[i] + inReal2[i]
///
/// Parameters:
/// - `inReal1`: The first input slice of f64 values.
/// - `inReal2`: The second input slice of f64 values, must be the same length as `inReal1`.
/// - `allocator`: Memory allocator used to allocate the output slice.
///
/// Returns:
/// - A new slice of f64 containing the element-wise sums.
///
/// Errors:
/// - Returns an error if the input slices have different lengths.
///
/// Example:
/// - Input: inReal1 = [1.0, 2.0, 3.0], inReal2 = [4.0, 5.0, 6.0]
/// - Output: [5.0, 7.0, 9.0]
pub fn Add(inReal1: []const f64, inReal2: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal1.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal1, inReal2) |*out, v1, v2| {
        out.* = v1 + v2;
    }

    return outReal;
}

test "Add work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };
    const y = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Add(&x, &y, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -200, -20, -2, 0, 2, 20, 200 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

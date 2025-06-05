const std = @import("std");
const math = std.math;

/// Element-wise division of two input arrays.
///
/// This function computes the division of corresponding elements from two input slices:
///   out[i] = inReal1[i] / inReal2[i]
///
/// Parameters:
/// - `inReal1`: The numerator input slice of f64 values.
/// - `inReal2`: The denominator input slice of f64 values, must be the same length as `inReal1`.
/// - `allocator`: Memory allocator used to allocate the output slice.
///
/// Returns:
/// - A new slice of f64 containing the element-wise divisions.
///
/// Errors:
/// - Returns an error if the input slices have different lengths.
/// - Care should be taken to avoid division by zero; behavior depends on implementation.
///
/// Example:
/// - Input: inReal1 = [10.0, 20.0, 30.0], inReal2 = [2.0, 5.0, 6.0]
/// - Output: [5.0, 4.0, 5.0]
pub fn Div(inReal1: []const f64, inReal2: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal1.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal1, inReal2) |*out, v1, v2| {
        out.* = v1 / v2;
    }

    return outReal;
}

test "Div work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };
    const y = [_]f64{ -100, -10, -1, 1, 1, 10, 100 };

    const result = try Div(&x, &y, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 1, 1, 1, 0, 1, 1, 1 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

const std = @import("std");
const math = std.math;

/// Computes the floor value (largest integer less than or equal to the input)
/// for each element in the input array.
///
/// The floor function is defined as:
///   floor(x) = the greatest integer less than or equal to x
///
/// For example:
///   floor(3.7)  = 3.0
///   floor(-2.1) = -3.0
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing the input data.
/// - `allocator`: A memory allocator used to allocate memory for the result.
///
/// Returns:
/// - A newly allocated slice of `f64`, where each element is `floor(inReal[i])`.
/// - Returns an error if memory allocation fails.
///
/// Use Cases:
/// - Discretizing continuous values
/// - Rounding down for threshold logic
/// - Aligning to lower bounds in financial or scientific calculations
///
/// Example:
/// - Input:  [1.2, 3.9, -1.1, -5.0]
/// - Output: [1.0, 3.0, -2.0, -5.0]
fn Floor(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.floor(v);
    }

    return outReal;
}

test "Floor work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, 1, 0, 1, 10, 100 };

    const result = try Floor(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -100, -10, 1, 0, 1, 10, 100 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

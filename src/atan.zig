const std = @import("std");
const math = std.math;

/// Computes the arctangent (inverse tangent) of each element in the input array.
///
/// The arctangent function is defined as:
///   atan(x), where x ∈ ℝ
///
/// Parameters:
/// - `inReal`: A slice of f64 values representing the input data.
/// - `allocator`: A memory allocator used to allocate space for the output array.
///
/// Returns:
/// - A newly allocated slice of f64 values, where each value is atan(inReal[i]) in radians.
/// - Returns an error if memory allocation fails.
///
/// Mathematical Notes:
/// - atan(x) is the inverse of the tangent function.
/// - Domain:    x ∈ (-∞, ∞)
/// - Range:     atan(x) ∈ (-π/2, π/2)
///
/// Usage:
/// Useful in signal processing, trigonometric transformations, or phase analysis.
fn Atan(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.atan(v);
    }

    return outReal;
}

test "Atan work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -1, -0.1, -0.8, 0, 0.8, 0.10, 1.5 };

    const result = try Atan(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        -0.7853981633974483, -0.09966865249116204, -0.6747409422235526, 0, 0.6747409422235526, 0.09966865249116204, 0.982793723247329,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

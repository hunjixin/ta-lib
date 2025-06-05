const std = @import("std");
const math = std.math;

/// Computes the hyperbolic tangent (tanh) of each element in the input array.
///
/// The hyperbolic tangent function is defined as:
///   tanh(x) = (e^x - e^(-x)) / (e^x + e^(-x))
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing input numbers.
/// - `allocator`: A memory allocator used to allocate memory for the output.
///
/// Returns:
/// - A newly allocated slice of `f64` values where each element is tanh(inReal[i]).
///
/// Notes:
/// - The output values range from -1 to 1.
/// - Useful in neural networks, signal processing, and mathematical modeling.
///
/// Example:
/// - Input:  [-2.0, 0.0, 2.0]
/// - Output: [-0.964, 0.0, 0.964]
pub fn Tanh(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.tanh(v);
    }

    return outReal;
}

test "Tanh work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Tanh(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -1, -0.9999999958776927, -0.7615941559557649, 0, 0.7615941559557649, 0.9999999958776927, 1 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

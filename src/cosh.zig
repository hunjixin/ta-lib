const std = @import("std");
const math = std.math;

/// Computes the hyperbolic cosine of each element in the input array.
///
/// The hyperbolic cosine function is defined as:
///   cosh(x) = (e^x + e^(-x)) / 2
///
/// It describes the shape of a hanging cable or chain (catenary curve)
/// and is widely used in physics, engineering, and mathematical modeling
/// of exponential growth/decay phenomena.
///
/// Parameters:
/// - `inReal`: A slice of f64 values representing input values.
/// - `allocator`: A memory allocator used to allocate the output array.
///
/// Returns:
/// - A newly allocated slice of f64 values, where each element is cosh(inReal[i]).
/// - Returns an error if memory allocation fails.
///
/// Mathematical Properties:
/// - Domain: All real numbers
/// - Range: [1, ∞)
///
/// Example:
/// - Input:  [0.0, 1.0]
/// - Output: [1.0, (e^1 + e^(-1))/2 ≈ 1.5431]
///
/// Usage:
/// - Common in solving certain differential equations
/// - Describes energy functions in physics and neural networks
pub fn Cosh(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.cosh(v);
    }

    return outReal;
}

test "Cosh work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, 1, 0, 1, 10, 100 };

    const result = try Cosh(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 1.3440585709080678e+43, 11013.232920103324, 1.5430806348152437, 1, 1.5430806348152437, 11013.232920103324, 1.3440585709080678e+43 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

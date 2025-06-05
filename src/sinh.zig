const std = @import("std");
const math = std.math;

/// Computes the hyperbolic sine (sinh) of each element in the input array.
///
/// The hyperbolic sine function is defined as:
///   sinh(x) = (e^x - e^(-x)) / 2
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing input numbers.
/// - `allocator`: A memory allocator used to allocate memory for the output.
///
/// Returns:
/// - A newly allocated slice of `f64` values where each element is sinh(inReal[i]).
///
/// Use Cases:
/// - Hyperbolic function computations in mathematics and physics
/// - Modeling certain types of growth or decay processes
///
/// Example:
/// - Input:  [0.0, 1.0, -1.0]
/// - Output: [0.0, 1.1752011936438014, -1.1752011936438014]
pub fn Sinh(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.sinh(v);
    }

    return outReal;
}

test "Sinh work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Sinh(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -1.3440585709080678e+43, -11013.232874703393, -1.1752011936438014, 0, 1.1752011936438014, 11013.232874703393, 1.3440585709080678e+43 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

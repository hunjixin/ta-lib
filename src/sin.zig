const std = @import("std");
const math = std.math;

/// Computes the sine of each element in the input array.
///
/// The sine function is defined as:
///   sin(x) = the y-coordinate of the point on the unit circle at angle x (radians)
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing input angles in radians.
/// - `allocator`: A memory allocator used to allocate memory for the output.
///
/// Returns:
/// - A newly allocated slice of `f64` values where each element is sin(inReal[i]).
///
/// Use Cases:
/// - Signal processing
/// - Harmonic analysis
/// - Mathematical modeling involving periodic functions
///
/// Example:
/// - Input:  [0.0, π/2, π]
/// - Output: [0.0, 1.0, 0.0]
pub fn Sin(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.sin(v);
    }

    return outReal;
}

test "Sin work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Sin(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0.5063656411097588, 0.5440211108893699, -0.8414709848078965, 0, 0.8414709848078965, -0.5440211108893699, -0.5063656411097588 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

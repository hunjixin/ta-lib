const std = @import("std");
const math = std.math;

/// Computes the cosine of each element in the input array (in radians).
///
/// The cosine function returns the cosine of a given angle.
/// This function applies the cosine function to each element of the input slice.
///
/// Mathematically:
///   cos(x) = adjacent / hypotenuse  (in a right triangle)
///   Domain: All real numbers
///   Range: [-1, 1]
///
/// Parameters:
/// - `inReal`: A slice of f64 values representing angles in radians.
/// - `allocator`: A memory allocator used to allocate the output array.
///
/// Returns:
/// - A newly allocated slice of f64 values, where each element is cos(inReal[i]).
/// - Returns an error if memory allocation fails.
///
/// Example:
/// - Input:  [0.0, math.pi / 2, math.pi]
/// - Output: [1.0, 0.0, -1.0]
///
/// Usage:
/// Used in signal processing, cyclic pattern recognition, Fourier transforms,
/// and many mathematical or physical models.
fn Cos(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.cos(v);
    }

    return outReal;
}

test "Cos work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, 1, 0, 1, 10, 100 };

    const result = try Cos(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0.8623188722876839, -0.8390715290764524, 0.5403023058681398, 1, 0.5403023058681398, -0.8390715290764524, 0.8623188722876839 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

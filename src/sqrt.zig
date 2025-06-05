const std = @import("std");
const math = std.math;

/// Computes the square root (sqrt) of each element in the input array.
///
/// The square root function is defined as:
///   sqrt(x) = y, where y * y = x and y >= 0
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing input numbers (should be >= 0).
/// - `allocator`: A memory allocator used to allocate memory for the output.
///
/// Returns:
/// - A newly allocated slice of `f64` values where each element is sqrt(inReal[i]).
///
/// Notes:
/// - Input values less than zero will cause a NaN results.
///
/// Use Cases:
/// - Mathematical computations requiring square roots
/// - Financial calculations, signal processing, and physics simulations
///
/// Example:
/// - Input:  [0.0, 4.0, 9.0]
/// - Output: [0.0, 2.0, 3.0]
pub fn Sqrt(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.sqrt(v);
    }

    return outReal;
}

test "Sqrt work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ 0, 1, 10, 100 };

    const result = try Sqrt(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 1, 3.1622776601683795, 10 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

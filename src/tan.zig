const std = @import("std");
const math = std.math;

/// Computes the tangent (tan) of each element in the input array.
///
/// The tangent function is defined as:
///   tan(x) = sin(x) / cos(x)
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing input angles in radians.
/// - `allocator`: A memory allocator used to allocate memory for the output.
///
/// Returns:
/// - A newly allocated slice of `f64` values where each element is tan(inReal[i]).
///
/// Notes:
/// - Input angles near (π/2 + kπ), where cosine approaches zero, may produce very large or infinite values.
/// - Input is expected in radians.
///
/// Use Cases:
/// - Trigonometric calculations in geometry, physics, and signal processing.
///
/// Example:
/// - Input:  [0.0, π/4, π/2]
/// - Output: [0.0, 1.0, large value (or ±∞)]
fn Tan(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.tan(v);
    }

    return outReal;
}

test "Tan work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };

    const result = try Tan(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0.587213915156929, -0.6483608274590867, -1.557407724654902, 0, 1.557407724654902, 0.6483608274590867, -0.587213915156929 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

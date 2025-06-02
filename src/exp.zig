const std = @import("std");
const math = std.math;

/// Computes the exponential (base e) of each element in the input array.
///
/// The exponential function is defined as:
///   exp(x) = e^x
///
/// Where `e` is Euler’s number (approximately 2.71828). The function models continuous
/// growth and is widely used in finance, statistics, natural sciences, and engineering.
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing the input data.
/// - `allocator`: A memory allocator used to allocate memory for the result.
///
/// Returns:
/// - A newly allocated slice of `f64`, where each element is `exp(inReal[i])`.
/// - Returns an error if memory allocation fails.
///
/// Mathematical Properties:
/// - Domain: All real numbers
/// - Range: (0, ∞)
///
/// Example:
/// - Input:  [0.0, 1.0, 2.0]
/// - Output: [1.0, e ≈ 2.71828, e² ≈ 7.38906]
///
/// Applications:
/// - Modeling exponential growth or decay
/// - Compounding interest calculations
/// - Solving differential equations
fn Exp(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.exp(v);
    }

    return outReal;
}

test "Exp work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -100, -10, 1, 0, 1, 10, 100 };

    const result = try Exp(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 3.720075976020836e-44, 4.5399929762484854e-05, 2.718281828459045, 1, 2.718281828459045, 22026.465794806718, 2.6881171418161356e+43 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

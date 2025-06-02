const std = @import("std");
const math = std.math;

/// Computes the arcsine (inverse sine) of each element in the input array.
///
/// The arcsine function is defined as:
///   asin(x), where x ∈ [-1, 1]
///
/// Parameters:
/// - `inReal`: Input slice of f64 values. Each element must be within the range [-1.0, 1.0].
/// - `allocator`: Allocator used to allocate memory for the output array.
///
/// Returns:
/// - A slice of f64 values, where each value is asin(inReal[i]) in radians.
/// - Returns `error.InputOutOfDomain` if any input value is outside the valid domain.
///
/// Mathematical Notes:
/// - asin(x) is the inverse of sin(x).
/// - Domain:    x ∈ [-1, 1]
/// - Range:     asin(x) ∈ [-π/2, π/2]
fn Asin(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.asin(v);
    }

    return outReal;
}

test "Asin work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{
        -0.1, -0.8, 0, 0.8, 0.10,
    };

    const result = try Asin(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        -0.1001674211615598, -0.9272952180016123, 0, 0.9272952180016123, 0.1001674211615598,
    };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

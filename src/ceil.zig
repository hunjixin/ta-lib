const std = @import("std");
const math = std.math;

/// Computes the ceiling value of each element in the input array.
///
/// The ceiling of a number is the smallest integer that is greater than or equal to the number.
///
/// Mathematically:
///   ceil(x) = the smallest integer ≥ x
///
/// Parameters:
/// - `inReal`: A slice of f64 values representing the input data.
/// - `allocator`: A memory allocator used to allocate space for the output array.
///
/// Returns:
/// - A newly allocated slice of f64 values, where each value is ceil(inReal[i]).
/// - Returns an error if memory allocation fails.
///
/// Example:
/// - Input:  [1.2, 3.7, -2.1]
/// - Output: [2.0, 4.0, -2.0]
///
/// Usage:
/// Often used when rounding up values is needed, such as in financial modeling,
/// order size rounding, or time intervals.
fn Ceil(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.ceil(v);
    }

    return outReal;
}

test "Ceil work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ -1.5, -1, -0.1, -0.8, 0, 0.8, 0.10, 1.5 };

    const result = try Ceil(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -1, -1, 0, 0, 0, 1, 1, 2 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

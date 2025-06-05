const std = @import("std");
const math = std.math;

/// Computes the base-10 logarithm for each element in the input array.
///
/// The base-10 logarithm function is defined as:
///   log10(x) = log₁₀(x)
///
/// Note:
/// - The input value `x` must be greater than 0.
/// - log10(x) is undefined for x ≤ 0; an error or NaN may be returned for such values.
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing the input data. All values must be > 0.
/// - `allocator`: A memory allocator used to allocate memory for the result.
///
/// Returns:
/// - A newly allocated slice of `f64`, where each element is log10(inReal[i]).
/// - Returns an error if memory allocation fails.
///
/// Use Cases:
/// - Calculating logarithmic scales in scientific data
/// - Data normalization
/// - Financial computations such as decibel calculations
///
/// Example:
/// - Input:  [1.0, 10.0, 100.0]
/// - Output: [0.0, 1.0, 2.0]
pub fn Log10(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.log10(v);
    }

    return outReal;
}

test "Log10 work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ 0.1, 1, 10, 100 };

    const result = try Log10(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -0.9999999999999999, 0, 1, 2 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

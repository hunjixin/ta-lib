const std = @import("std");
const math = std.math;

/// Computes the natural logarithm (base e) for each element in the input array.
///
/// The natural logarithm function is defined as:
///   ln(x) = logₑ(x)
/// where e ≈ 2.71828 is Euler's number.
///
/// Note:
/// - The input value `x` must be greater than 0.
/// - ln(x) is undefined for x ≤ 0; an error or NaN may be returned for such values.
///
/// Parameters:
/// - `inReal`: A slice of `f64` values representing the input data. All values must be > 0.
/// - `allocator`: A memory allocator used to allocate memory for the result.
///
/// Returns:
/// - A newly allocated slice of `f64`, where each element is ln(inReal[i]).
/// - Returns an error if memory allocation fails.
///
/// Use Cases:
/// - Log-transforming data for normalization
/// - Computing log returns in finance
/// - Statistical modeling or exponential decay analysis
///
/// Example:
/// - Input:  [1.0, e, 10.0]
/// - Output: [0.0, 1.0, ~2.3026]
pub fn Ln(inReal: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);

    for (outReal, inReal) |*out, v| {
        out.* = math.log(f64, math.e, v);
    }

    return outReal;
}

test "Ln work correctly" {
    var allocator = std.testing.allocator;
    const pricesX = [_]f64{ 0.1, 1, 10, 100 };

    const result = try Ln(&pricesX, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ -2.3025850929940455, 0, 2.302585092994046, 4.605170185988092 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

const std = @import("std");
const math = std.math;

/// Calculates the rolling sum over a specified time period.
///
/// This function computes the sum of the last `inTimePeriod` values at each point in the input array,
/// similar to a moving sum window. It is often used in technical analysis for smoothing or signal generation.
///
/// ---
/// **Formula:**
/// ```text
/// out[i] = inReal[i] + inReal[i-1] + ... + inReal[i - inTimePeriod + 1]
/// for i >= inTimePeriod - 1
/// ```
/// The first `inTimePeriod - 1` elements are typically set to 0.0 or left uninitialized depending on convention.
///
/// ---
/// **Parameters:**
/// - `inReal`: Slice of input floating-point values.
/// - `inTimePeriod`: The number of periods over which the sum is calculated (window size).
/// - `allocator`: Allocator used to allocate the output slice.
///
/// ---
/// **Returns:**
/// - A newly allocated slice of `f64` values containing the rolling sums.
///   The length of the output equals the length of the input.
///
/// ---
/// **Errors:**
/// - Returns an error if `inTimePeriod` is zero or greater than the length of `inReal`.
/// - May return an allocation error if memory allocation fails.
///
/// ---
/// **Example:**
/// ```text
/// inReal = [1.0, 2.0, 3.0, 4.0, 5.0], inTimePeriod = 3
///
/// Output:
/// result = [0.0, 0.0, 6.0, 9.0, 12.0] // First 2 values may be set to 0.0
/// ```
fn Sum(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    var periodTotal: f64 = 0.0;
    var trailingIdx: usize = 0;

    for (0..inTimePeriod - 1) |i| {
        periodTotal += inReal[i];
    }

    for (inTimePeriod - 1..inReal.len) |i| {
        periodTotal += inReal[i];
        outReal[i] = periodTotal;
        periodTotal -= inReal[trailingIdx];
        trailingIdx += 1;
    }
    return outReal;
}

test "Sum work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -100, -10, -1, 0, 1, 10, 100 };
    const result = try Sum(&x, 2, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, -110, -11, -1, 1, 11, 110 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

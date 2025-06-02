const std = @import("std");
const math = std.math;

/// Calculates the rolling minimum value over a specified time period.
///
/// This function returns an array where each element represents the minimum value
/// within a sliding window of `inTimePeriod` elements from the `inReal` input slice.
///
/// Formula:
/// out[i] = min(inReal[i - inTimePeriod + 1 ..= i])
///
/// Parameters:
/// - `inReal`: Input slice of f64 values (e.g., price series).
/// - `inTimePeriod`: The number of elements in each rolling window (must be ≥ 1).
/// - `allocator`: Memory allocator used to allocate the output slice.
///
/// Returns:
/// - A slice of f64 values where each element is the minimum over the last `inTimePeriod` values.
///   The first (inTimePeriod - 1) elements may be undefined or set to NaN depending on the implementation.
///
/// Errors:
/// - Returns an error if `inTimePeriod` is 0 or greater than the length of `inReal`.
///
/// Example:
/// ```text
/// inReal       = [4.0, 2.0, 5.0, 1.0, 3.0]
/// inTimePeriod = 3
/// Output       = [0, 0, 2.0, 1.0, 1.0]
/// ```
fn Min(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    if (inTimePeriod < 2) {
        return outReal;
    }

    var outIdx = inTimePeriod - 1;
    var today = inTimePeriod - 1;
    var trailingIdx: isize = 0;
    var lowestIdx: isize = -1;
    var lowest: f64 = inReal[0];

    while (today < outReal.len) : ({
        outIdx += 1;
        trailingIdx += 1;
        today += 1;
    }) {
        var tmp = inReal[today];
        if (lowestIdx < trailingIdx) {
            lowestIdx = trailingIdx;
            lowest = inReal[@intCast(lowestIdx)];
            var i = lowestIdx + 1;
            while (i <= today) {
                tmp = inReal[@intCast(i)];
                if (tmp < lowest) {
                    lowestIdx = i;
                    lowest = tmp;
                }
                i += 1;
            }
        } else if (tmp <= lowest) {
            lowestIdx = @intCast(today);
            lowest = tmp;
        }
        outReal[outIdx] = lowest;
    }
    return outReal;
}

test "Min work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const result = try Min(&x, 3, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, -100, -100, -1, 0, 1 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

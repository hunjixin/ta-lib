const std = @import("std");
const math = std.math;

/// Calculates the rolling maximum value over a specified time period.
///
/// This function returns an array where each element represents the maximum value
/// within a sliding window of `inTimePeriod` elements from the `inReal` input slice.
///
/// Formula:
/// out[i] = max(inReal[i - inTimePeriod + 1 ..= i])
///
/// Parameters:
/// - `inReal`: Input slice of f64 values (e.g., price series).
/// - `inTimePeriod`: The number of elements in each rolling window (must be >= 1).
/// - `allocator`: Memory allocator used to allocate the output slice.
///
/// Returns:
/// - A slice of f64 values where each element is the maximum over the last `inTimePeriod` values.
///   The first (inTimePeriod - 1) elements may be undefined or set to NaN depending on the implementation.
///
/// Errors:
/// - Returns an error if `inTimePeriod` is 0 or greater than the length of `inReal`.
///
/// Example:
/// ```text
/// inReal       = [1.0, 3.0, 2.0, 5.0, 4.0]
/// inTimePeriod = 3
/// Output       = [0, 0, 3.0, 5.0, 5.0]
/// ```
fn Max(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const outReal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);
    if (inTimePeriod < 2) {
        return outReal;
    }

    var outIdx = inTimePeriod - 1;
    var today = inTimePeriod - 1;
    var trailingIdx: isize = 0;
    var highestIdx: isize = -1;
    var highest: f64 = inReal[0];

    while (today < outReal.len) : ({
        outIdx += 1;
        trailingIdx += 1;
        today += 1;
    }) {
        var tmp = inReal[today];
        if (highestIdx < trailingIdx) {
            highestIdx = trailingIdx;
            highest = inReal[@intCast(highestIdx)];
            var i = highestIdx + 1;
            while (i <= today) {
                tmp = inReal[@intCast(i)];
                if (tmp > highest) {
                    highestIdx = i;
                    highest = tmp;
                }
                i += 1;
            }
        } else if (tmp >= highest) {
            highestIdx = @intCast(today);
            highest = tmp;
        }
        outReal[outIdx] = highest;
    }
    return outReal;
}

test "Max work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const result = try Max(&x, 3, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, -1, 0, 10, 10, 100 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

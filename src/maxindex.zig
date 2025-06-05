const std = @import("std");
const math = std.math;

/// Calculates the index of the maximum value within a sliding window over a specified time period.
///
/// This function returns an array where each element contains the **zero-based offset** (relative to the start of the window)
/// of the maximum value within the last `inTimePeriod` values of the `inReal` input slice.
///
/// **Formula:**
/// out[i] = index of max(inReal[i - inTimePeriod + 1 ..= i]) relative to window start
///
/// **Parameters:**
/// - `inReal`: Input slice of f64 values (e.g., prices).
/// - `inTimePeriod`: Size of the sliding window; must be ≥ 1.
/// - `allocator`: Allocator used for memory allocation.
///
/// **Returns:**
/// - A slice of f64 values where each value is the index (offset) of the maximum value within the window.
///   The index is always within the range [0, inTimePeriod - 1].
///   The first (inTimePeriod - 1) elements may be set to 0.
///
/// **Errors:**
/// - Returns an error if `inTimePeriod` is 0 or greater than the length of `inReal`.
///
/// **Example:**
/// ```text
/// inReal       = [1.0, 3.0, 2.0, 5.0, 4.0]
/// inTimePeriod = 3
/// Output       = [0, 0, 1.0, 3.0, 3.0]
///
/// Explanation:
/// - At i=2: window = [1.0, 3.0, 2.0] → max=3.0 at index 1
/// - At i=3: window = [3.0, 2.0, 5.0] → max=5.0 at index 3
/// - At i=4: window = [2.0, 5.0, 4.0] → max=5.0 at index 3
/// ```
pub fn MaxIndex(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
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
        outReal[outIdx] = @as(f64, @floatFromInt(highestIdx));
    }
    return outReal;
}

test "Max work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const result = try MaxIndex(&x, 3, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 2, 3, 4, 4, 6 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

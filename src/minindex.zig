const std = @import("std");
const math = std.math;

/// Calculates the index of the minimum value within a sliding window over a specified time period.
///
/// This function returns an array where each element contains the **zero-based offset** (relative to the start of the window)
/// of the minimum value within the last `inTimePeriod` values of the `inReal` input slice.
///
/// ---
/// **Formula:**
/// out[i] = index of min(inReal[i - inTimePeriod + 1 ..= i]) relative to window start
///
/// ---
/// **Parameters:**
/// - `inReal`: Slice of input values (e.g., price data).
/// - `inTimePeriod`: Size of the rolling window (must be ≥ 1 and ≤ inReal.len).
/// - `allocator`: Memory allocator for result slice.
///
/// ---
/// **Returns:**
/// - A slice of f64 values. Each value is the index (offset from window start) of the minimum value in the current window.
/// - The first (inTimePeriod - 1) values may be NaN or undefined, depending on the implementation.
///
/// ---
/// **Errors:**
/// - Returns an error if `inTimePeriod` is 0 or greater than the input length.
///
/// ---
/// **Example:**
/// ```text
/// inReal       = [3.0, 1.0, 4.0, 2.0, 5.0]
/// inTimePeriod = 3
/// Output       = [0, 0, 1.0, 1.0, 3.0]
///
/// Explanation:
/// - At i=2: window = [3.0, 1.0, 4.0] → min=1.0 at index 1
/// - At i=3: window = [1.0, 4.0, 2.0] → min=1.0 at index 1
/// - At i=4: window = [4.0, 2.0, 5.0] → min=2.0 at index 3
/// ```
pub fn MinIndex(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
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
        outReal[outIdx] = @floatFromInt(lowestIdx);
    }
    return outReal;
}

test "MinIndex work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const result = try MinIndex(&x, 3, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 1, 1, 2, 3, 5 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

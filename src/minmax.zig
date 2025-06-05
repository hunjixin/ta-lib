const std = @import("std");

/// Calculates the minimum and maximum values over a sliding window of a specified time period.
///
/// This function returns two arrays: one containing the minimum values, and the other containing the maximum values,
/// for each position of a moving window of length `inTimePeriod` over the `inReal` input slice.
///
/// ---
/// **Formula:**
/// Let `x[i]` be the input value at index `i`.
/// For each index `i ≥ inTimePeriod - 1`:
/// - `min_out[i] = min(x[i - inTimePeriod + 1 ..= i])`
/// - `max_out[i] = max(x[i - inTimePeriod + 1 ..= i])`
///
/// For `i < inTimePeriod - 1`, output values may be NaN or implementation-defined.
///
/// ---
/// **Parameters:**
/// - `inReal`: Input slice of real numbers (e.g., price data).
/// - `inTimePeriod`: Number of periods for the moving window (must be ≥ 1 and ≤ inReal.len).
/// - `allocator`: Memory allocator used to allocate result arrays.
///
/// ---
/// **Returns:**
/// - A struct containing two slices:
///   - `[]f64`: Minimum values within each window.
///   - `[]f64`: Maximum values within each window.
///
/// ---
/// **Errors:**
/// - Returns an error if `inTimePeriod` is zero or greater than `inReal.len`.
///
/// ---
/// **Example:**
/// ```text
/// inReal       = [3.0, 1.0, 4.0, 2.0, 5.0]
/// inTimePeriod = 3
///
/// Output:
/// min_out = [0, 0, 1.0, 1.0, 2.0]
/// max_out = [0, 0, 4.0, 4.0, 5.0]
///
/// Explanation:
/// - At i=2: window = [3.0, 1.0, 4.0] → min=1.0, max=4.0
/// - At i=3: window = [1.0, 4.0, 2.0] → min=1.0, max=4.0
/// - At i=4: window = [4.0, 2.0, 5.0] → min=2.0, max=5.0
/// ```
pub fn MinMax(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) !struct { []f64, []f64 } {
    // Allocate output arrays
    const outMin = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outMin);
    const outMax = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outMax);
    @memset(outMin, 0);
    @memset(outMax, 0);
    // Handle edge cases
    if (inTimePeriod < 1 or inReal.len == 0) {
        return .{ outMin, outMax };
    }

    const nbInitialElementNeeded = inTimePeriod - 1;
    const startIdx = nbInitialElementNeeded;

    var outIdx: usize = startIdx;
    var today: usize = startIdx;
    var trailingIdx: usize = 0;

    var highestIdx: usize = 0;
    var highest: f64 = 0.0;
    var lowestIdx: usize = 0;
    var lowest: f64 = 0.0;

    // Initialize first window
    if (startIdx < inReal.len) {
        highest = inReal[trailingIdx];
        lowest = inReal[trailingIdx];

        for (trailingIdx + 1..today + 1) |i| {
            const val = inReal[i];
            if (val > highest) {
                highest = val;
                highestIdx = i;
            }
            if (val < lowest) {
                lowest = val;
                lowestIdx = i;
            }
        }

        outMin[outIdx] = lowest;
        outMax[outIdx] = highest;
        outIdx += 1;
        today += 1;
        trailingIdx += 1;
    }

    // Process subsequent elements
    while (today < inReal.len) {
        const tmpLow = inReal[today];
        const tmpHigh = inReal[today];

        // Update maximum
        if (highestIdx < trailingIdx) {
            // Recalculate maximum in new window
            highest = tmpHigh;
            highestIdx = today;
            var i = trailingIdx;
            while (i <= today) : (i += 1) {
                const val = inReal[i];
                if (val > highest) {
                    highest = val;
                    highestIdx = i;
                }
            }
        } else if (tmpHigh >= highest) {
            // Extend current maximum
            highest = tmpHigh;
            highestIdx = today;
        }

        // Update minimum
        if (lowestIdx < trailingIdx) {
            // Recalculate minimum in new window
            lowest = tmpLow;
            lowestIdx = today;
            var i = trailingIdx;
            while (i <= today) : (i += 1) {
                const val = inReal[i];
                if (val < lowest) {
                    lowest = val;
                    lowestIdx = i;
                }
            }
        } else if (tmpLow <= lowest) {
            // Extend current minimum
            lowest = tmpLow;
            lowestIdx = today;
        }

        outMax[outIdx] = highest;
        outMin[outIdx] = lowest;

        // Move window forward
        outIdx += 1;
        today += 1;
        trailingIdx += 1;
    }

    return .{ outMin, outMax };
}

test "MinMax work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const min, const max = try MinMax(&x, 3, allocator);
    defer allocator.free(min);
    defer allocator.free(max);

    {
        const expected = [_]f64{ 0, 0, -100, -100, -1, 0, 1 };
        for (min, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
    {
        const expected = [_]f64{ 0, 0, -1, 0, 10, 10, 100 };
        for (max, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
}

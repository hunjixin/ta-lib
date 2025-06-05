const std = @import("std");

/// Calculates the indices of the minimum and maximum values over a sliding window.
///
/// This function returns two arrays:
/// - The first array contains the **index offset** of the minimum value within each moving window.
/// - The second array contains the **index offset** of the maximum value within each moving window.
///
/// The index is relative to the beginning of each window (not absolute in the input slice).
///
/// ---
/// **Formula:**
/// Let `x[i]` be the input value at index `i`.
/// For each index `i ≥ inTimePeriod - 1`:
/// - `min_index[i] = argmin(x[i - inTimePeriod + 1 ..= i])`
/// - `max_index[i] = argmax(x[i - inTimePeriod + 1 ..= i])`
///
/// For indices where `i < inTimePeriod - 1`, the values can be set as NaN or a sentinel value.
///
/// ---
/// **Parameters:**
/// - `inReal`: Input slice of real values (e.g., price data).
/// - `inTimePeriod`: The window size (must be ≥ 1 and ≤ `inReal.len()`).
/// - `allocator`: Memory allocator for output slices.
///
/// ---
/// **Returns:**
/// - A struct with two fields:
///   - `[]f64`: The relative indices of minimum values in each window.
///   - `[]f64`: The relative indices of maximum values in each window.
///
/// ---
/// **Example:**
/// ```text
/// inReal       = [3.0, 1.0, 4.0, 2.0, 5.0]
/// inTimePeriod = 3
///
/// Windows:
///   [3.0, 1.0, 4.0] → min_index = 1 (value 1.0), max_index = 2 (value 4.0)
///   [1.0, 4.0, 2.0] → min_index = 1 (value 1.0), max_index = 1 (value 4.0)
///   [4.0, 2.0, 5.0] → min_index = 3 (value 2.0), max_index = 4 (value 5.0)
///
/// Output:
/// min_index = [0, 0, 1.0, 1.0, 3.0]
/// max_index = [0, 0, 2.0, 1.0, 4.0]
/// ```
pub fn MinMaxIndex(inReal: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) !struct { []f64, []f64 } {
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

        outMin[outIdx] = @floatFromInt(lowestIdx);
        outMax[outIdx] = @floatFromInt(highestIdx);
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

        outMin[outIdx] = @floatFromInt(lowestIdx);
        outMax[outIdx] = @floatFromInt(highestIdx);

        // Move window forward
        outIdx += 1;
        today += 1;
        trailingIdx += 1;
    }

    return .{ outMin, outMax };
}

test "MinMaxIndex work correctly" {
    var allocator = std.testing.allocator;
    const x = [_]f64{ -10, -100, -1, 0, 10, 1, 100 };

    const min, const max = try MinMaxIndex(&x, 3, allocator);
    defer allocator.free(min);
    defer allocator.free(max);

    {
        const expected = [_]f64{ 0, 0, 1, 1, 2, 3, 5 };
        for (min, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
    {
        const expected = [_]f64{ 0, 0, 2, 3, 4, 4, 6 };
        for (max, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
        }
    }
}

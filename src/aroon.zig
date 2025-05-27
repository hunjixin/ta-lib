const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;

/// Calculates the Aroon Up and Aroon Down indicators for a given data frame.
///
/// The Aroon indicator is a technical analysis tool used to identify the strength and direction of a trend.
/// It consists of two lines: Aroon Up and Aroon Down, which measure the number of periods since the highest high and lowest low, respectively, over a specified time period.
///
/// Formula:
///   Aroon Up = ((inTimePeriod - periodsSinceHighestHigh) / inTimePeriod) * 100
///   Aroon Down = ((inTimePeriod - periodsSinceLowestLow) / inTimePeriod) * 100
///
/// Parameters:
///   - df: Pointer to a DataFrame containing f64 values (typically price data).
///   - inTimePeriod: The lookback period for the Aroon calculation.
///   - allocator: Memory allocator to use for result arrays.
///
/// Returns:
///   A struct containing two slices of f64:
///     - The first slice is the Aroon Up values.
///     - The second slice is the Aroon Down values.
///
/// Errors:
///   Returns an error if memory allocation fails or if input parameters are invalid.
pub fn Aroon(
    df: *const DataFrame(f64),
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) !struct { []f64, []f64 } {
    const inHigh = try df.getColumnData("high");
    const inLow = try df.getColumnData("low");

    const len = inHigh.len;
    if (len != inLow.len) return error.InvalidInput;

    var outAroonUp = try allocator.alloc(f64, len);
    var outAroonDown = try allocator.alloc(f64, len);

    // Initialize outputs to zero
    @memset(outAroonUp, 0);
    @memset(outAroonDown, 0);

    const startIdx: usize = inTimePeriod;
    var outIdx: usize = startIdx;
    var today: usize = startIdx;
    var trailingIdx: usize = startIdx - inTimePeriod;
    var lowestIdx: usize = 0;
    var highestIdx: usize = 0;
    var lowest: f64 = 0.0;
    var highest: f64 = 0.0;
    var lowest_valid = false;
    var highest_valid = false;
    const factor = 100.0 / @as(f64, @floatFromInt(inTimePeriod));

    while (today < len) {
        var tmp = inLow[today];
        if (!lowest_valid or lowestIdx < trailingIdx) {
            lowestIdx = trailingIdx;
            lowest = inLow[lowestIdx];
            var i = trailingIdx + 1;
            while (i <= today) : (i += 1) {
                tmp = inLow[i];
                if (tmp <= lowest) {
                    lowestIdx = i;
                    lowest = tmp;
                }
            }
            lowest_valid = true;
        } else if (tmp <= lowest) {
            lowestIdx = today;
            lowest = tmp;
        }

        tmp = inHigh[today];
        if (!highest_valid or highestIdx < trailingIdx) {
            highestIdx = trailingIdx;
            highest = inHigh[highestIdx];
            var i = trailingIdx + 1;
            while (i <= today) : (i += 1) {
                tmp = inHigh[i];
                if (tmp >= highest) {
                    highestIdx = i;
                    highest = tmp;
                }
            }
            highest_valid = true;
        } else if (tmp >= highest) {
            highestIdx = today;
            highest = tmp;
        }

        outAroonUp[outIdx] = factor * @as(f64, @floatFromInt(inTimePeriod - (today - highestIdx)));
        outAroonDown[outIdx] = factor * @as(f64, @floatFromInt(inTimePeriod - (today - lowestIdx)));
        outIdx += 1;
        trailingIdx += 1;
        today += 1;
    }

    return .{ outAroonDown, outAroonUp };
}

test "Aroon computes  correctly" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    try df.addColumnWithData("high", &[_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19, 21, 23, 22, 25, 24, 27, 29, 28, 30, 32, 31, 35, 34, 36, 38 });
    try df.addColumnWithData("low", &[_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17, 18, 19, 18, 20, 21, 22, 24, 23, 25, 26, 27, 28, 29, 30, 31 });

    const down, const up = try Aroon(&df, 5, gpa);
    defer gpa.free(up);
    defer gpa.free(down);

    {
        const expected = [_]f64{ 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 20.000000000, 0.000000000, 0.000000000, 40.000000000, 20.000000000, 0.000000000, 20.000000000, 0.000000000, 0.000000000, 20.000000000, 0.000000000, 20.000000000, 0.000000000, 0.000000000, 40.000000000, 20.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 20.000000000, 0.000000000, 0.000000000, 0.000000000 };
        for (expected, 0..) |exp, i| {
            try std.testing.expectApproxEqAbs(down[i], exp, 1e-9);
        }
    }
    {
        const expected = [_]f64{ 0, 0, 0, 0, 0, 100, 80, 100, 80, 100, 80, 60, 40, 20, 0, 100, 100, 80, 100, 80, 100, 100, 80, 100, 100, 80, 100, 80, 100, 100 };
        for (expected, 0..) |exp, i| {
            try std.testing.expectApproxEqAbs(up[i], exp, 1e-9);
        }
    }
}

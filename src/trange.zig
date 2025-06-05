const std = @import("std");

/// Calculates the True Range (TRANGE) indicator.
///
/// TRANGE measures the largest price range over a period by considering:
///     TR = max(
///         high - low,
///         abs(high - previous_close),
///         abs(low - previous_close)
///     )
///
/// Inputs:
/// - `high`: array of high prices
/// - `low`: array of low prices
/// - `close`: array of close prices
/// - `allocator`: memory allocator
///
/// Output:
/// - TRANGE values as a dynamically allocated slice of f64
///
/// Note:
/// - The first value of TR is high[0] - low[0] (no previous close).
pub fn TRange(
    inHigh: []const f64,
    inLow: []const f64,
    inClose: []const f64,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = inHigh.len;
    var outReal = try allocator.alloc(f64, len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    var outIdx: usize = 1;
    var today: usize = 1;
    while (today < len) : ({
        outIdx += 1;
        today += 1;
    }) {
        const tempLT = inLow[today];
        const tempHT = inHigh[today];
        const tempCY = inClose[today - 1];
        var greatest = tempHT - tempLT;
        const val2 = @abs(tempCY - tempHT);
        if (val2 > greatest) {
            greatest = val2;
        }
        const val3 = @abs(tempCY - tempLT);
        if (val3 > greatest) {
            greatest = val3;
        }
        outReal[outIdx] = greatest;
    }

    return outReal;
}

test "TRange basic test" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 13.27, 15.84, 11.46, 16.92, 14.15, 10.58, 18.33, 12.71, 17.49, 9.94, 19.02, 11.88, 13.63, 14.91, 16.47, 12.39, 15.02, 10.73, 17.76, 13.05 };
    const lows = [_]f64{ 11.12, 13.91, 10.08, 15.44, 12.77, 9.86, 16.50, 11.62, 15.88, 8.94, 17.11, 10.55, 12.41, 13.59, 14.89, 10.94, 13.31, 9.21, 15.61, 11.82 };
    const closes = [_]f64{ 12.20, 14.65, 10.90, 16.30, 13.60, 10.15, 17.40, 12.10, 16.73, 9.40, 18.15, 11.11, 13.02, 14.20, 15.69, 11.60, 14.30, 10.01, 16.80, 12.51 };

    const result = try TRange(
        &highs,
        &lows,
        &closes,
        allocator,
    );
    defer allocator.free(result);

    const expected = [_]f64{ 0, 3.6400000000000006, 4.57, 6.020000000000001, 3.530000000000001, 3.74, 8.179999999999998, 5.779999999999999, 5.389999999999999, 7.790000000000001, 9.62, 7.599999999999998, 2.5200000000000014, 1.8900000000000006, 2.2699999999999996, 4.75, 3.42, 5.09, 7.750000000000002, 4.98 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

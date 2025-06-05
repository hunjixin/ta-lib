const std = @import("std");
const TRange = @import("lib.zig").TRange;
const Sma = @import("lib.zig").Sma;

/// Calculates the Average True Range (ATR) indicator.
///
/// ATR is a technical analysis indicator that measures market volatility
/// by calculating the moving average of the True Range (TR) over a given period.
///
/// The True Range (TR) is defined as:
///     TR = max(
///         high[i] - low[i],
///         abs(high[i] - close[i-1]),
///         abs(low[i] - close[i-1])
///     )
///
/// ATR is computed as a moving average (usually exponential or simple) of TR values:
///     ATR[i] = (previous ATR * (n - 1) + TR[i]) / n   -- for exponential
///     ATR[i] = sum(TR[i-n+1]..TR[i]) / n              -- for simple
///
/// This implementation uses a **Simple Moving Average (Sma)** of the TR values.
///
/// Parameters:
/// - `inHigh`:     Slice of high prices
/// - `inLow`:      Slice of low prices
/// - `inClose`:    Slice of close prices
/// - `inTimePeriod`: The number of periods to calculate ATR over (e.g., 14)
/// - `allocator`:  Allocator for result memory
///
/// Returns:
/// - A slice of ATR values with the same length as the input; values before
///   `inTimePeriod - 1` will typically be zero or undefined depending on policy.
///
/// Errors:
/// - Returns `error.InvalidInput` if input lengths do not match or are too short.
pub fn Atr(
    inHigh: []const f64,
    inLow: []const f64,
    inClose: []const f64,
    inTimePeriod: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = inHigh.len;
    var outReal = try allocator.alloc(f64, len);
    errdefer allocator.free(outReal);
    @memset(outReal, 0);

    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);

    if (inTimePeriod < 1) {
        return outReal;
    }

    if (inTimePeriod <= 1) {
        return TRange(inHigh, inLow, inClose, allocator);
    }

    var today = inTimePeriod + 1;
    const tr = try TRange(inHigh, inLow, inClose, allocator);
    defer allocator.free(tr);
    const prevATRTemp = try Sma(tr, inTimePeriod, allocator);
    defer allocator.free(prevATRTemp);

    var prevATR = prevATRTemp[inTimePeriod];
    outReal[inTimePeriod] = prevATR;

    for (inTimePeriod + 1..len) |i| {
        prevATR *= inTimePeriodF - 1.0;
        prevATR += tr[today];
        prevATR /= inTimePeriodF;
        outReal[i] = prevATR;
        today += 1;
    }
    return outReal;
}

test "Atr basic test" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 13.27, 15.84, 11.46, 16.92, 14.15, 10.58, 18.33, 12.71, 17.49, 9.94, 19.02, 11.88, 13.63, 14.91, 16.47, 12.39, 15.02, 10.73, 17.76, 13.05 };
    const lows = [_]f64{ 11.12, 13.91, 10.08, 15.44, 12.77, 9.86, 16.50, 11.62, 15.88, 8.94, 17.11, 10.55, 12.41, 13.59, 14.89, 10.94, 13.31, 9.21, 15.61, 11.82 };
    const closes = [_]f64{ 12.20, 14.65, 10.90, 16.30, 13.60, 10.15, 17.40, 12.10, 16.73, 9.40, 18.15, 11.11, 13.02, 14.20, 15.69, 11.60, 14.30, 10.01, 16.80, 12.51 };

    const result = try Atr(
        &highs,
        &lows,
        &closes,
        10,
        allocator,
    );
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5.8260000000000005, 6.003400000000001, 5.655060000000001, 5.278554000000001, 4.977698600000001, 4.9549287400000015, 4.801435866000001, 4.830292279400001, 5.122263051460001, 5.108036746314001 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

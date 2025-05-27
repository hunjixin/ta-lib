const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const DataFrame = @import("./lib.zig").DataFrame;

/// Calculates the Minus Directional Movement (MinusDM) indicator for a given DataFrame of f64 values.
///
/// The MinusDM is a technical analysis indicator used to measure the downward price movement
/// over a specified period. It is commonly used in the Average Directional Index (ADX) calculation.
///
/// Formula:
///   MinusDM = Current Low - Previous Low, if (Previous High - Current High) < (Previous Low - Current Low) and (Previous Low - Current Low) > 0
///   Otherwise, MinusDM = 0
///
/// Parameters:
/// - df: Pointer to a DataFrame containing the input data (typically OHLC data).
/// - inTimePeriod: The period over which to calculate the MinusDM.
/// - allocator: Memory allocator for the output array.
///
/// Returns:
/// - An array of f64 values representing the MinusDM for each period.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input data is invalid.
pub fn MinusDm(df: *const DataFrame(f64), inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const inHigh = try df.getColumnData("high");
    const inLow = try df.getColumnData("low");
    const len = inHigh.len;
    var outReal = try allocator.alloc(f64, len);
    if (len == 0) return outReal;

    const inTimePeriodF: f64 = @floatFromInt(inTimePeriod);
    var lookbackTotal: usize = 1;
    if (inTimePeriod > 1) {
        lookbackTotal = inTimePeriod - 1;
    }
    const startIdx = lookbackTotal;
    var outIdx = startIdx;
    var today = startIdx;
    var prevHigh: f64 = 0.0;
    var prevLow: f64 = 0.0;

    if (inTimePeriod <= 1) {
        if (startIdx == 0) return outReal;
        today = startIdx - 1;
        prevHigh = inHigh[today];
        prevLow = inLow[today];
        while (today < len - 1) : (today += 1) {
            const tempHigh = inHigh[today + 1];
            const diffP = tempHigh - prevHigh;
            prevHigh = tempHigh;
            const tempLow = inLow[today + 1];
            const diffM = prevLow - tempLow;
            prevLow = tempLow;
            if (diffM > 0 and diffP < diffM) {
                outReal[outIdx] = diffM;
            } else {
                outReal[outIdx] = 0;
            }
            outIdx += 1;
        }
        return outReal;
    }

    var prevMinusDM: f64 = 0.0;
    today = startIdx - lookbackTotal;
    prevHigh = inHigh[today];
    prevLow = inLow[today];
    var i = inTimePeriod - 1;
    while (i > 0) : (i -= 1) {
        today += 1;
        const tempHigh = inHigh[today];
        const diffP = tempHigh - prevHigh;
        prevHigh = tempHigh;
        const tempLow = inLow[today];
        const diffM = prevLow - tempLow;
        prevLow = tempLow;
        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        }
    }

    // No warmup loop in original, so skip i = 0 loop
    outReal[startIdx] = prevMinusDM;
    outIdx = startIdx + 1;
    while (today < len - 1) : (today += 1) {
        const tempHigh = inHigh[today + 1];
        const diffP = tempHigh - prevHigh;
        prevHigh = tempHigh;
        const tempLow = inLow[today + 1];
        const diffM = prevLow - tempLow;
        prevLow = tempLow;
        if (diffM > 0 and diffP < diffM) {
            prevMinusDM = prevMinusDM - (prevMinusDM / inTimePeriodF) + diffM;
        } else {
            prevMinusDM = prevMinusDM - (prevMinusDM / inTimePeriodF);
        }
        outReal[outIdx] = prevMinusDM;
        outIdx += 1;
    }
    return outReal;
}

test "MinusDm calculation with valid input" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);

    const result = try MinusDm(&df, 4, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, highs.len);
    const expect = [_]f64{
        0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 0.000000000, 85.000000000, 63.750000000, 47.812500000, 35.859375000,
    };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}

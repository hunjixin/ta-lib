const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;

/// Calculate the Average Directional Index (ADX) for a given DataFrame.
///
/// The ADX is a technical analysis indicator used to quantify trend strength.
/// It is based on the Directional Movement Index (DMI), which consists of +DI and -DI.
/// The ADX is the smoothed moving average of the DX (Directional Movement Index).
///
/// Formula references:
/// - True Range (TR):
///     TR = max(high - low, abs(high - prev_close), abs(low - prev_close))
/// - +DM (Plus Directional Movement):
///     +DM = high - prev_high, if (high - prev_high) > (prev_low - low) and > 0, else 0
/// - -DM (Minus Directional Movement):
///     -DM = prev_low - low, if (prev_low - low) > (high - prev_high) and > 0, else 0
/// - Smoothed values (Wilder's smoothing):
///     smoothed_DM = previous_smoothed_DM - (previous_smoothed_DM / period) + current_DM
///     smoothed_TR = previous_smoothed_TR - (previous_smoothed_TR / period) + current_TR
/// - +DI = 100 * (smoothed +DM / smoothed TR)
/// - -DI = 100 * (smoothed -DM / smoothed TR)
/// - DX = 100 * abs(+DI - -DI) / (+DI + -DI)
/// - ADX = (previous_ADX * (period - 1) + current_DX) / period
///
/// Parameters:
/// - df: DataFrame containing "high", "low", and "close" columns
/// - period: lookback period for smoothing (commonly 14)
/// - allocator: memory allocator
///
/// Returns:
/// - Array of ADX values (length equals input data)
pub fn ADX(df: *const DataFrame(f64), period: usize, allocator: std.mem.Allocator) ![]f64 {
    const n = df.getRowCount();
    var out = try allocator.alloc(f64, n);
    @memset(out, 0);
    if (n == 0 or period < 2) return out;

    const inHigh = try df.getColumnData("high");
    const inLow = try df.getColumnData("low");
    const inClose = try df.getColumnData("close");

    const inTimePeriodF = @as(f64, @floatFromInt(period));
    const lookbackTotal = (2 * period) - 1;
    var outIdx: usize = period;
    var prevMinusDM: f64 = 0.0;
    var prevPlusDM: f64 = 0.0;
    var prevTR: f64 = 0.0;
    var today: usize = 0;
    var prevHigh = inHigh[0];
    var prevLow = inLow[0];
    var prevClose = inClose[0];

    // First period
    var i = period - 1;
    while (i > 0) : (i -= 1) {
        today += 1;
        var tempReal = inHigh[today];
        const diffP = tempReal - prevHigh;
        prevHigh = tempReal;
        tempReal = inLow[today];
        const diffM = prevLow - tempReal;
        prevLow = tempReal;
        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        } else if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }
        tempReal = prevHigh - prevLow;
        var tempReal2 = @abs(prevHigh - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        tempReal2 = @abs(prevLow - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        prevTR += tempReal;
        prevClose = inClose[today];
    }

    // Second period
    var sumDX: f64 = 0.0;
    i = period;
    while (i > 0) : (i -= 1) {
        today += 1;
        var tempReal = inHigh[today];
        const diffP = tempReal - prevHigh;
        prevHigh = tempReal;
        tempReal = inLow[today];
        const diffM = prevLow - tempReal;
        prevLow = tempReal;
        prevMinusDM -= prevMinusDM / inTimePeriodF;
        prevPlusDM -= prevPlusDM / inTimePeriodF;
        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        } else if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }
        tempReal = prevHigh - prevLow;
        var tempReal2 = @abs(prevHigh - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        tempReal2 = @abs(prevLow - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        prevTR = prevTR - (prevTR / inTimePeriodF) + tempReal;
        prevClose = inClose[today];
        if (!(prevTR > -1e-14 and prevTR < 1e-14)) {
            const minusDI = 100.0 * (prevMinusDM / prevTR);
            const plusDI = 100.0 * (prevPlusDM / prevTR);
            tempReal = minusDI + plusDI;
            if (!(tempReal > -1e-14 and tempReal < 1e-14)) {
                sumDX += 100.0 * (@abs(minusDI - plusDI) / tempReal);
            }
        }
    }
    var prevADX = sumDX / inTimePeriodF;
    if (lookbackTotal < n) out[lookbackTotal] = prevADX;
    outIdx = lookbackTotal + 1;
    today += 1;

    while (today < n) : (today += 1) {
        var tempReal = inHigh[today];
        const diffP = tempReal - prevHigh;
        prevHigh = tempReal;
        tempReal = inLow[today];
        const diffM = prevLow - tempReal;
        prevLow = tempReal;
        prevMinusDM -= prevMinusDM / inTimePeriodF;
        prevPlusDM -= prevPlusDM / inTimePeriodF;
        if (diffM > 0 and diffP < diffM) {
            prevMinusDM += diffM;
        } else if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }
        tempReal = prevHigh - prevLow;
        var tempReal2 = @abs(prevHigh - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        tempReal2 = @abs(prevLow - prevClose);
        if (tempReal2 > tempReal) tempReal = tempReal2;
        prevTR = prevTR - (prevTR / inTimePeriodF) + tempReal;
        prevClose = inClose[today];
        if (!(prevTR > -1e-14 and prevTR < 1e-14)) {
            const minusDI = 100.0 * (prevMinusDM / prevTR);
            const plusDI = 100.0 * (prevPlusDM / prevTR);
            tempReal = minusDI + plusDI;
            if (!(tempReal > -1e-14 and tempReal < 1e-14)) {
                tempReal = 100.0 * (@abs(minusDI - plusDI) / tempReal);
                prevADX = ((prevADX * (inTimePeriodF - 1)) + tempReal) / inTimePeriodF;
            }
        }
        if (outIdx < n) out[outIdx] = prevADX;
        outIdx += 1;
    }
    return out;
}

test "ADX computes expected values for simple data" {
    var allocator = std.testing.allocator;

    // Prepare simple test data
    const highs = [_]f64{ 30, 32, 31, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44 };
    const lows = [_]f64{ 28, 29, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41 };
    const closes = [_]f64{ 29, 31, 30, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43 };

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);
    try df.addColumnWithData("close", closes[0..]);

    const period = 5;
    const adx = try ADX(&df, period, allocator);
    defer allocator.free(adx);
    const expected = [_]f64{ 0e0, 0e0, 0e0, 0e0, 0e0, 0e0, 0e0, 0e0, 0e0, 1e2, 1e2, 1e2, 1e2, 1e2, 1e2 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-6);
    }
}

test "ADX handles trend reversals and choppy data" {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);
    try df.addColumnWithData("close", closes[0..]);

    const period = 5;
    const adx = try ADX(&df, period, allocator);
    defer allocator.free(adx);

    std.debug.print("ADX: {any}\n", .{adx});

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 100, 83.9503740135489, 70.6961927443363, 60.09284772896624, 50.99050951446177 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}

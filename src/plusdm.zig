const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const DataFrame = @import("./lib.zig").DataFrame;

/// Calculates the Plus Directional Movement (+DM) indicator for a given DataFrame of f64 values.
///
/// The Plus Directional Movement is a component of the Directional Movement System (DMS) used in technical analysis.
/// Formula:
///   +DM = current_high - previous_high, if (current_high - previous_high) > (previous_low - current_low) and (current_high - previous_high) > 0; otherwise, +DM = 0
///
/// Parameters:
/// - df: Pointer to a DataFrame containing f64 values representing the price data (typically high, low, close columns).
/// - inTimePeriod: The period over which to calculate the indicator.
/// - allocator: Allocator used for memory management.
///
/// Returns:
/// - An array of f64 values representing the calculated +DM values for each period.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input parameters are invalid.
pub fn PlusDM(df: *const DataFrame(f64), inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
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
            if (diffP > 0 and diffP > diffM) {
                outReal[outIdx] = diffP;
            } else {
                outReal[outIdx] = 0;
            }
            outIdx += 1;
        }
        return outReal;
    }

    var prevPlusDM: f64 = 0.0;
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
        if (diffP > 0 and diffP > diffM) {
            prevPlusDM += diffP;
        }
    }

    outReal[startIdx] = prevPlusDM;
    outIdx = startIdx + 1;
    while (today < len - 1) : (today += 1) {
        const tempHigh = inHigh[today + 1];
        const diffP = tempHigh - prevHigh;
        prevHigh = tempHigh;
        const tempLow = inLow[today + 1];
        const diffM = prevLow - tempLow;
        prevLow = tempLow;
        if (diffP > 0 and diffP > diffM) {
            prevPlusDM = prevPlusDM - (prevPlusDM / inTimePeriodF) + diffP;
        } else {
            prevPlusDM = prevPlusDM - (prevPlusDM / inTimePeriodF);
        }
        outReal[outIdx] = prevPlusDM;
        outIdx += 1;
    }
    return outReal;
}

test "PlusDM calculation with valid input" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);

    const result = try PlusDM(&df, 4, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, highs.len);
    const expect = [_]f64{
        0.000000000, 0.000000000, 0.000000000, 4.000000000, 3.000000000, 3.250000000, 2.437500000, 3.828125000, 2.871093750, 88.153320312, 66.114990234, 49.586242676, 39.189682007, 29.392261505, 24.044196129,
    };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}

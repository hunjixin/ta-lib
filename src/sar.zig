const std = @import("std");
const MyError = @import("./lib.zig").MyError;
const MinusDm = @import("./lib.zig").MinusDm;

/// Calculates the Parabolic Sar (Stop and Reverse) indicator for a given DataFrame of f64 values.
///
/// The Parabolic Sar is a trend-following indicator developed by J. Welles Wilder Jr. It is used to determine potential reversals in market price direction.
///
/// Formula:
///   Sar(n) = Sar(n-1) + AF * (EP - Sar(n-1))
///   - Sar(n): Current Sar value
///   - Sar(n-1): Previous Sar value
///   - AF: Acceleration Factor (starts at inAcceleration, increases by inAcceleration up to inMaximum)
///   - EP: Extreme Point (highest high or lowest low during the current trend)
///
/// Parameters:
///   - `high`: The high price of the asset.
///   - `low`: The low price of the asset.
///   - `inAcceleration`: Initial acceleration factor (commonly 0.02).
///   - `inMaximum`: Maximum acceleration factor (commonly 0.2).
///   - `allocator`: Memory allocator for result allocation.
///
/// Returns:
/// - An array of f64 values representing the Sar for each period.
///
/// Errors:
/// - Returns an error if memory allocation fails or if input data is invalid.
pub fn Sar(inHigh: []const f64, inLow: []const f64, inAcceleration: f64, inMaximum: f64, allocator: std.mem.Allocator) ![]f64 {
    const len = inHigh.len;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);

    var af = inAcceleration;
    if (af > inMaximum) {
        af = inMaximum;
    }

    const epTemp = try MinusDm(inHigh, inLow, 1, allocator);
    var isLong: i32 = 1;
    if (epTemp.len > 1 and epTemp[1] > 0) {
        isLong = 0;
    }
    allocator.free(epTemp);

    const startIdx: usize = 1;
    var outIdx: usize = startIdx;
    var todayIdx: usize = startIdx;
    var newHigh = inHigh[todayIdx - 1];
    var newLow = inLow[todayIdx - 1];
    var sar: f64 = 0.0;
    var ep: f64 = 0.0;
    if (isLong == 1) {
        ep = inHigh[todayIdx];
        sar = newLow;
    } else {
        ep = inLow[todayIdx];
        sar = newHigh;
    }
    newLow = inLow[todayIdx];
    newHigh = inHigh[todayIdx];
    var prevLow: f64 = 0.0;
    var prevHigh: f64 = 0.0;

    while (todayIdx < inHigh.len) {
        prevLow = newLow;
        prevHigh = newHigh;
        newLow = inLow[todayIdx];
        newHigh = inHigh[todayIdx];
        todayIdx += 1;
        if (isLong == 1) {
            // uptrend
            if (newLow <= sar) {
                // trend reversal to downtrend
                isLong = 0;
                sar = ep;
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;
                if (outIdx < out.len) out[outIdx] = sar;
                outIdx += 1;
                af = inAcceleration;
                ep = newLow;
                sar = sar + af * (ep - sar);
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;
            } else {
                // trend continues
                if (outIdx < out.len) out[outIdx] = sar;
                outIdx += 1;
                if (newHigh > ep) {
                    ep = newHigh;
                    af += inAcceleration;
                    if (af > inMaximum) af = inMaximum;
                }
                sar = sar + af * (ep - sar);
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;
            }
        } else {
            // downtrend
            if (newHigh >= sar) {
                // trend reversal to uptrend
                isLong = 1;
                sar = ep;
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;
                if (outIdx < out.len) out[outIdx] = sar;
                outIdx += 1;
                af = inAcceleration;
                ep = newHigh;
                sar = sar + af * (ep - sar);
                if (sar > prevLow) sar = prevLow;
                if (sar > newLow) sar = newLow;
            } else {
                // trend continues
                if (outIdx < out.len) out[outIdx] = sar;
                outIdx += 1;
                if (newLow < ep) {
                    ep = newLow;
                    af += inAcceleration;
                    if (af > inMaximum) af = inMaximum;
                }
                sar = sar + af * (ep - sar);
                if (sar < prevHigh) sar = prevHigh;
                if (sar < newHigh) sar = newHigh;
            }
        }
    }

    return out;
}

test "Sar calculation with valid input" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };

    const result = try Sar(&highs, &lows, 0.02, 0.2, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, highs.len);
    const expect = [_]f64{
        0.000000000, 8.000000000, 8.080000000, 8.158400000, 8.352064000, 8.537981440, 8.865702554, 9.173760400, 9.639859568, 10.068670803, 13.000000000, 14.000000000, 15.000000000, 15.000000000, 16.000000000,
    };
    for (expect, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, result[i], 1e-9);
    }
}

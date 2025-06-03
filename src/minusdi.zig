const std = @import("std");

/// Calculates the Minus Directional Indicator (-DI) for a given DataFrame of f64 values over a specified period.
///
/// The Minus Directional Indicator (-DI) is a technical analysis indicator used to measure the presence of a downtrend.
/// It is part of the Directional Movement System developed by J. Welles Wilder.
///
/// Formula:
///   - Calculate the Minus Directional Movement (-DM):
///       -DM = previous_low - current_low (if previous_low - current_low > current_high - previous_high and > 0, else 0)
///   - Calculate the True Range (TR):
///       TR = max(current_high - current_low, abs(current_high - previous_close), abs(current_low - previous_close))
///   - Smooth the -DM and TR values over the given period (typically using a Wilder's smoothing technique).
///   - -DI = 100 * (Smoothed -DM / Smoothed TR)
///
/// Parameters:
///   - `high`: The high price of the asset.
///   - `low`: The low price of the asset.
///   - `close`: The closing price of the asset.
///   - `period`: The number of periods to use for smoothing (e.g., 14).
///   - `allocator`: The allocator to use for memory management.
///
/// Returns:
///   - An array of f64 values representing the -DI for each period.
///
/// Errors:
///   - Returns an error if memory allocation fails or if the input DataFrame is invalid.
///
/// Reference:
///   - J. Welles Wilder, "New Concepts in Technical Trading Systems", 1978.
pub fn MinusDI(inHigh: []const f64, inLow: []const f64, inClose: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = inHigh.len;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);

    if (len == 0 or period == 0 or len <= period) return out;

    var minus_dm: f64 = 0;
    var tr: f64 = 0;

    // Warm-up: sum initial period
    for (1..period) |i| {
        const up = inHigh[i] - inHigh[i - 1];
        const down = inLow[i - 1] - inLow[i];
        if (down > 0 and down > up) minus_dm += down;
        const high_low = inHigh[i] - inLow[i];
        const high_close = @abs(inHigh[i] - inClose[i - 1]);
        const low_close = @abs(inLow[i] - inClose[i - 1]);
        tr += @max(high_low, @max(high_close, low_close));
    }

    // Main loop
    const period_multiplier: f64 = if (period == 1) 1.0 else 100.0;
    for (period..len) |i| {
        const up = inHigh[i] - inHigh[i - 1];
        const down = inLow[i - 1] - inLow[i];
        const plus = if (down > 0 and up < down) down else 0;
        minus_dm = minus_dm - (minus_dm / @as(f64, @floatFromInt(period))) + plus;

        const high_low = inHigh[i] - inLow[i];
        const high_close = @abs(inHigh[i] - inClose[i - 1]);
        const low_close = @abs(inLow[i] - inClose[i - 1]);
        const t = @max(high_low, @max(high_close, low_close));
        tr = tr - (tr / @as(f64, @floatFromInt(period))) + t;

        out[i] = if (tr > 1e-14) period_multiplier * (minus_dm / tr) else 0.0;
    }

    return out;
}

test "MinusDI " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const adx = try MinusDI(&highs, &lows, &closes, 5, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67.18804335365883, 65.88605652362618, 65.0976325715738, 63.20672799658612 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

test "MinusDI 1 perid " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const adx = try MinusDI(&highs, &lows, &closes, 1, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 85, 0, 0, 0 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

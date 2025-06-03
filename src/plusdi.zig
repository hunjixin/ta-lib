const std = @import("std");

/// Calculates the Plus Directional Indicator (+DI) for a given DataFrame of f64 values over a specified period.
///
/// The Plus Directional Indicator (+DI) is a technical analysis indicator that measures the presence of upward price movement.
/// It is part of the Directional Movement System developed by J. Welles Wilder.
///
/// Formula:
///   +DM = current_high - previous_high (if current_high - previous_high > previous_low - current_low and > 0, else 0)
///   TR = max(current_high - current_low, abs(current_high - previous_close), abs(current_low - previous_close))
///   +DI = 100 * (Smoothed +DM / Smoothed TR)
///
/// Arguments:
///   - `high`: The high price of the asset.
///   - `low`: The low price of the asset.
///   - `close`: The closing price of the asset.
///   - `period`: The number of periods to use for smoothing (e.g., 14).
///   - `allocator`: Allocator to use for result memory allocation.
///
/// Returns:
///   An array of f64 values representing the +DI for each period.
///
/// Errors:
///   Returns an error if memory allocation fails or if the input DataFrame is invalid.
pub fn PlusDI(inHigh: []const f64, inLow: []const f64, inClose: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = inHigh.len;
    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);

    if (len == 0 or period == 0 or len <= period) return out;

    var plus_dm: f64 = 0;
    var tr: f64 = 0;

    // Warm-up: sum initial period
    for (1..period) |i| {
        const up = inHigh[i] - inHigh[i - 1];
        const down = inLow[i - 1] - inLow[i];
        if (up > 0 and up > down) plus_dm += up;
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
        const plus = if (up > 0 and up > down) up else 0;
        plus_dm = plus_dm - (plus_dm / @as(f64, @floatFromInt(period))) + plus;

        const high_low = inHigh[i] - inLow[i];
        const high_close = @abs(inHigh[i] - inClose[i - 1]);
        const low_close = @abs(inLow[i] - inClose[i - 1]);
        const t = @max(high_low, @max(high_close, low_close));
        tr = tr - (tr / @as(f64, @floatFromInt(period))) + t;

        out[i] = if (tr > 1e-14) period_multiplier * (plus_dm / tr) else 0.0;
    }

    return out;
}

test "PlusDI " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const period = 5;
    const adx = try PlusDI(&highs, &lows, &closes, period, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 45.652173913043484, 40.19138755980862, 53.9594843462247, 47.17246930972028, 96.36207410281818, 45.38278250731527, 45.02405540630219, 46.0893931101081, 45.53786546706974, 47.11983850178317 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}

test "PlusDI 1 perid " {
    var allocator = std.testing.allocator;

    // Trend reversals and choppy data: up, down, up, down, flat, up, down, up, down, up
    const highs = [_]f64{ 10, 12, 11, 13, 13, 14, 13, 15, 14, 100, 17, 16, 18, 17, 19 };
    const lows = [_]f64{ 8, 9, 9, 10, 12, 12, 12, 13, 13, 14, 100, 15, 16, 16, 17 };
    const closes = [_]f64{ 9, 11, 10, 12, 13, 13, 13, 14, 14, 100, 16, 16, 17, 17, 18 };

    const period = 1;
    const adx = try PlusDI(&highs, &lows, &closes, period, allocator);
    defer allocator.free(adx);

    const expected = [_]f64{ 0, 0.6666666666666666, 0, 0.6666666666666666, 0, 0.5, 0, 1, 0, 1, 0, 0, 1, 0, 1 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

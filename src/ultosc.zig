// Ultimate Oscillator (UltOsc) in Zig

const std = @import("std");

pub fn UltOsc(
    high: []const f64,
    low: []const f64,
    close: []const f64,
    timePeriod1: usize,
    timePeriod2: usize,
    timePeriod3: usize,
    allocator: std.mem.Allocator,
) ![]f64 {
    const len = close.len;
    // Sort periods descending
    var periods = [_]usize{ timePeriod1, timePeriod2, timePeriod3 };
    std.mem.sort(usize, &periods, {}, std.sort.desc(usize));
    const p1 = periods[2];
    const p2 = periods[1];
    const p3 = periods[0];

    const lookback = @max(p1, p2, p3) + 1;
    if (lookback >= len) return error.NotEnoughData;

    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0.0);

    var a1_total: f64 = 0;
    var b1_total: f64 = 0;
    var a2_total: f64 = 0;
    var b2_total: f64 = 0;
    var a3_total: f64 = 0;
    var b3_total: f64 = 0;

    for (lookback - p1..lookback - 1) |i| {
        const tr = calcTrueRange(high, low, close, i);
        const bp = close[i] - @min(low[i], close[i - 1]);
        a1_total += bp;
        b1_total += tr;
    }
    for (lookback - p2..lookback - 1) |i| {
        const tr = calcTrueRange(high, low, close, i);
        const bp = close[i] - @min(low[i], close[i - 1]);
        a2_total += bp;
        b2_total += tr;
    }
    for (lookback - p3..lookback - 1) |i| {
        const tr = calcTrueRange(high, low, close, i);
        const bp = close[i] - @min(low[i], close[i - 1]);
        a3_total += bp;
        b3_total += tr;
    }

    var today = lookback - 1;
    var t1 = today - p1 + 1;
    var t2 = today - p2 + 1;
    var t3 = today - p3 + 1;

    while (today < len) : (today += 1) {
        const tr = calcTrueRange(high, low, close, today);
        const bp = close[today] - @min(low[today], close[today - 1]);

        a1_total += bp;
        b1_total += tr;
        a2_total += bp;
        b2_total += tr;
        a3_total += bp;
        b3_total += tr;

        var output: f64 = 0;
        if (b1_total > 1e-12) output += 4.0 * (a1_total / b1_total);
        if (b2_total > 1e-12) output += 2.0 * (a2_total / b2_total);
        if (b3_total > 1e-12) output += a3_total / b3_total;

        out[today] = 100.0 * (output / 7.0);

        // Slide window
        const tr1 = calcTrueRange(high, low, close, t1);
        const bp1 = close[t1] - @min(low[t1], close[t1 - 1]);
        a1_total -= bp1;
        b1_total -= tr1;
        t1 += 1;

        const tr2 = calcTrueRange(high, low, close, t2);
        const bp2 = close[t2] - @min(low[t2], close[t2 - 1]);
        a2_total -= bp2;
        b2_total -= tr2;
        t2 += 1;

        const tr3 = calcTrueRange(high, low, close, t3);
        const bp3 = close[t3] - @min(low[t3], close[t3 - 1]);
        a3_total -= bp3;
        b3_total -= tr3;
        t3 += 1;
    }

    return out;
}

fn calcTrueRange(high: []const f64, low: []const f64, close: []const f64, i: usize) f64 {
    const prev = close[i - 1];
    const tr1 = high[i] - low[i];
    const tr2 = @abs(high[i] - prev);
    const tr3 = @abs(low[i] - prev);
    return @max(tr1, tr2, tr3);
}

test "ultOsc basic test" {
    const allocator = std.testing.allocator;

    const highs = [_]f64{ 13.27, 15.84, 11.46, 16.92, 14.15, 10.58, 18.33, 12.71, 17.49, 9.94, 19.02, 11.88, 13.63, 14.91, 16.47, 12.39, 15.02, 10.73, 17.76, 13.05 };
    const lows = [_]f64{ 11.12, 13.91, 10.08, 15.44, 12.77, 9.86, 16.50, 11.62, 15.88, 8.94, 17.11, 10.55, 12.41, 13.59, 14.89, 10.94, 13.31, 9.21, 15.61, 11.82 };
    const closes = [_]f64{ 12.20, 14.65, 10.90, 16.30, 13.60, 10.15, 17.40, 12.10, 16.73, 9.40, 18.15, 11.11, 13.02, 14.20, 15.69, 11.60, 14.30, 10.01, 16.80, 12.51 };

    const result = try UltOsc(
        &highs,
        &lows,
        &closes,
        3,
        5,
        10,
        allocator,
    );
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59.141501165529306, 40.83958261393521, 53.89053613246809, 36.57014641997077, 62.82483828081046, 37.07290075607684, 48.211224941748604, 35.696175978358994, 58.28813910454544, 46.657725456083774 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

const std = @import("std");
const DataFrame = @import("./lib.zig").DataFrame;

pub fn MinusDI(df: *const DataFrame(f64), period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = df.getRowCount();
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    if (len == 0 or period == 0 or len <= period) return out;

    const inHigh = try df.getColumnData("high");
    const inLow = try df.getColumnData("low");
    const inClose = try df.getColumnData("close");

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

    var df = try DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("high", highs[0..]);
    try df.addColumnWithData("low", lows[0..]);
    try df.addColumnWithData("close", closes[0..]);

    const period = 5;
    const adx = try MinusDI(&df, period, allocator);
    defer allocator.free(adx);

    std.debug.print("ADX: {any}\n", .{adx});

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 67.18804335365883, 65.88605652362618, 65.0976325715738, 63.20672799658612 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}

test "MinusDI 1 perid " {
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

    const period = 1;
    const adx = try MinusDI(&df, period, allocator);
    defer allocator.free(adx);

    std.debug.print("ADX: {any}\n", .{adx});

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 85, 0, 0, 0 };
    for (adx, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(v, expected[i], 1e-9);
    }
}

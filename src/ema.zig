const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Exponential Moving Average (EMA) of a given data set.
///
/// The EMA is a type of moving average that places a greater weight and significance
/// on the most recent data points. It is calculated using the following formula:
///
/// EMA_today = (Value_today * alpha) + (EMA_yesterday * (1 - alpha))
///
/// Where:
/// - `alpha` is typically calculated as `2 / (N + 1)`, where `N` is the number of periods.
/// - `Value_today` is the current data point.
/// - `EMA_yesterday` is the EMA value calculated for the previous period.
///
/// This function is commonly used in financial analysis and time series data processing
/// to smooth out short-term fluctuations and highlight longer-term trends.
pub fn EMA(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    if (prices.len < period or period == 0) {
        return allocator.alloc(f64, prices.len);
    }
    const k1: f64 = 2.0 / (@as(f64, @floatFromInt(period)) + 1.0);
    return try EMAK(prices, period, k1, allocator);
}

pub fn EMAK(prices: []const f64, period: usize, k: f64, allocator: std.mem.Allocator) ![]f64 {
    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);

    const lookback_total = period - 1;
    const start_idx: usize = lookback_total;
    var today: usize = start_idx - lookback_total;
    var i: usize = period;
    var temp_real: f64 = 0.0;

    // Calculate initial SMA
    while (i > 0) : (i -= 1) {
        temp_real += prices[today];
        today += 1;
    }
    var prev_ma: f64 = temp_real / @as(f64, @floatFromInt(period));

    // Advance prev_ma to start_idx
    while (today <= start_idx) : (today += 1) {
        prev_ma = ((prices[today] - prev_ma) * k) + prev_ma;
    }
    out[start_idx] = prev_ma;

    var out_idx: usize = start_idx + 1;
    while (today < prices.len) : (today += 1) {
        prev_ma = ((prices[today] - prev_ma) * k) + prev_ma;
        out[out_idx] = prev_ma;
        out_idx += 1;
    }

    return out;
}

test "EMA calculation with valid input" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 5;

    const result = try EMA(prices[0..], period, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    for (0..4) |i| {
        try std.testing.expect(std.math.approxEqAbs(f64, result[i], 0, 1e-9));
    }
    try std.testing.expect(std.math.approxEqAbs(f64, result[4], 3.0, 1e-9)); // SMA for first 3 prices
    try std.testing.expect(std.math.approxEqAbs(f64, result[5], 4.0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, result[6], 5.0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, result[7], 6.0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, result[8], 7.0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, result[9], 8.0, 1e-9));
}

test "EMA calculation with empty input" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{};
    const period = 3;

    const result = try EMA(prices[0..], period, allocator);
    try std.testing.expect(result.len == 0);
}

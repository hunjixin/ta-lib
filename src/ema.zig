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
    if (prices.len < period) {
        return MyError.TooFewDataPoints;
    }

    const alpha: f64 = 2.0 / (@as(f64, @floatFromInt(period)) + 1.0);

    // Allocate memory for result
    var result = try allocator.alloc(f64, prices.len);

    // Set first (period - 1) EMA values to 0.0 (initialization)
    for (result[0 .. period - 1]) |*r| {
        r.* = 0.0;
    }

    // Compute the initial EMA using the Simple Moving Average (SMA)
    var sum: f64 = 0.0;
    for (prices[0..period]) |p| {
        sum += p;
    }
    var prev_ema: f64 = sum / @as(f64, @floatFromInt(period));
    result[period - 1] = prev_ema;

    // Compute the rest of the EMA values
    var i: usize = period;
    while (i < prices.len) : (i += 1) {
        const price = prices[i];
        const current_ema = alpha * price + (1.0 - alpha) * prev_ema;
        result[i] = current_ema;
        prev_ema = current_ema;
    }

    return result;
}

test "EMA calculation with valid input" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 3;

    const result = try EMA(prices[0..], period, allocator);
    defer allocator.free(result);

    try std.testing.expectEqual(result.len, prices.len);
    try std.testing.expectEqual(result[0], 0.0);
    try std.testing.expectEqual(result[1], 0.0);
    try std.testing.expect(std.math.approxEqAbs(f64, result[2], 2.0, 1e-9)); // SMA for first 3 prices
    try std.testing.expect(std.math.approxEqAbs(f64, result[3], 3.0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, result[4], 4.0, 1e-9));
}

test "EMA calculation with insufficient data points" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0 };
    const period = 3;

    const result = EMA(prices[0..], period, allocator);
    try std.testing.expect(result == MyError.TooFewDataPoints);
}

test "EMA calculation with empty input" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{};
    const period = 3;

    const result = EMA(prices[0..], period, allocator);
    try std.testing.expect(result == MyError.TooFewDataPoints);
}

const std = @import("std");
const Emak = @import("./ema.zig").Emak;
const Ema = @import("./lib.zig").Ema;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Moving Average Convergence Divergence (Macd) indicator for a given DataFrame of f64 values.
///
/// The Macd is a trend-following momentum indicator that shows the relationship between two moving averages of prices.
/// It is calculated using the following formulas:
///   - Macd Line = Ema(fastPeriod) - Ema(slowPeriod)
///   - Signal Line = Ema(Macd Line, signalPeriod)
///   - Histogram = Macd Line - Signal Line
///
/// Parameters:
///   - prices: Price sequence.
///   - inFastPeriod: The period for the fast Ema (typically 12).
///   - inSlowPeriod: The period for the slow Ema (typically 26).
///   - inSignalPeriod: The period for the signal line Ema (typically 9).
///   - allocator: Allocator used for memory management.
///
/// Returns:
///   - A struct containing three slices of f64:
///       1. The Macd line values.
///       2. The Signal line values.
///       3. The Histogram values.
///
/// Errors:
///   - Returns an error if memory allocation fails or if input parameters are invalid.
pub fn Macd(
    prices: []const f64,
    inFastPeriod: usize,
    inSlowPeriod: usize,
    inSignalPeriod: usize,
    allocator: std.mem.Allocator,
) !struct {
    []f64,
    []f64,
    []f64,
} {
    var fast_period = inFastPeriod;
    var slow_period = inSlowPeriod;
    if (slow_period < fast_period) {
        const tmp = slow_period;
        slow_period = fast_period;
        fast_period = tmp;
    }

    var k1: f64 = 0;
    var k2: f64 = 0;
    if (slow_period == 0) {
        slow_period = 26;
        k1 = 0.075;
    } else {
        k1 = 2.0 / (@as(f64, @floatFromInt(slow_period)) + 1.0);
    }

    if (fast_period == 0) {
        fast_period = 12;
        k2 = 0.15;
    } else {
        k2 = 2.0 / (@as(f64, @floatFromInt(fast_period)) + 1.0);
    }

    const lookback_signal = inSignalPeriod - 1;
    const lookback_total = lookback_signal + (slow_period - 1);

    // Compute fast and slow Ema
    var fast_ema = try Emak(prices, fast_period, k2, allocator);
    const slow_ema = try Emak(prices, slow_period, k1, allocator);
    defer allocator.free(slow_ema);
    defer allocator.free(fast_ema);

    // Subtract slow Ema from fast Ema
    for (0..fast_ema.len) |i| {
        fast_ema[i] = fast_ema[i] - slow_ema[i];
    }

    // outMACD
    var out_macd = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(out_macd);
    for (0..out_macd.len) |i| {
        if (i >= lookback_total - 1) {
            out_macd[i] = fast_ema[i];
        } else {
            out_macd[i] = 0;
        }
    }

    // outMACDSignal
    const out_macd_signal = try Ema(out_macd, inSignalPeriod, allocator);
    errdefer allocator.free(out_macd_signal);

    // outMACDHist
    var out_macd_hist = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(out_macd_hist);
    for (0..out_macd_hist.len) |i| {
        if (i >= lookback_total) {
            out_macd_hist[i] = out_macd[i] - out_macd_signal[i];
        } else {
            out_macd_hist[i] = 0;
        }
    }

    return .{
        out_macd,
        out_macd_signal,
        out_macd_hist,
    };
}

test " Macd calculation with expected values" {
    const gpa = std.testing.allocator;
    const close_prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0 };

    // Call Macd function
    const macd, const signal, const histogram = try Macd(&close_prices, 0, 0, 9, gpa);
    defer gpa.free(macd);
    defer gpa.free(signal);
    defer gpa.free(histogram);

    // Validate the result length
    try std.testing.expect(histogram.len == close_prices.len);

    const expected_macd = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6.768727299468942, 6.760660931990998, 6.753261315076564 };
    const expected_signal = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.3537454598937886, 2.4351285543132306, 3.2987551064658973 };
    const expected_histogram = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4.325532377677767, 3.454506208610667,
    };

    for (0..35) |i| {
        try std.testing.expectApproxEqAbs(expected_macd[i], macd[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_histogram[i], histogram[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_signal[i], signal[i], 1e-9);
    }
}

test " Macd calculation with period" {
    const gpa = std.testing.allocator;
    const close_prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0 };

    // Call Macd function
    const macd, const signal, const histogram = try Macd(&close_prices, 5, 10, 9, gpa);
    defer gpa.free(macd);
    defer gpa.free(signal);
    defer gpa.free(histogram);

    // Validate the result length
    try std.testing.expect(histogram.len == close_prices.len);

    const expected_macd = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5 };
    const expected_signal = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.5, 0.9, 1.2200000000000002, 1.4760000000000002, 1.6808, 1.84464, 1.9757120000000001, 2.0805696, 2.16445568, 2.2315645440000003, 2.2852516352000003, 2.32820130816, 2.362561046528, 2.3900488372224, 2.41203906977792, 2.429631255822336, 2.4437050046578688, 2.454964003726295, 2.4639712029810363 };
    const expected_histogram = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1.6, 1.2799999999999998, 1.0239999999999998, 0.8191999999999999, 0.6553599999999999, 0.5242879999999999, 0.4194304, 0.3355443199999999, 0.26843545599999974, 0.2147483647999997, 0.17179869183999985, 0.13743895347199997, 0.10995116277759998, 0.08796093022208007, 0.07036874417766414, 0.05629499534213123, 0.045035996273704804, 0.036028797018963665 };

    for (0..35) |i| {
        try std.testing.expectApproxEqAbs(expected_macd[i], macd[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_histogram[i], histogram[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_signal[i], signal[i], 1e-9);
    }
}

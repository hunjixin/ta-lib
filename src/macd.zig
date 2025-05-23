const std = @import("std");
const Column = @import("./lib.zig").Column;
const DataFrame = @import("./lib.zig").DataFrame;
const AD = @import("./lib.zig").AD;
const EMAK = @import("./lib.zig").EMAK;
const EMA = @import("./lib.zig").EMA;
const MyError = @import("./lib.zig").MyError;

/// Calculates the Moving Average Convergence Divergence (MACD) indicator for a given DataFrame of f64 values.
///
/// The MACD is a trend-following momentum indicator that shows the relationship between two moving averages of prices.
/// It is calculated using the following formulas:
///   - MACD Line = EMA(fastPeriod) - EMA(slowPeriod)
///   - Signal Line = EMA(MACD Line, signalPeriod)
///   - Histogram = MACD Line - Signal Line
///
/// Parameters:
///   - df: Pointer to a DataFrame containing input data as f64 values.
///   - inFastPeriod: The period for the fast EMA (typically 12).
///   - inSlowPeriod: The period for the slow EMA (typically 26).
///   - inSignalPeriod: The period for the signal line EMA (typically 9).
///   - allocator: Allocator used for memory management.
///
/// Returns:
///   - A struct containing three slices of f64:
///       1. The MACD line values.
///       2. The Signal line values.
///       3. The Histogram values.
///
/// Errors:
///   - Returns an error if memory allocation fails or if input parameters are invalid.
pub fn MACD(
    df: *const DataFrame(f64),
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
    var signalPeriod = inSignalPeriod;
    if (slow_period < fast_period) {
        const tmp = slow_period;
        slow_period = fast_period;
        fast_period = tmp;
    }

    if (slow_period == 0) slow_period = 26;
    if (fast_period == 0) fast_period = 12;
    if (signalPeriod == 0) signalPeriod = 9;

    const k1: f64 = 2.0 / (@as(f64, @floatFromInt(fast_period)) + 1.0);
    const k2: f64 = 2.0 / (@as(f64, @floatFromInt(slow_period)) + 1.0);

    const lookback_signal = signalPeriod - 1;
    const lookback_total = lookback_signal + (slow_period - 1);

    const prices = try df.getColumnData("Close");

    // Compute fast and slow EMA
    var fast_ema = try EMAK(prices, fast_period, k1, allocator);
    const slow_ema = try EMAK(prices, slow_period, k2, allocator);
    defer allocator.free(slow_ema);
    defer allocator.free(fast_ema);

    // Subtract slow EMA from fast EMA
    for (0..fast_ema.len) |i| {
        fast_ema[i] = fast_ema[i] - slow_ema[i];
    }

    // outMACD
    var out_macd = try allocator.alloc(f64, prices.len);
    for (0..out_macd.len) |i| {
        if (i >= lookback_total - 1) {
            out_macd[i] = fast_ema[i];
        } else {
            out_macd[i] = 0;
        }
    }

    // outMACDSignal
    const out_macd_signal = try EMA(out_macd, signalPeriod, allocator);

    // outMACDHist
    var out_macd_hist = try allocator.alloc(f64, prices.len);
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

test "MACD calculation with expected values" {
    const gpa = std.testing.allocator;

    var df = try DataFrame(f64).init(gpa);
    defer df.deinit();

    var close_prices: [35]f64 = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0 };
    try df.addColumnWithData("Close", close_prices[0..]);

    // Call MACD function
    const macd, const signal, const histogram = try MACD(&df, 0, 0, 0, gpa);
    defer gpa.free(macd);
    defer gpa.free(signal);
    defer gpa.free(histogram);

    // Validate the result length
    try std.testing.expect(histogram.len == close_prices.len);

    for (0..32) |i| {
        try std.testing.expect(std.math.approxEqAbs(f64, macd[i], 0, 1e-9));
        try std.testing.expect(std.math.approxEqAbs(f64, histogram[i], 0, 1e-9));
        try std.testing.expect(std.math.approxEqAbs(f64, signal[i], 0, 1e-9));
    }
    try std.testing.expect(std.math.approxEqAbs(f64, macd[32], 7, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, macd[33], 7, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, macd[34], 7, 1e-9));

    try std.testing.expect(std.math.approxEqAbs(f64, histogram[32], 0, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, histogram[33], 4.48, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, histogram[34], 3.5839999999999996, 1e-9));

    try std.testing.expect(std.math.approxEqAbs(f64, signal[32], 1.4000000000000001, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, signal[33], 2.52, 1e-9));
    try std.testing.expect(std.math.approxEqAbs(f64, signal[34], 3.4160000000000004, 1e-9));
}

const std = @import("std");
const Ma = @import("./ma.zig").Ma;
const MaType = @import("./ma.zig").MaType;

/// Calculates the Extended Macd (Moving Average Convergence/Divergence) indicator
/// with configurable fast, slow, and signal periods and moving average types.
///
/// The Macd is a momentum oscillator that calculates the difference between two
/// moving averages of price data. This extended version allows the user to select
/// different moving average types (e.g., Ema, Sma, etc.) for the fast, slow, and
/// signal line calculations.
///
/// # Arguments
/// - `inReal`: Slice of input price values (usually closing prices).
/// - `inFastPeriod`: The period for the fast moving average (e.g., 12).
/// - `inFastMAType`: The type of moving average to use for the fast Ma (e.g., Ema).
/// - `inSlowPeriod`: The period for the slow moving average (e.g., 26).
/// - `inSlowMAType`: The type of moving average to use for the slow Ma.
/// - `inSignalPeriod`: The period for the signal line moving average (e.g., 9).
/// - `inSignalMAType`: The type of moving average to use for the signal line.
/// - `allocator`: The allocator used for memory management of the output slices.
///
/// # Returns
/// Returns a struct containing three slices:
/// - `macd`: The Macd line (fast Ma - slow Ma)
/// - `signal`: The signal line (Ma of the Macd line using `inSignalPeriod`)
/// - `hist`: The Macd histogram (Macd - Signal)
///
/// # Formula
/// ```text
/// FastMA = Ma(inReal, inFastPeriod, inFastMAType)
/// SlowMA = Ma(inReal, inSlowPeriod, inSlowMAType)
/// Macd = FastMA - SlowMA
/// Signal = Ma(Macd, inSignalPeriod, inSignalMAType)
/// Histogram = Macd - Signal
/// ```
///
/// # Errors
/// Returns an error if allocation fails or if the input is insufficient to compute the output.
pub fn MacdExt(
    inReal: []const f64,
    inFastPeriod: usize,
    inFastMAType: MaType,
    inSlowPeriod: usize,
    inSlowMAType: MaType,
    inSignalPeriod: usize,
    inSignalMAType: MaType,
    allocator: std.mem.Allocator,
) !struct { []f64, []f64, []f64 } {
    // Input validation
    if (inFastPeriod >= inSlowPeriod) {
        return error.InvalidPeriods;
    }
    if (inReal.len == 0) {
        return error.EmptyInput;
    }

    // Calculate lookback periods
    const lookbackLargest = if (inFastPeriod > inSlowPeriod) inFastPeriod else inSlowPeriod;
    const lookbackTotal = (inSignalPeriod - 1) + (lookbackLargest - 1);

    // Allocate output arrays
    const outMACD = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outMACD);
    const outMACDSignal = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outMACDSignal);
    const outMACDHist = try allocator.alloc(f64, inReal.len);
    errdefer allocator.free(outMACDHist);
    @memset(outMACD, 0);
    @memset(outMACDSignal, 0);
    @memset(outMACDHist, 0);

    // Calculate MAs
    const slowMABuffer = try Ma(inReal, inSlowPeriod, inSlowMAType, allocator);
    defer allocator.free(slowMABuffer);
    const fastMABuffer = try Ma(inReal, inFastPeriod, inFastMAType, allocator);
    defer allocator.free(fastMABuffer);

    // Calculate Macd line (fast Ma - slow Ma)
    const tempBuffer1 = try allocator.alloc(f64, inReal.len);
    defer allocator.free(tempBuffer1);
    for (0..inReal.len) |i| {
        tempBuffer1[i] = fastMABuffer[i] - slowMABuffer[i];
    }

    // Calculate signal line (Ma of Macd line)
    const tempBuffer2 = try Ma(tempBuffer1, inSignalPeriod, inSignalMAType, allocator);
    defer allocator.free(tempBuffer2);
    // Calculate final outputs
    for (lookbackTotal..inReal.len) |i| {
        outMACD[i] = tempBuffer1[i];
        outMACDSignal[i] = tempBuffer2[i];
        outMACDHist[i] = outMACD[i] - outMACDSignal[i];
    }

    return .{ outMACD, outMACDSignal, outMACDHist };
}

test "MacdExt calculation with expected values" {
    const gpa = std.testing.allocator;

    const close_prices: [65]f64 = [_]f64{
        1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0,  8.0,  9.0,  10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0,
        20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0, 8,    9,    9,
        10,   12,   12,   12,   13,   13,   14,   100,  15,   16,   16,   17,   18,   19,   18,   20,   21,   22,   24,
        23,   25,   26,   27,   28,   29,   30,   31,
    };

    const macd, const signal, const histogram = try MacdExt(&close_prices, 5, MaType.SMA, 10, MaType.SMA, 8, MaType.SMA, gpa);
    defer {
        gpa.free(macd);
        gpa.free(signal);
        gpa.free(histogram);
    }
    const expected_macd = [_]f64{
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, -0.3000000000000007, -3.099999999999998, -6, -8.900000000000002, -11.700000000000001, -8.999999999999998, -6.399999999999999, -3.5999999999999996, -0.9000000000000004, 1.6000000000000014, 10, 10, 9.900000000000002, 9.900000000000002, 9.999999999999996, -7, -6.900000000000002, -7, -6.900000000000002, -6.800000000000001, 1.8000000000000007, 1.8999999999999986, 2.1999999999999993, 2.3000000000000007, 2.3999999999999986, 2.5, 2.400000000000002, 2.5, 2.5, 2.5,
    };
    const expected_signal = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.15, 1.4500000000000002, 0.3875000000000002, -1.0375, -2.8125, -4.25, -5.3625, -6.125, -6.2, -5.6125, -3.6125, -1.2499999999999996, 1.4500000000000008, 3.812500000000001, 5.862500000000001, 5.437500000000001, 4.6875, 3.6125, 1.4999999999999996, -0.6000000000000005, -1.6125000000000007, -2.612500000000001, -3.587500000000001, -2.4250000000000007, -1.2625000000000006, -0.07500000000000062, 1.0875, 2.25, 2.3375, 2.4125 };
    const expected_histogram = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -2.4500000000000006, -4.549999999999998, -6.3875, -7.8625000000000025, -8.887500000000001, -4.749999999999998, -1.0374999999999988, 2.5250000000000004, 5.3, 7.212500000000001, 13.6125, 11.25, 8.450000000000001, 6.087500000000001, 4.137499999999996, -12.4375, -11.587500000000002, -10.6125, -8.400000000000002, -6.2, 3.4125000000000014, 4.512499999999999, 5.7875, 4.725000000000001, 3.662499999999999, 2.5750000000000006, 1.3125000000000022, 0.25, 0.1625000000000001, 0.08749999999999991 };

    for (0..macd.len) |i| {
        try std.testing.expectApproxEqAbs(expected_macd[i], macd[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_signal[i], signal[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_histogram[i], histogram[i], 1e-9);
    }
}

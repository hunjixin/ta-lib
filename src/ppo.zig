const std = @import("std");
const EMA = @import("./lib.zig").EMA;
const MyError = @import("./lib.zig").MyError;
const MaType = @import("./lib.zig").MaType;
const Ma = @import("./lib.zig").Ma;
const IsZero = @import("./utils.zig").IsZero;

/// Calculates the Percentage Price Oscillator (PPO) for a given price series.
///
/// The Percentage Price Oscillator is a momentum-based technical indicator that shows
/// the percentage difference between two moving averages, typically a short-term and
/// a long-term Exponential Moving Average (EMA). Unlike MACD (which outputs absolute values),
/// PPO outputs percentage values, making it more suitable for comparing assets of different price levels.
///
/// ---
///
/// Formula:
///     PPO = 100 × (MA_fast - MA_slow) / MA_slow
///
/// Where:
///     - MA_fast = Moving Average over `inFastPeriod`
///     - MA_slow = Moving Average over `inSlowPeriod`
///     - The type of Moving Average is defined by the `maType` parameter (e.g., EMA, SMA, etc.)
///
/// This indicator is useful when:
///     - You want to compare momentum across assets with different price scales
///     - You prefer percentage-based oscillator values (like % divergence)
///
/// ---
///
/// Parameters:
/// - `prices`: slice of input price data (typically closing prices)
/// - `inFastPeriod`: lookback period for the fast moving average (e.g., 12)
/// - `inSlowPeriod`: lookback period for the slow moving average (e.g., 26)
/// - `maType`: enum specifying the type of moving average to use (e.g., EMA, SMA)
/// - `allocator`: memory allocator used to allocate the result slice
///
/// ---
///
/// Returns:
/// - `![]f64`: A slice of `f64` values representing the PPO series, aligned to input length.
///             Values before `inSlowPeriod` may be zero or uninitialized depending on the Ma implementation.
///
/// Errors:
/// - Returns an allocator error if memory allocation fails.
/// - May return domain-specific errors if `maType` is unsupported or if `prices.len < inSlowPeriod`.
pub fn Ppo(
    prices: []const f64,
    inFastPeriod: usize,
    inSlowPeriod: usize,
    maType: MaType,
    allocator: std.mem.Allocator,
) ![]f64 {
    var slowPeriod = inSlowPeriod;
    var fastPeriod = inFastPeriod;

    if (slowPeriod < fastPeriod) {
        std.mem.swap(usize, &slowPeriod, &fastPeriod);
    }

    const tempBuffer = try Ma(prices, fastPeriod, maType, allocator);
    defer allocator.free(tempBuffer);
    var outReal = try Ma(prices, slowPeriod, maType, allocator);

    for (slowPeriod - 1..prices.len) |i| {
        const tempReal = outReal[i];
        if (!IsZero(tempReal)) {
            outReal[i] = ((tempBuffer[i] - tempReal) / tempReal) * 100.0;
        } else {
            outReal[i] = 0.0;
        }
    }
    return outReal;
}

test "Ppo work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
    };
    const result = try Ppo(&prices, 10, 8, MaType.SMA, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.698573127229487, 4.860118439861144, -14.448184414524675, -8.07274340208472, 1.9316909294512974, -1.7225644535706033, -11.312849162011169, -15.646258503401341, 2.355072463768151, -4.190277363554987, -5.935836782968618, 7.4061074061074565, -24.167257264351484, -23.641502552881068, 6.612184249628605, 12.311613475177355, 12.807335751713058, -18.38966202783298, -19.181459566074917, 7.124551512045165, 11.553398058252478, 13.110643804594012, 12.548669695003268, 1.1259040105194222, -6.342913776015828, 2.663859392164092, 10.41009463722402, 9.62380573248412, -21.208530805687165, -45.978391356542566, -28.145336225596463, 2.465047829286325, 6.069711538461613, 5.536332179930863, 6.158605174353282, 6.655755591925859 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

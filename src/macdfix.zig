const std = @import("std");
const Macd = @import("./lib.zig").Macd;

/// Calculates the Macd Fix indicator for a given time series of prices.
///
/// The Macd Fix (Moving Average Convergence/Divergence Fix) is a simplified version
/// of the standard Macd indicator where the fast and slow Ema periods are fixed at
/// 12 and 26, respectively. Only the signal line period is configurable.
///
/// # Arguments
/// - `prices`: An array of input price data (typically closing prices).
/// - `period`: The period of the signal line Ema (typically 9).
/// - `allocator`: The memory allocator used to allocate output arrays.
///
/// # Returns
/// A struct containing:
/// - `macd`: The Macd line (Ema(12) - Ema(26))
/// - `signal`: The signal line (Ema of Macd line over `period`)
/// - `hist`: The histogram (Macd - Signal)
///
/// # Formula
/// ```text
/// EMA_fast = Ema(prices, 12)
/// EMA_slow = Ema(prices, 26)
/// Macd = EMA_fast - EMA_slow
/// Signal = Ema(Macd, period)
/// Histogram = Macd - Signal
/// ```
///
/// # Errors
/// Returns an error if allocation fails or input is insufficient for calculation.
pub fn MacdFix(
    prices: []const f64,
    period: usize,
    allocator: std.mem.Allocator,
) !struct {
    []f64,
    []f64,
    []f64,
} {
    return Macd(prices, 0, 0, period, allocator);
}

test "MacdFix calculation with expected values" {
    const gpa = std.testing.allocator;
    const close_prices = [_]f64{
        1.0,  2.0,  3.0,  4.0,  5.0,  6.0,  7.0,  8.0,  9.0,  10.0, 11.0, 12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0,
        20.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 29.0, 30.0, 31.0, 32.0, 33.0, 34.0, 35.0, 8,    9,    9,
        10,   12,   12,   12,   13,   13,   14,   100,  15,   16,   16,   17,   18,   19,   18,   20,   21,   22,   24,
        23,   25,   26,   27,   28,   29,   30,   31,
    };

    const macd, const signal, const histogram = try MacdFix(&close_prices, 5, gpa);
    defer gpa.free(macd);
    defer gpa.free(signal);
    defer gpa.free(histogram);

    try std.testing.expect(histogram.len == close_prices.len);

    const expected_macd = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6.809094424716772, 6.797623425071755, 6.787131088068804, 6.777526263359459, 6.768727299468942, 6.760660931990998, 6.753261315076564, 4.646469176482981, 3.0127310792783426, 1.694311275709314, 0.7136427033014385, 0.08456355783360436, -0.41100126031610884, -0.7960153344077661, -1.0147774776502452, -1.175362966151079, -1.2134004731156587, 5.220343292355988, 3.8451454659190674, 2.7956382883914515, 1.9390123393159584, 1.3186762980380458, 0.8911019772303632, 0.6198967702514793, 0.3246878375990043, 0.23892707612800734, 0.24380974781499276, 0.31990588876596604, 0.526137538340052, 0.6073681255113534, 0.8144027832627856, 1.0430217516081406, 1.2860394207640873, 1.5376441196543524, 1.7931698178107105, 2.048903737535781, 2.301924364872338 };
    const expected_histogram = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3.018616855666332, 2.005416345775588, 1.3305410140441616, 0.8811613667690965, 0.5820633328607681, 0.3831091439642229, -1.1491219964195736, -1.855240062416141, -2.1157732439901134, -2.064294544265326, -1.7955824598221068, -1.52743151864788, -1.2749637284930249, -0.9958172478236693, -0.7709351575496688, -0.5393151096761657, 3.929619103863654, 1.702947518284489, 0.4356268938379153, -0.280666036825052, -0.6006680520686432, -0.6854949152508838, -0.6378000814865119, -0.6220060094259913, -0.47184451393132554, -0.3113078948295601, -0.1568078359190579, 0.03294920910335203, 0.07611986418310235, 0.18876968128968963, 0.2782590997566965, 0.34751784594176216, 0.39941502988801814, 0.43662715202958413, 0.4615740478364365, 0.47639645011532905 };
    const expected_signal = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2.269698141572257, 3.779006569405423, 4.781714742293216, 5.446985249315297, 5.887565932699846, 6.17859759913023, 6.370152171112341, 5.795591172902554, 4.8679711416944835, 3.8100845196994273, 2.7779372475667645, 1.8801460176557112, 1.1164302583317711, 0.4789483940852588, -0.01896022982657586, -0.4044278086014102, -0.674085363439493, 1.2907241884923342, 2.1421979476345783, 2.360011394553536, 2.2196783761410104, 1.919344350106689, 1.576596892481247, 1.2576968517379912, 0.9466938470249956, 0.7107715900593329, 0.5551176426445529, 0.47671372468502393, 0.4931883292366999, 0.5312482613282511, 0.625633101973096, 0.7647626518514441, 0.9385215748223251, 1.1382290897663343, 1.3565426657811264, 1.5873296896993445, 1.8255279147570092 };

    for (0..35) |i| {
        try std.testing.expectApproxEqAbs(expected_macd[i], macd[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_histogram[i], histogram[i], 1e-9);
        try std.testing.expectApproxEqAbs(expected_signal[i], signal[i], 1e-9);
    }
}

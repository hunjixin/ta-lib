const std = @import("std");
const StdDev = @import("./lib.zig").StdDev;
const MaType = @import("./lib.zig").MaType;
const Ma = @import("./lib.zig").Ma;

/// Calculates Bollinger Bands for a given price series.
///
/// Bollinger Bands are a type of statistical chart characterizing the prices and volatility over time of a financial instrument or commodity,
/// using a formulaic method propounded by John Bollinger in the 1980s.
/// The bands are typically plotted two standard deviations (positively and negatively) away from a simple moving average (Sma) of the price,
/// but can be adjusted to user preferences.
///
/// Formula:
///   - Middle Band = Sma(prices, inTimePeriod)
///   - Upper Band  = Middle Band + (inNbDevUp * StandardDeviation(prices, inTimePeriod))
///   - Lower Band  = Middle Band - (inNbDevDn * StandardDeviation(prices, inTimePeriod))
///
/// Parameters:
///   prices        - Slice of input price data (e.g., closing prices)
///   inTimePeriod  - Number of periods for the moving average and standard deviation
///   inNbDevUp     - Number of standard deviations for the upper band
///   inNbDevDn     - Number of standard deviations for the lower band
///   maType        - Enum specifying the type of moving average to use (e.g., Ema, Sma)
///   allocator     - Allocator for result arrays
///
/// Returns:
///   A struct containing three slices of f64:
///     - Upper Band values
///     - Middle Band (Sma) values
///     - Lower Band values
///
/// Errors:
///   Returns an error if allocation fails or if input parameters are invalid.
///
/// Example usage:
///   const result = try Bbands(prices, 20, 2.0, 2.0, allocator);
pub fn BBands(prices: []const f64, inTimePeriod: usize, inNbDevUp: f64, inNbDevDn: f64, maType: MaType, allocator: std.mem.Allocator) !struct { []f64, []f64, []f64 } {
    var upper_band = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(upper_band);
    const middle_band = try Ma(prices, inTimePeriod, maType, allocator);
    errdefer allocator.free(middle_band);
    var lower_band = try allocator.alloc(f64, prices.len);
    errdefer allocator.free(lower_band);
    const stddev = try StdDev(prices, inTimePeriod, 1.0, allocator);
    defer allocator.free(stddev);

    if (inNbDevUp == inNbDevDn) {
        if (inNbDevUp == 1.0) {
            for (prices, 0..) |_, i| {
                upper_band[i] = middle_band[i] + stddev[i];
                lower_band[i] = middle_band[i] - stddev[i];
            }
        } else {
            for (prices, 0..) |_, i| {
                upper_band[i] = middle_band[i] + stddev[i] * inNbDevUp;
                lower_band[i] = middle_band[i] - stddev[i] * inNbDevUp;
            }
        }
    } else if (inNbDevUp == 1.0) {
        for (prices, 0..) |_, i| {
            upper_band[i] = middle_band[i] + stddev[i];
            lower_band[i] = middle_band[i] - stddev[i] * inNbDevDn;
        }
    } else if (inNbDevDn == 1.0) {
        for (prices, 0..) |_, i| {
            upper_band[i] = middle_band[i] + stddev[i] * inNbDevUp;
            lower_band[i] = middle_band[i] - stddev[i];
        }
    } else {
        for (prices, 0..) |_, i| {
            upper_band[i] = middle_band[i] + stddev[i] * inNbDevUp;
            lower_band[i] = middle_band[i] - stddev[i] * inNbDevDn;
        }
    }

    return .{ upper_band, middle_band, lower_band };
}

test "Bbands work correctly" {
    const allocator = std.testing.allocator;

    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0 };
    const period = 5;

    {
        const upper, const middle, const down = try BBands(prices[0..], period, 1, 1, MaType.SMA, allocator);
        defer allocator.free(upper);
        defer allocator.free(middle);
        defer allocator.free(down);

        const expect_upper = [_]f64{
            0, 0, 0, 0, 4.414213562373095, 5.414213562373095, 6.414213562373095, 7.414213562373095, 8.414213562373096, 9.414213562373096,
        };
        const expect_middle = [_]f64{
            0, 0, 0, 0, 3, 4, 5, 6, 7, 8,
        };
        const expect_lower = [_]f64{
            0, 0, 0, 0, 1.5857864376269049, 2.585786437626905, 3.585786437626905, 4.585786437626905, 5.585786437626905, 6.585786437626905,
        };

        for (expect_upper, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, upper[i], 1e-9);
        }
        for (expect_middle, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, middle[i], 1e-9);
        }
        for (expect_lower, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, down[i], 1e-9);
        }
    }

    {
        const upper, const middle, const down = try BBands(prices[0..], period, 2, 3, MaType.SMA, allocator);
        defer allocator.free(upper);
        defer allocator.free(middle);
        defer allocator.free(down);

        const expect_upper = [_]f64{
            0, 0, 0, 0, 5.82842712474619, 6.82842712474619, 7.82842712474619, 8.82842712474619, 9.82842712474619, 10.82842712474619,
        };
        const expect_middle = [_]f64{
            0, 0, 0, 0, 3, 4, 5, 6, 7, 8,
        };
        const expect_lower = [_]f64{
            0, 0, 0, 0, -1.2426406871192857, -0.24264068711928566, 0.7573593128807143, 1.7573593128807143, 2.7573593128807143, 3.7573593128807143,
        };

        for (expect_upper, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, upper[i], 1e-9);
        }
        for (expect_middle, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, middle[i], 1e-9);
        }
        for (expect_lower, 0..) |v, i| {
            try std.testing.expectApproxEqAbs(v, down[i], 1e-9);
        }
    }
}

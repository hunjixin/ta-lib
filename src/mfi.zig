const std = @import("std");
const MyError = @import("./lib.zig").MyError;

const moneyFlow = struct {
    positive: f64,
    negative: f64,
};

/// Calculates the Money Flow Index (MFI) for a given financial DataFrame.
///
/// The Money Flow Index is a volume-weighted version of the Relative Strength Index (Rsi),
/// which uses both price and volume to measure buying and selling pressure.
/// It ranges from 0 to 100, and is typically used to identify overbought or oversold conditions.
///
/// Formula:
///     Typical Price (TP) = (High + Low + Close) / 3
///     Raw Money Flow = TP * Volume
///     Money Flow is classified as positive or negative depending on whether TP increased or decreased
///
///     Positive Money Flow = sum of Raw Money Flow on days where TP > previous TP
///     Negative Money Flow = sum of Raw Money Flow on days where TP < previous TP
///
///     Money Flow Index = 100 × (Positive Money Flow) / (Positive + Negative Money Flow)
///
/// Arguments:
/// - `high`: The high price of the asset.
/// - `low`: The low price of the asset.
/// - `close`: The closing price of the asset.
/// - `volume`: The trading volume of the asset.
/// - `inTimePeriod`: the lookback period over which to compute the MFI (typically 14)
/// - `allocator`: memory allocator used to allocate the result buffer
///
/// Returns:
/// - `![]f64`: an array of MFI values of the same length as the input data,
///             with the first `inTimePeriod` elements potentially uninitialized or zero.
///
/// Errors:
/// - Returns `MyError.RowColumnMismatch` if the input column lengths do not match.
/// - Returns any allocator error if memory allocation fails.
pub fn Mfi(high: []const f64, low: []const f64, close: []const f64, volume: []const f64, inTimePeriod: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = high.len;
    if (!(len == low.len and len == close.len and len == volume.len)) {
        return MyError.RowColumnMismatch;
    }

    var out = try allocator.alloc(f64, len);
    errdefer allocator.free(out);
    @memset(out, 0);

    if (inTimePeriod == 0 or inTimePeriod >= len) {
        return out;
    }

    var mflow = try allocator.alloc(moneyFlow, inTimePeriod);
    defer allocator.free(mflow);

    var mflow_idx: usize = 0;

    var pos_sum_mf: f64 = 0.0;
    var neg_sum_mf: f64 = 0.0;

    const lookback_total = inTimePeriod;
    const start_idx = lookback_total;
    var out_idx = start_idx;
    var today: usize = 0;

    var prev_tp = (high[today] + low[today] + close[today]) / 3.0;
    today += 1;

    var i = inTimePeriod;
    while (i > 0) : (i -= 1) {
        const tp = (high[today] + low[today] + close[today]) / 3.0;
        const diff = tp - prev_tp;
        prev_tp = tp;
        const raw_mf = tp * volume[today];

        if (diff < 0) {
            mflow[mflow_idx] = .{ .positive = 0.0, .negative = raw_mf };
            neg_sum_mf += raw_mf;
        } else if (diff > 0) {
            mflow[mflow_idx] = .{ .positive = raw_mf, .negative = 0.0 };
            pos_sum_mf += raw_mf;
        } else {
            mflow[mflow_idx] = .{ .positive = 0.0, .negative = 0.0 };
        }

        mflow_idx = (mflow_idx + 1) % inTimePeriod;
        today += 1;
    }

    while (today < len) {
        const total_mf = pos_sum_mf + neg_sum_mf;
        out[out_idx] = if (total_mf < 1.0) 0.0 else 100.0 * (pos_sum_mf / total_mf);
        out_idx += 1;

        pos_sum_mf -= mflow[mflow_idx].positive;
        neg_sum_mf -= mflow[mflow_idx].negative;

        const tp = (high[today] + low[today] + close[today]) / 3.0;
        const diff = tp - prev_tp;
        prev_tp = tp;
        const raw_mf = tp * volume[today];

        if (diff < 0) {
            mflow[mflow_idx] = .{ .positive = 0.0, .negative = raw_mf };
            neg_sum_mf += raw_mf;
        } else if (diff > 0) {
            mflow[mflow_idx] = .{ .positive = raw_mf, .negative = 0.0 };
            pos_sum_mf += raw_mf;
        } else {
            mflow[mflow_idx] = .{ .positive = 0.0, .negative = 0.0 };
        }

        mflow_idx = (mflow_idx + 1) % inTimePeriod;
        today += 1;
    }
    const total_mf = pos_sum_mf + neg_sum_mf;
    out[out_idx] = if (total_mf < 1.0) 0.0 else 100.0 * (pos_sum_mf / total_mf);
    return out;
}

test "Mfi calculation works correctly" {
    const gpa = std.testing.allocator;

    const high = [_]f64{ 13.27, 15.84, 11.46, 16.92, 14.15, 10.58, 18.33, 12.71, 17.49, 9.94, 19.02, 11.88, 13.63, 14.91, 16.47, 12.39, 15.02, 10.73, 17.76, 13.05 };
    const low = [_]f64{ 11.12, 13.91, 10.08, 15.44, 12.77, 9.86, 16.50, 11.62, 15.88, 8.94, 17.11, 10.55, 12.41, 13.59, 14.89, 10.94, 13.31, 9.21, 15.61, 11.82 };
    const close = [_]f64{ 12.20, 14.65, 10.90, 16.30, 13.60, 10.15, 17.40, 12.10, 16.73, 9.40, 18.15, 11.11, 13.02, 14.20, 15.69, 11.60, 14.30, 10.01, 16.80, 12.51 };
    const volume = [_]f64{ 1100.0, 980.0, 1250.0, 1490.0, 1320.0, 1180.0, 1600.0, 1410.0, 1530.0, 1010.0, 1650.0, 1200.0, 1370.0, 1450.0, 1590.0, 1110.0, 1420.0, 990.0, 1510.0, 1300.0 };

    const mfi = try Mfi(&high, &low, &close, &volume, 8, gpa);
    defer gpa.free(mfi);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 60.348502726357346, 52.55910246505028, 65.53225805467731, 54.35468782335134, 65.99564591567959, 75.24098796981298, 74.7860179661825, 76.8157258895238, 75.98143314243461, 75.79737022445899, 75.02961864784554, 73.61781718554698 };
    for (mfi, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

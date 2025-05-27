const std = @import("std");
const MyError = @import("./lib.zig").MyError;

/// Calculates the Hilbert Transform Trendline (HT Trendline) for a given array of prices.
///
/// This function applies the Hilbert Transform to the input price series to estimate the trendline,
/// which can be used for technical analysis in financial applications.
///
/// Parameters:
/// - `prices`: A slice of f64 values representing the input price series.
/// - `allocator`: The allocator to use for allocating the result array.
///
/// Returns:
/// - An allocated slice of f64 values containing the calculated trendline.
///
/// Errors:
/// - Returns an error if memory allocation fails.
///
/// Example:
/// ```zig
/// const trendline = try HtTrendLine(prices, allocator);
/// ```
pub fn HtTrendLine(prices: []const f64, allocator: std.mem.Allocator) ![]f64 {
    const a = 0.0962;
    const b = 0.5769;
    const lookback_total = 63;
    const max_idx_smooth_price = 49;

    var out = try allocator.alloc(f64, prices.len);
    @memset(out, 0);

    var detrender_odd: [3]f64 = .{0} ** 3;
    var detrender_even: [3]f64 = .{0} ** 3;
    var q1_odd: [3]f64 = .{0} ** 3;
    var q1_even: [3]f64 = .{0} ** 3;
    var jI_odd: [3]f64 = .{0} ** 3;
    var jI_even: [3]f64 = .{0} ** 3;
    var jQ_odd: [3]f64 = .{0} ** 3;
    var jQ_even: [3]f64 = .{0} ** 3;
    var smooth_price: [max_idx_smooth_price + 1]f64 = .{0} ** (max_idx_smooth_price + 1);

    var iTrend1: f64 = 0;
    var iTrend2: f64 = 0;
    var iTrend3: f64 = 0;
    const one: f64 = 1.0;
    const temp_atan: f64 = std.math.atan(one);
    const rad2deg = 45.0 / temp_atan;

    var period: f64 = 0;
    var smooth_period: f64 = 0;
    var previ2: f64 = 0;
    var prevq2: f64 = 0;
    var Re: f64 = 0;
    var Im: f64 = 0;
    var i1_for_odd_prev3: f64 = 0;
    var i1_for_even_prev3: f64 = 0;
    var i1_for_odd_prev2: f64 = 0;
    var i1_for_even_prev2: f64 = 0;

    var detrender: f64 = 0;
    var prev_detrender_odd: f64 = 0;
    var prev_detrender_even: f64 = 0;
    var prev_detrender_input_odd: f64 = 0;
    var prev_detrender_input_even: f64 = 0;
    var q1: f64 = 0;
    var prev_q1_odd: f64 = 0;
    var prev_q1_even: f64 = 0;
    var prev_q1_input_odd: f64 = 0;
    var prev_q1_input_even: f64 = 0;
    var jI: f64 = 0;
    var prev_jI_odd: f64 = 0;
    var prev_jI_even: f64 = 0;
    var prev_jI_input_odd: f64 = 0;
    var prev_jI_input_even: f64 = 0;
    var jQ: f64 = 0;
    var prev_jQ_odd: f64 = 0;
    var prev_jQ_even: f64 = 0;
    var prev_jQ_input_odd: f64 = 0;
    var prev_jQ_input_even: f64 = 0;
    var q2: f64 = 0;
    var ii2: f64 = 0;

    var smooth_price_idx: usize = 0;
    var hilbert_idx: usize = 0;

    const start_idx: usize = lookback_total;
    var trailing_wma_idx: usize = start_idx - lookback_total;
    var today: usize = trailing_wma_idx;

    // WMA initialization
    var period_wma_sub = prices[today];
    var period_wma_sum = prices[today];
    today += 1;
    period_wma_sub += prices[today];
    period_wma_sum += prices[today] * 2.0;
    today += 1;
    period_wma_sub += prices[today];
    period_wma_sum += prices[today] * 3.0;
    today += 1;

    var trailing_wma_value: f64 = 0;
    var i: usize = 34;
    while (i != 0) {
        const temp_real = prices[today];
        today += 1;
        period_wma_sub += temp_real;
        period_wma_sub -= trailing_wma_value;
        period_wma_sum += temp_real * 4.0;
        trailing_wma_value = prices[trailing_wma_idx];
        trailing_wma_idx += 1;
        period_wma_sum -= period_wma_sub;
        i -= 1;
    }

    var out_idx: usize = 63;

    while (today < prices.len) {
        const adjusted_prev_period = (0.075 * period) + 0.54;
        const today_value = prices[today];
        period_wma_sub += today_value;
        period_wma_sub -= trailing_wma_value;
        period_wma_sum += today_value * 4.0;
        trailing_wma_value = prices[trailing_wma_idx];
        trailing_wma_idx += 1;
        const smoothed_value = period_wma_sum * 0.1;
        period_wma_sum -= period_wma_sub;
        smooth_price[smooth_price_idx] = smoothed_value;

        if ((today & 1) == 0) {
            // even
            var hilbert_temp_real = a * smoothed_value;
            detrender = -detrender_even[hilbert_idx];
            detrender_even[hilbert_idx] = hilbert_temp_real;
            detrender += hilbert_temp_real;
            detrender -= prev_detrender_even;
            prev_detrender_even = b * prev_detrender_input_even;
            detrender += prev_detrender_even;
            prev_detrender_input_even = smoothed_value;
            detrender *= adjusted_prev_period;

            hilbert_temp_real = a * detrender;
            q1 = -q1_even[hilbert_idx];
            q1_even[hilbert_idx] = hilbert_temp_real;
            q1 += hilbert_temp_real;
            q1 -= prev_q1_even;
            prev_q1_even = b * prev_q1_input_even;
            q1 += prev_q1_even;
            prev_q1_input_even = detrender;
            q1 *= adjusted_prev_period;

            hilbert_temp_real = a * i1_for_even_prev3;
            jI = -jI_even[hilbert_idx];
            jI_even[hilbert_idx] = hilbert_temp_real;
            jI += hilbert_temp_real;
            jI -= prev_jI_even;
            prev_jI_even = b * prev_jI_input_even;
            jI += prev_jI_even;
            prev_jI_input_even = i1_for_even_prev3;
            jI *= adjusted_prev_period;

            hilbert_temp_real = a * q1;
            jQ = -jQ_even[hilbert_idx];
            jQ_even[hilbert_idx] = hilbert_temp_real;
            jQ += hilbert_temp_real;
            jQ -= prev_jQ_even;
            prev_jQ_even = b * prev_jQ_input_even;
            jQ += prev_jQ_even;
            prev_jQ_input_even = q1;
            jQ *= adjusted_prev_period;

            hilbert_idx += 1;
            if (hilbert_idx == 3) hilbert_idx = 0;

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1_for_even_prev3 - jQ)) + (0.8 * previ2);
            i1_for_odd_prev3 = i1_for_odd_prev2;
            i1_for_odd_prev2 = detrender;
        } else {
            // odd
            var hilbert_temp_real = a * smoothed_value;
            detrender = -detrender_odd[hilbert_idx];
            detrender_odd[hilbert_idx] = hilbert_temp_real;
            detrender += hilbert_temp_real;
            detrender -= prev_detrender_odd;
            prev_detrender_odd = b * prev_detrender_input_odd;
            detrender += prev_detrender_odd;
            prev_detrender_input_odd = smoothed_value;
            detrender *= adjusted_prev_period;

            hilbert_temp_real = a * detrender;
            q1 = -q1_odd[hilbert_idx];
            q1_odd[hilbert_idx] = hilbert_temp_real;
            q1 += hilbert_temp_real;
            q1 -= prev_q1_odd;
            prev_q1_odd = b * prev_q1_input_odd;
            q1 += prev_q1_odd;
            prev_q1_input_odd = detrender;
            q1 *= adjusted_prev_period;

            hilbert_temp_real = a * i1_for_odd_prev3;
            jI = -jI_odd[hilbert_idx];
            jI_odd[hilbert_idx] = hilbert_temp_real;
            jI += hilbert_temp_real;
            jI -= prev_jI_odd;
            prev_jI_odd = b * prev_jI_input_odd;
            jI += prev_jI_odd;
            prev_jI_input_odd = i1_for_odd_prev3;
            jI *= adjusted_prev_period;

            hilbert_temp_real = a * q1;
            jQ = -jQ_odd[hilbert_idx];
            jQ_odd[hilbert_idx] = hilbert_temp_real;
            jQ += hilbert_temp_real;
            jQ -= prev_jQ_odd;
            prev_jQ_odd = b * prev_jQ_input_odd;
            jQ += prev_jQ_odd;
            prev_jQ_input_odd = q1;
            jQ *= adjusted_prev_period;

            q2 = (0.2 * (q1 + jI)) + (0.8 * prevq2);
            ii2 = (0.2 * (i1_for_odd_prev3 - jQ)) + (0.8 * previ2);
            i1_for_even_prev3 = i1_for_even_prev2;
            i1_for_even_prev2 = detrender;
        }

        Re = (0.2 * ((ii2 * previ2) + (q2 * prevq2))) + (0.8 * Re);
        Im = (0.2 * ((ii2 * prevq2) - (q2 * previ2))) + (0.8 * Im);
        prevq2 = q2;
        previ2 = ii2;

        const temp_period = period;
        if (Im != 0.0 and Re != 0.0) {
            period = 360.0 / (std.math.atan(Im / Re) * rad2deg);
        }
        var temp_real2 = 1.5 * temp_period;
        if (period > temp_real2) period = temp_real2;
        temp_real2 = 0.67 * temp_period;
        if (period < temp_real2) period = temp_real2;
        if (period < 6.0) {
            period = 6.0;
        } else if (period > 50.0) {
            period = 50.0;
        }
        period = (0.2 * period) + (0.8 * temp_period);
        smooth_period = (0.33 * period) + (0.67 * smooth_period);

        const dc_period = smooth_period + 0.5;
        const dc_period_int = @floor(dc_period);
        const idx = today;
        var sum: f64 = 0.0;
        var j: usize = 0;
        while (j < @as(usize, @intFromFloat(dc_period_int)) and idx >= j) : (j += 1) {
            sum += prices[idx - j];
        }
        if (dc_period_int > 0) {
            sum = sum / (dc_period_int * 1.0);
        }
        temp_real2 = (4.0 * sum + 3.0 * iTrend1 + 2.0 * iTrend2 + iTrend3) / 10.0;
        iTrend3 = iTrend2;
        iTrend2 = iTrend1;
        iTrend1 = sum;

        if (today >= start_idx and out_idx < out.len) {
            out[out_idx] = temp_real2;
            out_idx += 1;
        }

        smooth_price_idx += 1;
        if (smooth_price_idx > max_idx_smooth_price) smooth_price_idx = 0;

        today += 1;
    }

    return out;
}

test "HtTrendLine work correctly" {
    var allocator = std.testing.allocator;
    const prices = [_]f64{
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
        1.5,  2.7,  3.6,  4.8,  5.2,  6.4,  7.9,  8.3,  9.1,  9.7,  10.2, 11.6, 12.8, 13.9, 14.5,
        82.4, 15.7, 63.2, 91.5, 27.8, 54.6, 39.1, 75.3, 44.2, 10.8, 67.5, 16.2, 23.9, 87.1, 19.6,
        10.1, 12.8, 11.4, 75.9, 13.7, 14.2, 13.5, 15.9, 14.8, 43.3, 32.6, 16.2, 13.4, 17.5, 76.1,
        65.8, 12.6, 11.9, 13.3, 13.7, 13.1, 13.8, 15.4, 14.2, 10.6, 17.3, 43.1, 18.9, 17.7, 19.2,
        1.5,  2.7,  3.6,  4.8,  5.2,  6.4,  7.9,  8.3,  9.1,  9.7,  10.2, 11.6, 12.8, 13.9, 14.5,
    };
    const result = try HtTrendLine(&prices, allocator);
    defer allocator.free(result);

    const expected = [_]f64{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19.1611428571, 21.3729747899, 23.8644705882, 25.0798916409, 27.0454179567, 29.1838390093, 31.1192397661, 33.6827777778, 35.3434210526, 36.5905555556, 38.9438888889, 41.2929738562, 42.7895424837, 43.5448039216, 42.0170588235, 41.6332352941, 39.5265441176, 37.7658823529, 35.7387500000, 33.7318750000, 30.7596250000, 29.6255416667, 29.2431250000, 27.9707083333, 27.2564166667, 24.7721250000, 24.9990714286, 27.0412857143, 28.7195714286, 28.1600000000, 27.1728571429, 26.2442857143, 25.7592857143, 25.6807142857, 25.6435714286, 25.3190000000, 24.2121428571, 23.0021428571, 22.9013333333, 23.3445714286, 22.1780952381, 19.9381904762, 17.8700000000, 16.2864285714, 15.3492857143, 14.6967582418, 14.0506043956, 13.3853846154, 12.7876923077, 12.3669230769, 11.8953846154, 10.5946153846, 9.4123076923, 8.4469230769, 7.7184615385, 7.7915384615, 8.2953846154 };
    for (result, 0..) |v, i| {
        try std.testing.expectApproxEqAbs(expected[i], v, 1e-9);
    }
}

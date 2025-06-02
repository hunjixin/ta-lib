const std = @import("std");

pub fn Cmo(prices: []const f64, period: usize, allocator: std.mem.Allocator) ![]f64 {
    const len = prices.len;
    var out = try allocator.alloc(f64, len);
    @memset(out, 0);

    if (period == 1) {
        @memcpy(out, prices);
        return out;
    }

    const periodf: f64 = @floatFromInt(period);
    const periodf2: f64 = @floatFromInt(period - 1);
    const lookback_total = period;
    const start_idx = lookback_total;
    var out_idx = start_idx;
    var today: usize = start_idx - lookback_total;
    var prev_value = prices[today];
    var prev_gain: f64 = 0.0;
    var prev_loss: f64 = 0.0;
    today += 1;

    var i: usize = period;
    while (i > 0) : (i -= 1) {
        const temp_value1 = prices[today];
        const temp_value2 = temp_value1 - prev_value;
        prev_value = temp_value1;
        if (temp_value2 < 0) {
            prev_loss -= temp_value2;
        } else {
            prev_gain += temp_value2;
        }
        today += 1;
    }
    prev_loss /= periodf;
    prev_gain /= periodf;

    if (today > start_idx) {
        const temp_value1 = prev_gain + prev_loss;
        if (!((-1e-14 < temp_value1) and (temp_value1 < 1e-14))) {
            out[out_idx] = 100.0 * ((prev_gain - prev_loss) / temp_value1);
        } else {
            out[out_idx] = 0.0;
        }
        out_idx += 1;
    } else {
        while (today < start_idx) {
            const temp_value1 = prices[today];
            const temp_value2 = temp_value1 - prev_value;
            prev_value = temp_value1;
            prev_loss *= periodf2;
            prev_gain *= periodf2;
            if (temp_value2 < 0) {
                prev_loss -= temp_value2;
            } else {
                prev_gain += temp_value2;
            }
            prev_loss /= periodf;
            prev_gain /= periodf;
            today += 1;
        }
    }

    while (today < len) {
        var temp_value1 = prices[today];
        today += 1;
        const temp_value2 = temp_value1 - prev_value;
        prev_value = temp_value1;
        prev_loss *= periodf2;
        prev_gain *= periodf2;
        if (temp_value2 < 0) {
            prev_loss -= temp_value2;
        } else {
            prev_gain += temp_value2;
        }
        prev_loss /= periodf;
        prev_gain /= periodf;
        temp_value1 = prev_gain + prev_loss;
        if (!((-1e-14 < temp_value1) and (temp_value1 < 1e-14))) {
            out[out_idx] = 100.0 * ((prev_gain - prev_loss) / temp_value1);
        } else {
            out[out_idx] = 0.0;
        }
        out_idx += 1;
    }

    return out;
}

test "Cmo computes  correctly" {
    const allocator = std.testing.allocator;

    // Test data: prices and period
    const prices = [_]f64{ 1.0, 2.0, 3.0, 4.0, 5.0, 4, 3, 2, 1, 1.0, 2.0, 3.0, 4.0, 5.0, 4, 3, 2, 1 };
    const period = 3;

    const result = try Cmo(&prices, period, allocator);
    defer allocator.free(result);

    const expected = [_]f64{
        0.000000000,
        0.000000000,
        0.000000000,
        100.000000000,
        100.000000000,
        33.333333333,
        -11.111111111,
        -40.740740741,
        -60.493827160,
        -60.493827160,
        8.289241623,
        44.176060118,
        64.823270759,
        77.375319519,
        15.535717449,
        -24.137169042,
        -49.927937160,
        -66.838566917,
    };
    for (expected, 0..) |exp, i| {
        try std.testing.expectApproxEqAbs(exp, result[i], 1e-9);
    }
}

const std = @import("std");
pub const Sma = @import("sma.zig").Sma;
pub const Ema = @import("ema.zig").Ema;
pub const Tema = @import("tema.zig").Tema;
pub const Trima = @import("trima.zig").Trima;
pub const Wma = @import("wma.zig").Wma;
pub const Dema = @import("dema.zig").Dema;
pub const Kama = @import("kama.zig").Kama;
pub const Mama = @import("mama.zig").Mama;
pub const T3 = @import("t3.zig").T3;

pub const MaType = enum {
    SMA, // Simple Moving Average
    EMA, // Exponential Moving Average
    WMA, // Weighted Moving Average
    DEMA, // Double Exponential Moving Average
    TEMA, // Triple Exponential Moving Average
    TRIMA, // Triangular Moving Average
    KAMA, // Kaufman's Adaptive Moving Average
    MAMA, // MESA Adaptive Moving Average
    T3MA, // T3 Moving Average
};

pub fn Ma(
    inReal: []const f64,
    inTimePeriod: usize,
    inMatype: MaType,
    allocator: std.mem.Allocator,
) ![]f64 {
    if (inTimePeriod == 1) {
        const out_real = try allocator.alloc(f64, inReal.len);
        @memcpy(out_real, inReal);
        return out_real;
    }

    return switch (inMatype) {
        .SMA => try Sma(inReal, inTimePeriod, allocator),
        .EMA => try Ema(inReal, inTimePeriod, allocator),
        .WMA => try Wma(inReal, inTimePeriod, allocator),
        .DEMA => try Dema(inReal, inTimePeriod, allocator),
        .TEMA => try Tema(inReal, inTimePeriod, allocator),
        .TRIMA => try Trima(inReal, inTimePeriod, allocator),
        .KAMA => try Kama(inReal, inTimePeriod, allocator),
        .MAMA => {
            const out_real, const _ignore = try Mama(inReal, 0.5, 0.05, allocator);
            allocator.free(_ignore);
            return out_real;
        },
        .T3MA => try T3(inReal, inTimePeriod, 0.7, allocator),
    };
}

const std = @import("std");
const lib = @import("../src/lib.zig");

pub fn main() void {
    const result = lib.add(10, 20);
    std.debug.print("10 + 20 = {}\n", .{result});
}

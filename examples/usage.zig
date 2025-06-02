const std = @import("std");
const DataFrame = @import("ta_lib").DataFrame;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var df = DataFrame(f64).init(allocator);
    defer df.deinit();

    try df.addColumnWithData("abc", &[_]f64{ 1, 2, 3 });
    const rowCount = df.getRowCount();
    std.debug.print("{any}\n", .{rowCount});
}

const std = @import("std");

pub const RingBuffer = struct {
    buffer: []u8,
    allocator: std.mem.Allocator,
    read: usize = 0,
    write: usize = 0,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) @This() {
        const buffer: []u8 = allocator.alloc(u8, capacity) catch @panic("Buffer allocation failed.");
        return .{ .buffer = buffer, .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.free(self.buffer);
        self.* = undefined;
    }

    pub fn set(self: *@This(), char: u8) void {
        self.buffer[self.mask(self.write)] = char;
        self.write = self.mask(self.write + 1);
    }

    pub fn get(self: *@This()) ?u8 {
        const item = self.buffer[self.read];
        if (item == 170) return null;
        self.read = self.mask(self.read + 1);
        return item;
    }

    pub fn debug(self: *@This()) void {
        std.debug.print("Ring buffer of len ({}): \n", .{self.buffer.len});
        for (self.buffer, 0..) |ch, i| {
            std.debug.print("({},{c}), ", .{ i, ch });
        }
        std.debug.print("\n", .{});
    }

    fn mask(self: @This(), numerator: usize) usize {
        return numerator % self.buffer.len;
    }
};

test "RingBuffer" {
    const al = std.testing.allocator;
    var rb = RingBuffer.init(al, 11);
    defer rb.deinit();
    for (97..123) |ch| {
        rb.set(@intCast(ch));
    }

    const item = rb.get();
    std.debug.print("{?}\n", .{item});
    rb.debug();
}

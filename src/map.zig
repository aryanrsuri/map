const std = @import("std");

pub const data = struct { key: []const u8, value: usize };
pub const HashMap = struct {
    array: []?data,
    allocator: *std.mem.Allocator,
    pub fn init(allocator: *std.mem.Allocator, capacity: usize) @This() {
        const array: []?data = allocator.*.alloc(?data, capacity) catch {
            @panic("Array allocation failed!");
        };
        @memset(array, null);
        return .{ .array = array, .allocator = allocator };
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.*.free(self.array);
        self.* = undefined;
    }

    pub fn get(self: *@This(), key: []const u8) ?usize {
        var index = hash(key) % self.array.len;

        while (self.array[index] != null) : (index += 1) {
            if (std.mem.eql(u8, self.array[index].?.key, key)) return self.array[index].?.value;
            if (index == self.array.len - 1) break;
        }
        return null;
    }

    pub fn set(self: *@This(), key: []const u8, value: usize) void {
        if (self.size() >= self.array.len * 3 / 4) self.grow(self.array.len * 2);

        var index = hash(key) % self.array.len;
        while (self.array[index]) |item| : (index = (index + 1) % self.array.len) {
            if (std.mem.eql(u8, item.key, key)) {
                self.array[index].?.value = value;
                return;
            }
        }

        self.array[index] = .{ .key = key, .value = value };
    }

    pub fn delete(self: *@This(), key: []const u8) !void {
        var index = hash(key) % self.array.len;
        while (!std.mem.eql(u8, self.array[index].?.key, key)) : (index += 1) {
            if (index == self.array.len - 1) return error.KeyNotFound;
        }
        self.array[index] = null;
    }

    pub fn debug(self: *@This(), title: ?[]const u8) void {
        if (title) |string| {
            std.debug.print("\n{s}\n", .{string});
        }
        std.debug.print("Index\tKey\tValue\n", .{});
        for (self.array, 0..) |option, index| {
            if (option != null) {
                std.debug.print("{}\t{s}\t{d}\n", .{ index, option.?.key, option.?.value });
            }
        }
    }

    fn grow(self: *@This(), capacity: usize) void {
        const grown = self.allocator.realloc(self.array, capacity) catch {
            @panic("HashMap reallocation failed.");
        };
        for (grown[self.array.len..]) |*item| {
            item.* = null;
        }
        self.array = grown;
    }

    fn size(self: *@This()) usize {
        var count: usize = 0;
        for (self.array) |item| {
            if (item != null) count += 1;
        }
        return count;
    }

    fn hash(key: []const u8) usize {
        var h: usize = 0xcbf29ce484222325;
        for (key) |char| {
            h = (h ^ char) *% 0x100000001b3;
        }
        return h;
    }
};

test "Hash Map" {
    var allocator = std.testing.allocator;
    var hm = HashMap.init(&allocator, 6);
    defer hm.deinit();
    {
        hm.set("key", 1);
        hm.set("key1", 2);
        hm.set("key3", 4);
        hm.set("key4", 5);
        hm.set("key5", 6);
        hm.set("key6", 3);
        hm.set("key2", 3);
        hm.set("key7", 3);
        hm.set("key8", 1000);
        hm.set("key8", 100);
        hm.set("key8", 10);
        try std.testing.expectEqual(10, hm.get("key8"));
        try std.testing.expectEqual(null, hm.get("key9"));

        hm.debug("HashMap with key8");
        _ = try hm.delete("key8");
        hm.debug("HashMap without key8");
    }
}

test "HashMap practical" {
    var allocator = std.testing.allocator;
    var hm = HashMap.init(&allocator, 1_000);
    defer hm.deinit();
    const buffer = @embedFile("./utils/the_great_gatsby_fitzgerald.txt");
    var words = std.mem.splitAny(u8, buffer, " \n\t\r.");

    const start = std.time.milliTimestamp();
    while (words.next()) |word| {
        if (word.len == 0) continue;
        if (hm.get(word)) |count| {
            hm.set(word, count + 1);
        } else {
            hm.set(word, 1);
        }
    }
    const end = std.time.milliTimestamp();
    std.debug.print("Generated frequency map (including the iteration) of Great Gatsby took {} seconds long\n", .{@divFloor(end - start, 1000)});
    {
        const start2 = std.time.nanoTimestamp();
        const count = hm.get("suddenly");
        const end2 = std.time.nanoTimestamp();
        std.debug.print("{s} appeared {?} times\n", .{ "suddenly", count });
        std.debug.print("Indexting the hashmap for one key took {} nanoseconds  long\n", .{(end2 - start2)});
        std.debug.print("{} items in array\n", .{hm.size()});
    }
}

# Exemple

Minimal reproducer for a compiler crash triggered by `zigimg.Image.fromMemory(...)`.

Failed only for Debug build, all versions of -Doptimize=Release* compile OK.


## Reproduction

```bash
zig build
```


## Expected result

The Zig compiler terminates with `SIGSEGV` while compiling the executable.

The reproducer uses:

- Zig version `0.17.0-dev.93+76174e1bc`
- official dependency `https://github.com/zigimg/zigimg` at commit `c7e81a13bff1cf4c5b7f085a8360f9d551143d40`
- a small embedded PNG file loaded via `std.Io.Dir.cwd().readFileAlloc(...)`
- one call to `zigimg.Image.fromMemory(...)`

### Example of output message
```
$ zig build
install
└─ install zig_test1
   └─ compile exe zig_test1 Debug native failure
error: process terminated with signal SEGV
failed command: /home/tomas/Applications/zig-x86_64-linux-0.17.0-dev.93+76174e1bc/zig build-exe -ODebug --dep zigimg -Mroot=/home/tomas/git-osobni-github/zig-test/src/main.zig -ODebug --dep zigimg -Mzigimg=/home/tomas/git-osobni-github/zig-test/zig-pkg/zigimg-0.1.0-8_eo2uScFwCnpzB1Y2n_jf3euDfMEeCLxJE_E5_W5BNe/zigimg.zig --cache-dir .zig-cache --global-cache-dir /home/tomas/.cache/zig --name zig_test1 --zig-lib-dir /home/tomas/Applications/zig-x86_64-linux-0.17.0-dev.93+76174e1bc/lib/ --listen=-

Build Summary: 0/3 steps succeeded (1 failed)
install transitive failure
└─ install zig_test1 transitive failure
   └─ compile exe zig_test1 Debug native failure

error: the following build command failed with exit code 1:
.zig-cache/o/9b065196263e224b8058b24c2aa8a7bc/build /home/tomas/Applications/zig-x86_64-linux-0.17.0-dev.93+76174e1bc/zig /home/tomas/Applications/zig-x86_64-linux-0.17.0-dev.93+76174e1bc/lib /home/tomas/git-osobni-github/zig-test .zig-cache /home/tomas/.cache/zig --seed 0x2949daf1 -Za2ffc6b52b2ad03f
```

## Probable cause

image.zig
```
const all_interface_funcs = blk: {
    const all_formats_delcs = std.meta.declarations(SupportedFormats);
    var result: []const FormatInteraceFnType = &[0]FormatInteraceFnType{};
    for (all_formats_delcs) |decl| {
        const decl_value = @field(SupportedFormats, decl.name);
        const entry_type = @TypeOf(decl_value);
        if (entry_type == type) {
            const entry_type_info = @typeInfo(decl_value);
            if (entry_type_info == .@"struct") {
                for (entry_type_info.@"struct".decls) |struct_entry| {
                    if (std.mem.eql(u8, struct_entry.name, "formatInterface")) {
                        result = result ++ [_]FormatInteraceFnType{
                            @field(decl_value, struct_entry.name),
                        };
                        break;
                    }
                }
            }
        }
    }
    break :blk result[0..];
};
```

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

The actual cause is the self-hosted x86_64 codegen backend (src/codegen/x86_64/CodeGen.zig) cannot handle AIR instructions on types with abiSize == 0. The triggering function TGA.writeColorMap16 constructs a color.Rgb555 packed struct, which has a to ToMethods(...) = .{} field - and ToMethods(...) is just a container of declarations with no fields, i.e. zero-sized.
During codegen for this field, a chain of unreachable / assert > 0 panics fires across many sites (isPowerOfTwo, ceilPowerOfTwo, registerAlias, genSetMem, genSetReg, select/convert pattern matching, getResolvedInstValue).

Why Release passes: Release backend = LLVM, which has correct zero-size handling.
Why Debug crashes: Debug default uses a self-hosted x86_64 backend.

A full fix requires systematically adding zero-size handling at every relevant site in CodeGen.zig.
I tried 4 local patches, and each one uncovered another unreachable further down the chain, so the cascade is deep and non-trivial.

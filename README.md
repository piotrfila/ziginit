# ziginit

This is my attempt at writing an init system in [Zig](https://ziglang.org).
Runtime configuration is limited by design, the init system is intended to be configured at compile time.
Currently only linux running on x86-64 is supported.

## License

This work is licensed under the MIT license ([LICENSE-MIT](LICENSE-MIT) or https://opensource.org/licenses/MIT)

## Dependencies

To make an initial cpio archive for linux and run the init system you need cpio and qemu respectively.

## Contribution

PRs are welcome!

Unless you explicitly state otherwise, any contribution
intentionally submitted for inclusion in the work by you
shall be licensed as above, without any additional terms or conditions.

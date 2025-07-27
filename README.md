# ziginit

This is my attempt at writing an init system in [Zig](https://ziglang.org).
Runtime configuration is limited by design, the init system is intended to be configured at compile time.
Currently only linux running on x86-64 is supported.

## Usage

To create an initrd at `zig-out/rootfs.cpio` execute `zig build mkcpio`.

To run in a virtual machine using qemu, with 1 vcpu and 1 GiB of memory execute the following command: </br>
`zig build run-vm -- -smp 1 -m 1G -nographic -kernel <path-to-kernel> -append console=ttyS0`

Options following `--` are passed through to qemu.
You can also specify a different architecture with `-Darch=<architecture>`.


## License

This work is licensed under the MIT license ([LICENSE-MIT](LICENSE-MIT) or https://opensource.org/licenses/MIT)

## Dependencies

To make an initial cpio archive for linux and run the init system you need cpio and qemu respectively.

## Contribution

PRs are welcome!

Unless you explicitly state otherwise, any contribution
intentionally submitted for inclusion in the work by you
shall be licensed as above, without any additional terms or conditions.

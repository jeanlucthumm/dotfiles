# Loader shim for prebuilt (non-Nix) binaries.
#
# Anything from pip/uv/npm/curl is a manylinux binary that hardcodes
# /lib64/ld-linux-x86-64.so.2, which does not exist on NixOS. nix-ld puts a shim
# there that re-execs the real loader with NIX_LD_LIBRARY_PATH, so foreign
# binaries and anything they later dlopen can find their deps.
#
# Caveat worth remembering: this only applies to processes started via the
# foreign loader. A Nix-provided interpreter (e.g. nixpkgs' python) importing a
# manylinux wheel is started by Nix's own loader, so nix-ld never runs and the
# wheel's .so files still need LD_LIBRARY_PATH set in the project's devenv.
{
  flake.modules.nixos.dev = {pkgs, ...}: {
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        # Baseline C/C++ runtime almost every prebuilt binary wants
        stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
        zlib
        zstd
        xz
        openssl
        curl
        libxml2
        ncurses
        glib
        glibc

        # GPU compute. The ROCm PyTorch wheels vendor their own HIP/rocBLAS
        # under torch/lib, but still link these against the system.
        libdrm # libdrm.so.2, libdrm_amdgpu.so.1
        numactl # libnuma.so.1
        elfutils # libelf.so.1, wanted by ROCr/comgr

        # Enough graphics/X to keep GUI-ish wheels (opencv, matplotlib) loading
        libGL
        libxkbcommon
        libx11
        libxext
        libxrender
      ];
    };
  };
}

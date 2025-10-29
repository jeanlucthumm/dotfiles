{pkgs, config, ...}: {
  # Set ROCm support globally for this system
  nixpkgs.config.rocmSupport = true;

  environment.systemPackages = with pkgs; [
    # Whisper-cpp with ROCm support for AMD GPUs
    (whisper-cpp.override {
      rocmSupport = true;
      rocmPackages = rocmPackages;
    })

    # CLI-compatible whisper client (CPU only)
    whisper-ctranslate2

    # Python package for scripting if needed
    python312Packages.faster-whisper

    # Audio processing tools
    ffmpeg-full
    sox

    # ROCm tools for debugging
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
  ];

  # ROCm runtime support for AMD GPU acceleration
  hardware.graphics.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    rocmPackages.hipblas
    rocmPackages.rocblas
    rocmPackages.rocsolver
    rocmPackages.rocm-runtime
  ];

  # Environment variables for ROCm
  environment.variables = {
    HSA_OVERRIDE_GFX_VERSION = "11.0.0"; # For RX 7900 XT/XTX (gfx1100)
    ROCM_PATH = "${pkgs.rocmPackages.clr}";
  };
}
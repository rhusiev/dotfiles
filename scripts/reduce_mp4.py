#!/usr/bin/env python3

import subprocess
import sys
from pathlib import Path
import shutil
import argparse
import os
from datetime import datetime


class VideoCompressor:
    def __init__(
        self,
        output_codec: str = "hevc",
        crf_value: int = 23,
        preset: str = "medium",
        use_nvidia: bool = False,
    ):
        self.output_codec = output_codec
        self.crf_value = crf_value
        self.preset = preset
        self.use_nvidia = use_nvidia

        self.cpu_codecs = {
            "hevc": "libx265",
            "h265": "libx265",  # h265 and hevc are the same
            "av1": "libaom-av1",
            "h264": "libx264",
        }

        self.nvidia_codecs = {
            "hevc": "hevc_nvenc",
            "h265": "hevc_nvenc",
            "av1": "av1_nvenc",
            "h264": "h264_nvenc",
        }

        if not self._check_ffmpeg_available():
            raise RuntimeError("FFmpeg not found. Please install FFmpeg.")

        if self.use_nvidia:
            self._check_nvidia_support()

    def _check_ffmpeg_available(self) -> bool:
        return shutil.which("ffmpeg") is not None

    def _check_nvidia_support(self) -> None:
        """Check if NVIDIA GPU encoding is available"""
        try:
            subprocess.run(["nvidia-smi"], capture_output=True, check=True)
            result = subprocess.run(
                ["ffmpeg", "-encoders"], capture_output=True, text=True, check=True
            )
            available_encoders = []
            if "hevc_nvenc" in result.stdout:
                available_encoders.append("HEVC")
            if "av1_nvenc" in result.stdout:
                available_encoders.append("AV1")
            if "h264_nvenc" in result.stdout:
                available_encoders.append("H.264")
            if available_encoders:
                print(
                    f"✓ NVIDIA GPU encoders available: {', '.join(available_encoders)}"
                )
            else:
                print(
                    "Warning: No NVIDIA encoders found in FFmpeg. Using CPU encoding."
                )
                self.use_nvidia = False
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(
                "Warning: NVIDIA GPU not detected or drivers not installed. Using CPU encoding."
            )
            self.use_nvidia = False

    def _test_nvidia_encoder(self, encoder: str) -> bool:
        """Test if a specific NVIDIA encoder actually works"""
        try:
            test_cmd = [
                "ffmpeg",
                "-f",
                "lavfi",
                "-i",
                "testsrc2=duration=1:size=320x240:rate=1",
                "-c:v",
                encoder,
                "-preset",
                "fast",
                "-f",
                "null",
                "-",
            ]
            result = subprocess.run(
                test_cmd, capture_output=True, text=True, timeout=10
            )
            return result.returncode == 0
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            return False

    def _get_compression_command(
        self, input_path: Path, output_path: Path
    ) -> list[str]:
        if self.use_nvidia and self.output_codec.lower() in self.nvidia_codecs:
            encoder = self.nvidia_codecs[self.output_codec.lower()]
            if not self._test_nvidia_encoder(encoder):
                print(
                    f"Warning: {encoder} not supported on this GPU. Falling back to CPU."
                )
                encoder = self.cpu_codecs[self.output_codec.lower()]
                is_nvidia = False
            else:
                is_nvidia = True
        else:
            encoder = self.cpu_codecs.get(self.output_codec.lower())
            is_nvidia = False

        if not encoder:
            raise ValueError(f"Unsupported codec: {self.output_codec}")

        base_cmd = [
            "ffmpeg",
            "-i",
            str(input_path),
            "-c:v",
            encoder,
            "-c:a",
            "copy",
            "-y",
        ]

        if is_nvidia:
            if encoder in ["hevc_nvenc", "h264_nvenc"]:
                base_cmd.extend(
                    [
                        "-preset",
                        self.preset,
                        "-rc",
                        "vbr",
                        "-cq",
                        str(self.crf_value),
                        "-qmin",
                        str(max(0, self.crf_value - 5)),
                        "-qmax",
                        str(min(51, self.crf_value + 5)),
                    ]
                )
                if encoder == "hevc_nvenc":
                    base_cmd.extend(["-profile:v", "main"])
            elif encoder == "av1_nvenc":
                base_cmd.extend(
                    [
                        "-preset",
                        self.preset,
                        "-rc",
                        "vbr",
                        "-cq",
                        str(self.crf_value),
                        "-qmin",
                        str(max(0, self.crf_value - 5)),
                        "-qmax",
                        str(min(63, self.crf_value + 5)),
                    ]
                )
        else:
            if encoder in ["libx265", "libx264"]:
                base_cmd.extend(["-preset", self.preset, "-crf", str(self.crf_value)])
            elif encoder == "libaom-av1":
                base_cmd.extend(["-crf", str(self.crf_value), "-cpu-used", "4"])

        base_cmd.append(str(output_path))
        return base_cmd

    def _calculate_compression_ratio(
        self, original_size: int, compressed_size: int
    ) -> float:
        if original_size == 0:
            return 0.0
        return (1 - compressed_size / original_size) * 100

    def _is_video_file(self, file_path: Path) -> bool:
        """Check if a file is a video file based on extension"""
        video_extensions = {".mp4", ".mkv", ".mov", ".avi", ".webm"}
        return file_path.suffix.lower() in video_extensions

    def _get_video_files_from_directory(
        self, 
        directory_path: Path, 
        output_suffix: str, 
        recursive: bool = False,
        newer_than_timestamp: float = 0.0
    ) -> list[Path]:
        """
        Get all video files from a directory, optionally recursively.
        Optionally filters files older than newer_than_timestamp.
        """
        video_files = []
        
        iterator = directory_path.rglob("*") if recursive else directory_path.iterdir()

        for file_path in iterator:
            if not file_path.is_file():
                continue
                
            if not self._is_video_file(file_path):
                continue
                
            if file_path.stem.endswith(output_suffix):
                continue

            if newer_than_timestamp > 0:
                if file_path.stat().st_mtime < newer_than_timestamp:
                    continue

            video_files.append(file_path)
        
        return sorted(video_files)

    def _get_compressed_files_from_directory(
        self, directory_path: Path, output_suffix: str, recursive: bool = False
    ) -> list[Path]:
        """Get all compressed files from a directory, optionally recursively"""
        compressed_files = []
        
        if recursive:
            for file_path in directory_path.rglob("*"):
                if (file_path.is_file() and 
                    self._is_video_file(file_path) and 
                    file_path.stem.endswith(output_suffix)):
                    compressed_files.append(file_path)
        else:
            for file_path in directory_path.iterdir():
                if (file_path.is_file() and 
                    self._is_video_file(file_path) and 
                    file_path.stem.endswith(output_suffix)):
                    compressed_files.append(file_path)
        
        return sorted(compressed_files)

    def compress_file(
        self, input_path: Path, output_suffix: str = "_compressed"
    ) -> tuple[bool, str]:
        if not input_path.exists():
            return False, f"Input file does not exist: {input_path}"

        output_path = input_path.with_name(
            f"{input_path.stem}{output_suffix}{input_path.suffix}"
        )

        try:
            compression_command = self._get_compression_command(input_path, output_path)
            print(f"Compressing: {input_path}")
            print(f"Command: {' '.join(compression_command)}")

            subprocess.run(
                compression_command, capture_output=True, text=True, check=True
            )

            if output_path.exists():
                original_size = input_path.stat().st_size
                compressed_size = output_path.stat().st_size
                compression_ratio = self._calculate_compression_ratio(
                    original_size, compressed_size
                )
                size_info = (
                    f"Original: {original_size / (1024 * 1024):.1f}MB, "
                    f"Compressed: {compressed_size / (1024 * 1024):.1f}MB, "
                    f"Reduction: {compression_ratio:.1f}%"
                )
                return True, f"Successfully compressed. {size_info}"
            else:
                return False, "Output file was not created"

        except subprocess.CalledProcessError as e:
            return False, f"FFmpeg error: {e.stderr}"
        except Exception as e:
            return False, f"Unexpected error: {str(e)}"

    def _replace_original(
        self, original_path: Path, compressed_path: Path
    ) -> tuple[bool, str, str | None]:
        """
        Validates the compressed file and replaces the original.
        Returns a tuple: (success, message, reason_code).
        reason_code can be 'LARGER_FILE' or 'IO_ERROR'.
        """
        if not compressed_path.exists():
            return False, f"Compressed file not found: {compressed_path.name}", "IO_ERROR"

        try:
            compressed_size = compressed_path.stat().st_size
            original_size = original_path.stat().st_size

            if compressed_size == 0:
                return False, "Compressed file is empty (0 bytes). Not replacing.", "IO_ERROR"

            if compressed_size >= original_size:
                message = f"Compressed file ({compressed_size / (1024*1024):.1f}MB) is not smaller than original ({original_size / (1024*1024):.1f}MB)."
                return False, message, "LARGER_FILE"

            original_path.unlink()
            compressed_path.rename(original_path)
            return True, f"Replaced {original_path} with compressed version.", None

        except Exception as e:
            return False, f"Error during file replacement: {e}", "IO_ERROR"

    def process_files(
        self, 
        file_paths: list[Path], 
        output_suffix: str = "_compressed",
        replace_iteratively: bool = False,
    ) -> None:
        """Process a list of specific files"""
        valid_files = []
        for file_path in file_paths:
            if not file_path.exists():
                print(f"Warning: File does not exist: {file_path}")
                continue
            if not self._is_video_file(file_path):
                print(f"Warning: Not a video file: {file_path}")
                continue
            if file_path.stem.endswith(output_suffix):
                print(f"Warning: Already compressed file: {file_path}")
                continue
            valid_files.append(file_path)

        if not valid_files:
            print("No valid video files to process.")
            return

        total_files = len(valid_files)
        print(f"Processing {total_files} video files")
        encoder_type = "NVIDIA GPU" if self.use_nvidia else "CPU"
        print(
            f"Using {encoder_type} codec: {self.output_codec} (CRF: {self.crf_value}, Preset: {self.preset})"
        )
        print("-" * 50)

        self._process_file_list(valid_files, output_suffix, replace_iteratively)

    def process_directory(
        self,
        directory_path: Path,
        output_suffix: str = "_compressed",
        replace_iteratively: bool = False,
        recursive: bool = False,
        newer_than_timestamp: float = 0.0,
    ) -> None:
        """Compresses all valid video files in a directory."""
        video_files = self._get_video_files_from_directory(
            directory_path, output_suffix, recursive, newer_than_timestamp
        )

        if not video_files:
            scope = "recursively" if recursive else "in directory"
            date_msg = ""
            if newer_than_timestamp > 0:
                date_str = datetime.fromtimestamp(newer_than_timestamp).strftime('%Y-%m-%d %H:%M:%S')
                date_msg = f" newer than {date_str}"
            
            print(f"No new video files found to compress {scope}{date_msg}.")
            return

        total_files = len(video_files)
        scope = "recursively" if recursive else "in directory"
        print(f"Found {total_files} video files to compress {scope}")
        encoder_type = "NVIDIA GPU" if self.use_nvidia else "CPU"
        print(
            f"Using {encoder_type} codec: {self.output_codec} (CRF: {self.crf_value}, Preset: {self.preset})"
        )
        print("-" * 50)

        self._process_file_list(video_files, output_suffix, replace_iteratively)

    def _process_file_list(
        self,
        video_files: list[Path],
        output_suffix: str,
        replace_iteratively: bool,
    ) -> None:
        """Common processing logic for both directory and file processing"""
        successful_compressions = 0
        failed_count = 0
        total_original_size = 0
        total_compressed_size = 0
        total_files = len(video_files)

        for i, video_file in enumerate(video_files, 1):
            original_size = video_file.stat().st_size
            total_original_size += original_size

            success, message = self.compress_file(video_file, output_suffix)
            compressed_file = video_file.with_name(
                f"{video_file.stem}{output_suffix}{video_file.suffix}"
            )

            if success:
                successful_compressions += 1

                if compressed_file.exists():
                    compressed_size = compressed_file.stat().st_size
                    total_compressed_size += compressed_size
                print(f"✓ {message}")

                if replace_iteratively:
                    replace_success, replace_message, reason_code = self._replace_original(
                        video_file, compressed_file
                    )
                    if replace_success:
                        print(f"✓ {replace_message}")
                    else:
                        print(f"✗ Replacement failed: {replace_message}")
                        if reason_code == "LARGER_FILE" and compressed_file.exists():
                            try:
                                compressed_file.unlink()
                                print(f"  -> Deleted oversized compressed file: {compressed_file.name}")
                            except OSError as e:
                                print(f"  -> Error deleting oversized file: {e}")
            else:
                failed_count += 1
                print(f"✗ Failed to compress {video_file}: {message}")

            print("-" * 25)
            print(f"Files processed: {i} / {total_files}")
            print(f"Files left: {total_files - i}")
            print(f"Files failed: {failed_count}")
            print("-" * 25)
            print()

        print("-" * 50)
        print("Compression complete.")
        print(f"  - Succeeded: {successful_compressions}")
        print(f"  - Failed: {failed_count}")
        print(f"  - Total: {total_files}")

        if total_original_size > 0 and total_compressed_size > 0:
            overall_ratio = self._calculate_compression_ratio(
                total_original_size, total_compressed_size
            )
            print(f"Overall size reduction: {overall_ratio:.1f}%")
            print(
                f"Total space saved: {(total_original_size - total_compressed_size) / (1024 * 1024):.1f}MB"
            )

    def process_replacements(
        self, 
        directory_path: Path, 
        output_suffix: str,
        recursive: bool = False,
    ) -> None:
        """Scans for existing compressed files and replaces originals without re-compressing."""
        scope = "recursively" if recursive else "in directory"
        print(f"--- Running in Replace-Only Mode {scope} ---")
        print(f"Scanning for files ending with '{output_suffix}.<ext>'...")

        compressed_files = self._get_compressed_files_from_directory(directory_path, output_suffix, recursive)

        if not compressed_files:
            print(f"No compressed files found to process {scope}.")
            return

        print(
            f"Found {len(compressed_files)} potential compressed files. Checking for originals..."
        )
        replacements_done = 0

        for compressed_file in compressed_files:
            original_stem = compressed_file.stem.removesuffix(output_suffix)
            original_file = compressed_file.with_name(
                f"{original_stem}{compressed_file.suffix}"
            )

            if original_file.exists():
                print(f"\nProcessing replacement for: {original_file}")
                print(f"  Original: {original_file.name}")
                print(f"  Compressed: {compressed_file.name}")

                success, message, reason_code = self._replace_original(
                    original_file, compressed_file
                )
                if success:
                    print(f"✓ {message}")
                    replacements_done += 1
                else:
                    print(f"✗ {message}")
                    if reason_code == "LARGER_FILE" and compressed_file.exists():
                        try:
                            compressed_file.unlink()
                            print(f"  -> Deleted oversized compressed file: {compressed_file.name}")
                        except OSError as e:
                            print(f"  -> Error deleting oversized file: {e}")
            else:
                print(
                    f"-> Original file not found for '{compressed_file.name}', skipping."
                )

        print("-" * 50)
        scope = "recursively" if recursive else "in directory"
        print(f"Replacement scan complete {scope}. {replacements_done} files replaced.")


def main():
    parser = argparse.ArgumentParser(
        description="Compress video files with modern codecs like HEVC, AV1, etc."
    )
    CPU_PRESETS = [
        "ultrafast",
        "superfast",
        "veryfast",
        "faster",
        "fast",
        "medium",
        "slow",
        "slower",
        "veryslow",
    ]
    NVIDIA_PRESETS = [
        "slow",
        "medium",
        "fast",
        "p1",
        "p2",
        "p3",
        "p4",
        "p5",
        "p6",
        "p7",
    ]

    parser.add_argument(
        "--directory",
        type=str,
        default=".",
        help="Directory to process (default: current directory)",
    )
    parser.add_argument(
        "--files",
        nargs="+",
        help="Specific files to process (alternative to --directory)",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Process directories recursively",
    )
    parser.add_argument(
        "--newer-than",
        type=str,
        default=None,
        help="Only process files newer than this date (ISO format, e.g., '2023-01-01' or '2023-01-01T15:30:00')",
    )
    parser.add_argument(
        "--suffix",
        default="_compressed",
        help="Suffix for compressed files (default: _compressed)",
    )
    parser.add_argument(
        "--codec",
        choices=["hevc", "h265", "av1", "h264"],
        default="hevc",
        help="Output codec (default: hevc).",
    )
    parser.add_argument(
        "--crf",
        type=int,
        default=23,
        help="Constant Quality value (lower=better, default: 23 for NVENC, 28 for x265)",
    )
    parser.add_argument(
        "--preset",
        default="medium",
        help=f"Encoding preset. CPU: {CPU_PRESETS}. NVIDIA: {NVIDIA_PRESETS}.",
    )
    parser.add_argument(
        "--nvidia", action="store_true", help="Use NVIDIA GPU acceleration if available"
    )
    parser.add_argument(
        "--replace-iteratively",
        action="store_true",
        help="Automatically replace the original video with the compressed version if compression is valid.",
    )
    parser.add_argument(
        "--replace-existing",
        action="store_true",
        help="Scan for existing compressed files and replace originals without re-compressing.",
    )

    args = parser.parse_args()

    timestamp_threshold = 0.0
    if args.newer_than:
        try:
            dt = datetime.fromisoformat(args.newer_than)
            timestamp_threshold = dt.timestamp()
            print(f"Info: Filter active. Including files newer than: {dt}")
        except ValueError:
            print("Error: Invalid date format for --newer-than.")
            print("Please use ISO format. Examples: '2023-12-31' or '2023-12-31T23:59:00'")
            sys.exit(1)

    if args.nvidia:
        if args.preset not in NVIDIA_PRESETS:
            print(f"Error: Invalid preset '{args.preset}' for NVIDIA encoding.")
            print(f"Please choose one of: {', '.join(NVIDIA_PRESETS)}")
            sys.exit(1)
    else:
        if args.preset not in CPU_PRESETS:
            print(f"Error: Invalid preset '{args.preset}' for CPU encoding.")
            print(f"Please choose one of: {', '.join(CPU_PRESETS)}")
            sys.exit(1)

    if args.replace_iteratively and args.replace_existing:
        print(
            "Error: --replace-iteratively and --replace-existing are mutually exclusive."
        )
        sys.exit(1)

    if args.files and args.recursive:
        print(
            "Error: --files and --recursive are mutually exclusive. Use --files for specific files or --recursive for directory processing."
        )
        sys.exit(1)

    try:
        # Use a different default CRF for NVIDIA as it's less sensitive
        # A CRF of 23 on NVENC is much higher quality than 23 on x265
        crf_value = args.crf
        if args.nvidia and parser.get_default("crf") == args.crf:
            print(
                "Info: Using default CRF 23 for NVIDIA. This is a high quality setting."
            )
        elif not args.nvidia and parser.get_default("crf") == args.crf:
            print(
                "Info: Using default CRF 23 for CPU. This is a medium quality setting."
            )

        compressor = VideoCompressor(args.codec, crf_value, args.preset, args.nvidia)

        if args.files:
            file_paths = [Path(file_path).resolve() for file_path in args.files]
            compressor.process_files(file_paths, args.suffix, args.replace_iteratively)
        else:
            directory_path = Path(args.directory).resolve()

            if not directory_path.is_dir():
                print(f"Error: Directory does not exist: {directory_path}")
                sys.exit(1)

            if args.replace_existing:
                compressor.process_replacements(directory_path, args.suffix, args.recursive)
            else:
                compressor.process_directory(
                    directory_path, 
                    args.suffix, 
                    args.replace_iteratively, 
                    args.recursive, 
                    timestamp_threshold
                )

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

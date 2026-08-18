#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# AutoFFmpegGui v2 - PyQt6
# Modernized rewrite of ffmpegx.pb + ffmpegx_include.pb (Linux & Windows)
# Requires ffmpeg + ffprobe + ffplay on PATH (or in applications/).

import json
import os
import re
import sys
import time
import shutil
import stat
import subprocess
import tempfile
import tarfile
import urllib.request
import zipfile
import platform
from pathlib import Path

from PyQt6.QtCore import Qt, QThread, QSettings, QSize, QUrl, pyqtSignal
from PyQt6.QtGui import QDesktopServices, QFont, QIcon, QIntValidator
from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QPushButton, QLineEdit, QLabel,
    QGroupBox, QTabWidget, QComboBox, QSlider, QCheckBox, QSpinBox,
    QPlainTextEdit, QListWidget, QListWidgetItem, QFileDialog,
    QMessageBox, QProgressBar, QTextBrowser, QHBoxLayout, QVBoxLayout,
    QGridLayout,
)

APP_DIR = os.path.dirname(os.path.abspath(__file__))
IS_WINDOWS = os.name == "nt"
CONFIG_FILE = os.path.join(APP_DIR, "config.ini")
BINARY_DIR = os.path.join(APP_DIR, "applications")
PAYPAL_URL = "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=4278562"


def static_ffmpeg_source():
    if IS_WINDOWS:
        return ("https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/"
                "ffmpeg-master-latest-win64-gpl.zip", "Windows 64-bit ZIP")
    if platform.system() == "Linux" and platform.machine().lower() in (
            "x86_64", "amd64"):
        return ("https://johnvansickle.com/ffmpeg/releases/"
                "ffmpeg-release-amd64-static.tar.xz", "Linux amd64 TAR.XZ")
    return None, "unsupported platform"


def static_ffplay_sources():
    if IS_WINDOWS:
        return [
            ("https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip",
             "Windows stable essentials ZIP"),
        ]
    if platform.system() == "Linux" and platform.machine().lower() in (
            "x86_64", "amd64"):
        return [
            ("https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/"
             "ffmpeg-master-latest-linux64-gpl.tar.xz",
             "Linux amd64 GPL TAR.XZ fallback"),
        ]
    return []


def app_settings():
    return QSettings(CONFIG_FILE, QSettings.Format.IniFormat)

CODECS = {
    "x264": "libx264", "x265": "libx265",
    "vp9": "libvpx-vp9", "av1": "libsvtav1",
    "mpeg4": "mpeg4", "xvid": "libxvid",
    "mpeg2": "mpeg2video", "wmv": "wmv2", "prores": "prores_ks",
    "dnxhd": "dnxhd", "ffv1": "ffv1",
}
X_PRESETS = ["ultrafast", "superfast", "veryfast", "faster", "fast",
             "medium", "slow", "slower", "veryslow"]
BUILTIN_PRESETS = (
    ["H.264 - " + p for p in X_PRESETS]
    + ["H.265 - " + p for p in X_PRESETS]
    + ["H.264 - CRF", "H.265 - CRF", "MPEG-4", "Xvid", "MPEG-2", "WMV",
       "H.264 - Copy video"]
)
HW_ACCELS = {
    "None": None,
    "NVIDIA NVENC": "nvenc",
    "Intel QSV": "qsv",
    "AMD AMF": "amf",
    "VAAPI": "vaapi",
    "Apple VideoToolbox": "videotoolbox",
}
HW_ENCODERS = {
    ("x264", "nvenc"): "h264_nvenc", ("x264", "qsv"): "h264_qsv",
    ("x264", "amf"): "h264_amf", ("x264", "vaapi"): "h264_vaapi",
    ("x264", "videotoolbox"): "h264_videotoolbox",
    ("x265", "nvenc"): "hevc_nvenc", ("x265", "qsv"): "hevc_qsv",
    ("x265", "amf"): "hevc_amf", ("x265", "vaapi"): "hevc_vaapi",
    ("x265", "videotoolbox"): "hevc_videotoolbox",
    ("vp9", "vaapi"): "vp9_vaapi",
    ("av1", "nvenc"): "av1_nvenc", ("av1", "qsv"): "av1_qsv",
    ("av1", "vaapi"): "av1_vaapi",
}
HW_QUALITY_OPT = {"nvenc": "-cq", "qsv": "-global_quality",
                  "amf": "-qp", "vaapi": "-global_quality",
                  "videotoolbox": "-q:v"}
HW_INIT = {"qsv": ["-init_hw_device", "qsv=hw"],
           "vaapi": ["-init_hw_device", "vaapi=va:/dev/dri/renderD128"]}
AUDIO_CODECS = ["AAC", "MP3", "FLAC", "OGG (Vorbis)", "AC-3", "Copy"]
AUDIO_BITRATES = ["320", "256", "224", "192", "160", "128", "96", "64", "48"]


def detect_hw_encoders():
    encoders = set()
    try:
        p = subprocess.run([FFMPEG, "-hide_banner", "-encoders"],
                           capture_output=True, text=True, errors="replace",
                           timeout=15)
        for line in p.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 2 and len(parts[0]) == 6 and parts[0][0] == "V":
                encoders.add(parts[1])
    except Exception:
        pass
    return encoders

HDR_MODES = [
    "Auto (match source)",
    "SDR (tone map to BT.709)",
    "HDR10 (BT.2020 / PQ)",
    "HLG (BT.2020 / HLG)",
    "HDR10+ (dynamic metadata)",
    "Dolby Vision (source RPU)",
]
DEFAULT_MASTER = "G(13250,34500)B(7500,3000)R(34000,16000)WP(15635,16450)L(10000000,1)"
DEFAULT_CL = "1000,400"

LANG_NAMES = {
    "eng": "English", "ita": "Italian", "fra": "French", "fre": "French",
    "spa": "Spanish", "deu": "German", "ger": "German", "por": "Portuguese",
    "jpn": "Japanese", "kor": "Korean", "chi": "Chinese", "zho": "Chinese",
    "rus": "Russian", "ara": "Arabic", "hin": "Hindi", "tur": "Turkish",
    "pol": "Polish", "nld": "Dutch", "dut": "Dutch", "swe": "Swedish",
    "nor": "Norwegian", "dan": "Danish", "fin": "Finnish", "ces": "Czech",
    "cze": "Czech", "ell": "Greek", "gre": "Greek", "heb": "Hebrew",
    "tha": "Thai", "vie": "Vietnamese", "ind": "Indonesian",
    "msa": "Malay", "may": "Malay", "cat": "Catalan", "ron": "Romanian",
    "rum": "Romanian", "hun": "Hungarian", "ukr": "Ukrainian",
    "bul": "Bulgarian", "hrv": "Croatian", "srp": "Serbian",
    "slk": "Slovak", "slo": "Slovak", "slv": "Slovenian",
    "est": "Estonian", "lav": "Latvian", "lit": "Lithuanian",
    "isl": "Icelandic", "afr": "Afrikaans", "lat": "Latin",
    "mul": "Multiple", "und": "Unknown", "zxx": "No linguistic content",
}


def lang_name(code):
    code = (code or "").strip().lower().split("-")[0]
    return LANG_NAMES.get(code, code.capitalize() if code else "")

THEMES = {
    "dark": {
        "bg": "#1e1e2e", "panel": "#181825", "field": "#313244",
        "border": "#45475a", "hover": "#585b70", "pressed": "#313244",
        "disabled": "#292c3c", "accent": "#89b4fa", "accent_hover": "#a6adc8",
        "accent_fg": "#11111b", "danger": "#f38ba8", "danger_hover": "#eba0ac",
        "text": "#cdd6f4", "muted": "#a6adc8", "dim": "#6c7086",
        "success": "#a6e3a1", "slider_track": "#313244",
    },
    "light": {
        "bg": "#eef1f6", "panel": "#ffffff", "field": "#ffffff",
        "border": "#c9d2e0", "hover": "#e3e9f2", "pressed": "#d5deea",
        "disabled": "#e6eaf0", "accent": "#2563eb", "accent_hover": "#1d4ed8",
        "accent_fg": "#ffffff", "danger": "#dc2626", "danger_hover": "#b91c1c",
        "text": "#1f2430", "muted": "#4b5563", "dim": "#8a94a6",
        "success": "#16a34a", "slider_track": "#d5deea",
    },
}


def make_style(p):
    return f"""
* {{ outline: none; }}
QMainWindow, QWidget {{ background-color: {p['bg']}; color: {p['text']}; font-size: 13px; }}
QGroupBox {{ border: 1px solid {p['border']}; border-radius: 8px; margin-top: 0.9em;
            padding-top: 0.3em; background: {p['panel']}; font-weight: 600; }}
QGroupBox::title {{ subcontrol-origin: margin; left: 10px; padding: 0 5px; color: {p['accent']}; }}
QLineEdit, QPlainTextEdit, QComboBox, QSpinBox, QListWidget {{
    background: {p['field']}; border: 1px solid {p['border']}; border-radius: 6px;
    padding: 2px 5px; color: {p['text']}; selection-background-color: {p['accent']};
    selection-color: {p['accent_fg']}; }}
QLineEdit:focus, QComboBox:focus, QSpinBox:focus {{ border: 1px solid {p['accent']}; }}
QLineEdit:disabled, QComboBox:disabled {{ color: {p['dim']}; background: {p['disabled']}; }}
QPushButton {{ background: {p['field']}; border: 1px solid {p['border']}; border-radius: 6px;
              padding: 3px 10px; color: {p['text']}; }}
QPushButton:hover {{ background: {p['hover']}; }}
QPushButton:pressed {{ background: {p['pressed']}; }}
QPushButton:disabled {{ background: {p['disabled']}; color: {p['dim']}; border-color: {p['border']}; }}
QPushButton#primary {{ background: {p['accent']}; color: {p['accent_fg']}; font-weight: 600; }}
QPushButton#primary:hover {{ background: {p['accent_hover']}; }}
QPushButton#danger {{ background: {p['danger']}; color: {p['accent_fg']}; }}
QPushButton#danger:hover {{ background: {p['danger_hover']}; }}
QTabWidget::pane {{ border: 1px solid {p['border']}; border-radius: 6px; background: {p['panel']}; }}
QTabBar::tab {{ background: {p['field']}; color: {p['muted']}; padding: 4px 12px;
               border-top-left-radius: 6px; border-top-right-radius: 6px;
               margin-right: 2px; }}
QTabBar::tab:selected {{ background: {p['accent']}; color: {p['accent_fg']}; font-weight: 600; }}
QSlider::groove:horizontal {{ height: 6px; background: {p['slider_track']}; border-radius: 3px; }}
QSlider::handle:horizontal {{ width: 14px; margin: -5px 0; border-radius: 7px;
                             background: {p['accent']}; }}
QCheckBox {{ spacing: 6px; }}
QCheckBox::indicator {{ width: 15px; height: 15px; border-radius: 4px;
                       border: 1px solid {p['border']}; background: {p['field']}; }}
QCheckBox::indicator:checked {{ background: {p['accent']}; border-color: {p['accent']}; }}
QProgressBar {{ border: 1px solid {p['border']}; border-radius: 6px; background: {p['field']};
               text-align: center; color: {p['text']}; }}
QProgressBar::chunk {{ background: {p['success']}; border-radius: 5px; }}
QStatusBar {{ background: {p['panel']}; color: {p['muted']}; }}
QStatusBar::item {{ border: none; }}
QComboBox QAbstractItemView {{ background: {p['field']}; color: {p['text']};
                              selection-background-color: {p['accent']}; }}
QToolTip {{ background: {p['field']}; color: {p['text']}; border: 1px solid {p['border']}; }}
"""


def find_binary(name):
    local = os.path.join(BINARY_DIR, name + (".exe" if IS_WINDOWS else ""))
    if os.path.exists(local):
        return local
    found = shutil.which(name)
    return found if found else name


FFMPEG = find_binary("ffmpeg")
FFPROBE = find_binary("ffprobe")
FFPLAY = find_binary("ffplay")


def refresh_binaries():
    global FFMPEG, FFPROBE, FFPLAY
    FFMPEG = find_binary("ffmpeg")
    FFPROBE = find_binary("ffprobe")
    FFPLAY = find_binary("ffplay")


def detect_family(args):
    a = args.lower()
    if "libsvtav1" in a or "libaom" in a or "av1" in a:
        return "av1"
    if "libvpx-vp9" in a or "vp9" in a:
        return "vp9"
    if "h265" in a or "x265" in a or "libx265" in a or "hevc" in a:
        return "x265"
    if "h264" in a or "x264" in a or "libx264" in a:
        return "x264"
    if "xvid" in a:
        return "xvid"
    if "mpeg2" in a:
        return "mpeg2"
    if "wmv" in a or "wmav2" in a or "vc1" in a:
        return "wmv"
    if "mpeg4" in a:
        return "mpeg4"
    if "prores" in a:
        return "prores"
    if "dnxhr" in a or "dnxhd" in a:
        return "dnxhd"
    if "ffv1" in a:
        return "ffv1"
    return "x264"


def pb_profile_parse(lines):
    out, seen = [], set()
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(";")
        name = parts[0].strip()
        if not name or name in seen:
            continue
        args = parts[3].strip() if len(parts) > 3 and parts[3].strip() else (
            parts[1].strip() if len(parts) > 1 else "")
        out.append((name, args))
        seen.add(name)
    return out


class EncodeJob:
    def __init__(self, label, cmd, duration=0.0):
        self.label = label
        self.cmd = cmd
        self.duration = duration


class EncodeThread(QThread):
    log_line = pyqtSignal(str)
    progress = pyqtSignal(int, str)
    stats = pyqtSignal(str)
    job_started = pyqtSignal(int, str)
    job_done = pyqtSignal(int, int)
    all_done = pyqtSignal()

    def __init__(self, jobs, parent=None):
        super().__init__(parent)
        self.jobs = jobs
        self._proc = None
        self._cancel = False

    def cancel(self):
        self._cancel = True
        if self._proc and self._proc.poll() is None:
            self._proc.terminate()

    def run(self):
        total = len(self.jobs)
        for i, job in enumerate(self.jobs):
            if self._cancel:
                break
            self.job_started.emit(i, job.label)
            try:
                self._proc = subprocess.Popen(
                    job.cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                    text=True, bufsize=1, errors="replace")
            except OSError as e:
                self.log_line.emit(f"[error] cannot start process: {e}")
                self.job_done.emit(i, -1)
                continue
            start = time.time()
            last_emit = 0.0
            frac = 0.0
            best_frac = 0.0
            fps = speed = "-"
            for line in self._proc.stdout:
                line = line.rstrip()
                self.log_line.emit(line)
                if job.duration:
                    m = re.search(r"time=(\d+):(\d+):(\d+)(?:\.(\d+))?", line)
                    if m:
                        h, mi, s = int(m.group(1)), int(m.group(2)), int(m.group(3))
                        fs = m.group(4) or ""
                        frac_s = float("0." + fs) if fs else 0.0
                        t = h * 3600 + mi * 60 + s + frac_s
                        frac = min(1.0, t / job.duration)
                        if frac > best_frac:
                            best_frac = frac
                        pct = int(((i + best_frac) / total) * 100)
                        self.progress.emit(pct, job.label)
                m = re.search(r"fps=\s*([\d.]+)", line)
                if m:
                    fps = m.group(1)
                m = re.search(r"speed=\s*([\d.]+)x", line)
                if m:
                    speed = m.group(1)
                now = time.time()
                if now - last_emit >= 0.4:
                    last_emit = now
                    elapsed = now - start
                    bf = best_frac if best_frac > 0.01 else frac
                    eta = elapsed * (1 - bf) / bf if bf > 0.01 else elapsed
                    self.stats.emit(
                        f"fps {fps}  ·  {speed}x  ·  ETA {int(eta // 60):02d}:{int(eta % 60):02d}")
                if self._cancel:
                    self._proc.terminate()
                    break
            self._proc.wait()
            self.job_done.emit(i, self._proc.returncode)
        self.all_done.emit()


class FfmpegDownloadThread(QThread):
    progress = pyqtSignal(int)
    status = pyqtSignal(str)
    succeeded = pyqtSignal(str)
    failed = pyqtSignal(str)

    def run(self):
        url, archive_label = static_ffmpeg_source()
        if not url:
            self.failed.emit(f"Unsupported platform: {archive_label}")
            return
        suffix = ".zip" if url.lower().endswith(".zip") else ".tar.xz"
        archive = os.path.join(tempfile.gettempdir(),
                              "autoffmpeg-static-download" + suffix)
        fallback_archives = []
        try:
            self.status.emit(f"Downloading {archive_label}...")
            request = urllib.request.Request(
                url, headers={"User-Agent": "AutoFFmpegGui/2"})
            with urllib.request.urlopen(request, timeout=60) as response:
                total = int(response.headers.get("Content-Length", 0) or 0)
                done = 0
                with open(archive, "wb") as out:
                    while True:
                        chunk = response.read(1024 * 1024)
                        if not chunk:
                            break
                        out.write(chunk)
                        done += len(chunk)
                        if total:
                            self.progress.emit(min(95, int(done * 95 / total)))
            self.status.emit("Extracting FFmpeg binaries...")
            os.makedirs(BINARY_DIR, exist_ok=True)
            installed = self.extract_binaries(
                archive, required=("ffmpeg", "ffprobe"), optional=("ffplay",))
            if not self.has_binary("ffplay"):
                self.status.emit("ffplay not found in main archive")
                system_ffplay = shutil.which("ffplay")
                if system_ffplay:
                    self.status.emit(f"Using system ffplay: {system_ffplay}")
                    shutil.copy2(system_ffplay, self.binary_path("ffplay"))
                    if not IS_WINDOWS:
                        os.chmod(self.binary_path("ffplay"),
                                 os.stat(self.binary_path("ffplay")).st_mode |
                                 stat.S_IXUSR)
                    installed.append("ffplay (system fallback)")
                else:
                    for index, (fallback_url, fallback_label) in enumerate(
                            static_ffplay_sources()):
                        fallback_suffix = (".zip" if fallback_url.lower().endswith(".zip")
                                           else ".tar.xz")
                        fallback_archive = os.path.join(
                            tempfile.gettempdir(),
                            f"autoffmpeg-ffplay-fallback-{index}{fallback_suffix}")
                        fallback_archives.append(fallback_archive)
                        try:
                            self.status.emit(
                                f"Downloading ffplay fallback: {fallback_label}...\n"
                                f"{fallback_url}")
                            self.download_archive(fallback_url, fallback_archive)
                            self.status.emit("Extracting ffplay fallback...")
                            self.extract_binaries(
                                fallback_archive, required=("ffplay",))
                            installed.append("ffplay (fallback archive)")
                            break
                        except Exception as fallback_error:
                            self.status.emit(f"ffplay fallback failed: {fallback_error}")
                    if not self.has_binary("ffplay"):
                        raise RuntimeError(
                            "ffplay not found in main archive, system PATH, or fallback archive")
            self.status.emit(
                f"Extraction complete: {', '.join(installed)} installed")
            self.progress.emit(100)
            self.succeeded.emit(BINARY_DIR)
        except Exception as exc:
            self.failed.emit(str(exc))
        finally:
            try:
                os.remove(archive)
            except OSError:
                pass
            for fallback_archive in fallback_archives:
                try:
                    os.remove(fallback_archive)
                except OSError:
                    pass

    @staticmethod
    def binary_path(name):
        return os.path.join(BINARY_DIR, name + (".exe" if IS_WINDOWS else ""))

    @classmethod
    def has_binary(cls, name):
        return os.path.exists(cls.binary_path(name))

    def download_archive(self, url, archive):
        request = urllib.request.Request(
            url, headers={"User-Agent": "AutoFFmpegGui/2"})
        with urllib.request.urlopen(request, timeout=60) as response, open(archive, "wb") as out:
            shutil.copyfileobj(response, out)

    def extract_binaries(self, archive, required=("ffmpeg", "ffprobe", "ffplay"),
                         optional=()):
        installed = []
        names = required + optional
        if archive.endswith(".zip"):
            with zipfile.ZipFile(archive) as package:
                members = package.namelist()
                for name in names:
                    member = next((m for m in members
                                   if Path(m).name.lower() == name + ".exe"), None)
                    if not member:
                        if name in required:
                            raise RuntimeError(f"{name}.exe not found in archive")
                        continue
                    target = self.binary_path(name)
                    with package.open(member) as src, open(target, "wb") as dst:
                        shutil.copyfileobj(src, dst)
                    installed.append(name)
        else:
            with tarfile.open(archive, mode="r:xz") as package:
                members = package.getmembers()
                for name in names:
                    member = next((m for m in members
                                   if Path(m.name).name == name), None)
                    if not member:
                        if name in required:
                            raise RuntimeError(f"{name} not found in archive")
                        continue
                    source = package.extractfile(member)
                    if source is None:
                        raise RuntimeError(f"cannot extract {name}")
                    target = self.binary_path(name)
                    with source, open(target, "wb") as dst:
                        shutil.copyfileobj(source, dst)
                    os.chmod(target, os.stat(target).st_mode | stat.S_IXUSR)
                    installed.append(name)
        return installed


class AutoFfmpegGui(QMainWindow):

    def __init__(self):
        super().__init__()
        self.setWindowTitle("AutoFFmpegGui v2")
        self.theme = "dark"
        self.apply_theme(self.theme)
        self.setMinimumSize(900, 980)
        self.resize(1040, 1100)

        self.inputfile = ""
        self.outputfile = ""
        self.lastdir = ""
        self.auto_output = True
        self.probe = None
        self.vstream = None
        self.duration = 0.0
        self.vwidth = 0
        self.vheight = 0
        self.framerate = 0.0
        self.source_hdr_info = None   # (primaries, transfer, colorspace)
        self.source_dv = False
        self.dv_profile = None
        self.audio_tracks = []
        self.audio_rows = []
        self.subtitle_tracks = []
        self.subtitle_rows = []
        self.thread = None
        self.download_thread = None
        self.crop_worker = None
        self.available_encoders = detect_hw_encoders()

        self.build_ui()
        self.load_presets()
        self.load_settings()
        self.show_initial_info()

    # ------------------------------------------------------------------ #
    # UI
    # ------------------------------------------------------------------ #
    def build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        root = QVBoxLayout(central)
        root.setContentsMargins(10, 8, 10, 8)
        root.setSpacing(6)

        fg = QGroupBox("Files")
        fgrid = QGridLayout(fg)
        fgrid.addWidget(QLabel("Input:"), 0, 0)
        self.inp_input = QLineEdit()
        self.inp_input.setReadOnly(True)
        fgrid.addWidget(self.inp_input, 0, 1)
        self.btn_open = QPushButton("Browse...")
        fgrid.addWidget(self.btn_open, 0, 2)
        self.btn_play = QPushButton("Play")
        self.btn_play.setToolTip("Play the input file (ffplay)")
        fgrid.addWidget(self.btn_play, 0, 3)
        self.btn_preview = QPushButton("Preview")
        self.btn_preview.setToolTip("Preview with crop/resize/HDR applied (ffplay)")
        fgrid.addWidget(self.btn_preview, 0, 4)

        fgrid.addWidget(QLabel("Output:"), 1, 0)
        self.inp_output = QLineEdit()
        fgrid.addWidget(self.inp_output, 1, 1)
        self.btn_save = QPushButton("Browse...")
        fgrid.addWidget(self.btn_save, 1, 2)
        root.addWidget(fg)

        self.tabs = QTabWidget()
        self.tabs.addTab(self.build_video_tab(), "Audio / Video")
        self.tabs.addTab(self.build_queue_tab(), "Queue")
        self.tabs.addTab(self.build_info_tab(), "Info")
        self.tabs.addTab(self.build_manual_tab(), "Manual")
        self.tabs.addTab(self.build_log_tab(), "Log")
        self.tabs.addTab(self.build_ffmpeg_tab(), "FFmpeg")
        root.addWidget(self.tabs, 1)

        pg = QGroupBox("Encoding")
        prow = QHBoxLayout(pg)
        vcol = QVBoxLayout()
        self.progress = QProgressBar()
        self.progress.setRange(0, 100)
        self.lbl_stats = QLabel("")
        self.lbl_stats.setStyleSheet("color: #a6e3a1; font-family: monospace;")
        vcol.addWidget(self.progress)
        vcol.addWidget(self.lbl_stats)
        prow.addLayout(vcol, 1)
        self.lbl_status = QLabel("Ready")
        prow.addWidget(self.lbl_status)
        self.btn_cancel = QPushButton("Cancel")
        self.btn_cancel.setObjectName("danger")
        self.btn_cancel.setEnabled(False)
        self.btn_encode = QPushButton("Encode")
        self.btn_encode.setObjectName("primary")
        self.btn_encode.setToolTip("Start encoding (Ctrl+E)")
        self.btn_encode.setShortcut("Ctrl+E")
        self.btn_addqueue = QPushButton("Add to Queue")
        self.btn_startqueue = QPushButton("Start Queue")
        prow.addWidget(self.btn_cancel)
        prow.addWidget(self.btn_encode)
        prow.addWidget(self.btn_addqueue)
        prow.addWidget(self.btn_startqueue)
        root.addWidget(pg)

        self.statusBar().showMessage("Ready")
        self.paypal_btn = QPushButton()
        paypal_logo = os.path.join(APP_DIR, "_paypal_logo.png")
        if os.path.exists(paypal_logo):
            self.paypal_btn.setIcon(QIcon(paypal_logo))
            self.paypal_btn.setIconSize(QSize(85, 25))
            self.paypal_btn.setFixedSize(105, 35)
        else:
            self.paypal_btn.setText("Donate")
        self.paypal_btn.setToolTip("Support AutoFFmpegGui with PayPal")
        self.statusBar().addPermanentWidget(self.paypal_btn)
        self.paypal_btn.clicked.connect(self.open_paypal)
        self.theme_btn = QPushButton()
        self.theme_btn.setFixedSize(58, 24)
        self.theme_btn.setToolTip("Toggle light / dark theme")
        self.statusBar().addPermanentWidget(self.theme_btn)
        self.theme_btn.clicked.connect(self.toggle_theme)
        self.update_theme_button()

        self.btn_open.clicked.connect(self.openinputfile)
        self.btn_save.clicked.connect(self.savefile)
        self.btn_play.clicked.connect(self.play)
        self.btn_preview.clicked.connect(self.preview)
        self.btn_encode.clicked.connect(self.do_encode)
        self.btn_addqueue.clicked.connect(self.addtoqueue)
        self.btn_startqueue.clicked.connect(self.startqueue)
        self.btn_cancel.clicked.connect(self.cancel_encode)
        self.cmb_preset.currentIndexChanged.connect(self.on_preset_changed)
        self.cmb_mode.currentIndexChanged.connect(self.on_mode_changed)
        self.cmb_hw.currentIndexChanged.connect(self.on_mode_changed)
        self.cmb_hdr.currentIndexChanged.connect(self.on_hdr_changed)
        self.btn_hdr_meta.clicked.connect(self.choose_hdr_meta)
        self.sld_quality.valueChanged.connect(self.on_quality_changed)
        self.spin_quality.valueChanged.connect(self.sld_quality.setValue)
        self.chk_resize.toggled.connect(self.on_resize_toggled)
        self.btn_autocrop.clicked.connect(self.autocrop)
        self.btn_calc.clicked.connect(self.calc_bitrate)
        self.inp_cds.returnPressed.connect(self.calc_bitrate)
        self.inp_output.textEdited.connect(lambda _: setattr(self, "auto_output", False))
        self.sld_trackwidth.valueChanged.connect(lambda _: self.on_size_pct())
        self.inp_width.textEdited.connect(lambda _: self.silentscale())

    def open_paypal(self):
        QMessageBox.information(
            self, "Thanks For Your Support!",
            "Without your donation AutoFFmpegGui will be never a better application!")
        QDesktopServices.openUrl(QUrl(PAYPAL_URL))

    def build_ffmpeg_tab(self):
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setSpacing(10)
        title = QLabel("FFmpeg static binaries")
        title.setStyleSheet("font-size: 16px; font-weight: 600;")
        lay.addWidget(title)
        info = QLabel(
            "Download the latest static FFmpeg build for this operating system. "
            "The required ffmpeg, ffprobe and ffplay binaries are stored in "
            "applications/ and take priority over the system installation.")
        info.setWordWrap(True)
        lay.addWidget(info)
        self.ffmpeg_platform = QLabel("")
        self.ffmpeg_platform.setWordWrap(True)
        self.ffmpeg_platform.setTextInteractionFlags(
            Qt.TextInteractionFlag.TextSelectableByMouse)
        lay.addWidget(self.ffmpeg_platform)
        self.ffmpeg_progress = QProgressBar()
        self.ffmpeg_progress.setRange(0, 100)
        self.ffmpeg_progress.setValue(0)
        lay.addWidget(self.ffmpeg_progress)
        self.ffmpeg_status = QLabel("Ready")
        lay.addWidget(self.ffmpeg_status)
        row = QHBoxLayout()
        self.btn_download_ffmpeg = QPushButton("Download latest static FFmpeg")
        self.btn_download_ffmpeg.setObjectName("primary")
        self.btn_open_ffmpeg_dir = QPushButton("Open applications folder")
        row.addWidget(self.btn_download_ffmpeg)
        row.addWidget(self.btn_open_ffmpeg_dir)
        row.addStretch(1)
        lay.addLayout(row)
        lay.addStretch(1)
        url, label = static_ffmpeg_source()
        fallback_text = ""
        fallback_sources = static_ffplay_sources()
        if fallback_sources:
            fallback_text = "\nffplay fallback:\n" + "\n".join(
                f"{source_label}: {source_url}"
                for source_url, source_label in fallback_sources)
        self.ffmpeg_platform.setText(
            f"Source: {label}\n{url}{fallback_text}"
            if url else f"Not available: {label}")
        self.btn_download_ffmpeg.setEnabled(bool(url))
        self.btn_download_ffmpeg.clicked.connect(self.download_ffmpeg)
        self.btn_open_ffmpeg_dir.clicked.connect(self.open_ffmpeg_dir)
        return w

    def open_ffmpeg_dir(self):
        os.makedirs(BINARY_DIR, exist_ok=True)
        QDesktopServices.openUrl(QUrl.fromLocalFile(BINARY_DIR))

    def download_ffmpeg(self):
        if self.download_thread and self.download_thread.isRunning():
            return
        self.btn_download_ffmpeg.setEnabled(False)
        self.ffmpeg_progress.setValue(0)
        self.ffmpeg_status.setText("Starting download...")
        self._ffmpeg_last_logged_progress = -1
        url, _ = static_ffmpeg_source()
        self.log(f"[ffmpeg] download started: {url}")
        self.download_thread = FfmpegDownloadThread(self)
        self.download_thread.progress.connect(self.ffmpeg_download_progress)
        self.download_thread.status.connect(self.ffmpeg_download_status)
        self.download_thread.succeeded.connect(self.ffmpeg_download_done)
        self.download_thread.failed.connect(self.ffmpeg_download_failed)
        self.download_thread.start()

    def ffmpeg_download_progress(self, value):
        self.ffmpeg_progress.setValue(value)
        marker = value // 10 * 10
        if marker != self._ffmpeg_last_logged_progress and marker > 0:
            self._ffmpeg_last_logged_progress = marker
            self.log(f"[ffmpeg] download: {marker}%")

    def ffmpeg_download_status(self, message):
        self.ffmpeg_status.setText(message)
        self.log(f"[ffmpeg] {message}")

    def ffmpeg_download_done(self, directory):
        refresh_binaries()
        self.available_encoders = detect_hw_encoders()
        self.populate_hw()
        self.on_mode_changed()
        self.show_initial_info()
        self.ffmpeg_status.setText(f"Installed in {directory}")
        self.btn_download_ffmpeg.setEnabled(True)
        self.log(f"[ffmpeg] installed in {directory}")
        self.log(f"[ffmpeg] selected ffmpeg: {FFMPEG}")
        self.log(f"[ffmpeg] selected ffprobe: {FFPROBE}")
        self.log(f"[ffmpeg] selected ffplay: {FFPLAY}")
        self.log("[info] static FFmpeg binaries installed and selected")

    def ffmpeg_download_failed(self, message):
        self.ffmpeg_status.setText(f"Download failed: {message}")
        self.log(f"[ffmpeg] download/extraction failed: {message}")
        self.btn_download_ffmpeg.setEnabled(True)
        self.log(f"[error] FFmpeg download failed: {message}")

    def build_video_tab(self):
        w = QWidget()
        lay = QVBoxLayout(w)
        lay.setSpacing(10)
        columns = QHBoxLayout()
        columns.setSpacing(8)
        left = QVBoxLayout()
        left.setSpacing(10)
        right = QVBoxLayout()
        # QGroupBox titles are drawn in the top margin, so leave enough room
        # between stacked panels for the lower title to remain readable.
        right.setSpacing(24)

        # --- left column: video encoding ---
        vg = QGroupBox("Video encoding")
        vg.setMinimumHeight(300)
        gl = QGridLayout(vg)
        gl.setContentsMargins(8, 8, 8, 8)
        gl.setVerticalSpacing(2)
        gl.setHorizontalSpacing(6)
        gl.addWidget(QLabel("Preset:"), 0, 0)
        self.cmb_preset = QComboBox()
        gl.addWidget(self.cmb_preset, 0, 1, 1, 3)

        gl.addWidget(QLabel("Mode:"), 1, 0)
        self.cmb_mode = QComboBox()
        self.cmb_mode.addItems(
            ["Quality (CRF)", "1-pass bitrate", "2-pass bitrate", "Copy video"])
        gl.addWidget(self.cmb_mode, 1, 1, 1, 3)

        gl.addWidget(QLabel("HW accel:"), 2, 0)
        self.cmb_hw = QComboBox()
        self.cmb_hw.setToolTip(
            "Hardware accelerated encoders actually present in your ffmpeg build")
        gl.addWidget(self.cmb_hw, 2, 1, 1, 3)
        self.populate_hw()

        self.lbl_quality = QLabel("Quality:")
        self.lbl_quality.setToolTip("CRF or qscale quality; lower values mean higher quality")
        gl.addWidget(self.lbl_quality, 3, 0)
        self.sld_quality = QSlider(Qt.Orientation.Horizontal)
        self.sld_quality.setRange(0, 51)
        self.sld_quality.setValue(23)
        gl.addWidget(self.sld_quality, 3, 1, 1, 2)
        self.spin_quality = QSpinBox()
        self.spin_quality.setRange(0, 51)
        self.spin_quality.setValue(23)
        gl.addWidget(self.spin_quality, 3, 3)

        gl.addWidget(QLabel("Bitrate:"), 4, 0)
        self.inp_bitrate = QLineEdit("2000")
        self.inp_bitrate.setValidator(QIntValidator(0, 100000, self))
        gl.addWidget(self.inp_bitrate, 4, 1)
        gl.addWidget(QLabel("kbit/s"), 4, 2, 1, 2)

        gl.addWidget(QLabel("Target MB:"), 5, 0)
        self.inp_cds = QLineEdit("700")
        self.inp_cds.setValidator(QIntValidator(0, 100000, self))
        gl.addWidget(self.inp_cds, 5, 1)
        self.btn_calc = QPushButton("Calculate")
        gl.addWidget(self.btn_calc, 5, 2, 1, 2)

        gl.addWidget(QLabel("FPS:"), 6, 0)
        self.cmb_framerate = QComboBox()
        self.cmb_framerate.setEditable(True)
        self.cmb_framerate.addItems(
            ["automatic", "23.976", "24", "25", "29.97", "30", "50", "59.94", "60"])
        self.cmb_framerate.setCurrentIndex(0)
        gl.addWidget(self.cmb_framerate, 6, 1)
        gl.addWidget(QLabel("Frames:"), 6, 2)
        self.inp_vframes = QLineEdit()
        self.inp_vframes.setValidator(QIntValidator(0, 999999999, self))
        self.inp_vframes.setToolTip(
            "Maximum frames to encode. Leave empty for ALL frames.")
        gl.addWidget(self.inp_vframes, 6, 3)

        self.chk_deinterlace = QCheckBox("Deinterlace (yadif)")
        gl.addWidget(self.chk_deinterlace, 7, 0, 1, 4)

        source_box = QGroupBox("Source file")
        source_layout = QVBoxLayout(source_box)
        source_layout.setContentsMargins(8, 8, 8, 8)
        source_layout.setSpacing(2)
        source_box.setMaximumHeight(145)
        self.lbl_source_summary = QLabel("No file loaded")
        self.lbl_source_summary.setWordWrap(True)
        self.lbl_source_summary.setToolTip("Basic information about the loaded source")
        source_layout.addWidget(self.lbl_source_summary)
        left.addWidget(source_box)
        left.addWidget(vg)

        # --- full-width audio and subtitle selection ---
        ag = QGroupBox("Audio")
        gl = QGridLayout(ag)
        gl.setVerticalSpacing(2)
        gl.setHorizontalSpacing(6)
        tracks_label = QLabel("Tracks:")
        tracks_label.setFixedWidth(52)
        gl.addWidget(tracks_label, 0, 0, Qt.AlignmentFlag.AlignTop)
        self.audio_list = QListWidget()
        self.audio_list.setMinimumHeight(150)
        self.audio_list.setMaximumHeight(360)
        self.audio_list.setHorizontalScrollBarPolicy(
            Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.audio_list.setToolTip(
            "Select audio tracks and choose an encoding for each one.")
        gl.addWidget(self.audio_list, 0, 1, 1, 3)

        subs_label = QLabel("Subs:")
        subs_label.setFixedWidth(52)
        gl.addWidget(subs_label, 1, 0, Qt.AlignmentFlag.AlignTop)
        self.subtitle_list = QListWidget()
        self.subtitle_list.setMinimumHeight(80)
        self.subtitle_list.setMaximumHeight(180)
        self.subtitle_list.setHorizontalScrollBarPolicy(
            Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        self.subtitle_list.setToolTip("Select the subtitle tracks to include.")
        gl.addWidget(self.subtitle_list, 1, 1, 1, 3)

        self.chk_normalize = QCheckBox("Normalize loudness (loudnorm)")
        gl.addWidget(self.chk_normalize, 2, 0, 1, 2)
        gl.addWidget(QLabel("Gain:"), 2, 2)
        self.spin_gain = QSpinBox()
        self.spin_gain.setRange(-30, 30)
        self.spin_gain.setValue(0)
        self.spin_gain.setSuffix(" dB")
        gl.addWidget(self.spin_gain, 2, 3)
        gl.setColumnStretch(0, 0)
        gl.setColumnStretch(1, 1)
        gl.setColumnStretch(2, 0)
        gl.setColumnStretch(3, 1)
        # --- right column: resize + HDR ---
        rg = QGroupBox("Resize / crop")
        rl = QGridLayout(rg)
        rl.setContentsMargins(10, 10, 10, 10)
        rl.setVerticalSpacing(6)
        rl.setHorizontalSpacing(8)
        rg.setMinimumHeight(205)
        self.chk_resize = QCheckBox("Allow resize / crop")
        self.chk_resize.setChecked(True)
        rl.addWidget(self.chk_resize, 0, 0, 1, 3)

        self.inp_width = QLineEdit()
        self.inp_width.setValidator(QIntValidator(1, 99999, self))
        self.inp_height = QLineEdit()
        self.inp_height.setValidator(QIntValidator(1, 99999, self))
        self.cmb_mod = QComboBox()
        self.cmb_mod.addItems(["2", "4", "8", "16", "32"])
        self.cmb_mod.setCurrentText("16")
        wrow = QHBoxLayout()
        wrow.setSpacing(4)
        wrow.addWidget(QLabel("Size:"))
        wrow.addWidget(self.inp_width)
        wrow.addWidget(QLabel("x"))
        wrow.addWidget(self.inp_height)
        wrow.addWidget(QLabel("MOD:"))
        wrow.addWidget(self.cmb_mod)
        rl.addLayout(wrow, 1, 0, 1, 3)

        self.sld_trackwidth = QSlider(Qt.Orientation.Horizontal)
        self.sld_trackwidth.setRange(10, 200)
        self.sld_trackwidth.setValue(100)
        self.sld_trackwidth.setToolTip("Resize percentage")
        rl.addWidget(QLabel("Size %:"), 2, 0)
        rl.addWidget(self.sld_trackwidth, 2, 1, 1, 2)

        self.btn_autocrop = QPushButton("Auto crop")
        self.btn_autocrop.setToolTip("Detect black borders with ffmpeg cropdetect")
        rl.addWidget(self.btn_autocrop, 3, 0, 1, 3)

        self.inp_leftcrop = QLineEdit("0")
        self.inp_rightcrop = QLineEdit("0")
        self.inp_topcrop = QLineEdit("0")
        self.inp_bottomcrop = QLineEdit("0")
        for e in (self.inp_leftcrop, self.inp_rightcrop, self.inp_topcrop, self.inp_bottomcrop):
            e.setValidator(QIntValidator(0, 99999, self))
        croprow = QHBoxLayout()
        croprow.setSpacing(3)
        croprow.addWidget(QLabel("Crop:"))
        croprow.addWidget(self.inp_leftcrop)
        croprow.addWidget(QLabel("L"))
        croprow.addWidget(self.inp_rightcrop)
        croprow.addWidget(QLabel("R"))
        croprow.addWidget(self.inp_topcrop)
        croprow.addWidget(QLabel("T"))
        croprow.addWidget(self.inp_bottomcrop)
        croprow.addWidget(QLabel("B"))
        rl.addLayout(croprow, 4, 0, 1, 3)

        self.inp_dar = QLineEdit()
        self.inp_dar.setReadOnly(True)
        rl.addWidget(QLabel("DAR:"), 5, 0)
        rl.addWidget(self.inp_dar, 5, 1, 1, 2)
        right.addWidget(rg)

        hg = QGroupBox("HDR / Color")
        hl = QGridLayout(hg)
        hl.setContentsMargins(10, 10, 10, 10)
        hl.setVerticalSpacing(6)
        hl.setHorizontalSpacing(8)
        hg.setMinimumHeight(190)
        hl.addWidget(QLabel("Mode:"), 0, 0)
        self.cmb_hdr = QComboBox()
        self.cmb_hdr.addItems(HDR_MODES)
        self.cmb_hdr.setToolTip(
            "HDR10 / HLG: 10-bit BT.2020 with PQ/HLG.\n"
            "HDR10+: needs a JSON metadata file (hdr10plus_tool).\n"
            "Dolby Vision: re-encodes using the source DV RPU (libx265).")
        hl.addWidget(self.cmb_hdr, 0, 1, 1, 2)

        hl.addWidget(QLabel("HDR10+ file:"), 1, 0)
        self.inp_hdr_meta = QLineEdit()
        self.btn_hdr_meta = QPushButton("...")
        self.btn_hdr_meta.setFixedWidth(36)
        row = QHBoxLayout()
        row.addWidget(self.inp_hdr_meta)
        row.addWidget(self.btn_hdr_meta)
        hl.addLayout(row, 1, 1, 1, 2)

        hl.addWidget(QLabel("Master display:"), 2, 0)
        self.inp_masterdisplay = QLineEdit(DEFAULT_MASTER)
        self.inp_masterdisplay.setToolTip("x265 master-display metadata (BT.2020/P3)")
        hl.addWidget(self.inp_masterdisplay, 2, 1, 1, 2)

        hl.addWidget(QLabel("MaxCLL/FALL:"), 3, 0)
        self.inp_maxcll = QLineEdit(DEFAULT_CL)
        self.inp_maxcll.setToolTip("MaxCLL,MaxFALL in nits, e.g. 1000,400")
        hl.addWidget(self.inp_maxcll, 3, 1, 1, 2)

        self.lbl_hdrinfo = QLabel("")
        self.lbl_hdrinfo.setWordWrap(True)
        self.lbl_hdrinfo.setStyleSheet("color: #a6adc8;")
        hl.addWidget(self.lbl_hdrinfo, 4, 0, 1, 3)
        right.addWidget(hg)
        right.addStretch(1)
        columns.addLayout(left, 4)
        columns.addLayout(right, 6)
        columns.setStretch(0, 4)
        columns.setStretch(1, 6)
        lay.addLayout(columns, 0)
        lay.addWidget(ag)
        lay.addStretch(1)
        return w

    def build_queue_tab(self):
        w = QWidget()
        lay = QVBoxLayout(w)
        self.list_queue = QListWidget()
        lay.addWidget(self.list_queue, 1)
        row = QHBoxLayout()
        self.btn_remove_queue = QPushButton("Remove selected")
        self.btn_clear_queue = QPushButton("Clear")
        row.addWidget(self.btn_remove_queue)
        row.addWidget(self.btn_clear_queue)
        row.addStretch(1)
        lay.addLayout(row)
        self.btn_remove_queue.clicked.connect(self.remove_queue_item)
        self.btn_clear_queue.clicked.connect(self.list_queue.clear)
        return w

    def build_info_tab(self):
        w = QWidget()
        lay = QVBoxLayout(w)
        self.txt_info = QPlainTextEdit()
        self.txt_info.setReadOnly(True)
        lay.addWidget(self.txt_info, 1)
        return w

    def build_manual_tab(self):
        browser = QTextBrowser()
        browser.setOpenExternalLinks(True)
        browser.setOpenLinks(True)
        readme = os.path.join(APP_DIR, "MANUAL.md")
        try:
            with open(readme, encoding="utf-8", errors="replace") as fh:
                browser.setMarkdown(fh.read())
        except OSError as exc:
            browser.setPlainText(f"Unable to load the manual:\n{exc}")
        return browser

    def build_log_tab(self):
        w = QWidget()
        lay = QVBoxLayout(w)
        self.txt_log = QPlainTextEdit()
        self.txt_log.setReadOnly(True)
        self.txt_log.setMaximumBlockCount(3000)
        lay.addWidget(self.txt_log, 1)
        row = QHBoxLayout()
        btn = QPushButton("Clear log")
        btn.clicked.connect(self.txt_log.clear)
        row.addStretch(1)
        row.addWidget(btn)
        lay.addLayout(row)
        return w

    # ------------------------------------------------------------------ #
    # Logging / info
    # ------------------------------------------------------------------ #
    def log(self, msg):
        self.txt_log.appendPlainText(msg)
        sb = self.txt_log.verticalScrollBar()
        sb.setValue(sb.maximum())
        self.statusBar().showMessage(msg)

    # ------------------------------------------------------------------ #
    # Theme
    # ------------------------------------------------------------------ #
    def apply_theme(self, name):
        self.theme = name if name in THEMES else "dark"
        self.setStyleSheet(make_style(THEMES[self.theme]))
        p = THEMES[self.theme]
        if hasattr(self, "lbl_stats"):
            self.lbl_stats.setStyleSheet(
                f"color: {p['success']}; font-family: monospace;")
        if hasattr(self, "lbl_hdrinfo"):
            self.lbl_hdrinfo.setStyleSheet(f"color: {p['muted']};")
        self.update_theme_button()

    def toggle_theme(self):
        self.apply_theme("light" if self.theme == "dark" else "dark")
        app_settings().setValue("theme", self.theme)

    def update_theme_button(self):
        if not hasattr(self, "theme_btn"):
            return
        if self.theme == "dark":
            self.theme_btn.setText("Dark")
            self.theme_btn.setProperty("themeIsDark", True)
        else:
            self.theme_btn.setText("Light")
            self.theme_btn.setProperty("themeIsDark", False)
        self.theme_btn.style().unpolish(self.theme_btn)
        self.theme_btn.style().polish(self.theme_btn)

    def show_initial_info(self):
        ok = True
        for name, path in (("ffmpeg", FFMPEG), ("ffprobe", FFPROBE), ("ffplay", FFPLAY)):
            if not path or not os.path.exists(path):
                ok = False
                self.log(f"[warning] {name} not found. "
                         "Install it or put it in applications/.")
        first = "ffmpeg"
        if ok:
            try:
                p = subprocess.run([FFMPEG, "-version"], capture_output=True,
                                   text=True, errors="replace", timeout=10)
                first = p.stdout.splitlines()[0]
            except Exception:
                pass
        self.txt_info.setPlainText(
            "AutoFFmpegGui v2 (PyQt6)\n\n"
            "1. Open a file with Browse\n"
            "2. Choose a preset, HDR mode and settings\n"
            "3. Press Encode, or add the job to the queue\n\n"
            "Live progress, ETA and full ffmpeg output are shown.\n"
            "HDR support: HDR10, HLG, HDR10+ (JSON), Dolby Vision (RPU).\n\n"
            f"Using: {first}\n"
            f"ffmpeg : {FFMPEG}\n"
            f"ffprobe: {FFPROBE}\n"
            f"ffplay : {FFPLAY}\n")

    # ------------------------------------------------------------------ #
    # Presets
    # ------------------------------------------------------------------ #
    def load_presets(self):
        self.preset_sources = {}
        self.cmb_preset.clear()
        for name in BUILTIN_PRESETS:
            if " - Copy" in name:
                family = "copy"
            elif name.startswith("H.264 - "):
                xp = name.replace("H.264 - ", "").strip()
                family = "x264"
            elif name.startswith("H.265 - "):
                xp = name.replace("H.265 - ", "").strip()
                family = "x265"
            else:
                family = {"MPEG-4": "mpeg4", "Xvid": "xvid",
                          "MPEG-2": "mpeg2", "WMV": "wmv"}.get(name, "x264")
            src = {"family": family}
            if family in ("x264", "x265") and name not in (
                    "H.264 - CRF", "H.265 - CRF", "H.264 - Copy video"):
                src["xpreset"] = name.rsplit(" - ", 1)[1]
            self.preset_sources[name] = src
            self.cmb_preset.addItem(name)

        profile_file = os.path.join(APP_DIR, "profile.txt")
        if os.path.exists(profile_file):
            with open(profile_file, encoding="utf-8", errors="replace") as fh:
                lines = fh.read().splitlines()
            added = 0
            for name, args in pb_profile_parse(lines):
                family = detect_family(args)
                src = {"family": family, "rawargs": args.split()}
                self.preset_sources["[custom] " + name] = src
                self.cmb_preset.addItem("[custom] " + name)
                added += 1
            if added:
                self.log(f"[info] loaded {added} custom presets from profile.txt")
        idx = self.cmb_preset.findText("H.264 - medium")
        self.cmb_preset.setCurrentIndex(idx if idx >= 0 else 0)
        self.on_preset_changed()
        self.on_mode_changed()
        self.on_hdr_changed()

    def current_preset(self):
        name = self.get_text(self.cmb_preset)
        return self.preset_sources.get(name, {"family": "x264"})

    # ------------------------------------------------------------------ #
    # Text helpers
    # ------------------------------------------------------------------ #
    def get_text(self, widget):
        if isinstance(widget, QComboBox):
            return widget.currentText()
        return widget.text()

    def set_text(self, widget, value):
        if isinstance(widget, QComboBox):
            if widget.isEditable():
                widget.setEditText(str(value))
            else:
                idx = widget.findText(str(value))
                if idx >= 0:
                    widget.setCurrentIndex(idx)
        else:
            widget.setText(str(value))

    def get_int(self, widget, default=0):
        if isinstance(widget, QComboBox):
            try:
                return int(float(str(widget.currentText()).strip() or default))
            except ValueError:
                return default
        try:
            return int(float(str(widget.text()).strip() or default))
        except ValueError:
            return default

    def add_audio_row(self, stream_index, label):
        item = QListWidgetItem(self.audio_list)
        row = QWidget()
        layout = QHBoxLayout(row)
        layout.setContentsMargins(2, 1, 2, 1)
        layout.setSpacing(5)
        check = QCheckBox()
        check.setChecked(True)
        check.setToolTip("Include this audio track")
        text = QLabel(label)
        text.setWordWrap(False)
        codec = QComboBox()
        codec.addItems(AUDIO_CODECS)
        codec.setToolTip("Encoding for this audio track")
        bitrate = QComboBox()
        bitrate.setEditable(True)
        bitrate.addItems(AUDIO_BITRATES)
        bitrate.setToolTip("Bitrate for this audio track")
        channels = QComboBox()
        channels.addItems(["original", "1", "2", "6"])
        channels.setToolTip("Channels for this audio track")
        sampling = QComboBox()
        sampling.setEditable(True)
        sampling.addItems(["auto", "22050", "44100", "48000", "96000"])
        sampling.setToolTip("Sampling rate for this audio track")
        codec.setFixedWidth(105)
        bitrate.setFixedWidth(68)
        channels.setFixedWidth(84)
        sampling.setFixedWidth(78)
        layout.addWidget(check)
        layout.addWidget(text, 1)
        layout.addWidget(codec)
        layout.addWidget(bitrate)
        layout.addWidget(channels)
        layout.addWidget(sampling)
        item.setSizeHint(row.sizeHint())
        self.audio_list.setItemWidget(item, row)
        self.audio_rows.append({
            "input_index": stream_index,
            "check": check,
            "codec": codec,
            "bitrate": bitrate,
            "channels": channels,
            "sampling": sampling,
        })

    def add_subtitle_row(self, stream_index, label):
        item = QListWidgetItem(self.subtitle_list)
        row = QWidget()
        layout = QHBoxLayout(row)
        layout.setContentsMargins(2, 0, 2, 0)
        check = QCheckBox()
        check.setChecked(True)
        check.setToolTip("Include this subtitle track")
        layout.addWidget(check)
        layout.addWidget(QLabel(label), 1)
        item.setSizeHint(row.sizeHint())
        self.subtitle_list.setItemWidget(item, row)
        self.subtitle_rows.append({"input_index": stream_index, "check": check})

    def selected_audio_tracks(self):
        return [row for row in self.audio_rows if row["check"].isChecked()]

    def selected_subtitle_tracks(self):
        return [row for row in self.subtitle_rows if row["check"].isChecked()]

    # ------------------------------------------------------------------ #
    # Analysis (ffprobe)
    # ------------------------------------------------------------------ #
    def analyze(self):
        self.audio_tracks = []
        self.duration = 0.0
        self.vwidth = self.vheight = 0
        self.framerate = 0.0
        self.vstream = None
        self.source_hdr_info = None
        self.source_dv = False
        self.dv_profile = None
        if not os.path.exists(self.inputfile):
            return False
        try:
            p = subprocess.run(
                [FFPROBE, "-v", "quiet", "-print_format", "json",
                 "-show_format", "-show_streams", self.inputfile],
                capture_output=True, text=True, errors="replace", timeout=60)
        except (FileNotFoundError, subprocess.TimeoutExpired) as e:
            self.log(f"[error] ffprobe failed: {e}")
            return False
        try:
            data = json.loads(p.stdout)
        except json.JSONDecodeError:
            self.log("[error] could not parse ffprobe output")
            return False
        self.probe = data

        fmt = data.get("format", {})
        try:
            self.duration = float(fmt.get("duration", 0) or 0)
        except ValueError:
            self.duration = 0.0

        self.audio_list.clear()
        self.subtitle_list.clear()
        self.audio_tracks = []
        self.audio_rows = []
        self.subtitle_tracks = []
        self.subtitle_rows = []
        idx = 0
        sidx = 0
        for s in data.get("streams", []):
            if s.get("codec_type") == "video":
                self.vstream = s
                self.vwidth = int(s.get("width", 0) or 0)
                self.vheight = int(s.get("height", 0) or 0)
                rfr = s.get("r_frame_rate") or s.get("avg_frame_rate") or ""
                try:
                    num, den = map(int, str(rfr).split("/"))
                    self.framerate = num / den if den else 0.0
                except ValueError:
                    self.framerate = 0.0
                trc = s.get("color_transfer")
                self.dv_profile = None
                for sd in s.get("side_data_list", []):
                    if sd.get("side_data_type") == "DOVI configuration record":
                        self.source_dv = True
                        try:
                            self.dv_profile = int(sd.get("dv_profile", 0))
                        except (TypeError, ValueError):
                            self.dv_profile = None
                        break
                if not self.source_dv:
                    tags = s.get("tags", {}) or {}
                    tagstr = str(s.get("codec_tag_string", ""))
                    if ("dovi" in tagstr.lower() or "dvhe" in tagstr.lower()
                            or any(k.lower().startswith("dv_") for k in tags)
                            or "dolby" in str(tags).lower()):
                        self.source_dv = True
                        try:
                            self.dv_profile = int(tags.get("dv_profile", 0))
                        except (TypeError, ValueError):
                            self.dv_profile = None
                if trc in ("smpte2084", "arib-std-b67"):
                    self.source_hdr_info = (
                        s.get("color_primaries") or "bt2020",
                        trc,
                        s.get("color_space") or "bt2020nc")
                elif self.source_dv and self.dv_profile == 5:
                    self.source_hdr_info = ("bt2020", "smpte2084", "bt2020nc")
            elif s.get("codec_type") == "audio":
                tags = s.get("tags", {}) or {}
                lang = tags.get("language") or tags.get("LANGUAGE") or ""
                title = tags.get("title") or tags.get("Title") or ""
                label = (f"Track {idx}: {s.get('codec_name', '?')} "
                         f"{s.get('channel_layout', '')} "
                         f"{s.get('sample_rate', '')} Hz")
                if lang:
                    label += f"  [{lang_name(lang)}]"
                if title:
                    label += f"  -  {title}"
                self.add_audio_row(idx, label)
                self.audio_tracks.append(s)
                idx += 1
            elif s.get("codec_type") == "subtitle":
                tags = s.get("tags", {}) or {}
                lang = tags.get("language") or tags.get("LANGUAGE") or ""
                title = tags.get("title") or tags.get("Title") or ""
                label = f"Track {sidx}: {s.get('codec_name', '?')}"
                if lang:
                    label += f"  [{lang_name(lang)}]"
                if title:
                    label += f"  -  {title}"
                self.add_subtitle_row(sidx, label)
                self.subtitle_tracks.append(s)
                sidx += 1
        self.update_size_from_source()
        self.update_info()
        self.log(f"[info] analyzed {Path(self.inputfile).name}: "
                 f"{self.vwidth}x{self.vheight} @ {self.framerate:.2f} fps, "
                 f"{self.duration:.1f}s, {len(self.audio_tracks)} audio track(s), "
                 f"{len(self.subtitle_tracks)} subtitle track(s)")
        return True

    def update_info(self):
        if not self.probe:
            return
        fmt = self.probe.get("format", {})
        self.update_source_summary(fmt)
        lines = [
            f"File      : {self.inputfile}",
            f"Duration  : {self.duration:.2f} s",
            f"Container : {fmt.get('format_name', '?')}",
            f"Bitrate   : {fmt.get('bit_rate', '?')} bps",
            "",
        ]
        for s in self.probe.get("streams", []):
            t = s.get("codec_type")
            if t == "video":
                info = (f"Video     : {s.get('codec_name')} "
                        f"{s.get('width')}x{s.get('height')} "
                        f"{s.get('pix_fmt', '')} "
                        f"{s.get('r_frame_rate', '')} fps")
                if s.get("color_transfer"):
                    info += (f"\n             prim={s.get('color_primaries')} "
                             f"trc={s.get('color_transfer')} "
                             f"space={s.get('color_space')}")
                lines.append(info)
                if self.source_dv:
                    prof = f" (profile {self.dv_profile})" if self.dv_profile else ""
                    lines.append(f"             Dolby Vision{prof} (RPU) detected")
            elif t == "audio":
                tags = s.get("tags", {}) or {}
                lang = tags.get("language") or tags.get("LANGUAGE") or ""
                lines.append(
                    f"Audio     : {s.get('codec_name')} "
                    f"{s.get('channel_layout', '')} "
                    f"{s.get('sample_rate', '')} Hz "
                    f"{s.get('bit_rate', '?')} bps"
                    + (f"  [{lang_name(lang)}]" if lang else ""))
            elif t == "subtitle":
                tags = s.get("tags", {}) or {}
                lang = tags.get("language") or tags.get("LANGUAGE") or ""
                lines.append(
                    f"Subs      : {s.get('codec_name')}  "
                    f"{s.get('width', '')}x{s.get('height', '')} "
                    f"{s.get('codec_tag_string', '')}"
                    + (f"  [{lang_name(lang)}]" if lang else ""))
        self.txt_info.setPlainText("\n".join(lines))

        if self.vstream:
            if self.source_dv:
                prof = f" profile {self.dv_profile}" if self.dv_profile else ""
                label = (f"Source: Dolby Vision{prof} detected. "
                         f"Select \"Dolby Vision\" to re-encode with RPU.")
            elif self.source_hdr_info:
                prim, trc, space = self.source_hdr_info
                label = (f"Source: HDR detected ({trc}, {prim}, {space}). "
                         f"\"Auto\" will preserve HDR.")
            else:
                label = "Source: SDR (no HDR metadata)."
        else:
            label = ""
        self.lbl_hdrinfo.setText(label)

    def update_source_summary(self, fmt=None):
        if not self.probe or not self.vstream:
            self.lbl_source_summary.setText("No file loaded")
            return
        fmt = fmt or self.probe.get("format", {})
        if self.duration >= 3600:
            duration = f"{self.duration / 3600:.1f} h"
        elif self.duration >= 60:
            duration = f"{self.duration / 60:.1f} min"
        else:
            duration = f"{self.duration:.1f} s"
        container = str(fmt.get("format_name", "?")).split(",")[0]
        video = (f"{self.vstream.get('codec_name', '?')} "
                 f"{self.vwidth}x{self.vheight} @ {self.framerate:.2f} fps")
        if self.source_dv:
            color = "Dolby Vision" + (
                f" profile {self.dv_profile}" if self.dv_profile else "")
        elif self.source_hdr_info:
            color = f"HDR ({self.source_hdr_info[1]})"
        else:
            color = "SDR"
        self.lbl_source_summary.setText(
            f"{Path(self.inputfile).name}\n"
            f"Container: {container}    Video: {video}\n"
            f"Duration: {duration}    Audio: {len(self.audio_tracks)}    "
            f"Subtitles: {len(self.subtitle_tracks)}    Color: {color}")
        self.lbl_source_summary.setToolTip(self.inputfile)

    def update_size_from_source(self):
        if self.vwidth and self.vheight:
            self.inp_width.setText(str(self.vwidth))
            self.inp_height.setText(str(self.vheight))
            self.silentscale()

    # ------------------------------------------------------------------ #
    # HDR helpers
    # ------------------------------------------------------------------ #
    def hdr_mode(self):
        return self.get_text(self.cmb_hdr)

    def hdr_active(self):
        m = self.hdr_mode()
        if m in ("HDR10 (BT.2020 / PQ)", "HLG (BT.2020 / HLG)",
                 "HDR10+ (dynamic metadata)", "Dolby Vision (source RPU)"):
            return True
        if m == "Auto (match source)":
            return self.source_hdr_info is not None
        return False

    def active_hw(self):
        return HW_ACCELS.get(self.get_text(self.cmb_hw))

    def populate_hw(self):
        self.cmb_hw.clear()
        self.cmb_hw.addItem("None")
        for label, key in HW_ACCELS.items():
            if not key:
                continue
            if any(HW_ENCODERS.get((f, key)) in self.available_encoders
                   for f in ("x264", "x265", "vp9", "av1")):
                self.cmb_hw.addItem(label)
        if len(self.cmb_hw) == 1:
            self.cmb_hw.setToolTip(
                "No hardware encoder detected in this ffmpeg build")

    def effective_hw(self):
        if self.hdr_active():
            return None
        return self.active_hw()

    def effective_family(self):
        if self.hdr_active():
            return "x265"
        return self.current_preset().get("family", "x264")

    @staticmethod
    def family_supports_quality(family):
        return family in ("x264", "x265", "vp9", "av1", "mpeg4", "xvid",
                          "mpeg2", "wmv")

    @staticmethod
    def family_supports_bitrate(family):
        return family in ("x264", "x265", "vp9", "av1", "mpeg4", "xvid",
                          "mpeg2", "wmv")

    def hdr_parts(self, family, bitrate):
        m = self.hdr_mode()
        out = {"pix": None, "opts": [], "vf": [], "note": None, "force": None}
        md = self.get_text(self.inp_masterdisplay).strip() or DEFAULT_MASTER
        cl = self.get_text(self.inp_maxcll).strip() or DEFAULT_CL

        if m == "Auto (match source)":
            if not self.source_hdr_info:
                return out
            prim, trc, space = self.source_hdr_info
            out["pix"] = "yuv420p10le"
            out["opts"] += ["-color_primaries", prim, "-color_trc", trc,
                            "-colorspace", space]
            if family == "x265":
                out["opts"] += ["-x265-params",
                                f"colorprim={prim}:transfer={trc}:colormatrix={space}"
                                f":master-display={md}:max-cll={cl}"]
            return out

        if m == "SDR (tone map to BT.709)":
            out["pix"] = "yuv420p"
            out["vf"] = ["format=gbrpf32le,zscale=transfer=linear:npl=100,"
                         "tonemap=hable,zscale=transfer=bt709:primaries=bt709,"
                         "format=yuv420p"]
            out["opts"] += ["-color_primaries", "bt709", "-color_trc", "bt709",
                            "-colorspace", "bt709"]
            return out

        if m in ("HDR10 (BT.2020 / PQ)", "HLG (BT.2020 / HLG)",
                 "HDR10+ (dynamic metadata)", "Dolby Vision (source RPU)"):
            trc = "smpte2084" if m != "HLG (BT.2020 / HLG)" else "arib-std-b67"
            out["pix"] = "yuv420p10le"
            out["opts"] += ["-color_primaries", "bt2020", "-color_trc", trc,
                            "-colorspace", "bt2020nc"]
            if family != "x265":
                out["force"] = "x265"
                out["note"] = "HDR requires x265 (10-bit HEVC)."
            if m == "HDR10+ (dynamic metadata)":
                jf = self.get_text(self.inp_hdr_meta).strip()
                if jf and os.path.exists(jf) and os.path.getsize(jf) > 0:
                    out["opts"] += ["-x265-params",
                                    f"colorprim=bt2020:transfer=smpte2084:"
                                    f"colormatrix=bt2020nc:master-display={md}:"
                                    f"max-cll={cl}:dhdr10-info='{jf}':dhdr10-opt=1"]
                else:
                    out["opts"] += ["-x265-params",
                                    f"colorprim=bt2020:transfer=smpte2084:"
                                    f"colormatrix=bt2020nc:master-display={md}:"
                                    f"max-cll={cl}"]
                    out["note"] = ("HDR10+ metadata file missing or empty: "
                                   "encoding static HDR10 instead.")
            elif m == "Dolby Vision (source RPU)":
                out["opts"] += ["-dolbyvision", "1"]
                b = max(bitrate, 1000)
                out["opts"] += ["-maxrate", f"{b}k", "-bufsize", f"{b * 2}k"]
                out["opts"] += ["-x265-params",
                                f"colorprim=bt2020:transfer=smpte2084:"
                                f"colormatrix=bt2020nc:master-display={md}:"
                                f"max-cll={cl}"]
                out["note"] = ("Dolby Vision needs the source to carry the DV RPU. "
                               "Profile 5/8 sources work best.")
            else:
                out["opts"] += ["-x265-params",
                                f"colorprim=bt2020:transfer={trc}:"
                                f"colormatrix=bt2020nc:master-display={md}:"
                                f"max-cll={cl}"]
        return out

    def on_hdr_changed(self):
        m = self.hdr_mode()
        enable_meta = (m == "HDR10+ (dynamic metadata)")
        self.inp_hdr_meta.setEnabled(enable_meta)
        self.btn_hdr_meta.setEnabled(enable_meta)
        hard_hdr = m in ("HDR10 (BT.2020 / PQ)", "HLG (BT.2020 / HLG)",
                         "HDR10+ (dynamic metadata)",
                         "Dolby Vision (source RPU)")
        if hard_hdr and self.active_hw():
            self.set_text(self.cmb_hw, "None")
        self.cmb_hw.setEnabled(not hard_hdr)

    def choose_hdr_meta(self):
        f, _ = QFileDialog.getOpenFileName(
            self, "HDR10+ JSON metadata",
            self.lastdir, "JSON (*.json);;All files (*.*)")
        if f:
            self.inp_hdr_meta.setText(f)

    # ------------------------------------------------------------------ #
    # Resize / crop logic
    # ------------------------------------------------------------------ #
    @staticmethod
    def round_by(base, factor):
        return int(base / factor + 0.5) * factor

    def silentscale(self):
        if not self.vwidth or not self.vheight:
            return
        width = self.get_int(self.inp_width)
        height = self.get_int(self.inp_height)
        if not width or not height:
            return
        if width != self.vwidth or height != self.vheight:
            mod = max(2, self.get_int(self.cmb_mod, 16))
            height = self.round_by(width / (self.vwidth / self.vheight), mod)
            if height <= 0:
                height = mod
            self.inp_height.setText(str(height))
        if height > 0 and width > 0:
            self.inp_dar.setText(f"{width / height:.4f}")

    def on_size_pct(self):
        if not self.vwidth:
            return
        pct = self.sld_trackwidth.value()
        width = self.round_by(self.vwidth * pct / 100, 2)
        self.inp_width.setText(str(width))
        self.silentscale()

    def on_resize_toggled(self, enabled):
        for w in (self.inp_width, self.inp_height, self.cmb_mod,
                  self.sld_trackwidth, self.inp_leftcrop, self.inp_rightcrop,
                  self.inp_topcrop, self.inp_bottomcrop):
            w.setEnabled(enabled)

    def on_preset_changed(self):
        family = self.current_preset().get("family", "x264")
        if family in ("x264", "x265"):
            lo, hi, label = 0, 51, "Quality:"
            tooltip = "CRF quality; lower values mean higher quality"
        elif family in ("vp9", "av1"):
            lo, hi, label = 0, 63, "Quality:"
            tooltip = "CRF quality; lower values mean higher quality"
        else:
            lo, hi, label = 2, 31, "Quality:"
            tooltip = "Qscale quality; lower values mean higher quality"
        self.sld_quality.setRange(lo, hi)
        self.spin_quality.setRange(lo, hi)
        self.lbl_quality.setText(label)
        self.lbl_quality.setToolTip(tooltip)
        if family == "copy":
            self.cmb_mode.setCurrentIndex(self.cmb_mode.findText("Copy video"))

    def on_quality_changed(self):
        self.spin_quality.setValue(self.sld_quality.value())

    def on_mode_changed(self):
        mode = self.get_text(self.cmb_mode)
        hw = self.active_hw()
        is_copy = mode == "Copy video"
        hw_mode = bool(hw) and not is_copy
        self.cmb_preset.setEnabled(not is_copy)
        self.sld_quality.setEnabled(not is_copy)
        self.spin_quality.setEnabled(not is_copy)
        self.lbl_quality.setEnabled(not is_copy)
        self.inp_bitrate.setEnabled("bitrate" in mode)
        self.cmb_hw.setEnabled(not is_copy)
        if hw and mode == "2-pass bitrate":
            self.lbl_status.setText("HW encoders: using 1-pass bitrate")

    # ------------------------------------------------------------------ #
    # Command building
    # ------------------------------------------------------------------ #
    def build_filter_args(self):
        if not self.chk_resize.isChecked():
            return []
        vf = []
        l = self.get_int(self.inp_leftcrop)
        r = self.get_int(self.inp_rightcrop)
        t = self.get_int(self.inp_topcrop)
        b = self.get_int(self.inp_bottomcrop)
        cw = max(2, self.vwidth - l - r)
        ch = max(2, self.vheight - t - b)
        if l or r or t or b:
            vf.append(f"crop={cw}:{ch}:{l}:{t}")
        w = self.get_int(self.inp_width)
        h = self.get_int(self.inp_height)
        if w and h and (w != self.vwidth or h != self.vheight):
            vf.append(f"scale={w}:{h}")
        if self.chk_deinterlace.isChecked():
            vf.append("yadif")
        return vf

    def build_video_args(self, passno=0):
        preset = self.current_preset()
        family = self.effective_family()
        mode = self.get_text(self.cmb_mode)
        hw = self.effective_hw()
        quality = self.sld_quality.value()
        bitrate = self.get_int(self.inp_bitrate, 2000)

        if mode == "Copy video" or family == "copy":
            return ["-c:v", "copy"]

        if hw:
            enc = HW_ENCODERS.get((family, hw))
            if enc and enc in getattr(self, "available_encoders", set()):
                args = ["-c:v", enc]
                if mode == "Quality (CRF)":
                    args += [HW_QUALITY_OPT[hw], str(quality)]
                else:
                    args += ["-b:v", f"{bitrate}k"]
                return args
            if enc:
                self.log(f"[info] {enc} not available: falling back to software "
                         f"{CODECS.get(family, 'encoder')}")

        preset_family = preset.get("family", "x264")
        forced = preset_family in CODECS and family != preset_family
        if "rawargs" in preset and not forced:
            args = list(preset["rawargs"])
            if mode == "Quality (CRF)" and self.family_supports_quality(family):
                if family in ("x264", "x265", "vp9", "av1"):
                    if "-crf" not in args:
                        args += ["-crf", str(quality)]
                    if family == "vp9" and "-b:v" not in args:
                        args += ["-b:v", "0"]
                elif family in ("mpeg4", "xvid", "mpeg2", "wmv") and \
                        "-qscale:v" not in args:
                    args += ["-qscale:v", str(quality)]
            elif (mode in ("1-pass bitrate", "2-pass bitrate") and
                  self.family_supports_bitrate(family) and "-b:v" not in args
                  and "-crf" not in args and "-qscale:v" not in args):
                args += ["-b:v", f"{bitrate}k"]
                if mode == "2-pass bitrate":
                    args += ["-pass", str(passno)]
            return args

        if mode == "Quality (CRF)":
            if family in ("x264", "x265"):
                return ["-c:v", CODECS[family],
                        "-preset", preset.get("xpreset", "medium"),
                        "-crf", str(quality)]
            if family in ("vp9", "av1"):
                return ["-c:v", CODECS[family], "-crf", str(quality)]
            return ["-c:v", CODECS[family], "-qscale:v", str(quality)]

        if mode in ("1-pass bitrate", "2-pass bitrate"):
            if family in ("x264", "x265"):
                args = ["-c:v", CODECS[family],
                        "-preset", preset.get("xpreset", "medium"),
                        "-b:v", f"{bitrate}k"]
                maxr = int(bitrate * 1.25)
                args += ["-maxrate", f"{maxr}k", "-bufsize", f"{maxr * 2}k"]
            else:
                args = ["-c:v", CODECS[family], "-b:v", f"{bitrate}k"]
            if mode == "2-pass bitrate":
                args += ["-pass", str(passno)]
            return args
        return ["-c:v", "copy"]

    def build_audio_args(self):
        args = []
        selected = self.selected_audio_tracks()
        if not selected:
            return ["-an"]
        codec_names = {"AAC": "aac", "MP3": "libmp3lame", "FLAC": "flac",
                       "OGG (Vorbis)": "libvorbis", "AC-3": "ac3",
                       "Copy": "copy"}
        for output_index, row in enumerate(selected):
            codec = row["codec"].currentText()
            spec = f"a:{output_index}"
            args += [f"-c:{spec}", codec_names[codec]]
            if codec != "Copy" and codec != "FLAC":
                args += [f"-b:{spec}", f"{self.get_int(row['bitrate'], 128)}k"]
        for output_index, row in enumerate(selected):
            if row["codec"].currentText() == "Copy":
                continue
            ch = row["channels"].currentText()
            if ch in ("1", "2", "6"):
                args += [f"-ac:a:{output_index}", ch]
            sr = row["sampling"].currentText()
            if sr != "auto":
                args += [f"-ar:a:{output_index}", sr]
        gain = self.spin_gain.value()
        audio_filter = f"volume={gain}dB" if gain else (
            "loudnorm=I=-16:TP=-1.5:LRA=11"
            if self.chk_normalize.isChecked() else "")
        if audio_filter:
            for output_index, row in enumerate(selected):
                if row["codec"].currentText() != "Copy":
                    args += [f"-af:a:{output_index}", audio_filter]
        return args

    def build_stream_args(self, out_is_mp4):
        """Explicit stream mapping for video/audio/subtitles + sub codec."""
        maps = []
        sub_args = []
        if self.vstream:
            maps += ["-map", "0:v:0"]
        selected_audio = self.selected_audio_tracks()
        for row in selected_audio:
            maps += ["-map", f"0:a:{row['input_index']}"]
        selected_subs = self.selected_subtitle_tracks()
        if selected_subs:
            scodec = "mov_text" if out_is_mp4 else "copy"
            for output_index, row in enumerate(selected_subs):
                maps += ["-map", f"0:s:{row['input_index']}"]
                sub_args += [f"-c:s:{output_index}", scodec]
        else:
            sub_args += ["-sn"]
        return maps, sub_args

    def build_jobs(self):
        if not self.inputfile or not os.path.exists(self.inputfile):
            return []
        if not self.outputfile:
            self.outputfile = self.default_output()
            self.auto_output = True
            self.inp_output.setText(self.outputfile)

        preset = self.current_preset()
        family0 = preset.get("family", "x264")
        family = self.effective_family()
        mode = self.get_text(self.cmb_mode)
        rawargs = preset.get("rawargs", [])
        if "-crf" in rawargs or "-qscale:v" in rawargs:
            mode = "Quality (CRF)"
        if "rawargs" in preset and not self.family_supports_bitrate(family) and \
                mode in ("1-pass bitrate", "2-pass bitrate"):
            self.log(f"[info] {family} profile: bitrate mode uses profile settings")
            mode = "Quality (CRF)"
        hw = self.effective_hw()
        bitrate = self.get_int(self.inp_bitrate, 2000)

        if hw and self.hdr_active():
            self.log("[info] HDR is not supported with hardware encoders: using software x265")

        if hw and family in ("x264", "x265") and mode == "2-pass bitrate":
            mode = "1-pass bitrate"
            self.log("[info] hardware encoders: 2-pass not supported, using 1-pass")

        if self.hdr_active() and family != family0:
            self.log(f"[info] HDR requires 10-bit: switched encoder to {CODECS[family]}")

        hdr = self.hdr_parts(family, bitrate)
        if hdr.get("note"):
            self.log(f"[info] HDR: {hdr['note']}")

        vf = self.build_filter_args() + hdr["vf"]
        aargs = self.build_audio_args()
        fr = self.get_text(self.cmb_framerate)
        vf_n = self.get_text(self.inp_vframes)
        out_is_mp4 = Path(self.outputfile).suffix.lower() == ".mp4"
        passlog = (os.path.join(tempfile.gettempdir(), "autoffmpeg2pass")
                   if mode == "2-pass bitrate" else None)
        maps, sub_args = self.build_stream_args(out_is_mp4)

        def base(video_args, audio_args):
            cmd = [FFMPEG, "-y"]
            init = HW_INIT.get(hw, []) if hw else []
            if init:
                cmd += init
            cmd += ["-i", self.inputfile]
            all_vf = list(vf)
            if hw == "vaapi" and "hwupload" not in ",".join(all_vf):
                all_vf.append("format=nv12,hwupload")
            if all_vf:
                cmd += ["-vf", ",".join(all_vf)]
            if family == "x265" and out_is_mp4:
                cmd += ["-tag:v", "hvc1"]
            if fr != "automatic":
                cmd += ["-r", fr]
            if vf_n:
                cmd += ["-frames:v", vf_n]
            cmd += video_args
            if hdr["opts"]:
                cmd += hdr["opts"]
            if passlog:
                cmd += ["-passlogfile", passlog]
            has_pix = any(a == "-pix_fmt" for a in video_args)
            pix = hdr["pix"]
            if not pix and not hw and not has_pix and \
                    family in ("x264", "x265", "vp9", "av1"):
                pix = "yuv420p"
            if pix:
                cmd += ["-pix_fmt", pix]
            cmd += audio_args + sub_args + maps
            if out_is_mp4 and family not in ("copy",):
                cmd += ["-movflags", "+faststart"]
            cmd += ["-threads", "0", "-y", self.outputfile]
            return cmd

        jobs = []
        if mode == "2-pass bitrate":
            p1 = base(self.build_video_args(1), ["-an"])
            p2 = base(self.build_video_args(2), aargs)
            jobs.append(EncodeJob(
                f"Pass 1 -> {Path(self.outputfile).name}", p1, self.duration))
            jobs.append(EncodeJob(
                f"Pass 2 -> {Path(self.outputfile).name}", p2, self.duration))
        else:
            jobs.append(EncodeJob(
                f"Encode -> {Path(self.outputfile).name}",
                base(self.build_video_args(0), aargs), self.duration))
        return jobs

    def default_output(self):
        stem = Path(self.inputfile).stem
        family = self.effective_family()
        if family in ("x264", "x265"):
            ext = ".mp4"
        elif family in ("vp9", "av1", "ffv1", "dnxhd"):
            ext = ".mkv"
        elif family == "prores":
            ext = ".mov"
        else:
            ext = ".avi"
        return os.path.join(os.path.dirname(self.inputfile),
                            "autoffmpeg_" + stem + ext)

    # ------------------------------------------------------------------ #
    # Encoding
    # ------------------------------------------------------------------ #
    def run_jobs(self, jobs):
        if not jobs:
            QMessageBox.warning(self, "AutoFFmpegGui",
                                "Open a valid input file first.")
            return
        if self.thread and self.thread.isRunning():
            return
        for j in jobs:
            self.log("[cmd] " + " ".join(j.cmd))
        self.thread = EncodeThread(jobs, self)
        self.thread.log_line.connect(self.append_log)
        self.thread.progress.connect(self.on_progress)
        self.thread.stats.connect(self.lbl_stats.setText)
        self.thread.job_started.connect(self.on_job_started)
        self.thread.job_done.connect(self.on_job_done)
        self.thread.all_done.connect(self.on_all_done)
        self._had_failure = False
        self.btn_encode.setEnabled(False)
        self.btn_addqueue.setEnabled(False)
        self.btn_startqueue.setEnabled(False)
        self.btn_cancel.setEnabled(True)
        self.progress.setValue(0)
        self.lbl_stats.setText("")
        self.thread.start()

    def append_log(self, s):
        self.txt_log.appendPlainText(s)
        sb = self.txt_log.verticalScrollBar()
        sb.setValue(sb.maximum())

    def do_encode(self):
        self.run_jobs(self.build_jobs())

    def addtoqueue(self):
        jobs = self.build_jobs()
        if not jobs:
            QMessageBox.warning(self, "AutoFFmpegGui",
                                "Open a valid input file first.")
            return
        for j in jobs:
            item = QListWidgetItem(j.label)
            item.setData(Qt.ItemDataRole.UserRole, j)
            self.list_queue.addItem(item)
        self.log(f"[queue] added {len(jobs)} job(s)")

    def startqueue(self):
        jobs = []
        for i in range(self.list_queue.count()):
            item = self.list_queue.item(i)
            j = item.data(Qt.ItemDataRole.UserRole)
            if j:
                jobs.append(j)
        if not jobs:
            QMessageBox.information(self, "AutoFFmpegGui", "Queue is empty.")
            return
        self.list_queue.clear()
        self.run_jobs(jobs)

    def remove_queue_item(self):
        for item in self.list_queue.selectedItems():
            self.list_queue.takeItem(self.list_queue.row(item))

    def cancel_encode(self):
        if self.thread:
            self.thread.cancel()
            self.log("[info] cancel requested...")

    def on_progress(self, pct, label):
        self.progress.setValue(pct)
        self.lbl_status.setText(f"{label} ... {pct}%")

    def on_job_started(self, idx, label):
        self.lbl_status.setText(f"[{idx + 1}] {label} ...")
        self.log(f"[job] {label}")

    def on_job_done(self, idx, code):
        self.log(f"[job] finished (exit code {code})")
        if code != 0:
            self._had_failure = True
            self.lbl_status.setText(f"Job {idx + 1} failed (exit {code})")

    def on_all_done(self):
        self.btn_encode.setEnabled(True)
        self.btn_addqueue.setEnabled(True)
        self.btn_startqueue.setEnabled(True)
        self.btn_cancel.setEnabled(False)
        self.lbl_stats.setText("")
        if self.thread and self.thread._cancel:
            self.lbl_status.setText("Cancelled")
        elif self._had_failure:
            self.lbl_status.setText("Completed with errors")
        else:
            self.lbl_status.setText("Done")
            self.progress.setValue(100)
        self.thread = None

    # ------------------------------------------------------------------ #
    # Auto crop
    # ------------------------------------------------------------------ #
    def autocrop(self):
        if not self.inputfile or not os.path.exists(self.inputfile):
            QMessageBox.warning(self, "AutoFFmpegGui", "Open a file first.")
            return
        self.btn_autocrop.setEnabled(False)
        self.lbl_status.setText("Detecting crop ...")
        self.log("[crop] running cropdetect ...")
        skip = (min(3.0, max(0.0, self.duration * 0.2))
                if self.duration > 0 else 2.0)
        cmd = [FFMPEG]
        if skip > 0:
            cmd += ["-ss", f"{skip:.2f}"]
        cmd += ["-i", self.inputfile, "-vf",
                "cropdetect=limit=24:round=2", "-frames:v", "120",
                "-f", "null", "-"]
        proc = subprocess.Popen(
            cmd, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE,
            text=True, errors="replace")

        class _CropWorker(QThread):
            def run(self):
                out = self.proc.stderr.read()
                self.proc.wait()
                matches = re.findall(
                    r"crop=(-?\d+):(-?\d+):(-?\d+):(-?\d+)", out)
                self.result = (tuple(map(int, matches[-1])) if matches
                               else None)

        worker = _CropWorker(self)
        worker.proc = proc
        worker.finished.connect(self._autocrop_done)
        worker.start()
        self.crop_worker = worker

    def _autocrop_done(self):
        self.btn_autocrop.setEnabled(True)
        r = self.crop_worker
        if not r.result:
            self.lbl_status.setText("cropdetect did not report a crop")
            self.log("[crop] cropdetect did not report a crop region")
            return
        w, h, x, y = r.result
        if w <= 0 or h <= 0:
            for e in (self.inp_leftcrop, self.inp_rightcrop,
                      self.inp_topcrop, self.inp_bottomcrop):
                e.setText("0")
            self.lbl_status.setText("No black borders found - no crop applied")
            self.log("[crop] no black borders detected; crop left at 0")
            return
        self.inp_leftcrop.setText(str(x))
        self.inp_topcrop.setText(str(y))
        self.inp_rightcrop.setText(str(max(0, self.vwidth - x - w)))
        self.inp_bottomcrop.setText(str(max(0, self.vheight - y - h)))
        self.lbl_status.setText(f"Crop: {w}x{h}+{x}+{y}")
        self.log(f"[crop] detected {w}x{h}+{x}+{y}")
        self.silentscale()

    # ------------------------------------------------------------------ #
    # Bitrate calculator
    # ------------------------------------------------------------------ #
    def calc_bitrate(self):
        if not self.duration or self.duration <= 0:
            QMessageBox.information(self, "AutoFFmpegGui",
                                    "Open a file first to analyze it.")
            return
        mb = self.get_int(self.inp_cds, 700)
        selected = self.selected_audio_tracks()
        audio = sum(self.get_int(row["bitrate"], 128) for row in selected
                    if row["codec"].currentText() != "Copy")
        if not selected:
            audio = 128
        video_kbps = (mb * 8192 / self.duration) * 0.95 - audio
        if video_kbps <= 0:
            video_kbps = 64
        self.inp_bitrate.setText(str(int(video_kbps)))
        self.log(f"[calc] target {mb} MB over {self.duration:.0f}s "
                 f"-> video bitrate {int(video_kbps)} kbit/s")

    # ------------------------------------------------------------------ #
    # Preview / play
    # ------------------------------------------------------------------ #
    def run_ffplay(self, args):
        if not self.inputfile:
            return
        if not FFPLAY or not os.path.exists(FFPLAY):
            QMessageBox.warning(self, "AutoFFmpegGui", "ffplay not found.")
            return
        try:
            subprocess.Popen([FFPLAY] + args)
        except OSError as e:
            QMessageBox.warning(self, "AutoFFmpegGui", str(e))

    def play(self):
        self.run_ffplay(["-i", self.inputfile])

    def preview(self):
        vf = self.build_filter_args()
        args = []
        if vf:
            args += ["-vf", ",".join(vf)]
        args += ["-autoexit", "-i", self.inputfile]
        self.run_ffplay(args)

    # ------------------------------------------------------------------ #
    # File dialogs
    # ------------------------------------------------------------------ #
    def openinputfile(self):
        filters = ("Media (*.mp4 *.mkv *.avi *.mov *.ts *.mts *.m2ts *.vob "
                   "*.mpg *.mpeg *.wmv *.flv *.webm *.ogm *.m2v *.m2t *.vro "
                   "*.d2v *.dga *.avs *.grf);;All files (*.*)")
        f, _ = QFileDialog.getOpenFileName(self, "Open File to Encode",
                                           self.lastdir, filters)
        if not f:
            return
        self.lastdir = os.path.dirname(f)
        self.inp_input.setText(f)
        self.inputfile = f
        if self.auto_output:
            self.inp_output.setText("")
            self.outputfile = ""
        self.analyze()
        self.silentscale()

    def savefile(self):
        if self.inputfile:
            default = os.path.join(os.path.dirname(self.inputfile),
                                   Path(self.inputfile).stem + "_autoff.mp4")
        else:
            default = os.path.join(self.lastdir or "", "output.mp4")
        f, _ = QFileDialog.getSaveFileName(
            self, "Save output file", default,
            "MP4 (*.mp4);;MKV (*.mkv);;AVI (*.avi);;MPEG (*.mpg);;WMV (*.wmv)")
        if f:
            self.inp_output.setText(f)
            self.outputfile = f
            self.auto_output = False

    # ------------------------------------------------------------------ #
    # Settings persistence
    # ------------------------------------------------------------------ #
    def load_settings(self):
        s = app_settings()
        if s.contains("theme"):
            self.apply_theme(str(s.value("theme")))
        if s.contains("geometry"):
            self.restoreGeometry(s.value("geometry"))
        self.lastdir = s.value("lastdir", "")
        def restore_combo(cmb, key):
            if s.contains(key):
                v = s.value(key)
                if cmb.isEditable():
                    cmb.setEditText(v)
                else:
                    idx = cmb.findText(v)
                    if idx >= 0:
                        cmb.setCurrentIndex(idx)
        restore_combo(self.cmb_preset, "preset")
        restore_combo(self.cmb_mode, "mode")
        restore_combo(self.cmb_hw, "hw")
        restore_combo(self.cmb_hdr, "hdr")
        restore_combo(self.cmb_framerate, "framerate")
        if s.contains("quality"):
            self.sld_quality.setValue(int(s.value("quality")))
        if s.contains("bitrate"):
            self.inp_bitrate.setText(str(s.value("bitrate")))
        if s.contains("cds"):
            self.inp_cds.setText(str(s.value("cds")))
        if s.contains("masterdisplay"):
            self.inp_masterdisplay.setText(str(s.value("masterdisplay")))
        if s.contains("maxcll"):
            self.inp_maxcll.setText(str(s.value("maxcll")))
        if s.contains("hdr_meta"):
            self.inp_hdr_meta.setText(str(s.value("hdr_meta")))
        if s.contains("vframes"):
            self.inp_vframes.setText(str(s.value("vframes")))
        if s.contains("resize"):
            self.chk_resize.setChecked(s.value("resize", True, type=bool))
        if s.contains("deinterlace"):
            self.chk_deinterlace.setChecked(s.value("deinterlace", False, type=bool))
        if s.contains("normalize"):
            self.chk_normalize.setChecked(s.value("normalize", False, type=bool))
        if s.contains("gain"):
            self.spin_gain.setValue(int(s.value("gain")))
        self.on_preset_changed()
        self.on_mode_changed()
        self.on_hdr_changed()

    def closeEvent(self, e):
        s = app_settings()
        s.setValue("theme", self.theme)
        s.setValue("geometry", self.saveGeometry())
        s.setValue("lastdir", self.lastdir)
        s.setValue("preset", self.get_text(self.cmb_preset))
        s.setValue("mode", self.get_text(self.cmb_mode))
        s.setValue("hw", self.get_text(self.cmb_hw))
        s.setValue("hdr", self.get_text(self.cmb_hdr))
        s.setValue("quality", self.sld_quality.value())
        s.setValue("bitrate", self.get_text(self.inp_bitrate))
        s.setValue("cds", self.get_text(self.inp_cds))
        s.setValue("masterdisplay", self.get_text(self.inp_masterdisplay))
        s.setValue("maxcll", self.get_text(self.inp_maxcll))
        s.setValue("hdr_meta", self.get_text(self.inp_hdr_meta))
        s.setValue("framerate", self.get_text(self.cmb_framerate))
        s.setValue("normalize", self.chk_normalize.isChecked())
        s.setValue("gain", self.spin_gain.value())
        s.setValue("vframes", self.get_text(self.inp_vframes))
        s.setValue("resize", self.chk_resize.isChecked())
        s.setValue("deinterlace", self.chk_deinterlace.isChecked())
        super().closeEvent(e)


def main():
    app = QApplication(sys.argv)
    app.setApplicationName("AutoFFmpegGui")
    mono = os.path.join(APP_DIR, "DejaVuSansMono.ttf")
    app.setFont(QFont(mono, 9) if os.path.exists(mono) else QFont("DejaVu Sans", 9))
    win = AutoFfmpegGui()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

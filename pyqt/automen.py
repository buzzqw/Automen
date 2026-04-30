#!/usr/bin/env python3
"""
AutoMen - Video Encoding Frontend
Porting da PureBasic 4.x a Python/PyQt6
Autore originale: Buzzqw (azanzani@gmail.com)
"""

import sys
import os
import re
import shutil
import subprocess
import threading
from pathlib import Path

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QDialog,
    QPushButton, QLabel, QLineEdit, QComboBox, QCheckBox,
    QTextEdit, QPlainTextEdit, QSlider, QTabWidget, QFrame,
    QFileDialog, QMessageBox, QStatusBar, QGroupBox,
    QHBoxLayout, QVBoxLayout, QGridLayout, QSizePolicy,
    QSpacerItem
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal, QProcess
from PyQt6.QtGui import QFont, QColor, QPalette

VERSION = "v8.0-py"

# ---------------------------------------------------------------------------
# Rilevamento tool di sistema
# ---------------------------------------------------------------------------

def find_tool(*names):
    """Cerca un eseguibile nel PATH e in percorsi comuni."""
    paths = ["/usr/bin", "/usr/local/bin", "/usr/local/sbin"]
    for name in names:
        found = shutil.which(name)
        if found:
            return found
        for p in paths:
            candidate = os.path.join(p, name)
            if os.path.isfile(candidate):
                return candidate
    return ""


def detect_tools():
    tools = {
        "ffmpeg":     find_tool("ffmpeg"),
        "mencoder":   find_tool("mencoder"),
        "mplayer":    find_tool("mplayer"),
        "x264":       find_tool("x264"),
        "mkvmerge":   find_tool("mkvmerge"),
        "mkvextract": find_tool("mkvextract"),
        "mkvinfo":    find_tool("mkvinfo"),
        "mp4box":     find_tool("MP4Box", "mp4box"),
        "lame":       find_tool("lame"),
        "oggenc":     find_tool("oggenc", "oggenc2"),
        "flac":       find_tool("flac"),
        "faac":       find_tool("faac"),
        "aften":      find_tool("aften"),
        "faad":       find_tool("faad"),
        "neroaacenc": find_tool("neroAacEnc"),
        "eac3to":     "",   # solo Windows
        "avs2yuv":    find_tool("avs2yuv"),
        "x265":       find_tool("x265"),
        "ffmpeg_libx265": False,   # rilevato sotto
    }
    # Verifica se ffmpeg è compilato con libx265 (stderr, non stdout)
    ff = tools["ffmpeg"]
    if ff:
        try:
            import subprocess as _sp
            r = _sp.run([ff, "-encoders"], capture_output=True, text=True, timeout=8)
            tools["ffmpeg_libx265"] = "libx265" in r.stdout or "libx265" in r.stderr
        except Exception:
            tools["ffmpeg_libx265"] = False
    return tools


# ---------------------------------------------------------------------------
# Parsing menprofile.txt
# ---------------------------------------------------------------------------

def load_profiles(profile_path):
    """
    Restituisce dict:
      profiles[encoder_key][index] = {"name": ..., "opts": ...}
    encoder_key es.: "mencoder-xvid", "ffmpeg-x264", "avisynth-x264" ...
    """
    profiles = {}
    if not os.path.isfile(profile_path):
        return profiles
    with open(profile_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith(";"):
                continue
            parts = line.split(";")
            if len(parts) < 4:
                continue
            key   = parts[0].lower()          # es. "Mencoder-XviD" -> "mencoder-xvid"
            idx   = int(parts[1])
            name  = parts[2]
            opts  = parts[3]
            if key not in profiles:
                profiles[key] = {}
            profiles[key][idx] = {"name": name, "opts": opts}
    return profiles


def get_profile_opts(profiles, encoder_key, idx):
    """Restituisce la stringa opzioni o '' se non trovata."""
    k = encoder_key.lower()
    if k in profiles and idx in profiles[k]:
        return profiles[k][idx]["opts"]
    return ""


def get_profile_name(profiles, encoder_key, idx):
    k = encoder_key.lower()
    if k in profiles and idx in profiles[k]:
        return profiles[k][idx]["name"]
    return ""


def count_profiles(profiles, encoder_key):
    k = encoder_key.lower()
    if k in profiles:
        return len(profiles[k])
    return 0


# ---------------------------------------------------------------------------
# Calcolo bitrate
# ---------------------------------------------------------------------------

def calc_bitrate(framecount, framerate, target_mb, audio_codec, audio_bitrate, channels, neroaacenc):
    """Restituisce il bitrate video suggerito in kbit/s."""
    if framerate <= 0 or framecount <= 0:
        return 0
    tsec = framecount / framerate
    target_bytes = float(target_mb) * 1024 * 1024

    abit_kbps = 0.0
    try:
        ab = float(audio_bitrate)
    except Exception:
        ab = 128.0

    if audio_codec == "No Audio":
        abit_kbps = 0.0
    elif audio_codec == "Copy Audio":
        abit_kbps = ab
    elif audio_codec == "MP3 Audio":
        abit_kbps = ab
    elif audio_codec == "AC3 Audio":
        abit_kbps = ab
    elif audio_codec == "FLAC Audio":
        abit_kbps = 1400.0
        if channels == "Original":
            abit_kbps *= 1.7
    elif audio_codec == "OGG Audio":
        abit_kbps = 32 + ab * 28
        if channels == "Original":
            abit_kbps *= 1.7
    elif audio_codec == "AAC Audio":
        if neroaacenc:
            map_ = {0.05:15,0.10:24,0.15:32,0.25:64,0.35:100,
                    0.45:144,0.55:196,0.65:248,0.75:300,0.85:350,0.95:400}
            abit_kbps = 15.0
            for thresh, val in sorted(map_.items()):
                if ab >= thresh:
                    abit_kbps = val
            if ab > 0.95:
                abit_kbps = 425
            if channels == "Original":
                abit_kbps *= 1.7
        else:
            abit_kbps = ab

    # Formula originale di AutoMen
    try:
        bitrate = ((target_bytes - framecount*24 - abit_kbps*1000*tsec*0.128) /
                   ((tsec*0.128)/1024) / 1000) / 1024
    except ZeroDivisionError:
        bitrate = 0
    return int(bitrate)


# ---------------------------------------------------------------------------
# Analisi file (ffprobe / ffmpeg)
# ---------------------------------------------------------------------------

class MediaInfo:
    """Contenitore info media."""
    def __init__(self):
        self.width = 0
        self.height = 0
        self.framerate = 0.0
        self.duration_sec = 0.0
        self.framecount = 0
        self.ar = ""
        self.video_codec = ""
        self.audio_streams = []   # list of str
        self.crop_left = 0
        self.crop_right = 0
        self.crop_top = 0
        self.crop_bottom = 0


def analyze_with_ffmpeg(filepath, ffmpeg_bin, detect_crop=True):
    """Analizza il file con ffmpeg/ffprobe, ritorna MediaInfo."""
    info = MediaInfo()
    if not ffmpeg_bin or not os.path.isfile(filepath):
        return info

    # --- Informazioni base ---
    try:
        cmd = [ffmpeg_bin, "-hide_banner", "-i", filepath]
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = r.stderr  # ffmpeg scrive info su stderr

        for line in output.splitlines():
            line_s = line.strip()

            # Durata
            m = re.search(r"Duration:\s*(\d+):(\d+):([\d.]+)", line_s)
            if m:
                h, mi, s = int(m.group(1)), int(m.group(2)), float(m.group(3))
                info.duration_sec = h*3600 + mi*60 + s

            # Stream video
            if "Video:" in line_s and "Stream" in line_s:
                # codec
                for c in ["mpeg2video","h264","hevc","xvid","divx","mpeg4",
                          "mjpeg","dvvideo","lagarith","ffvp6f","vp6","av1","vp9"]:
                    if c in line_s.lower():
                        info.video_codec = c
                        break
                # risoluzione  es. 1920x1080
                m2 = re.search(r"(\d{2,5})x(\d{2,5})", line_s)
                if m2:
                    info.width  = int(m2.group(1))
                    info.height = int(m2.group(2))
                # DAR
                m3 = re.search(r"DAR\s+(\d+):(\d+)", line_s)
                if m3:
                    n, d = int(m3.group(1)), int(m3.group(2))
                    if d:
                        info.ar = f"{n/d:.4f}"
                # fps
                m4 = re.search(r"([\d.]+)\s+fps", line_s)
                if m4:
                    info.framerate = float(m4.group(1))
                m5 = re.search(r"([\d.]+)\s+tbr", line_s)
                if m5:
                    tbr = float(m5.group(1))
                    if info.framerate == 0:
                        info.framerate = tbr

            # Stream audio
            if "Audio:" in line_s and "Stream" in line_s:
                info.audio_streams.append(line_s)

    except Exception as e:
        print(f"[analyze] errore ffmpeg info: {e}")

    # Normalizza framerate
    fps = info.framerate
    common = [23.976, 24.0, 25.0, 29.97, 30.0, 50.0, 59.94, 60.0]
    for c in common:
        if abs(fps - c) < 0.05:
            info.framerate = c
            break

    if info.framerate > 0 and info.duration_sec > 0:
        info.framecount = int(info.duration_sec * info.framerate)

    if not info.ar and info.height:
        info.ar = f"{info.width/info.height:.4f}"

    # --- Crop detection ---
    if detect_crop and info.width > 0:
        try:
            # campiona 1 frame ogni 100 per velocità
            cmd2 = [ffmpeg_bin, "-hide_banner",
                    "-i", filepath,
                    "-vf", "select=not(mod(n\\,100)),cropdetect",
                    "-an", "-y", "-f", "null", "/dev/null"]
            r2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=120)
            crop_str = ""
            for line in (r2.stdout + r2.stderr).splitlines():
                if "cropdetect" in line and "crop=" in line:
                    m = re.search(r"crop=(\d+):(\d+):(\d+):(\d+)", line)
                    if m:
                        cw = int(m.group(1))
                        ch = int(m.group(2))
                        cx = int(m.group(3))
                        cy = int(m.group(4))
                        info.crop_left   = cx
                        info.crop_top    = cy
                        info.crop_right  = info.width  - cw - cx
                        info.crop_bottom = info.height - ch - cy
        except Exception as e:
            print(f"[analyze] errore cropdetect: {e}")

    return info


# ---------------------------------------------------------------------------
# Costruzione command-line
# ---------------------------------------------------------------------------

def round_mod(value, mod):
    """Arrotonda value al multiplo più vicino di mod."""
    if mod <= 0:
        return value
    return int(round(value / mod) * mod)


class CommandBuilder:
    """Costruisce le righe di comando per la coda."""

    def __init__(self, tools, profiles, state):
        self.t = tools
        self.p = profiles
        self.s = state   # dizionario con tutti i valori UI

    def _workpath(self):
        inp = self.s["input_file"]
        base = os.path.splitext(os.path.basename(inp))[0]
        wp = os.path.join(os.path.dirname(inp), base) + "/"
        os.makedirs(wp, exist_ok=True)
        return wp

    def _profile_key_for_encoder(self, encoder, vcodec):
        """Ritorna la chiave menprofile per l'encoder e codec correnti."""
        enc = encoder.lower()
        vc  = vcodec.lower()
        if "mencoder" in enc:
            return f"mencoder-{vc}"
        if "ffmpeg" in enc:
            if vc == "x265":
                return "ffmpeg-x265"   # sezione opzionale in menprofile
            return f"ffmpeg-{vc}"
        if "x265" in enc:
            return "x265"
        if "x264" in enc or "avisynth" in enc or "pipe" in enc:
            return "avisynth-x264"
        return ""

    def _vf_mencoder(self, workpath):
        """Costruisce la stringa -vf per mencoder."""
        s = self.s
        parts = []
        deint_map = {
            "FILM NTSC (29.97->23.976)": "pullup,softskip",
            "Interlaced":                "yadif",
            "Telecine":                  "filmdint",
            "Mixed Prog/Telecine":       "filmdint",
            "Mixed Prog/Interlaced":     "yadif",
        }
        fps_map = {
            "FILM NTSC (29.97->23.976)": "-ofps 24000/1001",
            "Telecine":                  "-ofps 24000/1001",
            "Mixed Prog/Telecine":       "-ofps 24000/1001",
            "Change FPS to 25":          "-ofps 25000/1000",
            "Change FPS to 23.976":      "-ofps 24000/1001",
            "Change FPS to 29.97":       "-ofps 30000/1001",
        }
        deint = s.get("deint", "Progressive")
        vf_pre = fps_map.get(deint, "")

        if deint in deint_map:
            parts.append(deint_map[deint])

        if s.get("allow_resize", True):
            cl = s["crop_left"]; cr = s["crop_right"]
            ct = s["crop_top"];  cb = s["crop_bottom"]
            cw = s["src_width"] - cl - cr
            ch = s["src_height"] - ct - cb
            parts.append(f"crop={cw}:{ch}:{cl}:{ct}")
            parts.append(f"scale={s['out_width']}:{s['out_height']}")

        denoise_map = {"Super Light":"hqdn3d=1","Light":"hqdn3d=2",
                       "Normal":"hqdn3d=4","Severe":"hqdn3d=6"}
        dn = s.get("denoise", "NONE")
        if dn in denoise_map:
            parts.append(denoise_map[dn])

        result = ""
        if parts:
            result = f"{vf_pre} -vf " + ",".join(parts)
        elif vf_pre:
            result = vf_pre
        return result.strip()

    def _vf_ffmpeg(self):
        s = self.s
        parts = []
        if s.get("allow_resize", True):
            cl = s["crop_left"]; cr = s["crop_right"]
            ct = s["crop_top"];  cb = s["crop_bottom"]
            cw = s["src_width"] - cl - cr
            ch = s["src_height"] - ct - cb
            if cl+cr+ct+cb > 0:
                parts.append(f"crop={cw}:{ch}:{cr}:{cb}")
            parts.append(f"scale={s['out_width']}:{s['out_height']}")

        deint = s.get("deint", "Progressive")
        if deint != "Progressive":
            parts.append("yadif")

        if parts:
            return "-vf " + ",".join(parts)
        return ""

    def _fps_ffmpeg(self):
        s = self.s
        deint = s.get("deint", "Progressive")
        fps_map = {
            "FILM NTSC (29.97->23.976)": "-r 23.976",
            "Telecine":                  "-r 23.976",
            "Mixed Prog/Telecine":       "-r 23.976",
            "Change FPS to 23.976":      "-r 23.976",
            "Change FPS to 25":          "-r 25",
            "Change FPS to 29.97":       "-r 29.97",
        }
        return fps_map.get(deint, "")

    def build_audio_cmd(self):
        """Costruisce il comando di estrazione/codifica audio. Ritorna (cmd_str, audio_file)."""
        s = self.s
        if s.get("audio_track", "none") == "none" or s.get("audio_codec") == "No Audio":
            return "", ""
        workpath = self._workpath()
        inp  = s["input_file"]
        ff   = self.t["ffmpeg"]
        codec = s.get("audio_codec", "Copy Audio")
        ab    = s.get("audio_bitrate", "128")
        ch    = s.get("audio_channels", "2")
        norm  = s.get("audio_normalize", False)
        track_str = s.get("audio_track", "")

        # Mappa stream audio: cerca "#0:N" nella stringa della traccia
        map_opt = ""
        for i in range(1, 12):
            if f"#0:{i}" in track_str:
                map_opt = f"-map 0:{i}"
                break
        if not map_opt and track_str and track_str != "none":
            map_opt = "-map 0:a:0"

        def ffmpeg_wav():
            """Estrae audio come WAV per ricodifica successiva."""
            wav = workpath + "automen.wav"
            # Costruisci filtri audio
            af_parts = []
            if ch == "2":
                af_parts.append("aformat=channel_layouts=stereo")
            elif ch == "1":
                af_parts.append("aformat=channel_layouts=mono")
            if norm:
                # loudnorm: analisi+normalizzazione in un passaggio
                af_parts.append("loudnorm=I=-16:TP=-1.5:LRA=11")
            af_str = f'-af "{",".join(af_parts)}"' if af_parts else ""
            cmd = (f'{ff} -i "{inp}" -vn {map_opt} {af_str} '
                   f'-ar 48000 -f wav -y "{wav}"')
            return cmd.strip(), wav

        # ── COPY AUDIO ──────────────────────────────────────────────────────
        if codec == "Copy Audio":
            ext = "ac3"
            track_low = track_str.lower()
            for fmt, ext_out in [("ac3","ac3"),("dts-hd","dts"),("dts","dts"),
                                  ("truehd","ac3"),("flac","flac"),("mp2","mp2"),
                                  ("mp3","mp3"),("aac","aac"),("pcm","wav"),
                                  ("vorbis","ogg"),("opus","opus")]:
                if fmt in track_low:
                    ext = ext_out
                    break
            out = workpath + f"automen_audio.{ext}"
            cmd = f'{ff} -i "{inp}" -vn {map_opt} -c:a copy -y "{out}"'
            return cmd, out

        wav_cmd, wav = ffmpeg_wav()

        # ── MP3 ─────────────────────────────────────────────────────────────
        if codec == "MP3 Audio":
            mode = s.get("mp3mode", "cbr")
            out  = workpath + "automen_audio.mp3"
            lame = self.t["lame"]
            if lame:
                if mode == "cbr":
                    enc = f'{lame} -h --cbr -b {ab} "{wav}" "{out}"'
                else:
                    enc = f'{lame} -h --abr {ab} "{wav}" "{out}"'
            else:
                enc = f'{ff} -i "{wav}" -c:a libmp3lame -b:a {ab}k -y "{out}"'
            return wav_cmd + "\n" + enc, out

        # ── AC3 ─────────────────────────────────────────────────────────────
        if codec == "AC3 Audio":
            out   = workpath + "automen_audio.ac3"
            aften = self.t["aften"]
            if aften:
                # aften: aften [opzioni] <input> <output>  (-b in kbps)
                enc = f'{aften} -b {ab} "{wav}" "{out}"'
            else:
                # Fallback: ffmpeg nativo
                enc = f'{ff} -i "{wav}" -c:a ac3 -b:a {ab}k -y "{out}"'
            return wav_cmd + "\n" + enc, out

        # ── FLAC ─────────────────────────────────────────────────────────────
        if codec == "FLAC Audio":
            out  = workpath + "automen_audio.flac"
            flac = self.t["flac"]
            if flac:
                # flac accetta livelli -0..-8
                level = ab if ab.lstrip("-").isdigit() and ab.startswith("-") else f"-{ab.lstrip('-')}"
                enc = f'{flac} {level} -f -o "{out}" "{wav}"'
            else:
                enc = f'{ff} -i "{wav}" -c:a flac -compression_level 5 -y "{out}"'
            return wav_cmd + "\n" + enc, out

        # ── OGG ─────────────────────────────────────────────────────────────
        if codec == "OGG Audio":
            out    = workpath + "automen_audio.ogg"
            oggenc = self.t["oggenc"]
            if oggenc:
                enc = f'{oggenc} -q {ab} -o "{out}" "{wav}"'
            else:
                enc = f'{ff} -i "{wav}" -c:a libvorbis -q:a {ab} -y "{out}"'
            return wav_cmd + "\n" + enc, out

        # ── AAC ─────────────────────────────────────────────────────────────
        if codec == "AAC Audio":
            out = workpath + "automen_audio.aac"
            if self.t["neroaacenc"]:
                nero = self.t["neroaacenc"]
                enc  = f'{nero} -q {ab} -ignorelength -if "{wav}" -of "{out}"'
            elif self.t["faac"]:
                faac = self.t["faac"]
                enc  = f'{faac} -b {ab} -o "{out}" "{wav}"'
            else:
                # ffmpeg nativo AAC (qualità discreta)
                enc = f'{ff} -i "{wav}" -c:a aac -b:a {ab}k -y "{out}"'
            return wav_cmd + "\n" + enc, out

        return "", ""

    def build_video_cmd(self, pass_num, audio_file):
        """Costruisce il comando di codifica video (ffmpeg/mencoder/x264/x265)."""
        s = self.s
        workpath   = self._workpath()
        inp        = s["input_file"]
        bitrate    = s.get("video_bitrate", "1500")
        encoder    = s.get("encoder", "FFmpeg")
        vcodec     = s.get("video_codec", "X264")
        pass_mode  = s.get("pass_mode", "1 pass")
        preset_idx = s.get("preset_idx", 5)
        enc_low    = encoder.lower()

        # Output temporaneo
        ext_map = {"XviD":"avi","Mpeg4":"avi","X264":"h264","X265":"hevc","WMV":"wmv"}
        tmp_ext = ext_map.get(vcodec, "avi")
        tmp_out = workpath + f"automen.{tmp_ext}"

        profile_key = self._profile_key_for_encoder(encoder, vcodec)
        prof_opts   = get_profile_opts(self.p, profile_key, preset_idx)

        # ── FFMPEG ──────────────────────────────────────────────────────────
        if "ffmpeg" in enc_low:
            ff      = self.t["ffmpeg"]
            vf      = self._vf_ffmpeg()
            fps_opt = self._fps_ffmpeg()

            # Scelta codec ffmpeg
            codec_map = {
                "XviD":  "-c:v libxvid",
                "Mpeg4": "-c:v mpeg4",
                "X264":  "-c:v libx264",
                "X265":  "-c:v libx265",
                "WMV":   "-c:v wmv2",
            }
            c_opt = codec_map.get(vcodec, "-c:v libx264")

            pass_opt = ""
            passlog  = "/tmp/automen_ff2pass"
            if pass_mode == "1 pass":
                pass_opt = f"-b:v {bitrate}k"
            elif pass_mode == "2 pass" and pass_num == 1:
                pass_opt = f"-b:v {bitrate}k -pass 1 -passlogfile {passlog}"
            elif pass_mode == "2 pass" and pass_num == 2:
                pass_opt = f"-b:v {bitrate}k -pass 2 -passlogfile {passlog}"
            elif pass_mode == "CRF 1 pass":
                # x265 usa -crf nativamente, x264 anche
                pass_opt = f"-crf {bitrate}"
            elif pass_mode == "QP 1 pass":
                pass_opt = f"-qp {bitrate}"
            elif pass_mode == "Copy Video":
                c_opt    = "-c:v copy"
                pass_opt = ""
            elif pass_mode == "Same Quality":
                pass_opt = "-q:v 2"  # -qscale è deprecato, usare -q:v

            # Threads: 0 = auto
            threads = "-threads 0"
            # Le opzioni profilo per x265 via ffmpeg sono opzioni ffmpeg dirette
            # (-preset, -tune, ecc.) - NON dentro -x265-params
            # I parametri interni x265 andrebbero in: -x265-params key=val:key=val
            # ma i preset li gestiamo come opzioni ffmpeg standard
            cmd = (f'{ff} -i "{inp}" {vf} {fps_opt} {c_opt} '
                   f'{pass_opt} {prof_opts} {threads} -an -y "{tmp_out}"')
            return cmd.strip(), tmp_out

        # ── MENCODER ────────────────────────────────────────────────────────
        if "mencoder" in enc_low:
            mc     = self.t["mencoder"]
            vf_str = self._vf_mencoder(workpath)

            if pass_mode == "1 pass":
                prof_opts = prof_opts.replace("bitrate", f"bitrate={bitrate}")
            elif pass_mode == "2 pass" and pass_num == 1:
                prof_opts = prof_opts.replace("bitrate", f"bitrate={bitrate}:pass=1") + ":turbo"
            elif pass_mode == "2 pass" and pass_num == 2:
                prof_opts = prof_opts.replace("bitrate", f"bitrate={bitrate}:pass=2")
            elif pass_mode == "CRF 1 pass":
                if vcodec == "XviD":
                    prof_opts = prof_opts.replace("bitrate", f"fixed_quant={bitrate}")
                elif vcodec == "Mpeg4":
                    prof_opts = prof_opts.replace("vbitrate", f"vqscale={bitrate}")
                else:
                    prof_opts = prof_opts.replace("bitrate", f"crf={bitrate}")
            elif pass_mode == "QP 1 pass":
                if vcodec == "XviD":
                    prof_opts = prof_opts.replace("bitrate", f"fixed_quant={bitrate}")
                else:
                    prof_opts = prof_opts.replace("bitrate", f"crf={bitrate}")
            elif pass_mode == "Copy Video":
                prof_opts = "-ovc copy"

            if vcodec == "Mpeg4":
                prof_opts = prof_opts.replace("pass=", "vpass=")

            passlog = '-passlogfile "/tmp/automen_mc2pass.log"'
            odml    = "-noodml" if s.get("noodml", False) else ""
            # -lavdopts threads=N: deprecato nelle versioni recenti di mencoder;
            # usare -lavcopts threads=N per il decoder e vhq etc nel codec string
            cmd = (f'{mc} {vf_str} {odml} -o "{tmp_out}" '
                   f'{prof_opts} -nosound {passlog} "{inp}"')
            return cmd.strip(), tmp_out

        # ── X264 standalone ─────────────────────────────────────────────────
        if "x264" in enc_low and "x265" not in enc_low:
            x264    = self.t["x264"]
            passlog = "/tmp/automen_x264.stats"
            pass_opt = ""
            if pass_mode == "1 pass":
                pass_opt = f"--bitrate {bitrate}"
            elif pass_mode == "2 pass" and pass_num == 1:
                pass_opt = f"--pass 1 --bitrate {bitrate} --stats {passlog}"
            elif pass_mode == "2 pass" and pass_num == 2:
                pass_opt = f"--pass 2 --bitrate {bitrate} --stats {passlog}"
            elif pass_mode == "CRF 1 pass":
                pass_opt = f"--crf {bitrate}"
            elif pass_mode == "QP 1 pass":
                pass_opt = f"--qp {bitrate}"

            vf_arg = ""
            if s.get("allow_resize", True):
                cl, cr = s["crop_left"], s["crop_right"]
                ct, cb = s["crop_top"],  s["crop_bottom"]
                ow, oh = s["out_width"], s["out_height"]
                # x264 --video-filter crop:left,top,right,bottom/resize:w,h
                resizer = s.get("resizer", "2 bicubic").split()[-1]
                vf_arg  = f'--video-filter "crop:{cl},{ct},{cr},{cb}/resize:{ow},{oh},method={resizer}"'

            # --demuxer lavf per leggere direttamente file non-raw
            cmd = (f'{x264} --demuxer lavf {prof_opts} {pass_opt} {vf_arg} '
                   f'--output "{tmp_out}" "{inp}"')
            return cmd.strip(), tmp_out

        # ── X265 standalone ─────────────────────────────────────────────────
        if "x265" in enc_low:
            x265    = self.t.get("x265", "")
            if not x265:
                # Prova via ffmpeg se x265 standalone non c'è
                return self._ffmpeg_x265_cmd(inp, tmp_out, bitrate, pass_mode, pass_num)
            passlog = "/tmp/automen_x265.stats"
            pass_opt = ""
            if pass_mode == "1 pass":
                pass_opt = f"--bitrate {bitrate}"
            elif pass_mode == "2 pass" and pass_num == 1:
                pass_opt = f"--pass 1 --bitrate {bitrate} --stats {passlog}"
            elif pass_mode == "2 pass" and pass_num == 2:
                pass_opt = f"--pass 2 --bitrate {bitrate} --stats {passlog}"
            elif pass_mode == "CRF 1 pass":
                pass_opt = f"--crf {bitrate}"
            elif pass_mode == "QP 1 pass":
                pass_opt = f"--qp {bitrate}"

            # x265 standalone legge solo YUV raw: servono pipe da ffmpeg
            # ffmpeg -i input -f yuv4mpegpipe - | x265 --y4m ... - --output out.hevc
            vf_filter = self._vf_ffmpeg()  # riusa la logica ffmpeg
            ff        = self.t["ffmpeg"]
            pipe_cmd  = f'{ff} -i "{inp}" {vf_filter} -f yuv4mpegpipe -'
            x265_cmd  = f'{x265} --y4m {prof_opts} {pass_opt} - --output "{tmp_out}"'
            cmd       = pipe_cmd + " | " + x265_cmd
            return cmd.strip(), tmp_out

        return "", ""

    def _ffmpeg_x265_cmd(self, inp, tmp_out, bitrate, pass_mode, pass_num):
        """Codifica x265 via ffmpeg libx265 (fallback se x265 standalone assente)."""
        ff      = self.t["ffmpeg"]
        vf      = self._vf_ffmpeg()
        passlog = "/tmp/automen_ff265"
        pass_opt = ""
        if pass_mode == "1 pass":
            pass_opt = f"-b:v {bitrate}k"
        elif pass_mode == "2 pass" and pass_num == 1:
            pass_opt = f"-b:v {bitrate}k -pass 1 -passlogfile {passlog}"
        elif pass_mode == "2 pass" and pass_num == 2:
            pass_opt = f"-b:v {bitrate}k -pass 2 -passlogfile {passlog}"
        elif pass_mode == "CRF 1 pass":
            pass_opt = f"-crf {bitrate}"
        cmd = (f'{ff} -i "{inp}" {vf} -c:v libx265 {pass_opt} '
               f'-threads 0 -an -y "{tmp_out}"')
        return cmd.strip(), tmp_out

    def build_mux_cmd(self, video_file, audio_file, out_file):
        """Costruisce il comando di mux finale."""
        s = self.s
        ext = os.path.splitext(out_file)[1].lower().lstrip(".")

        deint = s.get("deint", "Progressive")
        fps = s.get("framerate", 25.0)
        fps_map = {
            "FILM NTSC (29.97->23.976)": 23.976,
            "Telecine": 23.976, "Mixed Prog/Telecine": 23.976,
            "Change FPS to 23.976": 23.976,
            "Change FPS to 25": 25.0,
            "Change FPS to 29.97": 29.97,
        }
        fps = fps_map.get(deint, fps)

        if ext == "mkv":
            mkvm = self.t["mkvmerge"]
            audio_part = f'"{audio_file}"' if audio_file else ""
            dar_str = f'--aspect-ratio -1:{s.get("dar", "1.7778")}'
            cmd = (f'{mkvm} -o "{out_file}" --default-duration 0:{fps}fps '
                   f'{dar_str} "{video_file}" {audio_part}')
            return cmd.strip()

        if ext == "mp4":
            mp4b = self.t["mp4box"]
            audio_part = f'-add "{audio_file}"' if audio_file else ""
            cmd = f'{mp4b} "{out_file}" -fps {fps} -add "{video_file}" {audio_part}'
            return cmd.strip()

        if ext in ("avi", "wmv"):
            ff = self.t["ffmpeg"]
            audio_part = f'-i "{audio_file}"' if audio_file else ""
            cmd = (f'{ff} -i "{video_file}" {audio_part} '
                   f'-vcodec copy -acodec copy -y "{out_file}"')
            return cmd.strip()

        if ext in ("h264", "hevc"):
            cmds = [f'cp "{video_file}" "{out_file}"']
            if audio_file:
                aext = os.path.splitext(audio_file)[1]
                aout = os.path.splitext(out_file)[0] + aext
                cmds.append(f'cp "{audio_file}" "{aout}"')
            return "\n".join(cmds)

        return ""

    def build_full_queue(self):
        """Costruisce tutta la coda di comandi come lista di str."""
        s = self.s
        pass_mode = s.get("pass_mode", "1 pass")
        out_file  = s.get("output_file", "")
        clean     = s.get("clean_tmp", False)
        shutdown  = s.get("shutdown", False)
        workpath  = self._workpath()

        queue = []
        audio_cmd, audio_file = self.build_audio_cmd()
        if audio_cmd:
            queue.extend([l for l in audio_cmd.splitlines() if l.strip()])

        if pass_mode == "2 pass":
            cmd1, tmp_vid = self.build_video_cmd(1, audio_file)
            queue.append(cmd1)
            cmd2, tmp_vid = self.build_video_cmd(2, audio_file)
            queue.append(cmd2)
        else:
            cmd1, tmp_vid = self.build_video_cmd(1, audio_file)
            queue.append(cmd1)

        if out_file:
            mux_cmd = self.build_mux_cmd(tmp_vid, audio_file, out_file)
            if mux_cmd:
                queue.extend([l for l in mux_cmd.splitlines() if l.strip()])

        if clean:
            queue.append(f'rm -f "{workpath}automen"*')

        if shutdown:
            queue.append("shutdown -h now")

        return queue


# ---------------------------------------------------------------------------
# Worker thread per analisi file
# ---------------------------------------------------------------------------

class AnalyzeWorker(QThread):
    done = pyqtSignal(object)  # MediaInfo
    error = pyqtSignal(str)

    def __init__(self, filepath, ffmpeg_bin, detect_crop=True):
        super().__init__()
        self.filepath = filepath
        self.ffmpeg = ffmpeg_bin
        self.detect_crop = detect_crop

    def run(self):
        try:
            info = analyze_with_ffmpeg(self.filepath, self.ffmpeg, self.detect_crop)
            self.done.emit(info)
        except Exception as e:
            self.error.emit(str(e))


# ---------------------------------------------------------------------------
# Finestra principale
# ---------------------------------------------------------------------------

class AutoMenWindow(QMainWindow):

    def __init__(self):
        super().__init__()
        self.tools = detect_tools()
        here = os.path.dirname(os.path.abspath(__file__))
        profile_path = os.path.join(here, "menprofile.txt")
        self.profiles = load_profiles(profile_path)
        self.media_info = MediaInfo()
        self.audio_file = ""
        self.tmp_video  = ""

        self.setWindowTitle(f"AutoMen {VERSION}")
        self.setMinimumSize(620, 520)
        self._build_ui()
        self._check_tools()
        self._populate_encoders()
        self._on_encoder_changed()
        self._on_audio_codec_changed()
        self.status.showMessage("Apri un file video per iniziare la codifica.")

    # ------------------------------------------------------------------ UI --

    def _build_ui(self):
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QVBoxLayout(central)
        main_layout.setContentsMargins(8, 8, 8, 8)
        main_layout.setSpacing(4)

        # -- Barra superiore: input / output / pulsanti --
        row1 = QHBoxLayout()
        self.btn_open   = QPushButton("Apri...")
        self.btn_save   = QPushButton("Salva...")
        self.btn_play   = QPushButton("▶ Play")
        self.btn_encode = QPushButton("⚡ Encode")
        self.btn_preview= QPushButton("👁 Preview")
        for b, w in [(self.btn_open,70),(self.btn_save,70),(self.btn_play,80),
                     (self.btn_encode,80),(self.btn_preview,80)]:
            b.setFixedWidth(w)
        self.edit_input  = QLineEdit()
        self.edit_output = QLineEdit()
        self.edit_input.setPlaceholderText("File sorgente...")
        self.edit_output.setPlaceholderText("File destinazione...")

        # combo_encoder: oggetto interno, NON mostrato in UI
        # L'encoder viene scelto automaticamente in base al codec (pick_best_encoder)
        self.combo_encoder = QComboBox()   # non aggiunto al layout

        # Layout barra superiore (pulito, senza encoder)
        grid_io = QGridLayout()
        grid_io.setSpacing(4)

        # Riga 0: Apri | input | Play | Encode
        grid_io.addWidget(self.btn_open,       0, 0)
        grid_io.addWidget(self.edit_input,     0, 1)
        grid_io.addWidget(self.btn_play,       0, 2)
        grid_io.addWidget(self.btn_encode,     0, 3)

        # Riga 1: Salva | output | Preview
        grid_io.addWidget(self.btn_save,       1, 0)
        grid_io.addWidget(self.edit_output,    1, 1)
        grid_io.addWidget(self.btn_preview,    1, 2)

        grid_io.setColumnStretch(1, 1)
        main_layout.addLayout(grid_io)

        # -- Tab principale --
        self.tabs = QTabWidget()
        main_layout.addWidget(self.tabs)

        self.tabs.addTab(self._tab_summary(),  "Riepilogo")
        self.tabs.addTab(self._tab_video(),    "Video")
        self.tabs.addTab(self._tab_audio(),    "Audio")
        self.tabs.addTab(self._tab_filters(),  "Filtri")
        self.tabs.addTab(self._tab_queue(),    "Coda")

        # -- Statusbar --
        self.status = QStatusBar()
        self.setStatusBar(self.status)

        # -- Connessioni --
        self.btn_open.clicked.connect(self._open_file)
        self.btn_save.clicked.connect(self._save_file)
        self.btn_play.clicked.connect(self._play_file)
        self.btn_encode.clicked.connect(self._encode)
        self.btn_preview.clicked.connect(self._preview)
        self.combo_vcodec.currentIndexChanged.connect(self._on_vcodec_changed)
        self.combo_container.currentIndexChanged.connect(self._update_output_ext)
        self.combo_pass.currentIndexChanged.connect(self._on_pass_changed)
        self.combo_encoder.currentIndexChanged.connect(self._on_encoder_changed)
        self.combo_audio_codec.currentIndexChanged.connect(self._on_audio_codec_changed)
        self.slider_preset.valueChanged.connect(self._on_preset_changed)
        self.edit_cds.textChanged.connect(self._recalc_bitrate)
        self.edit_audio_bitrate.currentIndexChanged.connect(self._recalc_bitrate)
        self.chk_allow_resize.stateChanged.connect(self._on_allow_resize_changed)
        self.slider_width.valueChanged.connect(self._on_slider_width)
        self.edit_crop_top.textChanged.connect(self._recalc_scale)
        self.edit_crop_bottom.textChanged.connect(self._recalc_scale)
        self.edit_crop_left.textChanged.connect(self._recalc_scale)
        self.edit_crop_right.textChanged.connect(self._recalc_scale)
        self.edit_out_width.textChanged.connect(self._recalc_scale)
        self.combo_ar.currentTextChanged.connect(self._recalc_scale)
        self.btn_add_queue.clicked.connect(self._add_to_queue)
        self.btn_start_queue.clicked.connect(self._start_queue)
        self.btn_clear_queue.clicked.connect(self.txt_queue.clear)
        self.btn_autocrop.clicked.connect(self._do_autocrop)
        self.btn_make_report.clicked.connect(self._make_report)

    def _tab_summary(self):
        w = QWidget()
        h = QHBoxLayout(w)

        # Sinistra: info file
        left = QGroupBox("File sorgente")
        lg = QGridLayout(left)
        self.lbl_info = QPlainTextEdit()
        self.lbl_info.setReadOnly(True)
        self.lbl_info.setMaximumHeight(130)
        lg.addWidget(self.lbl_info, 0, 0, 1, 4)

        lg.addWidget(QLabel("W / H:"), 1, 0)
        self.edit_src_w = QLineEdit(); self.edit_src_h = QLineEdit()
        self.edit_src_w.setMaximumWidth(60); self.edit_src_h.setMaximumWidth(60)
        lg.addWidget(self.edit_src_w, 1, 1)
        lg.addWidget(self.edit_src_h, 1, 2)

        lg.addWidget(QLabel("FPS / Frame:"), 2, 0)
        self.edit_fps = QLineEdit(); self.edit_frames = QLineEdit()
        self.edit_fps.setMaximumWidth(70); self.edit_frames.setMaximumWidth(70)
        lg.addWidget(self.edit_fps, 2, 1)
        lg.addWidget(self.edit_frames, 2, 2)

        h.addWidget(left, 1)

        # Destra: impostazioni target
        right = QGroupBox("Formato destinazione")
        rg = QGridLayout(right)

        rg.addWidget(QLabel("Codec video:"), 0, 0)
        self.combo_vcodec = QComboBox()       # riempito da _on_encoder_changed
        rg.addWidget(self.combo_vcodec, 0, 1)
        self.combo_container = QComboBox()    # riempito da _on_encoder_changed
        rg.addWidget(self.combo_container, 0, 2)

        rg.addWidget(QLabel("Modalità:"), 1, 0)
        self.combo_pass = QComboBox()
        rg.addWidget(self.combo_pass, 1, 1, 1, 2)

        rg.addWidget(QLabel("Preset:"), 2, 0)
        self.slider_preset = QSlider(Qt.Orientation.Horizontal)
        self.slider_preset.setRange(1, 11)
        self.slider_preset.setValue(6)
        self.slider_preset.setTickPosition(QSlider.TickPosition.TicksBelow)
        rg.addWidget(self.slider_preset, 2, 1, 1, 2)

        self.lbl_preset_name = QLineEdit()
        self.lbl_preset_name.setReadOnly(True)
        rg.addWidget(self.lbl_preset_name, 3, 0, 1, 3)

        rg.addWidget(QLabel("Bitrate video:"), 4, 0)
        self.edit_video_bitrate = QLineEdit("1500")
        self.edit_video_bitrate.setMaximumWidth(80)
        rg.addWidget(self.edit_video_bitrate, 4, 1)
        rg.addWidget(QLabel("kbit/s"), 4, 2)

        rg.addWidget(QLabel("Durata (min):"), 5, 0)
        self.edit_duration = QLineEdit()
        self.edit_duration.setReadOnly(True)
        self.edit_duration.setMaximumWidth(60)
        rg.addWidget(self.edit_duration, 5, 1)
        rg.addWidget(QLabel("Target MB:"), 5, 2)
        self.edit_cds = QLineEdit("700")
        self.edit_cds.setMaximumWidth(60)
        rg.addWidget(self.edit_cds, 5, 3)

        h.addWidget(right, 1)
        return w

    def _tab_video(self):
        w = QWidget()
        g = QGridLayout(w)
        g.addWidget(QLabel("Deinterlacciamento:"), 0, 0)
        self.combo_deint = QComboBox()
        self.combo_deint.addItems([
            "Progressive","FILM NTSC (29.97->23.976)","Interlaced",
            "Telecine","Mixed Prog/Telecine","Mixed Prog/Interlaced",
            "Change FPS to 23.976","Change FPS to 25","Change FPS to 29.97"
        ])
        g.addWidget(self.combo_deint, 0, 1, 1, 3)

        g.addWidget(QLabel("Aspect Ratio:"), 1, 0)
        self.combo_ar = QComboBox()
        self.combo_ar.setEditable(True)
        self.combo_ar.addItems(["1","1.3334","1.7778","1.85","2.35"])
        g.addWidget(self.combo_ar, 1, 1)

        self.chk_anamorphic = QCheckBox("Anamorphic")
        g.addWidget(self.chk_anamorphic, 1, 2)
        self.chk_itu = QCheckBox("ITU Resizing")
        g.addWidget(self.chk_itu, 1, 3)

        self.chk_allow_resize = QCheckBox("Permetti resize/crop")
        self.chk_allow_resize.setChecked(True)
        g.addWidget(self.chk_allow_resize, 2, 0, 1, 2)

        self.btn_autocrop = QPushButton("Auto Crop")
        g.addWidget(self.btn_autocrop, 2, 2)

        # Crop
        grp_crop = QGroupBox("Crop (pixel)")
        gc = QGridLayout(grp_crop)
        gc.addWidget(QLabel("Top:"), 0, 1)
        self.edit_crop_top = QLineEdit("0"); self.edit_crop_top.setMaximumWidth(50)
        gc.addWidget(self.edit_crop_top, 1, 1)
        gc.addWidget(QLabel("Left:"), 1, 0)
        self.edit_crop_left = QLineEdit("0"); self.edit_crop_left.setMaximumWidth(50)
        gc.addWidget(self.edit_crop_left, 1, 0)
        gc.addWidget(QLabel("Right:"), 1, 2)
        self.edit_crop_right = QLineEdit("0"); self.edit_crop_right.setMaximumWidth(50)
        gc.addWidget(self.edit_crop_right, 1, 2)
        gc.addWidget(QLabel("Bottom:"), 2, 1)
        self.edit_crop_bottom = QLineEdit("0"); self.edit_crop_bottom.setMaximumWidth(50)
        gc.addWidget(self.edit_crop_bottom, 2, 1)
        g.addWidget(grp_crop, 3, 0, 1, 2)

        grp_size = QGroupBox("Output size")
        gs = QGridLayout(grp_size)
        self.slider_width = QSlider(Qt.Orientation.Horizontal)
        self.slider_width.setRange(10, 200)   # 10%..200% (upscale permesso)
        self.slider_width.setValue(87)
        self.slider_width.setTickInterval(10)
        self.slider_width.setTickPosition(QSlider.TickPosition.TicksBelow)
        self.lbl_slider_pct = QLabel("87%")
        self.lbl_slider_pct.setMinimumWidth(38)
        gs.addWidget(QLabel("Scala %:"), 0, 0)
        gs.addWidget(self.slider_width, 0, 1, 1, 2)
        gs.addWidget(self.lbl_slider_pct, 0, 3)
        gs.addWidget(QLabel("W x H:"), 1, 0)
        self.edit_out_width  = QLineEdit(); self.edit_out_width.setMaximumWidth(70)
        self.edit_out_height = QLineEdit(); self.edit_out_height.setMaximumWidth(70)
        gs.addWidget(self.edit_out_width, 1, 1)
        gs.addWidget(QLabel("x"), 1, 2)
        gs.addWidget(self.edit_out_height, 1, 3)
        gs.addWidget(QLabel("DAR:"), 2, 0)
        self.edit_dar    = QLineEdit(); self.edit_dar.setReadOnly(True); self.edit_dar.setMaximumWidth(70)
        self.edit_ar_err = QLineEdit(); self.edit_ar_err.setReadOnly(True); self.edit_ar_err.setMaximumWidth(70)
        gs.addWidget(self.edit_dar, 2, 1)
        gs.addWidget(QLabel("AR err%:"), 2, 2)
        gs.addWidget(self.edit_ar_err, 2, 3)
        gs.addWidget(QLabel("Mod W:"), 3, 0)
        self.combo_mod_w = QComboBox(); self.combo_mod_w.addItems(["16","8","4"])
        self.combo_mod_h = QComboBox(); self.combo_mod_h.addItems(["16","8","4"])
        gs.addWidget(self.combo_mod_w, 3, 1)
        gs.addWidget(QLabel("Mod H:"), 3, 2)
        gs.addWidget(self.combo_mod_h, 3, 3)
        g.addWidget(grp_size, 3, 2, 1, 2)

        g.setRowStretch(4, 1)
        return w

    def _tab_audio(self):
        w = QWidget()
        g = QGridLayout(w)

        g.addWidget(QLabel("Codec audio:"), 0, 0)
        self.combo_audio_codec = QComboBox()
        self.combo_audio_codec.addItems(["Copy Audio","No Audio"])
        g.addWidget(self.combo_audio_codec, 0, 1, 1, 3)

        self.lbl_audio_bit = QLabel("Bitrate:")
        g.addWidget(self.lbl_audio_bit, 1, 0)
        self.edit_audio_bitrate = QComboBox()
        self.edit_audio_bitrate.setEditable(True)
        self.edit_audio_bitrate.addItems(["320","288","256","224","192","160","128","96","64"])
        self.edit_audio_bitrate.setCurrentIndex(6)
        g.addWidget(self.edit_audio_bitrate, 1, 1)
        self.lbl_audio_bit_unit = QLabel("kbit/s")
        g.addWidget(self.lbl_audio_bit_unit, 1, 2)

        g.addWidget(QLabel("Campionamento:"), 2, 0)
        self.combo_sampling = QComboBox()
        self.combo_sampling.addItems(["AUTO","48000","44100","22050"])
        g.addWidget(self.combo_sampling, 2, 1)
        g.addWidget(QLabel("Hz"), 2, 2)

        g.addWidget(QLabel("Canali:"), 3, 0)
        self.combo_channels = QComboBox()
        self.combo_channels.addItems(["Original","2","1"])
        self.combo_channels.setCurrentIndex(1)
        g.addWidget(self.combo_channels, 3, 1)

        g.addWidget(QLabel("Modo MP3:"), 4, 0)
        self.combo_mp3mode = QComboBox()
        self.combo_mp3mode.addItems(["cbr","abr"])
        g.addWidget(self.combo_mp3mode, 4, 1)

        self.chk_normalize = QCheckBox("Normalizza audio")
        self.chk_normalize.setChecked(True)
        g.addWidget(self.chk_normalize, 5, 0, 1, 2)

        g.addWidget(QLabel("Traccia audio:"), 6, 0)
        self.combo_audio_track = QComboBox()
        self.combo_audio_track.addItem("none")
        g.addWidget(self.combo_audio_track, 6, 1, 1, 3)

        g.addWidget(QLabel("Sottotitoli:"), 7, 0)
        self.combo_subs = QComboBox()
        self.combo_subs.addItem("none")
        g.addWidget(self.combo_subs, 7, 1, 1, 2)
        self.btn_ext_sub = QPushButton("...")
        self.btn_ext_sub.setMaximumWidth(30)
        g.addWidget(self.btn_ext_sub, 7, 3)
        self.btn_ext_sub.clicked.connect(self._browse_subtitle)

        g.setRowStretch(8, 1)
        return w

    def _tab_filters(self):
        w = QWidget()
        g = QGridLayout(w)

        g.addWidget(QLabel("Riduzione rumore:"), 0, 0)
        self.combo_denoise = QComboBox()
        self.combo_denoise.addItems(["NONE","Super Light","Light","Normal","Severe"])
        g.addWidget(self.combo_denoise, 0, 1)

        g.addWidget(QLabel("Resizer:"), 1, 0)
        self.combo_resizer = QComboBox()
        self.combo_resizer.addItems(["0 bilinear","1 bilinear","2 bicubic","3 experimental",
                                     "4 point","5 area","6 bicublin","7 gauss",
                                     "8 sinc","9 lanczos","10 spline"])
        self.combo_resizer.setCurrentIndex(2)
        g.addWidget(self.combo_resizer, 1, 1)

        # Encoder scelto automaticamente da pick_best_encoder() in base al codec
        enc_info = QLabel("Encoder: scelto automaticamente in base al codec")
        enc_info.setStyleSheet("color: gray; font-style: italic;")
        g.addWidget(enc_info, 2, 0, 1, 3)

        self.chk_no_autocrop = QCheckBox("Non fare autocrop (più veloce su file HD/TS)")
        g.addWidget(self.chk_no_autocrop, 3, 0, 1, 3)
        self.chk_noodml = QCheckBox("Non usare ODML (solo Mencoder)")
        g.addWidget(self.chk_noodml, 4, 0, 1, 3)
        self.chk_clean = QCheckBox("Pulisci file temporanei a fine codifica")
        g.addWidget(self.chk_clean, 5, 0, 1, 3)
        self.chk_no_multithread = QCheckBox("Disabilita multithread")
        g.addWidget(self.chk_no_multithread, 6, 0, 1, 3)
        self.chk_divx_fourcc = QCheckBox("FourCC DIVX per XviD")
        g.addWidget(self.chk_divx_fourcc, 7, 0, 1, 3)
        self.chk_shutdown = QCheckBox("Spegni PC a fine codifica")
        g.addWidget(self.chk_shutdown, 8, 0, 1, 2)
        self.btn_make_report = QPushButton("Crea Report (supporto)")
        g.addWidget(self.btn_make_report, 8, 2)

        g.setRowStretch(9, 1)
        return w

    def _tab_queue(self):
        w = QWidget()
        v = QVBoxLayout(w)
        lbl = QLabel("Coda comandi (ogni riga è un comando shell):")
        v.addWidget(lbl)
        self.txt_queue = QPlainTextEdit()
        self.txt_queue.setFont(QFont("Monospace", 8))
        v.addWidget(self.txt_queue)

        h = QHBoxLayout()
        self.btn_add_queue    = QPushButton("Aggiungi alla coda")
        self.btn_start_queue  = QPushButton("▶ Avvia coda")
        self.btn_clear_queue  = QPushButton("Svuota")
        h.addWidget(self.btn_add_queue)
        h.addWidget(self.btn_start_queue)
        h.addWidget(self.btn_clear_queue)
        h.addStretch()

        self.edit_extra_cmd = QLineEdit()
        self.edit_extra_cmd.setPlaceholderText("Comando da aggiungere manualmente...")
        btn_add_extra = QPushButton("+ Aggiungi")
        btn_add_extra.clicked.connect(
            lambda: self.txt_queue.appendPlainText(self.edit_extra_cmd.text())
        )
        h.addWidget(self.edit_extra_cmd)
        h.addWidget(btn_add_extra)
        v.addLayout(h)
        return w

    # ----------------------------------------------------------------- Tools --

    def _check_tools(self):
        t = self.tools
        missing = []
        warns = []
        if not t["ffmpeg"] and not t["mencoder"]:
            missing.append("ffmpeg o mencoder")
        if not t["ffmpeg"]:
            warns.append("ffmpeg non trovato (analisi limitata)")
        if not t["mkvmerge"]:
            warns.append("mkvmerge non trovato (no MKV output)")
        if not t["mp4box"]:
            warns.append("MP4Box non trovato (no MP4 output)")
        if missing:
            QMessageBox.critical(self, "Tool mancanti",
                "Tool essenziali non trovati:\n" + "\n".join(missing))
        elif warns:
            self.status.showMessage("Avvisi: " + " | ".join(warns))

    def _populate_encoders(self):
        t = self.tools
        enc = self.combo_encoder
        enc.blockSignals(True)   # evita scatti prematuri durante il riempimento
        enc.clear()
        if t["mencoder"]:  enc.addItem("Mencoder")
        if t["ffmpeg"]:    enc.addItem("FFmpeg")
        if t["x264"]:      enc.addItem("x264 (lavf)")
        if t["mencoder"] and t["x264"]: enc.addItem("x264+mencoder pipe")
        if t["x265"]:      enc.addItem("x265 (ffmpeg)")
        if t["x265"] and t["x264"]: enc.addItem("x265 (standalone)")
        enc.blockSignals(False)
        # Seleziona FFmpeg come default se disponibile, altrimenti il primo
        idx_ff = enc.findText("FFmpeg")
        enc.setCurrentIndex(idx_ff if idx_ff >= 0 else 0)

        audio = self.combo_audio_codec
        audio.clear()
        audio.addItem("Copy Audio")
        audio.addItem("No Audio")
        if t["lame"]:     audio.addItem("MP3 Audio")
        if t["faac"] or t["neroaacenc"]: audio.addItem("AAC Audio")
        if t["aften"]:    audio.addItem("AC3 Audio")
        if t["oggenc"]:   audio.addItem("OGG Audio")
        if t["flac"]:     audio.addItem("FLAC Audio")

    # --------------------------------------------------------------- Slots --

    def _populate_pass(self):
        """Popola combo_pass in base all'encoder selezionato."""
        enc = self.combo_encoder.currentText().lower()
        cp = self.combo_pass
        current = cp.currentText()
        cp.blockSignals(True)
        cp.clear()
        cp.addItem("1 pass")
        cp.addItem("2 pass")
        cp.addItem("CRF 1 pass")
        cp.addItem("QP 1 pass")
        cp.addItem("Copy Video")
        if "ffmpeg" in enc:
            cp.addItem("Same Quality")
        # Ripristina selezione precedente se ancora valida
        idx = cp.findText(current)
        cp.setCurrentIndex(max(0, idx))
        cp.blockSignals(False)
        self._on_pass_changed()

    def _on_encoder_changed(self):
        """Ripopola codec e container in base all'encoder interno corrente."""
        enc     = self.combo_encoder.currentText().lower()
        t       = self.tools
        vc      = self.combo_vcodec
        ct      = self.combo_container
        prev_vc = vc.currentText()   # ricorda selezione utente
        prev_ct = ct.currentText()

        vc.blockSignals(True)
        ct.blockSignals(True)
        vc.clear(); ct.clear()

        if "mencoder" in enc:
            vc.addItems(["XviD", "Mpeg4", "X264"])
            if t["ffmpeg"] or t["mencoder"]: ct.addItem("AVI")
            if t["mp4box"]:   ct.addItem("MP4")
            if t["mkvmerge"]: ct.addItem("MKV")

        elif "ffmpeg" in enc:
            vc.addItems(["XviD", "Mpeg4", "X264"])
            if t.get("ffmpeg_libx265") or t.get("x265"):
                vc.addItem("X265")
            vc.addItem("WMV")
            ct.addItem("AVI")
            if t["mp4box"]:   ct.addItem("MP4")
            if t["mkvmerge"]: ct.addItem("MKV")
            ct.addItem("WMV")

        elif "x265" in enc:
            vc.addItem("X265")
            if t["mp4box"]:   ct.addItem("MP4")
            if t["mkvmerge"]: ct.addItem("MKV")
            ct.addItem("HEVC")

        else:   # x264 standalone
            vc.addItem("X264")
            if t["mp4box"]:   ct.addItem("MP4")
            if t["mkvmerge"]: ct.addItem("MKV")
            ct.addItem("H264")

        # Ripristina selezioni precedenti se ancora presenti
        idx_vc = vc.findText(prev_vc)
        vc.setCurrentIndex(idx_vc if idx_vc >= 0 else 0)
        idx_ct = ct.findText(prev_ct)
        ct.setCurrentIndex(idx_ct if idx_ct >= 0 else 0)

        vc.blockSignals(False)
        ct.blockSignals(False)

        self._populate_pass()
        self._update_preset_range()
        self._update_output_ext()

        # Statusbar: mostra encoder effettivo scelto per il codec corrente
        vc_name  = vc.currentText()
        enc_name = self.pick_best_encoder(vc_name)
        if enc_name:
            self.status.showMessage(
                f"Codec: {vc_name}  →  Encoder: {enc_name}", 4000)



    def _on_vcodec_changed(self):
        """Utente ha cambiato il codec: aggiorna encoder interno, preset, estensione."""
        vc   = self.combo_vcodec.currentText()
        best = self.pick_best_encoder(vc)
        # Aggiorna combo_encoder interno SENZA riscatenare _on_encoder_changed
        idx = self.combo_encoder.findText(best)
        if idx >= 0:
            self.combo_encoder.blockSignals(True)
            self.combo_encoder.setCurrentIndex(idx)
            self.combo_encoder.blockSignals(False)
        self._populate_pass()
        self._update_preset_range()
        self._update_output_ext()
        # Statusbar
        enc_name = self.pick_best_encoder(vc)
        self.status.showMessage(f"Codec: {vc}  →  Encoder: {enc_name}", 4000)

    def _update_preset_range(self):
        enc = self.combo_encoder.currentText().lower()
        vc  = self.combo_vcodec.currentText().lower()
        if "mencoder" in enc:
            key = f"mencoder-{vc}"
        elif "ffmpeg" in enc:
            key = f"ffmpeg-{vc}" if vc != "x265" else "ffmpeg-x265"
        elif "x265" in enc:
            key = "x265"
        else:
            key = "avisynth-x264"
        n = count_profiles(self.profiles, key)
        # Se non ci sono profili per questo codec, usa range standard
        if n == 0:
            n = 10 if vc in ("x264","x265") else 7
        self.slider_preset.setMaximum(n)
        self._on_preset_changed()

    def _on_preset_changed(self):
        enc = self.combo_encoder.currentText().lower()
        vc  = self.combo_vcodec.currentText().lower()
        idx = self.slider_preset.value()
        if "mencoder" in enc:
            key = f"mencoder-{vc}"
        elif "ffmpeg" in enc:
            key = f"ffmpeg-{vc}" if vc != "x265" else "ffmpeg-x265"
        elif "x265" in enc:
            key = "x265"
        else:
            key = "avisynth-x264"
        name = get_profile_name(self.profiles, key, idx)
        # Nomi preset standard x264/x265 se non in menprofile
        if not name and vc in ("x264", "x265"):
            preset_names = {1:"UltraFast",2:"SuperFast",3:"VeryFast",4:"Faster",
                            5:"Fast",6:"Medium",7:"Slow",8:"Slower",9:"VerySlow",10:"Placebo"}
            name = preset_names.get(idx, "")
        self.lbl_preset_name.setText(f"{vc.upper()} preset {idx}: {name}")

    def _on_pass_changed(self):
        pass_mode = self.combo_pass.currentText()
        is_crf = "CRF" in pass_mode
        self.edit_cds.setEnabled(not is_crf)

    def _on_audio_codec_changed(self):
        codec = self.combo_audio_codec.currentText()
        enabled = codec not in ("Copy Audio","No Audio")
        self.edit_audio_bitrate.setEnabled(True)
        self.combo_sampling.setEnabled(enabled)
        self.combo_channels.setEnabled(True)
        self.combo_mp3mode.setEnabled(codec == "MP3 Audio")

        ab = self.edit_audio_bitrate
        ab.blockSignals(True)
        ab.clear()
        if codec in ("MP3 Audio","Copy Audio"):
            ab.addItems(["320","288","256","224","192","160","128","96","64"])
            ab.setCurrentIndex(6)
        elif codec == "AC3 Audio":
            ab.addItems(["640","448","384","320","224","192"])
            ab.setCurrentIndex(2)
        elif codec == "FLAC Audio":
            ab.addItems(["-8","-7","-6","-5","-4","-3","-2","-1","0"])
            ab.setCurrentIndex(3)
        elif codec == "OGG Audio":
            ab.addItems(["10","9","8","7","6","5","4","3","2","1","0"])
            ab.setCurrentIndex(6)
        elif codec == "AAC Audio":
            if self.tools["neroaacenc"]:
                ab.addItems(["1","0.9","0.8","0.7","0.6","0.5","0.4","0.3","0.2","0.1"])
            else:
                ab.addItems(["320","288","256","224","192","160","128","96","64"])
            ab.setCurrentIndex(6)
        elif codec == "No Audio":
            ab.setEnabled(False)
            self.combo_sampling.setEnabled(False)
            self.combo_channels.setEnabled(False)
        ab.blockSignals(False)
        self._recalc_bitrate()

    def _on_allow_resize_changed(self, state):
        enabled = (state == Qt.CheckState.Checked.value)
        for w in [self.edit_crop_top,self.edit_crop_bottom,
                  self.edit_crop_left,self.edit_crop_right,
                  self.edit_out_width,self.edit_out_height,
                  self.slider_width]:
            w.setEnabled(enabled)

    def _on_slider_width(self):
        pct = self.slider_width.value()
        self.lbl_slider_pct.setText(f"{pct}%")
        src_w = self.media_info.width or int(self.edit_src_w.text() or 0)
        if src_w == 0:
            return
        mod_w = int(self.combo_mod_w.currentText())
        new_w = round_mod(int(src_w * pct / 100), mod_w)
        new_w = max(new_w, mod_w)   # minimo 1 blocco
        self.edit_out_width.blockSignals(True)
        self.edit_out_width.setText(str(new_w))
        self.edit_out_width.blockSignals(False)
        self._recalc_scale()

    def _recalc_scale(self):
        """Ricalcola altezza output in base a larghezza e AR."""
        try:
            src_w = self.media_info.width  or int(self.edit_src_w.text() or 0)
            src_h = self.media_info.height or int(self.edit_src_h.text() or 0)
            if src_w == 0 or src_h == 0:
                return
            cl = int(self.edit_crop_left.text()   or 0)
            cr = int(self.edit_crop_right.text()  or 0)
            ct = int(self.edit_crop_top.text()    or 0)
            cb = int(self.edit_crop_bottom.text() or 0)
            ow = int(self.edit_out_width.text()   or src_w)
            ar_str = self.combo_ar.currentText().strip()
            ar = float(ar_str) if ar_str else src_w/src_h
            mod_h = int(self.combo_mod_h.currentText())

            dar = ((src_w-cl-cr)/src_w) / ((src_h-ct-cb)/src_h) * ar
            oh = round_mod(int(ow / dar), mod_h)
            self.edit_out_height.blockSignals(True)
            self.edit_out_height.setText(str(oh))
            self.edit_out_height.blockSignals(False)
            self.edit_dar.setText(f"{dar:.4f}")
            ar_err = (dar / (ow/oh) * 100 - 100) if oh else 0
            self.edit_ar_err.setText(f"{ar_err:.2f}")
        except Exception:
            pass
        self._recalc_bitrate()

    def _recalc_bitrate(self):
        try:
            fc = int(self.edit_frames.text() or 0)
            fps = float(self.edit_fps.text() or 0)
            mb  = float(self.edit_cds.text() or 700)
            ab_str = self.edit_audio_bitrate.currentText()
            ab = float(ab_str) if ab_str else 128
            codec = self.combo_audio_codec.currentText()
            ch    = self.combo_channels.currentText()
            br = calc_bitrate(fc, fps, mb, codec, ab, ch, bool(self.tools["neroaacenc"]))
            if br > 0:
                self.edit_video_bitrate.setText(str(br))
        except Exception:
            pass

    def _update_output_ext(self):
        container = self.combo_container.currentText()
        ct_ext = {"MKV":"mkv","MP4":"mp4","AVI":"avi","H264":"h264",
                  "HEVC":"hevc","WMV":"wmv"}.get(container, container.lower())
        out = self.edit_output.text()
        if out:
            base = os.path.splitext(out)[0]
            self.edit_output.setText(base + "." + ct_ext)

    def pick_best_encoder(self, vcodec):
        """Sceglie l'encoder migliore disponibile per il codec richiesto.
        Priorità:
          XviD/Mpeg4 → mencoder > ffmpeg
          X264        → mencoder > ffmpeg(libx264) > x264-standalone
          X265        → ffmpeg(libx265) > x265-standalone-pipe
          WMV         → ffmpeg (unico)
        Ritorna una stringa compatibile con combo_encoder.currentText()
        """
        t = self.tools
        vc = vcodec.upper()

        if vc in ("XVID", "MPEG4"):
            if t["mencoder"]:   return "Mencoder"
            if t["ffmpeg"]:     return "FFmpeg"

        elif vc == "X264":
            if t["mencoder"]:   return "Mencoder"
            if t["ffmpeg"]:     return "FFmpeg"
            if t["x264"]:       return "x264 (lavf)"

        elif vc == "X265":
            if t.get("ffmpeg_libx265") and t["ffmpeg"]:
                return "FFmpeg"
            if t["x265"]:       return "x265 (standalone)"
            if t["ffmpeg"]:     return "FFmpeg"   # tenta comunque

        elif vc == "WMV":
            if t["ffmpeg"]:     return "FFmpeg"

        # Fallback generico
        if t["ffmpeg"]:         return "FFmpeg"
        if t["mencoder"]:       return "Mencoder"
        return ""

    def _collect_state(self):
        """Raccoglie tutti i valori UI in un dict."""
        src_w = self.media_info.width  or int(self.edit_src_w.text()  or 0)
        src_h = self.media_info.height or int(self.edit_src_h.text()  or 0)
        return {
            "input_file":     self.edit_input.text(),
            "output_file":    self.edit_output.text(),
            "src_width":      src_w,
            "src_height":     src_h,
            "out_width":      int(self.edit_out_width.text()  or src_w),
            "out_height":     int(self.edit_out_height.text() or src_h),
            "crop_left":      int(self.edit_crop_left.text()   or 0),
            "crop_right":     int(self.edit_crop_right.text()  or 0),
            "crop_top":       int(self.edit_crop_top.text()    or 0),
            "crop_bottom":    int(self.edit_crop_bottom.text() or 0),
            "deint":          self.combo_deint.currentText(),
            "ar":             self.combo_ar.currentText(),
            "dar":            self.edit_dar.text(),
            "anamorphic":     self.chk_anamorphic.isChecked(),
            "itu":            self.chk_itu.isChecked(),
            "allow_resize":   self.chk_allow_resize.isChecked(),
            "framerate":      float(self.edit_fps.text()    or 25),
            "framecount":     int(self.edit_frames.text()  or 0),
            "video_bitrate":  self.edit_video_bitrate.text(),
            "video_codec":    self.combo_vcodec.currentText(),
            "container":      self.combo_container.currentText(),
            "pass_mode":      self.combo_pass.currentText(),
            "preset_idx":     self.slider_preset.value(),
            "encoder":        self.pick_best_encoder(self.combo_vcodec.currentText()),
            "denoise":        self.combo_denoise.currentText(),
            "resizer":        self.combo_resizer.currentText(),
            "noodml":         self.chk_noodml.isChecked(),
            "clean_tmp":      self.chk_clean.isChecked(),
            "shutdown":       self.chk_shutdown.isChecked(),
            "audio_codec":    self.combo_audio_codec.currentText(),
            "audio_bitrate":  self.edit_audio_bitrate.currentText(),
            "audio_channels": self.combo_channels.currentText(),
            "audio_track":    self.combo_audio_track.currentText(),
            "mp3mode":        self.combo_mp3mode.currentText(),
            "audio_normalize":self.chk_normalize.isChecked(),
        }

    # -------------------------------------------------------------- Actions --

    def _open_file(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Apri file video", "",
            "Video (*.avi *.mkv *.mp4 *.mov *.ts *.m2ts *.evo *.vob *.mpg *.mpeg *.ogm *.flv *.wmv);;"
            "Tutti i file (*.*)"
        )
        if not path:
            return
        self.edit_input.setText(path)
        base = os.path.splitext(os.path.basename(path))[0]
        ext  = self.combo_container.currentText().lower()
        out  = os.path.join(os.path.dirname(path), f"automen_{base}.{ext}")
        self.edit_output.setText(out)
        self._analyze_file(path)

    def _save_file(self):
        path, _ = QFileDialog.getSaveFileName(
            self, "Salva file output", "",
            "MKV (*.mkv);;MP4 (*.mp4);;AVI (*.avi);;H264 (*.h264);;Tutti (*.*)"
        )
        if path:
            self.edit_output.setText(path)

    def _play_file(self):
        inp = self.edit_input.text()
        if not inp:
            return
        mpl = self.tools["mplayer"] or self.tools["ffmpeg"]
        if mpl and "mplayer" in mpl:
            subprocess.Popen([mpl, inp])
        elif self.tools["ffmpeg"]:
            subprocess.Popen(["xdg-open", inp])

    def _preview(self):
        inp = self.edit_input.text()
        if not inp or not self.tools["mplayer"]:
            self.status.showMessage("Preview richiede mplayer.")
            return
        s = self._collect_state()
        cl,cr,ct,cb = s["crop_left"],s["crop_right"],s["crop_top"],s["crop_bottom"]
        cw = s["src_width"]-cl-cr; ch = s["src_height"]-ct-cb
        crop = f"crop={cw}:{ch}:{cl}:{ct}"
        scale = f"scale={s['out_width']}:{s['out_height']}"
        ar = s["ar"]
        subprocess.Popen([self.tools["mplayer"],
                         "-vf", f"{crop},{scale}",
                         "-aspect", ar, inp])

    def _analyze_file(self, path):
        no_crop = self.chk_no_autocrop.isChecked()
        self.status.showMessage("Analisi file in corso...")
        self._worker = AnalyzeWorker(path, self.tools["ffmpeg"], detect_crop=not no_crop)
        self._worker.done.connect(self._on_analysis_done)
        self._worker.error.connect(lambda e: self.status.showMessage(f"Errore analisi: {e}"))
        self._worker.start()

    def _on_analysis_done(self, info: MediaInfo):
        self.media_info = info
        self.edit_src_w.setText(str(info.width))
        self.edit_src_h.setText(str(info.height))
        self.edit_fps.setText(f"{info.framerate:.3f}")
        self.edit_frames.setText(str(info.framecount))
        mins = info.duration_sec / 60
        self.edit_duration.setText(f"{mins:.2f}")

        if info.ar:
            self.combo_ar.setCurrentText(info.ar)

        self.edit_crop_top.setText(str(info.crop_top))
        self.edit_crop_bottom.setText(str(info.crop_bottom))
        self.edit_crop_left.setText(str(info.crop_left))
        self.edit_crop_right.setText(str(info.crop_right))

        # Audio tracks
        self.combo_audio_track.clear()
        self.combo_audio_track.addItem("none")
        for s in info.audio_streams:
            self.combo_audio_track.addItem(s)
        if len(info.audio_streams) > 0:
            self.combo_audio_track.setCurrentIndex(1)

        summary = (
            f"File: {os.path.basename(self.edit_input.text())}\n"
            f"Codec: {info.video_codec}\n"
            f"Risoluzione: {info.width}x{info.height}\n"
            f"FPS: {info.framerate:.3f}\n"
            f"Frame: {info.framecount}\n"
            f"Durata: {info.duration_sec:.1f} sec\n"
            f"Aspect Ratio: {info.ar}"
        )
        self.lbl_info.setPlainText(summary)

        self.slider_width.setValue(87)
        self._on_slider_width()
        self._recalc_bitrate()

        # Avviso telecine
        if info.framerate in (29.97, 59.94):
            r = QMessageBox.question(self, "AutoMen",
                "Possibile pattern Telecine trovato (29.97 fps).\n"
                "Attivare IVTC? (FILM NTSC 29.97->23.976)",
                QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No)
            if r == QMessageBox.StandardButton.Yes:
                self.combo_deint.setCurrentText("FILM NTSC (29.97->23.976)")

        self.status.showMessage(f"Analisi completata: {info.width}x{info.height} "
                                f"{info.framerate}fps - {info.video_codec}")

    def _do_autocrop(self):
        inp = self.edit_input.text()
        if not inp:
            return
        self.status.showMessage("Autocrop in corso (può richiedere tempo)...")
        self._worker2 = AnalyzeWorker(inp, self.tools["ffmpeg"], detect_crop=True)
        self._worker2.done.connect(self._on_autocrop_done)
        self._worker2.start()

    def _on_autocrop_done(self, info: MediaInfo):
        self.edit_crop_top.setText(str(info.crop_top))
        self.edit_crop_bottom.setText(str(info.crop_bottom))
        self.edit_crop_left.setText(str(info.crop_left))
        self.edit_crop_right.setText(str(info.crop_right))
        if any([info.crop_top>145,info.crop_bottom>145,
                info.crop_left>145,info.crop_right>145]):
            QMessageBox.warning(self, "AutoCrop",
                "Valori di crop insoliti. Verificare manualmente.")
        self.status.showMessage("Autocrop completato.")

    def _add_to_queue(self):
        inp = self.edit_input.text()
        if not inp:
            QMessageBox.warning(self, "AutoMen", "Caricare un file prima!")
            return
        s = self._collect_state()
        builder = CommandBuilder(self.tools, self.profiles, s)
        cmds = builder.build_full_queue()
        for c in cmds:
            if c.strip():
                self.txt_queue.appendPlainText(c)

    def _encode(self):
        self._add_to_queue()
        self._start_queue()

    def _start_queue(self):
        queue_text = self.txt_queue.toPlainText().strip()
        if not queue_text:
            QMessageBox.information(self, "Coda vuota", "Aggiungere prima dei job alla coda.")
            return
        script = "/tmp/automen_queue.sh"
        with open(script, "w") as f:
            f.write("#!/bin/bash\nset -e\n")
            f.write(queue_text + "\n")
        os.chmod(script, 0o755)
        subprocess.Popen(["xterm", "-e", script])
        self.txt_queue.clear()
        self.status.showMessage("Coda avviata in xterm.")

    def _browse_subtitle(self):
        path, _ = QFileDialog.getOpenFileName(
            self, "Seleziona sottotitolo", "",
            "Sottotitoli (*.srt *.sub *.ssa *.ass *.idx);;Tutti (*.*)"
        )
        if path:
            self.combo_subs.addItem(path)
            self.combo_subs.setCurrentText(path)

    def _make_report(self):
        s = self._collect_state()
        report = [
            f"[CODE]AutoMen {VERSION} report",
            "",
            f"Input: {s['input_file']}",
            f"Output: {s['output_file']}",
            "",
            f"Codec sorgente: {self.media_info.video_codec}",
            f"Risoluzione src: {s['src_width']}x{s['src_height']}",
            f"FPS: {s['framerate']}  Frame: {s['framecount']}",
            f"AR: {s['ar']}",
            "",
            f"Risoluzione output: {s['out_width']}x{s['out_height']}",
            f"Crop: L={s['crop_left']} R={s['crop_right']} T={s['crop_top']} B={s['crop_bottom']}",
            "",
            f"Encoder: {s['encoder']}",
            f"Codec video: {s['video_codec']}  Container: {s['container']}",
            f"Modalità: {s['pass_mode']}",
            f"Bitrate: {s['video_bitrate']} kbit/s",
            f"Preset idx: {s['preset_idx']}",
            f"Deinterlacciamento: {s['deint']}",
            f"Denoise: {s['denoise']}",
            "",
            f"Codec audio: {s['audio_codec']}",
            f"Bitrate audio: {s['audio_bitrate']}",
            f"Canali: {s['audio_channels']}",
            "",
            "Coda:",
            self.txt_queue.toPlainText(),
            "[/CODE]"
        ]
        report_path = "/tmp/automen_report.txt"
        with open(report_path, "w") as f:
            f.write("\n".join(report))
        QMessageBox.information(self, "Report", f"Report salvato in:\n{report_path}")
        subprocess.Popen(["xdg-open", report_path])


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    app = QApplication(sys.argv)
    app.setApplicationName("AutoMen")
    app.setApplicationVersion(VERSION)

    # Font monospace per leggibilità
    font = QFont()
    font.setFamily("DejaVu Sans Condensed")
    font.setPointSize(9)
    app.setFont(font)

    win = AutoMenWindow()
    win.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()

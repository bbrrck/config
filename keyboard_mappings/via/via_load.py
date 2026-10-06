# /// script
# requires-python = ">=3.12"
# dependencies = ["hidapi"]
# ///
"""Load a VIA layout JSON onto the keyboard over raw HID, without the VIA app.

Usage:
    uv run via_load.py [layout.json] [--dry-run]

Writes the keymap and encoder bindings straight to the board's EEPROM using the
VIA protocol, then reads them back to verify. Macros are not written.

Keycodes use the QMK >= 0.19 numbering (TO(n) = 0x52xx, RGB_* = 0x78xx), which is
what the DOIO KB16-01 firmware reports, even though it speaks VIA protocol 11.
"""

import argparse
import json
import re
import sys
from pathlib import Path

VIA_USAGE_PAGE = 0xFF60
VIA_USAGE = 0x61
REPORT_SIZE = 32
CHUNK = 28  # max payload bytes per buffer command

CMD_PROTOCOL_VERSION = 0x01
CMD_LAYER_COUNT = 0x11
CMD_GET_BUFFER = 0x12
CMD_SET_BUFFER = 0x13
CMD_GET_ENCODER = 0x14
CMD_SET_ENCODER = 0x15


def _basic_keycodes() -> dict[str, int]:
    codes = {"KC_NO": 0x00, "KC_TRNS": 0x01}
    for i, c in enumerate("ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
        codes[f"KC_{c}"] = 0x04 + i
    for i, c in enumerate("1234567890"):
        codes[f"KC_{c}"] = 0x1E + i
    for i in range(12):
        codes[f"KC_F{i + 1}"] = 0x3A + i
        codes[f"KC_F{i + 13}"] = 0x68 + i
    named = [
        (0x28, "ENT"), (0x29, "ESC"), (0x2A, "BSPC"), (0x2B, "TAB"), (0x2C, "SPC"),
        (0x2D, "MINS"), (0x2E, "EQL"), (0x2F, "LBRC"), (0x30, "RBRC"), (0x31, "BSLS"),
        (0x32, "NUHS"), (0x33, "SCLN"), (0x34, "QUOT"), (0x35, "GRV"), (0x36, "COMM"),
        (0x37, "DOT"), (0x38, "SLSH"), (0x39, "CAPS"), (0x46, "PSCR"), (0x47, "SCRL"),
        (0x48, "PAUS"), (0x49, "INS"), (0x4A, "HOME"), (0x4B, "PGUP"), (0x4C, "DEL"),
        (0x4D, "END"), (0x4E, "PGDN"), (0x4F, "RGHT"), (0x50, "LEFT"), (0x51, "DOWN"),
        (0x52, "UP"), (0xA8, "MUTE"), (0xA9, "VOLU"), (0xAA, "VOLD"), (0xAB, "MNXT"),
        (0xAC, "MPRV"), (0xAD, "MSTP"), (0xAE, "MPLY"), (0xE0, "LCTL"), (0xE1, "LSFT"),
        (0xE2, "LALT"), (0xE3, "LGUI"), (0xE4, "RCTL"), (0xE5, "RSFT"), (0xE6, "RALT"),
        (0xE7, "RGUI"),
    ]  # fmt: skip
    for code, name in named:
        codes[f"KC_{name}"] = code
    rgb = ["TOG", "MOD", "RMOD", "HUI", "HUD", "SAI", "SAD", "VAI", "VAD", "SPI", "SPD"]
    for i, name in enumerate(rgb):
        codes[f"RGB_{name}"] = 0x7820 + i
    return codes


KEYCODES = _basic_keycodes()
KEYNAMES = {v: k for k, v in KEYCODES.items()}

# Modifier wrappers, e.g. C(S(G(KC_LEFT))) or LCAG(KC_1).
MODS = {
    "C": 0x100, "LCTL": 0x100, "S": 0x200, "LSFT": 0x200,
    "A": 0x400, "LALT": 0x400, "LOPT": 0x400, "G": 0x800, "LGUI": 0x800, "LCMD": 0x800,
    "LCS": 0x300, "LCA": 0x500, "LSA": 0x600, "MEH": 0x700, "LCG": 0x900,
    "LSG": 0xA00, "SGUI": 0xA00, "LAG": 0xC00, "LCAG": 0xD00, "HYPR": 0xF00,
}  # fmt: skip
SHORT_MODS = [(0x100, "C"), (0x200, "S"), (0x400, "A"), (0x800, "G")]

# Layer functions, e.g. TO(3).
LAYER_FNS = {
    "TO": 0x5200,
    "MO": 0x5220,
    "DF": 0x5240,
    "TG": 0x5260,
    "OSL": 0x5280,
    "TT": 0x52C0,
}

CALL = re.compile(r"^([A-Z_]+)\((.*)\)$")


def parse_keycode(name: str) -> int:
    """Turn a VIA keycode string like 'LCAG(KC_1)' into its 16-bit value."""
    name = name.strip()
    if name.lower().startswith("0x"):
        return int(name, 16)
    if name in KEYCODES:
        return KEYCODES[name]
    if m := CALL.match(name):
        fn, arg = m.groups()
        if fn in MODS:
            # Nested wrappers like C(S(KC_X)) OR their mods onto the basic key.
            inner = parse_keycode(arg)
            if inner > 0x1FFF:
                raise ValueError(f"cannot apply modifiers to {arg!r}")
            return MODS[fn] | inner
        if fn in LAYER_FNS:
            return LAYER_FNS[fn] | int(arg)
    raise ValueError(f"unknown keycode {name!r}")


def format_keycode(code: int) -> str:
    """Best-effort reverse of parse_keycode, for diffs."""
    if code in KEYNAMES:
        return KEYNAMES[code]
    for fn, base in LAYER_FNS.items():
        if base <= code < base + 0x20:
            return f"{fn}({code - base})"
    if 0x100 <= code < 0x1000 and (code & 0xFF) in KEYNAMES:
        out = KEYNAMES[code & 0xFF]
        for bit, short in reversed(SHORT_MODS):
            if code & bit:
                out = f"{short}({out})"
        return out
    return f"0x{code:04X}"


class Via:
    def __init__(self, vendor_product_id: int):
        import hid  # ty: ignore[unresolved-import]  # compiled, untyped; tests run without it

        vid, pid = vendor_product_id >> 16, vendor_product_id & 0xFFFF
        paths = [
            d["path"]
            for d in hid.enumerate(vid, pid)
            if d["usage_page"] == VIA_USAGE_PAGE and d["usage"] == VIA_USAGE
        ]
        if not paths:
            sys.exit(f"Keyboard {vid:04X}:{pid:04X} not found. Is it plugged in?")
        self.dev = hid.device()
        self.dev.open_path(paths[0])

    def cmd(self, *payload: int) -> list[int]:
        self.dev.write([0, *payload] + [0] * (REPORT_SIZE - len(payload)))
        resp = self.dev.read(REPORT_SIZE, 1000)
        if not resp or resp[0] != payload[0]:
            sys.exit(f"Bad response to command 0x{payload[0]:02X}: {resp}")
        return resp

    def protocol_version(self) -> int:
        r = self.cmd(CMD_PROTOCOL_VERSION)
        return r[1] << 8 | r[2]

    def layer_count(self) -> int:
        return self.cmd(CMD_LAYER_COUNT)[1]

    def read_keymap(self, count: int) -> list[int]:
        size = count * 2
        data: list[int] = []
        for off in range(0, size, CHUNK):
            n = min(CHUNK, size - off)
            data += self.cmd(CMD_GET_BUFFER, off >> 8, off & 0xFF, n)[4 : 4 + n]
        return [data[i] << 8 | data[i + 1] for i in range(0, size, 2)]

    def write_keymap(self, codes: list[int]) -> None:
        data = [b for c in codes for b in (c >> 8, c & 0xFF)]
        for off in range(0, len(data), CHUNK):
            chunk = data[off : off + CHUNK]
            self.cmd(CMD_SET_BUFFER, off >> 8, off & 0xFF, len(chunk), *chunk)

    def read_encoder(self, layer: int, encoder: int, clockwise: int) -> int:
        r = self.cmd(CMD_GET_ENCODER, layer, encoder, clockwise)
        return r[4] << 8 | r[5]

    def write_encoder(
        self, layer: int, encoder: int, clockwise: int, code: int
    ) -> None:
        self.cmd(CMD_SET_ENCODER, layer, encoder, clockwise, code >> 8, code & 0xFF)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Load a VIA layout JSON onto the keyboard."
    )
    default = Path(__file__).with_name("kb16_01.layout.json")
    parser.add_argument("layout", nargs="?", type=Path, default=default)
    parser.add_argument(
        "--dry-run", action="store_true", help="show changes, write nothing"
    )
    args = parser.parse_args()

    layout = json.loads(args.layout.read_text())
    keymap = [parse_keycode(k) for layer in layout["layers"] for k in layer]
    # VIA saves encoders as [encoder][layer] -> [counter-clockwise, clockwise].
    encoders = {
        (layer, enc, cw): parse_keycode(pair[cw])
        for enc, per_layer in enumerate(layout.get("encoders", []))
        for layer, pair in enumerate(per_layer)
        for cw in (0, 1)
    }
    if any(layout.get("macros", [])):
        print("Warning: layout has macros; this script does not write them.")

    via = Via(layout["vendorProductId"])
    layers = via.layer_count()
    if layers != len(layout["layers"]):
        sys.exit(f"Board has {layers} layers, layout has {len(layout['layers'])}.")
    print(f"{layout['name']}: VIA protocol {via.protocol_version()}, {layers} layers")

    keys_per_layer = len(layout["layers"][0])
    current = via.read_keymap(len(keymap))
    changes = [
        f"  layer {i // keys_per_layer} key {i % keys_per_layer:>2}: "
        f"{format_keycode(old)} -> {format_keycode(new)}"
        for i, (old, new) in enumerate(zip(current, keymap))
        if old != new
    ]
    current_enc = {k: via.read_encoder(*k) for k in encoders}
    changes += [
        f"  layer {layer} encoder {enc} {'cw ' if cw else 'ccw'}: "
        f"{format_keycode(current_enc[layer, enc, cw])} -> {format_keycode(new)}"
        for (layer, enc, cw), new in encoders.items()
        if current_enc[layer, enc, cw] != new
    ]

    if not changes:
        print("Board already matches the layout.")
        return
    print(f"{len(changes)} change(s):", *changes, sep="\n")
    if args.dry_run:
        return

    via.write_keymap(keymap)
    for (layer, enc, cw), code in encoders.items():
        via.write_encoder(layer, enc, cw, code)

    if via.read_keymap(len(keymap)) != keymap or any(
        via.read_encoder(*k) != code for k, code in encoders.items()
    ):
        sys.exit("Verify failed: board does not match the layout after writing.")
    print("Written and verified.")


if __name__ == "__main__":
    main()

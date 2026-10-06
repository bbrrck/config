import pytest

from via_load import format_keycode, parse_keycode


# Expected values were read from the KB16-01 after loading the layout in the VIA app.
@pytest.mark.parametrize(
    ("name", "code"),
    [
        ("KC_NO", 0x0000),
        ("KC_TRNS", 0x0001),
        ("KC_ESC", 0x0029),
        ("KC_F20", 0x006F),
        ("KC_VOLD", 0x00AA),
        ("LCAG(KC_LEFT)", 0x0D50),
        ("C(G(KC_LEFT))", 0x0950),
        ("LAG(KC_F)", 0x0C09),
        ("C(S(G(KC_4)))", 0x0B21),
        ("S(A(G(KC_V)))", 0x0E19),
        ("G(S(KC_F))", 0x0A09),
        ("S(KC_SLSH)", 0x0238),
        ("TO(3)", 0x5203),
        ("RGB_TOG", 0x7820),
        ("RGB_SPD", 0x782A),
        ("0x7E00", 0x7E00),
    ],
)
def test_parse_keycode(name: str, code: int) -> None:
    assert parse_keycode(name) == code


def test_unknown_keycode() -> None:
    with pytest.raises(ValueError, match="unknown keycode"):
        parse_keycode("KC_BOGUS")


@pytest.mark.parametrize(
    "name", ["KC_ESC", "C(S(G(KC_4)))", "TO(2)", "RGB_HUI", "0x7E00"]
)
def test_format_roundtrip(name: str) -> None:
    assert format_keycode(parse_keycode(name)) == name

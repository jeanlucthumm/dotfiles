# Kitty watcher: keep a wide window's text column readable.
#
# When a tab shows a single window and that window is wider than MAX_COLS
# columns, this pads it left and right so it shows exactly MAX_COLS columns,
# centered. When the window is narrower, the configured default padding is
# restored. Tabs with several windows are left alone, except that a window
# which stops being alone in its tab gets its padding reset to default.
#
# Manual overrides (cmd+i / cmd+o run `set-spacing`) still work. A padding
# change alters the column count, which fires on_resize, but it does not alter
# the total width kitty allots to the window. This watcher only re-decides when
# that allotted width (or the cell width, i.e. font size) changes, so a manual
# choice sticks until the next real resize.
#
# Padding is applied from a zero-delay timer instead of inside on_resize:
# on_resize runs in the middle of a layout pass, and re-laying out from there
# leaves the outer pass with stale geometry.
from typing import Any

from kitty.boss import Boss
from kitty.fast_data_types import add_timer, cell_size_for_window, get_options, pt_to_px
from kitty.window import Window

MAX_COLS = 120

# window id -> (allotted width px, cell width px) at the last decision.
# Presence also means "this window was last seen alone in its tab".
_seen: dict[int, tuple[int, int]] = {}
# window id -> padding (pt, or None for default) waiting to be applied.
_pending: dict[int, float | None] = {}


def _allotted_width(g: Any) -> int:
    return (g.right - g.left) + g.spaces.left + g.spaces.right


def _desired_padding_pt(window: Window, allotted_px: int, cell_w: int) -> float | None:
    """Left/right padding in pt, or None to use the configured default."""
    osw = window.os_window_id
    default = get_options().window_padding_width
    default_px = pt_to_px(default.left, osw) + pt_to_px(default.right, osw)
    if (allotted_px - default_px) // cell_w <= MAX_COLS:
        return None
    pad_px = (allotted_px - MAX_COLS * cell_w) / 2
    px_per_pt = pt_to_px(1000, osw) / 1000
    return round(pad_px / px_per_pt, 1)


def _apply(boss: Boss, window_id: int) -> None:
    if window_id not in _pending:
        return
    pad = _pending.pop(window_id)
    window = boss.window_id_map.get(window_id)
    if window is None or window.destroyed:
        return
    cur = window.padding
    if pad is None:
        unchanged = cur.left is None and cur.right is None
    else:
        unchanged = (
            cur.left is not None and cur.right is not None
            and abs(cur.left - pad) < 0.5 and abs(cur.right - pad) < 0.5
        )
    if unchanged:
        return
    val = 'default' if pad is None else str(pad)
    boss.call_remote_control(
        window, ('set-spacing', f'--match=id:{window_id}', f'padding-left={val}', f'padding-right={val}'))


def _schedule(boss: Boss, window_id: int, pad: float | None) -> None:
    first = window_id not in _pending
    _pending[window_id] = pad
    if first:
        add_timer(lambda timer_id: _apply(boss, window_id), 0, False)


def on_resize(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    tab = window.tabref()
    if tab is None:
        return
    if not tab.has_single_window_visible():
        if _seen.pop(window.id, None) is not None:
            _schedule(boss, window.id, None)
        return
    cell_w, _ = cell_size_for_window(window.os_window_id)
    if cell_w <= 0:
        return
    key = (_allotted_width(data['new_geometry']), cell_w)
    if _seen.get(window.id) == key:
        return
    _seen[window.id] = key
    _schedule(boss, window.id, _desired_padding_pt(window, key[0], cell_w))


def on_close(boss: Boss, window: Window, data: dict[str, Any]) -> None:
    _seen.pop(window.id, None)
    _pending.pop(window.id, None)

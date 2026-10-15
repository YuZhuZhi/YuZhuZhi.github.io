#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
限定范围的经典游走 —— 精确解、蒙特卡洛与可视化
================================================================================

地图与角色配置**照抄**你之前写的 Code/gridGameOptimized.py 里的 demoMap / demoConfig，
不是另设的。模型则严格按题目：

    * 每回合内角色按固定顺序 1,2,...,7 依次行动（"行动顺序固定"）；
    * 某角色移动后若与另一名存活角色同格，立即遭遇：回合锁定、其余角色不动，
      两人各以 1/2 被淘汰，然后**本回合继续**往下走（"方可继续回合"）；
    * 角色处于边界时，把剩余可通行方向的概率重新归一化。

最后一条是这次新增的规则，它取代了此前"撞墙即原地不动"的约定：
合法方向 = 目标格在地图内且该方向权重为正；在合法方向上按权重归一化。
权重为 1 时，角上 3 个合法动作各 1/3，边上 4 个各 1/4，内部 5 个各 1/5。

五个类：

    GridMap     地图（解析带角色标签的地图文本）
    Walker      角色（权重、逐格合法方向、转移矩阵、占用与首达）
    Game        精确递推（顺序行动 + 遭遇决斗），带状态数上限保护
    MonteCarlo  蒙特卡洛（200 格 / 7 人时唯一可行的方法）
    Visualizer  可视化

概率图默认用**分段色标**（见 PROB_BANDS / prob_cmap_norm）：$N = 200$ 格时单格概率
本来就在 $1 slash N$ 量级，线性色标会把全部结构压成一片近白；分段之后低概率区反而
占据更多颜色档位，colorbar 上也直接标出断点数值。加 --linear-prob-color 可退回线性。

用法:
    python code/classical-walk.py
    python code/classical-walk.py --trials 400000 --no-gif
"""

from __future__ import annotations

import argparse
import json
import math
import string
import time
from collections import defaultdict
from pathlib import Path

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import font_manager
from PIL import Image

HERE = Path(__file__).resolve().parent
NOTE_DIR = HERE.parent
IMG_DIR = NOTE_DIR / "img"
IMG_DIR.mkdir(parents=True, exist_ok=True)

# ===========================================================================
# 本文使用的地图与配置（与 Code/gridGameOptimized.py 的 demoMap / demoConfig 逐字一致）
# ===========================================================================

MAP_TEXT = """......6........
1..............
...............
...............
.........5.....
.....#####.....
.....#####.....
.....#####.....
2....#####....7
.....#####.....
.....4.........
...............
...............
...............
.....3........."""

TURN_ORDER = ("1", "2", "3", "4", "5", "6", "7")
DEFAULT_MOVE_WEIGHTS = {"up": 1.0, "down": 1.0, "left": 1.0, "right": 1.0, "stay": 1.0}
DEFAULT_WIN_PROB = 0.5

# 只用于校核的小地图（4 人 / 32 格），使精确递推与蒙特卡洛可以互相印证
TEST_MAP_TEXT = """1....2
......
..##..
..##..
......
3....4"""
TEST_TURN_ORDER = ("1", "2", "3", "4")

# ===========================================================================
# 字体与配色（蓝绿色系）
# ===========================================================================

CJK_CANDIDATES = ("Microsoft YaHei", "SimHei", "Noto Sans CJK SC",
                  "Source Han Sans SC", "WenQuanYi Zen Hei", "PingFang SC")


def _pick_cjk_font() -> str | None:
    names = {f.name for f in font_manager.fontManager.ttflist}
    for candidate in CJK_CANDIDATES:
        if candidate in names:
            return candidate
    return None


CJK = _pick_cjk_font()
if CJK is not None:
    plt.rcParams["font.sans-serif"] = [CJK, "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["figure.dpi"] = 100
plt.rcParams["savefig.dpi"] = 150
plt.rcParams["font.size"] = 10


def L(zh: str, en: str) -> str:
    return zh if CJK is not None else en


WALL = "#C3D6DC"     # 障碍格
INK = "#16383D"      # 主文字
MUTED = "#5E7A80"    # 次要文字
C_START = "#0B4F4A"  # 出发点标记

PALETTE = (
    "#0B5D57",  # 深青绿
    "#0E93A8",  # 青蓝
    "#25C6DE",  # 亮青
    "#0E7490",  # 深青
    "#5FCFC0",  # 薄荷青
    "#8ED9E8",  # 浅青
    "#1FA396",  # 青绿
)
C1, C2, C3, C4, C5, C6, C7 = PALETTE


def _ramp(name: str, colors: list[str]):
    return matplotlib.colors.LinearSegmentedColormap.from_list(name, colors)


RAMP_PROB = _ramp("fresh-prob", ["#FBFEFF", "#DAF2F7", "#A8E4EF", "#6BD0E2", "#2FB2CB", "#0E8AA5"])
RAMP_MEAN = _ramp("fresh-mean", ["#F4FCFA", "#C9EFE8", "#93DFD1", "#55C4B4", "#1FA396"])
RAMP_STD = _ramp("fresh-std", ["#F5FBFF", "#D3EDF7", "#A3DAEE", "#66C0E0", "#2A9FC4"])

# ---------------------------------------------------------------------------
# 概率图的**分段色标**
#
# 为什么不能线性：$N = 200$ 格时，单个格子分到的概率本来就在 $1 slash N = 0.005$
# 量级；而色标上限是 $1$（第 0 回合那一格是 $1.0$）。线性色标于是把"概率已经
# 散开、但格与格之间有结构"的那一段全部压在接近白色的一小块里，画出来几乎一片空白。
#
# 这里改成按 vmax 的相对比例给出的**分段**断点：$0.005 v_"max"$ 以下占了 $14$ 档里的
# $5$ 档，$0.013 v_"max"$ 以下占了 $7$ 档，也就是说概率很小时颜色跨度反而更大。
# 用 BoundaryNorm 而不是连续色标有两个好处：colorbar 直接标出断点数值（非线性是
# 明示的，不会被误读成线性），而且每一档占同样的颜色宽度。
# ---------------------------------------------------------------------------

PROB_BANDS = (
    0.0, 0.0005, 0.001, 0.002, 0.0032, 0.005, 0.008,
    0.013, 0.022, 0.04, 0.08, 0.16, 0.32, 0.6, 1.0,
)


def prob_levels(vmax: float, fracs=PROB_BANDS) -> np.ndarray:
    """概率色标的分段断点（数据尺度）。断点按 vmax 成比例，因此与量级无关。"""
    fracs = np.asarray(fracs, dtype=float)
    return fracs * float(max(vmax, 1e-30))


def prob_cmap_norm(vmax: float):
    """返回 (离散化的蓝绿色 colormap, BoundaryNorm, 断点数组)。"""
    bounds = prob_levels(vmax)
    bands = len(bounds) - 1
    cmap = matplotlib.colors.ListedColormap(
        RAMP_PROB(np.linspace(0.0, 1.0, bands)), name="prob-band")
    cmap.set_bad(WALL)
    norm = matplotlib.colors.BoundaryNorm(bounds, cmap.N)
    return cmap, norm, bounds


def tidy_colorbar(cb, bounds=None) -> None:
    cb.ax.tick_params(colors=MUTED, labelsize=8)
    cb.outline.set_edgecolor("#BFD5DA")
    cb.outline.set_linewidth(0.8)
    cb.ax.yaxis.label.set_color(MUTED)
    if bounds is None or not isinstance(cb.norm, matplotlib.colors.BoundaryNorm):
        return
    # 分段色标有十几个断点，全标出来会挤在一起；隔几档标一个，首尾一定保留。
    # 注意 Colorbar 本身没有 get_ticklabels()，刻度标签挂在自己的坐标轴上。
    locs = list(cb.get_ticks())
    labels = [t.get_text() for t in cb.ax.get_yticklabels()]
    if len(locs) != len(labels) or len(locs) < 10:
        return
    step = max(1, round(len(locs) / 7))
    keep = sorted(set(list(range(0, len(locs), step)) + [len(locs) - 1]))
    cb.set_ticks([locs[i] for i in keep])
    cb.set_ticklabels([labels[i] for i in keep])
    cb.ax.tick_params(labelsize=7)


plt.rcParams.update(
    {
        "figure.facecolor": "white",
        "axes.facecolor": "white",
        "axes.edgecolor": "#BFD5DA",
        "axes.linewidth": 0.9,
        "axes.labelcolor": MUTED,
        "axes.titlecolor": INK,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.prop_cycle": matplotlib.cycler(color=list(PALETTE)),
        "text.color": INK,
        "xtick.color": MUTED,
        "ytick.color": MUTED,
        "xtick.labelsize": 9,
        "ytick.labelsize": 9,
        "grid.color": "#D3E5E9",
        "grid.alpha": 0.5,
        "grid.linewidth": 0.7,
        "legend.frameon": True,
        "legend.framealpha": 0.92,
        "legend.edgecolor": "#DFEDF0",
        "legend.facecolor": "#FFFFFF",
        "legend.fontsize": 8,
    }
)

DIRECTIONS = ("up", "down", "left", "right", "stay")
DELTA = {"up": (-1, 0), "down": (1, 0), "left": (0, -1), "right": (0, 1), "stay": (0, 0)}


# ===========================================================================
# 1. GridMap —— 地图
# ===========================================================================


class GridMap:
    """限定可通行范围的方形网格地图。

    字符约定与 gridGameOptimized.py 一致：`#` 障碍，`.` 空地，
    英文字母/数字是唯一角色标签（同时给出该角色的出发点）。
    """

    def __init__(self, art):
        if isinstance(art, str):
            art = [line for line in art.splitlines() if line.strip()]
        self.art = ["".join(line.split()) for line in art]
        if not self.art or any(len(row) != len(self.art[0]) for row in self.art):
            raise ValueError("地图必须非空且每行格数相同")
        self.rows = len(self.art)
        self.cols = len(self.art[0])

        allowed = set(string.ascii_letters + string.digits)
        self.cells: list[tuple[int, int]] = []
        self.starts: dict[str, int] = {}
        for r, row in enumerate(self.art):
            for c, ch in enumerate(row):
                if ch == "#":
                    continue
                if ch != "." and ch not in allowed:
                    raise ValueError(f"非法地图字符 {ch!r}")
                index = len(self.cells)
                self.cells.append((r, c))
                if ch != ".":
                    if ch in self.starts:
                        raise ValueError(f"角色标签 {ch!r} 重复")
                    self.starts[ch] = index
        self.size = len(self.cells)
        self.index = {cell: i for i, cell in enumerate(self.cells)}

        # step_table[i, k] = 从第 i 格做第 k 个动作后的目标格；越界/撞墙记 -1
        self.step_table = np.full((self.size, len(DIRECTIONS)), -1, dtype=int)
        for i, (r, c) in enumerate(self.cells):
            for k, name in enumerate(DIRECTIONS):
                dr, dc = DELTA[name]
                self.step_table[i, k] = self.index.get((r + dr, c + dc), -1)
        # 供 numpy 索引使用的安全版本（非法动作概率为 0，落到哪一格都无所谓）
        self.step_safe = np.where(self.step_table >= 0, self.step_table, 0)

        self._check_connectivity()

    def _check_connectivity(self) -> None:
        seen = {0}
        stack = [0]
        while stack:
            i = stack.pop()
            for j in self.step_table[i]:
                if j >= 0 and j not in seen:
                    seen.add(int(j))
                    stack.append(int(j))
        self.connected = len(seen) == self.size
        if not self.connected:
            raise ValueError(f"地图不连通：只访问到 {len(seen)}/{self.size} 格")

    def idx(self, r: int, c: int) -> int:
        return self.index[(r, c)]

    def occupancy_grid(self, values=None) -> np.ndarray:
        canvas = np.full((self.rows, self.cols), np.nan)
        if values is not None:
            for i, (r, c) in enumerate(self.cells):
                canvas[r, c] = values[i]
        return canvas

    def describe(self) -> dict:
        return {
            "art": self.art,
            "rows": self.rows,
            "cols": self.cols,
            "size": self.size,
            "starts": {label: list(self.cells[v]) for label, v in self.starts.items()},
        }


# ===========================================================================
# 2. Walker —— 角色
# ===========================================================================


class Walker:
    """一名角色：固定的五方向权重 + 逐格重新归一化的合法动作。

    参数
    ----
    label   : 角色标签（与地图上的字符一致）
    weights : 长度 5 的权重（上, 下, 左, 右, 原地），不要求归一化
    """

    def __init__(self, label: str, weights, grid: GridMap):
        self.label = label
        self.grid = grid
        self.weights = np.asarray(weights, dtype=float)
        if (self.weights < 0).any() or self.weights.sum() <= 0:
            raise ValueError(f"{label} 的方向权重必须非负且不全为零")
        if self.weights[4] <= 0:
            raise ValueError(f"{label} 必须有正的原地权重，否则边界处会没有合法动作")
        self.start = grid.starts[label]
        self.start_cell = grid.cells[self.start]

        # 合法掩码与逐格归一化概率：这就是题目新增的边界规则
        self.legal = (grid.step_table >= 0) & (self.weights > 0)[None, :]
        self.total_weight = (self.legal * self.weights[None, :]).sum(axis=1)   # W(c)
        self.prob = np.where(self.legal, self.weights[None, :], 0.0) / self.total_weight[:, None]
        self.cum = np.cumsum(self.prob, axis=1)

        self.n_legal = self.legal.sum(axis=1).astype(np.intp)
        self.uniform = bool(np.allclose(self.weights, self.weights[0]))
        if self.uniform:
            # 权重全相等时动作在合法集合上均匀分布。必须把合法目标**压缩到前若干列**：
            # 直接按方向顺序取前 d 列是错的——只要有一个非末尾方向被挡住
            # （例如向上的格子是障碍），前 d 列里就会混进一个非法方向。
            order = np.argsort(~self.legal, axis=1, kind="stable")
            self.legal_targets = np.take_along_axis(grid.step_safe, order, axis=1)

    # --- 转移矩阵 ---------------------------------------------------------

    @property
    def Q(self) -> np.ndarray:
        if not hasattr(self, "_Q"):
            Q = np.zeros((self.grid.size, self.grid.size))
            rows = np.arange(self.grid.size)
            for k in range(len(DIRECTIONS)):
                add = np.zeros(self.grid.size)
                add[self.legal[:, k]] = self.prob[self.legal[:, k], k]
                np.add.at(Q, (rows, self.grid.step_safe[:, k]), add)
            self._Q = Q
        return self._Q

    @property
    def symmetric_weights(self) -> bool:
        """上下、左右权重是否分别相等（决定 π ∝ W 是否严格成立）。"""
        return bool(self.weights[0] == self.weights[1] and self.weights[2] == self.weights[3])

    # --- 占用与平稳分布 ---------------------------------------------------

    def occupancy(self, turns: int) -> np.ndarray:
        out = np.empty((turns + 1, self.grid.size))
        p = np.zeros(self.grid.size)
        p[self.start] = 1.0
        out[0] = p
        Q = self.Q
        for t in range(1, turns + 1):
            p = p @ Q
            out[t] = p
        return out

    def stationary_analytic(self) -> np.ndarray:
        """π(c) ∝ W(c)（合法动作权重之和）。上下/左右权重相等时严格成立。"""
        return self.total_weight / self.total_weight.sum()

    def stationary_numeric(self, tol: float = 1e-14, max_iter: int = 200000) -> np.ndarray:
        p = np.full(self.grid.size, 1.0 / self.grid.size)
        Q = self.Q
        for _ in range(max_iter):
            q = p @ Q
            if np.abs(q - p).sum() < tol:
                return q
            p = q
        return p

    # --- 首次到达：基本矩阵（快）与尾和（慢，用作校核） -------------------

    def first_passage_maps(self, max_turns: int = 400000, tol: float = 1e-15) -> dict:
        """所有起点的首达期望与标准差矩阵（N x N），用基本矩阵公式。

            E_i[T_c]  = sum_j N_c[i, j]
            E_i[T_c^2] = sum_j (2 N_c[i, j] - delta_ij) E_j[T_c]

        其中 N_c = (I - Q_{-c})^{-1}，Q_{-c} 是删去第 c 行第 c 列的子矩阵。
        """
        N = self.grid.size
        Q = self.Q
        mean = np.zeros((N, N))
        std = np.zeros((N, N))
        for c in range(N):
            keep = np.array([i for i in range(N) if i != c])
            sub = Q[np.ix_(keep, keep)]
            Nc = np.linalg.inv(np.eye(N - 1) - sub)
            e = Nc.sum(axis=1)                      # E_j[T_c]
            m2 = 2.0 * (Nc @ e) - e                 # E_j[T_c^2]
            mean[keep, c] = e
            std[keep, c] = np.sqrt(np.clip(m2 - e * e, 0.0, None))
        return {"mean": mean, "std": std}

    def first_passage_tailsum(self, target: int, max_turns: int = 400000, tol: float = 1e-15) -> dict:
        """尾和公式的独立实现：p^(0) Q_k^t 的质量和就是 P(T > t)。"""
        N = self.grid.size
        if self.start == target:
            return {"mean": 0.0, "std": 0.0, "steps": 0, "final_mass": 0.0, "pmf": np.array([1.0])}
        Qk = self.Q.copy()
        Qk[target, :] = 0.0
        p = np.zeros(N)
        p[self.start] = 1.0
        tails = [1.0]
        t = 0
        while t < max_turns:
            p = p @ Qk
            p[target] = 0.0
            t += 1
            tails.append(float(p.sum()))
            if tails[-1] < tol:
                break
        tail = np.array(tails)
        ts = np.arange(len(tail))
        mean = float(tail.sum())
        second = float(((2 * ts + 1) * tail).sum())
        pmf = np.concatenate([[0.0], -np.diff(tail)])
        return {"mean": mean, "std": math.sqrt(max(second - mean * mean, 0.0)),
                "steps": t, "final_mass": float(tail[-1]), "pmf": pmf}

    def verify_first_passage(self, maps: dict, n_probe: int = 6, seed: int = 7) -> dict:
        """尾和公式 vs 基本矩阵公式（抽查若干目标格），返回最大偏差与迭代步数。"""
        rng = np.random.default_rng(seed)
        worst = 0.0
        steps = 0
        for target in rng.choice(self.grid.size, size=n_probe, replace=False):
            res = self.first_passage_tailsum(int(target))
            worst = max(worst, abs(res["mean"] - maps["mean"][self.start, target]))
            steps = max(steps, res["steps"])
        return {"max_deviation": float(worst), "max_steps": int(steps)}

    def summary(self) -> dict:
        return {
            "label": self.label,
            "start_cell": list(self.start_cell),
            "start_index": int(self.start),
            "weights": {name: float(w) for name, w in zip(DIRECTIONS, self.weights)},
            "uniform_weights": self.uniform,
            "symmetric_weights": self.symmetric_weights,
            "legal_action_count": [int(v) for v in np.bincount(self.n_legal, minlength=6)],
        }


# ===========================================================================
# 3. Game —— 顺序行动 + 遭遇决斗的精确递推（只用于小规模）
# ===========================================================================


def _contract(Q: np.ndarray, arr: np.ndarray, axis: int) -> np.ndarray:
    """把 Q 作用在 arr 的第 axis 轴上：out[...,c',...] = Σ_c arr[...,c,...] Q[c,c']。"""
    out = np.moveaxis(np.tensordot(Q, arr, axes=([0], [axis])), 0, axis)
    return np.ascontiguousarray(out)


def _axis_index(k: int, axis: int, N: int) -> np.ndarray:
    shape = [1] * k
    shape[axis] = N
    return np.arange(N).reshape(shape)


class Game:
    """按题目顺序模型的精确递推。

    状态 = （存活集合，各存活角色的当前位置）。存活集合始终按**行动顺序**排列，
    张量形状为 (N,)*|S|，第 p 轴对应存活集合中第 p 个角色。

    一回合：依次让 order 中的角色行动（已死的跳过）；角色 i 移动后若与另一名
    存活角色同格，则发生遭遇 —— 分片、决斗（各 1/2 被淘汰）、然后**本回合继续**
    处理 order 中的下一个角色。三人及以上同格不会被同时判定，因为不变量保证
    任何时刻全部存活角色的位置两两不同。
    """

    def __init__(self, grid: GridMap, walkers: list[Walker], max_turns: int = 400,
                 tol: float = 1e-13, max_states: int = 6_000_000):
        self.grid = grid
        self.walkers = walkers
        self.n = len(walkers)
        self.N = grid.size
        if self.N ** self.n > max_states:
            raise ValueError(
                f"精确递推需要 N^n = {self.N}^{self.n} = {self.N ** self.n:.3g} 个状态，"
                f"超过上限 {max_states}；请改用 MonteCarlo。"
            )
        self.max_turns = max_turns
        self.tol = tol
        self.order = tuple(range(self.n))

        T = max_turns + 1
        self.mass_trace = np.zeros(T)
        self.end_pmf = np.zeros(T)
        self.enc_all = np.zeros(T)                 # 第 t 回合发生过遭遇
        self.enc_global = np.zeros(T)              # 整局第一次遭遇
        self.enc_cell = np.zeros((T, self.N))
        self.enc_turn = np.zeros((T, self.n))      # 第 t 回合的决斗涉及角色 i
        self.first_duel = np.zeros((T, self.n))    # 角色 i 的首次遭遇
        self.pos_prob = np.zeros((T, self.n, self.N))
        self.nc_mass = np.zeros(T)                 # 到第 t 回合为止从未遭遇
        self.win_prob = np.zeros(self.n)
        self.residual = 0.0
        self.turns_run = 0
        self.runtime = 0.0

        starts = tuple(w.start for w in walkers)
        if len(set(starts)) != self.n:
            raise ValueError("初始方格必须两两不同")
        self._grids_k = {k: [_axis_index(k, a, self.N) for a in range(k)]
                         for k in range(1, self.n + 1)}
        self._init = np.zeros((self.N,) * self.n)
        self._init[starts] = 1.0

    # --- 工具 -------------------------------------------------------------

    def _split_at(self, arr, alive, axis):
        """把 arr 拆成「第 axis 轴与其它任何轴都不重合」与「第一个重合者是 (i,j)」。"""
        k = len(alive)
        grids = self._grids_k[k]
        mask = np.ones(arr.shape, dtype=bool)
        for other in range(k):
            if other != axis:
                mask &= grids[axis] != grids[other]
        free = np.where(mask, arr, 0.0)
        rest = np.where(mask, 0.0, arr)
        pieces = []
        for other in range(k):
            if other == axis:
                continue
            eq = grids[axis] == grids[other]
            sel = np.where(eq, rest, 0.0)
            rest = np.where(eq, 0.0, rest)
            if sel.any():
                pieces.append((alive[other], sel))
        return free, pieces

    @staticmethod
    def _add(dst, src):
        return src.copy() if dst is None else dst + src

    # --- 单回合内按顺序推进 -----------------------------------------------

    def _advance(self, turn, alive, arr, k, dueled, turn_dueled, nxt):
        if k == len(self.order):
            nxt[alive] = self._add(nxt.get(alive), arr)
            return
        who = self.order[k]
        if who not in alive:
            self._advance(turn, alive, arr, k + 1, dueled, turn_dueled, nxt)
            return

        axis = alive.index(who)
        arr = _contract(self.walkers[who].Q, arr, axis)
        free, pieces = self._split_at(arr, alive, axis)
        if free.any():
            self._advance(turn, alive, free, k + 1, dueled, turn_dueled, nxt)

        for partner, sel in pieces:
            mass = float(sel.sum())
            if mass <= 0.0:
                continue
            if not dueled and alive == self.order:
                self.enc_global[turn] += mass
            if not turn_dueled:
                # 「本回合发生过遭遇」每人每回合只记一次
                self.enc_all[turn] += mass
            self.enc_cell[turn] += sel.sum(axis=tuple(j for j in range(len(alive)) if j != axis))
            for i in (who, partner):
                if i not in dueled:
                    self.enc_turn[turn, i] += mass
            new_dueled = dueled | {who, partner}
            for dead in (who, partner):
                alive2 = tuple(x for x in alive if x != dead)
                new = 0.5 * sel.sum(axis=alive.index(dead))
                if len(alive2) == 1:
                    m = float(new.sum())
                    self.end_pmf[turn] += m
                    self.win_prob[alive2[0]] += m
                    self.pos_prob[turn, alive2[0]] += new
                else:
                    self._advance(turn, alive2, new, k + 1, new_dueled, True, nxt)

    def run(self, verbose: bool = True) -> "Game":
        t0 = time.time()
        dist = {self.order: self._init}
        nc = self._init.copy()
        for turn in range(0, self.max_turns + 1):
            self.turns_run = turn
            if turn > 0:
                nxt: dict[tuple[int, ...], np.ndarray] = {}
                for alive, arr in dist.items():
                    self._advance(turn, alive, arr, 0, frozenset(), False, nxt)
                dist = nxt
                # 「从未遭遇」对照：每一步都只保留无重合的质量
                for p, who in enumerate(self.order):
                    nc = _contract(self.walkers[who].Q, nc, p)
                    grids = self._grids_k[self.n]
                    mask = np.ones(nc.shape, dtype=bool)
                    for q in range(self.n):
                        if q != p:
                            mask &= grids[p] != grids[q]
                    nc = np.where(mask, nc, 0.0)

            self.mass_trace[turn] = sum(float(a.sum()) for a in dist.values())
            self.nc_mass[turn] = float(nc.sum())
            for alive, arr in dist.items():
                for p, i in enumerate(alive):
                    axes = tuple(j for j in range(len(alive)) if j != p)
                    self.pos_prob[turn, i] += arr.sum(axis=axes) if axes else arr
            if verbose:
                print(f"  turn {turn:4d} | 仍在进行 {self.mass_trace[turn]:.6e}"
                      f" | 本回合结束 {self.end_pmf[turn]:.6e}"
                      f" | 从未遭遇 {self.nc_mass[turn]:.6e}", flush=True)
            if turn > 0 and self.mass_trace[turn] < self.tol:
                break

        # 不把截断残差折进 end_pmf：残差是「到 max_turns 还没结束」的质量，
        # 它的归属未知，硬折进某一回合会让 win_prob 与 end_pmf 对不上。
        self.residual = float(self.mass_trace[self.turns_run])
        if self.n == 2:
            # 二人局里第一场决斗必然同时涉及两人，故 T_1^enc = T_2^enc = T_end
            self.first_duel[:, 0] = self.end_pmf[: len(self.first_duel)]
            self.first_duel[:, 1] = self.end_pmf[: len(self.first_duel)]
        keep = self.turns_run + 1
        for name in ("mass_trace", "end_pmf", "enc_all", "enc_global", "nc_mass"):
            setattr(self, name, getattr(self, name)[:keep])
        self.enc_cell = self.enc_cell[:keep]
        self.enc_turn = self.enc_turn[:keep]
        self.pos_prob = self.pos_prob[:keep]
        self.runtime = time.time() - t0
        return self

    def solve_first_duels(self, verbose: bool = False) -> "Game":
        """对每名角色各跑一次「保护」递推：一旦涉及该角色的决斗发生就收集并丢弃。"""
        for who in self.order:
            g = self._first_duel_dis(who)
            self.first_duel[: len(g), who] = g
            if verbose:
                print(f"   - {who}: 首次遭遇分布质量 {g.sum():.6f}"
                      f"，最终获胜 {self.win_prob[who]:.6f}", flush=True)
        return self

    def _first_duel_dis(self, who: int) -> np.ndarray:
        T = self.max_turns + 1
        g = np.zeros(T)
        dist = {self.order: self._init}

        def advance(turn, alive, arr, k, nxt):
            if k == len(self.order):
                nxt[alive] = self._add(nxt.get(alive), arr)
                return
            i = self.order[k]
            if i not in alive:
                advance(turn, alive, arr, k + 1, nxt)
                return
            axis = alive.index(i)
            arr2 = _contract(self.walkers[i].Q, arr, axis)
            free, pieces = self._split_at(arr2, alive, axis)
            if free.any():
                advance(turn, alive, free, k + 1, nxt)
            for partner, sel in pieces:
                if who in (i, partner):
                    g[turn] += float(sel.sum())
                    continue
                for dead in (i, partner):
                    alive2 = tuple(x for x in alive if x != dead)
                    new = 0.5 * sel.sum(axis=alive.index(dead))
                    if len(alive2) > 1:
                        advance(turn, alive2, new, k + 1, nxt)

        for turn in range(1, T):
            nxt: dict[tuple[int, ...], np.ndarray] = {}
            for alive, arr in dist.items():
                advance(turn, alive, arr, 0, nxt)
            dist = nxt
            if not dist or sum(float(a.sum()) for a in dist.values()) < self.tol:
                return g[: turn + 1]
        return g

    # --- 派生量与校核 -----------------------------------------------------

    def end_stats(self) -> dict:
        pmf = self.end_pmf
        ts = np.arange(len(pmf))
        mean = float((ts * pmf).sum())
        surv = 1.0 - np.cumsum(pmf)
        return {
            "pmf": pmf.tolist(),
            "mean": mean,
            "std": math.sqrt(max(float((ts ** 2 * pmf).sum()) - mean ** 2, 0.0)),
            "mean_tailsum": float(surv.sum()),
            "median": int(np.searchsorted(np.cumsum(pmf), 0.5)),
            "p95": int(np.searchsorted(np.cumsum(pmf), 0.95)),
            "mode": int(np.argmax(pmf)),
        }

    def encounter_stats(self) -> dict:
        out = {}
        for i in range(self.n):
            pmf = self.first_duel[:, i]
            total = float(pmf.sum())
            ts = np.arange(len(pmf))
            mean = float((ts * pmf).sum() / total) if total > 0 else float("nan")
            var = float((ts ** 2 * pmf).sum() / total - mean ** 2) if total > 0 else float("nan")
            out[self.walkers[i].label] = {
                "pmf": pmf.tolist(),
                "total": total,
                "mean": mean,
                "std": math.sqrt(max(var, 0.0)),
                "win": float(self.win_prob[i]),
            }
        return out

    def self_check(self) -> dict:
        checks = {}
        checks["C1_end_mass"] = abs(self.end_pmf.sum() + self.residual - 1.0)
        surv = 1.0 - np.cumsum(self.end_pmf)
        checks["C2_survival"] = float(np.max(np.abs(surv - self.mass_trace)))
        dec = -np.diff(self.nc_mass, prepend=self.nc_mass[0])
        dec[0] = 0.0
        checks["C3_global_encounter"] = float(np.max(np.abs(dec - self.enc_global)))
        for i in range(self.n):
            checks[f"C4_char_{self.walkers[i].label}"] = abs(
                self.first_duel[:, i].sum() + self.residual - 1.0)
        checks["C4b_win_sum"] = abs(self.win_prob.sum() + self.residual - 1.0)
        checks["C5_nc_le_running"] = float(np.max(np.clip(self.nc_mass - self.mass_trace, 0, None)))
        checks["C6_occupancy_le_1"] = float(np.max(np.clip(self.pos_prob.sum(axis=2) - 1.0, 0, None)))
        return {k: round(float(v), 15) for k, v in checks.items()}

    def verify_first_passage(self, walker: "Walker", n_probe: int = 6) -> float:
        """兼容旧调用：直接用 walker 自己的两种算法对照。"""
        maps = walker.first_passage_maps()
        return walker.verify_first_passage(maps, n_probe)["max_deviation"]


# ===========================================================================
# 4. MonteCarlo —— 顺序模型的大规模采样
# ===========================================================================


class MonteCarlo:
    """向量化的整局采样：向量的每一行是一局。

    顺序模型下每回合只需按行动顺序依次处理每个存活角色：移动 -> 找被撞者 ->
    决斗。不变量保证任何时刻存活角色两两不同格，因此每个角色每回合至多触发
    一次决斗。
    """

    def __init__(self, grid: GridMap, walkers: list[Walker], trials: int = 1000000,
                 max_turns: int = 3000, seed: int = 20261013, record_turns: int = 40):
        self.grid = grid
        self.walkers = walkers
        self.n = len(walkers)
        self.N = grid.size
        self.trials = trials
        self.max_turns = max_turns
        self.seed = seed
        self.record_turns = record_turns

    def _sample(self, rng, walker: Walker, cells: np.ndarray, T: int) -> np.ndarray:
        if walker.uniform:
            d = walker.n_legal[cells]
            k = (rng.random(T) * d).astype(np.intp)
            return walker.legal_targets[cells, k]
        cu = walker.cum[cells]
        k = (rng.random(T)[:, None] >= cu).sum(axis=1)
        return walker.grid.step_safe[cells, k]

    def run(self, verbose: bool = True) -> dict:
        rng = np.random.default_rng(self.seed)
        n, N, R = self.n, self.N, self.record_turns
        T = self.trials

        pos = np.tile(np.array([w.start for w in self.walkers]), (T, 1)).astype(np.int32)
        alive = np.ones((T, n), dtype=bool)
        duel_seen = np.zeros((T, n), dtype=bool)
        game_dueled = np.zeros(T, dtype=bool)

        end_counts = np.zeros(self.max_turns + 1)
        duel_hist = np.zeros((self.max_turns + 1, n))
        duel_sum = np.zeros(n)
        duel_sumsq = np.zeros(n)
        duel_cnt = np.zeros(n, dtype=np.int64)
        win_counts = np.zeros(n, dtype=np.int64)
        occ = np.zeros((R, n, N))
        for i in range(n):
            # 第 0 行就是第 0 回合（尚未移动）：确定性地站在出发点。
            # 这里记的是**计数**（最后统一除以 T），所以填 T 而不是 1。
            occ[0, i, self.walkers[i].start] = T
        enc_cell = np.zeros((R, N))
        enc_first = np.zeros(R)
        enc_any = np.zeros(R)

        turn = 0
        while turn < self.max_turns and pos.shape[0] > 0:
            turn += 1
            m = pos.shape[0]
            turn_dueled = np.zeros(m, dtype=bool)
            for a in range(n):
                act = alive[:, a]
                if not act.any():
                    continue
                moved = self._sample(rng, self.walkers[a], pos[:, a], m)
                pos[:, a] = np.where(act, moved, pos[:, a])
                for b in range(n):
                    if b == a:
                        continue
                    hit = act & alive[:, b] & (pos[:, b] == pos[:, a])
                    if not hit.any():
                        continue
                    turn_dueled |= hit
                    first = hit & ~game_dueled
                    if first.any():
                        game_dueled |= first
                        if turn < R:
                            enc_cell[turn] += np.bincount(pos[first, a], minlength=N)
                            enc_first[turn] += float(first.sum())
                    game_dueled |= hit
                    for i in (a, b):
                        fresh = hit & ~duel_seen[:, i]
                        if fresh.any():
                            cnt = float(fresh.sum())
                            duel_seen[fresh, i] = True
                            duel_hist[turn, i] += cnt
                            duel_sum[i] += turn * cnt
                            duel_sumsq[i] += (turn ** 2) * cnt
                            duel_cnt[i] += int(fresh.sum())
                    coin = rng.random(m) < 0.5
                    alive[hit & coin, a] = False
                    alive[hit & ~coin, b] = False
            if turn < R:
                for i in range(n):
                    sel = alive[:, i]
                    if sel.any():
                        occ[turn, i] += np.bincount(pos[sel, i], minlength=N)
                enc_any[turn] += float(turn_dueled.sum())

            # 已经分出唯一幸存者的试验直接移出数组，后续回合不再陪着它们算
            over = alive.sum(axis=1) == 1
            if over.any():
                end_counts[turn] += float(over.sum())
                # 唯一存活者就是胜者：注意它与「谁从未遭遇」完全不同 ——
                # 胜者是最后一场决斗的幸存者，所以它一定遭遇过。
                win_counts += np.bincount(np.argmax(alive[over], axis=1), minlength=n)
                keep = ~over
                pos = pos[keep]
                alive = alive[keep]
                duel_seen = duel_seen[keep]
                game_dueled = game_dueled[keep]

        unfinished = int(pos.shape[0])
        end_pmf = end_counts / T
        duel_pmf = duel_hist / T
        stats = {}
        for i in range(n):
            cnt = int(duel_cnt[i])
            mean = duel_sum[i] / cnt if cnt else float("nan")
            var = duel_sumsq[i] / cnt - mean ** 2 if cnt else float("nan")
            stats[self.walkers[i].label] = {
                "pmf": duel_pmf[:, i],
                "total": cnt / T,
                "wilson": self._wilson(cnt, T),
                "mean": mean,
                "std": math.sqrt(max(var, 0.0)),
                "se_mean": math.sqrt(max(var, 0.0)) / math.sqrt(max(cnt, 1)),
                "win": float(win_counts[i] / T),
                "win_wilson": self._wilson(int(win_counts[i]), T),
            }
        ts = np.arange(len(end_pmf))
        done = end_pmf.sum()
        mean_end = float((ts * end_pmf).sum() / done) if done > 0 else float("nan")
        var_end = float((ts ** 2 * end_pmf).sum() / done) - mean_end ** 2 if done > 0 else float("nan")
        result = {
            "trials": T,
            "seed": self.seed,
            "unfinished": unfinished,
            "record_turns": R,
            "end_pmf": end_pmf,
            "end_mean": mean_end,
            "end_std": math.sqrt(max(var_end, 0.0)),
            "end_se_mean": math.sqrt(max(var_end, 0.0)) / math.sqrt(max(int(end_counts.sum()), 1)),
            "duel": stats,
            "occ": occ / T,
            "enc_cell": enc_cell / T,
            "enc_first": enc_first / T,
            "enc_any": enc_any / T,
        }
        if verbose:
            print(f"  蒙特卡洛：{T} 局，未在 {self.max_turns} 回合内结束 {unfinished} 局；"
                  f"结束时均 {mean_end:.3f} ± {result['end_se_mean']:.3f}", flush=True)
        return result

    @staticmethod
    def _wilson(k: int, m: int, z: float = 1.959963985) -> tuple[float, float]:
        """二项比例的 Wilson 95% 置信区间。"""
        if m == 0:
            return (0.0, 1.0)
        p = k / m
        d = 1 + z * z / m
        centre = (p + z * z / (2 * m)) / d
        half = z * math.sqrt(p * (1 - p) / m + z * z / (4 * m * m)) / d
        return (max(centre - half, 0.0), min(centre + half, 1.0))


def permanent_dp(rows: np.ndarray) -> float:
    """矩阵的积和式 per(A) = Σ_{单射 φ} Π_i A[i, φ(i)]，用逐格子集 DP 精确计算。

    矩形矩阵的积和式也可由容斥展开，但交错求和可能放大浮点误差。
    这里采用只累加非负项的逐格递推：
    按格子从左到右扫描，f[mask] = 「已经安置好 mask 中这些角色」的总权重，
    每格可以选择不给人、或者给一个尚未安置的角色。全部项非负，没有相消。

    复杂度 O(N · 2^n · n)，本例 200 × 128 × 7 ≈ 1.8e5 次乘加。
    """
    n, m = rows.shape
    size = 1 << n
    without = [np.array([s for s in range(size) if not (s >> i) & 1]) for i in range(n)]
    f = np.zeros(size)
    f[0] = 1.0
    for j in range(m):
        col = rows[:, j]
        new = f.copy()
        for i in range(n):
            idx = without[i]
            new[idx | (1 << i)] += f[idx] * col[i]
        f = new
    return float(f[size - 1])


# ===========================================================================
# 5. Visualizer
# ===========================================================================


class Visualizer:
    def __init__(self, grid: GridMap, walkers: list[Walker], outdir: Path = IMG_DIR,
                 banded: bool = True):
        self.grid = grid
        self.walkers = walkers
        self.outdir = outdir
        self.banded = banded
        self.cmap = RAMP_PROB.copy()
        self.cmap.set_bad(WALL)
        self.annotate = grid.size <= 40

    # --- 底图 -------------------------------------------------------------

    def _paint(self, ax, values, vmax, title, annotate=None):
        """把一格一格的矩形格与角框画在地图上。

        self.banded 为真时概率用**分段色标**（@prob_cmap_norm），小概率区得到更大的
        颜色跨度；为假时退回原来的线性色标，方便对照。
        """
        annotate = self.annotate if annotate is None else annotate
        ax.set_facecolor("white")
        # 障碍格是 NaN。线性标度会自动把非有限值 mask 掉，但 BoundaryNorm 不一定，
        # 所以这里显式遮罩，保证障碍格一定落到 cmap.set_bad(WALL)。
        canvas = np.ma.masked_invalid(self.grid.occupancy_grid(np.asarray(values)))
        if self.banded:
            cmap, norm, bounds = prob_cmap_norm(vmax)
            im = ax.imshow(canvas, cmap=cmap, norm=norm, interpolation="nearest")
            # 分段色标下"深色"的起点要看颜色跨度而不是数值比例：
            # 第 62% 档对应的断点以上才用白字。
            idx = min(int(0.62 * (len(bounds) - 1)) + 1, len(bounds) - 1)
            dark_from = float(bounds[idx])
        else:
            im = ax.imshow(canvas, cmap=self.cmap, vmin=0.0, vmax=vmax,
                           interpolation="nearest")
            dark_from = 0.62 * vmax
        step = 1 if self.grid.cols <= 10 else 5
        ax.set_xticks(range(0, self.grid.cols, step))
        ax.set_yticks(range(0, self.grid.rows, step))
        ax.set_xticks(np.arange(-0.5, self.grid.cols, 1), minor=True)
        ax.set_yticks(np.arange(-0.5, self.grid.rows, 1), minor=True)
        ax.grid(which="minor", color="#FFFFFF", linewidth=0.5, alpha=0.85)
        ax.tick_params(which="both", length=0, colors=MUTED, labelsize=8)
        for side in ("top", "right", "left", "bottom"):
            ax.spines[side].set_color("#BFD5DA")
        ax.set_title(title, fontsize=10, color=INK, pad=8)
        if annotate:
            for i, (r, c) in enumerate(self.grid.cells):
                v = float(values[i])
                if v < 5e-3:
                    continue
                ax.text(c, r, f"{v:.2f}", ha="center", va="center", fontsize=6.2,
                        color="#FFFFFF" if v >= dark_from else INK)
        for w in self.walkers:
            r, c = w.start_cell
            ax.plot(c, r, marker="s", ms=4.0, mfc="none", mec=C_START, mew=1.2)
        return im

    def map_overview(self, path: Path) -> Path:
        fig, ax = plt.subplots(figsize=(7.2, 7.0), dpi=120)
        self._paint(ax, np.zeros(self.grid.size), 1.0,
                    L("地图与七名角色的出发点", "Map and the seven starting cells"))
        for w in self.walkers:
            r, c = w.start_cell
            ax.text(c, r, w.label, ha="center", va="center", fontsize=8,
                    color="white", weight="bold")
        ax.set_xlabel(L("列", "column"))
        ax.set_ylabel(L("行", "row"))
        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path

    # --- GIF --------------------------------------------------------------

    @staticmethod
    def _frames_to_gif(frames, path: Path, duration: int = 420) -> None:
        base = frames[0].convert("P", palette=Image.ADAPTIVE, colors=255)
        pal = [base] + [f.quantize(palette=base, dither=Image.Dither.NONE) for f in frames[1:]]
        pal[0].save(path, save_all=True, append_images=pal[1:], duration=duration, loop=0, optimize=True)

    def occupancy_gif(self, idx: int, occ: np.ndarray, turns: int, path: Path) -> Path:
        w = self.walkers[idx]
        data = occ[:, idx, :]
        turns = min(turns, len(data))
        vmax = max(float(data[:turns].max()), 1e-6)
        frames = []
        for t in range(turns):
            fig, ax = plt.subplots(figsize=(5.6, 5.4), dpi=86)
            im = self._paint(ax, data[t], vmax,
                             L(f"角色 {w.label}：第 {t} 回合的到达概率",
                               f"Character {w.label}: occupancy at turn {t}"))
            tidy_colorbar(fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03,
                                       label=L("概率", "probability")),
                          prob_levels(vmax))
            fig.tight_layout()
            fig.canvas.draw()
            frames.append(Image.fromarray(np.asarray(fig.canvas.buffer_rgba())).convert("RGB"))
            plt.close(fig)
        self._frames_to_gif(frames, path)
        return path

    def occupancy_gif_all(self, occ: np.ndarray, turns: int, path: Path) -> Path:
        turns = min(turns, len(occ))
        vmax = max(float(occ[:turns].max()), 1e-6)
        n = len(self.walkers)
        ncol = 4
        nrow = math.ceil(n / ncol)
        frames = []
        for t in range(turns):
            fig, axes = plt.subplots(nrow, ncol, figsize=(3.6 * ncol, 3.4 * nrow), dpi=66)
            axes = np.atleast_1d(axes).ravel()
            im = None
            for k in range(ncol * nrow):
                ax = axes[k]
                if k < n:
                    im = self._paint(ax, occ[t, k], vmax,
                                     L(f"角色 {self.walkers[k].label}", f"Character {self.walkers[k].label}"),
                                     annotate=False)
                else:
                    ax.axis("off")
            fig.suptitle(L(f"第 {t} 回合：七名角色的到达概率",
                           f"Turn {t}: occupancy of all seven characters"), fontsize=12, color=INK)
            tidy_colorbar(fig.colorbar(im, ax=axes.tolist(), fraction=0.02, pad=0.02,
                                       label=L("概率", "probability")),
                          prob_levels(vmax))
            fig.canvas.draw()
            frames.append(Image.fromarray(np.asarray(fig.canvas.buffer_rgba())).convert("RGB"))
            plt.close(fig)
        self._frames_to_gif(frames, path, duration=520)
        return path

    def encounter_gif(self, enc_cell: np.ndarray, enc_first: np.ndarray, turns: int, path: Path) -> Path:
        # enc_cell / enc_first 按下标 = 回合号存放，第 0 回合不可能有遭遇，
        # 所以 GIF 从第 1 回合开始画。
        turns = min(turns, len(enc_cell) - 1)
        vmax = max(float(enc_cell[1 : turns + 1].max()), 1e-9)
        frames = []
        for k in range(turns):
            t = k + 1
            p = float(enc_first[t])
            fig, ax = plt.subplots(figsize=(5.8, 5.6), dpi=86)
            im = self._paint(ax, enc_cell[t], vmax,
                             L(f"第 {t} 回合：首次遭遇发生的位置，P = {p:.3f}",
                               f"Turn {t}: first-encounter location, P = {p:.3f}"))
            tidy_colorbar(fig.colorbar(im, ax=ax, fraction=0.046, pad=0.03,
                                       label=L("概率", "probability")),
                          prob_levels(vmax))
            fig.tight_layout()
            fig.canvas.draw()
            frames.append(Image.fromarray(np.asarray(fig.canvas.buffer_rgba())).convert("RGB"))
            plt.close(fig)
        self._frames_to_gif(frames, path)
        return path

    # --- 曲线 -------------------------------------------------------------

    @staticmethod
    def _window(series: np.ndarray, quantile: float = 0.995, cap: int = 400) -> int:
        cdf = np.cumsum(series)
        return max(8, min(int(np.searchsorted(cdf, quantile)) + 3, cap, len(series)))

    def curves_arrival(self, fp: dict, start: int, targets, pmfs: dict, path: Path) -> Path:
        """单个角色对若干目标格的首达分布与累积分布。pmfs[cell_index] = pmf 数组。"""
        n_t = len(targets)
        fig, axes = plt.subplots(2, n_t, figsize=(3.5 * n_t, 6.8), squeeze=False)
        for col, cell in enumerate(targets):
            idx = self.grid.idx(*cell)
            pmf = pmfs[idx]
            K = min(len(pmf), 200)
            ax = axes[0][col]
            ax.bar(np.arange(K), pmf[:K], width=0.85, color=C2)
            ax.set_title(L(f"角色 {self.walkers[0].label} 首达 ({cell[0]},{cell[1]})",
                           f"char {self.walkers[0].label} first arrival at {cell}"), fontsize=10)
            ax.set_xlabel(L("回合 t", "turn t"))
            ax.grid(alpha=0.3)
            ax = axes[1][col]
            ax.plot(np.arange(K), np.cumsum(pmf[:K]), lw=1.5, color=C1)
            ax.axhline(0.5, color=MUTED, ls=":", lw=1)
            ax.set_title(L(f"累积：E={fp['mean'][start, idx]:.1f}, σ={fp['std'][start, idx]:.1f}",
                           f"CDF: E={fp['mean'][start, idx]:.1f}, σ={fp['std'][start, idx]:.1f}"),
                         fontsize=9)
            ax.set_xlabel(L("回合 t", "turn t"))
            ax.grid(alpha=0.3)
        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path

    def heat_first_passage(self, fp: dict, which: str, path: Path) -> Path:
        n = len(self.walkers)
        ncol = 4
        nrow = math.ceil(n / ncol)
        vals = fp[which]
        vmax = float(vals.max())
        ramp = RAMP_MEAN if which == "mean" else RAMP_STD
        cmap = ramp.copy()
        cmap.set_bad(WALL)
        fig, axes = plt.subplots(nrow, ncol, figsize=(3.5 * ncol, 3.3 * nrow), dpi=110)
        axes = np.atleast_1d(axes).ravel()
        for k in range(ncol * nrow):
            ax = axes[k]
            if k >= n:
                ax.axis("off")
                continue
            w = self.walkers[k]
            sub = vals[w.start]
            im = ax.imshow(self.grid.occupancy_grid(sub), cmap=cmap, vmin=0.0, vmax=vmax,
                           interpolation="nearest")
            ax.set_xticks([])
            ax.set_yticks([])
            for side in ("top", "right", "left", "bottom"):
                ax.spines[side].set_color("#BFD5DA")
            ax.set_title(f"{L('角色', 'char')} {w.label}", fontsize=10, color=INK, pad=6)
            r, c = w.start_cell
            ax.plot(c, r, marker="s", ms=4.5, mfc="none", mec=C_START, mew=1.2)
        name = L("首达期望 E[T]", "E[T]") if which == "mean" else L("首达标准差 σ[T]", "σ[T]")
        fig.suptitle(name, fontsize=12, color=INK)
        tidy_colorbar(fig.colorbar(im, ax=axes.tolist(), fraction=0.02, pad=0.02))
        fig.savefig(path)
        plt.close(fig)
        return path

    def curves_encounter(self, mc: dict, upper: np.ndarray, path: Path) -> Path:
        # 遭遇相关的量只记录到 record_turns，因此横轴用这个长度，而不是结束时间的分位
        hi = len(mc["enc_first"])
        ts = np.arange(hi)
        fig, axes = plt.subplots(2, 2, figsize=(11.0, 7.4))

        ax = axes[0, 0]
        ax.bar(ts[1:], mc["enc_first"][1:hi], color=C2, width=0.85,
               label=L("整局第一次遭遇", "very first encounter"))
        ax.plot(ts[1:], mc["enc_any"][1:hi], color=C1, lw=1.3, marker=".", ms=3,
                label=L("任意遭遇", "any encounter"))
        ax.set_title(L("任一回合发生遭遇的概率", "P(an encounter at turn t)"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.set_ylabel(L("概率", "probability"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)

        ax = axes[0, 1]
        for i, w in enumerate(self.walkers):
            ax.plot(ts, mc["duel"][w.label]["pmf"][:hi], lw=1.4, color=PALETTE[i % 7],
                    label=w.label)
        ax.set_title(L("各角色「首次遭遇」的回合分布", "First-encounter turn by character"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.legend(fontsize=7, ncol=2)
        ax.grid(alpha=0.3)

        ax = axes[1, 0]
        ax.plot(ts, 1.0 - np.cumsum(mc["enc_first"][:hi]), lw=2.0, color=C1,
                label=L("蒙特卡洛", "Monte Carlo"))
        ax.plot(ts, np.clip(upper[:hi], 0.0, 1.0), lw=1.4, ls=":", color=C4,
                label=L("积和式上界", "permanent bound"))
        ax.set_title(L("整局尚未遭遇的概率与积和式上界",
                       "P(no encounter yet) and the permanent bound"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.set_ylim(0, 1.02)
        ax.legend(fontsize=7.5)
        ax.grid(alpha=0.3)

        ax = axes[1, 1]
        ax.semilogy(ts[1:], np.clip(1.0 - np.cumsum(mc["enc_first"][:hi])[1:], 1e-17, None),
                    color=C3, lw=1.5, label=L("P(尚未遭遇)", "P(no encounter yet)"))
        ax.set_yscale("log")
        ax.set_title(L("整局尚未遭遇的概率", "P(no encounter yet)"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3, which="both")

        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path

    def curves_end(self, mc: dict, path: Path) -> Path:
        end = mc["end_pmf"]
        hi = self._window(end)
        ts = np.arange(len(end))
        mean, std = mc["end_mean"], mc["end_std"]
        fig, axes = plt.subplots(2, 2, figsize=(11.0, 7.4))

        ax = axes[0, 0]
        ax.bar(ts[:hi], end[:hi], color=C2, width=0.9)
        ax.axvline(int(np.argmax(end)), color=C1, ls="--", lw=1.2,
                   label=L(f"众数 {int(np.argmax(end))}", f"mode {int(np.argmax(end))}"))
        ax.set_title(L("第 t 回合游戏结束的概率", "P(game ends at turn t)"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.set_ylabel(L("概率", "probability"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)

        ax = axes[1, 0]
        ax.semilogy(ts[1:], np.clip(1.0 - np.cumsum(end)[:-1], 1e-17, None), color=C3, lw=1.6)
        ax.set_yscale("log")
        ax.set_title(L("第 t 回合游戏仍在进行的概率",
                       "P(game still running at turn t)"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.grid(alpha=0.3, which="both")

        ax = axes[0, 1]
        ax.plot(ts[:hi], np.cumsum(end[:hi]), lw=1.6, color=C2)
        ax.axhline(0.5, color=MUTED, ls=":", lw=1)
        ax.axvline(mean, color=C1, ls="--", lw=1.2,
                   label=L(f"期望 {mean:.2f} ± {mc['end_se_mean']:.2f}", f"mean {mean:.2f}"))
        ax.axvline(int(np.searchsorted(np.cumsum(end), 0.5)), color=C5, ls=":", lw=1.4,
                   label=L(f"中位数 {int(np.searchsorted(np.cumsum(end), 0.5))}", "median"))
        ax.set_title(L("结束时间的累积分布", "CDF of the end turn"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)

        ax = axes[1, 1]
        labels = [w.label for w in self.walkers]
        wins = [mc["duel"][w.label]["win"] for w in self.walkers]
        ax.bar(labels, wins, color=list(PALETTE))
        for i, v in enumerate(wins):
            ax.text(i, v + 0.002, f"{v:.4f}", ha="center", fontsize=8)
        ax.set_title(L("各角色获胜的概率", "P(being the sole survivor)"))
        ax.set_ylim(0, max(wins) * 1.25 + 1e-6)
        ax.grid(alpha=0.3, axis="y")

        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path

    def curves_occupancy_compare(self, walkers: list[Walker], exact_occ: list[np.ndarray],
                                 mc_occ: np.ndarray, stationary: np.ndarray, path: Path) -> Path:
        picks = [(0, 6), (4, 9), (8, 0), (14, 5)]
        for cell in picks:
            if cell not in self.grid.index:
                raise ValueError(f"代表格 {cell} 不在可通行集合中")
        chars = [0, 2, 5]
        fig, axes = plt.subplots(1, 2, figsize=(11.4, 4.4))

        ax = axes[0]
        hi = min(mc_occ.shape[0], 60)
        ts = np.arange(hi)
        # 颜色区分角色（每个角色只登一次图例），目标格在标题里说明
        for k, ch in enumerate(chars):
            for cell in picks:
                idx = self.grid.idx(*cell)
                ax.plot(ts, exact_occ[ch][:hi, idx], lw=1.5, color=PALETTE[k % 7])
                ax.plot(ts, mc_occ[:hi, ch, idx], lw=0.9, ls=":", color=PALETTE[k % 7])
            ax.plot([], [], lw=1.5, color=PALETTE[k % 7],
                    label=L(f"角色 {self.walkers[ch].label}", f"char {self.walkers[ch].label}"))
        for ls, name in (("-", L("单角色精确占用", "exact single walk")),
                         (":", L("游戏内占用（含淘汰）", "in-game (MC)"))):
            ax.plot([], [], lw=1.3, ls=ls, color=MUTED, label=name)
        ax.set_title(L("角色 1/3/6 在各自出发点的占用概率",
                       "occupancy at each character's own start"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.set_ylabel(L("概率", "probability"))
        ax.legend(fontsize=7.5)
        ax.grid(alpha=0.3)

        ax = axes[1]
        sorted_stat = np.sort(stationary)[::-1]
        ax.plot(np.arange(1, len(sorted_stat) + 1), sorted_stat, lw=1.8, color=C2)
        ax.set_yscale("log")
        ax.set_title(L("平稳分布 π(c) = W(c)/ΣW",
                       "stationary law π(c) = W(c)/ΣW"))
        ax.set_xlabel(L("方格序号", "cell rank"))
        ax.set_ylabel(L("概率", "probability"))
        uniq = np.unique(stationary)[::-1]
        pos = 1
        for val in uniq:
            n = int((stationary == val).sum())
            ax.annotate(L(f"{n} 格，π={val:.5f}", f"{n} cells, π={val:.5f}"),
                        (pos + n / 2, val), textcoords="offset points", xytext=(0, 9),
                        ha="center", fontsize=8, color=MUTED)
            pos += n
        ax.grid(alpha=0.3, which="both")
        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path

    def curves_validation(self, pair_exact_pmf: np.ndarray, pair_mc: dict,
                          test_exact_pmf: np.ndarray, test_mc: dict, path: Path) -> Path:
        fig, axes = plt.subplots(1, 2, figsize=(11.4, 4.4))

        ax = axes[0]
        hi = self._window(pair_exact_pmf)
        ts = np.arange(hi)
        ax.plot(ts, np.cumsum(pair_exact_pmf[:hi]), lw=1.8, color=C1,
                label=L("精确递推", "exact"))
        ax.plot(ts, np.cumsum(pair_mc["end_pmf"][:hi]), lw=1.0, ls="--", color=C5,
                label=L(f"蒙特卡洛（{pair_mc['trials']:,} 局）", f"MC ({pair_mc['trials']:,})"))
        ax.set_title(L("只有角色 1、2 时：相遇时间的累积分布",
                       "Only characters 1 and 2: CDF of the meeting time"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)

        ax = axes[1]
        hi = self._window(test_exact_pmf, cap=200)
        ts = np.arange(hi)
        ax.plot(ts, test_exact_pmf[:hi], lw=1.8, color=C1, marker="o", ms=2.5,
                label=L("精确递推", "exact"))
        ax.plot(ts, test_mc["end_pmf"][:hi], lw=1.0, ls="--", color=C5,
                label=L(f"蒙特卡洛（{test_mc['trials']:,} 局）", f"MC ({test_mc['trials']:,})"))
        ax.set_title(L("4 人、32 格测试地图：结束时间分布",
                       "4 characters, 32 cells: end-turn law"))
        ax.set_xlabel(L("回合 t", "turn t"))
        ax.legend(fontsize=8)
        ax.grid(alpha=0.3)
        fig.tight_layout()
        fig.savefig(path)
        plt.close(fig)
        return path


# ===========================================================================
# 6. 场景与主程序
# ===========================================================================


def build_scene(map_text: str, order, weights: dict, display_prefix: str = ""):
    grid = GridMap(map_text)
    walkers = [Walker(label, [weights[d] for d in DIRECTIONS], grid) for label in order]
    return grid, walkers


def main() -> None:
    parser = argparse.ArgumentParser(description="限定范围的经典游走：精确解 + 蒙特卡洛 + 可视化")
    parser.add_argument("--trials", type=int, default=800000)
    parser.add_argument("--max-turns", type=int, default=10000)
    parser.add_argument("--pair-max-turns", type=int, default=16000)
    parser.add_argument("--test-trials", type=int, default=200000)
    parser.add_argument("--order-trials", type=int, default=200000)
    parser.add_argument("--seed", type=int, default=20261013)
    parser.add_argument("--record-turns", type=int, default=80)
    parser.add_argument("--no-gif", action="store_true")
    parser.add_argument("--gif-turns", type=int, default=24)
    parser.add_argument("--linear-prob-color", action="store_true",
                        help="概率图退回线性色标（默认用分段色标，低概率区颜色跨度更大）")
    args = parser.parse_args()

    t0 = time.time()
    grid, walkers = build_scene(MAP_TEXT, TURN_ORDER, DEFAULT_MOVE_WEIGHTS)
    print(f"[地图] {grid.rows}x{grid.cols}，可通行 {grid.size} 格，连通={grid.connected}，"
          f"角色 {len(walkers)} 名，行动顺序 {list(TURN_ORDER)}")

    # ---- 1. 单角色：转移矩阵、平稳分布、首达（精确） ----
    print("[单角色] 逐格合法方向、平稳分布与首达矩阵（精确） ...")
    w0 = walkers[0]
    W = w0.total_weight
    print(f"   合法动作数分布 {np.bincount(w0.n_legal, minlength=6)[:6].tolist()}"
          f"（下标=合法动作个数）")
    print(f"   W(c) 取值 {sorted(set(W.tolist()))}，ΣW = {W.sum():.1f}")
    stat_analytic = w0.stationary_analytic()
    stat_numeric = w0.stationary_numeric()
    print(f"   π ∝ W 与幂法迭代的最大偏差 {np.abs(stat_analytic - stat_numeric).max():.3e}")
    fp = w0.first_passage_maps()
    print(f"   首达期望范围 [{fp['mean'].min():.2f}, {fp['mean'].max():.2f}]，"
          f"标准差最大 {fp['std'].max():.2f}")
    probe = w0.verify_first_passage(fp)
    print(f"   尾和公式 vs 基本矩阵公式（抽查 6 格）最大偏差 {probe['max_deviation']:.3e}"
          f"，最长迭代 {probe['max_steps']} 步")
    # 只保留上界与对比图需要的回合数，避免 (10001, 200) 的大数组白占内存
    occ_turns = min(args.max_turns, 400)
    exact_occ = {w.label: w.occupancy(occ_turns) for w in walkers}

    # ---- 2. 上界：同一时刻全体互异 = 积和式（Ryser，精确） ----
    print("[上界] 用 Ryser 公式精确计算「第 t 回合全体互异」的概率 ...")
    T_nc = min(400, args.max_turns)
    upper = np.ones(T_nc + 1)
    for t in range(1, T_nc + 1):
        rows = np.stack([exact_occ[w.label][t] for w in walkers])
        upper[t] = permanent_dp(rows)
    print(f"   t=10 时上界 {upper[10]:.4f}")

    # ---- 3. 只留两名角色时的精确解（作为蒙特卡洛的校核基准） ----
    print("[精确] 只保留角色 1、2 的精确递推 ...")
    pair_walkers = [walkers[TURN_ORDER.index("1")], walkers[TURN_ORDER.index("2")]]
    pair_exact = Game(grid, pair_walkers, max_turns=args.pair_max_turns, tol=1e-12).run(verbose=False)
    pair_stats = pair_exact.end_stats()
    print(f"   {pair_exact.turns_run} 回合，残留 {pair_exact.residual:.2e}，"
          f"精确 E[T_end]={pair_stats['mean']:.4f}，自检 {pair_exact.self_check()}")
    pair_mc = MonteCarlo(grid, pair_walkers, trials=min(args.trials, 400000),
                         max_turns=args.pair_max_turns, record_turns=8).run()

    # ---- 4. 小测试地图上的 4 人精确解与蒙特卡洛（校核连锁决斗） ----
    print("[校核] 小测试地图上 4 人的精确递推 ...")
    test_grid, test_walkers = build_scene(TEST_MAP_TEXT, TEST_TURN_ORDER, DEFAULT_MOVE_WEIGHTS)
    test_exact = Game(test_grid, test_walkers, max_turns=600, tol=1e-11).run(verbose=False)
    test_mc = MonteCarlo(test_grid, test_walkers, trials=args.test_trials,
                         max_turns=600, record_turns=8).run()
    print(f"   {test_grid.rows}x{test_grid.cols} / N={test_grid.size} / 4 人："
          f"精确 E[T_end]={test_exact.end_stats()['mean']:.4f}，"
          f"蒙特卡洛 {test_mc['end_mean']:.4f}")

    # ---- 5. 7 人局的蒙特卡洛 ----
    print("[蒙特卡洛] 7 人的整局采样 ...")
    mc = MonteCarlo(grid, walkers, trials=args.trials, max_turns=args.max_turns,
                    record_turns=args.record_turns).run()

    # ---- 5b. 把行动顺序倒过来再采样一次：分离「地理隔离」与「行动顺序」 ----
    print("[对照] 行动顺序倒过来（7,6,...,1）再采样一次 ...")
    rev_walkers = [walkers[TURN_ORDER.index(x)] for x in reversed(TURN_ORDER)]
    mc_rev = MonteCarlo(grid, rev_walkers, trials=args.order_trials,
                        max_turns=args.max_turns, record_turns=4,
                        seed=args.seed + 1).run()
    print("[摘要] 逆序行动顺序的获胜概率：" + "，".join(
        f"{w.label}={mc_rev['duel'][w.label]['win']:.5f}" for w in rev_walkers))
    print("[摘要] 正序行动顺序的获胜概率：" + "，".join(
        f"{w.label}={mc['duel'][w.label]['win']:.5f}" for w in walkers))

    # ---- 6. 先把关键数值全部打印出来（出图失败也不至于丢结果） ----
    ep = mc["end_pmf"]
    cep = np.cumsum(ep)
    ef = mc["enc_first"]
    cef = np.cumsum(ef)
    ts_ef = np.arange(len(ef))
    print("[摘要] 游戏结束时间："
          f"E={mc['end_mean']:.4f}±{mc['end_se_mean']:.4f} σ={mc['end_std']:.4f} "
          f"中位={int(np.searchsorted(cep, 0.5))} 众数={int(np.argmax(ep))} "
          f"P25/75/90/95/99%={[int(np.searchsorted(cep, q)) for q in (0.25, 0.75, 0.9, 0.95, 0.99)]}")
    print("[摘要] 整局首次遭遇："
          f"E={float((ts_ef * ef).sum()):.4f} "
          f"σ={float(np.sqrt(max((ts_ef ** 2 * ef).sum() - (ts_ef * ef).sum() ** 2, 0))):.4f} "
          f"众数={int(np.argmax(ef))} "
          f"累积 t=5/10/20/40: {[round(float(cef[t]), 4) for t in (5, 10, 20, 40)]}")
    print("[摘要] 上界 Pr(全体互异) t=1/5/10/20/50: "
          f"{[round(float(upper[t]), 4) for t in (1, 5, 10, 20, 50)]}")
    for w in walkers:
        d = mc["duel"][w.label]
        cum = np.cumsum(d["pmf"])
        print(f"[摘要] 角色 {w.label}@{w.start_cell}: 首次遭遇 E={d['mean']:.3f}±{d['se_mean']:.3f} "
              f"σ={d['std']:.3f} 中位={int(np.searchsorted(cum, 0.5))} "
              f"P90={int(np.searchsorted(cum, 0.9))} Wilson=({d['wilson'][0]:.5f},{d['wilson'][1]:.5f}) "
              f"获胜={d['win']:.5f}")
    print(f"[摘要] 获胜概率之和 = {sum(mc['duel'][w.label]['win'] for w in walkers):.6f}")
    for cell in [(0, 0), (7, 7), (0, 14), (14, 14), (7, 4)]:
        if cell in grid.index:
            i = grid.idx(*cell)
            print(f"[摘要] 角色 1 首达 {cell}: E={fp['mean'][walkers[0].start, i]:.2f} "
                  f"σ={fp['std'][walkers[0].start, i]:.2f}")
    print(f"[摘要] 两人局（角色 1、2）精确 E={pair_stats['mean']:.4f} σ={pair_stats['std']:.4f}，"
          f"蒙特卡洛 {pair_mc['end_mean']:.4f}±{pair_mc['end_se_mean']:.4f}")
    print(f"[摘要] 小测试地图精确 E={test_exact.end_stats()['mean']:.4f}，"
          f"蒙特卡洛 {test_mc['end_mean']:.4f}±{test_mc['end_se_mean']:.4f}")

    # ---- 7. 可视化 ----
    print("[可视化] 出图 ...")
    vis = Visualizer(grid, walkers, banded=not args.linear_prob_color)
    if vis.banded:
        print(f"   [色标] 概率图用分段色标，共 {len(PROB_BANDS) - 1} 档，"
              f"断点比例 {list(PROB_BANDS)}")
    vis.map_overview(IMG_DIR / "map.png")
    keep = args.gif_turns
    for i, w in enumerate(walkers):
        vis.occupancy_gif(i, mc["occ"], keep, IMG_DIR / f"walk-{w.label}.gif")
        print(f"   - walk-{w.label}.gif", flush=True)
    vis.occupancy_gif_all(mc["occ"], keep, IMG_DIR / "walk-all.gif")
    vis.encounter_gif(mc["enc_cell"], mc["enc_first"], keep, IMG_DIR / "encounter-location.gif")
    print("   - walk-all.gif / encounter-location.gif", flush=True)

    vis.curves_encounter(mc, upper, IMG_DIR / "curve-encounter.png")
    vis.curves_end(mc, IMG_DIR / "curve-end.png")
    targets = [(0, 6), (8, 0), (14, 5), (7, 4)]
    for cell in targets:
        if cell not in grid.index:
            raise ValueError(f"目标格 {cell} 不在可通行集合中")
    pmfs = {grid.idx(*cell): walkers[0].first_passage_tailsum(grid.idx(*cell))["pmf"]
            for cell in targets}
    vis.curves_arrival(fp, walkers[0].start, targets, pmfs, IMG_DIR / "curve-arrival.png")
    vis.heat_first_passage(fp, "mean", IMG_DIR / "heat-first-passage-E.png")
    vis.heat_first_passage(fp, "std", IMG_DIR / "heat-first-passage-sd.png")
    vis.curves_occupancy_compare(walkers, [exact_occ[w.label] for w in walkers],
                                 mc["occ"], stat_analytic, IMG_DIR / "curve-occupancy-compare.png")
    vis.curves_validation(pair_exact.end_pmf, pair_mc, test_exact.end_pmf, test_mc,
                          IMG_DIR / "curve-mc-validation.png")
    print("   - 曲线与热图完成")

    # ---- 8. 结果汇总 ----
    def rnd(x, nd: int = 6):
        if isinstance(x, np.ndarray):
            return rnd(x.tolist(), nd)
        if x is None or isinstance(x, (int, str, bool)):
            return x
        if isinstance(x, (list, tuple)):
            return [rnd(v, nd) for v in x]
        if isinstance(x, dict):
            return {k: rnd(v, nd) for k, v in x.items()}
        v = float(x)
        return 0.0 if v == 0 else float(f"%.{nd}g" % v)

    def cap(x, m: int = 400):
        return list(x)[:m]

    end_stats = {
        "mean": mc["end_mean"], "std": mc["end_std"], "se_mean": mc["end_se_mean"],
        "median": int(np.searchsorted(np.cumsum(mc["end_pmf"]), 0.5)),
        "mode": int(np.argmax(mc["end_pmf"])),
        "p95": int(np.searchsorted(np.cumsum(mc["end_pmf"]), 0.95)),
    }
    enc_stats = {}
    for w in walkers:
        d = mc["duel"][w.label]
        cum = np.cumsum(d["pmf"])
        enc_stats[w.label] = {
            "total": d["total"], "wilson": list(d["wilson"]), "mean": d["mean"],
            "std": d["std"], "se_mean": d["se_mean"], "win": d["win"],
            "median": int(np.searchsorted(cum, 0.5 * d["total"])) if d["total"] > 0 else 0,
            "p90": int(np.searchsorted(cum, 0.9 * d["total"])) if d["total"] > 0 else 0,
            "pmf": rnd(cap(d["pmf"])),
        }

    def brief_end(st):
        return {k: v for k, v in st.items() if k != "pmf"}

    results = {
        "map": grid.describe(),
        "parameters": {"trials": args.trials, "max_turns": args.max_turns,
                       "gif_turns": args.gif_turns, "cjk_font": CJK,
                       "map_source": "Code/gridGameOptimized.py 的 demoMap",
                       "weights": DEFAULT_MOVE_WEIGHTS, "turn_order": list(TURN_ORDER)},
        "walker": w0.summary(),
        "stationary": {
            "analytic": rnd(stat_analytic), "numeric": rnd(stat_numeric),
            "max_deviation": float(np.abs(stat_analytic - stat_numeric).max()),
            "W_values": {str(int(v)): int((W == v).sum()) for v in np.unique(W)},
        },
        "first_passage": {
            # 完整矩阵是 200×200，落盘太占地方；只存七名角色各自的出发点那一行
            "mean_by_start": {w.label: rnd(fp["mean"][w.start]) for w in walkers},
            "std_by_start": {w.label: rnd(fp["std"][w.start]) for w in walkers},
            "range_mean": [float(fp["mean"].min()), float(fp["mean"].max())],
            "range_std": [float(fp["std"].min()), float(fp["std"].max())],
            "tailsum_check": rnd(probe),
        },
        "naive_upper": rnd(cap(upper, 200)),
        "pair_exact": {
            "turns_run": pair_exact.turns_run, "residual": pair_exact.residual,
            "end": rnd(brief_end(pair_exact.end_stats())), "checks": pair_exact.self_check(),
            "end_pmf": rnd(cap(pair_exact.end_pmf, 600)),
            "nc_mass": rnd(cap(pair_exact.nc_mass, 600)),
        },
        "pair_mc": {"trials": pair_mc["trials"], "end_mean": pair_mc["end_mean"],
                    "end_std": pair_mc["end_std"], "end_se_mean": pair_mc["end_se_mean"],
                    "end_pmf": rnd(cap(pair_mc["end_pmf"], 600))},
        "test_exact": {"size": test_grid.size, "turns_run": test_exact.turns_run,
                       "end": rnd(brief_end(test_exact.end_stats())),
                       "checks": test_exact.self_check(),
                       "end_pmf": rnd(cap(test_exact.end_pmf, 200))},
        "test_mc": {"trials": test_mc["trials"], "end_mean": test_mc["end_mean"],
                    "end_std": test_mc["end_std"], "end_se_mean": test_mc["end_se_mean"],
                    "end_pmf": rnd(cap(test_mc["end_pmf"], 200))},
        "mc": {
            "trials": mc["trials"], "unfinished": mc["unfinished"],
            "end": end_stats,
            "end_pmf": rnd(cap(mc["end_pmf"])),
            "enc_first": rnd(cap(mc["enc_first"])),
            "enc_any": rnd(cap(mc["enc_any"])),
            "encounter": enc_stats,
            "enc_cell": rnd(mc["enc_cell"][: args.gif_turns]),
            "occupancy": {w.label: rnd(mc["occ"][: args.gif_turns, i, :])
                          for i, w in enumerate(walkers)},
            "enc_first_moments": {
                "mean": float((np.arange(len(mc["enc_first"])) * mc["enc_first"]).sum()),
                "std": float(np.sqrt(max(
                    (np.arange(len(mc["enc_first"])) ** 2 * mc["enc_first"]).sum()
                    - ((np.arange(len(mc["enc_first"])) * mc["enc_first"]).sum()) ** 2, 0.0))),
                "mode": int(np.argmax(mc["enc_first"])),
            },
        },
        "order_control": {
            "trials": mc_rev["trials"],
            "win_reversed_order": {w.label: mc_rev["duel"][w.label]["win"] for w in rev_walkers},
            "win_forward_order": {w.label: mc["duel"][w.label]["win"] for w in walkers},
            "end_mean_reversed": mc_rev["end_mean"],
            "end_se_reversed": mc_rev["end_se_mean"],
        },
    }
    out = NOTE_DIR / "results.json"
    out.write_text(json.dumps(results, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"[完成] results.json {out.stat().st_size / 1024:.1f} KB，总耗时 {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()

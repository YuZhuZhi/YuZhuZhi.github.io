#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.10"
# ///

"""
Tufted Blog Template 构建脚本

这是一个跨平台的构建脚本，用于将 Typst (.typ) 文件编译为 HTML 和 PDF，
并复制静态资源到输出目录。

支持增量编译：只重新编译修改后的文件，加快构建速度。

用法:
    uv run build.py build       # 完整构建 (HTML + PDF + 资源)
    uv run build.py html        # 仅构建 HTML 文件
    uv run build.py slides      # 仅构建 Touying 幻灯片 (HTML 演示文稿)
    uv run build.py pdf         # 仅构建 PDF 文件
    uv run build.py assets      # 仅复制静态资源
    uv run build.py clean       # 清理生成的文件
    uv run build.py preview     # 启动本地预览服务器（默认端口 8000）
    uv run build.py preview -p 3000  # 使用自定义端口
    uv run build.py --help      # 显示帮助信息

包含 Touying 包导入的 .typ 文件会被导出为自包含的 HTML 演示文稿（impress.js
幻灯片），而不是普通网页，详见 touying-exporter/README.md。

增量编译选项:
    --force, -f                 # 强制完整重建，忽略增量检查

预览服务器选项:
    --port, -p PORT             # 指定服务器端口号（默认: 8000）

也可以直接使用 Python 运行:
    python build.py build
    python build.py build --force
    python build.py preview -p 3000
"""

import argparse
import base64
import binascii
import hashlib
import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from dataclasses import dataclass
from datetime import datetime, timezone
from html.parser import HTMLParser
from pathlib import Path
from typing import Literal

# Windows 控制台默认可能是 GBK/cp936，打印 ✅/⚠️ 等 emoji 会直接抛
# UnicodeEncodeError，使脚本在编译完成后、复制资源前崩溃，留下过期的 _site 资源。
# 这里只替换无法编码的字符，不改变控制台编码，避免中文显示变成乱码。
try:
    sys.stdout.reconfigure(errors="replace")
    sys.stderr.reconfigure(errors="replace")
except Exception:
    pass

# ============================================================================
# 配置
# ============================================================================

CONTENT_DIR = Path("content")  # 源文件目录
SITE_DIR = Path("_site")  # 输出目录
ASSETS_DIR = Path("assets")  # 静态资源目录
FONT_DIR = Path("fonts")  # 构建字体目录（不随站点发布）
CONFIG_FILE = Path("config.typ")  # 全局配置文件
MATHML_MIN_TYPST_VERSION = (0, 15, 0)

# 内置的 touying-exporter 幻灯片模板（MIT，来源与版本见同目录 README.md）
SLIDE_TEMPLATE_FILE = Path("touying-exporter/template.html.j2")


@dataclass
class BuildStats:
    """构建统计信息"""

    success: int = 0
    skipped: int = 0
    failed: int = 0

    def format_summary(self) -> str:
        """格式化统计摘要"""
        parts = []
        if self.success > 0:
            parts.append(f"编译: {self.success}")
        if self.skipped > 0:
            parts.append(f"跳过: {self.skipped}")
        if self.failed > 0:
            parts.append(f"失败: {self.failed}")
        return ", ".join(parts) if parts else "无文件需要处理"

    @property
    def has_failures(self) -> bool:
        """是否存在失败"""
        return self.failed > 0


class HTMLMetadataParser(HTMLParser):
    """
    从 HTML 文件中提取元数据的解析器。

    解析以下元数据：
    - lang: 从 <html lang="..."> 属性获取
    - title: 从 <title> 标签获取
    - description: 从 <meta name="description" content="..."> 获取
    - link: 从 <link rel="canonical" href="..."> 获取
    - date: 从 <meta name="date" content="..."> 获取
    """

    def __init__(self):
        super().__init__()
        self.metadata = {"title": ""}
        self._in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]):
        attrs_dict = {k: v for k, v in attrs if v}

        match tag:
            case "html":
                self.metadata["lang"] = attrs_dict.get("lang", "")
            case "title":
                self._in_title = True
            case "meta":
                name = attrs_dict.get("name", "")
                if name in {"description", "date"}:
                    self.metadata[name] = attrs_dict.get("content", "")
            case "link":
                if attrs_dict.get("rel") == "canonical":
                    self.metadata["link"] = attrs_dict.get("href", "")

    def handle_endtag(self, tag: str):
        if tag == "title":
            self._in_title = False

    def handle_data(self, data: str):
        if self._in_title:
            self.metadata["title"] += data


def get_typst_version() -> tuple[int, ...] | None:
    """
    获取当前 Typst CLI 的语义化版本号。

    返回:
        tuple[int, int, int] | None: 版本号，获取失败时返回 None
    """
    try:
        result = subprocess.run(
            ["typst", "--version"],
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
    except (FileNotFoundError, OSError):
        return None

    if result.returncode != 0:
        return None

    match = re.search(r"typst (\d+)\.(\d+)\.(\d+)", result.stdout)
    if match is None:
        return None

    return tuple(int(component) for component in match.groups())


def warn_if_typst_version_is_outdated() -> None:
    """
    对低于 MathML 支持基线的 Typst 版本输出提示。
    """
    version = get_typst_version()
    if version is None or version >= MATHML_MIN_TYPST_VERSION:
        return

    current = ".".join(str(component) for component in version)
    required = ".".join(str(component) for component in MATHML_MIN_TYPST_VERSION)
    print(
        f"  ⚠️ 检测到 Typst {current}。HTML 导出的原生 MathML 公式支持需要 Typst {required}+，建议升级 Typst 版本。"
    )


# ============================================================================
# 增量编译辅助函数
# ============================================================================


def get_file_mtime(path: Path) -> float:
    """
    获取文件的修改时间戳。

    参数:
        path: 文件路径

    返回:
        float: 修改时间戳，文件不存在返回 0
    """
    try:
        return path.stat().st_mtime
    except (OSError, FileNotFoundError):
        return 0.0


def is_dep_file(path: Path) -> bool:
    """
    判断一个文件是否被追踪为依赖）。

    content/ 下的普通页面文件不被视为模板文件，因为它们是独立的页面，
    不应该相互依赖。

    参数:
        path: 文件路径

    返回:
        bool: 是否是依赖文件
    """
    try:
        resolved_path = path.resolve()
        project_root = Path(__file__).parent.resolve()
        content_dir = (project_root / CONTENT_DIR).resolve()

        # config.typ 是依赖文件
        if resolved_path == (project_root / CONFIG_FILE).resolve():
            return True

        # 检查是否在 content/ 目录下
        try:
            relative_to_content = resolved_path.relative_to(content_dir)
            # content/_* 目录下的文件视为依赖文件
            parts = relative_to_content.parts
            if len(parts) > 0 and parts[0].startswith("_"):
                return True
            # content/ 下的其他文件不是依赖文件
            return False
        except ValueError:
            # 不在 content/ 目录下，视为依赖文件（如 config.typ）
            return True

    except Exception:
        return True


def find_typ_dependencies(typ_file: Path) -> set[Path]:
    """
    解析 .typ 文件中的依赖（通过 #import 和 #include 导入的文件）。

    只追踪 .typ 文件的依赖，忽略 content/ 下的普通页面文件。
    其他资源文件（如 .md, .bib, 图片等）通过 copy_content_assets 处理。

    参数:
        typ_file: .typ 文件路径

    返回:
        set[Path]: 依赖的 .typ 文件路径集合
    """
    dependencies: set[Path] = set()

    try:
        content = typ_file.read_text(encoding="utf-8")
    except Exception:
        return dependencies

    # 获取文件所在目录，用于解析相对路径
    base_dir = typ_file.parent

    patterns = [
        r'#import\s+"([^"]+)"',
        r"#import\s+'([^']+)'",
        r'#include\s+"([^"]+)"',
        r"#include\s+'([^']+)'",
    ]

    for pattern in patterns:
        for match in re.finditer(pattern, content):
            dep_path_str = match.group(1)

            # 跳过包导入（如 @preview/xxx）
            if dep_path_str.startswith("@"):
                continue

            # 解析相对路径
            if dep_path_str.startswith("/"):
                # 相对于项目根目录的路径
                dep_path = Path(dep_path_str.lstrip("/"))
            else:
                # 相对于当前文件的路径
                dep_path = base_dir / dep_path_str

            # 规范化路径，只追踪 .typ 文件
            try:
                dep_path = dep_path.resolve()
                if dep_path.exists() and dep_path.suffix == ".typ" and is_dep_file(dep_path):
                    dependencies.add(dep_path)
            except Exception:
                pass

    return dependencies


def get_all_dependencies(typ_file: Path, visited: set[Path] | None = None) -> set[Path]:
    """
    递归获取 .typ 文件的所有依赖（包括传递依赖）。

    参数:
        typ_file: .typ 文件路径
        visited: 已访问的文件集合（用于避免循环依赖）

    返回:
        set[Path]: 所有依赖文件路径集合
    """
    if visited is None:
        visited = set()

    # 避免循环依赖
    abs_path = typ_file.resolve()
    if abs_path in visited:
        return set()
    visited.add(abs_path)

    all_deps: set[Path] = set()
    direct_deps = find_typ_dependencies(typ_file)

    for dep in direct_deps:
        all_deps.add(dep)
        # 只对 .typ 文件递归查找依赖
        if dep.suffix == ".typ":
            all_deps.update(get_all_dependencies(dep, visited))

    return all_deps


def needs_rebuild(source: Path, target: Path, extra_deps: list[Path] | None = None) -> bool:
    """
    判断是否需要重新构建。

    当以下任一条件满足时需要重建：
    1. 目标文件不存在
    2. 源文件比目标文件新
    3. 任何额外依赖文件比目标文件新
    4. 源文件的任何导入依赖比目标文件新
    5. 源文件同目录下的任何非 .typ 文件比目标文件新（如 .md, .bib, 图片等）

    参数:
        source: 源文件路径
        target: 目标文件路径
        extra_deps: 额外的依赖文件列表（如 config.typ）

    返回:
        bool: 是否需要重新构建
    """
    # 目标不存在，需要构建
    if not target.exists():
        return True

    target_mtime = get_file_mtime(target)

    # 源文件更新了
    if get_file_mtime(source) > target_mtime:
        return True

    # 检查额外依赖
    if extra_deps:
        for dep in extra_deps:
            if dep.exists() and get_file_mtime(dep) > target_mtime:
                return True

    # 检查源文件的导入依赖
    for dep in get_all_dependencies(source):
        if get_file_mtime(dep) > target_mtime:
            return True

    # 检查源文件同目录下的非 .typ 资源文件（如 .md, .bib, 图片等）
    # 只检查同一目录，不递归子目录，避免过度重编译
    source_dir = source.parent
    for item in source_dir.iterdir():
        if item.is_file() and item.suffix != ".typ":
            if get_file_mtime(item) > target_mtime:
                return True

    return False


def find_common_dependencies() -> list[Path]:
    """
    查找所有文件的公共依赖（如 config.typ）。

    返回:
        list[Path]: 公共依赖文件路径列表
    """
    common_deps = []

    # config.typ 是全局配置，修改后所有页面都需要重建
    if CONFIG_FILE.exists():
        common_deps.append(CONFIG_FILE)

    # 可以在这里添加其他公共依赖
    # 例如：查找 content/_* 目录下的模板文件
    if CONTENT_DIR.exists():
        for item in CONTENT_DIR.iterdir():
            if item.is_dir() and item.name.startswith("_"):
                for typ_file in item.rglob("*.typ"):
                    common_deps.append(typ_file)

    return common_deps


# ============================================================================
# 辅助函数
# ============================================================================


def find_typ_files() -> list[Path]:
    """
    查找 content/ 目录下所有 .typ 文件，排除路径中包含以下划线开头的目录的文件。

    返回:
        list[Path]: .typ 文件路径列表
    """
    typ_files = []
    for typ_file in CONTENT_DIR.rglob("*.typ"):
        # 检查路径中是否有以下划线开头的目录
        parts = typ_file.relative_to(CONTENT_DIR).parts
        if not any(part.startswith("_") for part in parts):
            typ_files.append(typ_file)
    return typ_files


def get_file_output_path(typ_file: Path, type: Literal["pdf", "html"]) -> Path:
    """
    获取 .typ 文件的输出路径。

    参数:
        typ_file: .typ 文件路径 (相对于 content/)

    返回:
        Path: 文件输出路径 (在 _site/ 目录下)
    """
    relative_path = typ_file.relative_to(CONTENT_DIR)
    return SITE_DIR / relative_path.with_suffix(f".{type}")


def get_page_path(typ_file: Path) -> str:
    """
    获取 .typ 文件对应的页面路径，作为 typst 的 `page-path` 输入。

    该值决定页面的规范链接（canonical URL），网页与演示文稿必须一致地使用它。

    参数:
        typ_file: .typ 文件路径

    返回:
        str: 站点内的页面路径，如 "Blog/hello"；首页返回空字符串
    """
    try:
        rel_path = typ_file.relative_to(CONTENT_DIR)
    except ValueError:
        return ""

    if rel_path.name == "index.typ":
        # index.typ 使用所在目录名作为路径
        # content/Blog/index.typ -> "Blog"
        # content/index.typ -> "" (Homepage)
        page_path = rel_path.parent.as_posix()
        return "" if page_path == "." else page_path

    # 普通页面使用文件名作为路径
    # content/about.typ -> "about"
    return rel_path.with_suffix("").as_posix()


def run_typst_command(args: list[str]) -> bool:
    """
    运行 typst 命令。

    参数:
        args: typst 命令参数列表

    返回:
        bool: 命令是否成功执行
    """
    try:
        result = subprocess.run(["typst"] + args, capture_output=True, text=True, encoding="utf-8")
        if result.returncode != 0:
            print(f"  ❌ Typst 错误: {result.stderr.strip()}")
            return False
        return True
    except FileNotFoundError:
        print("  ❌ 错误: 未找到 typst 命令。请确保已安装 Typst 并添加到 PATH 环境变量中。")
        print("  📝 安装说明: https://typst.app/open-source/#download")
        return False
    except Exception as e:
        print(f"  ❌ 执行 typst 命令时出错: {e}")
        return False


def get_font_args(ignore_system_fonts: bool = False) -> list[str]:
    """
    构建 typst 的字体参数。

    - `assets/` 一直作为字体目录，与既有构建保持一致；
    - `fonts/` 存放随仓库分发的中文字体（见 fonts/README.md）。CI 上没有任何
      中文字体，若不在构建时提供，TeX/Typst 会把中日韩字形画成空心方框；
    - `ignore_system_fonts=True` 时忽略系统字体，只使用随仓库分发的字体。
      幻灯片导出使用它，使同一份演示文稿在任何机器（本地 Windows 或 CI 的
      Linux）上都得到相同的分页与字形。

    参数:
        ignore_system_fonts: 是否忽略系统字体

    返回:
        list[str]: 要追加到 typst 命令中的字体参数
    """
    args = ["--font-path", str(ASSETS_DIR)]

    if FONT_DIR.exists():
        args += ["--font-path", str(FONT_DIR)]

    if ignore_system_fonts:
        args.append("--ignore-system-fonts")

    return args


# ============================================================================
# 幻灯片（Touying）导出
#
# 上游 touying-exporter 是一个 Python 包：它调用 typst 把演示文稿逐页导出为
# SVG，再用 impress.js 模板打包成单个 HTML 文件。本脚本不引入该依赖，而是
# 直接用命令行 typst 完成同样的事情：
#   1. `typst compile --format svg` 配合 `{p}` 输出模式得到每一页；
#   2. `typst eval`（旧版本回退到 `typst query`）读取 <pdfpc-file> 演讲者备注；
#   3. 用内置的 touying-exporter/template.html.j2 渲染 HTML。
# 好处是只用项目本来就需要的 typst 二进制，不会出现 typst-py 与本机 typst
# 版本不一致的问题。
# ============================================================================

# 源文件中的构建指令：`// build: slides` 强制导出演示文稿，`// build: page`
# 强制按普通网页编译，用于覆盖基于包导入的自动判定。
BUILD_DIRECTIVE_PATTERN = re.compile(r"^[ \t]*//[ \t]*build[ \t]*:[ \t]*(\w+)[ \t]*$", re.MULTILINE)

# 匹配 `#import "@preview/touying:0.6.1": *` 这类包导入；包名含 touying 即视为
# Touying 系主题（例如 modern-sysu-touying）。
TOUYING_IMPORT_PATTERN = re.compile(r"""#import[ \t]+["']@[^"'\s]*touying[^"'\s]*["']""")

# 上游模板中唯一的两处动态内容：幻灯片列表循环。
SLIDE_LOOP_PATTERN = re.compile(
    r"[ \t]*\{%[ \t]*for page_no in page_iter[ \t]*%\}.*?\{%[ \t]*endfor[ \t]*%\}",
    re.DOTALL,
)

# Typst 导出的 SVG 顶层尺寸，改为跟随容器，由 impress.js 负责缩放。
SLIDE_SVG_SIZE_PATTERN = re.compile(r'width="[0-9.]+pt" height="[0-9.]+pt"')

# Typst 把位图以 data URI 内嵌进 SVG（一篇 24 页的演示文稿因此接近 10 MB）。
# 导出时把图片提取成独立文件：HTML 只剩约十分之一，图片可被浏览器并行加载与
# 缓存，页面顶部的 impress.js 也就能在文档尚未下载完时尽快执行。
SLIDE_EMBEDDED_IMAGE_PATTERN = re.compile(
    r'(?P<attr>xlink:href|href)="data:image/(?P<kind>[a-zA-Z0-9.+-]+);base64,(?P<data>[^"]*)"'
)
SLIDE_IMAGE_DIR_NAME = "images"
SLIDE_IMAGE_FILE_PREFIX = "embed-"
SLIDE_IMAGE_EXTENSIONS = {
    "png": "png",
    "jpeg": "jpg",
    "jpg": "jpg",
    "gif": "gif",
    "webp": "webp",
    "bmp": "bmp",
    "tiff": "tiff",
    "svg+xml": "svg",
    "svg": "svg",
    "avif": "avif",
}

# 演示文稿左上角的返回链接样式。impress.js 会用 pointer-events 控制整页的交互，
# 因此这里必须显式打开 pointer-events，否则链接点不动。
DECK_BACK_LINK_CSS = (
    "      /* 返回列表页入口，见 touying-exporter/README.md */\n"
    "      a.deck-back-link {\n"
    "          position: fixed;\n"
    "          left: 12px;\n"
    "          top: 12px;\n"
    "          z-index: 20;\n"
    "          pointer-events: auto;\n"
    "          padding: 6px 12px;\n"
    "          border-radius: 6px;\n"
    "          background: rgba(0, 0, 0, 0.45);\n"
    "          color: rgb(255, 255, 255);\n"
    "          font: 14px/1.4 sans-serif;\n"
    "          text-decoration: none;\n"
    "          opacity: 0.4;\n"
    "          transition: opacity 0.2s;\n"
    "      }\n"
    "      a.deck-back-link:hover { opacity: 1 }\n"
    "      html:fullscreen a.deck-back-link { display: none }\n"
)

# 上游模板里 impress.js 用 `location.hash = ...` 记录当前页，每次翻页都会新增一条
# 历史记录；于是浏览器的「后退」只能退回上一张幻灯片，很难离开演示文稿。
# 改成 `location.replace`，URL 仍然显示当前页，但不再堆积历史记录。
DECK_HASH_ASSIGNMENT = 't.location.hash=e="#/"+n.target.id'
DECK_HASH_REPLACEMENT = 'e="#/"+n.target.id,t.location.replace(e)'

HEADER_LINKS_PATTERN = re.compile(r"header-links\s*:\s*\((.*?)\)\s*,", re.DOTALL)
HEADER_LINK_ENTRY_PATTERN = re.compile(r'"([^"]*)"\s*:\s*"([^"]*)"')


def read_typ_source(typ_file: Path) -> str:
    """
    读取 .typ 源文件内容，读取失败时返回空字符串。
    """
    try:
        return typ_file.read_text(encoding="utf-8")
    except OSError:
        return ""


def strip_raw_blocks(source: str) -> str:
    """
    移除 ```` ``` ```` 围栏代码块的内容（含围栏行本身）。

    幻灯片判定只应看到真实的包导入语句：讲解 Touying 的文章在示例代码里出现
    `#import "@preview/touying:..."` 时，该页面仍然是普通网页。
    """
    kept_lines = []
    in_fence = False
    for line in source.splitlines():
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            kept_lines.append(line)
    return "\n".join(kept_lines)


def get_build_directive(source: str) -> str | None:
    """
    读取源文件中的 `// build: <目标>` 指令，未声明时返回 None。
    """
    match = BUILD_DIRECTIVE_PATTERN.search(strip_raw_blocks(source))
    return None if match is None else match.group(1).lower()


def is_slide_source(typ_file: Path) -> bool:
    """
    判断 .typ 文件是否应导出为 HTML 演示文稿而不是普通网页。

    判定顺序:
        1. `// build: slides` 强制导出，`// build: page` 强制不导出；
        2. 源文件导入了名字含 `touying` 的 Typst 包。

    参数:
        typ_file: .typ 文件路径

    返回:
        bool: 是否应作为幻灯片导出
    """
    source = read_typ_source(typ_file)

    directive = get_build_directive(source)
    if directive == "slides":
        return True
    if directive == "page":
        return False

    return TOUYING_IMPORT_PATTERN.search(strip_raw_blocks(source)) is not None


def get_slide_files() -> list[Path]:
    """
    查找 content/ 下需要导出为 HTML 演示文稿的 .typ 文件。

    与网页构建保持一致：文件名中包含 "pdf" 的文件只编译为 PDF。

    返回:
        list[Path]: 演示文稿源文件路径列表
    """
    return [
        typ_file
        for typ_file in find_typ_files()
        if "pdf" not in typ_file.stem.lower() and is_slide_source(typ_file)
    ]


def get_slide_title(typ_file: Path) -> str:
    """
    由页面路径推出演示文稿的 <title>。

    上游模板把标题硬编码为 "Touying"，这里改用页面名，使其与网站目录结构
    （以及 RSS/Sitemap 中显示的名称）一致：
    `content/Slides/第一讲/index.typ` -> "第一讲"。

    参数:
        typ_file: .typ 文件路径

    返回:
        str: 演示文稿标题
    """
    try:
        rel_path = typ_file.relative_to(CONTENT_DIR)
    except ValueError:
        return typ_file.stem

    if rel_path.name == "index.typ" and rel_path.parent.name not in {"", "."}:
        return rel_path.parent.name
    return rel_path.stem


def resize_svg_page(svg: str) -> tuple[str, int]:
    """
    把 Typst 导出的 SVG 尺寸改为跟随容器，便于 impress.js 缩放。

    参数:
        svg: 单页 SVG 文本

    返回:
        tuple[str, int]: (处理后的 SVG, 成功替换的尺寸属性个数)
    """
    return SLIDE_SVG_SIZE_PATTERN.subn('width="100%" height="100%"', svg)


def read_svg_pages(pages_dir: Path) -> list[str]:
    """
    读取 Typst 以 `{p}` 模式导出的多页 SVG，按页码排序。

    参数:
        pages_dir: 存放 page-{p}.svg 的目录

    返回:
        list[str]: 按页码升序排列的 SVG 文本列表
    """
    page_files: list[tuple[int, Path]] = []
    for page_file in pages_dir.glob("page-*.svg"):
        match = re.fullmatch(r"page-(\d+)\.svg", page_file.name)
        if match is not None:
            page_files.append((int(match.group(1)), page_file))
    page_files.sort(key=lambda item: item[0])

    pages = []
    for page_no, page_file in page_files:
        svg, size_count = resize_svg_page(page_file.read_text(encoding="utf-8"))
        if size_count == 0:
            print(
                f"  ⚠️ 第 {page_no} 页 SVG 未找到 `width=\"…pt\" height=\"…pt\"`，"
                "可能无法自适应缩放。"
            )
        pages.append(svg)
    return pages


def query_slide_notes(typ_file: Path) -> dict[int, str]:
    """
    读取 Touying 演示文稿的演讲者备注。

    Touying 把备注写在 <pdfpc-file> 元数据中，键 `idx` 是 0 起始的物理页码。
    Typst 0.15 起 `typst query` 被标记为废弃，官方推荐 `typst eval`，因此这里
    优先使用 eval，失败时回退到 query 以兼容旧版本 Typst。

    参数:
        typ_file: .typ 文件路径

    返回:
        dict[int, str]: 页码 -> 备注文本；无备注或因故无法读取时返回空字典
    """
    # 必须与幻灯片本身使用相同的字体设置，否则分页可能与导出的页面不一致
    common_args = ["--root", ".", *get_font_args(ignore_system_fonts=True)]
    commands = [
        [
            "eval",
            "query(<pdfpc-file>).map(it => it.value)",
            *common_args,
            "--in",
            str(typ_file),
        ],
        [
            "query",
            *common_args,
            str(typ_file),
            "<pdfpc-file>",
            "--field",
            "value",
        ],
    ]

    for command in commands:
        try:
            result = subprocess.run(
                ["typst"] + command, capture_output=True, text=True, encoding="utf-8"
            )
        except (FileNotFoundError, OSError):
            return {}

        if result.returncode != 0 or not result.stdout.strip():
            continue

        try:
            values = json.loads(result.stdout)
        except json.JSONDecodeError:
            continue

        # 没有 <pdfpc-file> 标签时 query 返回空列表，说明该演示文稿没有备注
        if not isinstance(values, list) or not values:
            return {}

        pdfpc = values[0]
        if not isinstance(pdfpc, dict):
            return {}

        notes = {}
        for page in pdfpc.get("pages", []):
            if not isinstance(page, dict):
                continue
            page_no, note = page.get("idx"), page.get("note")
            if isinstance(page_no, int) and isinstance(note, str):
                notes[page_no] = note
        return notes

    print("  ⚠️ 读取 <pdfpc-file> 演讲者备注失败，本次导出不包含备注。")
    return {}


def extract_embedded_images(pages: list[str], images_dir: Path) -> list[str]:
    """
    把 SVG 中内嵌的 base64 位图提取为独立文件。

    Typst 的 SVG 导出会把位图以 data URI 内嵌，一篇含插图的演示文稿会因此膨胀
    到接近 10 MB，浏览器必须收完整个文档才会执行末尾的 `impress().init()`。
    提取成独立文件后：

    - HTML 体积降到约十分之一，初始化脚本能更早执行；
    - 多页复用的同一张图片只写出一份，并由浏览器缓存与并行加载。

    参数:
        pages: 各页 SVG 文本
        images_dir: 存放提取图片的目录

    返回:
        list[str]: 已经替换为相对路径的各页 SVG 文本
    """
    # 清理上次构建遗留的内嵌图片，避免演示文稿改动后留下孤儿文件
    if images_dir.is_dir():
        for stale in images_dir.glob(f"{SLIDE_IMAGE_FILE_PREFIX}*"):
            if stale.is_file():
                stale.unlink()

    written: dict[str, str] = {}
    result = []

    for page in pages:
        def replace(match: re.Match[str], written: dict[str, str] = written) -> str:
            kind = match.group("kind").lower()
            try:
                data = base64.b64decode(match.group("data"), validate=True)
            except (binascii.Error, ValueError):
                # 不是合法的 base64 就保持原样，交给浏览器处理
                return match.group(0)

            digest = hashlib.sha256(data).hexdigest()
            file_name = written.get(digest)
            if file_name is None:
                extension = SLIDE_IMAGE_EXTENSIONS.get(kind, kind if kind.isalnum() else "bin")
                file_name = f"{SLIDE_IMAGE_FILE_PREFIX}{digest[:16]}.{extension}"
                images_dir.mkdir(parents=True, exist_ok=True)
                (images_dir / file_name).write_bytes(data)
                written[digest] = file_name

            return f'{match.group("attr")}="{SLIDE_IMAGE_DIR_NAME}/{file_name}"'

        result.append(SLIDE_EMBEDDED_IMAGE_PATTERN.sub(replace, page))

    return result


def replace_once(text: str, old: str, new: str) -> str:
    """
    替换文本且要求 old 恰好出现一次。

    内置模板来自上游仓库，结构变化时立刻报错，避免静默产出错误的演示文稿。

    参数:
        text: 原文本
        old: 待替换的子串
        new: 替换后的子串

    返回:
        str: 替换结果
    """
    count = text.count(old)
    if count != 1:
        raise ValueError(f"内置模板结构已变化: 期望 1 处 {old!r}，实际 {count} 处")
    return text.replace(old, new, 1)


def get_site_lang() -> str:
    """
    读取站点语言（config.typ 中的 `lang: "zh"`）。

    演示文稿是网站的一部分，用站点语言声明 `<html lang>` 比上游模板硬编码的
    "en" 更准确。解析失败时回退到 "zh"。

    返回:
        str: 语言代码
    """
    try:
        content = CONFIG_FILE.read_text(encoding="utf-8")
    except OSError:
        return "zh"

    content = re.sub(r"//.*", "", content)
    match = re.search(r'^\s*lang\s*:\s*"([^"]*)"', content, re.MULTILINE)
    return match.group(1) if match is not None else "zh"


def get_header_links() -> dict[str, str]:
    """
    读取 config.typ 中顶部导航的 URL -> 显示名称映射。

    用于给演示文稿的返回链接取与导航栏一致的名称（例如 `/Notes/` -> `札记`）。

    返回:
        dict[str, str]: 页面路径 -> 显示名称
    """
    try:
        content = CONFIG_FILE.read_text(encoding="utf-8")
    except OSError:
        return {}

    content = re.sub(r"//.*", "", content)
    match = HEADER_LINKS_PATTERN.search(content)
    if match is None:
        return {}

    return {url: label for url, label in HEADER_LINK_ENTRY_PATTERN.findall(match.group(1))}


def get_deck_back_link(typ_file: Path) -> tuple[str, str]:
    """
    计算演示文稿「返回」链接的目标与文字。

    目标优先取页面上级目录里真实存在的列表页（`content/<父目录>/index.typ`），
    没有则回退到站点首页；文字取 config.typ 中 header-links 的显示名称。

    参数:
        typ_file: 演示文稿源文件路径

    返回:
        tuple[str, str]: (链接地址, 显示文字)
    """
    header_links = get_header_links()
    parent = Path(get_page_path(typ_file)).parent
    parent_path = parent.as_posix()

    if parent_path not in {"", "."} and (CONTENT_DIR / parent_path / "index.typ").exists():
        url = f"/{parent_path}/"
        return url, header_links.get(url, parent.name)

    return "/", header_links.get("/", "返回首页")


def render_slide_template(
    template: str,
    pages: list[str],
    notes: dict[int, str],
    title: str,
    lang: str,
    back_link: tuple[str, str],
) -> str:
    """
    把内置的 touying-exporter 模板渲染成完整的 HTML 演示文稿。

    上游模板是 Jinja2 模板，但动态内容只有「幻灯片列表」和「演讲者备注」两处，
    这里用等价的字符串替换完成渲染，从而让构建脚本只依赖标准库。

    参数:
        template: 模板原文
        pages: 按页码升序排列的 SVG 文本列表
        notes: 页码 -> 备注文本
        title: 演示文稿标题
        lang: 演示文稿的语言代码
        back_link: (链接地址, 显示文字)，指向进入演示文稿之前的列表页

    返回:
        str: 完整的 HTML 文档
    """
    steps = []
    for page_no, page in enumerate(pages):
        step_lines = [
            '    <div class="step slide">',
            f"      {page.strip()}",
        ]
        if note := notes.get(page_no):
            # 备注按纯文本插入，避免其中的 <、& 被当作标记解析
            step_lines.append(
                '      <div class="notes"><div style="white-space: pre-wrap;">'
                + html.escape(note)
                + "</div></div>"
            )
        step_lines.append("    </div>")
        steps.append("\n".join(step_lines))

    document = SLIDE_LOOP_PATTERN.sub("\n".join(steps), template)
    # {raw} 块只用于保护其后的压缩版 impress.js，替换模板标记后不再需要
    document = document.replace("{% raw %}", "").replace("{% endraw %}", "")
    if "{%" in document:
        raise ValueError("内置模板中仍有未处理的模板标记，请检查 template.html.j2")

    # 上游模板的提示条是「impress.js 初始化之前一直显示」，也就是整个文档下载完
    # 之前都会显示黄色提示条。改成默认隐藏，只有浏览器确实不支持时才显示。
    document = replace_once(
        document,
        "      .impress-supported .fallback-message {\n          display: none;\n      }\n",
        "      .fallback-message {\n"
        "          display: none;\n"
        "      }\n"
        "      .impress-not-supported .fallback-message {\n"
        "          display: block;\n"
        "      }\n",
    )
    # 配合上面的样式：先摘掉标记里的 impress-not-supported（它只服务于无
    # JavaScript 的场景），浏览器确实不支持时紧随其后的 impress.js 会加回来。
    document = replace_once(
        document,
        '<div class="fallback-message">\n'
        "    <p>Your browser <b>doesn't support the features required</b> by impress.js, so you are presented with a simplified version of this presentation.</p>\n"
        "    <p>For the best experience please use the latest <b>Chrome</b>, <b>Safari</b> or <b>Firefox</b> browser.</p>\n"
        "</div>",
        '<div class="fallback-message">\n'
        "    <p>Your browser <b>doesn't support the features required</b> by impress.js, so you are presented with a simplified version of this presentation.</p>\n"
        "    <p>For the best experience please use the latest <b>Chrome</b>, <b>Safari</b> or <b>Firefox</b> browser.</p>\n"
        "</div>\n"
        "<script>\n"
        '    document.body.classList.remove("impress-not-supported");\n'
        "</script>",
    )

    # 模板中的标题与作者是上游示例值，替换为本站信息
    document = replace_once(
        document, "<title>Touying</title>", f"<title>{html.escape(title)}</title>"
    )
    document = replace_once(
        document, '<meta name="description" content="Simple example touying slide show" />', ""
    )
    document = replace_once(document, '<meta name="author" content="OrangeX4" />', "")
    document = replace_once(document, '<html lang="en">', f'<html lang="{html.escape(lang)}">')

    # 返回列表页的链接与「后退键不再退回上一张幻灯片」
    back_url, back_label = back_link
    document = replace_once(
        document,
        "    </style>\n    \n</head>",
        DECK_BACK_LINK_CSS + "    </style>\n    \n</head>",
    )
    document = replace_once(
        document,
        '<body class="impress-not-supported">',
        '<body class="impress-not-supported">\n'
        f'<a class="deck-back-link" href="{html.escape(back_url, quote=True)}">'
        f"{html.escape(back_label)}</a>",
    )
    document = replace_once(document, DECK_HASH_ASSIGNMENT, DECK_HASH_REPLACEMENT)
    return document


def export_slide_deck(typ_file: Path, output_path: Path) -> bool:
    """
    把单个 .typ 文件导出为自包含的 HTML 演示文稿。

    参数:
        typ_file: .typ 文件路径
        output_path: 输出的 .html 文件路径

    返回:
        bool: 是否导出成功
    """
    try:
        template = SLIDE_TEMPLATE_FILE.read_text(encoding="utf-8")
    except OSError as e:
        print(f"  ❌ 无法读取内置幻灯片模板 {SLIDE_TEMPLATE_FILE}: {e}")
        return False

    with tempfile.TemporaryDirectory(prefix="touying-slides-") as temp_dir:
        pages_dir = Path(temp_dir) / "pages"
        pages_dir.mkdir()
        output_path.parent.mkdir(parents=True, exist_ok=True)

        compile_args = [
            "compile",
            "--root",
            ".",
            *get_font_args(ignore_system_fonts=True),
            "--format",
            "svg",
            "--input",
            f"page-path={get_page_path(typ_file)}",
            str(typ_file),
            str(pages_dir / "page-{p}.svg"),
        ]
        if not run_typst_command(compile_args):
            return False

        pages = read_svg_pages(pages_dir)
        if not pages:
            print(f"  ❌ 未导出任何幻灯片页面: {typ_file}")
            return False

        # 图片相对 HTML 引用，因此必须在生成 HTML 之前提取到输出目录
        pages = extract_embedded_images(pages, output_path.parent / SLIDE_IMAGE_DIR_NAME)

        try:
            document = render_slide_template(
                template,
                pages,
                query_slide_notes(typ_file),
                get_slide_title(typ_file),
                get_site_lang(),
                get_deck_back_link(typ_file),
            )
        except ValueError as e:
            print(f"  ❌ 渲染幻灯片失败: {e}")
            return False

        output_path.write_text(document, encoding="utf-8")

    return True


# ============================================================================
# 构建命令
# ============================================================================


def _compile_files(
    files: list[Path],
    force: bool,
    common_deps: list[Path],
    get_output_path_func,
    build_args_func=None,
    run_func=None,
) -> BuildStats:
    """
    通用文件编译函数，减少重复代码。

    参数:
        files: 要编译的文件列表
        force: 是否强制重建
        common_deps: 公共依赖列表
        get_output_path_func: 获取输出路径的函数
        build_args_func: 构建 typst 编译参数的函数（与 run_func 二选一）
        run_func: 自定义的执行函数 run_func(typ_file, output_path) -> bool，
            用于不走 `typst compile` 的构建流程（如幻灯片导出）

    返回:
        BuildStats: 构建统计信息
    """
    stats = BuildStats()

    for typ_file in files:
        output_path = get_output_path_func(typ_file)

        # 增量编译检查
        if not force and not needs_rebuild(typ_file, output_path, common_deps):
            stats.skipped += 1
            continue

        output_path.parent.mkdir(parents=True, exist_ok=True)

        if run_func is not None:
            compiled = run_func(typ_file, output_path)
        else:
            compiled = run_typst_command(build_args_func(typ_file, output_path))

        if compiled:
            stats.success += 1
        else:
            print(f"  ❌ {typ_file} 编译失败")
            stats.failed += 1

    return stats


def build_html(force: bool = False) -> bool:
    """
    编译所有 .typ 文件为 HTML。

    排除两类文件：文件名中包含 PDF 的（改为编译 PDF），以及使用 Touying 的
    演示文稿源文件（改为导出 HTML 幻灯片，见 build_slides）。

    参数:
        force: 是否强制重建所有文件
    """
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    typ_files = find_typ_files()

    # 排除标记为 PDF 的文件与演示文稿源文件
    html_files = [
        f for f in typ_files if "pdf" not in f.stem.lower() and not is_slide_source(f)
    ]

    if not html_files:
        print("  ⚠️ 未找到任何 HTML 文件。")
        return True

    print("正在构建 HTML 文件...")

    # 获取公共依赖
    common_deps = find_common_dependencies()

    def build_html_args(typ_file: Path, output_path: Path) -> list[str]:
        """构建 HTML 编译参数"""
        return [
            "compile",
            "--root",
            ".",
            *get_font_args(),
            "--features",
            "html",
            "--format",
            "html",
            "--input",
            f"page-path={get_page_path(typ_file)}",
            str(typ_file),
            str(output_path),
        ]

    stats = _compile_files(
        html_files,
        force,
        common_deps,
        lambda typ_file: get_file_output_path(typ_file, "html"),
        build_html_args,
    )

    print(f"✅ HTML 构建完成。{stats.format_summary()}")
    return not stats.has_failures


def build_pdf(force: bool = False) -> bool:
    """
    编译文件名包含 "PDF" 的 .typ 文件为 PDF。

    参数:
        force: 是否强制重建所有文件
    """
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    typ_files = find_typ_files()
    pdf_files = [f for f in typ_files if "pdf" in f.stem.lower()]

    if not pdf_files:
        return True

    print("正在构建 PDF 文件...")

    # 获取公共依赖
    common_deps = find_common_dependencies()

    def build_pdf_args(typ_file: Path, output_path: Path) -> list[str]:
        """构建 PDF 编译参数"""
        return [
            "compile",
            "--root",
            ".",
            *get_font_args(),
            str(typ_file),
            str(output_path),
        ]

    stats = _compile_files(
        pdf_files,
        force,
        common_deps,
        lambda typ_file: get_file_output_path(typ_file, "pdf"),
        build_pdf_args,
    )

    print(f"✅ PDF 构建完成。{stats.format_summary()}")
    return not stats.has_failures


def build_slides(force: bool = False) -> bool:
    """
    把 content/ 下使用 Touying 的 .typ 文件导出为 HTML 演示文稿。

    输出路径与普通网页一致（`content/Slides/第一讲/index.typ` ->
    `_site/Slides/第一讲/index.html`），因此演示文稿会进入 Sitemap，也可以
    被其他页面直接链接。

    参数:
        force: 是否强制重建所有文件
    """
    slide_files = get_slide_files()

    if not slide_files:
        return True

    SITE_DIR.mkdir(parents=True, exist_ok=True)
    print("正在构建 Touying 演示文稿...")

    # 公共依赖（config.typ 等）；内置模板与字体更新后所有演示文稿也需要重新生成
    extra_deps = find_common_dependencies()
    if SLIDE_TEMPLATE_FILE.exists():
        extra_deps = extra_deps + [SLIDE_TEMPLATE_FILE]
    if FONT_DIR.exists():
        extra_deps = extra_deps + [fontfile for fontfile in FONT_DIR.rglob("*") if fontfile.is_file()]

    stats = _compile_files(
        slide_files,
        force,
        extra_deps,
        lambda typ_file: get_file_output_path(typ_file, "html"),
        run_func=export_slide_deck,
    )

    print(f"✅ 演示文稿构建完成。{stats.format_summary()}")
    return not stats.has_failures


def copy_assets() -> bool:
    """
    复制静态资源到输出目录。
    """
    if not ASSETS_DIR.exists():
        print(f"  ⚠ 静态资源目录 {ASSETS_DIR} 不存在。")
        return True

    SITE_DIR.mkdir(parents=True, exist_ok=True)
    target_dir = SITE_DIR / "assets"

    try:
        if target_dir.exists():
            shutil.rmtree(target_dir)
        shutil.copytree(ASSETS_DIR, target_dir)
        return True
    except Exception as e:
        print(f"  ❌ 复制静态资源失败: {e}")
        return False


def copy_content_assets(force: bool = False) -> bool:
    """
    复制 content 目录下的非 .typ 文件（如图片）到输出目录。
    支持增量复制：只复制修改过的文件。

    参数:
        force: 是否强制复制所有文件
    """
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    if not CONTENT_DIR.exists():
        print(f"  ⚠ 内容目录 {CONTENT_DIR} 不存在，跳过。")
        return True

    try:
        copy_count = 0
        skip_count = 0

        for item in CONTENT_DIR.rglob("*"):
            # 跳过目录和 .typ 文件
            if item.is_dir() or item.suffix == ".typ":
                continue

            # 跳过以下划线开头的路径
            relative_path = item.relative_to(CONTENT_DIR)
            if any(part.startswith("_") for part in relative_path.parts):
                continue

            # 计算目标路径
            target_path = SITE_DIR / relative_path

            # 增量复制检查
            if not force and target_path.exists():
                if get_file_mtime(item) <= get_file_mtime(target_path):
                    skip_count += 1
                    continue

            # 创建目标目录
            target_path.parent.mkdir(parents=True, exist_ok=True)

            # 复制文件
            shutil.copy2(item, target_path)
            copy_count += 1

        return True
    except Exception as e:
        print(f"  ❌ 复制内容资源文件失败: {e}")
        return False


def clean() -> bool:
    """
    清理生成的文件。
    """
    print("正在清理生成的文件...")

    if not SITE_DIR.exists():
        print(f"  输出目录 {SITE_DIR} 不存在，无需清理。")
        return True

    try:
        # 删除 _site 目录下的所有内容
        for item in SITE_DIR.iterdir():
            if item.is_dir():
                shutil.rmtree(item)
            else:
                item.unlink()

        print(f"  ✅ 已清理 {SITE_DIR}/ 目录。")
        return True
    except Exception as e:
        print(f"  ❌ 清理失败: {e}")
        return False


def preview(port: int = 8000, open_browser_flag: bool = True) -> bool:
    """
    启动本地预览服务器。

    首先尝试使用 uvx livereload（支持实时刷新），
    如果失败则回退到 Python 内置的 http.server。

    参数:
        port: 服务器端口号，默认为 8000
        open_browser_flag: 是否自动打开浏览器，默认为 True
    """
    import webbrowser

    if not SITE_DIR.exists():
        print(f"  ⚠ 输出目录 {SITE_DIR} 不存在，请先运行 build 命令。")
        return False

    print("正在启动本地预览服务器（按 Ctrl+C 停止）...")
    print()

    if open_browser_flag:

        def open_browser():
            time.sleep(1.5)  # 等待服务器启动
            url = f"http://localhost:{port}"
            print(f"  🚀 正在打开浏览器: {url}")
            webbrowser.open(url)

        # 在后台线程中打开浏览器
        threading.Thread(target=open_browser, daemon=True).start()

    # 首先尝试 uvx livereload
    try:
        result = subprocess.run(
            ["uvx", "livereload", str(SITE_DIR), "-p", str(port)],
            check=False,
        )
        return result.returncode == 0
    except FileNotFoundError:
        print("  未找到 uv，尝试 Python http.server...")
    except KeyboardInterrupt:
        print("\n服务器已停止。")
        return True

    # 回退到 Python http.server
    try:
        print("使用 Python 内置 http.server...")
        result = subprocess.run(
            [sys.executable, "-m", "http.server", str(port), "--directory", str(SITE_DIR)],
            check=False,
        )
        return result.returncode == 0
    except KeyboardInterrupt:
        print("\n服务器已停止。")
        return True
    except Exception as e:
        print(f"  ❌ 启动服务器失败: {e}")
        return False


def parse_html_metadata(html_path: Path) -> dict[str, str]:
    """
    解析 HTML 文件并返回元数据解析器实例。

    参数:
        html_path (Path): HTML 文件路径

    返回:
        HTMLMetadataParser: 包含解析结果的解析器实例
    """
    parser = HTMLMetadataParser()
    parser.feed(html_path.read_text(encoding="utf-8"))
    return parser.metadata


def get_site_url() -> str | None:
    """
    从生成的首页 HTML 文件中解析站点 URL。

    功能:
        从 _site/index.html 的 <link rel="canonical" href="..."> 提取 site-url。

    返回:
        str: 站点的根 URL（如 "https://example.com"），末尾不带斜杠。
            如果未配置或解析失败则返回 None。
    """
    index_html = SITE_DIR / "index.html"
    parser = parse_html_metadata(index_html)

    if parser.get("link"):
        return parser["link"].rstrip("/")

    return None


def get_feed_dirs() -> set[str]:
    """
    从 config.typ 配置文件中解析 RSS Feed 订阅源的配置信息。

    功能:
        解析 config.typ 中的 feed 配置块，提取目录列表。

    返回:
        set[str]: 要包含的文章目录列表，默认为空集合
    """
    if not CONFIG_FILE.exists():
        return set()

    try:
        content = CONFIG_FILE.read_text(encoding="utf-8")

        # 移除注释
        content = re.sub(r"//.*", "", content)
        content = re.sub(r"/\*[\s\S]*?\*/", "", content)

        match = re.search(r"feed-dir\s*:\s*\((.*?)\)", content, re.DOTALL)
        if match:
            return set(
                c.strip("/") for c in re.findall(r'"([^"]*)"', match.group(1)) if c and c.strip("/")
            )
    except Exception as e:
        print(f"⚠️ 解析 feed-dir 失败: {e}")

    return set()


def extract_post_metadata(index_html: Path) -> tuple[str, str, str, datetime | None]:
    """
    从生成的 HTML 文件中提取文章的元数据信息。

    功能:
        提取文章元数据：
        1. 标题 (title): 从 <title> 标签提取
        2. 描述 (description): 从 <meta name="description"> 提取
        3. 链接 (link): 从 <link rel="canonical" href="..."> 提取
        4. 日期 (date): 依次尝试从以下来源获取：
            - HTML 中的 <meta name="date" content="...">
            - 文件夹名中的 YYYY-MM-DD 格式日期

    参数:
        index_html (Path): 文章的 index.html 文件路径

    返回:
        tuple[str, str, str, datetime | None]: 包含四个元素的元组：
            - str: 文章标题
            - str: 文章描述（可能为空字符串）
            - str: 文章链接（完整 URL）
            - datetime | None: 文章日期（带 UTC 时区），无法获取时为 None
    """
    parser = parse_html_metadata(index_html)

    title = parser["title"].strip()
    description = parser.get("description", "").strip()
    link = parser.get("link", "")
    date_obj = None

    # 尝试从 <meta name="date"> 解析日期
    if parser.get("date"):
        try:
            date_obj = datetime.strptime(parser["date"].split("T")[0], "%Y-%m-%d")
            date_obj = date_obj.replace(tzinfo=timezone.utc)
        except Exception:
            pass

    # 如果没找到日期，尝试从文件夹名提取 (YYYY-MM-DD)
    if not date_obj:
        date_match = re.search(r"(\d{4}-\d{2}-\d{2})", index_html.parent.name)
        if date_match:
            try:
                date_obj = datetime.strptime(date_match.group(1), "%Y-%m-%d")
                date_obj = date_obj.replace(tzinfo=timezone.utc)
            except ValueError:
                pass

    return title, description, link, date_obj


def collect_posts(dirs: set[str], site_url: str) -> list[dict]:
    """
    从指定的目录中收集所有文章的元数据。

    功能:
        遍历 _site 目录下指定目录中的所有子目录，提取每个文章的元数据信息。
        只处理目录（每个目录代表一篇文章），跳过普通文件。
        如果无法确定文章日期，则跳过该文章并输出警告。

    参数:
        dirs (set[str]): 要扫描的目录名称集合（如 {"Blog", "Docs"}）
        site_url (str): 站点的根 URL（如 "https://example.com"）

    返回:
        list[dict]: 文章数据字典列表，每个字典包含以下键：
            - title (str): 文章标题
            - description (str): 文章描述
            - dir (str): 文章所属分类（即目录名）
            - link (str): 文章的完整 URL
            - date (datetime): 文章日期对象（带时区）
    """
    posts = []

    for d in dirs:
        dir_path = SITE_DIR / d

        for item in dir_path.iterdir():
            if not item.is_dir():
                continue

            index_html = item / "index.html"
            if not index_html.exists():
                continue

            title, description, link, date_obj = extract_post_metadata(index_html)

            if not date_obj:
                print(f"⚠️ 无法确定文章 '{item.name}' 的日期，已跳过。")
                continue

            posts.append(
                {
                    "title": title,
                    "description": description,
                    "dir": d,
                    "link": link,
                    "date": date_obj,
                }
            )

    return posts


def build_rss_xml(posts: list[dict], config: dict) -> str:
    """
    构建符合 RSS 2.0 规范的 XML 内容字符串。

    功能:
        使用 Python 标准库 xml.etree.ElementTree 根据文章数据和站点配置生成完整的 RSS Feed XML。
        支持条件输出 description 标签（仅在有描述时输出）。

    参数:
        posts (list[dict]): 文章数据列表，每个字典应包含:
            - title: 标题
            - description: 描述（可选）
            - link: 文章链接
            - date: datetime 对象
            - dir: 分类名称 (即路径名)
        config (dict): 站点配置字典，应包含:
            - site_url: 站点根 URL
            - site_title: 站点标题
            - site_description: 站点描述
            - lang: 语言代码（如 "zh", "en"）

    返回:
        str: 完整的 RSS 2.0 XML 字符串，包含 XML 声明和所有必要的命名空间。
    """
    import xml.etree.ElementTree as ET
    from email.utils import format_datetime

    # 注册 atom 命名空间前缀
    ATOM_NS = "http://www.w3.org/2005/Atom"
    ET.register_namespace("atom", ATOM_NS)

    # 创建 RSS 根元素（命名空间声明由 register_namespace 自动处理）
    rss = ET.Element("rss", version="2.0")

    # Channel 元数据
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = config["site_title"]
    ET.SubElement(channel, "link").text = config["site_url"]
    ET.SubElement(channel, "description").text = config["site_description"]
    ET.SubElement(channel, "language").text = config["lang"]
    ET.SubElement(channel, "lastBuildDate").text = format_datetime(datetime.now(timezone.utc))

    # 添加 atom:link 自链接
    atom_link = ET.SubElement(channel, f"{{{ATOM_NS}}}link")
    atom_link.set("href", f"{config['site_url']}/feed.xml")
    atom_link.set("rel", "self")
    atom_link.set("type", "application/rss+xml")

    # 添加文章条目
    for post in posts:
        item = ET.SubElement(channel, "item")

        ET.SubElement(item, "title").text = post["title"]
        ET.SubElement(item, "link").text = post["link"]
        ET.SubElement(item, "guid", isPermaLink="true").text = post["link"]
        ET.SubElement(item, "pubDate").text = format_datetime(post["date"])
        ET.SubElement(item, "category").text = post["dir"]

        # 仅在有描述时添加
        if des := post["description"]:
            ET.SubElement(item, "description").text = des

    # 生成 XML 字符串
    ET.indent(rss, space="  ")
    xml_str = ET.tostring(rss, encoding="unicode", xml_declaration=False)

    return f'<?xml version="1.0" encoding="UTF-8"?>\n{xml_str}'


def generate_rss(site_url: str) -> bool:
    """
    生成网站的 RSS 订阅源文件。

    功能:
        完整的 RSS Feed 生成流程：
        1. 从 config.typ 读取目标目录（分类）
        2. 收集指定目录下的所有文章元数据
        3. 按日期排序
        4. 构建 RSS XML 并写入文件

    返回:
        bool: 生成是否成功。在以下情况返回 True：
            - 成功生成 RSS 文件
            - 未找到任何分类目录（跳过生成）
            - 未找到任何文章（生成空 Feed）
        仅在发生异常时返回 False。
    """
    rss_file = SITE_DIR / "feed.xml"
    dirs = get_feed_dirs()

    if not dirs:
        print("⚠️ 跳过 RSS 订阅源生成: 未配置任何目录。")
        return True

    # 检查是否至少有一个目录存在
    existing = {d for d in dirs if (SITE_DIR / d).exists()}
    missing = dirs - existing

    for d in missing:
        print(f"⚠️ 警告: 配置的目录 '{d}' 不存在。")

    if not existing:
        print("⚠️ 跳过 RSS 订阅源生成: 配置的目录都不存在。")
        return True

    # 收集文章
    posts = collect_posts(existing, site_url)

    if not posts:
        print("⚠️ 未找到任何文章，RSS 订阅源为空。")
        return True

    # 按日期降序排序
    posts = sorted(posts, key=lambda x: x["date"], reverse=True)

    # 获取配置信息
    index_html = SITE_DIR / "index.html"
    parser = parse_html_metadata(index_html)

    lang = parser["lang"]
    site_title = parser["title"].strip()
    site_description = parser.get("description", "").strip()

    config = {
        "site_url": site_url,
        "site_title": site_title,
        "site_description": site_description,
        "lang": lang,
    }

    # 构建 RSS XML
    try:
        rss_content = build_rss_xml(posts, config)
        rss_file.write_text(rss_content, encoding="utf-8")
        print(f"✅ RSS 订阅源生成成功: {rss_file} ({len(posts)} 篇文章)")
        return True
    except ValueError as e:
        print("❌ 错误: RSS 订阅源生成失败")
        print(f"   原因: feedgen 库报错 - {e}")
        print("   解决: 请检查 config.typ 中的必需配置字段（title 和 description）")
        return False
    except Exception as e:
        print("❌ 错误: 生成 RSS 订阅源时出错")
        print(f"   异常: {type(e).__name__}: {e}")
        return False


def generate_sitemap(site_url: str) -> bool:
    """
    使用 Python 标准库 xml.etree.ElementTree 生成 sitemap.xml。
    """
    import xml.etree.ElementTree as ET

    sitemap_path = SITE_DIR / "sitemap.xml"
    sitemap_ns = "http://www.sitemaps.org/schemas/sitemap/0.9"

    # 注册默认命名空间
    ET.register_namespace("", sitemap_ns)

    # 创建根元素
    urlset = ET.Element("urlset", xmlns=sitemap_ns)

    # 遍历 _site 目录
    for file_path in sorted(SITE_DIR.rglob("*.html")):
        rel_path = file_path.relative_to(SITE_DIR).as_posix()

        # 确定 URL 路径
        if rel_path == "index.html":
            url_path = ""
        elif rel_path.endswith("/index.html"):
            url_path = rel_path.removesuffix("index.html")
        elif rel_path.endswith(".html"):
            url_path = rel_path.removesuffix(".html") + "/"
        else:
            url_path = rel_path

        full_url = f"{site_url}/{url_path}"

        # 获取最后修改时间
        mtime = file_path.stat().st_mtime
        lastmod = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d")

        # 创建 url 元素
        url_elem = ET.SubElement(urlset, "url")
        ET.SubElement(url_elem, "loc").text = full_url
        ET.SubElement(url_elem, "lastmod").text = lastmod

    # 生成 XML 字符串
    ET.indent(urlset, space="  ")
    xml_str = ET.tostring(urlset, encoding="unicode", xml_declaration=False)
    sitemap_content = f'<?xml version="1.0" encoding="UTF-8"?>\n{xml_str}'

    try:
        sitemap_path.write_text(sitemap_content, encoding="utf-8")
        print(f"✅ Sitemap 构建完成: 包含 {len(urlset)} 个页面")
        return True
    except Exception as e:
        print(f"❌ Sitemap 构建失败: {e}")
        return False


def generate_robots_txt(site_url: str) -> bool:
    """
    Generate robots.txt pointing to the sitemap.
    """
    robots_content = f"""User-agent: *
Allow: /

Sitemap: {site_url}/sitemap.xml
"""

    try:
        (SITE_DIR / "robots.txt").write_text(robots_content, encoding="utf-8")
        return True
    except Exception as e:
        print(f"❌ 生成 robots.txt 失败: {e}")
        return False


def build(force: bool = False) -> bool:
    """
    完整构建：HTML + 演示文稿 + PDF + 资源。

    参数:
        force: 是否强制重建所有文件
    """
    print("-" * 60)
    if force:
        clean()
        print("🛠️ 开始完整构建...")
    else:
        print("🚀 开始增量构建...")
    print("-" * 60)

    # 确保输出目录存在
    SITE_DIR.mkdir(parents=True, exist_ok=True)

    results = []

    print()
    results.append(build_html(force))
    results.append(build_slides(force))
    results.append(build_pdf(force))
    print()

    results.append(copy_assets())
    results.append(copy_content_assets(force))

    if site_url := get_site_url():
        results.append(generate_sitemap(site_url))
        results.append(generate_robots_txt(site_url))
        results.append(generate_rss(site_url))

    print("-" * 60)
    if all(results):
        print("✅ 所有构建任务完成！")
        print(f"  📂 输出目录: {SITE_DIR.absolute()}")
    else:
        print("⚠ 构建完成，但有部分任务失败。")
    print("-" * 60)

    return all(results)


# ============================================================================
# 命令行接口
# ============================================================================


def create_parser() -> argparse.ArgumentParser:
    """
    创建命令行参数解析器。
    """
    parser = argparse.ArgumentParser(
        prog="build.py",
        description="Tufted Blog Template 构建脚本 - 将 content 中的 Typst 文件编译为 HTML、演示文稿和 PDF",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
构建脚本默认只重新编译修改过的文件，可使用 -f/--force 选项强制完整重建：
    uv run build.py build --force
    或 python build.py build -f

使用 Touying 编写的幻灯片会导出为自包含的 HTML 演示文稿，详见
touying-exporter/README.md：
    uv run build.py slides

使用 preview 命令启动本地预览服务器：
    uv run build.py preview
    或 python build.py preview -p 3000  # 使用自定义端口

更多信息请参阅 README.md
""",
    )

    subparsers = parser.add_subparsers(dest="command", title="可用命令", metavar="<command>")

    build_parser = subparsers.add_parser("build", help="完整构建 (HTML + 演示文稿 + PDF + 资源)")
    build_parser.add_argument("-f", "--force", action="store_true", help="强制完整重建")

    html_parser = subparsers.add_parser("html", help="仅构建 HTML 文件")
    html_parser.add_argument("-f", "--force", action="store_true", help="强制完整重建")

    slides_parser = subparsers.add_parser(
        "slides", help="仅构建 Touying 幻灯片 (导出为 HTML 演示文稿)"
    )
    slides_parser.add_argument("-f", "--force", action="store_true", help="强制完整重建")

    pdf_parser = subparsers.add_parser("pdf", help="仅构建 PDF 文件")
    pdf_parser.add_argument("-f", "--force", action="store_true", help="强制完整重建")

    subparsers.add_parser("assets", help="仅复制静态资源")
    subparsers.add_parser("clean", help="清理生成的文件")

    preview_parser = subparsers.add_parser("preview", help="启动本地预览服务器")
    preview_parser.add_argument(
        "-p", "--port", type=int, default=8000, help="服务器端口号（默认: 8000）"
    )
    preview_parser.add_argument(
        "--no-open", action="store_false", dest="open_browser", help="不自动打开浏览器"
    )
    preview_parser.set_defaults(open_browser=True)

    return parser


if __name__ == "__main__":
    parser = create_parser()
    args = parser.parse_args()

    if args.command is None:
        parser.print_help()
        sys.exit(0)

    # 确保在项目根目录运行
    script_dir = Path(__file__).parent.absolute()
    os.chdir(script_dir)

    if args.command in {"build", "html", "slides", "pdf"}:
        warn_if_typst_version_is_outdated()

    # 获取 force 参数
    force = getattr(args, "force", False)

    # 使用 match-case 执行对应的命令
    match args.command:
        case "build":
            success = build(force)
        case "html":
            success = build_html(force)
        case "slides":
            success = build_slides(force)
        case "pdf":
            success = build_pdf(force)
        case "assets":
            success = copy_assets()
        case "clean":
            success = clean()
        case "preview":
            success = preview(getattr(args, "port", 8000), getattr(args, "open_browser", True))
        case _:
            print(f"❌ 未知命令: {args.command}")
            success = False

    sys.exit(0 if success else 1)

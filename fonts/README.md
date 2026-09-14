# 构建字体

本目录存放**构建时**使用的中文字体。它们不随网站发布（不会出现在 `_site/`），
只在 typst 编译时被读取，字形会被烘焙进 SVG/PDF。

## 为什么需要它

GitHub Actions 的 ubuntu-latest 运行器**没有任何中文字体**。演示文稿（以及所有
需要 Typst 绘图的中文内容）在 CI 上编译时，中日韩字形会全部退化成空心方框；
本地 Windows/macOS 因为有系统中文字体，看起来一切正常 —— 于是出现「本地预览
没问题，部署到网站变成方块」的现象。

把字体放进仓库，构建时通过 `--font-path fonts` 提供，CI 与本地就能得到相同的
结果。幻灯片导出还会加上 `--ignore-system-fonts`，只使用这里的字体，从而保证
同一份 `.typ` 在任何机器上分页与字形完全一致。

> 若某份演示文稿需要其它字体（例如你自己安装的字体），把字体文件（`.ttf` /
> `.otf` / `.ttc`）放进本目录即可，构建时会一并加载。

## 内置字体

| 文件 | 字体族 | 字重 | 来源 | 许可证 |
| --- | --- | --- | --- | --- |
| `NotoSerifSC-Regular.otf` | Noto Serif SC | 400 | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) `Serif/SubsetOTF/SC/NotoSerifSC-Regular.otf` | SIL Open Font License 1.1（见 [LICENSE](LICENSE)） |
| `NotoSerifSC-Bold.otf` | Noto Serif SC | 700 | [notofonts/noto-cjk](https://github.com/notofonts/noto-cjk) `Serif/SubsetOTF/SC/NotoSerifSC-Bold.otf` | SIL Open Font License 1.1（见 [LICENSE](LICENSE)） |
| `LICENSE` | — | — | [google/fonts](https://github.com/google/fonts) `ofl/notoserifsc/OFL.txt` | SIL Open Font License 1.1 |

2026-09-14 下载时的校验和（`Get-FileHash <文件> -Algorithm SHA256`）：

```
NotoSerifSC-Regular.otf   11625800 bytes  e8f396decc1f0963a016a989c3d8852e863d1350996f573860a80767c83a1cd3
NotoSerifSC-Bold.otf      12094336 bytes  24693d48bdb9152f0a06b02af625638a1097abd6de4010ebba027f6e82710527
LICENSE                       4350 bytes  5e0da210fb04058a8c0087985d2d456b931c2579811a49655721d3cf0c36b6d6
```

（更新字体时请用 `Get-FileHash <文件> -Algorithm SHA256` / `sha256sum <文件>`
重新生成上面的校验和。）

Noto Serif SC 是思源宋体的简体中文子集版本，字形风格接近本地 Windows 默认用于
中文的宋体，因此本地与线上观感一致，且覆盖常用及生僻汉字。

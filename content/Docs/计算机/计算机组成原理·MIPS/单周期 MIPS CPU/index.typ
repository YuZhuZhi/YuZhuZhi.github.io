#import "../../../../index.typ": template, tufted
#show: template.with(
  title: "单周期 MIPS CPU：从指令编码到完整数据通路",
  description: "以 15 条精简 MIPS 指令为边界，重新组织单周期 CPU 的指令格式、控制、数据通路、Verilog 实现与验证。",
)

= 单周期 MIPS CPU：从指令编码到完整数据通路

本文重写自 2023 年课程实验报告，但目标不是复刻一份“模块代码清单”，而是回答一个更便于复核的问题：*一条 32 位指令进入处理器以后，哪些值沿什么路径移动，哪些状态在时钟边沿被提交？* 原始报告与工程代码仍可在 #link("https://github.com/YuZhuZhi/SYSUComputerComposition/blob/master/第五次实验报告.md")[SYSUComputerComposition] 中查阅。

#tufted.remark[讨论边界][本文描述的是实验中实现的 32 位、非流水、精简 MIPS 数据通路，不是完整的 MIPS32 处理器。它没有异常、延迟槽、乘除法、协处理器与缓存；`halt` 也是实验自定义指令。文中会把“设计意图”“原工程的实际行为”和“更稳健的写法”分开。]

#html.hr()
= 一、先固定 ISA：硬件只是在实现约定

处理器设计的第一个稳定对象不是 ALU，也不是 Verilog 模块，而是指令集体系结构（Instruction Set Architecture, ISA）。本实验选取 15 条指令：六条 R 型运算、三条 I 型运算、两条访存、两条条件分支、一条跳转和一条停止指令。

#figure(
  image("images/instruction-formats.svg", width: 100%, alt: "实验 MIPS 指令的 R 型、I 型与 J 型字段划分"),
  caption: [三类指令均为 32 位。颜色表示字段职责，而不是电路模块；同一位段在不同指令族中可以承担不同语义。图由 `rivet` 生成。],
)

原报告把寄存器助记符改写为 `src1`、`src2` 与 `tar`，目的是让读写方向直接出现在名称中。这个约定也改变了传统教材中 `rt` 的叙述方式：对 `addi`、`andi`、`ori` 与 `lw`，`[20:16]` 是目标寄存器；对 `beq` 与 `sw`，同一字段却是第二源寄存器。控制器必须按 `opcode` 解释字段，不能脱离指令类型谈“第几个寄存器字段”。

#table(
  columns: (auto, 1fr, auto, auto),
  inset: 6pt,
  align: (left, left, center, center),
  table.header([类别], [指令], [`opcode`], [`funct`]),
  [R 型], [`add sub and or slt sll`], [`000000`], [`100000 100010 100100 100101 101010 000000`],
  [I 型运算], [`addi andi ori`], [`001000 001100 001101`], [—],
  [访存], [`lw sw`], [`100011 101011`], [—],
  [分支], [`beq bgtz`], [`000100 000111`], [—],
  [跳转 / 停止], [`j halt`], [`000010 111111`], [—],
)

== 1. 三种下一 PC

顺序执行、条件分支与无条件跳转分别产生三个候选地址：

$
  "PC"_("seq") &= "PC" + 4, \\
  "PC"_("branch") &= "PC" + 4 + ("sext"("imm"_(16)) << 2), \\
  "PC"_("jump") &= {("PC"+4)_(31:28), "target"_(25:0), 00_2}.
$

分支立即数以“指令字”为单位，因此左移 2 位以后才成为字节偏移。跳转地址则保留 `PC+4` 的高 4 位，并把 26 位目标字段左移 2 位。`Next-PC logic` 的职责不是计算任意地址，而是在这三个候选值中按照 `Jump`、`Branch` 和比较结果作出唯一选择。

== 2. 立即数扩展不是统一动作

`addi`、`lw`、`sw` 与分支位移使用符号扩展；标准 MIPS 中 `andi`、`ori` 使用零扩展。这一区分决定高 16 位究竟复制 `imm[15]` 还是全部填零。原工程的 `SignExtend` 对所有 I 型指令都执行符号扩展，所以当 `andi/ori` 的立即数最高位为 1 时，它与标准 MIPS 语义不同。

#tufted.definition[提交（commit）][本文把“提交”定义为处理器体系结构状态发生不可撤销的更新：PC 更新、寄存器写入或数据存储器写入。单周期数据通路中的组合信号可以在周期内多次变化；只有边沿触发的提交才构成一条指令的可观察结果。]

#html.hr()
= 二、单周期数据通路

#tufted.full-width[
  #figure(
    image("images/single-cycle-datapath.svg", width: 100%, alt: "单周期 MIPS CPU 的模块级数据通路"),
    caption: [粗线表示 32 位数据总线，细线与控制总线决定多选器、寄存器写使能和存储器写使能。图只保留决定数据流的接口，省略开发板外设。],
  )
]

每个周期开始时，PC 给出取指地址。指令存储器输出的字段同时进入控制器、寄存器堆和立即数扩展单元；寄存器读口与扩展立即数在 ALU 前汇合。ALU 结果一方面可以成为访存地址，另一方面可以直接写回；`lw` 则从数据存储器取得写回值。与此同时，下一 PC 逻辑并行计算顺序、分支与跳转地址。时钟边沿到来时，PC、寄存器堆和数据存储器按各自写使能提交结果。

这意味着单周期的时钟周期 $T_("clk")$ 必须覆盖最慢指令的最长组合路径。以 `lw` 为例：

$
  T_("clk") >= t_("PC") + t_("IM") + t_("RF") + t_("ALU") + t_("DM") + t_("mux") + t_("setup").
$

`add` 不需要数据存储器，`j` 甚至不需要寄存器堆与通用 ALU，但它们仍要等待同一个周期结束。单周期的“简单”来自每条指令只提交一次，不来自硬件延迟较小。

== 1. 控制信号应表达选择，不应承担数据

原工程让 `Control` 直接输出读写寄存器编号和四位 `ALUControl`，从而省去传统数据通路中的目标寄存器多选器。对本实验的固定 ISA，这种集中译码可以工作；代价是控制器同时知道编码细节与数据通路布线，扩展指令时耦合较强。

#table(
  columns: (auto, 1fr, 1fr),
  inset: 6pt,
  table.header([信号], [为 0 时], [为 1 时]),
  [`ALUSrc`], [ALU 第二输入取扩展立即数], [取寄存器第二读口（原工程的极性）],
  [`MemtoReg`], [写回 ALU 结果], [写回存储器读数],
  [`RegWrite`], [寄存器状态不变], [在写回边沿更新目标寄存器],
  [`MemWrite`], [数据存储器状态不变], [在存储器边沿写入一个字],
  [`Jump`], [保留分支/顺序候选], [选择 J 型目标地址],
  [`Branch`], [选择顺序地址], [条件成立时选择分支地址],
  [`Halt`], [PC 正常更新], [保持 PC，从体系结构层面停机],
)

ALU 控制码采用 `0000` 与、`0001` 或、`0010` 加、`0110` 减、`0111` 小于置位、`1100` 左移。加法同时服务于算术、有效地址与地址生成；减法同时服务于 `sub` 和相等比较。复用相同运算语义比复用模块名称更重要。

== 2. 最小、完整的组合逻辑

组合模块应对所有输入给出确定输出，并使用 `always_comb` 或连续赋值表达。下面是比原始实现更稳健的 ALU 骨架：

```verilog
always_comb begin
    result = 32'b0;
    unique case (alu_control)
        4'b0000: result = src1 & src2;
        4'b0001: result = src1 | src2;
        4'b0010: result = src1 + src2;
        4'b0110: result = src1 - src2;
        4'b0111: result = ($signed(src1) < $signed(src2));
        4'b1100: result = src1 << shamt;
        default: illegal_alu_control = 1'b1;
    endcase
end

assign zero = (result == 32'b0);
```

这里显式使用 `$signed`，否则 Verilog 的无符号向量比较实现的是 `sltu` 而非 `slt`。非法控制码也不应输出高阻 `z`：FPGA 内部三态通常会被综合为逻辑，并会在仿真中传播未知状态。确定的缺省值配合错误标志更容易验证。

== 3. 时序状态与不变量

寄存器堆应维持两个不变量：零号寄存器永远读出 0；任一周期至多写一个非零寄存器。原报告使用下降沿写寄存器与存储器、上升沿更新 PC，以在一个较慢的实验时钟内错开动作。这个安排可以用于教学板验证，但真正决定正确性的仍应是同步时序约束，而不是“仿真波形看起来错开了”。

```verilog
always_ff @(posedge clk) begin
    if (reset) begin
        pc <= 32'b0;
    end else if (!halt) begin
        pc <= next_pc;
    end

    if (reg_write && (write_addr != 5'd0))
        regs[write_addr] <= write_data;
end

assign read_data1 = (read_addr1 == 0) ? 32'b0 : regs[read_addr1];
```

#html.hr()
= 三、用冒泡排序贯穿数据通路

实验目标是输入十个数并按降序排序。程序把数组首地址放在 `$a0`，外层计数放在 `$t2`，内层游标放在 `$a1`；`lw` 读取相邻元素，`slt` 判断前一项是否小于后一项，必要时用两条 `sw` 交换。

```text
inner_loop:
    sub  $t7, $t0, $t2
    beq  $t1, $t7, done_inner_loop
    lw   $t3, 0($a1)
    lw   $t4, 4($a1)
    slt  $t8, $t3, $t4
    beq  $t8, $zero, no_swap
    sw   $t4, 0($a1)
    sw   $t3, 4($a1)
no_swap:
    addi $a1, $a1, 4
    addi $t1, $t1, 1
    j    inner_loop
```

这段程序覆盖了数据通路中最关键的闭环：`lw → slt → beq → sw → addi → j`。只验证最后十个数有序仍不充分，因为错误的排序程序或偶然初值也可能产生同样结果。更可靠的验证同时检查：PC 序列、每条指令的译码、写回地址与数据、存储器写地址与数据，以及 `halt` 后状态保持。

#figure(
  image("images/sort-waveform.png", width: 92%, alt: "单周期 CPU 运行冒泡排序后的 Vivado 仿真波形"),
  caption: [原实验的整体验证波形。它证明该测试输入在该工程配置下得到有序结果，但不能替代逐指令断言和边界测试。],
)

== 1. 建议的自检式验证

```verilog
always_ff @(posedge clk) begin
    assert (regs[0] == 32'b0);
    if (halt) begin
        assert ($stable(pc));
        assert (!reg_write && !mem_write);
    end
end
```

还应分别构造以下测试：立即数为 `16'h8000` 的 `andi/ori`，负数参与的 `slt`，`beq` 成立与不成立，`bgtz` 的负、零、正三种输入，以及数组已经有序、逆序和含重复值三种情况。

#html.hr()
= 四、原工程中需要明确的边界

#tufted.remark[已知语义偏差][原工程对 `andi/ori` 使用符号扩展；`slt` 的输入未声明为有符号数；`bgtz` 与 `beq` 共用相等标志，因此现有组合实际上不能正确表达“严格大于零”。冒泡排序程序没有使用 `bgtz`，所以整体排序通过不能覆盖这些问题。]

此外，`always @(Instruct)` 应改为 `always_comb`，时序块应统一使用非阻塞赋值 `<=`，指令存储器中的绝对 `$readmemb` 路径应改成工程相对路径或参数。`reg [31:0] Reg [1:31]` 也不应再初始化索引 0；更清楚的写法是声明 `[0:31]` 并硬连零号寄存器的读值与写保护。

这些修改并不否定原实验的教学价值。相反，它们揭示了 CPU 实验真正值得保留的部分：一条指令的正确性不是由某个模块单独决定，而是由编码、组合路径、写使能、边沿与验证共同决定。

#html.hr()
= 五、从单周期走向多周期

单周期实现已经给出完整的指令级数据依赖，但它让所有指令服从 `lw` 的最长路径。下一篇将把一次提交拆成 IF、ID、EXE、MEM 与 WB 五类阶段，并检查“加入阶段计数器”是否足以构成严格意义上的多周期处理器。

本文的四幅核心图稿均以 Typst 保存；指令格式使用 #link("https://git.kb28.ch/HEL/rivet-typst")[rivet]，数据通路使用 #link("https://git.kb28.ch/HEL/circuiteria")[circuiteria]。

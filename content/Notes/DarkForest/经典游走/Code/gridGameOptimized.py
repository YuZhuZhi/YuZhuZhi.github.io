#!/usr/bin/env python3
"""回合制网格淘汰游戏：联合状态枚举 + 稀疏吸收链（浮点数值计算）。

Python >= 3.10。安装：python -m pip install numpy scipy tqdm
创建输入示例：python gridGameOptimized.py --init demo
计算：python gridGameOptimized.py --map demo/map.txt --config demo/config.json --rounds 50
不传地图时运行内置示例。函数、变量、参数名使用小驼峰。

地图：# 障碍；. 空地；A-Z/a-z/0-9 为唯一角色标签。行内空白忽略。
外部边界自动不可通行；允许矩形地图；空行忽略；不可用 # 写注释。
坐标从 0 起，row 向下、col 向右。初始角色按标签排序，可用 turnOrder 覆盖。
对决暂停移动、不消耗额外回合；胜者占相遇格；轮到死者时跳过。
若被攻击的角色尚未行动且获胜，本回合仍有自己的行动。
只剩一人立即停止，包括后续回合；无胜负历史、血量等隐藏状态。

输出 endProbabilities.csv: 恰在本回合结束、累计结束、仍未结束概率。
输出 positionProbabilities.csv: 回合末各角色在各格的无条件概率及存活概率。
淘汰角色无位置；已结束路径将胜者冻结；位置概率之和等于存活概率。
输出 encounterProbabilities.csv: 本回合每个方格至少相遇一次的概率。
输出 roundEncounterProbabilities.csv: 本回合任意位置至少相遇一次的概率。
相遇记录在移动进入占用格时、对决前；同格重复相遇仅计一次事件。
输出 survivalProbabilities.csv: 各角色回合末存活、淘汰及仍在游戏中的概率。
输出 summary.json: 期望回合数、各角色存活期望及计算方法。
--method exact: 完整枚举，按存活集合分块、缓存 LU；适合小地图。
--method simulate: NumPy 批量模拟；适合当前 200 格/7 人地图。
--method auto（默认）: 状态组合上界超过 maxStates 时选择模拟。
模拟增加概率标准误；有未结束样本时，报告截断期望而不冒充完整期望。
默认模拟 10000 局，每局上限 5000 回合，可用 --samples/--maxSimulationRounds 调整。
精确枚举、子对局求解、模拟和导出均使用 tqdm；--noProgress 关闭。
各角色 expectedActiveRounds 为游戏结束前进入回合时仍存活的回合数期望。
淘汰/结束所在回合计入；初始只有一人时为 0。
expectedRoundsUntilElimination 为首次淘汰回合的期望，永不淘汰则无穷。
精确模式 null 配合 IsInfinite=true 表示无穷大。
模拟模式 null/IsInfinite=null 也可能表示尚不能判断或完整期望被截断；见 notes。
精确模式期望来自分块线性方程；模拟模式明确标记样本均值与截断情况。
默认移动为上/下/左/右/停各 1，默认双方胜率 0.5。
pairWinProb 中 A:B 表示 A 对 B 获胜概率，与谁主动移动无关。
所有参数时间不变、位置无关，选择在合法方向中重新归一化。
"""

import argparse
import csv
import json
import math
import string
from collections import defaultdict, deque
from pathlib import Path
from tqdm.auto import tqdm


demoMap = """
......6........
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
.....3.........
"""
demoConfig = {
    "turnOrder": ["1", "2", "3", "4", "5", "6", "7"],
    "defaultMoveWeights": {"up": 1, "down": 1, "left": 1, "right": 1, "stay": 1},
    # "moveWeights": {"A": {"right": 2, "stay": 0.5}},
    "defaultWinProb": 0.5,
    # "pairWinProb": {"A:B": 0.6, "A:C": 0.5, "B:C": 0.4},
}
directionOffsets = {"up": (-1, 0), "down": (1, 0), "left": (0, -1),
                    "right": (0, 1), "stay": (0, 0)}


def readMap(mapText):
    rows = ["".join(line.split()) for line in mapText.splitlines() if line.strip()]
    if not rows or not rows[0] or any(len(row) != len(rows[0]) for row in rows):
        raise ValueError("地图必须非空且每行格数相同。")
    cells, starts = [], {}
    for rowIndex, row in enumerate(rows):
        for colIndex, label in enumerate(row):
            if label == "#":
                continue
            if label != "." and label not in string.ascii_letters + string.digits:
                raise ValueError(f"非法地图字符 {label!r}；仅允许 # . 和英文字母/数字。")
            cellIndex = len(cells)
            cells.append((rowIndex, colIndex))
            if label != ".":
                if label in starts:
                    raise ValueError(f"角色标签 {label!r} 重复。")
                starts[label] = cellIndex
    if not starts:
        raise ValueError("至少需要一名角色。")
    return rows, cells, starts


def checkNumber(value, name, probability=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{name} 必须是数值。")
    if not math.isfinite(value) or value < 0 or (probability and value > 1):
        raise ValueError(f"{name} 必须为有限非负数" + ("且不大于 1。" if probability else "。"))
    return float(value)


def prepareGame(mapText, config):
    if not isinstance(config, dict):
        raise ValueError("配置必须是 JSON 对象。")
    allowedKeys = {"turnOrder", "defaultMoveWeights", "moveWeights", "defaultWinProb", "pairWinProb"}
    if set(config) - allowedKeys:
        raise ValueError(f"未知配置项：{set(config) - allowedKeys}")
    rows, cells, starts = readMap(mapText)
    labels = config.get("turnOrder", sorted(starts))
    if not isinstance(labels, list) or any(not isinstance(label, str) for label in labels):
        raise ValueError("turnOrder 必须是角色标签数组。")
    if len(labels) != len(starts) or set(labels) != set(starts):
        raise ValueError("turnOrder 必须恰好包含每名角色一次。")
    cellLookup = {cell: index for index, cell in enumerate(cells)}
    defaultWeights = dict.fromkeys(directionOffsets, 1.0)
    specifiedDefaults = config.get("defaultMoveWeights", {})
    moveWeights = config.get("moveWeights", {})
    if not isinstance(specifiedDefaults, dict) or not isinstance(moveWeights, dict):
        raise ValueError("移动权重必须是 JSON 对象。")
    if set(moveWeights) - set(labels):
        raise ValueError("moveWeights 中存在未知角色。")
    if set(specifiedDefaults) - set(directionOffsets):
        raise ValueError("defaultMoveWeights 中存在未知方向。")
    defaultWeights.update(specifiedDefaults)
    moveOptions = []
    for label in labels:
        overrides = moveWeights.get(label, {})
        if not isinstance(overrides, dict) or set(overrides) - set(directionOffsets):
            raise ValueError(f"角色 {label} 的方向配置无效。")
        weights = {**defaultWeights, **overrides}
        weights = {key: checkNumber(value, f"{label}.{key}") for key, value in weights.items()}
        actorOptions = []
        for rowIndex, colIndex in cells:
            legalOptions = []
            for direction, (rowOffset, colOffset) in directionOffsets.items():
                target = cellLookup.get((rowIndex + rowOffset, colIndex + colOffset))
                if target is not None and weights[direction] > 0:
                    legalOptions.append((target, weights[direction]))
            totalWeight = sum(weight for _, weight in legalOptions)
            if not math.isfinite(totalWeight) or totalWeight <= 0:
                raise ValueError(f"角色 {label} 在 {(rowIndex, colIndex)} 无正权重合法方向；请给 stay 正权重。")
            actorOptions.append([(target, weight / totalWeight) for target, weight in legalOptions])
        moveOptions.append(actorOptions)
    defaultWinProb = checkNumber(config.get("defaultWinProb", 0.5), "defaultWinProb", True)
    pairWinProb = config.get("pairWinProb", {})
    if not isinstance(pairWinProb, dict):
        raise ValueError("pairWinProb 必须是 JSON 对象。")
    winLookup = {}
    for pair, value in pairWinProb.items():
        parts = pair.split(":")
        if len(parts) != 2 or parts[0] == parts[1] or any(label not in labels for label in parts):
            raise ValueError(f"无效对决组合 {pair!r}，格式应为 A:B。")
        first, second = map(labels.index, parts)
        if (second, first) in winLookup:
            raise ValueError(f"对决组合 {pair!r} 重复定义了反向胜率。")
        winLookup[first, second] = checkNumber(value, pair, True)
    # 未指定组合：按 turnOrder 较早者作为 defaultWinProb 对应的一方。
    for first in range(len(labels)):
        for second in range(first + 1, len(labels)):
            if (first, second) not in winLookup and (second, first) not in winLookup:
                winLookup[first, second] = defaultWinProb
    for (first, second), value in list(winLookup.items()):
        winLookup[second, first] = 1.0 - value
    initialState = tuple(starts[label] for label in labels)
    return rows, cells, labels, moveOptions, winLookup, initialState


def isFinished(state):
    return sum(cell >= 0 for cell in state) == 1


def getRoundTransitions(state, moveOptions, winLookup, maxStates, collectEncounters=False):
    # mask 记录本回合发生过相遇的方格，防止把重复相遇次数当作概率。
    distribution = {(state, 0): 1.0}
    for actorIndex in range(len(state)):
        nextDistribution = defaultdict(float)
        for (currentState, encounterMask), stateProb in distribution.items():
            actorCell = currentState[actorIndex]
            if actorCell < 0 or isFinished(currentState):
                nextDistribution[currentState, encounterMask] += stateProb
                continue
            for targetCell, moveProb in moveOptions[actorIndex][actorCell]:
                opponentIndex = next((index for index, cell in enumerate(currentState)
                                      if index != actorIndex and cell == targetCell), None)
                movedState = list(currentState)
                movedState[actorIndex] = targetCell
                branchProb = stateProb * moveProb
                if opponentIndex is None:
                    nextDistribution[tuple(movedState), encounterMask] += branchProb
                else:
                    nextMask = encounterMask | (1 << targetCell) if collectEncounters else 0
                    winProb = winLookup[actorIndex, opponentIndex]
                    if winProb > 0:
                        winnerState = movedState.copy()
                        winnerState[opponentIndex] = -1
                        nextDistribution[tuple(winnerState), nextMask] += branchProb * winProb
                    if winProb < 1:
                        loserState = movedState.copy()
                        loserState[actorIndex] = -1
                        nextDistribution[tuple(loserState), nextMask] += branchProb * (1 - winProb)
            if len(nextDistribution) > maxStates:
                raise ValueError("单回合分支数超过 maxStates，请缩小地图/减少角色，或提高上限。")
        distribution = nextDistribution
    if not math.isclose(sum(distribution.values()), 1.0, abs_tol=1e-10):
        raise ArithmeticError("单回合转移概率不守恒。")
    transitions = defaultdict(float)
    encounterRates = defaultdict(float)
    anyEncounterRate = 0.0
    for (targetState, encounterMask), probability in distribution.items():
        transitions[targetState] += probability
        if encounterMask:
            anyEncounterRate += probability
        while encounterMask:
            lowestBit = encounterMask & -encounterMask
            encounterRates[lowestBit.bit_length() - 1] += probability
            encounterMask ^= lowestBit
    if collectEncounters:
        return dict(transitions), dict(encounterRates), anyEncounterRate
    return dict(transitions)


def buildChain(initialState, moveOptions, winLookup, maxStates, showProgress=True):
    import numpy as np
    from scipy.sparse import csr_matrix
    states = [initialState]
    stateIds = {initialState: 0}
    rowIndices, colIndices, probabilities = [], [], []
    encounterRows, encounterCols, encounterValues = [], [], []
    cellCount = len(moveOptions[0])
    stateIndex = 0
    progress = tqdm(desc="枚举可达状态", unit="状态", disable=not showProgress)
    while stateIndex < len(states):
        transitions, encounterRates, anyEncounterRate = getRoundTransitions(
            states[stateIndex], moveOptions, winLookup, maxStates, collectEncounters=True)
        for cellIndex, probability in encounterRates.items():
            encounterRows.append(stateIndex)
            encounterCols.append(cellIndex)
            encounterValues.append(probability)
        if anyEncounterRate > 0:
            encounterRows.append(stateIndex)
            encounterCols.append(cellCount)
            encounterValues.append(anyEncounterRate)
        for targetState, probability in transitions.items():
            if probability <= 0:
                continue
            if targetState not in stateIds:
                if len(states) >= maxStates:
                    raise ValueError(f"可达状态数超过 {maxStates}；请缩小地图/减少角色，或提高 --maxStates。")
                stateIds[targetState] = len(states)
                states.append(targetState)
            rowIndices.append(stateIndex)
            colIndices.append(stateIds[targetState])
            probabilities.append(probability)
        stateIndex += 1
        progress.update(1)
        if stateIndex % 100 == 0:
            progress.set_postfix(discovered=len(states), edges=len(probabilities))
    progress.close()
    transitionMatrix = csr_matrix((probabilities, (rowIndices, colIndices)), shape=(len(states), len(states)))
    if not np.allclose(np.asarray(transitionMatrix.sum(axis=1)).ravel(), 1.0, atol=1e-10, rtol=0):
        raise ArithmeticError("转移矩阵行和不为 1。")
    encounterMatrix = csr_matrix((encounterValues, (encounterRows, encounterCols)),
                                 shape=(len(states), cellCount + 1))
    return states, transitionMatrix, encounterMatrix


class survivorBlockSolver:
    """按存活集合拆分子对局：先求人数少的块，复用各块的 LU 分解。

    H_A = (I - M_AA)^(-1) [r_A + sum_{B subset A} M_AB H_B]。
    保留角色标签和位置；不能仅按人数合并状态，也不重置回合内操作顺序。
    枚举得到的是回合边界状态，回合中途淘汰由 getRoundTransitions 完整处理。
    """

    def __init__(self, states, transitionMatrix, showProgress=True):
        from collections import OrderedDict
        self.transitionMatrix = transitionMatrix
        self.survivorMasks = [sum(1 << index for index, cell in enumerate(state) if cell >= 0)
                              for state in states]
        self.factorCache = OrderedDict()
        self.factorizations = 0
        self.cacheHits = 0
        self.maxBlockSize = 0
        self.showProgress = showProgress

    def solve(self, selectedIds, rightSide):
        import numpy as np
        from scipy.sparse import eye
        from scipy.sparse.linalg import splu
        groups = defaultdict(list)
        for localIndex, globalIndex in enumerate(selectedIds):
            groups[self.survivorMasks[int(globalIndex)]].append(localIndex)
        values = np.zeros(len(selectedIds))
        blockOrder = sorted(groups, key=lambda mask: (mask.bit_count(), mask))
        for mask in tqdm(blockOrder, desc="求解存活集合子对局", unit="块", disable=not self.showProgress):
            localIds = np.array(groups[mask], dtype=int)
            globalIds = selectedIds[localIds]
            cacheKey = tuple(int(index) for index in globalIds)
            factor = self.factorCache.get(cacheKey)
            if factor is None:
                blockMatrix = self.transitionMatrix[globalIds][:, globalIds]
                factor = splu((eye(len(globalIds), format="csc") - blockMatrix).tocsc())
                self.factorCache[cacheKey] = factor
                self.factorizations += 1
                self.maxBlockSize = max(self.maxBlockSize, len(globalIds))
                # 限制缓存数量，避免为大地图无限保存 LU 分解。
                if len(self.factorCache) > 32:
                    self.factorCache.popitem(last=False)
            else:
                self.cacheHits += 1
                self.factorCache.move_to_end(cacheKey)
            lowerContribution = self.transitionMatrix[globalIds][:, selectedIds] @ values
            values[localIds] = factor.solve(rightSide[localIds] + lowerContribution)
        return values


def expectedMaskedRounds(transitionMatrix, stateMask, blockSolver=None):
    """求初始状态起、首次离开 stateMask 前经历的回合数；调用方保证不能重新进入。"""
    import numpy as np
    from scipy.sparse import eye
    from scipy.sparse.linalg import spsolve
    if not stateMask[0]:
        return False, 0.0
    selectedIds = np.flatnonzero(stateMask)
    subMatrix = transitionMatrix[selectedIds][:, selectedIds]
    # 根据转移图寻找具有离开 mask 的路径的状态，不用浮点行和判断出口。
    canExit = np.zeros(len(selectedIds), dtype=bool)
    for localIndex, globalIndex in enumerate(selectedIds):
        targetIds = transitionMatrix.indices[transitionMatrix.indptr[globalIndex]:transitionMatrix.indptr[globalIndex + 1]]
        canExit[localIndex] = bool(np.any(~stateMask[targetIds]))
    reverseMatrix = subMatrix.transpose().tocsr()
    pending = deque(np.flatnonzero(canExit).tolist())
    while pending:
        targetIndex = pending.popleft()
        for sourceIndex in reverseMatrix.indices[reverseMatrix.indptr[targetIndex]:reverseMatrix.indptr[targetIndex + 1]]:
            if not canExit[sourceIndex]:
                canExit[sourceIndex] = True
                pending.append(int(sourceIndex))
    # 所有枚举状态均可达，且离开后不能重入，因此任一封闭子类都导致期望无穷。
    if np.any(~canExit):
        return True, None
    systemMatrix = eye(len(selectedIds), format="csr") - subMatrix
    rightSide = np.ones(len(selectedIds))
    values = blockSolver.solve(selectedIds, rightSide) if blockSolver else spsolve(systemMatrix, rightSide)
    if not np.all(np.isfinite(values)) or not np.allclose(systemMatrix @ values, rightSide, atol=1e-8, rtol=1e-8):
        raise ArithmeticError("期望存活回合数的线性方程求解不稳定。")
    return False, float(values[0])


def solveActorLifetimes(states, transitionMatrix, labels, blockSolver=None):
    import numpy as np
    unfinishedMask = np.array([not isFinished(state) for state in states])
    actorResults = {}
    for actorIndex, label in enumerate(labels):
        aliveMask = np.array([state[actorIndex] >= 0 for state in states])
        activeIsInfinite, activeExpectation = expectedMaskedRounds(transitionMatrix, aliveMask & unfinishedMask, blockSolver)
        lifeIsInfinite, lifeExpectation = expectedMaskedRounds(transitionMatrix, aliveMask, blockSolver)
        actorResults[label] = {
            "expectedActiveRounds": activeExpectation,
            "expectedActiveRoundsIsInfinite": activeIsInfinite,
            "expectedRoundsUntilElimination": lifeExpectation,
            "expectedRoundsUntilEliminationIsInfinite": lifeIsInfinite,
        }
    return actorResults


def solveSummary(states, transitionMatrix, blockSolver=None):
    import numpy as np
    from scipy.sparse import eye
    from scipy.sparse.linalg import spsolve
    finishedMask = np.array([isFinished(state) for state in states])
    if finishedMask[0]:
        return {"eventualEndProbability": 1.0, "expectedRounds": 0.0,
                "expectedRoundsIsInfinite": False, "stateCount": len(states)}
    # 反向搜索：识别能到达吸收态的状态。每个枚举状态均从初始态可达。
    reverseMatrix = transitionMatrix.transpose().tocsr()
    canFinish = finishedMask.copy()
    pending = deque(np.flatnonzero(finishedMask).tolist())
    while pending:
        targetIndex = pending.popleft()
        for sourceIndex in reverseMatrix.indices[reverseMatrix.indptr[targetIndex]:reverseMatrix.indptr[targetIndex + 1]]:
            if not canFinish[sourceIndex]:
                canFinish[sourceIndex] = True
                pending.append(int(sourceIndex))
    goodIds = np.flatnonzero(canFinish & ~finishedMask)
    endProbability = 0.0
    expectedRounds = None
    isInfinite = bool(np.any(~canFinish))
    if len(goodIds):
        goodMatrix = transitionMatrix[goodIds][:, goodIds]
        systemMatrix = eye(len(goodIds), format="csr") - goodMatrix
        endRates = np.asarray(transitionMatrix[goodIds][:, finishedMask].sum(axis=1)).ravel()
        def solveChecked(rightSide):
            values = blockSolver.solve(goodIds, rightSide) if blockSolver else spsolve(systemMatrix, rightSide)
            if not np.all(np.isfinite(values)) or not np.allclose(systemMatrix @ values, rightSide, atol=1e-8, rtol=1e-8):
                raise ArithmeticError("线性方程求解不稳定；请调整极端权重或改用更高精度。")
            return values
        endValues = solveChecked(endRates)
        if goodIds[0] == 0:
            endProbability = float(np.clip(endValues[0], 0, 1))
        if not isInfinite:
            expectedRounds = float(solveChecked(np.ones(len(goodIds)))[0])
    return {"eventualEndProbability": endProbability, "expectedRounds": expectedRounds,
            "expectedRoundsIsInfinite": isInfinite, "stateCount": len(states)}


def writeResults(states, transitionMatrix, encounterMatrix, labels, cells, roundCount, outputDir, showProgress=True):
    import numpy as np
    outputDir.mkdir(parents=True, exist_ok=True)
    finishedMask = np.array([isFinished(state) for state in states])
    distribution = np.zeros(len(states))
    distribution[0] = 1.0
    transposeMatrix = transitionMatrix.transpose().tocsr()
    transposeEncounters = encounterMatrix.transpose().tocsr()
    from scipy.sparse import csr_matrix
    observationRows, observationCols = [], []
    activeRows, activeCols = [], []
    for stateIndex, state in enumerate(states):
        for actorIndex, cellIndex in enumerate(state):
            if cellIndex >= 0:
                observationRows.append(actorIndex * len(cells) + cellIndex)
                observationCols.append(stateIndex)
                if not finishedMask[stateIndex]:
                    activeRows.append(actorIndex)
                    activeCols.append(stateIndex)
    positionObservation = csr_matrix((np.ones(len(observationRows)), (observationRows, observationCols)),
                                     shape=(len(labels) * len(cells), len(states)))
    activeObservation = csr_matrix((np.ones(len(activeRows)), (activeRows, activeCols)),
                                   shape=(len(labels), len(states)))
    previousCumulative = 0.0
    with (outputDir / "endProbabilities.csv").open("w", encoding="utf-8-sig", newline="") as endFile, \
         (outputDir / "positionProbabilities.csv").open("w", encoding="utf-8-sig", newline="") as positionFile, \
         (outputDir / "encounterProbabilities.csv").open("w", encoding="utf-8-sig", newline="") as encounterFile, \
         (outputDir / "roundEncounterProbabilities.csv").open("w", encoding="utf-8-sig", newline="") as roundEncounterFile, \
         (outputDir / "survivalProbabilities.csv").open("w", encoding="utf-8-sig", newline="") as survivalFile:
        endWriter, positionWriter = csv.writer(endFile), csv.writer(positionFile)
        encounterWriter = csv.writer(encounterFile)
        roundEncounterWriter = csv.writer(roundEncounterFile)
        survivalWriter = csv.writer(survivalFile)
        endWriter.writerow(["round", "endThisRoundProbability", "endedByRoundProbability", "notEndedProbability"])
        positionWriter.writerow(["round", "actor", "row", "col", "positionProbability", "aliveProbability", "positionGivenAliveProbability"])
        encounterWriter.writerow(["round", "row", "col", "atLeastOneEncounterProbability"])
        roundEncounterWriter.writerow(["round", "atLeastOneEncounterAnywhereProbability"])
        survivalWriter.writerow(["round", "actor", "aliveProbability", "eliminatedProbability", "aliveAndGameOngoingProbability"])
        for roundIndex in tqdm(range(roundCount + 1), desc="导出精确概率", unit="回合", disable=not showProgress):
            encounters = np.zeros(len(cells) + 1)
            if roundIndex > 0:
                # 本回合的事件概率必须从上一回合末分布计算。
                encounters = transposeEncounters @ distribution
                distribution = transposeMatrix @ distribution
            roundEncounterWriter.writerow([roundIndex, encounters[-1]])
            for cellIndex, (rowIndex, colIndex) in enumerate(cells):
                encounterWriter.writerow([roundIndex, rowIndex, colIndex, encounters[cellIndex]])
            cumulative = float(distribution[finishedMask].sum())
            roundProbability = cumulative - previousCumulative
            notEnded = float(distribution[~finishedMask].sum())
            endWriter.writerow([roundIndex, roundProbability, cumulative, notEnded])

            previousCumulative = cumulative
            positions = (positionObservation @ distribution).reshape(len(labels), len(cells))
            activeProbabilities = activeObservation @ distribution
            aliveProbabilities = positions.sum(axis=1)
            for actorIndex, label in enumerate(labels):
                aliveProbability = float(aliveProbabilities[actorIndex])
                activeProbability = float(activeProbabilities[actorIndex])
                survivalWriter.writerow([roundIndex, label, aliveProbability, 1.0 - aliveProbability, activeProbability])
                for cellIndex, (rowIndex, colIndex) in enumerate(cells):
                    conditionalPosition = positions[actorIndex, cellIndex] / aliveProbability if aliveProbability > 0 else ""
                    positionWriter.writerow([roundIndex, label, rowIndex, colIndex,
                                             positions[actorIndex, cellIndex], aliveProbability, conditionalPosition])


def probabilitySe(probability, sampleCount):
    """单个概率估计的标准误；不是所有格子/回合同时覆盖的置信区间。"""
    return math.sqrt(max(0.0, probability * (1 - probability)) / sampleCount)


def runSimulation(initialState, moveOptions, winLookup, labels, cells, args):
    """批量 NumPy 模拟，不枚举联合状态。回合中的淘汰、剩余行动顺序保持不变。"""
    import numpy as np
    actorCount, cellCount = len(labels), len(cells)
    roundCount, sampleCount = args.roundCount, args.samples
    randomGenerator = np.random.default_rng(args.seed)
    targets = np.zeros((actorCount, cellCount, 5), dtype=np.int32)
    cumulativeWeights = np.ones((actorCount, cellCount, 5))
    for actorIndex, options in enumerate(moveOptions):
        for cellIndex, choices in enumerate(options):
            total = 0.0
            for choiceIndex, (target, probability) in enumerate(choices):
                targets[actorIndex, cellIndex, choiceIndex] = target
                total += probability
                cumulativeWeights[actorIndex, cellIndex, choiceIndex] = total
            cumulativeWeights[actorIndex, cellIndex, len(choices) - 1:] = 1.0
    winMatrix = np.zeros((actorCount, actorCount))
    for (first, second), probability in winLookup.items():
        winMatrix[first, second] = probability
    positionCounts = np.zeros((roundCount + 1, actorCount, cellCount), dtype=np.int64)
    activeCounts = np.zeros((roundCount + 1, actorCount), dtype=np.int64)
    encounterCounts = np.zeros((roundCount + 1, cellCount), dtype=np.int64)
    anyEncounterCounts = np.zeros(roundCount + 1, dtype=np.int64)
    endCounts = np.zeros(roundCount + 1, dtype=np.int64)
    endLengths = np.zeros(sampleCount, dtype=np.int64)
    activeLengths = np.zeros((sampleCount, actorCount), dtype=np.int64)
    eliminatedAt = np.full((sampleCount, actorCount), -1, dtype=np.int64)
    winners = np.full(sampleCount, -1, dtype=np.int32)
    censored = np.zeros(sampleCount, dtype=bool)
    progress = tqdm(total=sampleCount, desc="批量模拟", unit="局", disable=args.noProgress)
    for batchStart in range(0, sampleCount, args.batchSize):
        batchCount = min(args.batchSize, sampleCount - batchStart)
        batchSlice = slice(batchStart, batchStart + batchCount)
        positions = np.tile(initialState, (batchCount, 1)).astype(np.int32)
        aliveCounts = np.full(batchCount, actorCount, dtype=np.int32)
        finishRounds = np.full(batchCount, -1, dtype=np.int64)
        if actorCount == 1:
            finishRounds[:] = 0
        def recordPositions(roundIndex):
            for actorIndex in range(actorCount):
                liveCells = positions[:, actorIndex]
                positionCounts[roundIndex, actorIndex] += np.bincount(liveCells[liveCells >= 0], minlength=cellCount)
                activeCounts[roundIndex, actorIndex] += np.count_nonzero((liveCells >= 0) & (aliveCounts > 1))
        recordPositions(0)
        for roundIndex in range(1, args.maxSimulationRounds + 1):
            ongoing = aliveCounts > 1
            if not np.any(ongoing) and roundIndex > roundCount:
                break
            activeLengths[batchSlice] += (positions >= 0) & ongoing[:, None]
            encounteredCells = np.zeros((batchCount, cellCount), dtype=bool) if roundIndex <= roundCount else None
            for actorIndex in range(actorCount):
                sampleIds = np.flatnonzero((aliveCounts > 1) & (positions[:, actorIndex] >= 0))
                if not len(sampleIds):
                    continue
                actorCells = positions[sampleIds, actorIndex]
                uniforms = randomGenerator.random(len(sampleIds))
                choiceIds = np.sum(uniforms[:, None] >= cumulativeWeights[actorIndex, actorCells], axis=1)
                targetCells = targets[actorIndex, actorCells, choiceIds]
                matches = positions[sampleIds] == targetCells[:, None]
                matches[:, actorIndex] = False
                hasOpponent = matches.any(axis=1)
                positions[sampleIds, actorIndex] = targetCells
                hitIds = sampleIds[hasOpponent]
                if not len(hitIds):
                    continue
                opponents = matches[hasOpponent].argmax(axis=1)
                if encounteredCells is not None:
                    encounteredCells[hitIds, targetCells[hasOpponent]] = True
                actorWins = randomGenerator.random(len(hitIds)) < winMatrix[actorIndex, opponents]
                loserIds = np.where(actorWins, opponents, actorIndex)
                positions[hitIds, loserIds] = -1
                eliminatedAt[batchStart + hitIds, loserIds] = roundIndex
                aliveCounts[hitIds] -= 1
                newFinished = hitIds[aliveCounts[hitIds] == 1]
                finishRounds[newFinished] = roundIndex
            if roundIndex <= roundCount:
                recordPositions(roundIndex)
                encounterCounts[roundIndex] += encounteredCells.sum(axis=0)
                anyEncounterCounts[roundIndex] += np.count_nonzero(encounteredCells.any(axis=1))
        batchCensored = finishRounds < 0
        censored[batchSlice] = batchCensored
        endLengths[batchSlice] = np.where(batchCensored, args.maxSimulationRounds, finishRounds)
        for actorIndex in range(actorCount):
            winners[batchStart + np.flatnonzero((positions[:, actorIndex] >= 0) & ~batchCensored)] = actorIndex
        exportedEnds = finishRounds[(finishRounds >= 0) & (finishRounds <= roundCount)]
        endCounts += np.bincount(exportedEnds, minlength=roundCount + 1)
        progress.update(batchCount)
        progress.set_postfix(censored=int(censored[:batchStart + batchCount].sum()))
    progress.close()
    args.outputDir.mkdir(parents=True, exist_ok=True)
    def makeWriter(fileName, header):
        file = (args.outputDir / fileName).open("w", encoding="utf-8-sig", newline="")
        writer = csv.writer(file)
        writer.writerow(header)
        return file, writer
    from contextlib import ExitStack
    with ExitStack() as stack:
        specifications = [
            ("endProbabilities.csv", ["round", "endThisRoundProbability", "endedByRoundProbability", "notEndedProbability", "endThisRoundStandardError", "endedByRoundStandardError"]),
            ("positionProbabilities.csv", ["round", "actor", "row", "col", "positionProbability", "aliveProbability", "positionGivenAliveProbability", "positionStandardError"]),
            ("encounterProbabilities.csv", ["round", "row", "col", "atLeastOneEncounterProbability", "standardError"]),
            ("roundEncounterProbabilities.csv", ["round", "atLeastOneEncounterAnywhereProbability", "standardError"]),
            ("survivalProbabilities.csv", ["round", "actor", "aliveProbability", "eliminatedProbability", "aliveAndGameOngoingProbability", "aliveStandardError"])]
        writers = []
        for fileName, header in specifications:
            file, writer = makeWriter(fileName, header)
            stack.enter_context(file)
            writers.append(writer)
        endWriter, positionWriter, encounterWriter, roundEncounterWriter, survivalWriter = writers
        cumulativeEnds = np.cumsum(endCounts) / sampleCount
        for roundIndex in tqdm(range(roundCount + 1), desc="导出模拟概率", unit="回合", disable=args.noProgress):
            endProbability = endCounts[roundIndex] / sampleCount
            endedProbability = cumulativeEnds[roundIndex]
            endWriter.writerow([roundIndex, endProbability, endedProbability, 1 - endedProbability,
                                probabilitySe(endProbability, sampleCount), probabilitySe(endedProbability, sampleCount)])
            encounterProbability = anyEncounterCounts[roundIndex] / sampleCount
            roundEncounterWriter.writerow([roundIndex, encounterProbability, probabilitySe(encounterProbability, sampleCount)])
            for cellIndex, (rowIndex, colIndex) in enumerate(cells):
                probability = encounterCounts[roundIndex, cellIndex] / sampleCount
                encounterWriter.writerow([roundIndex, rowIndex, colIndex, probability, probabilitySe(probability, sampleCount)])
            for actorIndex, label in enumerate(labels):
                aliveCount = int(positionCounts[roundIndex, actorIndex].sum())
                aliveProbability = aliveCount / sampleCount
                survivalWriter.writerow([roundIndex, label, aliveProbability, 1 - aliveProbability,
                                         activeCounts[roundIndex, actorIndex] / sampleCount, probabilitySe(aliveProbability, sampleCount)])
                for cellIndex, (rowIndex, colIndex) in enumerate(cells):
                    count = int(positionCounts[roundIndex, actorIndex, cellIndex])
                    probability = count / sampleCount
                    positionWriter.writerow([roundIndex, label, rowIndex, colIndex, probability, aliveProbability,
                                             count / aliveCount if aliveCount else "", probabilitySe(probability, sampleCount)])
    allFinished = not bool(censored.any())
    def meanSe(values):
        return float(values.std(ddof=1) / math.sqrt(sampleCount)) if sampleCount > 1 else None
    summary = {
        "method": "batched Monte Carlo; estimates, not exact enumeration",
        "samples": sampleCount, "seed": args.seed, "batchSize": args.batchSize,
        "maxSimulationRounds": args.maxSimulationRounds,
        "censoredSampleCount": int(censored.sum()), "censoredFraction": float(censored.mean()),
        "endedBySimulationLimitProbability": float(1 - censored.mean()),
        "eventualEndProbability": None,
        "expectedRounds": float(endLengths.mean()) if allFinished else None,
        "expectedRoundsStandardError": meanSe(endLengths) if allFinished else None,
        "expectedRoundsIsInfinite": None,
        "expectedTruncatedRounds": float(endLengths.mean()),
        "expectedTruncatedRoundsStandardError": meanSe(endLengths),
        "probabilityStandardErrorUpperBound": 0.5 / math.sqrt(sampleCount),
        "notes": "未完成样本存在时仅报告 E[min(T,H)] 的估计，不把截断均值当作完整期望；有限模拟不能证明最终结束概率或无穷期望。单项标准误不构成同时置信区间，零命中也不证明概率为零。",
        "actorLifetimes": {},
    }
    for actorIndex, label in enumerate(labels):
        lengths = activeLengths[:, actorIndex]
        # 对该角色，只要已淘汰或游戏结束，其参与回合数已完全观测。
        actorCensored = censored & (eliminatedAt[:, actorIndex] < 0)
        observedWinner = bool(np.any(winners == actorIndex))
        allEliminated = bool(np.all(eliminatedAt[:, actorIndex] >= 0))
        summary["actorLifetimes"][label] = {
            "expectedActiveRounds": float(lengths.mean()) if not actorCensored.any() else None,
            "expectedActiveRoundsStandardError": meanSe(lengths) if not actorCensored.any() else None,
            "expectedActiveRoundsIsInfinite": None,
            "expectedTruncatedActiveRounds": float(lengths.mean()),
            "activeCensoredFraction": float(actorCensored.mean()),
            "observedWinProbability": float(np.mean(winners == actorIndex)),
            "expectedRoundsUntilElimination": float(eliminatedAt[:, actorIndex].mean()) if allEliminated else None,
            "expectedRoundsUntilEliminationIsInfinite": True if observedWinner else None,
            "eliminationExpectationNote": "观察到获胜路径可证明永不淘汰概率为正，因此期望无穷；未观察到不证明不可能获胜。",
        }
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--init", type=Path, help="创建 map.txt 和 config.json，不覆盖已有输入")
    parser.add_argument("--map", dest="mapPath", type=Path)
    parser.add_argument("--config", dest="configPath", type=Path)
    parser.add_argument("--rounds", dest="roundCount", type=int, default=50, help="逐回合 CSV 输出上限")
    parser.add_argument("--method", choices=["auto", "exact", "simulate"], default="auto")
    parser.add_argument("--samples", type=int, default=10000, help="模拟局数，默认 10000")
    parser.add_argument("--batchSize", type=int, default=1000, help="每批局数，默认 1000")
    parser.add_argument("--maxSimulationRounds", type=int, default=5000, help="每局模拟上限，不能小于 rounds")
    parser.add_argument("--seed", type=int, default=20261012)
    parser.add_argument("--maxStates", type=int, default=50000)
    parser.add_argument("--noProgress", action="store_true", help="关闭 tqdm 进度条")
    parser.add_argument("--out", dest="outputDir", type=Path, default=Path("results"))
    args = parser.parse_args()
    try:
        if args.init is not None:
            args.init.mkdir(parents=True, exist_ok=True)
            paths = [args.init / "map.txt", args.init / "config.json"]
            if any(path.exists() for path in paths):
                raise ValueError("输入文件已存在，请选择其他目录。")
            paths[0].write_text(demoMap, encoding="utf-8")
            paths[1].write_text(json.dumps(demoConfig, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            print(f"已创建 {paths[0]} 和 {paths[1]}")
            return
        if args.roundCount < 0 or args.maxStates < 1 or args.samples < 1 or args.batchSize < 1 or args.seed < 0:
            raise ValueError("rounds/seed 必须非负；maxStates/samples/batchSize 必须为正。")
        mapText = args.mapPath.read_text(encoding="utf-8-sig") if args.mapPath else demoMap
        config = json.loads(args.configPath.read_text(encoding="utf-8-sig")) if args.configPath else (demoConfig if args.mapPath is None else {})
        rows, cells, labels, moveOptions, winLookup, initialState = prepareGame(mapText, config)
        print("地图：\n" + "\n".join(rows))
        print("移动顺序：" + " → ".join(labels))
        # 所有存活集合的状态数上界 sum C(N,k) * P(C,k)，可达子集通常更少。
        stateUpperBound = sum(math.comb(len(labels), count) * math.perm(len(cells), count)
                              for count in range(1, len(labels) + 1))
        method = args.method
        if method == "auto":
            method = "exact" if stateUpperBound <= args.maxStates else "simulate"
        print(f"方法：{method}；联合状态组合上界约 {stateUpperBound:.3g}")
        if method == "simulate":
            if args.maxSimulationRounds < max(1, args.roundCount):
                raise ValueError("maxSimulationRounds 必须至少为 max(1, rounds)。")
            summary = runSimulation(initialState, moveOptions, winLookup, labels, cells, args)
            print(f"截断平均结束回合：{summary['expectedTruncatedRounds']:.8g}；未完成样本：{summary['censoredSampleCount']}/{args.samples}")
            if summary["expectedRounds"] is not None:
                print(f"结束回合数样本均值：{summary['expectedRounds']:.8g}，标准误 {summary['expectedRoundsStandardError']}")
            print(f"单个概率估计的标准误上界：{summary['probabilityStandardErrorUpperBound']:.6g}")
            for label, values in summary["actorLifetimes"].items():
                value = values["expectedActiveRounds"]
                if value is None:
                    print(f"角色 {label}：截断参与回合均值 {values['expectedTruncatedActiveRounds']:.8g}；仍存活未结束比例 {values['activeCensoredFraction']:.6g}")
                else:
                    print(f"角色 {label}：参与存活回合样本均值 {value:.8g}")
        else:
            states, transitionMatrix, encounterMatrix = buildChain(initialState, moveOptions, winLookup, args.maxStates, not args.noProgress)
            blockSolver = survivorBlockSolver(states, transitionMatrix, not args.noProgress)
            summary = solveSummary(states, transitionMatrix, blockSolver)
            summary["actorLifetimes"] = solveActorLifetimes(states, transitionMatrix, labels, blockSolver)
            writeResults(states, transitionMatrix, encounterMatrix, labels, cells, args.roundCount, args.outputDir, not args.noProgress)
            summary.update({"method": "exact state enumeration; survivor-set block solve; floating point",
                            "blockFactorizations": blockSolver.factorizations, "blockCacheHits": blockSolver.cacheHits,
                            "maxBlockSize": blockSolver.maxBlockSize})
            print(f"可达状态：{len(states)}；子对局分解：{blockSolver.factorizations}；缓存命中：{blockSolver.cacheHits}")
            print(f"最终结束概率：{summary['eventualEndProbability']:.12g}；期望回合：{summary['expectedRounds']}")
        summary.update({"turnOrder": labels, "roundsExported": args.roundCount, "stateCountUpperBound": stateUpperBound})
        args.outputDir.mkdir(parents=True, exist_ok=True)
        (args.outputDir / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8")
        print(f"结果目录：{args.outputDir.resolve()}")
    except (ValueError, OSError, ArithmeticError, RuntimeError) as error:
        parser.exit(2, f"错误：{error}\n")
    except ImportError:
        parser.exit(2, "缺少依赖，请执行：python -m pip install numpy scipy tqdm\n")


if __name__ == "__main__":
    main()

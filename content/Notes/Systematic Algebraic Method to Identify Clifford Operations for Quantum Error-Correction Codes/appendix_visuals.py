"""Reproduce the appendix animations and verify binary Clifford calculations.

Requires numpy and Pillow. Run this file with Python from any working directory.
The toric numbering and gate list are transcribed from SM Fig. S5 / Eq. (S54).
All matrices act on row vectors in (Z | X) order. No phase verification is claimed.
"""
from pathlib import Path
import json
import re

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
OUT = HERE / "img"
SEQUENCE = """
[1 7][7 1][2 8][8 2][3 9][7 13][9 3][8 14][1 7][9 15][2 8][3 9][5 17][13 7][7 13][14 8][8 14][15 9][6 18][4 5][17 5]
[9 15][4 6][5 17][4 1][4 2][5 2][5 3][18 6][6 18][6 1][6 3][13 14][14 15][10 17][11 17][15 16][8 2][10 18][10 5]
[16 15][16 17][7 1][12 18][9 3][15 16][10 6][15 18][11 5][15 2][13 1][14 9][15 5][14 13][12 6][15 6][17 16][16 17]
[16 9][15 13][17 18][18 17][18 9][16 13][16 14][17 18][17 1][17 14][18 14]H18[1 18][2 18][3 18][13 8]
(13 18)(14 18)(15 18)(16 18)(17 18)[13 1][13 7]
"""


def mul(a, b):
    return (a @ b) % 2


def symplectic_form(n):
    j = np.zeros((2*n, 2*n), dtype=np.uint8)
    j[:n, n:] = j[n:, :n] = np.eye(n, dtype=np.uint8)
    return j


def gate(n, kind, i, j=None):
    p = np.eye(2*n, dtype=np.uint8)
    i -= 1
    if j is not None:
        j -= 1
    if kind == "H":
        p[:, [i, i+n]] = p[:, [i+n, i]]
    elif kind == "S":
        p[:, i] ^= p[:, i+n]
    elif kind == "CNOT":
        p[:, i] ^= p[:, j]
        p[:, j+n] ^= p[:, i+n]
    elif kind == "SWAP":
        p[:, [i, j]] = p[:, [j, i]]
        p[:, [i+n, j+n]] = p[:, [j+n, i+n]]
    else:
        raise ValueError(kind)
    assert np.array_equal(mul(mul(p, symplectic_form(n)), p.T), symplectic_form(n))
    return p


def rank(a):
    a = a.copy()
    r = 0
    for c in range(a.shape[1]):
        pivots = np.flatnonzero(a[r:, c])
        if not len(pivots):
            continue
        k = r + pivots[0]
        a[[r, k]] = a[[k, r]]
        for k in range(r+1, len(a)):
            if a[k, c]:
                a[k] ^= a[r]
        r += 1
        if r == len(a):
            break
    return r


def support(indices, n=18):
    a = np.zeros(n, dtype=np.uint8)
    a[np.array(indices)-1] = 1
    return a


def solve_binary(a, b):
    """Exact GF(2) elimination, choosing all non-pivot variables as zero."""
    if b.ndim == 1:
        b = b[:,None]
    aug = np.concatenate([a.copy(),b.copy()],axis=1)
    pivots = []
    for c in range(a.shape[1]):
        r = len(pivots)
        candidates = np.flatnonzero(aug[r:,c])
        if not len(candidates):
            continue
        k = r+candidates[0]
        aug[[r,k]] = aug[[k,r]]
        mask = aug[:,c].astype(bool)
        mask[r] = False
        aug[mask] ^= aug[r]
        pivots.append(c)
        if len(pivots) == len(aug):
            break
    if aug[len(pivots):,a.shape[1]:].any():
        raise ValueError("Inconsistent binary system")
    x = np.zeros((a.shape[1],b.shape[1]),dtype=np.uint8)
    x[pivots] = aug[:len(pivots),a.shape[1]:]
    assert np.array_equal(mul(a,x),b)
    return x


def construct_lifted_solution(hz, hx, z, x, target):
    """SM S3/S4, S17/S22, sparse S=T=0 ansatz, then explicit matching.

    This computes a new solution; it does not claim to reproduce the authors'
    pivot choices or their particular matrix/gate list.
    """
    nz,nx,n = len(hz),len(hx),hz.shape[1]
    mz,mx = np.vstack([z,hz]),np.vstack([x,hx])
    ez = solve_binary(mz,np.eye(len(mz),dtype=np.uint8))
    ex = solve_binary(mx,np.eye(len(mx),dtype=np.uint8))
    k = len(z)
    bzz = mul(ez,np.vstack([target[:k,:n],hz]))
    bzx = mul(ez,np.vstack([target[:k,n:],np.zeros_like(hz)]))
    bxz = mul(ex,np.vstack([target[k:,:n],np.zeros_like(hx)]))
    bxx = mul(ex,np.vstack([target[k:,n:],hx]))
    assert not mul(bzz,hx.T).any() and not mul(bxz,hx.T).any()
    assert np.array_equal(mul(hx,bxx),hx) and not mul(hx,bxz).any()
    assert not (mul(bzx,bzz.T)^mul(bzz,bzx.T)).any()
    assert not (mul(bxx,bxz.T)^mul(bxz,bxx.T)).any()
    lower = np.tril_indices(n,-1)
    shapes = [(nx,n),(nz,n),(nz,nx)]
    sizes = [a*b for a,b in shapes]
    offsets = np.cumsum([0]+sizes)
    def unpack(v):
        return [v[offsets[i]:offsets[i+1]].reshape(shape) for i,shape in enumerate(shapes)]
    def lhs(v):
        r,vv,f4 = unpack(v)
        zz,xx = mul(hx.T,r),mul(hz.T,vv)
        f0 = mul(bzx,zz.T)^mul(zz,bzx.T)
        f1 = mul(xx,bxz.T)^mul(bxz,xx.T)
        f2 = mul(mul(hz.T,f4),hx)^mul(bxx,zz.T)^mul(xx,bzz.T)
        return np.concatenate([f0[lower],f1[lower],f2.ravel()])
    a = np.empty((n*(2*n-1),sum(sizes)),dtype=np.uint8)
    for i in range(sum(sizes)):
        basis = np.zeros(sum(sizes),dtype=np.uint8)
        basis[i] = 1
        a[:,i] = lhs(basis)
    rhs3 = np.eye(n,dtype=np.uint8)^mul(bxx,bzz.T)^mul(bxz,bzx.T)
    rhs = np.concatenate([np.zeros(n*(n-1),dtype=np.uint8),rhs3.ravel()])
    sol = solve_binary(a,rhs).ravel()
    r,v,f4 = unpack(sol)
    assert np.array_equal(mul(r,hx.T),np.eye(nx,dtype=np.uint8))
    delta = mul(v,r.T)^f4
    corrected_v = v^mul(delta,hx)
    assert np.array_equal(mul(corrected_v,r.T),f4)
    u = np.block([[mul(hx.T,r)^bzz,bzx],[bxz,mul(hz.T,corrected_v)^bxx]])
    h = np.block([[hz,np.zeros_like(hz)],[np.zeros_like(hx),hx]])
    l = np.block([[z,np.zeros_like(z)],[np.zeros_like(x),x]])
    j = symplectic_form(n)
    assert np.array_equal(mul(mul(u,j),u.T),j)
    assert np.array_equal(mul(h,u),h)
    assert np.array_equal(mul(l,u),target)
    return {"n_Z":nz,"n_X":nx,"lifted_equations":len(rhs),
            "sparse_variables":sum(sizes),"matching_K_is_identity":True,
            "all_original_constraints":True}


def toric_inputs():
    v = lambda r, c: 6*(r % 3)+(c % 3)+1
    h = lambda r, c: 6*(r % 3)+(c % 3)+4
    hz = np.array([support([h(r,c), h(r+1,c), v(r+1,c), v(r+1,c+1)])
                   for r in range(3) for c in range(3)])[:-1]
    hx = np.array([support([v(r,c), v(r+1,c), h(r,c), h(r,c-1)])
                   for r in range(3) for c in range(3)])[:-1]
    z = np.array([support([1,7,13]), support([4,5,6])])
    x = np.array([support([1,2,3]), support([4,10,16])])
    assert rank(hz) == rank(hx) == 8
    assert not mul(hz, hx.T).any()
    assert not mul(hz, x.T).any() and not mul(hx, z.T).any()
    assert np.array_equal(mul(z, x.T), np.eye(2, dtype=np.uint8))
    return hz, hx, z, x


def paper_gates():
    result = []
    for a,b,c,d,e in re.findall(r"\[(\d+) (\d+)\]|\((\d+) (\d+)\)|H(\d+)", SEQUENCE):
        if a:
            result.append(("CNOT", int(b), int(a)))
        elif c:
            result.append(("SWAP", int(c), int(d)))
        else:
            result.append(("H", int(e), None))
    return result


def font(size):
    paths = [Path("C:/Windows/Fonts/arial.ttf"), Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf")]
    for path in paths:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size=size)


def matrix_frame(a, title, subtitle, active=()):
    im = Image.new("RGB", (900, 850), "white")
    d = ImageDraw.Draw(im)
    d.text((26,22),title,font=font(30),fill="#0B5E1F")
    d.text((26,72),subtitle,font=font(23),fill="#5A6B5C")
    m = len(a)
    cell = min(145, 610//m)
    width = m*cell
    left, top = (900-width)//2, 158
    n = m//2
    for i in range(m):
        for j in range(m):
            fill = "#0B5E1F" if a[i,j] else "#EDF5EF"
            if j in active:
                fill = "#B76513" if a[i,j] else "#FFF0DD"
            x,y = left+j*cell,top+i*cell
            d.rectangle((x,y,x+cell-2,y+cell-2), fill=fill)
            if m <= 8:
                d.text((x+cell/2-9,y+cell/2-16),str(a[i,j]),font=font(28),fill="white" if a[i,j] else "#68746B")
    d.line((left+n*cell-1,top-8,left+n*cell-1,top+width+8),fill="#617B65",width=3)
    d.line((left-8,top+n*cell-1,left+width+8,top+n*cell-1),fill="#617B65",width=3)
    for pos, txt in [(left+width/4,"Z"),(left+3*width/4,"X")]:
        d.text((pos-12, top-40),txt,font=font(27),fill="#0B5E1F")
    d.text((26,785),"Green = 1    Pale = 0    Orange = changed columns",font=font(23),fill="#5A6B5C")
    return im


def save_animation(frames, name, duration):
    frames[0].save(OUT/name, save_all=True, append_images=frames[1:], duration=duration, loop=0, disposal=2)
    frames[0].save(OUT/name.replace(".gif", "-poster.png"))


def main():
    OUT.mkdir(exist_ok=True)
    # A fully explicit two-qubit example of symplectic column elimination.
    operations = [("H",1,None),("S",2,None),("CNOT",1,2)]
    u = np.eye(4,dtype=np.uint8)
    for op in reversed(operations):
        u = mul(u,gate(2,*op))
    frames = [matrix_frame(u,"Two-qubit symplectic elimination", "Start: U = P(CNOT12) P(S2) P(H1)")]
    toy_start = u.tolist()
    for op in operations:
        u = mul(u,gate(2,*op))
        kind,i,j = op
        active = (i-1,i+1) if kind == "H" else (i-1,) if kind == "S" else (i-1,j+1)
        frames.append(matrix_frame(u,"Two-qubit symplectic elimination",f"Right multiply by {kind}{i}"+(f",{j}" if j else ""),active))
    assert np.array_equal(u,np.eye(4,dtype=np.uint8))
    frames.append(matrix_frame(u,"Two-qubit symplectic elimination","Final: I4. Every step preserves U J U^T = J"))
    save_animation(frames,"appendix-elimination.gif",[1800,1600,1600,1600,2200])

    hz,hx,z,x = toric_inputs()
    gates = paper_gates()
    # Eq. S54 uses operator products. For row-vector binary action, its
    # matrices compose in the written order. Physical gates run back to front.
    u = np.eye(36,dtype=np.uint8)
    for op in gates:
        u = mul(u,gate(18,*op))
    j = symplectic_form(18)
    stabilizers = np.block([[hz,np.zeros_like(hz)],[np.zeros_like(hx),hx]])
    logicals = np.block([[z,np.zeros_like(z)],[np.zeros_like(x),x]])
    target = logicals[[2,1,0,3]]
    assert np.array_equal(mul(mul(u,j),u.T),j)
    assert np.array_equal(mul(stabilizers,u),stabilizers)
    assert np.array_equal(mul(logicals,u),target)
    assert np.array_equal(u[:18,18:],mul(x[0,:,None],x[0,None,:]))
    assert np.array_equal(u[18:,:18],mul(z[0,:,None],z[0,None,:]))
    assert np.array_equal(u[:18,:18],u[18:,18:].T)
    # Animate elimination rather than physical application, avoiding an
    # ambiguous visual time direction: U * P(last) * ... * P(first) = I.
    state = u.copy()
    frames = [matrix_frame(state,"Toric d=3: 36 x 36 symplectic matrix", "Start: the logical H1 I2 matrix from Eq. S54")]
    for step,op in enumerate(reversed(gates),1):
        state = mul(state,gate(18,*op))
        assert np.array_equal(mul(mul(state,j),state.T),j)
        if step % 4 == 0 or op[0] != "CNOT" or step == len(gates):
            kind,i,k = op
            label = f"{kind}({i}"+(f",{k}" if k else "")+")"
            if kind == "H":
                active = (i-1,i+17)
            elif kind == "SWAP":
                active = (i-1,k-1,i+17,k+17)
            else:
                active = (i-1,k+17)
            frames.append(matrix_frame(state,"Toric d=3: 36 x 36 symplectic matrix",f"Elimination {step}/81: right multiply by {label}",active))
    assert np.array_equal(state,np.eye(36,dtype=np.uint8))
    frames.append(matrix_frame(state,"Toric d=3: 36 x 36 symplectic matrix","Final: I36. Synthesize U using inverse physical gates"))
    save_animation(frames,"appendix-toric.gif",[1800]+[700]*(len(frames)-2)+[2200])
    counts = {kind:sum(op[0]==kind for op in gates) for kind in ("CNOT","SWAP","H")}
    report = {"n":18,"k":2,"rank_HZ":rank(hz),"rank_HX":rank(hx),"gates":counts,
              "CNOT_equivalents":counts["CNOT"]+3*counts["SWAP"],
              "symplectic":True,"stabilizers_fixed":True,"logical_target":True,
              "S53_blocks":True,"all_elimination_steps_symplectic":True,
              "phase_checked":False,"toy_start":toy_start}
    # Independently exercise the actual lifted construction, including the
    # missing rank argument, with targets of different logical block forms.
    report["lifted_construction"] = {}
    for name,p in [("I",np.eye(4,dtype=np.uint8)),("H1",gate(2,"H",1)),
                   ("S1",gate(2,"S",1)),("CNOT12",gate(2,"CNOT",1,2))]:
        report["lifted_construction"][name] = construct_lifted_solution(hz,hx,z,x,mul(p,logicals))
    # Unequal stabilizer ranks and a missing stabilizer type exercise the
    # rank argument without the paper's n_Z >= n_X / transposed branches.
    for nz,nx in [(1,2),(2,1),(0,1),(1,0),(0,0)]:
        n = nz+nx+2
        eye = np.eye(n,dtype=np.uint8)
        hz0,hx0 = eye[:nz],eye[nz:nz+nx]
        z0,x0 = eye[nz+nx:].copy(),eye[nz+nx:].copy()
        physical = np.eye(2*n,dtype=np.uint8)
        for step in range(2*n):
            i,j = step%n+1,(step+1)%n+1
            physical = mul(physical,gate(n,"CNOT",i,j))
        hz0,hx0 = mul(hz0,physical[:n,:n]),mul(hx0,physical[n:,n:])
        z0,x0 = mul(z0,physical[:n,:n]),mul(x0,physical[n:,n:])
        l0 = np.block([[z0,np.zeros_like(z0)],[np.zeros_like(x0),x0]])
        target0 = mul(gate(2,"H",1),l0)
        try:
            check = construct_lifted_solution(hz0,hx0,z0,x0,target0)
            check["sparse_lift_consistent"] = True
        except ValueError:
            # Independent pivot right inverses need not admit S=T=0.
            # Preserve the counterexample rather than silently choosing
            # different inputs or claiming the sparse ansatz is universal.
            j0 = symplectic_form(n)
            pinv = mul(mul(j0,physical.T),j0)
            full_u = mul(mul(pinv,gate(n,"H",nz+nx+1)),physical)
            h0 = np.block([[hz0,np.zeros_like(hz0)],[np.zeros_like(hx0),hx0]])
            assert np.array_equal(mul(mul(full_u,j0),full_u.T),j0)
            assert np.array_equal(mul(h0,full_u),h0)
            assert np.array_equal(mul(l0,full_u),target0)
            check = {"n_Z":nz,"n_X":nx,"sparse_lift_consistent":False,
                     "independent_pivot_right_inverses":True,
                     "known_full_solution_verified":True,
                     "H_Z":hz0.tolist(),"H_X":hx0.tolist(),
                     "logical_Z":z0.tolist(),"logical_X":x0.tolist(),
                     "target":target0.tolist(),"full_U":full_u.tolist(),
                     "note":"S=T=0 is inconsistent for these chosen B blocks. This is not a no-go for logical Clifford operations."}
        report["lifted_construction"][f"unequal_{nz}_{nx}"] = check
    (OUT/"appendix-verification.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
    print(json.dumps(report,indent=2))


if __name__ == "__main__":
    main()

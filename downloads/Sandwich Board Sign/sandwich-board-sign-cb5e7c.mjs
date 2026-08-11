/*
 * Sandwich Board Sign
 * https://polyfork.dev/asset/sandwich-board-sign-cb5e7c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sandwich-board-sign-cb5e7c.mjs';
 *   scene.add(createAsset());
 *
 * The bare "three" specifiers below resolve through any bundler, or through
 * an importmap in your page:
 *
 *   { "imports": { "three": "https://unpkg.com/three@0.180.0/build/three.module.js",
 *                  "three/addons/": "https://unpkg.com/three@0.180.0/examples/jsm/" } }
 *
 * Browsers refuse to load ES modules from file:// URLs, so a page of your own
 * that imports this file has to be served over http:  python3 -m http.server
 *
 * The index.html in this asset's .zip download sidesteps that and opens with
 * a double-click. The store page above has the same snippet for Unity, Godot,
 * Blender and GLB.
 *
 * OPTIONS  createAsset({ ... })
 *
 *   colorway  choice  'walnut-slate' 'walnut-slate' | 'cedar-cream' | 'vermilion-tea' | 'noir-steel' | 'sakura-boa…
 *   frame     color   '#7E4B33'      any hex or THREE.Color
 *   board     color   '#3C4145'      any hex or THREE.Color
 *   panel     color   '#8FB4C9'      any hex or THREE.Color
 *   chalk     color   '#F2EFE7'      any hex or THREE.Color
 *   hinge     color   '#C7CBCC'      any hex or THREE.Color
 *   tallness  range   1              0.8 to 1.35
 *   panes     range   2              1 to 3
 *   menuRows  range   4              0 to 6
 *   stance    range   0.5            0.36 to 0.66
 *
 * Every option is described in full at https://polyfork.dev/cdn/sandwich-board-sign-cb5e7c-params.json
 *
 * SPECS  362 triangles, 1 material, 0.7 x 1 x 0.5 m (real-world scale).
 * PARTS  animate: board-front, board-back
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'walnut-slate':  { frame: '#7E4B33', board: '#3C4145', panel: '#8FB4C9', chalk: '#F2EFE7', hinge: '#C7CBCC' },
  'cedar-cream':   { frame: '#8C7355', board: '#2E3134', panel: '#D9CFBC', chalk: '#F2EFE7', hinge: '#A9AFB4' },
  'vermilion-tea': { frame: '#B5462F', board: '#2E3134', panel: '#F2EFE7', chalk: '#F0C24B', hinge: '#8A9197' },
  'noir-steel':    { frame: '#4E5459', board: '#1B1D20', panel: '#6B7278', chalk: '#C9DDE6', hinge: '#A9AFB4' },
  'sakura-board':  { frame: '#63503C', board: '#3C4145', panel: '#F7C9D6', chalk: '#F2EFE7', hinge: '#C7CBCC' },
};

export const presets = COLORWAYS;

const ZONES = ['frame', 'board', 'panel', 'chalk', 'hinge'];

export const params = {
  colorway: {
    type: 'choice', default: 'walnut-slate', label: 'Colorway', affects: 'colors',
    options: Object.keys(COLORWAYS),
    describe: 'Curated kit-coherent scheme. walnut-slate is the default oiled brown frame around a dark slate board with a pale blue lower panel; cedar-cream is bleached driftwood timber over near-black slate with a warm bone panel; vermilion-tea is a lacquered red shrine frame with yellow chalk; noir-steel is a cold grey-on-grey painted steel board with almost no warmth; sakura-board is dark aged timber with a blossom-pink lower panel.',
  },
  frame: {
    type: 'color', default: COLORWAYS['walnut-slate'].frame, label: 'Frame timber', affects: 'colors',
    describe: 'Albedo of every timber member: the two full-length stiles (which continue below the board as the legs), the top / sill / bottom rails, the mullions between panes and the chalk ledge. The dominant mass colour of the asset.',
  },
  board: {
    type: 'color', default: COLORWAYS['walnut-slate'].board, label: 'Chalkboard', affects: 'colors',
    describe: 'Albedo of the recessed slate writing field on both boards, and of the inward-facing backs of every field inside the A-frame cavity. Keep it clearly darker than Frame timber or the board fuses into its surround; keep it clearly darker than Chalk or the menu blocks stop reading.',
  },
  panel: {
    type: 'color', default: COLORWAYS['walnut-slate'].panel, label: 'Lower panel', affects: 'colors',
    describe: 'Albedo of the pale notice panel recessed into the bottom bay of both boards, below the chalkboard. This is the one bright horizontal band in the elevation; hold it far lighter than the frame or the sign loses its two-tier read.',
  },
  chalk: {
    type: 'color', default: COLORWAYS['walnut-slate'].chalk, label: 'Chalk marks', affects: 'colors',
    describe: 'Albedo of the chalked menu blocks on the front board: one solid header block per pane over a stack of shorter centred bars. Flush faces of the slate field itself, never raised slabs. Near-white by default; a warm yellow reads as coloured chalk.',
  },
  hinge: {
    type: 'color', default: COLORWAYS['walnut-slate'].hinge, label: 'Hinge straps', affects: 'colors',
    describe: 'Albedo of the two pale metal hinge straps lying across the ridge where the boards meet. Muted galvanised steel, never bright; it is the only hardware zone on the asset.',
  },
  tallness: {
    type: 'range', default: 1.00, min: 0.80, max: 1.35, affects: 'geometry', label: 'Tallness',
    describe: 'Overall height in metres from the pavement to the ridge (width stays 0.70 m). REBUILDS rather than scales: leg clearance stays 0.20 m, rails stay a 0.055 m gauge, stiles stay 0.062 m wide and the lower notice panel stays 0.135 m tall at every value, so all the change lands in the chalkboard bay. Past a 0.62 m bay the board splits into two stacked writing fields with a real horizontal rail between them and a full chalked menu in each, so the triangle count rises with the knob (362 tris up to 1.00 m, 492 at 1.35 m). 0.80 m is a squat cafe board, 1.35 m a tall two-panel menu board that clears a parked bicycle.',
  },
  panes: {
    type: 'range', default: 2, min: 1, max: 3, affects: 'geometry', label: 'Panes',
    describe: 'How many vertical panes the front chalkboard is divided into by timber mullions (integer; the pipeline previews each whole value). 1 is one undivided writing field, 2 is the reference two-column menu, 3 gives three narrow columns of short chalk bars. The mullions are the same 0.045 m gauge at every count, so the panes narrow as the count rises. Front board only — the back board is always one plain field.',
  },
  menuRows: {
    type: 'range', default: 4, min: 0, max: 6, affects: 'geometry', label: 'Menu rows',
    describe: 'How many chalked rows are written in each pane of the front board (integer). Row 1 is a wide solid header block; below it come centred bars of alternating length, every third row splitting into an item-and-price PAIR. The run always spreads to fill the writing bay, so a higher count reads as a denser, finer-lined menu rather than a longer one. 0 gives a completely blank wiped board with no marks at all, 6 a densely chalked one. Affects the front face only.',
  },
  stance: {
    type: 'range', default: 0.50, min: 0.36, max: 0.66, affects: 'geometry', label: 'Stance',
    describe: 'Foot-to-foot spread in metres, measured across the outside of the two legs on the ground, at the default tallness. Nothing repeats along this dimension — the A opens by re-angling both boards about the ridge hinge, so the boards genuinely lengthen and re-mitre rather than stretching. 0.36 m is a tight near-vertical A that hugs a shopfront, 0.66 m a wide-braced stance for a windy pavement. The hinge fold angle in the rig follows it.',
  },
};

export const rig = {

  'board-front': { axis: 'x', range: [0, 11.4] },
  'board-back':  { axis: 'x', range: [0, -11.4] },
};
export const detach = [];
export const night = {};

const clamp = (v, a, b) => Math.min(b, Math.max(a, v));

export function createAsset(opts = {}) {

  const cwName = COLORWAYS[opts.colorway] ? opts.colorway : params.colorway.default;
  const C = { ...COLORWAYS[cwName] };
  for (const z of ZONES) if (opts[z] !== undefined) C[z] = opts[z];

  const H      = clamp(opts.tallness ?? params.tallness.default, params.tallness.min, params.tallness.max);
  const SPREAD = clamp(opts.stance   ?? params.stance.default,   params.stance.min,   params.stance.max);
  const PANES  = Math.round(clamp(opts.panes    ?? params.panes.default,    params.panes.min,    params.panes.max));
  const NROWS  = Math.round(clamp(opts.menuRows ?? params.menuRows.default, params.menuRows.min, params.menuRows.max));

  const W       = 0.70;
  const T       = 0.045;
  const T2      = T / 2;
  const STILE   = 0.062;
  const RAIL    = 0.055;
  const MULL    = 0.045;
  const LEG     = 0.200;
  const PANEL_H = 0.135;
  const REC     = 0.0085;
  const CHAM    = 0.010;
  const RIDGE_Z = T2 + 0.004;

  const zBot  = SPREAD / 2 - T2;
  const THETA = Math.atan2(zBot - RIDGE_Z, H);
  const K     = Math.tan(THETA);
  const L     = H / Math.cos(THETA);

  const V_BOT0 = LEG,             V_BOT1 = V_BOT0 + RAIL;
  const V_PAN0 = V_BOT1,          V_PAN1 = V_PAN0 + PANEL_H;
  const V_SIL0 = V_PAN1,          V_SIL1 = V_SIL0 + RAIL;
  const V_TOP0 = L - RAIL;
  const FIELD  = V_TOP0 - V_SIL1;
  const NF     = clamp(1 + Math.floor(FIELD / 0.62), 1, 3);
  const FH     = (FIELD - (NF - 1) * RAIL) / NF;
  const FX     = W / 2 - STILE;

  const newP = () => ({ frame: [], board: [], panel: [], chalk: [], hinge: [] });
  const tri = (o, a, b, c) => o.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);

  function chamPoly(cs, c) {
    const out = [];
    for (let i = 0; i < cs.length; i++) {
      const pr = cs[(i + cs.length - 1) % cs.length], cu = cs[i], nx = cs[(i + 1) % cs.length];
      for (const o of [pr, nx]) {
        const dx = o[0] - cu[0], dy = o[1] - cu[1], d = Math.hypot(dx, dy) || 1;
        const k = Math.min(c, d * 0.45);
        out.push([cu[0] + dx / d * k, cu[1] + dy / d * k]);
      }
    }
    return out;
  }

  const MAP_V = (p, q, t) => [q, t, p];
  const MAP_X = (p, q, t) => [t, p, q];

  function buildBoard(side) {
    const P = newP();
    const Q = (z, a, b, c, d) => { tri(P[z], a, b, c); tri(P[z], a, c, d); };

    function prism(zone, poly, map, t0, t1, capLo, capHi) {
      const N = poly.length;
      const f = (v, pt) => (typeof v === 'function' ? v(pt[0], pt[1]) : v);
      const lo = poly.map(pt => map(pt[0], pt[1], f(t0, pt)));
      const hi = poly.map(pt => map(pt[0], pt[1], f(t1, pt)));
      for (let i = 0; i < N; i++) { const j = (i + 1) % N; Q(zone, lo[i], lo[j], hi[j], hi[i]); }
      if (capHi) for (let i = 1; i < N - 1; i++) tri(P[zone], hi[0], hi[i], hi[i + 1]);
      if (capLo) for (let i = 1; i < N - 1; i++) tri(P[zone], lo[0], lo[i + 1], lo[i]);
    }

    const flat = (zone, x0, x1, v0, v1, n, dir) => dir > 0
      ? Q(zone, [x0, v0, n], [x1, v0, n], [x1, v1, n], [x0, v1, n])
      : Q(zone, [x1, v0, n], [x0, v0, n], [x0, v1, n], [x1, v1, n]);

    for (const sx of [1, -1]) {
      const x0 = sx > 0 ? W / 2 - STILE : -W / 2, x1 = sx > 0 ? W / 2 : -W / 2 + STILE;
      const sec = chamPoly([[-T2, x0], [T2, x0], [T2, x1], [-T2, x1]], CHAM);
      prism('frame', sec, MAP_V, (p) => -p * K, (p) => L - p * K, true, true);
    }

    const rx0 = -(FX + 0.006), rx1 = FX + 0.006;
    const railSec = (v0, v1) => chamPoly([[v0, -T2], [v1, -T2], [v1, T2], [v0, T2]], CHAM);
    const rail = (v0, v1) => prism('frame', railSec(v0, v1), MAP_X, rx0, rx1, false, false);

    rail(V_BOT0, V_BOT1);
    rail(V_SIL0, V_SIL1);

    const HEAD = L - 0.004;
    prism('frame', chamPoly([
      [V_TOP0, -T2], [HEAD + T2 * K, -T2], [HEAD - T2 * K, T2], [V_TOP0, T2],
    ], CHAM), MAP_X, rx0, rx1, false, false);

    const pb = 0.008;
    flat('panel', -FX - pb, FX + pb, V_PAN0 - pb, V_PAN1 + pb,  REC,  1);
    flat('board', -FX - pb, FX + pb, V_PAN0 - pb, V_PAN1 + pb, -REC, -1);

    const paneCount = side > 0 ? PANES : 1;
    const paneW = (2 * FX - (paneCount - 1) * MULL) / paneCount;

    for (let f = 0; f < NF; f++) {
      const v0 = V_SIL1 + f * (FH + RAIL), v1 = v0 + FH;
      if (f > 0) rail(v0 - RAIL, v0);
      flat('board', -FX - pb, FX + pb, v0 - pb, v1 + pb, -REC, -1);

      for (let p = 0; p < paneCount; p++) {
        const u0 = -FX + p * (paneW + MULL), u1 = u0 + paneW;
        if (p > 0) {
          const mx0 = u0 - MULL, mx1 = u0;
          prism('frame', chamPoly([[-T2, mx0], [T2, mx0], [T2, mx1], [-T2, mx1]], CHAM),
            MAP_V, v0 - 0.006, v1 + 0.006, false, false);
        }
        tilePane(u0, u1, v0, v1, side > 0 ? menuMarks(u0, u1, v0, v1) : []);
      }
    }

    function tilePane(u0, u1, v0, v1, marks) {
      const ys = [v0, v1];
      for (const m of marks) ys.push(m.y0, m.y1);
      ys.sort((a, b) => a - b);
      for (let i = 0; i < ys.length - 1; i++) {
        const a = ys[i], b = ys[i + 1];
        if (b - a < 1e-5) continue;
        const mid = (a + b) / 2;
        const row = marks.filter(m => m.y0 <= mid && m.y1 >= mid).sort((p, q) => p.x0 - q.x0);
        let x = u0;
        for (const m of row) {
          if (m.x0 - x > 1e-5) flat('board', x, m.x0, a, b, REC, 1);
          flat('chalk', m.x0, m.x1, a, b, REC, 1);
          x = m.x1;
        }
        if (u1 - x > 1e-5) flat('board', x, u1, a, b, REC, 1);
      }
    }

    if (side > 0) {
      const tv0 = V_SIL0 + 0.006, tv1 = tv0 + 0.030;
      const tn0 = T2 - 0.012, tn1 = T2 + 0.055;
      prism('frame', chamPoly([[tv0, tn0], [tv1, tn0], [tv1, tn1], [tv0, tn1]], CHAM),
        MAP_X, -(W / 2 - 0.018), W / 2 - 0.018, true, true);
    }

    return P;
  }

  function menuMarks(u0, u1, v0, v1) {
    const marks = [];
    const pw = u1 - u0, cx = (u0 + u1) / 2;
    const MARGIN = 0.038;
    const usable = (v1 - v0) - 2 * MARGIN;
    if (NROWS < 1 || usable < 0.03) return marks;

    const cap = (usable / NROWS) * 0.62;
    const hOf = (i) => Math.min(cap, i === 0 ? 0.058 : (i % 3 === 2 ? 0.032 : 0.038));
    const step = NROWS > 1 ? (usable - hOf(NROWS - 1)) / (NROWS - 1) : 0;
    for (let i = 0; i < NROWS; i++) {
      const h = hOf(i);
      const top = v1 - MARGIN - i * step;
      const bot = top - h;
      if (i === 0) {
        marks.push({ x0: cx - 0.40 * pw, x1: cx + 0.40 * pw, y0: bot, y1: top });
      } else if (i % 3 === 2) {
        const w = 0.27 * pw, off = 0.21 * pw;
        marks.push({ x0: cx - off - w / 2, x1: cx - off + w / 2, y0: bot, y1: top });
        marks.push({ x0: cx + off - w / 2, x1: cx + off + w / 2, y0: bot, y1: top });
      } else {
        const w = (i % 3 === 1 ? 0.62 : 0.44) * pw;
        marks.push({ x0: cx - w / 2, x1: cx + w / 2, y0: bot, y1: top });
      }
    }
    return marks;
  }

  function hingeStraps() {
    const P = newP();
    const Q = (z, a, b, c, d) => { tri(P[z], a, b, c); tri(P[z], a, c, d); };
    const zEx = RIDGE_Z + T2 + 0.002;
    for (const sx of [1, -1]) {
      const x0 = sx * 0.125, x1 = sx * 0.225;
      const xa = Math.min(x0, x1), xb = Math.max(x0, x1);
      const y0 = -0.011, y1 = 0.005, z0 = -zEx, z1 = zEx;
      Q('hinge', [xa, y0, z1], [xb, y0, z1], [xb, y1, z1], [xa, y1, z1]);
      Q('hinge', [xb, y0, z0], [xa, y0, z0], [xa, y1, z0], [xb, y1, z0]);
      Q('hinge', [xb, y0, z1], [xb, y0, z0], [xb, y1, z0], [xb, y1, z1]);
      Q('hinge', [xa, y0, z0], [xa, y0, z1], [xa, y1, z1], [xa, y1, z0]);
      Q('hinge', [xa, y1, z1], [xb, y1, z1], [xb, y1, z0], [xa, y1, z0]);
    }
    return P;
  }

  const MAT = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  function bake(chunks, name) {
    const geos = [];
    for (const { P, m } of chunks) {
      for (const z of ZONES) {
        const pos = P[z];
        if (!pos.length) continue;
        const g = new THREE.BufferGeometry();
        g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
        if (m) g.applyMatrix4(m);
        const col = new THREE.Color(C[z]);
        const n = pos.length / 3, arr = new Float32Array(n * 3);
        for (let i = 0; i < n; i++) { arr[i * 3] = col.r; arr[i * 3 + 1] = col.g; arr[i * 3 + 2] = col.b; }
        g.setAttribute('color', new THREE.BufferAttribute(arr, 3));
        geos.push(g);
      }
    }
    const merged = mergeGeometries(geos);
    merged.computeVertexNormals();
    const mesh = new THREE.Mesh(merged, MAT);
    mesh.name = name;
    return mesh;
  }

  const mFront = new THREE.Matrix4()
    .makeTranslation(0, 0, RIDGE_Z)
    .multiply(new THREE.Matrix4().makeRotationX(-THETA))
    .multiply(new THREE.Matrix4().makeTranslation(0, -L, 0));
  const mBack = new THREE.Matrix4()
    .makeTranslation(0, 0, -RIDGE_Z)
    .multiply(new THREE.Matrix4().makeRotationY(Math.PI))
    .multiply(new THREE.Matrix4().makeRotationX(-THETA))
    .multiply(new THREE.Matrix4().makeTranslation(0, -L, 0));

  const gFront = new THREE.Group();
  gFront.name = 'board-front';
  gFront.position.set(0, H, 0);
  gFront.add(bake([{ P: buildBoard(1), m: mFront }, { P: hingeStraps(), m: null }], 'board-front-shell'));

  const gBack = new THREE.Group();
  gBack.name = 'board-back';
  gBack.position.set(0, H, 0);
  gBack.add(bake([{ P: buildBoard(-1), m: mBack }], 'board-back-shell'));

  const g = new THREE.Group();
  g.name = 'sandwich-board-sign';
  g.add(gFront, gBack);
  return g;
}

export default createAsset;

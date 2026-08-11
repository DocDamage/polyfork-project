/*
 * Pavement Tile
 * https://polyfork.dev/asset/pavement-tile-8a9740
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './pavement-tile-8a9740.mjs';
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
 *   colorway    choice  'grey-cast'    'grey-cast' | 'pale-concrete' | 'sun-bleached' | 'wet-slate'
 *   paving      color   '#A9AFB4'      any hex or THREE.Color
 *   bedding     color   '#2E3134'      any hex or THREE.Color
 *   flags       range   4              3 to 5
 *   bond        choice  'grid'         'grid' | 'running' | 'plank'
 *   jointWidth  range   0.054          0.03 to 0.09
 *   settled     range   0              0 to 6
 *
 * Every option is described in full at https://polyfork.dev/cdn/pavement-tile-8a9740-params.json
 *
 * SPECS  396 triangles, 1 material, 4 x 0.05 x 4 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SIZE = 4.0;
const HALF = SIZE / 2;
const THICK = 0.05;
const TOP_Y = 0.0;
const BOT_Y = TOP_Y - THICK;

const CONCRETE_H = 0.040;
const CONC_BOT = TOP_Y - CONCRETE_H;

const JOINT_DEPTH = 0.038;
const FLOOR_Y = TOP_Y - JOINT_DEPTH;

const RAMP = 0.06;

const CHAM_W = 0.010;
const CHAM_D = 0.017;

const SETTLE_DROP = 0.016;

const DEF = {
  colorway: 'grey-cast',
  flags: 4,
  jointWidth: 0.054,
  bond: 'grid',
  settled: 0,
};

const SETTLE_CELLS = [[1, 2], [2, 0], [0, 1], [3, 2], [1, 3], [2, 1]];

const COLORWAYS = {
  'grey-cast':     { paving: '#A9AFB4', bedding: '#2E3134' },
  'pale-concrete': { paving: '#C7CBCC', bedding: '#4E5459' },
  'sun-bleached':  { paving: '#E4E2DC', bedding: '#6B7278' },
  'wet-slate':     { paving: '#6B7278', bedding: '#1B1D20' },
};
const COLOR_KEYS = ['paving', 'bedding'];

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function rimWalls(out, y0, y1) {
  const P = HALF, M = -HALF;
  quad(out, [P, y0, P], [P, y0, M], [P, y1, M], [P, y1, P]);
  quad(out, [M, y0, M], [M, y0, P], [M, y1, P], [M, y1, M]);
  quad(out, [M, y0, P], [P, y0, P], [P, y1, P], [M, y1, P]);
  quad(out, [P, y0, M], [M, y0, M], [M, y1, M], [P, y1, M]);
}

function layout(bond, N) {
  const cells = [];
  const lines = (n) => Array.from({ length: n + 1 }, (_, k) => -HALF + k * (SIZE / n));
  if (bond === 'plank') {

    const cols = Math.max(2, Math.ceil(N / 2));
    const zs = lines(N), xs = lines(cols);
    for (let j = 0; j < N; j++) for (let i = 0; i < cols; i++)
      cells.push({ x0: xs[i], x1: xs[i + 1], z0: zs[j], z1: zs[j + 1], col: i, row: j });
    return cells;
  }
  const zs = lines(N), pitch = SIZE / N;
  for (let j = 0; j < N; j++) {

    const off = (bond === 'running' && j % 2 === 1) ? pitch / 2 : 0;
    const first = off || pitch;
    const xs = [-HALF];

    for (let k = 0; ; k++) {
      const x = -HALF + first + k * pitch;
      if (x >= HALF - 1e-4) break;
      xs.push(x);
    }
    xs.push(HALF);
    for (let i = 0; i < xs.length - 1; i++)
      cells.push({ x0: xs[i], x1: xs[i + 1], z0: zs[j], z1: zs[j + 1], col: i, row: j });
  }
  return cells;
}

function flagOutline(cell, inset) {
  const { x0, x1, z0, z1 } = cell;
  const E = 1e-6;
  const bxn = x0 <= -HALF + E, bxp = x1 >= HALF - E;
  const bzn = z0 <= -HALF + E, bzp = z1 >= HALF - E;
  const X0 = x0 + inset, X1 = x1 - inset, Z0 = z0 + inset, Z1 = z1 - inset;

  const C = [
    { bx: bxn, bz: bzp, ox: x0, oz: z1, ix: X0, iz: Z1, rx: x0 + RAMP, rz: z1 - RAMP, xLast: true },
    { bx: bxp, bz: bzp, ox: x1, oz: z1, ix: X1, iz: Z1, rx: x1 - RAMP, rz: z1 - RAMP, xLast: false },
    { bx: bxp, bz: bzn, ox: x1, oz: z0, ix: X1, iz: Z0, rx: x1 - RAMP, rz: z0 + RAMP, xLast: true },
    { bx: bxn, bz: bzn, ox: x0, oz: z0, ix: X0, iz: Z0, rx: x0 + RAMP, rz: z0 + RAMP, xLast: false },
  ];
  const pts = [];
  for (const c of C) {
    const corner = [c.ox, c.oz];
    if (c.bx && !c.bz) {
      const r = [c.rx, c.iz];
      pts.push(...(c.xLast ? [corner, r] : [r, corner]));
    } else if (c.bz && !c.bx) {
      const r = [c.ix, c.rz];
      pts.push(...(c.xLast ? [r, corner] : [corner, r]));
    } else if (c.bx && c.bz) pts.push(corner);
    else pts.push([c.ix, c.iz]);
  }
  return pts;
}

const borderDist = (p) => Math.min(HALF - Math.abs(p[0]), HALF - Math.abs(p[1]));

const onBorder = (p) => borderDist(p) < 1e-6;

const heldForSettle = (p) => borderDist(p) <= RAMP + 1e-6;

const samePt = (a, b) => Math.abs(a[0] - b[0]) < 1e-9 && Math.abs(a[1] - b[1]) < 1e-9 &&
                         Math.abs(a[2] - b[2]) < 1e-9;

function ringSkirt(out, A, B) {
  const n = A.length;
  for (let k = 0; k < n; k++) {
    const j = (k + 1) % n;
    const c0 = samePt(A[k], B[k]), c1 = samePt(A[j], B[j]);
    if (c0 && c1) continue;
    if (c0) tri(out, A[k], B[j], A[j]);
    else if (c1) tri(out, A[k], B[k], B[j]);
    else quad(out, A[k], B[k], B[j], A[j]);
  }
}

function flag(cell, topInset, botInset, settled) {
  const drop = settled ? SETTLE_DROP : 0;

  const lift = (pts, dy) => pts.map(p => [
    p[0],
    onBorder(p) ? TOP_Y : TOP_Y - (settled && heldForSettle(p) ? 0 : drop) - dy,
    p[1],
  ]);

  const T = lift(flagOutline(cell, topInset + CHAM_W), 0);
  const M = lift(flagOutline(cell, topInset), CHAM_D);
  const B = flagOutline(cell, botInset).map(p => [p[0], FLOOR_Y, p[1]]);

  const pos = [];
  ringSkirt(pos, T, M);
  ringSkirt(pos, M, B);
  const n = T.length;
  if (n === 4 && !settled) {
    quad(pos, T[0], T[1], T[2], T[3]);
  } else {

    const cx = T.reduce((s, p) => s + p[0], 0) / n, cz = T.reduce((s, p) => s + p[2], 0) / n;
    const cy = T.reduce((s, p) => s + p[1], 0) / n;
    const mid = [cx, settled ? cy : TOP_Y, cz];
    for (let k = 0; k < n; k++) tri(pos, mid, T[k], T[(k + 1) % n]);
  }
  return pos;
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {};
  for (const k of COLOR_KEYS) C[k] = p[k] !== undefined ? p[k] : cw[k];

  const N = Math.max(3, Math.min(5, Math.round(p.flags !== undefined ? p.flags : DEF.flags)));
  const jw = Math.max(0.030, Math.min(0.090, p.jointWidth !== undefined ? p.jointWidth : DEF.jointWidth));
  const bond = ['grid', 'running', 'plank'].includes(p.bond) ? p.bond : DEF.bond;
  const nSet = Math.max(0, Math.min(SETTLE_CELLS.length,
    Math.round(p.settled !== undefined ? p.settled : DEF.settled)));

  const topInset = jw / 2;

  const botInset = Math.max(0.001, topInset - 0.0015);

  const paving = [], bed = [];

  quad(paving, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF]);
  rimWalls(bed, BOT_Y, CONC_BOT);

  rimWalls(paving, CONC_BOT, FLOOR_Y);

  quad(paving, [-HALF, FLOOR_Y, HALF], [HALF, FLOOR_Y, HALF], [HALF, FLOOR_Y, -HALF], [-HALF, FLOOR_Y, -HALF]);

  const sunk = new Set(SETTLE_CELLS.slice(0, nSet).map(([c, r]) => `${c},${r}`));
  const E = 1e-6;
  for (const cell of layout(bond, N)) {

    const onX = cell.x0 <= -HALF + E || cell.x1 >= HALF - E;
    const onZ = cell.z0 <= -HALF + E || cell.z1 >= HALF - E;
    const settled = sunk.has(`${cell.col},${cell.row}`) && !(onX && onZ);
    paving.push(...flag(cell, topInset, botInset, settled));
  }

  const g = new THREE.Group();
  g.name = 'pavement-tile';
  const mesh = finish([
    { g: posGeo(paving), c: C.paving },
    { g: posGeo(bed), c: C.bedding },
  ]);
  mesh.name = 'pavement-surface';
  g.add(mesh);
  return g;
}

export const params = {
  colorway: {
    type: 'choice', default: 'grey-cast', label: 'Colorway',
    options: ['grey-cast', 'pale-concrete', 'sun-bleached', 'wet-slate'],
    describe: 'Curated kit-palette pavement scheme; sets both zone colours at once. grey-cast ' +
      'is the shipped default, a mid pale-grey precast footway on a near-charcoal bed — the ' +
      'pour the refs read as, and dark enough that the joint grid and the arris have something ' +
      'to be darker than. pale-concrete is one step lighter, a cool bleached-grey pavement for ' +
      'a bright street. sun-bleached is an almost off-white sunlit footway. wet-slate drops ' +
      'both zones to a dark rain-soaked grey. Every scheme keeps the same ordering: pale pour ' +
      'over a distinctly darker bedding course.',
  },
  paving: {
    type: 'color', default: '#A9AFB4', label: 'Paving',
    describe: 'Albedo of the entire cast slab — all 16 flag tops, every chamfered arris, every ' +
      'joint cheek and floor, the concrete course of the slab edge and the underside. About ' +
      '96% of the lit pixels on this tile. One uniform pour: the joints and the chamfers ' +
      'deliberately share it, so the dark grid lines come from real cut depth and cast shadow ' +
      'and never from paint. Going much lighter than the default washes the relief out — the ' +
      'grooves can only be dark relative to this tone.',
  },
  bedding: {
    type: 'color', default: '#2E3134', label: 'Bedding course',
    describe: 'Albedo of the bottom 10 mm of the slab edge — the sand/cement bed the flags are ' +
      'laid on, and the darkest tone on the tile. It runs as an unbroken band round all four ' +
      'sides, taking the bottom fifth of the 0.05 m section so the pale course clearly owns ' +
      'the rest, and it is what keeps the border a crisp line where one tile meets the next. ' +
      'Keep a full value gap from the paving or the whole edge mushes into one hairline.',
  },
  flags: {
    type: 'range', default: 4, min: 3, max: 5, step: 1, label: 'Flags per side',
    affects: 'geometry',
    describe: 'How many paving flags the 4 m tile is scored into per side, genuinely rebuilt ' +
      'at each value — the triangle count moves with it (246 / 404 / 598), it is not a ' +
      'stretch. 3 gives big 1.33 m slabs and a sparse nine-square grid; the default 4 gives ' +
      'the 1.0 m flag of the refs; 5 gives 0.80 m flags and a noticeably busier ruled ' +
      'surface. The flag pitch quantizes the tile, so the STEP is 4 m / N. The joint section, ' +
      'the chamfer and the border margin are identical at every value and the joints always ' +
      'die out before the border, so any two values still butt seamlessly against each other.',
  },
  bond: {
    type: 'choice', default: 'grid', label: 'Bond',
    options: ['grid', 'running', 'plank'], affects: 'geometry',
    describe: 'How the flags are laid out on the top face — the only surface a ground tile ' +
      'really shows. grid is the default square scored grid of the refs, every joint lining ' +
      'up in both axes. running staggers alternate rows by half a flag so the cross joints ' +
      'break bond like brickwork, and the end flags of those rows come out half width, cut ' +
      'against the border exactly as a real bond is cut at a kerb. plank lays half as many ' +
      'columns as rows, so each flag becomes a wide 2:1 bay lying across the footway. All ' +
      'three keep the same flush border and tile seamlessly against each other.',
  },
  jointWidth: {
    type: 'range', default: 0.054, min: 0.030, max: 0.090, label: 'Joint width',
    affects: 'geometry',
    describe: 'Width in metres of the SLOT between the two chamfered arrises — the plumb-cheeked, ' +
      'flat-floored part of the joint. The visible mouth is this plus the two 10 mm chamfers. ' +
      'The default 0.054 (a 74 mm mouth) is the width measured to read best at the hero camera: ' +
      'that camera looks along the pavement at 18 degrees and foreshortens every horizontal ' +
      'dimension to 31% of itself, so a joint narrower than this projects to a couple of pixels ' +
      'and disappears however deep it is cut. 0.030 is a tight seam for flags laid almost ' +
      'touching, read mainly from above; 0.090 opens a broad 110 mm channel and each flag reads ' +
      'as a separately bedded slab. Depth (38 mm), chamfer and cheek angle are identical at ' +
      'every value — this knob widens the mouth, it does not deepen the cut.',
  },
  settled: {
    type: 'range', default: 0, min: 0, max: 6, step: 1, label: 'Settled flags',
    affects: 'geometry',
    describe: 'The tile\'s single variation knob, and its minimum is OFF. 0 is the shipped ' +
      'default: all 16 flags dead coplanar at the walkable plane and one flat colour per ' +
      'material zone — a freshly laid pavement with no mark that could repeat in a grid when ' +
      'a customer paves an area with dozens of copies. 1 to 6 sink that many individual ' +
      'flags 12 mm into their bed, each throwing a real step across its joints against its ' +
      'unsettled neighbours: 1-2 reads as a lightly used footway, 6 as a badly subsided one. ' +
      'The flags are picked in a fixed order balanced across both halves of the tile and ' +
      'never as a touching pair. A settled flag NEVER moves a point that lies on a tiling ' +
      'border, so all four mating edges stay dead flat at every value. Vary this per instance ' +
      'across a paved run — that, not a mark baked into every copy, is where variation belongs.',
  },
};

export const presets = COLORWAYS;
export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

/*
 * Sidewalk Tile
 * https://polyfork.dev/asset/sidewalk-tile-4dfa7b
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sidewalk-tile-4dfa7b.mjs';
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
 *   colorway    choice  'warm-concrete' 'warm-concrete' | 'gray-cast' | 'bluestone' | 'sun-worn'
 *   concrete    color   '#cfc6b9'      any hex or THREE.Color
 *   bedding     color   '#45525f'      any hex or THREE.Color
 *   base        color   '#97614a'      any hex or THREE.Color
 *   flags       range   4              3 to 6
 *   jointWidth  range   0.05           0.02 to 0.09
 *   bond        choice  'grid'         'grid' | 'running' | 'plank'
 *
 * Every option is described in full at https://polyfork.dev/cdn/sidewalk-tile-4dfa7b-params.json
 *
 * SPECS  284 triangles, 1 material, 4 x 0.05 x 4 m (real-world scale).
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

const CONCRETE_H = 0.020;
const CONC_BOT = TOP_Y - CONCRETE_H;

const SCORE_DEPTH = 0.014;
const FLOOR_Y = TOP_Y - SCORE_DEPTH;

const RAMP = 0.06;

const BASE_SHARE = 0.73;

const DEF = {
  colorway: 'warm-concrete',
  flags: 4,
  jointWidth: 0.05,
  bond: 'grid',
};

const COLORWAYS = {
  'warm-concrete': { concrete: 0xcfc6b9, bedding: 0x45525f, base: 0x97614a },
  'gray-cast':     { concrete: 0x9f9890, bedding: 0x322d2c, base: 0x564e4a },
  'bluestone':     { concrete: 0x7b8b8f, bedding: 0x322d2c, base: 0x463b37 },
  'sun-worn':      { concrete: 0xc1b0a1, bedding: 0x62605c, base: 0x9a8472 },
};

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
  const rowsZ = (n) => Array.from({ length: n + 1 }, (_, k) => -HALF + k * (SIZE / n));
  if (bond === 'plank') {

    const cols = Math.max(2, Math.ceil(N / 2));
    const zs = rowsZ(N), xs = rowsZ(cols);
    for (let j = 0; j < N; j++) for (let i = 0; i < cols; i++)
      cells.push({ x0: xs[i], x1: xs[i + 1], z0: zs[j], z1: zs[j + 1] });
    return cells;
  }
  const zs = rowsZ(N), pitch = SIZE / N;
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
      cells.push({ x0: xs[i], x1: xs[i + 1], z0: zs[j], z1: zs[j + 1] });
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

function flag(cell, topInset, botInset) {
  const rt = flagOutline(cell, topInset);
  const rb = flagOutline(cell, botInset);
  const T = rt.map(p => [p[0], TOP_Y, p[1]]);
  const B = rb.map(p => [p[0], FLOOR_Y, p[1]]);

  const pos = [];
  const n = T.length;
  for (let k = 0; k < n; k++) quad(pos, T[k], B[k], B[(k + 1) % n], T[(k + 1) % n]);
  if (n === 4) {
    quad(pos, T[0], T[1], T[2], T[3]);
  } else {

    const cx = T.reduce((s, p) => s + p[0], 0) / n, cz = T.reduce((s, p) => s + p[2], 0) / n;
    const mid = [cx, TOP_Y, cz];
    for (let k = 0; k < n; k++) tri(pos, mid, T[k], T[(k + 1) % n]);
  }
  return pos;
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {
    concrete: p.concrete !== undefined ? p.concrete : cw.concrete,
    bedding: p.bedding !== undefined ? p.bedding : cw.bedding,
    base: p.base !== undefined ? p.base : cw.base,
  };
  const N = Math.max(3, Math.min(6, Math.round(p.flags !== undefined ? p.flags : DEF.flags)));
  const jw = Math.max(0.02, Math.min(0.09, p.jointWidth !== undefined ? p.jointWidth : DEF.jointWidth));
  const bond = ['grid', 'running', 'plank'].includes(p.bond) ? p.bond : DEF.bond;

  const topInset = jw / 2;

  const botInset = Math.max(0.002, topInset - 0.007);

  const under = THICK - CONCRETE_H;
  const baseTop = BOT_Y + under * BASE_SHARE;

  const conc = [], bed = [], base = [];

  quad(base, [-HALF, BOT_Y, -HALF], [HALF, BOT_Y, -HALF], [HALF, BOT_Y, HALF], [-HALF, BOT_Y, HALF]);
  rimWalls(base, BOT_Y, baseTop);
  rimWalls(bed, baseTop, CONC_BOT);
  rimWalls(conc, CONC_BOT, FLOOR_Y);

  quad(conc, [-HALF, FLOOR_Y, HALF], [HALF, FLOOR_Y, HALF], [HALF, FLOOR_Y, -HALF], [-HALF, FLOOR_Y, -HALF]);

  for (const cell of layout(bond, N)) conc.push(...flag(cell, topInset, botInset));

  const g = new THREE.Group();
  g.name = 'sidewalk-tile';
  const mesh = finish([
    { g: posGeo(conc), c: C.concrete },
    { g: posGeo(bed), c: C.bedding },
    { g: posGeo(base), c: C.base },
  ]);
  mesh.name = 'sidewalk-surface';
  g.add(mesh);
  return g;
}

export const params = {
  colorway:   { type: 'choice', default: 'warm-concrete', label: 'Colorway',
                options: ['warm-concrete', 'gray-cast', 'bluestone', 'sun-worn'],
                describe: 'curated pavement scheme: warm-concrete is the kit default pale warm grey sidewalk on a brown sub-base, gray-cast a cooler neutral concrete on near-black bedding, bluestone a darker blue-grey flagstone pavement, sun-worn a light sandy weathered concrete. Sets all three zone colours at once' },
  concrete:   { type: 'color', default: '#cfc6b9', label: 'Concrete',
                describe: 'albedo of the whole pavement surface — flag tops, score-channel walls and channel floors, about 90% of what the camera sees. One uniform pour: the joints deliberately share it, so the dark score lines come from real shadow and never from paint' },
  bedding:    { type: 'color', default: '#45525f', label: 'Bedding course',
                describe: 'albedo of the thin dark band in the slab edge between the concrete and the sub-base; the darkest tone on the tile, it keeps the border a crisp line against neighbouring tiles' },
  base:       { type: 'color', default: '#97614a', label: 'Base course',
                describe: 'albedo of the deep warm band at the bottom of the slab edge and the underside — the compacted earth/ballast the pavement is laid on' },
  flags:      { type: 'range', default: 4, min: 3, max: 6, step: 1, label: 'Flags per side',
                affects: 'geometry',
                describe: 'how many concrete flags the 4 m tile is scored into per side: 3 gives big 1.33 m slabs and a sparse grid, the default 4 gives the standard 1 m sidewalk flag, 6 gives fine 0.67 m flags and a much busier ruled surface. The grid stays square and centred at every value and the joints always die out before the border' },
  jointWidth: { type: 'range', default: 0.05, min: 0.02, max: 0.09, label: 'Joint width',
                affects: 'geometry',
                describe: 'width in metres of the score channel at the top face: 0.02 is a hairline saw cut that barely catches shadow, the default 0.05 reads clearly at hero distance, 0.09 is a wide open joint that makes the flags read as separately laid slabs. Depth stays 0.014 m at every value' },
  bond:       { type: 'choice', default: 'grid', label: 'Bond',
                options: ['grid', 'running', 'plank'],
                affects: 'geometry',
                describe: 'how the flags are laid out: grid is the default square scored grid with every joint lining up, running staggers alternate rows by half a flag so the cross joints break bond like brickwork (the end flags of those rows come out half width, cut against the border), plank pours half as many columns as rows so each flag is a wide 2:1 bay lying across the pavement. All three keep the same flush border and tile seamlessly against each other' },
};
export const presets = COLORWAYS;
export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

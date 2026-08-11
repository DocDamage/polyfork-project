/*
 * Path Stone A
 * https://polyfork.dev/asset/path-stone-a-aead48
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './path-stone-a-aead48.mjs';
 *   scene.add(createAsset());
 *
 * OPTIONS  createAsset({ ... }) — no arguments rebuilds this exact stone.
 *
 *   colorway     choice  'light-stone'   light-stone, slate, sandstone, mossy
 *   stone        color   '#e8dcc0'       the one stone albedo (a rock is one zone)
 *   sides        range   10              6 chunky pebble .. 12 near-round cobble
 *   chamfer      range   1               0.35 crisp flagstone .. 1.7 rounded boulder
 *   thickness    range   0.058           0.03 thin flag .. 0.058 m full slab
 *   depth        range   0.75            0.5 narrow stepping stone .. 0.9 m round
 *   crown        range   0.2414          0 flat paver .. 0.45 humped cobble
 *
 *   scene.add(createAsset({ colorway: 'slate', sides: 7, depth: 0.55 }));
 *
 * `presets` holds the colorway swatches and `night` the after-dark map (empty:
 * a stone emits nothing). Full machine-readable schema, with a `describe` per
 * knob: https://polyfork.dev/cdn/path-stone-a-aead48-params.json
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
 * SPECS  80 triangles, 1 material, 0.9 x 0.06 x 0.75 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'light-stone': { stone: 0xE8DCC0 },
  'slate':       { stone: 0x3C4550 },
  'sandstone':   { stone: 0xB89B72 },
  'mossy':       { stone: 0x7D8A5A },
};
export const presets = COLORWAYS;

const DEF_CROWN_FRAC = 0.014 / 0.058;

export const params = {
  colorway: { type: 'choice', default: 'light-stone', label: 'Colorway',
              options: ['light-stone', 'slate', 'sandstone', 'mossy'],
              describe: 'curated stone type; sets the single stone albedo (light-stone = pale kit limestone, slate = dark blue-grey, sandstone = warm sand, mossy = lichened green-grey). A rock is one material, so this is the only zone there is' },
  stone:    { type: 'color', default: '#e8dcc0', label: 'Stone',
              describe: 'albedo of the whole slab — every face, tread, chamfers, rim and underside. This asset has a single colour zone by design (craft rule 7b): all tone difference in a render is scene light on the facets, never paint' },
  sides:    { type: 'range', default: 10, min: 6, max: 12, label: 'Sides', affects: 'geometry',
              describe: 'number of straight sides in the plan outline (whole numbers 6-12). 6 = a chunky angular pebble with long flanks and a coarsely faceted rim, 10 = the approved worn stone, 12 = a near-round river cobble. Drives the triangle count directly (~8 tris per side) and regenerates the whole irregular radius/gap/inset/height table set, so each value is its own stone rather than the same outline subdivided' },
  chamfer:  { type: 'range', default: 1, min: 0.35, max: 1.7, label: 'Chamfer breadth', affects: 'geometry',
              describe: 'plan width of the hero top bevel band, as a multiple of the approved 24-60 mm per-corner inset. 0.35 = a crisp cut flagstone whose tread runs almost to the widest line with a hairline lip, 1 = the approved worn bevel, 1.7 = a heavily rounded-off boulder whose tread is a small dome on a wide skirt. Per-corner unevenness is preserved at every value; the inset is capped so no corner band can collapse the tread' },
  thickness:{ type: 'range', default: 0.058, min: 0.03, max: 0.058, label: 'Thickness', affects: 'geometry',
              describe: 'total height in metres from the ground plane to the crown, the defining proportion of a paving stone. 0.058 (the default) is the chunkiest this kit allows — the 8bc path-stone ceiling is 0.06 m — so the range runs DOWNWARD only: 0.03 is a thin flagstone half the height, sunk almost flush with the ground for a worn trail. The three section bands (bottom splay, rim wall, top chamfer) and the millimetre tread wobble all rebuild at the new height in the same ratios; a rock has nothing repeating in its section, so this rebuilds proportions rather than multiplying a structure' },
  depth:    { type: 'range', default: 0.75, min: 0.5, max: 0.9, label: 'Depth', affects: 'geometry',
              describe: 'front-to-back size in metres of the plan outline; the 0.90 m long axis is fixed by the kit footprint so this is the plan ASPECT knob. 0.5 = a long narrow stepping stone, 0.75 = the approved lozenge, 0.9 = a round-ish boulder as deep as it is wide. Consumers scatter clones of both shapes to break up a run' },
  crown:    { type: 'range', default: DEF_CROWN_FRAC, min: 0, max: 0.45, label: 'Tread crown', affects: 'geometry',
              describe: 'share of the total height taken by the domed tread above the rim, so the top reads from flat to humped. 0 = a dead-flat paver walked smooth (the two high points sit down on the rim line and the tread unevenness damps to nearly nothing), 0.2414 = the approved crown, 0.45 = a rounded cobble whose two unequal high points stand well proud over a visibly rocking tread. The per-corner tread unevenness scales with the crown, since a humped stone is a worn lump and a flat one has been trodden flat. Total height stays at the thickness knob at every value, so this never breaks the 0.06 m ceiling' },
};

export const rig = {};
export const detach = [];
export const night = {};

const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['light-stone'];
  return { stone: (hexOf(o.stone) ?? cw.stone) & 0xFFFFFF };
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
function prng(seed = 1) {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  const r = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 12; i++) r();
  return r;
}

function prep(geo, hex) {
  geo = geo.toNonIndexed();
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
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const DEF_N    = 10;
const R        = 0.475;
const WIDTH    = 0.90;
const DEF_T    = 0.058;
const DEF_MID  = 0.014;
const DEF_UP   = 0.024;
const DEF_WOB  = 0.006;
const DEF_CROWN= 0.014;
const R_BOT    = 0.88;
const R_UP     = 1.00;
const MID_R_10 = [1.016, 1.004, 1.009, 1.000, 1.013, 1.005, 1.016, 1.008, 1.001, 1.012];
const INSET_10 = [0.026, 0.034, 0.048, 0.060, 0.052, 0.038, 0.028, 0.024, 0.032, 0.044];
const TOP_Y_10 = [0.005, -0.006, -0.003, 0.006, -0.006, 0.003, 0.005, -0.005, -0.002, 0.004];
const GAP_10   = [1.45, 0.66, 1.02, 0.83, 1.30, 0.74, 1.38, 0.60, 1.15, 0.87];
const RAD_10   = [0.80, 0.89, 0.95, 0.98, 0.89, 0.86, 0.95, 0.83, 0.86, 0.95];

function tablesFor(n) {
  if (n === DEF_N) return { gap: GAP_10, rad: RAD_10, midR: MID_R_10, inset: INSET_10, topY: TOP_Y_10 };
  const rnd = prng(9176 + n * 7919);
  const gap = [], rad = [], midR = [], inset = [], topY = [];
  for (let i = 0; i < n; i++) {
    gap.push(0.60 + rnd() * 0.90);
    rad.push(0.80 + rnd() * 0.18);
    midR.push(1.000 + rnd() * 0.016);
    inset.push(0.024 + rnd() * 0.036);
    topY.push((rnd() * 2 - 1) * DEF_WOB);
  }
  const flank = rad.map((_, i) => gap[(i + n - 1) % n] + gap[i]);
  const mean = flank.reduce((s, f) => s + f, 0) / n;
  for (let i = 0; i < n; i++) rad[i] = clamp(rad[i] - 0.22 * (flank[i] - mean) / mean, 0.78, 0.99);
  for (let pass = 0; pass < 3; pass++) {
    for (let i = 0; i < n; i++) {
      const p = inset[(i + n - 1) % n], q = inset[(i + 1) % n];
      inset[i] = inset[i] * 0.6 + (p + q) * 0.2;
    }
  }
  return { gap, rad, midR, inset, topY };
}

function sectionOf(t, crownFrac) {
  const k = t / DEF_T;
  const crown = t * crownFrac;
  const wobMul = clamp(0.55 + 0.45 * (crownFrac / DEF_CROWN_FRAC), 0.55, 1.4);
  const wobRatio = DEF_WOB / (DEF_T - DEF_CROWN);
  const h = Math.min(t - crown, t / (1 + wobRatio * wobMul));
  return { yMid: DEF_MID * k, yUp: DEF_UP * k, h, crown, wobK: wobMul * h / (DEF_T - DEF_CROWN) };
}

function buildSlab(o) {
  const N = Math.round(clamp(num(o.sides, DEF_N), 6, 12));
  const chamfer = clamp(num(o.chamfer, 1), 0.35, 1.7);
  const T = clamp(num(o.thickness, DEF_T), 0.03, 0.06);
  const DEPTH = clamp(num(o.depth, 0.75), 0.5, 0.9);
  const crownFrac = clamp(num(o.crown, DEF_CROWN_FRAC), 0, 0.45);
  const { gap: GAP, rad: RAD, midR: MID_R, inset: INSET, topY: TOP_Y } = tablesFor(N);
  const { yMid: Y_MID, yUp: Y_UP, h: H, crown: CROWN, wobK } = sectionOf(T, crownFrac);

  const ring = [];
  const total = GAP.reduce((s, w) => s + w, 0);
  let a = 0;
  for (let i = 0; i < N; i++) {
    const r = R * RAD[i];
    ring.push({ x: Math.cos(a) * r, z: Math.sin(a) * r * 0.86 });
    a -= (GAP[i] / total) * Math.PI * 2;
  }
  const turn = (i) => {
    const p = ring[(i + N - 1) % N], q = ring[i], s = ring[(i + 1) % N];
    return (q.x - p.x) * (s.z - q.z) - (q.z - p.z) * (s.x - q.x);
  };
  for (let pass = 0; pass < 24; pass++) {
    let sum = 0;
    for (let i = 0; i < N; i++) sum += turn(i);
    const sign = sum >= 0 ? 1 : -1;
    let fixed = false;
    for (let i = 0; i < N; i++) {
      if (turn(i) * sign <= 0) { ring[i].x *= 1.04; ring[i].z *= 1.04; fixed = true; }
    }
    if (!fixed) break;
  }
  const wx = ring.map((p, i) => p.x * MID_R[i]), wz = ring.map((p, i) => p.z * MID_R[i]);
  const sx = WIDTH / (Math.max(...wx) - Math.min(...wx));
  const sz = DEPTH / (Math.max(...wz) - Math.min(...wz));
  ring.forEach(p => { p.x *= sx; p.z *= sz; });

  const mid = ring.map((p, i) => [p.x * MID_R[i], Y_MID, p.z * MID_R[i]]);
  const bot = ring.map(p => [p.x * R_BOT, 0, p.z * R_BOT]);
  const up  = ring.map(p => [p.x * R_UP, Y_UP, p.z * R_UP]);
  const yFloor = Y_UP + 0.12 * T;
  const top = mid.map((p, i) => {
    const len = Math.hypot(p[0], p[2]);
    const k = (len - Math.min(INSET[i] * chamfer, len * 0.55)) / len;
    return [p[0] * k, Math.max(yFloor, H + TOP_Y[i] * wobK), p[2] * k];
  });
  const dz = DEPTH / 0.75;
  const hiA = [0.155, H + CROWN, -0.115 * dz];
  const hiB = [-0.175, H + CROWN * 0.75, 0.095 * dz];
  const cx = top.reduce((s, p) => s + p[0], 0) / N, cz = top.reduce((s, p) => s + p[2], 0) / N;
  const inside = (p) => {
    let sign = 0;
    for (let i = 0; i < N; i++) {
      const q = top[i], s = top[(i + 1) % N];
      const t = (s[0] - q[0]) * (p[2] - q[2]) - (s[2] - q[2]) * (p[0] - q[0]);
      if (t !== 0) { if (sign === 0) sign = Math.sign(t); else if (Math.sign(t) !== sign) return false; }
    }
    return true;
  };
  for (const h of [hiA, hiB]) {
    for (let k = 0; k < 24 && !inside(h); k++) {
      h[0] += (cx - h[0]) * 0.18; h[2] += (cz - h[2]) * 0.18;
    }
  }
  const d2 = (p, h) => (p[0] - h[0]) ** 2 + (p[2] - h[2]) ** 2;
  const owner = top.map(p => (d2(p, hiA) <= d2(p, hiB) ? hiA : hiB));

  const pos = [];
  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    quad(pos, bot[i], bot[j], mid[j], mid[i]);
    quad(pos, mid[i], mid[j], up[j], up[i]);
    quad(pos, up[i], up[j], top[j], top[i]);
    if (owner[i] === owner[j]) tri(pos, owner[i], top[i], top[j]);
    else quad(pos, owner[i], top[i], top[j], owner[j]);
  }
  for (let k = 1; k <= N - 2; k++) tri(pos, bot[0], bot[k + 1], bot[k]);
  return posGeo(pos);
}

const DEFAULTS = {
  colorway: 'light-stone', sides: DEF_N, chamfer: 1,
  thickness: DEF_T, depth: 0.75, crown: DEF_CROWN_FRAC,
};

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const g = new THREE.Group();
  g.name = 'path-stone-a';
  const mesh = finish([{ g: buildSlab(o), c: C.stone }]);
  mesh.name = 'stone';
  mesh.geometry.computeBoundingBox();
  const b = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(b.min.x + b.max.x) / 2, -b.min.y, -(b.min.z + b.max.z) / 2);
  g.add(mesh);
  return g;
}

export default createAsset;

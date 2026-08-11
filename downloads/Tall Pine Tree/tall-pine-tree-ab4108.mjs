/*
 * Tall Pine Tree
 * https://polyfork.dev/asset/tall-pine-tree-ab4108
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './tall-pine-tree-ab4108.mjs';
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
 *   colorway  choice  'deep-pine'    'deep-pine' | 'spring-fir' | 'shadow-spruce' | 'golden-larch'
 *   needles   color   '#4c8140'      any hex or THREE.Color
 *   bark      color   '#4a3527'      any hex or THREE.Color
 *   snow      color   '#f4ece0'      any hex or THREE.Color
 *   season    choice  'summer'       'summer' | 'snow'
 *   tallness  range   9              6.4 to 9.6
 *   facets    range   10             7 to 12
 *   flare     range   0.7            0.25 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/tall-pine-tree-ab4108-params.json
 *
 * SPECS  350 triangles, 1 material, 3.67 x 9 x 3.56 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';

const COLORWAYS = {
  'deep-pine':     { needles: '#4c8140', bark: '#4a3527', snow: '#f4ece0' },
  'spring-fir':    { needles: '#5f9a4b', bark: '#5d4430', snow: '#f4ece0' },
  'shadow-spruce': { needles: '#2f4f2e', bark: '#3a2a1e', snow: '#e0d2b4' },
  'golden-larch':  { needles: '#8fa84a', bark: '#75563b', snow: '#f4ece0' },
};

export const params = {
  colorway: {
    type: 'choice', default: 'deep-pine', label: 'Colorway',
    options: ['deep-pine', 'spring-fir', 'shadow-spruce', 'golden-larch'],
    describe: 'Curated kit-palette schemes. deep-pine is the shipped mid forest green on ' +
      'dark brown bark; spring-fir is a brighter fresh green; shadow-spruce is a very dark ' +
      'near-black green on almost black bark for background/night forests; golden-larch is ' +
      'an olive-gold autumn conifer on warm brown bark.',
  },
  needles: {
    type: 'color', default: '#4c8140', label: 'Needles',
    describe: 'Albedo of ALL foliage — the crown spire and every skirt tier share this one ' +
      'flat green. Changing it recolours the entire canopy.',
  },
  bark: {
    type: 'color', default: '#4a3527', label: 'Bark',
    describe: 'Albedo of the whole trunk including its ground flare. Keep it clearly darker ' +
      'than the needles or the trunk stops reading against the bottom skirt.',
  },
  snow: {
    type: 'color', default: '#f4ece0', label: 'Snow',
    describe: 'Albedo of the snow caps. Only visible when season is "snow"; ignored in summer.',
  },
  season: {
    type: 'choice', default: 'summer', label: 'Season', affects: 'geometry',
    options: ['summer', 'snow'],
    describe: 'State knob. "summer" is bare green foliage. "snow" builds a real snow shell ' +
      'lying on the upper slope of every tier and over the crown point — added geometry ' +
      'standing ~30-50mm proud of the needles, not a repaint.',
  },
  tallness: {
    type: 'range', default: 9.0, min: 6.4, max: 9.6, label: 'Tallness (m)',
    affects: 'geometry',
    describe: 'Total height in metres, and it REBUILDS rather than scaling: branch whorls are ' +
      'added at a roughly constant 1.6-1.8m tier pitch, so 6.4m is a sparse 3-whorl young pine, ' +
      '9.0m the shipped 4-whorl tree and 9.6m a dense 5-whorl veteran. Triangle count changes ' +
      'with the whorl count. Spread follows height (the tree stays 0.40 wide per unit tall).',
  },
  facets: {
    type: 'range', default: 10, min: 7, max: 12, label: 'Facets', affects: 'geometry',
    describe: 'Number of flat planes around the canopy. 7 is a coarse angular crystal pine ' +
      'with obvious corners on every rim; 12 is a smoother, rounder conifer. Trunk stays an ' +
      '8-sided prism. Changes triangle count.',
  },
  flare: {
    type: 'range', default: 0.7, min: 0.25, max: 1, label: 'Tier flare', affects: 'geometry',
    describe: 'How far each tier overhangs the one below. 0.25 gives fat tier tops and shallow ' +
      'lips, so the outline reads as a nearly smooth cone with faint notches; 1 gives narrow tier ' +
      'tops and deep shelving ledges, a strongly stepped pagoda silhouette with hard shadow lines ' +
      'under every whorl. 0.7 is the shipped look.',
  },
};

export const presets = COLORWAYS;
export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  const f = () => (s = (s * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 8; i++) f();
  return f;
}

function jitterTable(S, m, seed, amp) {
  const rnd = prng(seed);
  const cache = new Map();
  const out = [];
  for (let i = 0; i < S; i++) {
    const j = ((m - i) % S + S) % S;
    const key = Math.min(i, j);
    if (!cache.has(key)) cache.set(key, (rnd() * 2 - 1) * amp);
    out.push(cache.get(key));
  }
  return out;
}

export function createAsset(opts = {}) {

  const cwName = COLORWAYS[opts.colorway] ? opts.colorway : params.colorway.default;
  const C = { ...COLORWAYS[cwName] };
  for (const k of ['needles', 'bark', 'snow']) if (opts[k] !== undefined) C[k] = opts[k];

  const clamp = (v, a, b) => Math.min(b, Math.max(a, v));
  const H = clamp(opts.tallness === undefined ? params.tallness.default : +opts.tallness,
    params.tallness.min, params.tallness.max);
  const S = Math.round(clamp(opts.facets === undefined ? params.facets.default : +opts.facets,
    params.facets.min, params.facets.max));
  const flare = clamp(opts.flare === undefined ? params.flare.default : +opts.flare, 0, 1);
  const snowy = (opts.season || params.season.default) === 'snow';

  const n = clamp(Math.round(H / 2.05), 3, 5);
  const yBase = 0.160 * H;
  const u = (H - yBase) / (n + 0.22);
  const R = 0.2015 * H;
  const rise = (0.05 + 0.16 * flare) * u;
  const neckK = 0.90 - 0.44 * flare;

  const rimR = (t) => R * Math.pow((n - t) / n, 0.6);
  const rimY = (t) => yBase + t * u;
  const apexY = rimY(n - 1) + 1.22 * u;

  const step = (Math.PI * 2) / S;
  const phase = (Math.PI % step) / 2;
  const mFold = Math.floor(Math.PI / step);

  function skirtPoint(t, s) {
    const rn = neckK * rimR(t + 1), yn = rimY(t + 1) + rise;
    const rr = rimR(t), yr = rimY(t);
    const g = 0.75 * s + 0.25 * s * s;
    return { r: rn + (rr - rn) * g, y: yn + (yr - yn) * s, w: s };
  }

  function crownPoint(s) {
    const rr = rimR(n - 1);
    const g = 0.85 * s + 0.15 * s * s;
    return { r: rr * g, y: apexY + (rimY(n - 1) - apexY) * s, w: s };
  }

  const pos = [], col = [];
  const tmp = new THREE.Color();
  const push3 = (a, b, c, hex) => {
    pos.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
    tmp.set(hex);
    for (let i = 0; i < 3; i++) col.push(tmp.r, tmp.g, tmp.b);
  };

  const band = (A, B, hex) => {
    for (let i = 0; i < A.length; i++) {
      const k = (i + 1) % A.length;
      push3(A[i], B[k], B[i], hex);
      push3(A[i], A[k], B[k], hex);
    }
  };
  const fanFrom = (P, B, hex) => {
    for (let i = 0; i < B.length; i++) push3(P, B[(i + 1) % B.length], B[i], hex);
  };
  const fanTo = (A, P, hex) => {
    for (let i = 0; i < A.length; i++) push3(A[i], A[(i + 1) % A.length], P, hex);
  };

  function ring(r, y, jr, jy, w, segs = S, ph = phase, dr = 0, dy = 0) {
    const v = [];
    for (let i = 0; i < segs; i++) {
      const a = ph + i * ((Math.PI * 2) / segs);
      const rr = r * (1 + (jr ? jr[i] * w : 0)) + dr;
      v.push([Math.cos(a) * rr, y + (jy ? jy[i] * w : 0) + dy, Math.sin(a) * rr]);
    }
    return v;
  }

  const jr = [], jy = [];
  for (let t = 0; t < n; t++) {
    jr.push(jitterTable(S, mFold, 101 + t * 37, 0.05));
    jy.push(jitterTable(S, mFold, 613 + t * 53, 0.030 * u));
  }

  const apex = [0, apexY, 0];
  const crownRings = [];
  for (const s of [0.30, 0.62, 1.0]) {
    const p = crownPoint(s);
    crownRings.push(ring(p.r, p.y, jr[n - 1], jy[n - 1], p.w));
  }
  fanFrom(apex, crownRings[0], C.needles);
  band(crownRings[0], crownRings[1], C.needles);
  band(crownRings[1], crownRings[2], C.needles);

  let above = crownRings[2];
  for (let t = n - 2; t >= 0; t--) {
    const sp0 = skirtPoint(t, 0);
    const neck = ring(sp0.r, sp0.y, null, null, 0);
    band(above, neck, C.needles);
    const rings = [neck];
    for (const s of [0.34, 0.68, 1.0]) {
      const p = skirtPoint(t, s);
      rings.push(ring(p.r, p.y, jr[t], jy[t], p.w));
    }
    for (let i = 0; i < 3; i++) band(rings[i], rings[i + 1], C.needles);
    above = rings[3];
  }

  const shutR = 0.44 * (H / 9);
  band(above, ring(shutR, rimY(0) + rise, null, null, 0), C.needles);

  if (snowy) {
    const off = 0.035 * (H / 9), lip = 0.006 * (H / 9), up = 0.06 * (H / 9);

    const c1 = crownPoint(0.42), c2 = crownPoint(0.47);
    const cA = ring(c1.r, c1.y, jr[n - 1], jy[n - 1], c1.w, S, phase, off, up);
    const cB = ring(c2.r, c2.y, jr[n - 1], jy[n - 1], c2.w, S, phase, lip, lip);
    fanFrom(apex, cA, C.snow);
    band(cA, cB, C.snow);
    for (let t = n - 2; t >= 0; t--) {
      const p0 = skirtPoint(t, 0), p1 = skirtPoint(t, 0.58), p2 = skirtPoint(t, 0.63);
      const A = ring(p0.r, p0.y, null, null, 0);
      const B = ring(p1.r, p1.y, jr[t], jy[t], p1.w, S, phase, off, up);
      const D = ring(p2.r, p2.y, jr[t], jy[t], p2.w, S, phase, lip, lip);
      band(A, B, C.snow);
      band(B, D, C.snow);
    }
  }

  const TS = 8, tj = jitterTable(TS, 4, 907, 0.04);
  const tr = 0.50 * (H / 9), tf = 0.66 * (H / 9);
  const tTop = ring(tr, 2.40 * (H / 9), tj, null, 0.3, TS, 0);
  const tMid = ring(tr, 0.62 * (H / 9), tj, null, 0.8, TS, 0);
  const tBot = ring(tf, 0, tj, null, 1.0, TS, 0);

  band(tTop, tMid, C.bark);
  band(tMid, tBot, C.bark);
  fanTo(tBot, [0, 0, 0], C.bark);

  const geo = new THREE.BufferGeometry();
  geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  geo.setAttribute('color', new THREE.Float32BufferAttribute(col, 3));
  geo.computeVertexNormals();

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'pine';

  const g = new THREE.Group();
  g.name = 'tall-pine-tree';
  g.add(mesh);
  return g;
}

export default createAsset;

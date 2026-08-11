/*
 * Checkered-flag
 * https://polyfork.dev/asset/checkered-flag-81784a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './checkered-flag-81784a.mjs';
 *   scene.add(createAsset());
 *
 *   // every knob is optional; createAsset() alone gives the default flag
 *   scene.add(createAsset({ colorway: 'caution-yellow', columns: 11, waviness: 1.6 }));
 *
 *   import { params, presets, night } from './checkered-flag-81784a.mjs';
 *   // params: the knob schema (types, ranges, machine-readable describe)
 *   // presets: the curated colorways   night: what glows after dark (nothing here)
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
 * SPECS  416 triangles, 1 material, 0.82 x 1.85 x 0.11 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// ---------------------------------------------------------------- colorways --
// Three zones only — the graphic two-tone checker IS the asset, plus the metal pole.
// Every hex is on the Retro Cars kit menu.
export const COLORWAYS = {
  'racing-classic': { dark: 0x0c0e14, light: 0xf1f2ef, pole: 0x999ca3 }, // the finish flag
  'midnight-cream': { dark: 0x2a3a6b, light: 0xecf1cb, pole: 0xc2c7cd },
  'caution-yellow': { dark: 0x2a2d35, light: 0xe8cc42, pole: 0x999ca3 },
  'pit-red':        { dark: 0x98443d, light: 0xf1f2ef, pole: 0x4c4f57 },
  'team-teal':      { dark: 0x267466, light: 0xecf1cb, pole: 0xafb5bb },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'racing-classic', label: 'Colorway',
    options: ['racing-classic', 'midnight-cream', 'caution-yellow', 'pit-red', 'team-teal'],
    describe: 'curated kit-palette scheme for the whole prop: racing-classic is the near-black / warm off-white finish flag on grey metal, midnight-cream a navy-and-cream variant, caution-yellow a charcoal-and-yellow marshal flag, pit-red a red-and-white pit-lane flag on dark steel, team-teal a teal-and-cream team flag',
  },
  dark: {
    type: 'color', default: '#0c0e14', label: 'Dark squares',
    describe: 'albedo of the dark half of the checkerboard, on both faces of the cloth; near-black by default, never pure black',
  },
  light: {
    type: 'color', default: '#f1f2ef', label: 'Light squares',
    describe: 'albedo of the pale half of the checkerboard, on both faces of the cloth; warm off-white by default, never pure white',
  },
  pole: {
    type: 'color', default: '#999ca3', label: 'Pole',
    describe: 'albedo of the pole shaft, its ground cap and the ball finial — one painted-metal grey for the whole mast',
  },
  columns: {
    type: 'range', default: 8, min: 4, max: 11, label: 'Checker columns', icon: '↔️', affects: 'geometry',
    describe: 'how many checker squares run across the flag, whole numbers 4-11. The square stays a fixed 0.10 m and the cloth is REBUILT wider (one more square, two more facet columns, 40 more triangles per step): 4 is a stubby 0.40 m marshal flag, 8 the 0.80 m default, 11 a long 1.10 m banner. Square size, row height and pole are unchanged; the ripple keeps its 1.5 wavelengths and scales its depth with the width, so the folds stay equally steep',
  },
  rows: {
    type: 'range', default: 5, min: 3, max: 7, label: 'Checker rows', icon: '↕️', affects: 'geometry',
    describe: 'how many checker squares run down the flag, whole numbers 3-7, at the same fixed 0.10 m square. The hoist top edge stays pinned at 1.74 m just under the finial and the cloth is REBUILT downward (one more square row, 0.10 m deeper, 64 more triangles per step at the default width): 3 is a shallow 0.30 m pennant on the top eighth of the pole, 5 the 0.50 m default, 7 a deep 0.70 m panel reaching to mid-pole',
  },
  waviness: {
    type: 'range', default: 1, min: 0.3, max: 1.9, label: 'Waviness', icon: '〰️', affects: 'geometry',
    describe: 'amplitude of the faceted ripple that travels hoist-to-fly across the cloth (1.5 wavelengths, always pinned to zero at the pole so the hoist edge stays dead straight). 0.3 is near-limp cloth in still air, a nearly flat panel with a straight fly edge; 1 is the default snap of ±65 mm at the 0.80 m default width (the swing scales with flag width); 1.9 is a hard wind — ±124 mm of swing at that width, deep flat-shaded light/dark steps across the squares and a strongly curled fly edge. Triangle count is unchanged, only the surface',
  },
  finial: {
    type: 'toggle', default: true, label: 'Ball finial', icon: '⚪', affects: 'geometry',
    describe: 'the plump ball cap on the pole top. On (default) the pole tops out at 1.85 m with the ball seated into the tube; off gives a plain flat-capped mast 1.80 m tall, sealed with a disc so the tube is never left open. The cloth does not move either way',
  },
};

export const rig = {};    // static prop — nothing hinges, spins or slides
export const detach = []; // nothing is removable: the cloth is bound to the pole
export const night = {};  // cloth and a bare painted-metal pole emit nothing after dark

// ---- fixed dimensions (meters, per BRIEF.md) ----
const POLE_H = 1.80, POLE_R = 0.020, BALL_R = 0.034;
const SQUARE = 0.10;                     // checker square — fixed, the count is the knob
const FLAG_TOP = 1.74;                   // hoist top sits one ball-width under the finial
const HOIST_X = -0.010;                  // cloth leading edge buried inside the pole
const THICK = 0.006;                     // cloth thickness (z offset per shell)
const SUB = 2;                           // facet sub-columns per checker square
const WAVE_A = 0.065, WAVES = 1.5;       // ripple amplitude / wavelength count

// ---- knob plumbing ----
const ZONE_KEYS = ['dark', 'light', 'pole'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['racing-classic'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    // explicit knob > colorway preset > default scheme
    let hex = (hexOf(o[k]) ?? cw[k] ?? COLORWAYS['racing-classic'][k]) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF; // every zone keeps a unique albedo
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const isOn = (v) => !(v === false || v === 'false' || v === 0 || v === '0');

// NOTE: parts is reset at the top of every createAsset() call — the module must stay
// safe to call repeatedly (the configurator instantiates many variants in one process).
const parts = [];
const add = (g, c) => parts.push({ g, c });

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

// ---- bake + merge (SNIPPETS standard skeleton) ----
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

const DEFAULTS = { colorway: 'racing-classic', columns: 8, rows: 5, waviness: 1, finial: true };

export function createAsset(opts = {}) {
  parts.length = 0;
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const cols = Math.round(clamp(num(o.columns, 8), 4, 11));
  const rows = Math.round(clamp(num(o.rows, 5), 3, 7));
  const wav = clamp(num(o.waviness, 1), 0.3, 1.9);
  const ballOn = isOn(o.finial);

  // the cloth is REBUILT from the square count, never scaled: the square stays 0.10 m
  const FLAG_W = cols * SQUARE, FLAG_H = rows * SQUARE;
  const FLAG_BOT = FLAG_TOP - FLAG_H;
  const NX = cols * SUB, NY = rows;
  // amplitude follows the flag's WIDTH, so the fold slope (and therefore the facet
  // tone steps) stay the same on a 0.40 m marshal flag and a 1.10 m banner
  const amp = WAVE_A * wav * (FLAG_W / 0.80);

  // ripple: zero at the hoist, growing toward the fly edge, slight phase shear down the cloth
  const clothZ = (x, y) => {
    const u = (x - HOIST_X) / FLAG_W;
    const v = (y - FLAG_BOT) / FLAG_H;
    const env = Math.pow(Math.max(u, 0), 0.7);
    return amp * env * Math.sin(2 * Math.PI * WAVES * u + 0.6 + 0.45 * v);
  };
  // gentle droop of the free edge
  const clothY = (x, y) => {
    const u = (x - HOIST_X) / FLAG_W;
    return y - 0.020 * Math.pow(Math.max(u, 0), 1.5);
  };

  // ---- cloth grid ----
  // Two shells (front/back) offset +-THICK/2 in z, but boundary vertices are shared
  // (offset falls to 0 on the edge ring): the cloth closes at a crisp zero-thickness
  // edge like a real hem - no rim walls, no see-through slits, no dead triangles.
  const P = [];
  for (let i = 0; i <= NX; i++) {
    P.push([]);
    for (let j = 0; j <= NY; j++) {
      const x = HOIST_X + (i / NX) * FLAG_W;
      const yb = FLAG_BOT + (j / NY) * FLAG_H;
      const y = clothY(x, yb);
      const edge = (i === 0 || i === NX || j === 0 || j === NY) ? 0 : THICK / 2;
      P[i].push([x, y, clothZ(x, y), edge]);
    }
  }
  // one square = SUB facet columns x 1 row; parity alternates in both directions
  const isDark = (i, j) => ((Math.floor(i / SUB) + j) % 2 === 0);

  const darkTris = [], lightTris = [];
  const F = (p) => [p[0], p[1], p[2] + p[3]]; // front-shell vertex
  const B = (p) => [p[0], p[1], p[2] - p[3]]; // back-shell vertex

  for (let i = 0; i < NX; i++) {
    for (let j = 0; j < NY; j++) {
      const a = P[i][j], b = P[i + 1][j], c = P[i + 1][j + 1], d = P[i][j + 1];
      const col = isDark(i, j) ? darkTris : lightTris;
      // front shell (+z), CCW seen from +z
      tri(col, F(a), F(b), F(c));
      tri(col, F(a), F(c), F(d));
      // back shell (-z), CCW seen from -z
      tri(col, B(a), B(c), B(b));
      tri(col, B(a), B(d), B(c));
    }
  }

  // ---- pole + finial ----
  const pole = new THREE.CylinderGeometry(POLE_R, POLE_R, POLE_H, 8, 1, true)
    .translate(0, POLE_H / 2, 0);
  add(pole, C.pole);
  // bottom cap (closed mesh: a prop can be tipped over)
  const cap = new THREE.CircleGeometry(POLE_R, 8).rotateX(Math.PI / 2).translate(0, 0.001, 0);
  add(cap, C.pole);
  if (ballOn) {
    // ball finial, seated into the pole top
    const ball = new THREE.SphereGeometry(BALL_R, 8, 5, 0, Math.PI * 2, 0, Math.PI * 0.8)
      .translate(0, POLE_H + BALL_R * 0.55, 0); // open bottom ring seals inside the pole
    add(ball, C.pole);
  } else {
    // no finial: seal the open tube with a flat disc, never leave the mouth open
    const top = new THREE.CircleGeometry(POLE_R, 8).rotateX(-Math.PI / 2).translate(0, POLE_H, 0);
    add(top, C.pole);
  }

  add(posGeo(darkTris), C.dark);
  add(posGeo(lightTris), C.light);

  const g = new THREE.Group();
  g.name = 'checkered-flag';
  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  g.add(new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  })));
  return g;
}

export default createAsset;

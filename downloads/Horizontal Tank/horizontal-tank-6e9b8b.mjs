/*
 * Horizontal Tank
 * https://polyfork.dev/asset/horizontal-tank-6e9b8b
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './horizontal-tank-6e9b8b.mjs';
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
 *   colorway     choice  'polar-cyan'   'polar-cyan' | 'astro-amber' | 'gunmetal' | 'regolith'
 *   hull         color   '#b4b7bc'      any hex or THREE.Color
 *   band         color   '#47b7b1'      any hex or THREE.Color
 *   cradle       color   '#3d3f47'      any hex or THREE.Color
 *   pads         color   '#5f6570'      any hex or THREE.Color
 *   tankLength   range   1              0.78 to 1.12
 *   girth        range   1              0.84 to 1.16
 *   facets       choice  'standard'     'chunky' | 'standard' | 'smooth'
 *   standHeight  range   1              0.25 to 2.1
 *
 * Every option is described in full at https://polyfork.dev/cdn/horizontal-tank-6e9b8b-params.json
 *
 * SPECS  344 triangles, 1 material, 2.4 x 1.33 x 1.16 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'polar-cyan':  { hull: '#b4b7bc', band: '#47b7b1', cradle: '#3d3f47', pads: '#5f6570' },
  'astro-amber': { hull: '#b4b7bc', band: '#b2684b', cradle: '#434e67', pads: '#737785' },
  'gunmetal':    { hull: '#989ea7', band: '#434e67', cradle: '#1d1e26', pads: '#5f6570' },
  'regolith':    { hull: '#c1a078', band: '#975b44', cradle: '#3d3f47', pads: '#856f5d' },
};
export const presets = COLORWAYS;

const FACET_SIDES = { chunky: 8, standard: 12, smooth: 16 };

export const params = {
  colorway: {
    type: 'choice', default: 'polar-cyan', label: 'Colorway', affects: 'colors',
    options: ['polar-cyan', 'astro-amber', 'gunmetal', 'regolith'],
    describe: 'Curated kit-coherent scheme, all two-tone across the hull waterline. ' +
      'polar-cyan = off-white upper hull over a kit-cyan lower half on a dark gunmetal ' +
      'cradle (the approved default); astro-amber swaps the lower half to the kit ' +
      'rust-orange over a slate cradle; gunmetal is a darker utility tank with a deep ' +
      'slate-blue bottom; regolith is a dust-tan hull over brown for weathered field gear.',
  },
  hull: {
    type: 'color', default: '#b4b7bc', label: 'Upper hull', affects: 'colors',
    describe: 'Albedo of the upper half of the pressure vessel — every facet above the hull ' +
      'mid-line, barrel and both end domes. Keep it the lightest value in the asset; the ' +
      'lower half takes the accent hue.',
  },
  band: {
    type: 'color', default: '#47b7b1', label: 'Lower hull', affects: 'colors',
    describe: 'Albedo of the ENTIRE lower half of the vessel — every facet below the hull ' +
      'mid-line, barrel and both end domes, cut dead level on the equator. Two-tone paint, ' +
      'so this reads as roughly half the object: give it a chromatic hue that carries against ' +
      'the pale upper hull rather than a near-neutral.',
  },
  cradle: {
    type: 'color', default: '#3d3f47', label: 'Cradle', affects: 'colors',
    describe: 'Albedo of the two straps that wrap over the hull and the four legs that drop ' +
      'from them. Wants a clear dark step below the hull so the straps cut the capsule into thirds.',
  },
  pads: {
    type: 'color', default: '#5f6570', label: 'Foot pads', affects: 'colors',
    describe: 'Albedo of the two flat ground pads the legs stand on. Sits one value step ' +
      'LIGHTER than the cradle so the pads do not merge with the straps into one black mass ' +
      'when the model is viewed from below; reads as bare skid plate under painted steel.',
  },
  tankLength: {
    type: 'range', default: 1.0, min: 0.78, max: 1.12, label: 'Tank length', affects: 'geometry',
    describe: 'Lengthens the straight barrel run (the end domes keep their shape), so the whole ' +
      'tank goes from 1.99 m at 0.78 — a stubby drum barely longer than it is wide — to ' +
      '2.62 m at 1.12, a long slim cylinder. It REBUILDS the stand rather than stretching it: ' +
      'saddles sit at most 1.42 m apart (the shipped span), so a tank longer than the default ' +
      'gains a THIRD saddle — strap, two legs and its own foot pad — on the centreline, and ' +
      'the three then spread evenly over the barrel. 2 saddles / 344 tris at 0.78, 3 saddles / ' +
      '420 tris at 1.12. The strap keeps its 0.10 m width at every length.',
  },
  girth: {
    type: 'range', default: 1.0, min: 0.84, max: 1.16, label: 'Girth', affects: 'geometry',
    describe: 'Hull diameter, from 0.92 m at 0.84 (a slim gas cylinder) to 1.28 m at 1.16 (a fat ' +
      'bulk tank almost as deep as it is long). A pressure vessel has nothing repeating AROUND ' +
      'its girth except the plates it is rolled from, so that is what this rebuilds: the facet ' +
      'CHORD is held at its shipped width and the segment count follows the diameter, giving 10 ' +
      'sides at 0.84 and 14 at 1.16 (12 at the default) — the fat tank is made of MORE plates ' +
      'the same size, not of stretched ones. The strap and legs keep their 0.10 x 0.075 m ' +
      'section at every diameter; only the wrap radius and the pad width follow the hull. ' +
      '10 sides / 300 tris at 0.84, 14 sides / 412 tris at 1.16.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facets', options: ['chunky', 'standard', 'smooth'],
    affects: 'geometry',
    describe: 'How WIDE a hull plate is, quoted as the segment count at the default girth: ' +
      'chunky = 8 sides, a hard octagonal barrel; standard = 12 (the approved default); ' +
      'smooth = 16, a rounder hull with a wider strap wrap. The count itself is re-derived from ' +
      'the diameter (see girth) so the chord stays put. Changes the outline, not the ' +
      'proportions — the two-tone waterline stays on the equator at every setting because the ' +
      'ring count is always even and so always has vertices there.',
  },
  standHeight: {
    type: 'range', default: 1.0, min: 0.25, max: 2.1, label: 'Stand height', affects: 'geometry',
    describe: 'Ground clearance under the belly, from 0.05 m at 0.25 (the tank almost resting ' +
      'in the dust, legs nearly gone) to 0.42 m at 2.1 (tall trestle legs with a walk-under ' +
      'gap). The vessel and the strap wrap are untouched; the STAND rebuilds. Legs hold a ' +
      '0.45 m bracing bay, so once the drop past the strap exceeds that — above about 1.11 — ' +
      'each saddle gains a horizontal cross-tie between its two legs, giving 344 tris at 0.25 ' +
      'and 360 at 2.1. The legs keep the strap\'s own 0.10 x 0.075 m section at every height; ' +
      'only their length changes.',
  },
};

export const rig = {};
export const detach = [];

export const night = {};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function sub(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }
function cross(a, b) {
  return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
}
function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }

function face(out, pts, hint) {
  const n = cross(sub(pts[1], pts[0]), sub(pts[2], pts[0]));
  const p = dot(n, hint) >= 0 ? pts : pts.slice().reverse();
  for (let i = 1; i < p.length - 1; i++) tri(out, p[0], p[i], p[i + 1]);
}

function boxInto(out, x0, x1, y0, y1, z0, z1, skip = {}) {
  const V = (x, y, z) => [x, y, z];
  if (!skip.px) face(out, [V(x1, y0, z0), V(x1, y1, z0), V(x1, y1, z1), V(x1, y0, z1)], [1, 0, 0]);
  if (!skip.nx) face(out, [V(x0, y0, z0), V(x0, y1, z0), V(x0, y1, z1), V(x0, y0, z1)], [-1, 0, 0]);
  if (!skip.py) face(out, [V(x0, y1, z0), V(x1, y1, z0), V(x1, y1, z1), V(x0, y1, z1)], [0, 1, 0]);
  if (!skip.ny) face(out, [V(x0, y0, z0), V(x1, y0, z0), V(x1, y0, z1), V(x0, y0, z1)], [0, -1, 0]);
  if (!skip.pz) face(out, [V(x0, y0, z1), V(x1, y0, z1), V(x1, y1, z1), V(x0, y1, z1)], [0, 0, 1]);
  if (!skip.nz) face(out, [V(x0, y0, z0), V(x1, y0, z0), V(x1, y1, z0), V(x0, y1, z0)], [0, 0, -1]);
}

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
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!merged) throw new Error('mergeGeometries returned null — attribute sets disagree');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const DOME_R = [0.28, 0.58, 0.86, 1.0];
const DOME_X = [0.00, 0.24, 0.60, 1.0];

function vessel(G, hullPos, bandPos) {
  const { sides: N, R, axisY, halfBarrel: B, domeD: D } = G;

  const prof = [];
  for (let i = 0; i < 4; i++) prof.push([-(B + D) + DOME_X[i] * D, DOME_R[i] * R]);
  for (let i = 3; i >= 0; i--) prof.push([(B + D) - DOME_X[i] * D, DOME_R[i] * R]);

  const th = (i) => (i / N) * Math.PI * 2;
  const P = (x, r, i) => [x, axisY + r * Math.sin(th(i)), r * Math.cos(th(i))];

  const lowerHalf = (k) => (k % N) >= N / 2;

  for (let j = 0; j < prof.length - 1; j++) {
    const [x0, r0] = prof[j], [x1, r1] = prof[j + 1];
    for (let k = 0; k < N; k++) {
      const a = P(x0, r0, k), b = P(x1, r1, k), c = P(x1, r1, k + 1), d = P(x0, r0, k + 1);
      const hint = [0, (a[1] - axisY) + (c[1] - axisY), a[2] + c[2]];
      face(lowerHalf(k) ? bandPos : hullPos, [a, b, c, d], hint);
    }
  }

  for (const s of [-1, 1]) {
    const x = s * (B + D), r = DOME_R[0] * R, ctr = [x, axisY, 0];
    for (let k = 0; k < N; k++) {
      face(lowerHalf(k) ? bandPos : hullPos, [ctr, P(x, r, k), P(x, r, k + 1)], [s, 0, 0]);
    }
  }
}

const SPAN_MAX = 2 * 0.7634 * 0.93;
const BRACE_BAY = 0.45;
function cradle(G, xc, cradlePos, padPos) {
  const { sides: N, R, axisY } = G;
  const step = (Math.PI * 2) / N;

  const wrap = Math.ceil(N / 12);
  const iStart = -wrap, iEnd = N / 2 + wrap - 1;

  const Ri = R - 0.043;
  const Ro = R + 0.032;
  const hw = 0.05;
  const x0 = xc - hw, x1 = xc + hw;

  const V = (x, r, i) => [x, axisY + r * Math.sin(i * step), r * Math.cos(i * step)];

  for (let i = iStart; i <= iEnd; i++) {
    const a = V(x0, Ro, i), b = V(x1, Ro, i), c = V(x1, Ro, i + 1), d = V(x0, Ro, i + 1);
    face(cradlePos, [a, b, c, d], [0, (a[1] - axisY) + (c[1] - axisY), a[2] + c[2]]);
    face(cradlePos, [V(x1, Ro, i + 1), V(x1, Ro, i), V(x1, Ri, i), V(x1, Ri, i + 1)], [1, 0, 0]);
    face(cradlePos, [V(x0, Ri, i + 1), V(x0, Ri, i), V(x0, Ro, i), V(x0, Ro, i + 1)], [-1, 0, 0]);
  }

  const yBot = 0.03;
  const padH = 0.06;
  let legZo = 0, legZi = 0, legTop = 0;
  for (const i of [iStart, iEnd + 1]) {
    const zo = Ro * Math.cos(i * step), zi = Ri * Math.cos(i * step);
    const yo = axisY + Ro * Math.sin(i * step), yi = axisY + Ri * Math.sin(i * step);
    const s = zo < 0 ? -1 : 1;
    legZo = Math.abs(zo);
    legZi = Math.abs(zi);
    legTop = yo;
    face(cradlePos, [[x0, yBot, zo], [x1, yBot, zo], [x1, yo, zo], [x0, yo, zo]], [0, 0, s]);
    face(cradlePos, [[x0, yBot, zi], [x1, yBot, zi], [x1, yi, zi], [x0, yi, zi]], [0, 0, -s]);
    face(cradlePos, [[x1, yo, zo], [x1, yi, zi], [x1, yBot, zi], [x1, yBot, zo]], [1, 0, 0]);
    face(cradlePos, [[x0, yo, zo], [x0, yi, zi], [x0, yBot, zi], [x0, yBot, zo]], [-1, 0, 0]);
  }

  const legRun = legTop - yBot;
  const bays = Math.max(1, Math.ceil(legRun / BRACE_BAY - 1e-9));
  for (let b = 1; b < bays; b++) {
    const y = yBot + (legRun * b) / bays;
    boxInto(cradlePos, xc - 0.03, xc + 0.03, y, y + 0.075,
      -(legZi + 0.01), legZi + 0.01, { pz: true, nz: true });
  }

  const padHalfZ = legZo + 0.055;
  boxInto(padPos, xc - 0.13, xc + 0.13, 0, padH, -padHalfZ, padHalfZ);
}

function resolveColors(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['hull', 'band', 'cradle', 'pads']) {
    C[k] = p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  return C;
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const num = (v, spec) => clamp(v === undefined ? spec.default : Number(v), spec.min, spec.max);

export function createAsset(p = {}) {
  const C = resolveColors(p);

  const girth = num(p.girth, params.girth);
  const lengthK = num(p.tankLength, params.tankLength);
  const standK = num(p.standHeight, params.standHeight);

  const chord = FACET_SIDES[p.facets] || FACET_SIDES[params.facets.default];
  const sides = 2 * Math.max(4, Math.round((chord * girth) / 2));

  const R = 0.55 * girth;
  const G = {
    sides,
    R,
    girth,
    domeD: 0.27 * girth,
    halfBarrel: 0.93 * lengthK,
    axisY: 0.20 * standK + R,
  };

  const hullPos = [], bandPos = [], cradlePos = [], padPos = [];
  vessel(G, hullPos, bandPos);

  const xOuter = 0.7634 * G.halfBarrel;
  const bays = Math.max(1, Math.ceil((2 * xOuter) / SPAN_MAX - 1e-9));
  for (let i = 0; i <= bays; i++) {
    cradle(G, xOuter - (i * 2 * xOuter) / bays, cradlePos, padPos);
  }

  const mesh = finish([
    { g: posGeo(hullPos), c: C.hull },
    { g: posGeo(bandPos), c: C.band },
    { g: posGeo(cradlePos), c: C.cradle },
    { g: posGeo(padPos), c: C.pads },
  ]);
  mesh.name = 'tank-shell';

  const g = new THREE.Group();
  g.name = 'horizontal-tank';
  g.add(mesh);
  return g;
}

export default createAsset;

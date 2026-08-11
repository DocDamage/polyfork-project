/*
 * Survey Flag
 * https://polyfork.dev/asset/survey-flag-fa500f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './survey-flag-fa500f.mjs';
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
 *   colorway   choice  'astro-orange' 'astro-orange' | 'deep-slate' | 'regolith-tan' | 'gunmetal'
 *   mast       color   '#b4b7bc'      any hex or THREE.Color
 *   collar     color   '#737785'      any hex or THREE.Color
 *   ferrule    color   '#5f6570'      any hex or THREE.Color
 *   spike      color   '#3d3f47'      any hex or THREE.Color
 *   pennant    color   '#b2684b'      any hex or THREE.Color
 *   tallness   range   1              0.62 to 1.28
 *   flagSize   range   1              0.7 to 1.4
 *   flagShape  choice  'pennant'      'pennant' | 'swallowtail' | 'banner'
 *
 * Every option is described in full at https://polyfork.dev/cdn/survey-flag-fa500f-params.json
 *
 * SPECS  308 triangles, 1 material, 0.56 x 1.45 x 0.14 m (real-world scale).
 * PARTS  animate: flag
 *        detach: flag
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'astro-orange': { mast: '#b4b7bc', collar: '#737785', ferrule: '#5f6570', spike: '#3d3f47', pennant: '#b2684b' },
  'deep-slate':   { mast: '#989ea7', collar: '#737785', ferrule: '#5f6570', spike: '#1d1e26', pennant: '#434e67' },
  'regolith-tan': { mast: '#c1a078', collar: '#856f5d', ferrule: '#73594d', spike: '#3e2f2b', pennant: '#975b44' },
  'gunmetal':     { mast: '#878c94', collar: '#5f6570', ferrule: '#3d3f47', spike: '#1d1e26', pennant: '#ac7c64' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'astro-orange', label: 'Colorway', affects: 'colors',
    options: ['astro-orange', 'deep-slate', 'regolith-tan', 'gunmetal'],
    describe: 'Curated kit-coherent scheme. astro-orange = pale off-white mast, gunmetal ' +
      'fittings and the kit rust-orange pennant (the approved default, a claim/hazard ' +
      'marker readable across open regolith); deep-slate keeps the pale mast but flies a ' +
      'deep blue pennant on a near-black spike, for a survey grid marker that must NOT read ' +
      'as a warning; regolith-tan is a dust-caked field stake, tan mast and brown flag, for ' +
      'gear that has stood out in the storm; gunmetal is the darkest, a grey mast with a ' +
      'muted tan pennant for low-visibility survey work.',
  },
  mast: {
    type: 'color', default: '#b4b7bc', label: 'Mast', affects: 'colors',
    describe: 'Albedo of the whole painted-aluminium pole and its top cap — about half the ' +
      'visible surface and the lightest value in the asset, so the thin vertical line stays ' +
      'readable against dark ground. Going darker than the collars collapses the mast, the ' +
      'collars and the spike into one silhouette.',
  },
  collar: {
    type: 'color', default: '#737785', label: 'Joint collars', affects: 'colors',
    describe: 'Albedo of the small proud rings that pitch up the mast, the screw joints of a ' +
      'sectional survey rod. Wants to sit exactly one value step darker than the mast: ' +
      'lighter and the rings disappear, much darker and they read as three black bands ' +
      'chopping the pole into pieces.',
  },
  ferrule: {
    type: 'color', default: '#5f6570', label: 'Ferrule', affects: 'colors',
    describe: 'Albedo of the short proud socket where the mast plugs into the ground spike. ' +
      'It is the mid rung of the value ladder — pale mast, mid ferrule, near-black spike — ' +
      'and is what stops the foot of the asset reading as one undifferentiated dark lump.',
  },
  spike: {
    type: 'color', default: '#3d3f47', label: 'Ground spike', affects: 'colors',
    describe: 'Albedo of the faceted steel ground spike: the shoulder, the long point and the ' +
      'step under the ferrule. The darkest value in the asset — it is the arrowhead half of ' +
      'the silhouette and needs to read as a hard black wedge at thumbnail size.',
  },
  pennant: {
    type: 'color', default: '#b2684b', label: 'Pennant', affects: 'colors',
    describe: 'Albedo of the cloth, one flat tone on BOTH faces (the fold is shaded by the ' +
      'renderer, never painted). This is the only colour event on the object and the only ' +
      'thing that says "marker" rather than "aerial", so keep it the most saturated hue in ' +
      'the scheme; a near-neutral flag makes the whole asset vanish into the terrain.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.62, max: 1.28, label: 'Tallness', affects: 'geometry',
    describe: 'Stretches the bare mast run only; the spike, the pennant and the cap keep ' +
      'their size, so the flag stays a small object riding a longer or shorter pole. Total ' +
      'height runs from 1.00 m at 0.62 — a knee-high stake whose flag and spike nearly touch ' +
      '— through the 1.45 m default to 1.78 m at 1.28, a tall sighting rod visible over a ' +
      'rover. The joint collars redistribute over the new bare run and drop from three to ' +
      'two to one as the run shortens, so they never crowd.',
  },
  flagSize: {
    type: 'range', default: 1.0, min: 0.70, max: 1.40, label: 'Flag size', affects: 'geometry',
    describe: 'Scales the pennant in length and height together about its hoist. At 0.70 it ' +
      'is a 0.36 x 0.21 m tab, a discreet plot marker; at 1.40 it is a 0.73 x 0.42 m banner ' +
      'that dominates the top third of the mast and reads from across a base. The fold ' +
      'amplitude scales with it, so a big flag keeps the same cloth character instead of ' +
      'flattening into a card.',
  },
  flagShape: {
    type: 'choice', default: 'pennant', label: 'Flag shape', affects: 'geometry',
    options: ['pennant', 'swallowtail', 'banner'],
    describe: 'Outline of the cloth at the fly end. pennant = the approved default, a ' +
      'rectangular hoist tapering to a near-point (a directional survey flag); swallowtail ' +
      'keeps full height and cuts a deep V notch into the fly, giving two forked tails (a ' +
      'route or rally marker); banner is an uncut rectangle, the biggest, calmest silhouette ' +
      '(a claim or hazard placard). All three share the same triangle count and the same fold.',
  },
};

export const rig = { 'flag': { axis: 'y', range: [0, 62] } };
export const detach = ['flag'];

export const night = {};

const SIDES = 8;
const POLE_R = 0.022;
const CAP_R = 0.016, CAP_H = 0.013;
const COLLAR_R = 0.030, COLLAR_H = 0.030, COLLAR_C = 0.008;

const SPIKE_ROWS = [
  [0.000, 0.000], [0.046, 0.150], [0.040, 0.205], [0.030, 0.226],
];
const FERRULE_ROWS = [
  [0.030, 0.226], [0.028, 0.258], [POLE_R, 0.272],
];
const SPIKE_TOP = 0.272;

const POLE_RUN = 1.178;
const FLAG_L = 0.52, FLAG_H = 0.30;
const FLAG_DROP = 0.030;
const HOIST_X = -0.010;

const CLOTH_U = [0, 0.42, 0.58, 0.80, 1.00];

const CLOTH_Z = [0, -0.014, 0.004, 0.050, 0.086];
const CLOTH_V = [0, 0.5, 1];
const CLOTH_T = 0.016;

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

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function ringPt(r, y, i) {
  const a = ((i + 0.5) / SIDES) * Math.PI * 2;
  return [r * Math.sin(a), y, r * Math.cos(a)];
}

function band(out, r0, y0, r1, y1) {
  for (let k = 0; k < SIDES; k++) {
    const a = ringPt(r0, y0, k), b = ringPt(r1, y1, k);
    const c = ringPt(r1, y1, k + 1), d = ringPt(r0, y0, k + 1);
    if (r0 < 1e-6) face(out, [[0, y0, 0], b, c], [b[0] + c[0], 0, b[2] + c[2]]);
    else if (r1 < 1e-6) face(out, [[0, y1, 0], a, d], [a[0] + d[0], 0, a[2] + d[2]]);
    else face(out, [a, b, c, d], [a[0] + c[0], 0, a[2] + c[2]]);
  }
}

function rows(out, list) {
  for (let i = 0; i < list.length - 1; i++) {
    band(out, list[i][0], list[i][1], list[i + 1][0], list[i + 1][1]);
  }
}

function discUp(out, r, y) {
  for (let k = 0; k < SIDES; k++) {
    face(out, [[0, y, 0], ringPt(r, y, k), ringPt(r, y, k + 1)], [0, 1, 0]);
  }
}

function outline(shape) {
  if (shape === 'swallowtail') {
    return {
      top: () => 1, bot: () => 0,
      lenFrac: (v) => 1 - 0.34 * Math.max(0, 1 - Math.abs(v - 0.5) / 0.5),
    };
  }
  if (shape === 'banner') {
    return { top: () => 1, bot: () => 0, lenFrac: () => 1 };
  }

  return {
    top: (u) => (u <= 0.58 ? 1 : 1 - 0.42 * (u - 0.58) / 0.42),
    bot: (u) => (u <= 0.42 ? 0 : 0.50 * (u - 0.42) / 0.58),
    lenFrac: () => 1,
  };
}

function cloth(out, L, H, yBot, shape) {
  const o = outline(shape);
  const NX = CLOTH_U.length - 1, NY = CLOTH_V.length - 1;
  const scale = H / FLAG_H;
  const P = [];
  for (let i = 0; i <= NX; i++) {
    P.push([]);
    for (let j = 0; j <= NY; j++) {
      const u = CLOTH_U[i], v = CLOTH_V[j];
      const x = HOIST_X + u * o.lenFrac(v) * (L - HOIST_X);
      const f = o.bot(u) + v * (o.top(u) - o.bot(u));
      const y = yBot + f * H;
      P[i].push([x, y, CLOTH_Z[i] * scale]);
    }
  }

  const F = (p) => [p[0], p[1], p[2] + CLOTH_T / 2];
  const B = (p) => [p[0], p[1], p[2] - CLOTH_T / 2];
  for (let i = 0; i < NX; i++) {
    for (let j = 0; j < NY; j++) {
      const a = P[i][j], b = P[i + 1][j], c = P[i + 1][j + 1], d = P[i][j + 1];
      tri(out, F(a), F(b), F(c)); tri(out, F(a), F(c), F(d));
      tri(out, B(a), B(c), B(b)); tri(out, B(a), B(d), B(c));
    }
  }

  for (let i = 0; i < NX; i++) {
    const t0 = P[i][NY], t1 = P[i + 1][NY];
    face(out, [F(t0), F(t1), B(t1), B(t0)], [0, 1, 0]);
    const b0 = P[i][0], b1 = P[i + 1][0];
    face(out, [F(b0), F(b1), B(b1), B(b0)], [0, -1, 0]);
  }
  for (let j = 0; j < NY; j++) {
    const f0 = P[NX][j], f1 = P[NX][j + 1];
    face(out, [F(f0), F(f1), B(f1), B(f0)], [1, 0, 0]);
  }
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

function material() {
  return new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
}

function finish(list, mat) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  if (!merged) throw new Error('mergeGeometries returned null — attribute sets disagree');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, mat);
}

function resolveColors(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['mast', 'collar', 'ferrule', 'spike', 'pennant']) {
    C[k] = p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  return C;
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const num = (v, spec) => clamp(v === undefined ? spec.default : Number(v), spec.min, spec.max);

export function createAsset(p = {}) {
  const C = resolveColors(p);
  const tallness = num(p.tallness, params.tallness);
  const flagSize = num(p.flagSize, params.flagSize);
  const shape = params.flagShape.options.includes(p.flagShape)
    ? p.flagShape : params.flagShape.default;

  const poleTop = SPIKE_TOP + POLE_RUN * tallness;
  const L = FLAG_L * flagSize, H = FLAG_H * flagSize;
  const flagTop = poleTop - CAP_H - FLAG_DROP;
  const flagBot = flagTop - H;

  const mastPos = [], collarPos = [], ferrulePos = [], spikePos = [], clothPos = [];

  rows(spikePos, SPIKE_ROWS);
  rows(ferrulePos, FERRULE_ROWS);

  band(mastPos, POLE_R, 0.16, POLE_R, poleTop - CAP_H);
  rows(mastPos, [[POLE_R, poleTop - CAP_H], [CAP_R, poleTop]]);
  discUp(mastPos, CAP_R, poleTop);

  const yLo = SPIKE_TOP + 0.12, yHi = flagBot - 0.08;
  const span = yHi - yLo;
  const nCollars = span > 0.55 ? 3 : span > 0.28 ? 2 : 1;
  for (let i = 0; i < nCollars; i++) {
    const t = nCollars === 1 ? 0.5 : i / (nCollars - 1);
    const y0 = yLo + t * Math.max(span, 0) - COLLAR_H / 2;
    rows(collarPos, [
      [POLE_R, y0], [COLLAR_R, y0 + COLLAR_C],
      [COLLAR_R, y0 + COLLAR_H - COLLAR_C], [POLE_R, y0 + COLLAR_H],
    ]);
  }

  cloth(clothPos, L, H, flagBot, shape);

  const mat = material();

  const mast = finish([
    { g: posGeo(mastPos), c: C.mast },
    { g: posGeo(collarPos), c: C.collar },
    { g: posGeo(ferrulePos), c: C.ferrule },
    { g: posGeo(spikePos), c: C.spike },
  ], mat);
  mast.name = 'mast';

  const clothMesh = finish([{ g: posGeo(clothPos), c: C.pennant }], mat);
  clothMesh.name = 'flag-cloth';

  const flag = new THREE.Group();
  flag.name = 'flag';
  flag.add(clothMesh);

  const g = new THREE.Group();
  g.name = 'survey-flag';
  g.add(mast);
  g.add(flag);
  return g;
}

export default createAsset;

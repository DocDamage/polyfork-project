/*
 * Tree Stump
 * https://polyfork.dev/asset/tree-stump-00f3bf
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './tree-stump-00f3bf.mjs';
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
 *   colorway    choice  'weathered-oak' 'weathered-oak' | 'pale-driftwood' | 'sun-bleached' | 'dark-mangrove'
 *   bark        color   '#6B4526'      any hex or THREE.Color
 *   sawnWood    color   '#F0E6CE'      any hex or THREE.Color
 *   heartwood   color   '#DCCBA6'      any hex or THREE.Color
 *   tallness    range   0.6            0.44 to 0.76
 *   roots       range   3              3 to 6
 *   facets      range   12             9 to 15
 *   rootSpread  range   1              0.62 to 1.15
 *
 * Every option is described in full at https://polyfork.dev/cdn/tree-stump-00f3bf-params.json
 *
 * SPECS  456 triangles, 1 material, 0.91 x 0.6 x 0.77 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-oak':  { bark: '#6B4526', sawnWood: '#F0E6CE', heartwood: '#DCCBA6' },
  'pale-driftwood': { bark: '#8A8071', sawnWood: '#E9F5F2', heartwood: '#DCCBA6' },
  'sun-bleached':   { bark: '#9C6B3C', sawnWood: '#E8D6A8', heartwood: '#C4A46A' },
  'dark-mangrove':  { bark: '#4A2E1B', sawnWood: '#F0E6CE', heartwood: '#DCCBA6' },
};
const ZONE_KEYS = ['bark', 'sawnWood', 'heartwood'];

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: Object.keys(COLORWAYS),
    describe: 'Curated Pirate Cove wood schemes. weathered-oak is warm mid-brown bark under a cream sawn face; pale-driftwood is grey sea-bleached timber with an almost white cut; sun-bleached is dry orange-brown driftwood; dark-mangrove is near-black wet bark that makes the pale cut pop hardest. Sets bark, sawnWood and heartwood unless those are passed explicitly.',
  },
  bark: {
    type: 'color', default: COLORWAYS['weathered-oak'].bark, label: 'Bark',
    describe: 'Albedo of the ENTIRE trunk exterior, the root flares, the crown rim and the underside — about four fifths of the visible surface and the dominant colour of the prop. The facets, not this colour, do the shading.',
  },
  sawnWood: {
    type: 'color', default: COLORWAYS['weathered-oak'].sawnWood, label: 'Sawn face',
    describe: 'Albedo of the flat sapwood ring of the cut top. Keep it clearly LIGHTER than Bark — it is the only bright mass on the prop and the whole silhouette read at distance depends on the contrast.',
  },
  heartwood: {
    type: 'color', default: COLORWAYS['weathered-oak'].heartwood, label: 'Heartwood',
    describe: 'Albedo of the bullseye disc at the centre of the cut, 0.44 of the sawn face radius. A warm step darker than Sawn face; set it equal to Sawn face and the growth-ring read disappears, leaving one flat lid.',
  },
  tallness: {
    type: 'range', default: 0.60, min: 0.44, max: 0.76, label: 'Tallness', affects: 'geometry',
    describe: 'Height of the cut face above the ground, in metres, REBUILT not scaled: the bark drum gains or loses whole ring bands at a constant 0.105 m pitch, so the triangle count moves with it (366 tris at 0.44, 414 at the default, 438 at 0.76). 0.44 is a squat knee-high block no taller than its roots are long; 0.76 is a thigh-high post you could sit on. Trunk girth (0.60 m at the ground, 0.40 m at the cut) and the root flares are unchanged at every value, so a tall one reads slender and a short one reads chunky.',
  },
  roots: {
    type: 'range', default: 3, min: 3, max: 6, step: 1, label: 'Root flares', affects: 'geometry',
    describe: 'How many root spikes splay off the base. Each is a real lofted arm booked onto its own bark facet, so the count changes the triangle budget and the star footprint: 3 is the wide-open tripod of the reference, 6 is a dense crown of shorter-looking claws with almost no bark left showing between them. One root always points at +Z.',
  },
  facets: {
    type: 'range', default: 12, min: 9, max: 15, step: 1, label: 'Bark facets', affects: 'geometry',
    describe: 'Number of columns around the bark drum, i.e. how coarse the faceting is. Columns alternate raised ridge and sunken groove, so this also sets how many in-and-out corners the outline carries: 9 gives a hard chunky hand-hewn prism whose ridges read from across a scene; 15 gives a finer, more closely scalloped log. Changes the triangle count and the number of corners in the outline, never the diameter.',
  },
  rootSpread: {
    type: 'range', default: 1.0, min: 0.62, max: 1.15, label: 'Root spread', affects: 'geometry',
    describe: 'How far the claws reach out from the trunk core. 0.62 pulls them into stubby knuckles barely past the bark, a 0.64 m footprint that reads as a plain sawn block; the 1.0 default is the reference tripod, its tips planted 0.53 m out; 1.15 throws them into long low claws for a footprint over a metre wide. The trunk itself never moves, so this changes the star, not the stump — triangle count is unchanged, because nothing repeats along a root.',
  },
};
export const presets = COLORWAYS;

const R_BASE = 0.300;
const R_TOP = 0.200;
const RING_PITCH = 0.105;

const FLARE_S = 0.09;
const FLARE_H = 0.42;
const ARCH_LIFT = 0.055;

const flareWidth = (nRoots) => Math.min(0.48, (Math.PI / nRoots) * 0.85);

const RIDGE_OUT = 0.09;
const GROOVE_IN = -0.13;

const RIM_F = 0.83;
const HEART_F = 0.48;
const CUT_DROP = 0.010;
const CHAMF_H = 0.014;
const CHAMF_IN = 0.050;

const SPREAD_ORIGIN = 0.100;
const ROOT_PATH = [
  { u: 0.225, yT: 0.345, yB: 0.000, w: 0.120 },
  { u: 0.318, yT: 0.278, yB: 0.014, w: 0.122 },
  { u: 0.390, yT: 0.208, yB: 0.048, w: 0.092 },
  { u: 0.450, yT: 0.130, yB: 0.036, w: 0.055 },
  { u: 0.487, yT: 0.055, yB: 0.000, w: 0.026 },
].map(S => ({ u: S.u, y: (S.yT + S.yB) / 2, h: (S.yT - S.yB) / 2, w: S.w }));

const ROOT_SECT = [
  [1.00, 0.00], [0.72, 0.62], [0.10, 0.95], [-0.55, 0.72],
  [-0.85, 0.00], [-0.55, -0.72], [0.10, -0.95], [0.72, -0.62],
];

const ROOT_VAR = [
  { len: 1.00, tall: 1.05, w: 1.00 },
  { len: 1.06, tall: 0.88, w: 0.94 },
  { len: 0.93, tall: 1.10, w: 1.07 },
  { len: 1.02, tall: 0.95, w: 0.97 },
];

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

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

function mergeParts(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return merged;
}

function angDiff(a, b) {
  const d = Math.abs(a - b) % (Math.PI * 2);
  return d > Math.PI ? Math.PI * 2 - d : d;
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

function buildStump(P, C, parts) {
  const { H, COLS, ROOT_A, spread } = P;
  const BANDS = Math.max(3, Math.round(H / RING_PITCH));

  const trunkR = (y) => {
    const t = clamp(1 - y / H, 0, 1);
    return R_TOP + (R_BASE - R_TOP) * (t + 0.28 * t * (1 - t));
  };

  const FW = flareWidth(ROOT_A.length);
  const rootW = (a) => {
    let w = 0;
    for (const A of ROOT_A) {
      const d = angDiff(a, A) / FW;
      w = Math.max(w, Math.exp(-d * d));
    }
    return w;
  };

  const flare = (a, y) => FLARE_S * rootW(a) * Math.pow(clamp(1 - y / FLARE_H, 0, 1), 1.3);

  const rankOf = (i) => Math.min((i - 1 + COLS) % COLS, (COLS - i) % COLS);
  const rnd = prng(913277);
  const GNARL_T = Array.from({ length: COLS }, () => 0.955 + rnd() * 0.105);
  const WOB_T = Array.from({ length: COLS }, () => (rnd() - 0.5) * 0.010);
  const isRidge = (i) => rankOf(i) % 2 === 0;

  const JIT = Array.from({ length: BANDS + 1 }, () =>
    Array.from({ length: COLS }, () => 0.94 + rnd() * 0.12));

  const ANG0 = Math.PI / 2 - Math.PI / COLS;
  const colAngle = (ci) => ANG0 + (ci / COLS) * Math.PI * 2;

  const reliefAt = (y) => 1 - 0.26 * Math.pow(clamp(y / H, 0, 1), 2.2);

  const jitAt = (y) => 1 - 0.65 * Math.pow(clamp(y / H, 0, 1), 2);

  const radiusAt = (ri, ci, y) => {
    const k = rankOf(ci);
    const a = colAngle(ci);
    const rel = 1 + (isRidge(ci) ? RIDGE_OUT : GROOVE_IN) * reliefAt(y);
    const jit = 1 + (JIT[ri][k] - 1) * jitAt(y);
    return trunkR(y) * GNARL_T[k] * rel * jit * (1 + flare(a, y));
  };

  const baseY = (ci) => ARCH_LIFT * Math.pow(clamp(1 - rootW(colAngle(ci)) * 1.45, 0, 1), 1.6);

  const ringY = (ri, ci) => (ri === 0 ? baseY(ci) : (ri / BANDS) * (H - CHAMF_H));
  function ringVert(ri, ci) {
    const y = ringY(ri, ci);
    const a = colAngle(ci);
    const r = radiusAt(ri, ci, y);
    return [Math.cos(a) * r, y, Math.sin(a) * r];
  }

  const crownVert = (ci) => {
    const v = ringVert(BANDS, ci);
    return [v[0] * (1 - CHAMF_IN), H + WOB_T[rankOf(ci)], v[2] * (1 - CHAMF_IN)];
  };

  const bark = [];

  for (let ri = 0; ri < BANDS; ri++) {
    for (let ci = 0; ci < COLS; ci++) {
      const cj = (ci + 1) % COLS;
      quad(bark, ringVert(ri, ci), ringVert(ri + 1, ci), ringVert(ri + 1, cj), ringVert(ri, cj));
    }
  }

  for (let ci = 0; ci < COLS; ci++) {
    const cj = (ci + 1) % COLS;
    quad(bark, ringVert(BANDS, ci), crownVert(ci), crownVert(cj), ringVert(BANDS, cj));
  }

  for (let ci = 0; ci < COLS; ci++) {
    tri(bark, [0, ARCH_LIFT * 0.85, 0], ringVert(0, ci), ringVert(0, (ci + 1) % COLS));
  }

  const Y_CUT = H - CUT_DROP;
  const ringAt = (f) => Array.from({ length: COLS }, (_, ci) => {
    const v = crownVert(ci);
    return [v[0] * f, Y_CUT, v[2] * f];
  });
  const rim = ringAt(RIM_F), hrt = ringAt(HEART_F);
  const cut = [], heart = [];

  for (let ci = 0; ci < COLS; ci++) {
    const cj = (ci + 1) % COLS;
    quad(bark, crownVert(ci), rim[ci], rim[cj], crownVert(cj));
    quad(cut, rim[ci], hrt[ci], hrt[cj], rim[cj]);
    tri(heart, [0, Y_CUT, 0], hrt[cj], hrt[ci]);
  }

  for (let k = 0; k < ROOT_A.length; k++) {
    const V = ROOT_VAR[Math.min(k, (ROOT_A.length - k) % ROOT_A.length) % ROOT_VAR.length];
    bark.push(...loftArm(ROOT_A[k], V, spread));
  }

  parts.push({ g: posGeo(bark), c: C.bark });
  parts.push({ g: posGeo(cut), c: C.sawnWood });
  parts.push({ g: posGeo(heart), c: C.heartwood });
}

function loftArm(A, V, spread) {
  const u = new THREE.Vector3(Math.cos(A), 0, Math.sin(A));
  const t = new THREE.Vector3(-Math.sin(A), 0, Math.cos(A));
  const up = new THREE.Vector3(0, 1, 0);
  const rings = ROOT_PATH.map((S) => {

    const uu = SPREAD_ORIGIN + (S.u - SPREAD_ORIGIN) * spread * V.len;
    const yy = S.y * V.tall;
    const w = S.w * V.w, h = S.h * V.tall;
    const c = new THREE.Vector3().copy(u).multiplyScalar(uu).setY(yy);
    return ROOT_SECT.map(([cu, cs]) => [
      c.x + up.x * cu * h + t.x * cs * w,
      c.y + up.y * cu * h + t.y * cs * w,
      c.z + up.z * cu * h + t.z * cs * w,
    ]);
  });

  const pos = [];
  for (let i = 0; i < rings.length - 1; i++) {
    for (let s = 0; s < ROOT_SECT.length; s++) {
      const j = (s + 1) % ROOT_SECT.length;
      quad(pos, rings[i][s], rings[i][j], rings[i + 1][j], rings[i + 1][s]);
    }
  }

  const last = rings[rings.length - 1];
  const cx = last.reduce((a, p) => a + p[0], 0) / last.length;
  const cy = last.reduce((a, p) => a + p[1], 0) / last.length;
  const cz = last.reduce((a, p) => a + p[2], 0) / last.length;
  for (let s = 0; s < ROOT_SECT.length; s++) {
    tri(pos, [cx, cy, cz], last[s], last[(s + 1) % ROOT_SECT.length]);
  }
  return pos;
}

function resolve(p) {
  const cwName = COLORWAYS[p.colorway] ? p.colorway : params.colorway.default;
  const C = { ...COLORWAYS[cwName] };

  for (const k of ZONE_KEYS) if (p[k] !== undefined) C[k] = p[k];

  const H = clamp(p.tallness !== undefined ? +p.tallness : params.tallness.default,
    params.tallness.min, params.tallness.max);
  const COLS = Math.round(clamp(p.facets !== undefined ? +p.facets : params.facets.default,
    params.facets.min, params.facets.max));
  const NR = Math.round(clamp(p.roots !== undefined ? +p.roots : params.roots.default,
    params.roots.min, params.roots.max));
  const spread = clamp(p.rootSpread !== undefined ? +p.rootSpread : params.rootSpread.default,
    params.rootSpread.min, params.rootSpread.max);

  const ANG0 = Math.PI / 2 - Math.PI / COLS;
  const booked = [];
  for (let k = 0; k < NR; k++) {
    let b = Math.round((k * COLS) / NR) % COLS;
    while (booked.includes(b)) b = (b + 1) % COLS;
    booked.push(b);
  }
  const ROOT_A = booked.map(b => ANG0 + ((b + 0.5) / COLS) * Math.PI * 2);

  return { C, P: { H, COLS, ROOT_A, spread } };
}

export function createAsset(userParams = {}) {
  const { C, P } = resolve(userParams);

  const g = new THREE.Group();
  g.name = 'tree-stump';

  const parts = [];
  buildStump(P, C, parts);
  const geo = mergeParts(parts);

  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'stump-mesh';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

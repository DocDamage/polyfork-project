/*
 * Broadleaf Oak
 * https://polyfork.dev/asset/broadleaf-oak-997c22
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './broadleaf-oak-997c22.mjs';
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
 *   colorway   choice  'summer-oak'   'summer-oak' | 'spring-oak' | 'deep-forest' | 'autumn-oak'
 *   leaf       color   '#4c8140'      any hex or THREE.Color
 *   leafLight  color   '#77b258'      any hex or THREE.Color
 *   bark       color   '#4a3527'      any hex or THREE.Color
 *   foot       color   '#75563b'      any hex or THREE.Color
 *   tallness   range   1              0.82 to 1.06
 *   limbs      range   3              2 to 5
 *   canopy     range   1              0.84 to 1.16
 *
 * Every option is described in full at https://polyfork.dev/cdn/broadleaf-oak-997c22-params.json
 *
 * SPECS  457 triangles, 1 material, 4.5 x 6.98 x 3.57 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'summer-oak': {
    bark: '#4a3527', foot: '#75563b', leaf: '#4c8140', leafLight: '#77b258',
  },
  'spring-oak': {
    bark: '#5d4430', foot: '#8c6a47', leaf: '#5f9a4b', leafLight: '#93c46a',
  },
  'deep-forest': {
    bark: '#3a2a1e', foot: '#5d4430', leaf: '#2f4f2e', leafLight: '#4c8140',
  },
  'autumn-oak': {
    bark: '#4a3527', foot: '#75563b', leaf: '#e2833f', leafLight: '#f0c05a',
  },
};
export const presets = COLORWAYS;

const ZONES = ['bark', 'foot', 'leaf', 'leafLight'];

export const params = {
  colorway: {
    type: 'choice', default: 'summer-oak', label: 'Colorway',
    options: ['summer-oak', 'spring-oak', 'deep-forest', 'autumn-oak'],
    describe: 'Curated kit-palette scheme; sets all four zone colours at once. ' +
      'summer-oak is the shipped build: dark brown limbs over a lighter warm brown foot, ' +
      'a mid-green main canopy lump and a step-lighter green on the satellite lumps. ' +
      'spring-oak lifts the whole canopy to fresh acid green and warms the bark. ' +
      'deep-forest drops the foliage to heavy dark green over near-black bark, an old ' +
      'oak standing in shade. autumn-oak turns the crown amber and gold over unchanged ' +
      'bark. Every scheme keeps the canopy one hue family with the main lump dominant ' +
      'and the trunk clearly darker than the foliage.',
  },
  leaf: {
    type: 'color', default: '#4c8140', label: 'Leaf (main canopy lump)',
    describe: 'The DOMINANT canopy tone — the one big rounded lump that is the tree, ' +
      'about two thirds of all foliage, and the colour the oak is named by at a ' +
      'distance. One uniform mid green on every facet: the lump is real faceted ' +
      'geometry and the scene lights shade it. This should always be the tone that wins.',
  },
  leafLight: {
    type: 'color', default: '#77b258', label: 'Leaf (satellite lumps)',
    describe: 'The lighter green: every satellite and shoulder lump clustered around the ' +
      'main mass, plus two hand-aimed patches inside the main mass (one up-facing, one ' +
      'down-facing, so it is structured foliage variation and never baked shading). ' +
      'Must sit a clear value step above the main canopy tone or the lumps fuse into ' +
      'the big mass and the crown reads as one flat ball.',
  },
  bark: {
    type: 'color', default: '#4a3527', label: 'Bark (upper trunk and limbs)',
    describe: 'Albedo of the trunk above the bark line at 1.15 m and of all three limbs ' +
      '— one uniform dark brown on every facet, because the taper, the bow and the six ' +
      'flat columns are real geometry. Clearly darker than the foot and far darker than ' +
      'any foliage tone, so the fork reads as a dark Y against the green.',
  },
  foot: {
    type: 'color', default: '#75563b', label: 'Bark (lower trunk)',
    describe: 'The lower 1.15 m of the trunk plus its root flare, in a lighter warm ' +
      'brown that ends on a real bark line rather than fading. Lighter than the upper ' +
      'bark — this is deliberate albedo and the inverse of a light-from-above gradient. ' +
      'At parity with the upper bark the trunk loses its footing and reads as a plain ' +
      'stick; pushed too pale it reads as stone.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.82, max: 1.06, affects: 'geometry',
    label: 'Tallness',
    describe: 'How tall this oak has grown, about 6.1 m at 0.82 to 7.3 m at 1.06 (7.0 m ' +
      'at the shipped default). REBUILT, not scaled: the trunk gains RINGS at a constant ' +
      '0.55 m pitch — four above the bark line at 0.82, six at 1.06 — so the triangle ' +
      'count moves with the knob, and the limbs re-solve their tips against the crown at ' +
      'its new height. The trunk girth, the root flare, the bark line at 1.15 m and every ' +
      'foliage mass are untouched: a tall one is a leggier tree carrying the same head.',
  },
  limbs: {
    type: 'range', default: 3, min: 2, max: 5, step: 1, affects: 'geometry',
    label: 'Limbs at the fork',
    describe: 'How many limbs the trunk splits into, counting the leader that carries on ' +
      'up into the crown. Each extra limb is a real lofted branch plus its own satellite ' +
      'foliage lump, so the triangle count moves. At 2 a spare tree — one leader and one ' +
      'side limb, with a lot of sky under the crown; at 3 (shipped) the reference oak, a ' +
      'clear Y with a big lump left and a smaller one right; at 5 a dense four-way fork ' +
      'with a lump in every quadrant. The limbs are hand-placed at fixed azimuths and ' +
      'heights so extra ones fill the empty quarters rather than widening the tree, and ' +
      'the spread stays inside 4.3 m at every value.',
  },
  canopy: {
    type: 'range', default: 1.0, min: 0.84, max: 1.16, affects: 'geometry',
    label: 'Canopy fullness',
    describe: 'The size of every foliage mass together — the big lump, the satellite ' +
      'lumps and the shoulder lumps — from 0.84 (a thin, see-through crown with a lot of ' +
      'limb showing and a deeply scalloped outline) to 1.16 (a heavy nearly closed head ' +
      'where the satellites merge into the main mass). A foliage blob has no repeating ' +
      'structure inside it, so this knob honestly resizes the masses instead of ' +
      'pretending to rebuild them; the limbs re-solve their tips against the new surface ' +
      'so no branch is ever left stopping in open air, and the trunk is untouched. The ' +
      'two rebuilding size knobs are tallness and limbs.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
const mid = (a, b) => [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2, (a[2] + b[2]) / 2];
function unit(a, b) {
  const d = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
  const l = Math.hypot(d[0], d[1], d[2]) || 1;
  return [d[0] / l, d[1] / l, d[2] / l];
}
const dot3 = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

function roundPoles(geo, a = 0.45) {
  const pos = geo.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    const r = Math.hypot(x, y, z);
    if (r < 1e-9) continue;
    const phi = Math.acos(Math.max(-1, Math.min(1, y / r)));
    const t = phi / Math.PI;
    const p2 = (t - a * Math.sin(2 * Math.PI * t) / (2 * Math.PI)) * Math.PI;
    const s = Math.sin(phi);
    const k = s < 1e-6 ? 0 : Math.sin(p2) / s;
    pos.setXYZ(i, x * k, r * Math.cos(p2), z * k);
  }
  return geo;
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
  const live = list.filter(p => p.g.attributes.position.count > 0);
  const merged = mergeGeometries(live.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const RAY = [0.57735, 0.57734, 0.57736];

function pointInMesh(tris, p) {
  let hits = 0;
  for (let i = 0; i < tris.length; i += 9) {
    const e1 = [tris[i + 3] - tris[i], tris[i + 4] - tris[i + 1], tris[i + 5] - tris[i + 2]];
    const e2 = [tris[i + 6] - tris[i], tris[i + 7] - tris[i + 1], tris[i + 8] - tris[i + 2]];
    const h = [RAY[1] * e2[2] - RAY[2] * e2[1], RAY[2] * e2[0] - RAY[0] * e2[2], RAY[0] * e2[1] - RAY[1] * e2[0]];
    const a = e1[0] * h[0] + e1[1] * h[1] + e1[2] * h[2];
    if (a > -1e-12 && a < 1e-12) continue;
    const f = 1 / a;
    const s = [p[0] - tris[i], p[1] - tris[i + 1], p[2] - tris[i + 2]];
    const u = f * (s[0] * h[0] + s[1] * h[1] + s[2] * h[2]);
    if (u < 0 || u > 1) continue;
    const q = [s[1] * e1[2] - s[2] * e1[1], s[2] * e1[0] - s[0] * e1[2], s[0] * e1[1] - s[1] * e1[0]];
    const v = f * (RAY[0] * q[0] + RAY[1] * q[1] + RAY[2] * q[2]);
    if (v < 0 || u + v > 1) continue;
    if (f * (e2[0] * q[0] + e2[1] * q[1] + e2[2] * q[2]) > 1e-9) hits++;
  }
  return (hits & 1) === 1;
}

function insideBlob(b, p) {
  const dx = p[0] - b.c[0], dy = p[1] - b.c[1], dz = p[2] - b.c[2];
  if (dx * dx + dy * dy + dz * dz > b.far * b.far) return false;
  return pointInMesh(b.tris, p);
}

function triBuried(o, p) {
  const c = [0, 1, 2].map(j => (p[0][j] + p[1][j] + p[2][j]) / 3);
  return insideBlob(o, p[0]) && insideBlob(o, p[1]) && insideBlob(o, p[2])
    && insideBlob(o, mid(p[0], p[1])) && insideBlob(o, mid(p[1], p[2]))
    && insideBlob(o, mid(p[2], p[0])) && insideBlob(o, c);
}

function solidBuried(tris, p) {
  const c = [0, 1, 2].map(j => (p[0][j] + p[1][j] + p[2][j]) / 3);
  return [p[0], p[1], p[2], mid(p[0], p[1]), mid(p[1], p[2]), mid(p[2], p[0]), c]
    .every(v => pointInMesh(tris, v));
}

const COLS = 6;
const RING_PITCH = 0.55;
const FOOT_TOP = 1.15;
const R_BASE = 0.26;
const R_TOP = 0.105;
const FLARE = 1.32;
const LEAN = 0.15;

const rnd = prng(19970422);
const COL_GNARL = Array.from({ length: COLS }, () => 0.945 + rnd() * 0.115);
const COL_SKEW = Array.from({ length: COLS }, () => (rnd() - 0.5) * 0.13);
const COL_TOE = [0.22, 0.05, 0.17, 0.04, 0.20, 0.08];

function trunkRings(rise) {
  const ys = [0, FOOT_TOP * 0.48, FOOT_TOP];
  for (let y = FOOT_TOP + RING_PITCH; y < rise - 0.12; y += RING_PITCH) ys.push(y);
  ys.push(rise);
  return ys.map((y) => {
    const t = y / rise;
    const r = R_TOP + (R_BASE - R_TOP) * (1 - t) ** 1.15;
    return {
      y,
      r: r * (y <= 1e-6 ? FLARE : y < FOOT_TOP ? 1 + (FLARE - 1) * (1 - y / FOOT_TOP) ** 1.6 : 1),

      x: LEAN * Math.max(0, (t - 0.33) / 0.67) ** 1.5,
      z: -0.40 * LEAN * Math.max(0, (t - 0.45) / 0.55) ** 1.5,
      flare: y < FOOT_TOP ? (1 - y / FOOT_TOP) ** 2.2 : 0,
    };
  });
}

function trunkVert(R, ci) {
  const a = (ci / COLS) * Math.PI * 2 + COL_SKEW[ci];
  const r = R.r * COL_GNARL[ci] * (1 + COL_TOE[ci] * R.flare);
  return [R.x + Math.cos(a) * r, R.y, R.z + Math.sin(a) * r];
}

function buildTrunk(rings) {
  const bark = [], foot = [];
  for (let ri = 0; ri < rings.length - 1; ri++) {
    for (let ci = 0; ci < COLS; ci++) {
      const cj = (ci + 1) % COLS;
      const a = trunkVert(rings[ri], ci), b = trunkVert(rings[ri], cj);
      const c = trunkVert(rings[ri + 1], cj), d = trunkVert(rings[ri + 1], ci);

      quad(rings[ri].y < FOOT_TOP - 1e-6 ? foot : bark, a, d, c, b);
    }
  }

  const R0 = rings[0], capC = [R0.x, 0, R0.z];
  for (let ci = 0; ci < COLS; ci++) {
    tri(foot, capC, trunkVert(R0, ci), trunkVert(R0, (ci + 1) % COLS));
  }
  return { bark, foot };
}

function trunkSolid(rings, shell) {
  const out = shell.slice();
  const RN = rings[rings.length - 1], capC = [RN.x, RN.y, RN.z];
  for (let ci = 0; ci < COLS; ci++) {
    tri(out, capC, trunkVert(RN, (ci + 1) % COLS), trunkVert(RN, ci));
  }
  return out;
}

function limbGeo(path, radii, sides = 5, capStart = false, capEnd = true, buried = [], host = null) {
  const P = path.map(p => new THREE.Vector3(...p));
  const rings = [];
  for (let i = 0; i < P.length; i++) {
    const prev = P[Math.max(0, i - 1)], next = P[Math.min(P.length - 1, i + 1)];
    const t = new THREE.Vector3().subVectors(next, prev).normalize();
    const up = Math.abs(t.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
    const u = new THREE.Vector3().crossVectors(up, t).normalize();
    const v = new THREE.Vector3().crossVectors(t, u).normalize();
    const ring = [];
    for (let s = 0; s < sides; s++) {
      const a = (s / sides) * Math.PI * 2;
      const cs = Math.cos(a) * radii[i], sn = Math.sin(a) * radii[i];
      ring.push([P[i].x + u.x * cs + v.x * sn, P[i].y + u.y * cs + v.y * sn, P[i].z + u.z * cs + v.z * sn]);
    }
    rings.push(ring);
  }
  const pos = [];
  for (let i = 0; i < rings.length - 1; i++) {
    for (let s = 0; s < sides; s++) {
      const t = (s + 1) % sides;
      quad(pos, rings[i][s], rings[i][t], rings[i + 1][t], rings[i + 1][s]);
    }
  }
  if (capStart) {
    const b0 = [P[0].x, P[0].y, P[0].z];
    for (let s = 0; s < sides; s++) tri(pos, b0, rings[0][(s + 1) % sides], rings[0][s]);
  }
  if (capEnd) {
    const n = rings.length - 1, bN = [P[n].x, P[n].y, P[n].z];
    for (let s = 0; s < sides; s++) tri(pos, bN, rings[n][s], rings[n][(s + 1) % sides]);
  }
  if (!buried.length && !host) return posGeo(pos);

  const keep = [];
  for (let t = 0; t < pos.length; t += 9) {
    const p = [0, 1, 2].map(j => [pos[t + j * 3], pos[t + j * 3 + 1], pos[t + j * 3 + 2]]);
    if (buried.some(o => triBuried(o, p))) continue;
    if (host && solidBuried(host, p)) continue;
    for (const v of p) keep.push(v[0], v[1], v[2]);
  }
  return posGeo(keep);
}

const STEP = 0.02, REACH = 1.30, MIN_RUN = 0.12, DEPTH = 0.30;
const MAX_GAP = 0.60, MAX_TURN = 0.60;

function crownHit(from, dir, blobs, min) {
  const at = (s) => [from[0] + dir[0] * s, from[1] + dir[1] * s, from[2] + dir[2] * s];
  const inside = (p) => blobs.some(o => insideBlob(o, p));
  let entry = -1;
  for (let s = min; s <= min + REACH; s += STEP) {
    if (inside(at(s))) { if (entry < 0) entry = s; }
    else if (entry >= 0) {
      if (s - STEP - entry >= MIN_RUN) break;
      entry = -1;
    }
  }
  if (entry < 0 || entry - min > MAX_GAP) return null;
  let last = entry;
  for (let s = entry; s <= entry + DEPTH; s += STEP) { if (!inside(at(s))) break; last = s; }
  return at(last);
}

function reachIntoCrown(path, blobs) {
  const n = path.length - 1;
  const base = path[n - 1];
  const dir = unit(base, path[n]);
  const len = Math.hypot(path[n][0] - base[0], path[n][1] - base[1], path[n][2] - base[2]);
  const aims = [dir].concat(blobs
    .map(o => unit(base, o.c))
    .map(d => ({ d, dot: dot3(d, dir) }))
    .filter(x => x.dot > MAX_TURN)
    .sort((a, b) => b.dot - a.dot)
    .map(x => x.d));
  for (const aim of aims) {
    const hit = crownHit(base, aim, blobs, len);
    if (!hit) continue;
    const p = path.slice(); p[n] = hit;
    return { path: p, buried: true };
  }
  return { path, buried: false };
}

const CROWN = {
  up: 1.15,
  off: [0.05, -0.06],

  r: 1.85, ry: 1.80, rz: 1.58,
  seg: [11, 8],

  patch: [
    { d: [0.62, 0.55, 0.56], cos: 0.86 },
    { d: [-0.58, -0.52, 0.63], cos: 0.85 },
  ],
};

const SHOULDERS = [
  { az: 300, rad: 1.28, dy: -0.72, r: 0.80, seg: [7, 5], seed: 11 },
  { az: 62, rad: 1.20, dy: -1.02, r: 0.69, seg: [6, 4], seed: 23 },
];

const LIMBS = [
  { az: 180, yf: 0.63, reach: 1.42, up: 0.95, blob: 0.88, bend: 0.09, seed: 3 },
  { az: 345, yf: 0.67, reach: 1.30, up: 0.88, blob: 0.76, bend: -0.11, seed: 17 },
  { az: 258, yf: 0.60, reach: 1.18, up: 0.80, blob: 0.70, bend: 0.12, seed: 31 },
  { az: 100, yf: 0.70, reach: 1.05, up: 0.82, blob: 0.63, bend: -0.10, seed: 47 },
];

function blobRadius(b, x, y, z) {
  const el = Math.asin(Math.max(-1, Math.min(1, y)));
  const az = Math.atan2(z, x);
  const lat = Math.cos(el);
  return 1 + 0.15 * Math.sin(3 * az + b.p1) * lat
    + 0.10 * Math.sin(2 * az + b.p2) * lat
    + 0.12 * Math.sin(2.2 * el + b.p3);
}

function blobTris(b) {
  const g = roundPoles(new THREE.SphereGeometry(1, b.seg[0], b.seg[1]));
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    const w = blobRadius(b, x, y, z);
    pos.setXYZ(i, x * w, y * w, z * w);
  }
  g.scale(b.s[0], b.s[1], b.s[2]);
  g.translate(b.c[0], b.c[1], b.c[2]);
  return Array.from(g.toNonIndexed().attributes.position.array);
}

function blobBuild(blobs) {
  for (const b of blobs) {
    b.tris = blobTris(b);
    b.far = 1.38 * Math.max(b.s[0], b.s[1], b.s[2]);
  }
  return blobs;
}

function buildBlob(b, others) {
  const bins = { leaf: [], leafLight: [] };
  for (let t = 0; t < b.tris.length; t += 9) {
    const p = [0, 1, 2].map(j => b.tris.slice(t + j * 3, t + j * 3 + 3));
    if (others.some(o => o !== b && triBuried(o, p))) continue;
    let tone = b.tone;
    if (b.patch) {
      const n = unit(b.c, [0, 1, 2].map(j => (p[0][j] + p[1][j] + p[2][j]) / 3));
      for (const q of b.patch) {
        const d = q.d, l = Math.hypot(d[0], d[1], d[2]);
        if (dot3(n, [d[0] / l, d[1] / l, d[2] / l]) > q.cos) { tone = 'leafLight'; break; }
      }
    }
    for (const v of p) bins[tone].push(v[0], v[1], v[2]);
  }
  return bins;
}

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const col = { ...cw };

  for (const k of ZONES) if (p[k] !== undefined) col[k] = p[k];
  const num = (k) => {
    const s = params[k], v = p[k];
    if (v === undefined || Number.isNaN(Number(v))) return s.default;
    return Math.max(s.min, Math.min(s.max, Number(v)));
  };
  return {
    col,
    tall: num('tallness'),
    limbs: Math.round(num('limbs')),
    canopy: num('canopy'),
  };
}

const RISE = 4.20;

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const C = P.col;
  const rise = RISE * P.tall;
  const K = P.canopy;
  const parts = [];

  const blobs = [{
    tone: 'leaf', patch: CROWN.patch, seg: CROWN.seg,
    c: [CROWN.off[0], rise + CROWN.up, CROWN.off[1]],
    s: [CROWN.r * K, CROWN.ry * K, CROWN.rz * K],
    p1: 2.3, p2: 0.7, p3: 1.6,
  }];
  const crownC = blobs[0].c;
  for (const S of SHOULDERS) {
    const a = S.az * Math.PI / 180;
    const j = prng(S.seed)();
    blobs.push({
      tone: 'leafLight', seg: S.seg,
      c: [crownC[0] + Math.cos(a) * S.rad, crownC[1] + S.dy, crownC[2] + Math.sin(a) * S.rad],
      s: [S.r * K * (1.04 + j * 0.10), S.r * K * (0.90 + j * 0.10), S.r * K * (0.98 + j * 0.09)],
      p1: S.seed * 0.61, p2: S.seed * 1.17, p3: S.seed * 0.37,
    });
  }
  const used = LIMBS.slice(0, P.limbs - 1);
  for (const B of used) {
    const a = B.az * Math.PI / 180;
    const j = prng(B.seed)();
    blobs.push({
      tone: 'leafLight', seg: [7, 5],
      c: [Math.cos(a) * B.reach, rise * B.yf + B.up, Math.sin(a) * B.reach],
      s: [B.blob * K * (1.03 + j * 0.10), B.blob * K * (0.88 + j * 0.11), B.blob * K * (0.97 + j * 0.09)],
      p1: B.seed * 0.73, p2: B.seed * 1.31, p3: B.seed * 0.41,
    });
  }
  blobBuild(blobs);

  const rings = trunkRings(rise);
  const T = buildTrunk(rings);
  const trunkHost = trunkSolid(rings, T.bark.concat(T.foot));

  const unburied = (src) => {
    const keep = [];
    for (let t = 0; t < src.length; t += 9) {
      const p = [0, 1, 2].map(j => src.slice(t + j * 3, t + j * 3 + 3));
      if (blobs.some(o => triBuried(o, p))) continue;
      for (const v of p) keep.push(v[0], v[1], v[2]);
    }
    return keep;
  };
  parts.push({ g: posGeo(unburied(T.bark)), c: C.bark });
  parts.push({ g: posGeo(T.foot), c: C.foot });

  used.forEach((B) => {
    const a = B.az * Math.PI / 180;
    const dx = Math.cos(a), dz = Math.sin(a);
    const y0 = rise * B.yf;
    const path = [0, 0.55, 1].map((s) => {
      const bow = B.bend * Math.sin(s * Math.PI);
      return [
        dx * B.reach * s - dz * bow,
        y0 + B.up * s - 0.07 * Math.sin(s * Math.PI),
        dz * B.reach * s + dx * bow,
      ];
    });
    const R = reachIntoCrown(path, blobs);
    parts.push({
      g: limbGeo(R.path, [0.100, 0.072, 0.046], 5, false, !R.buried, blobs, trunkHost),
      c: C.bark,
    });
  });

  for (const b of blobs) {
    const bins = buildBlob(b, blobs);
    parts.push({ g: posGeo(bins.leaf), c: C.leaf });
    parts.push({ g: posGeo(bins.leafLight), c: C.leafLight });
  }

  const mesh = finish(parts);
  mesh.name = 'broadleaf-oak-mesh';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );

  const g = new THREE.Group();
  g.name = 'broadleaf-oak';
  g.add(mesh);
  return g;
}

export default createAsset;

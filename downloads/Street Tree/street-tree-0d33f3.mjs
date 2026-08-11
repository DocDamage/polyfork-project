/*
 * Street Tree
 * https://polyfork.dev/asset/street-tree-0d33f3
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './street-tree-0d33f3.mjs';
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
 *   colorway  choice  'street-green' 'street-green' | 'deep-summer' | 'autumn-gold'
 *   canopy    color   '#5f7c42'      any hex or THREE.Color
 *   bark      color   '#7d5642'      any hex or THREE.Color
 *   frame     color   '#c1b0a1'      any hex or THREE.Color
 *   bed       color   '#52613b'      any hex or THREE.Color
 *   tallness  range   1              0.85 to 1.08
 *   spread    range   1              0.82 to 1.2
 *   crown     choice  'egg'          'egg' | 'round' | 'broad'
 *
 * Every option is described in full at https://polyfork.dev/cdn/street-tree-0d33f3-params.json
 *
 * SPECS  272 triangles, 1 material, 3.05 x 6 x 3.05 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries, mergeVertices } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'street-green', label: 'Colorway',
    options: ['street-green', 'deep-summer', 'autumn-gold'],
    describe: 'curated kit-coherent scheme: street-green is the approved high-summer ' +
      'tree, deep-summer is a darker cooler crown on near-black bark and grey kerb, ' +
      'autumn-gold turns the crown to the kit\'s warm ochre over a bare earth bed',
  },
  canopy: {
    type: 'color', default: '#5f7c42', label: 'Canopy',
    describe: 'albedo of the entire crown — one flat green over every facet; the ' +
      'dominant colour of the asset by far',
  },
  bark: {
    type: 'color', default: '#7d5642', label: 'Bark',
    describe: 'albedo of the trunk, its root flare and both fork limbs — a mid warm ' +
      'brown sitting between the kit\'s two brownstone tones, matching the bark ' +
      'sampled off the references',
  },
  frame: {
    type: 'color', default: '#c1b0a1', label: 'Kerb stone',
    describe: 'albedo of the square pit kerb ring, every face — pale warm stone, the ' +
      'lightest zone and the thing that grounds the tree at thumbnail size',
  },
  bed: {
    type: 'color', default: '#52613b', label: 'Planting bed',
    describe: 'albedo of the recessed bed inside the kerb; darker and duller than the ' +
      'crown so the two greens never merge',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.85, max: 1.08, affects: 'geometry',
    label: 'Tallness',
    describe: 'stretches the clear stem only, so the crown rides up or down while ' +
      'keeping its own size: 0.85 is a 5.55 m young tree whose canopy sits close over ' +
      'the kerb, 1.08 a leggy 6.24 m specimen with a long bare stem. The kerb and the ' +
      'root flare never change',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.82, max: 1.2, affects: 'geometry',
    label: 'Canopy spread',
    describe: 'scales the crown across X and Z only, never its height: 0.82 is a tight ' +
      '2.50 m ball on a visibly bare stem, 1.2 a 3.66 m crown that nearly fills the ' +
      '4 m kit cell (3.93 m at the widest, combined with the broad crown shape)',
  },
  crown: {
    type: 'choice', default: 'egg', affects: 'geometry', label: 'Crown shape',
    options: ['egg', 'round', 'broad'],
    describe: 'the crown\'s profile at a fixed underside height: egg is the approved ' +
      'upright ellipsoid, 3.05 m wide by 3.15 m tall; round is a near-even ball, ' +
      '3.15 x 2.90 m; broad is a squat spreading dome, 3.28 x 2.52 m, which reads as ' +
      'an older street tree and drops the overall height to 5.37 m',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {
  'street-green': {},
  'deep-summer': { canopy: '#47632f', bark: '#463b37', frame: '#9f9890', bed: '#3f5030' },
  'autumn-gold': { canopy: '#c98f45', bark: '#7d5240', frame: '#cfc6b9', bed: '#564e4a' },
};
export const presets = COLORWAYS;

function resolveColors(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  return { canopy: hex(p.canopy), bark: hex(p.bark), frame: hex(p.frame), bed: hex(p.bed) };
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
function resolveShape(user = {}) {
  const num = (k) => {
    const s = params[k];
    return clamp(user[k] === undefined ? s.default : Number(user[k]), s.min, s.max);
  };
  const crown = params.crown.options.includes(user.crown) ? user.crown : params.crown.default;
  return { tallness: num('tallness'), spread: num('spread'), crown };
}

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
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
  if (!merged) throw new Error('mergeGeometries returned null — attribute sets differ');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const FORK_Y = 2.42;
const LEADER_Y = 3.10;
const CROWN_BOT = 2.85;

const CROWN_W = 3.05;
const CROWN_H = 3.15;

const FR_O = 0.70;
const FR_I = 0.46;
const FR_H = 0.16;
const FR_CH = 0.04;
const FR_CI = 0.03;
const BED_Y = 0.09;

const CROWN_SHAPE = { egg: [1.00, 1.00], round: [1.033, 0.92], broad: [1.075, 0.80] };

const COLS = 10;

const TRUNK_RINGS = [
  { y: 0.06, r: 0.190 },
  { y: 0.15, r: 0.178 },
  { y: 0.72, r: 0.162 },
  { y: 1.60, r: 0.148 },
  { y: FORK_Y, r: 0.132 },
  { y: LEADER_Y, r: 0.092 },
];

const rnd = prng(20260728);
const COL_WOBBLE = Array.from({ length: COLS }, () => 0.94 + rnd() * 0.12);

const COL_FLARE = [0.18, 0.05, 0.12, 0.04, 0.17, 0.06, 0.14, 0.04, 0.16, 0.05];
const FLARE_H = 0.35;

function trunkVert(ri, ci) {
  const R = TRUNK_RINGS[ri];
  const y = R.y;
  const a = (ci / COLS) * Math.PI * 2;
  const flare = 1 + COL_FLARE[ci] * Math.max(0, 1 - R.y / FLARE_H) ** 1.5;
  const r = R.r * COL_WOBBLE[ci] * flare;
  return [Math.cos(a) * r, y, Math.sin(a) * r];
}

function stemY(y, t) {
  const base = 0.72;
  return y <= base ? y : base + (y - base) * (1 + (t - 1) * (FORK_Y / (FORK_Y - base)));
}

function buildTrunk(parts, C, t) {
  const pos = [];
  const V = (ri, ci) => {
    const p = trunkVert(ri, ci);
    return [p[0], stemY(p[1], t), p[2]];
  };

  for (let ri = 0; ri < TRUNK_RINGS.length - 1; ri++) {
    for (let ci = 0; ci < COLS; ci++) {
      const cj = (ci + 1) % COLS;
      quad(pos, V(ri, ci), V(ri + 1, ci), V(ri + 1, cj), V(ri, cj));
    }
  }

  parts.push({ g: posGeo(pos), c: C.bark });
}

function limb(path, radii, sides = 5) {
  const P = path.map(p => new THREE.Vector3(...p));
  const rings = [];
  for (let i = 0; i < P.length; i++) {
    const prev = P[Math.max(0, i - 1)], next = P[Math.min(P.length - 1, i + 1)];
    const tg = new THREE.Vector3().subVectors(next, prev).normalize();
    const up = Math.abs(tg.y) > 0.9 ? new THREE.Vector3(1, 0, 0) : new THREE.Vector3(0, 1, 0);
    const u = new THREE.Vector3().crossVectors(up, tg).normalize();
    const v = new THREE.Vector3().crossVectors(tg, u).normalize();
    const ring = [];
    for (let s = 0; s < sides; s++) {
      const a = (s / sides) * Math.PI * 2;
      const cs = Math.cos(a) * radii[i], sn = Math.sin(a) * radii[i];
      ring.push([P[i].x + u.x * cs + v.x * sn, P[i].y + u.y * cs + v.y * sn,
                 P[i].z + u.z * cs + v.z * sn]);
    }
    rings.push(ring);
  }
  const pos = [];
  for (let i = 0; i < rings.length - 1; i++) {
    for (let s = 0; s < sides; s++) {
      const t2 = (s + 1) % sides;
      quad(pos, rings[i][s], rings[i][t2], rings[i + 1][t2], rings[i + 1][s]);
    }
  }
  return posGeo(pos);
}

const LIMBS = [
  { path: [[-0.02, FORK_Y - 0.22, 0.02], [0.30, FORK_Y + 0.34, 0.18], [0.52, FORK_Y + 0.70, 0.30]],
    r: [0.115, 0.088, 0.058] },
  { path: [[0.02, FORK_Y - 0.16, -0.02], [-0.27, FORK_Y + 0.30, -0.14], [-0.46, FORK_Y + 0.66, -0.24]],
    r: [0.100, 0.078, 0.052] },
];

function posHash(x, y, z, seed) {
  const s = Math.sin(x * 127.1 + y * 311.7 + z * 74.7 + seed) * 43758.5453;
  return s - Math.floor(s);
}

function crownGeo(shape) {
  const [sx, sy] = CROWN_SHAPE[shape.crown];
  let g = mergeVertices(new THREE.IcosahedronGeometry(1, 1), 1e-4);
  const pos = g.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const x = pos.getX(i), y = pos.getY(i), z = pos.getZ(i);
    let k = 1 + (posHash(x, y, z, 17) - 0.5) * 0.26;

    k *= 1 + 0.12 * Math.max(0, z) ** 2;
    k *= 1 - 0.10 * Math.max(0, -x) ** 2 * Math.max(0, 1 - Math.abs(y));
    pos.setXYZ(i, x * k, y * k, z * k);
  }

  const W = CROWN_W * shape.spread * sx, Hc = CROWN_H * sy;
  g.computeBoundingBox();
  const b = g.boundingBox;
  g.translate(-(b.min.x + b.max.x) / 2, -(b.min.y + b.max.y) / 2, -(b.min.z + b.max.z) / 2);
  g.scale(W / (b.max.x - b.min.x), Hc / (b.max.y - b.min.y), W / (b.max.z - b.min.z));
  g.translate(0, stemY(CROWN_BOT, shape.tallness) + Hc / 2, 0);
  return g;
}

function squareRing(h, y) {
  return [[-h, y, -h], [h, y, -h], [h, y, h], [-h, y, h]];
}

function buildPit(parts, C) {
  const pos = [];
  const r0 = squareRing(FR_O, 0);
  const r1 = squareRing(FR_O, FR_H - FR_CH);
  const r2 = squareRing(FR_O - FR_CH, FR_H);
  const r3 = squareRing(FR_I + FR_CI, FR_H);
  const r4 = squareRing(FR_I, FR_H - FR_CI);
  const r5 = squareRing(FR_I, 0);
  for (let i = 0; i < 4; i++) {
    const j = (i + 1) % 4;
    quad(pos, r0[i], r1[i], r1[j], r0[j]);
    quad(pos, r1[i], r2[i], r2[j], r1[j]);
    quad(pos, r2[i], r3[i], r3[j], r2[j]);
    quad(pos, r3[i], r4[i], r4[j], r3[j]);
    quad(pos, r4[i], r5[i], r5[j], r4[j]);
    quad(pos, r5[i], r0[i], r0[j], r5[j]);
  }
  parts.push({ g: posGeo(pos), c: C.frame });

  const b = [];
  const top = squareRing(FR_I, BED_Y), bot = squareRing(FR_I, 0);
  quad(b, top[0], top[3], top[2], top[1]);
  quad(b, bot[0], bot[1], bot[2], bot[3]);
  parts.push({ g: posGeo(b), c: C.bed });
}

export function createAsset(userParams = {}) {
  const C = resolveColors(userParams);
  const S = resolveShape(userParams);

  const g = new THREE.Group();
  g.name = 'street-tree';

  const parts = [];
  buildPit(parts, C);
  buildTrunk(parts, C, S.tallness);
  for (const L of LIMBS) {
    parts.push({
      g: limb(L.path.map(p => [p[0], stemY(p[1], S.tallness), p[2]]), L.r),
      c: C.bark,
    });
  }
  parts.push({ g: crownGeo(S), c: C.canopy });

  const mesh = finish(parts);
  mesh.name = 'street-tree-mesh';

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

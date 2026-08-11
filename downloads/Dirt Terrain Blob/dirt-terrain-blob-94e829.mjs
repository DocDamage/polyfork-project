/*
 * Dirt Terrain Blob
 * https://polyfork.dev/asset/dirt-terrain-blob-94e829
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './dirt-terrain-blob-94e829.mjs';
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
 *   colorway  choice  'packed-dirt'  'packed-dirt' | 'dry-earth' | 'forest-loam' | 'pale-clay'
 *   dirt      color   '#75563b'      any hex or THREE.Color
 *   spread    range   1              0.72 to 1.24
 *   sides     range   14             9 to 14
 *   facets    range   6              3 to 8
 *   relief    range   1              0 to 1.4
 *   swells    range   3              0 to 4
 *
 * Every option is described in full at https://polyfork.dev/cdn/dirt-terrain-blob-94e829-params.json
 *
 * SPECS  364 triangles, 1 material, 7 x 0.23 x 5.83 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'packed-dirt', label: 'Colorway',
    options: ['packed-dirt', 'dry-earth', 'forest-loam', 'pale-clay'],
    describe: 'curated earth scheme; every hex is from the kit menu and each one repaints ' +
      'the WHOLE blob, because the asset is one material. packed-dirt is the mid-brown ' +
      'trodden forest floor of the kit concept and is the default; dry-earth is a warmer, ' +
      'lighter sun-baked trail dirt for clearings; forest-loam is the darkest damp soil for ' +
      'shaded ground under a closed canopy; pale-clay is a dusty pale exposed subsoil for ' +
      'banks and worn paths',
  },
  dirt: {
    type: 'color', default: '#75563b', label: 'Dirt',
    describe: 'the single albedo of the entire asset — the walkable plane, every facet of ' +
      'the earth swells, both rim bands and the underside. There is deliberately no second ' +
      'zone: bare earth is one material, so all of its facet-to-facet tone must come from ' +
      'flat shading under the scene lights, never from paint',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.72, max: 1.24, label: 'Spread', affects: 'geometry',
    describe: 'overall diameter of the patch. 0.72 is a 5.0 m bare scrape that carries a ' +
      'campfire or one tent; 1.0 is the 7.0 x 5.8 m default; 1.24 is an 8.7 m clearing ' +
      'floor wide enough for a whole camp. This REBUILDS rather than scales: the facet SIZE ' +
      'is held constant, so a wider patch is built from more lattice rings and the triangle ' +
      'count moves with the knob, and the undulation keeps its real 3-4 m wavelength so a ' +
      'big patch shows more swells rather than bigger ones. Rim section and relief height ' +
      'never change, so the ground stays flush with the rest of the kit at every value',
  },
  sides: {
    type: 'range', default: 14, min: 9, max: 14, label: 'Outline sides', affects: 'geometry',
    describe: 'number of straight sides in the outline (integer 9-14). 14 is the default ' +
      'and the roundest the class allows, reading as a smooth worn patch of ground; 9 gives ' +
      'a coarse chunky outline with long flat edges and obvious corners. The outline stays ' +
      'convex, oval and irregular at every value',
  },
  facets: {
    type: 'range', default: 6, min: 3, max: 8, label: 'Facet density', affects: 'geometry',
    describe: 'how finely the top surface is broken into planes (integer 3-8 lattice rings ' +
      'from rim to centre). 3 is coarse and chunky — a handful of big 1.5 m plates, the ' +
      'blockiest read; 6 is the default, roughly 0.6 m facets, the crease network the refs ' +
      'show; 8 is a finer crumpled surface. This is the knob that trades triangles for ' +
      'surface detail: the count runs from about 250 to about 530',
  },
  relief: {
    type: 'range', default: 1.0, min: 0.0, max: 1.40, label: 'Surface relief', affects: 'geometry',
    describe: 'height of the ground undulation. 0 is a dead-flat pad for building on — one ' +
      'perfectly level plane, no creases at all; 1.0 is the default rumpled earth, facets ' +
      'tilted 9-12 degrees against each other with crests about +0.18 m above the plane and ' +
      'hollows about 0.03 m into it; 1.40 is rough churned ground whose crests reach ' +
      '+0.26 m. The rim edge stays at exactly 0.05 m all the way round at every value, so ' +
      'the skirt and the footprint never change',
  },
  swells: {
    type: 'range', default: 3, min: 0, max: 4, label: 'Earth swells', affects: 'geometry',
    describe: 'how many pronounced mounds of heaped earth rise out of the undulation ' +
      '(integer 0-4). 0 leaves only the fine rumple, an evenly worn floor; 3 is the default ' +
      '— swells 2.2-3.1 m across standing 0.09-0.145 m proud of the surrounding ground, ' +
      'the tallest on the +Z front, which is what breaks the top line in the front and side ' +
      'elevations; 4 adds a fourth off the ' +
      'back quarter for heavily worked ground. Swells keep their real size at every spread, ' +
      'so a small scrape carries proportionally fewer of them',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'packed-dirt': { dirt: '#75563b' },
  'dry-earth':   { dirt: '#8c6a47' },
  'forest-loam': { dirt: '#5d4430' },
  'pale-clay':   { dirt: '#a5855e' },
};
export const presets = COLORWAYS;

function resolve(userParams = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[userParams.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (userParams[k] !== undefined) p[k] = userParams[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const num = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: { dirt: hex(p.dirt) },
    spread: num(p.spread, 0.72, 1.24),
    sides:  Math.round(num(p.sides, 9, 14)),
    facets: Math.round(num(p.facets, 3, 8)),
    relief: num(p.relief, 0, 1.40),
    swells: Math.round(num(p.swells, 0, 4)),
  };
}

const TOP   = 0.05;
const CAP_Y = 0.420;

const FLOOR_Y = 0.018;
const BASE_D = 7.0;
const OVAL = 0.80;

const WALL_Y = 0.032;
const CHAM_R = 0.018;

const AMP = 0.045;
const DIP = 0.28;

const CRUMPLE = 0.18;
const CRUMPLE_DOWN = 0.55;

const CELL = 0.62;
const chequer = (x, z) => ((Math.floor(x / CELL) + Math.floor(z / CELL)) % 2 === 0 ? 1 : -1);
function undulate(x, z) {
  return 0.58 * Math.sin(1.85 * x + 0.70) * Math.cos(1.55 * z - 0.40)
       + 0.42 * Math.sin(2.35 * z + 2.10) * Math.cos(1.95 * x + 1.30);
}

const SEATS = [

  { fx: -0.18, fz: +0.46, r: 1.55, h: 0.145 },
  { fx: +0.38, fz: -0.36, r: 1.40, h: 0.112 },
  { fx: +0.56, fz: +0.40, r: 1.10, h: 0.092 },
  { fx: -0.26, fz: -0.54, r: 1.25, h: 0.082 },
];
const bumpFall = (t) => (t >= 1 ? 0 : (1 - t * t) * (1 - t * t));

const TAU = Math.PI * 2;
const FRONT = Math.PI / 2;

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }
function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
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

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const N = P.sides;
  const step = TAU / N;
  const rand = prng(60127);

  const ang = [], rad = [];

  for (let i = 0; i < N; i++) ang.push(i * step + (rand() - 0.5) * step * 0.30);

  {
    let best = 0;
    for (let i = 1; i < N; i++) {
      if (Math.abs(ang[i] - FRONT) < Math.abs(ang[best] - FRONT)) best = i;
    }
    ang[best] = FRONT;
  }
  for (let i = 0; i < N; i++) {
    const a = ang[i];

    const lobe = 1
      + 0.052 * Math.sin(3 * a + 2.4) + 0.026 * Math.sin(5 * a + 0.9)
      + (rand() - 0.5) * 0.050;

    const front = 1 + 0.075 * Math.pow(Math.max(0, Math.cos(a - FRONT)), 2);
    rad.push(lobe * front);
  }

  const raw = (a, r) => [Math.cos(a) * r, Math.sin(a) * r * OVAL];
  let minX = Infinity, maxX = -Infinity, minZ = Infinity, maxZ = -Infinity;
  for (let i = 0; i < N; i++) {
    const [x, z] = raw(ang[i], rad[i]);
    minX = Math.min(minX, x); maxX = Math.max(maxX, x);
    minZ = Math.min(minZ, z); maxZ = Math.max(maxZ, z);
  }
  const S = (BASE_D * P.spread) / (maxX - minX);
  const cx = (minX + maxX) / 2, cz = (minZ + maxZ) / 2;
  const xz = (a, r) => { const [x, z] = raw(a, r); return [(x - cx) * S, (z - cz) * S]; };

  const foot = [], wall = [], rimR = [];
  for (let i = 0; i < N; i++) {
    const [x, z] = xz(ang[i], rad[i]);
    const len = Math.hypot(x, z) || 1;
    foot.push([x, 0, z]);
    wall.push([x, WALL_Y, z]);
    rimR.push(Math.max(0, 1 - CHAM_R / len));
  }

  const hx = (BASE_D * P.spread) / 2, hz = (maxZ - minZ) * S / 2;

  const buckets = new Map();
  const emit = (hex, a, b, c) => {
    if (!buckets.has(hex)) buckets.set(hex, []);
    tri(buckets.get(hex), a, b, c);
  };
  const DIRT = P.C.dirt;

  const seats = SEATS.slice(0, P.swells).map((s) => ({ x: s.fx * hx, z: s.fz * hz, r: s.r, h: s.h }));
  const amp = AMP * P.relief;
  const groundY = (x, z, jitter, facetW) => {
    let h = undulate(x, z);
    h = (h > 0 ? h : h * DIP) * amp;
    for (const s of seats) h += s.h * P.relief * bumpFall(Math.hypot(x - s.x, z - s.z) / s.r);
    h += (jitter > 0 ? jitter : jitter * CRUMPLE_DOWN) * CRUMPLE * facetW * P.relief;
    return Math.min(CAP_Y, Math.max(FLOOR_Y, TOP + h));
  };

  const R = Math.max(2, Math.round(P.facets * P.spread));
  const M = N * 2;
  const jrand = prng(31337);

  const ringPhase = Array.from({ length: R }, () => (jrand() - 0.5) * (TAU / M) * 0.8);
  const ringJit = Array.from({ length: R }, () =>
    Array.from({ length: M }, () => 1 + (jrand() - 0.5) * 0.13));

  const vJit = Array.from({ length: R }, () =>
    Array.from({ length: M }, () => 0.62 + 0.38 * jrand()));

  const ringF = Array.from({ length: R }, (_, k) => (k / R) * (0.90 + 0.20 * jrand()));

  const outlineAt = (c) => {
    const t = (c / 2) % N;
    const i = Math.floor(t), j = (i + 1) % N, f = t - i;

    const da = ((ang[j] - ang[i] + TAU) % TAU);
    return [ang[i] + da * f, rad[i] + (rad[j] - rad[i]) * f];
  };

  const rings = [];
  for (let k = 1; k < R; k++) {
    const f = ringF[k];
    rings.push(Array.from({ length: M }, (_, c) => {
      const [a, r] = outlineAt(c);
      const [x, z] = xz(a + ringPhase[k], r * f * ringJit[k][c]);

      const ease = 1 - 0.35 * Math.min(1, Math.max(0, (f - 0.76) / 0.18));
      const y = groundY(x, z, chequer(x, z) * vJit[k][c], TAU * Math.hypot(x, z) / M);
      return [x, TOP + (y - TOP) * ease, z];
    }));
  }
  const centre = [0, groundY(0, 0, 0, 0), 0];
  const rim = Array.from({ length: N }, (_, i) =>
    [foot[i][0] * rimR[i], TOP, foot[i][2] * rimR[i]]);

  {
    const out = rings[rings.length - 1];
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;
      const c0 = 2 * i, c1 = (2 * i + 1) % M, c2 = (2 * i + 2) % M;
      emit(DIRT, rim[i], out[c0], out[c1]);
      emit(DIRT, rim[i], out[c1], rim[j]);
      emit(DIRT, rim[j], out[c1], out[c2]);
    }
  }

  for (let k = rings.length - 1; k > 0; k--) {
    const outer = rings[k], inner = rings[k - 1];
    for (let c = 0; c < M; c++) {
      const d = (c + 1) % M;
      emit(DIRT, inner[c], inner[d], outer[d]);
      emit(DIRT, inner[c], outer[d], outer[c]);
    }
  }

  {
    const inner = rings[0];
    for (let c = 0; c < M; c++) emit(DIRT, centre, inner[(c + 1) % M], inner[c]);
  }

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    emit(DIRT, wall[i], wall[j], foot[j]);
    emit(DIRT, wall[i], foot[j], foot[i]);
    emit(DIRT, rim[i], rim[j], wall[j]);
    emit(DIRT, rim[i], wall[j], wall[i]);
  }

  for (let i = 0; i < N; i++) emit(DIRT, [0, 0, 0], foot[i], foot[(i + 1) % N]);

  const list = [];
  for (const [hex, pos] of buckets) list.push(prep(posGeo(pos), hex));
  const geo = mergeGeometries(list);
  if (!geo) throw new Error('dirt-terrain-blob: mergeGeometries returned null');
  geo.computeVertexNormals();

  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.9, metalness: 0,
  }));
  mesh.name = 'dirt-terrain-blob-mesh';

  const g = new THREE.Group();
  g.name = 'dirt-terrain-blob';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

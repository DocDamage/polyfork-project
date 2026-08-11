/*
 * Grass Terrain Blob
 * https://polyfork.dev/asset/grass-terrain-blob-c4f709
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './grass-terrain-blob-c4f709.mjs';
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
 *   colorway  choice  'meadow'       'meadow' | 'deep-forest' | 'spring-fresh' | 'dry-pasture'
 *   grass     color   '#77b258'      any hex or THREE.Color
 *   spread    range   1              0.7 to 1.22
 *   facets    range   7              3 to 8
 *   relief    range   1              0 to 1.7
 *   swells    range   3              0 to 4
 *
 * Every option is described in full at https://polyfork.dev/cdn/grass-terrain-blob-c4f709-params.json
 *
 * SPECS  390 triangles, 1 material, 9 x 0.5 x 8.18 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'meadow', label: 'Colorway',
    options: ['meadow', 'deep-forest', 'spring-fresh', 'dry-pasture'],
    describe: 'curated green scheme; every hex is from the kit menu and each ' +
      'preset repaints the WHOLE blob, because the asset is one material. meadow is the ' +
      'bright mid-green pasture of the kit concept image and is the default; deep-forest ' +
      'is the dark shaded floor of a closed canopy; spring-fresh is bright new growth ' +
      'for clearings and sunlit banks; dry-pasture is olive late-summer grass',
  },
  grass: {
    type: 'color', default: '#77b258', label: 'Grass',
    describe: 'the single albedo of the entire asset — the walkable plane, the crown, ' +
      'every facet of the swells, the bank that skirts down to the ground and the ' +
      'underside. There is deliberately no second zone: this is a grassed-over island, ' +
      'one material, so every facet-to-facet tone difference has to come from flat ' +
      'shading under the scene lights, never from paint',
  },
  spread: {
    type: 'range', default: 1.0, min: 0.70, max: 1.22, label: 'Spread', affects: 'geometry',
    describe: 'overall diameter of the patch. 0.70 is a 6.30 x 5.72 m island big enough ' +
      'for one tree and a bush (286 triangles); 1.0 is the 9.00 x 8.18 m default (390); ' +
      '1.22 is a 10.98 x 9.98 m meadow floor (494). This REBUILDS rather than scales: the ' +
      'facet SIZE is held constant, so a wider patch is built from more lattice rings and ' +
      'the triangle count moves with the knob, and the undulation keeps its real 3-4 m ' +
      'wavelength so a big patch shows more swells rather than bigger ones. Bank section, ' +
      'crown rise and swell height never change, so the ground stays flush with the rest ' +
      'of the kit at every value',
  },
  facets: {
    type: 'range', default: 7, min: 3, max: 8, label: 'Facet density', affects: 'geometry',
    describe: 'how finely the top is broken into planes (integer 3-8 lattice rings from ' +
      'rim to centre). 3 is coarse and chunky, a handful of big 1.8 m plates and the ' +
      'blockiest read (182 triangles); 7 is the default, roughly 0.7 m facets, the calm ' +
      'crease network the refs show (390); 8 is a finer crumpled meadow (442). This is ' +
      'the knob that trades triangles for surface detail. The outline, the crown profile ' +
      'and the swells are identical at every value, so only the surface changes',
  },
  relief: {
    type: 'range', default: 1.0, min: 0.0, max: 1.70, label: 'Surface relief', affects: 'geometry',
    describe: 'height of the whole top profile — crown, shoulder, swells and facet ' +
      'crumple together. 0 is a dead-level pad for building on: one perfectly flat plane ' +
      'at 0.05 m, no crown and no creases, total height 0.05 m. 1.0 is the default gently ' +
      'rolling turf — plateau 0.30 m over the rim plane, facets tilted 8-14 degrees ' +
      'against each other and a total height of 0.499 m on a 9 m span. 1.70 is a hummocky ' +
      'pasture, total height 0.814 m, steep enough to read as a low hill rather than a ' +
      'ground patch. The rim edge stays at exactly 0.05 m all the way round at every ' +
      'value, so the skirt and the footprint never change and props still sit flush there',
  },
  swells: {
    type: 'range', default: 3, min: 0, max: 4, label: 'Ground swells', affects: 'geometry',
    describe: 'how many pronounced low mounds rise out of the turf (integer 0-4). 0 ' +
      'leaves only the crown and the fine rumple, an evenly grazed field, and drops the ' +
      'total height from 0.499 m to 0.374 m; 3 is the default and they sit ONE PER ' +
      'CARDINAL out on the shoulder — 3.1 m across and 0.175 m proud on the +Z front, ' +
      '2.8 m and 0.150 m on the -X left, 2.6 m and 0.128 m on the -Z back — so every ' +
      'elevation has a crest of its own breaking its top line; 4 adds a 2.4 m mound ' +
      '0.112 m tall on the +X right. Mounds keep their real size in metres at every ' +
      'spread, so a small island carries proportionally fewer of them',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'meadow':       { grass: '#77b258' },
  'deep-forest':  { grass: '#4c8140' },
  'spring-fresh': { grass: '#93c46a' },
  'dry-pasture':  { grass: '#6f8f3c' },
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
    C: { grass: hex(p.grass) },
    spread: num(p.spread, 0.70, 1.22),
    facets: Math.round(num(p.facets, 3, 8)),
    relief: num(p.relief, 0, 1.70),
    swells: Math.round(num(p.swells, 0, 4)),
  };
}

const TOP    = 0.05;
const CAP_Y  = 0.850;

const FLOOR_Y = 0.020;
const BASE_D = 9.0;
const OVAL   = 0.89;

const N_SIDES = 13;

const WALL_Y = 0.022;
const CHAM_R = 0.020;

const CROWN  = 0.300;
const PLAT_Q = 0.74;
const LIP_Q  = 0.930;
function crownAt(q) {
  if (q <= PLAT_Q) return CROWN * (1 - 0.26 * (q / PLAT_Q) ** 2);
  if (q <= LIP_Q) {
    const u = (q - PLAT_Q) / (LIP_Q - PLAT_Q);
    return CROWN * (0.74 + (0.52 - 0.74) * u * (2 - u));
  }
  const u = (q - LIP_Q) / (1 - LIP_Q);
  return CROWN * 0.52 * (1 - u);
}

const AMP = 0.038;
const DIP = 0.30;

const CELL      = 0.85;
const STEP_UP   = 0.075;
const STEP_DOWN = 0.045;

function cellHash(i, j) {
  const h = Math.sin(i * 127.1 + j * 311.7) * 43758.5453;
  return h - Math.floor(h);
}
function crumpleAt(x, z) {
  const i = Math.floor(x / CELL), j = Math.floor(z / CELL);
  const up = (((i + j) % 2) + 2) % 2 === 0;
  const m = 0.55 + 0.45 * cellHash(i, j);
  return up ? STEP_UP * m : -STEP_DOWN * m;
}
function undulate(x, z) {
  return 0.58 * Math.sin(1.82 * x - 1.15) * Math.cos(1.51 * z + 0.65)
       + 0.42 * Math.sin(2.30 * z - 0.55) * Math.cos(1.98 * x + 2.35);
}

const SEATS = [
  { fx: +0.10, fz: +0.66, r: 1.55, h: 0.175 },
  { fx: -0.66, fz: -0.20, r: 1.42, h: 0.150 },
  { fx: +0.16, fz: -0.64, r: 1.30, h: 0.128 },
  { fx: +0.62, fz: +0.26, r: 1.20, h: 0.112 },
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
  const N = N_SIDES;
  const step = TAU / N;
  const rand = prng(90211);

  const ang = [], rad = [];

  for (let i = 0; i < N; i++) ang.push(i * step + (rand() - 0.5) * step * 0.28);

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
      + 0.050 * Math.sin(3 * a - 1.1) + 0.028 * Math.sin(5 * a + 2.6)
      + (rand() - 0.5) * 0.048;

    const front = 1 + 0.070 * Math.pow(Math.max(0, Math.cos(a - FRONT)), 2);
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
  const rim = Array.from({ length: N }, (_, i) =>
    [foot[i][0] * rimR[i], TOP, foot[i][2] * rimR[i]]);

  const hx = (BASE_D * P.spread) / 2, hz = (maxZ - minZ) * S / 2;

  const buckets = new Map();
  const emit = (hex, a, b, c) => {
    if (!buckets.has(hex)) buckets.set(hex, []);
    tri(buckets.get(hex), a, b, c);
  };

  const band = (hex, up, lo, i, j) => {
    emit(hex, up[i], up[j], lo[j]);
    emit(hex, up[i], lo[j], lo[i]);
  };
  const GRASS = P.C.grass;

  const seats = SEATS.slice(0, P.swells).map((s) => ({ x: s.fx * hx, z: s.fz * hz, r: s.r, h: s.h }));
  const amp = AMP * P.relief;
  const groundY = (x, z) => {

    const q = Math.min(1, Math.hypot(x / hx, z / hz));
    let h = crownAt(q) * P.relief;
    const u = undulate(x, z);
    h += (u > 0 ? u : u * DIP) * amp;
    for (const s of seats) h += s.h * P.relief * bumpFall(Math.hypot(x - s.x, z - s.z) / s.r);

    h += crumpleAt(x, z) * P.relief * Math.min(1, q / 0.22) * (0.22 + 1.45 * q ** 3);
    return Math.min(CAP_Y, Math.max(FLOOR_Y, TOP + h));
  };

  const R = Math.max(3, Math.round(P.facets * P.spread));
  const M = N * 2;
  const jrand = prng(20773);

  const ringPhase = Array.from({ length: R }, () => (jrand() - 0.5) * (TAU / M) * 0.45);
  const ringJit = Array.from({ length: R }, () =>
    Array.from({ length: M }, () => 1 + (jrand() - 0.5) * 0.12));

  const ringF = Array.from({ length: R }, (_, k) =>
    k === R - 1 ? LIP_Q : LIP_Q * (k / (R - 1)) * (0.90 + 0.20 * jrand()));

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

      const ease = 1 - 0.25 * Math.min(1, Math.max(0, (f - 0.72) / 0.20));
      const y = groundY(x, z);
      return [x, TOP + (y - TOP) * ease, z];
    }));
  }
  const centre = [0, groundY(0, 0), 0];

  {
    const out = rings[rings.length - 1];
    for (let i = 0; i < N; i++) {
      const j = (i + 1) % N;
      const c0 = 2 * i, c1 = (2 * i + 1) % M, c2 = (2 * i + 2) % M;
      emit(GRASS, rim[i], out[c0], out[c1]);
      emit(GRASS, rim[i], out[c1], rim[j]);
      emit(GRASS, rim[j], out[c1], out[c2]);
    }
  }

  for (let k = rings.length - 1; k > 0; k--) {
    const outer = rings[k], inner = rings[k - 1];
    for (let c = 0; c < M; c++) {
      const d = (c + 1) % M;
      emit(GRASS, inner[c], inner[d], outer[d]);
      emit(GRASS, inner[c], outer[d], outer[c]);
    }
  }

  {
    const inner = rings[0];
    for (let c = 0; c < M; c++) emit(GRASS, centre, inner[(c + 1) % M], inner[c]);
  }

  for (let i = 0; i < N; i++) {
    const j = (i + 1) % N;
    band(GRASS, wall, foot, i, j);
    band(GRASS, rim,  wall, i, j);
  }

  for (let i = 0; i < N; i++) emit(GRASS, [0, 0, 0], foot[i], foot[(i + 1) % N]);

  const list = [];
  for (const [hex, pos] of buckets) list.push(prep(posGeo(pos), hex));
  const geo = mergeGeometries(list);
  if (!geo) throw new Error('grass-terrain-blob: mergeGeometries returned null');
  geo.computeVertexNormals();

  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  geo.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const mesh = new THREE.Mesh(geo, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.9, metalness: 0,
  }));
  mesh.name = 'grass-terrain-blob-mesh';

  const g = new THREE.Group();
  g.name = 'grass-terrain-blob';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

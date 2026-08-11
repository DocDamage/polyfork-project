/*
 * Wooden Fence Section
 * https://polyfork.dev/asset/wooden-fence-section-5f04b7
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wooden-fence-section-5f04b7.mjs';
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
 *   colorway   choice  'weathered-oak' 'weathered-oak' | 'dark-walnut' | 'pale-birch' | 'grey-driftwood'
 *   railWood   color   '#8c6a47'      any hex or THREE.Color
 *   postWood   color   '#75563b'      any hex or THREE.Color
 *   capWood    color   '#a5855e'      any hex or THREE.Color
 *   pegIron    color   '#57544e'      any hex or THREE.Color
 *   rails      range   2              2 to 3
 *   midPost    toggle  false          true | false
 *   weathered  range   0              0 to 1
 *
 * Every option is described in full at https://polyfork.dev/cdn/wooden-fence-section-5f04b7-params.json
 *
 * SPECS  428 triangles, 1 material, 2 x 1.1 x 0.24 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const LEN        = 2.000;
const H          = 1.100;
const POST_X     = 0.800;
const POST_W     = 0.200;
const POST_FLARE = 0.010;
const POST_TAPER = 0.011;
const CAP_H      = 0.130;
const CAP_W      = 0.240;
const CAP_TOP    = 0.185;
const RAIL_H     = 0.150;
const RAIL_D     = 0.120;
const CH         = 0.022;
const PEG_W      = 0.070;
const PEG_OUT    = 0.019;
const RAIL_TOP_Y = 0.750;
const RAIL_BOT2  = 0.360;
const RAIL_BOT3  = 0.290;

const COLORWAYS = {
  'weathered-oak':  { railWood: '#8c6a47', postWood: '#75563b', capWood: '#a5855e', pegIron: '#57544e' },
  'dark-walnut':    { railWood: '#5d4430', postWood: '#4a3527', capWood: '#75563b', pegIron: '#3a2a1e' },
  'pale-birch':     { railWood: '#c2a479', postWood: '#a5855e', capWood: '#e0d2b4', pegIron: '#6e6b63' },
  'grey-driftwood': { railWood: '#a3a099', postWood: '#87847c', capWood: '#bcb9b1', pegIron: '#57544e' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'dark-walnut', 'pale-birch', 'grey-driftwood'],
    describe: 'Curated timber schemes from the kit palette. weathered-oak is a warm ' +
              'mid brown; dark-walnut is a near-black brown for deep forest; ' +
              'pale-birch is a bleached light wood; grey-driftwood is silvered, ' +
              'sun-bleached timber with no brown left in it.',
  },
  railWood: {
    type: 'color', default: '#8c6a47', label: 'Rail timber',
    describe: 'Albedo of the horizontal rails only. Keep it a step LIGHTER than the ' +
              'posts so the rails read in front of the post faces at a distance.',
  },
  postWood: {
    type: 'color', default: '#75563b', label: 'Post timber',
    describe: 'Albedo of the two (or three) square post shafts. The darkest wood step; ' +
              'it grounds the fence against light terrain.',
  },
  capWood: {
    type: 'color', default: '#a5855e', label: 'Post cap',
    describe: 'Albedo of the overhanging cap block on top of each post. The lightest ' +
              'wood step, so the cap line reads as a crown along the run.',
  },
  pegIron: {
    type: 'color', default: '#57544e', label: 'Peg head',
    describe: 'Albedo of the small square peg heads that pin each rail through its ' +
              'post. Dark iron-grey; the only non-wood zone on the asset.',
  },
  rails: {
    type: 'range', default: 2, min: 2, max: 3, step: 1, affects: 'geometry',
    label: 'Rails',
    describe: 'How many horizontal rails span the section. 2 is the open paddock ' +
              'fence of the reference; 3 closes the gaps for a stock or garden run. ' +
              'The rail SECTION never changes — the extra rail is real added timber, ' +
              'so the triangle count rises with it, and the top rail stays at 0.75 m ' +
              'while the lowest drops to 0.29 m to re-space the band.',
  },
  midPost: {
    type: 'toggle', default: false, affects: 'geometry', label: 'Middle post',
    describe: 'Adds a third identical post (shaft, cap and pegs) at the section ' +
              'centre, halving the rail span for a braced, heavier-duty fence. ' +
              'Off gives the clean two-post span of the reference.',
  },
  weathered: {
    type: 'range', default: 0, min: 0, max: 1, step: 0.05, affects: 'geometry',
    label: 'Weathering', describe:
      'Old-fence wonkiness, rebuilt into the timber rather than painted on. At 0 ' +
      'every post is dead plumb, every cap level and the rails dead straight — the ' +
      'crisp kit default. Rising to 1 each post leans up to ~3.5 degrees on its own ' +
      'seeded axis, settles up to 60 mm into the ground so the cap line goes ragged, ' +
      'and the rails sag about 35 mm at mid-span. The rail ENDS never move: flat at ' +
      'x = ±1.000 at their exact heights so sections still chain seamlessly.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

const parts = [];
function tri(out, a, b, c) {

  const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
  const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
  if (nx * nx + ny * ny + nz * nz < 1e-12) return;
  out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]);
}

function faceOut(out, pts, inner) {
  const [a, b, c] = pts;
  const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
  const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
  let cx = 0, cy = 0, cz = 0;
  for (const p of pts) { cx += p[0]; cy += p[1]; cz += p[2]; }
  cx /= pts.length; cy /= pts.length; cz /= pts.length;
  const d = nx * (cx - inner[0]) + ny * (cy - inner[1]) + nz * (cz - inner[2]);
  const p = d >= 0 ? pts : pts.slice().reverse();
  for (let i = 1; i < p.length - 1; i++) tri(out, p[0], p[i], p[i + 1]);
}

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function centre(ring) {
  let x = 0, y = 0, z = 0;
  for (const p of ring) { x += p[0]; y += p[1]; z += p[2]; }
  return [x / ring.length, y / ring.length, z / ring.length];
}

function sweep(rings, out, capStart = true, capEnd = true) {
  for (let i = 0; i < rings.length - 1; i++) {
    const A = rings[i], B = rings[i + 1];
    const ca = centre(A), cb = centre(B);
    const inner = [(ca[0] + cb[0]) / 2, (ca[1] + cb[1]) / 2, (ca[2] + cb[2]) / 2];
    for (let j = 0; j < A.length; j++) {
      const k = (j + 1) % A.length;
      faceOut(out, [A[j], A[k], B[k], B[j]], inner);
    }
  }
  if (capStart) faceOut(out, rings[0], centre(rings[1]));
  if (capEnd) faceOut(out, rings[rings.length - 1], centre(rings[rings.length - 2]));
  return out;
}

function octRing(hu, hv, ch, map) {
  const c = Math.min(ch, Math.min(hu, hv) * 0.49);
  const uv = [
    [hu - c, -hv], [hu, -hv + c], [hu, hv - c], [hu - c, hv],
    [-hu + c, hv], [-hu, hv - c], [-hu, -hv + c], [-hu + c, -hv],
  ];
  return uv.map(([u, v]) => map(u, v));
}

function prng(seed = 1) {
  let s = seed % 2147483647;
  if (s <= 0) s += 2147483646;
  const r = () => (s = (s * 16807) % 2147483647) / 2147483647;
  r(); r(); r();
  return r;
}

export function createAsset(opts = {}) {
  const g = new THREE.Group();
  g.name = 'wooden-fence-section';

  const cwName = COLORWAYS[opts.colorway] ? opts.colorway : params.colorway.default;
  const C = { ...COLORWAYS[cwName] };
  for (const k of ['railWood', 'postWood', 'capWood', 'pegIron']) {
    if (opts[k]) C[k] = opts[k];
  }

  const nRails = Math.max(2, Math.min(3, Math.round(opts.rails ?? params.rails.default)));
  const midPost = opts.midPost ?? params.midPost.default;
  const wear = Math.max(0, Math.min(1, opts.weathered ?? params.weathered.default));

  parts.length = 0;
  const add = (geo, hex) => parts.push({ g: geo, c: hex });

  const railYs = [];
  if (nRails <= 2) railYs.push(RAIL_TOP_Y, RAIL_BOT2);
  else for (let i = 0; i < nRails; i++) {
    railYs.push(RAIL_TOP_Y - (RAIL_TOP_Y - RAIL_BOT3) * (i / (nRails - 1)));
  }

  const postXs = midPost ? [-POST_X, 0, POST_X] : [-POST_X, POST_X];

  const rand = prng(20860808);
  const posts = postXs.map(() => ({
    leanX: (rand() * 2 - 1) * wear * 0.065,
    leanZ: (rand() * 2 - 1) * wear * 0.042,

    hMul: 1 - rand() * wear * 0.055,
  }));

  const shaftHalf = (y, top) => {
    const w0 = (POST_W + POST_FLARE * 2) / 2;
    const w1 = POST_W / 2;
    const w2 = POST_W / 2 - POST_TAPER;
    if (y < 0.07) return w0 + (w1 - w0) * (y / 0.07);
    return w1 + (w2 - w1) * ((y - 0.07) / Math.max(0.001, top - 0.07));
  };

  postXs.forEach((px, i) => {
    const { leanX, leanZ, hMul } = posts[i];
    const top = H * hMul;
    const shaftTop = top - CAP_H;

    const sx = (y) => px + leanX * (y / top);
    const sz = (y) => leanZ * (y / top);
    const at = (y, half, ch) =>
      octRing(half, half, ch, (u, v) => [sx(y) + u, y, sz(y) + v]);

    const shaft = [];
    for (const y of [0, 0.07, shaftTop]) shaft.push(at(y, shaftHalf(y, shaftTop), CH));

    add(posGeo(sweep(shaft, [], true, false)), C.postWood);

    const capB = CAP_W / 2, capT = CAP_TOP / 2;
    const cap = [
      at(shaftTop - 0.030, capB, CH),
      at(shaftTop + CAP_H * 0.55, capB, CH),
      at(top, capT, CH * 0.7),
    ];
    add(posGeo(sweep(cap, [])), C.capWood);

    for (const ry of railYs) {
      if (ry > shaftTop - 0.05) continue;
      const half = shaftHalf(ry, shaftTop);
      for (const s of [1, -1]) {
        const cx = sx(ry), cz = sz(ry);
        const z0 = cz + s * (half - 0.004), z1 = cz + s * (half + PEG_OUT);
        const h = PEG_W / 2;
        const p = (x, y, z) => [x, y, z];
        const A = [p(cx - h, ry - h, z0), p(cx + h, ry - h, z0), p(cx + h, ry + h, z0), p(cx - h, ry + h, z0)];
        const B = [p(cx - h, ry - h, z1), p(cx + h, ry - h, z1), p(cx + h, ry + h, z1), p(cx - h, ry + h, z1)];
        const out = [];
        const inner = [cx, ry, (z0 + z1) / 2];
        for (let j = 0; j < 4; j++) {
          const k = (j + 1) % 4;
          faceOut(out, [A[j], A[k], B[k], B[j]], inner);
        }
        faceOut(out, B, inner);
        add(posGeo(out), C.pegIron);
      }
    }
  });

  const sag = wear * 0.035;
  const stations = [-1, -0.97, -0.35, 0.35, 0.97, 1].map((f) => f * (LEN / 2));
  for (const ry of railYs) {
    const rings = stations.map((x) => {
      const t = Math.abs(x) / POST_X;
      const drop = t >= 1 ? 0 : -sag * (1 - t * t);
      const ch = Math.abs(Math.abs(x) - LEN / 2) < 1e-6 ? 0.002 : CH;
      return octRing(RAIL_D / 2, RAIL_H / 2, ch, (u, v) => [x, ry + drop + v, u]);
    });
    add(posGeo(sweep(rings, [])), C.railWood);
  }

  const geos = parts.map(({ g: geo, c }) => {
    const b = geo.toNonIndexed();
    b.deleteAttribute('uv');
    b.deleteAttribute('normal');
    const col = new THREE.Color(c);
    const n = b.attributes.position.count;
    const arr = new Float32Array(n * 3);
    for (let i = 0; i < n; i++) { arr[i * 3] = col.r; arr[i * 3 + 1] = col.g; arr[i * 3 + 2] = col.b; }
    b.setAttribute('color', new THREE.BufferAttribute(arr, 3));
    return b;
  });
  const merged = mergeGeometries(geos);
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'fence';
  g.add(mesh);
  return g;
}

export default createAsset;

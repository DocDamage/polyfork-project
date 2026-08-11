/*
 * Street-lamp
 * https://polyfork.dev/asset/street-lamp-b4fa26
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './street-lamp-b4fa26.mjs';
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
 *   colorway  choice  'municipal-teal' 'municipal-teal' | 'highway-silver' | 'sunset-diner' | 'park-green'
 *   post      color   '#ddceb0'      any hex or THREE.Color
 *   shell     color   '#54b4b1'      any hex or THREE.Color
 *   skirt     color   '#3d3f46'      any hex or THREE.Color
 *   lens      color   '#f1f2ef'      any hex or THREE.Color
 *   collar    color   '#e58132'      any hex or THREE.Color
 *   tallness  range   1              0.85 to 1.22
 *   reach     range   1              0.65 to 1.55
 *   facets    choice  'standard'     'chunky' | 'standard' | 'smooth'
 *
 * Every option is described in full at https://polyfork.dev/cdn/street-lamp-b4fa26-params.json
 *
 * SPECS  422 triangles, 1 material, 2.25 x 3.97 x 0.62 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BASE = {
  post:   0xddceb0,
  shell:  0x54b4b1,
  skirt:  0x3d3f46,
  lens:   0xf1f2ef,

  collar: 0xe58132,
};

const COLORWAYS = {
  'municipal-teal': {},
  'highway-silver': { post: 0xafb5bb, shell: 0x898c95, skirt: 0x2a2d35, lens: 0xc2c7cd, collar: 0x676b72 },
  'sunset-diner':   { post: 0xc7baa6, shell: 0xd13d34, skirt: 0x4c4f57, lens: 0xecf1cb, collar: 0x6b2627 },
  'park-green':     { post: 0xc7baa6, shell: 0x267466, skirt: 0x2a2d35, lens: 0xddceb0, collar: 0x4e3c30 },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'municipal-teal', label: 'Colorway',
    options: ['municipal-teal', 'highway-silver', 'sunset-diner', 'park-green'],
    describe: 'curated kit-coherent scheme; sets post, housing, skirt, lens and collar '
      + 'tones together. municipal-teal is the cream post + teal head of the reference; '
      + 'highway-silver is all-grey galvanised; sunset-diner is a red head on cream; '
      + 'park-green is a deep bottle-green head.',
  },
  post: {
    type: 'color', default: 0xddceb0, label: 'Post & arm',
    describe: 'albedo of the whole cream painted-steel run — base pedestal, shaft, '
      + 'shaft bead and the curved gooseneck arm. The dominant colour of the asset.',
  },
  shell: {
    type: 'color', default: 0x54b4b1, label: 'Lamp shell',
    describe: 'albedo of the lamp housing above the rim crease: top plate, top chamfer '
      + 'and the sloping upper sides. The head\'s hero colour.',
  },
  skirt: {
    type: 'color', default: 0x3d3f46, label: 'Diffuser skirt',
    describe: 'albedo of the dark tapering underside of the lamp head, from the widest '
      + 'rim crease down to the lens. Keep it well darker than the shell or the crease dies.',
  },
  lens: {
    type: 'color', default: 0xf1f2ef, label: 'Lens',
    describe: 'albedo of the pale refractor panel on the underside of the head — the '
      + 'only bright note seen from below. Keep it near-white: anything mid-grey sinks '
      + 'into the dark skirt when the camera looks up at the lamp.',
  },
  collar: {
    type: 'color', default: 0xe58132, label: 'Collars',
    describe: 'albedo of the two proud fitting bands — one at the base pedestal joint, '
      + 'one on the arm just before the lamp. A small hot accent; avoid post-like tones.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.85, max: 1.22, label: 'Post height',
    affects: 'geometry',
    describe: 'stretches ONLY the straight shaft between the base collar and the bend; '
      + 'the pedestal, hook and head keep their size and ride up. Total height runs '
      + '3.57 m (a squat driveway lamp) to 4.55 m (a highway mast).',
  },
  reach: {
    type: 'range', default: 1.0, min: 0.65, max: 1.55, label: 'Arm reach',
    affects: 'geometry',
    describe: 'scales both the hook\'s horizontal run and the level stretch of arm that '
      + 'follows it. At 0.65 the bend is a tight hook and the head sits close over the '
      + 'post; at 1.55 the arm swings far out over the road. Total reach from the post '
      + 'centre runs 1.64 m to 2.36 m.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Post facets',
    options: ['chunky', 'standard', 'smooth'], affects: 'geometry',
    describe: 'cross-section of the whole swept run (pedestal, collars, shaft, arm). '
      + 'chunky = 6 flats, a crude cast pole with obvious edges; standard = 8 flats, '
      + 'the reference; smooth = 12 flats, a near-round drawn-steel tube.',
  },
};

const SHAFT_TOP = 3.300;
const ARC_RISE  = 0.595;
const ARC_RUN   = 0.530;
const ARC_SEGS  = 5;
const ARM_LEVEL = 0.270;

const HEAD_GAP  = 0.140;
const SHAFT_BASE = 0.614;

const PLAN_TOP   = [[0.058, 0.128], [0.176, 0.245], [0.556, 0.237], [0.768, 0.161], [0.900, 0.070]];
const PLAN_CHAM  = [[0.026, 0.162], [0.152, 0.280], [0.558, 0.271], [0.786, 0.192], [0.944, 0.098]];
const PLAN_RIM   = [[0.000, 0.190], [0.130, 0.310], [0.560, 0.300], [0.800, 0.215], [0.980, 0.115]];
const PLAN_SKIRT = [[0.058, 0.112], [0.178, 0.215], [0.552, 0.208], [0.762, 0.148], [0.906, 0.076]];
const PLAN_LENS  = [[0.112, 0.068], [0.228, 0.148], [0.540, 0.143], [0.730, 0.100], [0.848, 0.048]];

const Y_TOP = 3.965, Y_CHAM = 3.930, Y_RIM = 3.680, Y_SKIRT = 3.420, Y_LENS = 3.365;
const ARM_Y = 3.895;

const FACET_SEGS = { chunky: 6, standard: 8, smooth: 12 };

const MAT = new THREE.MeshStandardMaterial({
  vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
});
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

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function face(out, pts, ref) {
  let nx = 0, ny = 0, nz = 0;
  for (let i = 0; i < pts.length; i++) {
    const a = pts[i], b = pts[(i + 1) % pts.length];
    nx += (a[1] - b[1]) * (a[2] + b[2]);
    ny += (a[2] - b[2]) * (a[0] + b[0]);
    nz += (a[0] - b[0]) * (a[1] + b[1]);
  }
  const p = (nx * ref[0] + ny * ref[1] + nz * ref[2]) < 0 ? pts.slice().reverse() : pts;
  for (let i = 1; i < p.length - 1; i++) tri(out, p[0], p[i], p[i + 1]);
}

function sweepTube(stations, seg) {
  const n = stations.length;
  const dirs = [];
  for (let i = 0; i < n - 1; i++) {
    const dx = stations[i + 1].x - stations[i].x, dy = stations[i + 1].y - stations[i].y;
    const L = Math.hypot(dx, dy) || 1;
    dirs.push([dx / L, dy / L]);
  }
  const U = [];
  for (let i = 0; i < n; i++) {
    const a = dirs[Math.max(0, i - 1)], b = dirs[Math.min(dirs.length - 1, i)];
    const tx = a[0] + b[0], ty = a[1] + b[1];
    const L = Math.hypot(tx, ty) || 1;
    U.push([-ty / L, tx / L]);
  }

  const ang = k => ((k + 0.5) / seg) * Math.PI * 2;
  const rings = stations.map((s, i) => {
    const pts = [];
    for (let k = 0; k < seg; k++) {
      const cs = Math.cos(ang(k)) * s.r, sn = Math.sin(ang(k)) * s.r;
      pts.push([s.x + U[i][0] * cs, s.y + U[i][1] * cs, sn]);
    }
    return pts;
  });
  const buckets = new Map();
  for (let i = 0; i < n - 1; i++) {
    const c = stations[i + 1].c;
    if (!buckets.has(c)) buckets.set(c, []);
    const out = buckets.get(c);
    const A = rings[i], B = rings[i + 1];
    const ux = (U[i][0] + U[i + 1][0]) / 2, uy = (U[i][1] + U[i + 1][1]) / 2;
    for (let k = 0; k < seg; k++) {
      const k2 = (k + 1) % seg;
      const am = (ang(k) + ang(k + 1)) / 2;
      const ref = [ux * Math.cos(am), uy * Math.cos(am), Math.sin(am)];
      face(out, [A[k], A[k2], B[k2], B[k]], ref);
    }
  }
  return { buckets, rings };
}

function headRing(y, plan, x0) {
  const pts = plan.map(([u, hw]) => [x0 + u, y, hw]);
  for (let i = plan.length - 1; i >= 0; i--) pts.push([x0 + plan[i][0], y, -plan[i][1]]);
  return pts;
}

function loftBand(out, A, B) {
  const n = A.length;
  for (let k = 0; k < n; k++) {
    const k2 = (k + 1) % n;
    const mx = (A[k][0] + A[k2][0] + B[k][0] + B[k2][0]) / 4;
    const mz = (A[k][2] + A[k2][2] + B[k][2] + B[k2][2]) / 4;
    const cx = (A[0][0] + A[n / 2][0]) / 2;
    face(out, [A[k], A[k2], B[k2], B[k]], [mx - cx, 0, mz]);
  }
}

const nd = (hex, k) => (hex & 0xffff00) | Math.max(0, Math.min(255, (hex & 0xff) + k));

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  Object.assign(p, userParams);

  const C = { ...BASE, ...(COLORWAYS[p.colorway] || {}) };
  for (const k of ['post', 'shell', 'skirt', 'lens', 'collar']) {
    if (userParams[k] !== undefined) C[k] = userParams[k];
  }
  const Z = { post: C.post, shell: C.shell, skirt: C.skirt, lens: C.lens, collar: C.collar };

  if (Z.skirt === Z.shell) Z.skirt = nd(Z.skirt, -1);
  if (Z.lens === Z.skirt) Z.lens = nd(Z.lens, 1);
  if (Z.collar === Z.post) Z.collar = nd(Z.collar, -1);

  const seg = FACET_SEGS[p.facets] || FACET_SEGS.standard;

  const shaftTop = SHAFT_BASE + (SHAFT_TOP - SHAFT_BASE) * p.tallness;
  const dy = shaftTop - SHAFT_TOP;
  const run = ARC_RUN * p.reach;
  const level = ARM_LEVEL * p.reach;
  const armY = ARM_Y + dy;
  const headX0 = run + level + 0.108 + HEAD_GAP;
  const bead = SHAFT_BASE + 1.000 * p.tallness;

  const st = [

    { x: 0, y: 0.000, r: 0.235, c: Z.post },
    { x: 0, y: 0.085, r: 0.235, c: Z.post },
    { x: 0, y: 0.087, r: 0.190, c: Z.post },
    { x: 0, y: 0.500, r: 0.126, c: Z.post },
    { x: 0, y: 0.612, r: 0.126, c: Z.collar },
    { x: 0, y: SHAFT_BASE, r: 0.080, c: Z.collar },
    { x: 0, y: bead,         r: 0.0745, c: Z.post },
    { x: 0, y: bead + 0.002, r: 0.1000, c: Z.post },
    { x: 0, y: bead + 0.057, r: 0.1000, c: Z.post },
    { x: 0, y: bead + 0.059, r: 0.0735, c: Z.post },
    { x: 0, y: shaftTop, r: 0.066, c: Z.post },
  ];

  for (let i = 1; i <= ARC_SEGS; i++) {
    const t = (i / ARC_SEGS) * Math.PI / 2;
    st.push({
      x: run * (1 - Math.cos(t)),
      y: shaftTop + ARC_RISE * Math.sin(t),
      r: 0.066 + (0.0625 - 0.066) * (i / ARC_SEGS),
      c: Z.post,
    });
  }
  const a = run + level;
  st.push({ x: a,         y: armY, r: 0.0625, c: Z.post });
  st.push({ x: a + 0.002, y: armY, r: 0.0840, c: Z.collar });
  st.push({ x: a + 0.106, y: armY, r: 0.0840, c: Z.collar });
  st.push({ x: a + 0.108, y: armY, r: 0.0625, c: Z.collar });
  st.push({ x: headX0 + 0.090, y: armY, r: 0.0625, c: Z.post });

  const { buckets, rings } = sweepTube(st, seg);
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  for (const [c, pos] of buckets) add(posGeo(pos), c);

  const foot = [];
  face(foot, rings[0], [0, -1, 0]);
  add(posGeo(foot), Z.post);

  const rT = headRing(Y_TOP   + dy, PLAN_TOP,   headX0);
  const rC = headRing(Y_CHAM  + dy, PLAN_CHAM,  headX0);
  const rR = headRing(Y_RIM   + dy, PLAN_RIM,   headX0);
  const rS = headRing(Y_SKIRT + dy, PLAN_SKIRT, headX0);
  const rL = headRing(Y_LENS  + dy, PLAN_LENS,  headX0);

  const shell = [];
  face(shell, rT, [0, 1, 0]);
  loftBand(shell, rT, rC);
  loftBand(shell, rC, rR);
  add(posGeo(shell), Z.shell);

  const skirt = [];
  loftBand(skirt, rR, rS);
  add(posGeo(skirt), Z.skirt);

  const lensG = [];
  loftBand(lensG, rS, rL);
  face(lensG, rL, [0, -1, 0]);
  add(posGeo(lensG), Z.lens);

  const merged = mergeGeometries(parts.map(q => prep(q.g, q.c)));
  merged.computeVertexNormals();

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);

  const mesh = new THREE.Mesh(merged, MAT);
  mesh.name = 'street-lamp-body';

  const g = new THREE.Group();
  g.name = 'street-lamp';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {
  lens: { color: '#ffcf87', describe: 'warm sodium lamp behind the glass' },
};

export default createAsset;

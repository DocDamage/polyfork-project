/*
 * Street Lamp
 * https://polyfork.dev/asset/street-lamp-136745
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './street-lamp-136745.mjs';
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
 *   colorway  choice  'municipal-green' 'municipal-green' | 'gotham-black' | 'granite-grey' | 'signal-red'
 *   paint     color   '#3d6b52'      any hex or THREE.Color
 *   glass     color   '#322d2c'      any hex or THREE.Color
 *   lens      color   '#cfc6b9'      any hex or THREE.Color
 *   tallness  range   1              0.85 to 1.12
 *   reach     range   1              0.6 to 1.6
 *   facets    choice  'standard'     'chunky' | 'standard' | 'smooth'
 *
 * Every option is described in full at https://polyfork.dev/cdn/street-lamp-136745-params.json
 *
 * SPECS  344 triangles, 1 material, 2.56 x 6 x 0.9 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BASE = {
  paint: 0x3d6b52,
  glass: 0x322d2c,
  lens:  0xcfc6b9,
};

const COLORWAYS = {
  'municipal-green': {},
  'gotham-black':    { paint: 0x463b37, glass: 0x211f1d, lens: 0xc1b0a1 },
  'granite-grey':    { paint: 0x62605c, glass: 0x211f1d, lens: 0xcfc6b9 },
  'signal-red':      { paint: 0xb63735, glass: 0x322d2c, lens: 0xcfc6b9 },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'municipal-green', label: 'Colorway',
    options: ['municipal-green', 'gotham-black', 'granite-grey', 'signal-red'],
    describe: 'curated kit-coherent scheme; sets the paint, glass and refractor tones '
      + 'together. municipal-green is the kit\'s shipped street-furniture green of the '
      + 'reference; gotham-black is a warm near-black cast iron; granite-grey is a plain '
      + 'galvanised municipal grey; signal-red matches the kit\'s fire hydrant.',
  },
  paint: {
    type: 'color', default: 0x3d6b52, label: 'Paint',
    describe: 'albedo of the entire painted casting — plinth, flared shaft, gooseneck arm, '
      + 'the ridge lying on the head, and the head\'s shell and flange. Roughly 90% of the '
      + 'asset; this is the colour the lamp is recognised by.',
  },
  glass: {
    type: 'color', default: 0x322d2c, label: 'Diffuser glass',
    describe: 'albedo of the dark tapering sides under the head\'s flange. Keep it far '
      + 'darker than the paint or the flange overhang stops reading as an overhang.',
  },
  lens: {
    type: 'color', default: 0xcfc6b9, label: 'Refractor',
    describe: 'albedo of the pale panel on the underside of the lamp head — the only bright '
      + 'note when the camera looks up at the lamp, and the surface that lights at night. '
      + 'Keep it pale: a mid-grey sinks into the dark glass from beneath.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.85, max: 1.12, label: 'Post height',
    affects: 'geometry',
    describe: 'stretches ONLY the straight shaft between the foot flare and the bend; the '
      + 'plinth, flare, hook and lamp head keep their size and ride up. Total height runs '
      + '5.45 m (a squat side-street lamp) to 6.44 m (an avenue mast).',
  },
  reach: {
    type: 'range', default: 1.0, min: 0.6, max: 1.6, label: 'Arm reach',
    affects: 'geometry',
    describe: 'scales the hook\'s horizontal run and the free span of arm before the head. '
      + 'At 0.6 the head sits tucked close over the kerb with the hook a tight snap; at 1.6 '
      + 'the arm swings right out over a traffic lane on a long free span. Reach from the '
      + 'pole centre to the head tip runs 1.92 m to 2.48 m.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Post facets',
    options: ['chunky', 'standard', 'smooth'], affects: 'geometry',
    describe: 'cross-section of the whole swept run — plinth, flare, shaft, arm and the '
      + 'ridge on the head. chunky = 6 flats, a crude cast pole with obvious edges; '
      + 'standard = 8 flats, the octagonal reference post; smooth = 12 flats, a nearly '
      + 'round drawn-steel tube.',
  },
};

const SHAFT_TOP = 5.280;
const ARC_RISE  = 0.620;
const ARC_RUN   = 0.300;
const ARC_SEGS  = 6;
const DIP_RUN   = 0.260;
const DIP_FALL  = 0.100;
const HEAD_X0   = 0.660;

const HEAD_L    = 1.480;
const RIDGE_U   = 0.920;

const RINGS = [
  { key: 'TOP',   y: 5.735, uN: 0.055, uF: 1.425, hw: 0.385, clip: 0.075 },
  { key: 'FL_T',  y: 5.645, uN: 0.000, uF: 1.480, hw: 0.450, clip: 0.105 },
  { key: 'FL_B',  y: 5.530, uN: 0.000, uF: 1.480, hw: 0.450, clip: 0.105 },

  { key: 'RIM',   y: 5.335, uN: 0.110, uF: 1.370, hw: 0.350, clip: 0.085 },
  { key: 'SKIRT', y: 5.015, uN: 0.255, uF: 1.225, hw: 0.245, clip: 0.062 },
  { key: 'LENS',  y: 4.955, uN: 0.290, uF: 1.190, hw: 0.212, clip: 0.054 },
];
const ARM_Y = 5.800;

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
  const out = [];
  for (let i = 0; i < n - 1; i++) {
    const A = rings[i], B = rings[i + 1];
    const ux = (U[i][0] + U[i + 1][0]) / 2, uy = (U[i][1] + U[i + 1][1]) / 2;
    for (let k = 0; k < seg; k++) {
      const k2 = (k + 1) % seg;
      const am = (ang(k) + ang(k + 1)) / 2;
      const ref = [ux * Math.cos(am), uy * Math.cos(am), Math.sin(am)];
      face(out, [A[k], A[k2], B[k2], B[k]], ref);
    }
  }
  return { pos: out, rings };
}

function headRing(r, x0, dy) {
  const plan = [
    [r.uN, r.hw - r.clip], [r.uN + r.clip, r.hw],
    [r.uF - r.clip, r.hw], [r.uF, r.hw - r.clip],
  ];
  const y = r.y + dy;
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
  for (const k of ['paint', 'glass', 'lens']) {
    if (userParams[k] !== undefined) C[k] = userParams[k];
  }
  const Z = { paint: C.paint, glass: C.glass, lens: C.lens };

  if (Z.glass === Z.paint) Z.glass = nd(Z.glass, -1);
  if (Z.lens === Z.glass) Z.lens = nd(Z.lens, 1);

  const seg = FACET_SEGS[p.facets] || FACET_SEGS.standard;

  const FLARE_TOP = 1.620;
  const shaftTop = FLARE_TOP + (SHAFT_TOP - FLARE_TOP) * p.tallness;
  const dy = shaftTop - SHAFT_TOP;
  const run = ARC_RUN * p.reach;
  const dip = DIP_RUN * p.reach;
  const headX0 = HEAD_X0 + (run - ARC_RUN) + (dip - DIP_RUN);
  const armY = ARM_Y + dy;

  const st = [
    { x: 0, y: 0.000, r: 0.410 },
    { x: 0, y: 0.055, r: 0.455 },
    { x: 0, y: 0.300, r: 0.455 },
    { x: 0, y: 0.303, r: 0.375 },
    { x: 0, y: 0.700, r: 0.295 },
    { x: 0, y: 1.150, r: 0.222 },
    { x: 0, y: FLARE_TOP, r: 0.168 },
    { x: 0, y: shaftTop, r: 0.112 },
  ];

  for (let i = 1; i <= ARC_SEGS; i++) {
    const t = (i / ARC_SEGS) * Math.PI / 2;
    st.push({
      x: run * (1 - Math.cos(t)),
      y: shaftTop + ARC_RISE * Math.sin(t),
      r: 0.112 + (0.104 - 0.112) * (i / ARC_SEGS),
    });
  }

  st.push({ x: run + dip, y: armY, r: 0.102 });
  st.push({ x: headX0 + RIDGE_U, y: armY, r: 0.102 });

  const { pos: tubePos, rings } = sweepTube(st, seg);
  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  add(posGeo(tubePos), Z.paint);

  const caps = [];
  face(caps, rings[0], [0, -1, 0]);

  face(caps, rings[rings.length - 1], [1, 0, 0]);
  add(posGeo(caps), Z.paint);

  const R = {};
  for (const r of RINGS) R[r.key] = headRing(r, headX0, dy);

  const shell = [];
  face(shell, R.TOP, [0, 1, 0]);
  loftBand(shell, R.TOP, R.FL_T);
  loftBand(shell, R.FL_T, R.FL_B);
  loftBand(shell, R.FL_B, R.RIM);
  add(posGeo(shell), Z.paint);

  const skirt = [];
  loftBand(skirt, R.RIM, R.SKIRT);
  add(posGeo(skirt), Z.glass);

  const lensG = [];
  loftBand(lensG, R.SKIRT, R.LENS);
  face(lensG, R.LENS, [0, -1, 0]);
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
  lens:  { color: '#ffcf87', describe: 'warm sodium lamp behind the refractor panel' },
  glass: { color: '#c98f45', intensity: 0.55, describe: 'diffuser sides leaking amber' },
};

export default createAsset;

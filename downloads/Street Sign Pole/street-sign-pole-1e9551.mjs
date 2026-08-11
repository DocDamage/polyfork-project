/*
 * Street Sign Pole
 * https://polyfork.dev/asset/street-sign-pole-1e9551
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './street-sign-pole-1e9551.mjs';
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
 *   colorway     choice  'municipal-green' 'municipal-green' | 'gotham-black' | 'brooklyn-blue' | 'historic-brown'
 *   iron         color   '#322d2c'      any hex or THREE.Color
 *   blade        color   '#3d6b52'      any hex or THREE.Color
 *   trim         color   '#cfc6b9'      any hex or THREE.Color
 *   ink          color   '#211f1d'      any hex or THREE.Color
 *   tallness     range   1              0.85 to 1.15
 *   bladeLength  range   1              0.74 to 1.32
 *   finial       choice  'ball'         'ball' | 'acorn' | 'cap'
 *
 * Every option is described in full at https://polyfork.dev/cdn/street-sign-pole-1e9551-params.json
 *
 * SPECS  353 triangles, 1 material, 1.34 x 3 x 1.24 m (real-world scale).
 *        detach: one-way-sign
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const BASE = {
  iron:  0x322d2c,
  blade: 0x3d6b52,
  trim:  0xcfc6b9,
  ink:   0x211f1d,
};

const COLORWAYS = {
  'municipal-green': {},
  'gotham-black':    { iron: 0x211f1d, trim: 0xc1b0a1, ink: 0x322d2c },
  'brooklyn-blue':   { iron: 0x322d2c, blade: 0x45525f },
  'historic-brown':  { iron: 0x463b37, blade: 0x564e4a, trim: 0xc1b0a1 },
};

export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'municipal-green', label: 'Colorway',
    options: ['municipal-green', 'gotham-black', 'brooklyn-blue', 'historic-brown'],
    describe: 'curated kit-coherent scheme; sets the iron, blade, trim and ink tones '
      + 'together. municipal-green is the reference: near-black iron under green name '
      + 'blades. gotham-black drops the post to the kit\'s deepest black with warmer '
      + 'sheet steel. brooklyn-blue swaps the blades to the kit\'s slate blue for a '
      + 'borough that signs in blue. historic-brown is a landmark-district pole: warm '
      + 'brown iron and brown name blades.',
  },
  iron: {
    type: 'color', default: 0x322d2c, label: 'Iron',
    describe: 'albedo of the entire cast-iron post — plinth, splayed foot, both collars, '
      + 'the straight shaft, the stem and the ball finial. Roughly 60% of the asset and '
      + 'the colour the pole is recognised by. Keep it dark: a pale post stops reading '
      + 'as iron and the green blades lose their contrast.',
  },
  blade: {
    type: 'color', default: 0x3d6b52, label: 'Name blade',
    describe: 'albedo of the two recessed panels inside the street-name blades. Green is '
      + 'the default because that is what a street NAME blade is; the kit\'s slate blue '
      + 'and brown are the only other real-world options. Must stay clearly darker than '
      + 'the pale frame or the recess stops reading.',
  },
  trim: {
    type: 'color', default: 0xcfc6b9, label: 'Sheet trim',
    describe: 'albedo of every pale pressed-steel part: the blade frame rails and end '
      + 'caps, the one-way plate\'s rim, back and white field, and the bracket. Keep it '
      + 'near-white — it is the only bright value on the asset and it is what makes the '
      + 'blades legible against a dark street.',
  },
  ink: {
    type: 'color', default: 0x211f1d, label: 'Sign ink',
    describe: 'albedo of the one-way sign\'s printed graphics — the border band around '
      + 'its face and the arrow itself. Near-black by default; anything lighter than the '
      + 'iron makes the arrow disappear at thumbnail size.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.85, max: 1.15, label: 'Post height',
    affects: 'geometry',
    describe: 'stretches ONLY the bare shaft between the foot collar and the neck; the '
      + 'foot, finial, blades and one-way sign keep their size and ride up together. '
      + 'Total height runs 2.71 m (a squat side-street pole) to 3.29 m (a wide-avenue '
      + 'pole that clears a bus roof).',
  },
  bladeLength: {
    type: 'range', default: 1.0, min: 0.74, max: 1.32, label: 'Blade length',
    affects: 'geometry',
    describe: 'scales both name blades together. At 0.74 they are stubby 0.75 m plates '
      + 'for a short street name; at 1.32 they are 1.35 m boards that overhang most of '
      + 'a kerb lane. Changes the widest thing in the silhouette, so it is obvious from '
      + 'the front as well as the hero.',
  },
  finial: {
    type: 'choice', default: 'ball', label: 'Finial',
    options: ['ball', 'acorn', 'cap'], affects: 'geometry',
    describe: 'the shape crowning the post, which is the whole top silhouette. ball is '
      + 'the reference sphere, as wide as it is tall; acorn is a narrower egg drawn up '
      + 'into a real point, for an ornamental district; cap is a squat flat-topped '
      + 'octagonal cap with a proud disc, for a modern municipal pole. All three crown '
      + 'at exactly the same total height, so the knob changes shape and nothing else.',
  },
};

const SEG        = 8;
const POST_R     = 0.092;
const COLLAR_TOP = 0.680;
const SHAFT_TOP  = 2.620;
const TOTAL_H    = 3.000;

const BLADE_L   = 1.020;
const BLADE_HH  = 0.130;
const BLADE_HT  = 0.031;
const PANEL_HH  = 0.097;
const PANEL_HT  = 0.025;
const BLADE_CAP = 0.032;
const BLADE_X0  = 0.030;
const BLADE_Y_HI = 2.600;
const BLADE_Y_LO = 2.310;

const SIGN_HW = 0.290, SIGN_HH = 0.130, SIGN_T = 0.045;
const SIGN_Y  = 1.980;
const SIGN_Z0 = 0.115;

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

function boxFaces(out, min, max, skip = '') {
  const [x0, y0, z0] = min, [x1, y1, z1] = max;
  const s = ` ${skip} `;
  const has = k => !s.includes(` ${k} `);
  if (has('px')) face(out, [[x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0]], [1, 0, 0]);
  if (has('nx')) face(out, [[x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0]], [-1, 0, 0]);
  if (has('py')) face(out, [[x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1]], [0, 1, 0]);
  if (has('ny')) face(out, [[x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1]], [0, -1, 0]);
  if (has('pz')) face(out, [[x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]], [0, 0, 1]);
  if (has('nz')) face(out, [[x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0]], [0, 0, -1]);
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

function nameBlade(out, L, yaw) {
  const x1 = BLADE_X0 + L;
  const xc = x1 - BLADE_CAP;

  boxFaces(out.trim, [BLADE_X0, PANEL_HH, -BLADE_HT], [xc, BLADE_HH, BLADE_HT], 'nx px');
  boxFaces(out.trim, [BLADE_X0, -BLADE_HH, -BLADE_HT], [xc, -PANEL_HH, BLADE_HT], 'nx px');

  boxFaces(out.trim, [xc, -BLADE_HH, -BLADE_HT], [x1, BLADE_HH, BLADE_HT], '');

  boxFaces(out.blade, [BLADE_X0, -PANEL_HH, -PANEL_HT], [xc, PANEL_HH, PANEL_HT],
    'nx px py ny');
  return yaw;
}

function signFace(out, z) {
  const A = SIGN_HW, B = SIGN_HH;
  const bw = 0.028;
  const ax = A - bw, ay = B - bw;
  const hy = 0.062;
  const sy = 0.024;
  const sx = 0.035;
  const tip = 0.170, tail = -0.170;
  const q = (x0, y0, x1, y1, list) =>
    face(list, [[x0, y0, z], [x1, y0, z], [x1, y1, z], [x0, y1, z]], [0, 0, 1]);

  q(-A, ay, A, B, out.ink);  q(-A, -B, A, -ay, out.ink);
  q(-A, -ay, -ax, ay, out.ink);  q(ax, -ay, A, ay, out.ink);

  q(-ax, hy, ax, ay, out.trim);  q(-ax, -ay, ax, -hy, out.trim);
  q(-ax, -hy, tail, hy, out.trim);  q(tip, -hy, ax, hy, out.trim);

  q(tail, -sy, sx, sy, out.ink);
  q(tail, sy, sx, hy, out.trim);  q(tail, -hy, sx, -sy, out.trim);
  face(out.ink, [[sx, -hy, z], [tip, 0, z], [sx, hy, z]], [0, 0, 1]);
  face(out.trim, [[sx, hy, z], [tip, 0, z], [tip, hy, z]], [0, 0, 1]);
  face(out.trim, [[sx, -hy, z], [tip, -hy, z], [tip, 0, z]], [0, 0, 1]);
}

const nd = (hex, k) => (hex & 0xffff00) | Math.max(0, Math.min(255, (hex & 0xff) + k));

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  Object.assign(p, userParams);

  const C = { ...BASE, ...(COLORWAYS[p.colorway] || {}) };
  for (const k of ['iron', 'blade', 'trim', 'ink']) {
    if (userParams[k] !== undefined) C[k] = userParams[k];
  }
  const Z = { iron: C.iron, blade: C.blade, trim: C.trim, ink: C.ink };
  if (Z.blade === Z.iron) Z.blade = nd(Z.blade, 1);
  if (Z.ink === Z.iron) Z.ink = nd(Z.ink, -1);
  if (Z.trim === Z.blade) Z.trim = nd(Z.trim, 1);

  const dy = (SHAFT_TOP - COLLAR_TOP) * (p.tallness - 1);
  const shaftTop = SHAFT_TOP + dy;
  const bladeL = BLADE_L * p.bladeLength;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });
  const bucket = { iron: [], blade: [], trim: [], ink: [] };

  const st = [
    { x: 0, y: 0.000, r: 0.176 },
    { x: 0, y: 0.028, r: 0.202 },
    { x: 0, y: 0.130, r: 0.202 },
    { x: 0, y: 0.134, r: 0.150 },
    { x: 0, y: 0.600, r: 0.100 },
    { x: 0, y: 0.640, r: 0.114 },
    { x: 0, y: COLLAR_TOP, r: POST_R },
    { x: 0, y: shaftTop, r: POST_R },
    { x: 0, y: shaftTop + 0.060, r: 0.110 },
    { x: 0, y: shaftTop + 0.100, r: 0.072 },
    { x: 0, y: shaftTop + 0.180, r: 0.072 },
  ];
  const { pos: tubePos, rings } = sweepTube(st, SEG);
  bucket.iron.push(...tubePos);
  face(bucket.iron, rings[0], [0, -1, 0]);

  const crown = TOTAL_H + dy;
  if (p.finial === 'ball') {

    const g = new THREE.SphereGeometry(0.120, 10, 5).translate(0, crown - 0.120, 0);
    add(g, Z.iron);
  } else if (p.finial === 'acorn') {

    const g = new THREE.SphereGeometry(0.100, 10, 5);
    g.scale(1, 1.30, 1);
    g.translate(0, crown - 0.170, 0);

    const tip = new THREE.CylinderGeometry(0, 0.075, 0.100, SEG, 1, true)
      .rotateY(Math.PI / SEG).translate(0, crown - 0.050, 0);
    add(g, Z.iron); add(tip, Z.iron);
  } else {
    const body = new THREE.CylinderGeometry(0.115, 0.145, 0.160, SEG)
      .rotateY(Math.PI / SEG).translate(0, crown - 0.140, 0);
    const plate = new THREE.CylinderGeometry(0.135, 0.135, 0.060, SEG)
      .rotateY(Math.PI / SEG).translate(0, crown - 0.030, 0);
    add(body, Z.iron); add(plate, Z.iron);
  }

  for (const [y, yaw] of [[BLADE_Y_HI, 0], [BLADE_Y_LO, -Math.PI / 2]]) {
    const b = { trim: [], blade: [] };
    nameBlade(b, bladeL, yaw);
    for (const key of ['trim', 'blade']) {
      const g = posGeo(b[key]);
      g.rotateY(yaw);
      g.translate(0, y + dy, 0);
      add(g, Z[key]);
    }
  }

  const sg = { trim: [], ink: [] };

  boxFaces(sg.trim, [-0.042, -0.070, 0.040], [0.042, 0.070, SIGN_Z0 + 0.003], 'pz nz');

  boxFaces(sg.trim, [-SIGN_HW, -SIGN_HH, SIGN_Z0], [SIGN_HW, SIGN_HH, SIGN_Z0 + SIGN_T],
    'pz');
  signFace(sg, SIGN_Z0 + SIGN_T);

  const signParts = [];
  for (const key of ['trim', 'ink']) {
    signParts.push(prep(posGeo(sg[key]).translate(0, SIGN_Y + dy, 0), Z[key]));
  }
  const signGeo = mergeGeometries(signParts);
  signGeo.computeVertexNormals();

  for (const key of ['iron', 'blade', 'trim', 'ink']) {
    if (bucket[key].length) add(posGeo(bucket[key]), Z[key]);
  }
  const merged = mergeGeometries(parts.map(q => prep(q.g, q.c)));
  merged.computeVertexNormals();

  const probe = mergeGeometries([merged.clone(), signGeo.clone()]);
  probe.computeBoundingBox();
  const bb = probe.boundingBox;
  const ox = -(bb.min.x + bb.max.x) / 2, oy = -bb.min.y, oz = -(bb.min.z + bb.max.z) / 2;
  merged.translate(ox, oy, oz);
  signGeo.translate(ox, oy, oz);

  const body = new THREE.Mesh(merged, MAT);
  body.name = 'sign-pole-body';
  const sign = new THREE.Mesh(signGeo, MAT);
  sign.name = 'one-way-plate';

  const signGroup = new THREE.Group();
  signGroup.name = 'one-way-sign';
  signGroup.add(sign);

  const g = new THREE.Group();
  g.name = 'street-sign-pole';
  g.add(body);
  g.add(signGroup);
  return g;
}

export const rig = {};

export const detach = ['one-way-sign'];

export const night = {};

export default createAsset;

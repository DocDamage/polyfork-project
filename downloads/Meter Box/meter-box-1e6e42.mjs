/*
 * Meter Box
 * https://polyfork.dev/asset/meter-box-1e6e42
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './meter-box-1e6e42.mjs';
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
 *   colorway    choice  'grey-steel'   'grey-steel' | 'moss-green' | 'cream-enamel' | 'rust-brown' | 'charcoal'
 *   body        color   '#6B7278'      any hex or THREE.Color
 *   door        color   '#A9AFB4'      any hex or THREE.Color
 *   cap         color   '#C7CBCC'      any hex or THREE.Color
 *   bezel       color   '#E4E2DC'      any hex or THREE.Color
 *   dial        color   '#D9CFBC'      any hex or THREE.Color
 *   hardware    color   '#4E5459'      any hex or THREE.Color
 *   readout     color   '#2E3134'      any hex or THREE.Color
 *   height      range   0.7            0.62 to 1.05
 *   dialFacets  range   12             6 to 16
 *   pipeStub    toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/meter-box-1e6e42-params.json
 *
 * SPECS  410 triangles, 1 material, 0.54 x 0.7 x 0.34 m (real-world scale).
 * PARTS  animate: door
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {

  'grey-steel':   { body: '#6B7278', door: '#A9AFB4', cap: '#C7CBCC', bezel: '#E4E2DC', dial: '#D9CFBC', hardware: '#4E5459', readout: '#2E3134' },
  'moss-green':   { body: '#2F6B4F', door: '#3F8A5E', cap: '#6FA860', bezel: '#E4E2DC', dial: '#F2EFE7', hardware: '#4E5459', readout: '#1B1D20' },
  'cream-enamel': { body: '#D8D2C4', door: '#F2EFE7', cap: '#E4E2DC', bezel: '#C7CBCC', dial: '#D9CFBC', hardware: '#6B7278', readout: '#2E3134' },
  'rust-brown':   { body: '#7E4B33', door: '#B9A88C', cap: '#D8D2C4', bezel: '#F2EFE7', dial: '#E4E2DC', hardware: '#42352A', readout: '#1B1D20' },
  'charcoal':     { body: '#2E3134', door: '#6B7278', cap: '#8A9197', bezel: '#F2EFE7', dial: '#E4E2DC', hardware: '#A9AFB4', readout: '#1B1D20' },
};
const COLOR_KEYS = ['body', 'door', 'cap', 'bezel', 'dial', 'hardware', 'readout'];

const DEF = { colorway: 'grey-steel', height: 0.70, dialFacets: 12, pipeStub: true };

const HW = 0.250;
const HD = 0.125;
const CH = 0.018;
const FOOT = 0.010;

const CAP_H = 0.075, CAP_OS = 0.018;
const CAP_BEV = 0.016, CAP_CHAM = 0.012;
const SOFFIT = 0.012;

const M_SIDE = 0.024, M_TOP = 0.032, M_BOT = 0.026;
const DOOR_P = 0.011, DOOR_CH = 0.005;
const Z_FRONT = HD;
const Z_DOOR = HD + DOOR_P;

const DIAL_DROP = 0.235;
const R_OUT = 0.118, R_IN = 0.098, R_FACE = 0.092;
const Z_DRUM0 = Z_DOOR - 0.004;
const Z_BEZ = 0.178, Z_FACE = 0.160;

const DRUM_CH = 0.007;

const REG_W = 0.082, REG_H = 0.026, REG_DY = -0.044;
const REG_D = 0.006, REG_G = 0.004;
const REG_STEP = 0.007, REG_STEP_D = 0.002;

const NDL_A = (152 * Math.PI) / 180;
const NDL_R0 = 0.008, NDL_R1 = 0.072, NDL_W0 = 0.009, NDL_W1 = 0.004;
const NDL_Z0 = 0.158, NDL_Z1 = 0.165;
const HUB_R = 0.013, HUB_SEG = 8, HUB_Z0 = 0.156, HUB_Z1 = 0.167;

const LATCH_X = -0.168, LATCH_DROP = 0.092;
const LATCH_W = 0.028, LATCH_H = 0.066, LATCH_Z1 = 0.153;

const HINGE_X = 0.234, HINGE_R = 0.013, HINGE_SEG = 6;
const HINGE_H = 0.040, HINGE_Z = 0.132, HINGE_INSET = 0.100;

const PIPE_Y = 0.150;
const COL_R = 0.036, COL_SEG = 6, COL_Z0 = 0.132, COL_Z1 = 0.158;
const STUB_R = 0.019, STUB_SEG = 8, STUB_Z0 = 0.152, STUB_Z1 = 0.192;
const NUT_R = 0.028, NUT_SEG = 6, NUT_Z1 = 0.212;

const CAV_Z = Z_FRONT - 0.090;
const MTR_W = 0.170, MTR_H = 0.140, MTR_D = 0.050;
const DSP_W = 0.090, DSP_H = 0.038;

const VENT_W = 0.130, VENT_H = 0.016, VENT_PITCH = 0.032;
const VENT_D = 0.008, VENT_G = 0.005;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
const crs = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
const dot = (a, b) => a[0] * b[0] + a[1] * b[1] + a[2] * b[2];

function triN(out, a, b, c, want) {
  if (dot(crs(sub(b, a), sub(c, a)), want) < 0) tri(out, c, b, a); else tri(out, a, b, c);
}
function quadN(out, a, b, c, d, want) {
  if (dot(crs(sub(b, a), sub(c, a)), want) < 0) quad(out, d, c, b, a); else quad(out, a, b, c, d);
}

function padBox(out, x0, x1, y0, y1, z0, z1) {
  quadN(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
  quadN(out, [x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0], [1, 0, 0]);
  quadN(out, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0]);
  quadN(out, [x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1], [0, 1, 0]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1], [0, -1, 0]);
}

function faceHoles(out, map, contour, holes, w) {
  const c2 = contour.map(q => new THREE.Vector2(q[0], q[1]));
  const h2 = holes.map(h => h.map(q => new THREE.Vector2(q[0], q[1])));
  const faces = THREE.ShapeUtils.triangulateShape(c2, h2);
  const all = c2.concat(...h2);
  for (const f of faces) {
    const A = all[f[0]], B = all[f[1]], D = all[f[2]];
    const area = (B.x - A.x) * (D.y - A.y) - (B.y - A.y) * (D.x - A.x);
    const t = area >= 0 ? [A, B, D] : [A, D, B];
    tri(out, map(t[0].x, t[0].y, w), map(t[1].x, t[1].y, w), map(t[2].x, t[2].y, w));
  }
  return out;
}

const FRONT = (z) => (u, v, w) => [u, v, z + w];
const triangulateXY = (contour, holes, z) => faceHoles([], FRONT(z), contour, holes, 0);
const rectXY = (x0, y0, x1, y1) => [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];
const ringXY = (n, r, cx, cy) => Array.from({ length: n }, (_, i) => {
  const a = (i / n + 0.5 / n) * Math.PI * 2;
  return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
});

function recessRect(out, z, u0, v0, u1, v1, g, d) {
  const P = (u, v, w) => [u, v, z + w];
  quadN(out, P(u0 - g, v0 - g, 0), P(u0, v0, -d), P(u0, v1, -d), P(u0 - g, v1 + g, 0), [1, 0, 0]);
  quadN(out, P(u1 + g, v0 - g, 0), P(u1, v0, -d), P(u1, v1, -d), P(u1 + g, v1 + g, 0), [-1, 0, 0]);
  quadN(out, P(u0 - g, v0 - g, 0), P(u1 + g, v0 - g, 0), P(u1, v0, -d), P(u0, v0, -d), [0, 1, 0]);
  quadN(out, P(u0 - g, v1 + g, 0), P(u1 + g, v1 + g, 0), P(u1, v1, -d), P(u0, v1, -d), [0, -1, 0]);
}

const outline = (hw, hdF, hdB, c) => ([
  [hw, -hdB], [hw, hdF - c], [hw - c, hdF],
  [-hw + c, hdF], [-hw, hdF - c], [-hw, -hdB],
]);

function skirt(out, pb, pt, y0, y1, skip = []) {
  for (let i = 0; i < pb.length; i++) {
    if (skip.includes(i)) continue;
    const j = (i + 1) % pb.length;
    const dx = pb[j][0] - pb[i][0], dz = pb[j][1] - pb[i][1];
    quadN(out,
      [pb[i][0], y0, pb[i][1]], [pb[j][0], y0, pb[j][1]],
      [pt[j][0], y1, pt[j][1]], [pt[i][0], y1, pt[i][1]], [dz, 0, -dx]);
  }
}

function capY(out, p, y, up) {
  for (let i = 1; i < p.length - 1; i++) {
    triN(out, [p[0][0], y, p[0][1]], [p[i][0], y, p[i][1]], [p[i + 1][0], y, p[i + 1][1]],
      [0, up ? 1 : -1, 0]);
  }
}

function ringY(out, pOut, pIn, y, up) {
  for (let i = 0; i < pOut.length; i++) {
    const j = (i + 1) % pOut.length;
    quadN(out, [pOut[i][0], y, pOut[i][1]], [pOut[j][0], y, pOut[j][1]],
      [pIn[j][0], y, pIn[j][1]], [pIn[i][0], y, pIn[i][1]], [0, up ? 1 : -1, 0]);
  }
}

const ringCenter = (ring) => {
  let x = 0, y = 0;
  for (const q of ring) { x += q[0]; y += q[1]; }
  return [x / ring.length, y / ring.length];
};
function barrelZ(out, ring, z0, z1, outward = true) {
  const n = ring.length, [cx, cy] = ringCenter(ring);
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const mx = (ring[i][0] + ring[j][0]) / 2 - cx, my = (ring[i][1] + ring[j][1]) / 2 - cy;
    const s = outward ? 1 : -1;
    quadN(out, [ring[i][0], ring[i][1], z0], [ring[j][0], ring[j][1], z0],
      [ring[j][0], ring[j][1], z1], [ring[i][0], ring[i][1], z1], [s * mx, s * my, 0]);
  }
}

function chamferZ(out, rBack, rFront, zBack, zFront) {
  const n = rBack.length, [cx, cy] = ringCenter(rBack);
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const mx = (rBack[i][0] + rBack[j][0]) / 2 - cx, my = (rBack[i][1] + rBack[j][1]) / 2 - cy;
    quadN(out, [rBack[i][0], rBack[i][1], zBack], [rBack[j][0], rBack[j][1], zBack],
      [rFront[j][0], rFront[j][1], zFront], [rFront[i][0], rFront[i][1], zFront], [mx, my, 1]);
  }
}

function annulusZ(out, rOut, rIn, z, front = true) {
  const n = rOut.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    quadN(out, [rOut[i][0], rOut[i][1], z], [rOut[j][0], rOut[j][1], z],
      [rIn[j][0], rIn[j][1], z], [rIn[i][0], rIn[i][1], z], [0, 0, front ? 1 : -1]);
  }
}

function coneZ(out, rNear, rFar, zNear, zFar) {
  const n = rNear.length, [cx, cy] = ringCenter(rNear);
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const mx = (rNear[i][0] + rNear[j][0]) / 2 - cx, my = (rNear[i][1] + rNear[j][1]) / 2 - cy;
    quadN(out, [rNear[i][0], rNear[i][1], zNear], [rNear[j][0], rNear[j][1], zNear],
      [rFar[j][0], rFar[j][1], zFar], [rFar[i][0], rFar[i][1], zFar], [-mx, -my, 0]);
  }
}
function capZ(out, ring, z, front = true) {
  for (let i = 1; i < ring.length - 1; i++) {
    triN(out, [ring[0][0], ring[0][1], z], [ring[i][0], ring[i][1], z],
      [ring[i + 1][0], ring[i + 1][1], z], [0, 0, front ? 1 : -1]);
  }
}

function prismY(out, ring, y0, y1, zMin = -Infinity) {
  const n = ring.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const mx = (ring[i][0] + ring[j][0]) / 2, mz = (ring[i][1] + ring[j][1]) / 2;
    if (mz < zMin) continue;
    quadN(out, [ring[i][0], y0, ring[i][1]], [ring[j][0], y0, ring[j][1]],
      [ring[j][0], y1, ring[j][1]], [ring[i][0], y1, ring[i][1]], [mx - HINGE_X, 0, mz - HINGE_Z]);
  }
  capY(out, ring, y1, true);
  capY(out, ring, y0, false);
}

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {};
  for (const k of COLOR_KEYS) C[k] = p[k] !== undefined ? p[k] : cw[k];

  const H = clamp(num(p.height, DEF.height), 0.62, 1.05);
  const nFacet = Math.round(clamp(num(p.dialFacets, DEF.dialFacets), 6, 16));
  const hasPipe = p.pipeStub !== undefined ? !!p.pipeStub : DEF.pipeStub;

  const Z = {}, D = {};
  for (const k of COLOR_KEYS) { Z[k] = []; D[k] = []; }

  const capY0 = H - CAP_H;
  const ay0 = M_BOT, ay1 = capY0 - M_TOP;
  const ax0 = -HW + M_SIDE, ax1 = HW - M_SIDE;
  const dialY = capY0 - DIAL_DROP;

  const vf0 = PIPE_Y + COL_R + 0.010, vf1 = dialY - R_OUT - 0.010;
  const nVent = Math.max(0, Math.min(10, Math.floor((vf1 - vf0) / VENT_PITCH)));
  const vents = [];
  {
    const span = nVent * VENT_PITCH;
    const y0 = (vf0 + vf1) / 2 - span / 2 + (VENT_PITCH - VENT_H) / 2;
    for (let i = 0; i < nVent; i++) {
      const y = y0 + i * VENT_PITCH;
      vents.push([-VENT_W / 2, y, VENT_W / 2, y + VENT_H]);
    }
  }

  const bodyLoop = outline(HW, HD, HD, CH);
  const footLoop = outline(HW - FOOT, HD - FOOT, HD - FOOT, CH);
  capY(Z.body, footLoop, 0, false);
  skirt(Z.body, footLoop, bodyLoop, 0, FOOT);
  skirt(Z.body, bodyLoop, bodyLoop, FOOT, capY0, [2]);

  faceHoles(Z.body, FRONT(Z_FRONT), rectXY(-HW + CH, FOOT, HW - CH, capY0),
    [rectXY(ax0, ay0, ax1, ay1)], 0);

  {
    const lb = outline(HW + CAP_OS, HD + CAP_OS, HD, CH);
    const lt = outline(HW + CAP_OS - CAP_CHAM, HD + CAP_OS - CAP_CHAM, HD, CH);

    const soffitY = capY0 - SOFFIT;
    for (let i = 0; i < lb.length; i++) {
      if (i === 5) continue;
      const j = (i + 1) % lb.length;
      const dx = lb[j][0] - lb[i][0], dz = lb[j][1] - lb[i][1];
      quadN(Z.cap,
        [bodyLoop[i][0], capY0, bodyLoop[i][1]], [bodyLoop[j][0], capY0, bodyLoop[j][1]],
        [lb[j][0], soffitY, lb[j][1]], [lb[i][0], soffitY, lb[i][1]],
        [dz, -3 * Math.hypot(dx, dz), -dx]);
    }
    for (const s of [-1, 1]) {
      triN(Z.cap, [s * HW, capY0, -HD], [s * (HW + CAP_OS), soffitY, -HD],
        [s * (HW + CAP_OS), capY0, -HD], [0, 0, -1]);
    }
    skirt(Z.cap, lb, lb, soffitY, H - CAP_BEV, [5]);
    quadN(Z.cap, [lb[5][0], capY0, -HD], [lb[0][0], capY0, -HD],
      [lb[0][0], H - CAP_BEV, -HD], [lb[5][0], H - CAP_BEV, -HD], [0, 0, -1]);
    skirt(Z.cap, lb, lt, H - CAP_BEV, H);
    capY(Z.cap, lt, H, true);
  }

  {
    quadN(Z.body, [ax0, ay0, Z_FRONT], [ax0, ay1, Z_FRONT], [ax0, ay1, CAV_Z], [ax0, ay0, CAV_Z], [1, 0, 0]);
    quadN(Z.body, [ax1, ay0, Z_FRONT], [ax1, ay1, Z_FRONT], [ax1, ay1, CAV_Z], [ax1, ay0, CAV_Z], [-1, 0, 0]);
    quadN(Z.body, [ax0, ay0, Z_FRONT], [ax1, ay0, Z_FRONT], [ax1, ay0, CAV_Z], [ax0, ay0, CAV_Z], [0, 1, 0]);
    quadN(Z.body, [ax0, ay1, Z_FRONT], [ax1, ay1, Z_FRONT], [ax1, ay1, CAV_Z], [ax0, ay1, CAV_Z], [0, -1, 0]);
    Z.body.push(...triangulateXY(rectXY(ax0, ay0, ax1, ay1), [], CAV_Z));

    padBox(Z.bezel, -MTR_W / 2, MTR_W / 2, dialY - MTR_H / 2, dialY + MTR_H / 2,
      CAV_Z - 0.002, CAV_Z + MTR_D);
    padBox(Z.readout, -DSP_W / 2, DSP_W / 2, dialY - DSP_H / 2, dialY + DSP_H / 2,
      CAV_Z + MTR_D - 0.002, CAV_Z + MTR_D + 0.004);
  }

  {
    const fx0 = ax0 + DOOR_CH, fx1 = ax1 - DOOR_CH;
    const fy0 = ay0 + DOOR_CH, fy1 = ay1 - DOOR_CH;
    quadN(D.door, [ax0, ay0, Z_FRONT], [ax1, ay0, Z_FRONT], [fx1, fy0, Z_DOOR], [fx0, fy0, Z_DOOR], [0, -1, 0]);
    quadN(D.door, [ax0, ay1, Z_FRONT], [ax1, ay1, Z_FRONT], [fx1, fy1, Z_DOOR], [fx0, fy1, Z_DOOR], [0, 1, 0]);
    quadN(D.door, [ax0, ay0, Z_FRONT], [ax0, ay1, Z_FRONT], [fx0, fy1, Z_DOOR], [fx0, fy0, Z_DOOR], [-1, 0, 0]);
    quadN(D.door, [ax1, ay0, Z_FRONT], [ax1, ay1, Z_FRONT], [fx1, fy1, Z_DOOR], [fx1, fy0, Z_DOOR], [1, 0, 0]);
    const holes = vents.map(v => rectXY(v[0] - VENT_G, v[1] - VENT_G, v[2] + VENT_G, v[3] + VENT_G));
    faceHoles(D.door, FRONT(Z_DOOR), rectXY(fx0, fy0, fx1, fy1), holes, 0);

    quadN(D.body, [ax0, ay0, Z_FRONT], [ax1, ay0, Z_FRONT], [ax1, ay1, Z_FRONT], [ax0, ay1, Z_FRONT], [0, 0, -1]);
  }

  for (const v of vents) {
    recessRect(D.readout, Z_DOOR, v[0], v[1], v[2], v[3], VENT_G, VENT_D);
    D.readout.push(...triangulateXY(rectXY(v[0], v[1], v[2], v[3]), [], Z_DOOR - VENT_D));
  }

  {
    const rOut = ringXY(nFacet, R_OUT, 0, dialY);
    const rChm = ringXY(nFacet, R_OUT - DRUM_CH, 0, dialY);
    const rIn = ringXY(nFacet, R_IN, 0, dialY);
    const rFace = ringXY(nFacet, R_FACE, 0, dialY);
    barrelZ(D.bezel, rOut, Z_DRUM0, Z_BEZ - DRUM_CH);
    chamferZ(D.bezel, rOut, rChm, Z_BEZ - DRUM_CH, Z_BEZ);
    annulusZ(D.bezel, rChm, rIn, Z_BEZ, true);
    coneZ(D.bezel, rIn, rFace, Z_BEZ, Z_FACE);

    const rx0 = -REG_W / 2, rx1 = REG_W / 2;
    const ry0 = dialY + REG_DY - REG_H / 2, ry1 = ry0 + REG_H;
    const sx0 = rx0 - REG_STEP, sx1 = rx1 + REG_STEP;
    const sy0 = ry0 - REG_STEP, sy1 = ry1 + REG_STEP;
    D.dial.push(...triangulateXY(rFace,
      [rectXY(sx0 - REG_G, sy0 - REG_G, sx1 + REG_G, sy1 + REG_G)], Z_FACE));
    recessRect(D.bezel, Z_FACE, sx0, sy0, sx1, sy1, REG_G, REG_STEP_D);
    D.bezel.push(...faceHoles([], FRONT(Z_FACE - REG_STEP_D), rectXY(sx0, sy0, sx1, sy1),
      [rectXY(rx0 - REG_G, ry0 - REG_G, rx1 + REG_G, ry1 + REG_G)], 0));
    recessRect(D.readout, Z_FACE - REG_STEP_D, rx0, ry0, rx1, ry1, REG_G, REG_D);
    D.readout.push(...triangulateXY(rectXY(rx0, ry0, rx1, ry1), [], Z_FACE - REG_STEP_D - REG_D));

    {
      const c = Math.cos(NDL_A), s = Math.sin(NDL_A), px = -s, py = c;
      const P = (r, w, z) => [c * r + px * w, dialY + s * r + py * w, z];
      const a0 = P(NDL_R0, -NDL_W0, NDL_Z1), b0 = P(NDL_R0, NDL_W0, NDL_Z1);
      const a1 = P(NDL_R1, -NDL_W1, NDL_Z1), b1 = P(NDL_R1, NDL_W1, NDL_Z1);
      const a0b = P(NDL_R0, -NDL_W0, NDL_Z0), b0b = P(NDL_R0, NDL_W0, NDL_Z0);
      const a1b = P(NDL_R1, -NDL_W1, NDL_Z0), b1b = P(NDL_R1, NDL_W1, NDL_Z0);
      quadN(D.readout, a0, a1, b1, b0, [0, 0, 1]);
      quadN(D.readout, a0, a1, a1b, a0b, [-px, -py, 0]);
      quadN(D.readout, b0, b1, b1b, b0b, [px, py, 0]);
      quadN(D.readout, a1, b1, b1b, a1b, [c, s, 0]);
    }

    const hub = ringXY(HUB_SEG, HUB_R, 0, dialY);
    barrelZ(D.hardware, hub, HUB_Z0, HUB_Z1);
    capZ(D.hardware, hub, HUB_Z1, true);
  }

  {
    const ly = dialY - LATCH_DROP;
    padBox(D.hardware, LATCH_X - LATCH_W / 2, LATCH_X + LATCH_W / 2,
      ly - LATCH_H / 2, ly + LATCH_H / 2, Z_DOOR - 0.004, LATCH_Z1);

    const knuckle = ringXY(HINGE_SEG, HINGE_R, HINGE_X, HINGE_Z);
    for (const y of [ay0 + HINGE_INSET, ay1 - HINGE_INSET]) {
      prismY(Z.hardware, knuckle, y - HINGE_H / 2, y + HINGE_H / 2, HINGE_Z - 0.005);
    }
  }

  if (hasPipe) {
    const col = ringXY(COL_SEG, COL_R, 0, PIPE_Y);
    const stub = ringXY(STUB_SEG, STUB_R, 0, PIPE_Y);
    const nut = ringXY(NUT_SEG, NUT_R, 0, PIPE_Y);
    barrelZ(D.hardware, col, COL_Z0, COL_Z1);
    capZ(D.hardware, col, COL_Z1, true);
    barrelZ(D.hardware, stub, STUB_Z0, STUB_Z1);
    capZ(D.hardware, nut, STUB_Z1, false);
    barrelZ(D.hardware, nut, STUB_Z1, NUT_Z1);
    capZ(D.hardware, nut, NUT_Z1, true);
  }

  const material = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const OZ = -(-HD + (hasPipe ? NUT_Z1 : Z_BEZ)) / 2;

  const g = new THREE.Group();
  g.name = 'meter-box';

  const shell = finish(COLOR_KEYS.map(k => ({ g: posGeo(Z[k]), c: C[k] })), material);
  shell.name = 'cabinet';
  shell.geometry.translate(0, 0, OZ);
  g.add(shell);

  const panel = finish(COLOR_KEYS.map(k => ({ g: posGeo(D[k]), c: C[k] })), material);
  panel.name = 'door-panel';
  panel.geometry.translate(-HINGE_X, 0, -HINGE_Z);
  const door = new THREE.Group();
  door.name = 'door';
  door.position.set(HINGE_X, 0, HINGE_Z + OZ);
  door.add(panel);
  g.add(door);

  return g;
}

const num = (v, d) => (typeof v === 'number' && isFinite(v) ? v : d);
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));

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
function finish(list, material) {
  const merged = mergeGeometries(list.filter(q => q.g.attributes.position.count > 0)
    .map(q => prep(q.g, q.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, material);
}

export const params = {
  colorway: {
    type: 'choice', default: 'grey-steel', label: 'Colorway',
    options: ['grey-steel', 'moss-green', 'cream-enamel', 'rust-brown', 'charcoal'],
    describe: 'Curated kit-palette scheme; sets all seven zone colours at once. grey-steel ' +
      'is the shipped galvanised cabinet of the references. moss-green is the painted ' +
      'utility-green cabinet common on Japanese back-alley walls. cream-enamel is a pale ' +
      'enamelled box for a bright shopfront, with the bezel dropped to grey so the dial ' +
      'still separates. rust-brown is an old sun-baked painted box with dark brown ' +
      'hardware. charcoal inverts the ladder — a dark grey cabinet with LIGHT hardware and ' +
      'a pale dial so the instrument still reads. Every scheme keeps the bezel brighter ' +
      'than the dial face and the readout near-black.',
  },
  body: {
    type: 'color', default: '#6B7278', label: 'Cabinet',
    describe: 'Albedo of the sheet-steel shell: both side walls, the flat mounting back, ' +
      'the chamfered foot, the underside, the frame margin around the door, the interior ' +
      'the door swings open to reveal and the door leaf\'s own reverse face. The dominant ' +
      'tone of the asset. Keep it a clear step DARKER than the door, or the frame reveal ' +
      'stops reading at street distance. One uniform colour on every face — the bright top ' +
      'and dark flanks in the reference renders are lighting, not paint.',
  },
  door: {
    type: 'color', default: '#A9AFB4', label: 'Door',
    describe: 'Albedo of the door plate standing 11 mm proud of the cabinet front, ' +
      'including its chamfered edge. Keep it a clear step LIGHTER than the cabinet: the ' +
      'door is the largest flat surface the hero camera sees and the value step is what ' +
      'separates the plate from its frame at street distance.',
  },
  cap: {
    type: 'color', default: '#C7CBCC', label: 'Cap hood',
    describe: 'Albedo of the lid band across the top of the cabinet — its overhanging ' +
      'underside lip, its four walls and its chamfered top. The lightest of the three ' +
      'painted masses, so the crown reads as a separate pressing rather than fusing into ' +
      'the wall below it.',
  },
  bezel: {
    type: 'color', default: '#E4E2DC', label: 'Dial bezel',
    describe: 'Albedo of the whole dial drum: the faceted barrel standing off the door, ' +
      'the flat ring around the glass and the sloping wall of the 18 mm well. The ' +
      'BRIGHTEST tone on the asset — a light ring around a darker centre is what makes the ' +
      'sunk dial read as a dish; darken it and the drum flattens into the door.',
  },
  dial: {
    type: 'color', default: '#D9CFBC', label: 'Dial face',
    describe: 'Albedo of the dial card at the bottom of the well, the surface the needle ' +
      'and the counter window sit on. A warm off-white a step below the bezel; if it ' +
      'matches the bezel the well loses its shadow line, and if it goes dark the near-' +
      'black needle and counter stop reading.',
  },
  hardware: {
    type: 'color', default: '#4E5459', label: 'Hardware',
    describe: 'Albedo of the unpainted steel fittings: the door latch tab, the two hinge ' +
      'knuckles on the opposite door edge, the hex collar, the pipe stub with its union ' +
      'nut, and the needle hub. Clearly darker than the door so every fitting reads as a ' +
      'separate bolted-on part rather than a bump in the panel.',
  },
  readout: {
    type: 'color', default: '#2E3134', label: 'Readout & vents',
    describe: 'Albedo of the near-black marks and openings only: the needle, the sunken ' +
      'counter window on the dial, and the vent slots recessed into the lower door. Never ' +
      'used on an outward-facing panel — it is the darkest tone and reads as a hole ' +
      'wherever it appears.',
  },
  height: {
    type: 'range', default: 0.70, min: 0.62, max: 1.05, label: 'Cabinet height',
    affects: 'geometry',
    describe: 'Cabinet height in metres. This REBUILDS rather than stretches: the 0.075 m ' +
      'cap hood, the 0.236 m dial drum at its fixed 0.235 m drop below the cap, the latch, ' +
      'the hinge knuckles, the chamfers and the pipe stub at its fixed 0.150 m service ' +
      'height all keep their exact size and position, and the extra length goes into the ' +
      'blank door field between the stub and the dial, which fills with whole vent SLOTS ' +
      'at a constant 0.032 m pitch (no slots below 0.68, 2 at the default 0.70, 3 at 0.75, ' +
      '5 at 0.80, 8 at 0.90, 10 from 1.00 up) — so the triangle count moves with the knob ' +
      '(378 tris at 0.62, 410 at the default, 538 at 1.05). 0.62 is a squat ' +
      'single-meter box; 1.05 is a tall louvered service cabinet. Width and depth never ' +
      'change, so it stays a facade bolt-on inside one 4 m bay at every value.',
  },
  dialFacets: {
    type: 'range', default: 12, min: 6, max: 16, step: 1, label: 'Dial facets',
    affects: 'geometry',
    describe: 'How many flat facets the dial drum, its bezel ring and its well are turned ' +
      'from. 6 is a boldly hexagonal drum that reads as a chunky faceted boss, matching a ' +
      'coarse-poly kit; the default 12 is the smooth-but-visibly-faceted reference dial; ' +
      '16 is a near-round instrument for hero close-ups. Drum diameter, projection and ' +
      'well depth are fixed, so this changes the FORM and the triangle count only. A ' +
      'facet centre always sits at 12 o\'clock, so the needle never straddles an edge.',
  },
  pipeStub: {
    type: 'toggle', default: true, label: 'Pipe stub', affects: 'geometry',
    describe: 'The service connection below the dial: a hex collar flat against the door, ' +
      'a round stub running forward and a wider hex union nut at its tip, 76 mm proud of ' +
      'the door face. On (default) ' +
      'is the reference gas/water meter and sets the delivered depth. Off leaves a clean ' +
      'unbroken door with no socket or scar — an electricity meter cabinet — and the box ' +
      're-centres on the shallower delivered depth. The vent bank and every other fitting ' +
      'stay exactly where they are.',
  },
};

export const presets = COLORWAYS;
export const rig = {

  'door': { axis: 'y', range: [0, 100] },
};
export const detach = [];
export const night = {};
export default createAsset;

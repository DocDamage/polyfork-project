/*
 * Air-Con Unit
 * https://polyfork.dev/asset/air-con-unit-9fadc2
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './air-con-unit-9fadc2.mjs';
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
 *   colorway   choice  'beige'        'beige' | 'grey-steel' | 'cream-white' | 'weathered-tan' | 'charcoal'
 *   casing     color   '#D9CFBC'      any hex or THREE.Color
 *   panel      color   '#E4E2DC'      any hex or THREE.Color
 *   bracket    color   '#6B7278'      any hex or THREE.Color
 *   fan        color   '#4E5459'      any hex or THREE.Color
 *   void       color   '#2E3134'      any hex or THREE.Color
 *   width      range   0.85           0.72 to 1.35
 *   ventSlots  range   2              1 to 4
 *   fanBlades  range   6              4 to 8
 *   pipeBox    toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/air-con-unit-9fadc2-params.json
 *
 * SPECS  480 triangles, 1 material, 0.92 x 0.6 x 0.38 m (real-world scale).
 * PARTS  animate: fan
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'beige':        { casing: '#D9CFBC', panel: '#E4E2DC', bracket: '#6B7278', fan: '#4E5459', void: '#2E3134' },
  'grey-steel':   { casing: '#A9AFB4', panel: '#C7CBCC', bracket: '#4E5459', fan: '#3C4145', void: '#1B1D20' },
  'cream-white':  { casing: '#E4E2DC', panel: '#F2EFE7', bracket: '#8A9197', fan: '#6B7278', void: '#3C4145' },
  'weathered-tan':{ casing: '#B9A88C', panel: '#D8D2C4', bracket: '#63503C', fan: '#4E5459', void: '#2E3134' },
  'charcoal':     { casing: '#4E5459', panel: '#6B7278', bracket: '#2E3134', fan: '#A9AFB4', void: '#1B1D20' },
};
const COLOR_KEYS = ['casing', 'panel', 'bracket', 'fan', 'void'];

const DEF = { colorway: 'beige', width: 0.85, ventSlots: 2, fanBlades: 6, pipeBox: true };

const DEPTH   = 0.35, HD = DEPTH / 2;
const CH      = 0.022;
const CY0     = 0.070, CY1 = 0.548;
const LID_Y1  = 0.600;
const LID_OS  = 0.014;
const LID_BEV = 0.028, LID_CHAM = 0.016;
const FZ      = HD;

const PW = 0.450, PH = 0.410;
const P_LEFT = CH + 0.034;
const RD = 0.020, RG = 0.010;
const PZ = FZ - RD;

const SEG = 14;
const R_MOUTH = 0.190, R_WELL = 0.176;
const Z_LIP = PZ, Z_WELL = PZ - 0.015, Z_FLOOR = PZ - 0.100;

const BAR_W = 0.014;

const BAR_R = 0.182;

const SVC_INSET_Z = 0.045, SVC_INSET_Y = 0.055, SVC_D = 0.014, SVC_G = 0.007;

const SLOT_H = 0.026, SLOT_PITCH = 0.052, SLOT_D = 0.012, SLOT_G = 0.006;
const SLOT_MID = 0.215;
const BANK_PITCH = 0.30, BANK_W = 0.19;

const FOOT_W = 0.120, FOOT_H = 0.032, FOOT_INSET = 0.115;
const RISE_W = 0.070, RISE_D = 0.060, RISE_Y0 = 0.020, RISE_Y1 = 0.078;
const FOOT_FZ0 = 0.075, FOOT_FZ1 = 0.205;
const FOOT_BZ0 = -0.170, FOOT_BZ1 = -0.055;

const BOX_PROUD = 0.055;
const BOX_Y0 = 0.085, BOX_Y1 = 0.300, BOX_Z0 = -0.025, BOX_Z1 = 0.145, BOX_TAPER = 0.012;
const PIPE_R = 0.018, PIPE_SEG = 8, PIPE_Y0 = 0.240, PIPE_Y1 = 0.455, PIPE_Z = 0.095;

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

function boxN(out, x0, x1, y0, y1, z0, z1) {
  quadN(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [0, 0, -1]);
  quadN(out, [x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0], [1, 0, 0]);
  quadN(out, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0]);
  quadN(out, [x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1], [0, 1, 0]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1], [0, -1, 0]);
}

function tubeBoxX(out, x0, x1, y0, y1, z0, z1) {
  quadN(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [0, 0, -1]);
  quadN(out, [x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1], [0, 1, 0]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y0, z1], [x0, y0, z1], [0, -1, 0]);
}
function tubeBoxY(out, x0, x1, y0, y1, z0, z1) {
  quadN(out, [x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1], [0, 0, 1]);
  quadN(out, [x0, y0, z0], [x1, y0, z0], [x1, y1, z0], [x0, y1, z0], [0, 0, -1]);
  quadN(out, [x1, y0, z0], [x1, y0, z1], [x1, y1, z1], [x1, y1, z0], [1, 0, 0]);
  quadN(out, [x0, y0, z0], [x0, y0, z1], [x0, y1, z1], [x0, y1, z0], [-1, 0, 0]);
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
const triangulateXY = (contour, holes, z) =>
  faceHoles([], (u, v, w) => [u, v, z + w], contour, holes, 0);
const rectXY = (x0, y0, x1, y1) => [[x0, y0], [x1, y0], [x1, y1], [x0, y1]];
const ringXY = (n, r, cx, cy) => Array.from({ length: n }, (_, i) => {
  const a = (i / n) * Math.PI * 2;
  return [cx + r * Math.cos(a), cy + r * Math.sin(a)];
});

function recessRect(out, map, u0, v0, u1, v1, g, d) {
  const o = map(0, 0, 0);
  const eu = sub(map(1, 0, 0), o), ev = sub(map(0, 1, 0), o);
  const neg = (a) => [-a[0], -a[1], -a[2]];
  const P = (u, v, w) => map(u, v, w);
  quadN(out, P(u0 - g, v0 - g, 0), P(u0, v0, -d), P(u0, v1, -d), P(u0 - g, v1 + g, 0), eu);
  quadN(out, P(u1 + g, v0 - g, 0), P(u1, v0, -d), P(u1, v1, -d), P(u1 + g, v1 + g, 0), neg(eu));
  quadN(out, P(u0 - g, v0 - g, 0), P(u1 + g, v0 - g, 0), P(u1, v0, -d), P(u0, v0, -d), ev);
  quadN(out, P(u0 - g, v1 + g, 0), P(u1 + g, v1 + g, 0), P(u1, v1, -d), P(u0, v1, -d), neg(ev));
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

export function createAsset(p = {}) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[DEF.colorway];
  const C = {};
  for (const k of COLOR_KEYS) C[k] = p[k] !== undefined ? p[k] : cw[k];

  const W = clamp(num(p.width, DEF.width), 0.72, 1.35);
  const nSlot = Math.round(clamp(num(p.ventSlots, DEF.ventSlots), 1, 4));
  const nBlade = Math.round(clamp(num(p.fanBlades, DEF.fanBlades), 4, 8));
  const hasBox = p.pipeBox !== undefined ? !!p.pipeBox : DEF.pipeBox;

  const HW = W / 2;

  const px0 = -HW + P_LEFT, px1 = px0 + PW;
  const py0 = CY0 + (CY1 - CY0 - PH) / 2, py1 = py0 + PH;
  const pcx = (px0 + px1) / 2, pcy = (py0 + py1) / 2;

  const fx0 = px1 + 0.040, fx1 = HW - CH - 0.024;
  const field = fx1 - fx0;

  const banks = clamp(Math.round(field / BANK_PITCH), 0, 3);
  const bankPitch = banks > 0 ? field / banks : 0;
  const slotW = Math.min(BANK_W, bankPitch - 0.050);

  const minX = -(HW + LID_OS);
  const maxX = Math.max(HW + LID_OS, hasBox ? HW + BOX_PROUD : HW);
  const OX = -(minX + maxX) / 2;
  const OZ = -(-HD + FOOT_FZ1) / 2;

  const FRONT = (u, v, w) => [u, v, FZ + w];
  const LEFT = (u, v, w) => [-HW - w, v, u];

  const Z = { casing: [], panel: [], bracket: [], fan: [], void: [] };

  const caseLoop = outline(HW, HD, HD, CH);
  skirt(Z.casing, caseLoop, caseLoop, CY0, CY1, [2, 4]);
  capY(Z.casing, caseLoop, CY0, false);

  {
    const contour = rectXY(-HW + CH, CY0, HW - CH, CY1);
    const holes = [rectXY(px0 - RG, py0 - RG, px1 + RG, py1 + RG)];
    for (const s of slotRects(banks, fx0, bankPitch, slotW, nSlot)) {
      holes.push(rectXY(s[0] - SLOT_G, s[1] - SLOT_G, s[2] + SLOT_G, s[3] + SLOT_G));
    }
    faceHoles(Z.casing, FRONT, contour, holes, 0);
  }

  {
    const su0 = -HD + SVC_INSET_Z, su1 = HD - CH - SVC_INSET_Z;
    const sv0 = CY0 + SVC_INSET_Y, sv1 = CY1 - SVC_INSET_Y;
    faceHoles(Z.casing, LEFT, rectXY(-HD, CY0, HD - CH, CY1),
      [rectXY(su0 - SVC_G, sv0 - SVC_G, su1 + SVC_G, sv1 + SVC_G)], 0);
    recessRect(Z.panel, LEFT, su0, sv0, su1, sv1, SVC_G, SVC_D);
    faceHoles(Z.panel, LEFT, rectXY(su0, sv0, su1, sv1), [], -SVC_D);
  }

  recessRect(Z.panel, FRONT, px0, py0, px1, py1, RG, RD);
  Z.panel.push(...triangulateXY(rectXY(px0, py0, px1, py1),
    [ringXY(SEG, R_MOUTH, pcx, pcy)], PZ));

  {
    const dz = Z_LIP - Z_WELL, dr = R_MOUTH - R_WELL;
    for (let i = 0; i < SEG; i++) {
      const a0 = (i / SEG) * Math.PI * 2, a1 = ((i + 1) / SEG) * Math.PI * 2;
      const am = (a0 + a1) / 2;
      quadN(Z.panel,
        [pcx + R_MOUTH * Math.cos(a0), pcy + R_MOUTH * Math.sin(a0), Z_LIP],
        [pcx + R_MOUTH * Math.cos(a1), pcy + R_MOUTH * Math.sin(a1), Z_LIP],
        [pcx + R_WELL * Math.cos(a1), pcy + R_WELL * Math.sin(a1), Z_WELL],
        [pcx + R_WELL * Math.cos(a0), pcy + R_WELL * Math.sin(a0), Z_WELL],
        [-dz * Math.cos(am), -dz * Math.sin(am), dr]);
    }
  }

  for (let i = 0; i < SEG; i++) {
    const a0 = (i / SEG) * Math.PI * 2, a1 = ((i + 1) / SEG) * Math.PI * 2;
    const am = (a0 + a1) / 2;
    quadN(Z.void,
      [pcx + R_WELL * Math.cos(a0), pcy + R_WELL * Math.sin(a0), Z_WELL],
      [pcx + R_WELL * Math.cos(a1), pcy + R_WELL * Math.sin(a1), Z_WELL],
      [pcx + R_WELL * Math.cos(a1), pcy + R_WELL * Math.sin(a1), Z_FLOOR],
      [pcx + R_WELL * Math.cos(a0), pcy + R_WELL * Math.sin(a0), Z_FLOOR],
      [-Math.cos(am), -Math.sin(am), 0]);
  }
  Z.void.push(...triangulateXY(ringXY(SEG, R_WELL, pcx, pcy), [], Z_FLOOR));

  tubeBoxX(Z.panel, pcx - BAR_R, pcx + BAR_R, pcy - BAR_W / 2, pcy + BAR_W / 2, PZ - 0.030, PZ - 0.018);
  tubeBoxY(Z.panel, pcx - BAR_W / 2, pcx + BAR_W / 2, pcy - BAR_R, pcy + BAR_R, PZ - 0.044, PZ - 0.032);

  for (const s of slotRects(banks, fx0, bankPitch, slotW, nSlot)) {
    recessRect(Z.void, FRONT, s[0], s[1], s[2], s[3], SLOT_G, SLOT_D);
    Z.void.push(...triangulateXY(rectXY(s[0], s[1], s[2], s[3]), [], FZ - SLOT_D));
  }

  {
    const lb = outline(HW + LID_OS, HD + LID_OS, HD, CH);
    const lt = outline(HW + LID_OS - LID_CHAM, HD + LID_OS - LID_CHAM, HD - LID_CHAM, CH);
    ringY(Z.casing, lb, caseLoop, CY1, false);
    skirt(Z.casing, lb, lb, CY1, LID_Y1 - LID_BEV);
    skirt(Z.casing, lb, lt, LID_Y1 - LID_BEV, LID_Y1);
    capY(Z.casing, lt, LID_Y1, true);
  }

  for (const sx of [-1, 1]) {
    const cx = sx * (HW - FOOT_INSET);
    for (const [z0, z1] of [[FOOT_FZ0, FOOT_FZ1], [FOOT_BZ0, FOOT_BZ1]]) {
      boxN(Z.bracket, cx - FOOT_W / 2, cx + FOOT_W / 2, 0, FOOT_H, z0, z1);
      const rz = (z0 + z1) / 2 + (z0 > 0 ? -0.014 : 0.014);

      tubeBoxY(Z.bracket, cx - RISE_W / 2, cx + RISE_W / 2, RISE_Y0, RISE_Y1,
        rz - RISE_D / 2, rz + RISE_D / 2);
    }
  }

  if (hasBox) {
    const xi = HW - 0.005, xo = HW + BOX_PROUD, t = BOX_TAPER;
    const inner = [[BOX_Z0, BOX_Y0], [BOX_Z1, BOX_Y0], [BOX_Z1, BOX_Y1], [BOX_Z0, BOX_Y1]];
    const outer = [[BOX_Z0 + t, BOX_Y0 + t], [BOX_Z1 - t, BOX_Y0 + t],
                   [BOX_Z1 - t, BOX_Y1 - t], [BOX_Z0 + t, BOX_Y1 - t]];
    for (let i = 0; i < 4; i++) {
      const j = (i + 1) % 4;
      const mz = (inner[i][0] + inner[j][0]) / 2, my = (inner[i][1] + inner[j][1]) / 2;
      quadN(Z.casing,
        [xi, inner[i][1], inner[i][0]], [xi, inner[j][1], inner[j][0]],
        [xo, outer[j][1], outer[j][0]], [xo, outer[i][1], outer[i][0]],
        [0.35, my - (BOX_Y0 + BOX_Y1) / 2, mz - (BOX_Z0 + BOX_Z1) / 2]);
    }
    quadN(Z.casing, [xo, outer[0][1], outer[0][0]], [xo, outer[1][1], outer[1][0]],
      [xo, outer[2][1], outer[2][0]], [xo, outer[3][1], outer[3][0]], [1, 0, 0]);

    const cx = HW - 0.006 + PIPE_R;
    for (let i = 0; i < PIPE_SEG; i++) {
      const a0 = (i / PIPE_SEG) * Math.PI * 2, a1 = ((i + 1) / PIPE_SEG) * Math.PI * 2;
      const am = (a0 + a1) / 2;
      quadN(Z.bracket,
        [cx + PIPE_R * Math.cos(a0), PIPE_Y0, PIPE_Z + PIPE_R * Math.sin(a0)],
        [cx + PIPE_R * Math.cos(a1), PIPE_Y0, PIPE_Z + PIPE_R * Math.sin(a1)],
        [cx + PIPE_R * Math.cos(a1), PIPE_Y1, PIPE_Z + PIPE_R * Math.sin(a1)],
        [cx + PIPE_R * Math.cos(a0), PIPE_Y1, PIPE_Z + PIPE_R * Math.sin(a0)],
        [Math.cos(am), 0, Math.sin(am)]);
    }
    capY(Z.bracket, ringXY(PIPE_SEG, PIPE_R, cx, PIPE_Z), PIPE_Y1, true);
  }

  const material = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });

  const g = new THREE.Group();
  g.name = 'air-con-unit';

  const body = finish(COLOR_KEYS.map(k => ({ g: posGeo(Z[k]), c: C[k] })), material);
  body.name = 'casing';
  body.geometry.translate(OX, 0, OZ);
  g.add(body);

  const F = {};
  for (const k of COLOR_KEYS) F[k] = [];
  buildFan(F, nBlade);
  const fanMesh = finish(COLOR_KEYS.map(k => ({ g: posGeo(F[k]), c: C[k] })), material);
  fanMesh.name = 'fan-mesh';
  fanMesh.geometry.translate(0, 0, OZ);
  const fan = new THREE.Group();
  fan.name = 'fan';
  fan.position.set(pcx + OX, pcy, 0);
  fan.add(fanMesh);
  g.add(fan);

  return g;
}

function slotRects(banks, fx0, pitch, w, n) {
  const out = [];
  const y0 = SLOT_MID - ((n - 1) * SLOT_PITCH + SLOT_H) / 2;
  for (let b = 0; b < banks; b++) {
    const cx = fx0 + pitch * (b + 0.5);
    for (let i = 0; i < n; i++) {
      const y = y0 + i * SLOT_PITCH;
      out.push([cx - w / 2, y, cx + w / 2, y + SLOT_H]);
    }
  }
  return out;
}

const B_R  = [0.048, 0.112, 0.170];
const B_C  = [0.60, 1.00, 0.98];
const B_SW = [0.00, 0.16, 0.34];
const B_TW = [0.005, 0.011, 0.017];
const B_T  = 0.005;
const HUB_R = 0.052, HUB_SEG = 10, HUB_Z0 = 0.055, HUB_Z1 = 0.095;

function buildFan(F, n) {

  const k = Math.min(0.52, 0.95 * Math.PI / n);
  for (let b = 0; b < n; b++) {
    const base = (b / n) * Math.PI * 2;
    const P = [];
    for (let i = 0; i < 3; i++) {
      const a = base + B_SW[i], h = B_C[i] * k, r = B_R[i], zc = 0.080;
      const pt = (ang, z) => [r * Math.cos(ang), r * Math.sin(ang), z];
      P.push([pt(a + h, zc + B_TW[i] + B_T), pt(a + h, zc + B_TW[i] - B_T),
              pt(a - h, zc - B_TW[i] + B_T), pt(a - h, zc - B_TW[i] - B_T)]);
    }
    for (let i = 0; i < 2; i++) {
      const A = P[i], Bs = P[i + 1];
      quadN(F.fan, A[0], Bs[0], Bs[2], A[2], [0, 0, 1]);
      quadN(F.fan, A[1], Bs[1], Bs[3], A[3], [0, 0, -1]);
      const lead = crs(sub(Bs[0], A[0]), sub(A[1], A[0]));
      quadN(F.fan, A[0], Bs[0], Bs[1], A[1], lead);
      const trail = crs(sub(Bs[2], A[2]), sub(A[3], A[2]));
      quadN(F.fan, A[2], Bs[2], Bs[3], A[3], [-trail[0], -trail[1], -trail[2]]);
    }
    const T = P[2];
    quadN(F.fan, T[0], T[1], T[3], T[2], [Math.cos(base + B_SW[2]), Math.sin(base + B_SW[2]), 0]);
  }

  for (let i = 0; i < HUB_SEG; i++) {
    const a0 = (i / HUB_SEG) * Math.PI * 2, a1 = ((i + 1) / HUB_SEG) * Math.PI * 2;
    const am = (a0 + a1) / 2;
    quadN(F.fan,
      [HUB_R * Math.cos(a0), HUB_R * Math.sin(a0), HUB_Z0],
      [HUB_R * Math.cos(a1), HUB_R * Math.sin(a1), HUB_Z0],
      [HUB_R * Math.cos(a1), HUB_R * Math.sin(a1), HUB_Z1],
      [HUB_R * Math.cos(a0), HUB_R * Math.sin(a0), HUB_Z1],
      [Math.cos(am), Math.sin(am), 0]);
  }
  const face = [];
  for (let i = 0; i < HUB_SEG; i++) {
    const a = (i / HUB_SEG) * Math.PI * 2;
    face.push([HUB_R * Math.cos(a), HUB_R * Math.sin(a)]);
  }
  for (let i = 1; i < HUB_SEG - 1; i++) {
    triN(F.fan, [face[0][0], face[0][1], HUB_Z1], [face[i][0], face[i][1], HUB_Z1],
      [face[i + 1][0], face[i + 1][1], HUB_Z1], [0, 0, 1]);
  }

  boxN(F.bracket, 0.014, 0.040, -0.013, 0.013, HUB_Z1 - 0.002, HUB_Z1 + 0.014);
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
    type: 'choice', default: 'beige', label: 'Colorway',
    options: ['beige', 'grey-steel', 'cream-white', 'weathered-tan', 'charcoal'],
    describe: 'Curated kit-palette scheme; sets all five zone colours at once. beige is ' +
      'the shipped warm painted casing with a pale galvanised grille panel. grey-steel is ' +
      'a cooler unpainted-looking machine grey for back-alley walls. cream-white is the ' +
      'brightest, for a freshly fitted unit on a pale shopfront. weathered-tan drops the ' +
      'casing to a sun-baked sand with brown brackets for an old unit. charcoal inverts ' +
      'the ladder: a dark grey casing with LIGHT fan blades so the grille still reads. ' +
      'Every scheme keeps the panel lighter than the casing and the well darkest.',
  },
  casing: {
    type: 'color', default: '#D9CFBC', label: 'Casing',
    describe: 'Albedo of the painted sheet-metal shell: both side walls, the flat back, ' +
      'the front frame around the grille, the underside, the whole top lid and the side ' +
      'pipe-cover box — roughly 60% of the pixels the camera sees. One uniform tone on ' +
      'every face; the bright top and dark front in the reference renders are lighting.',
  },
  panel: {
    type: 'color', default: '#E4E2DC', label: 'Grille panel',
    describe: 'Albedo of the bare galvanised sheet sunk 20 mm into the front face: the ' +
      'panel plate, its four sloping recess walls, the flared mouth of the fan well and ' +
      'the two guard bars crossing it. Keep it LIGHTER than the casing — a light ring ' +
      'around the dark well is what makes the recess read as a dish rather than a patch.',
  },
  bracket: {
    type: 'color', default: '#6B7278', label: 'Brackets & pipe',
    describe: 'Albedo of the four mounting foot brackets, the vertical pipe stub beside ' +
      'the side box and the small boss on the fan hub — the dull unpainted steel fittings. ' +
      'Clearly darker than the casing so the feet read as separate hardware and daylight ' +
      'still shows under the body.',
  },
  fan: {
    type: 'color', default: '#4E5459', label: 'Fan',
    describe: 'Albedo of the six swept condenser blades and their hub barrel. Sits between ' +
      'the grille panel and the well: light enough to separate from the dark bore behind ' +
      'it, dark enough that the fan reads as the hole in the front face at street distance.',
  },
  void: {
    type: 'color', default: '#2E3134', label: 'Well & vents',
    describe: 'Albedo of the genuine openings only — the fan well bore and floor behind ' +
      'the blades, and the sunk louver slots on the right of the face. The darkest tone ' +
      'on the asset; it is never used on an outward-facing surface.',
  },
  width: {
    type: 'range', default: 0.85, min: 0.72, max: 1.35, label: 'Casing width',
    affects: 'geometry',
    describe: 'Casing width in metres. This REBUILDS rather than stretches: the fan, its ' +
      '0.352 m well, the recessed panel, the lid thickness, the chamfers and the four foot ' +
      'brackets are all fixed components that keep their exact size, and the extra length ' +
      'goes into the blank field right of the grille, which gains whole louver BANKS at a ' +
      'constant ~0.30 m pitch (0 banks at 0.72, 1 at the default 0.85, 2 near 1.05, 3 at ' +
      '1.35) — so the triangle count moves with the knob. 0.72 is a compact domestic ' +
      'split-system condenser with a blank right-hand cheek; 1.35 is a wide commercial ' +
      'unit whose front is half grille, half louver. Depth and height never change, so it ' +
      'stays a facade bolt-on inside one 4 m bay at every value.',
  },
  ventSlots: {
    type: 'range', default: 2, min: 1, max: 4, step: 1, label: 'Louver slots',
    affects: 'geometry',
    describe: 'How many horizontal louver slots each bank on the right-hand field carries, ' +
      'stacked at a constant 0.052 m pitch and centred low on the face as the references ' +
      'show. 1 is a single drain vent on an almost blank cheek; the default 2 matches the ' +
      'reference unit; 4 fills the lower half of the field with a proper louver stack. ' +
      'Each slot is a real 12 mm recess with sloping walls, never a painted line. ' +
      'Multiplies with the bank count that Casing width sets.',
  },
  fanBlades: {
    type: 'range', default: 6, min: 4, max: 8, step: 1, label: 'Fan blades',
    affects: 'geometry',
    describe: 'Number of swept blades on the condenser rotor. Blade chord is capped ' +
      'against the count so the disc never self-intersects: 4 gives a sparse, chunky ' +
      'propeller with the dark well showing broadly between the blades; the default 6 ' +
      'matches the reference; 8 is a dense fine-pitch rotor that nearly closes the disc. ' +
      'Blade root radius, tip radius, sweep and twist are fixed, so this is a genuine ' +
      'count rebuild, not a rescale.',
  },
  pipeBox: {
    type: 'toggle', default: true, label: 'Pipe cover box', affects: 'geometry',
    describe: 'The refrigerant pipe cover on the +X side face and the vertical pipe stub ' +
      'rising out of it — the asset\'s one deliberate asymmetry. On (default) is the ' +
      'reference unit and adds 55 mm to the delivered width. Off leaves a clean flat side ' +
      'wall with no socket or scar, for units placed shoulder to shoulder in a row or ' +
      'seen only from the grille side; the casing re-centres itself on the narrower box.',
  },
};

export const presets = COLORWAYS;
export const rig = {

  'fan': { axis: 'z', range: [0, 33] },
};
export const detach = [];
export const night = {};
export default createAsset;

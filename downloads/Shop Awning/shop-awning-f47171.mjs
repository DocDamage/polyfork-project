/*
 * Shop Awning
 * https://polyfork.dev/asset/shop-awning-f47171
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './shop-awning-f47171.mjs';
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
 *   colorway     choice  'shop-green'   'shop-green' | 'awning-red' | 'slate-blue' | 'canvas-cream'
 *   fabric       color   '#3d6b52'      any hex or THREE.Color
 *   valance      color   '#3d6b51'      any hex or THREE.Color
 *   frame        color   '#9a8472'      any hex or THREE.Color
 *   rise         range   1.27           1 to 1.55
 *   valanceDrop  range   0.32           0.18 to 0.5
 *   projection   range   1              0.75 to 1.4
 *
 * Every option is described in full at https://polyfork.dev/cdn/shop-awning-f47171-params.json
 *
 * SPECS  180 triangles, 1 material, 4 x 1.27 x 1 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'shop-green', label: 'Colorway',
    options: ['shop-green', 'awning-red', 'slate-blue', 'canvas-cream'],
    describe: 'curated two-tone scheme: canopy fabric, valance band and painted timber frame. '
            + 'shop-green is the approved default (one uniform dark green over pale timber); '
            + 'awning-red and slate-blue give the valance a visibly lighter band than the canopy; '
            + 'canvas-cream is an unbleached-canvas awning on grey frame.',
  },
  fabric: {
    type: 'color', default: '#3d6b52', label: 'Canopy fabric',
    describe: 'albedo of the sloped top plane, the thick leading edge and the flat soffit — '
            + 'the dominant mass, ~70% of the visible area.',
  },
  valance: {
    type: 'color', default: '#3d6b51', label: 'Valance band',
    describe: 'albedo of the short flap hanging at the front. Defaults 1/255 off the canopy so '
            + 'the awning reads as one uniform colour; set it apart for a classic two-tone awning.',
  },
  frame: {
    type: 'color', default: '#9a8472', label: 'Timber frame',
    describe: 'albedo of the wall mounting board (the whole back face and the lip above the '
            + 'ridge) and of the seven ribs under the soffit. Keep it lighter than the fabric — '
            + 'it is what stops the underside reading as one flat value.',
  },
  rise: {
    type: 'range', default: 1.27, min: 1.00, max: 1.55, affects: 'geometry',
    label: 'Rise',
    describe: 'total height in metres, set by how high the back ridge sits on the wall. 1.00 is a '
            + 'shallow shade hood pitched at ~30 degrees; 1.55 is a steep, deep-shading wedge at '
            + '~50 degrees. Changes the front silhouette directly; footprint is unaffected.',
  },
  valanceDrop: {
    type: 'range', default: 0.32, min: 0.18, max: 0.50, affects: 'geometry',
    label: 'Valance drop',
    describe: 'how far the front flap hangs below the soffit, in metres, and therefore how high '
            + 'the whole canopy sits off the shopfront head. 0.18 is a mere hem; 0.50 is a deep '
            + 'shop-sign band taking up nearly half the front elevation.',
  },
  projection: {
    type: 'range', default: 1.00, min: 0.75, max: 1.40, affects: 'geometry',
    label: 'Projection',
    describe: 'how far the awning reaches out from the wall, in metres. 0.75 is a tight shade '
            + 'hood; 1.40 is a full pavement canopy with a much larger sloped top face and a '
            + 'shallower pitch. Width stays exactly 4 m at every value, so clones still chain.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {

  'shop-green':   { fabric: '#3d6b52', valance: '#3d6b51', frame: '#9a8472' },
  'awning-red':   { fabric: '#b63735', valance: '#c7504d', frame: '#cfc6b9' },
  'slate-blue':   { fabric: '#45525f', valance: '#7b8b8f', frame: '#c1b0a1' },
  'canvas-cream': { fabric: '#cfc6b9', valance: '#9a8472', frame: '#736e69' },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const hex = (s) => (typeof s === 'string' ? parseInt(s.replace('#', ''), 16) : s);
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: { fabric: hex(p.fabric), valance: hex(p.valance), frame: hex(p.frame) },
    rise: clamp(p.rise, 1.00, 1.55),
    drop: clamp(p.valanceDrop, 0.18, 0.50),
    proj: clamp(p.projection, 0.75, 1.40),
  };
}

const W = 4.00, HW = W / 2;
const BOARD_T = 0.08;
const BOARD_LIP = 0.06;
const BOARD_SKIRT = 0.12;
const EDGE_T = 0.14;
const VAL_T = 0.15;
const VAL_LAP = 0.06;

const FRONT_INSET = 0.11;
const CH_F = 0.025, CH_V = 0.018, CH_B = 0.018;
const RIB_N = 7, RIB_W = 0.12, RIB_DROP = 0.08, RIB_BITE = 0.02;

const RIB_SPAN = 3.80, BOW_FRAC = 0.0573, BOW_HW = 0.10;
const ribX = (i) => -RIB_SPAN / 2 + (RIB_SPAN * i) / (RIB_N - 1);

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

function wall(out, p, q, hw) {
  quad(out, [-hw, p[1], p[0]], [hw, p[1], p[0]], [hw, q[1], q[0]], [-hw, q[1], q[0]]);
}

function cap(out, poly, x, sign) {
  const contour = poly.map((p) => new THREE.Vector2(p[0], p[1]));
  for (const f of THREE.ShapeUtils.triangulateShape(contour, [])) {
    let [a, b, c] = f.map((i) => poly[i]);

    const area = (b[0] - a[0]) * (c[1] - a[1]) - (c[0] - a[0]) * (b[1] - a[1]);
    if (area < 0) { const t = b; b = c; c = t; }
    const A = [x, a[1], a[0]], B = [x, b[1], b[0]], C = [x, c[1], c[0]];
    if (sign > 0) tri(out, C, B, A); else tri(out, A, B, C);
  }
}

function slab(out, x0, x1, y0, y1, z0, z1, faces) {
  const v = (x, y, z) => [x, y, z];
  if (faces.includes('ny')) quad(out, v(x0, y0, z0), v(x1, y0, z0), v(x1, y0, z1), v(x0, y0, z1));
  if (faces.includes('py')) quad(out, v(x0, y1, z1), v(x1, y1, z1), v(x1, y1, z0), v(x0, y1, z0));
  if (faces.includes('px')) quad(out, v(x1, y0, z0), v(x1, y1, z0), v(x1, y1, z1), v(x1, y0, z1));
  if (faces.includes('nx')) quad(out, v(x0, y0, z1), v(x0, y1, z1), v(x0, y1, z0), v(x0, y0, z0));
  if (faces.includes('pz')) quad(out, v(x0, y0, z1), v(x1, y0, z1), v(x1, y1, z1), v(x0, y1, z1));
  if (faces.includes('nz')) quad(out, v(x1, y0, z0), v(x0, y0, z0), v(x0, y1, z0), v(x1, y1, z0));
}

export function createAsset(userParams = {}) {
  const { C, rise, drop, proj } = resolve(userParams);

  const HD = proj / 2;
  const SF = drop;
  const RL = -HD + BOARD_T;
  const VF = HD;
  const VB = HD - VAL_T;
  const FR = HD - FRONT_INSET;
  const RB = SF - BOARD_SKIRT;
  const VT = SF + VAL_LAP;
  const FT = SF + EDGE_T;

  const RIDGE = Math.max(rise - BOARD_LIP, FT + 0.22);
  const RISE = RIDGE + BOARD_LIP;

  const sdz = RL - FR, sdy = RIDGE - FT, sl = Math.hypot(sdz, sdy);
  const chz = FR + CH_F * (sdz / sl), chy = FT + CH_F * (sdy / sl);

  const PROFILE = [
    [-HD, RB],
    [RL - CH_B, RB],
    [RL, RB + CH_B],
    [RL, SF],
    [VB, SF],
    [VB, 0],
    [VF - CH_V, 0],
    [VF, CH_V],
    [VF, VT - CH_V],
    [VF - CH_V, VT],
    [FR, VT],
    [FR, FT - CH_F],
    [chz, chy],
    [RL, RIDGE],
    [RL, RISE - CH_B],
    [RL - CH_B, RISE],
    [-HD, RISE],
  ];
  const F = C.fabric, V = C.valance, M = C.frame;
  const EDGE_COL = [M, M, M, F, V, V, V, V, V, V, F, F, F, M, M, M, M];

  const CAP_BOARD = [PROFILE[0], PROFILE[1], PROFILE[2], PROFILE[14], PROFILE[15], PROFILE[16]];
  const CAP_FABRIC = [[RL, SF], [VB, SF], [VB, VT], [FR, VT], PROFILE[11], PROFILE[12], PROFILE[13]];
  const CAP_VALANCE = [PROFILE[5], PROFILE[6], PROFILE[7], PROFILE[8], PROFILE[9], [VB, VT]];

  const buf = { [F]: [], [V]: [], [M]: [] };
  for (let i = 0; i < PROFILE.length; i++) {
    if (i === 12) continue;
    wall(buf[EDGE_COL[i]], PROFILE[i], PROFILE[(i + 1) % PROFILE.length], HW);
  }

  {
    const p = PROFILE[12], q = PROFILE[13];
    const dz = q[0] - p[0], dy = q[1] - p[1], L = Math.hypot(dz, dy);
    const nz = dy / L, ny = -dz / L;
    const xs = [];
    for (let i = 0; i < RIB_N; i++) { const c = ribX(i); xs.push(c - BOW_HW, c, c + BOW_HW); }
    const ts = [0, 0.5, 1];
    const bowH = BOW_FRAC * L;
    const S = (x, t) => {
      let a = 0;
      for (let i = 0; i < RIB_N; i++) {
        a = Math.max(a, bowH * (1 - Math.min(1, Math.abs(x - ribX(i)) / BOW_HW)));
      }
      const h = a * (1 - Math.abs(2 * t - 1));
      return [x, p[1] + dy * t + ny * h, p[0] + dz * t + nz * h];
    };
    for (let i = 0; i + 1 < xs.length; i++) {
      for (let j = 0; j + 1 < ts.length; j++) {
        quad(buf[F], S(xs[i], ts[j]), S(xs[i + 1], ts[j]),
          S(xs[i + 1], ts[j + 1]), S(xs[i], ts[j + 1]));
      }
    }
  }
  for (const s of [-1, 1]) {
    cap(buf[M], CAP_BOARD, s * HW, s);
    cap(buf[F], CAP_FABRIC, s * HW, s);
    cap(buf[V], CAP_VALANCE, s * HW, s);
  }

  for (let i = 0; i < RIB_N; i++) {
    const xc = ribX(i);
    slab(buf[M], xc - RIB_W / 2, xc + RIB_W / 2,
      SF - RIB_DROP, SF + RIB_BITE, RL - 0.02, VB + 0.02, ['ny', 'px', 'nx']);
  }

  const merged = mergeGeometries(
    Object.entries(buf).filter(([, p]) => p.length).map(([hex, p]) => prep(posGeo(p), Number(hex)))
  );
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'awning-body';

  const g = new THREE.Group();
  g.name = 'shop-awning';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];
export const night = {};
export default createAsset;

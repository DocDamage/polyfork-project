/*
 * Serving Tongs
 * https://polyfork.dev/asset/serving-tongs-d6480a
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './serving-tongs-d6480a.mjs';
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
 *   steel     color   '#7b8b8f'      any hex or THREE.Color
 *   polished  color   '#dfe9ec'      any hex or THREE.Color
 *   spring    color   '#46545a'      any hex or THREE.Color
 *
 * Every option is described in full at https://polyfork.dev/cdn/serving-tongs-d6480a-params.json
 *
 * SPECS  220 triangles, 1 material, 0.26 x 0.04 x 0.09 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const palette = {
  steel:    0x7b8b8f,
  polished: 0xdfe9ec,
  spring:   0x46545a,
};
export const presets = { 'house-steel': { ...palette } };

export const params = {
  steel:    { type: 'color', default: 0x7b8b8f, label: 'Tongs steel',
              describe: 'Arms and spring bend. Muted desaturated blue-grey reads as stainless at this flat-shaded style.' },
  polished: { type: 'color', default: 0xdfe9ec, label: 'Heads',
              describe: 'The two spoon-paddle gripping heads. Near-white polished steel so the business end separates from the arms at thumbnail size.' },
  spring:   { type: 'color', default: 0x46545a, label: 'Spring band',
              describe: 'Dark accent on the outer half of the spring U-bend — the hinge. Darkest value on the asset; anchors the back end at 64px.' },
};

export const night = {};

const parts = [];
const add = (g, c) => parts.push({ g, c });

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
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }

function quadN(out, a, b, c, d, want) {
  const u = [b[0] - a[0], b[1] - a[1], b[2] - a[2]];
  const v = [c[0] - b[0], c[1] - b[1], c[2] - b[2]];
  const n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]];
  if (n[0] * want[0] + n[1] * want[1] + n[2] * want[2] < 0) quad(out, d, c, b, a);
  else quad(out, a, b, c, d);
}
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const SPINE = [

  [0.140,   0.011,  0.005, 0.009],
  [0.136,   0.014,  0.006, 0.014],
  [0.126,   0.017,  0.007, 0.020],
  [0.112,   0.022,  0.007, 0.015],
  [0.098,   0.027,  0.009, 0.009],

  [0.072,   0.031,  0.009, 0.008],
  [0.042,   0.034,  0.009, 0.008],
  [0.005,   0.034,  0.009, 0.008],
  [-0.032,  0.031,  0.009, 0.008],
  [-0.062,  0.025,  0.009, 0.008],
  [-0.084,  0.019,  0.009, 0.008],

  [-0.096,  0.016,  0.007, 0.008],
  [-0.1054, 0.0129, 0.007, 0.008],
  [-0.1112, 0.0049, 0.007, 0.008],
  [-0.1112, -0.0049, 0.007, 0.008],
  [-0.1054, -0.0129, 0.007, 0.008],
  [-0.096, -0.016,  0.007, 0.008],

  [-0.084, -0.019,  0.009, 0.008],
  [-0.062, -0.025,  0.009, 0.008],
  [-0.032, -0.031,  0.009, 0.008],
  [0.005,  -0.034,  0.009, 0.008],
  [0.042,  -0.034,  0.009, 0.008],
  [0.072,  -0.031,  0.009, 0.008],

  [0.098,  -0.027,  0.009, 0.009],
  [0.112,  -0.022,  0.007, 0.015],
  [0.126,  -0.017,  0.007, 0.020],
  [0.136,  -0.014,  0.006, 0.014],
  [0.140,  -0.011,  0.005, 0.009],
];
const HEAD_SECTIONS = 5;
const BEND_SEGS = [13, 14];

function loftTongs() {
  const n = SPINE.length;

  const secs = SPINE.map(([x, z, w, h], i) => {
    const [xp, zp] = SPINE[Math.max(0, i - 1)];
    const [xn, zn] = SPINE[Math.min(n - 1, i + 1)];
    let tx = xn - xp, tz = zn - zp;
    const l = Math.hypot(tx, tz); tx /= l; tz /= l;
    const nx = -tz, nz = tx;
    return {
      c: [x, z], nx, nz, w,

      TL: [x + nx * w, 2 * h, z + nz * w], TR: [x - nx * w, 2 * h, z - nz * w],
      BL: [x + nx * w, 0, z + nz * w], BR: [x - nx * w, 0, z - nz * w],
    };
  });

  const armPos = [], headPos = [], bendPos = [];
  const emitSeg = (out, A, B) => {
    quadN(out, A.TL, A.TR, B.TR, B.TL, [0, 1, 0]);
    quadN(out, A.BR, A.BL, B.BL, B.BR, [0, -1, 0]);
    quadN(out, A.BL, A.TL, B.TL, B.BL, [A.nx + B.nx, 0, A.nz + B.nz]);
    quadN(out, A.TR, A.BR, B.BR, B.TR, [-A.nx - B.nx, 0, -A.nz - B.nz]);
  };
  for (let i = 0; i < n - 1; i++) {

    const isHead = (i < HEAD_SECTIONS - 1) || (i >= n - HEAD_SECTIONS);
    const out = isHead ? headPos : (BEND_SEGS.includes(i) ? bendPos : armPos);
    emitSeg(out, secs[i], secs[i + 1]);
  }

  const cap = (out, S, dir) =>
    quadN(out, S.TL, S.TR, S.BR, S.BL, dir);
  cap(headPos, secs[0], [secs[0].c[0] - secs[1].c[0], 0, secs[0].c[1] - secs[1].c[1]]);
  cap(headPos, secs[n - 1], [secs[n - 1].c[0] - secs[n - 2].c[0], 0, secs[n - 1].c[1] - secs[n - 2].c[1]]);

  return { arms: posGeo(armPos), heads: posGeo(headPos), bend: posGeo(bendPos) };
}

export function createAsset(opts = {}) {
  const P = { ...palette };
  for (const k of Object.keys(palette)) if (opts[k] !== undefined) P[k] = opts[k];

  const { arms, heads, bend } = loftTongs();
  add(arms, P.steel);
  add(heads, P.polished);
  add(bend, P.spring);

  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.6, metalness: 0.35,
  }));

  const root = new THREE.Group();
  root.name = 'serving-tongs';
  root.add(mesh);
  return root;
}

export const rig = {};
export const detach = [];

export default createAsset;

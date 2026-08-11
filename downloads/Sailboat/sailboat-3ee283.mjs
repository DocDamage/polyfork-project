/*
 * Sailboat
 * https://polyfork.dev/asset/sailboat-3ee283
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sailboat-3ee283.mjs';
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
 * SPECS  60 triangles, 1 material, 0.22 x 0.3 x 0.09 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const HULL = 0xc0392b;
const WOOD = 0xa9764a;
const SAIL = 0xf3f5f6;

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function triOut(out, a, b, c, center) {
  const ux = b[0] - a[0], uy = b[1] - a[1], uz = b[2] - a[2];
  const vx = c[0] - a[0], vy = c[1] - a[1], vz = c[2] - a[2];
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
  const fx = (a[0] + b[0] + c[0]) / 3 - center[0];
  const fy = (a[1] + b[1] + c[1]) / 3 - center[1];
  const fz = (a[2] + b[2] + c[2]) / 3 - center[2];
  if (nx * fx + ny * fy + nz * fz < 0) tri(out, a, c, b); else tri(out, a, b, c);
}

function triBoth(out, a, b, c) { tri(out, a, b, c); tri(out, a, c, b); }

function cylBetween(p0, p1, r, seg) {
  const dir = new THREE.Vector3(p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]);
  const len = dir.length();
  const g = new THREE.CylinderGeometry(r, r, len, seg);
  const q = new THREE.Quaternion().setFromUnitVectors(new THREE.Vector3(0, 1, 0), dir.clone().normalize());
  const m = new THREE.Matrix4().compose(
    new THREE.Vector3((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, (p0[2] + p1[2]) / 2), q, new THREE.Vector3(1, 1, 1));
  return g.applyMatrix4(m);
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

export function createAsset() {
  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const dy = 0.0417;
  const V = {
    bow:  [0.1242, dy, 0],
    pf:   [0.0497, dy, 0.0457],
    ps:   [-0.0993, dy, 0.0417],
    ss:   [-0.0993, dy, -0.0417],
    sf:   [0.0497, dy, -0.0457],
    kb:   [0.1093, 0, 0],
    ks:   [-0.0974, 0, 0],
  };

  const hc = [0, 0, 0];
  for (const k of Object.keys(V)) { hc[0] += V[k][0]; hc[1] += V[k][1]; hc[2] += V[k][2]; }
  hc[0] /= 7; hc[1] /= 7; hc[2] /= 7;

  const hp = [];
  const F = (a, b, c) => triOut(hp, V[a], V[b], V[c], hc);

  F('bow', 'pf', 'ps'); F('bow', 'ps', 'ss'); F('bow', 'ss', 'sf');

  F('bow', 'pf', 'kb'); F('pf', 'ps', 'ks'); F('pf', 'ks', 'kb');

  F('ps', 'ss', 'ks');

  F('ss', 'sf', 'kb'); F('ss', 'kb', 'ks'); F('sf', 'bow', 'kb');
  add(posGeo(hp), HULL);

  const mastX = 0.0338;
  const mastTop = [mastX, 0.30, 0];
  const mastBase = [mastX, dy - 0.002, 0];
  add(cylBetween(mastBase, mastTop, 0.0045, 6), WOOD);
  const clew = [-0.0715, 0.0656, 0];
  add(cylBetween([mastX, 0.0596, 0], clew, 0.0032, 5), WOOD);

  const head = [mastX, 0.294, 0];
  const tack = [mastX, 0.0616, 0];
  const belly = [
    (head[0] + tack[0] + clew[0]) / 3,
    (head[1] + tack[1] + clew[1]) / 3,
    0.0159,
  ];
  const sp = [];
  triBoth(sp, head, tack, belly);
  triBoth(sp, tack, clew, belly);
  triBoth(sp, clew, head, belly);
  add(posGeo(sp), SAIL);

  const merged = mergeGeometries(parts.map(p => prep(p.g, p.c)));
  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(-(bb.min.x + bb.max.x) / 2, -bb.min.y, -(bb.min.z + bb.max.z) / 2);
  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
    side: THREE.DoubleSide,
  }));
  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};

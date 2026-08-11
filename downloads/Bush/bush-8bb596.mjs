/*
 * Bush
 * https://polyfork.dev/asset/bush-8bb596
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './bush-8bb596.mjs';
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
 * SPECS  260 triangles, 1 material, 0.95 x 0.62 x 0.82 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const SAGE = '#7d8a5a';
const DEEP = '#4a6a4f';

const TARGET = { x: 0.95, y: 0.62, z: 0.82 };

function hash3(x, y, z, seed) {
  const q = (v) => Math.round(v * 4096);
  let h = (q(x) * 374761393 + q(y) * 668265263 + q(z) * 2147483647 + seed * 69069) | 0;
  h = (h ^ (h >>> 13)) * 1274126177;
  h = h ^ (h >>> 16);
  return ((h >>> 0) % 100000) / 100000;
}

function lobe(r, detail, seed, amp = 0.085) {
  const geo = new THREE.IcosahedronGeometry(r, detail);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) {
    const x = p.getX(i), y = p.getY(i), z = p.getZ(i);
    const len = Math.hypot(x, y, z) || 1;
    const fine = hash3(x, y, z, seed) - 0.5;

    const swell = hash3(x * 0.45, y * 0.45, z * 0.45, seed + 977) - 0.5;
    const k = 1 + amp * 2 * fine + amp * 1.6 * swell;
    p.setXYZ(i, (x / len) * r * k, (y / len) * r * k, (z / len) * r * k);
  }
  return geo;
}

function place(geo, sy, tx, ty, tz) {
  return geo.applyMatrix4(new THREE.Matrix4().makeScale(1, sy, 1))
            .applyMatrix4(new THREE.Matrix4().makeTranslation(tx, ty, tz));
}

function prep(geo) {
  if (geo.index) geo = geo.toNonIndexed();

  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  return geo;
}

export function createAsset() {
  const g = new THREE.Group();
  g.name = 'bush-shrub';

  const main = place(lobe(0.42, 2, 17, 0.11), 0.82, 0.09, 0.0, 0.0);
  const bud  = place(lobe(0.25, 1, 4231, 0.13), 0.82, -0.21, 0.055, 0.055);

  const merged = mergeGeometries([prep(main), prep(bud)]);

  const pos = merged.attributes.position;
  let maxY = -Infinity;
  for (let i = 0; i < pos.count; i++) maxY = Math.max(maxY, pos.getY(i));
  const cut = -0.185;
  for (let i = 0; i < pos.count; i++) {
    if (pos.getY(i) < cut) pos.setY(i, cut);
  }

  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  const sx = TARGET.x / (bb.max.x - bb.min.x);
  const sy = TARGET.y / (bb.max.y - bb.min.y);
  const sz = TARGET.z / (bb.max.z - bb.min.z);
  merged.applyMatrix4(new THREE.Matrix4().makeScale(sx, sy, sz));
  merged.computeBoundingBox();
  const b2 = merged.boundingBox;
  merged.applyMatrix4(new THREE.Matrix4().makeTranslation(
    -(b2.max.x + b2.min.x) / 2, -b2.min.y, -(b2.max.z + b2.min.z) / 2,
  ));

  const p2 = merged.attributes.position;
  merged.computeBoundingBox();
  const h = merged.boundingBox.max.y || 1;
  const sage = new THREE.Color(SAGE), deep = new THREE.Color(DEEP);
  const col = new Float32Array(p2.count * 3);
  const a = new THREE.Vector3(), b = new THREE.Vector3(), c = new THREE.Vector3();
  const e1 = new THREE.Vector3(), e2 = new THREE.Vector3(), n = new THREE.Vector3();
  const tmp = new THREE.Color();

  for (let f = 0; f < p2.count; f += 3) {
    a.fromBufferAttribute(p2, f); b.fromBufferAttribute(p2, f + 1); c.fromBufferAttribute(p2, f + 2);
    const cy = (a.y + b.y + c.y) / 3;
    n.crossVectors(e1.subVectors(b, a), e2.subVectors(c, a)).normalize();

    const t = Math.min(1, Math.max(0,
      0.46 + Math.max(0, n.y) * 0.52 + (cy / h) * 0.16));
    tmp.copy(deep).lerp(sage, t);

    const w = 0.94 + hash3(a.x + b.x, a.y + b.y, a.z + c.z, 8123) * 0.13;
    tmp.multiplyScalar(w);

    for (let k = 0; k < 3; k++) {
      col[(f + k) * 3] = tmp.r; col[(f + k) * 3 + 1] = tmp.g; col[(f + k) * 3 + 2] = tmp.b;
    }
  }
  merged.setAttribute('color', new THREE.BufferAttribute(col, 3));

  merged.computeVertexNormals();

  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'foliage';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export default createAsset;

/*
 * Sample Container
 * https://polyfork.dev/asset/sample-container-c5dc43
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './sample-container-c5dc43.mjs';
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
 * SPECS  272 triangles, 1 material, 0.12 x 0.26 x 0.16 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const C = {
  glow: 0xa9f0e6,
  gray: 0x878c94,
  dark: 0x3d3f47,
};

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

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeBoundingBox();
  const bb = merged.boundingBox;
  merged.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2,
  );
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function cylY(r, yBot, yTop, seg = 8, open = false) {
  const g = new THREE.CylinderGeometry(r, r, yTop - yBot, seg, 1, open);
  return g.translate(0, (yTop + yBot) / 2, 0);
}

function strapY(R, tube, x, y, z) {
  const g = new THREE.TorusGeometry(R, tube, 4, 8, Math.PI);
  g.rotateY(Math.PI / 2);
  g.rotateX(-Math.PI / 2);
  return g.translate(x, y, z);
}

export function createAsset() {

  add(cylY(0.056, 0.016, 0.226, 8, true), C.glow);

  add(cylY(0.062, 0.000, 0.014), C.gray);
  add(cylY(0.058, 0.014, 0.034), C.gray);

  add(cylY(0.058, 0.204, 0.226), C.gray);
  add(cylY(0.062, 0.226, 0.240), C.gray);
  add(cylY(0.022, 0.240, 0.258), C.gray);

  add(cylY(0.058, 0.146, 0.158), C.dark);

  add(strapY(0.048, 0.010, 0, 0.121, -0.044), C.dark);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export default createAsset;

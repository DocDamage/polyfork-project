/*
 * Carrot
 * https://polyfork.dev/asset/carrot-1f7e61
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './carrot-1f7e61.mjs';
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
 * SPECS  116 triangles, 1 material, 0.08 x 0.28 x 0.09 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const ORANGE = 0xf07818;
const GREEN = 0x4ca13a;

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
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

const SIDES = 7;
const TOP_Y = 0.178;

export function createAsset() {

  const profile = [
    new THREE.Vector2(0.000, 0.000),
    new THREE.Vector2(0.019, 0.045),
    new THREE.Vector2(0.036, 0.115),
    new THREE.Vector2(0.042, TOP_Y),
    new THREE.Vector2(0.000, 0.214),
  ];
  add(new THREE.LatheGeometry(profile, SIDES), ORANGE);

  const LEAVES = 5;
  for (let i = 0; i < LEAVES; i++) {
    const len = i % 2 ? 0.080 : 0.098;
    const tilt = i % 2 ? 0.60 : 0.38;
    const leaf = new THREE.CylinderGeometry(0.004, 0.026, len, 3)
      .translate(0, len / 2, 0)
      .rotateZ(tilt)
      .rotateY((i / LEAVES) * Math.PI * 2 + 0.4)
      .translate(0, TOP_Y + 0.012, 0);
    add(leaf, GREEN);
  }

  const g = new THREE.Group();
  g.name = 'carrot';
  g.add(finish(parts));
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

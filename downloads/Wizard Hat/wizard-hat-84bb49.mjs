/*
 * Wizard Hat
 * https://polyfork.dev/asset/wizard-hat-84bb49
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './wizard-hat-84bb49.mjs';
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
 * SPECS  92 triangles, 1 material, 0.74 x 0.57 x 0.72 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const INDIGO = '#3a2d6b';
const GOLD = '#f4c542';

const parts = [];
const add = (g, c) => parts.push({ g, c });

function prep(geo, hex) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i*3] = c.r; col[i*3+1] = c.g; col[i*3+2] = c.b; }
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

export function createAsset() {
  const SEG = 7;

  const brimTopY = 0.055;
  const brim = new THREE.CylinderGeometry(0.20, 0.38, 0.055, SEG, 1);
  brim.translate(0, brimTopY / 2, 0);
  add(brim, INDIGO);

  const H = 0.52, R = 0.185;
  const cone = new THREE.ConeGeometry(R, H, SEG, 1);
  cone.translate(0, brimTopY + H / 2, 0);
  add(cone, INDIGO);

  const band = new THREE.CylinderGeometry(R * 0.99, R * 1.02, 0.05, SEG, 1, true);
  band.translate(0, brimTopY + 0.035, 0);
  add(band, GOLD);

  const starShape = new THREE.Shape();
  const spikes = 5, outer = 0.075, inner = 0.032;
  for (let i = 0; i < spikes * 2; i++) {
    const r = i % 2 === 0 ? outer : inner;
    const a = (i / (spikes * 2)) * Math.PI * 2 + Math.PI / 2;
    const x = Math.cos(a) * r, y = Math.sin(a) * r;
    if (i === 0) starShape.moveTo(x, y); else starShape.lineTo(x, y);
  }
  starShape.closePath();
  const star = new THREE.ExtrudeGeometry(starShape, {
    depth: 0.02, bevelEnabled: false,
  });

  const slope = Math.atan(R / H);
  const starY = brimTopY + H * 0.40;
  const faceR = R * (1 - (starY - brimTopY) / H);
  star.rotateX(-slope);
  star.translate(0, starY, faceR + 0.008);
  add(star, GOLD);

  const group = new THREE.Group();
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

export const night = {};

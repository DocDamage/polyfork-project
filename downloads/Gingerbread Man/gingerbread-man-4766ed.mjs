/*
 * Gingerbread Man
 * https://polyfork.dev/asset/gingerbread-man-4766ed
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './gingerbread-man-4766ed.mjs';
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
 * SPECS  280 triangles, 1 material, 0.15 x 0.15 x 0.04 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

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

const DOUGH = 0xa2602a;
const ICING = 0xf6efdd;
const CANDY = 0xc23b2e;

const HIP_Y = 0.050;
const TORSO_Y0 = 0.048, TORSO_Y1 = 0.098;
const TORSO_R0 = 0.030, TORSO_R1 = 0.033;
const HEAD_Y = 0.121, HEAD_R = 0.028, HEAD_T = 0.022;
const ARM_LEN = 0.048, ARM_TILT = 0.44;
const ARM_R0 = 0.0105, ARM_R1 = 0.014;
const LEG_LEN = 0.0502, LEG_SPLAY = 0.10;
const LEG_R0 = 0.0135, LEG_R1 = 0.0165;
const SHOULDER = [0.026, 0.090];

export function createAsset() {

  {
    const g = new THREE.CylinderGeometry(HEAD_R, HEAD_R, HEAD_T, 10);
    g.rotateX(Math.PI / 2);
    g.translate(0, HEAD_Y, 0);
    add(g, DOUGH);
  }

  {
    const g = new THREE.CylinderGeometry(TORSO_R1, TORSO_R0, TORSO_Y1 - TORSO_Y0, 8);
    g.scale(1, 1, 0.62);
    g.translate(0, (TORSO_Y0 + TORSO_Y1) / 2, 0);
    add(g, DOUGH);
  }

  for (const side of [1, -1]) {
    const rot = -side * (Math.PI / 2 + ARM_TILT);
    const arm = new THREE.CylinderGeometry(ARM_R1, ARM_R0, ARM_LEN, 6);
    arm.translate(0, ARM_LEN / 2, 0);
    arm.rotateZ(rot);
    arm.translate(side * SHOULDER[0], SHOULDER[1], 0);
    add(arm, DOUGH);

    const cuff = new THREE.CylinderGeometry(ARM_R1 + 0.0015, ARM_R1 + 0.0015, 0.009, 6, 1, true);
    cuff.translate(0, ARM_LEN * 0.78, 0);
    cuff.rotateZ(rot);
    cuff.translate(side * SHOULDER[0], SHOULDER[1], 0);
    add(cuff, ICING);
  }

  for (const side of [1, -1]) {
    const rot = side * LEG_SPLAY;
    const leg = new THREE.CylinderGeometry(LEG_R0, LEG_R1, LEG_LEN, 6);
    leg.translate(0, -LEG_LEN / 2, 0);
    leg.rotateZ(rot);
    leg.translate(side * 0.014, HIP_Y, 0);
    add(leg, DOUGH);

    const cuff = new THREE.CylinderGeometry(LEG_R1 + 0.0015, LEG_R1 + 0.0015, 0.009, 6, 1, true);
    cuff.translate(0, -LEG_LEN * 0.82, 0);
    cuff.rotateZ(rot);
    cuff.translate(side * 0.014, HIP_Y, 0);
    add(cuff, ICING);
  }

  const faceZ = HEAD_T / 2;
  for (const side of [1, -1]) {
    const eye = new THREE.OctahedronGeometry(0.0055, 0);
    eye.scale(1, 1.15, 0.5);
    eye.translate(side * 0.0105, 0.127, faceZ - 0.001);
    add(eye, ICING);

    const stroke = new THREE.BoxGeometry(0.014, 0.0032, 0.002);
    stroke.rotateZ(side * 0.32);
    stroke.translate(side * 0.0065, 0.1148, faceZ + 0.0005);
    add(stroke, ICING);
  }

  for (const y of [0.088, 0.076, 0.062]) {
    const t = (TORSO_Y1 - y) / (TORSO_Y1 - TORSO_Y0);
    const r = TORSO_R1 + (TORSO_R0 - TORSO_R1) * t;
    const b = new THREE.OctahedronGeometry(0.0065, 0);
    b.scale(1, 1, 0.45);
    b.translate(0, y, r * 0.62 - 0.001);
    add(b, CANDY);
  }

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  mesh.position.y = -mesh.geometry.boundingBox.min.y;

  const group = new THREE.Group();
  group.add(mesh);
  return group;
}

export const rig = {};
export const detach = [];

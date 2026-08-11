/*
 * Muffin
 * https://polyfork.dev/asset/muffin-e3bd16
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './muffin-e3bd16.mjs';
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
 * SPECS  162 triangles, 1 material, 0.09 x 0.07 x 0.09 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const CUP   = 0xe9cd96;
const CRUMB = 0xb06a2e;
const CHIP  = 0x38200f;

const CUP_H   = 0.047;
const CUP_RB  = 0.028;
const CUP_RT  = 0.040;
const FLUTES  = 9;
const DOME_R  = 0.047;
const DOME_SQ = 0.62;
const DOME_Y  = 0.041;

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

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }

function triRadial(out, a, b, c) {
  const ux = b[0]-a[0], uy = b[1]-a[1], uz = b[2]-a[2];
  const vx = c[0]-a[0], vy = c[1]-a[1], vz = c[2]-a[2];
  const nx = uy*vz - uz*vy, ny = uz*vx - ux*vz, nz = ux*vy - uy*vx;
  const cx = (a[0]+b[0]+c[0])/3, cz = (a[2]+b[2]+c[2])/3;
  if (nx*cx + nz*cz < 0) { const t = b; b = c; c = t; }
  tri(out, a, b, c);
}

const N = FLUTES * 2;
const ring = (y, rBase, amp) => {
  const pts = [];
  for (let i = 0; i < N; i++) {
    const a = (i / N) * Math.PI * 2;
    const r = rBase + (i % 2 === 0 ? amp : -amp);
    pts.push([Math.cos(a) * r, y, Math.sin(a) * r]);
  }
  return pts;
};
const bot = ring(0, CUP_RB, 0.0030);
const rim = ring(CUP_H, CUP_RT, 0.0034);

const cupPos = [];
for (let i = 0; i < N; i++) {
  const j = (i + 1) % N;
  triRadial(cupPos, bot[i], bot[j], rim[j]);
  triRadial(cupPos, bot[i], rim[j], rim[i]);
}

const C0 = [0, 0, 0];
for (let i = 0; i < N; i++) tri(cupPos, C0, bot[i], bot[(i + 1) % N]);
add(posGeo(cupPos), CUP);

const dome = new THREE.IcosahedronGeometry(DOME_R, 1);
dome.scale(1, DOME_SQ, 1);
dome.translate(0, DOME_Y, 0);
add(dome, CRUMB);

const UPRIGHT = new THREE.Quaternion().setFromUnitVectors(
  new THREE.Vector3(1, 1, 1).normalize(), new THREE.Vector3(0, 1, 0));

const CHIPS = [
  [12, 0.4, 0.0125], [30, 2.1, 0.0110], [34, 4.3, 0.0120],
  [52, 1.1, 0.0105], [55, 3.2, 0.0115], [50, 5.4, 0.0100], [70, 2.7, 0.0105],
];
for (const [polDeg, az, size] of CHIPS) {
  const pol = polDeg * Math.PI / 180;
  const g = new THREE.TetrahedronGeometry(size, 0);
  g.applyQuaternion(UPRIGHT);
  g.scale(1, 0.62, 1);
  g.rotateY(az * 2.3);

  const px = Math.sin(pol) * Math.cos(az) * DOME_R;
  const py = Math.cos(pol) * DOME_R * DOME_SQ;
  const pz = Math.sin(pol) * Math.sin(az) * DOME_R;
  g.translate(px * 0.88, DOME_Y + py * 0.88, pz * 0.88);
  add(g, CHIP);
}

export function createAsset() {
  const group = new THREE.Group();
  group.name = 'muffin';
  group.add(finish(parts));
  return group;
}

export const rig = {};
export const detach = [];

/*
 * Banana
 * https://polyfork.dev/asset/banana-09c206
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './banana-09c206.mjs';
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
 * SPECS  88 triangles, 1 material, 0.22 x 0.11 x 0.05 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const YELLOW = 0xf3c218;
const GOLD   = 0xc9930f;
const BROWN  = 0x4a3316;

function tri(out, a, b, c) { out.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const SIDES = 5;
const RINGS = 7;
const R_ARC = 0.11;
const SPAN = THREE.MathUtils.degToRad(56);

const RADII = [0.0080, 0.019, 0.0250, 0.0260, 0.0255, 0.0210, 0.0150];

const theta = (t) => (t * 2 - 1) * SPAN;

function centre(t) {
  const th = theta(t);
  return [R_ARC * Math.sin(th), -R_ARC * Math.cos(th), 0];
}

function tangent(t) { const th = theta(t); return [Math.cos(th), Math.sin(th), 0]; }
function radial(t)  { const th = theta(t); return [Math.sin(th), -Math.cos(th), 0]; }

const ANG = (j) => (j / SIDES) * Math.PI * 2 + Math.PI / SIDES;

function sect(t, r, j) {
  const c = centre(t), u = radial(t), a = ANG(j);
  const cu = Math.cos(a) * r, cv = Math.sin(a) * r;
  return [c[0] + u[0] * cu, c[1] + u[1] * cu, c[2] + cv];
}

function offsetSect(t, dist, r, j) {
  const c = centre(t), u = radial(t), T = tangent(t), a = ANG(j);
  const cu = Math.cos(a) * r, cv = Math.sin(a) * r;
  return [c[0] + T[0] * dist + u[0] * cu, c[1] + T[1] * dist + u[1] * cu, c[2] + cv];
}
const offsetPoint = (t, dist) => {
  const c = centre(t), T = tangent(t);
  return [c[0] + T[0] * dist, c[1] + T[1] * dist, c[2]];
};

const STALK_DIR = (() => {
  const d = new THREE.Vector3(0.30, 0.95, 0).normalize();
  return [d.x, d.y, d.z];
})();
function stalkSect(dist, r, j) {
  const c = centre(1), u = radial(1), a = ANG(j);
  const cu = Math.cos(a) * r, cv = Math.sin(a) * r;
  return [c[0] + STALK_DIR[0] * dist + u[0] * cu,
          c[1] + STALK_DIR[1] * dist + u[1] * cu,
          c[2] + cv];
}

export function createAsset() {
  const peel = [], belly = [], dark = [];

  for (let i = 0; i < RINGS - 1; i++) {
    const t0 = i / (RINGS - 1), t1 = (i + 1) / (RINGS - 1);
    for (let j = 0; j < SIDES; j++) {
      const out = j === 4 ? belly : peel;
      quad(out,
        sect(t0, RADII[i], j),
        sect(t1, RADII[i + 1], j),
        sect(t1, RADII[i + 1], (j + 1) % SIDES),
        sect(t0, RADII[i], (j + 1) % SIDES));
    }
  }

  const tipApex = offsetPoint(0, -0.030);
  for (let j = 0; j < SIDES; j++) {
    tri(j === 4 ? belly : peel,
      tipApex, sect(0, RADII[0], j), sect(0, RADII[0], (j + 1) % SIDES));
  }

  const SHOULDER = { d: 0.014, r: 0.0105 }, TOP = { d: 0.042, r: 0.0085 };
  for (let j = 0; j < SIDES; j++) {
    const k = (j + 1) % SIDES;
    quad(dark,
      sect(1, RADII[RINGS - 1], j), stalkSect(SHOULDER.d, SHOULDER.r, j),
      stalkSect(SHOULDER.d, SHOULDER.r, k), sect(1, RADII[RINGS - 1], k));
    quad(dark,
      stalkSect(SHOULDER.d, SHOULDER.r, j), stalkSect(TOP.d, TOP.r, j),
      stalkSect(TOP.d, TOP.r, k), stalkSect(SHOULDER.d, SHOULDER.r, k));
  }

  for (let j = 1; j < SIDES - 1; j++) {
    tri(dark, stalkSect(TOP.d, TOP.r, 0), stalkSect(TOP.d, TOP.r, j + 1), stalkSect(TOP.d, TOP.r, j));
  }

  const parts = [
    { g: posGeo(peel), c: YELLOW },
    { g: posGeo(belly), c: GOLD },
    { g: posGeo(dark), c: BROWN },
  ];

  const mesh = finish(parts);

  mesh.geometry.computeBoundingBox();
  const bb = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(bb.min.x + bb.max.x) / 2,
    -bb.min.y,
    -(bb.min.z + bb.max.z) / 2);
  mesh.geometry.computeBoundingBox();

  const group = new THREE.Group();
  group.name = 'banana';
  group.add(mesh);
  return group;
}

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

export const rig = {};
export const detach = [];

export const night = {};

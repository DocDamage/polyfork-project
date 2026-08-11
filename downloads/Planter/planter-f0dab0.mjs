/*
 * Planter
 * https://polyfork.dev/asset/planter-f0dab0
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './planter-f0dab0.mjs';
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
 *   colorway     choice  'concrete-sage' 'concrete-sage' | 'terracotta-olive' | 'charcoal-teal' | 'sandstone-deep'
 *   stone        color   '#c7baa6'      any hex or THREE.Color
 *   plinth       color   '#898c95'      any hex or THREE.Color
 *   soil         color   '#4e3c30'      any hex or THREE.Color
 *   foliage      color   '#6f8a4b'      any hex or THREE.Color
 *   tubTallness  range   1              0.7 to 1.4
 *   shrubBulk    range   1              0.75 to 1.3
 *   shrubFacets  choice  'faceted'      'chunky' | 'faceted' | 'smooth'
 *
 * Every option is described in full at https://polyfork.dev/cdn/planter-f0dab0-params.json
 *
 * SPECS  260 triangles, 1 material, 0.31 x 0.5 x 0.31 m (real-world scale).
 *        detach: shrub
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'concrete-sage': { stone: '#c7baa6', plinth: '#898c95', soil: '#4e3c30', foliage: '#6f8a4b' },
  'terracotta-olive': { stone: '#ae8566', plinth: '#744d36', soil: '#4e3c30', foliage: '#267466' },
  'charcoal-teal': { stone: '#676b72', plinth: '#3d3f46', soil: '#2a2d35', foliage: '#267466' },
  'sandstone-deep': { stone: '#ddceb0', plinth: '#91776a', soil: '#4e3c30', foliage: '#6f8a4b' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'concrete-sage', label: 'Colorway',
    options: Object.keys(COLORWAYS),
    describe: 'Curated kit-coherent scheme. concrete-sage is warm pale concrete with a sage shrub; terracotta-olive is a clay-brown tub with deep green foliage; charcoal-teal is a dark grey street tub with deep green; sandstone-deep is pale sand stone on a cool grey foot.',
  },
  stone: {
    type: 'color', default: '#c7baa6', label: 'Concrete',
    describe: 'Albedo of the tub body, its top chamfer, the flat rim and the inner wall — the dominant mass, about three quarters of the visible surface.',
  },
  plinth: {
    type: 'color', default: '#898c95', label: 'Base foot',
    describe: 'Albedo of the inset plinth slab the tub stands on. Keep it a clear value step darker than Concrete or the shadow reveal at the ground line disappears.',
  },
  soil: {
    type: 'color', default: '#4e3c30', label: 'Soil',
    describe: 'Albedo of the earth surface inside the tub, seen as a dark sliver in the gap between the shrub and the rim. Darkest value on the asset.',
  },
  foliage: {
    type: 'color', default: '#6f8a4b', label: 'Foliage',
    describe: 'Single flat albedo of the whole shrub cushion. Mid-value green; the facet-to-facet tone in a lit scene comes from the flat shading, not from this colour.',
  },
  tubTallness: {
    type: 'range', default: 1.0, min: 0.7, max: 1.4, affects: 'geometry', label: 'Tub tallness',
    describe: 'Scales the height of the concrete tub only (0.28 m at 1.0). At 0.7 it is a shallow square tray barely deeper than the shrub is thick; at 1.4 it is a tall pedestal box roughly as tall as it is wide, and the whole asset grows from 0.50 m to 0.61 m.',
  },
  shrubBulk: {
    type: 'range', default: 1.0, min: 0.75, max: 1.3, affects: 'geometry', label: 'Shrub bulk',
    describe: 'Scales the foliage cushion in all three axes (0.275 m wide at 1.0). At 0.75 it is a small mound sunk inside the mouth showing a wide ring of soil; at 1.3 it is an overgrown dome that bulges well past the tub sides.',
  },
  shrubFacets: {
    type: 'choice', default: 'faceted', label: 'Shrub facets',
    options: ['chunky', 'faceted', 'smooth'], affects: 'geometry',
    describe: 'Subdivision of the foliage cushion. chunky is a 20-plane crystal boulder of a bush; faceted is the approved ~80-plane low-poly cushion; smooth is a 320-plane rounded shrub for close-up hero placement.',
  },
};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }

function faceN(out, pts, n) {
  const [ax, ay, az] = pts[0], [bx, by, bz] = pts[1], [cx, cy, cz] = pts[2];
  const ux = bx - ax, uy = by - ay, uz = bz - az;
  const vx = cx - ax, vy = cy - ay, vz = cz - az;
  const nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
  const p = (nx * n[0] + ny * n[1] + nz * n[2]) < 0 ? pts.slice().reverse() : pts;
  for (let i = 2; i < p.length; i++) tri(out, p[0], p[i - 1], p[i]);
}

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function ringPts(half, cut) {
  const s = half - cut;
  const c = [[1, 1], [-1, 1], [-1, -1], [1, -1]];
  const pts = [];
  for (let k = 0; k < 4; k++) {
    for (let j = 0; j < 3; j++) {
      const a = (k * 90 + j * 45) * Math.PI / 180;
      pts.push([c[k][0] * s + Math.cos(a) * cut, c[k][1] * s + Math.sin(a) * cut]);
    }
  }
  return pts;
}

function band(out, ra, ya, rb, yb, sign = 1) {
  const n = ra.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    const a = [ra[i][0], ya, ra[i][1]], b = [ra[j][0], ya, ra[j][1]];
    const cc = [rb[j][0], yb, rb[j][1]], d = [rb[i][0], yb, rb[i][1]];
    const mx = (a[0] + b[0] + cc[0] + d[0]) / 4, mz = (a[2] + b[2] + cc[2] + d[2]) / 4;
    faceN(out, [a, b, cc, d], [mx * sign, 0, mz * sign]);
  }
}

function cap(out, r, y, dir) {
  const n = r.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    faceN(out, [[0, y, 0], [r[i][0], y, r[i][1]], [r[j][0], y, r[j][1]]], [0, dir, 0]);
  }
}

function annulus(out, outer, inner, y, dir) {
  const n = outer.length;
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n;
    faceN(out, [
      [outer[i][0], y, outer[i][1]], [outer[j][0], y, outer[j][1]],
      [inner[j][0], y, inner[j][1]], [inner[i][0], y, inner[i][1]],
    ], [0, dir, 0]);
  }
}

function hash3(x, y, z, seed) {
  const q = (v) => Math.round(v * 4096);
  let h = (q(x) * 374761393 + q(y) * 668265263 + q(z) * 2147483647 + seed * 69069) | 0;
  h = (h ^ (h >>> 13)) * 1274126177;
  h = h ^ (h >>> 16);
  return ((h >>> 0) % 100000) / 100000;
}

function lobe(r, detail, seed, amp) {
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

function prep(geo, hex) {
  if (geo.index) geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const c = new THREE.Color(hex);
  const n = geo.attributes.position.count;
  const col = new Float32Array(n * 3);
  for (let i = 0; i < n; i++) { col[i * 3] = c.r; col[i * 3 + 1] = c.g; col[i * 3 + 2] = c.b; }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function material() {
  return new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
}

function finish(list, mat) {
  const merged = mergeGeometries(list.map((p) => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, mat);
}

const FACET_DETAIL = { chunky: 0, faceted: 1, smooth: 2 };

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  Object.assign(p, userParams);

  const way = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const C = {
    stone: userParams.stone || way.stone,
    plinth: userParams.plinth || way.plinth,
    soil: userParams.soil || way.soil,
    foliage: userParams.foliage || way.foliage,
  };

  const g = new THREE.Group();
  g.name = 'roadside-planter';

  const HALF = 0.155;
  const CUT = 0.013;
  const PL_HALF = 0.138;
  const PL_CUT = 0.011;
  const PL_TOP = 0.038;
  const PL_CH = 0.012;

  const bodyH = 0.278 * p.tubTallness;
  const RIM_Y = PL_TOP + bodyH;
  const CH_Y = RIM_Y - 0.015;
  const RIM_OUT = HALF - 0.015;
  const RIM_IN = HALF - 0.035;
  const SOIL_Y = RIM_Y - 0.075;

  const rOut = ringPts(HALF, CUT);
  const rRimOut = ringPts(RIM_OUT, CUT);
  const rRimIn = ringPts(RIM_IN, CUT);
  const rPlinth = ringPts(PL_HALF, PL_CUT);
  const rPlinthFoot = ringPts(PL_HALF - PL_CH, PL_CUT);

  const parts = [];

  const pl = [];
  cap(pl, rPlinthFoot, 0, -1);
  band(pl, rPlinthFoot, 0, rPlinth, PL_CH);
  band(pl, rPlinth, PL_CH, rPlinth, PL_TOP);
  parts.push({ g: posGeo(pl), c: C.plinth });

  const tub = [];
  cap(tub, rOut, PL_TOP, -1);
  band(tub, rOut, PL_TOP, rOut, CH_Y);
  band(tub, rOut, CH_Y, rRimOut, RIM_Y);
  annulus(tub, rRimOut, rRimIn, RIM_Y, 1);
  band(tub, rRimIn, RIM_Y, rRimIn, SOIL_Y, -1);
  parts.push({ g: posGeo(tub), c: C.stone });

  const dirt = [];
  cap(dirt, rRimIn, SOIL_Y, 1);
  parts.push({ g: posGeo(dirt), c: C.soil });

  const mat = material();
  const tubMesh = finish(parts, mat);
  tubMesh.name = 'planter-tub';
  g.add(tubMesh);

  const shrubGroup = new THREE.Group();
  shrubGroup.name = 'shrub';
  const detail = FACET_DETAIL[p.shrubFacets] ?? 1;
  const geo = lobe(0.14, detail, 17, 0.08).toNonIndexed();
  geo.applyMatrix4(new THREE.Matrix4().makeScale(1, 0.94, 0.96));
  geo.computeBoundingBox();
  const bb = geo.boundingBox;
  const W = 0.285 * p.shrubBulk, H = 0.235 * p.shrubBulk, D = 0.275 * p.shrubBulk;
  geo.applyMatrix4(new THREE.Matrix4().makeScale(
    W / (bb.max.x - bb.min.x), H / (bb.max.y - bb.min.y), D / (bb.max.z - bb.min.z),
  ));
  geo.computeBoundingBox();
  const b2 = geo.boundingBox;
  geo.applyMatrix4(new THREE.Matrix4().makeTranslation(
    -(b2.max.x + b2.min.x) / 2,
    (RIM_Y - 0.055) - b2.min.y,
    -(b2.max.z + b2.min.z) / 2,
  ));
  const shrubMesh = finish([{ g: geo, c: C.foliage }], mat);
  shrubMesh.name = 'foliage';
  shrubGroup.add(shrubMesh);
  g.add(shrubGroup);

  return g;
}

export const rig = {};

export const detach = ['shrub'];

export const night = {};

export default createAsset;

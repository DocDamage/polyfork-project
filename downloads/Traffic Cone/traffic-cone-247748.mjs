/*
 * Traffic Cone
 * https://polyfork.dev/asset/traffic-cone-247748
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './traffic-cone-247748.mjs';
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
 *   colorway   choice  'safety-orange' 'safety-orange' | 'hazard-red' | 'faded-works' | 'amber-works'
 *   cone       color   '#E8853A'      any hex or THREE.Color
 *   band       color   '#F2EFE7'      any hex or THREE.Color
 *   base       color   '#2E3134'      any hex or THREE.Color
 *   tallness   range   0.7            0.55 to 0.9
 *   facets     range   12             8 to 16
 *   basePlate  toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/traffic-cone-247748-params.json
 *
 * SPECS  376 triangles, 1 material, 0.44 x 0.7 x 0.44 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'safety-orange': { cone: '#E8853A', band: '#F2EFE7', base: '#2E3134' },
  'hazard-red':    { cone: '#D6452F', band: '#E4E2DC', base: '#1B1D20' },
  'faded-works':   { cone: '#B5462F', band: '#D9CFBC', base: '#3C4145' },
  'amber-works':   { cone: '#F0C24B', band: '#F2EFE7', base: '#4E5459' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'safety-orange', label: 'Colorway',
    options: ['safety-orange', 'hazard-red', 'faded-works', 'amber-works'],
    describe: 'Curated kit-palette scheme, sets all three colour zones at once. ' +
              'safety-orange is the standard bright cone on a near-black pad shown in the ' +
              'references; hazard-red is a deeper red fire-lane cone on the darkest pad; ' +
              'faded-works is a sun-bleached red-brown cone with cream tape on a grey pad; ' +
              'amber-works is a yellow works-department cone on a mid-grey pad. Explicit ' +
              'cone/band/base values override the preset.',
  },
  cone: {
    type: 'color', default: '#E8853A', label: 'Cone',
    describe: 'Albedo of the moulded plastic body: the tapered cone, the flared skirt and ' +
              'the flat tip cap. This is the dominant mass — roughly three quarters of the ' +
              'visible triangles — so it sets the whole prop\'s read at street distance.',
  },
  band: {
    type: 'color', default: '#F2EFE7', label: 'Band',
    describe: 'Albedo of the reflective tape sleeves that ring the cone. Keep a large value ' +
              'gap from `cone`: the bands are the only value break on the object and they ' +
              'are what makes it read as a traffic cone rather than an orange spike. ' +
              'Light and desaturated works; a mid tone close to the cone reads as mud.',
  },
  base: {
    type: 'color', default: '#2E3134', label: 'Base',
    describe: 'Albedo of the square ballast plate under the cone. Wants to be the darkest ' +
              'value on the object so the plate reads as a rubber pad on the pavement ' +
              'rather than as part of the cone. Unused when `basePlate` is off.',
  },
  tallness: {
    type: 'range', default: 0.70, min: 0.55, max: 0.90, affects: 'geometry',
    label: 'Tallness',
    describe: 'Overall height of the cone in metres, REBUILT rather than scaled. The plate, ' +
              'the skirt and the tape sleeves are fixed real-world sections that never ' +
              'change size; what changes is the length of the taper and, because the band ' +
              'pitch is a constant 0.191 m, HOW MANY sleeves fit on it — so the triangle ' +
              'count moves with the knob (280 tris at 0.55, 376 at 0.70, 472 at 0.90). ' +
              '0.55 = a short single-band work cone, 0.70 = the standard two-band road cone ' +
              'in the references, 0.90 = a tall three-band motorway cone. The second band ' +
              'appears at 0.61 m and the third at 0.81 m, so the knob steps the silhouette ' +
              'at those two heights.',
  },
  facets: {
    type: 'range', default: 12, min: 8, max: 16, affects: 'geometry',
    label: 'Facets',
    describe: 'Number of facet columns around the cone, snapped to the nearest EVEN value ' +
              '(an odd count would stand the prop on a vertex and break its mirror ' +
              'symmetry). 8 is a blunt, obviously hand-faceted chunk that reads as a ' +
              'low-poly toy; 12 matches the references; 16 is a smooth cone for hero ' +
              'foreground placement. Drives the triangle count directly.',
  },
  basePlate: {
    type: 'toggle', default: true, affects: 'geometry',
    label: 'Base plate',
    describe: 'The square charcoal ballast plate under the cone. On (default) is the ' +
              'weighted road cone of the references. Off removes the plate entirely and ' +
              'closes the skirt with a recessed underside cap, giving the lighter ' +
              'stackable cone that sits straight on the pavement — the footprint drops from ' +
              '0.44 m square to the 0.364 m skirt circle.',
  },
};

function resolve(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const clamp = (v, k) => Math.min(params[k].max, Math.max(params[k].min, v ?? params[k].default));
  return {
    cone: p.cone ?? cw.cone,
    band: p.band ?? cw.band,
    base: p.base ?? cw.base,
    H: clamp(p.tallness, 'tallness'),
    seg: Math.max(8, Math.min(16, 2 * Math.round(clamp(p.facets, 'facets') / 2))),
    plate: p.basePlate ?? params.basePlate.default,
  };
}

function prep(geo, colorFn) {
  geo = geo.toNonIndexed();
  geo.deleteAttribute('uv');
  geo.deleteAttribute('normal');
  const pos = geo.attributes.position;
  const n = pos.count;
  const col = new Float32Array(n * 3);
  const c = new THREE.Color();
  for (let i = 0; i < n; i += 3) {
    const cy = (pos.getY(i) + pos.getY(i + 1) + pos.getY(i + 2)) / 3;
    c.set(colorFn(cy));
    for (let k = 0; k < 3; k++) {
      col[(i + k) * 3] = c.r; col[(i + k) * 3 + 1] = c.g; col[(i + k) * 3 + 2] = c.b;
    }
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  return geo;
}

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, typeof p.c === 'function' ? p.c : () => p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function disc(r, y, seg, up) {
  const pos = [];
  const ring = [];
  for (let i = 0; i < seg; i++) {
    const phi = (i / seg) * Math.PI * 2;
    ring.push([Math.sin(phi) * r, y, Math.cos(phi) * r]);
  }
  for (let i = 0; i < seg; i++) {
    const a = ring[i], b = ring[(i + 1) % seg];
    const [p, q] = up ? [a, b] : [b, a];
    pos.push(0, y, 0, p[0], p[1], p[2], q[0], q[1], q[2]);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

const HALF   = 0.220;
const BEV    = 0.010;
const BT     = 0.007;
const SLAB   = 0.032;

const R_FOOT = 0.182;
const Y_BED  = 0.012;
const Y_LIP  = 0.048;
const Y_CONE = 0.135;
const R_CONE = 0.116;
const SCOOP  = 1.7;
const R_TIP  = 0.032;
const TIP_CH = 0.012;
const TIP_IN = 0.008;
const REC_R  = 0.014;
const REC_Y  = 0.016;

const BAND_H  = 0.107;
const PITCH   = 0.191;
const TOP_OFF = 0.133;
const PROUD   = 0.006;
const CHAM    = 0.006;

function bandRanges(H) {
  const out = [];
  const floor = Y_CONE + 0.045;
  for (let k = 0; k < 8; k++) {
    const top = H - TOP_OFF - k * PITCH;
    if (top - BAND_H < floor) break;
    out.push([top - BAND_H, top]);
  }
  return out.reverse();
}

export function createAsset(userParams = {}) {
  const P = resolve(userParams);
  const H = P.H, SEG = P.seg;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  if (P.plate) {
    const a = HALF - BEV;
    const shape = new THREE.Shape();
    shape.moveTo(a, a); shape.lineTo(-a, a); shape.lineTo(-a, -a); shape.lineTo(a, -a);
    shape.closePath();
    const slab = new THREE.ExtrudeGeometry(shape, {
      depth: SLAB - 2 * BT, bevelEnabled: true,
      bevelThickness: BT, bevelSize: BEV, bevelOffset: 0, bevelSegments: 1,
    });
    slab.rotateX(-Math.PI / 2).translate(0, BT, 0);
    add(slab, P.base);
  }

  const yFoot = P.plate ? Y_BED : 0;
  const yTip = H - TIP_CH;
  const rCone = (y) => R_CONE + (R_TIP - R_CONE) * (y - Y_CONE) / (yTip - Y_CONE);

  const profile = [];
  if (!P.plate) profile.push([R_FOOT - REC_R, REC_Y]);
  profile.push([R_FOOT, yFoot]);
  profile.push([R_FOOT, Y_LIP]);
  for (let i = 1; i <= 3; i++) {
    const y = Y_LIP + (Y_CONE - Y_LIP) * i / 3;
    const t = (Y_CONE - y) / (Y_CONE - Y_LIP);
    profile.push([R_CONE + (R_FOOT - R_CONE) * Math.pow(t, SCOOP), y]);
  }

  const bands = bandRanges(H);
  for (const [lo, hi] of bands) {
    profile.push([rCone(lo), lo]);
    profile.push([rCone(lo + CHAM) + PROUD, lo + CHAM]);
    profile.push([rCone(hi - CHAM) + PROUD, hi - CHAM]);
    profile.push([rCone(hi), hi]);
  }

  const rTop = R_TIP - TIP_IN;
  profile.push([R_TIP, yTip]);
  profile.push([rTop, H]);

  const lathe = new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(r, y)), SEG);
  const inBand = (y) => bands.some(([lo, hi]) => y > lo && y < hi);
  add(lathe, (y) => (inBand(y) ? P.band : P.cone));

  add(disc(rTop, H, SEG, true), P.cone);
  if (!P.plate) add(disc(R_FOOT - REC_R, REC_Y, SEG, false), P.cone);

  const g = new THREE.Group();
  g.name = 'traffic-cone';
  const mesh = finish(parts);
  mesh.name = 'cone';
  g.add(mesh);
  return g;
}

export const rig = {};
export const detach = [];

export const night = {};

export default createAsset;

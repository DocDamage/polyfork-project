/*
 * Fuel Tank
 * https://polyfork.dev/asset/fuel-tank-3a0111
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './fuel-tank-3a0111.mjs';
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
 *   colorway     choice  'off-white'    'off-white' | 'gunmetal' | 'regolith-tan' | 'deep-navy'
 *   hull         color   '#b4b7bc'      any hex or THREE.Color
 *   band         color   '#b2684b'      any hex or THREE.Color
 *   leg          color   '#5f6570'      any hex or THREE.Color
 *   pad          color   '#737785'      any hex or THREE.Color
 *   tallness     range   1              0.7 to 1.18
 *   facets       choice  '12'           '8' | '12' | '16'
 *   legs         choice  '4'            '3' | '4' | '6'
 *   manway       toggle  false          true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/fuel-tank-3a0111-params.json
 *
 * SPECS  416 triangles, 1 material, 2.6 x 4 x 2.6 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'off-white':    { hull: 0xb4b7bc, band: 0xb2684b, leg: 0x5f6570, pad: 0x737785 },
  'gunmetal':     { hull: 0x878c94, band: 0xb2684b, leg: 0x3d3f47, pad: 0x5f6570 },
  'regolith-tan': { hull: 0xc1a078, band: 0x975b44, leg: 0x5b4337, pad: 0x856f5d },
  'deep-navy':    { hull: 0xb4b7bc, band: 0x434e67, leg: 0x3d3f47, pad: 0x5f6570 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'off-white', label: 'Colorway',
              options: ['off-white', 'gunmetal', 'regolith-tan', 'deep-navy'],
              describe: 'curated kit-legal paint scheme; sets all four zone albedos at once. off-white = the shipped astro-orange-on-white fuel tank; gunmetal = darker service-grey hull, same orange band; regolith-tan = dusty tan hull with a rust band and brown legs (reads as a weathered field tank); deep-navy = white hull with a navy band instead of orange (reads as water/coolant rather than fuel)' },

  hull: { type: 'color', default: '#b4b7bc', label: 'Hull',
          describe: 'albedo of the whole pressure vessel — straight barrel, shoulder dome, bottom cone, bottom disc and any girth stiffener ribs. ONE flat albedo over every facet; this is the mass that dominates the part' },
  band: { type: 'color', default: '#b2684b', label: 'Hazard band',
          describe: 'albedo of the proud hazard ring around the upper barrel — the only saturated accent on the part. Push it far from the hull value or the ring stops reading at thumbnail size' },
  leg:  { type: 'color', default: '#5f6570', label: 'Saddle legs',
          describe: 'albedo of the radial saddle leg plates under the tank, and of the manway fitting on the dome when it is switched on. Wants a hard dark step off the hull' },
  pad:  { type: 'color', default: '#737785', label: 'Foot plates',
          describe: 'albedo of the bolted foot plate each leg lands on. Keep it one step LIGHTER than the legs or the feet crush to black in low camera angles' },

  tallness: { type: 'range', default: 1.0, min: 0.7, max: 1.18, label: 'Tallness', icon: '↕️', affects: 'geometry',
              describe: 'length of the straight barrel run only: 0.70 = 1.75 m barrel / 3.25 m overall (a squat drum on tall legs), 1.00 = the shipped 2.50 m barrel / 4.00 m overall, 1.18 = 2.95 m barrel / 4.45 m overall. This REBUILDS rather than scales: the cone, the shoulder dome, the leg plates, the foot plates and the hazard band all keep their exact shipped size and the daylight gap under the hull stays 0.58 m, so only the barrel run changes. A plain barrel has nothing repeating in it, so the repeat that height drags is the GIRTH STIFFENER RIB: the lower barrel carries one rib per 1.20 m of plain run below the hazard band, which means 0 ribs up to tallness 1.04 and 1 rib from 1.045 upward (+72 triangles at 12 facets)' },
  facets: { type: 'choice', default: '12', label: 'Facet count', icon: '⬡', affects: 'geometry',
            options: ['8', '12', '16'],
            describe: 'radial facet count of the hull, hazard band and stiffener ribs: 8 = a chunky octagonal drum with ~0.96 m planes and hard corner highlights, 12 = the shipped read (~0.65 m planes), 16 = a near-round tank with ~0.49 m planes that reads smooth from 10 m. Diameter across the corners stays 2.50 m at every value; the legs step inboard as the count drops so their plates never pierce a facet' },
  legs: { type: 'choice', default: '4', label: 'Leg count', icon: '🦵', affects: 'geometry',
          options: ['3', '4', '6'],
          describe: 'number of radial saddle legs and foot plates, evenly spaced with one always dead-centre on the +Z front face: 3 = a wide-stanced tripod with big daylight gaps, 4 = the shipped square stance, 6 = a dense skirt of blades that reads almost as a plinth. Leg plate section (0.26 x 0.30 m), height and foot plate are identical at every count — only the count changes' },
  manway: { type: 'toggle', default: false, label: 'Manway hatch', icon: '🔩', affects: 'geometry',
            describe: 'optional bolted inspection manway standing proud of the shoulder dome — a 0.72 m gunmetal neck capped by a wider 0.88 m lipped lid, adding 0.14 m to the overall height and breaking the dome silhouette. OFF = the shipped clean dome closing to a small flat cap facet' },
};

export const rig = {};
export const detach = [];

export const night = {};

const R        = 1.25;
const Y_BOT    = 0.58;
const Y_BARREL = 0.92;
const BARREL_0 = 2.50;
const DOME_H   = 0.58;
const BAND_H = 0.44, BAND_OUT = 0.05;
const BAND_F = 0.544;
const RIB_PITCH = 1.20;
const RIB_OUT = 0.05, RIB_H = 0.06;

const LEG_H    = 1.05, LEG_W = 0.26, LEG_T = 0.30, LEG_R0 = 1.04;
const PAD_H    = 0.06;

const r4 = (x) => Math.round(x * 1e4) / 1e4;
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

const ZONE_KEYS = ['hull', 'band', 'leg', 'pad'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['off-white'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.hull) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
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

function finish(list) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function annulus(rIn, rOut, y, seg, faceUp) {
  const pos = [];
  const p = (r, i) => {
    const a = (i / seg) * Math.PI * 2;
    return [Math.cos(a) * r, y, Math.sin(a) * r];
  };
  for (let i = 0; i < seg; i++) {
    const i0 = p(rIn, i), i1 = p(rIn, i + 1), o0 = p(rOut, i), o1 = p(rOut, i + 1);
    if (faceUp) quad(pos, i0, i1, o1, o0);
    else quad(pos, i0, o0, o1, i1);
  }
  return posGeo(pos);
}

function chamferPlate(w, t, h, cut, noCaps) {
  const hw = w / 2, ht = t / 2;
  const shape = new THREE.Shape([
    new THREE.Vector2(-hw + cut, -ht), new THREE.Vector2(hw - cut, -ht),
    new THREE.Vector2(hw, -ht + cut), new THREE.Vector2(hw, ht - cut),
    new THREE.Vector2(hw - cut, ht), new THREE.Vector2(-hw + cut, ht),
    new THREE.Vector2(-hw, ht - cut), new THREE.Vector2(-hw, -ht + cut),
  ]);
  let g = new THREE.ExtrudeGeometry(shape, { depth: h, bevelEnabled: false });
  if (noCaps) {
    const w1 = g.groups.find(gr => gr.materialIndex === 1);
    const a = g.attributes.position.array;
    g = posGeo(Array.from(a.slice(w1.start * 3, (w1.start + w1.count) * 3)));
  }
  g.rotateX(-Math.PI / 2);
  return g;
}

function hullProfile(yShldr, ribYs) {
  const p = [
    [0.00, Y_BOT],
    [0.72, Y_BOT],
    [0.88, r4(Y_BOT + 0.06)],
    [R,    Y_BARREL],
  ];
  for (const y of ribYs) {
    p.push([R, r4(y - RIB_H)], [r4(R + RIB_OUT), y], [R, r4(y + RIB_H)]);
  }
  p.push(
    [R,    yShldr],
    [1.17, r4(yShldr + 0.20)],
    [0.97, r4(yShldr + 0.40)],
    [0.58, r4(yShldr + 0.54)],
    [0.00, r4(yShldr + DOME_H)],
  );
  return p;
}

function lathe(profile, seg) {
  const g = new THREE.LatheGeometry(profile.map(([r, y]) => new THREE.Vector2(r, y)), seg)
    .toNonIndexed();
  const p = g.attributes.position.array, keep = [];
  const same = (i, j) => p[i] === p[j] && p[i + 1] === p[j + 1] && p[i + 2] === p[j + 2];
  for (let t = 0; t < p.length; t += 9) {
    if (same(t, t + 3) || same(t + 3, t + 6) || same(t, t + 6)) continue;
    for (let k = 0; k < 9; k++) keep.push(p[t + k]);
  }
  return posGeo(keep);
}

const DEFAULTS = { colorway: 'off-white', tallness: 1, facets: '12', legs: '4', manway: false };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const tall = clamp(num(o.tallness, 1), 0.7, 1.18);
  const SEG = [8, 12, 16].includes(parseInt(o.facets, 10)) ? parseInt(o.facets, 10) : 12;
  const nLeg = [3, 4, 6].includes(parseInt(o.legs, 10)) ? parseInt(o.legs, 10) : 4;
  const manwayOn = !(o.manway === false || o.manway === 'false' || o.manway === 0 ||
                     o.manway === undefined || o.manway === null);

  const barrel  = r4(BARREL_0 * tall);
  const yShldr  = r4(Y_BARREL + barrel);
  const yTop    = r4(yShldr + DOME_H);
  const bandY   = r4(Y_BARREL + BAND_F * barrel);
  const bandY0  = r4(bandY - BAND_H / 2), bandY1 = r4(bandY + BAND_H / 2);

  const lower = r4(bandY0 - Y_BARREL);
  const nRib = Math.max(0, Math.floor(lower / RIB_PITCH));
  const ribYs = [];
  for (let i = 0; i < nRib; i++) ribYs.push(r4(Y_BARREL + (lower * (i + 1)) / (nRib + 1)));

  const apo = r4(R * Math.cos(Math.PI / SEG));
  const legR = Math.min(LEG_R0, r4(apo - LEG_W / 2 - 0.037));

  const parts = [];
  const add = (geo, c) => parts.push({ g: geo, c });

  add(lathe(hullProfile(yShldr, ribYs), SEG), C.hull);

  const rB = r4(R + BAND_OUT), rLedge = r4(apo - 0.01);
  add(new THREE.CylinderGeometry(rB, rB, BAND_H, SEG, 1, true).translate(0, bandY, 0), C.band);
  add(annulus(rLedge, rB, bandY1, SEG, true), C.band);
  add(annulus(rLedge, rB, bandY0, SEG, false), C.band);

  for (let i = 0; i < nLeg; i++) {
    const a = Math.PI / 2 + (i / nLeg) * Math.PI * 2;
    const cx = r4(Math.cos(a) * legR), cz = r4(Math.sin(a) * legR);

    const leg = chamferPlate(LEG_W, LEG_T, LEG_H, 0.05, true);
    leg.rotateY(-a);
    leg.translate(cx, PAD_H - 0.03, cz);
    add(leg, C.leg);

    const pad = chamferPlate(LEG_W + 0.04, LEG_T + 0.06, PAD_H, 0.035, false);
    pad.rotateY(-a);
    pad.translate(cx, 0, cz);
    add(pad, C.pad);
  }

  if (manwayOn) {
    add(lathe([
      [0.36, r4(yTop - 0.30)],
      [0.36, r4(yTop + 0.08)],
      [0.44, r4(yTop + 0.10)],
      [0.44, r4(yTop + 0.14)],
      [0.00, r4(yTop + 0.14)],
    ], 6), C.leg);
  }

  const g = new THREE.Group();
  g.name = 'fuel-tank';
  const mesh = finish(parts);
  mesh.name = 'fuel-tank-mesh';
  g.add(mesh);
  return g;
}

export default createAsset;

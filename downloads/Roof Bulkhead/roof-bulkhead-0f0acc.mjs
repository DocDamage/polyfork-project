/*
 * Roof Bulkhead
 * https://polyfork.dev/asset/roof-bulkhead-0f0acc
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './roof-bulkhead-0f0acc.mjs';
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
 *   colorway     choice  'warm-gray'    'warm-gray' | 'brownstone' | 'oxide-red' | 'service-green'
 *   wall         color   '#b5aea0'      any hex or THREE.Color
 *   stone        color   '#ece5d3'      any hex or THREE.Color
 *   door         color   '#3f4247'      any hex or THREE.Color
 *   hardware     color   '#6f8fa0'      any hex or THREE.Color
 *   brass        color   '#e8a825'      any hex or THREE.Color
 *   lowEnd       range   1.38           1.02 to 1.86 (metres)
 *   pilasters    range   0              0 to 3
 *   hood         toggle  false          true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/roof-bulkhead-0f0acc-params.json
 *
 * SPECS  336 triangles, 1 material, 2.5 x 2.89 x 3.54 m (real-world scale).
 * PARTS  animate: door
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'warm-gray':     { wall: 0xb5aea0, stone: 0xece5d3, door: 0x3f4247, hardware: 0x6f8fa0, brass: 0xe8a825 },
  'brownstone':    { wall: 0x8a5a44, stone: 0xece5d3, door: 0x3f4247, hardware: 0x6f8fa0, brass: 0xe8a825 },
  'oxide-red':     { wall: 0xa34a38, stone: 0xb5aea0, door: 0x3f4247, hardware: 0x6f8fa0, brass: 0xe8a825 },
  'service-green': { wall: 0xb5aea0, stone: 0xece5d3, door: 0x3d6b52, hardware: 0x3f4247, brass: 0xe8a825 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'warm-gray', label: 'Colorway',
    options: ['warm-gray', 'brownstone', 'oxide-red', 'service-green'],
    describe: 'curated paint scheme; sets every zone albedo. warm-gray = the shipped warm concrete box with a pale cast-stone cap; brownstone = brown masonry walls under the same pale cap; oxide-red = painted red-oxide walls with a grey concrete cap; service-green = warm concrete with a green painted service door and charcoal hardware',
  },
  wall: {
    type: 'color', default: '#b5aea0', label: 'Concrete',
    describe: 'albedo of the poured-concrete wall mass — all four walls plus the front wall plate around the door opening; roughly 65% of the visible surface',
  },
  stone: {
    type: 'color', default: '#ece5d3', label: 'Cast stone',
    describe: 'albedo of every cast-stone member: both coping tiers, the four corner piers, any side pilasters, the door architrave and the optional door hood. This is the lightest value on the object',
  },
  door: {
    type: 'color', default: '#3f4247', label: 'Door leaf',
    describe: 'albedo of the steel door leaf and of the panel lining its recess, so the reveal around the leaf reads as one dark void. Darkest value on the object',
  },
  hardware: {
    type: 'color', default: '#6f8fa0', label: 'Hardware',
    describe: 'albedo of the two edge hinges and the handle backplates on both faces of the leaf; sits one value step above the door leaf so the fittings read against it',
  },
  brass: {
    type: 'color', default: '#e8a825', label: 'Lever',
    describe: 'albedo of the two brass lever bars only — the single warm accent fleck on the object',
  },
  lowEnd: {
    type: 'range', default: 1.38, min: 1.02, max: 1.86, label: 'Low end', affects: 'geometry',
    describe: 'height in metres of the wall top at the low (rear) end; the door end stays 2.70 m, so this knob sets the mono-pitch roof angle and the whole wedge silhouette. 1.02 = a steep ~38 deg ramp and a near-triangular wedge, 1.38 (default) = the brief ~32 deg ramp with the tall end almost exactly 2x the low end, 1.86 = a shallow ~21 deg ramp reading as a nearly flat-roofed box. The coping cap, its kink and the rear corner piers all rebuild to follow the new roof line; the overall bounding box does not change. NOTE this asset has no honest size knob in X or Z — a plain rectilinear box has nothing repeating along either axis, so widening or lengthening it would only stretch coordinates',
  },
  pilasters: {
    type: 'range', default: 0, min: 0, max: 3, label: 'Side pilasters', affects: 'geometry',
    describe: 'integer count of extra cast-stone pilaster ribs added to EACH long side wall, evenly spaced between the corner piers. Same section as the corner piers (0.35 m wide, standing 0.07 m proud of the wall) and full height, with the top following the sloped roof line up under the coping. 0 (default) = the shipped plain walls, 3 = a heavily ribbed utility bulkhead. Costs ~14 tris per rib',
  },
  hood: {
    type: 'toggle', default: false, label: 'Door hood', affects: 'geometry',
    describe: 'optional cast-stone drip hood cantilevered over the door architrave — a chamfered 1.48 x 0.10 m slab projecting 0.25 m from the wall face, overshooting the architrave head by 0.06 m each side. off (default) = the brief bare-wall stripe between the head and the coping; on = a second shadow line over the doorway. Sits inside the coping overhang, so the bounding box is unchanged',
  },
};

export const rig = {
  'door': { axis: 'y', range: [0, -100] },
};

export const detach = [];

export const night = {};

const XB = 1.06;
const ZF = 1.39, ZR = -1.53;
const Y_HI = 2.70;
const Y_LO_DEF = 1.38;
const Z_KINK = -0.75;

const XP = 1.13, PIER_IN = 0.76;
const PIER_CH = 0.055;
const PIER_PROUD = XP - XB;

const PLATE_Z = 1.51;
const OP_X = 0.47, OP_Y = 2.20;
const ARCH_Z = 1.57;
const PIER_Z = 1.62;
const LEAF_W = 0.90, LEAF_H = 2.15, LEAF_T = 0.09;

const CAP_LO = 0.09, CAP_HI = 0.19;
const XC1 = 1.21, XC2 = 1.25;
const ZC1F = 1.74, ZC1R = -1.72;
const ZC2F = 1.78, ZC2R = -1.76;

const BURY = 0.04;

const MATERIAL = new THREE.MeshStandardMaterial({
  vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
});

const ZONE_KEYS = ['wall', 'stone', 'door', 'hardware', 'brass'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};

function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['warm-gray'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.wall) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));

const q = (v) => Math.round(v * 1e9) / 1e9;

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

function finish(list, name) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const m = new THREE.Mesh(merged, MATERIAL);
  m.name = name;
  return m;
}

function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function cbox(w, h, d, ch, x, y, z) {
  const hw = w / 2 - ch, hd = d / 2 - ch;
  const s = new THREE.Shape();
  s.moveTo(-hw, -hd); s.lineTo(hw, -hd); s.lineTo(hw, hd); s.lineTo(-hw, hd); s.closePath();
  const g = new THREE.ExtrudeGeometry(s, {
    depth: h - 2 * ch, bevelEnabled: true,
    bevelThickness: ch, bevelSize: ch, bevelSegments: 1, curveSegments: 1,
  });
  g.rotateX(-Math.PI / 2);
  g.translate(0, -(h - 2 * ch) / 2, 0);
  g.translate(x, y, z);
  return g;
}

function prismX(profile, width, x0) {
  const s = new THREE.Shape(profile.map(p => new THREE.Vector2(p[0], p[1])));
  const g = new THREE.ExtrudeGeometry(s, { depth: width, bevelEnabled: false, curveSegments: 1 });
  g.rotateY(-Math.PI / 2);
  g.translate(x0 + width, 0, 0);
  return g;
}

function prismY(profile, y0, y1) {
  const s = new THREE.Shape(profile.map(p => new THREE.Vector2(p[0], -p[1])));
  const g = new THREE.ExtrudeGeometry(s, { depth: y1 - y0, bevelEnabled: false, curveSegments: 1 });
  g.rotateX(-Math.PI / 2);
  g.translate(0, y0, 0);
  return g;
}

function pier(sx, zOut, zIn, yTop) {
  const c = PIER_CH, sgn = Math.sign(zOut - zIn);
  const xo = sx * XP, xi = sx * PIER_IN;

  return prismY([
    [xi, zIn],
    [xo, zIn],
    [xo, zOut - sgn * c],
    [xo - sx * c, zOut],
    [xi + sx * c, zOut],
    [xi, zOut - sgn * c],
  ], 0, yTop);
}

const DEFAULTS = { colorway: 'warm-gray', lowEnd: Y_LO_DEF, pilasters: 0, hood: false };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const Y_LO = q(clamp(num(o.lowEnd, Y_LO_DEF), 1.02, 1.86));
  const nRib = Math.round(clamp(num(o.pilasters, 0), 0, 3));
  const hoodOn = !(o.hood === false || o.hood === 'false' || o.hood === 0 || o.hood == null);

  const SLOPE = (Y_HI - Y_LO) / (ZF - Z_KINK);

  const topY = (z) => {
    if (z >= ZF) return Y_HI;
    if (z <= Z_KINK) return Y_LO;
    return Y_LO + (z - Z_KINK) * SLOPE;
  };

  const g = new THREE.Group();
  g.name = 'roof-bulkhead';
  const parts = [];
  const add = (geo, c) => parts.push({ g: geo, c });

  add(prismX([
    [ZR, 0], [ZF, 0], [ZF, Y_HI], [Z_KINK, Y_LO], [ZR, Y_LO],
  ], XB * 2, -XB), C.wall);

  add(pier(-1, PIER_Z, ZF - 0.12, Y_HI), C.stone);
  add(pier( 1, PIER_Z, ZF - 0.12, Y_HI), C.stone);
  add(pier(-1, ZR - 0.07, ZR + 0.25, Y_LO + BURY), C.stone);
  add(pier( 1, ZR - 0.07, ZR + 0.25, Y_LO + BURY), C.stone);

  if (nRib > 0) {
    const zA = ZR + 0.25, zB = ZF - 0.12;
    const PW = 0.35, run = zB - zA;
    for (let k = 0; k < nRib; k++) {
      const zc = zA + ((k + 1) * run) / (nRib + 1);
      const z0 = zc - PW / 2, z1 = zc + PW / 2;
      const prof = [[z0, 0], [z1, 0], [z1, topY(z1) + BURY]];
      if (z0 < Z_KINK && z1 > Z_KINK) prof.push([Z_KINK, topY(Z_KINK) + BURY]);
      prof.push([z0, topY(z0) + BURY]);
      add(prismX(prof, PIER_PROUD + 0.02, XB - 0.02), C.stone);
      add(prismX(prof, PIER_PROUD + 0.02, -XP), C.stone);
    }
  }

  const pw = PLATE_Z - ZF, pz = (ZF + PLATE_Z) / 2, plateTop = Y_HI + BURY;
  add(box(XB - OP_X, OP_Y, pw, -(OP_X + XB) / 2, OP_Y / 2, pz), C.wall);
  add(box(XB - OP_X, OP_Y, pw,  (OP_X + XB) / 2, OP_Y / 2, pz), C.wall);
  add(box(XB * 2, plateTop - OP_Y, pw, 0, (OP_Y + plateTop) / 2, pz), C.wall);

  add(box(OP_X * 2, OP_Y, 0.04, 0, OP_Y / 2, ZF), C.door);

  const aw = ARCH_Z - PLATE_Z, az = (PLATE_Z + ARCH_Z) / 2;
  add(box(0.14, OP_Y, aw, -(OP_X + 0.07), OP_Y / 2, az), C.stone);
  add(box(0.14, OP_Y, aw,  (OP_X + 0.07), OP_Y / 2, az), C.stone);
  add(box(1.36, 0.22, aw, 0, OP_Y + 0.11, az), C.stone);

  if (hoodOn) {
    add(cbox(1.48, 0.10, 0.28, 0.02, 0, OP_Y + 0.25, 1.62), C.stone);
  }

  const capProfile = (zR, zF, lo, hi) => {
    const zs = [zR, Z_KINK, ZF, zF];
    const up = zs.map(z => [z, topY(z) + hi]);
    const dn = zs.map(z => [z, topY(z) + lo]).reverse();
    return dn.concat(up);
  };
  add(prismX(capProfile(ZC1R, ZC1F, -0.01, CAP_LO), XC1 * 2, -XC1), C.stone);
  add(prismX(capProfile(ZC2R, ZC2F, CAP_LO - 0.01, CAP_HI), XC2 * 2, -XC2), C.stone);

  g.add(finish(parts, 'bulkhead-shell'));

  const door = new THREE.Group();
  door.name = 'door';
  door.position.set(-LEAF_W / 2, 0, PLATE_Z);
  {
    const d = [];
    const y0 = 0.03;

    d.push({ g: cbox(LEAF_W, LEAF_H, LEAF_T, 0.014, LEAF_W / 2, y0 + LEAF_H / 2, -LEAF_T / 2), c: C.door });

    for (const hy of [0.36, 1.86]) {
      d.push({ g: box(0.06, 0.17, LEAF_T + 0.015, 0.02, hy, -LEAF_T / 2), c: C.hardware });
    }

    for (const s of [1, -1]) {
      const zf = s > 0 ? 0 : -LEAF_T;
      d.push({ g: box(0.08, 0.19, 0.025, 0.75, 1.06, zf + s * 0.0125), c: C.hardware });
      d.push({ g: box(0.16, 0.04, 0.04, 0.70, 1.06, zf + s * 0.045), c: C.brass });
    }
    door.add(finish(d, 'door-leaf'));
  }
  g.add(door);

  g.updateMatrixWorld(true);
  const bb = new THREE.Box3().setFromObject(g);
  const dx = -(bb.min.x + bb.max.x) / 2, dy = -bb.min.y, dz = -(bb.min.z + bb.max.z) / 2;
  for (const child of g.children) child.position.set(
    child.position.x + dx, child.position.y + dy, child.position.z + dz,
  );

  return g;
}

export default createAsset;

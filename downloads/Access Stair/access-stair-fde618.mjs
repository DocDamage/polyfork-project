/*
 * Access Stair
 * https://polyfork.dev/asset/access-stair-fde618
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './access-stair-fde618.mjs';
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
 *   colorway   choice  'astro-orange' 'astro-orange' | 'regolith-tan' | 'gunmetal' | 'deep-navy' | 'rust-brown'
 *   frame      color   '#b2684b'      any hex or THREE.Color
 *   brace      color   '#975b44'      any hex or THREE.Color
 *   tread      color   '#5f6570'      any hex or THREE.Color
 *   rail       color   '#b4b7bc'      any hex or THREE.Color
 *   risers     range   10             7 to 12
 *   handrails  choice  'both'         'both' | 'right' | 'none'
 *   bracing    choice  'legs'         'legs' | 'trussed' | 'none'
 *
 * Every option is described in full at https://polyfork.dev/cdn/access-stair-fde618-params.json
 *
 * SPECS  496 triangles, 1 material, 2 x 3.87 x 3.3 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const COLORWAYS = {
  'astro-orange': { frame: 0xb2684b, brace: 0x975b44, tread: 0x5f6570, rail: 0xb4b7bc },
  'regolith-tan': { frame: 0xc1a078, brace: 0xac7c64, tread: 0x5f6570, rail: 0x989ea7 },
  'gunmetal':     { frame: 0x878c94, brace: 0x737785, tread: 0x3d3f47, rail: 0xb4b7bc },
  'deep-navy':    { frame: 0x434e67, brace: 0x3d3f47, tread: 0x5f6570, rail: 0x989ea7 },
  'rust-brown':   { frame: 0x73594d, brace: 0x5b4337, tread: 0x3e2f2b, rail: 0x989ea7 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: { type: 'choice', default: 'astro-orange', label: 'Colorway',
              options: ['astro-orange', 'regolith-tan', 'gunmetal', 'deep-navy', 'rust-brown'],
              describe: 'curated kit-palette scheme; sets all four zone albedos at once (astro-orange painted steel over gunmetal treads, regolith tan, bare gunmetal utility, deep navy, weathered rust brown)' },
  frame: { type: 'color', default: '#b2684b', label: 'Frame',
           describe: 'albedo of the painted structural steel: both stringers, the side beams over the landing, the back wall frame and the foot blocks — the dominant mass' },
  brace: { type: 'color', default: '#975b44', label: 'Bolted members',
           describe: 'albedo of the bolted-on members: the sunk hatch panel in the back wall and the under-stair legs, ties and diagonals; one value step off the frame' },
  tread: { type: 'color', default: '#5f6570', label: 'Treads',
           describe: 'albedo of the walking surfaces — all open-riser tread slabs and the landing deck plate' },
  rail: { type: 'color', default: '#b4b7bc', label: 'Handrail',
          describe: 'albedo of the bare alloy handrails, their posts and the drop post over the landing; the lightest, slimmest zone' },
  risers: { type: 'range', default: 10, min: 7, max: 12, label: 'Risers', icon: '📏', affects: 'geometry',
            describe: 'number of 0.30 m risers, i.e. the flight is REBUILT: deck height = risers x 0.30 m (10 = exactly one 3 m storey, 7 = a 2.10 m mezzanine, 12 = a 3.60 m high deck). Treads are added at the constant 0.30 m pitch and rail posts at 0.75 m (2 posts a side at 7 risers, 4 at 12), so the triangle count moves with the knob; every member section, the bracing stations, the back wall and the landing stay put and the flight grows forward only (depth 2.40 m to 3.90 m, still inside one 4 m cell)' },
  handrails: { type: 'choice', default: 'both', label: 'Handrails', icon: '🛗', affects: 'geometry',
               options: ['both', 'right', 'none'],
               describe: 'which sides carry the alloy rail assembly (rake, landing return, drop post and posts): both = the default pair, right = only the +X side so the flight can hug a wall on the left, none = a bare open frame for a service/cargo run' },
  bracing: { type: 'choice', default: 'legs', label: 'Under-stair bracing', icon: '🪜', affects: 'geometry',
             options: ['legs', 'trussed', 'none'],
             describe: 'the open frame under the flight, per side: legs = the default tall back leg, a mid-run leg and the low tie beam between them (a flight of 7-8 risers is too short for the mid leg and ships the back leg alone); trussed = the same legs plus a diagonal strut per bay landing on the leg foot and the next leg head, and a transverse cross-brace between the two back legs, which reads as a gantry truss; none = legs and ties removed, the flight carried on its stringers alone and the underside fully open' },
};

export const rig = {};
export const detach = [];
export const night = {};

const ZONE_KEYS = ['frame', 'brace', 'tread', 'rail'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['astro-orange'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {

    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.frame) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF;
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const q = (v) => Math.round(v * 1e6) / 1e6;

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

const box = (w, h, d, x, y, z) => new THREE.BoxGeometry(w, h, d).translate(x, y, z);

function prismZY(pts, width, xCenter) {
  const shape = new THREE.Shape(pts.map(([z, y]) => new THREE.Vector2(-z, y)));
  const geo = new THREE.ExtrudeGeometry(shape, { depth: width, bevelEnabled: false });
  geo.rotateY(Math.PI / 2);
  geo.translate(xCenter - width / 2, 0, 0);
  return geo;
}

function strut(section, z1, y1, z2, y2, x) {
  const dz = z2 - z1, dy = y2 - y1, len = Math.hypot(dz, dy);
  const g = new THREE.BoxGeometry(section, len, section);
  g.rotateX(Math.atan2(dz, dy));
  g.translate(x, (y1 + y2) / 2, (z1 + z2) / 2);
  return g;
}

const RISE = 0.30;
const HALF_W = 1.00;

const STR_W = 0.16, STR_X = HALF_W - STR_W / 2 - 0.003;
const STR_DEPTH = 0.48;
const TREAD_T = 0.08, TREAD_D = 0.34, TREAD_HX = 0.88;

const BACK_Z = -1.70;
const WALL_D = 0.20;
const STR_TOP_Z = -1.20;
const DECK_D = STR_TOP_Z - BACK_Z;
const LEG_S = 0.14;
const LEG_PITCH = 1.47;
const POST_PITCH = 0.75;

const DEFAULTS = { colorway: 'astro-orange', risers: 10, handrails: 'both', bracing: 'legs' };

export function createAsset(opts = {}) {
  const o = { ...DEFAULTS, ...opts };
  const C = zonesFor(String(o.colorway), o);
  const N = Math.round(clamp(num(o.risers, 10), 7, 12));
  const rails = ['both', 'right', 'none'].includes(String(o.handrails)) ? String(o.handrails) : 'both';
  const brace = ['legs', 'trussed', 'none'].includes(String(o.bracing)) ? String(o.bracing) : 'legs';
  const STEPS = N - 1;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const DECK_Y = q(RISE * N);
  const WALL_H = q(DECK_Y - TREAD_T);
  const A = q(WALL_H + STR_TOP_Z);
  const TREAD_LINE = q(A + 0.18);
  const TOE_Z = q(A - 0.22);
  const GROUND_Z = q(TOE_Z - 0.26);
  const strTopY = z => q(A - z);
  const nosingZ = i => q(TREAD_LINE - RISE * i);

  {
    const outer = new THREE.Shape([
      new THREE.Vector2(-HALF_W, 0), new THREE.Vector2(HALF_W, 0),
      new THREE.Vector2(HALF_W, WALL_H), new THREE.Vector2(-HALF_W, WALL_H),
    ]);
    const inset = 0.18;
    outer.holes.push(new THREE.Path([
      new THREE.Vector2(-HALF_W + inset, inset), new THREE.Vector2(-HALF_W + inset, WALL_H - inset),
      new THREE.Vector2(HALF_W - inset, WALL_H - inset), new THREE.Vector2(HALF_W - inset, inset),
    ]));
    const ring = new THREE.ExtrudeGeometry(outer, { depth: WALL_D, bevelEnabled: false });
    ring.translate(0, 0, BACK_Z);
    add(ring, C.frame);

    add(box(2 * (HALF_W - inset) + 0.02, WALL_H - 2 * inset + 0.02, 0.14,
            0, WALL_H / 2, BACK_Z + 0.08 + 0.07), C.brace);
  }

  add(box(TREAD_HX * 2, TREAD_T, DECK_D, 0, DECK_Y - TREAD_T / 2, (BACK_Z + STR_TOP_Z) / 2), C.tread);

  const legZ = [-1.285];
  for (let z = q(-1.27 + LEG_PITCH); z <= A - STR_DEPTH - 0.70 + 1e-9; z = q(z + LEG_PITCH)) legZ.push(z);

  const postZ = [q(TOE_Z - 0.10)];
  for (let z = -0.55; z <= postZ[0] - 0.50 + 1e-9; z = q(z + POST_PITCH)) postZ.push(z);
  postZ.sort((a, b) => b - a);

  for (const sx of [-1, 1]) {
    const X = sx * STR_X;

    add(prismZY([
      [TOE_Z, strTopY(TOE_Z)],
      [STR_TOP_Z, strTopY(STR_TOP_Z)],
      [STR_TOP_Z, q(strTopY(STR_TOP_Z) - STR_DEPTH)],
      [GROUND_Z, 0],
      [TOE_Z, 0],
    ], STR_W, X), C.frame);

    add(box(STR_W, STR_DEPTH + 0.003, DECK_D - 0.01, X,
            q(WALL_H + 0.003 - (STR_DEPTH + 0.003) / 2), q((BACK_Z + 0.01 + STR_TOP_Z) / 2)), C.frame);

    add(box(0.24, 0.26, 0.42, sx * (HALF_W - 0.12), 0.13, q(TOE_Z - 0.12)), C.frame);

    if (brace !== 'none') {
      const legTop = legZ.map(z => q((z <= STR_TOP_Z ? WALL_H - STR_DEPTH : strTopY(z) - STR_DEPTH) + 0.06));
      legZ.forEach((z, i) => add(box(LEG_S, legTop[i], LEG_S, X, legTop[i] / 2, z), C.brace));
      if (legZ.length > 1) {
        const zBack = q(legZ[0] - LEG_S / 2 + 0.04), zFront = q(legZ[legZ.length - 1] + LEG_S / 2 - 0.04);
        add(box(0.12, 0.16, q(zFront - zBack), X, 0.42, q((zBack + zFront) / 2)), C.brace);
      }
      if (brace === 'trussed') {
        for (let i = 0; i + 1 < legZ.length; i++) {
          add(strut(0.10, legZ[i], 0.10, legZ[i + 1], q(legTop[i + 1] - 0.06), X), C.brace);
        }
        if (sx === 1) {
          add(box(2 * STR_X, 0.12, 0.12, 0, q(legTop[0] / 2), legZ[0]), C.brace);
        }
      }
    }

    if (rails === 'both' || (rails === 'right' && sx === 1)) {
      const RX = sx * 0.935, RS = 0.08, PS = 0.07;
      const RAKE_S = 0.076;
      const railY = z => q(TREAD_LINE + 0.95 - z);
      const zA = q(TOE_Z - 0.05), zB = -0.96;
      const len = (zA - zB) * Math.SQRT2 + RS;
      const rake = new THREE.BoxGeometry(RAKE_S, RAKE_S, len);
      rake.rotateX(Math.PI / 4);
      rake.translate(RX, (railY(zA) + railY(zB)) / 2, (zA + zB) / 2);
      add(rake, C.rail);

      add(box(RS, RS, 0.68, RX, railY(zB), -1.26), C.rail);
      const dropTop = railY(zB), dropBot = WALL_H;
      add(box(PS, dropTop - dropBot, PS, RX, (dropTop + dropBot) / 2, -1.56), C.rail);

      for (const pz of postZ) {
        const top = railY(pz) - RS / 2 + 0.02;
        const bot = strTopY(pz) - 0.07;
        add(box(PS, top - bot, PS, RX, (top + bot) / 2, pz), C.rail);
      }
    }
  }

  for (let i = 1; i <= STEPS; i++) {
    const zf = nosingZ(i), zb = q(zf - TREAD_D), yt = q(RISE * i), yb = q(yt - TREAD_T);
    add(prismZY([
      [zb, yb], [zf, yb], [zf, q(yt - 0.03)], [q(zf - 0.045), yt], [zb, yt],
    ], TREAD_HX * 2, 0), C.tread);
  }

  const g = new THREE.Group();
  g.name = 'access-stair';
  const mesh = finish(parts);
  mesh.name = 'stair-body';

  mesh.geometry.computeBoundingBox();
  const b = mesh.geometry.boundingBox;
  mesh.geometry.translate(
    -(b.min.x + b.max.x) / 2,
    -b.min.y,
    -(b.min.z + b.max.z) / 2,
  );
  g.add(mesh);
  return g;
}

export default createAsset;

/*
 * Mailbox
 * https://polyfork.dev/asset/mailbox-8e36e8
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './mailbox-8e36e8.mjs';
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
 * SPECS  450 triangles, 1 material, 0.71 x 1.2 x 0.69 m (real-world scale).
 * PARTS  animate: door
 * KNOBS  createAsset({ colorway, shell, hardware, accent, width, stance, hinges,
 *        placard }) — see the exported params / presets / night maps below.
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// Street mail collection box for the "New York city" kit.
// Modeled from scratch (no comparable catalog part was reachable from this sandbox).
// Construction: ONE swept "tombstone" side profile is the single source of truth for
// the shell skin, the recessed side panels and the raised border rib / corner posts,
// so the rib always hugs the silhouette instead of being a guessed outline.
//
// PARAMS RETROFIT: every dimension the knobs drive is expressed as an inset from the
// half-width or an offset from the underside, so `createAsset()` with no arguments
// rebuilds the approved mesh vertex-for-vertex (proved with a position/colour diff
// against refs/pre-retrofit.mjs — max delta 0).

/* --------------------------------------------------------------- colorways */
// Zone keys: shell   — the painted steel body, vault, rib, posts, legs, doors, jambs,
//                      alcove lining, drip lip, escutcheon (ONE painted object);
//            hardware— true voids and ironmongery: the sunken mail slot, hinge
//                      knuckles, keyhole plug, foot pads;
//            accent  — the collection-times placard on the pull-down panel.
// Every hex is from the kit menu (#3f4247 #b5aea0 #8a5a44 #a34a38 #e8a825 #6f8fa0
// #3d6b52 #ece5d3); each preset keeps its three hexes distinct.
export const COLORWAYS = {
  'steel-blue':  { shell: 0x6f8fa0, hardware: 0x3f4247, accent: 0xe8a825 },
  'postal-green':{ shell: 0x3d6b52, hardware: 0x3f4247, accent: 0xece5d3 },
  'oxide-red':   { shell: 0xa34a38, hardware: 0x3f4247, accent: 0xece5d3 },
  'stone-gray':  { shell: 0xb5aea0, hardware: 0x3f4247, accent: 0xe8a825 },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'steel-blue', label: 'Colorway',
    options: ['steel-blue', 'postal-green', 'oxide-red', 'stone-gray'],
    describe: 'curated kit-palette paint scheme; sets all three zone albedos at once. ' +
      'steel-blue is the shipped US-style blue-gray box with a taxi-yellow placard, ' +
      'postal-green is an olive relay-box green with a cream placard, oxide-red is a ' +
      'brick-red box with a cream placard, stone-gray is a warm pale grey box with a ' +
      'yellow placard. Hardware stays charcoal in every scheme.',
  },
  shell: {
    type: 'color', default: '#6f8fa0', label: 'Shell',
    describe: 'albedo of the whole painted-steel body: side panels, border rib, corner ' +
      'posts, legs, vault, front bands, both door leaves, drip lip, alcove lining, ' +
      'jambs, pull lip and escutcheon. ~76% of the faces — this is the colour the ' +
      'object reads as from 10 m.',
  },
  hardware: {
    type: 'color', default: '#3f4247', label: 'Hardware',
    describe: 'albedo of the ironmongery and true voids: the inside of the sunken mail ' +
      'slot, the hinge knuckles, the keyhole plug and the four foot pads. Keep it dark ' +
      'and low-chroma — it is what makes the slot read as an opening rather than paint.',
  },
  accent: {
    type: 'color', default: '#e8a825', label: 'Placard',
    describe: 'albedo of the small collection-times placard on the pull-down panel, the ' +
      'one bright mass on the object (~3% of faces). Unused when the placard knob is off.',
  },
  width: {
    type: 'range', default: 0.71, min: 0.56, max: 0.76, step: 0.01, affects: 'geometry',
    label: 'Width', icon: '↔️',
    describe: 'overall width of the box in metres across X (the front elevation), rebuilt ' +
      'rather than scaled: the border rib stays 45 mm, the corner posts and legs keep ' +
      'their sections and their inset from the side plane, the mail slot, pull lip, ' +
      'placard and escutcheon keep their real sizes, and only the panel, door, drip lip ' +
      'and alcove spans grow with the body. 0.56 is a narrow single-slot post box, 0.71 ' +
      'the shipped chunky street box, 0.76 a wide double-width collection box. Depth and ' +
      'height are unaffected. A sheet-steel box has nothing repeating across its width — ' +
      'no bays, no pickets — so the triangle count is flat across this range; the hinges ' +
      'knob is the one that actually multiplies a repeat unit.',
  },
  stance: {
    type: 'range', default: 0.15, min: 0.07, max: 0.22, step: 0.01, affects: 'geometry',
    label: 'Leg height', icon: '🦵',
    describe: 'height in metres of the four corner legs, i.e. the band of daylight under ' +
      'the body. The legs keep their 36 x 52 mm section and only change length; the body ' +
      'mass, vault and every front feature ride up with them, so overall height is ' +
      '1.05 m + this value (1.12 m squat to 1.27 m perched). 0.07 sits the box almost on ' +
      'the pavement, 0.22 makes it read as perched on stilts. A four-post stance has no ' +
      'repeat unit in it either, so only the leg length changes and the triangle count is ' +
      'flat across the range.',
  },
  hinges: {
    type: 'range', default: 2, min: 2, max: 4, step: 1, affects: 'geometry',
    label: 'Hinge knuckles', icon: '🔩',
    describe: 'number of charcoal hinge barrels stacked down the +X jamb of the lower ' +
      'service door, spread evenly between the same top and bottom stations at every ' +
      'value. 2 is the shipped pair, 3 matches the reference photo, 4 reads as a ' +
      'heavy-duty vault door. Integer only; each knuckle costs 12 triangles.',
  },
  placard: {
    type: 'toggle', default: true, affects: 'geometry',
    label: 'Collection-times placard', icon: '🏷️',
    describe: 'the small collection-times plate bolted to the pull-down panel. On is the ' +
      'shipped box and the only accent-coloured mass on it; off leaves a clean unbroken ' +
      'pull-down panel (nothing is left behind — the plate is a proud slab, not a recess) ' +
      'for boxes with no posted schedule.',
  },
};

export const rig = {
  'door': { axis: 'y', range: [0, 100] },   // service door, hinged on the +X jamb
};
export const detach = [];

// Nothing on this object emits or leaks light after dark. It is a sealed painted-steel
// box: the mail slot is a void with no lamp behind it, the placard is printed paint, and
// there is no lens, pane, screen or dial anywhere on it. Declared empty rather than
// omitted so `import { night } from '...'` resolves.
export const night = {};

/* ------------------------------------------------------------ dimensions */
const HD = 0.31;          // half depth  (Z) -> 0.62 m
const R = 0.24;           // vault shoulder radius
const ARC = 4;            // facets per shoulder (chunky, kit style: no smooth curves)
const RIB_W = 0.045;      // border rib width
const FZ = 0.31;          // front plane
const ALC_Z = 0.16;       // alcove back wall
const SLOT_X = 0.12, SLOT_Z = 0.135;   // mail slot (a functional size — never scales)
const DR_Z = 0.275;       // service-door recess back plane

/* ------------------------------------------------------------ param utils */
const ZONE_KEYS = ['shell', 'hardware', 'accent'];
const hexOf = (v) => {
  if (typeof v === 'number' && Number.isFinite(v)) return v & 0xFFFFFF;
  if (typeof v === 'string' && /^#?[0-9a-f]{6}$/i.test(v)) return parseInt(v.replace('#', ''), 16);
  return null;
};
// explicit knob > colorway preset > shell. Schema defaults must NOT seed `o`, or an
// explicit default would out-rank the chosen colorway.
function zonesFor(name, o = {}) {
  const cw = COLORWAYS[name] || COLORWAYS['steel-blue'];
  const used = new Set(), out = {};
  for (const k of ZONE_KEYS) {
    let hex = (hexOf(o[k]) ?? cw[k] ?? cw.shell) & 0xFFFFFF;
    while (used.has(hex)) hex = (hex + 1) & 0xFFFFFF; // unique albedo per zone
    used.add(hex); out[k] = hex;
  }
  return out;
}
const num = (v, d) => { const x = +v; return Number.isFinite(x) ? x : d; };
const clamp = (x, a, b) => Math.min(b, Math.max(a, x));
const bool = (v, d) => (v === undefined || v === null ? d : !(v === false || v === 'false' || v === 0));

/* --------------------------------------------------------- raw tri utils */
const tri = (o, a, b, c) => o.push(a[0],a[1],a[2], b[0],b[1],b[2], c[0],c[1],c[2]);
const quad = (o, a, b, c, d) => { tri(o, a, b, c); tri(o, a, c, d); };
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
const box = (w, h, d, x, y, z) => new THREE.BoxGeometry(w, h, d).translate(x, y, z);

// axis-aligned quads; s = +1 -> normal along the positive axis, -1 -> flipped
function qz(o, x0, x1, y0, y1, z, s) {
  const a=[x0,y0,z], b=[x1,y0,z], c=[x1,y1,z], d=[x0,y1,z];
  s > 0 ? quad(o,a,b,c,d) : quad(o,d,c,b,a);
}
function qy(o, x0, x1, z0, z1, y, s) {
  const a=[x0,y,z1], b=[x1,y,z1], c=[x1,y,z0], d=[x0,y,z0];
  s > 0 ? quad(o,a,b,c,d) : quad(o,d,c,b,a);
}
function qx(o, y0, y1, z0, z1, x, s) {
  const a=[x,y0,z1], b=[x,y0,z0], c=[x,y1,z0], d=[x,y1,z1];
  s > 0 ? quad(o,a,b,c,d) : quad(o,d,c,b,a);
}
/* ------------------------------------------------- the swept side profile */
// closed ring in (z, y), counter-clockwise as seen from +X
function buildProfile(Y0, SPRING, TOP) {
  const p = [[HD, Y0], [-HD, Y0], [-HD, SPRING]];
  const czB = -HD + R, czF = HD - R;
  for (let i = 1; i <= ARC; i++) {
    const a = Math.PI - i * (Math.PI / 2) / ARC;
    p.push([czB + R * Math.cos(a), SPRING + R * Math.sin(a)]);
  }
  p.push([czF, TOP]);
  for (let i = 1; i <= ARC; i++) {
    const a = Math.PI / 2 - i * (Math.PI / 2) / ARC;
    p.push([czF + R * Math.cos(a), SPRING + R * Math.sin(a)]);
  }
  return p;
}
const inwardN = (a, b) => {
  const ez = b[0] - a[0], ey = b[1] - a[1], L = Math.hypot(ez, ey) || 1;
  return [ey / L, -ez / L];
};
function insetPoly(p, d) {
  const n = p.length, out = [];
  for (let i = 0; i < n; i++) {
    const n1 = inwardN(p[(i - 1 + n) % n], p[i]);
    const n2 = inwardN(p[i], p[(i + 1) % n]);
    let mz = n1[0] + n2[0], my = n1[1] + n2[1];
    const L = Math.hypot(mz, my) || 1; mz /= L; my /= L;
    const c = Math.max(0.4, mz * n1[0] + my * n1[1]);
    out.push([p[i][0] + mz * d / c, p[i][1] + my * d / c]);
  }
  return out;
}

/* ------------------------------------------------------------------ build */
export function createAsset(opts = {}) {
  const o = opts || {};
  const Z = zonesFor(o.colorway, o);
  const SHELL = Z.shell, DARK = Z.hardware, YELLOW = Z.accent;

  // --- knob-driven dimensions. Both collapse to the shipped numbers at the default.
  const WIDTH = clamp(num(o.width, 0.71), 0.56, 0.76);
  const HW = WIDTH / 2;                                   // 0.355 at the default
  const Y0 = clamp(num(o.stance, 0.15), 0.07, 0.22);      // underside of the body
  const dy = Y0 - 0.15;                                   // everything above the legs rides up
  const nHinge = Math.round(clamp(num(o.hinges, 2), 2, 4));
  const wantPlacard = bool(o.placard, true);

  const TOP = 1.20 + dy;
  const SPRING = 0.96 + dy;                               // vault springing line
  // SECTIONS STAY PUT: each of these is a fixed inset from the side plane, so a wider
  // box gets wider PANELS, never a fatter rib or a fatter leg.
  const PANEL_X = HW - 0.018;   // recessed side panel plane (rib stands 18 mm proud)
  const POSTX   = HW - 0.020;   // corner post centreline (outer face 2 mm inside the skin)
  const LEGX    = HW - 0.027;   // leg centreline
  const DR_X    = HW - 0.050;   // service-door recess half-span
  const ALC_X   = HW - 0.080;   // deposit alcove half-span
  const ALC_Y0 = 0.82 + dy, ALC_Y1 = 0.96 + dy;
  const SLOT_Y0 = 0.876 + dy, SLOT_Y1 = 0.910 + dy;
  const DR_Y0 = 0.185 + dy, DR_Y1 = 0.560 + dy;

  const g = new THREE.Group();
  g.name = 'mail-collection-box';

  const P = buildProfile(Y0, SPRING, TOP);
  const Q = insetPoly(P, RIB_W);
  const N = P.length;
  const iFront = N - 1;              // segment (N-1)->0 is the front elevation

  const shell = [], dark = [];

  /* --- swept outer skin (every profile segment except the open front face) */
  for (let i = 0; i < N; i++) {
    if (i === iFront) continue;      // front elevation is built from panels below
    const a = P[i], b = P[(i + 1) % N];
    const A = [-HW, a[1], a[0]], D = [-HW, b[1], b[0]];
    const C = [ HW, b[1], b[0]], B = [ HW, a[1], a[0]];
    quad(shell, A, D, C, B);
  }

  /* --- recessed side panels (fan of the inset ring) + border rib + rim step */
  for (const s of [1, -1]) {
    const px = s * PANEL_X, rx = s * HW;
    for (let k = 1; k < N - 1; k++) {
      const a = [px, Q[0][1], Q[0][0]];
      const b = [px, Q[k][1], Q[k][0]];
      const c = [px, Q[k + 1][1], Q[k + 1][0]];
      s > 0 ? tri(shell, a, b, c) : tri(shell, a, c, b);
    }
    for (let i = 0; i < N; i++) {    // every segment, incl. the underside: the rim
      const j = (i + 1) % N;         // step is what closes the panel to the skin
      const po = [rx, P[i][1], P[i][0]], pn = [rx, P[j][1], P[j][0]];
      const qo = [rx, Q[i][1], Q[i][0]], qn = [rx, Q[j][1], Q[j][0]];
      const qo2 = [px, Q[i][1], Q[i][0]], qn2 = [px, Q[j][1], Q[j][0]];
      if (s > 0) { quad(shell, po, pn, qn, qo); quad(shell, qo, qn, qn2, qo2); }
      else       { quad(shell, qo, qn, pn, po); quad(shell, qo2, qn2, qn, qo); }
    }
  }

  /* --- front elevation: frame around the service-door opening --------- */
  qz(shell, -HW, HW, Y0, DR_Y0, FZ, 1);            // sill band
  qz(shell, -HW, HW, DR_Y1, ALC_Y0, FZ, 1);        // panel band above the door
  qz(shell, -HW, -DR_X, DR_Y0, DR_Y1, FZ, 1);      // left stile
  qz(shell,  DR_X, HW, DR_Y0, DR_Y1, FZ, 1);       // right stile

  /* --- deposit alcove (the shell's own paint, shadowed by the vault lip) */
  qz(shell, -HW, -ALC_X, ALC_Y0, ALC_Y1, FZ, 1);   // jamb faces
  qz(shell,  ALC_X, HW, ALC_Y0, ALC_Y1, FZ, 1);
  qx(shell, ALC_Y0, ALC_Y1, ALC_Z, FZ, -ALC_X, 1); // jamb returns
  qx(shell, ALC_Y0, ALC_Y1, ALC_Z, FZ,  ALC_X, -1);
  qy(shell, -ALC_X, ALC_X, ALC_Z, FZ, ALC_Y0, 1);  // shelf floor
  qy(shell, -ALC_X, ALC_X, ALC_Z, FZ, ALC_Y1, -1); // ceiling (underside of vault lip)
  // back wall, built as a frame so the mail slot is a real sunken void
  qz(shell, -ALC_X, ALC_X, ALC_Y0, SLOT_Y0, ALC_Z, 1);
  qz(shell, -ALC_X, ALC_X, SLOT_Y1, ALC_Y1, ALC_Z, 1);
  qz(shell, -ALC_X, -SLOT_X, SLOT_Y0, SLOT_Y1, ALC_Z, 1);
  qz(shell,  SLOT_X, ALC_X, SLOT_Y0, SLOT_Y1, ALC_Z, 1);
  // the slot itself — the one genuinely dark void up here
  qz(dark, -SLOT_X, SLOT_X, SLOT_Y0, SLOT_Y1, SLOT_Z, 1);
  qy(dark, -SLOT_X, SLOT_X, SLOT_Z, ALC_Z, SLOT_Y1, -1);
  qy(dark, -SLOT_X, SLOT_X, SLOT_Z, ALC_Z, SLOT_Y0, 1);
  qx(dark, SLOT_Y0, SLOT_Y1, SLOT_Z, ALC_Z, -SLOT_X, 1);
  qx(dark, SLOT_Y0, SLOT_Y1, SLOT_Z, ALC_Z,  SLOT_X, -1);

  /* --- service-door recess interior (jamb reveal, still the shell paint) */
  qz(shell, -DR_X, DR_X, DR_Y0, DR_Y1, DR_Z, 1);
  qy(shell, -DR_X, DR_X, DR_Z, FZ, DR_Y1, -1);
  qy(shell, -DR_X, DR_X, DR_Z, FZ, DR_Y0, 1);
  qx(shell, DR_Y0, DR_Y1, DR_Z, FZ, -DR_X, 1);
  qx(shell, DR_Y0, DR_Y1, DR_Z, FZ,  DR_X, -1);

  /* --- applied front relief -------------------------------------------- */
  const parts = [];
  const add = (geo, c) => parts.push({ g: geo, c });

  add(posGeo(shell), SHELL);
  add(posGeo(dark), DARK);

  // pull-down door panel (relief) + its taxi-yellow collection placard
  add(box(WIDTH - 0.08, 0.190, 0.019, 0, 0.720 + dy, 0.3125), SHELL);
  if (wantPlacard) add(box(0.21, 0.062, 0.016, 0, 0.700 + dy, 0.3240), YELLOW);
  // chunky pull lip over the mail slot
  add(box(0.28, 0.022, 0.044, 0, 0.925 + dy, 0.182), SHELL);
  // projecting drip lip between the two doors
  add(box(WIDTH - 0.075, 0.053, 0.075, 0, 0.5915 + dy, 0.3275), SHELL);

  /* --- corner posts (the border rib turning the corner onto front/back) */
  // Z-FIGHT FIX (gate-driven, 2 mm): the post used to end its outer face exactly on the
  // side skin plane (x = +-HW) and its foot exactly on the body underside (y = Y0), two
  // same-facing coplanar overlaps the newer audit reports. The face now stops 2 mm
  // inboard of the skin and the foot overshoots the underside by 2 mm, so each plane has
  // one owner. Both moves are below the 4 mm the side view resolves.
  for (const sx of [1, -1]) for (const sz of [1, -1]) {
    add(box(0.036, SPRING - Y0 + 0.002, 0.017, sx * POSTX, (Y0 - 0.002 + SPRING) / 2, sz * 0.3135), SHELL);
  }

  /* --- legs + foot pads ------------------------------------------------ */
  // the leg is one fixed 36 x 52 mm baulk whose LENGTH follows the stance knob; it
  // buries 5 mm into the body above and 10 mm into its foot pad below.
  for (const sx of [1, -1]) for (const sz of [1, -1]) {
    add(box(0.036, Y0 - 0.005, 0.052, sx * LEGX, (Y0 + 0.015) / 2, sz * 0.268), SHELL);
    add(box(0.054, 0.020, 0.080, sx * LEGX, 0.010, sz * 0.268), DARK);
  }

  /* --- static mesh ------------------------------------------------------ */
  const material = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
  g.add(finish(parts, material, 'body'));

  /* --- rigged service door (hinged on the +X jamb) --------------------- */
  // pivot on the jamb AND on the leaf's outer face, so the swinging leaf clears the
  // corner post instead of scraping through it
  const hx = DR_X, hz = 0.306;
  const dparts = [];
  const dadd = (geo, c) => dparts.push({ g: geo.translate(-hx, 0, -hz), c });
  dadd(box(WIDTH - 0.100, 0.365, 0.028, 0, 0.3725, 0.292), SHELL);  // leaf
  dadd(box(0.190, 0.084, 0.014, 0, 0.465, 0.3130), SHELL);       // escutcheon
  dadd(box(0.078, 0.042, 0.014, 0, 0.407, 0.3130), SHELL);       // its lower tab
  dadd(box(0.026, 0.036, 0.010, 0, 0.473, 0.3250), DARK);        // keyhole plug
  // hinge knuckles: always between the same two stations, so extra barrels fill the
  // gap instead of lengthening the hinge line
  for (let i = 0; i < nHinge; i++) {
    const t = nHinge > 1 ? i / (nHinge - 1) : 0.5;
    dadd(box(0.030, 0.062, 0.032, hx, 0.245 + t * 0.255, 0.2990), DARK);
  }
  const door = new THREE.Group();
  door.name = 'door';
  door.position.set(hx, dy, hz);
  door.add(finish(dparts, material, 'door-mesh'));
  g.add(door);

  return g;
}

/* -------------------------------------------------- bake facets + colors */
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
function finish(list, material, name) {
  const merged = mergeGeometries(list.map(p => prep(p.g, p.c)));
  merged.computeVertexNormals();
  const m = new THREE.Mesh(merged, material);
  m.name = name;
  return m;
}

export default createAsset;

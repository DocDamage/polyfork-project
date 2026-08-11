/*
 * Dock Platform Section
 * https://polyfork.dev/asset/dock-platform-section-b36e7c
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './dock-platform-section-b36e7c.mjs';
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
 *   colorway    choice  'weathered-oak' 'weathered-oak' | 'dark-walnut' | 'sun-bleached' | 'driftwood-grey'
 *   deckWood    color   '#c2a479'      any hex or THREE.Color
 *   beamWood    color   '#8c6a47'      any hex or THREE.Color
 *   pileWood    color   '#5d4430'      any hex or THREE.Color
 *   railWood    color   '#a5855e'      any hex or THREE.Color
 *   rail        choice  'one'          'one' | 'both' | 'none'
 *   deckHeight  range   0.35           0.26 to 0.48
 *   boards      range   6              4 to 8
 *   cleat       toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/dock-platform-section-b36e7c-params.json
 *
 * SPECS  410 triangles, 1 material, 2 x 0.62 x 1.6 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-oak':  { deckWood: '#c2a479', beamWood: '#8c6a47',
                      pileWood: '#5d4430', railWood: '#a5855e' },
  'dark-walnut':    { deckWood: '#a5855e', beamWood: '#5d4430',
                      pileWood: '#3a2a1e', railWood: '#8c6a47' },
  'sun-bleached':   { deckWood: '#e0d2b4', beamWood: '#c2a479',
                      pileWood: '#75563b', railWood: '#a5855e' },

  'driftwood-grey': { deckWood: '#bcb9b1', beamWood: '#6e6b63',
                      pileWood: '#57544e', railWood: '#87847c' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'dark-walnut', 'sun-bleached', 'driftwood-grey'],
    describe: 'Curated Nature & Forest timber schemes; sets all four zones at once. ' +
      'weathered-oak is the shipped build - a pale sun-worn board deck over mid ' +
      'warm-brown beams on near-chocolate piles, matched to the kit\'s fallen log and ' +
      'plank bridge. dark-walnut drops every zone a rung into wet shaded timber for a ' +
      'dock that has stood in the water a long time. sun-bleached is dry driftwood, an ' +
      'almost cream deck over tan beams, for bright lake or coastal scenes. ' +
      'driftwood-grey leaves the brown family entirely for the kit\'s silver-grey ramp, ' +
      'matching the birch and the rocks.',
  },
  deckWood: {
    type: 'color', default: '#c2a479', label: 'Deck boards',
    describe: 'Albedo of every deck board, including the square-cut end grain at the ' +
      'chaining faces. The palest mass in the asset: it must stay clearly LIGHTER than ' +
      'the beams under it or the deck and the beam sandwich fuse into one slab from a ' +
      'low camera and the dock stops reading as a built-up structure.',
  },
  beamWood: {
    type: 'color', default: '#8c6a47', label: 'Cross beams',
    describe: 'Albedo of the two transverse beams that run the full 1.6 m width under ' +
      'each end of the deck and carry the boards. Mid rung of the value ladder: one ' +
      'step darker than the deck above, one step lighter than the piles it passes ' +
      'through, so the under-deck reads as carpentry rather than one dark shadow.',
  },
  pileWood: {
    type: 'color', default: '#5d4430', label: 'Piles and cleat',
    describe: 'Albedo of the four corner piles, the mooring cleat on the deck and the ' +
      'optional bracing ties - all the round timber, which is one zone because they ' +
      'are the same member family and always change together. Keep it the darkest ' +
      'tone: dark legs ground the platform, and it is what makes the pile heads and ' +
      'the cleat pop against the pale deck from 10 m.',
  },
  railWood: {
    type: 'color', default: '#a5855e', label: 'Kerb rail',
    describe: 'Albedo of the low kerb rail board. A rung lighter than the piles it is ' +
      'carried on, so the rail reads as a separate board lapped across the pile heads ' +
      'instead of melting into them; matched to the piles the whole railed edge ' +
      'collapses into one dark bar in silhouette.',
  },
  rail: {
    type: 'choice', default: 'one', label: 'Kerb rail', options: ['one', 'both', 'none'],
    affects: 'geometry',
    describe: 'Which long edges carry the low kerb rail board. one (the approved build) ' +
      'puts a single board on the -Z edge, leaving the +Z edge open to step off or moor ' +
      'against - the asymmetric jetty edge the references show. both mirrors it to a ' +
      'guarded walkway with a board down each side, for a run that crosses open water. ' +
      'none strips both boards for a bare landing stage or a boat slip; the pile heads ' +
      'stay fully modelled and closed, no sockets or stubs left behind. The board ' +
      'always runs the full 2 m, so chained sections give one continuous rail line.',
  },
  deckHeight: {
    type: 'range', default: 0.35, min: 0.26, max: 0.48, step: 0.01, label: 'Deck height',
    affects: 'geometry',
    describe: 'Height of the walking surface above the ground, REBUILT rather than ' +
      'stretched: only the free length of the piles changes, while board thickness, ' +
      'beam section and pile girth stay identical, and once the open span under the ' +
      'beams passes 0.24 m the piles gain a horizontal bracing TIE on each side, so ' +
      'the triangle count moves with the knob. 0.26 is a low boardwalk almost on the ' +
      'sand, beams nearly at ground level; 0.35 is the approved build with a clear gap ' +
      'under the deck; 0.48 is a tall braced jetty standing over deeper water.',
  },
  boards: {
    type: 'range', default: 6, min: 4, max: 8, step: 1, label: 'Deck boards',
    affects: 'geometry',
    describe: 'How many boards make up the deck across the fixed 1.16 m walking width, ' +
      'at a constant 24 mm gap - the deck width is set by the kit module and cannot ' +
      'move, so the count is what changes and the boards re-cut to suit. 4 is heavy ' +
      'wide sawn planking with three broad shadow gaps; 6 is the approved build; 8 is ' +
      'narrow close-laid decking that reads finer and stripier from above. Board ' +
      'thickness and the chamfer on their top edges never change.',
  },
  cleat: {
    type: 'toggle', default: true, label: 'Mooring cleat',
    affects: 'geometry',
    describe: 'The short round timber mooring stub standing on the deck, off-centre ' +
      'toward the open side, that boats tie off to. On is the approved build. Off ' +
      'gives a clear unobstructed deck for a section used as plain walkway in the ' +
      'middle of a jetty run, leaving the boards below it whole and closed.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}
function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

function prismZ(section, z0, z1) {
  const out = [], n = section.length;
  for (let i = 0; i < n; i++) {
    const q = section[i], m = section[(i + 1) % n];
    quad(out, [q[0], q[1], z0], [m[0], m[1], z0], [m[0], m[1], z1], [q[0], q[1], z1]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [section[0][0], section[0][1], z1], [section[i][0], section[i][1], z1],
        [section[i + 1][0], section[i + 1][1], z1]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [section[0][0], section[0][1], z0], [section[i + 1][0], section[i + 1][1], z0],
        [section[i][0], section[i][1], z0]);
  }
  return posGeo(out);
}

function prismX(section, x0, x1) {
  const s = section.slice().reverse();
  const out = [], n = s.length;
  for (let i = 0; i < n; i++) {
    const q = s[i], m = s[(i + 1) % n];
    quad(out, [x0, q[1], q[0]], [x0, m[1], m[0]], [x1, m[1], m[0]], [x1, q[1], q[0]]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [x1, s[0][1], s[0][0]], [x1, s[i][1], s[i][0]], [x1, s[i + 1][1], s[i + 1][0]]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [x0, s[0][1], s[0][0]], [x0, s[i + 1][1], s[i + 1][0]], [x0, s[i][1], s[i][0]]);
  }
  return posGeo(out);
}

function ringPts(r, sides) {
  const p = [];
  for (let i = 0; i < sides; i++) {
    const a = -(i + 0.5) * 2 * Math.PI / sides;
    p.push([Math.cos(a) * r, Math.sin(a) * r]);
  }
  return p;
}

function postY(rings, sides, capBottom = true, capTop = true) {
  const R = rings.map(rg => ({ p: ringPts(rg.r, sides), y: rg.y }));
  const out = [];
  for (let k = 0; k < R.length - 1; k++) {
    const lo = R[k], hi = R[k + 1];
    for (let i = 0; i < sides; i++) {
      const j = (i + 1) % sides;
      quad(out, [lo.p[i][0], lo.y, lo.p[i][1]], [lo.p[j][0], lo.y, lo.p[j][1]],
                [hi.p[j][0], hi.y, hi.p[j][1]], [hi.p[i][0], hi.y, hi.p[i][1]]);
    }
  }
  if (capTop) {
    const t = R[R.length - 1];
    for (let i = 1; i < sides - 1; i++) {
      tri(out, [t.p[0][0], t.y, t.p[0][1]], [t.p[i][0], t.y, t.p[i][1]],
          [t.p[i + 1][0], t.y, t.p[i + 1][1]]);
    }
  }
  if (capBottom) {
    const b = R[0];
    for (let i = 1; i < sides - 1; i++) {
      tri(out, [b.p[0][0], b.y, b.p[0][1]], [b.p[i + 1][0], b.y, b.p[i + 1][1]],
          [b.p[i][0], b.y, b.p[i][1]]);
    }
  }
  return posGeo(out);
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

const LEN      = 2.00;
const HALF_LEN = LEN / 2;
const WIDTH    = 1.60;

const DECK_HZ  = 0.58;
const GAP      = 0.024;
const PLANK_H  = 0.06;
const PLANK_CH = 0.014;

const PILE_SIDES = 8;
const PILE_FLAT  = 0.20;
const PILE_R     = (PILE_FLAT / 2) / Math.cos(Math.PI / PILE_SIDES);
const PILE_X     = 0.78;
const PILE_Z     = 0.66;
const PILE_RISE  = 0.27;
const PILE_TAPER = 0.94;
const PILE_CH    = 0.025;
const PILE_CHIN  = 0.022;

const BEAM_W   = 0.16;
const BEAM_H   = 0.14;
const BEAM_CH  = 0.025;
const BEAM_HZ  = WIDTH / 2;

const RAIL_Z   = 0.635;
const RAIL_T   = 0.10;
const RAIL_H   = 0.19;
const RAIL_UP  = 0.04;
const RAIL_CH  = 0.022;

const CLEAT_SIDES = 8;
const CLEAT_FLAT  = 0.11;
const CLEAT_HEAD  = 0.135;
const CLEAT_Z     = 0.30;
const CLEAT_SINK  = 0.03;

const TIE_MIN  = 0.24;
const TIE_H    = 0.08;
const TIE_T    = 0.06;
const TIE_HX   = 0.84;

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  const way = COLORWAYS[userParams.colorway ?? p.colorway] || COLORWAYS[p.colorway];
  Object.assign(p, way);
  for (const [k, v] of Object.entries(userParams)) if (v !== undefined) p[k] = v;

  const H = Math.max(0.26, Math.min(0.48, p.deckHeight));
  const nBoards = Math.max(4, Math.min(8, Math.round(p.boards)));

  const plankTop = H;
  const plankBot = H - PLANK_H;
  const beamTop  = plankBot + 0.02;
  const beamBot  = beamTop - BEAM_H;
  const pileTop  = H + PILE_RISE;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  for (const sx of [-1, 1]) for (const sz of [-1, 1]) {
    const rHead = PILE_R * PILE_TAPER;
    add(postY([
      { r: PILE_R,             y: 0 },
      { r: rHead,              y: pileTop - PILE_CH },
      { r: rHead - PILE_CHIN,  y: pileTop },
    ], PILE_SIDES).translate(sx * PILE_X, 0, sz * PILE_Z), p.pileWood);
  }

  const bs = [
    [-BEAM_W / 2, beamBot + BEAM_CH], [-BEAM_W / 2 + BEAM_CH, beamBot],
    [ BEAM_W / 2 - BEAM_CH, beamBot], [ BEAM_W / 2, beamBot + BEAM_CH],
    [ BEAM_W / 2, beamTop], [-BEAM_W / 2, beamTop],
  ];
  for (const sx of [-1, 1]) {
    add(prismZ(bs, -BEAM_HZ, BEAM_HZ).translate(sx * PILE_X, 0, 0), p.beamWood);
  }

  const WOB = [1.07, 0.94, 1.02, 0.96, 1.07, 0.94, 1.02, 0.96];
  const wob = [];
  for (let i = 0; i < nBoards; i++) wob.push(WOB[Math.min(i, nBoards - 1 - i)]);
  const sum = wob.reduce((a, b) => a + b, 0);
  const unit = (DECK_HZ * 2 - (nBoards - 1) * GAP) / sum;
  const boardZ = [], boardW = [];
  let z = -DECK_HZ;
  for (let i = 0; i < nBoards; i++) {
    const w = unit * wob[i];
    boardW.push(w); boardZ.push(z + w / 2); z += w + GAP;
  }
  for (let i = 0; i < nBoards; i++) {
    const cz = boardZ[i], hz = boardW[i] / 2, c = Math.min(PLANK_CH, hz * 0.4);
    const section = [
      [cz - hz, plankBot], [cz + hz, plankBot], [cz + hz, plankTop - c],
      [cz + hz - c, plankTop], [cz - hz + c, plankTop], [cz - hz, plankTop - c],
    ];
    add(prismX(section, -HALF_LEN, HALF_LEN), p.deckWood);
  }

  const railSides = p.rail === 'both' ? [-1, 1] : p.rail === 'none' ? [] : [-1];
  for (const sz of railSides) {
    const y0 = H + RAIL_UP, y1 = y0 + RAIL_H;
    const rs = [
      [-RAIL_T / 2, y0], [RAIL_T / 2, y0], [RAIL_T / 2, y1 - RAIL_CH],
      [RAIL_T / 2 - RAIL_CH, y1], [-RAIL_T / 2 + RAIL_CH, y1], [-RAIL_T / 2, y1 - RAIL_CH],
    ];
    add(prismX(rs, -HALF_LEN, HALF_LEN).translate(0, 0, sz * RAIL_Z), p.railWood);
  }

  const openSpan = beamBot;
  if (openSpan >= TIE_MIN) {
    for (const sz of [-1, 1]) {
      add(box(TIE_HX * 2, TIE_H, TIE_T, 0, openSpan / 2, sz * PILE_Z), p.pileWood);
    }
  }

  if (p.cleat) {
    let cz = boardZ[0];
    for (const z of boardZ) if (Math.abs(z - CLEAT_Z) < Math.abs(cz - CLEAT_Z)) cz = z;
    const r  = (CLEAT_FLAT / 2) / Math.cos(Math.PI / CLEAT_SIDES);
    const rh = (CLEAT_HEAD / 2) / Math.cos(Math.PI / CLEAT_SIDES);
    add(postY([
      { r,      y: H - CLEAT_SINK },
      { r,      y: H + 0.075 },
      { r: rh,  y: H + 0.095 },
      { r: rh,  y: H + 0.145 },
    ], CLEAT_SIDES, false).translate(0, 0, cz), p.pileWood);
  }

  const merged = mergeGeometries(parts.map(q => prep(q.g, q.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'dock';

  const g = new THREE.Group();
  g.name = 'dock-platform-section';
  g.add(mesh);
  return g;
}

export default createAsset;

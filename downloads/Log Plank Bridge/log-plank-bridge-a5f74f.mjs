/*
 * Log Plank Bridge
 * https://polyfork.dev/asset/log-plank-bridge-a5f74f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './log-plank-bridge-a5f74f.mjs';
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
 *   colorway  choice  'weathered-oak' 'weathered-oak' | 'dark-walnut' | 'sun-bleached' | 'birch-crossing'
 *   deckWood  color   '#c2a479'      any hex or THREE.Color
 *   beamWood  color   '#8c6a47'      any hex or THREE.Color
 *   sillWood  color   '#5d4430'      any hex or THREE.Color
 *   postWood  color   '#75563b'      any hex or THREE.Color
 *   railWood  color   '#a5855e'      any hex or THREE.Color
 *   length    range   1              0.76 to 1.08
 *   posts     range   5              3 to 7
 *   railings  toggle  true           true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/log-plank-bridge-a5f74f-params.json
 *
 * SPECS  480 triangles, 1 material, 4 x 1.33 x 1.72 m (real-world scale).
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'weathered-oak': { deckWood: '#c2a479', beamWood: '#8c6a47', sillWood: '#5d4430',
                     postWood: '#75563b', railWood: '#a5855e' },
  'dark-walnut':   { deckWood: '#a5855e', beamWood: '#75563b', sillWood: '#3a2a1e',
                     postWood: '#5d4430', railWood: '#8c6a47' },
  'sun-bleached':  { deckWood: '#e0d2b4', beamWood: '#c2a479', sillWood: '#75563b',
                     postWood: '#8c6a47', railWood: '#a5855e' },

  'birch-crossing': { deckWood: '#e0d2b4', beamWood: '#bcb9b1', sillWood: '#6e6b63',
                      postWood: '#87847c', railWood: '#c2a479' },
};
export const presets = COLORWAYS;

export const params = {
  colorway: {
    type: 'choice', default: 'weathered-oak', label: 'Colorway',
    options: ['weathered-oak', 'dark-walnut', 'sun-bleached', 'birch-crossing'],
    describe: 'Curated Nature & Forest timber schemes; sets all five zones at once. ' +
      'weathered-oak is the shipped build — mid warm-brown logs under a pale sun-worn ' +
      'plank deck, matched to the kit\'s fallen log. dark-walnut drops every zone one ' +
      'rung into damp shaded forest timber, near-chocolate at the ground. sun-bleached ' +
      'is old driftwood-pale wood, an almost cream deck over tan logs, for dry or ' +
      'coastal scenes. birch-crossing is the one scheme that leaves the brown family: ' +
      'silver-grey birch logs and grey posts under a cream deck, with tan rails as the ' +
      'only warm note, to match the kit\'s birch tree.',
  },
  deckWood: {
    type: 'color', default: '#c2a479', label: 'Deck planks',
    describe: 'Albedo of every transverse deck board — the walkway, and the palest mass ' +
      'in the asset. It must stay clearly LIGHTER than the beams below it or the deck ' +
      'and the log sandwich under it fuse into one slab from a low camera.',
  },
  beamWood: {
    type: 'color', default: '#8c6a47', label: 'Log beams',
    describe: 'Albedo of the two octagonal beams running the full length under the deck, ' +
      'including the flat-cut octagon faces on their protruding ends. Mid rung of the ' +
      'value ladder: one step darker than the deck, one step lighter than the sills.',
  },
  sillWood: {
    type: 'color', default: '#5d4430', label: 'Ground sills',
    describe: 'Albedo of the two transverse log sills that lie flat on the ground at ' +
      'each end and carry everything else. Keep it the darkest of the three log tones ' +
      'so the feet ground the object; a sill matched to the beams makes the bridge look ' +
      'like it is floating.',
  },
  postWood: {
    type: 'color', default: '#75563b', label: 'Rail posts',
    describe: 'Albedo of the square railing posts on both deck edges. Dark against the ' +
      'pale deck, which is what turns the railing into a readable open lattice from ' +
      '10 m instead of a pale smear along the deck line.',
  },
  railWood: {
    type: 'color', default: '#a5855e', label: 'Rails',
    describe: 'Albedo of the two horizontal rails on each side. A rung LIGHTER than the ' +
      'posts: matched to them the railing collapses into one grid of the same tone and ' +
      'the horizontal run stops reading against the trees behind it.',
  },
  length: {
    type: 'range', default: 1.0, min: 0.76, max: 1.08, step: 0.01, label: 'Length',
    affects: 'geometry',
    describe: 'How far the bridge spans, REBUILT rather than stretched: the deck gains ' +
      'or loses whole planks at a constant 0.36 m pitch and the rails re-space over the ' +
      'new run, so the triangle count moves with the knob while plank thickness, log ' +
      'girth and rail section stay exactly the same. 0.76 is a 3.0 m ditch crossing of ' +
      '7 boards; 1.0 is the approved 4.0 m stream span of 10 boards; 1.08 is a 4.3 m ' +
      'run of 11. The two ground sills always stay at the extreme ends.',
  },
  posts: {
    type: 'range', default: 5, min: 3, max: 7, step: 1, label: 'Rail posts',
    affects: 'geometry',
    describe: 'Number of posts in EACH side railing, evenly spaced end to end with the ' +
      'two rails always reaching past the outermost pair. 3 is a sparse open guard with ' +
      'long unsupported rail runs, a rough farm crossing; 5 is the approved build at ' +
      'about 0.85 m pitch; 7 packs the deck edge into a dense picket-like lattice that ' +
      'reads much heavier in silhouette. Post section never changes, only the count.',
  },
  railings: {
    type: 'toggle', default: true, label: 'Railings',
    affects: 'geometry',
    describe: 'Whether the asset ships with its two side railings. On (the approved ' +
      'build) gives the guarded footbridge. Off strips both railings down to the bare ' +
      'plank deck on its logs — a cart crossing or a low boardwalk — leaving the deck ' +
      'edges fully modelled and closed, no sockets or stubs left behind.',
  },
};

export const rig = {};
export const detach = [];
export const night = {};

function prng(seed = 1) { return () => (seed = (seed * 16807) % 2147483647) / 2147483647; }

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
}

function logX(len, flats, sides = 8) {
  const r = (flats / 2) / Math.cos(Math.PI / sides);
  const p = [];
  for (let i = 0; i < sides; i++) {
    const a = (i + 0.5) * 2 * Math.PI / sides;
    p.push([Math.cos(a) * r, Math.sin(a) * r]);
  }
  const hx = len / 2, out = [];
  for (let i = 0; i < sides; i++) {
    const q = p[i], n = p[(i + 1) % sides];
    quad(out, [-hx, q[0], q[1]], [-hx, n[0], n[1]], [hx, n[0], n[1]], [hx, q[0], q[1]]);
  }
  for (let i = 1; i < sides - 1; i++) {
    tri(out, [hx, p[0][0], p[0][1]], [hx, p[i][0], p[i][1]], [hx, p[i + 1][0], p[i + 1][1]]);
  }
  for (let i = 1; i < sides - 1; i++) {
    tri(out, [-hx, p[0][0], p[0][1]], [-hx, p[i + 1][0], p[i + 1][1]], [-hx, p[i][0], p[i][1]]);
  }
  return posGeo(out);
}

function prismZ(section, len) {
  const hz = len / 2, out = [], n = section.length;
  for (let i = 0; i < n; i++) {
    const q = section[i], m = section[(i + 1) % n];
    quad(out, [q[0], q[1], -hz], [m[0], m[1], -hz], [m[0], m[1], hz], [q[0], q[1], hz]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [section[0][0], section[0][1], hz], [section[i][0], section[i][1], hz],
        [section[i + 1][0], section[i + 1][1], hz]);
  }
  for (let i = 1; i < n - 1; i++) {
    tri(out, [section[0][0], section[0][1], -hz], [section[i + 1][0], section[i + 1][1], -hz],
        [section[i][0], section[i][1], -hz]);
  }
  return posGeo(out);
}

function box(w, h, d, x, y, z) { return new THREE.BoxGeometry(w, h, d).translate(x, y, z); }

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

const SIDES      = 8;
const SILL_FLATS = 0.30;
const BEAM_FLATS = 0.28;
const SILL_LEN   = 1.72;
const DECK_W     = 1.44;
const BEAM_Z     = 0.54;

const BASE_LEN   = 4.00;
const END_STUB   = 0.20;
const PLANK_PITCH = 0.36;
const PLANK_H    = 0.09;
const PLANK_CH   = 0.018;

const SILL_Y  = SILL_FLATS / 2;
const BEAM_Y  = SILL_FLATS - 0.03 + BEAM_FLATS / 2;
const BEAM_TOP = BEAM_Y + BEAM_FLATS / 2;
const PLANK_Y0 = BEAM_TOP - 0.02;
const DECK_TOP = PLANK_Y0 + PLANK_H;

const POST_S    = 0.10;
const POST_TOP  = 1.33;
const POST_BOT  = 0.50;
const POST_ZIN  = 0.70;
const RAIL_H    = 0.10;
const RAIL_T    = 0.06;

const RAIL_Y    = [0.86, 1.19];
const RAIL_OVER = 0.13;

export function createAsset(userParams = {}) {
  const p = {};
  for (const k of Object.keys(params)) p[k] = params[k].default;
  const way = COLORWAYS[userParams.colorway ?? p.colorway] || COLORWAYS[p.colorway];
  Object.assign(p, way);
  for (const [k, v] of Object.entries(userParams)) if (v !== undefined) p[k] = v;

  const nPosts = Math.max(3, Math.min(7, Math.round(p.posts)));
  const span   = BASE_LEN * p.length;
  const deckLen = span - 2 * END_STUB;

  const parts = [];
  const add = (g, c) => parts.push({ g, c });

  const sillX = span / 2 - END_STUB - SILL_FLATS / 2 - 0.05;
  for (const s of [-1, 1]) {
    add(logX(SILL_LEN, SILL_FLATS, SIDES)
      .rotateY(Math.PI / 2)
      .translate(s * sillX, SILL_Y, 0), p.sillWood);
  }

  for (const s of [-1, 1]) {
    add(logX(span, BEAM_FLATS, SIDES).translate(0, BEAM_Y, s * BEAM_Z), p.beamWood);
  }

  const nPlanks = Math.max(4, Math.round(deckLen / PLANK_PITCH));
  const pitch = deckLen / nPlanks;
  const rand = prng(20260807);
  const half = Math.ceil(nPlanks / 2);
  const wob = [];
  for (let i = 0; i < half; i++) wob.push(0.94 + rand() * 0.12);
  for (let i = 0; i < nPlanks; i++) {
    const w = pitch * 0.93 * wob[Math.min(i, nPlanks - 1 - i)];
    const cx = -deckLen / 2 + (i + 0.5) * pitch;
    const hw = w / 2, y0 = PLANK_Y0, y1 = PLANK_Y0 + PLANK_H, c = PLANK_CH;
    const section = [
      [cx - hw, y0], [cx + hw, y0], [cx + hw, y1 - c],
      [cx + hw - c, y1], [cx - hw + c, y1], [cx - hw, y1 - c],
    ];
    add(prismZ(section, DECK_W), p.deckWood);
  }

  const g = new THREE.Group();
  g.name = 'log-plank-bridge';

  if (p.railings) {
    const runHalf = deckLen / 2 - 0.14;
    const gap = nPosts > 1 ? (runHalf * 2) / (nPosts - 1) : 0;
    for (const side of [1, -1]) {
      const pz = side * (POST_ZIN + POST_S / 2);
      for (let i = 0; i < nPosts; i++) {
        const px = -runHalf + i * gap;
        add(box(POST_S, POST_TOP - POST_BOT, POST_S, px, (POST_TOP + POST_BOT) / 2, pz),
            p.postWood);
      }

      const rz = side * (POST_ZIN + POST_S + RAIL_T / 2 - 0.02);
      for (const ry of RAIL_Y) {
        add(box(runHalf * 2 + RAIL_OVER * 2, RAIL_H, RAIL_T, 0, ry, rz), p.railWood);
      }
    }
  }

  const merged = mergeGeometries(parts.map(q => prep(q.g, q.c)));
  merged.computeVertexNormals();
  const mesh = new THREE.Mesh(merged, new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  }));
  mesh.name = 'bridge';
  g.add(mesh);
  return g;
}

export default createAsset;

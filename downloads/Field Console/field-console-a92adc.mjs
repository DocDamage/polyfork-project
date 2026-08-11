/*
 * Field Console
 * https://polyfork.dev/asset/field-console-a92adc
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './field-console-a92adc.mjs';
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
 *   colorway    choice  'astro-gunmetal' 'astro-gunmetal' | 'ice-hull' | 'rust-field'
 *   hull        color   '#3d3f47'      any hex or THREE.Color
 *   head        color   '#434e67'      any hex or THREE.Color
 *   accent      color   '#5f6570'      any hex or THREE.Color
 *   plinth      color   '#737785'      any hex or THREE.Color
 *   trim        color   '#b2684b'      any hex or THREE.Color
 *   keyboard    color   '#b4b7bc'      any hex or THREE.Color
 *   keys        color   '#878c94'      any hex or THREE.Color
 *   screen      color   '#4ec6d2'      any hex or THREE.Color
 *   glyphs      color   '#a9e7ec'      any hex or THREE.Color
 *   tallness    range   1              0.75 to 1.18
 *   screenSize  range   1              0.85 to 1.18
 *   cornerCut   range   1              0.55 to 1.5
 *
 * Every option is described in full at https://polyfork.dev/cdn/field-console-a92adc-params.json
 *
 * SPECS  396 triangles, 2 material, 0.78 x 1.52 x 0.61 m (real-world scale).
 * PARTS  animate: screen-head
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

export const params = {
  colorway: {
    type: 'choice', default: 'astro-gunmetal', label: 'Colorway',
    options: ['astro-gunmetal', 'ice-hull', 'rust-field'],
    describe: 'curated kit-coherent scheme. astro-gunmetal is the dark NASA-punk default; ' +
      'ice-hull turns the console into a pale off-white station terminal on a grey foot; ' +
      'rust-field paints it in the regolith browns of the kit terrain with a sand trim band.',
  },
  hull: {
    type: 'color', default: '#3d3f47', label: 'Hull gunmetal',
    describe: 'dominant albedo: the tapered column, the keyboard tray, the proud bezel ' +
      'frame around the display and the hinge boss. Darkening it makes the whole totem read heavier.',
  },
  head: {
    type: 'color', default: '#434e67', label: 'Screen head',
    describe: 'albedo of the cut-corner screen shell and the neck yoke behind it — the ' +
      'mass that cantilevers over the column. Slightly bluer than the hull so the head separates.',
  },
  accent: {
    type: 'color', default: '#5f6570', label: 'Light accent',
    describe: 'albedo of the shelf bracket under the keyboard tray and the access hatch on ' +
      'the column back; one value step lighter than the hull so both read as bolted-on plates.',
  },
  plinth: {
    type: 'color', default: '#737785', label: 'Plinth',
    describe: 'albedo of the splayed octagonal foot. The lightest of the greys, so the ' +
      'console reads as planted in the regolith rather than floating.',
  },
  trim: {
    type: 'color', default: '#b2684b', label: 'Trim band',
    describe: 'albedo of the unbroken ring above the plinth — the only warm colour on the ' +
      'asset. Astro orange by default; the one accent that carries at thumbnail size.',
  },
  keyboard: {
    type: 'color', default: '#b4b7bc', label: 'Keyboard slab',
    describe: 'albedo of the pale keyboard deck on the shelf; the brightest surface on the ' +
      'model after the glass.',
  },
  keys: {
    type: 'color', default: '#878c94', label: 'End key blocks',
    describe: 'albedo of the two grey key blocks flanking the keyboard slab; mid grey so ' +
      'they separate from the slab without matching the tray.',
  },
  screen: {
    type: 'color', default: '#4ec6d2', label: 'Display glow',
    describe: 'albedo AND emissive tint of the sunken display glass. Drives the colour of ' +
      'the light the console throws; swap it to amber or green for an alarm/nav terminal.',
  },
  glyphs: {
    type: 'color', default: '#a9e7ec', label: 'HUD glyphs',
    describe: 'albedo of the flush hexagon outline and corner blips on the glass. Keep it ' +
      'lighter than the display glow or the readout disappears into the screen.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.75, max: 1.18, label: 'Tallness', affects: 'geometry',
    describe: 'stretches everything above the trim band — column, shelf and screen head rise ' +
      'together. 0.75 is a squat 1.18 m bench console (the prompt\'s "1.2 m" reading), 1.0 ' +
      'the 1.52 m standing default, 1.18 a lanky 1.76 m station.',
  },
  screenSize: {
    type: 'range', default: 1.0, min: 0.85, max: 1.18, label: 'Screen size', affects: 'geometry',
    describe: 'scales the screen head in width and height only (bezel depth is fixed). 0.85 ' +
      'is a modest 0.66 m panel barely wider than the shelf, 1.18 a 0.92 m billboard head ' +
      'that heavily overhangs the base.',
  },
  cornerCut: {
    type: 'range', default: 1.0, min: 0.55, max: 1.5, label: 'Corner cut', affects: 'geometry',
    describe: 'depth of the 45-degree corner chamfer on every octagon (plinth, column, tray, ' +
      'bezel). 0.55 reads as an almost square-cornered slab console, 1.5 as a heavily ' +
      'faceted eight-sided one.',
  },
};
for (const k of Object.keys(params)) if (!params[k].affects) params[k].affects = 'colors';

const COLORWAYS = {
  'astro-gunmetal': {},
  'ice-hull': {
    hull: '#5f6570', head: '#989ea7', accent: '#878c94', plinth: '#737785',
    trim: '#b2684b', keyboard: '#b4b7bc', keys: '#3d3f47',
  },
  'rust-field': {
    hull: '#5b4337', head: '#73594d', accent: '#856f5d', plinth: '#3e2f2b',
    trim: '#c1a078', keyboard: '#b4b7bc', keys: '#ac7c64',
  },
};
export const presets = COLORWAYS;

function resolve(user = {}) {
  const p = {};
  for (const [k, spec] of Object.entries(params)) p[k] = spec.default;
  Object.assign(p, COLORWAYS[user.colorway ?? p.colorway] ?? {});
  for (const k of Object.keys(params)) if (user[k] !== undefined) p[k] = user[k];
  const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, Number(v)));
  return {
    C: {
      gun: p.hull, slate: p.head, lite: p.accent, pale: p.plinth, orange: p.trim,
      white: p.keyboard, key: p.keys, glass: p.screen, glyph: p.glyphs,
    },
    tall: clamp(p.tallness, params.tallness.min, params.tallness.max),
    sSize: clamp(p.screenSize, params.screenSize.min, params.screenSize.max),
    cut: clamp(p.cornerCut, params.cornerCut.min, params.cornerCut.max),
  };
}

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function quad(out, a, b, c, d) { tri(out, a, b, c); tri(out, a, c, d); }
function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
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

function dim(hex, f) {
  const n = typeof hex === 'string' ? parseInt(hex.replace('#', ''), 16) : hex;
  const b = [(n >> 16) & 255, (n >> 8) & 255, n & 255].map(v => Math.round(v * f));
  return new THREE.Color(`rgb(${b[0]},${b[1]},${b[2]})`);
}
function merge(list) {
  const m = mergeGeometries(list.map(p => prep(p.g, p.c)));
  m.computeVertexNormals();
  return m;
}

function ring(hx, zf, zb, cut) {
  const cz = Math.min(cut, (zf - zb) * 0.4);
  const cx = Math.min(cut, hx * 0.8);
  return [
    [hx - cx, zf], [hx, zf - cz], [hx, zb + cz], [hx - cx, zb],
    [-hx + cx, zb], [-hx, zb + cz], [-hx, zf - cz], [-hx + cx, zf],
  ];
}

function loft(rings, caps = 'tb') {
  const pos = [];
  const P = (r, i) => [r.pts[i][0], r.y, r.pts[i][1]];
  for (let s = 0; s < rings.length - 1; s++) {
    const lo = rings[s], hi = rings[s + 1];
    for (let i = 0; i < 8; i++) {
      const j = (i + 1) % 8;
      quad(pos, P(lo, i), P(lo, j), P(hi, j), P(hi, i));
    }
  }
  const top = rings[rings.length - 1], bot = rings[0];
  for (let i = 1; i < 7; i++) {
    if (caps.includes('t')) tri(pos, P(top, 0), P(top, i), P(top, i + 1));
    if (caps.includes('b')) tri(pos, P(bot, 0), P(bot, i + 1), P(bot, i));
  }
  return posGeo(pos);
}

function octPts(w, h, cut, inset = 0) {
  const x = w / 2 - inset, y = h / 2 - inset;
  const c = Math.min(cut, x * 0.8, y * 0.8);
  return [
    [-x + c, -y], [x - c, -y], [x, -y + c], [x, y - c],
    [x - c, y], [-x + c, y], [-x, y - c], [-x, -y + c],
  ];
}
function octShape(w, h, cut) {
  const p = octPts(w, h, cut);
  const s = new THREE.Shape();
  s.moveTo(p[0][0], p[0][1]);
  for (let i = 1; i < 8; i++) s.lineTo(p[i][0], p[i][1]);
  s.closePath();
  return s;
}

function band(out, lo, z0, hi, z1, dir = 'out') {
  for (let i = 0; i < 8; i++) {
    const j = (i + 1) % 8;
    const A = [lo[i][0], lo[i][1], z0], B = [lo[j][0], lo[j][1], z0];
    const Cq = [hi[j][0], hi[j][1], z1], D = [hi[i][0], hi[i][1], z1];
    if (dir === 'out') quad(out, A, B, Cq, D); else quad(out, D, Cq, B, A);
  }
}

function annulus(out, outer, inner, z, face = 1) {
  for (let i = 0; i < 8; i++) {
    const j = (i + 1) % 8;
    const A = [outer[i][0], outer[i][1], z], B = [outer[j][0], outer[j][1], z];
    const Cq = [inner[j][0], inner[j][1], z], D = [inner[i][0], inner[i][1], z];
    if (face > 0) quad(out, A, B, Cq, D); else quad(out, D, Cq, B, A);
  }
}

function octFace(out, pts, z) {
  for (let i = 1; i < 7; i++)
    tri(out, [pts[0][0], pts[0][1], z], [pts[i][0], pts[i][1], z],
             [pts[i + 1][0], pts[i + 1][1], z]);
}

function plate(shape, total, bevel) {
  const g = new THREE.ExtrudeGeometry(shape, {
    depth: total - 2 * bevel, bevelEnabled: bevel > 0, bevelThickness: bevel,
    bevelSize: bevel, bevelOffset: 0, bevelSegments: 1, curveSegments: 1,
  });
  g.translate(0, 0, -(total - bevel));
  return g;
}

function decal(out, cx, cy, w, h, z) {
  quad(out,
    [cx - w / 2, cy - h / 2, z], [cx + w / 2, cy - h / 2, z],
    [cx + w / 2, cy + h / 2, z], [cx - w / 2, cy + h / 2, z]);
}

const TILT = -16 * Math.PI / 180;
const BAND_TOP = 0.175;

export function createAsset(userParams = {}) {
  const { C, tall, sSize, cut } = resolve(userParams);
  const K = (v) => v * cut;
  const Y = (y) => BAND_TOP + (y - BAND_TOP) * tall;

  const g = new THREE.Group();
  g.name = 'field-console';

  const PIVOT = new THREE.Vector3(0, Y(0.96), -0.09);

  const body = [];
  const add = (geo, c) => body.push({ g: geo, c });

  add(loft([
    { y: 0.000, pts: ring(0.270, 0.215, -0.215, K(0.082)) },
    { y: 0.075, pts: ring(0.240, 0.190, -0.190, K(0.076)) },
    { y: 0.100, pts: ring(0.226, 0.180, -0.180, K(0.072)) },
  ], 'b'), C.pale);

  add(loft([
    { y: 0.100, pts: ring(0.226, 0.180, -0.180, K(0.072)) },
    { y: BAND_TOP, pts: ring(0.219, 0.174, -0.174, K(0.070)) },
  ], 't'), C.orange);

  const colTop = Y(0.920);
  add(loft([
    { y: BAND_TOP, pts: ring(0.215, 0.170, -0.170, K(0.068)) },
    { y: Y(0.600), pts: ring(0.184, 0.145, -0.180, K(0.062)) },
    { y: colTop,   pts: ring(0.147, 0.075, -0.235, K(0.056)) },
  ], 't'), C.gun);

  const rake = Math.atan2(0.065, 0.745 * tall);
  const hatch = new THREE.BoxGeometry(0.20, 0.26 * tall, 0.030);
  hatch.rotateX(-rake);
  hatch.translate(0, Y(0.560), -0.199);
  add(hatch, C.lite);

  add(loft([
    { y: Y(0.645), pts: ring(0.110, 0.132, 0.055, K(0.038)) },
    { y: Y(0.700), pts: ring(0.098, 0.280, 0.055, K(0.038)) },
  ], ''), C.lite);

  add(loft([
    { y: Y(0.700), pts: ring(0.292, 0.315, 0.010, K(0.052)) },
    { y: Y(0.760), pts: ring(0.310, 0.335, 0.020, K(0.058)) },
  ], 'tb'), C.gun);

  add(new THREE.BoxGeometry(0.38, 0.036, 0.180).translate(0, Y(0.760) + 0.006, 0.220), C.white);
  add(new THREE.BoxGeometry(0.080, 0.030, 0.140).translate(-0.238, Y(0.760) + 0.003, 0.225), C.key);
  add(new THREE.BoxGeometry(0.080, 0.030, 0.140).translate(0.238, Y(0.760) + 0.003, 0.225), C.key);

  const bodyMat = new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.85, metalness: 0,
  });
  const bodyMesh = new THREE.Mesh(merge(body), bodyMat);
  bodyMesh.name = 'console-body';
  g.add(bodyMesh);

  const head = new THREE.Group();
  head.name = 'screen-head';
  head.position.copy(PIVOT);

  const hull = [];
  const panel = [];
  const hAdd = (geo, c) => hull.push({ g: geo, c });
  const pAdd = (geo, c) => panel.push({ g: geo, c });

  hAdd(loft([
    { y: -0.095, pts: ring(0.098, 0.068, -0.068, K(0.030)) },
    { y:  0.060, pts: ring(0.150, 0.010, -0.090, K(0.040)) },
    { y:  0.150, pts: ring(0.205, -0.030, -0.105, K(0.055)) },
    { y:  0.300, pts: ring(0.202, -0.030, -0.100, K(0.055)) },
  ], 't'), C.slate);

  const HW = 0.78, HH = 0.58, HCUT = K(0.125);
  const SB = 0.012;
  pAdd(plate(octShape(HW - 2 * SB, HH - 2 * SB, HCUT - SB), 0.135, SB), C.slate);

  const OUT = octPts(0.760, 0.560, K(0.114));
  const LIP = octPts(0.760, 0.560, K(0.114), 0.011);
  const INN = octPts(0.628, 0.428, K(0.074));
  const fr = [];
  band(fr, OUT, -0.002, OUT, 0.024);
  band(fr, OUT, 0.024, LIP, 0.034);
  annulus(fr, LIP, INN, 0.034, +1);
  band(fr, INN, -0.002, INN, 0.034, 'in');

  pAdd(posGeo(fr), C.gun);

  const glassParts = [];
  const gl = [];
  octFace(gl, octPts(0.648, 0.448, K(0.079)), 0.016);
  glassParts.push({ g: posGeo(gl), c: C.glass });

  const d = [];
  const Z = 0.019;
  const hex = [];
  for (let i = 0; i < 6; i++) {
    const a = Math.PI / 6 + i * Math.PI / 3;
    hex.push([Math.cos(a) * 0.160, Math.sin(a) * 0.136]);
  }
  for (let i = 0; i < 6; i++) {
    const p = hex[i], q = hex[(i + 1) % 6];
    const mx = (p[0] + q[0]) / 2, my = (p[1] + q[1]) / 2;
    const dx = q[0] - p[0], dy = q[1] - p[1];
    const len = Math.hypot(dx, dy) * 0.86, ang = Math.atan2(dy, dx);
    const seg = [];
    decal(seg, 0, 0, len, 0.016, 0);
    const gseg = posGeo(seg);
    gseg.rotateZ(ang); gseg.translate(mx, my, Z);
    glassParts.push({ g: gseg, c: C.glyph });
  }
  for (const sx of [-1, 1]) {
    decal(d, sx * 0.252, 0.146, 0.060, 0.046, Z);
    decal(d, sx * 0.252, -0.146, 0.060, 0.046, Z);
  }
  decal(d, 0, 0.196, 0.190, 0.014, Z);
  glassParts.push({ g: posGeo(d), c: C.glyph });

  const grow = new THREE.Matrix4().makeScale(sSize, sSize, 1);
  const place = new THREE.Matrix4().makeTranslation(0, 0.265 * sSize, 0.100);
  const tiltM = new THREE.Matrix4().makeRotationX(TILT);
  for (const p of panel.concat(glassParts)) {
    p.g.applyMatrix4(grow); p.g.applyMatrix4(place);
  }
  for (const p of hull.concat(panel, glassParts)) p.g.applyMatrix4(tiltM);

  const hullMesh = new THREE.Mesh(merge(hull.concat(panel)), bodyMat);
  hullMesh.name = 'screen-shell';
  head.add(hullMesh);

  const glassMesh = new THREE.Mesh(merge(glassParts), new THREE.MeshStandardMaterial({
    vertexColors: true, flatShading: true, roughness: 0.35, metalness: 0,
    emissive: dim(C.glass, 0.59), emissiveIntensity: 0.85,
  }));
  glassMesh.name = 'display';
  head.add(glassMesh);
  g.add(head);

  const box = new THREE.Box3().setFromObject(g);
  const off = new THREE.Vector3(
    -(box.min.x + box.max.x) / 2, -box.min.y, -(box.min.z + box.max.z) / 2);
  bodyMesh.geometry.translate(off.x, off.y, off.z);
  head.position.add(off);

  return g;
}

export const rig = {
  'screen-head': { axis: 'x', range: [0, 18] },
};
export const detach = [];

export const night = {
  screen: { color: '#4ec6d2', intensity: 0.75, describe: 'display backlight' },
  glyphs: { color: '#c8f6fb', describe: 'readout characters over the backlight' },
};
export default createAsset;

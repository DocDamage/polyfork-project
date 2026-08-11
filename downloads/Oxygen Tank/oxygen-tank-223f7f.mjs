/*
 * Oxygen Tank
 * https://polyfork.dev/asset/oxygen-tank-223f7f
 *
 * A parametric low-poly model for three.js: one import, no loader, no
 * textures, one draw call. createAsset() returns a ready THREE.Group.
 *
 * QUICK START
 *
 *   import { createAsset } from './oxygen-tank-223f7f.mjs';
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
 *   colorway    choice  'medical-cyan' 'medical-cyan' | 'astro-amber' | 'gunmetal' | 'regolith'
 *   hull        color   '#b4b7bc'      any hex or THREE.Color
 *   shoulder    color   '#47b7b1'      any hex or THREE.Color
 *   valve       color   '#3d3f47'      any hex or THREE.Color
 *   wheel       color   '#5f6570'      any hex or THREE.Color
 *   tallness    range   1              0.58 to 1.45
 *   girth       range   1              0.8 to 1.3
 *   facets      choice  'standard'     'chunky' | 'standard' | 'smooth'
 *   valveGuard  toggle  false          true | false
 *
 * Every option is described in full at https://polyfork.dev/cdn/oxygen-tank-223f7f-params.json
 *
 * SPECS  322 triangles, 1 material, 0.28 x 1.1 x 0.28 m (real-world scale).
 * PARTS  animate: valve-wheel
 *
 * LICENSE  Personal and commercial use: games, apps, client work. Modify
 *          freely, no attribution required. Do not resell or redistribute
 *          the file itself as an asset. Terms: https://polyfork.dev/licensing
 */

import * as THREE from 'three';
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const COLORWAYS = {
  'medical-cyan': { hull: '#b4b7bc', shoulder: '#47b7b1', valve: '#3d3f47', wheel: '#5f6570' },
  'astro-amber':  { hull: '#b4b7bc', shoulder: '#b2684b', valve: '#3d3f47', wheel: '#737785' },
  'gunmetal':     { hull: '#989ea7', shoulder: '#434e67', valve: '#1d1e26', wheel: '#5f6570' },
  'regolith':     { hull: '#c1a078', shoulder: '#73594d', valve: '#3e2f2b', wheel: '#856f5d' },
};
export const presets = COLORWAYS;

const FACET_SIDES = { chunky: 8, standard: 12, smooth: 16 };

export const params = {
  colorway: {
    type: 'choice', default: 'medical-cyan', label: 'Colorway', affects: 'colors',
    options: ['medical-cyan', 'astro-amber', 'gunmetal', 'regolith'],
    describe: 'Curated kit-coherent scheme. medical-cyan = off-white hull with a turquoise ' +
      'shoulder dome and near-black valve furniture (the approved default, the breathing-gas ' +
      'bottle); astro-amber swaps the dome to the kit rust-orange for a fuel/oxidiser bottle; ' +
      'gunmetal is a darker utility bottle, grey hull with a deep slate-blue shoulder; ' +
      'regolith is a dust-tan field cylinder with a brown shoulder for weathered outpost gear.',
  },
  hull: {
    type: 'color', default: '#b4b7bc', label: 'Hull', affects: 'colors',
    describe: 'Albedo of the whole painted steel bottle below the shoulder — the straight ' +
      'barrel, the foot chamfer and the base disc, one flat tone over every facet. This is ' +
      'about 70% of the visible surface, so keep it the lightest value in the asset; the ' +
      'shoulder carries the colour.',
  },
  shoulder: {
    type: 'color', default: '#47b7b1', label: 'Shoulder', affects: 'colors',
    describe: 'Albedo of the rounded dome cap and the small crown ring around the valve boss ' +
      '— the gas-code band, cut dead level where the dome meets the barrel. It is the only ' +
      'colour event on the object, so give it a saturated hue that carries against the pale ' +
      'hull rather than a near-neutral; this is what says which gas is in the bottle.',
  },
  valve: {
    type: 'color', default: '#3d3f47', label: 'Valve body', affects: 'colors',
    describe: 'Albedo of the cast valve furniture: the wide boss on the crown, the slim stem ' +
      'above it and the outlet port on the front. Wants to be the darkest value in the asset ' +
      'so the whole fitting silhouettes as one dark hat against the pale dome.',
  },
  wheel: {
    type: 'color', default: '#5f6570', label: 'Handwheel', affects: 'colors',
    describe: 'Albedo of the rotating handwheel — hub, four arms and top cap (and the valve ' +
      'guard cage when that is switched on). Sits one clear value step LIGHTER than the valve ' +
      'body so the cruciform reads as a separate part instead of merging into the boss below it.',
  },
  tallness: {
    type: 'range', default: 1.0, min: 0.58, max: 1.45, label: 'Tallness', affects: 'geometry',
    describe: 'REBUILDS the barrel, it does not stretch it. A drawn-steel bottle is rolled in ' +
      'COURSES of at most 0.726 m and every joint between two courses carries a rolled ' +
      'reinforcing hoop, so the barrel gains a real hoop of fixed section (56 mm tall, 10 mm ' +
      'proud, chamfered top and bottom) as soon as it runs past one course — the hoop is the ' +
      'same welded band on a short bottle and a tall one, only the number of courses changes. ' +
      'The foot, dome and valve keep their shape and size throughout. Total height runs from ' +
      '0.79 m at 0.58 (a squat single-course portable bottle barely 2.8x its own width, dome ' +
      'and valve dominating it), through the 1.10 m default (exactly one course, a bare ' +
      'barrel, no hoop), to 1.43 m at 1.45 — a two-course full-size industrial cylinder at ' +
      '4.8x its width with a hoop banding its waist. Triangles: 322 at one course, 418 at two.',
  },
  girth: {
    type: 'range', default: 1.0, min: 0.80, max: 1.30, label: 'Girth', affects: 'geometry',
    describe: 'REBUILDS the hull ring at a CONSTANT FACET PITCH, it does not stretch it. The ' +
      'flat vertical panel keeps its ~76 mm width at every diameter, so a wider bottle is ' +
      'built from MORE panels rather than from wider ones: 10 panels at 0.80 (a 0.23 m ' +
      'slender medical cylinder, the handwheel overhanging it like a tap), 12 at the default ' +
      '0.29 m, 16 at 1.30 (a 0.37 m fat industrial bottle wider than its own handwheel). ' +
      'The panel count is the facets setting scaled by this knob and rounded to a whole ' +
      'panel, so the hull reads equally faceted at any size instead of going coarse when it ' +
      'grows. The dome, foot chamfer, valve seat and guard cage all re-derive from the new ' +
      'radius; the valve furniture grows only weakly, so the top fitting reads bigger ' +
      'relative to a slim bottle and smaller on a fat one.',
  },
  facets: {
    type: 'choice', default: 'standard', label: 'Facets', affects: 'geometry',
    options: ['chunky', 'standard', 'smooth'],
    describe: 'The facet PITCH class of the revolve — how wide one flat hull panel is, given ' +
      'as the panel count at the default diameter. chunky = 8 panels (a hard octagonal bottle ' +
      'with wide flat faces), standard = 12 (the approved default), smooth = 16 (a rounder ' +
      'hull with finer facets). The girth knob then adds or drops whole panels at that pitch, ' +
      'so chunky stays chunky and smooth stays smooth at any diameter. Changes the outline ' +
      'only — the cyan waterline, the foot chamfer, any reinforcing hoop and the valve seat ' +
      'land on the same heights at every setting.',
  },
  valveGuard: {
    type: 'toggle', default: false, label: 'Valve guard', affects: 'geometry',
    describe: 'Adds the industrial protection cage: four gunmetal posts rising off the dome ' +
      'to a square-section ring that stands just proud of the handwheel, so the bottle can be ' +
      'stood in a rack or dropped without shearing the valve. Off = the clean reference ' +
      'bottle with a bare cruciform top; on = a heavier, stockier top mass and roughly 20 mm ' +
      'more height. The posts seat on the dome surface itself, so they follow the girth knob.',
  },
};

export const rig = { 'valve-wheel': { axis: 'y', range: [0, 45] } };
export const detach = [];

export const night = {};

function tri(out, a, b, c) { out.push(a[0], a[1], a[2], b[0], b[1], b[2], c[0], c[1], c[2]); }
function sub(a, b) { return [a[0] - b[0], a[1] - b[1], a[2] - b[2]]; }
function cross(a, b) {
  return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
}
function dot(a, b) { return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]; }

function face(out, pts, hint) {
  const n = cross(sub(pts[1], pts[0]), sub(pts[2], pts[0]));
  const p = dot(n, hint) >= 0 ? pts : pts.slice().reverse();
  for (let i = 1; i < p.length - 1; i++) tri(out, p[0], p[i], p[i + 1]);
}

function posGeo(pos) {
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  return g;
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
  const merged = mergeGeometries(list.filter((p) => p.g).map((p) => prep(p.g, p.c)));
  if (!merged) throw new Error('mergeGeometries returned null — attribute sets disagree');
  merged.computeVertexNormals();
  return new THREE.Mesh(merged, mat);
}

const DOME_T = [0.00, 0.28, 0.55, 0.78, 1.00];
const DOME_F = [1.00, 0.958, 0.872, 0.718, 0.455];

const COURSE = 0.726;
const RIB = { half: 0.028, cham: 0.010, proud: 0.010 };

function profile(G) {
  const { R, yFoot, yDome, domeH } = G;
  const p = [[0, 0], [G.rFoot, 0], [R, yFoot]];
  for (const yc of G.ribs) {
    p.push([R, yc - RIB.half], [R + RIB.proud, yc - RIB.half + RIB.cham],
      [R + RIB.proud, yc + RIB.half - RIB.cham], [R, yc + RIB.half]);
  }
  p.push([R, yDome]);
  for (let i = 1; i < DOME_T.length; i++) {
    p.push([DOME_F[i] * R, yDome + DOME_T[i] * domeH]);
  }
  p.push([0, yDome + domeH]);
  return p;
}

function domeYAtRadius(G, r) {
  const f = r / G.R;
  for (let i = 1; i < DOME_F.length; i++) {
    if (f >= DOME_F[i]) {
      const k = (DOME_F[i - 1] - f) / (DOME_F[i - 1] - DOME_F[i]);
      return G.yDome + (DOME_T[i - 1] + k * (DOME_T[i] - DOME_T[i - 1])) * G.domeH;
    }
  }
  return G.yDome + G.domeH;
}

function bottle(G, hullPos, shoulderPos) {
  const N = G.sides;
  const prof = profile(G);
  const th = (i) => ((i + 0.5) / N) * Math.PI * 2;
  const P = (r, y, i) => [r * Math.sin(th(i)), y, r * Math.cos(th(i))];

  for (let j = 0; j < prof.length - 1; j++) {
    const [r0, y0] = prof[j], [r1, y1] = prof[j + 1];

    const out = y0 >= G.yDome - 1e-6 ? shoulderPos : hullPos;
    for (let k = 0; k < N; k++) {
      const a = P(r0, y0, k), b = P(r1, y1, k), c = P(r1, y1, k + 1), d = P(r0, y0, k + 1);
      if (r0 === 0) {
        face(out, [[0, y0, 0], b, c], [0, -1, 0]);
      } else if (r1 === 0) {
        face(out, [[0, y1, 0], a, d], [0, 1, 0]);
      } else {
        face(out, [a, b, c, d], [a[0] + c[0], 0, a[2] + c[2]]);
      }
    }
  }
}

function tube(out, r, y0, y1, seg, phase = 0.5) {
  const P = (r_, y, i) => {
    const a = ((i + phase) / seg) * Math.PI * 2;
    return [r_ * Math.sin(a), y, r_ * Math.cos(a)];
  };
  for (let i = 0; i < seg; i++) {
    const a = P(r, y0, i), b = P(r, y1, i), c = P(r, y1, i + 1), d = P(r, y0, i + 1);
    face(out, [a, b, c, d], [a[0] + c[0], 0, a[2] + c[2]]);
  }
}

function disc(out, r, y, seg, up, phase = 0.5) {
  const P = (i) => {
    const a = ((i + phase) / seg) * Math.PI * 2;
    return [r * Math.sin(a), y, r * Math.cos(a)];
  };
  for (let i = 0; i < seg; i++) face(out, [[0, y, 0], P(i), P(i + 1)], [0, up ? 1 : -1, 0]);
}

function arm(out, x0, x1, w0, w1, h0, h1, yc, ang) {
  const rot = (p) => {
    const s = Math.sin(ang), c = Math.cos(ang);
    return [p[0] * c + p[2] * s, p[1], -p[0] * s + p[2] * c];
  };
  const V = (x, sz, sy, w, h) => rot([x, yc + sy * h, sz * w]);
  const i00 = V(x0, -1, -1, w0, h0), i01 = V(x0, 1, -1, w0, h0);
  const i11 = V(x0, 1, 1, w0, h0), i10 = V(x0, -1, 1, w0, h0);
  const o00 = V(x1, -1, -1, w1, h1), o01 = V(x1, 1, -1, w1, h1);
  const o11 = V(x1, 1, 1, w1, h1), o10 = V(x1, -1, 1, w1, h1);
  const rx = rot([1, 0, 0]), rz = rot([0, 0, 1]);
  face(out, [o00, o01, o11, o10], rx);
  face(out, [i10, i11, o11, o10], [0, 1, 0]);
  face(out, [i00, i01, o01, o00], [0, -1, 0]);
  face(out, [i01, i11, o11, o01], rz);
  face(out, [i00, i10, o10, o00], [-rz[0], -rz[1], -rz[2]]);
}

function ring(out, rIn, rOut, y0, y1, seg) {
  const P = (r, y, i) => {
    const a = ((i + 0.5) / seg) * Math.PI * 2;
    return [r * Math.sin(a), y, r * Math.cos(a)];
  };
  for (let i = 0; i < seg; i++) {
    const oa = P(rOut, y0, i), ob = P(rOut, y1, i), oc = P(rOut, y1, i + 1), od = P(rOut, y0, i + 1);
    const ia = P(rIn, y0, i), ib = P(rIn, y1, i), ic = P(rIn, y1, i + 1), id = P(rIn, y0, i + 1);
    face(out, [oa, ob, oc, od], [oa[0] + oc[0], 0, oa[2] + oc[2]]);
    face(out, [ia, ib, ic, id], [-(ia[0] + ic[0]), 0, -(ia[2] + ic[2])]);
    face(out, [ib, ob, oc, ic], [0, 1, 0]);
    face(out, [ia, oa, od, id], [0, -1, 0]);
  }
}

function resolveColors(p) {
  const cw = COLORWAYS[p.colorway] || COLORWAYS[params.colorway.default];
  const C = {};
  for (const k of ['hull', 'shoulder', 'valve', 'wheel']) {
    C[k] = p[k] !== undefined ? p[k] : (cw[k] !== undefined ? cw[k] : params[k].default);
  }
  return C;
}

const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));
const num = (v, spec) => clamp(v === undefined ? spec.default : Number(v), spec.min, spec.max);

export function createAsset(p = {}) {
  const C = resolveColors(p);
  const tallness = num(p.tallness, params.tallness);
  const girth = num(p.girth, params.girth);
  const guard = p.valveGuard === undefined ? params.valveGuard.default : !!p.valveGuard;

  const baseSides = FACET_SIDES[p.facets] || FACET_SIDES[params.facets.default];
  const sides = Math.max(6, Math.round(baseSides * girth));

  const R = 0.145 * girth;
  const G = {
    sides,
    R,
    rFoot: 0.672 * R,
    yFoot: 0.483 * R,
    domeH: 1.20 * R,
  };
  const barrel = 0.726 * tallness;
  G.yDome = G.yFoot + barrel;

  const courses = Math.max(1, Math.ceil(barrel / COURSE - 1e-9));
  G.ribs = [];
  for (let k = 1; k < courses; k++) G.ribs.push(G.yFoot + (barrel * k) / courses);
  const yCrown = G.yDome + G.domeH;
  const rCrown = DOME_F[DOME_F.length - 1] * R;

  const hullPos = [], shoulderPos = [], valvePos = [], wheelPos = [];
  bottle(G, hullPos, shoulderPos);

  const vs = 0.55 + 0.45 * girth;

  const V = {
    bossR: 0.0585 * vs, bossH: 0.050,
    stemR: 0.036 * vs,  stemH: 0.033,
    hubR:  0.041 * vs,  hubH:  0.038,
    capR:  0.031 * vs,  capH:  0.010,
    span:  0.102 * vs,
    portR: 0.016 * vs,
  };
  const yBoss = yCrown, yStem = yBoss + V.bossH, yHub = yStem + V.stemH;
  const yCap = yHub + V.hubH, yTop = yCap + V.capH;
  const yArm = yHub + V.hubH * 0.50;

  tube(valvePos, V.bossR, yBoss, yStem, 8);
  disc(valvePos, V.bossR, yStem, 8, true);

  tube(valvePos, V.stemR, yStem, yHub, 8);

  {
    const yP = yBoss + V.bossH * 0.52, z0 = V.bossR * 0.55, z1 = V.bossR + 0.021 * vs;
    const P = (z, i) => {
      const a = ((i + 0.5) / 8) * Math.PI * 2;
      return [V.portR * Math.sin(a), yP + V.portR * Math.cos(a), z];
    };
    for (let i = 0; i < 8; i++) {
      const a = P(z0, i), b = P(z1, i), c = P(z1, i + 1), d = P(z0, i + 1);
      face(valvePos, [a, b, c, d],
        [a[0] + c[0], (a[1] - yP) + (c[1] - yP), 0]);
      face(valvePos, [[0, yP, z1], P(z1, i), P(z1, i + 1)], [0, 0, 1]);
    }
  }

  tube(wheelPos, V.hubR, yHub, yCap, 8);
  disc(wheelPos, V.hubR, yHub, 8, false);
  disc(wheelPos, V.hubR, yCap, 8, true);
  tube(wheelPos, V.capR, yCap, yTop, 6);
  disc(wheelPos, V.capR, yTop, 6, true);
  for (let k = 0; k < 4; k++) {
    arm(wheelPos, V.hubR * 0.80, V.span, 0.018 * vs, 0.024 * vs, 0.017 * vs, 0.014 * vs,
      yArm, (k / 4) * Math.PI * 2);
  }

  const guardPos = [];
  if (guard) {

    const rw = 0.014 * vs, hw = 0.012 * vs;
    const postR = V.span + 0.012 * vs + rw;
    const yRing0 = yTop - 0.004, yRing1 = yRing0 + 0.028;

    ring(guardPos, postR - rw, postR + rw, yRing0, yRing1, Math.min(sides, 12));

    const ySeat = domeYAtRadius(G, Math.min(postR, G.R * 0.98)) - 0.030;
    const yPost = yRing0 + 0.012;
    const corners = [[-hw, -hw], [hw, -hw], [hw, hw], [-hw, hw]];
    for (let k = 0; k < 4; k++) {
      const ang = (k / 4) * Math.PI * 2, ca = Math.cos(ang), sa = Math.sin(ang);
      const P = (dx, dz, y) => {
        const x = postR + dx;
        return [x * ca + dz * sa, y, -x * sa + dz * ca];
      };
      for (let e = 0; e < 4; e++) {
        const [ax, az] = corners[e], [bx, bz] = corners[(e + 1) % 4];
        const mx = (ax + bx) / 2, mz = (az + bz) / 2;
        face(guardPos,
          [P(ax, az, ySeat), P(bx, bz, ySeat), P(bx, bz, yPost), P(ax, az, yPost)],
          [mx * ca + mz * sa, 0, -mx * sa + mz * ca]);
      }
      face(guardPos, corners.map(([dx, dz]) => P(dx, dz, ySeat)), [0, -1, 0]);
    }
  }

  const mat = material();

  const shell = finish([
    { g: posGeo(hullPos), c: C.hull },
    { g: posGeo(shoulderPos), c: C.shoulder },
    { g: posGeo(valvePos), c: C.valve },

    guardPos.length ? { g: posGeo(guardPos), c: C.wheel } : null,
  ].filter(Boolean), mat);
  shell.name = 'bottle-shell';

  const wheelMesh = finish([{ g: posGeo(wheelPos), c: C.wheel }], mat);
  wheelMesh.name = 'valve-wheel-mesh';
  wheelMesh.position.set(0, -(yArm), 0);

  const wheelGroup = new THREE.Group();
  wheelGroup.name = 'valve-wheel';
  wheelGroup.position.set(0, yArm, 0);
  wheelGroup.add(wheelMesh);

  const g = new THREE.Group();
  g.name = 'oxygen-tank';
  g.add(shell);
  g.add(wheelGroup);
  return g;
}

export default createAsset;

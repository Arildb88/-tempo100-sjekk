import test from 'node:test';
import assert from 'node:assert/strict';
import { makePlateTracker, plateCandidates } from '../public/plate-reader.js';
test('plate extraction preserves digits and supports trailer plates', () => {
  assert.deepEqual(plateCandidates('AB 1234\nAB1234'), ['AB1234']);
  assert.deepEqual(plateCandidates('AB 12345'), ['AB12345']);
  assert.deepEqual(plateCandidates('AB I234'), []);
});
test('automatic lookup requires three consistent confident readings', () => {
  const read = makePlateTracker();
  assert.equal(read('AB1234', 90), null);
  assert.equal(read('AB1234', 90), null);
  assert.equal(read('AB1234', 90), 'AB1234');
});
test('ambiguous, weak and different readings reset confirmation', () => {
  const read = makePlateTracker();
  read('AB1234', 90); read('AB1234', 90);
  assert.equal(read('AB1234 CD5678', 90), null);
  assert.equal(read('AB1234', 90), null);
  assert.equal(read('AB1234', 69), null);
  assert.equal(read('CD5678', 90), null);
  assert.equal(read('AB1234', 90), null);
});

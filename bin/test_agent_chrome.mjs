import { test } from 'node:test';
import assert from 'node:assert/strict';
import { Readable } from 'node:stream';
import { backgroundCommand, messages } from './agent-chrome.mjs';

test('new tabs and windows stay in the background even when foreground is requested', () => {
  for (const background of [undefined, false, true]) {
    const command = { id: 3, method: 'Target.createTarget', params: { url: 'about:blank', background, newWindow: true } };
    const result = backgroundCommand(command);
    assert.equal(result.forward.params.background, true);
    assert.equal(result.forward.params.newWindow, true);
    assert.equal(command.params.background, background);
  }
});

test('focus requests are acknowledged without activating Chrome', () => {
  for (const method of ['Page.bringToFront', 'Target.activateTarget']) {
    assert.deepEqual(backgroundCommand({ id: 7, method, sessionId: 'page-1' }), {
      reply: { id: 7, result: {}, sessionId: 'page-1' },
    });
    assert.deepEqual(backgroundCommand({ id: 8, method }), { reply: { id: 8, result: {} } });
  }
});

test('navigation and other debugging requests retain their IDs, sessions and parameters', () => {
  const command = { id: 12, method: 'Page.navigate', sessionId: 'page-2', params: { url: 'https://example.com' } };
  assert.deepEqual(backgroundCommand(command), { forward: command });
});

test('debugging messages survive fragmented and combined UTF-8 pipe frames', async () => {
  const frames = [{ id: 1, result: { text: 'café' } }, { method: 'Target.targetCreated', params: {} }];
  const data = Buffer.from(frames.map(frame => JSON.stringify(frame) + '\0').join(''));
  const accent = data.indexOf(Buffer.from('é'));
  const stream = Readable.from([data.subarray(0, accent + 1), data.subarray(accent + 1)]);
  assert.deepEqual(await Array.fromAsync(messages(stream)), frames);
});

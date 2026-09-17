// JSON-RPC client for the local Codex daemon. Shared by internal scripts.
"use strict";
const net = require("node:net");
const { execFileSync } = require("node:child_process");

async function connect(clientName = "dotfiles", timeout = 5000) {
  const daemon = JSON.parse(execFileSync("codex", ["app-server", "daemon", "version"], {
    encoding: "utf8", timeout, stdio: ["ignore", "pipe", "ignore"],
  }));
  if (daemon.status !== "running" || !daemon.socketPath) throw new Error("Codex daemon is not running");

  // Node's WebSocket client needs a TCP endpoint. Bridge to the daemon's Unix
  // socket and normalize Host/Origin for the local listener.
  const streams = new Set();
  const pending = new Map();
  let ws;
  let nextId = 0;
  let failure;
  const bridge = net.createServer((client) => {
    const upstream = net.createConnection(daemon.socketPath);
    streams.add(client).add(upstream);
    client.on("close", () => streams.delete(client));
    upstream.on("close", () => streams.delete(upstream));
    client.on("error", () => upstream.destroy());
    upstream.on("error", () => client.destroy());
    let request = Buffer.alloc(0);
    let upgraded = false;
    client.on("data", (chunk) => {
      if (upgraded) return upstream.write(chunk);
      request = Buffer.concat([request, chunk]);
      const end = request.indexOf("\r\n\r\n");
      if (end < 0) {
        if (request.length > 16384) client.destroy();
        return;
      }
      const lines = request.subarray(0, end).toString("latin1").split("\r\n");
      const keep = ["connection:", "upgrade:", "sec-websocket-key:", "sec-websocket-version:"];
      const headers = [lines[0], "Host: localhost", ...lines.slice(1).filter(
        (line) => keep.some((prefix) => line.toLowerCase().startsWith(prefix)),
      )].join("\r\n");
      upstream.write(Buffer.concat([Buffer.from(headers + "\r\n\r\n", "latin1"), request.subarray(end + 4)]));
      request = Buffer.alloc(0);
      upgraded = true;
    });
    upstream.pipe(client);
  });

  function fail(error) {
    failure ||= error;
    for (const entry of pending.values()) entry.reject(failure);
    pending.clear();
  }
  function close() {
    fail(new Error("Codex connection closed"));
    if (ws && ws.readyState < WebSocket.CLOSING) ws.close();
    for (const stream of streams) stream.destroy();
    bridge.close();
  }
  function call(method, params) {
    if (failure) return Promise.reject(failure);
    return new Promise((resolve, reject) => {
      const id = ++nextId;
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new Error(`Codex ${method} timed out`));
      }, timeout);
      pending.set(id, {
        resolve: (value) => { clearTimeout(timer); resolve(value); },
        reject: (error) => { clearTimeout(timer); reject(error); },
      });
      try {
        ws.send(JSON.stringify({ id, method, params }));
      } catch (error) {
        pending.get(id).reject(error);
        pending.delete(id);
      }
    });
  }

  try {
    await new Promise((resolve, reject) => {
      bridge.once("error", reject);
      bridge.listen(0, "127.0.0.1", resolve);
    });
    ws = new WebSocket(`ws://127.0.0.1:${bridge.address().port}`);
    ws.addEventListener("message", (event) => {
      let message;
      try { message = JSON.parse(event.data); } catch {
        fail(new Error("Invalid JSON from Codex daemon"));
        close();
        return;
      }
      const entry = pending.get(message.id);
      if (!entry) return;
      pending.delete(message.id);
      if (message.error) entry.reject(new Error(message.error.message));
      else entry.resolve(message.result);
    });
    ws.addEventListener("error", () => fail(new Error("Codex connection failed")));
    ws.addEventListener("close", () => fail(new Error("Codex connection closed")));
    await new Promise((resolve, reject) => {
      const timer = setTimeout(() => reject(new Error("Codex connection timed out")), timeout);
      ws.addEventListener("open", () => { clearTimeout(timer); resolve(); }, { once: true });
      ws.addEventListener("error", () => { clearTimeout(timer); reject(new Error("Codex connection failed")); }, { once: true });
    });
    await call("initialize", {
      clientInfo: { name: clientName, version: "1" },
      capabilities: { experimentalApi: true },
    });
    ws.send(JSON.stringify({ method: "initialized", params: {} }));
    return { call, close };
  } catch (error) {
    close();
    throw error;
  }
}

module.exports = { connect };

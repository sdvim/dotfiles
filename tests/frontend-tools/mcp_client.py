"""Small stdio client for explicit local integration probes (no dependencies)."""
import json
import os
import queue
import signal
import subprocess
import threading
import time


class Client:
    def __init__(self, command, cwd=None, log=None):
        self.log = open(log, 'w') if log else subprocess.DEVNULL
        self.process = subprocess.Popen(command, cwd=cwd, stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, stderr=self.log,
                                        text=True, start_new_session=True)
        self.messages = queue.Queue()
        self.sequence = 0
        threading.Thread(target=self._read, daemon=True).start()
        self.server = self.request('initialize', {
            'protocolVersion': '2024-11-05', 'capabilities': {},
            'clientInfo': {'name': 'dotfiles-integration-probe', 'version': '1.0'},
        })
        self.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})

    def _read(self):
        for line in self.process.stdout:
            try:
                self.messages.put(json.loads(line))
            except json.JSONDecodeError:
                pass
        self.messages.put(None)

    def send(self, message):
        self.process.stdin.write(json.dumps(message) + '\n')
        self.process.stdin.flush()

    def request(self, method, params, timeout=120):
        self.sequence += 1
        request_id = self.sequence
        self.send({'jsonrpc': '2.0', 'id': request_id, 'method': method, 'params': params})
        deadline = time.monotonic() + timeout
        while True:
            message = self.messages.get(timeout=max(0.01, deadline - time.monotonic()))
            if message is None:
                raise RuntimeError('MCP server exited before responding')
            if message.get('id') != request_id:
                continue
            if 'error' in message:
                raise RuntimeError(message['error'])
            return message['result']

    def call(self, name, arguments):
        result = self.request('tools/call', {'name': name, 'arguments': arguments})
        if result.get('isError'):
            raise RuntimeError(result)
        return result

    def close(self):
        self.process.stdin.close()
        try:
            self.process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(self.process.pid, signal.SIGTERM)
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(self.process.pid, signal.SIGKILL)
                self.process.wait()
        if self.log != subprocess.DEVNULL:
            self.log.close()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

# HexStrike Server-Sent Events (SSE) Streaming API Guide

## Overview

The HexStrike server now supports **real-time streaming** of command execution output using Server-Sent Events (SSE). This allows clients to receive incremental output as commands execute, rather than waiting for completion.

## Key Features

✅ **Real-time Output Streaming** - Receive stdout/stderr as it's generated  
✅ **Progress Tracking** - Monitor execution progress and resource usage  
✅ **Task Management** - Create, start, monitor, and terminate streaming tasks  
✅ **Backward Compatible** - Existing REST endpoints remain unchanged  
✅ **Tool-Specific Endpoints** - Simplified streaming for common security tools  

---

## Architecture

### Components

1. **StreamingTaskManager** - Manages streaming task lifecycle
2. **SSE Event Stream** - Real-time event delivery via HTTP
3. **Output Queues** - Thread-safe buffering of command output
4. **Process Integration** - Leverages existing ProcessManager for execution

### Event Types

| Event Type | Description | Data Fields |
|------------|-------------|-------------|
| `start` | Command execution started | `message`, `command` |
| `stdout` | Standard output line | `line`, `timestamp` |
| `stderr` | Standard error line | `line`, `timestamp` |
| `timeout` | Command timed out | `message` |
| `complete` | Execution completed | `success`, `return_code`, `output_lines`, `error_lines` |
| `error` | Execution error | `message`, `traceback` |
| `terminated` | Task terminated by user | `message` |
| `status` | Task status update | Full task metadata |

---

## API Endpoints

### 1. Create Streaming Task

**POST** `/api/stream/create`

Create a new streaming task for command execution.

**Request Body:**
```json
{
  "command": "nmap -sV 192.168.1.1",
  "context": {
    "timeout": 3600,
    "description": "Network scan"
  },
  "auto_start": true
}
```

**Response:**
```json
{
  "success": true,
  "task_id": "stream_1713564123456_7890",
  "task_info": {
    "task_id": "stream_1713564123456_7890",
    "command": "nmap -sV 192.168.1.1",
    "status": "running",
    "created_at": "2026-04-20T01:15:23.456Z"
  },
  "stream_url": "/api/stream/stream_1713564123456_7890",
  "timestamp": "2026-04-20T01:15:23.456Z"
}
```

**Parameters:**
- `command` (required): Shell command to execute
- `context` (optional): Additional metadata (timeout, description, etc.)
- `auto_start` (optional, default: true): Start execution immediately

---

### 2. Stream Task Output

**GET** `/api/stream/<task_id>`

Connect to SSE stream for real-time output.

**Response Headers:**
```
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
```

**Event Stream Example:**
```
event: status
data: {"task_id":"stream_123","status":"running","command":"nmap -sV 192.168.1.1"}

event: start
data: {"message":"Command execution started","command":"nmap -sV 192.168.1.1"}

event: stdout
data: {"line":"Starting Nmap 7.94 ( https://nmap.org )","timestamp":"2026-04-20T01:15:24.123Z"}

event: stdout
data: {"line":"Nmap scan report for 192.168.1.1","timestamp":"2026-04-20T01:15:25.456Z"}

event: complete
data: {"success":true,"return_code":0,"output_lines":42,"error_lines":0}
```

---

### 3. Start Streaming Task

**POST** `/api/stream/<task_id>/start`

Start execution of a created task (if `auto_start` was false).

**Response:**
```json
{
  "success": true,
  "task_id": "stream_1713564123456_7890",
  "message": "Task execution started",
  "stream_url": "/api/stream/stream_1713564123456_7890",
  "timestamp": "2026-04-20T01:15:23.456Z"
}
```

---

### 4. Get Task Info

**GET** `/api/stream/<task_id>/info`

Get current task status and metadata.

**Response:**
```json
{
  "success": true,
  "task_info": {
    "task_id": "stream_1713564123456_7890",
    "command": "nmap -sV 192.168.1.1",
    "status": "running",
    "start_time": "2026-04-20T01:15:23.456Z",
    "pid": 12345,
    "progress": 0.45,
    "output_lines": 128,
    "error_lines": 0,
    "created_at": "2026-04-20T01:15:23.000Z"
  },
  "timestamp": "2026-04-20T01:16:00.000Z"
}
```

---

### 5. Terminate Task

**POST** `/api/stream/<task_id>/terminate`

Terminate a running streaming task.

**Response:**
```json
{
  "success": true,
  "task_id": "stream_1713564123456_7890",
  "message": "Task terminated successfully",
  "timestamp": "2026-04-20T01:16:30.000Z"
}
```

---

### 6. List Tasks

**GET** `/api/stream/tasks?status=running`

List all streaming tasks, optionally filtered by status.

**Query Parameters:**
- `status` (optional): Filter by status (`pending`, `running`, `completed`, `failed`, `error`, `terminated`)

**Response:**
```json
{
  "success": true,
  "tasks": [
    {
      "task_id": "stream_1713564123456_7890",
      "command": "nmap -sV 192.168.1.1",
      "status": "running",
      "start_time": "2026-04-20T01:15:23.456Z",
      "output_lines": 128
    }
  ],
  "count": 1,
  "filter": {"status": "running"},
  "timestamp": "2026-04-20T01:16:00.000Z"
}
```

---

### 7. Tool-Specific Streaming

**POST** `/api/tools/<tool_name>/stream`

Execute a specific tool with streaming output (simplified interface).

**Supported Tools:**
- `nmap`, `gobuster`, `nuclei`, `nikto`, `sqlmap`, `ffuf`, `feroxbuster`
- `rustscan`, `masscan`, `amass`, `subfinder`

**Request Body (nmap example):**
```json
{
  "target": "192.168.1.1",
  "additional_args": "-sV -p-",
  "timeout": 3600
}
```

**Response:**
```json
{
  "success": true,
  "task_id": "stream_1713564123456_7890",
  "tool": "nmap",
  "command": "nmap 192.168.1.1 -sV -p-",
  "task_info": {...},
  "stream_url": "/api/stream/stream_1713564123456_7890",
  "timestamp": "2026-04-20T01:15:23.456Z"
}
```

---

## Client Examples

### Python (using requests)

```python
import requests
import json

# Create streaming task
response = requests.post('http://localhost:8888/api/stream/create', json={
    'command': 'nmap -sV 192.168.1.1',
    'auto_start': True
})
task_id = response.json()['task_id']

# Connect to SSE stream
stream_url = f'http://localhost:8888/api/stream/{task_id}'
with requests.get(stream_url, stream=True) as r:
    for line in r.iter_lines():
        if line:
            line = line.decode('utf-8')
            if line.startswith('event:'):
                event_type = line.split(':', 1)[1].strip()
            elif line.startswith('data:'):
                data = json.loads(line.split(':', 1)[1].strip())
                print(f"[{event_type}] {data}")
```

### JavaScript (Browser)

```javascript
// Create streaming task
const response = await fetch('http://localhost:8888/api/stream/create', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    command: 'nmap -sV 192.168.1.1',
    auto_start: true
  })
});
const {task_id, stream_url} = await response.json();

// Connect to SSE stream
const eventSource = new EventSource(`http://localhost:8888${stream_url}`);

eventSource.addEventListener('stdout', (e) => {
  const data = JSON.parse(e.data);
  console.log('Output:', data.line);
});

eventSource.addEventListener('complete', (e) => {
  const data = JSON.parse(e.data);
  console.log('Completed:', data);
  eventSource.close();
});

eventSource.addEventListener('error', (e) => {
  console.error('Stream error:', e);
  eventSource.close();
});
```

### cURL (Testing)

```bash
# Create task
curl -X POST http://localhost:8888/api/stream/create \
  -H "Content-Type: application/json" \
  -d '{"command":"nmap -sV 192.168.1.1","auto_start":true}'

# Stream output (replace TASK_ID)
curl -N http://localhost:8888/api/stream/TASK_ID

# Get task info
curl http://localhost:8888/api/stream/TASK_ID/info

# Terminate task
curl -X POST http://localhost:8888/api/stream/TASK_ID/terminate
```

---

## Best Practices

### 1. Connection Management
- **Reconnect on disconnect** - Network issues may close SSE connections
- **Handle keepalive events** - Server sends `: keepalive` every 30s
- **Close connections** - Always close EventSource when done

### 2. Error Handling
- **Check task status** - Verify task exists before streaming
- **Handle timeout events** - Commands may timeout but have partial results
- **Parse error events** - Contains traceback for debugging

### 3. Performance
- **Use tool-specific endpoints** - Simpler than building commands manually
- **Set appropriate timeouts** - Default is 3600s (1 hour)
- **Monitor queue size** - Check `/api/stream/tasks` for backlog

### 4. Security
- **Validate commands** - Sanitize user input before creating tasks
- **Limit concurrent tasks** - Prevent resource exhaustion
- **Authenticate requests** - Add authentication layer if exposing publicly

---

## Comparison: REST vs SSE Streaming

| Feature | REST API | SSE Streaming |
|---------|----------|---------------|
| **Response Time** | Wait for completion | Real-time updates |
| **Progress Tracking** | No | Yes |
| **Resource Usage** | High (blocking) | Low (async) |
| **User Experience** | Poor for long tasks | Excellent |
| **Complexity** | Simple | Moderate |
| **Use Case** | Quick commands | Long-running scans |

---

## Troubleshooting

### Stream Not Connecting
- Verify task exists: `GET /api/stream/<task_id>/info`
- Check server logs for errors
- Ensure firewall allows SSE connections

### Missing Events
- Check output queue size (max 1000 events)
- Increase queue size in `StreamingTaskManager.__init__`
- Monitor server resource usage

### Task Stuck in "pending"
- Manually start: `POST /api/stream/<task_id>/start`
- Check if `auto_start` was set to `false`
- Verify command is valid

### High Memory Usage
- Limit concurrent streaming tasks
- Reduce command output verbosity
- Clear completed tasks periodically

---

## Migration Guide

### From REST to Streaming

**Before (REST):**
```python
response = requests.post('http://localhost:8888/api/tools/nmap', json={
    'target': '192.168.1.1',
    'scan_type': 'version'
})
result = response.json()  # Blocks until complete
print(result['stdout'])
```

**After (Streaming):**
```python
# Create streaming task
response = requests.post('http://localhost:8888/api/tools/nmap/stream', json={
    'target': '192.168.1.1',
    'additional_args': '-sV'
})
task_id = response.json()['task_id']

# Stream output in real-time
with requests.get(f'http://localhost:8888/api/stream/{task_id}', stream=True) as r:
    for line in r.iter_lines():
        if line and line.startswith(b'data:'):
            data = json.loads(line[5:])
            if 'line' in data:
                print(data['line'])  # Real-time output
```

---

## Technical Details

### Event Stream Format (SSE)
```
event: <event_type>\n
data: <json_data>\n
\n
```

### Task Lifecycle
```
pending → running → completed/failed/error
                 ↓
              terminated
```

### Resource Cleanup
- Output queues cleared after stream completion
- Task metadata retained for history
- Process registry cleaned up automatically

---

## Support

For issues or questions:
- Check server logs: `docker logs hexstrike-server`
- Review task info: `GET /api/stream/<task_id>/info`
- List all tasks: `GET /api/stream/tasks`

---

**Version:** 6.1 (SSE Streaming)  
**Last Updated:** 2026-04-20  
**Compatibility:** HexStrike Server v6.0+
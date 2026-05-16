#!/usr/bin/env python3
"""
Test script for HexStrike SSE Streaming API

This script demonstrates how to use the streaming API endpoints
and validates that streaming functionality works correctly.
"""

import requests
import json
import time
import sys
from typing import Dict, Any

# Configuration
# SERVER_URL = "http://localhost:8888"
SERVER_URL = "http://localhost:10443/"
TIMEOUT = 30  # seconds

def print_header(text: str):
    """Print formatted header"""
    print(f"\n{'='*70}")
    print(f"  {text}")
    print(f"{'='*70}\n")

def print_success(text: str):
    """Print success message"""
    print(f"✅ {text}")

def print_error(text: str):
    """Print error message"""
    print(f"❌ {text}")

def print_info(text: str):
    """Print info message"""
    print(f"ℹ️  {text}")

def test_health_check() -> bool:
    """Test server health check"""
    print_header("Test 1: Server Health Check")
    try:
        response = requests.get(f"{SERVER_URL}/health", timeout=5)
        if response.status_code == 200:
            data = response.json()
            print_success(f"Server is healthy")
            print_info(f"Available tools: {data.get('available_tools', 0)}")
            return True
        else:
            print_error(f"Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print_error(f"Cannot connect to server: {e}")
        return False

def test_create_streaming_task() -> str:
    """Test creating a streaming task"""
    print_header("Test 2: Create Streaming Task")
    try:
        # Use a simple command that completes quickly
        payload = {
            "command": "echo 'Hello from streaming!' && sleep 1 && echo 'Streaming works!'",
            "context": {
                "timeout": 10,
                "description": "Test streaming task"
            },
            "auto_start": False  # Don't auto-start for testing
        }
        
        response = requests.post(
            f"{SERVER_URL}/api/stream/create",
            json=payload,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            task_id = data.get("task_id")
            print_success(f"Task created: {task_id}")
            print_info(f"Stream URL: {data.get('stream_url')}")
            print_info(f"Status: {data['task_info']['status']}")
            return task_id
        else:
            print_error(f"Failed to create task: {response.status_code}")
            print_error(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print_error(f"Error creating task: {e}")
        return None

def test_get_task_info(task_id: str) -> bool:
    """Test getting task information"""
    print_header("Test 3: Get Task Info")
    try:
        response = requests.get(
            f"{SERVER_URL}/api/stream/{task_id}/info",
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            task_info = data.get("task_info", {})
            print_success("Task info retrieved")
            print_info(f"Task ID: {task_info.get('task_id')}")
            print_info(f"Status: {task_info.get('status')}")
            print_info(f"Command: {task_info.get('command')}")
            return True
        else:
            print_error(f"Failed to get task info: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error getting task info: {e}")
        return False

def test_start_streaming_task(task_id: str) -> bool:
    """Test starting a streaming task"""
    print_header("Test 4: Start Streaming Task")
    try:
        response = requests.post(
            f"{SERVER_URL}/api/stream/{task_id}/start",
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            print_success("Task started successfully")
            print_info(f"Message: {data.get('message')}")
            return True
        else:
            print_error(f"Failed to start task: {response.status_code}")
            print_error(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print_error(f"Error starting task: {e}")
        return False

def test_stream_output(task_id: str) -> bool:
    """Test streaming output via SSE"""
    print_header("Test 5: Stream Task Output (SSE)")
    try:
        print_info("Connecting to SSE stream...")
        
        response = requests.get(
            f"{SERVER_URL}/api/stream/{task_id}",
            stream=True,
            timeout=TIMEOUT
        )
        
        if response.status_code != 200:
            print_error(f"Failed to connect to stream: {response.status_code}")
            return False
        
        print_success("Connected to SSE stream")
        print_info("Receiving events...\n")
        
        event_count = 0
        current_event = None
        
        for line in response.iter_lines():
            if not line:
                continue
                
            line = line.decode('utf-8')
            
            if line.startswith('event:'):
                current_event = line.split(':', 1)[1].strip()
                
            elif line.startswith('data:'):
                data_str = line.split(':', 1)[1].strip()
                try:
                    data = json.loads(data_str)
                    event_count += 1
                    
                    # Print event based on type
                    if current_event == 'start':
                        print(f"🚀 [{current_event}] {data.get('message')}")
                    elif current_event == 'stdout':
                        print(f"📤 [{current_event}] {data.get('line')}")
                    elif current_event == 'stderr':
                        print(f"📥 [{current_event}] {data.get('line')}")
                    elif current_event == 'complete':
                        print(f"✅ [{current_event}] Success: {data.get('success')}, "
                              f"Output lines: {data.get('output_lines')}")
                        break
                    elif current_event == 'error':
                        print(f"❌ [{current_event}] {data.get('message')}")
                        break
                    else:
                        print(f"ℹ️  [{current_event}] {data}")
                        
                except json.JSONDecodeError:
                    print_info(f"Non-JSON data: {data_str}")
            
            elif line.startswith(':'):
                # Keepalive comment
                pass
        
        print(f"\n")
        print_success(f"Stream completed. Received {event_count} events")
        return event_count > 0
        
    except Exception as e:
        print_error(f"Error streaming output: {e}")
        return False

def test_list_tasks() -> bool:
    """Test listing streaming tasks"""
    print_header("Test 6: List Streaming Tasks")
    try:
        response = requests.get(
            f"{SERVER_URL}/api/stream/tasks",
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            tasks = data.get("tasks", [])
            print_success(f"Retrieved {len(tasks)} tasks")
            
            for task in tasks[:3]:  # Show first 3
                print_info(f"  - {task.get('task_id')}: {task.get('status')} - {task.get('command', '')[:50]}")
            
            return True
        else:
            print_error(f"Failed to list tasks: {response.status_code}")
            return False
            
    except Exception as e:
        print_error(f"Error listing tasks: {e}")
        return False

def test_tool_specific_streaming() -> bool:
    """Test tool-specific streaming endpoint"""
    print_header("Test 7: Tool-Specific Streaming (echo)")
    try:
        # Use echo as a simple test (not in the tool list but demonstrates the concept)
        # In production, use actual tools like nmap, gobuster, etc.
        payload = {
            "command": "echo 'Testing tool-specific streaming' && sleep 1 && echo 'Done!'",
            "auto_start": True
        }
        
        response = requests.post(
            f"{SERVER_URL}/api/stream/create",
            json=payload,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            task_id = data.get("task_id")
            print_success(f"Tool-specific task created: {task_id}")
            
            # Brief stream test
            time.sleep(2)  # Let it execute
            
            # Check final status
            info_response = requests.get(
                f"{SERVER_URL}/api/stream/{task_id}/info",
                timeout=5
            )
            
            if info_response.status_code == 200:
                task_info = info_response.json().get("task_info", {})
                print_info(f"Final status: {task_info.get('status')}")
                return True
            
        print_error("Tool-specific streaming test failed")
        return False
        
    except Exception as e:
        print_error(f"Error in tool-specific streaming: {e}")
        return False

def main():
    """Run all tests"""
    print("\n" + "="*70)
    print("  HexStrike SSE Streaming API Test Suite")
    print("="*70)
    
    results = []
    
    # Test 1: Health check
    results.append(("Health Check", test_health_check()))
    
    if not results[0][1]:
        print_error("\nServer is not available. Exiting tests.")
        sys.exit(1)
    
    # Test 2: Create task
    task_id = test_create_streaming_task()
    results.append(("Create Task", task_id is not None))
    
    if not task_id:
        print_error("\nCannot proceed without task ID. Exiting tests.")
        sys.exit(1)
    
    # Test 3: Get task info
    results.append(("Get Task Info", test_get_task_info(task_id)))
    
    # Test 4: Start task
    results.append(("Start Task", test_start_streaming_task(task_id)))
    
    # Test 5: Stream output
    results.append(("Stream Output", test_stream_output(task_id)))
    
    # Test 6: List tasks
    results.append(("List Tasks", test_list_tasks()))
    
    # Test 7: Tool-specific streaming
    results.append(("Tool-Specific Streaming", test_tool_specific_streaming()))
    
    # Summary
    print_header("Test Summary")
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\n{'='*70}")
    print(f"  Results: {passed}/{total} tests passed")
    print(f"{'='*70}\n")
    
    sys.exit(0 if passed == total else 1)

if __name__ == "__main__":
    main()

# Made with Bob

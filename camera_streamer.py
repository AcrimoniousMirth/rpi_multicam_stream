#!/usr/bin/env python3
"""
USB Webcam Streamer - Multi-camera MJPEG streaming
Lightweight implementation using ffmpeg for video capture and streaming
"""

import subprocess
import threading
import logging
import signal
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn


class CameraStream:
    """Manages a single camera stream using ffmpeg"""
    
    def __init__(self, config):
        self.name = config['name']
        self.device = config['device']
        self.port = config['port']
        self.width = config['resolution']['width']
        self.height = config['resolution']['height']
        self.fps = config['framerate']
        self.rotation = config.get('rotation', 0)
        self.quality = config.get('quality', 80)
        
        self.process = None
        self.running = False
        self.logger = logging.getLogger(f"Camera-{self.name}")
        
    def build_ffmpeg_command(self):
        """Build ffmpeg command for camera capture and streaming"""
        # Base command with v4l2 input
        cmd = [
            'ffmpeg',
            '-f', 'v4l2',
            '-input_format', 'mjpeg',  # Try MJPEG first for USB cameras
            '-video_size', f'{self.width}x{self.height}',
            '-framerate', str(self.fps),
            '-i', self.device,
        ]
        
        # Add rotation filter if needed
        if self.rotation != 0:
            if self.rotation == 90:
                cmd.extend(['-vf', 'transpose=1'])
            elif self.rotation == 180:
                cmd.extend(['-vf', 'transpose=1,transpose=1'])
            elif self.rotation == 270:
                cmd.extend(['-vf', 'transpose=2'])
        
        # Output to stdout as MJPEG
        cmd.extend([
            '-c:v', 'mjpeg',
            '-q:v', str(100 - self.quality),  # ffmpeg quality is inverse (lower = better)
            '-f', 'mpjpeg',
            'pipe:1'
        ])
        
        return cmd
    
    def start(self):
        """Start the camera capture process"""
        if self.running:
            self.logger.warning("Camera already running")
            return
        
        try:
            cmd = self.build_ffmpeg_command()
            self.logger.info(f"Starting camera on {self.device}")
            self.logger.debug(f"Command: {' '.join(cmd)}")
            
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=10**8
            )
            
            self.running = True
            self.logger.info(f"Camera started successfully on port {self.port}")
            
        except Exception as e:
            self.logger.error(f"Failed to start camera: {e}")
            raise
    
    def stop(self):
        """Stop the camera capture process"""
        if not self.running:
            return
        
        self.logger.info("Stopping camera")
        self.running = False
        
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.logger.warning("Force killing camera process")
                self.process.kill()
                self.process.wait()
        
        self.logger.info("Camera stopped")
    
    def read_frame(self):
        """Read a single MJPEG frame from ffmpeg output"""
        if not self.running or not self.process:
            return None
        
        try:
            # Read MJPEG boundary
            while True:
                line = self.process.stdout.readline()
                if not line:
                    return None
                if b'--' in line:  # MJPEG boundary marker
                    break
            
            # Read headers
            headers = {}
            while True:
                line = self.process.stdout.readline()
                if line == b'\r\n' or line == b'\n':
                    break
                if b':' in line:
                    key, value = line.decode().strip().split(':', 1)
                    headers[key.strip()] = value.strip()
            
            # Read frame data
            content_length = int(headers.get('Content-Length', 0))
            if content_length > 0:
                frame_data = self.process.stdout.read(content_length)
                return frame_data
            
        except Exception as e:
            self.logger.error(f"Error reading frame: {e}")
            return None


class StreamingHandler(BaseHTTPRequestHandler):
    """HTTP request handler for MJPEG streaming"""
    
    camera = None  # Will be set by the server
    
    def do_GET(self):
        """Handle GET requests"""
        if self.path == '/stream':
            self.stream_mjpeg()
        elif self.path == '/' or self.path == '/index.html':
            self.send_index()
        else:
            self.send_error(404, "File not found")
    
    def stream_mjpeg(self):
        """Stream MJPEG frames"""
        self.send_response(200)
        self.send_header('Content-type', 'multipart/x-mixed-replace; boundary=--jpgboundary')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Connection', 'close')
        self.end_headers()
        
        try:
            while self.camera.running:
                frame = self.camera.read_frame()
                if frame:
                    self.wfile.write(b'--jpgboundary\r\n')
                    self.wfile.write(b'Content-Type: image/jpeg\r\n')
                    self.wfile.write(f'Content-Length: {len(frame)}\r\n\r\n'.encode())
                    self.wfile.write(frame)
                    self.wfile.write(b'\r\n')
                else:
                    time.sleep(0.01)  # Prevent busy loop
        except BrokenPipeError:
            logging.debug("Client disconnected")
        except Exception as e:
            logging.error(f"Streaming error: {e}")
    
    def send_index(self):
        """Send a simple HTML page to view the stream"""
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>{self.camera.name} Stream</title>
            <style>
                body {{ 
                    font-family: Arial, sans-serif; 
                    text-align: center; 
                    background: #1a1a1a;
                    color: #fff;
                    padding: 20px;
                }}
                h1 {{ color: #4CAF50; }}
                img {{ 
                    max-width: 90vw; 
                    max-height: 80vh; 
                    border: 2px solid #4CAF50;
                    border-radius: 8px;
                }}
                .info {{
                    background: #2a2a2a;
                    padding: 15px;
                    border-radius: 8px;
                    margin: 20px auto;
                    max-width: 600px;
                }}
            </style>
        </head>
        <body>
            <h1>{self.camera.name}</h1>
            <div class="info">
                <p><strong>Device:</strong> {self.camera.device}</p>
                <p><strong>Resolution:</strong> {self.camera.width}x{self.camera.height}</p>
                <p><strong>FPS:</strong> {self.camera.fps}</p>
                <p><strong>Rotation:</strong> {self.camera.rotation}°</p>
            </div>
            <img src="/stream" alt="Camera Stream">
        </body>
        </html>
        """
        
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(html.encode())
    
    def log_message(self, format, *args):
        """Override to use proper logging"""
        logging.debug(f"{self.address_string()} - {format % args}")


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Threaded HTTP server for handling multiple simultaneous connections"""
    allow_reuse_address = True
    daemon_threads = True


class CameraServer:
    """HTTP server for streaming a single camera"""
    
    def __init__(self, camera):
        self.camera = camera
        self.server = None
        self.thread = None
        self.logger = logging.getLogger(f"Server-{camera.name}")
    
    def start(self):
        """Start the HTTP server"""
        try:
            # Create handler class with camera reference
            handler = type('Handler', (StreamingHandler,), {'camera': self.camera})
            
            self.server = ThreadedHTTPServer(('0.0.0.0', self.camera.port), handler)
            self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
            self.thread.start()
            
            self.logger.info(f"HTTP server started on port {self.camera.port}")
            
        except Exception as e:
            self.logger.error(f"Failed to start HTTP server: {e}")
            raise
    
    def stop(self):
        """Stop the HTTP server"""
        if self.server:
            self.logger.info("Stopping HTTP server")
            self.server.shutdown()
            self.thread.join(timeout=5)
            self.logger.info("HTTP server stopped")

#!/usr/bin/env python3
"""
Main entry point for USB Webcam Streamer
"""

import yaml
import logging
import signal
import sys
import time
from pathlib import Path
from camera_streamer import CameraStream, CameraServer


class WebcamStreamerApp:
    """Main application class"""
    
    def __init__(self, config_path):
        self.config_path = config_path
        self.cameras = []
        self.servers = []
        self.running = False
        self.logger = logging.getLogger("WebcamStreamer")
    
    def load_config(self):
        """Load configuration from YAML file"""
        try:
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            if not config or 'cameras' not in config:
                raise ValueError("Invalid configuration: 'cameras' section missing")
            
            if not config['cameras']:
                raise ValueError("No cameras configured")
            
            return config
            
        except FileNotFoundError:
            self.logger.error(f"Configuration file not found: {self.config_path}")
            raise
        except yaml.YAMLError as e:
            self.logger.error(f"Invalid YAML in configuration file: {e}")
            raise
    
    def setup_logging(self, config):
        """Setup logging based on configuration"""
        settings = config.get('settings', {})
        log_level = settings.get('log_level', 'INFO')
        log_file = settings.get('log_file')
        
        # Configure root logger
        level = getattr(logging, log_level.upper(), logging.INFO)
        
        # Format
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(formatter)
        
        handlers = [console_handler]
        
        # File handler (optional)
        if log_file:
            try:
                file_handler = logging.FileHandler(log_file)
                file_handler.setFormatter(formatter)
                handlers.append(file_handler)
            except Exception as e:
                print(f"Warning: Could not create log file {log_file}: {e}")
        
        logging.basicConfig(
            level=level,
            handlers=handlers
        )
    
    def validate_camera_config(self, camera_config):
        """Validate a single camera configuration"""
        required = ['name', 'device', 'port', 'resolution', 'framerate']
        for field in required:
            if field not in camera_config:
                raise ValueError(f"Camera configuration missing required field: {field}")
        
        resolution = camera_config['resolution']
        if 'width' not in resolution or 'height' not in resolution:
            raise ValueError("Resolution must include 'width' and 'height'")
        
        # Check for valid rotation
        rotation = camera_config.get('rotation', 0)
        if rotation not in [0, 90, 180, 270]:
            raise ValueError(f"Invalid rotation: {rotation}. Must be 0, 90, 180, or 270")
    
    def start(self):
        """Start all camera streams and servers"""
        try:
            # Load configuration
            config = self.load_config()
            
            # Setup logging
            self.setup_logging(config)
            
            self.logger.info("Starting USB Webcam Streamer")
            self.logger.info(f"Loading configuration from {self.config_path}")
            
            # Validate and create cameras
            for idx, cam_config in enumerate(config['cameras']):
                try:
                    self.validate_camera_config(cam_config)
                    
                    # Create camera stream
                    camera = CameraStream(cam_config)
                    camera.start()
                    self.cameras.append(camera)
                    
                    # Create HTTP server
                    server = CameraServer(camera)
                    server.start()
                    self.servers.append(server)
                    
                    self.logger.info(
                        f"Camera '{cam_config['name']}' streaming on "
                        f"http://0.0.0.0:{cam_config['port']}/stream"
                    )
                    
                except Exception as e:
                    self.logger.error(f"Failed to start camera {idx}: {e}")
                    # Continue with other cameras
            
            if not self.cameras:
                self.logger.error("No cameras started successfully")
                return False
            
            self.running = True
            self.logger.info(f"Successfully started {len(self.cameras)} camera(s)")
            
            # Print access information
            print("\n" + "="*60)
            print("USB Webcam Streamer - Running")
            print("="*60)
            for camera in self.cameras:
                print(f"  {camera.name}: http://<raspberry-pi-ip>:{camera.port}/stream")
            print("="*60 + "\n")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to start application: {e}")
            self.stop()
            return False
    
    def stop(self):
        """Stop all cameras and servers"""
        if not self.running:
            return
        
        self.logger.info("Shutting down...")
        self.running = False
        
        # Stop servers
        for server in self.servers:
            try:
                server.stop()
            except Exception as e:
                self.logger.error(f"Error stopping server: {e}")
        
        # Stop cameras
        for camera in self.cameras:
            try:
                camera.stop()
            except Exception as e:
                self.logger.error(f"Error stopping camera: {e}")
        
        self.cameras.clear()
        self.servers.clear()
        
        self.logger.info("Shutdown complete")
    
    def run(self):
        """Run the application until interrupted"""
        if not self.start():
            sys.exit(1)
        
        try:
            # Keep running until interrupted
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.logger.info("Received keyboard interrupt")
        finally:
            self.stop()


def signal_handler(signum, frame):
    """Handle shutdown signals"""
    print(f"\nReceived signal {signum}, shutting down...")
    if hasattr(signal_handler, 'app'):
        signal_handler.app.stop()
    sys.exit(0)


def main():
    """Main entry point"""
    # Default config path
    config_path = Path(__file__).parent / 'config.yaml'
    
    # Allow override via command line
    if len(sys.argv) > 1:
        config_path = Path(sys.argv[1])
    
    # Create and run app
    app = WebcamStreamerApp(str(config_path))
    
    # Setup signal handlers
    signal_handler.app = app
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run the application
    app.run()


if __name__ == '__main__':
    main()

import pygame
import sys
import tkinter as tk
from tkinter import ttk, scrolledtext
from serial import Serial, SerialException, tools
from serial.tools.list_ports import comports
from threading import Thread, Lock
from queue import Queue
import gzip
import pickle
import random

# Pygame constants
CELL_SIZE = 20
GRID_SIZE = 28
MAX_INTENSITY = 50
BRUSH_STRENGTH = 1
COLORS = {
    'white': (255, 255, 255),
    'black': (0, 0, 0),
    'gray': (200, 200, 200)
}

class SerialInterface:
    def __init__(self, console_callback):
        self.ser = None
        self.connected = False
        self.console_queue = Queue()
        self.lock = Lock()
        self.console_callback = console_callback
        self.running = True
        self.receive_thread = Thread(target=self.receive_data, daemon=True)
        
    def connect(self, port, baudrate):
        try:
            with self.lock:
                self.ser = Serial(port=port, baudrate=baudrate, timeout=0.1)
                self.connected = True
                self.receive_thread.start()
                self.log_message(f"Connected to {port} @ {baudrate}")
                return True
        except SerialException as e:
            self.log_message(f"Connection failed: {str(e)}", error=True)
            return False
            
    def disconnect(self):
        with self.lock:
            if self.ser and self.ser.is_open:
                self.ser.close()
            self.connected = False
            self.log_message("Disconnected")
            
    def send_data(self, data):
        if not self.connected:
            self.log_message("Not connected!", error=True)
            return False
        try:
            with self.lock:
                self.ser.write(data)
                self.log_message(f"Sent {len(data)} bytes: {data.hex()}", tx=True)
                return True
        except SerialException as e:
            self.log_message(f"Send failed: {str(e)}", error=True)
            self.disconnect()
            return False
            
    def receive_data(self):
        buffer = bytearray()
        while self.connected:
            try:
                with self.lock:
                    if self.ser.in_waiting:
                        data = self.ser.read(self.ser.in_waiting)
                        buffer += data
                        
                        # Try to decode complete UTF-8 messages
                        while True:
                            try:
                                message = buffer.decode('utf-8')
                                buffer.clear()
                                self.log_message(message, rx=True)
                                break
                            except UnicodeDecodeError:
                                # Wait for more data if incomplete
                                break
            except SerialException:
                self.disconnect()
                
    def log_message(self, message, error=False, tx=False, rx=False):
        self.console_queue.put((message, error, tx, rx))
        
    def update_console(self):
        while not self.console_queue.empty():
            message, error, tx, rx = self.console_queue.get()
            self.console_callback(message, error, tx, rx)

class PygameDrawing:
    def __init__(self):
        self.grid = [[0 for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]
        self.running = False
        self.drawing = False
        self.last_pos = None
        self.brush_radius = 1  # Brush size in cells
        self.mnist_images = self.load_mnist_from_pklgz('mnist.pkl.gz')  # Update file name

    def load_mnist_from_pklgz(self, filename):
        """Load MNIST from pickle.gz format"""
        try:
            with gzip.open(filename, 'rb') as f:
                data = pickle.load(f, encoding='latin1')
                # Assuming data structure: (train_images, train_labels), (valid...), (test...)
                train_images = data[0][0]
                # Reshape and convert to 2D arrays
                return [img.reshape(28, 28) for img in train_images]
        except Exception as e:
            print(f"Error loading MNIST: {str(e)}")
            return []

    def load_random_mnist(self):
        """Load a random MNIST image into the drawing grid"""
        if not self.mnist_images:
            return False
        
        img = random.choice(self.mnist_images)
        for y in range(GRID_SIZE):
            for x in range(GRID_SIZE):
                # Convert from 0-1 float to 0-MAX_INTENSITY scale
                pixel_value = int(img[y][x] * MAX_INTENSITY)
                self.grid[y][x] = min(pixel_value, MAX_INTENSITY)
        return True

    def clear_grid(self):
        self.grid = [[0 for _ in range(GRID_SIZE)] for _ in range(GRID_SIZE)]

    def start(self):
        pygame.init()
        self.screen = pygame.display.set_mode((GRID_SIZE*CELL_SIZE, GRID_SIZE*CELL_SIZE))
        pygame.display.set_caption("Drawing Grid")
        self.running = True
        self.run()
        
    def run(self):
        while self.running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    self.running = False
                    break
                elif event.type == pygame.MOUSEBUTTONDOWN:
                    if event.button in (1, 3):  # Left or right click
                        self.drawing = True
                        self.handle_drawing(event.pos, event.button)
                elif event.type == pygame.MOUSEBUTTONUP:
                    if event.button in (1, 3):
                        self.drawing = False
                        self.last_pos = None
                elif event.type == pygame.MOUSEMOTION:
                    if self.drawing:
                        self.handle_drawing(event.pos, 
                                            pygame.mouse.get_pressed()[0] and 1 or 3)
            
            self.draw_grid()
            self.draw_brush_preview()
            pygame.display.flip()

    def handle_drawing(self, pos, button):
        x = pos[0] // CELL_SIZE
        y = pos[1] // CELL_SIZE
        
        # Calculate affected cells with brush radius
        for dy in range(-self.brush_radius, self.brush_radius + 1):
            for dx in range(-self.brush_radius, self.brush_radius + 1):
                if dx*dx + dy*dy <= self.brush_radius**2:
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < GRID_SIZE and 0 <= ny < GRID_SIZE:
                        if button == 1:  # Draw
                            self.grid[ny][nx] = min(
                                self.grid[ny][nx] + BRUSH_STRENGTH, 
                                MAX_INTENSITY
                            )
                        elif button == 3:  # Erase
                            self.grid[ny][nx] = max(
                                self.grid[ny][nx] - BRUSH_STRENGTH, 
                                0
                            )

    def draw_brush_preview(self):
        mouse_pos = pygame.mouse.get_pos()
        x = mouse_pos[0] // CELL_SIZE
        y = mouse_pos[1] // CELL_SIZE
        
        # Draw brush preview
        preview_color = (255, 0, 0) if pygame.mouse.get_pressed()[0] else (0, 255, 0)
        for dy in range(-self.brush_radius, self.brush_radius + 1):
            for dx in range(-self.brush_radius, self.brush_radius + 1):
                if dx*dx + dy*dy <= self.brush_radius**2:
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < GRID_SIZE and 0 <= ny < GRID_SIZE:
                        pygame.draw.rect(
                            self.screen, preview_color,
                            (nx*CELL_SIZE + 1, ny*CELL_SIZE + 1, CELL_SIZE-2, CELL_SIZE-2),
                            1
                        )
            
    def draw_grid(self):
        self.screen.fill(COLORS['white'])
        for y in range(GRID_SIZE):
            for x in range(GRID_SIZE):
                if self.grid[y][x] > 0:
                    intensity = 255 - (self.grid[y][x] * (255 // MAX_INTENSITY))
                    pygame.draw.rect(
                        self.screen,
                        (intensity, intensity, intensity),
                        (x*CELL_SIZE, y*CELL_SIZE, CELL_SIZE, CELL_SIZE)
                    )
                    
        # Draw grid lines
        for x in range(GRID_SIZE + 1):
            pygame.draw.line(
                self.screen,
                COLORS['gray'],
                (x * CELL_SIZE, 0),
                (x * CELL_SIZE, GRID_SIZE * CELL_SIZE)
            )
        for y in range(GRID_SIZE + 1):
            pygame.draw.line(
                self.screen,
                COLORS['gray'],
                (0, y * CELL_SIZE),
                (GRID_SIZE * CELL_SIZE, y * CELL_SIZE)
            )

class Application(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Serial Control Console")
        self.serial = SerialInterface(self.console_callback)
        self.drawing = PygameDrawing()
        self.protocol("WM_DELETE_WINDOW", self.on_close)
        
        # Start Pygame in separate thread
        self.pygame_thread = Thread(target=self.drawing.start, daemon=True)
        self.pygame_thread.start()
        
        # GUI Setup
        self.create_widgets()
        self.after(100, self.update_console)
        
    def create_widgets(self):
        # Serial Controls
        control_frame = ttk.Frame(self)
        control_frame.pack(padx=10, pady=5, fill=tk.X)
        
        # Port Selection
        ttk.Label(control_frame, text="Port:").grid(row=0, column=0, sticky='w')
        self.port_combo = ttk.Combobox(control_frame, width=20)
        self.port_combo.grid(row=0, column=1, padx=5)
        
        # Baud Rate
        ttk.Label(control_frame, text="Baud:").grid(row=0, column=2, sticky='w')
        self.baud_combo = ttk.Combobox(control_frame, 
                                     values=[9600, 19200, 38400, 57600, 115200],
                                     width=10)
        self.baud_combo.grid(row=0, column=3)
        self.baud_combo.set("115200")
        
        # Control Buttons
        self.connect_btn = ttk.Button(control_frame, text="Connect", command=self.toggle_connection)
        self.connect_btn.grid(row=0, column=4, padx=5)
        ttk.Button(control_frame, text="Refresh", command=self.update_ports).grid(row=0, column=5)
        ttk.Button(control_frame, text="Send Image", command=self.send_image).grid(row=0, column=6)
        ttk.Button(control_frame, text="Clear Grid", command=self.clear_grid).grid(row=0, column=7, padx=5)
        ttk.Button(control_frame, text="Load MNIST", command=self.load_mnist).grid(row=0, column=8, padx=5)
        ttk.Button(control_frame, text="Recognize", command=self.send_recognize).grid(row=0, column=9, padx=5)

        # Console
        console_frame = ttk.LabelFrame(self, text="Serial Console")
        console_frame.pack(padx=10, pady=5, fill=tk.BOTH, expand=True)
        
        self.console = scrolledtext.ScrolledText(console_frame, wrap=tk.WORD, height=15)
        self.console.pack(fill=tk.BOTH, expand=True)
        self.console.tag_config('error', foreground='red')
        self.console.tag_config('tx', foreground='blue')
        self.console.tag_config('rx', foreground='green')
        
        # Command Entry
        cmd_frame = ttk.Frame(self)
        cmd_frame.pack(padx=10, pady=5, fill=tk.X)
        
        self.cmd_entry = ttk.Entry(cmd_frame)
        self.cmd_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        ttk.Button(cmd_frame, text="Send", command=self.send_command).pack(side=tk.RIGHT)

        # Add brush size controls
        control_frame = ttk.Frame(self)
        control_frame.pack(padx=10, pady=5, fill=tk.X)
        
        ttk.Label(control_frame, text="Brush Size:").pack(side=tk.LEFT)
        self.brush_size = ttk.Scale(control_frame, from_=1, to=5, 
                                  command=lambda v: setattr(self.drawing, 'brush_radius', int(float(v))))
        self.brush_size.set(1)
        self.brush_size.pack(side=tk.LEFT, padx=5)
        
        # Initial setup
        self.update_ports()

    def load_mnist(self):
        if self.drawing.load_random_mnist():
            self.serial.log_message("Loaded random MNIST image")
        else:
            self.serial.log_message("Failed to load MNIST images!", error=True)
     
    def update_ports(self):
        ports = [p.device for p in comports()]
        self.port_combo['values'] = ports
        if ports:
            self.port_combo.current(0)
            
    def toggle_connection(self):
        if self.serial.connected:
            self.serial.disconnect()
            self.connect_btn.config(text="Connect")
        else:
            if self.serial.connect(self.port_combo.get(), int(self.baud_combo.get())):
                self.connect_btn.config(text="Disconnect")
                
    def send_image(self):
        if not self.serial.connected:
            return
        self.serial.send_data(b'g')   
        scaled_data = []
        for row in self.drawing.grid:
            scaled_row = [min(int(val * (255/MAX_INTENSITY)), 255) for val in row]
            scaled_data.extend(scaled_row)
        self.serial.send_data(bytes(scaled_data))
        # self.serial.send_data(b'd')
        
    def send_command(self):
        cmd = self.cmd_entry.get()
        if cmd and self.serial.connected:
            self.serial.send_data(cmd.encode() + b'\r\n')
            self.cmd_entry.delete(0, tk.END)

    def clear_grid(self):
        self.drawing.clear_grid()
        self.serial.log_message("Grid cleared")
    
    def send_recognize(self):
        if self.serial.connected:
            self.serial.send_data(b'd')
            self.serial.log_message("Sent recognition command")
        else:
            self.serial.log_message("Not connected!", error=True)
            
    def console_callback(self, message, error, tx, rx):
        tag = 'error' if error else 'tx' if tx else 'rx' if rx else ''
        self.console.insert(tk.END, message + '\n', tag)
        self.console.see(tk.END)
        
    def update_console(self):
        self.serial.update_console()
        self.after(100, self.update_console)
        
    def on_close(self):
        self.drawing.running = False
        self.serial.disconnect()
        self.destroy()

if __name__ == "__main__":
    app = Application()
    app.mainloop()
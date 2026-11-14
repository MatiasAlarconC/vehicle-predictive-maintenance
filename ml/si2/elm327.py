"""Emulador de adaptador ELM327 por TCP (como los adaptadores Wi-Fi) y cliente de referencia.

El emulador responde a los comandos AT de inicializacion y a las consultas del modo 01 de OBD-II
con los valores de una sesion grabada, codificados con las formulas del estandar SAE J1979.
"""
import socket
import threading

import numpy as np

import comun as C

# PID -> (bytes, codificar valor fisico -> entero, decodificar bytes -> valor fisico)
PID = {
    'ENGINE_RPM': ('0C', 2, lambda v: v * 4, lambda a, b: (256 * a + b) / 4),
    'VEHICLE_SPEED': ('0D', 1, lambda v: v, lambda a: a),
    'THROTTLE': ('11', 1, lambda v: v * 255 / 100, lambda a: a * 100 / 255),
    'ENGINE_LOAD': ('04', 1, lambda v: v * 255 / 100, lambda a: a * 100 / 255),
    'COOLANT_TEMPERATURE': ('05', 1, lambda v: v + 40, lambda a: a - 40),
    'LONG_TERM_FUEL_TRIM_BANK_1': ('07', 1, lambda v: (v + 100) * 1.28, lambda a: a / 1.28 - 100),
    'SHORT_TERM_FUEL_TRIM_BANK_1': ('06', 1, lambda v: (v + 100) * 1.28, lambda a: a / 1.28 - 100),
    'INTAKE_MANIFOLD_PRESSURE': ('0B', 1, lambda v: v, lambda a: a),
    'INTAKE_AIR_TEMP': ('0F', 1, lambda v: v + 40, lambda a: a - 40),
    'TIMING_ADVANCE': ('0E', 1, lambda v: (v + 64) * 2, lambda a: a / 2 - 64),
    'CATALYST_TEMPERATURE_BANK1_SENSOR1': ('3C', 2, lambda v: (v + 40) * 10, lambda a, b: (256 * a + b) / 10 - 40),
    'CONTROL_MODULE_VOLTAGE': ('42', 2, lambda v: v * 1000, lambda a, b: (256 * a + b) / 1000),
}
POR_CODIGO = {v[0]: k for k, v in PID.items()}


def mascara(base):
    """Respuesta a 0100/0120/0140: mapa de bits de los PIDs soportados en [base+1, base+32]."""
    bits = 0
    for cod in POR_CODIGO:
        n = int(cod, 16)
        if base < n <= base + 32:
            bits |= 1 << (32 - (n - base))
    if base < 0x40:  # indica que existe el siguiente bloque
        bits |= 1
    return '%08X' % bits


class Emulador(threading.Thread):
    """Sirve una sesion (T, 12). Avanza un registro cada vez que se consulta el primer PID (RPM)."""

    def __init__(self, sesion, puerto=0):
        super().__init__(daemon=True)
        self.x, self.t = sesion, -1
        self.srv = socket.socket()
        self.srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.srv.bind(('127.0.0.1', puerto))
        self.srv.listen(1)
        self.puerto = self.srv.getsockname()[1]
        self.eco = True

    def responder(self, cmd):
        cmd = cmd.replace(' ', '').upper()
        if cmd.startswith('AT'):
            if cmd == 'ATZ':
                return 'ELM327 v1.5'
            if cmd == 'ATE0':
                self.eco = False
            if cmd == 'ATRV':
                return '%.1fV' % self.x[max(self.t, 0), C.IX['CONTROL_MODULE_VOLTAGE']]
            if cmd == 'ATDPN':
                return 'A6'
            return 'OK'
        if len(cmd) == 4 and cmd.startswith('01'):
            cod = cmd[2:]
            if cod in ('00', '20', '40'):
                return '41' + cod + mascara(int(cod, 16))
            if cod in POR_CODIGO:
                nombre = POR_CODIGO[cod]
                if cod == '0C':
                    self.t += 1
                if self.t >= len(self.x):
                    return 'NO DATA'
                _, nb, enc, _ = PID[nombre]
                v = int(round(float(enc(self.x[self.t, C.IX[nombre]]))))
                v = min(max(v, 0), 256 ** nb - 1)
                return '41' + cod + ('%0*X' % (2 * nb, v))
            return 'NO DATA'
        return '?'

    def run(self):
        con, _ = self.srv.accept()
        buf = b''
        with con:
            while True:
                d = con.recv(1024)
                if not d:
                    break
                buf += d
                while b'\r' in buf:
                    linea, buf = buf.split(b'\r', 1)
                    cmd = linea.decode().strip()
                    r = self.responder(cmd)
                    con.sendall(((cmd + '\r' if self.eco else '') + r + '\r\r>').encode())


class ClienteElm327:
    """Cliente de referencia: inicializa el adaptador, descubre los PIDs soportados y lee los 12 PIDs."""

    def __init__(self, host, puerto):
        self.s = socket.create_connection((host, puerto))
        self.s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        for c in ('ATZ', 'ATE0', 'ATL0', 'ATS0', 'ATH0', 'ATSP0'):
            self.cmd(c)
        self.soportados = set()
        for base in ('00', '20', '40'):
            r = self.cmd('01' + base)
            if not r.startswith('41' + base):
                break
            bits = int(r[4:12], 16)
            for i in range(32):
                if bits & (1 << (31 - i)):
                    self.soportados.add('%02X' % (int(base, 16) + i + 1))

    def cmd(self, c):
        self.s.sendall((c + '\r').encode())
        buf = b''
        while not buf.endswith(b'>'):
            d = self.s.recv(1024)
            if not d:
                break
            buf += d
        lineas = [l.strip() for l in buf.decode().replace('>', '').split('\r') if l.strip()]
        return lineas[-1].replace(' ', '') if lineas else ''

    def leer(self):
        """Devuelve los 12 valores en el orden de comun.PIDS, o None si el adaptador ya no tiene datos."""
        out = []
        for nombre in C.PIDS:
            cod, nb, _, dec = PID[nombre]
            r = self.cmd('01' + cod)
            if not r.startswith('41' + cod):
                return None
            datos = bytes.fromhex(r[4:4 + 2 * nb])
            out.append(dec(*datos))
        return np.array(out, np.float32)

    def cerrar(self):
        self.s.close()


if __name__ == '__main__':
    # Uso: python elm327.py <puerto> [sesion]   (sirve una sesion de carOBD a un cliente)
    import sys
    ses, _ = C.load_carobd()
    nombre = sys.argv[2] if len(sys.argv) > 2 else sorted(ses)[0]
    emu = Emulador(ses[nombre], int(sys.argv[1]))
    print('Emulador ELM327 en 127.0.0.1:%d con la sesion %s (%d s)' % (emu.puerto, nombre, len(ses[nombre])), flush=True)
    emu.run()

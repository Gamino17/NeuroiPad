# Referencia del SDK Muse 8.0.5

## 📚 Información del SDK

**Versión**: 8.0.5  
**Ubicación**: `/Users/danielgamino/Desktop/Trabajo/Neuroelite/Bandas/Muse/Muse SDK/Muse SDK 8.0.5/libmuse_ios_8.0.5/`  
**Ejemplo Oficial**: `MuseStatsIosSwift`

---

## 🎯 Clases Principales del SDK

### IXNMuseManager (IXNMuseManagerIos)

**Propósito**: Manager principal para escanear y gestionar dispositivos Muse.

```swift
let museManager = IXNMuseManagerIos()

// Configuración
museManager.removeFromList(after: 10)  // Elimina dispositivos no encontrados después de 10s
museManager.setMuseListener(listener)  // Registra listener para cambios en la lista

// Control de escaneo
museManager.startListening()  // Inicia escaneo Bluetooth
museManager.stopListening()   // Detiene escaneo

// Obtener dispositivos
let muses = museManager.getMuses()  // Array de IXNMuse encontrados
```

### IXNMuse

**Propósito**: Representa un dispositivo Muse individual.

```swift
// Información del dispositivo
let name = muse.getName()              // "Muse-1234"
let mac = muse.getMacAddress()         // "00:11:22:33:44:55"
let state = muse.getConnectionState()  // .disconnected, .connecting, .connected

// Registro de listeners
muse.register(connectionListener)                    // Listener de conexión
muse.register(dataListener, type: .eeg)             // Listener de datos EEG
muse.register(dataListener, type: .accelerometer)   // Listener de acelerómetro
muse.register(dataListener, type: .ppg)             // Listener de PPG
muse.unregisterAllListeners()                       // Elimina todos los listeners

// Configuración
muse.setPreset(IXNMusePreset.preset21)  // Preset 21: 256 Hz, notch 60Hz

// Conexión (opción 1: async automático - RECOMENDADO)
muse.runAsynchronously()  // SDK maneja el loop async internamente

// Conexión (opción 2: manual)
muse.connect()
DispatchQueue.global().async {
    while muse.getConnectionState() != .disconnected {
        muse.execute()  // Procesar eventos
        Thread.sleep(forTimeInterval: 0.02)  // 50 Hz
    }
}

// Desconexión
muse.disconnect()
```

### IXNMusePreset

**Presets disponibles**:

| Preset | Sampling Rate | Notch Filter | Uso Recomendado |
|--------|---------------|--------------|-----------------|
| `preset10` | 500 Hz | 50 Hz | Europa (50 Hz power) |
| `preset12` | 500 Hz | 60 Hz | USA (60 Hz power) |
| `preset14` | 500 Hz | None | Sin filtro de red |
| `preset20` | 256 Hz | 50 Hz | Europa, más eficiente |
| `preset21` | **256 Hz** | **60 Hz** | **USA, RECOMENDADO** |
| `preset22` | 256 Hz | None | Sin filtro |
| `preset23` | 256 Hz | 50/60 Hz | Filtro dual |

**Recomendación**: Usa `preset21` (256 Hz, 60 Hz notch) para USA/México.

---

## 📡 Tipos de Datos

### 1. EEG (Electroencefalografía)

**Tipo de paquete**: `IXNMuseDataPacketType.eeg`

```swift
func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
    if packet?.packetType() == .eeg {
        let tp9 = packet.getEegChannelValue(.tp9)   // Temporal posterior izquierdo
        let af7 = packet.getEegChannelValue(.af7)   // Frontal anterior izquierdo
        let af8 = packet.getEegChannelValue(.af8)   // Frontal anterior derecho
        let tp10 = packet.getEegChannelValue(.tp10) // Temporal posterior derecho
    }
}
```

**Canales EEG**:
- `TP9`: Temporal Posterior Izquierdo (detrás oreja izquierda)
- `AF7`: Frontal Anterior Izquierdo (frente izquierda)
- `AF8`: Frontal Anterior Derecho (frente derecha)
- `TP10`: Temporal Posterior Derecho (detrás oreja derecha)

**Rango de valores**: Típicamente -500 a +500 µV (microvolts)

**Frecuencia**: 256 Hz (con preset21) = 256 muestras por segundo

### 2. Accelerometer (Acelerómetro)

**Tipo de paquete**: `IXNMuseDataPacketType.accelerometer`

```swift
if packet?.packetType() == .accelerometer {
    let x = packet.getAccelerometerValue(.x)  // Eje X
    let y = packet.getAccelerometerValue(.y)  // Eje Y
    let z = packet.getAccelerometerValue(.z)  // Eje Z
}
```

**Rango**: ±8g (g = gravedad)  
**Frecuencia**: ~50 Hz  
**Uso**: Detectar movimientos de cabeza, orientación

### 3. PPG (Fotopletismografía)

**Tipo de paquete**: `IXNMuseDataPacketType.ppg`

```swift
if packet?.packetType() == .ppg {
    let ambient = packet.getPpgChannelValue(.ambient)      // Luz ambiente
    let infrared = packet.getPpgChannelValue(.infrared)    // Infrarrojo
    let red = packet.getPpgChannelValue(.red)              // Rojo
}
```

**Uso**: Medir frecuencia cardíaca, SpO2  
**Disponible**: Solo en Muse S / Muse 2

### 4. Gyroscope (Giroscopio)

**Tipo de paquete**: `IXNMuseDataPacketType.gyroscope`

```swift
if packet?.packetType() == .gyroscope {
    let x = packet.getGyroValue(.x)
    let y = packet.getGyroValue(.y)
    let z = packet.getGyroValue(.z)
}
```

**Rango**: ±2000 °/s  
**Frecuencia**: ~50 Hz  
**Uso**: Detectar rotación de cabeza

---

## 🔌 Estados de Conexión

### IXNConnectionState

```swift
enum IXNConnectionState {
    case unknown
    case disconnected    // No conectado
    case connecting      // Conectando...
    case connected       // Conectado y listo
    case needsUpdate     // Firmware necesita actualización
    case needsLicense    // Necesita licencia
}
```

**Transiciones típicas**:
```
disconnected → connecting → connected
              ↓
         disconnected (si falla)
```

---

## 👂 Listeners (Protocolos)

### 1. IXNMuseListener

**Propósito**: Notifica cambios en la lista de dispositivos disponibles.

```swift
class MuseListener: IXNMuseListener {
    func museListChanged() {
        // Se llamó cuando se encuentra/pierde un dispositivo
        let muses = museManager.getMuses()
        // Actualizar UI
    }
}
```

### 2. IXNMuseConnectionListener

**Propósito**: Notifica cambios en el estado de conexión.

```swift
class ConnectionListener: IXNMuseConnectionListener {
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {
        let prevState = packet.previousConnectionState
        let currState = packet.currentConnectionState
        
        if currState == .connected {
            print("Conectado!")
        } else if currState == .disconnected {
            print("Desconectado")
        }
    }
}
```

### 3. IXNMuseDataListener

**Propósito**: Recibe paquetes de datos (EEG, acelerómetro, etc.).

```swift
class DataListener: IXNMuseDataListener {
    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        guard let packet = packet else { return }
        
        switch packet.packetType() {
        case .eeg:
            // Procesar EEG
            break
        case .accelerometer:
            // Procesar acelerómetro
            break
        default:
            break
        }
    }
    
    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse?) {
        // Artefactos: parpadeos, masticación, etc.
    }
}
```

---

## ⚙️ Configuración Recomendada

### Setup Completo

```swift
class MuseManager {
    var museManager: IXNMuseManager?
    var museListener: IXNMuseListener?
    var dataListener: IXNMuseDataListener?
    var connectionListener: IXNMuseConnectionListener?
    
    init() {
        // 1. Crear manager
        museManager = IXNMuseManagerIos()
        
        // 2. Crear listeners
        museListener = MyMuseListener()
        dataListener = MyDataListener()
        connectionListener = MyConnectionListener()
        
        // 3. Configurar manager
        museManager?.removeFromList(after: 10)
        museManager?.setMuseListener(museListener)
        
        // 4. Iniciar escaneo
        museManager?.startListening()
    }
    
    func connect(to muse: IXNMuse) {
        // 1. Detener escaneo
        museManager?.stopListening()
        
        // 2. Limpiar listeners previos
        muse.unregisterAllListeners()
        
        // 3. Registrar nuevos listeners
        muse.register(connectionListener)
        muse.register(dataListener, type: .eeg)
        
        // 4. Configurar preset
        muse.setPreset(IXNMusePreset.preset21)
        
        // 5. Conectar
        muse.runAsynchronously()
    }
}
```

---

## 🎨 Bandas de Frecuencia EEG

Para calcular las bandas de frecuencia estándar, necesitarás aplicar FFT (Fast Fourier Transform) a los datos EEG:

| Banda | Frecuencia | Asociación |
|-------|-----------|------------|
| **Delta (δ)** | 0.5-4 Hz | Sueño profundo |
| **Theta (θ)** | 4-8 Hz | Meditación, creatividad |
| **Alpha (α)** | 8-13 Hz | Relajación, ojos cerrados |
| **Beta (β)** | 13-30 Hz | Concentración, alerta |
| **Gamma (γ)** | 30-100 Hz | Procesamiento cognitivo alto |

**Nota**: El SDK proporciona datos crudos. El cálculo de bandas requiere procesamiento adicional (FFT).

---

## 🛡️ Permisos Requeridos (Info.plist)

```xml
<!-- Bluetooth -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Necesario para conectar a dispositivos Muse</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Necesario para comunicarse con la banda Muse</string>
```

---

## 📊 Calidad de Señal

Para evaluar la calidad de la señal EEG, monitorea:

1. **Valores fuera de rango**: Si los valores son muy altos (>500 µV), puede indicar mala conexión
2. **Artefactos**: Usa `IXNMuseArtifactPacket` para detectar parpadeos, movimientos
3. **Consistency**: Señal estable sin grandes saltos repentinos

---

## 🐛 Troubleshooting Común

### No encuentra dispositivos

**Causas**:
- Muse no está encendido
- Bluetooth apagado
- Muse conectado a otro dispositivo
- Fuera de rango

**Solución**:
```swift
// Reiniciar escaneo
museManager?.stopListening()
Thread.sleep(forTimeInterval: 1.0)
museManager?.startListening()
```

### Conexión falla

**Causa**: Timeout o mala señal Bluetooth

**Solución**:
```swift
// Verificar estado antes de conectar
if muse.getConnectionState() == .disconnected {
    muse.runAsynchronously()
}
```

### Datos llegan lento o se pierden

**Causa**: Procesamiento lento en el listener

**Solución**:
```swift
// Procesar en background
func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
    DispatchQueue.global().async {
        // Procesar datos pesados aquí
    }
}
```

---

## 📖 Documentación Adicional

- **HTML Docs**: `doc/index.html` en la carpeta del SDK
- **Ejemplos**: `examples/MuseStatsIosSwift/`
- **Website**: https://choosemuse.com/
- **Developer Forums**: https://choosemuse.com/forums/

---

## ✅ Checklist de Implementación

- [x] Inicializar IXNMuseManagerIos
- [x] Configurar removeFromList
- [x] Registrar IXNMuseListener
- [x] Iniciar escaneo (startListening)
- [x] Registrar ConnectionListener en el Muse
- [x] Registrar DataListener con tipos específicos
- [x] Configurar preset (preset21 recomendado)
- [x] Usar runAsynchronously() para conexión
- [x] Manejar estados de conexión correctamente
- [x] Unregister listeners al desconectar
- [x] Cleanup en deinit

---

**Implementación Actual**: ✅ Completamente implementado en `MuseSDKAdapter.swift` basado en el ejemplo oficial.

**Última actualización**: 2025-11-20  
**Basado en**: MuseStatsIosSwift (ejemplo oficial SDK 8.0.5)


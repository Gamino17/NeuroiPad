# Integración del SDK Muse - Guía Paso a Paso

## 📦 Archivo que Necesitas

De los archivos que tienes, usa: **`libmuse_ios_8.0.5.tar.gz`**

Los otros son para:
- `libmuse_android_*` → Android (no necesario)
- `libmuse_catalyst_*` → Mac Catalyst (no necesario)
- `libmuse_macos_*` → macOS nativo (no necesario)
- `libmuse_unity_*` → Unity (no necesario)
- `libmuse_windows_*` → Windows (no necesario)

## 🚀 Pasos de Integración

### Paso 1: Descomprimir el SDK

```bash
# Navega a donde descargaste el archivo
cd ~/Downloads

# Descomprimir
tar -xzf libmuse_ios_8.0.5.tar.gz

# Verificar contenido
ls -la libmuse_ios_8.0.5/
```

Deberías ver:
```
libmuse_ios_8.0.5/
├── Muse.framework/          ← Framework principal (LO NECESITAS)
├── MuseExamples/            ← Ejemplos de código (referencia)
├── Documentation/           ← Documentación del SDK
└── README.txt               ← Instrucciones básicas
```

### Paso 2: Copiar el Framework al Proyecto

```bash
# Copiar Muse.framework a tu proyecto
cp -R ~/Downloads/libmuse_ios_8.0.5/Muse.framework \
      /Users/danielgamino/Desktop/Trabajo/Programación/NeuroiPad/NeuroiPad/ios-app/
```

### Paso 3: Abrir Xcode

```bash
cd /Users/danielgamino/Desktop/Trabajo/Programación/NeuroiPad/NeuroiPad/ios-app
open NeuroiPad.xcodeproj
```

### Paso 4: Agregar Framework en Xcode

#### Método 1: Drag & Drop (Más Fácil)

1. En **Finder**, navega a:
   ```
   /Users/danielgamino/Desktop/Trabajo/Programación/NeuroiPad/NeuroiPad/ios-app/
   ```

2. Arrastra `Muse.framework` al navegador de Xcode (sidebar izquierdo)

3. En el diálogo:
   - ✅ **"Copy items if needed"** (dejar marcado si copiaste el framework)
   - ✅ **Target: NeuroiPad** (debe estar seleccionado)
   - Click **Finish**

#### Método 2: Manual

1. Click en el **proyecto NeuroiPad** (icono azul arriba del todo)
2. Selecciona el **target "NeuroiPad"** (en la lista de targets)
3. Ve al tab **"General"**
4. Scroll hasta **"Frameworks, Libraries, and Embedded Content"**
5. Click el botón **"+"**
6. Click **"Add Other..."** → **"Add Files..."**
7. Navega a tu proyecto y selecciona `Muse.framework`
8. Click **"Open"**

### Paso 5: Configurar "Embed & Sign"

En **"Frameworks, Libraries, and Embedded Content"**:

1. Encuentra `Muse.framework`
2. En la columna derecha, cambia de **"Do Not Embed"** a **"Embed & Sign"**

### Paso 6: Configurar Linker Flags

1. Con el proyecto seleccionado, ve al tab **"Build Settings"**
2. Busca: **"Other Linker Flags"** (puedes usar el buscador arriba)
3. Haz doble click en el valor
4. Click el botón **"+"**
5. Escribe: `-ObjC`
6. Presiona Enter

### Paso 7: Verificar Info.plist

Ya está configurado en `Info.plist`, pero verifica que existan estas keys:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>La app necesita acceso a Bluetooth para conectarse a la banda Muse y capturar datos EEG durante los entrenamientos</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>La app usa Bluetooth para comunicarse con la banda Muse</string>
```

### Paso 8: Build

1. Selecciona un iPad como destino (arriba a la izquierda en Xcode)
   - Si no tienes iPad físico, selecciona un simulador de iPad
   - **NOTA**: Bluetooth NO funciona en simulador, necesitarás iPad físico para probar Muse

2. Presiona **Cmd + B** para compilar

3. Deberías ver: **"Build Succeeded"** ✅

Si hay errores, ve a la sección de [Troubleshooting](#troubleshooting) abajo.

## 🔧 Estructura del SDK Muse

### Clases Principales

El SDK de Muse incluye estas clases principales (ya abstraídas en `MuseSDKAdapter.swift`):

```swift
// Manager para escanear dispositivos
IXNMuseManagerIOS.sharedManager()

// Representación de un dispositivo Muse
IXNMuse

// Listeners para eventos
IXNMuseConnectionListener    // Estado de conexión
IXNMuseDataListener          // Datos EEG, acelerómetro, etc.

// Tipos de datos
IXNMuseDataPacketType.EEG             // Señales EEG
IXNMuseDataPacketType.ACCELEROMETER   // Acelerómetro
IXNMuseDataPacketType.PPG             // Fotopletismografía (pulso)
IXNMuseDataPacketType.GYROSCOPE       // Giroscopio

// Canales EEG de Muse
IXNEegSample.TP9    // Temporal posterior izquierdo
IXNEegSample.AF7    // Frontal anterior izquierdo
IXNEegSample.AF8    // Frontal anterior derecho
IXNEegSample.TP10   // Temporal posterior derecho
```

## 📝 Código de Integración

El código ya está preparado en `MuseSDKAdapter.swift`. Solo necesitas descomentar la sección al final del archivo (líneas ~245-310).

### Ejemplo de Uso del Adapter (Ya Implementado)

```swift
// Crear adapter
let museAdapter = MuseSDKAdapter()

// 1. Escanear dispositivos
museAdapter.startScanning()

// 2. Callback cuando se descubre un dispositivo
museAdapter.onMuseDiscovered = { device in
    print("Found: \(device.name)")
}

// 3. Conectar
museAdapter.connect(to: device)

// 4. Callback de estado
museAdapter.onConnectionStateChanged = { state in
    switch state {
    case .connected:
        print("Connected!")
    case .disconnected:
        print("Disconnected")
    default:
        break
    }
}

// 5. Recibir datos
museAdapter.onDataPacket = { packet in
    print("EEG channels: \(packet.channels)")
}

// 6. Iniciar streaming
museAdapter.startStreaming()
```

## 🧪 Probar la Integración

### Test Rápido (Sin Muse Físico)

1. Compila la app
2. Si compila sin errores, la integración del SDK está correcta ✅
3. La app usará datos mock para testing

### Test Completo (Con Muse Físico)

1. Enciende tu banda Muse
2. Asegúrate de que esté cerca del iPad
3. Conecta el iPad al Mac vía USB
4. En Xcode, selecciona tu iPad como destino
5. Presiona **Cmd + R** para ejecutar
6. En la app:
   - Ve al tab "Entrenar"
   - Presiona "Buscar Dispositivos"
   - Deberías ver tu Muse en la lista
   - Conecta y prueba el entrenamiento

## 🔍 Troubleshooting

### Error: "Module 'Muse' not found"

**Solución**:
1. Verifica que `Muse.framework` esté en la carpeta del proyecto
2. Verifica que esté agregado en **"Frameworks, Libraries, and Embedded Content"**
3. Limpia build: **Product → Clean Build Folder** (Cmd + Shift + K)
4. Rebuild: **Cmd + B**

### Error: "dyld: Library not loaded"

**Solución**:
1. Verifica que `Muse.framework` esté en **"Embed & Sign"** (no "Do Not Embed")
2. Limpia Derived Data:
   - Xcode → Preferences → Locations
   - Click la flecha junto a "Derived Data"
   - Elimina la carpeta de tu proyecto
   - Rebuild

### Error: "Undefined symbols for architecture arm64"

**Solución**:
1. Verifica que `-ObjC` esté en **"Other Linker Flags"**
2. Verifica que el framework sea para iOS (no macOS o otro)

### App se cierra inmediatamente al abrir

**Solución**:
1. Verifica los permisos de Bluetooth en `Info.plist`
2. En el iPad: Settings → Privacy → Bluetooth
3. Asegúrate de que la app tenga permiso

### No encuentra dispositivos Muse

**Posibles causas**:
1. Muse no está encendido (presiona botón de encendido 5 segundos)
2. Muse está conectado a otro dispositivo (desconectar primero)
3. Bluetooth del iPad está apagado
4. Estás usando simulador (Bluetooth no funciona en simulador)

**Solución**:
1. Enciende Muse (LED azul debe parpadear)
2. Cierra otras apps que usen Bluetooth
3. Activa Bluetooth en iPad
4. Usa iPad físico, no simulador

## 📚 Documentación Adicional

### Archivos del SDK

Una vez descomprimido, puedes consultar:

1. **Documentation/** - Documentación completa del SDK
2. **MuseExamples/** - Ejemplos de código
3. **README.txt** - Instrucciones básicas

### Recursos Online

- [Muse Developer Site](https://sites.google.com/a/interaxon.ca/muse-developer-site/)
- [Muse SDK Documentation](https://sites.google.com/a/interaxon.ca/muse-developer-site/documentation)
- [Muse Forums](https://choosemuse.com/forums/)

## ✅ Checklist de Integración

- [ ] Descomprimir `libmuse_ios_8.0.5.tar.gz`
- [ ] Copiar `Muse.framework` a la carpeta del proyecto
- [ ] Agregar framework en Xcode
- [ ] Configurar "Embed & Sign"
- [ ] Agregar `-ObjC` a Other Linker Flags
- [ ] Verificar permisos Bluetooth en Info.plist
- [ ] Descomentar código del SDK en `MuseSDKAdapter.swift`
- [ ] Build exitoso (Cmd + B)
- [ ] Probar en iPad físico

## 🎯 Resultado Esperado

Después de seguir estos pasos:

1. ✅ La app compila sin errores
2. ✅ Puedes escanear dispositivos Muse
3. ✅ Puedes conectarte a Muse
4. ✅ Recibes datos EEG en tiempo real
5. ✅ Los datos se sincronizan con el backend
6. ✅ Todo funciona end-to-end

---

**Última actualización**: 2025-11-20  
**SDK Version**: libmuse_ios_8.0.5  
**Compatibilidad**: iOS/iPadOS 16.0+

Si tienes problemas, consulta la documentación en la carpeta `Documentation/` del SDK o contacta al soporte de Muse.


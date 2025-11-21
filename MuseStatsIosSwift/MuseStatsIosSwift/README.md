# NeuroiPad iOS App

Aplicación iPad para entrenamientos de neurofeedback con banda Muse. Construida con Swift, siguiendo arquitectura Clean + MVVM.

## 🎯 Características

- Conexión Bluetooth con banda Muse
- Entrenamiento de 5 minutos con visualización en tiempo real
- Gráficos de señales EEG
- Sincronización automática con backend
- Almacenamiento seguro de tokens (Keychain)

## 📋 Requisitos

- Xcode 15.0+
- iOS/iPadOS 16.0+
- Swift 5.9+
- CocoaPods o Swift Package Manager
- Banda Muse (Muse S, Muse 2, Muse 2016)
- Muse SDK (LibMuse)

## 🚀 Instalación

### 1. Clonar y Abrir Proyecto

```bash
cd ios-app
open NeuroiPad.xcodeproj
```

### 2. Configurar Muse SDK

#### Opción A: Descarga Manual

1. Descarga Muse SDK desde [Muse Developer Site](https://sites.google.com/a/interaxon.ca/muse-developer-site/)
2. Arrastra `Muse.framework` a tu proyecto Xcode
3. En **General** → **Frameworks, Libraries, and Embedded Content**:
   - Marca `Muse.framework` como **Embed & Sign**

#### Opción B: CocoaPods (si está disponible)

```ruby
# Podfile
platform :ios, '16.0'

target 'NeuroiPad' do
  use_frameworks!
  
  pod 'Muse', '~> 12.0'
  pod 'Alamofire', '~> 5.8'
  pod 'KeychainAccess', '~> 4.2'
end
```

```bash
pod install
open NeuroiPad.xcworkspace
```

### 3. Configurar Build Settings

En Xcode, ve a **Build Settings** → **Linking**:

- **Other Linker Flags**: Agrega `-ObjC`

### 4. Configurar Info.plist

Agrega las siguientes keys en `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>La app necesita acceso a Bluetooth para conectarse a la banda Muse y capturar datos EEG</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>La app usa Bluetooth para comunicarse con la banda Muse</string>
```

### 5. Configurar Backend URL

Edita `Infrastructure/Networking/Endpoints.swift`:

```swift
enum APIConfig {
    static let baseURL = "http://localhost:3000/v1" // Desarrollo
    // static let baseURL = "https://api.neuroipad.com/v1" // Producción
}
```

### 6. Configurar Signing & Capabilities

1. Selecciona el target **NeuroiPad**
2. Ve a **Signing & Capabilities**
3. Selecciona tu **Team**
4. Verifica que **Automatically manage signing** esté habilitado
5. Agrega capability: **Keychain Sharing**

## 🏗️ Arquitectura

### Clean Architecture + MVVM

```
┌─────────────────────────────────────┐
│      PRESENTATION LAYER             │
│   (Views + ViewModels)              │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│       DOMAIN LAYER                  │
│   (Use Cases + Models)              │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│        DATA LAYER                   │
│      (Repositories)                 │
└────────────┬────────────────────────┘
             │
┌────────────▼────────────────────────┐
│   INFRASTRUCTURE LAYER              │
│  (Muse SDK + Network + Security)    │
└─────────────────────────────────────┘
```

### Estructura de Carpetas

```
ios-app/
├── Presentation/
│   ├── Screens/
│   │   ├── ConnectMuse/
│   │   │   ├── ConnectMuseView.swift
│   │   │   └── ConnectMuseViewModel.swift
│   │   ├── Training/
│   │   │   ├── TrainingView.swift
│   │   │   └── TrainingViewModel.swift
│   │   └── History/
│   ├── Components/
│   │   ├── Charts/
│   │   │   └── RealTimeChartView.swift
│   │   └── Common/
│   └── Navigation/
├── Domain/
│   ├── Models/
│   │   ├── Session.swift
│   │   ├── Sample.swift
│   │   └── User.swift
│   ├── UseCases/
│   │   ├── StartTrainingSessionUseCase.swift
│   │   ├── SendSamplesUseCase.swift
│   │   └── FinishSessionUseCase.swift
│   └── RepositoryInterfaces/
├── Data/
│   └── Repositories/
│       ├── SessionRepository.swift
│       ├── MuseRepository.swift
│       └── AuthRepository.swift
├── Infrastructure/
│   ├── MuseSDK/
│   │   ├── MuseSDKAdapter.swift
│   │   └── MuseDataModels.swift
│   ├── Networking/
│   │   ├── APIClient.swift
│   │   ├── Endpoints.swift
│   │   └── NetworkModels.swift
│   └── Security/
│       ├── KeychainManager.swift
│       └── TokenManager.swift
└── Tests/
```

## 🔌 Integración con Muse SDK

### Flujo de Conexión

```swift
// 1. Crear adapter
let museAdapter = MuseSDKAdapter()

// 2. Escanear dispositivos
museAdapter.startScanning()

// 3. Conectar
museAdapter.onMuseDiscovered = { muse in
    museAdapter.connect(to: muse)
}

// 4. Recibir datos
museAdapter.onDataPacket = { packet in
    print("EEG channels: \(packet.channels)")
}

// 5. Iniciar streaming
museAdapter.startStreaming()
```

### Tipos de Datos Muse

- **EEG**: 4 canales (TP9, AF7, AF8, TP10)
- **Acelerómetro**: 3 ejes (X, Y, Z)
- **PPG** (Pulse): Frecuencia cardíaca
- **Gyroscope**: 3 ejes (X, Y, Z)

## 🎨 UI/UX

### Pantallas Principales

#### 1. Conexión Muse
- Escaneo de dispositivos Bluetooth
- Lista de Muse disponibles
- Indicador de intensidad de señal
- Botón de conectar

#### 2. Entrenamiento (5 minutos)
- Contador regresivo: 5:00 → 0:00
- Gráfico en tiempo real de señal EEG
- Indicador de calidad de señal
- Indicador de conexión Bluetooth
- Botón "Stop" de emergencia

#### 3. Historial
- Lista de sesiones pasadas
- Métricas por sesión
- Gráficos de progreso

### SwiftUI vs UIKit

Este proyecto usa **SwiftUI** para todas las vistas. Si prefieres UIKit, la arquitectura es compatible.

## 🔐 Seguridad

### Keychain Storage

```swift
// Guardar token
try KeychainManager.shared.save(token: accessToken, for: .accessToken)

// Leer token
let token = try KeychainManager.shared.get(.accessToken)

// Eliminar token
try KeychainManager.shared.delete(.accessToken)
```

### HTTPS Only

Configurado en `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
</dict>
```

Para desarrollo local con HTTP, agregar excepción:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## 🧪 Testing

### Unit Tests

```bash
# Ejecutar tests desde Xcode
Cmd + U

# O desde terminal
xcodebuild test -scheme NeuroiPad -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
```

### Escribir Tests

```swift
import XCTest
@testable import NeuroiPad

class StartTrainingSessionUseCaseTests: XCTestCase {
    var sut: StartTrainingSessionUseCase!
    var mockSessionRepo: MockSessionRepository!
    var mockMuseRepo: MockMuseRepository!
    
    override func setUp() {
        super.setUp()
        mockSessionRepo = MockSessionRepository()
        mockMuseRepo = MockMuseRepository()
        sut = StartTrainingSessionUseCase(
            sessionRepo: mockSessionRepo,
            museRepo: mockMuseRepo
        )
    }
    
    func testStartSession_Success() async throws {
        // Given
        mockSessionRepo.createSessionResult = "session_123"
        
        // When
        try await sut.execute()
        
        // Then
        XCTAssertEqual(mockSessionRepo.createSessionCallCount, 1)
        XCTAssertTrue(mockMuseRepo.startStreamingCalled)
    }
}
```

### UI Tests

```swift
class TrainingFlowUITests: XCTestCase {
    func testCompleteTrainingSession() {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to training
        app.buttons["Start Training"].tap()
        
        // Verify countdown
        let countdown = app.staticTexts["5:00"]
        XCTAssertTrue(countdown.waitForExistence(timeout: 2))
        
        // Verify chart
        XCTAssertTrue(app.otherElements["EEG Chart"].exists)
    }
}
```

## 📊 Visualización de Datos

### Gráfico en Tiempo Real

Usa **Charts** (framework nativo de Swift):

```swift
import Charts

struct RealTimeChartView: View {
    @State private var dataPoints: [DataPoint] = []
    
    var body: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("Time", point.time),
                y: .value("EEG", point.value)
            )
        }
        .chartYScale(domain: -1...1)
        .chartXAxis(.hidden)
    }
}
```

## 🚀 Build & Run

### Desarrollo

1. Conecta un iPad físico (Bluetooth no funciona en simulador)
2. Selecciona el dispositivo en Xcode
3. Presiona **Cmd + R** o botón **Play**

### Producción

1. Cambiar Build Configuration a **Release**
2. Archive: **Product** → **Archive**
3. Distribuir vía **App Store Connect** o **Ad Hoc**

## 📱 Dispositivos Compatibles

- iPad Pro (todos los modelos)
- iPad Air (3ra gen+)
- iPad (8va gen+)
- iPad mini (5ta gen+)

**Nota**: Se recomienda iPad Pro 12.9" para mejor experiencia.

## 🐛 Debugging

### Logs de Muse SDK

```swift
// Habilitar logs en MuseSDKAdapter
MuseSDKAdapter.logLevel = .debug
```

### Breakpoints Condicionales

```swift
// En Xcode, agregar breakpoint con condición:
// packet.quality < 0.5
```

### Network Debugging

```bash
# Proxy con Charles o Proxyman
# Configurar proxy en iPad Settings → WiFi → HTTP Proxy
```

## 🔧 Troubleshooting

### Problema: No se encuentra Muse.framework

**Solución**: 
1. Verifica que el framework esté en **Frameworks, Libraries, and Embedded Content**
2. Marca como **Embed & Sign**

### Problema: Error de firma de código

**Solución**:
1. Verifica que **Automatically manage signing** esté habilitado
2. Selecciona un Team válido

### Problema: Bluetooth no funciona

**Solución**:
1. Verifica permisos en `Info.plist`
2. Usa dispositivo físico (no simulador)
3. Verifica que Bluetooth esté encendido en iPad

### Problema: Cannot connect to backend

**Solución**:
1. Verifica que el backend esté corriendo
2. Verifica la URL en `Endpoints.swift`
3. Para desarrollo local, agrega excepción en `Info.plist`

## 📚 Recursos

### Documentación Oficial
- [Muse SDK Documentation](https://sites.google.com/a/interaxon.ca/muse-developer-site/)
- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Combine Framework](https://developer.apple.com/documentation/combine)

### Librerías Recomendadas
- **Alamofire**: Networking (alternativa a URLSession)
- **KeychainAccess**: Manejo simplificado de Keychain
- **SwiftLint**: Linting de código Swift

## 🤝 Contribuir

1. Seguir guía de estilo Swift
2. Usar SwiftLint
3. Escribir tests para nuevas features
4. Documentar funciones públicas con comentarios

```swift
/// Inicia una sesión de entrenamiento de 5 minutos
/// - Parameter userId: ID del usuario que inicia la sesión
/// - Returns: ID de la sesión creada
/// - Throws: `TrainingError` si no se puede crear la sesión
func startTrainingSession(userId: String) async throws -> String {
    // Implementation
}
```

## 📝 Licencia

[Por definir]

---

**Versión**: 1.0.0  
**Última actualización**: 2025-11-20  
**Plataforma**: iOS/iPadOS 16.0+


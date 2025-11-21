import SwiftUI

/// Vista principal de autenticación (Login/Registro)
/// Permite al usuario iniciar sesión o crear una cuenta nueva
struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo con gradiente
                LinearGradient(
                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo y título
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text("NeuroiPad")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Entrenamiento de Neurofeedback")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 60)
                        
                        // Formulario de login/registro
                        VStack(spacing: 20) {
                            if showingRegister {
                                registerForm
                            } else {
                                loginForm
                            }
                        }
                        .padding(32)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(radius: 20)
                        .padding(.horizontal, 40)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    // MARK: - Login Form
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            Text("Iniciar Sesión")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                TextField("email@ejemplo.com", text: $viewModel.email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                SecureField("••••••••", text: $viewModel.password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.password)
            }
            
            // Login button
            Button(action: {
                Task {
                    await viewModel.login(coordinator: coordinator)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Iniciar Sesión")
                        .font(.headline)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || !viewModel.isLoginValid)
            
            // Toggle to register
            Button(action: {
                withAnimation {
                    showingRegister = true
                    viewModel.clearForm()
                }
            }) {
                Text("¿No tienes cuenta? **Regístrate**")
                    .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Register Form
    
    private var registerForm: some View {
        VStack(spacing: 20) {
            Text("Crear Cuenta")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Nombre")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                TextField("Tu nombre", text: $viewModel.name)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.name)
            }
            
            // Email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                TextField("email@ejemplo.com", text: $viewModel.email)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            // Password
            VStack(alignment: .leading, spacing: 8) {
                Text("Contraseña")
                    .font(.subheadline.bold())
                    .foregroundColor(.secondary)
                
                SecureField("Mínimo 8 caracteres", text: $viewModel.password)
                    .textFieldStyle(CustomTextFieldStyle())
                    .textContentType(.newPassword)
            }
            
            // Register button
            Button(action: {
                Task {
                    await viewModel.register(coordinator: coordinator)
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Crear Cuenta")
                        .font(.headline)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(viewModel.isLoading || !viewModel.isRegisterValid)
            
            // Toggle to login
            Button(action: {
                withAnimation {
                    showingRegister = false
                    viewModel.clearForm()
                }
            }) {
                Text("¿Ya tienes cuenta? **Inicia sesión**")
                    .font(.subheadline)
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Custom Styles

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                configuration.isPressed
                    ? Color.blue.opacity(0.8)
                    : Color.blue
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Preview

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AppCoordinator())
    }
}


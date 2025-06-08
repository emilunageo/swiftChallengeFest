import SwiftUI

// MARK: - Loading Animation Views
struct AppleLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 3.0
    
    var body: some View {
        VStack(spacing: 16) {
            Image("manzana-real")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)
                .foregroundColor(Color.warmRed)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(scale)
                .onAppear {
                    withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                }
            
            Text("Loading messages...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.warmRed)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}


// MARK: - Message Model
struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isFromCurrentUser: Bool
    let timestamp: Date
    let reaction: String?
}

// NO necesitamos la clase MessageService compleja
// Simplificamos para que funcione sin API

// MARK: - Message Bubble View
struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundColor(.white)
                        .background(
                            LinearGradient(
                                colors: [Color.warmRed, Color.warmRed, Color.warmRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: Color.warmRed.opacity(0.5), radius: 5, x: 0, y: 3)
                    
                    if let reaction = message.reaction {
                        Text(reaction)
                            .font(.title2)
                            .padding(.trailing, 8)
                            .shadow(color: Color.black.opacity(0.1), radius: 1)
                    }
                }
                .padding(.leading, 60) // Añade más espacio a la izquierda para mensajes propios
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.spring(), value: message.id)
            } else {
                HStack(alignment: .bottom, spacing: 6) {
                    // Avatar
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.lightGray.opacity(0.8), Color.lightGray.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.black.opacity(0.05), radius: 2)
                    
                    VStack(alignment: .leading) {
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .foregroundColor(.black.opacity(0.8))
                            .background(
                                LinearGradient(
                                    colors: [Color.white, Color.lightGray.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        
                        if let reaction = message.reaction {
                            Text(reaction)
                                .font(.title2)
                                .padding(.leading, 8)
                                .shadow(color: Color.black.opacity(0.1), radius: 1)
                        }
                    }
                }
                .padding(.trailing, 60) // Añade más espacio a la derecha para mensajes de otros
                .transition(.move(edge: .leading).combined(with: .opacity))
                .animation(.spring(), value: message.id)
                
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}

// MARK: - Input Bar View
struct MessageInputBar: View {
    @Binding var messageText: String
    var onSend: () -> Void
    @State private var isTextFieldFocused: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            
            TextField("Write a message...", text: $messageText)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [Color.lightGray.opacity(0.8), Color.lightGray.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .font(.system(size: 16))
                .animation(.easeOut(duration: 0.2), value: messageText)
            
            if !messageText.isEmpty {
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.warmRed, Color.warmRed],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.warmRed.opacity(0.3), radius: 5, x: 0, y: 3)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(), value: messageText.isEmpty)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: -2)
    }
}

// MARK: - Header View
import SwiftUI

struct ChatHeaderView: View {
    var body: some View {

        Text("Forum")

        HStack {
            Spacer()
            
            VStack {
                Text("Chat with your Doctor")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Botón de llamada
            if let phoneURL = URL(string: "tel://6673909470") {
                Link(destination: phoneURL) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(Color.warmRed)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                .padding(.trailing, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.white, Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

    }
}

// MARK: - Main Chat View
struct ChatView: View {
    @State private var messages: [Message] = [
        Message(content: "Hello! I've been experimenting headaches all week, is it related to my glucose level?", isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3600), reaction: nil),
        Message(content: "Yes, you should eat food with more fiber first, to reduce de absorbed glucose.", isFromCurrentUser: false, timestamp: Date().addingTimeInterval(-3500), reaction: nil),
        Message(content: "Really!", isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3400), reaction: nil),
        Message(content: "I have celery in my fridge right now", isFromCurrentUser: true, timestamp: Date().addingTimeInterval(-3300), reaction: nil)
    ]
    @State private var messageText: String = ""
    @State private var isLoading = true
    @State private var scrollToBottom = false
    @State private var animateBackground = false
    
    var body: some View {
        ZStack(alignment: .top) {
            // Fondo con gradiente
            LinearGradient(
                colors: [Color.lightGray.opacity(0.4), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            .opacity(animateBackground ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 1.0), value: animateBackground)
            .onAppear {
                animateBackground = true
                // Simular carga completada después de 1.5 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring()) {
                        self.isLoading = false
                    }
                }
            }
            
            VStack(spacing: 0) {
                // Header
                ChatHeaderView()
                
                // Messages
                ZStack {
                    ScrollViewReader { scrollView in
                        ScrollView {
                            LazyVStack {
                                if !isLoading {
                                    ForEach(messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                    .animation(.easeOut, value: messages.count)
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onAppear {
                            if let lastMessage = messages.last {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.white.opacity(0.3))
                    )
                    
                    if isLoading {
                        AppleLoadingView()
                    }
                }
                
                // Input bar
                MessageInputBar(messageText: $messageText, onSend: sendMessage)
                    .padding(.bottom, 70) // Añadir espacio en la parte inferior para el TabBar
            }
            .background(Color.clear)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let text = messageText
        messageText = ""
        
        // Feedback haptico
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Agregar mensaje directamente sin llamada API
        let newMessage = Message(
            content: text,
            isFromCurrentUser: true,
            timestamp: Date(),
            reaction: nil
        )
        
        withAnimation(.spring()) {
            self.messages.append(newMessage)
        }
        
        // Simular una respuesta automática después de enviar un mensaje
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let responseMessage = Message(
                //aqui hardcodear mañana
                content: "You should cook some carrots with it!",
                isFromCurrentUser: false,
                timestamp: Date(),
                reaction: nil
            )
            withAnimation(.spring()) {
                self.messages.append(responseMessage)
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatView()
        }
    }
}

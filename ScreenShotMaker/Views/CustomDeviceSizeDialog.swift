import SwiftUI

struct CustomDeviceSizeDialog: View {
  @Bindable var projectState: ProjectState
  @Environment(\.dismiss) private var dismiss
  
  @State private var name: String = ""
  @State private var width: String = ""
  @State private var height: String = ""
  @State private var showError: Bool = false
  @State private var errorMessage: String = ""
  
  private var isValid: Bool {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
    guard let w = Int(width), w > 0, w <= 10000 else { return false }
    guard let h = Int(height), h > 0, h <= 10000 else { return false }
    return true
  }
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Add Custom Size")
        .font(.headline)
      
      VStack(alignment: .leading, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Name")
            .font(.caption)
            .foregroundColor(.secondary)
          TextField("e.g., Instagram Story", text: $name)
            .textFieldStyle(.roundedBorder)
        }
        
        HStack(spacing: 8) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Width (px)")
              .font(.caption)
              .foregroundColor(.secondary)
            TextField("1080", text: $width)
              .textFieldStyle(.roundedBorder)
            #if os(iOS)
              .keyboardType(.numberPad)
            #endif
          }
          
          Text("×")
            .padding(.top, 16)
          
          VStack(alignment: .leading, spacing: 4) {
            Text("Height (px)")
              .font(.caption)
              .foregroundColor(.secondary)
            TextField("1920", text: $height)
              .textFieldStyle(.roundedBorder)
            #if os(iOS)
              .keyboardType(.numberPad)
            #endif
          }
        }
        
        Text("Please specify between 1-10000px")
          .font(.caption2)
          .foregroundColor(.secondary)
      }
      
      if showError {
        Text(errorMessage)
          .font(.caption)
          .foregroundColor(.red)
          .padding(.horizontal)
      }
      
      HStack {
        Button("Cancel") {
          dismiss()
        }
        #if os(macOS)
        .keyboardShortcut(.cancelAction)
        #endif
        
        Spacer()
        
        Button("Done") {
          addCustomDevice()
        }
        .buttonStyle(.borderedProminent)
        .disabled(!isValid)
        #if os(macOS)
        .keyboardShortcut(.defaultAction)
        #endif
      }
    }
    .padding()
    .frame(width: 400)
  }
  
  private func addCustomDevice() {
    guard let w = Int(width), let h = Int(height) else {
      showError = true
      errorMessage = String(localized: "Please enter width and height as numbers")
      return
    }
    
    guard w > 0 && w <= 10000 && h > 0 && h <= 10000 else {
      showError = true
      errorMessage = String(localized: "Please specify size between 1-10000px")
      return
    }
    
    let trimmedName = name.trimmingCharacters(in: .whitespaces)
    guard !trimmedName.isEmpty else {
      showError = true
      errorMessage = String(localized: "Please enter a name")
      return
    }
    
    projectState.addCustomDevice(name: trimmedName, width: w, height: h)
    dismiss()
  }
}

#Preview {
  @Previewable @State var projectState = ProjectState()
  CustomDeviceSizeDialog(projectState: projectState)
}

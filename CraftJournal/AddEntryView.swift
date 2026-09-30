import SwiftUI
import CoreData
import UIKit
import PhotosUI

struct AddEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    var entryToEdit: CraftEntry? = nil

    @State private var title: String
    @State private var craftType: String
    @State private var notes: String
    @State private var artisanName: String
    @State private var image: UIImage?
    @State private var showingCamera = false
    @State private var photoItem: PhotosPickerItem?

    init(entryToEdit: CraftEntry? = nil) {
        self.entryToEdit = entryToEdit
        _title = State(initialValue: entryToEdit?.title ?? "")
        _craftType = State(initialValue: entryToEdit?.craftType ?? crafts[0])
        _notes = State(initialValue: entryToEdit?.notes ?? "")
        _artisanName = State(initialValue: entryToEdit?.artisanName ?? "")
        if let data = entryToEdit?.photo, let ui = UIImage(data: data) {
            _image = State(initialValue: ui)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                TextField("Artisan", text: $artisanName)
                Picker("Craft", selection: $craftType) {
                    ForEach(crafts, id: \.self) { craft in
                        Text(craft)
                    }
                }
                TextField("Notes", text: $notes, axis: .vertical)
                Section("Photo") {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                    }
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    PhotosPicker("Choose from Library", selection: $photoItem, matching: .images)
                }
            }
            .navigationTitle(entryToEdit == nil ? "New Entry" : "Edit Entry")
            .onChange(of: photoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        image = uiImage
                    }
                }
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView(image: $image)
                    .ignoresSafeArea()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                        .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveEntry() {
        let entry: CraftEntry
        if let existing = entryToEdit {
            entry = existing
        } else {
            entry = CraftEntry(context: viewContext)
            entry.id = UUID()
        }
        entry.title = title
        entry.craftType = craftType
        entry.date = entry.date ?? Date()
        entry.notes = notes
        entry.artisanName = artisanName
        entry.photo = image?.jpegData(compressionQuality: 0.7)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Could not save: \(error)")
        }
    }
}

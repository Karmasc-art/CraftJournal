import SwiftUI
import UIKit
import CoreData

struct EntryDetailView: View {
    @ObservedObject var entry: CraftEntry
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if let data = entry.photo, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                HStack {
                    Text(entry.title ?? "Untitled")
                        .font(.largeTitle)
                        .bold()
                    if entry.isFavourite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.title2)
                    }
                }
                Text(entry.craftType ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                if let artisan = entry.artisanName, !artisan.isEmpty {
                    Text("Artisan: \(artisan)")
                        .font(.body)
                }
                if let date = entry.date {
                    Text(date, style: .date)
                }
                if let notes = entry.notes, !notes.isEmpty {
                    Text("Notes")
                        .font(.headline)
                        .padding(.top, 8)
                    Text(notes)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    entry.isFavourite.toggle()
                    try? entry.managedObjectContext?.save()
                } label: {
                    Image(systemName: entry.isFavourite ? "star.fill" : "star")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            if let context = entry.managedObjectContext {
                AddEntryView(entryToEdit: entry)
                    .environment(\.managedObjectContext, context)
            }
        }
    }
}

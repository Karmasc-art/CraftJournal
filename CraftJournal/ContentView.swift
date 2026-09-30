import SwiftUI
import UIKit
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CraftEntry.date, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<CraftEntry>

    @State private var showingAddEntry = false
    @State private var selectedCraft: String? = nil
    @State private var searchText = ""
    @State private var showFavouritesOnly = false

    var body: some View {
        NavigationView {
            VStack {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Entries Yet",
                        systemImage: "book.closed",
                        description: Text("Tap + to add your first craft entry.")
                    )
                } else {
                    Text("\(entries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    List {
                        ForEach(entries) { entry in
                            NavigationLink {
                                EntryDetailView(entry: entry)
                            } label: {
                                EntryRow(entry: entry)
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("Craft Journal")
            .searchable(text: $searchText, prompt: "Search entries")
            .onChange(of: searchText) { _, _ in applyPredicate() }
            .onChange(of: selectedCraft) { _, _ in applyPredicate() }
            .onChange(of: showFavouritesOnly) { _, _ in applyPredicate() }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("All Crafts") { selectedCraft = nil }
                        ForEach(crafts, id: \.self) { craft in
                            Button(craft) { selectedCraft = craft }
                        }
                        Divider()
                        Button(showFavouritesOnly ? "Show All" : "Favourites Only") {
                            showFavouritesOnly.toggle()
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddEntryView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }

    private func applyPredicate() {
        var predicates: [NSPredicate] = []
        if let selectedCraft {
            predicates.append(NSPredicate(format: "craftType == %@", selectedCraft))
        }
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[cd] %@", searchText))
        }
        if showFavouritesOnly {
            predicates.append(NSPredicate(format: "isFavourite == YES"))
        }
        entries.nsPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    private func deleteEntries(offsets: IndexSet) {
        offsets.map { entries[$0] }.forEach(viewContext.delete)
        do {
            try viewContext.save()
        } catch {
            print("Could not delete: \(error)")
        }
    }
}

struct EntryRow: View {
    @ObservedObject var entry: CraftEntry

    var body: some View {
        HStack {
            if let data = entry.photo, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "photo")
                    .frame(width: 60, height: 60)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading) {
                HStack {
                    Text(entry.title ?? "Untitled")
                        .font(.headline)
                    if entry.isFavourite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                }
                Text(entry.craftType ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let artisan = entry.artisanName, !artisan.isEmpty {
                    Text(artisan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext,
                      PersistenceController.preview.container.viewContext)
}

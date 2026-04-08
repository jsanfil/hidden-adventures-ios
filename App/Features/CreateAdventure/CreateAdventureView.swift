import SwiftUI

struct CreateAdventureView: View {
  private enum Layout {
    static let horizontalPadding: CGFloat = 20
    static let bottomPadding: CGFloat = 112
  }

  let initialVariant: CreateAdventureFixtureVariant
  let onClose: () -> Void

  @State private var step: CreateAdventureStep
  @State private var selectedPhotoNames: [String]
  @State private var activePhotoIndex: Int
  @State private var title: String
  @State private var description: String
  @State private var resolvedLocation: CreateAdventureResolvedLocation?
  @State private var locationLabel: String
  @State private var selectedCategory: Category?
  @State private var visibility: Visibility
  @State private var isLocationPickerPresented: Bool
  @State private var locationPickerMode: CreateAdventureLocationPickerMode
  @State private var locationSearchQuery: String
  @State private var currentLocationState: CreateAdventureCurrentLocationState
  @State private var locationSearchResults: [CreateAdventureSearchResult]
  @State private var pinLocation: CreateAdventureResolvedLocation

  init(
    initialVariant: CreateAdventureFixtureVariant = .photos,
    onClose: @escaping () -> Void
  ) {
    let model = MockFixtures.createAdventureScreenModel(for: initialVariant)
    self.initialVariant = initialVariant
    self.onClose = onClose
    _step = State(initialValue: model.step)
    _selectedPhotoNames = State(initialValue: model.selectedPhotoNames)
    _activePhotoIndex = State(initialValue: model.activePhotoIndex)
    _title = State(initialValue: model.title)
    _description = State(initialValue: model.description)
    _resolvedLocation = State(initialValue: model.resolvedLocation)
    _locationLabel = State(initialValue: model.locationLabel)
    _selectedCategory = State(initialValue: model.selectedCategory)
    _visibility = State(initialValue: model.visibility)
    _isLocationPickerPresented = State(initialValue: model.isLocationPickerPresented)
    _locationPickerMode = State(initialValue: model.locationPickerMode)
    _locationSearchQuery = State(initialValue: model.locationSearchQuery)
    _currentLocationState = State(initialValue: model.currentLocationState)
    _locationSearchResults = State(initialValue: model.locationSearchResults)
    _pinLocation = State(initialValue: model.pinLocation)
  }

  private var availablePhotoNames: [String] {
    MockFixtures.createAdventureAvailablePhotos
  }

  private var canContinueFromPhotos: Bool {
    selectedPhotoNames.isEmpty == false
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(isLocationPickerPresented ? 0.14 : 0.08)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        HAStatusBarSpacer()
        header
        Divider()

        if step == .photos {
          photoSelectionStep
        } else {
          detailsStep
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .background(HATheme.Colors.background)
      .clipShape(
        UnevenRoundedRectangle(
          topLeadingRadius: 26,
          topTrailingRadius: 26
        )
      )
      .overlay(alignment: .bottom) {
        if isLocationPickerPresented {
          Color.black.opacity(0.24)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
              isLocationPickerPresented = false
            }
            .accessibilityIdentifier("create.locationSheet.backdrop")
        }
      }

      if isLocationPickerPresented {
        locationPickerSheet
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.22), value: isLocationPickerPresented)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var header: some View {
    HStack(spacing: 12) {
      if step == .photos {
        Button(action: onClose) {
          Image(systemName: "xmark")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("create.close")
      } else {
        Button {
          step = .photos
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("create.back")
      }

      Text(step == .photos ? "New Adventure" : "Adventure Details")
        .font(.system(size: 19, weight: .semibold))
        .foregroundStyle(HATheme.Colors.foreground)
        .accessibilityIdentifier("create.header.title")

      Spacer()

      if step == .photos {
        Button {
          guard canContinueFromPhotos else { return }
          step = .details
        } label: {
          HStack(spacing: 4) {
            Text("Next")
            Image(systemName: "chevron.right")
              .font(.system(size: 12, weight: .semibold))
          }
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(canContinueFromPhotos ? HATheme.Colors.primary : HATheme.Colors.mutedForeground)
        }
        .buttonStyle(.plain)
        .disabled(canContinueFromPhotos == false)
        .accessibilityIdentifier("create.next")
      } else {
        Button {
          onClose()
        } label: {
          Text("Post")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(HATheme.Colors.primary)
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("create.post")
      }
    }
    .padding(.horizontal, Layout.horizontalPadding)
    .padding(.bottom, 16)
  }

  private var photoSelectionStep: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 0) {
        if let previewPhoto = currentPreviewPhotoName {
          ZStack(alignment: .bottom) {
            Image(previewPhoto)
              .resizable()
              .scaledToFill()
              .frame(maxWidth: .infinity)
              .aspectRatio(1, contentMode: .fit)
              .clipped()
              .accessibilityIdentifier("create.photoPreview")

            if selectedPhotoNames.count > 1 {
              HStack {
                Spacer()

                Text("\(activePhotoIndex + 1)/\(selectedPhotoNames.count)")
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 10)
                  .frame(height: 26)
                  .background(Color.black.opacity(0.58))
                  .clipShape(Capsule(style: .continuous))
                  .padding(.trailing, 16)
                  .padding(.bottom, 14)
                  .accessibilityIdentifier("create.photoCount")
              }

              HStack(spacing: 6) {
                ForEach(Array(selectedPhotoNames.enumerated()), id: \.offset) { index, _ in
                  Button {
                    activePhotoIndex = index
                  } label: {
                    Circle()
                      .fill(index == activePhotoIndex ? Color.white : Color.white.opacity(0.52))
                      .frame(width: index == activePhotoIndex ? 8 : 6, height: index == activePhotoIndex ? 8 : 6)
                  }
                  .buttonStyle(.plain)
                  .accessibilityIdentifier("create.photoDot.\(index)")
                }
              }
              .padding(.bottom, 16)
            }
          }
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("SELECT PHOTOS (\(selectedPhotoNames.count) SELECTED)")
            .font(.system(size: 12, weight: .semibold))
            .tracking(1.1)
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .padding(.top, 16)

          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 3), spacing: 1) {
            addPhotoCell

            ForEach(availablePhotoNames, id: \.self) { photoName in
              photoGridCell(photoName)
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, Layout.bottomPadding)
      }
    }
    .accessibilityIdentifier("create.photos.scroll")
  }

  private var currentPreviewPhotoName: String? {
    guard selectedPhotoNames.isEmpty == false else { return nil }
    let index = min(max(activePhotoIndex, 0), selectedPhotoNames.count - 1)
    return selectedPhotoNames[index]
  }

  private var addPhotoCell: some View {
    Button(action: {}) {
      VStack(spacing: 6) {
        Image(systemName: "plus")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
        Text("Add Photo")
          .font(.system(size: 11, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)
      }
      .frame(maxWidth: .infinity)
      .aspectRatio(1, contentMode: .fit)
      .background(HATheme.Colors.secondary)
      .overlay {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(HATheme.Colors.border, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("create.photoGrid.add")
  }

  private func photoGridCell(_ photoName: String) -> some View {
    let isSelected = selectedPhotoNames.contains(photoName)
    let selectionIndex = selectedPhotoNames.firstIndex(of: photoName)

    return Button {
      togglePhoto(photoName)
    } label: {
      ZStack(alignment: .topTrailing) {
        Image(photoName)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .clipped()

        if isSelected {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(HATheme.Colors.primary.opacity(0.20))
        }

        ZStack {
          Circle()
            .fill(isSelected ? HATheme.Colors.primary : Color.black.opacity(0.28))
          Circle()
            .stroke(isSelected ? HATheme.Colors.primary : Color.white.opacity(0.84), lineWidth: 2)

          if let selectionIndex {
            Text("\(selectionIndex + 1)")
              .font(.system(size: 10, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        .frame(width: 22, height: 22)
        .padding(8)
      }
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("create.photoGrid.\(photoName)")
  }

  private var detailsStep: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 18) {
        photoStrip

        labeledField("TITLE") {
          TextField("Give this spot a name...", text: $title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(HATheme.Colors.foreground)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(HATheme.Colors.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier("create.title")
        }

        labeledField("DESCRIPTION") {
          TextField(
            "What makes this place special? Share tips, directions, best time to visit...",
            text: $description,
            axis: .vertical
          )
          .lineLimit(3...5)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .textFieldStyle(.plain)
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
          .background(HATheme.Colors.secondary)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
          .accessibilityIdentifier("create.description")
        }

        labeledField("LOCATION") {
          VStack(alignment: .leading, spacing: 10) {
            coordinatesButton

            ZStack(alignment: .trailing) {
              TextField("Location label (e.g. Columbia River Gorge, OR)", text: $locationLabel)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(HATheme.Colors.foreground)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(HATheme.Colors.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityIdentifier("create.location.label")

              if locationLabel.isEmpty == false {
                Button {
                  locationLabel = ""
                } label: {
                  clearCircleIcon
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                .accessibilityIdentifier("create.location.clearLabel")
              }
            }

            Text("This label appears below the title in the feed. Auto-filled from your pin, or write your own.")
              .font(.system(size: 12, weight: .medium))
              .foregroundStyle(HATheme.Colors.mutedForeground)
              .padding(.horizontal, 2)
              .accessibilityIdentifier("create.location.helper")
          }
        }

        labeledField("CATEGORY") {
          LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Category.allCases) { category in
              categoryButton(category)
            }
          }
        }

        labeledField("WHO CAN SEE THIS?") {
          VStack(spacing: 10) {
            ForEach(visibilityOptions, id: \.rawValue) { option in
              visibilityButton(option)
            }
          }
        }
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.top, 14)
      .padding(.bottom, Layout.bottomPadding)
    }
    .accessibilityIdentifier("create.details.scroll")
  }

  private var photoStrip: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(Array(selectedPhotoNames.enumerated()), id: \.offset) { index, photoName in
          Image(photoName)
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(index == activePhotoIndex ? HATheme.Colors.primary : Color.clear, lineWidth: 2)
            }
            .accessibilityIdentifier("create.photoStrip.\(index)")
        }
      }
    }
  }

  private var visibilityOptions: [Visibility] {
    [.public, .connections, .private]
  }

  private var coordinatesButton: some View {
    ZStack(alignment: .trailing) {
      Button {
        isLocationPickerPresented = true
        if initialVariant == .locationSearchEmpty || initialVariant == .locationSearchResults || initialVariant == .locationPin {
          locationPickerMode = MockFixtures.createAdventureScreenModel(for: initialVariant).locationPickerMode
        } else {
          locationPickerMode = .options
        }
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "mappin")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(resolvedLocation == nil ? HATheme.Colors.mutedForeground : HATheme.Colors.primary)

          Text(resolvedLocation.map(coordinateText(for:)) ?? "Set coordinates...")
            .font(.system(size: 16, weight: resolvedLocation == nil ? .regular : .medium))
            .foregroundStyle(resolvedLocation == nil ? HATheme.Colors.mutedForeground : HATheme.Colors.foreground)
            .frame(maxWidth: .infinity, alignment: .leading)

          if resolvedLocation == nil {
            Image(systemName: "chevron.right")
              .font(.system(size: 14, weight: .semibold))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          } else {
            Color.clear.frame(width: 20, height: 20)
          }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(HATheme.Colors.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("create.location.coordinatesButton")

      if resolvedLocation != nil {
        Button {
          resolvedLocation = nil
          locationLabel = ""
        } label: {
          clearCircleIcon
        }
        .buttonStyle(.plain)
        .padding(.trailing, 12)
        .accessibilityIdentifier("create.location.clearCoordinates")
      }
    }
  }

  private var clearCircleIcon: some View {
    Image(systemName: "xmark")
      .font(.system(size: 10, weight: .bold))
      .foregroundStyle(HATheme.Colors.foreground.opacity(0.75))
      .frame(width: 20, height: 20)
      .background(HATheme.Colors.muted)
      .clipShape(Circle())
  }

  private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .semibold))
        .tracking(1.0)
        .foregroundStyle(HATheme.Colors.mutedForeground)

      content()
    }
  }

  private func categoryButton(_ category: Category) -> some View {
    let isSelected = selectedCategory == category

    return Button {
      selectedCategory = isSelected ? nil : category
    } label: {
      HStack(spacing: 10) {
        Image(systemName: category.systemImage)
          .font(.system(size: 16, weight: .medium))
        Text(category.displayTitle)
          .font(.system(size: 16, weight: .semibold))
          .lineLimit(1)
      }
      .foregroundStyle(isSelected ? Color.white : HATheme.Colors.foreground)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 16)
      .frame(height: 48)
      .background(isSelected ? HATheme.Colors.primary : HATheme.Colors.secondary)
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(isSelected ? HATheme.Colors.primary : Color.clear, lineWidth: 1)
      }
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("create.category.\(category.rawValue)")
  }

  private func visibilityButton(_ option: Visibility) -> some View {
    let isSelected = visibility == option

    return Button {
      visibility = option
    } label: {
      HStack(spacing: 14) {
        ZStack {
          Circle()
            .fill(isSelected ? HATheme.Colors.primary : HATheme.Colors.muted)
            .frame(width: 32, height: 32)

          Image(systemName: visibilitySymbol(for: option))
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(isSelected ? Color.white : HATheme.Colors.mutedForeground)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(visibilityTitle(for: option))
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(isSelected ? HATheme.Colors.primary : HATheme.Colors.foreground)
          Text(visibilityDescription(for: option))
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
        }

        Spacer()

        ZStack {
          Circle()
            .stroke(isSelected ? HATheme.Colors.primary : HATheme.Colors.border, lineWidth: 2)
            .frame(width: 18, height: 18)
          if isSelected {
            Circle()
              .fill(HATheme.Colors.primary)
              .frame(width: 18, height: 18)
            Circle()
              .fill(.white)
              .frame(width: 7, height: 7)
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .background(isSelected ? HATheme.Colors.primary.opacity(0.10) : HATheme.Colors.secondary)
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(isSelected ? HATheme.Colors.primary : Color.clear, lineWidth: 1)
      }
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("create.visibility.\(option.rawValue)")
  }

  private func visibilityTitle(for visibility: Visibility) -> String {
    switch visibility {
    case .public:
      return "Public"
    case .connections:
      return "Connections"
    case .private:
      return "Private"
    }
  }

  private func visibilityDescription(for visibility: Visibility) -> String {
    switch visibility {
    case .public:
      return "Anyone can see this"
    case .connections:
      return "Only people you follow"
    case .private:
      return "Only you"
    }
  }

  private func visibilitySymbol(for visibility: Visibility) -> String {
    switch visibility {
    case .public:
      return "globe"
    case .connections:
      return "person.2"
    case .private:
      return "lock"
    }
  }

  private var locationPickerSheet: some View {
    VStack(spacing: 0) {
      Capsule(style: .continuous)
        .fill(HATheme.Colors.border)
        .frame(width: 40, height: 4)
        .padding(.top, 12)
        .padding(.bottom, 10)

      HStack {
        if locationPickerMode == .options {
          Color.clear.frame(width: 60, height: 24)
        } else {
          Button {
            locationPickerMode = .options
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "chevron.left")
              Text("Back")
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(HATheme.Colors.primary)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("create.locationSheet.back")
        }

        Spacer()

        Text(locationSheetTitle)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("create.locationSheet.title")

        Spacer()

        Button {
          isLocationPickerPresented = false
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(HATheme.Colors.foreground)
            .frame(width: 32, height: 32)
            .background(HATheme.Colors.secondary)
            .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("create.locationSheet.close")
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.bottom, 16)

      Divider()

      Group {
        switch locationPickerMode {
        case .options:
          locationOptions
        case .search:
          locationSearch
        case .pin:
          locationPin
        }
      }
      .padding(.horizontal, Layout.horizontalPadding)
      .padding(.top, 16)
      .padding(.bottom, 28)
    }
    .frame(maxWidth: .infinity)
    .background(HATheme.Colors.background)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
      )
    )
  }

  private var locationSheetTitle: String {
    switch locationPickerMode {
    case .options:
      return "Add Location"
    case .search:
      return "Search Places"
    case .pin:
      return "Drop a Pin"
    }
  }

  private var locationOptions: some View {
    VStack(spacing: 12) {
      locationOptionCard(
        id: "create.locationSheet.currentLocation",
        icon: locationCurrentLocationIcon,
        title: locationCurrentLocationTitle,
        subtitle: locationCurrentLocationSubtitle,
        trailing: locationCurrentLocationTrailing
      ) {
        switch currentLocationState {
        case .idle:
          currentLocationState = .loading
          Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            await MainActor.run {
              currentLocationState = .resolved(MockFixtures.createAdventureCurrentLocation)
            }
          }
        case .loading:
          break
        case let .resolved(location):
          applyLocation(location)
        }
      }

      locationOptionCard(
        id: "create.locationSheet.searchPlaces",
        icon: AnyView(optionIconCircle(symbol: "magnifyingglass")),
        title: "Search for a Place",
        subtitle: "Find by name, address, or landmark",
        trailing: AnyView(optionChevron)
      ) {
        locationPickerMode = .search
      }

      locationOptionCard(
        id: "create.locationSheet.dropPin",
        icon: AnyView(optionIconCircle(symbol: "map")),
        title: "Drop a Pin",
        subtitle: "Pick an exact spot on the map",
        trailing: AnyView(optionChevron)
      ) {
        locationPickerMode = .pin
      }
    }
  }

  private var locationSearch: some View {
    VStack(spacing: 16) {
      HStack(spacing: 10) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(HATheme.Colors.mutedForeground)

        TextField("Search parks, trails, landmarks...", text: $locationSearchQuery)
          .textFieldStyle(.plain)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(HATheme.Colors.foreground)
          .accessibilityIdentifier("create.locationSheet.searchField")

        if locationSearchQuery.isEmpty == false {
          Button {
            locationSearchQuery = ""
            locationSearchResults = []
          } label: {
            clearCircleIcon
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("create.locationSheet.clearSearch")
        }
      }
      .padding(.horizontal, 14)
      .frame(height: 46)
      .background(HATheme.Colors.secondary)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

      if locationSearchQuery.isEmpty {
        VStack(spacing: 14) {
          optionIconCircle(symbol: "magnifyingglass")
          Text("Start typing to search for a location")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .accessibilityIdentifier("create.locationSheet.searchEmpty")
      } else if locationSearchResults.isEmpty {
        VStack(spacing: 14) {
          optionIconCircle(symbol: "mappin")
          Text("No places found for \"\(locationSearchQuery)\"")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 44)
        .accessibilityIdentifier("create.locationSheet.noResults")
      } else {
        VStack(spacing: 0) {
          ForEach(locationSearchResults) { result in
            Button {
              applyLocation(
                CreateAdventureResolvedLocation(
                  name: result.name,
                  latitude: result.latitude,
                  longitude: result.longitude
                )
              )
            } label: {
              HStack(spacing: 12) {
                optionIconCircle(symbol: "mappin")

                VStack(alignment: .leading, spacing: 2) {
                  Text(result.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(HATheme.Colors.foreground)
                  Text(result.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(HATheme.Colors.mutedForeground)
                }

                Spacer()

                optionChevron
              }
              .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("create.locationSheet.result.\(result.id)")

            if result.id != locationSearchResults.last?.id {
              Divider()
            }
          }
        }
      }
    }
    .onChange(of: locationSearchQuery) { _, newValue in
      locationSearchResults = searchResults(for: newValue)
    }
  }

  private var locationPin: some View {
    VStack(spacing: 14) {
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(
          LinearGradient(
            colors: [HATheme.Colors.mapForest, HATheme.Colors.mapBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(height: 240)
        .overlay {
          VStack(spacing: 10) {
            Image(systemName: "mappin.circle.fill")
              .font(.system(size: 34, weight: .medium))
              .foregroundStyle(HATheme.Colors.primary)
            Text("Pin preview")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(HATheme.Colors.foreground)
            Text("Mock-first map state for UI parity")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }
        }
        .accessibilityIdentifier("create.locationSheet.pinMap")

      Text("Tap anywhere on the map to move the pin")
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(HATheme.Colors.mutedForeground)
        .frame(maxWidth: .infinity, alignment: .center)

      HStack(spacing: 12) {
        HStack(spacing: 12) {
          Image(systemName: "mappin")
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(HATheme.Colors.primary)

          VStack(alignment: .leading, spacing: 2) {
            Text(pinLocation.name)
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(HATheme.Colors.foreground)
            Text(coordinateText(for: pinLocation))
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(HATheme.Colors.mutedForeground)
          }
        }
        .accessibilityIdentifier("create.locationSheet.pinSummary")

        Spacer()

        Button {
          applyLocation(pinLocation)
        } label: {
          Text("Confirm")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(HATheme.Colors.primary)
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("create.locationSheet.confirmPin")
      }
      .padding(16)
      .background(HATheme.Colors.secondary)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
  }

  private var locationCurrentLocationIcon: AnyView {
    switch currentLocationState {
    case .idle:
      return AnyView(optionIconCircle(symbol: "location.north"))
    case .loading:
      return AnyView(
        Circle()
          .fill(HATheme.Colors.primary.opacity(0.12))
          .frame(width: 40, height: 40)
          .overlay {
            ProgressView()
              .tint(HATheme.Colors.primary)
          }
      )
    case .resolved:
      return AnyView(
        Circle()
          .fill(Color.green.opacity(0.12))
          .frame(width: 40, height: 40)
          .overlay {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(.green)
          }
      )
    }
  }

  private var locationCurrentLocationTitle: String {
    switch currentLocationState {
    case .idle:
      return "Use Current Location"
    case .loading:
      return "Finding your location..."
    case let .resolved(location):
      return location.name
    }
  }

  private var locationCurrentLocationSubtitle: String {
    switch currentLocationState {
    case .idle:
      return "Detect where you are now"
    case .loading:
      return "This will just take a moment"
    case let .resolved(location):
      return coordinateText(for: location)
    }
  }

  private var locationCurrentLocationTrailing: AnyView {
    switch currentLocationState {
    case .resolved:
      return AnyView(
        Text("Use")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 12)
          .frame(height: 30)
          .background(HATheme.Colors.primary)
          .clipShape(Capsule(style: .continuous))
      )
    default:
      return AnyView(optionChevron)
    }
  }

  private func locationOptionCard(
    id: String,
    icon: AnyView,
    title: String,
    subtitle: String,
    trailing: AnyView,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 14) {
        icon

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(HATheme.Colors.foreground)
            .multilineTextAlignment(.leading)
          Text(subtitle)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(HATheme.Colors.mutedForeground)
            .multilineTextAlignment(.leading)
        }

        Spacer()

        trailing
      }
      .padding(16)
      .background(HATheme.Colors.secondary)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier(id)
  }

  private func optionIconCircle(symbol: String) -> some View {
    Circle()
      .fill(HATheme.Colors.primary.opacity(0.12))
      .frame(width: 40, height: 40)
      .overlay {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(HATheme.Colors.primary)
      }
  }

  private var optionChevron: some View {
    Image(systemName: "chevron.right")
      .font(.system(size: 14, weight: .semibold))
      .foregroundStyle(HATheme.Colors.mutedForeground)
  }

  private func togglePhoto(_ photoName: String) {
    if let currentIndex = selectedPhotoNames.firstIndex(of: photoName) {
      selectedPhotoNames.remove(at: currentIndex)
      if selectedPhotoNames.isEmpty {
        activePhotoIndex = 0
      } else if activePhotoIndex >= selectedPhotoNames.count {
        activePhotoIndex = selectedPhotoNames.count - 1
      }
    } else {
      selectedPhotoNames.append(photoName)
      activePhotoIndex = selectedPhotoNames.count - 1
    }
  }

  private func applyLocation(_ location: CreateAdventureResolvedLocation) {
    resolvedLocation = location
    if locationLabel.isEmpty {
      locationLabel = location.name
    }
    isLocationPickerPresented = false
  }

  private func searchResults(for query: String) -> [CreateAdventureSearchResult] {
    guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      return []
    }

    return MockFixtures.createAdventureSearchResults.filter { result in
      result.name.localizedCaseInsensitiveContains(query)
        || result.subtitle.localizedCaseInsensitiveContains(query)
    }
  }

  private func coordinateText(for location: CreateAdventureResolvedLocation) -> String {
    "\(String(format: "%.4f", location.latitude)), \(String(format: "%.4f", location.longitude))"
  }
}

struct CreateAdventureView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CreateAdventureView(initialVariant: .photos, onClose: {})
      CreateAdventureView(initialVariant: .detailsLocation, onClose: {})
      CreateAdventureView(initialVariant: .locationOptions, onClose: {})
    }
  }
}

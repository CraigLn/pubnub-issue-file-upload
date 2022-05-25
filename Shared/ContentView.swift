//
//  ContentView.swift
//  pubnub-issue-file-upload
//
//  Created by Craig Lane on 4/28/22.
//

import SwiftUI

struct ContentView: View {
  
  @State var usWestDefault = 0.00
  @State var usWestDefaultProgress: Progress?
  
  @State var usEastDefault = 0.00
  @State var usEastDefaultProgress: Progress?
  
  @State var euCentralDefault = 0.00
  @State var euCentralDefaultProgress: Progress?
  
  @State var apacSouthDefault = 0.00
  @State var apacSouthDefaultProgress: Progress?
  
  @State var usWestBackground = 0.00
  @State var usWestBackgroundProgress: Progress?

  @State var usEastBackground = 0.00
  @State var usEastBackgroundProgress: Progress?
  
  @State var euCentralBackground = 0.00
  @State var euCentralBackgroundProgress: Progress?

  @State var apacSouthBackground = 0.00
  @State var apacSouthBackgroundProgress: Progress?
  
  @State var usePercentageDiff = false
  
  let network = FileNetwork()
  
  let imageData: Data? = {
    #if os(iOS)
    UIImage(named: "uploadFile")?.jpegData(compressionQuality: 0.98)
    #else
    guard let cgImage = NSImage(named: "uploadFile")?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
    return jpegData
    #endif
  }()
  
  var body: some View {
    VStack {
      HStack {
        VStack {
          Text("AWS Region").expandVertical()
          Text("USWest").expandVertical()
            .onTapGesture {
              uploadUSWestDefault {
                uploadUSWestBackground()
              }
            }
          Text("US East").expandVertical()
            .onTapGesture {
              uploadUSEastDefault() {
                uploadUSEastBackground()
              }
            }
          Text("EU Cen").expandVertical()
            .onTapGesture {
              uploadEUCentralDefault() {
                uploadEUCentralBackground()
              }
            }
          Text("APAC S").expandVertical()
            .onTapGesture {
              uploadApacSouthDefault() {
                uploadApacSouthBackground()
              }
            }
        }
        VStack {
          Text("Default Config").expandVertical()
            .onTapGesture {
              uploadAllDefault()
            }
          
          if let progress = usWestDefaultProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(usWestDefault/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadUSWestDefault()
              }
          }
          
          if let progress = usEastDefaultProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(usEastDefault/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadUSEastDefault()
              }
          }
          
          if let progress = euCentralDefaultProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(euCentralDefault/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadEUCentralDefault()
              }
          }
          
          if let progress = apacSouthDefaultProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(apacSouthDefault/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadApacSouthDefault()
              }
          }
        }
        VStack {
          Text("BG Config").expandVertical()
            .onTapGesture {
              uploadAllBackground()
            }
          
          if let progress = usWestBackgroundProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(usWestBackground/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadUSWestBackground()
              }
          }
  
          if let progress = usEastBackgroundProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(usEastBackground/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadUSEastBackground()
              }
          }
          
          if let progress = euCentralBackgroundProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(euCentralBackground/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadEUCentralBackground()
              }
          }
          
          if let progress = apacSouthBackgroundProgress {
            ProgressView(progress)
              .progressViewStyle(GaugeProgressStyle())
          } else {
            Text("\(apacSouthBackground/1000.00, specifier:  "%.2f") s").expandVertical()
              .onTapGesture {
                uploadApacSouthBackground()
              }
          }
        }
        VStack {
          Text("Diff D-B #s / %").expandVertical()
            .onTapGesture {
              usePercentageDiff.toggle()
            }
          
          if usePercentageDiff {
            Text("\(((usWestDefault - usWestBackground)/usWestBackground)*100, specifier:  "%.2f") %").expandVertical()
          } else {
            Text("\((usWestDefault - usWestBackground)/1000, specifier:  "%.2f") s").expandVertical()
          }
          
          if usePercentageDiff {
            Text("\(((usEastDefault - usEastBackground)/usEastBackground)*100, specifier:  "%.2f") %").expandVertical()
          } else {
            Text("\((usEastDefault - usEastBackground)/1000, specifier:  "%.2f") s").expandVertical()
          }
          
          if usePercentageDiff {
            Text("\(((euCentralDefault - euCentralBackground)/euCentralBackground)*100, specifier:  "%.2f") %").expandVertical()
          } else {
            Text("\((euCentralDefault - euCentralBackground)/1000, specifier:  "%.2f") s").expandVertical()
          }
          
          if usePercentageDiff {
            Text("\(((apacSouthDefault - apacSouthBackground)/apacSouthBackground)*100, specifier:  "%.2f") %").expandVertical()
          } else {
            Text("\((apacSouthDefault - apacSouthBackground)/1000, specifier:  "%.2f") s").expandVertical()
          }
        }
      }
      
      Button("Test All") {
        uploadAllDefault()
        
        uploadAllBackground()
      }
      
      Spacer()
      
      Text(appDescriptionString).padding().minimumScaleFactor(0.01)

      Spacer()
    }
  }
  
  let appDescriptionString = """
Tap on the 'Test All' button to run tests on both Session Types across all AWS Regions.

Tap on either `Default Config` or `BG Config` to run tests for all AWS Regions on that Session Type.

Tap on `USWest`, `US East`, `EU Cen`, or `APAC S` to run tests on both Session Types for that AWS Region.

Tap on any cell in the Session/AWS Region matrix to run that specific test.

Tap `Diff D-B` to toggle between showing the timing or percentage differences between the two Session Types for a given AWS Region.
"""
  
  func uploadAllDefault() {
    uploadUSWestDefault {
      uploadUSEastDefault {
        uploadEUCentralDefault {
          uploadApacSouthDefault()
        }
      }
    }
  }
  
  func uploadAllBackground() {
    uploadUSWestBackground {
      uploadUSEastBackground {
        uploadEUCentralBackground {
          uploadApacSouthBackground()
        }
      }
    }
  }
  
  // MARK: US West
  
  func uploadUSWestDefault(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .usWest,
      sessionType: .default
    ) { progress in
      usWestDefaultProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        usWestDefaultProgress = nil
        usWestDefault = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  func uploadUSWestBackground(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .usWest,
      sessionType: .background
    ) { progress in
      usWestBackgroundProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        usWestBackgroundProgress = nil
        usWestBackground = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  // MARK: US East
  
  func uploadUSEastDefault(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .usEast,
      sessionType: .default
    ) { progress in
      usEastDefaultProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        usEastDefaultProgress = nil
        usEastDefault = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  func uploadUSEastBackground(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .usEast,
      sessionType: .background
    ) { progress in
      usEastBackgroundProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        usEastBackgroundProgress = nil
        usEastBackground = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  
  // MARK: EU Central
  
  func uploadEUCentralDefault(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .euCentral,
      sessionType: .default
    ) { progress in
      euCentralDefaultProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        euCentralDefaultProgress = nil
        euCentralDefault = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  func uploadEUCentralBackground(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .euCentral,
      sessionType: .background
    ) { progress in
      euCentralBackgroundProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        euCentralBackgroundProgress = nil
        euCentralBackground = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  // MARK: APAC South
  
  func uploadApacSouthDefault(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .apacSouth,
      sessionType: .default
    ) { progress in
      apacSouthDefaultProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        apacSouthDefaultProgress = nil
        apacSouthDefault = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
  
  func uploadApacSouthBackground(_ completion: (() -> Void)? = nil ) {
    network.upload(
      imageData: imageData,
      key: .apacSouth,
      sessionType: .background
    ) { progress in
      apacSouthBackgroundProgress = progress
    } completion: { result in
      switch result {
      case .success(let timing):
        apacSouthBackgroundProgress = nil
        apacSouthBackground = timing
      case .failure(let error):
        print("Error while uploading \(error)")
      }
      
      completion?()
    }
  }
}

// MARK: Progress Style

struct GaugeProgressStyle: ProgressViewStyle {
  var strokeColor = Color.blue
  var strokeWidth = 2.0
  
  func makeBody(configuration: Configuration) -> some View {
    let fractionCompleted = configuration.fractionCompleted ?? 0
    
    return ZStack {
      Circle()
        .trim(from: 0, to: CGFloat(fractionCompleted))
        .stroke(strokeColor, style: StrokeStyle(lineWidth: CGFloat(strokeWidth), lineCap: .round))
        .rotationEffect(.degrees(-90))
        .frame(width: 50, height: 50, alignment: .center)
    }
  }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}



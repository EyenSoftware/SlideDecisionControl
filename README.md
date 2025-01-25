# SlideDecisionControl

SlideDecisionControl is a SwiftUI control designed to help prevent accidental actions by requiring a deliberate slide to confirm or reject decisions. It ensures intentional choices and provides a smooth user experience.

## Features

- **Prevents accidental taps** by requiring a sliding action.
- **Use explicit gestures** for critical operations.
- **Customizable UI** to fit various design needs.

## Demo

Check out how SlideDecisionControl works in action:

![SlideDecisionControl in action](Demo/demo.gif)

## Installation

### Swift Package Manager (SPM)

To install via Swift Package Manager, add the following line to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/EyenSoftware/SlideDecisionControl.git", from: "1.0.0")
]
```

Alternatively, in Xcode:

1. Go to **File > Add Packages...**
2. Enter the repository URL: `https://github.com/EyenSoftware/SlideDecisionControl.git`
3. Select the latest version and add it to your project.

## Usage

### Basic Example

```swift
import SlideDecisionControl

struct ContentView: View {
    var body: some View {
        SlideDecisionControl {
        	action in
        }
        .padding()
    }
}
```

### Customization

```swift
import SlideDecisionControl

struct ContentView: View {
    var body: some View {
        SlideDecisionControl(
			imageAccept: .system(name: "heart"),
			textAccept: "Slide to Love",
			imageMiddle: .system(name: "bubble"),
			imageReject: .system(name: "xmark.circle"),
			textReject: "Slide to Hate"
		) { _ in
		}
        .padding()
    }
}
```

![Customized](Demo/customized.gif)

## Requirements

- iOS 17.0+
- Swift 5.5+

## License

SlideDecisionControl is available under the MIT license. See the [LICENSE](LICENSE) file for more information.

## Contribution

Contributions are welcome! If you'd like to contribute, please fork the repository and submit a pull request.

## Feedback

We’d love to hear your thoughts! Feel free to open an issue for suggestions, bugs, or improvements.

---

**Made with ❤️ by [Eyen](https://eyen.fr)**


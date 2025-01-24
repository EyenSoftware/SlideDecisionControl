// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SlideDecisionControl",
	platforms: [
		.iOS(.v18)
	],
	products: [
		.library(name: "SlideDecisionControl", targets: ["SlideDecisionControl"]),
	],
	dependencies: [
		.package(url: "https://github.com/realm/SwiftLint", from: "0.58.2")
	],
	targets: [
		.target(
			name: "SlideDecisionControl",
			swiftSettings: [
				.swiftLanguageMode(.v6)
			],
			plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLint")]),
	]
)

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SlideDecisionControl",
	platforms: [
		.iOS(.v17)
	],
	products: [
		.library(name: "SlideDecisionControl", targets: ["SlideDecisionControl"]),
	],
	targets: [
		.target(
			name: "SlideDecisionControl",
			swiftSettings: [
				.swiftLanguageMode(.v6)
			]),
	]
)

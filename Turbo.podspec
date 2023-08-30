Pod::Spec.new do |spec|
  spec.name           = "Turbo"
  spec.version        = "7.0.0"
  spec.swift_version  = "5.3"
  spec.summary        = "Native iOS Framework for Turbo apps"
  spec.homepage       = "https://turbo.hotwired.dev/"
  spec.license        = { :type => "MIT", :file => "LICENSE" }
  spec.author         = { "Jay Ohms" => "jay@37signals.com" }
  spec.platform       = :ios, "14.0"
  spec.source         = { :git => "https://github.com/hotwired/turbo-ios.git", :tag => spec.version }
  spec.source_files   = "Source/**/*.swift"
  spec.resources      = "Source/**/*.js"
end

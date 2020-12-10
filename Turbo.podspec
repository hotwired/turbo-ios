Pod::Spec.new do |spec|
  spec.name           = "Turbo"
  spec.version        = "7.0.0"
  spec.swift_version  = "5.3"
  spec.summary        = "Native iOS Framework for Turbo apps"
  spec.homepage       = "https://hotwire.dev/turbo"
  spec.license        = { :type => "MIT", :file => "LICENSE" }
  spec.author         = { "Zach Waugh" => "zwaugh@gmail.com" }
  spec.platform       = :ios, "12.0"
  spec.source         = { :git => "https://github.com/basecamp/turbo-ios.git", :tag => "#{spec.version}" }
  spec.source_files   = "Source/**/*.swift"
  spec.resources      = "Source/**/*.js"
end

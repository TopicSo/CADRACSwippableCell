Pod::Spec.new do |s|
  s.name         = "LaserSwippableCell"
  s.version      = "1.0.0"
  s.summary      = "Swippable CollectionView cells made with Reactive Cocoa"

  s.homepage     = "https://github.com/LaserSrl/LaserSwippableCell"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author             = { "Laser Patrick" => "patrick.negretto@laser-group.com" }
  s.platform     = :ios, '9.0'
  s.requires_arc = true
  s.source       = { :git => "https://github.com/LaserSrl/LaserSwippableCell.git", :tag => "1.0.0" }
  s.source_files  = 'Source'

s.dependency 'ReactiveObjC'

end

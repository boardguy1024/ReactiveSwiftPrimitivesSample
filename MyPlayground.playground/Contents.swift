//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport
import ReactiveSwift
import Foundation
import Result


let (output, input) = Signal<Int, NoError>.pipe()

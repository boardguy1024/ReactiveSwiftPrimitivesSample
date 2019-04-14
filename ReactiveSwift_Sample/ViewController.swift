//
//  ViewController.swift
//  ReactiveSwift_Sample
//
//  Created by park kyung suk on 2019/04/11.
//  Copyright © 2019 park kyung suk. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Propertyを定義
        let title = "ReactiveSwift"
        let titleSignal = textSignalGenerator(text: title)
        let titleProperty = Property(initial: "", then: titleSignal)
        
        
        // Action を定義
        let titleLengthChecker = Action<Int, Bool, NoError>(
            state: titleProperty,
            execute: lengthCheckerSignalProducer
        )
        
        
        // Observer 정의
        titleLengthChecker.values.observeValues { isValid in
            print("is title valid: \(isValid)")
        }
        
        // 이것은 textField 에 문자를 하나씩 입력되는 것을 표현함
        // Action에 apply
        for i in 0..<title.count {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(i)) {
                // 10은 최소문자열
                titleLengthChecker.apply(10).start()
            }
        }
    }
    
    
    private func lengthCheckerSignalProducer(text: String, minimumLength: Int) -> SignalProducer<Bool, NoError> {
        return SignalProducer<Bool, NoError> { (observer, _) in

            observer.send(value: text.count > minimumLength)
            observer.sendCompleted()
        }
    }
    
    // 이것을 호출하면 singalGenegator 가 생성되고 (그 때부터 살아있다)
    // 클로저 안에서 n초마다 observer.send 로 값을 방출한다.
    private func textSignalGenerator(text: String) -> Signal<String, NoError> {
        return Signal<String, NoError> { (observer, _) in
            
            let now = DispatchTime.now()
            
            // text : ReactiveSwift
            for index in 0..<text.count {
                
                // 현재의 시점에서 * index 초마다 아래를 실행
                DispatchQueue.main.asyncAfter(deadline: now + 1.0 * Double(index)) {
                    
                    // 이건 now + index 마다
                    // R
                    // Re
                    // Rea
                    // Reac
                    // React
                    // ........ 이렇게  oserver.send( ) 로 값을 송출한다.
                    let indexStartOfText = text.startIndex
                    let indexEndOfText = text.index(text.startIndex, offsetBy: index)
                    let subString = text[indexStartOfText...indexEndOfText]
                    let value = String(subString)
                    
                    observer.send(value: value)
                }
            }
        }
    }
    
    private func doPropertySample() {
        
        let signalProducer: SignalProducer<Int, NoError> = SignalProducer { (observer, lifetime) in
            
            let now = DispatchTime.now()
            
            for index in 0..<10 {
                let timeElapsed = index * 5
                
                DispatchQueue.main.asyncAfter(deadline: now + Double(timeElapsed)) {
                    
                    guard !lifetime.hasEnded else {
                        observer.sendInterrupted()
                        return
                    }
                    
                    observer.send(value: timeElapsed)
                    
                    if index == 9 {
                        observer.sendCompleted()
                    }
                }
            }
        }
        
        let property = Property(initial: 0, then: signalProducer)
        
        property.signal.observeValues { value in
            print("[Observing Signal] Time elapsed = \(value)]")
        }
    }
    
    private func doSinglaProducerSample() {
        //Observer를 생성
        let signalObserver = Signal<Int, NoError>.Observer(
            value: { value in
                print("Time elapsed: \(value)")
        }, completed: {
            print("completed")
        }, interrupted: {
            print("interrupted")
        })
        
        let signalProducer: SignalProducer<Int, NoError> = SignalProducer { (observer, lifetime) in
            
            for i in 0..<10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 * Double(i)) {
                    
                    guard !lifetime.hasEnded else {
                        observer.sendInterrupted()
                        return
                    }
                    
                    observer.send(value: i)
                    
                    if i == 9 { observer.sendCompleted() }
                }
            }
        }
        
        // signalProducer를 start 한다.
        let disposable = signalProducer.start(signalObserver)
        
        // 10초후에 dispose한다.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            disposable.dispose()
        }
    }
    
    
    
    private func doActionSample() {
                // 이것은 SignalProducer<Int, NoError> 타입을 반환하는 클로저이다.
                let signalProducerGenerator: (Int) -> SignalProducer<Int, NoError> = { timeInterval in
                    return SignalProducer<Int, NoError> { (observer, lifetime) in
        
                        let now = DispatchTime.now()
        
                        for index in 0..<10 {
                            let timeElapsed = index * timeInterval
        
                            DispatchQueue.main.asyncAfter(deadline: now + Double(timeElapsed)) {
        
                                guard !lifetime.hasEnded else {
                                    observer.sendInterrupted()
                                    return
                                }
        
                                observer.send(value: timeElapsed)
        
                                if index == 9 {
                                    observer.sendCompleted()
                                }
                            }
                        }
                    }
        
                }
        
                let action = Action<Int, Int, NoError>(execute: signalProducerGenerator)
        
        
                action.values.observeValues { value in
                    print("Teim elapsed = \(value)")
                }
        
                action.values.observeCompleted {
                    print("Action completed")
                }
        
        
                // 1. input을 apply 하고 start
                action.apply(1).start()
        
                // 2. Action 이 처리실행중이므로 무시된다.
                action.apply(2).start()
        
        
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) {
        
                    // 3. action.apply(1) 이 완료한 후 이므로 실행된다.
                    action.apply(3).start()
                }
    }
    
    private func doSignalSample() {
        
        // Observer를 생성한다.
        let signalObserver = Signal<Int, NoError>.Observer(value: { value in
            print("Time elapsed: \(value)")
        }, completed: {
            print("completed")
        }, interrupted: {
            print("interrupted")
        })
        
        // Signal을 생성
        let (output, input) = Signal<Int, NoError>.pipe()
        
        for i in 0..<10 {
            
            // 위의 Signal 의 input 에 값을 send로 Event배출한다.
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 * Double(i)) {
                input.send(value: i)
            }
        }
        
        // output을 감시하는 시그널을 셋팅한다!
        output.observe(signalObserver)
    }
    
}


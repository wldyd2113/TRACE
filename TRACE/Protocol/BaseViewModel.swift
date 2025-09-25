//
//  BaseViewModel.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation

protocol BaseViewModel {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

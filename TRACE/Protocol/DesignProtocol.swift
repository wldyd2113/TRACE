//
//  DesignProtocol.swift
//  TRACE
//
//  Created by 차지용 on 9/25/25.
//

import Foundation

protocol DesiginProtocol {
    func configureHierarchy()
    func configureUI()
    func configureLayout()
}

protocol DesiginProtocolBind: DesiginProtocol {
    func bind()
}

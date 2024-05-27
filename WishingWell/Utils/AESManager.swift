//
//  AESManager.swift
//  TheWayToBasketball
//
//  Created by TWMP_IT_1 on 2022/8/15.
//  Copyright © 2022 LunYuChang. All rights reserved.
//

import Foundation
import CryptoSwift

class AESManager {
    static let shared = AESManager()
    
    private init() {
        print("AESManager init...")
    }
    
    private var hashKey = "CPLAOE0pgLmcBvUX3tcH5sSgkaTQLCwK"
    private var hashIv = "tdclsC14sqUO7hMS"

    func encrypt(str: String) -> String? {
        do {
            let sourceBytes = Padding.pkcs7.add(to: str.bytes, blockSize: 32)
            let aes = try AES(key: hashKey.bytes, blockMode: CBC(iv: hashIv.bytes), padding: .noPadding)
            let encrypted = try aes.encrypt(sourceBytes)
            return encrypted.toHexString()
            
        }catch {
            print("AES encrypt error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func decrypt(str: String) -> String? {
        do {
            let data = Data(hex: str)
            let aes = try AES(key: hashKey.bytes, blockMode: CBC(iv: hashIv.bytes), padding: .noPadding)
            let decrypted = try aes.decrypt(data.bytes)
            let result = Padding.pkcs7.remove(from: decrypted, blockSize: 32)
            return String(bytes: result, encoding: .utf8) ?? ""
            
        }catch {
            print("AES decrypt error: \(error.localizedDescription)")
            return nil
        }
    }
    
//    func addPKCS7Padding(data: [UInt8], iBlockSize: Int) -> [UInt8] {
//        let iLength: Int = data.count
//
//        let cPadding: UInt8 = UInt8(iBlockSize - (iLength % iBlockSize))
//
//        var output: [UInt8] = Data(count: iLength + Int(cPadding)).bytes
//
//        output[0..<iLength] = data[0..<iLength]
//
//        for i in iLength..<output.count {
//            output[i] = cPadding
//        }
//        return output
//    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
